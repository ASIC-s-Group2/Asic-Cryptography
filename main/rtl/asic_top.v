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
    output reg chunk_request //handshaking for streaming in the key
);
    
    //making another FSM controller here 
    reg [2:0] fsm_state;

    localparam IDLE        = 3'b000;
    localparam ACQUIRE     = 3'b001;
    localparam CORE        = 3'b010;
    localparam WAIT        = 3'b011;
    localparam COMPLETE    = 3'b100;

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
    localparam KEY     = 2'b00;
    localparam NONCE   = 2'b01;
    localparam COUNTER = 2'b10;

    reg [4:0] current_chunk_id; // Internal register to track which chunk we're on
    reg [255:0] internal_key_storage; // Accumulates the streamed key chunks
    assign chunk_index = current_chunk_id;

    reg core_start;
    wire core_done;
    wire core_busy;

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

        .in_key(key),
        .in_nonce(nonce),
        .in_counter(counter),

        .plaintext(in_state),
        .ciphertext(out_state)
    );

    TRNG trng_unit (
        .clk(clk),
        .rst_n(rst_n),

        .random_number(trng_data),
        .ready(trng_ready),
        .trng_request(trng_request)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            //reset
            fsm_state <= IDLE;
            busy <= 0;
            done <= 0;
            chunk_request <= 0;
            chunk_type <= KEY;
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

            case (fsm_state)
                IDLE: begin
                    done <= 0;
                    busy <= 0;
                    if (start) begin
                        busy <= 1;
                        fsm_state <= ACQUIRE;
                        acquire_sub_state <= KEY;
                        current_chunk_id <= 0;

                        if (use_streamed_key) begin //use streamed
                            chunk_request <= 1;
                            chunk_type <= KEY;
                        end else begin //use TRNG
                            trng_request <= 1;
                            chunk_type <= KEY;
                        end
                        // Reset
                        temp_key <= 256'b0;
                        temp_nonce <= 96'b0;
                        temp_counter <= 32'b0;
                        key <= 256'b0;
                        key <= 96'b0;
                        key <= 32'b0;
                    end
                end

                ACQUIRE: begin
                    // Determine if data is ready from the selected source
                    reg data_source_ready;
                    if (acquire_sub_state == KEY && use_streamed_key) data_source_ready = (chunk_valid && chunk_type == KEY);
                    else if (acquire_sub_state == NONCE && use_streamed_nonce) data_source_ready = (chunk_valid && chunk_type == NONCE);
                    else if (acquire_sub_state == COUNTER && use_streamed_counter) data_source_ready = (chunk_valid && chunk_type == COUNTER);
                    else data_source_ready = trng_ready; // If not streamed, it's TRNG

                    // Request data if not ready
                    if (!data_source_ready) begin
                        if (acquire_sub_state == KEY && use_streamed_key) chunk_request <= 1;
                        else if (acquire_sub_state == NONCE && use_streamed_nonce) chunk_request <= 1;
                        else if (acquire_sub_state == COUNTER && use_streamed_counter) chunk_request <= 1;
                        else trng_request <= 1;
                    end

                    // Process data if ready
                    if (data_source_ready) begin
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