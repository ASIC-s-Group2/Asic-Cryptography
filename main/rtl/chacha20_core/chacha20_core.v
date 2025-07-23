module ChaCha20 (
    input wire clk,
    input wire rst_n, // Active-low reset input

    input wire start, // Start signal for the operation
    output wire busy, // Indicates core is processing
    output wire done, // Indicates operation is complete

    // Direct inputs for Key, Nonce, and Counter (TRNG acquisition removed)
    input wire [255:0] in_key,
    input wire [95:0]  in_nonce,
    input wire [31:0]  in_counter,

    input wire [511:0] in_state, // Main data input (plaintext for encrypt, ciphertext for decrypt)
    output wire [511:0] out_state, // Main data output (ciphertext for encrypt, plaintext for decrypt)

    // --- Temporary Debug Ports (for waveform visibility) ---
    output wire [511:0] debug_s,             // Current 's' state array
    output wire [511:0] debug_s_col_out,     // Output of column round (combinatorial)
    output wire [511:0] debug_s_round_result, // Output of diagonal round (combinatorial)
    output wire [3:0] debug_fsm_state,
    output wire [4:0] debug_round_count,
    output wire       debug_is_col_round
);

// Define the number of double-rounds (10 for ChaCha20)
localparam NUM_DOUBLE_ROUNDS = 10;

// ChaCha20 Internal State Register
reg [31:0] s [0:15]; // Array of 16 32-bit registers for the ChaCha20 state

// Debug Port Concatenations (connects internal arrays to 512-bit output wires)
assign debug_s = {s[15], s[14], s[13], s[12], s[11], s[10], s[9], s[8], s[7], s[6], s[5], s[4], s[3], s[2], s[1], s[0]};
assign debug_s_col_out = {s_col_out[15], s_col_out[14], s_col_out[13], s_col_out[12], s_col_out[11], s_col_out[10], s_col_out[9], s_col_out[8], s_col_out[7], s_col_out[6], s_col_out[5], s_col_out[4], s_col_out[3], s_col_out[2], s_col_out[1], s_col_out[0]};
assign debug_s_round_result = {s_round_result[15], s_round_result[14], s_round_result[13], s_round_result[12], s_round_result[11], s_round_result[10], s_round_result[9], s_round_result[8], s_round_result[7], s_round_result[6], s_round_result[5], s_round_result[4], s_round_result[3], s_round_result[2], s_round_result[1], s_round_result[0]};
assign debug_fsm_state = current_fsm_state;
assign debug_round_count = round_count;
assign debug_is_col_round = current_round_is_col;
// Defining the constants for the initial state
localparam C0 = 32'h61707865; // "expa"
localparam C1 = 32'h3320646e; // "nd 3"
localparam C2 = 32'h79622d32; // "2-by"
localparam C3 = 32'h6b206574; // "te k"

// Internal registers for FSM and data path
reg [511:0] original_state_copy; // Stores initial s state for final addition
reg [4:0] round_count;             // Tracks double-rounds (0 to NUM_DOUBLE_ROUNDS-1)
reg current_round_is_col; // 0: Diagonal round stage, 1: Column round stage
reg busy_reg;                      // Internal busy status register
reg done_reg;                      // Internal done status register
reg [511:0] out_state_reg;         // Internal register for out_state port
reg [511:0] full_keystream_block_temp; // Temporary storage for the 512-bit keystream

// Assign internal status registers to output ports
assign busy = busy_reg;
assign done = done_reg;
assign out_state = out_state_reg;


// --- Pipelined Round Logic (Combinatorial) ---
// These wires hold the combinatorial outputs of the QR instances
wire [31:0] s_col_out[0:15];      // Output of the column rounds (combinatorial)
wire [31:0] s_round_result[0:15]; // Output of the diagonal rounds (combinatorial)

// Register to pipeline the column round output into the diagonal round input
// This allows column round to happen in one cycle, diagonal in the next.
reg [31:0] s_col_reg[0:15]; 

// QR COLUMN rounds (operating on the current 's' state)
// s_col_out[i] represents the element at matrix position 'i' after column QR.
QR U_QR_COL_0 (.in_a(s[0]), .in_b(s[4]), .in_c(s[8]),  .in_d(s[12]), .out_a(s_col_out[0]),  .out_b(s_col_out[4]),  .out_c(s_col_out[8]),  .out_d(s_col_out[12]));
QR U_QR_COL_1 (.in_a(s[1]), .in_b(s[5]), .in_c(s[9]),  .in_d(s[13]), .out_a(s_col_out[1]),  .out_b(s_col_out[5]),  .out_c(s_col_out[9]),  .out_d(s_col_out[13]));
QR U_QR_COL_2 (.in_a(s[2]), .in_b(s[6]), .in_c(s[10]), .in_d(s[14]), .out_a(s_col_out[2]),  .out_b(s_col_out[6]),  .out_c(s_col_out[10]), .out_d(s_col_out[14]));
QR U_QR_COL_3 (.in_a(s[3]), .in_b(s[7]), .in_c(s[11]), .in_d(s[15]), .out_a(s_col_out[3]),  .out_b(s_col_out[7]),  .out_c(s_col_out[11]), .out_d(s_col_out[15]));

