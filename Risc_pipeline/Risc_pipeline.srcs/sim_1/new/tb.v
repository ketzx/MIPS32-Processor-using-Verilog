`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/28/2023 06:06:20 PM
// Design Name: 
// Module Name: tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb;
	reg clk1, clk2;
	integer k;
	pipe_mips_32 mips (clk1, clk2);

	initial begin
		clk1 = 0; clk2 = 0;
		repeat (20) begin
			#5 clk1 = 1; #5 clk1 = 0;
			#5 clk2 = 1; #5 clk2 = 0;
		end
	end

	initial begin
		for (k = 0; k < 32; k = k + 1)
			mips.reg_bank[k] = k;
//      Example 1
//		mips.inst_mem[0] = 32'h2801000a;
//		mips.inst_mem[1] = 32'h28020014;
//		mips.inst_mem[2] = 32'h28030019;
//		mips.inst_mem[3] = 32'h0ce77800;
//		mips.inst_mem[4] = 32'h0ce77800;
//		mips.inst_mem[5] = 32'h00222000;
//		mips.inst_mem[6] = 32'h0ce77800;
//		mips.inst_mem[7] = 32'h00832800; // Fixed typo: 'mipa' should be 'mips'
//		mips.inst_mem[8] = 32'hfc000000;

//      Example 2

		mips.inst_mem[0] = 32'h28010078;
		mips.inst_mem[1] = 32'h0c631800;
		mips.inst_mem[2] = 32'h20220000;
		mips.inst_mem[3] = 32'h0c631800;
		mips.inst_mem[4] = 32'h2842002d;
		mips.inst_mem[5] = 32'h0c631800;
		mips.inst_mem[6] = 32'h24220001;
		mips.inst_mem[7] = 32'hfc000000; // Fixed typo: 'mipa' should be 'mips'
		mips.inst_mem[120] = 85;

//      Example 3
//        mips.inst_mem[200] = 7;

//		mips.inst_mem[0] = 32'h280a00c8;
//		mips.inst_mem[1] = 32'h28020001;
//		mips.inst_mem[2] = 32'h0e94a000;
//		mips.inst_mem[3] = 32'h21430000;
//		mips.inst_mem[4] = 32'h0e94a000;
//		mips.inst_mem[5] = 32'h14431000;
//		mips.inst_mem[6] = 32'h2c630001;
//		mips.inst_mem[7] = 32'h0e94a000; 		
//		mips.inst_mem[8] = 32'h3460fffc;
//		mips.inst_mem[10] = 32'h84050000;
//		mips.inst_mem[9] = 32'h2542fffe;
//		mips.inst_mem[10] = 32'hfc000000;

		mips.HALTED = 0;
		mips.PC = 0;
		mips.TAKEN_BRANCH = 0;
		
		#2000;
      
		for (k = 0; k < 6; k = k + 1)
			$display("R%1d - %2d", k, mips.reg_bank[k]);
	end

	initial begin
//		$dumpfile("mips.vcd");
//		$dumpvars(0, test_mips32);
		#300 $finish;
	end
endmodule
