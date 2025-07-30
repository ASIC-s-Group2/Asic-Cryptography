module chacha20_key_loader (
    input wire clk,
    input wire rst_n,
    input wire trng_ready,
    input wire [31:0] trng_bit,
    output wire trng_request,

    output reg key_write_enable, //enable the signal to write the key to the chacha20 module
    output reg [2:0] key_index, //
    output reg [31:0] chacha20_key, // <--- This is the 32-bit word currently being transmitted
    output reg key_ready //indicates that the key is ready to be used when this is driven high
);

reg [3:0] state; //state machine to control the key loading process
localparam IDLE = 4'd0,
           WAIT_FOR_TRNG = 4'd1,
           LOAD_KEY = 4'd2, // Renamed from my previous suggestion back to your original, as it represents loading one word
           DONE = 4'd3;

assign trng_request = (state == WAIT_FOR_TRNG);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        state <= IDLE;
        key_index <= 3'd0;
        chacha20_key <= 32'd0; // Initialize key (current word) to 0
        key_write_enable <= 1'b0;
        key_ready <= 1'b0;
    end else begin
        case (state)
            IDLE: begin
                key_index <= 3'd0; // reset key index
                key_ready <= 1'b0; // reset key ready
                key_write_enable <= 1'b0; // disable key write
                state <= WAIT_FOR_TRNG; // move to wait for TRNG state
            end
            WAIT_FOR_TRNG: begin
                key_write_enable <= 1'b0; // disable key write while waiting for TRNG
                if (trng_ready) begin
                    chacha20_key <= trng_bit; // Latch the 32-bit TRNG data into the output register
                    state <= LOAD_KEY; // Move to assert write enable for this data
                end
            end
            LOAD_KEY: begin // This state implies that `chacha20_key` now holds the data to be written
                key_write_enable <= 1'b1; // Pulse key_write_enable high for one cycle
                state <= (key_index == 3'd7) ? DONE : WAIT_FOR_TRNG; // If all 8 words sent, go DONE, else request next
                key_index <= key_index + 1; // Increment for the next word
            end
            DONE : begin
                key_write_enable <= 1'b0; // disable key write
                key_ready <= 1'b1; // Indicate that the entire 256-bit key transfer is complete
            end
            // No default state needed if all possibilities are covered, but good for robustness
        endcase
    end
end
endmodule