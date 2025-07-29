module TRNG (
    input wire clk,
    input wire rst_n,
    input wire raw_entropy_in, // This is the raw entropy input
    input wire trng_request,
    output wire [31:0] random_number,
    output wire ready
);

    // TRNG implementation goes here
    wire ring_oscillator_output;
    RingOsc #(.CW(4)) ring_oscillator (
        .RESET(~rst_n),
        .RAW_ENTROPY_OUT(ring_oscillator_output)
    );

    //Make a shift register to collect bits from the ring oscillator

    reg [31:0] shift_reg = 32'b0;
    reg[5:0] bit_count = 6'b0; // 32 bits total

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 32'b0;
            bit_count <= 6'b0;
            random_number <= 32'b0;
            ready <= 1'b0;
        end else begin
            if (trng_request & ~ready) begin
            shift_reg <= {shift_reg[30:0], ring_oscillator_output}; //The curly brackets are used to concatenate the bits
            bit_count <= bit_count + 1;
            if (bit_count == 31) begin
                random_number <= {shift_reg[30:0],ring_oscillator_output}; // Output the collected bits when we have 32 bits
                ready <= 1'b1; // Indicate that the random number is ready
            end
            end else if (~trng_request) begin
                ready <= 1'b0; // Reset ready signal after outputting the random number
                bit_count <= 6'b0; // Reset bit count
                shift_reg <= 32'b0; // Reset shift register
            end
        end
    end
endmodule
