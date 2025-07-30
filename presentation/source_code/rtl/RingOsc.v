module RingOsc #(parameter CW = 4) (
    input wire RESET,
    input wire CLK,
    output wire RAW_ENTROPY_OUT
);

    reg [CW:0] chain;

    always @(posedge CLK or posedge RESET) begin
        if (RESET)
            chain <= 0;
        else
            chain <= chain + 1;
    end

    assign RAW_ENTROPY_OUT = chain[0];

endmodule