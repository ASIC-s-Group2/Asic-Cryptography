`timescale 1ns/1ps

module tb_asic_top;

    // --- Clock period and timeout ---
    localparam CLK_PERIOD = 10;
    localparam TIMEOUT = 10000;

    // --- RFC 8439 test vectors (Counter = 1) ---
    localparam [255:0] RFC_KEY   = {32'h1f1e1d1c, 32'h1b1a1918, 32'h17161514, 32'h13121110,
                                    32'h0f0e0d0c, 32'h0b0a0908, 32'h07060504, 32'h03020100};
    localparam [95:0]  RFC_NONCE = {32'h00000000, 32'h4a000000, 32'h00000000};

    // --- DUT interface ---
    reg clk, rst_n, start;
    reg [31:0] in_state_word;
    reg        in_state_valid, in_state_last;
    wire       in_state_ready;

    wire [31:0] out_state_word;
    wire        out_state_valid;
    reg         out_state_ready;

    reg  use_streamed_key, use_streamed_nonce;
    reg  [1:0] chunk_type;
    reg        chunk_valid;
    reg  [31:0] chunk;
    wire [4:0] chunk_index;
    wire       chunk_request;
    wire [1:0] request_type;
    wire [1:0] out_chunk_type;
    wire       out_chunk_valid;
    wire [31:0] out_chunk;
    wire [4:0]  out_chunk_index;
    reg         out_chunk_ready;
    wire done;

    // --- Keystream reference values ---
    reg [31:0] rfc_keystream[0:15];

    // --- DUT instantiation ---
    asic_top dut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .in_state_word(in_state_word), .in_state_valid(in_state_valid),
        .in_state_last(in_state_last), .in_state_ready(in_state_ready),
        .out_state_word(out_state_word), .out_state_valid(out_state_valid),
        .out_state_ready(out_state_ready),
        .use_streamed_key(use_streamed_key), .use_streamed_nonce(use_streamed_nonce),
        .chunk(chunk), .chunk_type(chunk_type), .chunk_valid(chunk_valid),
        .chunk_index(chunk_index), .chunk_request(chunk_request),
        .request_type(request_type), .out_chunk_type(out_chunk_type),
        .out_chunk_valid(out_chunk_valid), .out_chunk(out_chunk),
        .out_chunk_index(out_chunk_index), .out_chunk_ready(out_chunk_ready)
    );

    // --- Clock generation ---
    always #(CLK_PERIOD/2) clk = ~clk;

    // --- Test logic ---
    initial begin
        reg [31:0] captured_keystream[0:15];
        integer wait_count, mismatches;
        mismatches = 0;

        $display("--- RFC 8439 Compliance Test Started ---");
        $dumpfile("rfc_compliance.vcd");
        $dumpvars(0, tb_asic_top);

        // --- Initialize signals ---
        clk = 0; rst_n = 0; start = 0;
        in_state_valid = 0; in_state_last = 0; in_state_word = 0;
        use_streamed_key = 1; use_streamed_nonce = 1;
        chunk_valid = 0;
        out_state_ready = 1; out_chunk_ready = 1;

        repeat (5) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        start = 1;
        @(posedge clk);
        start = 0;

        // --- Send Key Chunks ---
        $display("TB: Sending RFC key...");
        for (int i = 0; i < 8; i++) begin
            wait_count = 0;
            while (!(chunk_request && request_type == 2'b00) && wait_count < TIMEOUT) begin
                @(posedge clk); wait_count++;
            end
            if (wait_count >= TIMEOUT) begin
                $fatal("Timeout waiting for KEY chunk request %0d", i);
            end

            chunk       <= RFC_KEY[i*32 +: 32];
            chunk_type  <= 2'b00;
            chunk_valid <= 1;
            $display("KEY[%0d] = 0x%08x", i, RFC_KEY[i*32 +: 32]);
            @(posedge clk);
            chunk_valid <= 0;
        end

        // --- Send Nonce Chunks ---
        $display("TB: Sending RFC nonce...");
        for (int i = 0; i < 3; i++) begin
            wait_count = 0;
            while (!(chunk_request && request_type == 2'b01) && wait_count < TIMEOUT) begin
                @(posedge clk); wait_count++;
            end
            if (wait_count >= TIMEOUT) begin
                $fatal("Timeout waiting for NONCE chunk request %0d", i);
            end

            chunk       <= RFC_NONCE[i*32 +: 32];
            chunk_type  <= 2'b01;
            chunk_valid <= 1;
            $display("NONCE[%0d] = 0x%08x", i, RFC_NONCE[i*32 +: 32]);
            @(posedge clk);
            chunk_valid <= 0;
        end

        // --- Send plaintext and receive keystream ---
        $display("TB: Sending zero plaintext and capturing keystream...");
        for (int i = 0; i < 16; i++) begin
            wait_count = 0;
            while (!in_state_ready && wait_count < TIMEOUT) begin
                @(posedge clk); wait_count++;
            end
            if (wait_count >= TIMEOUT) $fatal("Timeout waiting for in_state_ready (%0d)", i);

            in_state_word  <= 32'h0;
            in_state_valid <= 1;
            in_state_last  <= (i == 15);
            @(posedge clk);
            in_state_valid <= 0;

            wait_count = 0;
            while (!out_state_valid && wait_count < TIMEOUT) begin
                @(posedge clk); wait_count++;
            end
            if (wait_count >= TIMEOUT) $fatal("Timeout waiting for out_state_valid (%0d)", i);

            captured_keystream[i] = out_state_word;
            $display("OUT[%0d] = 0x%08x", i, out_state_word);
        end
        in_state_last <= 0;

        // --- Wait for done signal ---
        wait_count = 0;
        while (!done && wait_count < TIMEOUT) begin
            @(posedge clk); wait_count++;
        end
        if (wait_count >= TIMEOUT) $fatal("Timeout waiting for done signal");
        $display("TB: 'done' received.");

        // --- RFC expected keystream (Counter = 1) ---
        rfc_keystream = '{
            32'h10106437, 32'h19245f3c, 32'h806cd541, 32'h31a33555,
            32'h87995a80, 32'h4933e33a, 32'h4782326b, 32'h899a1cf1,
            32'h9a533783, 32'h5694a869, 32'h2e3a14c2, 32'h03428b77,
            32'h94a32e1a, 32'he62506d7, 32'hb039b015, 32'h94249b33
        };

        // --- Verify output ---
        $display("\n======== Verification ========");
        $display("Idx |   DUT Output   | RFC Ref        | Match");
        $display("---------------------------------------------");
        for (int i = 0; i < 16; i++) begin
            if (captured_keystream[i] === rfc_keystream[i]) begin
                $display("%2d  | 0x%08x | 0x%08x |  ✅", i, captured_keystream[i], rfc_keystream[i]);
            end else begin
                $display("%2d  | 0x%08x | 0x%08x |  ❌", i, captured_keystream[i], rfc_keystream[i]);
                mismatches++;
            end
        end

        if (mismatches == 0) begin
            $display("Test PASSED ✅ — RFC keystream match complete!");
        end else begin
            $display("Test FAILED ❌ — %0d mismatch(es)", mismatches);
        end

        $finish;
    end

endmodule
