`timescale 1 ns / 1 ns

//testbench
module testbench();

	/*
		#############################
		# 			parameters			 #
		#############################
	*/
	
	parameter hlf_clk  = 5;
	parameter full_clk = 2*hlf_clk;
	parameter lng_wait = 10*hlf_clk;
	parameter ini_wait = 10;
	parameter offset_inf_conv = 0;
	parameter offset_fmi = 2*(2**20);
	parameter offset_fmo = 4*(2**20);
	parameter offset_kex = 6*(2**20);
	parameter offset_kpw = 26*(2**20);
	parameter offset_kdw = 44*(2**20);
	parameter Tox_I = 7;
	parameter Tix 	= 2*Tox_I;
	parameter Tox 	= Tix;
	
	parameter Toy_I = 7;
	parameter Tiy 	= 2*Toy_I;
	parameter Toy 	= Tiy;
	
	parameter Nkx 	= 3;
	parameter Nky  = 3;
	
	parameter Tif 	= 8;
	parameter Tof 	= Tif;
	
	parameter Npar = 8;
	
	parameter Nnp 	= 2;
	parameter Size_Par = Npar * Nnp;
	parameter KDWSize = Nkx * Nky; // 16 bits each weight
	parameter init_words = 8;
	parameter PX_W = 16;
	parameter WG_W = 16;
	// RAM FMI param
	parameter FMI_N_ELEM = Tix * Tiy * Tif;
	parameter FMI_N_CHAN = Tix * Tiy;
	// RAM FMO param
	parameter FMO_N_ELEM = Tox * Toy * Tof;
	// RAM KEX param
	parameter KEX_N_ELEM = Nnp * Tif; // Normally, Nnp * maximum possible Ngr * Npar, but as max Ngr = (max Nif)/Npar => Nnp * Nif
	// RAM KPW param
	parameter KPW_N_ELEM = Nnp * Tof;
	// RAM FDW param
	parameter KDW_N_ELEM = Nkx * Nky * Npar;
	// RAM FMINT param
	parameter FMINT_N_ELEM = Tix * Tiy * Npar;
	/*
		#############################
		# 			dut signals			 #
		#############################
	*/
	// File descriptors
	int fd_inf    , fd_fmi      , fd_kex;
	int fd_res_fmi, fd_res_fmint, fd_res_kex, fd_res_fmo;
	// DUT input
	logic clk, rst, start;
	logic valid_data;
	logic [31:0] data_2_l;
	// DUT output
	logic finish_dut;
	logic request_dut, write_dut;
	logic [31:0] addr_dut, data_dut;
	logic w_fmi_dut, w_kex_dut, w_kpw_dut, w_kdw_dut, w_fmint_dut;
	logic [31:0] ram_addr_dut;
	logic f1, f2;
	// Control signals
	//Valid data
	logic valid_data_n;
	// Data_2_l
	logic [31:0] data_2_l_n;
	// Request
	logic request;
	//Finish
	logic finish; 
	//Write
	logic write;
	//write_
	logic w_fmi, w_kex, w_kpw, w_kdw, w_fmint;
	logic [31:0] addr;
	logic [31:0] data;
	// ram_addr_dut
	logic [31:0] ram_addr;
	
	//
	logic signed [15:0] test1, test2, test4;
	logic signed [31:0] test3;
	//Clock
	always 
		begin
			clk = ~clk; #hlf_clk;
		end
	
	/*
		#############################
		# 		dut instantiation	    #
		#############################
	*/
	inverted_residual_block dut(.clk(clk), .rst(rst), .start(start),
									.valid_extmem(valid_data),
									.data_extmem(data_2_l),
									.finish(finish_dut),
									.request_extmem(request_dut), . write_extmem(write_dut),
									.addr_extmem(addr_dut),
									.w_data(data_dut),
									.w_fmi(w_fmi_dut), .w_kex(w_kex_dut), .w_kpw(w_kpw_dut),
									.w_kdw(w_kdw_dut), .w_fmint(w_fmint_dut),
									.ram_addr_dma(ram_addr_dut),
									.finish_dma(f1), .finish_conv11(f2)
									 );
	/*
		#############################
		#  signals initalization    #
		#############################
	*/
	// Initiate Memory
	initial 
		begin
			clk <= 0; rst <= 1; start = 0; valid_data = 0;
			fd_res_fmi = $fopen("simulation_file/result_fmi.txt", "w");
			fd_res_fmint = $fopen("simulation_file/result_fmint.txt", "w");
			fd_res_kex = $fopen("simulation_file/result_kexp.txt", "w");
			fd_res_fmo = $fopen("simulation_file/result_fmo.txt", "w");
			#ini_wait;
			#lng_wait;
			rst <= '0;
			start <= 1;
			//test1 = 16'h0eee;
			//test2 = 16'h0ce0;
			//test3 = test1 * test2;
			//test4 = test3[32-4-1:32-4-16] + test3[32-4-1];
			//$display("%h \n", test4);
			//$stop; 
	end
	
	/*
		#############################
		#  	  Comb logic	       #
		#############################
	*/
	
	// Write results	
	always @(posedge clk) begin
		if (w_fmi) begin
			$fwrite(fd_res_fmi, "%h : %d\n", data[PX_W - 1:0], ram_addr);
		end
		else if (write) begin
			$fwrite(fd_res_fmo, "%h : %d\n", data[PX_W - 1:0], addr - offset_fmo);
		end
		else if (w_fmint) begin
			$fwrite(fd_res_fmint, "%h : %d\n", data[PX_W - 1:0], ram_addr);
		end
		else if (w_kex) begin
			$fwrite(fd_res_kex, "%h : %h : %d\n", data[WG_W - 1:0], data[WG_W + $clog2(Npar) - 1:WG_W], ram_addr);
		end
	end
	
	// Read ext memfor dut
	always_comb begin
		valid_data_n = '0;
		data_2_l_n = '0;
		if (request) begin
			if (addr >= offset_inf_conv &&  addr < offset_fmi) begin
				fd_inf = $fopen("simulation_file/inf_conv.txt", "r");
				for (int i=0; i<=addr - offset_inf_conv; i=i+1) begin
					$fscanf(fd_inf,"%h\n", data_2_l_n); 
					if (i == addr - offset_inf_conv)
						valid_data_n = 1;
			 end
			 $fclose(fd_inf);
			 end
			 else if (addr >= offset_fmi &&  addr < offset_fmo) begin
				fd_fmi = $fopen("simulation_file/fmi.txt", "r");
				for (int i=0; i<= addr - offset_fmi; i=i+1) begin
					$fscanf(fd_fmi,"%h\n", data_2_l_n);
					if (i == addr - offset_fmi)
						valid_data_n = 1;
			 end
			 $fclose(fd_fmi);
			 end 
			 else if (addr >= offset_kex &&  addr < offset_kpw) begin
				fd_kex = $fopen("simulation_file/kex.txt", "r"); 
				for (int i=0; i<= addr - offset_kex; i=i+1) begin
					$fscanf(fd_kex,"%h\n", data_2_l_n);
					if (i == addr - offset_kex)
						valid_data_n = 1;
				end
			end
		end
	end
	
	/*
		#############################
		#  	  Seq logic	          #
		#############################
	*/
	always @(posedge clk) begin
		// Write to DUT
		valid_data = valid_data_n;
		data_2_l = data_2_l_n;
		// Read from DUT
		request <= request_dut;
		write <= write_dut;
		w_fmi <= w_fmi_dut;
		w_kex <= w_kex_dut;
		w_kpw <= w_kpw_dut;
		w_kdw <= w_kdw_dut;
		w_fmint <= w_fmint_dut;
		finish <= finish_dut;
		addr <= addr_dut;
		data <= data_dut;
		ram_addr <= ram_addr_dut;
	end
	
	/*always @(posedge f1) begin
		$stop;
	end
	always @(posedge f2) begin
		$stop;
	end
	*/
	/*
		#############################
		#  	  End simulation      #
		#############################
	*/
	always @(posedge finish) begin
		#full_clk;
		$fclose(fd_res_kex);
		$fclose(fd_res_fmi);
		$fclose(fd_res_fmint);
		$fclose(fd_res_fmo);
		$stop;
	end
	
endmodule
