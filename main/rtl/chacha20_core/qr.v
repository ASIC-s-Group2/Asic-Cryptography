module QR (
    input wire [31:0] in_a,
    input wire [31:0] in_b,
    input wire [31:0] in_c,
    input wire [31:0] in_d,
    output wire [31:0] out_a,
    output wire [31:0] out_b,
    output wire [31:0] out_c,
    output wire [31:0] out_d
);

    // Intermediate wires to represent the dataflow at each step of the calculation
    wire [31:0] a1, b1, c1, d1;
    wire [31:0] a2, b2, c2, d2;
    wire [31:0] a3, b3, d3;

    // Step 1: a += b; d ^= a; d <<<= 16;
    assign a1 = in_a + in_b;
    assign d1 = in_d ^ a1;
    assign d2 = {d1[15:0], d1[31:16]}; // Explicit Rotate Left by 16

    // Step 2: c += d; b ^= c; b <<<= 12;
    assign c1 = in_c + d2;
    assign b1 = in_b ^ c1;
    assign b2 = {b1[19:0], b1[31:20]}; // Explicit Rotate Left by 12

    // Step 3: a += b; d ^= a; d <<<= 8;
    assign a2 = a1 + b2;
    assign d3 = d2 ^ a2;
    assign out_d = {d3[23:0], d3[31:24]}; // Explicit Rotate Left by 8

    // Step 4: c += d; b ^= c; b <<<= 7;
    assign c2 = c1 + out_d;
    assign b3 = b2 ^ c2;
    assign out_b = {b3[24:0], b3[31:25]}; // Explicit Rotate Left by 7

    // Final assignments to the remaining outputs
    assign out_a = a2;
    assign out_c = c2;

endmodule