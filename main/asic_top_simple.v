// Simplified asic_top for testing basic functionality
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

    // Simple FSM states
    reg [2:0] state;
    parameter IDLE = 3'b000;
    parameter REQ_TRNG = 3'b001;
    parameter WAIT_TRNG = 3'b010;
    parameter PROCESSING = 3'b011;
    parameter COMPLETE = 3'b100;

    reg [3:0] counter;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            trng_request <= 0;
            chunk_request <= 0;
            request_type <= 0;
            chunk_index <= 0;
            counter <= 0;
            in_state_ready <= 0;
            out_state_valid <= 0;
            out_state_word <= 0;
        end else begin
            // Default values
            trng_request <= 0;
            chunk_request <= 0;
            done <= 0;
            in_state_ready <= 0;
            out_state_valid <= 0;

            case (state)
                IDLE: begin
                    busy <= 0;
                    if (start) begin
                        busy <= 1;
                        state <= REQ_TRNG;
                        counter <= 0;
                    end
                end

                REQ_TRNG: begin
                    trng_request <= 1;
                    if (trng_ready) begin
                        state <= WAIT_TRNG;
                    end
                end

                WAIT_TRNG: begin
                    // Simple processing - just copy TRNG data to output
                    out_state_word <= trng_data;
                    out_state_valid <= 1;
                    if (out_state_ready) begin
                        counter <= counter + 1;
                        if (counter >= 15) begin // Output 16 words
                            state <= COMPLETE;
                        end else begin
                            state <= REQ_TRNG; // Get more data
                        end
                    end
                end

                COMPLETE: begin
                    done <= 1;
                    busy <= 0;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
