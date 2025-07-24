`timescale 1ns / 1ps

// ChaCha20 RFC 8439 Testbench: Checks output against RFC reference keystream block
module tb_ChaCha20_rfc;

    // Signal Declarations
    reg clk;
    reg rst_n;
    reg start;
    reg [255:0] in_key;
    reg [95:0]  in_nonce;
    reg [31:0]  in_counter;
    reg [511:0] in_state;
    reg [511:0] expected_out_state;

    wire busy;
    wire done;
    wire [511:0] out_state;

    // Wires for debug ports (optional)
    wire [511:0] debug_s;
    wire [511:0] debug_s_col_out;
    wire [511:0] debug_s_round_result;
    wire [3:0]   debug_fsm_state;
    wire [4:0]   debug_round_count;
    wire         debug_is_col_round;

    // DUT Instantiation using named port connection for clarity
    ChaCha20 UUT (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .busy(busy),
        .done(done),
        .in_key(in_key),
        .in_nonce(in_nonce),
        .in_counter(in_counter),
        .in_state(in_state),
        .out_state(out_state),
        .debug_s(debug_s),
        .debug_s_col_out(debug_s_col_out),
        .debug_s_round_result(debug_s_round_result),
        .debug_fsm_state(debug_fsm_state),
        .debug_round_count(debug_round_count),
        .debug_is_col_round(debug_is_col_round)
    );

    // Clock Generator
    always #5 clk = ~clk;

    initial begin
        $display("STARTING ChaCha20 RFC 8439 TEST");
        $dumpfile("chacha20_rfc_tb.vcd");
        $dumpvars(0, tb_ChaCha20_rfc);

        // Initialize signals & load RFC test vectors
        clk = 0;
        rst_n = 1;
        start = 0;
        in_state = 512'h0;

        in_key     = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
        in_nonce   =  96'h000000000000004a00000000;
        in_counter =  32'h00000001;

        // RFC 8439 (Section 2.3.2) keystream, little-endian 32-bit words, packed big-endian for Verilog
        expected_out_state = 512'he4e7f11015593bd11fdd0f50c47120a336d6d0c72a083ed088090e429bcbe63bc5f2528343475fb479e94820f5e13100207f8fc891ca406348de53841cc5de62;

        // Reset the core
        rst_n = 0; #20; rst_n = 1; #10;

        // Start the operation
        start = 1; #10; start = 0;

        // Wait for completion
        wait (done);
        #10; // Allow final output to settle

        // Display and compare result
        $display("\n---------------------- FINAL STATE COMPARISON ----------------------");
        $display("DUT Output:      %h", out_state);
        $display("Expected Output: %h", expected_out_state);
        $display("--------------------------------------------------------------------\n");

        if (out_state === expected_out_state) begin
            $display("********************************************************************");
            $display("** SUCCESS: Core output perfectly matches RFC 8439 vector.        **");
            $display("********************************************************************");
        end else begin
            $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            $display("!!   FAILURE: Core output DOES NOT match RFC 8439 vector.         !!");
            $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
        end

        $finish;
    end

endmodule