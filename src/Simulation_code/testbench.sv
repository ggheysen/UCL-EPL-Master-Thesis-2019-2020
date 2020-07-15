`timescale 1 ns / 100 ps

//import
`include "tb_pkg.sv"

//testbench
module testbench();
	logic [15:0] test_vector [7:0];
	logic clk, rst;
	logic w_e, r_e; //Start either filling ram or getting values from it
	logic r_valid; // When the component reads the main memory, enable means valid value
	logic [15:0] r_value, ram_value;
	logic w_valid, r_req;
	logic [2:0] ram_addr;
	logic ffill, fwrite;
	
	//Clock
	always 
		begin
			clk = ~clk; #hlf_clk;
		end
		
	//Instantiate module
   inverted_residual_block dut (.clk(clk), .rst(rst),
										 .i_w(w_e), .i_r(r_e),
										 .r_valid(r_valid),
										 .r_value(r_value), .ram_val(ram_value),
										 .w_valid(w_valid), .r_req(r_req),
										 .adr_val(ram_addr),
										 .ffill(ffill), .fwrite(fwrite));
	
		
	// Initiate Memory
	initial 
		begin
			clk <= 0; rst <= 1; r_valid <= 1; #full_clk;
			$readmemh("simulation_file/test1.txt", test_vector);
			#full_clk; #full_clk; #full_clk;
			rst = 0; #full_clk; #full_clk; #full_clk;
			w_e <= 1; #full_clk;
			w_e <= 0;
			while(ffill == 0) begin
				#full_clk;
			end
			#full_clk; #full_clk;
			r_e <= 1; #full_clk;
			r_e <= 0;
		end
	
	always @(posedge clk) begin
		if(r_req) begin 
			r_value <= test_vector[ram_addr];
			r_valid <= 1;
		end
		else begin
			r_valid <= 0;
		end
	end
	
	always @(posedge fwrite) begin
		$finish;
	end
	
endmodule
