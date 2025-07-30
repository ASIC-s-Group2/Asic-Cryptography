module TRNGHardened (
    input wire          clk,
    input wire          rst_n,
    input wire          trng_request,
    output reg [31:0]   random_number,
    output reg          ready
);

    reg [1:0] state, next_state;
    localparam S_IDLE    = 2'b00;
    localparam S_PROVIDE = 2'b01;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= S_IDLE;
        else        state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE:    if (trng_request) next_state = S_PROVIDE;
            S_PROVIDE: if (!trng_request) next_state = S_IDLE;
            default:   next_state = S_IDLE;
        endcase
    end

    always @(*) begin
        ready = (state == S_PROVIDE);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // IMPORTANT: Initialize with a non-zero seed!
            random_number <= 32'hDEADBEEF;
        end else if (state == S_IDLE && trng_request) begin
            // Use a simple LFSR for a predictable sequence
            random_number <= {random_number[30:0], random_number[31]^random_number[21]^random_number[1]^random_number[0]};
        end
    end

endmodule