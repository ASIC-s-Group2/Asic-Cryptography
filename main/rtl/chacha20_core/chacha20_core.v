module ChaCha20 (
    input wire clk,
    input wire rst_n,

    input wire start,
    output wire busy,
    output wire done,

    input wire [255:0] in_key,
    input wire [95:0]  in_nonce,
    input wire [31:0]  in_counter,

    input wire [511:0] in_state,
    output wire [511:0] out_state,

    // --- Temporary Debug Ports ---
    output wire [511:0] debug_s,
    output wire [511:0] debug_s_col_out,
    output wire [511:0] debug_s_round_result
);

//Important Internal State Registers

reg [31:0] s [0:15]; // Array of 16 32-bit registers

// --- Assign internal signals to debug ports ---
    // Concatenate the arrays into 512-bit vectors for output
    assign debug_s = {s[15], s[14], s[13], s[12], s[11], s[10], s[9], s[8], s[7], s[6], s[5], s[4], s[3], s[2], s[1], s[0]};
    assign debug_s_col_out = {s_col_out[15], s_col_out[14], s_col_out[13], s_col_out[12], s_col_out[11], s_col_out[10], s_col_out[9], s_col_out[8], s_col_out[7], s_col_out[6], s_col_out[5], s_col_out[4], s_col_out[3], s_col_out[2], s_col_out[1], s_col_out[0]};
    assign debug_s_round_result = {s_round_result[15], s_round_result[14], s_round_result[13], s_round_result[12], s_round_result[11], s_round_result[10], s_round_result[9], s_round_result[8], s_round_result[7], s_round_result[6], s_round_result[5], s_round_result[4], s_round_result[3], s_round_result[2], s_round_result[1], s_round_result[0]};
/*
Pretend it looks like:
[ s0  s1  s2  s3  ]
[ s4  s5  s6  s7  ]
[ s8  s9 s10 s11 ]
[ s12 s13 s14 s15 ]
*/
// So col s0 (and down) s1...s3 then diagonals

//Defining the constants that take up some of these spots
localparam C0 = 32'h61707865; // "expa"
localparam C1 = 32'h3320646e; // "nd 3"
localparam C2 = 32'h79622d32; // "2-by"
localparam C3 = 32'h6b206574; // "te k"

reg [511:0] original_state_copy; // Stores the state before rounds begin for final addition
reg [4:0] round_count;
reg busy_reg, done_reg;
reg [511:0] out_state_reg;
reg [511:0] full_keystream_block_temp;

assign busy = busy_reg;
assign done = done_reg;
assign out_state = out_state_reg;


// --- SIMPLIFIED AND CORRECTED ROUND LOGIC ---
wire [31:0] s_col_out[0:15];
wire [31:0] s_round_result[0:15]; // Final result of one double-round

// 1. Column Round
QR U_QR_COL_0 (.in_a(s[0]), .in_b(s[4]), .in_c(s[8]),  .in_d(s[12]), .out_a(s_col_out[0]),  .out_b(s_col_out[4]),  .out_c(s_col_out[8]),  .out_d(s_col_out[12]));
QR U_QR_COL_1 (.in_a(s[1]), .in_b(s[5]), .in_c(s[9]),  .in_d(s[13]), .out_a(s_col_out[1]),  .out_b(s_col_out[5]),  .out_c(s_col_out[9]),  .out_d(s_col_out[13]));
QR U_QR_COL_2 (.in_a(s[2]), .in_b(s[6]), .in_c(s[10]), .in_d(s[14]), .out_a(s_col_out[2]),  .out_b(s_col_out[6]),  .out_c(s_col_out[10]), .out_d(s_col_out[14]));
QR U_QR_COL_3 (.in_a(s[3]), .in_b(s[7]), .in_c(s[11]), .in_d(s[15]), .out_a(s_col_out[3]),  .out_b(s_col_out[7]),  .out_c(s_col_out[11]), .out_d(s_col_out[15]));

// 2. Diagonal Round (with corrected direct wiring)
// The outputs from the column round are wired directly to the inputs of the
// diagonal round in their "rotated" positions. The outputs of the diagonal
// round are wired to the s_round_result array in the same rotated positions.
QR U_QR_DIAG_0 (.in_a(s_col_out[0]), .in_b(s_col_out[5]), .in_c(s_col_out[10]), .in_d(s_col_out[15]), .out_a(s_round_result[0]),  .out_b(s_round_result[5]),  .out_c(s_round_result[10]), .out_d(s_round_result[15]));
QR U_QR_DIAG_1 (.in_a(s_col_out[1]), .in_b(s_col_out[6]), .in_c(s_col_out[11]), .in_d(s_col_out[12]), .out_a(s_round_result[1]),  .out_b(s_round_result[6]),  .out_c(s_round_result[11]), .out_d(s_round_result[12]));
QR U_QR_DIAG_2 (.in_a(s_col_out[2]), .in_b(s_col_out[7]), .in_c(s_col_out[8]),  .in_d(s_col_out[13]), .out_a(s_round_result[2]),  .out_b(s_round_result[7]),  .out_c(s_round_result[8]),  .out_d(s_round_result[13]));
QR U_QR_DIAG_3 (.in_a(s_col_out[3]), .in_b(s_col_out[4]), .in_c(s_col_out[9]),  .in_d(s_col_out[14]), .out_a(s_round_result[3]),  .out_b(s_round_result[4]),  .out_c(s_round_result[9]),  .out_d(s_round_result[14]));

// Creating the finite state machine that will handle this --> When clock clicks the state updates

//Now all the different states of this machine.

