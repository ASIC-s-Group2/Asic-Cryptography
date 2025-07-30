// Full asic_top with Verilog-2005 compatible ChaCha20 core
module asic_top (
    input wire clk,
    input wire rst_n,

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

    input wire use_streamed_key,
    input wire use_streamed_nonce,
    input wire use_streamed_counter,

    input wire [1:0] chunk_type,
    input wire chunk_valid,
    input wire [31:0] chunk,
    output reg [4:0] chunk_index,
    output reg chunk_request,
    output reg [1:0] request_type,

    // TRNG signals
    input wire [31:0] trng_data,
    input wire trng_ready,
    output reg trng_request
);

    // Main FSM controller
    reg [2:0] fsm_state;

    // FSM States
    parameter IDLE       = 3'b000;
    parameter ACQUIRE    = 3'b001;
    parameter LOAD_IN    = 3'b010;
    parameter CORE       = 3'b011;
    parameter CORE_WAIT  = 3'b100;
    parameter OUTPUT     = 3'b101;
    parameter COMPLETE   = 3'b110;

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

    // Internal FSM for data acquisition
    reg [1:0] acquire_sub_state;
    parameter KEY      = 2'b00;
    parameter NONCE    = 2'b01;
    parameter COUNTER  = 2'b10;

    reg [4:0] current_chunk_id;

    // Data selection logic for key/nonce/counter
    wire data_is_from_stream;
    assign data_is_from_stream = (acquire_sub_state == KEY   && use_streamed_key) ||
                                 (acquire_sub_state == NONCE && use_streamed_nonce) ||
                                 (acquire_sub_state == COUNTER && use_streamed_counter);

    wire stream_data_is_valid;
    assign stream_data_is_valid = chunk_valid && (chunk_type == acquire_sub_state);

    wire data_source_is_ready;
    assign data_source_is_ready = data_is_from_stream ? stream_data_is_valid : trng_ready;

    wire [31:0] data_to_accumulate;
    assign data_to_accumulate = data_is_from_stream ? chunk : trng_data;

    reg core_start;
    wire core_done;
    wire core_busy;
    wire [511:0] core_ciphertext;

    // Instantiate ChaCha20 core (Verilog-2005 compatible version)
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
        .ciphertext(core_ciphertext)
    );
    
    // Connect core output to buffer
    always @(posedge clk) begin
        if (core_done) begin
            out_state <= core_ciphertext;
        end
    end

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
            // Default assignments for current cycle
            core_start <= 0;
            chunk_request <= 0;
            trng_request <= 0;
            done <= 0;
            in_state_ready <= 0;
            out_state_valid <= 0;

            case (fsm_state)
                IDLE: begin
                    done <= 0;
                    busy <= 0;
                    if (start) begin
                        busy <= 1;
                        fsm_state <= ACQUIRE;
                        acquire_sub_state <= KEY;
                        current_chunk_id <= 0;
                        // Reset
                        temp_key <= 256'b0;
                        temp_nonce <= 96'b0;
                        temp_counter <= 32'b0;
                        key <= 256'b0;
                        nonce <= 96'b0;
                        counter <= 32'b0;
                        in_state_ptr <= 0;
                        out_state_ptr <= 0;
                    end
                end

                ACQUIRE: begin
                    if (data_source_is_ready) begin
                        // Process data if ready
                        case (acquire_sub_state)
                            KEY: begin
                                // Accumulate data into key accumulator
                                case (current_chunk_id)
                                    0: temp_key[31:0]   <= data_to_accumulate;
                                    1: temp_key[63:32]  <= data_to_accumulate;
                                    2: temp_key[95:64]  <= data_to_accumulate;
                                    3: temp_key[127:96] <= data_to_accumulate;
                                    4: temp_key[159:128]<= data_to_accumulate;
                                    5: temp_key[191:160]<= data_to_accumulate;
                                    6: temp_key[223:192]<= data_to_accumulate;
                                    7: temp_key[255:224]<= data_to_accumulate;
                                endcase

                                if (current_chunk_id < 7) begin
                                    current_chunk_id <= current_chunk_id + 1;
                                end else begin
                                    key <= temp_key;
                                    current_chunk_id <= 0;
                                    acquire_sub_state <= NONCE;
                                end
                            end

                            NONCE: begin
                                case (current_chunk_id)
                                    0: temp_nonce[31:0]  <= data_to_accumulate;
                                    1: temp_nonce[63:32] <= data_to_accumulate;
                                    2: temp_nonce[95:64] <= data_to_accumulate;
                                endcase

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
                                fsm_state <= LOAD_IN;
                            end
                        endcase
                    end else begin
                        // Request data if not ready
                        if (data_is_from_stream) begin
                            chunk_request <= 1;
                            request_type <= acquire_sub_state;
                            chunk_index <= current_chunk_id;
                        end else begin
                            trng_request <= 1;
                        end
                    end
                end

                LOAD_IN: begin
                    // Stream 16 words (512 bits) into in_state buffer
                    in_state_ready <= 1;
                    if (in_state_valid) begin
                        in_state[in_state_ptr*32 +: 32] <= in_state_word;
                        if (in_state_ptr < 15)
                            in_state_ptr <= in_state_ptr + 1;
                        else begin
                            in_state_ptr <= 0;
                            fsm_state <= CORE;
                        end
                    end
                end

                CORE: begin
                    core_start <= 1;
                    fsm_state <= CORE_WAIT;
                end

                CORE_WAIT: begin
                    if (core_done) begin
                        fsm_state <= OUTPUT;
                    end
                end

                OUTPUT: begin
                    // Stream 16 words (512 bits) out from out_state buffer
                    if (out_state_ptr < 16) begin
                        out_state_word <= out_state[out_state_ptr*32 +: 32];
                        out_state_valid <= 1;
                        if (out_state_ready) begin
                            if (out_state_ptr < 15) begin
                                out_state_ptr <= out_state_ptr + 1;
                            end else begin
                                out_state_ptr <= 0;
                                fsm_state <= COMPLETE;
                            end
                        end
                    end
                end

                COMPLETE: begin
                    done <= 1;
                    busy <= 0;
                    fsm_state <= IDLE;
                end

                default: fsm_state <= IDLE;
            endcase
        end
    end
endmodule
