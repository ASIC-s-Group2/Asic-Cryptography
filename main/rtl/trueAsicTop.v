// Corrected asic_top module with integrated hardened TRNG and a wait state for the core

module asic_top (
    input wire clk,
    input wire rst_n, //the n means the reset is applied low on the negative edge

    input wire start,
    output reg busy,
    output reg done,

    // Streaming state input (plaintext) - 32 bits wide
    input wire [31:0] in_state_word,
    input wire in_state_valid,
    output reg in_state_ready,

    // Streaming state output (ciphertext) - 32 bits wide
    output reg [31:0] out_state_word,
    output reg out_state_valid,
    input wire out_state_ready,

    output reg [31:0] out_key_word,
    output reg out_key_valid,
    input  wire out_key_ready,

    input wire use_streamed_key,
    input wire use_streamed_nonce,
    input wire use_streamed_counter,

    input wire [1:0] chunk_type,
    input wire chunk_valid,
    input wire [31:0] chunk,
    output reg [4:0] chunk_index,
    output reg chunk_request, //handshaking for streaming in the key/nonce/counter
    output reg [1:0] request_type
);

    // --- Hardened TRNG Integration ---
    wire [31:0] trng_data;
    wire trng_ready;
    reg trng_request;

    TRNGHardened trng_inst (
        .clk(clk),
        .rst_n(rst_n),
        .trng_request(trng_request),
        .random_number(trng_data),
        .ready(trng_ready)
    );

    // Main FSM controller
    reg [2:0] fsm_state;

    // FSM States - Added CORE_WAIT state
    localparam IDLE       = 3'b000;
    localparam ACQUIRE    = 3'b001;
    localparam LOAD_IN    = 3'b010;
    localparam CORE       = 3'b011;
    localparam CORE_WAIT  = 3'b100; // New state to wait for ChaCha20 core
    localparam OUTPUT     = 3'b101;
    localparam COMPLETE   = 3'b110;
    localparam OUTPUT_KEY = 3'b111;

    // Buffers for streaming in/out the ChaCha block
    reg [511:0] in_state;
    reg [3:0] in_state_ptr;
    reg [511:0] out_state;
    reg [3:0] out_state_ptr;

    // Where we build the key, nonce, and counter
    reg [255:0] temp_key;
    reg [95:0] temp_nonce;
    reg [31:0] temp_counter;

    // The stuff passed to the core
    reg [255:0] key;
    reg [95:0] nonce;
    reg [31:0] counter;

    reg [3:0] out_key_ptr;
    // Internal FSM for data acquisition (within ACQUIRE state)
    reg [1:0] acquire_sub_state;
    localparam KEY      = 2'b00;
    localparam NONCE    = 2'b01;
    localparam COUNTER  = 2'b10;

    reg [4:0] current_chunk_id; // Internal register to track which chunk we're on

    // Data selection logic for key/nonce/counter
    wire data_is_from_stream = (acquire_sub_state == KEY   && use_streamed_key) ||
                              (acquire_sub_state == NONCE && use_streamed_nonce) ||
                              (acquire_sub_state == COUNTER && use_streamed_counter);

    wire stream_data_is_valid = chunk_valid && (chunk_type == acquire_sub_state);

    wire data_source_is_ready = data_is_from_stream ? stream_data_is_valid : trng_ready;

    wire [31:0] data_to_accumulate = data_is_from_stream ? chunk : trng_data;

    reg core_start;
    wire core_done;
    wire core_busy;

    // Instantiate ChaCha20 core
    ChaCha20 chacha_unit (
        .clk(clk),
        .rst_n(rst_n),
        .start(core_start),
        .busy(core_busy),
        .done(core_done),
        .key(key),
        .nonce(nonce),
        .counter(counter),
        .plaintext(in_state),
        .ciphertext(out_state)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            //reset
            fsm_state <= IDLE;
            busy <= 0;
            done <= 0;
            chunk_request <= 0;
            request_type <= KEY;
            chunk_index <= 0;
            current_chunk_id <= 0;
            key <= 256'b0;
            nonce <= 96'b0;
            counter <= 32'b0;
            temp_key <= 256'b0;
            temp_nonce <= 96'b0;
            temp_counter <= 32'b0;
            core_start <= 0;
            trng_request <= 0;
            in_state_ptr <= 0;
            out_state_ptr <= 0;
            in_state_ready <= 0;
            out_state_valid <= 0;
            out_state_word <= 0;
        end else begin
            // Default assignments for current cycle (overridden by FSM state)
            core_start <= 0;
            chunk_request <= 0;
            trng_request <= 0;
            done <= 0;
            in_state_ready <= 0;
            out_state_valid <= 0;

            case (fsm_state)
                // Wait for start signal
                IDLE: begin
                    done         <= 0;
                    busy         <= 0;
                    out_key_valid<= 0;
                    if (start) begin
                        busy         <= 1;
                        fsm_state    <= ACQUIRE;
                        acquire_sub_state <= KEY;
                        current_chunk_id  <= 0;
                        out_key_ptr       <= 0;
                        temp_key          <= 256'b0;
                        temp_nonce        <= 96'b0;
                        temp_counter      <= 32'b0;
                        key               <= 256'b0;
                        nonce             <= 96'b0;
                        counter           <= 32'b0;
                        in_state_ptr      <= 0;
                        out_state_ptr     <= 0;
                    end
                end

                // Acquire key, nonce, and counter (stream/TRNG)
                ACQUIRE: begin
                    if (data_source_is_ready) begin
                        case (acquire_sub_state)
                            KEY: begin
                                // Store each 32-bit chunk into temp_key
                                temp_key[current_chunk_id*32 +: 32] <= data_to_accumulate;
                                if (current_chunk_id < 7) begin
                                    current_chunk_id <= current_chunk_id + 1;
                                end else begin
                                    key <= temp_key;
                                    current_chunk_id <= 0;
                                    acquire_sub_state <= NONCE;
                                end
                            end
                            NONCE: begin
                                temp_nonce[current_chunk_id*32 +: 32] <= data_to_accumulate;
                                if (current_chunk_id < 2) begin
                                    current_chunk_id <= current_chunk_id + 1;
                                end else begin
                                    nonce <= temp_nonce;
                                    current_chunk_id <= 0;
                                    acquire_sub_state <= COUNTER;
                                end
                            end
                            COUNTER: begin
                                temp_counter <= data_to_accumulate;
                                counter <= data_to_accumulate;
                                // Move to key output state
                                fsm_state <= OUTPUT_KEY;
                            end
                        endcase
                    end else begin
                        // Request next chunk or TRNG
                        if (data_is_from_stream) begin
                            chunk_request <= 1;
                            request_type  <= acquire_sub_state;
                            chunk_index   <= current_chunk_id;
                        end else begin
                            trng_request  <= 1;
                        end
                    end
                end

                // Stream out the key, 32 bits at a time
                OUTPUT_KEY: begin
                    if (out_key_ptr < 8) begin
                        out_key_word  <= key[out_key_ptr*32 +: 32];
                        out_key_valid <= 1;
                        if (out_key_ready) begin
                            if (out_key_ptr < 7)
                                out_key_ptr <= out_key_ptr + 1;
                            else begin
                                out_key_ptr   <= 0;
                                out_key_valid <= 0;
                                fsm_state     <= LOAD_IN; // Next step: load plaintext
                            end
                        end
                    end else begin
                        out_key_valid <= 0;
                        fsm_state     <= LOAD_IN;
                    end
                end

                // Load plaintext state in as 32-bit words
                LOAD_IN: begin
                    in_state_ready <= 1;
                    if (in_state_valid) begin
                        in_state[in_state_ptr*32 +: 32] <= in_state_word;
                        if (in_state_ptr < 15)
                            in_state_ptr <= in_state_ptr + 1;
                        else begin
                            in_state_ptr <= 0;
                            fsm_state    <= CORE;
                        end
                    end
                end

                // Start the ChaCha20 core
                CORE: begin
                    core_start <= 1;
                    fsm_state  <= CORE_WAIT;
                end

                // Wait for core to finish
                CORE_WAIT: begin
                    if (core_done) begin
                        fsm_state <= OUTPUT;
                    end
                end

                // Output 512-bit state as 32-bit words
                OUTPUT: begin
                    if (out_state_ptr < 16) begin
                        out_state_word  <= out_state[out_state_ptr*32 +: 32];
                        out_state_valid <= 1;
                        if (out_state_ready) begin
                            if (out_state_ptr < 15)
                                out_state_ptr <= out_state_ptr + 1;
                            else begin
                                out_state_ptr <= 0;
                                fsm_state     <= COMPLETE;
                            end
                        end
                    end else begin
                        out_state_valid <= 0;
                        fsm_state       <= COMPLETE;
                    end
                end

                // Finish, reset everything
                COMPLETE: begin
                    done      <= 1;
                    busy      <= 0;
                    fsm_state <= IDLE;
                end

                default: fsm_state <= IDLE;
            endcase
        end
    end
endmodule