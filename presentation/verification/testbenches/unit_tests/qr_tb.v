// qr_tb.v
// A minimal unit testbench to verify ONLY the qr.v module.
// Uses the official, published test vector from RFC 8439, Section 2.3.1.
`timescale 1ns / 1ps

module qr_tb;

    // Inputs to the QR module
    reg [31:0] in_a_reg;
    reg [31:0] in_b_reg;
    reg [31:0] in_c_reg;
    reg [31:0] in_d_reg;

    // Outputs from the QR module
    wire [31:0] out_a_wire;
    wire [31:0] out_b_wire;
    wire [31:0] out_c_wire;
    wire [31:0] out_d_wire;

    // Instantiate ONLY the module under test
    QR UUT (
        .in_a(in_a_reg),
        .in_b(in_b_reg),
        .in_c(in_c_reg),
        .in_d(in_d_reg),
        .out_a(out_a_wire),
        .out_b(out_b_wire),
        .out_c(out_c_wire),
        .out_d(out_d_wire)
    );

    // These are the EXACT input and output values from the RFC 8439
    // Quarter Round example. This is a known-good, published test case.
    localparam [31:0] INPUT_A = 32'h11111111;
    localparam [31:0] INPUT_B = 32'h01020304;
    localparam [31:0] INPUT_C = 32'h9b8d6f43;
    localparam [31:0] INPUT_D = 32'h01234567;

    localparam [31:0] EXPECTED_A = 32'hea2a92f4;
    localparam [31:0] EXPECTED_B = 32'hcb1cf8ce;
    localparam [31:0] EXPECTED_C = 32'h4581472e;
    localparam [31:0] EXPECTED_D = 32'h5881c4bb;

    // Test sequence
    initial begin
        $display("--- Running QR Unit Test with RFC 8439 Vector ---");

        // 1. Provide the inputs
        in_a_reg = INPUT_A;
        in_b_reg = INPUT_B;
        in_c_reg = INPUT_C;
        in_d_reg = INPUT_D;

        // 2. Wait for combinatorial logic to settle
        #1;

        // 3. Check the results
        $display("Input a:  %h", in_a_reg);
        $display("Output a: %h (Expected: %h)", out_a_wire, EXPECTED_A);
        $display("Input b:  %h", in_b_reg);
        $display("Output b: %h (Expected: %h)", out_b_wire, EXPECTED_B);
        $display("Input c:  %h", in_c_reg);
        $display("Output c: %h (Expected: %h)", out_c_wire, EXPECTED_C);
        $display("Input d:  %h", in_d_reg);
        $display("Output d: %h (Expected: %h)", out_d_wire, EXPECTED_D);

        if (out_a_wire === EXPECTED_A &&
            out_b_wire === EXPECTED_B &&
            out_c_wire === EXPECTED_C &&
            out_d_wire === EXPECTED_D) begin
            $display("RESULT: PASS - QR module is mathematically correct.");
        end else begin
            $display("RESULT: FAIL - QR module is mathematically INCORRECT.");
        end

        $finish;
    end

endmodule
