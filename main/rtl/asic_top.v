module asic_top (
    input wire clk,
    input wire rst_n, //the n means the reset is applied low on the negative edge

    input wire start,
    output reg busy,
    output reg done,

    input wire [511:0] in_state,
    output wire [511:0] out_state,

    input wire use_streamed_key,
    input wire use_streamed_nonce,
    input wire use_streamed_counter,

    input wire [1:0] chunk_type,
    input wire chunk_valid,
    input wire [31:0] chunk,
    output reg [4:0] chunk_index,
    output reg chunk_request, //handshaking for streaming in the key
    output reg [1:0] request_type
);
    
    //making another FSM controller here 
    reg [2:0] fsm_state;

    localparam IDLE       = 3'b000;
    localparam ACQUIRE    = 3'b001;
    localparam CORE       = 3'b010;
    localparam WAIT       = 3'b011;
    localparam COMPLETE   = 3'b100;

    //where we will build them
    reg [255:0] temp_key;
    reg [95:0] temp_nonce;
    reg [31:0] temp_counter;

    //The stuff passed to the core
    reg [255:0] key;
    reg [95:0] nonce;
    reg [31:0] counter;

    // Internal FSM for data acquisition (within ACQUIRE_INPUT_DATA state)
    reg [1:0] acquire_sub_state;
    localparam KEY      = 2'b00;
    localparam NONCE    = 2'b01;
    localparam COUNTER  = 2'b10;

    reg [4:0] current_chunk_id; // Internal register to track which chunk we're on
    reg [255:0] internal_key_storage; // Accumulates the streamed key chunks
    assign chunk_index = current_chunk_id;

    reg core_start;
    wire core_done;
    wire core_busy;
    
    wire [31:0] trng_data;
    wire        trng_ready;
    reg         trng_request;

    wire [31:0] data_to_accumulate; //FIX
    assign data_to_accumulate =
    (acquire_sub_state == KEY && use_streamed_key) ? chunk :
    (acquire_sub_state == NONCE && use_streamed_nonce) ? chunk :
    (acquire_sub_state == COUNTER && use_streamed_counter) ? chunk :
    trng_data; //Uses ternary to see if it should assign the current data to chunk (streamed in) or use the trng data if its not available

    // Instantiate
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
///REPLACE WITH REAL TRNG HARDENED MODULE
    // For simulation purposes, we use a mock TRNG module
    MockTRNGHardened trng_unit (
        .clk(clk),
        .rst_n(rst_n),

        .random_number(trng_data),
        .ready(trng_ready),
        .trng_request(trng_request)
    );

    wire data_is_from_stream;
    wire stream_data_is_valid;
    wire data_source_is_ready;
    assign data_is_from_stream = (acquire_sub_state == KEY   && use_streamed_key) ||
                                 (acquire_sub_state == NONCE && use_streamed_nonce) ||
                                 (acquire_sub_state == COUNTER && use_streamed_counter);
    assign stream_data_is_valid = chunk_valid && (chunk_type == acquire_sub_state);
    assign data_source_is_ready = data_is_from_stream ? stream_data_is_valid : trng_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            //reset
            fsm_state <= IDLE;
            busy <= 0;
            done <= 0;
            chunk_request <= 0;
            request_type <= KEY;
            current_chunk_id <= 0;
            key <= 256'b0;
            nonce <= 96'b0;
            counter <= 32'b0;
            temp_key <= 256'b0;
            temp_nonce <= 96'b0;
            temp_counter <= 32'b0;
            core_start <= 0;
            trng_request <= 0;
        end else begin
            // Default assignments for current cycle (overridden by FSM state)
            core_start <= 0;
            chunk_request <= 0;
            trng_request <= 0; 
            done <= 0;

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
                    end
                end

                ACQUIRE: begin
                    if (data_source_is_ready) begin
                        // Process data if ready
                        case (acquire_sub_state)
                            KEY: begin
                                // Accumulate data into key accumulator
                                case (current_chunk_id)
                                    0: temp_key[31:0] <= data_to_accumulate;
                                    1: temp_key[63:32] <= data_to_accumulate;
                                    2: temp_key[95:64] <= data_to_accumulate;
                                    3: temp_key[127:96] <= data_to_accumulate;
                                    4: temp_key[159:128] <= data_to_accumulate;
                                    5: temp_key[191:160] <= data_to_accumulate;
                                    6: temp_key[223:192] <= data_to_accumulate;
                                    7: temp_key[255:224] <= data_to_accumulate;
                                endcase

                                if (current_chunk_id < 7) begin 
                                    current_chunk_id <= current_chunk_id + 1;
                                end else begin // All key chunks received
                                    key <= temp_key;
                                    current_chunk_id <= 0;
                                    acquire_sub_state <= NONCE;
                                end
                            end

                            NONCE: begin
                                case (current_chunk_id)
                                    0: temp_nonce[31:0] <= data_to_accumulate;
                                    1: temp_nonce[63:32] <= data_to_accumulate;
                                    2: temp_nonce[95:64] <= data_to_accumulate;
                                endcase

                                if (current_chunk_id < 2) begin
                                    current_chunk_id <= current_chunk_id + 1;
                                end else begin // all nonce chunks received
                                    nonce <= temp_nonce;
                                    current_chunk_id <= 0;
                                    acquire_sub_state <= COUNTER;
                                end
                            end

                            COUNTER: begin
                                counter <= data_to_accumulate;
                                fsm_state <= CORE;
                            end
                        endcase
                    end else begin
                        // Request data if not ready
                        if (data_is_from_stream) begin
                            chunk_request <= 1;
                            request_type <= acquire_sub_state;
                        end else begin
                            trng_request <= 1;
                        end
                    end
                end

                CORE: begin
                    core_start <= 1;
                    fsm_state <= WAIT;
                end

                WAIT: begin
                    if (core_done) begin
                        fsm_state <= COMPLETE;
                    end
                    // Stay in WAIT until core_done is high
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
