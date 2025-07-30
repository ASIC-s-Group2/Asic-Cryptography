module trng_uart_stream (
    input wire clk,
    input wire rst,
    input wire [31:0] random_number,
    input wire ready,
    output wire tx
);
    reg tx_start = 0;
    reg [7:0] tx_data = 0;
    wire tx_busy;

    reg [2:0] state = 0;
    reg [31:0] buffer = 0;

    uart_transmitter uart0 (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .tx_busy(tx_busy)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_start <= 0;
            tx_data <= 0;
            buffer <= 0;
            state <= 0;
        end else begin
            tx_start <= 0;

            case (state)
                0: if (ready) begin
                    buffer <= random_number;
                    state <= 1;
                end

                1: if (!tx_busy) begin
                    tx_data <= buffer[31:24];
                    tx_start <= 1;
                    state <= 2;
                end

                2: if (!tx_busy) begin
                    tx_data <= buffer[23:16];
                    tx_start <= 1;
                    state <= 3;
                end

                3: if (!tx_busy) begin
                    tx_data <= buffer[15:8];
                    tx_start <= 1;
                    state <= 4;
                end

                4: if (!tx_busy) begin
                    tx_data <= buffer[7:0];
                    tx_start <= 1;
                    state <= 5;
                end

                5: if (!tx_busy) begin
                    state <= 0;
                end
            endcase
        end
    end
endmodule