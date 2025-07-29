`timescale 1ns / 1ps

module tb_asic_top_fixed;

    // --- Testbench Signals ---
    reg clk;
    reg rst_n;
    reg start;

    // --- DUT Connections ---
    wire busy;
    wire done;
    wire [4:0] chunk_index;
    wire chunk_request;
    wire [1:0] request_type;
    wire trng_request;

    reg use_streamed_key;
    reg use_streamed_nonce;
    reg use_streamed_counter;

    // Chunk Streaming (Key/Nonce/Counter)
    reg [1:0] tb_chunk_type;
    reg tb_chunk_valid;
    reg [31:0] tb_chunk_data;

    // State Streaming (Plaintext/Ciphertext)
    reg [31:0] tb_in_state_word;
    reg tb_in_state_valid;
    wire tb_in_state_ready;
    wire [31:0] tb_out_state_word;
    wire tb_out_state_valid;
    reg tb_out_state_ready;

    // TRNG signals driven by the mock TRNG in the testbench
    reg [31:0] tb_trng_data;
    reg tb_trng_ready;

    // --- Internal Testbench Variables ---
    integer test_id = 0;
    integer pass_count = 0;
    reg [511:0] original_plaintext;
    reg [511:0] intermediate_ciphertext;
    reg [511:0] final_plaintext;
    reg [255:0] test_key;
    reg [95:0]  test_nonce;
    reg [31:0]  test_counter;

    // Timeout counter to prevent infinite loops
    integer timeout_counter;
    parameter MAX_TIMEOUT = 10000;

    // --- Instantiate asic_top ---
    asic_top U_ASIC_TOP (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .busy(busy),
        .done(done),
        .in_state_word(tb_in_state_word),
        .in_state_valid(tb_in_state_valid),
        .in_state_ready(tb_in_state_ready),
        .out_state_word(tb_out_state_word),
        .out_state_valid(tb_out_state_valid),
        .out_state_ready(tb_out_state_ready),
        .use_streamed_key(use_streamed_key),
        .use_streamed_nonce(use_streamed_nonce),
        .use_streamed_counter(use_streamed_counter),
        .chunk_type(tb_chunk_type),
        .chunk_valid(tb_chunk_valid),
        .chunk(tb_chunk_data),
        .chunk_index(chunk_index),
        .chunk_request(chunk_request),
        .request_type(request_type),
        .trng_data(tb_trng_data),
        .trng_ready(tb_trng_ready),
        .trng_request(trng_request)
    );

    // --- Instantiate Mock TRNG ---
    MockTRNGHardened U_MOCK_TRNG (
        .clk(clk),
        .rst_n(rst_n),
        .trng_request(trng_request),
        .random_number(tb_trng_data),
        .ready(tb_trng_ready)
    );

    // --- Clock Generation ---
    always #5 clk = ~clk;

    // --- Enhanced Tasks with Timeouts ---
    
    // Task to wait with timeout
    task wait_with_timeout(input condition, input [31:0] max_cycles, input [255:0] description);
        begin
            timeout_counter = 0;
            while (!condition && timeout_counter < max_cycles) begin
                @(posedge clk);
                timeout_counter = timeout_counter + 1;
            end
            if (timeout_counter >= max_cycles) begin
                $display("TIMEOUT: %s after %0d cycles", description, max_cycles);
                $finish;
            end
        end
    endtask

    // Enhanced stream_in_data with timeout
    task stream_in_data(input [511:0] data_block);
        begin
            $display("  Streaming in data block: %h", data_block);
            for (integer i = 0; i < 16; i = i + 1) begin
                wait_with_timeout(tb_in_state_ready, 1000, "waiting for in_state_ready");
                @(posedge clk);
                tb_in_state_word  = data_block[i*32 +: 32];
                tb_in_state_valid = 1;
                $display("    Word %0d: %h", i, data_block[i*32 +: 32]);
                @(posedge clk);
                tb_in_state_valid = 0;
            end
            $display("  Data streaming complete");
        end
    endtask

    // Enhanced stream_out_data with timeout
    task stream_out_data(output [511:0] captured_block);
        begin
            $display("  Streaming out data...");
            for (integer i = 0; i < 16; i = i + 1) begin
                tb_out_state_ready = 1;
                wait_with_timeout(tb_out_state_valid, 1000, "waiting for out_state_valid");
                @(posedge clk);
                captured_block[i*32 +: 32] = tb_out_state_word;
                $display("    Word %0d: %h", i, tb_out_state_word);
            end
            tb_out_state_ready = 0;
            $display("  Data capture complete: %h", captured_block);
        end
    endtask

    // Enhanced stream_in_k_n_c with timeout and debug
    task stream_in_k_n_c(input [255:0] key, input [95:0] nonce, input [31:0] counter);
        begin
            $display("  Streaming Key/Nonce/Counter...");
            
            // Stream 8 key chunks
            $display("    Streaming KEY (%h)", key);
            for (integer i = 0; i < 8; i = i + 1) begin
                wait_with_timeout(chunk_request && request_type == 2'b00, 1000, "waiting for key chunk request");
                @(posedge clk);
                tb_chunk_data = key[i*32 +: 32];
                tb_chunk_type = 2'b00; // KEY
                tb_chunk_valid = 1;
                $display("      Key chunk %0d: %h", i, key[i*32 +: 32]);
                @(posedge clk);
                tb_chunk_valid = 0;
            end

            // Stream 3 nonce chunks
            $display("    Streaming NONCE (%h)", nonce);
            for (integer i = 0; i < 3; i = i + 1) begin
                wait_with_timeout(chunk_request && request_type == 2'b01, 1000, "waiting for nonce chunk request");
                @(posedge clk);
                tb_chunk_data = nonce[i*32 +: 32];
                tb_chunk_type = 2'b01; // NONCE
                tb_chunk_valid = 1;
                $display("      Nonce chunk %0d: %h", i, nonce[i*32 +: 32]);
                @(posedge clk);
                tb_chunk_valid = 0;
            end

            // Stream 1 counter chunk
            $display("    Streaming COUNTER (%h)", counter);
            wait_with_timeout(chunk_request && request_type == 2'b10, 1000, "waiting for counter chunk request");
            @(posedge clk);
            tb_chunk_data = counter;
            tb_chunk_type = 2'b10; // COUNTER
            tb_chunk_valid = 1;
            $display("      Counter: %h", counter);
            @(posedge clk);
            tb_chunk_valid = 0;
            
            $display("  K/N/C streaming complete");
        end
    endtask

    // --- Main Test Sequence ---
    initial begin
        $dumpfile("tb_asic_top_fixed.vcd");
        $dumpvars(0, tb_asic_top_fixed);

        // Initialize all signals
        clk = 0; rst_n = 0; start = 0;
        use_streamed_key = 0; use_streamed_nonce = 0; use_streamed_counter = 0;
        tb_chunk_type = 2'b00; tb_chunk_valid = 0; tb_chunk_data = 32'h0;
        tb_in_state_word = 32'h0; tb_in_state_valid = 0; tb_out_state_ready = 0;

        $display("========================================");
        $display(" ASIC Top-Level Fixed Testbench ");
        $display("========================================");

        #20 rst_n = 1; #10;
        $display("Reset complete, starting test...");

        // --- Test Case 1: All Streamed Inputs, Encrypt then Decrypt ---
        test_id = 1;
        $display("\n--- Test %0d: All Streamed Inputs Encrypt/Decrypt Cycle ---", test_id);
        use_streamed_key = 1; use_streamed_nonce = 1; use_streamed_counter = 1;

        // Define test data
        original_plaintext = 512'h000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F;
        test_key = 256'hDEADBEEF_CAFEF00D_01020304_05060708_DEADBEEF_CAFEF00D_01020304_05060708;
        test_nonce = 96'h12345678_9ABCDEF0_FEDCBA98;
        test_counter = 32'hA0B0C0D0;

        $display("Original plaintext: %h", original_plaintext);
        $display("Test key: %h", test_key);
        $display("Test nonce: %h", test_nonce);
        $display("Test counter: %h", test_counter);

        // -- ENCRYPTION PASS --
        $display("\nTest %0d: Starting Encryption Pass...", test_id);
        start = 1; #10; start = 0;

        fork
            stream_in_k_n_c(test_key, test_nonce, test_counter);
            stream_in_data(original_plaintext);
            stream_out_data(intermediate_ciphertext);
        join

        wait_with_timeout(done, 5000, "waiting for encryption to complete");
        #10;
        $display("Encryption Pass Complete. Ciphertext: %h", intermediate_ciphertext);

        // -- DECRYPTION PASS --
        $display("\nTest %0d: Starting Decryption Pass...", test_id);
        start = 1; #10; start = 0;

        fork
            stream_in_k_n_c(test_key, test_nonce, test_counter);
            stream_in_data(intermediate_ciphertext);
            stream_out_data(final_plaintext);
        join

        wait_with_timeout(done, 5000, "waiting for decryption to complete");
        #10;
        $display("Decryption Pass Complete. Final Plaintext: %h", final_plaintext);

        // -- VERIFICATION --
        if (final_plaintext == original_plaintext) begin
            $display("  ✅ PASS: Decrypted text matches original plaintext!");
            pass_count = pass_count + 1;
        end else begin
            $display("  ❌ FAIL: Decrypted text DOES NOT match original plaintext!");
            $display("    Original:  %h", original_plaintext);
            $display("    Final:     %h", final_plaintext);
        end

        // --- Final Summary ---
        $display("\n========================================");
        $display("              Test Summary              ");
        $display("========================================");
        $display("Total Tests Run: 1");
        $display("Tests Passed:    %0d", pass_count);
        $display("Tests Failed:    %0d", 1 - pass_count);
        if (pass_count == 1) begin
            $display("*** ALL TESTS PASSED! ***");
        end else begin
            $display("!!! SOME TESTS FAILED !!!");
        end
        $display("========================================");

        $finish;
    end

    // Safety timeout for the entire simulation
    initial begin
        #1000000; // 1 million time units
        $display("SIMULATION TIMEOUT - Test took too long!");
        $finish;
    end

endmodule
