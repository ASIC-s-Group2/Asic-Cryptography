module chacha20_system (
    input wire clk,
    input wire rst_n,
    // Add any top-level inputs/outputs you might need for system control or monitoring
    // For example, to initiate encryption, provide input data, read output data.
    // For now, we'll keep it simple for just key loading and ChaCha20 initialization.

    // Example system control/status (you might want more granular control later)
    output wire chacha20_ready, // Indicates the ChaCha20 core is ready
    output wire key_loading_done // Indicates the key has been fully loaded
);

    // --- Internal Wires for Module Connections ---

    // Wires for TRNG
    wire trng_request_w;
    wire [31:0] trng_random_number_w;
    wire trng_ready_w;

    // Wires for chacha20_key_loader
    wire key_write_enable_w;
    wire [2:0] key_index_w;
    wire [31:0] chacha20_key_word_w; // The 32-bit word from key_loader
    wire key_ready_loader_w;         // Indicates key loader has finished

    // Wires for chacha20_keyinput module
    // These signals map to the memory-mapped interface of chacha20_keyinput
    wire chacha20_cs;           // Chip select for ChaCha20 module
    wire chacha20_we;           // Write enable for ChaCha20 module
    wire [7:0] chacha20_addr;   // Address for ChaCha20 registers
    wire [31:0] chacha20_write_data; // Data to write to ChaCha20 module
    wire [31:0] chacha20_read_data;  // Data read from ChaCha20 module

    // Internal signals for ChaCha20 control (init, next)
    reg init_chacha_reg;
    reg next_chacha_reg;

    // Internal state for managing key transfer to chacha20_keyinput
    reg [2:0] key_transfer_state;
    localparam KEY_TRANSFER_IDLE = 3'd0,
               TRANSFERRING_KEY  = 3'd1,
               KEY_TRANSFER_DONE = 3'd2;


    // --- Module Instantiations ---

    // Instantiate the TRNG module
    TRNG u_trng (
        .clk(clk),
        .rst_n(rst_n),
        .trng_request(trng_request_w),
        .raw_entropy_in(mock_raw_entropy), // Connect to a new input lol
        .random_number(trng_random_number_w),
        .ready(trng_ready_w)
    );

    // Instantiate the chacha20_key_loader module
    chacha20_key_loader u_key_loader (
        .clk(clk),
        .rst_n(rst_n),
        .trng_ready(trng_ready_w),
        .trng_bit(trng_random_number_w), // Connect TRNG output to key_loader input
        .trng_request(trng_request_w),   // Connect key_loader request to TRNG input

        .key_write_enable(key_write_enable_w),
        .key_index(key_index_w),
        .chacha20_key(chacha20_key_word_w), // This is the 32-bit word for chacha20_keyinput
        .key_ready(key_ready_loader_w)
    );

    // Instantiate the chacha20_keyinput module
    chacha20_keyinput u_chacha20_core (
        .clk(clk),
        .reset_n(rst_n),
        .cs(chacha20_cs),
        .we(chacha20_we),
        .addr(chacha20_addr),
        .write_data(chacha20_write_data),
        .read_data(chacha20_read_data), // Connect if you plan to read from ChaCha20
        .ready(chacha20_ready) // <<< ADDED: Connect core ready to top-level output
        // Note: You might need to modify the chacha20_keyinput module to include a `ready` output
        // if it doesn't already have one. This is to indicate when the ChaCha20 core is ready for operations.
    );

    // --- Connections and Control Logic ---

    // Map output `key_ready_loader_w` to top-level `key_loading_done`
    assign key_loading_done = key_ready_loader_w;

    // Map `core_ready` from chacha20_keyinput to top-level `chacha20_ready`
    // This assumes you add a `ready` output to the `chacha20_keyinput` module's port list
    // (It's an internal wire `core_ready` in chacha20_keyinput, so we need to expose it)
    // For now, let's assume `u_chacha20_core.ready` is available or map to `u_chacha20_core.core_ready`
    // You might need to add `output wire ready` to `chacha20_keyinput` module's port list
    // and assign `ready = core_ready;` inside that module.
    // For this example, let's just make a dummy connection or assume direct access (not ideal for real code)
    // For the sake of this top-level, let's assume `chacha20_keyinput` has an output `ready`
    assign chacha20_ready = u_chacha20_core.ready; // You might need to modify chacha20_keyinput for this

    // Logic to transfer the key from key_loader to chacha20_keyinput
    // This FSM drives the memory-mapped interface of chacha20_keyinput
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key_transfer_state <= KEY_TRANSFER_IDLE;
            chacha20_cs        <= 1'b0;
            chacha20_we        <= 1'b0;
            chacha20_addr      <= 8'h00;
            chacha20_write_data <= 32'h0;
            init_chacha_reg    <= 1'b0;
            next_chacha_reg    <= 1'b0;
        end else begin
            // Default assignments to prevent latches and unintended behavior
            chacha20_cs        <= 1'b0;
            chacha20_we        <= 1'b0;
            init_chacha_reg    <= 1'b0; // Pulse init when starting ChaCha20
            next_chacha_reg    <= 1'b0; // Pulse next to process next block

            case (key_transfer_state)
                KEY_TRANSFER_IDLE: begin
                    // Wait for the key_loader to finish providing all key words
                    if (key_ready_loader_w) begin
                        key_transfer_state <= TRANSFERRING_KEY;
                        // Initial setup for the first key word transfer
                        chacha20_addr <= 8'h10; // Start address for KEY0
                        chacha20_write_data <= 32'h0; // Will be updated by key_loader output
                    end
                end
                TRANSFERRING_KEY: begin
                    // When key_loader pulses key_write_enable, write to chacha20_keyinput
                    if (key_write_enable_w) begin
                        chacha20_cs        <= 1'b1; // Assert chip select
                        chacha20_we        <= 1'b1; // Assert write enable
                        chacha20_addr      <= 8'h10 + key_index_w; // Calculate target address (0x10 to 0x17)
                        chacha20_write_data <= chacha20_key_word_w; // Data from key_loader

                        if (key_index_w == 3'd7) begin // If this was the last word (index 7)
                            key_transfer_state <= KEY_TRANSFER_DONE;
                        end
                        // Note: key_loader automatically transitions `key_index` and `trng_request`
                        // so we just respond to its `key_write_enable` and `key_index`.
                    end
                end
                KEY_TRANSFER_DONE: begin
                    // Key has been fully transferred to chacha20_keyinput's internal registers.
                    // Now you might want to initialize the ChaCha20 core, e.g., by setting its 'init' control bit.
                    // This is just an example; your full system control might differ.
                    // For example, you might pulse 'init' here once.
                    // init_chacha_reg <= 1'b1; // Example: pulse init
                    // key_transfer_state <= KEY_TRANSFER_DONE; // Stay here, or move to a 'Cipher_Operational' state
                end
                default: begin
                    key_transfer_state <= KEY_TRANSFER_IDLE;
                end
            endcase
        end
    end

    // Connect `init_chacha_reg` and `next_chacha_reg` to `chacha20_keyinput`'s control inputs
    // (These are internal to chacha20_keyinput, typically driven by its `cs`/`we`/`addr` interface)
    // The chacha20_keyinput module inherently handles its `init` and `next` internally
    // via its `ADDR_CTRL` writes. So, we don't need to drive them directly from the top level,
    // unless you want external control over `init` and `next` distinct from the memory map.
    // For this setup, the `chacha20_keyinput` module will internally manage `init_reg` and `next_reg`
    // based on `cs`, `we`, `addr`, and `write_data` inputs.

    // If you wanted to manually trigger init/next from the top-level (bypassing addr/data for these specific signals)
    // you would need to modify chacha20_keyinput to expose direct inputs for 'init' and 'next'.
    // Given the current chacha20_keyinput, you'd perform a write to ADDR_CTRL to initiate/trigger:
    // Example: To init ChaCha20 after key is loaded
    // You'd add a state after KEY_TRANSFER_DONE to write to ADDR_CTRL.
    /*
    always @(posedge clk) begin
        if (key_transfer_state == KEY_TRANSFER_DONE && !chacha_initialized) begin
            chacha20_cs <= 1'b1;
            chacha20_we <= 1'b1;
            chacha20_addr <= u_chacha20_core.ADDR_CTRL; // Access the control address
            chacha20_write_data <= (1 << u_chacha20_core.CTRL_INIT_BIT); // Set init bit high
            // Move to a new state or just clear these in the next cycle
            chacha_initialized <= 1'b1; // A flag to ensure it only initializes once
        end else if (chacha_initialized) begin
            chacha20_cs <= 1'b0;
            chacha20_we <= 1'b0;
            chacha20_write_data <= 32'h0;
        end
    end
    */

endmodule