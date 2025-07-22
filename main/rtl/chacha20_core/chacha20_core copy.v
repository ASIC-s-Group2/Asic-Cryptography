module ChaCha20 (
    input wire clk,
    input wire rst,

    input wire start,
    output wire busy,
    output wire done,
    input wire mode, // Mode of operation (encryption or decryption)

    input wire [511:0] in_state,
    output wire [511:0] out_state,

    // TRNG interface
    input wire [31:0] trng_data,
    output wire trng_request, 
    input wire trng_ready
);

//Important Internal State Registers

reg [31:0] s [0:15]; // Array of 16 32-bit registers

/*
Pretend it looks like:
[ s0  s1  s2  s3  ]
[ s4  s5  s6  s7  ]
[ s8  s9 s10 s11 ]
[ s12 s13 s14 s15 ]
*/

reg [255:0] current_key;
reg [95:0] current_nonce;
reg [31:0] current_counter;
reg [4:0] round;

// States for modes of operation (made into local parameters for clarity)
localparam IDLE  = 2'b00;
localparam INIT  = 2'b01;
localparam RUN   = 2'b10;
localparam FINAL = 2'b11;

// State machine to control the operation of the ChaCha20 core
reg [1:0] state, next_state;

// Temporary registers for double-round output
    reg [31:0] col_out [0:15]; // After column rounds

    // Wires for QR outputs (column rounds)
    wire [31:0] qr0_a_o, qr0_b_o, qr0_c_o, qr0_d_o;
    wire [31:0] qr1_a_o, qr1_b_o, qr1_c_o, qr1_d_o;
    wire [31:0] qr2_a_o, qr2_b_o, qr2_c_o, qr2_d_o;
    wire [31:0] qr3_a_o, qr3_b_o, qr3_c_o, qr3_d_o;

    // Wires for QR outputs (diagonal rounds)
    wire [31:0] qr4_a_o, qr4_b_o, qr4_c_o, qr4_d_o;
    wire [31:0] qr5_a_o, qr5_b_o, qr5_c_o, qr5_d_o;
    wire [31:0] qr6_a_o, qr6_b_o, qr6_c_o, qr6_d_o;
    wire [31:0] qr7_a_o, qr7_b_o, qr7_c_o, qr7_d_o;

    // QR COLUMN rounds
    QR qr0(.a(s[0]),  .b(s[4]),  .c(s[8]),  .d(s[12]), .out_a(qr0_a_o), .out_b(qr0_b_o), .out_c(qr0_c_o), .out_d(qr0_d_o));
    QR qr1(.a(s[1]),  .b(s[5]),  .c(s[9]),  .d(s[13]), .out_a(qr1_a_o), .out_b(qr1_b_o), .out_c(qr1_c_o), .out_d(qr1_d_o));
    QR qr2(.a(s[2]),  .b(s[6]),  .c(s[10]), .d(s[14]), .out_a(qr2_a_o), .out_b(qr2_b_o), .out_c(qr2_c_o), .out_d(qr2_d_o));
    QR qr3(.a(s[3]),  .b(s[7]),  .c(s[11]), .d(s[15]), .out_a(qr3_a_o), .out_b(qr3_b_o), .out_c(qr3_c_o), .out_d(qr3_d_o));

    // QR DIAGONAL rounds
    QR qr4(.a(col_out[0]),  .b(col_out[5]),  .c(col_out[10]), .d(col_out[15]), .out_a(qr4_a_o), .out_b(qr4_b_o), .out_c(qr4_c_o), .out_d(qr4_d_o));
    QR qr5(.a(col_out[1]),  .b(col_out[6]),  .c(col_out[11]), .d(col_out[12]), .out_a(qr5_a_o), .out_b(qr5_b_o), .out_c(qr5_c_o), .out_d(qr5_d_o));
    QR qr6(.a(col_out[2]),  .b(col_out[7]),  .c(col_out[8]),  .d(col_out[13]), .out_a(qr6_a_o), .out_b(qr6_b_o), .out_c(qr6_c_o), .out_d(qr6_d_o));
    QR qr7(.a(col_out[3]),  .b(col_out[4]),  .c(col_out[9]),  .d(col_out[14]), .out_a(qr7_a_o), .out_b(qr7_b_o), .out_c(qr7_c_o), .out_d(qr7_d_o));

    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            busy <= 0;
            done <= 0;
            round_ctr <= 0;
            out_state <= 0;
            trng_request <= 0;
            for (i = 0; i < 16; i = i + 1) begin // Reset all state registers
                s[i] <= 0;
                s_orig[i] <= 0;
                col_out[i] <= 0;
            end
        end else begin
            case (state)
                IDLE: begin
                    busy <= 0;
                    done <= 0;
                    out_state <= 0;
                    if (start) begin
                        // Load state from in_state
                        for (i = 0; i < 16; i = i + 1) begin
                            s[i]      <= in_state[32*(16-i)-1 -: 32];
                            s_orig[i] <= in_state[32*(16-i)-1 -: 32];
                        end
                        round_ctr <= 0;
                        busy <= 1;
                        state <= LOAD;
                    end
                end
                LOAD: begin
                    // First round, go to ROUND
                    state <= ROUND;
                end
                ROUND: begin
                    // Column rounds
                    col_out[0]  <= qr0_a_o;   col_out[4]  <= qr0_b_o;   col_out[8]  <= qr0_c_o;   col_out[12] <= qr0_d_o;
                    col_out[1]  <= qr1_a_o;   col_out[5]  <= qr1_b_o;   col_out[9]  <= qr1_c_o;   col_out[13] <= qr1_d_o;
                    col_out[2]  <= qr2_a_o;   col_out[6]  <= qr2_b_o;   col_out[10] <= qr2_c_o;   col_out[14] <= qr2_d_o;
                    col_out[3]  <= qr3_a_o;   col_out[7]  <= qr3_b_o;   col_out[11] <= qr3_c_o;   col_out[15] <= qr3_d_o;
                    // Diagonal rounds, update s[]
                    s[0]  <= qr4_a_o;   s[5]  <= qr4_b_o;   s[10] <= qr4_c_o;   s[15] <= qr4_d_o;
                    s[1]  <= qr5_a_o;   s[6]  <= qr5_b_o;   s[11] <= qr5_c_o;   s[12] <= qr5_d_o;
                    s[2]  <= qr6_a_o;   s[7]  <= qr6_b_o;   s[8]  <= qr6_c_o;   s[13] <= qr6_d_o;
                    s[3]  <= qr7_a_o;   s[4]  <= qr7_b_o;   s[9]  <= qr7_c_o;   s[14] <= qr7_d_o;
                    // Increment round or finish
                    if (round_ctr == 19) begin //if you're at 20 rounds, finish
                        state <= FINISH;
                    end else begin
                        round_ctr <= round_ctr + 1;
                    end
                end
                FINISH: begin
                    // Add original state to result
                    for (i = 0; i < 16; i = i + 1) begin
                        out_state[32*(16-i)-1 -: 32] <= s[i] + s_orig[i];
                    end
                    busy <= 0;
                    done <= 1;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule