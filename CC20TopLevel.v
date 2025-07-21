module CC20TopLevel(
    input wire clk,
    input wire reset,
    input wire [255:0] key,
    input wire [127:0] plaintext,
)
endmodule


//chacha20 quarter round function
// This module implements the quarter round function used in the ChaCha20 stream cipher.
// It takes four 32-bit inputs and produces four 32-bit outputs.
// The quarter round function is a fundamental operation in the ChaCha20 algorithm,
// which mixes the input values to produce new values that are used in the encryption process.
// The function performs a series of additions and bitwise operations to achieve diffusion and confusion,   
module chacha_qr( 
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [31:0] c,
    input  wire [31:0] d,
    output wire [31:0] a_prim,
    output wire [31:0] b_prim,
    output wire [31:0] c_prim,
    output wire [31:0] d_prim
);
    reg [31:0] internal_a_prim;
    reg [31:0] internal_b_prim;
    reg [31:0] internal_c_prim;
    reg [31:0] internal_d_prim;
    assign a_prim = internal_a_prim;
    assign b_prim = internal_b_prim;
    assign c_prim = internal_c_prim;
    assign d_prim = internal_d_prim;
    always @* begin : qr
        reg [31:0] a0, a1;
        reg [31:0] b0, b1, b2, b3;
        reg [31:0] c0, c1;
        reg [31:0] d0, d1, d2, d3;
        a0 = a + b;
        d0 = d ^ a0;
        d1 = {d0[15:0], d0[31:16]};
        c0 = c + d1;
        b0 = b ^ c0;
        b1 = {b0[19:0], b0[31:20]};
        a1 = a0 + b1;
        d2 = d1 ^ a1;
        d3 = {d2[23:0], d2[31:24]};
        c1 = c0 + d3;
        b2 = b1 ^ c1;
        b3 = {b2[24:0], b2[31:25]};
        internal_a_prim = a1;
        internal_b_prim = b3;
        internal_c_prim = c1;
        internal_d_prim = d3;
    end
endmodule