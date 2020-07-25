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
module RAM_FMI(
	input logic clk,
	input logic [$clog2(FMI_N_ELEM)-1:0] addr,
	input logic [PX_W-1:0] data,
	input logic write,
	output logic [PX_W-1:0] res);
	
	logic [PX_W-1:0] mem [FMI_N_ELEM-1:0];

	always_ff @(posedge clk) begin
	if (write) begin
		mem[addr] <= data;
		res <= data;
	end 
	else res <= mem[addr];
	end
endmodule
