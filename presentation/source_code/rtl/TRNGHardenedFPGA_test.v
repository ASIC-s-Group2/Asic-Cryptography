module TRNGHardenedFPGA_test (
    input wire clk,
    input wire rst_n,
    output wire [31:0] random_number,
    output wire ready
);

    // Request new random number every time ready drops
    reg trng_request = 0;
    reg [31:0] rand_reg = 0;
    reg ready_reg = 0;

    TRNGHardened uut (
        .clk(clk),
        .rst_n(rst_n),
        .trng_request(trng_request),
        .random_number(random_number),
        .ready(ready)
    );

    // Simple state machine: request, capture, repeat
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            trng_request <= 0;
        end else begin
            if (!ready) begin
                trng_request <= 1;
            end else begin
                trng_request <= 0; // One-shot request
            end
        end
    end
endmodule