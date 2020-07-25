/* 
	Description : Component DMA which handles the transactions between the external and the on-chip memory
	Author : 	  Guillaume Gheysen
*/ 

/* 
	###################################################################################################################################
	# import 																																								 #
   ###################################################################################################################################
*/
import dma_pkg::*;
import ram_pkg::*;

/* 
	###################################################################################################################################
	# module definition 																																					 #
   ###################################################################################################################################
*/

module DMA( input  logic clk, rst, 										// Clock and reset signals
				input	 logic s_op,											// Enabled when the DMA has to perform a transfer
				input  logic [2:0] op,										// The operation 
				input  logic r_valid_extmem,								// When enabled, the DMA can read the signal sent by external memory
				output logic r_request_extmem,							// Enabled when the DMA has to read from the external memory
				output logic e_op,											// Enabled when the DMA has finished the transaction
				output logic w_fmi, w_kex, w_kpw, w_kdw, w_ext,		// enabled when the DMA has to Write on the different buffer and external memory
				input  logic [31:0]  tx_i, ty_i, x_mem_i, y_mem_i,	// Address signal to tell where to read from the external memory
				input	 logic [31:0] data_extmem,							// Data sent by external memory
				input  logic [PX_W-1:0] ram_data_i,
				output logic [31:0] addr_extmem,							// Address to read/write from external memory
				output logic [31:0] ram_addr,								// Address to write to a RAM
				output logic [31:0] w_data,						 		// Data to write to a RAM & Extmem
				output logic [41:0] inf_conv								// Information of the convolution (for main controller)
			  );

	/* 
		###################################################################################################################################
		# internal signals																																					 #
		###################################################################################################################################
	*/
	typedef enum logic [4:0] {IDLE,             
									  FINISHED,					// State telling the DMA has finished its transaction
									  RAM_LOADING,
									  R_INIT, W_INIT, 		// States related about storing the information about the layer
									  R_FMI, W_FMI, A_FMI, 	// States related about writing to FM input buffer
									  R_KEXP, W_KEXP, 		// States related about writing to 1*1 expansion filter buffer
									  R_KPW, W_KPW, A_KPW,	// States related about writing to pointwise filter buffer
									  R_KDW, W_KDW, A_KDW,	// States related about writing to external memory the final results (in output buffer)
									  R_FMO, W_FMO 			// States related about writing to external memory the final results (in output buffer)
									  } statetype; 
									  
	statetype state, state_n; // Variables containing the state
	
	// Registers
	logic [7:0]		Nix, Niy, Nox, Noy; 													 // Spatial Dimensions
	logic [7:0]		Tox, Toy;			  													 // Output Tiling, Calculated from Tix/Tiy
	logic [10:0]	Nif, Nof;			  													 // channel dimensions & number of kernel groups of size Npar
	logic [10:0]	Ngr, Ngrint;		  													 // Number of groups in each 1*1 convolution (Ngr for expansion and Ngrint for pointwise)
	logic [2:0]		t;						  												    // Expansion factor
	logic 			S;						  													 // Stride
	logic [31:0] 	data;					  													 // Data request from a memory bank or Ram
	logic [31:0] 	x, y, x_mem, y_mem, tx, ty, tx_mem, ty_mem, x_ref, y_ref; // Information needed to construct the right address
	logic [31:0]	f, f_mem; 																 // Information needed to construct the right address
	
	
	// Next value for registers
	logic [7:0]		Nix_n, Niy_n;
	logic [10:0]	Nif_n, Nof_n, Ngr_n, Ngrint_n;
	logic [2:0]		t_n;
	logic 			S_n;
	logic [31:0] 	addr_extmem_n;
	logic [31:0] 	data_n;
	logic [31:0] 	ram_addr_n;
	logic [31:0] 	x_n, y_n, x_mem_n, y_mem_n, tx_n, ty_n, tx_mem_n, ty_mem_n, x_ref_n, y_ref_n;
	logic [31:0]	f_n, f_mem_n;
	logic 			r_request_extmem_n;
	
	// Memory (offset & multiplication)
	logic [31:0] mem_offset [9:0];
	
	/* 
		###################################################################################################################################
		# Sequential logic																																					 #
		###################################################################################################################################
	*/
	always_ff @(posedge clk, posedge rst)
		if(rst) begin // If reset enabled, set to initial values
			state <= IDLE;
			Nix 	<= '0; Niy 		<= '0;
			Nif 	<= '0; Nof 		<= '0; 
			Ngr 	<= '0; Ngrint	<= '0;
			t 		<= '0; S 		<=  0;
			addr_extmem	  <= '0;
			ram_addr		  <= '0;
			data			  <= '0;
			x		 <= '0; y	   <= '0; 
			x_mem	 <= '0; y_mem  <= '0;
			tx		 <= '0; ty	   <= '0;
			tx_mem <= '0; ty_mem	<= '0;
			x_ref <= '0; y_ref	<= '0;
			f <= '0; f_mem <= '0;
			r_request_extmem <= '0;
		end
		else begin // Else, take next values
			state <= state_n;
			Nix 	<= Nix_n; Niy 		<= Niy_n;
			Nif 	<= Nif_n; Nof 		<= Nof_n;
			Ngr 	<= Ngr_n; Ngrint	<= Ngrint_n;
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
			r_request_extmem <= r_request_extmem_n;
		end 
	
	/* 
		###################################################################################################################################
		# Combinational logic																																				 #
		###################################################################################################################################
	*/
	// Convolution information
	assign inf_conv[7:0]   = Nix;
	assign inf_conv[15:8]  = Niy;
	assign inf_conv[26:16] = Nif;
	assign inf_conv[37:27] = Nof;
	assign inf_conv[40:38] = t;
	assign inf_conv[41]    = S;
	
	// DMA finished transfer when in final states
	assign e_op = (state == FINISHED);
	
	// Data to write the RAM
	assign w_data = data;
	
	// Write to RAM (depending on state)
	assign w_fmi = (state == W_FMI);
	assign w_ext = (state == W_FMO);
	assign w_kex = (state == W_KEXP);
	assign w_kpw = (state == W_KPW);
	assign w_kdw = (state == W_KDW);
	
	// Determine the Output dimension
	assign Nox = Nix >> S;
	assign Noy = Niy >> S;
	assign Tox = Tix[7:0] >> S;
	assign Toy = Tiy[7:0] >> S;
	
	// Store constant depending on the layer parameters
	assign mem_offset[5] = Nix * Niy; // The size of one channel of input FM
	assign mem_offset[6] = Ngr * Nnp; // The size of 1*1 exp kernel
	assign mem_offset[7] = Nif * t;   // The number of intermediate channels
	assign mem_offset[8] = Ngrint * Nnp; // The size of pointwise exp kernel
	assign mem_offset[9] = Nox * Noy; // The size of one channel of output FM
	
	always_comb begin
		// If no values has changed
		state_n = state;
		Nix_n   = Nix; Niy_n   = Niy;
		Nif_n   = Nif; Nof_n   = Nof;
		Ngr_n = Ngr; Ngrint_n = Ngrint;
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
		r_request_extmem_n = '0; 
		// FSM
		case(state)
			/* ############################################### */
			// IDLE state
			IDLE: begin
				if(s_op) begin
					case(op)
						0: begin // Store layer information
							state_n 			 = R_INIT;
							r_request_extmem_n = 1;
							addr_extmem_n 	 = '0;			
						end
						
						1: begin // Fill IFM buffer
							state_n 			 = R_FMI;
							r_request_extmem_n = 1;
							ram_addr_n 	 =  '0;
							// Variables
							x_n = 1; y_n = 1; f_n = 1; // to make sure we do exceed the tile
							x_mem_n = x_mem_i; y_mem_n = y_mem_i; f_mem_n = 0; // address of the first element to extract in memory (without offset and channel)
							tx_n = tx_i; ty_n = ty_i; // spatial position of the first pixel, to make sure we do not exceed the dimension of the FM 
							// Reference
							tx_mem_n = tx_i; ty_mem_n = ty_i;
							x_ref_n =  x_mem_i; y_ref_n = y_mem_i;
							// New address
							addr_extmem_n 	 = mem_offset[0] + x_mem_i + y_mem_i;
						end
						
						2: begin // Fill Kexp buffer
							state_n 			 = R_KEXP;
							r_request_extmem_n = 1;
							ram_addr_n 	 =  '0;
							// Variables
							x_n = 1; f_n = 1; 
							tx_n = tx_i; // tx is the first kernel channel to extract
							// New address
							addr_extmem_n 	 = mem_offset[2] + x_mem_i; // x_mem_i contains the adress of the channel represented by tx
						end
						
						3: begin // Fill KPW buffer
							state_n 			 = R_KPW;
							r_request_extmem_n = 1;
							ram_addr_n 	 =  '0;
							// Variables
							x_n = 1; f_n = 1; // we load every weight from 1 to Nof corresponding to that group in the kernel (Nnp weights)
							tx_n = tx_i; // Tx_i represents which group to select,
							x_mem_n = 0 ; f_mem_n = x_mem_i;
							// Reference
							x_ref_n = x_mem_i; tx_mem_n = tx_i;
							// New address
							addr_extmem_n 	 = mem_offset[3] + x_mem_i; // x_mem_i contains the adress of the par channel
						end
						
						4: begin // Fill KDW buffer
							state_n 			 = R_KDW;
							r_request_extmem_n = 1;
							ram_addr_n 	 =  '0;
							// Variables
							x_n = 1; y_n = 1; f_n = 1; tx_n = tx_i; // tx represent the first channel (to tx + Npar) to load the weights
							x_mem_n = '0 ; y_mem_n = '0; f_mem_n = x_mem_i; // X_mem_i the address of the first weight corresponding to channel tx
							// Reference
							x_ref_n = x_mem_i; tx_mem_n = tx_i;
							// New address
							addr_extmem_n 	 = mem_offset[4] + x_mem_i;
						end
						5: begin // Flush FMO buffer
							state_n 			 = RAM_LOADING;
							ram_addr_n 	 =  '0;
							// Variables
							x_n = 1; y_n = 1; f_n = 1;
							x_mem_n = x_mem_i; y_mem_n = y_mem_i; f_mem_n = 0; // address of the first element to write in memory (without offset and channel
							tx_n = tx_i; ty_n = ty_i;  
							// Reference
							tx_mem_n = tx_i; ty_mem_n = ty_i;
							x_ref_n =  x_mem_i; y_ref_n = y_mem_i;
						end
						default: state_n = IDLE;
					endcase
				end
			end
			
			/* ############################################### */
			// FMI states
			
			R_FMI: begin
				if(r_valid_extmem) begin
						data_n = data_extmem;
						state_n = W_FMI;
				end
			end
			
			W_FMI: begin
				// Update address
				ram_addr_n = ram_addr + 32'b1;
				// Changing the state
				if (x == Tix || tx == Nix) begin // We change row
					x_n = 1; x_mem_n = x_ref; tx_n = tx_mem;
					if(y == Tiy || ty == Niy) begin // We change channel
						y_n = 1; y_mem_n = y_ref; ty_n = ty_mem;
						if (f == Nif) begin // If transaction is over
							state_n 			 = FINISHED;
						end
						else begin
							state_n = A_FMI;
							f_n = f + 1; f_mem_n  = f_mem + mem_offset[5];
						end
					end
					else begin
						state_n = A_FMI;
						y_n = y + 1; y_mem_n = y_mem + Nix; ty_n = ty + 1;
					end
				end
				else begin
					state_n = A_FMI;
					x_mem_n = x_mem + 1;
					x_n = x + 1;
					tx_n = tx + 1;
				end
			end
			
			A_FMI: begin
				addr_extmem_n = mem_offset[0] + f_mem + x_mem + y_mem;
				state_n = R_FMI;
				r_request_extmem_n = 1;
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
				ram_addr_n = ram_addr + 32'b1;
				addr_extmem_n = addr_extmem + 1;
				// Changing the state
				if (f == mem_offset[6]) begin  // We change weight after fully loaded them
					f_n = 1; f_mem_n = '0;
					if(x == Npar || tx == mem_offset[7]) begin // We have loaded Npar weights
							state_n = FINISHED;
					end
					else begin
						state_n = R_KEXP;
						r_request_extmem_n = 1;
						tx_n = tx + 1;
						x_n = x + 1;
					end
				end
				else begin
					state_n = R_KEXP;
					r_request_extmem_n = 1;
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
				ram_addr_n = ram_addr + 32'b1;
				if(f == Nnp || tx == mem_offset[8]) begin // We change weights after loaded Nnp weights (one group)
					f_n = 1; f_mem_n = x_ref; tx_n = tx_mem;
				   if (x == Nof) begin // We finish after we load the same group in every kernel.
						state_n = FINISHED;
					end
					else begin
						state_n = A_KPW; x_n = x + 1; x_mem_n = x_mem + mem_offset[8];
					end
				end
				else begin
					state_n = A_KPW;
					f_n = f + 1;
					f_mem_n = f_mem + 1;
					tx_n = tx + 1;
				end
			end
			A_KPW: begin
				addr_extmem_n 	 = mem_offset[3] + x_mem + f_mem;
				state_n = R_KPW;
				r_request_extmem_n = 1;
			end
			/* ############################################### */
			// KDW States
			R_KDW: begin
				if(r_valid_extmem) begin
						state_n = W_KDW;
						data_n = data_extmem;
				end
			end
			
			W_KDW: begin
				// Update address
				ram_addr_n = ram_addr + 32'b1;
				// Changing the state
				if (x == Nkx) begin // We change the row 
					x_n = 1; x_mem_n = '0;
					if(y == Nky) begin // We change the kernel
						y_n = 1; y_mem_n = '0;
						if (f == Npar || tx == mem_offset[7]) begin // transaction finished after loading Npar weights
							state_n 			 = FINISHED;
						end
						else begin
							state_n = A_KDW;
							f_n = f + 1; tx_n = tx + 1; f_mem_n  = f_mem + KDWSize; // 2 weights on each address of the 
						end
					end
					else begin
						state_n = A_KDW;
						y_n = y + 1; y_mem_n = y_mem + Nkx;
					end
				end
				else begin
					state_n = A_KDW;
					x_mem_n = x_mem + 1;
					x_n = x + 1;
				end
			end
			A_KDW: begin
				addr_extmem_n 	 = mem_offset[4] + x_mem + y_mem + f_mem;
				state_n = R_KDW;
				r_request_extmem_n = 1;
			end
			
			/* ############################################### */
			// FMO States
			RAM_LOADING: begin
				state_n = R_FMO;
			end
			
			R_FMO: begin
				addr_extmem_n = mem_offset[1] + f_mem + x_mem + y_mem;
				state_n = W_FMO;
				data_n = ram_data_i; 
				ram_addr_n = ram_addr + 32'b1;
			end
			
			W_FMO: begin
				// Changing the state
				state_n = R_FMO;
				// Update next address
				if (x == Tox || tx == Nox) begin 
					x_n = 1; x_mem_n = x_ref; tx_n = tx_mem;
					if(y == Toy || ty == Niy) begin
						y_n = 1; y_mem_n = y_ref; ty_n = ty_mem;
						if (f == Nof) begin
							state_n 			 = FINISHED;
						end
						else begin
							f_n = f + 1; f_mem_n  = f_mem + mem_offset[9];
							state_n = R_FMO;
						end
					end
					else begin
						y_n = y + 1; y_mem_n = y_mem + Nox; ty_n = ty + 1;
						state_n = R_FMO;
					end
				end
				else begin
					state_n = R_FMO;
					x_mem_n = x_mem + 1;
					x_n = x + 1;
					tx_n = tx + 1;
				end
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
					r_request_extmem_n = 1;
					addr_extmem_n = addr_extmem + 1;
				end
				// Handling the signals
				case (addr_extmem[2:0])
					0: begin
						Nix_n   = data[7:0]; 
						Niy_n   = data[15:8];
						t_n 	  = data[18:16]; 	 
						S_n 	  = data[19];
					end
					1:begin
						Nif_n   = data[10:0]; 
						Nof_n   = data[22:12];
					end
					2: begin
						Ngr_n	  = data[10:0];
						Ngrint_n	  = data[22:12];
					end
					3:begin // IFM
						mem_offset[0] = data;
					end
					4:begin // OFM
						mem_offset[1] = data;
					end
					5:begin // KEXP
						mem_offset[2] = data;
					end
					6:begin; // KPW
						mem_offset[3] = data;
					end
					7:begin // KDW
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
