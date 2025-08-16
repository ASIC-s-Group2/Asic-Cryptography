// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// Copyright 2022-2025 Advanced Micro Devices, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2025.1 (win64) Build 6140274 Thu May 22 00:12:29 MDT 2025
// Date        : Wed Jul 30 14:39:09 2025
// Host        : Mirage running 64-bit major release  (build 9200)
// Command     : write_verilog -mode funcsim -nolib -force -file
//               C:/Users/Admin/cypher_test_1/cypher_test_1.sim/sim_1/synth/func/xsim/TRNG_func_synth.v
// Design      : TRNG
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7a35tcpg236-1
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module RingOsc
   (rst_n,
    D,
    ready_reg,
    trng_request_IBUF,
    ready_OBUF,
    rst_n_IBUF);
  output rst_n;
  output [0:0]D;
  output [0:0]ready_reg;
  input trng_request_IBUF;
  input ready_OBUF;
  input rst_n_IBUF;

  (* RTL_KEEP = "true" *) wire [4:0]chain;
  wire ready_OBUF;
  wire [0:0]ready_reg;
  (* RTL_KEEP = "true" *) wire rst_n;
  wire rst_n_IBUF;
  wire trng_request_IBUF;

  assign D[0] = chain[0];
  LUT1 #(
    .INIT(2'h1)) 
    RESET_inferred_i_1
       (.I0(rst_n_IBUF),
        .O(rst_n));
  LUT1 #(
    .INIT(2'h1)) 
    chain_inferred_i_1
       (.I0(chain[3]),
        .O(chain[4]));
  LUT1 #(
    .INIT(2'h1)) 
    chain_inferred_i_2
       (.I0(chain[2]),
        .O(chain[3]));
  LUT1 #(
    .INIT(2'h1)) 
    chain_inferred_i_3
       (.I0(chain[1]),
        .O(chain[2]));
  LUT1 #(
    .INIT(2'h1)) 
    chain_inferred_i_4
       (.I0(chain[0]),
        .O(chain[1]));
  LUT2 #(
    .INIT(4'h1)) 
    chain_inferred_i_5
       (.I0(chain[4]),
        .I1(rst_n),
        .O(chain[0]));
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[0]_i_1 
       (.I0(chain[0]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(ready_reg));
endmodule

(* NotValidForBitStream *)
module TRNG
   (clk,
    rst_n,
    raw_entropy_in,
    trng_request,
    random_number,
    ready);
  input clk;
  input rst_n;
  input raw_entropy_in;
  input trng_request;
  output [31:0]random_number;
  output ready;

  wire bit_count;
  wire \bit_count[4]_i_2_n_0 ;
  wire [5:0]bit_count_reg;
  wire clk;
  wire clk_IBUF;
  wire clk_IBUF_BUFG;
  wire [30:0]p_0_in;
  wire [5:0]p_0_in__0;
  wire [31:1]p_1_in;
  wire [31:0]random_number;
  wire \random_number[31]_i_1_n_0 ;
  wire \random_number[31]_i_2_n_0 ;
  wire [31:0]random_number_OBUF;
  wire ready;
  wire ready_OBUF;
  wire ready_i_1_n_0;
  wire ring_oscillator_n_0;
  wire ring_oscillator_output;
  wire rst_n;
  wire rst_n_IBUF;
  wire trng_request;
  wire trng_request_IBUF;

  (* SOFT_HLUTNM = "soft_lutpair2" *) 
  LUT3 #(
    .INIT(8'hC4)) 
    \bit_count[0]_i_1 
       (.I0(bit_count_reg[0]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in__0[0]));
  (* SOFT_HLUTNM = "soft_lutpair0" *) 
  LUT4 #(
    .INIT(16'hBE00)) 
    \bit_count[1]_i_1 
       (.I0(ready_OBUF),
        .I1(bit_count_reg[0]),
        .I2(bit_count_reg[1]),
        .I3(trng_request_IBUF),
        .O(p_0_in__0[1]));
  (* SOFT_HLUTNM = "soft_lutpair0" *) 
  LUT5 #(
    .INIT(32'hBFEA0000)) 
    \bit_count[2]_i_1 
       (.I0(ready_OBUF),
        .I1(bit_count_reg[0]),
        .I2(bit_count_reg[1]),
        .I3(bit_count_reg[2]),
        .I4(trng_request_IBUF),
        .O(p_0_in__0[2]));
  LUT6 #(
    .INIT(64'hBFFFEAAA00000000)) 
    \bit_count[3]_i_1 
       (.I0(ready_OBUF),
        .I1(bit_count_reg[1]),
        .I2(bit_count_reg[0]),
        .I3(bit_count_reg[2]),
        .I4(bit_count_reg[3]),
        .I5(trng_request_IBUF),
        .O(p_0_in__0[3]));
  (* SOFT_HLUTNM = "soft_lutpair3" *) 
  LUT4 #(
    .INIT(16'hEB00)) 
    \bit_count[4]_i_1 
       (.I0(ready_OBUF),
        .I1(\bit_count[4]_i_2_n_0 ),
        .I2(bit_count_reg[4]),
        .I3(trng_request_IBUF),
        .O(p_0_in__0[4]));
  (* SOFT_HLUTNM = "soft_lutpair1" *) 
  LUT4 #(
    .INIT(16'h7FFF)) 
    \bit_count[4]_i_2 
       (.I0(bit_count_reg[2]),
        .I1(bit_count_reg[0]),
        .I2(bit_count_reg[1]),
        .I3(bit_count_reg[3]),
        .O(\bit_count[4]_i_2_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair2" *) 
  LUT4 #(
    .INIT(16'hEB00)) 
    \bit_count[5]_i_1 
       (.I0(ready_OBUF),
        .I1(\random_number[31]_i_2_n_0 ),
        .I2(bit_count_reg[5]),
        .I3(trng_request_IBUF),
        .O(p_0_in__0[5]));
  FDCE #(
    .INIT(1'b0)) 
    \bit_count_reg[0] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in__0[0]),
        .Q(bit_count_reg[0]));
  FDCE #(
    .INIT(1'b0)) 
    \bit_count_reg[1] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in__0[1]),
        .Q(bit_count_reg[1]));
  FDCE #(
    .INIT(1'b0)) 
    \bit_count_reg[2] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in__0[2]),
        .Q(bit_count_reg[2]));
  FDCE #(
    .INIT(1'b0)) 
    \bit_count_reg[3] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in__0[3]),
        .Q(bit_count_reg[3]));
  FDCE #(
    .INIT(1'b0)) 
    \bit_count_reg[4] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in__0[4]),
        .Q(bit_count_reg[4]));
  FDCE #(
    .INIT(1'b0)) 
    \bit_count_reg[5] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in__0[5]),
        .Q(bit_count_reg[5]));
  BUFG clk_IBUF_BUFG_inst
       (.I(clk_IBUF),
        .O(clk_IBUF_BUFG));
  IBUF clk_IBUF_inst
       (.I(clk),
        .O(clk_IBUF));
  LUT4 #(
    .INIT(16'h0004)) 
    \random_number[31]_i_1 
       (.I0(bit_count_reg[5]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .I3(\random_number[31]_i_2_n_0 ),
        .O(\random_number[31]_i_1_n_0 ));
  (* SOFT_HLUTNM = "soft_lutpair1" *) 
  LUT5 #(
    .INIT(32'h7FFFFFFF)) 
    \random_number[31]_i_2 
       (.I0(bit_count_reg[3]),
        .I1(bit_count_reg[1]),
        .I2(bit_count_reg[0]),
        .I3(bit_count_reg[2]),
        .I4(bit_count_reg[4]),
        .O(\random_number[31]_i_2_n_0 ));
  OBUF \random_number_OBUF[0]_inst 
       (.I(random_number_OBUF[0]),
        .O(random_number[0]));
  OBUF \random_number_OBUF[10]_inst 
       (.I(random_number_OBUF[10]),
        .O(random_number[10]));
  OBUF \random_number_OBUF[11]_inst 
       (.I(random_number_OBUF[11]),
        .O(random_number[11]));
  OBUF \random_number_OBUF[12]_inst 
       (.I(random_number_OBUF[12]),
        .O(random_number[12]));
  OBUF \random_number_OBUF[13]_inst 
       (.I(random_number_OBUF[13]),
        .O(random_number[13]));
  OBUF \random_number_OBUF[14]_inst 
       (.I(random_number_OBUF[14]),
        .O(random_number[14]));
  OBUF \random_number_OBUF[15]_inst 
       (.I(random_number_OBUF[15]),
        .O(random_number[15]));
  OBUF \random_number_OBUF[16]_inst 
       (.I(random_number_OBUF[16]),
        .O(random_number[16]));
  OBUF \random_number_OBUF[17]_inst 
       (.I(random_number_OBUF[17]),
        .O(random_number[17]));
  OBUF \random_number_OBUF[18]_inst 
       (.I(random_number_OBUF[18]),
        .O(random_number[18]));
  OBUF \random_number_OBUF[19]_inst 
       (.I(random_number_OBUF[19]),
        .O(random_number[19]));
  OBUF \random_number_OBUF[1]_inst 
       (.I(random_number_OBUF[1]),
        .O(random_number[1]));
  OBUF \random_number_OBUF[20]_inst 
       (.I(random_number_OBUF[20]),
        .O(random_number[20]));
  OBUF \random_number_OBUF[21]_inst 
       (.I(random_number_OBUF[21]),
        .O(random_number[21]));
  OBUF \random_number_OBUF[22]_inst 
       (.I(random_number_OBUF[22]),
        .O(random_number[22]));
  OBUF \random_number_OBUF[23]_inst 
       (.I(random_number_OBUF[23]),
        .O(random_number[23]));
  OBUF \random_number_OBUF[24]_inst 
       (.I(random_number_OBUF[24]),
        .O(random_number[24]));
  OBUF \random_number_OBUF[25]_inst 
       (.I(random_number_OBUF[25]),
        .O(random_number[25]));
  OBUF \random_number_OBUF[26]_inst 
       (.I(random_number_OBUF[26]),
        .O(random_number[26]));
  OBUF \random_number_OBUF[27]_inst 
       (.I(random_number_OBUF[27]),
        .O(random_number[27]));
  OBUF \random_number_OBUF[28]_inst 
       (.I(random_number_OBUF[28]),
        .O(random_number[28]));
  OBUF \random_number_OBUF[29]_inst 
       (.I(random_number_OBUF[29]),
        .O(random_number[29]));
  OBUF \random_number_OBUF[2]_inst 
       (.I(random_number_OBUF[2]),
        .O(random_number[2]));
  OBUF \random_number_OBUF[30]_inst 
       (.I(random_number_OBUF[30]),
        .O(random_number[30]));
  OBUF \random_number_OBUF[31]_inst 
       (.I(random_number_OBUF[31]),
        .O(random_number[31]));
  OBUF \random_number_OBUF[3]_inst 
       (.I(random_number_OBUF[3]),
        .O(random_number[3]));
  OBUF \random_number_OBUF[4]_inst 
       (.I(random_number_OBUF[4]),
        .O(random_number[4]));
  OBUF \random_number_OBUF[5]_inst 
       (.I(random_number_OBUF[5]),
        .O(random_number[5]));
  OBUF \random_number_OBUF[6]_inst 
       (.I(random_number_OBUF[6]),
        .O(random_number[6]));
  OBUF \random_number_OBUF[7]_inst 
       (.I(random_number_OBUF[7]),
        .O(random_number[7]));
  OBUF \random_number_OBUF[8]_inst 
       (.I(random_number_OBUF[8]),
        .O(random_number[8]));
  OBUF \random_number_OBUF[9]_inst 
       (.I(random_number_OBUF[9]),
        .O(random_number[9]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[0] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(ring_oscillator_output),
        .Q(random_number_OBUF[0]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[10] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[10]),
        .Q(random_number_OBUF[10]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[11] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[11]),
        .Q(random_number_OBUF[11]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[12] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[12]),
        .Q(random_number_OBUF[12]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[13] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[13]),
        .Q(random_number_OBUF[13]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[14] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[14]),
        .Q(random_number_OBUF[14]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[15] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[15]),
        .Q(random_number_OBUF[15]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[16] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[16]),
        .Q(random_number_OBUF[16]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[17] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[17]),
        .Q(random_number_OBUF[17]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[18] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[18]),
        .Q(random_number_OBUF[18]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[19] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[19]),
        .Q(random_number_OBUF[19]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[1] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[1]),
        .Q(random_number_OBUF[1]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[20] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[20]),
        .Q(random_number_OBUF[20]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[21] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[21]),
        .Q(random_number_OBUF[21]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[22] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[22]),
        .Q(random_number_OBUF[22]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[23] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[23]),
        .Q(random_number_OBUF[23]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[24] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[24]),
        .Q(random_number_OBUF[24]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[25] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[25]),
        .Q(random_number_OBUF[25]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[26] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[26]),
        .Q(random_number_OBUF[26]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[27] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[27]),
        .Q(random_number_OBUF[27]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[28] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[28]),
        .Q(random_number_OBUF[28]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[29] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[29]),
        .Q(random_number_OBUF[29]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[2] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[2]),
        .Q(random_number_OBUF[2]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[30] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[30]),
        .Q(random_number_OBUF[30]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[31] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[31]),
        .Q(random_number_OBUF[31]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[3] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[3]),
        .Q(random_number_OBUF[3]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[4] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[4]),
        .Q(random_number_OBUF[4]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[5] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[5]),
        .Q(random_number_OBUF[5]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[6] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[6]),
        .Q(random_number_OBUF[6]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[7] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[7]),
        .Q(random_number_OBUF[7]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[8] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[8]),
        .Q(random_number_OBUF[8]));
  FDCE #(
    .INIT(1'b0)) 
    \random_number_reg[9] 
       (.C(clk_IBUF_BUFG),
        .CE(\random_number[31]_i_1_n_0 ),
        .CLR(ring_oscillator_n_0),
        .D(p_1_in[9]),
        .Q(random_number_OBUF[9]));
  OBUF ready_OBUF_inst
       (.I(ready_OBUF),
        .O(ready));
  LUT4 #(
    .INIT(16'hF100)) 
    ready_i_1
       (.I0(\random_number[31]_i_2_n_0 ),
        .I1(bit_count_reg[5]),
        .I2(ready_OBUF),
        .I3(trng_request_IBUF),
        .O(ready_i_1_n_0));
  FDCE #(
    .INIT(1'b0)) 
    ready_reg
       (.C(clk_IBUF_BUFG),
        .CE(1'b1),
        .CLR(ring_oscillator_n_0),
        .D(ready_i_1_n_0),
        .Q(ready_OBUF));
  RingOsc ring_oscillator
       (.D(ring_oscillator_output),
        .ready_OBUF(ready_OBUF),
        .ready_reg(p_0_in[0]),
        .rst_n(ring_oscillator_n_0),
        .rst_n_IBUF(rst_n_IBUF),
        .trng_request_IBUF(trng_request_IBUF));
  IBUF rst_n_IBUF_inst
       (.I(rst_n),
        .O(rst_n_IBUF));
  (* SOFT_HLUTNM = "soft_lutpair13" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[10]_i_1 
       (.I0(p_1_in[10]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[10]));
  (* SOFT_HLUTNM = "soft_lutpair13" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[11]_i_1 
       (.I0(p_1_in[11]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[11]));
  (* SOFT_HLUTNM = "soft_lutpair12" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[12]_i_1 
       (.I0(p_1_in[12]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[12]));
  (* SOFT_HLUTNM = "soft_lutpair12" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[13]_i_1 
       (.I0(p_1_in[13]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[13]));
  (* SOFT_HLUTNM = "soft_lutpair11" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[14]_i_1 
       (.I0(p_1_in[14]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[14]));
  (* SOFT_HLUTNM = "soft_lutpair11" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[15]_i_1 
       (.I0(p_1_in[15]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[15]));
  (* SOFT_HLUTNM = "soft_lutpair10" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[16]_i_1 
       (.I0(p_1_in[16]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[16]));
  (* SOFT_HLUTNM = "soft_lutpair10" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[17]_i_1 
       (.I0(p_1_in[17]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[17]));
  (* SOFT_HLUTNM = "soft_lutpair9" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[18]_i_1 
       (.I0(p_1_in[18]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[18]));
  (* SOFT_HLUTNM = "soft_lutpair9" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[19]_i_1 
       (.I0(p_1_in[19]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[19]));
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[1]_i_1 
       (.I0(p_1_in[1]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[1]));
  (* SOFT_HLUTNM = "soft_lutpair8" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[20]_i_1 
       (.I0(p_1_in[20]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[20]));
  (* SOFT_HLUTNM = "soft_lutpair8" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[21]_i_1 
       (.I0(p_1_in[21]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[21]));
  (* SOFT_HLUTNM = "soft_lutpair7" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[22]_i_1 
       (.I0(p_1_in[22]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[22]));
  (* SOFT_HLUTNM = "soft_lutpair7" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[23]_i_1 
       (.I0(p_1_in[23]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[23]));
  (* SOFT_HLUTNM = "soft_lutpair6" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[24]_i_1 
       (.I0(p_1_in[24]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[24]));
  (* SOFT_HLUTNM = "soft_lutpair6" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[25]_i_1 
       (.I0(p_1_in[25]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[25]));
  (* SOFT_HLUTNM = "soft_lutpair5" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[26]_i_1 
       (.I0(p_1_in[26]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[26]));
  (* SOFT_HLUTNM = "soft_lutpair5" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[27]_i_1 
       (.I0(p_1_in[27]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[27]));
  (* SOFT_HLUTNM = "soft_lutpair4" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[28]_i_1 
       (.I0(p_1_in[28]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[28]));
  (* SOFT_HLUTNM = "soft_lutpair4" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[29]_i_1 
       (.I0(p_1_in[29]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[29]));
  (* SOFT_HLUTNM = "soft_lutpair17" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[2]_i_1 
       (.I0(p_1_in[2]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[2]));
  LUT2 #(
    .INIT(4'h7)) 
    \shift_reg[30]_i_1 
       (.I0(ready_OBUF),
        .I1(trng_request_IBUF),
        .O(bit_count));
  (* SOFT_HLUTNM = "soft_lutpair3" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[30]_i_2 
       (.I0(p_1_in[30]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[30]));
  (* SOFT_HLUTNM = "soft_lutpair17" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[3]_i_1 
       (.I0(p_1_in[3]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[3]));
  (* SOFT_HLUTNM = "soft_lutpair16" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[4]_i_1 
       (.I0(p_1_in[4]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[4]));
  (* SOFT_HLUTNM = "soft_lutpair16" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[5]_i_1 
       (.I0(p_1_in[5]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[5]));
  (* SOFT_HLUTNM = "soft_lutpair15" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[6]_i_1 
       (.I0(p_1_in[6]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[6]));
  (* SOFT_HLUTNM = "soft_lutpair15" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[7]_i_1 
       (.I0(p_1_in[7]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[7]));
  (* SOFT_HLUTNM = "soft_lutpair14" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[8]_i_1 
       (.I0(p_1_in[8]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[8]));
  (* SOFT_HLUTNM = "soft_lutpair14" *) 
  LUT3 #(
    .INIT(8'hC8)) 
    \shift_reg[9]_i_1 
       (.I0(p_1_in[9]),
        .I1(trng_request_IBUF),
        .I2(ready_OBUF),
        .O(p_0_in[9]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[0] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[0]),
        .Q(p_1_in[1]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[10] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[10]),
        .Q(p_1_in[11]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[11] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[11]),
        .Q(p_1_in[12]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[12] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[12]),
        .Q(p_1_in[13]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[13] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[13]),
        .Q(p_1_in[14]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[14] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[14]),
        .Q(p_1_in[15]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[15] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[15]),
        .Q(p_1_in[16]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[16] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[16]),
        .Q(p_1_in[17]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[17] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[17]),
        .Q(p_1_in[18]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[18] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[18]),
        .Q(p_1_in[19]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[19] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[19]),
        .Q(p_1_in[20]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[1] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[1]),
        .Q(p_1_in[2]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[20] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[20]),
        .Q(p_1_in[21]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[21] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[21]),
        .Q(p_1_in[22]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[22] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[22]),
        .Q(p_1_in[23]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[23] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[23]),
        .Q(p_1_in[24]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[24] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[24]),
        .Q(p_1_in[25]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[25] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[25]),
        .Q(p_1_in[26]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[26] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[26]),
        .Q(p_1_in[27]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[27] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[27]),
        .Q(p_1_in[28]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[28] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[28]),
        .Q(p_1_in[29]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[29] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[29]),
        .Q(p_1_in[30]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[2] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[2]),
        .Q(p_1_in[3]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[30] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[30]),
        .Q(p_1_in[31]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[3] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[3]),
        .Q(p_1_in[4]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[4] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[4]),
        .Q(p_1_in[5]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[5] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[5]),
        .Q(p_1_in[6]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[6] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[6]),
        .Q(p_1_in[7]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[7] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[7]),
        .Q(p_1_in[8]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[8] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[8]),
        .Q(p_1_in[9]));
  FDCE #(
    .INIT(1'b0)) 
    \shift_reg_reg[9] 
       (.C(clk_IBUF_BUFG),
        .CE(bit_count),
        .CLR(ring_oscillator_n_0),
        .D(p_0_in[9]),
        .Q(p_1_in[10]));
  IBUF trng_request_IBUF_inst
       (.I(trng_request),
        .O(trng_request_IBUF));
endmodule
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
