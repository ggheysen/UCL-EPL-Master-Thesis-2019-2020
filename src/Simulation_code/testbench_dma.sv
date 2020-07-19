`timescale 1 ns / 100 ps

//import
`include "tb_pkg.sv"

//testbench
module testbench_dma();
	int fd_inf, fd_fmi, fd_kexp, fd_res; // File descriptor
	int cnt;
	logic clk, rst;
	logic s_op;
	logic [2:0] op;
	logic write_fmi;
	logic r_valid_extmem, r_valid_extmem_n;
	logic r_request_extmem;
	logic e_op;
	logic [31:0] data_extmem, data_extmem_n, ram_data;
	logic [31:0] addr_extmem;
	logic [15:0] ram_addr;
	logic [41:0] inf_conv;
	logic [7:0]  tx_i, ty_i, x_mem_i, y_mem_i;
	
	//Clock
	always 
		begin
			clk = ~clk; #hlf_clk;
		end
		
	//Instantiate module
   DMA dut(.clk(clk), .rst(rst),
				.s_op(s_op), .op(op),
				.r_valid_extmem(r_valid_extmem),
				.r_request_extmem(r_request_extmem), .tx_i(tx_i), .ty_i(ty_i), .x_mem_i(x_mem_i), .y_mem_i(y_mem_i),
				.e_op(e_op), .write(write_fmi), .data_extmem(data_extmem),
				.addr_extmem(addr_extmem), .ram_addr(ram_addr), .ram_data(ram_data),
				.inf_conv(inf_conv)
				);
				
		
	// Initiate Memory
	initial 
		begin
			clk <= 0; rst <= 1; s_op = 0; op = 2;  tx_i = '0; ty_i ='0; x_mem_i = '0; y_mem_i = '0; cnt = 0;
			fd_res = $fopen("simulation_file/result.txt", "w");
			#ini_wait;
			#lng_wait;
			rst = 0;
			#lng_wait;	
			s_op = 1;
			op = 0;
		end
	
	always @(posedge clk) begin
		data_extmem <= data_extmem_n;
		r_valid_extmem <= r_valid_extmem_n;
	end
	
	always_comb begin
		r_valid_extmem_n = '0;
		data_extmem_n = '0;
		if(r_request_extmem) begin
			 if (addr_extmem >= offset_inf_conv &&  addr_extmem < offset_fmi) begin
				fd_inf = $fopen("simulation_file/inf_conv.txt", "r");
				for (int i=0; i<=addr_extmem - offset_inf_conv; i=i+1) begin
					$fscanf(fd_inf,"%h\n", data_extmem_n);
					if (i == addr_extmem - offset_inf_conv) 
						r_valid_extmem_n = 1;
			 end
			 $fclose(fd_inf);
			 end
			 else if (addr_extmem >= offset_fmi &&  addr_extmem < offset_fmo) begin
				fd_fmi = $fopen("simulation_file/fmi.txt", "r");
				for (int i=0; i<= addr_extmem - offset_fmi; i=i+1) begin
					$fscanf(fd_fmi,"%h\n", data_extmem_n);
					if (i == addr_extmem - offset_fmi)
						r_valid_extmem_n = 1;
			 end
			 $fclose(fd_fmi);
			 end
			 else if (addr_extmem >= offset_kex &&  addr_extmem < offset_kpw) begin
				fd_kexp = $fopen("simulation_file/kexp.txt", "r");
				for (int i=0; i<= addr_extmem - offset_kex; i=i+1) begin
					$fscanf(fd_kexp,"%h\n", data_extmem_n);
					if (i == addr_extmem - offset_kex)
						r_valid_extmem_n = 1;
				end
			end
			else if (addr_extmem >= offset_kpw &&  addr_extmem < offset_kdw) begin
				fd_kexp = $fopen("simulation_file/kpw.txt", "r");
				for (int i=0; i<= addr_extmem - offset_kpw; i=i+1) begin
					$fscanf(fd_kexp,"%h\n", data_extmem_n);
					if (i == addr_extmem - offset_kex)
						r_valid_extmem_n = 1;
				end
			end
		end
	end
	
	
	always @(posedge e_op) begin
		if (cnt == 1) begin
			#full_clk;
			$fclose(fd_res);
			$stop;
		end
		else if (cnt == 0) begin
			cnt = cnt + 1;
			s_op = 0;
			op = 3;
			#full_clk;
			#full_clk;
			tx_i = 5; x_mem_i = 16;
			s_op = 1;
			#full_clk;
			#full_clk;
			#full_clk;
			s_op = 0;
		end
	end
		
	always @(posedge clk) begin
		if (write_fmi) begin
			$fwrite(fd_res, "%d\n", ram_data[15:0]);
			$display("%d", ram_addr)
		end
	end
endmodule
