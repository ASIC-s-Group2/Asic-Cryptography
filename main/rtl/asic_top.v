module asic_top (
    input wire clk,
    input wire rst_n, //the n means the reset is applied low on the negative edge

    input wire start,
    output wire busy,
    input wire mode,
    output wire done,

    input wire [511:0] in_state,
    output wire [511:0] out_state
);

    // Wires connecting modules
    wire [31:0] trng_data; // TRNG output in 32 bit chunks. The ChaCha core needs 256 bit for a key, 96 for a nonce, and 32 for a counter so just call this as many times as needed.
    wire trng_request;
    wire trng_ready;


    // Instantiate
    ChaCha20 chacha_unit (
        .clk(clk),
        .rst_n(rst_n),

        .start(start),
        .busy(busy),
        .mode(mode),

        .in_state(in_state),
        .out_state(out_state),

        .done(done),

        .trng_data(trng_data),
        .trng_request(trng_request),
        .trng_ready(trng_ready)
    );

    TRNG trng_unit (
        .clk(clk),
        .rst(rst),

        .random_number(trng_data),
        .ready(trng_ready),
        .trng_request(trng_request)
    );

endmodule