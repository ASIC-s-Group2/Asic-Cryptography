/*
 * File: qr.v
 * Description: Combinational ChaCha20 Quarter-Round (QR) function.
 * Complies with Icarus Verilog (no inner reg declarations).
 */
module QR (
    input  wire [31:0] in_a,
    input  wire [31:0] in_b,
    input  wire [31:0] in_c,
    input  wire [31:0] in_d,
    output wire [31:0] out_a,
    output wire [31:0] out_b,
    output wire [31:0] out_c,
    output wire [31:0] out_d
);

    // Internal wires for the steps
    wire [31:0] a0, d0, d1;
    wire [31:0] c0, b0, b1;
    wire [31:0] a1, d2, d3;
    wire [31:0] c1, b2, b3;

    // Step 1
    assign a0 = in_a + in_b;
    assign d0 = in_d ^ a0;
    assign d1 = {d0[15:0], d0[31:16]}; // ROTL 16

    // Step 2
    assign c0 = in_c + d1;
    assign b0 = in_b ^ c0;
    assign b1 = {b0[19:0], b0[31:20]}; // ROTL 12

    // Step 3
    assign a1 = a0 + b1;
    assign d2 = d1 ^ a1;
    assign d3 = {d2[23:0], d2[31:24]}; // ROTL 8

    // Step 4
    assign c1 = c0 + d3;
    assign b2 = b1 ^ c1;
    assign b3 = {b2[24:0], b2[31:25]}; // ROTL 7

    // Final outputs
    assign out_a = a1;
    assign out_b = b3;
    assign out_c = c1;
    assign out_d = d3;

endmodule
