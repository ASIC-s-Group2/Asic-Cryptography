// Verilog-2005 compatible QR module
module QR (
    input  wire [31:0] in_a,
    input  wire [31:0] in_b,
    input  wire [31:0] in_c,
    input  wire [31:0] in_d,
    output reg  [31:0] out_a,
    output reg  [31:0] out_b,
    output reg  [31:0] out_c,
    output reg  [31:0] out_d
);

    // Declare variables outside the always block for Verilog-2005 compatibility
    reg [31:0] a, b, c, d;

    always @(*) begin
        // Initialize with input values for this round
        a = in_a;
        b = in_b;
        c = in_c;
        d = in_d;

        // --- Execute the ChaCha20 Quarter Round (RFC 8439) ---

        // Step 1
        a = a + b;
        d = d ^ a;
        d = (d << 16) | (d >> 16); // Rotate left by 16

        // Step 2
        c = c + d;
        b = b ^ c;
        b = (b << 12) | (b >> 20); // Rotate left by 12 (32-12=20)

        // Step 3
        a = a + b;
        d = d ^ a;
        d = (d << 8)  | (d >> 24); // Rotate left by 8 (32-8=24)

        // Step 4
        c = c + d;
        b = b ^ c;
        b = (b << 7)  | (b >> 25); // Rotate left by 7 (32-7=25)

        // Assign the final results to the output ports
        out_a = a;
        out_b = b;
        out_c = c;
        out_d = d;
    end

endmodule
