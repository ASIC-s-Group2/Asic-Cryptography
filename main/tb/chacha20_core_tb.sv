// Testbench for the ChaCha20 Core
// ---------------------------------
// This testbench is designed to work with Icarus Verilog.
// It initializes the ChaCha20 module with the official RFC 8439 test vector
// and verifies the output for compliance.

`timescale 1ns / 1ps

module tb_ChaCha20;

    // Testbench Registers for ChaCha20 Inputs
    reg clk;
    reg rst_n;
    reg start;
    reg [255:0] in_key;
    reg [95:0]  in_nonce;
    reg [31:0]  in_counter;
    reg [511:0] in_state;
    reg [511:0] expected_out_state; // To hold the known-correct output

    // Wires for ChaCha20 Outputs
    wire busy;
    wire done;
    wire [511:0] out_state;

    // Wires for Debugging
    wire [511:0] debug_s;
    wire [511:0] debug_s_col_out;
    wire [511:0] debug_s_round_result;

    // Instantiate the Unit Under Test (UUT)
    // Make sure your ChaCha20 module file is included in the compilation command.
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
        .debug_s_round_result(debug_s_round_result)
    );

    // Clock Generation
    // Generate a 100MHz clock (10ns period)
    always #5 clk = ~clk;

    // Main Test Sequence
    initial begin
        // --- Initialization ---
        $display("--------------------------------------------------");
        $display("--- ChaCha20 RFC 8439 Testbench Starting ---");
        $display("--------------------------------------------------");

        // Set up waveform dumping
        $dumpfile("chacha20_rfc_tb.vcd");
        $dumpvars(0, tb_ChaCha20);

        // Initialize with RFC 8439 Section 2.4.2 Test Vector
        clk = 0;
        rst_n = 1;
        start = 0;
        in_key     = 256'h000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f;
        in_nonce   =  96'h000000090000004a00000000;
        in_counter =  32'h00000001;
        in_state   = 512'h0; // Plaintext is all zeros for keystream generation

        // Expected output keystream block from the RFC
        expected_out_state = 512'h10f1e7e4d13b5915500fdd1fa32071c4c7d0d636d03e082a420e09883be6cb9b8352f2c5b45f47432048e979f5e13100c88f7f2063ca40918453de4862dec51c;

        // --- Reset Pulse ---
        $display("Applying reset...");
        rst_n = 0;
        #20; // Hold reset for 2 clock cycles
        rst_n = 1;
        #10;
        $display("Reset released.");

        // --- Start the Encryption ---
        $display("Asserting 'start' to begin ChaCha20 operation.");
        start = 1;
        #10;
        start = 0; // 'start' is a single-cycle pulse

        // --- Wait for Completion ---
        $display("Waiting for 'busy' to go high...");
        wait (busy);
        $display("'busy' is now high. ChaCha20 core is processing.");

        $display("Waiting for 'done' signal...");
        wait (done);
        $display("'done' signal received. ChaCha20 operation complete.");

        // --- Display and Verify Results ---
        #10; // Allow one cycle for the final output to settle
        $display("\n----------------- RESULTS -----------------");
        $display("Input Key: \t\t%h", in_key);
        $display("Input Nonce: \t\t%h", in_nonce);
        $display("Input Counter: \t%h", in_counter);
        $display("Output State: \t\t%h", out_state);
        $display("Expected State: \t%h", expected_out_state);
        $display("-------------------------------------------\n");

        // --- Verification Check ---
        if (out_state === expected_out_state) begin
            $display("SUCCESS: Output matches the RFC 8439 test vector!");
        end else begin
            $display("FAILURE: Output does NOT match the RFC 8439 test vector.");
        end

        // --- Finish Simulation ---
        $display("Simulation finished.");
        $finish;
    end

endmodule
