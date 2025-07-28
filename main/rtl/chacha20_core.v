module ChaCha20 (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [255:0] key,
    input wire [95:0] nonce,
    input wire [31:0] counter,
    input wire [511:0] plaintext,
    output reg [511:0] ciphertext,
    output reg done,
    output reg busy
);

    // ChaCha20 constants
    localparam [31:0] C0 = 32'h61707865; // "expa"
    localparam [31:0] C1 = 32'h3320646e; // "nd 3"
    localparam [31:0] C2 = 32'h79622d32; // "2-by"
    localparam [31:0] C3 = 32'h6b206574; // "te k"

    // State matrix (16 words)
    reg [31:0] state [0:15];    // This will act as the 'working' state
    reg [31:0] original [0:15]; // Stores the initial state for final addition

    // Control FSM
    reg [4:0] round_count;
    reg [2:0] fsm_state;

    // FSM State Definitions
    localparam IDLE     = 3'b000;
    localparam INIT     = 3'b001;
    localparam ROUND    = 3'b010;
    localparam OUTPUT   = 3'b011;
    localparam COMPLETE = 3'b100;

    // Intermediate wires for connecting QR module instances
    // These hold the combinatorial outputs of the column rounds
    wire [31:0] col_out_s0, col_out_s4, col_out_s8, col_out_s12;
    wire [31:0] col_out_s1, col_out_s5, col_out_s9, col_out_s13;
    wire [31:0] col_out_s2, col_out_s6, col_out_s10, col_out_s14;
    wire [31:0] col_out_s3, col_out_s7, col_out_s11, col_out_s15;

    // These hold the combinatorial outputs of the diagonal rounds
    wire [31:0] diag_out_s0, diag_out_s5, diag_out_s10, diag_out_s15;
    wire [31:0] diag_out_s1, diag_out_s6, diag_out_s11, diag_out_s12;
    wire [31:0] diag_out_s2, diag_out_s7, diag_out_s8, diag_out_s13;
    wire [31:0] diag_out_s3, diag_out_s4, diag_out_s9, diag_out_s14;


    QR U_QR_COL_0 (.in_a(state[0]), .in_b(state[4]), .in_c(state[8]),  .in_d(state[12]), .out_a(col_out_s0),  .out_b(col_out_s4),  .out_c(col_out_s8),  .out_d(col_out_s12));
    QR U_QR_COL_1 (.in_a(state[1]), .in_b(state[5]), .in_c(state[9]),  .in_d(state[13]), .out_a(col_out_s1),  .out_b(col_out_s5),  .out_c(col_out_s9),  .out_d(col_out_s13));
    QR U_QR_COL_2 (.in_a(state[2]), .in_b(state[6]), .in_c(state[10]), .in_d(state[14]), .out_a(col_out_s2),  .out_b(col_out_s6),  .out_c(col_out_s10), .out_d(col_out_s14));
    QR U_QR_COL_3 (.in_a(state[3]), .in_b(state[7]), .in_c(state[11]), .in_d(state[15]), .out_a(col_out_s3),  .out_b(col_out_s7),  .out_c(col_out_s11), .out_d(col_out_s15));

    // Diagonal Rounds: Take column round outputs as input
    QR U_QR_DIAG_0 (.in_a(col_out_s0), .in_b(col_out_s5), .in_c(col_out_s10), .in_d(col_out_s15), .out_a(diag_out_s0), .out_b(diag_out_s5), .out_c(diag_out_s10), .out_d(diag_out_s15));
    QR U_QR_DIAG_1 (.in_a(col_out_s1), .in_b(col_out_s6), .in_c(col_out_s11), .in_d(col_out_s12), .out_a(diag_out_s1), .out_b(diag_out_s6), .out_c(diag_out_s11), .out_d(diag_out_s12));
    QR U_QR_DIAG_2 (.in_a(col_out_s2), .in_b(col_out_s7), .in_c(col_out_s8),  .in_d(col_out_s13), .out_a(diag_out_s2), .out_b(diag_out_s7), .out_c(diag_out_s8),  .out_d(diag_out_s13));
    QR U_QR_DIAG_3 (.in_a(col_out_s3), .in_b(col_out_s4), .in_c(col_out_s9),  .in_d(col_out_s14), .out_a(diag_out_s3), .out_b(diag_out_s4), .out_c(diag_out_s9),  .out_d(diag_out_s14));
    // Main FSM and data path logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Asynchronous reset
            fsm_state <= IDLE;
            round_count <= 0;
            done <= 0;
            busy <= 0;
            ciphertext <= 0;
            // Initialize state and original arrays to zero on reset
            for (int i = 0; i < 16; i = i + 1) begin
                state[i] <= 32'b0;
                original[i] <= 32'b0;
            end
        end else begin
            // Synchronous state updates
            case (fsm_state)
                IDLE: begin
                    done <= 0; // Ensure done is low when idle
                    if (start) begin
                        busy <= 1; // Indicate that the module is busy
                        fsm_state <= INIT;
                        round_count <= 0;
                         state[0] <= C0;           // "expa"
                    state[1] <= C1;           // "nd 3"
                    state[2] <= C2;           // "2-by"
                    state[3] <= C3;           // "te k"
                    state[4] <= key[31:0];    // key[0]
                    state[5] <= key[63:32];   // key[1]
                    state[6] <= key[95:64];   // key[2]
                    state[7] <= key[127:96];  // key[3]
                    state[8] <= key[159:128]; // key[4]
                    state[9] <= key[191:160]; // key[5]
                    state[10] <= key[223:192]; // key[6]
                    state[11] <= key[255:224]; // key[7]
                    state[12] <= counter;      // counter
                    state[13] <= nonce[31:0];  // nonce[0]
                    state[14] <= nonce[63:32]; // nonce[1]
                    state[15] <= nonce[95:64]; // nonce[2]
                    end else begin
                        busy <= 0; // Not busy if start is not asserted
                    end
                end

                INIT: begin
                    // Initialize state matrix per RFC 8439
                    // Assuming key, nonce, and counter inputs are already in the correct
                    // 32-bit little-endian word order. No byte reordering is performed here

                    // Copy the initial state to 'original' for final addition
                    for (int i = 0; i < 16; i = i + 1) begin
                        original[i] <= state[i];
                    end

                    fsm_state <= ROUND; // Move to the round computation phase
                end

                ROUND: begin
                    // Perform 10 double rounds (20 total rounds)
                    if (round_count < 10) begin
                        // The QR logic is now outside. We just latch its results
                        // from the 'diag_out' wires into the 'state' registers.
                        state[0] <= diag_out_s0;
                        state[1] <= diag_out_s1;
                        state[2] <= diag_out_s2;
                        state[3] <= diag_out_s3;
                        state[4] <= diag_out_s4;
                        state[5] <= diag_out_s5;
                        state[6] <= diag_out_s6;
                        state[7] <= diag_out_s7;
                        state[8] <= diag_out_s8;
                        state[9] <= diag_out_s9;
                        state[10] <= diag_out_s10;
                        state[11] <= diag_out_s11;
                        state[12] <= diag_out_s12;
                        state[13] <= diag_out_s13;
                        state[14] <= diag_out_s14;
                        state[15] <= diag_out_s15;

                        round_count <= round_count + 1;
                    end else begin
                        fsm_state <= OUTPUT; // All rounds completed
                    end
                end

                OUTPUT: begin
                    // Add the original state to the final working state (after rounds)
                    // and then XOR with the plaintext to produce the ciphertext.
                    // The concatenation ensures correct word order for the 512-bit block.
                    ciphertext <= {
                        (state[15] + original[15]) ^ plaintext[511:480],
                        (state[14] + original[14]) ^ plaintext[479:448],
                        (state[13] + original[13]) ^ plaintext[447:416],
                        (state[12] + original[12]) ^ plaintext[415:384],
                        (state[11] + original[11]) ^ plaintext[383:352],
                        (state[10] + original[10]) ^ plaintext[351:320],
                        (state[9] + original[9]) ^ plaintext[319:288],
                        (state[8] + original[8]) ^ plaintext[287:256],
                        (state[7] + original[7]) ^ plaintext[255:224],
                        (state[6] + original[6]) ^ plaintext[223:192],
                        (state[5] + original[5]) ^ plaintext[191:160],
                        (state[4] + original[4]) ^ plaintext[159:128],
                        (state[3] + original[3]) ^ plaintext[127:96],
                        (state[2] + original[2]) ^ plaintext[95:64],
                        (state[1] + original[1]) ^ plaintext[63:32],
                        (state[0] + original[0]) ^ plaintext[31:0]
                    };
                    fsm_state <= COMPLETE; // Move to completion state
                end

                COMPLETE: begin
                    done <= 1; // Signal that the operation is complete
                    busy <= 0; // Not busy anymore
                    fsm_state <= IDLE; // Return to idle, ready for next operation
                end

                default: fsm_state <= IDLE; // Safety default
            endcase
        end
    end

endmodule