`timescale 1ns / 1ps

module tb_chacha20_system;

    // --- Test Bench Signals ---
    reg clk;
    reg rst_n;

    // Dummy signal to simulate TRNG's raw entropy output
    reg raw_entropy_mock;

    // Wires to connect to the DUT's outputs
    wire chacha20_ready_o;
    wire key_loading_done_o;

    // Internal signals for monitoring the key loader and ChaCha20 core behavior
    // We'll peek inside the DUT (if allowed by tool/synthesis directives)
    // For proper black-box testing, you'd only check the top-level outputs.
    // But for debugging, it's useful to see internal signals.
    wire trng_request_internal;
    wire [31:0] trng_random_number_internal;
    wire trng_ready_internal;
    wire key_write_enable_internal;
    wire [2:0] key_index_internal;
    wire [31:0] chacha20_key_word_internal;
    wire key_ready_loader_internal;
    wire [31:0] chacha20_core_key_reg_0_internal; // Monitor a specific key register

    // --- Parameters for Simulation ---
    parameter CLK_PERIOD = 10; // 10ns for 100 MHz clock

    // --- Instantiate the Design Under Test (DUT) ---
    chacha20_system but (
        .clk(clk),
        .rst_n(rst_n),
        .chacha20_ready(chacha20_ready_o),
        .key_loading_done(key_loading_done_o)
    );

    // --- Connect internal signals for monitoring (for debugging) ---
    // These require knowledge of the DUT's internal hierarchy.
    // Replace `dut.u_trng.ring_oscillator_output` if your RingOsc is instantiated differently
    // Or, if your TRNG is simple, you could just drive `dut.u_trng.ring_oscillator_output` directly.
    // In this setup, TRNG's RingOsc #(.CW(4)) ring_oscillator is an instance.
    // We'll directly drive the wire `dut.u_trng.ring_oscillator_output` from the testbench.
    // NOTE: This might lead to warnings about multiple drivers if TRNG also drives it.
    // A better approach for the TRNG would be to make `RAW_ENTROPY_OUT` an input to `TRNG` module for simulation.
    // For simplicity here, I'll simulate a dummy `RingOsc` and connect its output to the TRNG input.

    // Let's create a simplified dummy RingOsc model for the testbench
    // This `RingOsc` module will only be instantiated in the testbench to simulate the real one.
    // The `TRNG` module itself would then take `RAW_ENTROPY_OUT` as an input from this dummy.

    // For now, let's assume `TRNG`'s `ring_oscillator_output` is its own internal wire,
    // and we cannot directly drive it from the testbench without modifying the TRNG.
    // A common solution is to add `ifdef` for simulation or make it an input for TB purposes.
    // Since TRNG instantiation `RingOsc #(.CW(4)) ring_oscillator` is internal,
    // the cleanest way is to create a *dummy* `RingOsc` module that generates simple changing data.

    // Let's adapt the TRNG module to accept an external entropy source for testing
    // or provide a simple `RingOsc` dummy module.

    // Option 1: Modify TRNG to accept simulated entropy
    // This is the cleanest:
    // In TRNG module: `input wire mock_raw_entropy; // Add this port`
    // And in TRNG: `assign ring_oscillator_output = mock_raw_entropy; // Or use it in `shift_reg` line`
    // OR if we don't want to modify TRNG:

    // Option 2: Define a simple mock RingOsc in the testbench to connect to TRNG's input
    // This would require the `TRNG` module to have an input for `RAW_ENTROPY_OUT`.
    // Since `RAW_ENTROPY_OUT` is currently an output of an internal `RingOsc` instance
    // within the `TRNG` module, we cannot directly inject entropy from the test bench
    // without modifying the `TRNG` module or adding a way to override its internal `RingOsc`.

    // For this test bench, I'll assume you will *modify* the `TRNG` module slightly
    // to allow a simulated entropy input for testing purposes.
    // If not, the test bench cannot provide "randomness" to your TRNG.

    // *** IMPORTANT MODIFICATION TO TRNG MODULE FOR TEST BENCHING ***
    // Please update your TRNG module as follows for proper test benching:
    /*
    module TRNG (
        input wire clk,
        input wire rst_n,
        input wire trng_request,
        input wire raw_entropy_in, // <<< ADD THIS INPUT FOR SIMULATION
        output wire [31:0] random_number,
        output wire ready
    );
        // Original RingOsc instantiation (keep for synthesis, but won't be used in this TB setup)
        RingOsc #(.CW(4)) ring_oscillator (
            .RESET(~rst_n),
            .RAW_ENTROPY_OUT() // Unconnected in simulation for this setup or connect to internal wire
        );

        // Connect the shift register to either real TRNG output OR simulation input
        wire entropy_source = raw_entropy_in; // Use the input for simulation

        reg [31:0] shift_reg = 32'b0;
        reg[5:0] bit_count = 6'b0;

        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                shift_reg <= 32'b0;
                bit_count <= 6'b0;
                random_number <= 32'b0; // This should be reg, as it's an output reg
                ready <= 1'b0;
            end else begin
                if (trng_request & ~ready) begin // Only shift if requested and not already ready
                    shift_reg <= {shift_reg[30:0], entropy_source};
                    bit_count <= bit_count + 1;
                    if (bit_count == 31) begin // After collecting 32 bits (0 to 31)
                        random_number <= {shift_reg[30:0], entropy_source}; // Final bit collection
                        ready <= 1'b1;
                    end
                end else if (!trng_request && ready) begin // Reset when trng_request goes low AND we were ready
                    ready <= 1'b0;
                    bit_count <= 6'b0;
                    shift_reg <= 32'b0;
                end
            end
        end
    endmodule
    */
    // Assuming TRNG has been modified to accept `raw_entropy_in`
    // And assuming chacha20_keyinput also exposes `core_ready` as an output `ready`.

    // Connect mock_raw_entropy to the TRNG input
    // The `TRNG` instance inside `chacha20_system` is `dut.u_trng`.
    // So, we need to pass `raw_entropy_mock` to `dut.u_trng.raw_entropy_in`.
    // For this to work, `raw_entropy_in` needs to be added to `TRNG`'s port list.
    // If you add it, the instantiation in `chacha20_system` for `TRNG` will need `raw_entropy_in(raw_entropy_mock_internal_wire)`.
    // It becomes a bit circular. The cleanest way is often to modify the `TRNG` module temporarily for simulation:
    // Either by adding a direct `raw_entropy_in` to the TRNG module's ports,
    // or by making the `RingOsc` instantiation `ifdef SIMULATION` and providing a direct `assign`.

    // Let's just drive the TRNG's `trng_bit` directly in the testbench with random data,
    // and skip simulating `TRNG`'s internal bits collection for simplicity,
    // as the main goal is to test the key loader and ChaCha20 interface.
    // This simplifies the TRNG-key_loader interface in the testbench.

    // --- Direct TRNG simulation within Test Bench (simpler for this case) ---
    // Instead of instantiating the full TRNG, we'll model its `trng_bit` and `trng_ready` directly
    // and provide `trng_request` to the key loader from the DUT.

    // This means we remove the TRNG instance from the `chacha20_system` and manage its interface directly here.
    // NO, let's keep the `TRNG` module as is and provide its `trng_request` and read its `trng_ready` and `random_number`.
    // The TRNG module needs a source of entropy. For simulation, we need to provide `raw_entropy_in` to `TRNG`.

    // Let's assume you've modified `TRNG` to include `input wire raw_entropy_in`.
    // If so, then your `chacha20_system` instantiation of `TRNG` should look like:
    /*
    TRNG u_trng (
        .clk(clk),
        .rst_n(rst_n),
        .trng_request(trng_request_w),
        .raw_entropy_in(raw_entropy_mock), // Connect to the testbench's mock entropy
        .random_number(trng_random_number_w),
        .ready(trng_ready_w)
    );
    */

    // For the testbench to work with your provided `TRNG` as-is, we have to
    // either directly modify the `TRNG` module's internal `RingOsc` or create a dummy `RingOsc`
    // within the test bench and connect its output directly to the `TRNG`'s internal `ring_oscillator_output`.
    // This is generally bad practice (reaching into DUT's internal wires).

    // **BEST APPROACH:** Modify your `TRNG` module to accept `raw_entropy_in`.
    // I will assume this modification has been made to your `TRNG` module for the testbench.

    // ------------------------------------------------------------------------------------------------------
    // Start of actual Test Bench code (assuming TRNG is modified to have `input wire raw_entropy_in`)
    // ------------------------------------------------------------------------------------------------------

    // Instantiation of the system
    // (This `u_trng` instantiation will be inside `chacha20_system`)
    // So, in the `chacha20_system` module, modify `u_trng` instantiation like this:
    /*
    // Inside chacha20_system module
    input wire mock_raw_entropy; // Add this to chacha20_system ports for the testbench to drive

    // ...
    TRNG u_trng (
        .clk(clk),
        .rst_n(rst_n),
        .trng_request(trng_request_w),
        .raw_entropy_in(mock_raw_entropy), // Connect to the new system input
        .random_number(trng_random_number_w),
        .ready(trng_ready_w)
    );
    */

    // Now, the `chacha20_system` module has a `mock_raw_entropy` input.
    // Update `chacha20_system` module definition accordingly:
    /*
    module chacha20_system (
        input wire clk,
        input wire rst_n,
        input wire mock_raw_entropy, // Add this input!
        output wire chacha20_ready,
        output wire key_loading_done
    );
    */

    // Now, back to the test bench:
    chacha20_system dut (
        .clk(clk),
        .rst_n(rst_n),
        .mock_raw_entropy(raw_entropy_mock), // Connect the TB's mock entropy
        .chacha20_ready(chacha20_ready_o),
        .key_loading_done(key_loading_done_o)
    );

    // --- Clock Generation ---
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // --- Reset Sequence ---
    initial begin
        rst_n = 0; // Assert reset
        #(CLK_PERIOD * 2); // Hold reset for a few clock cycles
        rst_n = 1; // De-assert reset
    end

    // --- Simulate TRNG Raw Entropy ---
    // This will generate a new "random" bit on every positive edge of clk.
    // In a real scenario, this would be unpredictable.
    // For simulation, we want a *deterministic* sequence for reproducibility.
    initial begin
        raw_entropy_mock = 1'b0; // Initial value
        forever @(posedge clk) begin
            raw_entropy_mock = $random % 2; // Generates a 0 or 1 randomly
            // For a more structured test, you might use a counter or predefined sequence
            // raw_entropy_mock = ~raw_entropy_mock; // Simple alternating pattern
        end
    end

    // --- Test Scenario ---
    initial begin
        $display("Starting ChaCha20 System Test Bench...");
        $dumpfile("chacha20_system.vcd"); // For waveform viewing
        $dumpvars(0, tb_chacha20_system); // Dump all signals

        // Wait for reset to finish
        @(negedge rst_n); // Wait until reset is de-asserted

        $display("Reset complete. Initiating key loading sequence.");

        // Monitor key loading progress
        @(posedge key_loading_done_o);
        $display("Key loading reported as DONE by key_loader at time %0t", $time);

        // Verify the key_transfer_state in the top_level
        @(posedge dut.key_transfer_state == dut.KEY_TRANSFER_DONE);
        $display("Key transfer to chacha20_keyinput FSM is DONE at time %0t", $time);

        // At this point, the 256-bit key should be loaded into `u_chacha20_core.key_reg`.
        // You can add more detailed checks here, e.g., using $monitor or $strobe.
        // Example: Display contents of key registers in chacha20_keyinput
        $display("--- Final Key in ChaCha20 Core (u_chacha20_core.key_reg): ---");
        for (int i = 0; i < 8; i = i + 1) begin
            $display("key_reg[%0d] = 0x%h", i, dut.u_chacha20_core.key_reg[i]);
        end
        $display("---------------------------------------------------------");

        // Now, you could add logic to:
        // 1. Load the IV (by driving chacha20_cs, we, addr=0x20/0x21, write_data)
        // 2. Load input data (by driving chacha20_cs, we, addr=0x40-0x4F, write_data)
        // 3. Initiate the ChaCha20 core (by driving chacha20_cs, we, addr=0x08, write_data with init bit set)
        // 4. Wait for chacha20_ready_o and data_out_valid.
        // 5. Read output data.

        // Example: Initiate ChaCha20 core after key loading (simplified, just a direct write)
        // In a real system, this would be part of a larger control FSM.
        #(CLK_PERIOD); // Wait one cycle after key transfer done
        $display("Attempting to initialize ChaCha20 core...");
        dut.chacha20_cs <= 1'b1;
        dut.chacha20_we <= 1'b1;
        dut.chacha20_addr <= dut.u_chacha20_core.ADDR_CTRL; // Address of control register
        dut.chacha20_write_data <= (1 << dut.u_chacha20_core.CTRL_INIT_BIT); // Set INIT bit

        #(CLK_PERIOD); // Pulse for one cycle
        dut.chacha20_cs <= 1'b0;
        dut.chacha20_we <= 1'b0;
        dut.chacha20_write_data <= 32'h0;
        dut.chacha20_addr <= 8'h00; // Return to default

        $display("ChaCha20 Init signal pulsed.");

        // Wait for the ChaCha20 core to become ready again (after processing a block)
        // This assumes `chacha20_keyinput` exposes its `ready` output.
        // If not, you might need to monitor `u_chacha20_core.core_ready` directly (requires SystemVerilog or hierarchy access).
        @(posedge chacha20_ready_o);
        $display("ChaCha20 core reported READY at time %0t", $time);


        #(CLK_PERIOD * 100); // Let simulation run for a bit more
        $display("Test bench finished at time %0t", $time);
        $finish; // End simulation
    end

    // You can add more initial blocks for specific sequences or
    // use an `always` block for more complex control logic.

    // Optional: Monitoring internal signals (useful for debug, requires access to hierarchy)
    initial begin
        $monitor("Time: %0t | key_loader_state: %d | key_transfer_state: %d | key_idx: %d | key_we: %b | chacha_key_word: %h | key_loader_ready: %b | TRNG_req: %b | TRNG_ready: %b | TRNG_rand: %h",
                 $time,
                 dut.u_key_loader.state,
                 dut.key_transfer_state,
                 dut.key_index_w,
                 dut.key_write_enable_w,
                 dut.chacha20_key_word_w,
                 dut.key_ready_loader_w,
                 dut.trng_request_w,
                 dut.trng_ready_w,
                 dut.trng_random_number_w);
    end

endmodule