localparam  S_IDLE                 = 4'h0;
localparam  S_INIT_STATE_MATRIX    = 4'h1;
localparam  S_COPY_INITIAL_STATE   = 4'h2;
localparam  S_RUN_ROUNDS           = 4'h3;
localparam  S_GENERATE_OUTPUT      = 4'h4;
localparam  S_DONE_PULSE           = 4'h5;

reg [3:0] current_fsm_state, next_fsm_state;

always @(*) begin
    next_fsm_state = current_fsm_state;

    case (current_fsm_state)
        S_IDLE : begin
                if (start) begin
                    next_fsm_state = S_INIT_STATE_MATRIX;
                end
            end
            S_INIT_STATE_MATRIX : begin
                next_fsm_state = S_COPY_INITIAL_STATE;
            end
            S_COPY_INITIAL_STATE : begin
                next_fsm_state = S_RUN_ROUNDS;
             end
             S_RUN_ROUNDS : begin
                if (round_count == 5'd9) begin
                   next_fsm_state = S_GENERATE_OUTPUT;
                end
            end
            S_GENERATE_OUTPUT : begin
                next_fsm_state = S_DONE_PULSE;
            end
            S_DONE_PULSE : begin
                next_fsm_state = S_IDLE;
            end
            default: begin
                next_fsm_state = S_IDLE;
            end
    endcase

end


always @(posedge clk or negedge rst_n) begin // The main machine action on clock or reset
    if (!rst_n) begin // Reset the whole machine and core

        current_fsm_state <= S_IDLE;
        busy_reg <= 1'b0;
        done_reg <= 1'b0;
        round_count <= 5'b0;
        original_state_copy <= 512'b0;
        out_state_reg <= 512'b0;
        full_keystream_block_temp <= 512'b0;
        
        for (int i = 0; i < 16; i = i + 1) begin // Reset all the s 32 bit registers
            s[i] <= 32'b0;
        end

    end else begin // The action on the clock edge.

        current_fsm_state <= next_fsm_state; // Update to the next state
        done_reg <= 1'b0;
        busy_reg <= 1'b1;

        case (current_fsm_state) // What to do at each state
            S_IDLE: begin
                busy_reg <= 1'b0;
                round_count <= 5'd0;
            end
            S_INIT_STATE_MATRIX: begin
                busy_reg <= 1'b1;
                s[0]  <= C0;
                s[1]  <= C1;
                s[2]  <= C2;
                s[3]  <= C3;

                // Load Key (RFC 8439 specifies little-endian loading)
                // This requires byte-swapping each 32-bit word from the input vector.
                s[4]  <= {in_key[231:224], in_key[239:232], in_key[247:240], in_key[255:248]}; // Word 0
                s[5]  <= {in_key[199:192], in_key[207:200], in_key[215:208], in_key[223:216]}; // Word 1
                s[6]  <= {in_key[167:160], in_key[175:168], in_key[183:176], in_key[191:184]}; // Word 2
                s[7]  <= {in_key[135:128], in_key[143:136], in_key[151:144], in_key[159:152]}; // Word 3
                s[8]  <= {in_key[103:96],  in_key[111:104], in_key[119:112], in_key[127:120]}; // Word 4
                s[9]  <= {in_key[71:64],   in_key[79:72],   in_key[87:80],   in_key[95:88]};   // Word 5
                s[10] <= {in_key[39:32],   in_key[47:40],   in_key[55:48],   in_key[63:56]};   // Word 6
                s[11] <= {in_key[7:0],     in_key[15:8],    in_key[23:16],   in_key[31:24]};   // Word 7

                // Load Counter and Nonce (also little-endian)
                s[12] <= {in_counter[7:0], in_counter[15:8], in_counter[23:16], in_counter[31:24]};
                s[13] <= {in_nonce[71:64], in_nonce[79:72], in_nonce[87:80], in_nonce[95:88]};     // Word 0 of nonce
                s[14] <= {in_nonce[39:32], in_nonce[47:40], in_nonce[55:48], in_nonce[63:56]};     // Word 1 of nonce
                s[15] <= {in_nonce[7:0],   in_nonce[15:8],  in_nonce[23:16], in_nonce[31:24]};     // Word 2 of nonce
            end
            S_COPY_INITIAL_STATE: begin
                // Make a copy of the state immediately after loading 's' --> used in the final keystream generation step.
                original_state_copy <= {
                    s[15], s[14], s[13], s[12],
                    s[11], s[10], s[9], s[8],
                    s[7],  s[6],  s[5],  s[4],
                    s[3],  s[2],  s[1],  s[0]
                };
            end
            S_RUN_ROUNDS: begin
                for (int i = 0; i < 16; i = i + 1) begin
                    s[i] <= s_round_result[i];
                end
                round_count <= round_count + 1'b1; // Increment round counter
            end
            S_GENERATE_OUTPUT: begin
                full_keystream_block_temp <= {
                    s[15] + original_state_copy[511:480],
                    s[14] + original_state_copy[479:448],
                    s[13] + original_state_copy[447:416],
                    s[12] + original_state_copy[415:384],
                    s[11] + original_state_copy[383:352],
                    s[10] + original_state_copy[351:320],
                    s[9]  + original_state_copy[319:288],
                    s[8]  + original_state_copy[287:256],
                    s[7]  + original_state_copy[255:224],
                    s[6]  + original_state_copy[223:192],
                    s[5]  + original_state_copy[191:160],
                    s[4]  + original_state_copy[159:128],
                    s[3]  + original_state_copy[127:96],
                    s[2]  + original_state_copy[95:64],
                    s[1]  + original_state_copy[63:32],
                    s[0]  + original_state_copy[31:0]
                };
            end
            S_DONE_PULSE: begin
                out_state_reg <= in_state ^ full_keystream_block_temp;
                busy_reg <= 1'b0;
                done_reg <= 1'b1;
            end
        endcase
    end
end

endmodule