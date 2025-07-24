`timescale 1ns / 1ps

// Testbench for ChaCha20 Core: Encryption followed by Decryption
module tb_ChaCha20;

    // Signal Declarations
    reg clk;
    reg rst_n;
    reg start;
    reg [255:0] in_key;
    reg [95:0]  in_nonce;
    reg [31:0]  in_counter;
    reg [511:0] in_state_encrypt;  // Original plaintext input for encryption
    reg [511:0] in_state_decrypt;  // Ciphertext input for decryption

    wire busy_encrypt;
    wire done_encrypt;
    wire [511:0] out_state_encrypt; // Ciphertext output from encryption
    wire [511:0] keystream_encrypt; // Internal keystream for verification

    wire busy_decrypt;
    wire done_decrypt;
    wire [511:0] out_state_decrypt; // Plaintext output from decryption

    // Wires for debug ports (optional but helpful)
    wire [511:0] debug_s_enc;
    wire [511:0] debug_s_col_out_enc;
    wire [511:0] debug_s_round_result_enc;
    wire [3:0]   debug_fsm_state_enc;
    wire [4:0]   debug_round_count_enc;
    wire         debug_is_col_round_enc;

    wire [511:0] debug_s_dec;
    wire [511:0] debug_s_col_out_dec;
    wire [511:0] debug_s_round_result_dec;
    wire [3:0]   debug_fsm_state_dec;
    wire [4:0]   debug_round_count_dec;
    wire         debug_is_col_round_dec;

    // --- DUT Instantiation for Encryption ---
    ChaCha20 UUT_ENCRYPT (
        .clk(clk),
        .rst_n(rst_n),
        .start(start), // Use same start for both, will sequence manually
        .busy(busy_encrypt),
        .done(done_encrypt),
        .in_key(in_key),
        .in_nonce(in_nonce),
        .in_counter(in_counter),
        .in_state(in_state_encrypt), // Plaintext input
        .out_state(out_state_encrypt), // Ciphertext output

        // Debug ports (rename to avoid clashes)
        .debug_s(debug_s_enc),
        .debug_s_col_out(debug_s_col_out_enc),
        .debug_s_round_result(debug_s_round_result_enc),
        .debug_fsm_state(debug_fsm_state_enc),
        .debug_round_count(debug_round_count_enc),
        .debug_is_col_round(debug_is_col_round_enc)
    );

    // --- DUT Instantiation for Decryption ---
    ChaCha20 UUT_DECRYPT (
        .clk(clk),
        .rst_n(rst_n),
        .start(start_decrypt_signal), // Separate start signal for decryption phase
        .busy(busy_decrypt),
        .done(done_decrypt),
        .in_key(in_key),          // Use same key
        .in_nonce(in_nonce),      // Use same nonce
        .in_counter(in_counter),  // Use same counter
        .in_state(in_state_decrypt), // Ciphertext input from encryption
        .out_state(out_state_decrypt), // Decrypted plaintext output

        // Debug ports (rename to avoid clashes)
        .debug_s(debug_s_dec),
        .debug_s_col_out(debug_s_col_out_dec),
        .debug_s_round_result(debug_s_round_result_dec),
        .debug_fsm_state(debug_fsm_state_dec),
        .debug_round_count(debug_round_count_dec),
        .debug_is_col_round(debug_is_col_round_dec)
    );

    // Separate start signal for decryption (controlled manually)
    reg start_decrypt_signal;

    // Clock Generator
    always #5 clk = ~clk;

    // Main Test Sequence
    initial begin
        $display("STARTING ChaCha20 ENCRYPTION-DECRYPTION CYCLE TEST");
        $dumpfile("chacha20_cycle_tb.vcd");
        $dumpvars(0, tb_ChaCha20);

        // Initialize signals
        clk = 0;
        rst_n = 1;
        start = 0;
        start_decrypt_signal = 0;
        in_state_encrypt = 512'h0; // Initial plaintext (can be anything, e.g., all zeros)
        in_state_decrypt = 512'h0; // Initialize, will be loaded with ciphertext

        // Use RFC 8439 example inputs for Key, Nonce, Counter
        in_key      = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
        in_nonce    =  96'h000000000000004a00000000;
        in_counter  =  32'h00000001;

        // Set a non-zero plaintext input for encryption
        // This is 64 bytes of sample data (ASCII 'A' through 'D', repeated)
        in_state_encrypt = 512'h444342414443424144434241444342414443424144434241444342414443424144434241444342414443424144434241444342414443424144434241;

        // Reset the core
        rst_n = 0; #20; rst_n = 1; #10;

        $display("\n--- ENCRYPTION PHASE ---");
        // Start Encryption operation
        start = 1; #10; start = 0;

        // Wait for encryption to complete
        wait (done_encrypt);
        #10; // Allow final output to settle

        $display("Encryption Done.");
        $display("Original Plaintext: %h", in_state_encrypt);
        $display("Ciphertext Output:  %h", out_state_encrypt);

        // --- DECRYPTION PHASE ---
        $display("\n--- DECRYPTION PHASE ---");
        // Load the ciphertext from encryption as input for decryption
        in_state_decrypt = out_state_encrypt;

        // Start Decryption operation (using a separate start signal)
        start_decrypt_signal = 1; #10; start_decrypt_signal = 0;

        // Wait for decryption to complete
        wait (done_decrypt);
        #10; // Allow final output to settle

        $display("Decryption Done.");
        $display("Ciphertext Input:   %h", in_state_decrypt);
        $display("Decrypted Output:   %h", out_state_decrypt);

        // --- VERIFICATION ---
        $display("\n---------------------- FINAL VERIFICATION ----------------------");
        $display("Original Plaintext: %h", in_state_encrypt);
        $display("Decrypted Output:   %h", out_state_decrypt);
        $display("----------------------------------------------------------------\n");

        if (out_state_decrypt === in_state_encrypt) begin
            $display("********************************************************************");
            $display("** SUCCESS: Decryption matches original plaintext. Cycle complete!**");
            $display("********************************************************************");
        end else begin
            $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            $display("!!   FAILURE: Decryption DOES NOT match original plaintext.       !!");
            $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        end

        $finish;
    end

endmodule