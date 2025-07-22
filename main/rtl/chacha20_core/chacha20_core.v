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

// Wires for column round outputs
wire [31:0] s_col_out [0:15]; // Holds the state after column rounds
// Wires for diagonal round outputs
wire [31:0] s_double_round_out [0:15]; // Holds the state after a full double round

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

localparam  S_IDLE                 = 3'h0;
localparam  S_ACQUIRE_KEY          = 3'h1;
localparam  S_ACQUIRE_NONCE        = 3'h2;
localparam  S_ACQUIRE_COUNTER      = 3'h3;
localparam  S_INIT_STATE_MATRIX    = 3'h4;
localparam  S_RUN_ROUNDS           = 3'h5;
localparam  S_GENERATE_OUTPUT      = 3'h6;
localparam  S_DONE_PULSE           = 3'h7;

reg [2:0] current_fsm_state, next_fsm_state, chunk_index; // The chunk is a sort of substate to use as we move through the key and nonce peice by peice

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
                next_fsm_state = S_RUN_ROUNDS;
            end
            S_RUN_ROUNDS : begin
                if (round_count == 4'h14) begin
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

        case (current_fsm_state) // What to do at each state
            S_IDLE: begin
                busy_reg <= 1'b0;
                done_reg <= 1'b0;
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
                // Row 0: Constants
                s[0]  <= C0;
                s[1]  <= C1;
                s[2]  <= C2;
                s[3]  <= C3;

                // Row 1-3: Key (8 words = 256 bits)
                s[4]  <= current_key[31:0];     // Key Word 0
                s[5]  <= current_key[63:32];    // Key Word 1
                s[6]  <= current_key[95:64];    // Key Word 2
                s[7]  <= current_key[127:96];   // Key Word 3
                s[8]  <= current_key[159:128];  // Key Word 4
                s[9]  <= current_key[191:160];  // Key Word 5
                s[10] <= current_key[223:192];  // Key Word 6
                s[11] <= current_key[255:224];  // Key Word 7

                // Row 4 (part): Counter (1 word = 32 bits)
                s[12] <= current_counter;

                // Row 4 (remainder): Nonce (3 words = 96 bits)
                s[13] <= current_nonce[31:0];   // Nonce Word 0
                s[14] <= current_nonce[63:32];  // Nonce Word 1
                s[15] <= current_nonce[95:64];  // Nonce Word 2

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
                // Logic for encryption/decryption based on 'mode'
                // mode = 1 for encryption (plaintext -> ciphertext)
                // mode = 0 for decryption (ciphertext -> plaintext)
                if (mode == 1'b1) begin // Encryption mode
                    out_state_reg <= in_state ^ full_keystream_block_temp; // plaintext XOR keystream
                end else begin // Decryption mode (mode == 0)
                    out_state_reg <= in_state ^ full_keystream_block_temp; // ciphertext XOR keystream
                end //Final Step :) Notice how they are the same either way this is just for user clarity i guess
            end
            S_DONE_PULSE: begin
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

    always @(posedge clk or posedge rst) begin // Asynchronous reset
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