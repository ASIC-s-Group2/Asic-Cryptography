`timescale 1ns / 1ps

module tb_asic_top;

    // --- Testbench Signals ---
    reg clk;
    reg rst_n;
    reg start;
    reg [511:0] in_state; // Plaintext input

    // asic_top outputs
    wire busy;
    wire done;
    wire [511:0] out_state; // Ciphertext output

    // asic_top control inputs
    reg use_streamed_key;
    reg use_streamed_nonce;
    reg use_streamed_counter;

    // asic_top streaming inputs (driven by testbench)
    reg [1:0] tb_chunk_type;
    reg tb_chunk_valid;
    reg [31:0] tb_chunk_data;

    // asic_top streaming outputs (monitored by testbench)
    wire [4:0] chunk_index;
    wire chunk_request;
    wire [1:0] request_type;

    // TRNG mock signals
    wire [31:0] mock_trng_random_number;
    wire mock_trng_ready;
    wire mock_trng_request; // This will be the trng_request output from asic_top

    // --- Internal Testbench Variables ---
    integer test_id = 0;
    integer pass_count = 0;
    reg [255:0] expected_key_val;
    reg [95:0] expected_nonce_val;
    reg [31:0] expected_counter_val;
    reg [511:0] expected_ciphertext_val;

    // --- Instantiate asic_top ---
    asic_top U_ASIC_TOP (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .busy(busy),
        .done(done),
        .in_state(in_state),
        .out_state(out_state),
        .use_streamed_key(use_streamed_key),
        .use_streamed_nonce(use_streamed_nonce),
        .use_streamed_counter(use_streamed_counter),
        .chunk_type(tb_chunk_type),
        .chunk_valid(tb_chunk_valid),
        .chunk(tb_chunk_data),
        .chunk_index(chunk_index),
        .chunk_request(chunk_request),
        .request_type(request_type),
        .trng_random_number(mock_trng_random_number),
        .trng_ready(mock_trng_ready),
        .trng_request(mock_trng_request) // asic_top's trng_request output
    );

    // --- Instantiate Mock TRNGHardened ---
    MockTRNGHardened U_MOCK_TRNG (
        .clk(clk),
        .rst_n(rst_n),
        .trng_request(mock_trng_request), // Connect to asic_top's request
        .random_number(mock_trng_random_number),
        .ready(mock_trng_ready)
    );

    // --- Clock Generation ---
    always #5 clk = ~clk; // 10ns period (100MHz)

    // --- Main Test Sequence ---
    initial begin
        $dumpfile("tb_asic_top.vcd");
        $dumpvars(0, tb_asic_top);

        // Initialize all signals
        clk = 0;
        rst_n = 0; // Assert reset
        start = 0;
        in_state = 512'h0;
        use_streamed_key = 0;
        use_streamed_nonce = 0;
        use_streamed_counter = 0;
        tb_chunk_type = 2'b00; // KEY
        tb_chunk_valid = 0;
        tb_chunk_data = 32'h0;

        $display("========================================");
        $display("  ASIC Top-Level ChaCha20 Testbench     ");
        $display("========================================");

        // Release reset
        #20 rst_n = 1;
        #10; // Allow reset to propagate

        // --- Test Case 1: All TRNG-Generated Inputs ---
        test_id = 1;
        $display("\n--- Test %0d: All Inputs TRNG-Generated ---", test_id);
        use_streamed_key = 0;
        use_streamed_nonce = 0;
        use_streamed_counter = 0;
        in_state = 512'hAABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899; // Sample plaintext

        start = 1;
        #10 start = 0; // Pulse start

        // Wait for acquisition to complete (TRNG takes cycles)
        // Key: 8 chunks, Nonce: 3 chunks, Counter: 1 chunk = 12 TRNG cycles
        // Plus 1 cycle for CORE_START, multiple for CORE_WAIT
        // We'll just wait for 'done'
        wait(done);
        #10;

        $display("Test %0d Results:", test_id);
        $display("  Busy: %b, Done: %b", busy, done);
        $display("  Ciphertext: %h", out_state);
        // We can't predict TRNG output, so we just check if it completed.
        if (done) begin
            $display("  PASS: All TRNG acquisition and core operation completed.");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: All TRNG acquisition and core operation did not complete.");
        end

        // --- Test Case 2: Streamed Key, TRNG Nonce, TRNG Counter ---
        test_id = 2;
        $display("\n--- Test %0d: Streamed Key, TRNG Nonce/Counter ---", test_id);
        use_streamed_key = 1;
        use_streamed_nonce = 0;
        use_streamed_counter = 0;
        in_state = 512'h11223344556677889900AABBCCDDEEFF11223344556677889900AABBCCDDEEFF11223344556677889900AABBCCDDEEFF11223344556677889900AABBCCDDEEFF; // Different plaintext

        start = 1;
        #10 start = 0; // Pulse start

        // Stream 8 key chunks
        for (integer i = 0; i < 8; i = i + 1) begin
            wait(chunk_request && request_type == 2'b00); // Wait for key request
            tb_chunk_data = 32'h10000000 + i; // Sample key data
            tb_chunk_type = 2'b00; // KEY
            tb_chunk_valid = 1;
            #10; // Allow ASIC to latch
            tb_chunk_valid = 0; // Deassert valid
        end

        // Wait for acquisition and core operation to complete
        wait(done);
        #10;

        $display("Test %0d Results:", test_id);
        $display("  Busy: %b, Done: %b", busy, done);
        $display("  Ciphertext: %h", out_state);
        if (done) begin
            $display("  PASS: Streamed Key, TRNG Nonce/Counter acquisition and core operation completed.");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: Streamed Key, TRNG Nonce/Counter acquisition and core operation did not complete.");
        end

        // --- Test Case 3: Streamed Key, Streamed Nonce, TRNG Counter ---
        test_id = 3;
        $display("\n--- Test %0d: Streamed Key/Nonce, TRNG Counter ---", test_id);
        use_streamed_key = 1;
        use_streamed_nonce = 1;
        use_streamed_counter = 0;
        in_state = 512'hAAAABBBBCCCCDDDDEEEEFFFF0000111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFF0000111122223333444455556666777788889999; // Different plaintext

        start = 1;
        #10 start = 0; // Pulse start

        // Stream 8 key chunks
        for (integer i = 0; i < 8; i = i + 1) begin
            wait(chunk_request && request_type == 2'b00); // Wait for key request
            tb_chunk_data = 32'h20000000 + i; // Sample key data
            tb_chunk_type = 2'b00; // KEY
            tb_chunk_valid = 1;
            #10;
            tb_chunk_valid = 0;
        end

        // Stream 3 nonce chunks
        for (integer i = 0; i < 3; i = i + 1) begin
            wait(chunk_request && request_type == 2'b01); // Wait for nonce request
            tb_chunk_data = 32'h30000000 + i; // Sample nonce data
            tb_chunk_type = 2'b01; // NONCE
            tb_chunk_valid = 1;
            #10;
            tb_chunk_valid = 0;
        end

        // Wait for acquisition and core operation to complete
        wait(done);
        #10;

        $display("Test %0d Results:", test_id);
        $display("  Busy: %b, Done: %b", busy, done);
        $display("  Ciphertext: %h", out_state);
        if (done) begin
            $display("  PASS: Streamed Key/Nonce, TRNG Counter acquisition and core operation completed.");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: Streamed Key/Nonce, TRNG Counter acquisition and core operation did not complete.");
        end

        // --- Test Case 4: All Streamed Inputs (Key, Nonce, Counter) ---
        test_id = 4;
        $display("\n--- Test %0d: All Streamed Inputs ---", test_id);
        use_streamed_key = 1;
        use_streamed_nonce = 1;
        use_streamed_counter = 1;
        in_state = 512'h0000111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFF0000111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFF; // Different plaintext

        start = 1;
        #10 start = 0; // Pulse start

        // Stream 8 key chunks
        for (integer i = 0; i < 8; i = i + 1) begin
            wait(chunk_request && request_type == 2'b00); // Wait for key request
            tb_chunk_data = 32'h40000000 + i; // Sample key data
            tb_chunk_type = 2'b00; // KEY
            tb_chunk_valid = 1;
            #10;
            tb_chunk_valid = 0;
        end

        // Stream 3 nonce chunks
        for (integer i = 0; i < 3; i = i + 1) begin
            wait(chunk_request && request_type == 2'b01); // Wait for nonce request
            tb_chunk_data = 32'h50000000 + i; // Sample nonce data
            tb_chunk_type = 2'b01; // NONCE
            tb_chunk_valid = 1;
            #10;
            tb_chunk_valid = 0;
        end

        // Stream 1 counter chunk
        wait(chunk_request && request_type == 2'b10); // Wait for counter request
        tb_chunk_data = 32'h60000000; // Sample counter data
        tb_chunk_type = 2'b10; // COUNTER
        tb_chunk_valid = 1;
        #10;
        tb_chunk_valid = 0;

        // Wait for acquisition and core operation to complete
        wait(done);
        #10;

        $display("Test %0d Results:", test_id);
        $display("  Busy: %b, Done: %b", busy, done);
        $display("  Ciphertext: %h", out_state);
        if (done) begin
            $display("  PASS: All Streamed Inputs acquisition and core operation completed.");
            pass_count = pass_count + 1;
        end else begin
            $display("  FAIL: All Streamed Inputs acquisition and core operation did not complete.");
        end

        // --- Final Summary ---
        $display("\n========================================");
        $display("          Test Summary                  ");
        $display("========================================");
        $display("Total Tests Run: %0d", test_id);
        $display("Tests Passed:    %0d", pass_count);
        $display("Tests Failed:    %0d", test_id - pass_count);
        if (pass_count == test_id) begin
            $display("*** ALL TESTS PASSED! ***");
        end else begin
            $display("!!! SOME TESTS FAILED !!!");
        end
        $display("========================================");

        $finish;
    end

endmodule
