module uart_transmitter #(
    parameter CLK_FREQ = 100_000_000,
    parameter BAUD = 9600
)(
    input wire clk,
    input wire rst,
    input wire tx_start,
    input wire [7:0] tx_data,
    output reg tx_busy,
    output reg tx
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD;
    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;

    reg [1:0] state = IDLE;
    reg [15:0] clk_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] tx_shift = 0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            clk_count <= 0;
            bit_index <= 0;
            tx <= 1;
            tx_busy <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1;
                    tx_busy <= 0;
                    if (tx_start) begin
                        tx_shift <= tx_data;
                        state <= START;
                        clk_count <= 0;
                        tx_busy <= 1;
                    end
                end
                START: begin
                    tx <= 0;
                    if (clk_count == CLKS_PER_BIT-1) begin
                        clk_count <= 0;
                        state <= DATA;
                        bit_index <= 0;
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                DATA: begin
                    tx <= tx_shift[bit_index];
                    if (clk_count == CLKS_PER_BIT-1) begin
                        clk_count <= 0;
                        if (bit_index == 7) begin
                            state <= STOP;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
                STOP: begin
                    tx <= 1;
                    if (clk_count == CLKS_PER_BIT-1) begin
                        state <= IDLE;
                        clk_count <= 0;
                        tx_busy <= 0;
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end
            endcase
        end
    end
endmodule