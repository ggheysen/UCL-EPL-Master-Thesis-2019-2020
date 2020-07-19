`include "dma_pkg.sv"

module RAM_FMI(
	input logic clk,
	input logic [FMI_ADDR_W-1:0] addr,
	input logic [15:0] data,
	input logic write,
	output logic [15:0] res);
	
	logic [15:0] mem [FMI_N_ELEM-1:0];

	always_ff @(posedge clk) begin
	if (write) begin
		mem[addr] <= data;
		res <= data;
	end 
	else res <= mem[addr];
	end
endmodule