// QR DIAGONAL rounds (operating on the *registered* state after column rounds)
// s_round_result[i] represents the element at matrix position 'i' after diagonal QR.
QR U_QR_DIAG_0 (.in_a(s_col_reg[0]),  .in_b(s_col_reg[5]),  .in_c(s_col_reg[10]), .in_d(s_col_reg[15]), .out_a(s_round_result[0]),  .out_b(s_round_result[5]),  .out_c(s_round_result[10]), .out_d(s_round_result[15]));
QR U_QR_DIAG_1 (.in_a(s_col_reg[1]),  .in_b(s_col_reg[6]),  .in_c(s_col_reg[11]), .in_d(s_col_reg[12]), .out_a(s_round_result[1]),  .out_b(s_round_result[6]),  .out_c(s_round_result[11]), .out_d(s_round_result[12]));
QR U_QR_DIAG_2 (.in_a(s_col_reg[2]),  .in_b(s_col_reg[7]),  .in_c(s_col_reg[8]),  .in_d(s_col_reg[13]), .out_a(s_round_result[2]),  .out_b(s_round_result[7]),  .out_c(s_round_result[8]),  .out_d(s_round_result[13]));
QR U_QR_DIAG_3 (.in_a(s_col_reg[3]),  .in_b(s_col_reg[4]),  .in_c(s_col_reg[9]),  .in_d(s_col_reg[14]), .out_a(s_round_result[3]),  .out_b(s_round_result[4]),  .out_c(s_round_result[9]),  .out_d(s_round_result[14]));

// Finite State Machine (FSM) State Definitions
// These map to clock-cycle stages of the operation.
localparam  S_IDLE                 = 4'h0; // Core is waiting for a start signal
localparam  S_INIT_AND_COPY        = 4'h1; // Initialize 's' and 'original_state_copy' from inputs
localparam  S_RUN_ROUNDS           = 4'h2; // Perform Diagonal Round, latch results into 's' and increment round_count
localparam  S_GENERATE_OUTPUT      = 4'h3; // Generate keystream and final output
localparam  S_DONE_PULSE           = 4'h4; // Signal completion for one cycle

reg [3:0] current_fsm_state, next_fsm_state;

// FSM: Combinatorial Next State Logic
// Determines 'next_fsm_state' based on 'current_fsm_state' and inputs.
always @(*) begin
    next_fsm_state = current_fsm_state; // Default: stay in current state (unless transition condition met)

    case (current_fsm_state)
        S_IDLE : begin
            if (start) begin // If start signal is asserted, begin operation
                next_fsm_state = S_INIT_AND_COPY;
            end
        end
        S_INIT_AND_COPY : begin
        next_fsm_state = S_RUN_ROUNDS; // Move to the rounds super-state
        end
        S_RUN_ROUNDS : begin // This state runs for 20 cycles (10 double-rounds)
             if (round_count == (NUM_DOUBLE_ROUNDS - 1) && !current_round_is_col) begin
                next_fsm_state = S_GENERATE_OUTPUT;
            end else begin
                next_fsm_state = S_RUN_ROUNDS;
            end
        end
        // The logic for column/diagonal decision happens inside S_RUN_ROUNDS sequential block
        S_GENERATE_OUTPUT : begin // Final output calculation
            next_fsm_state = S_DONE_PULSE; // Move to signal completion
        end
        S_DONE_PULSE : begin // Signal completion for one cycle, then return to idle
            next_fsm_state = S_IDLE;
        end
        default: begin // Safety default for any undefined states
            next_fsm_state = S_IDLE;
        end
    endcase
end

