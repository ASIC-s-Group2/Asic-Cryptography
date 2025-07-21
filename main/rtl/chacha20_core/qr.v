module QR (
    input wire [31:0] a,
    input wire [31:0] b,
    input wire [31:0] c,
    input wire [31:0] d,
    output reg [31:0] out_a,
    output reg [31:0] out_b,
    output reg [31:0] out_c,
    output reg [31:0] out_d
);
    // Implementation of quarterround operation
    reg [31:0] temp_a, temp_b, temp_c, temp_d;

    always @(*) begin
        // Initialize temp variables with inputs for the first step
        temp_a = a;
        temp_b = b;
        temp_c = c;
        temp_d = d;

        // Step 1:
        temp_a = temp_a + temp_b;
        temp_d = temp_d ^ temp_a;
        temp_d = temp_d <<< 16;

        // Step 2:
        temp_c = temp_c + temp_d;
        temp_b = temp_b ^ temp_c;
        temp_b = temp_b <<< 12;

        // Step 3:
        temp_a = temp_a + temp_b;
        temp_d = temp_d ^ temp_a;
        temp_d = temp_d <<< 8;

        // Step 4:
        temp_c = temp_c + temp_d;
        temp_b = temp_b ^ temp_c;
        temp_b = temp_b <<< 7;

        // Assign final computed values to the output ports
        out_a = temp_a;
        out_b = temp_b;
        out_c = temp_c;
        out_d = temp_d;
    end

endmodule