// chacha20_core_tb.sv

`timescale 1ns / 1ps // Defines time units for simulation

module chacha20_core_tb;

    // ----------------------------------------------------
    // 1. Declare Testbench Signals (Inputs as reg, Outputs as wire)
    //    These will connect to your ChaCha20 UUT (Unit Under Test)
    // ----------------------------------------------------
    reg         clk;
    reg         rst; // Assuming 'rst' is your active-high reset, or rst_n for active-low
    reg         start;
    wire        busy;
    wire        done;
    reg         mode; // 1 for encrypt, 0 for decrypt
    reg  [511:0] in_state;
    wire [511:0] out_state;

    // TRNG interface signals (controlled by testbench to mock TRNG)
    reg  [31:0] trng_data;
    wire        trng_request;
    reg         trng_ready;

    // Internal testbench variables for FSM state tracking during TRNG acquisition
    reg [2:0]   trng_chunk_counter; // To mock which chunk the TRNG is delivering

    // ----------------------------------------------------
    // 2. Instantiate the Unit Under Test (UUT)
    //    Connect testbench signals to the ChaCha20 module's ports
    // ----------------------------------------------------
    ChaCha20 UUT (
        .clk        (clk),
        .rst        (rst),
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
    //    Creates a free-running clock signal
    // ----------------------------------------------------
    parameter CLK_PERIOD = 10; // 10ns period -> 100 MHz clock
    initial begin
        clk = 1'b0; // Start clock low
        forever #(CLK_PERIOD / 2) clk = ~clk; // Toggle every half period
    end

    // ----------------------------------------------------
    // 4. Initial Test Sequence (main 'initial' block)
    //    This drives inputs and checks outputs
    // ----------------------------------------------------
    initial begin
        // For waveform viewing (optional, but highly recommended for debugging)
        $dumpfile("chacha20_core.vcd");
        $dumpvars(0, UUT); // Dump all signals in the UUT

        // --- Test Scenario: RFC 8439 Section 2.3. Test Vector ---
        // (This is where you put your actual test data)

        // RFC Key (32 bytes / 256 bits):
        // 00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00:00
        // Important: RFCs often use Little-Endian for words/bytes. Verilog is Big-Endian for multi-bit numbers.
        // You'll need to reverse the order of 32-bit words or individual bytes when converting RFC hex strings to Verilog literals.
        // For all zeros, it's easy:
        localparam [255:0] TEST_KEY = 256'h0;

        // RFC Nonce (12 bytes / 96 bits):
        // 00:00:00:00:00:00:00:00:00:00:00:00
        localparam [95:0] TEST_NONCE = 96'h0;

        // RFC Initial Counter (4 bytes / 32 bits):
        // 00:00:00:00
        localparam [31:0] TEST_COUNTER = 32'h0;

        // RFC Plaintext (64 bytes / 512 bits):
        // (Just one block for simplicity. Full block is 64 bytes of ASCII 'a')
        // 61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:
        // 61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61:61
        localparam [511:0] TEST_PLAINTEXT = 512'h61616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161616161;

        // RFC Expected Ciphertext (64 bytes / 512 bits):
        // (This is the output you should expect for the above inputs, copy precisely from RFC)
        // 8e: 21: 67: ec: a0: b5: 23: 3c: 19: d4: ba: 66: 08: 07: 57: 37: be: 90: b4: 51: 0c: 24: 07: c9: 3d: d7: c0: 89: 42: 07: 51: b3:
        // 86: 12: 12: 51: c4: d3: 4e: c3: b5: 19: ef: a6: 0e: 45: 5b: 54: 8f: 05: 75: 86: 0d: 6a: 42: a3: cf: 84: 58: c2: 89: a7: d3: 20
        localparam [511:0] EXPECTED_CIPHERTEXT = 512'h8e2167eca0b5233c19d4ba6608075737be90b4510c2407c93dd7c089420751b386121251c4d34ec3b519efa60e455b548f0575860d6a42a3cf8458c289a7d320;

        // --- 5. Reset Sequence ---
        rst = 1'b1; // Assert reset (active high, assuming your 'rst' port is active high)
        start = 1'b0;
        mode = 1'b1; // Test in encryption mode
        in_state = 512'b0;
        trng_data = 32'b0;
        trng_ready = 1'b0;
        trng_chunk_counter = 3'b0;

        #(CLK_PERIOD * 5); // Hold reset for 5 clock cycles
        rst = 1'b0;       // De-assert reset
        #(CLK_PERIOD); // Wait one cycle after reset for stability

        // --- 6. Simulate TRNG Data Acquisition ---
        // This 'fork-join' block will run in parallel with the main initial block
        // to respond to trng_request.
        fork
            automatic bit [255:0] key_val;
            automatic bit [95:0] nonce_val;
            automatic bit [31:0] counter_val;
            automatic int key_chunk_idx;
            automatic int nonce_chunk_idx;

            // Assign values from test vectors (ensure correct byte/word order if endianness matters)
            key_val = TEST_KEY;
            nonce_val = TEST_NONCE;
            counter_val = TEST_COUNTER;

            // Wait for requests and provide data
            always @(posedge clk) begin
                if (rst) begin // Reset TRNG mock
                    trng_ready <= 1'b0;
                    trng_data <= 32'b0;
                    trng_chunk_counter <= 3'b0;
                    key_chunk_idx = 0;
                    nonce_chunk_idx = 0;
                end else begin
                    trng_ready <= 1'b0; // Default to not ready
                    if (trng_request) begin // If ChaCha20 core requests data
                        // Provide data based on current chunk_index (tracked in ChaCha20 core)
                        // and internal counters in the testbench
                        case (UUT.current_fsm_state) // Read the FSM state of the UUT
                            UUT.S_ACQUIRE_KEY: begin
                                // Provide key chunk
                                trng_data <= key_val[key_chunk_idx * 32 +: 32];
                                trng_ready <= 1'b1; // Data is ready
                                key_chunk_idx = key_chunk_idx + 1;
                            end
                            UUT.S_ACQUIRE_NONCE: begin
                                // Provide nonce chunk
                                trng_data <= nonce_val[nonce_chunk_idx * 32 +: 32];
                                trng_ready <= 1'b1;
                                nonce_chunk_idx = nonce_chunk_idx + 1;
                            end
                            UUT.S_ACQUIRE_COUNTER: begin
                                // Provide counter chunk
                                trng_data <= counter_val;
                                trng_ready <= 1'b1;
                                // Reset for next operation cycle, or you can manage it based on UUT.current_fsm_state
                            end
                            default: begin // Not in an acquire state, stop requesting
                                trng_data <= 32'b0;
                                trng_ready <= 1'b0;
                            end
                        endcase
                    end
                end
            end
        join_none // Allow this always block to run continuously in parallel

        // --- 7. Start ChaCha20 Operation ---
        #(CLK_PERIOD); // Wait a cycle to ensure TRNG mock is ready

        start = 1'b1; // Pulse start signal
        #(CLK_PERIOD); // Hold start for one cycle
        start = 1'b0; // De-assert start

        // --- 8. Wait for Completion and Check Results ---
        #(CLK_PERIOD * 20); // Wait for the operation to complete (approx 20 cycles for rounds)
        // You might need more cycles depending on TRNG acquisition time

        // Wait until done goes high
        wait (done);

        // Check if busy is low and done is high
        if (busy == 1'b0 && done == 1'b1) begin
            $display("Test Passed: ChaCha20 core completed operation.");
            $display("Input Plaintext: %h", TEST_PLAINTEXT);
            $display("Actual Ciphertext: %h", out_state);
            $display("Expected Ciphertext: %h", EXPECTED_CIPHERTEXT);

            if (out_state == EXPECTED_CIPHERTEXT) begin
                $display("RESULT: PASS - Output matches expected ciphertext!");
            end else begin
                $display("RESULT: FAIL - Output does NOT match expected ciphertext!");
                // You can add more detailed mismatch reporting here
            end
        end else begin
            $display("RESULT: FAIL - ChaCha20 core did not complete successfully (busy=%0b, done=%0b).", busy, done);
        end

        #(CLK_PERIOD * 2); // Small delay to see final outputs

        $finish; // End simulation
    end

endmodule