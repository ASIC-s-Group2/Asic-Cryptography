// Corrected asic_top module that instantiates its own TRNG for robust simulation.
module asic_top (
    input wire clk,
    input wire rst_n,

    input wire start,
    output reg busy,
    output reg done,

    // Streaming state input (plaintext)
    input wire [31:0] in_state_word,
    input wire in_state_valid,
    output reg in_state_ready,

    // Streaming state output (ciphertext)
    output reg [31:0] out_state_word,
    output reg out_state_valid,
    input wire out_state_ready,

    // Configuration for how to load key/nonce/counter
    input wire use_streamed_key,
    input wire use_streamed_nonce,
    input wire use_streamed_counter,

    // Streaming chunk input for key/nonce/counter
    input wire [1:0] chunk_type,
    input wire chunk_valid,
    input wire [31:0] chunk,
    output reg [4:0] chunk_index,
    output reg chunk_request,
    output reg [1:0] request_type
);

    // --- Internal TRNG Instantiation ---
    // The TRNG is now part of this module, simplifying the testbench.
    reg trng_request;
    wire [31:0] trng_data;
    wire trng_ready;

    MockTRNGHardened trng_unit (
        .clk(clk),
        .rst_n(rst_n),
        .trng_request(trng_request),
        .trng_data(trng_data),
        .trng_ready(trng_ready)
    );
    // ------------------------------------

    reg [2:0] fsm_state;
    localparam IDLE      = 3'b000;
    localparam ACQUIRE   = 3'b001;
    localparam LOAD_IN   = 3'b010;
    localparam CORE      = 3'b011;
    localparam CORE_WAIT = 3'b100;
    localparam OUTPUT    = 3'b101;
    localparam COMPLETE  = 3'b110;

    reg [511:0] in_state;
    reg [3:0] in_state_ptr;
    reg [511:0] out_state;
    reg [3:0] out_state_ptr;

    reg [255:0] temp_key;
    reg [95:0] temp_nonce;
    reg [31:0] temp_counter;

    reg [255:0] key;
    reg [95:0] nonce;
    reg [31:0] counter;

    reg [1:0] acquire_sub_state;
    localparam KEY     = 2'b00;
    localparam NONCE   = 2'b01;
    localparam COUNTER = 2'b10;

    reg [4:0] current_chunk_id;

    wire data_is_from_stream;
    assign data_is_from_stream = (acquire_sub_state == KEY     && use_streamed_key) ||
                                 (acquire_sub_state == NONCE   && use_streamed_nonce) ||
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

    ChaCha20 chacha_unit (
        .clk(clk), .rst_n(rst_n), .start(core_start), .busy(core_busy), .done(core_done),
        .key(key), .nonce(nonce), .counter(counter), .plaintext(in_state), .ciphertext(out_state)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fsm_state <= IDLE;
            busy <= 0;
            done <= 0;
            chunk_request <= 0;
            request_type <= KEY;
            chunk_index <= 0;
            current_chunk_id <= 0;
            key <= 0;
            nonce <= 0;
            counter <= 0;
            temp_key <= 0;
            temp_nonce <= 0;
            temp_counter <= 0;
            core_start <= 0;
            trng_request <= 0;
            in_state_ptr <= 0;
            out_state_ptr <= 0;
            in_state_ready <= 0;
            out_state_valid <= 0;
            out_state_word <= 0;
        end else begin
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
                        temp_key <= 0;
                        temp_nonce <= 0;
                        temp_counter <= 0;
                        key <= 0;
                        nonce <= 0;
                        counter <= 0;
                        in_state_ptr <= 0;
                        out_state_ptr <= 0;
                    end
                end

                ACQUIRE: begin
                    if (data_source_is_ready) begin
                        case (acquire_sub_state)
                            KEY: begin
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
                                fsm_state <= LOAD_IN;
                            end
                        endcase
                    end else begin
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
                    in_state_ready <= 1;
                    if (in_state_valid) begin
                        in_state[in_state_ptr*32 +: 32] <= in_state_word;
                        if (in_state_ptr < 15) begin
                            in_state_ptr <= in_state_ptr + 1;
                        end else begin
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
