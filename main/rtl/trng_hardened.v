module TRNGHardened (
    input wire clk,
    input wire rst_n,

    input wire trng_request,
    output reg [31:0] random_number,
    output reg ready
);
    // Instantiate 3 independent ring oscillators
    wire ro_out0, ro_out1, ro_out2;

    RingOsc #(.CW(4)) ro0 (.RESET(~rst_n), .RAW_ENTROPY_OUT(ro_out0));
    RingOsc #(.CW(5)) ro1 (.RESET(~rst_n), .RAW_ENTROPY_OUT(ro_out1));
    RingOsc #(.CW(7)) ro2 (.RESET(~rst_n), .RAW_ENTROPY_OUT(ro_out2));

    // Synchronizers for each RO output
    reg ro0_sync1, ro0_sync2;
    reg ro1_sync1, ro1_sync2;
    reg ro2_sync1, ro2_sync2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ro0_sync1 <= 0; ro0_sync2 <= 0;
            ro1_sync1 <= 0; ro1_sync2 <= 0;
            ro2_sync1 <= 0; ro2_sync2 <= 0;
        end else begin
            ro0_sync1 <= ro_out0; ro0_sync2 <= ro0_sync1;
            ro1_sync1 <= ro_out1; ro1_sync2 <= ro1_sync1;
            ro2_sync1 <= ro_out2; ro2_sync2 <= ro2_sync1;
        end
    end

    // Majority voting logic for 3 bits (synthesizes to a simple LUT)
    wire entropy_bit = (ro0_sync2 & ro1_sync2) | (ro0_sync2 & ro2_sync2) | (ro1_sync2 & ro2_sync2);

    // Random bit shift register
    reg [31:0] shift_reg = 32'b0;
    reg [5:0] bit_count = 6'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 32'b0;
            bit_count <= 6'b0;
            random_number <= 32'b0;
            ready <= 1'b0;
        end else begin
            if (trng_request & ~ready) begin
                shift_reg <= {shift_reg[30:0], entropy_bit};
                bit_count <= bit_count + 1;
                if (bit_count == 31) begin
                    random_number <= {shift_reg[30:0], entropy_bit};
                    ready <= 1'b1;
                end
            end else if (~trng_request) begin
                ready <= 1'b0;
                bit_count <= 6'b0;
                shift_reg <= 32'b0;
            end
        end
    end
endmodule