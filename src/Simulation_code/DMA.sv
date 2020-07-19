//import
`include "dma_pkg.sv"

module DMA( input  logic clk, rst, 										// Clock and reset signals
				input	 logic s_op,											// Enabled when the DMA has to perform a transfer
				input  logic [2:0] op,										// The operation 
				input  logic r_valid_extmem,								// When enabled, the DMA can read the signal sent by external memory
				output logic r_request_extmem,							// Enabled when the DMA has to read from the external memory
				output logic e_op,											// Enabled when the DMA has finished the transaction
				output logic write,											// enabled when the DMA has to Write on the different buffer and external memory
				input  logic [7:0]  tx_i, ty_i, x_mem_i, y_mem_i,	// Address signal to tell where to read from the external memory
				input	 logic [31:0] data_extmem,							// Data sent by external memory
				output logic [31:0] addr_extmem,							// Address to read/write from external memory
				output logic [15:0] ram_addr,								// Address to write to a RAM
				output logic [31:0] ram_data,								// Data to write to a RAM
				output logic [41:0] inf_conv								// Information of the convolution (for main controller)
			  );

	// states of the FSM
	typedef enum logic [4:0] {IDLE, FINISHED, 
									  R_INIT, W_INIT, 
									  R_FMI, W0_FMI, W1_FMI, A_FMI, 
									  R_KEXP, W_KEXP, 
									  R_KPW, W_KPW, A_KPW} statetype; 
									  
	statetype state, state_n;
	
	// Register
	logic [7:0]		Nix, Niy; 			  // Spatial Dimensions
	logic [10:0]	Nif, Nof, Ngr;		  // channel dimensions & number of kernel groups of size Npar
	logic [2:0]		t;						  // Expansion factor
	logic 			S;						  // Stride
	logic [31:0] 	data;					  // Data request from a memory bank
	logic [7:0] 	x, y, x_mem, y_mem, tx, ty, tx_mem, ty_mem, x_ref, y_ref; // Information needed to construct the right address
	logic [10:0]	f, f_mem; // Information needed to construct the right address
	
	
	// Next value for registers
	logic [7:0]		Nix_n, Niy_n;
	logic [10:0]	Nif_n, Nof_n, Ngr_n;
	logic [2:0]		t_n;
	logic 			S_n;
	logic [31:0] 	addr_extmem_n;
	logic [31:0] 	data_n;
	logic [15:0] 	ram_addr_n;
	logic [7:0] 	x_n, y_n, x_mem_n, y_mem_n, tx_n, ty_n, tx_mem_n, ty_mem_n, x_ref_n, y_ref_n;
	logic [10:0]	f_n, f_mem_n;
	
	// Memory (offset & multiplication)
	logic [31:0] mem_offset [7:0];
	
	// SEQ LOGIQE
	always_ff @(posedge clk, posedge rst)
		if(rst) begin // If reset enabled, set to initial values
			state <= IDLE;
			Nix 	<= '0; Niy 	<= '0;
			Nif 	<= '0; Nof 	<= '0; 
			Ngr 	<= '0;
			t 		<= '0; S 	<=  0;
			addr_extmem	  <= '0;
			ram_addr		  <= '0;
			data			  <= '0;
			x		 <= '0; y	   <= '0; 
			x_mem	 <= '0; y_mem  <= '0;
			tx		 <= '0; ty	   <= '0;
			tx_mem <= '0; ty_mem	<= '0;
			x_ref <= '0; y_ref	<= '0;
			f <= '0; f_mem <= '0;
		end
		else begin // Else, take next values
			state <= state_n;
			Nix 	<= Nix_n; Niy 	<= Niy_n;
			Nif 	<= Nif_n; Nof 	<= Nof_n;
			Ngr 	<= Ngr_n;
			t 		<= t_n; 	 S 	<= S_n;
			ram_addr <= ram_addr_n;
			addr_extmem <= addr_extmem_n;
			data			<= data_n;
			x		 <= x_n; 		y	    <= y_n; 
			x_mem	 <= x_mem_n; 	y_mem  <= y_mem_n;
			tx		 <= tx_n; 		ty	    <= ty_n;
			tx_mem <= tx_mem_n;	ty_mem <= ty_mem_n;
			tx_mem <= tx_mem_n;	ty_mem <= ty_mem_n;
			x_ref <= x_ref_n	; y_ref	<= y_ref_n;
			f <= f_n; f_mem <= f_mem_n;
		end 
	
	// COMB LOGIQUE
	// Convolution information
	assign inf_conv[7:0]   = Nix;
	assign inf_conv[15:8]  = Niy;
	assign inf_conv[26:16] = Nif;
	assign inf_conv[37:27] = Nof;
	assign inf_conv[40:38] = t;
	assign inf_conv[41]    = S;
	// DMA finished transfer when in final states
	assign e_op = (state == FINISHED);
	// When the DMA asks access to external memory
	assign r_request_extmem = (state == R_INIT || state == R_FMI || state == R_KEXP);
	// Data to write the RAM
	assign ram_data = data;
	// Write to RAM (depending on state)
	assign write = (state == W0_FMI || state == W1_FMI || state == W_KEXP);
	// Store constant depending on the layer parameters
	assign mem_offset[5] = (Nix + Nix[0]) * Niy;
	assign mem_offset[6] = Ngr * Nnp;
	assign mem_offset[7] = Nif * t;
	
	always_comb begin
		// If no values has changed
		state_n = state;
		Nix_n   = Nix; Niy_n   = Niy;
		Nif_n   = Nif; Nof_n   = Nof;
		Ngr_n = Ngr;
		t_n 	  = t; 	 S_n 	  = S;
		addr_extmem_n	 = addr_extmem;
		data_n = data;
		x_n		  = x; 		y_n	   = y; 
		x_mem_n	  = x_mem; 	y_mem_n  = y_mem;
		tx_n		  = tx; 		ty_n     = ty;
		tx_mem_n	  = tx_mem;	ty_mem_n = ty_mem;
		x_ref_n		  = x_ref; 		y_ref_n	   = y_ref; 
		ram_addr_n = ram_addr;
		f_n = f; f_mem_n = f_mem;
		// FSM
		case(state)
			/* ############################################### */
			// IDLE state
			IDLE: begin
				if(s_op) begin
					case(op)
						0: begin // Initialization
							state_n 			 = R_INIT;
							addr_extmem_n 	 = '0;			
						end
						
						1: begin // Fill IFM buffer
							state_n 			 = R_FMI;
							ram_addr_n 	 =  '0;
							// Variables
							x_n = 1; y_n = 1; f_n = 1;
							x_mem_n = x_mem_i; y_mem_n = y_mem_i; f_mem_n = 0;
							tx_n = tx_i; ty_n = ty_i; 
							// Reference
							tx_mem_n = tx_i; ty_mem_n = ty_i;
							x_ref_n =  x_mem_i; y_ref_n = y_mem_i;
							// New address
							addr_extmem_n 	 = mem_offset[0] + ((x_mem_i + y_mem_i) >> 1);
						end
						
						2: begin // Fill Kexp buffer
							state_n 			 = R_KEXP;
							ram_addr_n 	 =  '0;
							// Variables - y not used, tx_i => par, x_mem_i, par in memory, 
							x_n = 1; f_n = 1; tx_n = tx_i; // Tx_i contains the number of the par channel
							// New address
							addr_extmem_n 	 = mem_offset[2] + x_mem_i; // x_mem_i contains the adress of the par channel
						end
						
						3: begin // Fill KPW buffer
							state_n 			 = R_KPW;
							x_n = 1; f_n = tx_i; // Tx_i represents which group to select, we load every weight from 1 to Nof corresponding to that group in the kernel
							x_mem_n = 0 ; f_mem_n = x_mem_i;
							x_ref_n = x_mem_i;
							addr_extmem_n 	 = mem_offset[3] + x_mem_i; // x_mem_i contains the adress of the par channel
						end
						default: state_n = IDLE;
					endcase
				end
			end
			
			/* ############################################### */
			// FMI states
			
			R_FMI: begin
				if(r_valid_extmem) begin
					if ((tx[0] ^ x[0]) && x == 1) begin
						data_n[15:0] = data_extmem[31:16];
						state_n = W1_FMI;
					end
					else begin
						data_n = data_extmem;
						state_n = W0_FMI;
					end
					if(tx[0] ^ x[0]) begin
						state_n = W1_FMI;
					end
					else begin
						state_n = W0_FMI;
					end
				end
			end
			
			W0_FMI: begin
				// Update address
				ram_addr_n = ram_addr + 1;
				// Changing the state
				if (x == Tix || tx == Nix) begin 
					x_n = 1; x_mem_n = x_ref; tx_n = tx_mem;
					if(y == Tiy || ty == Niy) begin
						y_n = 1; y_mem_n = y_ref; ty_n = ty_mem;
						if (f == Nif) begin
							state_n 			 = FINISHED;
						end
						else begin
							state_n = A_FMI;
							f_n = f + 1; f_mem_n  = f_mem + mem_offset[5];
						end
					end
					else begin
						state_n = A_FMI;
						y_n = y + 1; y_mem_n = y_mem + Nix+ Nix[0]; ty_n = ty + 1;
					end
				end
				else if (~x[0]) begin
					state_n = A_FMI;
					x_mem_n = x_mem + 1;
					x_n = x + 1;
					tx_n = tx + 1;
				end
				else begin
					state_n = W0_FMI;
					data_n[15:0] = data[31:16];
					x_mem_n = x_mem + 1;
					x_n = x + 1; 
					tx_n = tx + 1;
				end
			end
			
			W1_FMI: begin
				// Update address
				ram_addr_n = ram_addr + 1;
				// Changing the state
				if (x == Tix || tx == Nix) begin 
					x_n = 1; x_mem_n = x_ref; tx_n = tx_mem;
					if(y == Tiy || ty == Niy) begin
						y_n = 1; y_mem_n = y_ref; ty_n = ty_mem;
						if (f == Nif) begin
							state_n 			 = FINISHED;
						end
						else begin
							state_n = A_FMI;
							f_n = f + 1; f_mem_n  = f_mem + mem_offset[5];
						end
					end
					else begin
						state_n = A_FMI;
						y_n = y + 1; y_mem_n = y_mem + Nix+ Nix[0]; ty_n = ty + 1;
					end
				end
				else if (x[0]) begin
					state_n = A_FMI;
					x_mem_n = x_mem + 1;
					x_n = x + 1;
					tx_n = tx + 1;
				end
				else begin
					state_n = W1_FMI;
					data_n[15:0] = data[31:16];
					x_mem_n = x_mem + 1;
					x_n = x + 1;
					tx_n = tx + 1;
				end
			end
			
			A_FMI: begin
				addr_extmem_n = mem_offset[0] + ((f_mem + x_mem + y_mem) >> 1);
				state_n = R_FMI;
			end
			
			/* ############################################### */
			// KEXP States
			
			R_KEXP: begin
				if(r_valid_extmem) begin
						state_n = W_KEXP;
						data_n = data_extmem;
				end
			end
			
			W_KEXP: begin
				// Update address
				ram_addr_n = ram_addr + 1;
				addr_extmem_n = addr_extmem + 1;
				// Changing the state
				if (f == mem_offset[6]) begin 
					f_n = 1; f_mem_n = '0;
					if(x == Npar || tx == mem_offset[7]) begin
							state_n = FINISHED;
					end
					else begin
						state_n = R_KEXP;
						tx_n = tx + 1;
						x_n = x + 1;
					end
				end
				else begin
					state_n = R_KEXP;
					f_n = f + 1;
				end
			end
			
			/* ############################################### */
			// KPW States
			R_KPW: begin
				if(r_valid_extmem) begin
						state_n = W_KPW;
						data_n = data_extmem;
				end
			end
			W_KPW: begin
			end
			A_KPW: begin
			end
			/* ############################################### */
			//Init states
			
			R_INIT: begin
				if(r_valid_extmem) begin
					state_n = W_INIT;
					data_n = data_extmem;
				end
			end
			
			W_INIT: begin
				// Changing the state
				if (addr_extmem == init_words - 1) begin
					state_n = FINISHED;
				end
				else begin
					state_n = R_INIT;
					addr_extmem_n = addr_extmem + 1;
				end
				// Handling the signals
				case (addr_extmem)
				0: begin
					Nix_n   = data[7:0]; 
					Niy_n   = data[15:8];
					t_n 	  = data[18:16]; 	 
					S_n 	  = data[19];
				end
				1:begin
					Nif_n   = data[10:0]; 
					Nof_n   = data[21:11];
					Ngr_n	  = data[31:22];
				end
				2:begin // IFM
					mem_offset[0] = data;
				end
				3:begin // OFM
					mem_offset[1] = data;
				end
				4:begin // KEXP
					mem_offset[2] = data;
				end
				5:begin; // KPW
					mem_offset[3] = data;
				end
				6:begin // KDW
					mem_offset[4] = data;
				end
				default: state_n = FINISHED;
				endcase
			end
			
			/* ############################################### */
			// Finish state
			FINISHED: begin
				state_n = IDLE;
			end

		endcase
	end

endmodule
