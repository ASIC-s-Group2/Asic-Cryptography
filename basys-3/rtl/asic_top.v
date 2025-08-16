module asic_top (
    // System Signals
    input wire clk,
    input wire rst_n,

    // Control & Message Info
    input wire start,
    // 'message_length_bytes' removed
    output reg busy,
    output reg done,

    //Data Input
    input wire [31:0] in_state_word,
    input wire in_state_valid,
    input wire in_state_last,
    output reg in_state_ready,

    //Data Output
    output reg [31:0] out_state_word,
    output reg out_state_valid,
    input wire out_state_ready,

    input wire use_streamed_key,
    input wire use_streamed_nonce,

    // Input Parameter Interface
    input wire [1:0] chunk_type,
    input wire chunk_valid,
    input wire [31:0] chunk,
    output reg [4:0] chunk_index,
    output reg chunk_request,
    output reg [1:0] request_type,

    // Output Parameter Interface
    output reg [1:0] out_chunk_type,
    output reg out_chunk_valid,
    output reg [31:0] out_chunk,
    output reg [4:0] out_chunk_index,
    input wire out_chunk_ready
);

    wire [31:0] trng_data;
    wire trng_ready;
    reg trng_request;

    TRNGHardened trng_inst (
        .clk(clk), .rst_n(rst_n), .trng_request(trng_request),
        .random_number(trng_data), .ready(trng_ready)
    );

    reg [3:0] fsm_state;
    localparam IDLE               = 4'b0000;
    localparam ACQUIRE            = 4'b0001;
    localparam STREAM_KEY_OUT     = 4'b0010;
    localparam STREAM_NONCE_OUT   = 4'b0011;
    localparam LOAD_IN            = 4'b0100;
    localparam CORE               = 4'b0101;
    localparam CORE_WAIT          = 4'b0110;
    localparam OUTPUT             = 4'b0111;
    localparam COMPLETE           = 4'b1000;

    reg [511:0] in_state;
    reg [4:0]   in_state_ptr;
    reg [511:0] out_state;
    reg [4:0]   out_state_ptr;
    reg [255:0] temp_key;
    reg [95:0]  temp_nonce;
    reg [255:0] key;
    reg [95:0]  nonce;
    reg [31:0]  counter;

    reg [1:0] acquire_sub_state;
    localparam KEY    = 2'b00;
    localparam NONCE  = 2'b01;

    reg [4:0] current_chunk_id;
    reg [4:0] out_chunk_ptr;
    reg last_block_flag; // Flag to remember if the current block is the last one

    // Data selection logic
    wire data_is_from_stream = (acquire_sub_state == KEY  && use_streamed_key) ||
                               (acquire_sub_state == NONCE && use_streamed_nonce);
    wire stream_data_is_valid = chunk_valid && (chunk_type == acquire_sub_state);
    wire data_source_is_ready = data_is_from_stream ? stream_data_is_valid : trng_ready;
    wire [31:0] data_to_accumulate = data_is_from_stream ? chunk : trng_data;

    // Core signals
    reg core_start;
    wire core_done;
    wire core_busy;

    ChaCha20 chacha_unit (
        .clk(clk), .rst_n(rst_n), .start(core_start), .busy(core_busy), .done(core_done),
        .key(key), .nonce(nonce), .counter(counter),
        .plaintext(in_state), .ciphertext(out_state)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset
            fsm_state <= IDLE; busy <= 0; done <= 0; chunk_request <= 0; request_type <= KEY;
            chunk_index <= 0; current_chunk_id <= 0; key <= 0; nonce <= 0; counter <= 1;
            temp_key <= 0; temp_nonce <= 0; core_start <= 0; trng_request <= 0;
            in_state_ptr <= 0; out_state_ptr <= 0; in_state_ready <= 0; out_state_valid <= 0;
            out_state_word <= 0; out_chunk_valid <= 0; out_chunk <= 0;
            out_chunk_index <= 0; out_chunk_type <= 0; out_chunk_ptr <= 0; last_block_flag <= 0;
        end else begin
            core_start <= 0; chunk_request <= 0; trng_request <= 0; done <= 0;
            in_state_ready <= 0; out_state_valid <= 0; out_chunk_valid <= 0;

            case (fsm_state)
                IDLE: begin
                    done <= 0; busy <= 0;
                    if (start) begin
                        busy <= 1; fsm_state <= ACQUIRE; acquire_sub_state <= KEY;
                        current_chunk_id <= 0; temp_key <= 0; temp_nonce <= 0;
                        key <= 0; nonce <= 0; counter <= 1; in_state_ptr <= 0; out_state_ptr <= 0;
                        out_chunk_ptr <= 0; last_block_flag <= 0;
                    end
                end

                ACQUIRE: begin
                    if (data_source_is_ready) begin
                        case (acquire_sub_state)
                            KEY: begin
                                temp_key[current_chunk_id*32 +: 32] <= data_to_accumulate;
                                if (current_chunk_id < 7) current_chunk_id <= current_chunk_id + 1;
                                else begin
                                    key <= temp_key; current_chunk_id <= 0;
                                    if (use_streamed_key) acquire_sub_state <= NONCE;
                                    else fsm_state <= STREAM_KEY_OUT;
                                end
                            end
                            NONCE: begin
                                temp_nonce[current_chunk_id*32 +: 32] <= data_to_accumulate;
                                if (current_chunk_id < 2) current_chunk_id <= current_chunk_id + 1;
                                else begin
                                    nonce <= temp_nonce; current_chunk_id <= 0;
                                    if (use_streamed_nonce) fsm_state <= LOAD_IN;
                                    else fsm_state <= STREAM_NONCE_OUT;
                                end
                            end
                        endcase
                    end else begin
                        if (data_is_from_stream) begin chunk_request <= 1; request_type <= acquire_sub_state; chunk_index <= current_chunk_id;
                        end else begin trng_request <= 1; end
                    end
                end

                STREAM_KEY_OUT: begin
                    out_chunk_valid <= 1'b1;
                    out_chunk_type <= KEY;
                    out_chunk_index <= out_chunk_ptr;
                    out_chunk <= key[out_chunk_ptr*32 +: 32];
                    if (out_chunk_ready) begin
                        if (out_chunk_ptr == 7) begin
                           out_chunk_ptr <= 0;
                           acquire_sub_state <= NONCE;
                           fsm_state <= ACQUIRE;
                        end else begin
                            out_chunk_ptr <= out_chunk_ptr + 1;
                        end
                    end
                end

                STREAM_NONCE_OUT: begin
                    out_chunk_valid <= 1'b1;
                    out_chunk_type <= NONCE;
                    out_chunk_index <= out_chunk_ptr;
                    out_chunk <= nonce[out_chunk_ptr*32 +: 32];
                    if (out_chunk_ready) begin
                        if (out_chunk_ptr == 2) begin
                            out_chunk_ptr <= 0;
                            fsm_state <= LOAD_IN;
                        end else begin
                            out_chunk_ptr <= out_chunk_ptr + 1;
                        end
                    end
                end

                LOAD_IN: begin
                    in_state_ready <= 1;
                    if (in_state_valid) begin
                        in_state[in_state_ptr*32 +: 32] <= in_state_word;
                        
                        // Latch the 'last' signal on the final word of a block
                        if(in_state_ptr == 15 && in_state_last) begin
                            last_block_flag <= 1;
                        end

                        if (in_state_ptr < 15) begin
                            in_state_ptr <= in_state_ptr + 1;
                        end else begin
                            in_state_ptr <= 0;
                            fsm_state <= CORE;
                        end
                    end
                end

                CORE: begin core_start <= 1; fsm_state <= CORE_WAIT; end
                CORE_WAIT: begin if (core_done) fsm_state <= OUTPUT; end

                OUTPUT: begin
                    out_state_valid <= 1;
                    out_state_word <= out_state[out_state_ptr*32 +: 32];
                    if (out_state_ready) begin
                        if (out_state_ptr < 15) out_state_ptr <= out_state_ptr + 1;
                        else begin out_state_ptr <= 0; fsm_state <= COMPLETE; end
                    end
                end

                COMPLETE: begin
                    if (last_block_flag) begin
                        done <= 1; busy <= 0; fsm_state <= IDLE;
                    end else begin
                        counter <= counter + 1;
                        fsm_state <= LOAD_IN;
                    end
                end

                default: fsm_state <= IDLE;
            endcase
        end
    end
endmodule
