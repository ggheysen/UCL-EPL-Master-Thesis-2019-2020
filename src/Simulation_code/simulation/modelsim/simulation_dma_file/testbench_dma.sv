`timescale 1 ns / 100 ps

//import
`include "tb_pkg.sv"
import dma_pkg::*;

//testbench
module testbench_dma();
	int fd_inf, fd_fmi, fd_kex, fd_kpw, fd_kdw, fd_res_fmi, fd_res_fmo, fd_res_kex, fd_res_kpw, fd_res_kdw; // File descriptor
	int cnt;
	logic clk, rst;
	logic s_op;
	logic [2:0] op;
	logic w_fmi, w_fmo, w_kex, w_kpw, w_kdw;
	logic r_valid_extmem, r_valid_extmem_n;
	logic r_request_extmem;
	logic e_op;
	logic [31:0] data_extmem, data_extmem_n, ram_data, w_data_exmem;
	logic [31:0] addr_extmem;
	logic [15:0] ram_addr;
	logic [41:0] inf_conv;
	logic [31:0]  tx_i, ty_i, x_mem_i, y_mem_i;
	logic [WG_W - 1:0] kdw_res;
	logic [WG_W + $clog2(Npar)- 1:0] kex_res, kpw_res;
	logic [PX_W - 1:0] fmi_res, fmo_res;
	
	//Clock
	always 
		begin
			clk = ~clk; #hlf_clk;
		end
		
	//Instantiate module
   DMA dut(.clk(clk), 
				.rst(rst),
				.s_op(s_op), 
				.op(op),
				.r_valid_extmem(r_valid_extmem),
				.r_request_extmem(r_request_extmem),
				.e_op(e_op),
				.w_fmi(w_fmi), .w_kex(w_kex), .w_kpw(w_kpw), .w_kdw(w_kdw), .w_ext(w_fmo),
				.tx_i(tx_i), .ty_i(ty_i), .x_mem_i(x_mem_i), .y_mem_i(y_mem_i),
				.data_extmem(data_extmem),
				.ram_data_i(fmo_res),
				.addr_extmem(addr_extmem), 
				.ram_addr(ram_addr), 
				.w_data(ram_data),
				.inf_conv(inf_conv));
				
	RAM_FMI ram_fmi( .clk(clk), .addr(ram_addr[$clog2(FMI_N_ELEM) - 1:0]), .write(w_fmi), .data(ram_data[PX_W - 1:0]), 			.res(fmi_res));
	RAM_FMO ram_fmo( .clk(clk), .addr(ram_addr[$clog2(FMO_N_ELEM) - 1:0]), .write(0), .data(ram_data[PX_W - 1:0]), 			.res(fmo_res));
	RAM_KEX ram_kex( .clk(clk), .addr(ram_addr[$clog2(KEX_N_ELEM) - 1:0]), .write(w_kex), .data(ram_data[WG_W + $clog2(Npar) - 1:0]), .res(kex_res));
	RAM_KPW ram_kpw( .clk(clk), .addr(ram_addr[$clog2(KPW_N_ELEM) - 1:0]), .write(w_kpw), .data(ram_data[WG_W + $clog2(Npar) - 1:0]), .res(kpw_res));
	RAM_KDW ram_kdw( .clk(clk), .addr(ram_addr[$clog2(KDW_N_ELEM) - 1:0]), .write(w_kdw), .data(ram_data[WG_W - 1:0]), 			.res(kdw_res));
		
	// Initiate Memory
	initial 
		begin
			clk <= 0; rst <= 1; s_op = 0; op = 0;  tx_i = '0; ty_i ='0; x_mem_i = '0; y_mem_i = '0; cnt = 0;
			fd_res_fmi = $fopen("simulation_dma_file/result_fmi.txt", "w");
			fd_res_fmo = $fopen("simulation_dma_file/result_fmo.txt", "w");
			fd_res_kex = $fopen("simulation_dma_file/result_kexp.txt", "w");
			fd_res_kpw = $fopen("simulation_dma_file/result_kpw.txt", "w");
			fd_res_kdw = $fopen("simulation_dma_file/result_kdw.txt", "w");
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
				fd_inf = $fopen("simulation_dma_file/inf_conv.txt", "r");
				for (int i=0; i<=addr_extmem - offset_inf_conv; i=i+1) begin
					$fscanf(fd_inf,"%h\n", data_extmem_n);
					if (i == addr_extmem - offset_inf_conv) 
						r_valid_extmem_n = 1;
			 end
			 $fclose(fd_inf);
			 end
			 else if (addr_extmem >= offset_fmi &&  addr_extmem < offset_fmo) begin
				fd_fmi = $fopen("simulation_dma_file/fmi.txt", "r");
				for (int i=0; i<= addr_extmem - offset_fmi; i=i+1) begin
					$fscanf(fd_fmi,"%h\n", data_extmem_n);
					if (i == addr_extmem - offset_fmi)
						r_valid_extmem_n = 1;
			 end
			 $fclose(fd_fmi);
			 end
			 else if (addr_extmem >= offset_kex &&  addr_extmem < offset_kpw) begin
				fd_kex = $fopen("simulation_dma_file/kexp.txt", "r");
				for (int i=0; i<= addr_extmem - offset_kex; i=i+1) begin
					$fscanf(fd_kex,"%h\n", data_extmem_n);
					if (i == addr_extmem - offset_kex)
						r_valid_extmem_n = 1;
				end
			end
			else if (addr_extmem >= offset_kpw &&  addr_extmem < offset_kdw) begin
				fd_kpw = $fopen("simulation_dma_file/kpw.txt", "r");
				for (int i=0; i<= addr_extmem - offset_kpw; i=i+1) begin
					$fscanf(fd_kpw,"%h\n", data_extmem_n);
					if (i == addr_extmem - offset_kpw)
						r_valid_extmem_n = 1;
				end
			end
			else if (addr_extmem >= offset_kdw) begin
				fd_kdw = $fopen("simulation_dma_file/kdw.txt", "r");
				for (int i=0; i<= addr_extmem - offset_kdw; i=i+1) begin
					$fscanf(fd_kdw,"%h\n", data_extmem_n);
					if (i == addr_extmem - offset_kdw)
						r_valid_extmem_n = 1;
				end
			end
		end
	end
	
	always @(posedge clk) begin
		if (w_fmi) begin
			$fwrite(fd_res_fmi, "%d : %d\n", ram_data[PX_W - 1:0], ram_addr[$clog2(FMI_N_ELEM) - 1:0]);
		end
		else if (w_fmo) begin
			$fwrite(fd_res_fmo, "%d : %d\n", fmo_res , addr_extmem - offset_fmo);
		end
		else if (w_kex) begin
			$fwrite(fd_res_kex, "%d : %d : %d\n", ram_data[WG_W - 1:0], ram_data[WG_W + $clog2(Npar) - 1:WG_W], ram_addr[$clog2(KEX_N_ELEM) - 1:0]);
		end
		else if (w_kpw) begin
			$fwrite(fd_res_kpw, "%d : %d : %d\n", ram_data[WG_W - 1:0], ram_data[WG_W + $clog2(Npar) - 1:WG_W], ram_addr[$clog2(KPW_N_ELEM) - 1:0]);
		end
		else if (w_kdw) begin
			$fwrite(fd_res_kdw, "%d : %d\n", ram_data[WG_W - 1:0], ram_addr[$clog2(KDW_N_ELEM) - 1:0]);
		end
	end
	
	always @(posedge e_op) begin
		if (cnt == 5) begin // FMO
			#full_clk;
			$fclose(fd_res_fmo);
			$stop;
		end
		else if (cnt == 4) begin // FMO
			cnt = cnt + 1;
			s_op = 0;
			op = op+1;
			#full_clk;
			#full_clk;
			tx_i = 1; x_mem_i = 0;
			ty_i = 1; y_mem_i = 0;
			s_op = 1;
			$fclose(fd_res_kdw);
			#full_clk;
			#full_clk;
			#full_clk;
			s_op = 0;
		end
		else if (cnt == 3) begin  // KDW
			cnt = cnt + 1;
			s_op = 0;
			op = op+1;
			#full_clk;
			#full_clk;
			tx_i = 37; x_mem_i = 324;
			ty_i = 1; y_mem_i = 0;
			s_op = 1;
			$fclose(fd_res_kpw);
			#full_clk;
			#full_clk;
			#full_clk;
			s_op = 0;
		end
		else if (cnt == 2) begin // KPW
			cnt = cnt + 1;
			s_op = 0;
			op = op+1;
			#full_clk;
			#full_clk;
			tx_i = 19; x_mem_i = 18;
			ty_i = 1; y_mem_i = 0;
			s_op = 1;
			$fclose(fd_res_kex);
			#full_clk;
			#full_clk;
			#full_clk;
			s_op = 0;
		end
		else if (cnt == 1) begin // KEXP
			cnt = cnt + 1;
			s_op = 0;
			op = op+1;
			#full_clk;
			#full_clk;
			tx_i = 37; x_mem_i = 144;
			ty_i = 37; y_mem_i = 0;
			s_op = 1;
			$fclose(fd_res_fmi);
			#full_clk;
			#full_clk;
			#full_clk;
			s_op = 0;
		end
		else if (cnt == 0) begin // FMI
			cnt = cnt + 1;
			s_op = 0;
			op = op+1;
			#full_clk;
			#full_clk;
			tx_i = 15; x_mem_i = 14;
			ty_i = 15; y_mem_i = 392;
			s_op = 1;
			#full_clk;
			#full_clk;
			#full_clk;
			s_op = 0;
		end
	end
		
endmodule
