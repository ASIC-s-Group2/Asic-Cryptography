module asic_top (
    input wire clk,
    input wire rst_n, //the n means the reset is applied low on the negative edge

    input wire start,
    output wire busy,
    output wire done,

    input wire [511:0] in_state,
    output wire [511:0] out_state
);
    //making another FSM controller here 

    localparam S_IDLE              = 3'h0;
    localparam S_ACQUIRE_DATA      = 3'h1;
    // You could add an S_CHECK_DATA state here
    localparam S_START_CHACHA      = 3'h2;
    localparam S_WAIT_FOR_CHACHA   = 3'h3;
    localparam S_DONE              = 3'h4;

    // Here we will use some example fixed values but later there will be a system here that builds these from the TRNG and then starts the core
    reg [255:0] key_reg = 256'h03020100_07060504_0b0a0908_0f0e0d0c_13121110_17161514_1b1a1918_1f1e1d1c;
    reg [95:0] nonce_reg = 96'h00000000_08070605_04030201;
    reg [31:0] counter_reg = 32'h00000001;

    // Wires connecting modules


    // Instantiate
    ChaCha20 chacha_unit (
        .clk(clk),
        .rst_n(rst_n),

        .start(start),
        .busy(busy),
        .done(done),

        .in_key(key_reg),
        .in_nonce(nonce_reg),
        .in_counter(counter_reg),

        .in_state(in_state),
        .out_state(out_state)
    );

    TRNG trng_unit (
        .clk(clk),
        .rst(rst),

        .random_number(trng_data),
        .ready(trng_ready),
        .trng_request(trng_request)
    );

endmodule