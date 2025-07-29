// Simple compilation check for all modules
`timescale 1ns / 1ps

// Include all RTL files for compilation check
`include "rtl/qr.v"
`include "rtl/chacha20_core.v"
`include "rtl/MockTRNGHardened.v"
`include "rtl/asic_top.v"
`include "tb/tb_asic_top.sv"

// This file just ensures all modules compile together
module compile_check;
    initial begin
        $display("All modules compiled successfully!");
        $finish;
    end
endmodule