// FSM: Sequential Logic
// Updates current_fsm_state and registers based on clock edge and reset.
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin // Reset the whole machine and core to initial state
        current_fsm_state <= S_IDLE;
        busy_reg <= 1'b0;
        done_reg <= 1'b0;
        round_count <= 5'd0; // Reset round counter (0-9 for 10 double-rounds)
        current_round_is_col <= 1'b1;
        original_state_copy <= 512'b0; // Reset original state copy
        out_state_reg <= 512'b0; // Reset output register
        full_keystream_block_temp <= 512'b0; // Reset temporary keystream

        // Reset all internal state arrays
        for (int i = 0; i < 16; i = i + 1) begin
            s[i] <= 32'b0;
            s_col_reg[i] <= 32'b0; // Reset pipelining register
        end
    end else begin // Normal operation: on clock edge
        current_fsm_state <= next_fsm_state; // Update FSM state

        // Default busy/done assignments for active states (overridden below for IDLE/DONE)
        busy_reg <= 1'b1; // Default busy status for active states
        done_reg <= 1'b0; // Default not done by default
        out_state_reg <= 512'b0; // Default output to 0s to prevent X propagation
        full_keystream_block_temp <= 512'b0; // Default to 0s
        
        case (current_fsm_state) // Specific actions for each FSM state
            S_IDLE: begin
                busy_reg <= 1'b0; // Not busy when idle
                done_reg <= 1'b0; // Not done when idle
                round_count <= 5'd0; // Reset round count on starting new operation (or keep it in reset)
                current_round_is_col <= 1'b1;
            end
            S_INIT_AND_COPY: begin
                busy_reg <= 1'b1;
                
                // Load 's' registers
                s[0]  <= C0;
                s[1]  <= C1;
                s[2]  <= C2;
                s[3]  <= C3;
                s[4]  <= {in_key[231:224], in_key[239:232], in_key[247:240], in_key[255:248]}; // K0
                s[5]  <= {in_key[199:192], in_key[207:200], in_key[215:208], in_key[223:216]}; // K1
                s[6]  <= {in_key[167:160], in_key[175:168], in_key[183:176], in_key[191:184]}; // K2
                s[7]  <= {in_key[135:128], in_key[143:136], in_key[151:144], in_key[159:152]}; // K3
                s[8]  <= {in_key[103:96],  in_key[111:104], in_key[119:112], in_key[127:120]}; // K4
                s[9]  <= {in_key[71:64],   in_key[79:72],  in_key[87:80],  in_key[95:88]};   // K5
                s[10] <= {in_key[39:32],   in_key[47:40],  in_key[55:48],  in_key[63:56]};   // K6
                s[11] <= {in_key[7:0],     in_key[15:8],   in_key[23:16],  in_key[31:24]};   // K7
                s[12] <= {in_counter[7:0], in_counter[15:8], in_counter[23:16], in_counter[31:24]};
                s[13] <= {in_nonce[7:0],   in_nonce[15:8],   in_nonce[23:16],   in_nonce[31:24]};
                s[14] <= {in_nonce[39:32], in_nonce[47:40],  in_nonce[55:48],   in_nonce[63:56]};
                s[15] <= {in_nonce[71:64], in_nonce[79:72],  in_nonce[87:80],   in_nonce[95:88]};
                
                // Load 'original_state_copy' with the same values
                original_state_copy <= {
                    {in_nonce[71:64], in_nonce[79:72],  in_nonce[87:80],   in_nonce[95:88]},   // s[15]
                    {in_nonce[39:32], in_nonce[47:40],  in_nonce[55:48],   in_nonce[63:56]},   // s[14]
                    {in_nonce[7:0],   in_nonce[15:8],   in_nonce[23:16],   in_nonce[31:24]},   // s[13]
                    {in_counter[7:0], in_counter[15:8], in_counter[23:16], in_counter[31:24]}, // s[12]
                    {in_key[7:0],     in_key[15:8],   in_key[23:16],  in_key[31:24]},       // s[11]
                    {in_key[39:32],   in_key[47:40],  in_key[55:48],  in_key[63:56]},       // s[10]
                    {in_key[71:64],   in_key[79:72],  in_key[87:80],  in_key[95:88]},       // s[9]
                    {in_key[103:96],  in_key[111:104], in_key[119:112], in_key[127:120]},   // s[8]
                    {in_key[135:128], in_key[143:136], in_key[151:144], in_key[159:152]},   // s[7]
                    {in_key[167:160], in_key[175:168], in_key[183:176], in_key[191:184]},   // s[6]
                    {in_key[199:192], in_key[207:200], in_key[215:208], in_key[223:216]},   // s[5]
                    {in_key[231:224], in_key[239:232], in_key[247:240], in_key[255:248]},   // s[4]
                    C3, C2, C1, C0
                };
            end
            S_RUN_ROUNDS: begin
                if (current_round_is_col) begin // Execute Column Round actions
                    for (int i = 0; i < 16; i = i + 1) begin
                        s_col_reg[i] <= s_col_out[i];
                    end
                    current_round_is_col <= 1'b0; // Switch to Diagonal for next cycle
                end else begin // Execute Diagonal Round actions
                    for (int i = 0; i < 16; i++) begin
                        s[i] <= s_round_result[i];
                    end
                    round_count <= round_count + 1'b1; // Increment double-round counter
                    current_round_is_col <= 1'b1; // Switch back to Column for next double-round
                end
            end
            S_GENERATE_OUTPUT: begin
                // Calculate full keystream block (final s + original_state_copy)
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
            S_DONE_PULSE : begin
                out_state_reg <= in_state ^ full_keystream_block_temp;
                busy_reg <= 1'b0; // Not busy anymore
                done_reg <= 1'b1; // Signal completion
            end
            default: begin
                // busy_reg, done_reg, out_state_reg, full_keystream_block_temp
                // are set by defaults at the start of the 'else' block.
            end
        endcase
    end
end

endmodule