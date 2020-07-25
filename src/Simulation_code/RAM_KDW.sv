/* 
	Description : Component DMA which handles the transactions between the external and the on-chip memory
	Author : 	  Guillaume Gheysen
*/
 
/* 
	###################################################################################################################################
	# import 																																								 #
   ###################################################################################################################################
*/
import ram_pkg::*;
/* 
	###################################################################################################################################
	# module definition 																																					 #
   ###################################################################################################################################
*/
module RAM_KDW(
	input logic clk,
	input logic [$clog2(KDW_N_ELEM)-1:0] addr,
	input logic [WG_W -1:0] data,
	input logic write,
	output logic [WG_W-1:0] res);
	
	logic [WG_W-1:0] mem [KDW_N_ELEM-1:0];

	always_ff @(posedge clk) begin
	if (write) begin
		mem[addr] <= data;
		res <= data;
	end 
	else res <= mem[addr];
	end
endmodule
