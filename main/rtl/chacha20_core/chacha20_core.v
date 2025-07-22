module ChaCha20 (
    input wire clk,
    input wire rst_n,

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
// So col s0 (and down) s1...s3 then diagonals

//Defining the constants that take up some of these spots
localparam C0 = 32'h61707865; // "expa"
localparam C1 = 32'h3320646e; // "nd 3"
localparam C2 = 32'h79622d32; // "2-by"
localparam C3 = 32'h6b206574; // "te k"

reg [511:0] original_state_copy; // Stores the state before rounds begin for final addition
reg [255:0] current_key;
reg [95:0] current_nonce;
reg [31:0] current_counter;
reg [4:0] round_count;

reg busy_reg, done_reg, trng_request_reg;
reg [511:0] out_state_reg;
reg [511:0] full_keystream_block_temp;

assign busy = busy_reg;
assign done = done_reg;
assign trng_request = trng_request_reg;
assign out_state = out_state_reg;

// Wire for the initial state calculation. Using wires and assign is cleaner for pure combo logic.
wire [31:0] s_initial_calc [0:15];

assign s_initial_calc[0]  = C0;
assign s_initial_calc[1]  = C1;
assign s_initial_calc[2]  = C2;
assign s_initial_calc[3]  = C3;
assign s_initial_calc[4]  = current_key[31:0];
assign s_initial_calc[5]  = current_key[63:32];
assign s_initial_calc[6]  = current_key[95:64];
assign s_initial_calc[7]  = current_key[127:96];
assign s_initial_calc[8]  = current_key[159:128];
assign s_initial_calc[9]  = current_key[191:160];
assign s_initial_calc[10] = current_key[223:192];
assign s_initial_calc[11] = current_key[255:224];
assign s_initial_calc[12] = current_counter;
assign s_initial_calc[13] = current_nonce[31:0];
assign s_initial_calc[14] = current_nonce[63:32];
assign s_initial_calc[15] = current_nonce[95:64];


// Wires for Quarter Round outputs
wire [31:0] s_col_out [0:15];
wire [31:0] s_double_round_out [0:15];

// QR COLUMN rounds (operating on the current 's' state)
QR U_QR_COL_0 (.in_a(s[0]), .in_b(s[4]), .in_c(s[8]),  .in_d(s[12]), .out_a(s_col_out[0]),  .out_b(s_col_out[4]),  .out_c(s_col_out[8]),  .out_d(s_col_out[12]));
QR U_QR_COL_1 (.in_a(s[1]), .in_b(s[5]), .in_c(s[9]),  .in_d(s[13]), .out_a(s_col_out[1]),  .out_b(s_col_out[5]),  .out_c(s_col_out[9]),  .out_d(s_col_out[13]));
QR U_QR_COL_2 (.in_a(s[2]), .in_b(s[6]), .in_c(s[10]), .in_d(s[14]), .out_a(s_col_out[2]),  .out_b(s_col_out[6]),  .out_c(s_col_out[10]), .out_d(s_col_out[14]));
QR U_QR_COL_3 (.in_a(s[3]), .in_b(s[7]), .in_c(s[11]), .in_d(s[15]), .out_a(s_col_out[3]),  .out_b(s_col_out[7]),  .out_c(s_col_out[11]), .out_d(s_col_out[15]));

// QR DIAGONAL rounds (operating on the state *after* column rounds)
QR U_QR_DIAG_0 (.in_a(s_col_out[0]),  .in_b(s_col_out[5]),  .in_c(s_col_out[10]), .in_d(s_col_out[15]), .out_a(s_double_round_out[0]),  .out_b(s_double_round_out[5]),  .out_c(s_double_round_out[10]), .out_d(s_double_round_out[15]));
QR U_QR_DIAG_1 (.in_a(s_col_out[1]),  .in_b(s_col_out[6]),  .in_c(s_col_out[11]), .in_d(s_col_out[12]), .out_a(s_double_round_out[1]),  .out_b(s_double_round_out[6]),  .out_c(s_double_round_out[11]), .out_d(s_double_round_out[12]));
QR U_QR_DIAG_2 (.in_a(s_col_out[2]),  .in_b(s_col_out[7]),  .in_c(s_col_out[8]),  .in_d(s_col_out[13]), .out_a(s_double_round_out[2]),  .out_b(s_double_round_out[7]),  .out_c(s_double_round_out[8]),  .out_d(s_double_round_out[13]));
QR U_QR_DIAG_3 (.in_a(s_col_out[3]),  .in_b(s_col_out[4]),  .in_c(s_col_out[9]),  .in_d(s_col_out[14]), .out_a(s_double_round_out[3]),  .out_b(s_double_round_out[4]),  .out_c(s_double_round_out[9]),  .out_d(s_double_round_out[14]));

// Creating the finite state machine that will handle this --> When clock clicks the state updates

//Now all the different states of this machine. The hex-decimals count from 0-17 in binary and can be compared to the fsm_state variables below

localparam  S_IDLE                 = 4'h0;
localparam  S_ACQUIRE_KEY          = 4'h1;
localparam  S_ACQUIRE_NONCE        = 4'h2;
localparam  S_ACQUIRE_COUNTER      = 4'h3;
localparam  S_INIT_STATE_MATRIX    = 4'h4;
localparam  S_COPY_INITIAL_STATE   = 4'h5;
localparam  S_RUN_ROUNDS           = 4'h6;
localparam  S_GENERATE_OUTPUT      = 4'h7;
localparam  S_DONE_PULSE           = 4'h8;

reg [3:0] current_fsm_state, next_fsm_state; // Changed to 4 bits
reg [2:0] chunk_index;

always @(*) begin
    next_fsm_state = current_fsm_state;
    trng_request_reg = 1'b0;

    case (current_fsm_state)
        S_IDLE : begin
                if (start) begin
                    next_fsm_state = S_ACQUIRE_KEY;
                end
            end
            S_ACQUIRE_KEY : begin
                trng_request_reg = 1'b1;
                if (trng_ready && chunk_index == 3'h7) begin
                    next_fsm_state = S_ACQUIRE_NONCE;
                end
            end
            S_ACQUIRE_NONCE : begin
                trng_request_reg = 1'b1;
                if (trng_ready && chunk_index == 3'h2) begin
                    next_fsm_state = S_ACQUIRE_COUNTER;
                end
            end
            S_ACQUIRE_COUNTER : begin
                trng_request_reg = 1'b1;
                if (trng_ready) begin
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
        trng_request_reg <= 1'b0;

        round_count <= 5'b0;
        current_key <= 256'b0;
        current_nonce <= 96'b0;
        current_counter <= 32'b0;
        chunk_index <= 3'b0;
        original_state_copy <= 512'b0;
        

        for (int i = 0; i < 16; i++) begin // Reset all the s 32 bit registers
            s[i] <= 0;
        end

    end else begin // The action on the clock edge.

        current_fsm_state <= next_fsm_state; // Update to the next state
        busy_reg <= 1'b1; // Default busy unless in IDLE or DONE
        done_reg <= 1'b0;
        out_state_reg <= 512'b0;

        case (current_fsm_state) // What to do at each state
            S_IDLE: begin
                busy_reg <= 1'b0;
                done_reg <= 1'b0;

                round_count <= 5'd0;
                chunk_index <= 3'd0;
            end
            S_ACQUIRE_KEY: begin
                if (trng_ready) begin
                    case (chunk_index)
                        3'h0: current_key[31:0] <= trng_data;
                        3'h1: current_key[63:32] <= trng_data;
                        3'h2: current_key[95:64] <= trng_data;
                        3'h3: current_key[127:96] <= trng_data;
                        3'h4: current_key[159:128] <= trng_data;
                        3'h5: current_key[191:160] <= trng_data;
                        3'h6: current_key[223:192] <= trng_data;
                        3'h7: current_key[255:224] <= trng_data;
                        default: ; // Safety, should not be reached
                    endcase
                    chunk_index <= chunk_index + 1'b1; // Increment chunk_index
                end
            end
            S_ACQUIRE_NONCE: begin
                if (trng_ready) begin
                    case (chunk_index)
                        3'h0: current_nonce[31:0] <= trng_data;
                        3'h1: current_nonce[63:32] <= trng_data;
                        3'h2: current_nonce[95:64] <= trng_data;
                        default: ;
                    endcase
                    chunk_index <= chunk_index + 1'b1;
                end
            end
            S_ACQUIRE_COUNTER: begin
                if (trng_ready) begin
                    current_counter <= trng_data;
                    chunk_index <= chunk_index + 1'b1; // Reset to 0 after this state? Or just let it count.
                end
            end
            // Other states' specific sequential assignments will go here:
            S_INIT_STATE_MATRIX: begin
                
                for (int i = 0; i < 16; i = i + 1) begin
                s[i] <= s_initial_calc[i];
            end

                round_count <= 5'd0;
            end
            S_COPY_INITIAL_STATE: begin
                // CRITICAL: Make a copy of the *initial* state immediately after loading 's'
                // This copy is used in the final keystream generation step.
                original_state_copy <= {
                    s[15], s[14], s[13], s[12],
                    s[11], s[10], s[9], s[8],
                    s[7],  s[6],  s[5],  s[4],
                    s[3],  s[2],  s[1],  s[0]
                };
            end
            S_RUN_ROUNDS: begin
                // Update 's' array with the results of the completed double round
                s[0]  <= s_double_round_out[0];
                s[1]  <= s_double_round_out[1];
                s[2]  <= s_double_round_out[2];
                s[3]  <= s_double_round_out[3];
                s[4]  <= s_double_round_out[4];
                s[5]  <= s_double_round_out[5];
                s[6]  <= s_double_round_out[6];
                s[7]  <= s_double_round_out[7];
                s[8]  <= s_double_round_out[8];
                s[9]  <= s_double_round_out[9];
                s[10] <= s_double_round_out[10];
                s[11] <= s_double_round_out[11];
                s[12] <= s_double_round_out[12];
                s[13] <= s_double_round_out[13];
                s[14] <= s_double_round_out[14];
                s[15] <= s_double_round_out[15];

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
            default: begin // All other states where processing occurs
                busy_reg <= 1'b1;
                done_reg <= 1'b0;
            end
        endcase

        // If a state transitions, reset chunk_index for the new phase
        if (current_fsm_state == S_ACQUIRE_KEY && next_fsm_state == S_ACQUIRE_NONCE) begin
            chunk_index <= 3'b0; // Reset for nonce acquisition
        end else if (current_fsm_state == S_ACQUIRE_NONCE && next_fsm_state == S_ACQUIRE_COUNTER) begin
            chunk_index <= 3'b0; // Reset for counter acquisition
        end else if (current_fsm_state == S_ACQUIRE_COUNTER && next_fsm_state == S_INIT_STATE_MATRIX) begin
            chunk_index <= 3'b0; // Reset for next phase
        end

    end
end

endmodule