`timescale 1ns / 1ps

module tb_asic_top;

    // --- DUT Interface Signals ---
    reg clk = 0;
    reg rst_n;
    reg start;
    reg [31:0] in_state_word;
    reg in_state_valid;
    reg in_state_last;
    reg out_state_ready;
    reg use_streamed_key;
    reg use_streamed_nonce;
    reg [1:0] chunk_type;
    reg chunk_valid;
    reg [31:0] chunk;
    reg out_chunk_ready;

    wire busy;
    wire done;
    wire in_state_ready;
    wire [31:0] out_state_word;
    wire out_state_valid;
    wire [4:0] chunk_index;
    wire chunk_request;
    wire [1:0] request_type;
    wire [1:0] out_chunk_type;
    wire out_chunk_valid;
    wire [31:0] out_chunk;
    wire [4:0] out_chunk_index;

    // --- Testbench Internal Variables ---
    integer test_count = 0;
    integer pass_count = 0;
    integer i; // General purpose loop counter

    // --- DUT Instantiation ---
    asic_top dut (
        .clk(clk), .rst_n(rst_n), .start(start), .busy(busy), .done(done),
        .in_state_word(in_state_word), .in_state_valid(in_state_valid),
        .in_state_last(in_state_last), .in_state_ready(in_state_ready),
        .out_state_word(out_state_word), .out_state_valid(out_state_valid),
        .out_state_ready(out_state_ready), .use_streamed_key(use_streamed_key),
        .use_streamed_nonce(use_streamed_nonce), .chunk_type(chunk_type),
        .chunk_valid(chunk_valid), .chunk(chunk), .chunk_index(chunk_index),
        .chunk_request(chunk_request), .request_type(request_type),
        .out_chunk_type(out_chunk_type), .out_chunk_valid(out_chunk_valid),
        .out_chunk(out_chunk), .out_chunk_index(out_chunk_index),
        .out_chunk_ready(out_chunk_ready)
    );

    // --- Clock Generator ---
    always #5 clk = ~clk;

    // --- Simple Reset Task ---
    task reset_dut;
        begin
            rst_n <= 0;
            start <= 0;
            in_state_valid <= 0;
            in_state_last <= 0;
            chunk_valid <= 0;
            out_state_ready <= 1;
            out_chunk_ready <= 1;
            #20;
            rst_n <= 1;
            @(posedge clk);
            $display("INFO: DUT Reset Complete.");
        end
    endtask

    // --- MAIN TEST SEQUENCE ---
    initial begin
        // --- Test-specific variables ---
        reg [255:0] rfc_key;
        reg [95:0]  rfc_nonce;
        reg [511:0] rfc_plaintext;
        reg [511:0] rfc_ciphertext;
        reg [511:0] received_ciphertext;
        reg         test_ok;

        $dumpfile("comprehensive_dump.vcd");
        $dumpvars(0, tb_asic_top);
        $display("\n--- Comprehensive Testbench Started ---\n");

        // ====================================================================
        // TEST 1: RFC 8439 Vector Verification (Streamed Key & Nonce)
        // ====================================================================
        test_count = test_count + 1;
        $display("--- Running Test %0d: RFC 8439 Vector Verification ---", test_count);
        reset_dut();

        rfc_key        = 256'h03020100_07060504_0b0a0908_0f0e0d0c_13121110_17161514_1b1a1918_1f1e1d1c;
        rfc_nonce      = 96'h00000000_00000000_09000000;
        // ** FIX: Corrected the plaintext hex literal to be the correct value and size **
        rfc_plaintext  = 512'h6f20756f_79207265_66666f20_646c756f_63204920_6649203a_39392720_666f2073_73616c63_20656874_20666f20_6e656d65_6c746e65_4720646e_61207365_6964614c;
        rfc_ciphertext = 512'he405f1e3_ce2e4963_e33c6a13_b9314028_6c55353c_9e585505_2f333646_6474e28b_d8ab4402_41223a5e_48a4c8a2_143d4974_d2580f8e_2083648a_359a3b84_6b53e831;

        use_streamed_key <= 1'b1;
        use_streamed_nonce <= 1'b1;
        start <= 1; @(posedge clk); start <= 0;

        for (i = 0; i < 8; i = i + 1) begin
            wait(dut.chunk_request && dut.request_type == 2'b00 && dut.chunk_index == i);
            chunk_valid <= 1; chunk_type <= 2'b00; chunk <= rfc_key[i*32 +: 32];
            @(posedge clk); chunk_valid <= 0;
        end
        for (i = 0; i < 3; i = i + 1) begin
            wait(dut.chunk_request && dut.request_type == 2'b01 && dut.chunk_index == i);
            chunk_valid <= 1; chunk_type <= 2'b01; chunk <= rfc_nonce[i*32 +: 32];
            @(posedge clk); chunk_valid <= 0;
        end

        for (i = 0; i < 16; i = i + 1) begin
            wait (dut.in_state_ready);
            in_state_valid <= 1; in_state_word <= rfc_plaintext[i*32 +: 32];
            in_state_last <= (i == 15);
            @(posedge clk);
        end
        in_state_valid <= 0;

        for (i = 0; i < 16; i = i + 1) begin
            wait(dut.out_state_valid);
            received_ciphertext[i*32 +: 32] = dut.out_state_word;
            @(posedge clk);
        end

        test_ok = (received_ciphertext === rfc_ciphertext);
        wait(dut.done);
        if (test_ok && dut.done) begin
            $display("✅ SUCCESS: Test %0d Passed!", test_count);
            pass_count = pass_count + 1;
        end else begin
            $error("❌ FAILURE: Test %0d Failed! Output mismatch or 'done' not received.", test_count);
            $error("  Expected: %h", rfc_ciphertext);
            $error("  Received: %h", received_ciphertext);
        end

        // ====================================================================
        // TEST 2: Generated Key & Nonce (Protocol Check)
        // ====================================================================
        test_count = test_count + 1;
        $display("\n--- Running Test %0d: Generated Key & Nonce ---", test_count);
        reset_dut();

        use_streamed_key <= 1'b0; use_streamed_nonce <= 1'b0;
        start <= 1; @(posedge clk); start <= 0;

        for (i = 0; i < 8; i = i + 1) begin
            wait(dut.out_chunk_valid && dut.out_chunk_type == 2'b00 && dut.out_chunk_index == i);
            @(posedge clk);
        end
        for (i = 0; i < 3; i = i + 1) begin
            wait(dut.out_chunk_valid && dut.out_chunk_type == 2'b01 && dut.out_chunk_index == i);
            @(posedge clk);
        end

        for(i=0; i<16; i=i+1) begin
            wait(dut.in_state_ready);
            in_state_valid <= 1; in_state_word <= 32'hdeadbeef + i;
            in_state_last <= (i==15);
            @(posedge clk);
        end
        in_state_valid <= 0;

        wait(dut.done);
        $display("✅ SUCCESS: Test %0d Passed! ('done' signal received)", test_count);
        pass_count = pass_count + 1;

        // ====================================================================
        // TEST 3: Multi-Block Message (128 bytes)
        // ====================================================================
        test_count = test_count + 1;
        $display("\n--- Running Test %0d: Multi-Block Message (128 bytes) ---", test_count);
        reset_dut();

        use_streamed_key <= 1'b0; use_streamed_nonce <= 1'b0;
        start <= 1; @(posedge clk); start <= 0;

        for (i = 0; i < 8; i = i + 1) begin
            wait(dut.out_chunk_valid && dut.out_chunk_type == 2'b00 && dut.out_chunk_index == i);
            @(posedge clk);
        end
        for (i = 0; i < 3; i = i + 1) begin
            wait(dut.out_chunk_valid && dut.out_chunk_type == 2'b01 && dut.out_chunk_index == i);
            @(posedge clk);
        end

        for(i=0; i<32; i=i+1) begin
            wait(dut.in_state_ready);
            in_state_valid <= 1; in_state_word <= 32'h0 + i;
            in_state_last <= (i==31);
            @(posedge clk);
        end
        in_state_valid <= 0;

        wait(dut.done);
        $display("✅ SUCCESS: Test %0d Passed! ('done' signal received for multi-block message)", test_count);
        pass_count = pass_count + 1;

        // ====================================================================
        // TEST 4: Streamed Key, Generated Nonce
        // ====================================================================
        test_count = test_count + 1;
        $display("\n--- Running Test %0d: Streamed Key, Generated Nonce ---", test_count);
        reset_dut();

        use_streamed_key <= 1'b1; use_streamed_nonce <= 1'b0;
        start <= 1; @(posedge clk); start <= 0;

        for (i = 0; i < 8; i = i + 1) begin
            wait(dut.chunk_request && dut.request_type == 2'b00 && dut.chunk_index == i);
            chunk_valid <= 1; chunk_type <= 2'b00; chunk <= 32'h11111111 * (i+1);
            @(posedge clk); chunk_valid <= 0;
        end

        for (i = 0; i < 3; i = i + 1) begin
            wait(dut.out_chunk_valid && dut.out_chunk_type == 2'b01 && dut.out_chunk_index == i);
            @(posedge clk);
        end

        for(i=0; i<16; i=i+1) begin
            wait(dut.in_state_ready);
            in_state_valid <= 1; in_state_word <= 32'hAAAAAAAA + i;
            in_state_last <= (i==15);
            @(posedge clk);
        end
        in_state_valid <= 0;

        wait(dut.done);
        $display("✅ SUCCESS: Test %0d Passed! ('done' signal received)", test_count);
        pass_count = pass_count + 1;

        // --- Final Summary ---
        $display("\n--- Testbench Finished ---");
        $display("--- SUMMARY: %0d / %0d tests passed. ---", pass_count, test_count);
        #50;
        $finish;
    end

endmodule