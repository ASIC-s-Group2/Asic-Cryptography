//======================================================================
// chacha20_keyinput.v
// -------------------
// Top-level wrapper for the ChaCha20 stream cipher core, providing
// a simple memory-mapped interface with 32-bit data access.
// 
// *** This version takes the key as a direct input port, NOT via register writes. ***
// - 256-bit key input only (no Poly1305, no 128-bit mode)
// - 64-bit counter
// - 64-bit IV (nonce) [for RFC compliance, use 96-bit IV if needed]
// - 20 rounds, fixed
//

//BASED ON
// Copyright (c) 2013  Secworks Sweden AB
//
//======================================================================

module chacha20_keyinput (
    input  wire        clk,          // Clock input
    input  wire        reset_n,      // Active-low reset
    input  wire        cs,           // Chip select (active high)
    input  wire        we,           // Write enable (high for writes)
    input  wire [7:0]  addr,         // 8-bit address bus
    input  wire [31:0] write_data,   // 32-bit data input for writes
    output wire [31:0] read_data     // 32-bit data output for reads
    // input  wire [255:0] key,      // <<< REMOVED: Key is no longer a direct input.
);

    // ---------------------------------------------------------------
    // Address map for memory-mapped registers
    // ---------------------------------------------------------------
    localparam ADDR_CTRL         = 8'h08; // Control register address
    localparam ADDR_STATUS       = 8'h09; // Status register address

    // <<< ADDED: Key register addresses (0x10 - 0x17)
    localparam ADDR_KEY0         = 8'h10;
    localparam ADDR_KEY7         = 8'h17;

    localparam ADDR_IV0          = 8'h20; // IV registers: 0x20 - 0x21
    localparam ADDR_IV1          = 8'h21;

    localparam ADDR_DATA_IN0     = 8'h40; // Input data: 0x40 - 0x4F
    localparam ADDR_DATA_IN15    = 8'h4f;

    localparam ADDR_DATA_OUT0    = 8'h80; // Output data: 0x80 - 0x8F
    localparam ADDR_DATA_OUT15   = 8'h8f;

    // Control bits
    localparam CTRL_INIT_BIT     = 0;
    localparam CTRL_NEXT_BIT     = 1;

    // Status bits
    localparam STATUS_READY_BIT      = 0;
    localparam STATUS_DATA_VALID_BIT = 1;

    // ----------------------------------------------------------------
    // Internal registers
    // ----------------------------------------------------------------

    // Control signals
    reg        init_reg, init_new;
    reg        next_reg, next_new;

    // <<< ADDED: Key storage (256-bit = 8x32b)
    reg [31:0] key_reg[0:7];
    reg        key_we;

    // IV storage (64-bit = 2x32b)
    reg [31:0] iv_reg[0:1];
    reg        iv_we;

    // Input data storage (512-bit = 16x32b)
    reg [31:0] data_in_reg [0:15];
    reg        data_in_we;

    // Output data (from core)
    wire [511:0] core_data_out;
    wire         core_data_out_valid;

    // Status signals from core
    wire         core_ready;

    // Output register for read_data bus
    reg [31:0]  tmp_read_data;

    // ----------------------------------------------------------------
    // Data bus assignment
    // ----------------------------------------------------------------

    // <<< ADDED: Concatenate key registers for the core
    wire [255:0] core_key = {key_reg[7], key_reg[6], key_reg[5], key_reg[4],
                             key_reg[3], key_reg[2], key_reg[1], key_reg[0]};

    // Concatenate IV and input data arrays for core
    wire [63:0]  core_iv      = {iv_reg[0], iv_reg[1]};
    wire [511:0] core_data_in = {data_in_reg[0], data_in_reg[1], data_in_reg[2], data_in_reg[3],
                                 data_in_reg[4], data_in_reg[5], data_in_reg[6], data_in_reg[7],
                                 data_in_reg[8], data_in_reg[9], data_in_reg[10], data_in_reg[11],
                                 data_in_reg[12], data_in_reg[13], data_in_reg[14], data_in_reg[15]};

    assign read_data = tmp_read_data;

    // ----------------------------------------------------------------
    // Core instantiation.
    // ----------------------------------------------------------------
    chacha20_core_keyinput core (
        .clk(clk),
        .reset_n(reset_n),
        .init(init_reg),
        .next(next_reg),
        .key(core_key),   // <<< MODIFIED: Pass the concatenated key from registers
        .iv(core_iv),
        .data_in(core_data_in),
        .ready(core_ready),
        .data_out(core_data_out),
        .data_out_valid(core_data_out_valid)
    );

    // ----------------------------------------------------------------
    // Register update logic
    // ----------------------------------------------------------------
    always @ (posedge clk) begin : reg_update
        integer i;
        if (!reset_n) begin
            init_reg <= 0;
            next_reg <= 0;
            // <<< ADDED: Reset key registers
            for (i = 0 ; i < 8 ; i = i + 1)
                key_reg[i] <= 32'h0;
            iv_reg[0]  <= 32'h0;
            iv_reg[1]  <= 32'h0;
            for (i = 0 ; i < 16 ; i = i + 1)
                data_in_reg[i] <= 32'h0;
        end else begin
            init_reg <= init_new;
            next_reg <= next_new;
            // <<< ADDED: Write to the addressed key register
            if (key_we)
                key_reg[addr - ADDR_KEY0] <= write_data;
            if (iv_we)
                iv_reg[addr[0]] <= write_data;
            if (data_in_we)
                data_in_reg[addr[3:0]] <= write_data;
        end
    end

    // ----------------------------------------------------------------
    // Address decoder logic
    // ----------------------------------------------------------------
    always @* begin : addr_decoder
        key_we        = 1'h0; // <<< ADDED
        iv_we         = 1'h0;
        data_in_we    = 1'h0;
        init_new      = 1'h0;
        next_new      = 1'h0;
        tmp_read_data = 32'h0;

        if (cs) begin
            if (we) begin // Write operations
                if (addr == ADDR_CTRL) begin
                    init_new = write_data[CTRL_INIT_BIT];
                    next_new = write_data[CTRL_NEXT_BIT];
                end
                // <<< ADDED: Enable write for key address range
                if ((addr >= ADDR_KEY0) && (addr <= ADDR_KEY7))
                    key_we = 1;
                if ((addr >= ADDR_IV0) && (addr <= ADDR_IV1))
                    iv_we = 1;
                if ((addr >= ADDR_DATA_IN0) && (addr <= ADDR_DATA_IN15))
                    data_in_we = 1;
            end else begin // Read operations
                if ((addr >= ADDR_DATA_OUT0) && (addr <= ADDR_DATA_OUT15))
                    tmp_read_data = core_data_out[(15 - (addr - ADDR_DATA_OUT0)) * 32 +: 32];
                // <<< ADDED: Allow reading back the key
                if ((addr >= ADDR_KEY0) && (addr <= ADDR_KEY7))
                    tmp_read_data = key_reg[addr - ADDR_KEY0];

                case (addr)
                    ADDR_CTRL:   tmp_read_data = {30'h0, next_reg, init_reg};
                    ADDR_STATUS: tmp_read_data = {30'h0, core_data_out_valid, core_ready};
                    ADDR_IV0:    tmp_read_data = iv_reg[0];
                    ADDR_IV1:    tmp_read_data = iv_reg[1];
                    default: ;
                endcase
            end
        end
    end
endmodule

//----------------------------------------------------------------------
// chacha20_core_keyinput
//  - Core ChaCha20 logic, assumes 256-bit key input, 20 rounds fixed.
//----------------------------------------------------------------------
module chacha20_core_keyinput (
    input  wire         clk,
    input  wire         reset_n,
    input  wire         init,
    input  wire         next,
    input  wire [255:0] key,        // <<<<<<<< Direct key input!
    input  wire [63:0]  iv,
    input  wire [511:0] data_in,
    output wire         ready,
    output wire [511:0] data_out,
    output wire         data_out_valid
);

    // Constants for ChaCha20
    localparam SIGMA0 = 32'h61707865;
    localparam SIGMA1 = 32'h3320646e;
    localparam SIGMA2 = 32'h79622d32;
    localparam SIGMA3 = 32'h6b206574;

    // State machine states
    localparam CTRL_IDLE     = 3'h0;
    localparam CTRL_INIT     = 3'h1;
    localparam CTRL_ROUNDS   = 3'h2;
    localparam CTRL_FINALIZE = 3'h3;
    localparam CTRL_DONE     = 3'h4;

    // 64-bit block counter (split into two 32-bit words)
    reg [31:0] block0_ctr_reg, block1_ctr_reg;
    reg [31:0] block0_ctr_new, block1_ctr_new;
    reg        block0_ctr_we,  block1_ctr_we;
    reg        block_ctr_inc,  block_ctr_set;

    // ChaCha state registers
    reg [31:0]  state_reg [0:15];
    reg [31:0]  state_new [0:15];
    reg         state_we;

    // Output register
    reg [511:0] data_out_reg, data_out_new;
    reg         data_out_valid_reg, data_out_valid_new, data_out_valid_we;

    // Round/quarterround counters
    reg         qr_ctr_reg, qr_ctr_new, qr_ctr_we, qr_ctr_inc, qr_ctr_rst;
    reg [3:0]   dr_ctr_reg, dr_ctr_new, dr_ctr_we, dr_ctr_inc, dr_ctr_rst;

    reg         ready_reg, ready_new, ready_we;
    reg [2:0]   chacha_ctrl_reg, chacha_ctrl_new;
    reg         chacha_ctrl_we;

    reg [31:0]  init_state_word [0:15];
    reg         init_state, update_state, update_output;

    // Quarter round wires
    reg [31:0]  qr0_a, qr0_b, qr0_c, qr0_d;
    wire [31:0] qr0_a_prim, qr0_b_prim, qr0_c_prim, qr0_d_prim;
    reg [31:0]  qr1_a, qr1_b, qr1_c, qr1_d;
    wire [31:0] qr1_a_prim, qr1_b_prim, qr1_c_prim, qr1_d_prim;
    reg [31:0]  qr2_a, qr2_b, qr2_c, qr2_d;
    wire [31:0] qr2_a_prim, qr2_b_prim, qr2_c_prim, qr2_d_prim;
    reg [31:0]  qr3_a, qr3_b, qr3_c, qr3_d;
    wire [31:0] qr3_a_prim, qr3_b_prim, qr3_c_prim, qr3_d_prim;

    // Endian swap function (little endian)
    function [31:0] l2b(input [31:0] op);
        l2b = {op[7:0], op[15:8], op[23:16], op[31:24]};
    endfunction

    // Instantiate quarterrounds
    chacha_qr qr0(.a(qr0_a), .b(qr0_b), .c(qr0_c), .d(qr0_d),
                  .a_prim(qr0_a_prim), .b_prim(qr0_b_prim), .c_prim(qr0_c_prim), .d_prim(qr0_d_prim));
    chacha_qr qr1(.a(qr1_a), .b(qr1_b), .c(qr1_c), .d(qr1_d),
                  .a_prim(qr1_a_prim), .b_prim(qr1_b_prim), .c_prim(qr1_c_prim), .d_prim(qr1_d_prim));
    chacha_qr qr2(.a(qr2_a), .b(qr2_b), .c(qr2_c), .d(qr2_d),
                  .a_prim(qr2_a_prim), .b_prim(qr2_b_prim), .c_prim(qr2_c_prim), .d_prim(qr2_d_prim));
    chacha_qr qr3(.a(qr3_a), .b(qr3_b), .c(qr3_c), .d(qr3_d),
                  .a_prim(qr3_a_prim), .b_prim(qr3_b_prim), .c_prim(qr3_c_prim), .d_prim(qr3_d_prim));

    assign data_out = data_out_reg;
    assign data_out_valid = data_out_valid_reg;
    assign ready = ready_reg;

    //----------------------------------------------------------------
    // Register update for all state, counters, etc.
    //----------------------------------------------------------------
    always @ (posedge clk) begin
        integer i;
        if (!reset_n) begin
            for (i = 0 ; i < 16 ; i = i + 1)
                state_reg[i] <= 32'h0;
            data_out_reg       <= 512'h0;
            data_out_valid_reg <= 0;
            qr_ctr_reg         <= 0;
            dr_ctr_reg         <= 0;
            block0_ctr_reg     <= 32'h0;
            block1_ctr_reg     <= 32'h0;
            chacha_ctrl_reg    <= CTRL_IDLE;
            ready_reg          <= 1;
        end else begin
            if (state_we)
                for (i = 0 ; i < 16 ; i = i + 1)
                    state_reg[i] <= state_new[i];
            if (update_output)
                data_out_reg <= data_out_new;
            if (data_out_valid_we)
                data_out_valid_reg <= data_out_valid_new;
            if (qr_ctr_we)
                qr_ctr_reg <= qr_ctr_new;
            if (dr_ctr_we)
                dr_ctr_reg <= dr_ctr_new;
            if (block0_ctr_we)
                block0_ctr_reg <= block0_ctr_new;
            if (block1_ctr_we)
                block1_ctr_reg <= block1_ctr_new;
            if (ready_we)
                ready_reg <= ready_new;
            if (chacha_ctrl_we)
                chacha_ctrl_reg <= chacha_ctrl_new;
        end
    end

    //----------------------------------------------------------------
    // Initial state logic for ChaCha20 (fixed 256-bit key, SIGMA constant, 20 rounds)
    //----------------------------------------------------------------
    always @* begin
        reg [31:0] key0, key1, key2, key3, key4, key5, key6, key7;
        key0 = l2b(key[255:224]);
        key1 = l2b(key[223:192]);
        key2 = l2b(key[191:160]);
        key3 = l2b(key[159:128]);
        key4 = l2b(key[127:96]);
        key5 = l2b(key[95:64]);
        key6 = l2b(key[63:32]);
        key7 = l2b(key[31:0]);
        // ChaCha20 state: constant, key, counter, IV
        init_state_word[ 0] = SIGMA0;
        init_state_word[ 1] = SIGMA1;
        init_state_word[ 2] = SIGMA2;
        init_state_word[ 3] = SIGMA3;
        init_state_word[ 4] = key0;
        init_state_word[ 5] = key1;
        init_state_word[ 6] = key2;
        init_state_word[ 7] = key3;
        init_state_word[ 8] = key4;
        init_state_word[ 9] = key5;
        init_state_word[10] = key6;
        init_state_word[11] = key7;
        init_state_word[12] = block0_ctr_reg;
        init_state_word[13] = block1_ctr_reg;
        // Note: 64-bit IV. For 96-bit, extend here.
        init_state_word[14] = l2b(iv[63:32]);
        init_state_word[15] = l2b(iv[31:0]);
    end

    //----------------------------------------------------------------
    // State logic: initializes and updates the ChaCha state matrix.
    //----------------------------------------------------------------
    always @* begin
        integer i;
        for (i = 0 ; i < 16 ; i = i + 1)
            state_new[i] = 32'h0;
        state_we = 0;
        qr0_a = 32'h0; qr0_b = 32'h0; qr0_c = 32'h0; qr0_d = 32'h0;
        qr1_a = 32'h0; qr1_b = 32'h0; qr1_c = 32'h0; qr1_d = 32'h0;
        qr2_a = 32'h0; qr2_b = 32'h0; qr2_c = 32'h0; qr2_d = 32'h0;
        qr3_a = 32'h0; qr3_b = 32'h0; qr3_c = 32'h0; qr3_d = 32'h0;
        if (init_state) begin
            for (i = 0 ; i < 16 ; i = i + 1)
                state_new[i] = init_state_word[i];
            state_we   = 1;
        end
        if (update_state) begin
            state_we = 1;
            case (qr_ctr_reg)
                0: begin
                    qr0_a = state_reg[ 0]; qr0_b = state_reg[ 4]; qr0_c = state_reg[ 8]; qr0_d = state_reg[12];
                    qr1_a = state_reg[ 1]; qr1_b = state_reg[ 5]; qr1_c = state_reg[ 9]; qr1_d = state_reg[13];
                    qr2_a = state_reg[ 2]; qr2_b = state_reg[ 6]; qr2_c = state_reg[10]; qr2_d = state_reg[14];
                    qr3_a = state_reg[ 3]; qr3_b = state_reg[ 7]; qr3_c = state_reg[11]; qr3_d = state_reg[15];
                    state_new[ 0] = qr0_a_prim; state_new[ 4] = qr0_b_prim; state_new[ 8] = qr0_c_prim; state_new[12] = qr0_d_prim;
                    state_new[ 1] = qr1_a_prim; state_new[ 5] = qr1_b_prim; state_new[ 9] = qr1_c_prim; state_new[13] = qr1_d_prim;
                    state_new[ 2] = qr2_a_prim; state_new[ 6] = qr2_b_prim; state_new[10] = qr2_c_prim; state_new[14] = qr2_d_prim;
                    state_new[ 3] = qr3_a_prim; state_new[ 7] = qr3_b_prim; state_new[11] = qr3_c_prim; state_new[15] = qr3_d_prim;
                end
                1: begin
                    qr0_a = state_reg[ 0]; qr0_b = state_reg[ 5]; qr0_c = state_reg[10]; qr0_d = state_reg[15];
                    qr1_a = state_reg[ 1]; qr1_b = state_reg[ 6]; qr1_c = state_reg[11]; qr1_d = state_reg[12];
                    qr2_a = state_reg[ 2]; qr2_b = state_reg[ 7]; qr2_c = state_reg[ 8]; qr2_d = state_reg[13];
                    qr3_a = state_reg[ 3]; qr3_b = state_reg[ 4]; qr3_c = state_reg[ 9]; qr3_d = state_reg[14];
                    state_new[ 0] = qr0_a_prim; state_new[ 5] = qr0_b_prim; state_new[10] = qr0_c_prim; state_new[15] = qr0_d_prim;
                    state_new[ 1] = qr1_a_prim; state_new[ 6] = qr1_b_prim; state_new[11] = qr1_c_prim; state_new[12] = qr1_d_prim;
                    state_new[ 2] = qr2_a_prim; state_new[ 7] = qr2_b_prim; state_new[ 8] = qr2_c_prim; state_new[13] = qr2_d_prim;
                    state_new[ 3] = qr3_a_prim; state_new[ 4] = qr3_b_prim; state_new[ 9] = qr3_c_prim; state_new[14] = qr3_d_prim;
                end
            endcase
        end
    end

    //----------------------------------------------------------------
    // Output block computation: add original state, then XOR input data.
    //----------------------------------------------------------------
    always @* begin
        integer i;
        reg [31:0] msb_block_state [0:15];
        reg [31:0] lsb_block_state [0:15];
        reg [511:0] block_state;
        for (i = 0 ; i < 16 ; i = i + 1) begin
            msb_block_state[i] = init_state_word[i] + state_reg[i];
            lsb_block_state[i] = l2b(msb_block_state[i][31:0]);
        end
        block_state = {lsb_block_state[ 0], lsb_block_state[ 1],
                       lsb_block_state[ 2], lsb_block_state[ 3],
                       lsb_block_state[ 4], lsb_block_state[ 5],
                       lsb_block_state[ 6], lsb_block_state[ 7],
                       lsb_block_state[ 8], lsb_block_state[ 9],
                       lsb_block_state[10], lsb_block_state[11],
                       lsb_block_state[12], lsb_block_state[13],
                       lsb_block_state[14], lsb_block_state[15]};
        data_out_new = data_in ^ block_state;
    end

    //----------------------------------------------------------------
    // QR and DR counters, block counter, FSM
    //----------------------------------------------------------------
    always @* begin
        qr_ctr_new = 0; qr_ctr_we = 0;
        if (qr_ctr_rst) begin qr_ctr_new = 0; qr_ctr_we = 1; end
        if (qr_ctr_inc) begin qr_ctr_new = qr_ctr_reg + 1'b1; qr_ctr_we = 1; end
    end
    always @* begin
        dr_ctr_new = 0; dr_ctr_we = 0;
        if (dr_ctr_rst) begin dr_ctr_new = 0; dr_ctr_we = 1; end
        if (dr_ctr_inc) begin dr_ctr_new = dr_ctr_reg + 1'b1; dr_ctr_we = 1; end
    end
    always @* begin
        block0_ctr_new = 32'h0; block1_ctr_new = 32'h0;
        block0_ctr_we = 0; block1_ctr_we = 0;
        if (block_ctr_set) begin
            block0_ctr_new = 32'h0;   // Block counter always starts at 0 for first block
            block1_ctr_new = 32'h0;
            block0_ctr_we = 1; block1_ctr_we = 1;
        end
        if (block_ctr_inc) begin
            block0_ctr_new = block0_ctr_reg + 1;
            block0_ctr_we = 1;
            if (block0_ctr_reg == 32'hffffffff) begin
                block1_ctr_new = block1_ctr_reg + 1;
                block1_ctr_we = 1;
            end
        end
    end

    //----------------------------------------------------------------
    // State machine: FSM for ChaCha20 block processing
    //----------------------------------------------------------------
    always @* begin
        init_state         = 0;
        update_state       = 0;
        update_output      = 0;
        qr_ctr_inc         = 0;
        qr_ctr_rst         = 0;
        dr_ctr_inc         = 0;
        dr_ctr_rst         = 0;
        block_ctr_inc      = 0;
        block_ctr_set      = 0;
        ready_new          = 0;
        ready_we           = 0;
        data_out_valid_new = 0;
        data_out_valid_we  = 0;
        chacha_ctrl_new    = CTRL_IDLE;
        chacha_ctrl_we     = 0;
        case (chacha_ctrl_reg)
            CTRL_IDLE: begin
                if (init) begin
                    block_ctr_set   = 1;
                    ready_new       = 0;
                    ready_we        = 1;
                    chacha_ctrl_new = CTRL_INIT;
                    chacha_ctrl_we  = 1;
                end
            end
            CTRL_INIT: begin
                init_state      = 1;
                qr_ctr_rst      = 1;
                dr_ctr_rst      = 1;
                chacha_ctrl_new = CTRL_ROUNDS;
                chacha_ctrl_we  = 1;
            end
            CTRL_ROUNDS: begin
                update_state = 1;
                qr_ctr_inc   = 1;
                if (qr_ctr_reg == 1) begin
                    dr_ctr_inc = 1;
                    if (dr_ctr_reg == 9) begin // 10 double rounds = 20 rounds
                        chacha_ctrl_new = CTRL_FINALIZE;
                        chacha_ctrl_we  = 1;
                    end
                end
            end
            CTRL_FINALIZE: begin
                ready_new          = 1;
                ready_we           = 1;
                update_output      = 1;
                data_out_valid_new = 1;
                data_out_valid_we  = 1;
                chacha_ctrl_new    = CTRL_DONE;
                chacha_ctrl_we     = 1;
            end
            CTRL_DONE: begin
                if (init) begin
                    ready_new          = 0;
                    ready_we           = 1;
                    data_out_valid_new = 0;
                    data_out_valid_we  = 1;
                    block_ctr_set      = 1;
                    chacha_ctrl_new    = CTRL_INIT;
                    chacha_ctrl_we     = 1;
                end else if (next) begin
                    ready_new          = 0;
                    ready_we           = 1;
                    data_out_valid_new = 0;
                    data_out_valid_we  = 1;
                    block_ctr_inc      = 1;
                    chacha_ctrl_new    = CTRL_INIT;
                    chacha_ctrl_we     = 1;
                end
            end
            default: ;
        endcase
    end
endmodule

//----------------------------------------------------------------------
// chacha_qr - ChaCha quarterround, unchanged from reference implementation
//----------------------------------------------------------------------
module chacha_qr(
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [31:0] c,
    input  wire [31:0] d,
    output wire [31:0] a_prim,
    output wire [31:0] b_prim,
    output wire [31:0] c_prim,
    output wire [31:0] d_prim
);
    reg [31:0] internal_a_prim;
    reg [31:0] internal_b_prim;
    reg [31:0] internal_c_prim;
    reg [31:0] internal_d_prim;
    assign a_prim = internal_a_prim;
    assign b_prim = internal_b_prim;
    assign c_prim = internal_c_prim;
    assign d_prim = internal_d_prim;
    always @* begin : qr
        reg [31:0] a0, a1;
        reg [31:0] b0, b1, b2, b3;
        reg [31:0] c0, c1;
        reg [31:0] d0, d1, d2, d3;
        a0 = a + b;
        d0 = d ^ a0;
        d1 = {d0[15:0], d0[31:16]};
        c0 = c + d1;
        b0 = b ^ c0;
        b1 = {b0[19:0], b0[31:20]};
        a1 = a0 + b1;
        d2 = d1 ^ a1;
        d3 = {d2[23:0], d2[31:24]};
        c1 = c0 + d3;
        b2 = b1 ^ c1;
        b3 = {b2[24:0], b2[31:25]};
        internal_a_prim = a1;
        internal_b_prim = b3;
        internal_c_prim = c1;
        internal_d_prim = d3;
    end
endmodule