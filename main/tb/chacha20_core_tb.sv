<<<<<<< HEAD
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
=======

// chacha20_core_tb.sv
// Testbench for the ChaCha20 core module.
// Verifies functionality against RFC 8439 Section 2.3 test vector.

`timescale 1ns / 1ps // Defines time units for simulation

module chacha20_core_tb;

    // ----------------------------------------------------
    // 1. Declare Testbench Signals (Inputs as reg, Outputs as wire)
    //    These simulate the external world connected to your ChaCha20 UUT.
    // ----------------------------------------------------
    reg         clk;
    reg         rst_n; // Active-low reset input
    reg         start; // Start pulse for the UUT
    wire        busy;  // UUT busy status
    wire        done;  // UUT completion signal
    reg         mode;  // Operation mode (1: encrypt, 0: decrypt)
    reg  [511:0] in_state; // Data block input (plaintext for encrypt)
    wire [511:0] out_state; // Data block output (ciphertext from encrypt)

    // TRNG interface signals (controlled by testbench to mock TRNG behavior)
    reg  [31:0] trng_data;    // Data provided by TRNG mock to UUT
    wire        trng_request; // Request from UUT to TRNG mock
    reg         trng_ready;   // Ready signal from TRNG mock to UUT

    // ----------------------------------------------------
    // 2. Instantiate the Unit Under Test (UUT)
    //    Connect testbench signals to the ChaCha20 module's ports.
    // ----------------------------------------------------
    ChaCha20 UUT (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .busy       (busy),
        .done       (done),
        .mode       (mode),
        .in_state   (in_state),
        .out_state  (out_state),
        .trng_data  (trng_data),
        .trng_request(trng_request),
        .trng_ready (trng_ready)
    );

    // ----------------------------------------------------
    // 3. Clock Generation
    //    Creates a free-running clock signal.
    // ----------------------------------------------------
    parameter CLK_PERIOD = 10; // 10ns period -> 100 MHz clock
    initial begin
        clk = 1'b0; // Start clock low
        forever #(CLK_PERIOD / 2) clk = ~clk; // Toggle every half period
    end

    // ----------------------------------------------------
    // 4. Test Vector Data (from RFC 8439 Section 2.3)
    //    Important: RFCs often use Little-Endian for words/bytes. Verilog is Big-Endian.
    //    For all-zero/all-'a' values, direct hex conversion works fine.
    //    For mixed values, you'd need careful byte/word swapping.
    // ----------------------------------------------------
    localparam [255:0] TEST_KEY       = 256'h0; // All zeros
    localparam [95:0]  TEST_NONCE     = 96'h0;  // All zeros
    localparam [31:0]  TEST_COUNTER   = 32'h0;  // All zeros (for initial counter)

    // Plaintext (64 bytes of ASCII 'a' = 0x61)
    localparam [511:0] TEST_PLAINTEXT = 512'h61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161;

    // Expected Ciphertext for the above Key, Nonce, Counter, Plaintext
    localparam [511:0] EXPECTED_CIPHERTEXT = 512'h8e2167eca0b5233c19d4ba6608075737be90b4510c2407c93dd7c089420751b386121251c4d34ec3b519efa60e455b548f0575860d6a42a3cf8458c289a7d320;

    // Array to hold the TRNG mock data in sequence: 8 key chunks, 3 nonce chunks, 1 counter chunk
    // Total 12 chunks needed
    localparam NUM_KEY_CHUNKS     = 8;
    localparam NUM_NONCE_CHUNKS   = 3;
    localparam NUM_COUNTER_CHUNKS = 1;
    localparam TOTAL_TRNG_CHUNKS  = NUM_KEY_CHUNKS + NUM_NONCE_CHUNKS + NUM_COUNTER_CHUNKS;

    reg [31:0] trng_mock_data_array [0:TOTAL_TRNG_CHUNKS-1]; // Correct array size

    // Initialize the TRNG mock data array with test vector values
    // This runs ONCE at time 0
    initial begin
        // Key chunks (8 chunks)
        trng_mock_data_array[0] = TEST_KEY[31:0];
        trng_mock_data_array[1] = TEST_KEY[63:32];
        trng_mock_data_array[2] = TEST_KEY[95:64];
        trng_mock_data_array[3] = TEST_KEY[127:96];
        trng_mock_data_array[4] = TEST_KEY[159:128];
        trng_mock_data_array[5] = TEST_KEY[191:160];
        trng_mock_data_array[6] = TEST_KEY[223:192];
        trng_mock_data_array[7] = TEST_KEY[255:224];

        // Nonce chunks (3 chunks)
        trng_mock_data_array[8] = TEST_NONCE[31:0];
        trng_mock_data_array[9] = TEST_NONCE[63:32];
        trng_mock_data_array[10] = TEST_NONCE[95:64];

        // Counter chunk (1 chunk)
        trng_mock_data_array[11] = TEST_COUNTER;
    end


    // ----------------------------------------------------
    // 5. TRNG Mocking Logic (responds to UUT's trng_request)
    //    This simulates the TRNG module's behavior.
    // ----------------------------------------------------
    // trng_chunk_index will be driven by UUT.chunk_index; no need for a separate mock index here.
    initial begin
        trng_ready = 1'b0; // Start not ready
        trng_data = 32'b0; // Start with zero data
    end

    always @(posedge clk) begin
        if (rst_n == 1'b0) begin // Reset TRNG mock
            trng_ready <= 1'b0;
            trng_data <= 32'b0;
        end else begin
            trng_ready <= 1'b0; // Default to not ready each cycle
            // Respond only if UUT is requesting and we have a valid chunk_index within its current state
            case (UUT.current_fsm_state)
                UUT.S_ACQUIRE_KEY: begin
                    if (trng_request && UUT.chunk_index < NUM_KEY_CHUNKS) begin
                        trng_data <= trng_mock_data_array[UUT.chunk_index];
                        trng_ready <= 1'b1; // Signal data is ready for this cycle
                    end
                end
                UUT.S_ACQUIRE_NONCE: begin
                    if (trng_request && UUT.chunk_index < NUM_NONCE_CHUNKS) begin
                        trng_data <= trng_mock_data_array[NUM_KEY_CHUNKS + UUT.chunk_index]; // Offset for nonce chunks
                        trng_ready <= 1'b1;
                    end
                end
                UUT.S_ACQUIRE_COUNTER: begin
                    if (trng_request && UUT.chunk_index < NUM_COUNTER_CHUNKS) begin
                        trng_data <= trng_mock_data_array[NUM_KEY_CHUNKS + NUM_NONCE_CHUNKS + UUT.chunk_index]; // Offset for counter chunk
                        trng_ready <= 1'b1;
                    end
                end
                default: begin
                    // Not in an acquire state, stop sending
                    trng_data <= 32'b0;
                end
            endcase
        end
    end


    // ----------------------------------------------------
    // 6. Main Test Sequence
    //    Drives inputs to the UUT and checks outputs.
    // ----------------------------------------------------
    initial begin
        // --- For waveform viewing (highly recommended for debugging) ---
        $dumpfile("chacha20_core.vcd"); // Create the VCD file
        $dumpvars(0, UUT);             // Dump all signals within the UUT
        // You can also dump specific signals from the testbench scope if needed:
        // $dumpvars(0, clk, rst_n, start, busy, done, mode, in_state, out_state, trng_data, trng_request, trng_ready);
        // $dumpvars(0, trng_mock_data_array);


        // --- Reset UUT ---
        rst_n = 1'b0;       // Assert reset (active-low)
        start = 1'b0;
        mode = 1'b1;        // Encryption mode
        in_state = 512'b0;  // Initial input data state

        #(CLK_PERIOD * 5);  // Hold reset for 5 clock cycles (50ns)
        rst_n = 1'b1;       // De-assert reset
        #(CLK_PERIOD);      // Wait one cycle after reset for stability

        // --- Start ChaCha20 Operation ---
        start = 1'b1;              // Pulse start signal
        in_state = TEST_PLAINTEXT; // Provide the plaintext input
        #(CLK_PERIOD);             // Hold start for one cycle (10ns)
        start = 1'b0;              // De-assert start

        // --- Wait for Completion ---
        // Give it plenty of time for acquisition, init, rounds, and output.
        // Approx (12 TRNG chunks + 1 init + 20 rounds + 1 output) = ~34 cycles minimum.
        // We'll wait a generous 50 cycles before checking `done`.

        // The 'wait' will pause the simulation until 'done' goes high.
        // If it hangs here, the UUT is stuck and not signaling 'done'.
        wait (done == 1'b1);

        // --- Check Results ---
        if (busy == 1'b0 && done == 1'b1) begin
            $display("--- Test Completed ---");
            $display("Input Plaintext:   %h", TEST_PLAINTEXT);
            $display("Actual Ciphertext: %h", out_state); // Use out_state directly, not out_state_reg from UUT scope
            $display("Expected Ciphertext: %h", EXPECTED_CIPHERTEXT);

            if (out_state === EXPECTED_CIPHERTEXT) begin // Use '===' for bit-for-bit comparison including X/Z
                $display("RESULT: PASS - Output matches expected ciphertext!");
            end else begin
                $display("RESULT: FAIL - Output does NOT match expected ciphertext!");
            end
        end else begin
            $display("RESULT: FAIL - ChaCha20 core did not complete successfully (busy=%0b, done=%0b).", busy, done);
        end

        #(CLK_PERIOD * 2); // Small delay to see final outputs in waveform before finishing

        $finish; // End simulation
    end

endmodule
>>>>>>> 98faa693bca7a0f129fd58886e73a4a237123516
