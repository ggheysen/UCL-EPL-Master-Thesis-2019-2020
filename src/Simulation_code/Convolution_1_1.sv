/* 
	Description : Component convolution_1_1 which perform the 1*1 convolution needed for inverted residual block and 1*1 convolution layer
	Author : 	  Guillaume Gheysen
*/ 

/* 
	###################################################################################################################################
	# import 																																								 #
   ###################################################################################################################################
*/
import irb_pkg::*;

/* 
	###################################################################################################################################
	# module definition 																																					 #
   ###################################################################################################################################
*/
module Convolution_1_1(input logic clk, rst, start,								// clock, reset and start the module signals
							  input logic signed [PX_W - 1:0] fmi_data,				//	Data sent from the FMI buffer
							  input logic signed [WG_W -1:0] kex_data,				//	Data sent from the KEX buffer (the weight)
							  input logic [$clog2(Npar) - 1:0] kex_pos,				// Data sent from the FMI buffer (the position of the weight)
							  input logic [10:0] Nif,										//	Number of input channels
							  input logic [$clog2(KEX_N_ELEM)-1:0]	Size_KEX,		// Size of one expasion kernel (number of element)
							  output logic [$clog2(FMI_N_ELEM)-1:0] fmi_addr,		// Address of the fmi buffer to read the pixels
							  output logic [$clog2(KEX_N_ELEM)-1:0] kex_addr,		// Address of the fmi buffer to read the weights
							  output logic [$clog2(FMINT_N_ELEM)-1:0] fmint_addr,	// Address of the fmint buffer to write resutls
							  output logic finish, write,									// Finish enabled when the module has finished its computation and write enabled if intermediate results can be written to main memory
							  output logic signed [PX_W - 1:0] res						// output pixel to be written to fmint buffer
							 );
	
	/* 
		###################################################################################################################################
		# internal signals																																					 #
		###################################################################################################################################
	*/
	// States
	typedef enum logic [2:0] {IDLE,             
									  FINISHED,					// State telling the DMA has finished its transaction
									  LOAD_DATA,
									  FINISHED_LOAD,
									  COMPUTATION,
									  WRITE
									  } statetype;
	statetype state, state_n; // Variables containing the state
	
	// Registers
	logic signed [PX_W - 1:0]  px  [Npar-1 : 0]; 					// Registers containing the value of the pixels needed for computation
	logic signed [WG_W - 1:0]  wg  [Nnp-1 : 0];						// Registers containing the value of the weights needed for computation
	logic [$clog2(Npar) - 1:0] pos [Nnp-1 : 0];						// Registers containing the value of the position needed for computation
	logic [7:0] x_fmi, y_fmi;												// Position of the pixels where the convolution happen
	logic [10:0] f_fmi, f_fmint, tf_fmi;								// input and intermediate channel
	logic [10:0] np_kex;														// position of the weight in the kernel
	logic [$clog2(FMI_N_ELEM)-1:0] x_addr, y_addr, f_fmi_addr;	// address of the FMI pixels
	logic [$clog2(FMI_N_ELEM)-1:0] f_fmint_addr;						// address of the FMINT pixels (same x and y than FMI)
	logic [$clog2(KEX_N_ELEM)-1:0] f_kex_mem, x_kex_mem;			// RAM address of the 1*1 expansion kernel
	logic load_px, load_wg;													// when enabled, we fill the corresponding shift registers
	logic signed [PX_W - 1:0] sum;										// Intermediate sum
	
	// Next value for registers 						
	logic [7:0] x_fmi_n, y_fmi_n;
	logic [10:0] f_fmi_n, f_fmint_n, tf_fmi_n;
	logic [10:0] np_kex_n;
	logic [$clog2(FMI_N_ELEM)-1:0] x_addr_n, y_addr_n, f_fmi_addr_n; 
	logic [$clog2(FMINT_N_ELEM)-1:0] f_fmint_addr_n;					
	logic [$clog2(KEX_N_ELEM)-1:0] f_kex_mem_n, x_kex_mem_n;
	logic load_px_n, load_wg_n;
	logic signed [PX_W - 1:0] sum_n; 
	 
	/* 
		###################################################################################################################################
		# Modules instatiation																																					 #
		###################################################################################################################################
	*/
	SHIFT_REGISTER_PX reg_px(.clk(clk), .load(load_px), .data(fmi_data), .pixels(px));
	SHIFT_REGISTER_WG reg_wg(.clk(clk), .load(load_wg), .data(kex_data), .weights(wg));
	SHIFT_REGISTER_POS reg_pos(.clk(clk), .load(load_wg), .data(kex_pos), .pos(pos));
	
	RELU6 activation(.in(sum), .out(res));
	
	/* 
		###################################################################################################################################
		# Sequential logic																																					 #
		###################################################################################################################################
	*/
	always_ff @(posedge clk, posedge rst) begin
		if(rst) begin
			state <= IDLE;
			x_fmi <= '0; y_fmi <= '0;
			f_fmi <= '0; f_fmint <= '0; tf_fmi <= '0;
			np_kex <= '0; f_kex_mem <= '0;
			load_px <= '0; load_wg <= '0;
			sum <= '0;
			x_addr<= '0; y_addr <= '0; f_fmi_addr <= '0;
			f_fmint_addr <= '0;
			x_kex_mem <= '0;
		end
		else begin
			state <= state_n;
			x_fmi <= x_fmi_n; y_fmi <= y_fmi_n;
			f_fmi <= f_fmi_n; f_fmint <= f_fmint_n; tf_fmi <= tf_fmi_n;
			np_kex <= np_kex_n;
			f_kex_mem <= f_kex_mem_n;
			load_px <= load_px_n; 
			load_wg <= load_wg_n;
			sum <= sum_n;
			x_addr<= x_addr_n; y_addr <= y_addr_n; f_fmi_addr <= f_fmi_addr_n;
			f_fmint_addr <= f_fmint_addr_n;
			x_kex_mem <= x_kex_mem_n;
		end
	end
	
	/* 
		###################################################################################################################################
		# Combinational logic																																				 #
		###################################################################################################################################
	*/
	// Control bits
	assign finish = state == FINISHED;
	assign write = state == WRITE;
	
	//Addresses
	assign fmi_addr = x_addr + y_addr + f_fmi_addr;
	assign fmint_addr = x_addr + y_addr + f_fmint_addr;
	assign kex_addr = f_kex_mem + x_kex_mem;
	
	always_comb begin
		state_n = state;
		x_fmi_n = x_fmi; y_fmi_n = y_fmi;
		f_fmi_n = f_fmi; f_fmint_n = f_fmint; tf_fmi_n = tf_fmi;
		np_kex_n = np_kex;
		f_kex_mem_n = f_kex_mem;
		load_px_n = '0; load_wg_n = '0;
		sum_n = sum;
		x_addr_n = x_addr; y_addr_n = y_addr; f_fmi_addr_n = f_fmi_addr;
		f_fmint_addr_n = f_fmint_addr;
		f_kex_mem_n = f_kex_mem; x_kex_mem_n = x_kex_mem;
		case(state)
		
			// IDLE state - when no computation is occuring
			IDLE: begin
				if(start) begin
					// Change State
					state_n = LOAD_DATA;
					// Loop Variables
					x_fmi_n = 1; y_fmi_n = 1; f_fmint_n = 1; // Output pixels variables & address
					f_fmi_n = 1; tf_fmi_n = 1; // FMI channel loop variables
					np_kex_n = 1; // weight in a kernel
					// RAM variables 
					x_addr_n = '0; y_addr_n = '0; f_fmi_addr_n = '0;
					f_fmint_addr_n = '0;
					f_kex_mem_n = '0; x_kex_mem_n = '0;
					// Internal sum
					sum_n = '0;
				end
			end
			
			// FINISHED state - when the component has finished its computation and waiting for operation
		   FINISHED: begin
				state_n = IDLE;
			end
			
			// Load the data necessary for the computation
		   LOAD_DATA: begin
				// Load the input pixels
				if (tf_fmi == Npar|| f_fmi == Nif ) begin
					// Change state
					state_n = COMPUTATION;
				end
				else if (tf_fmi == Npar - 1|| f_fmi == Nif - 1 ) begin
					// enabled load
					load_px_n = '1;
					// Loop variables (no need to change the address here)
					f_fmi_n = f_fmi + 11'b1; tf_fmi_n = tf_fmi + 11'b1;
				end
				else begin
					// enabled load (state don't change)
					load_px_n = 'b1;
					// Loop variables
					f_fmi_n = f_fmi + load_px; tf_fmi_n = tf_fmi + load_px;
					// Update address
					f_fmi_addr_n = f_fmi_addr + Size_FMI_T[$clog2(FMI_N_ELEM)-1:0];
				end
				
				// Load the corresponding weights
				if (np_kex == Nnp) begin
					if(np_kex == 1) begin
						load_wg_n = 1;
					end
				end
				else if (np_kex == Nnp - 1) begin
					// enabled load
					load_wg_n = '1; 
					// Loop variables
					np_kex_n = np_kex + load_wg;
					// Update address
					x_kex_mem_n = x_kex_mem + {{$clog2(KEX_N_ELEM) - 1{1'b0}}, ~load_wg}; 
				end
				else begin
					// enabled load
					load_wg_n = '1;
					// Loop variables
					np_kex_n = np_kex + load_wg;
					// Update address
					x_kex_mem_n = x_kex_mem + {{$clog2(KEX_N_ELEM) - 1{1'b0}}, 1'b1};
				end
			end
			
			// We perform the convolution
		   COMPUTATION: begin
			
				for(int i = 0; i < Nnp ; i=i+1) begin
					// Intermediate values
					logic signed [PX_W - 1 : 0] cur_val;
					logic signed [WG_W - 1 : 0] cur_wg;
					logic signed [$clog2(Npar):0] cur_pos;
					logic signed [(2*PX_W) - 1 : 0] int_res;
					logic signed [PX_W - 1 : 0] trunc_res;
					logic signed [PX_W - 1 : 0] round_res;
					// Computation
					cur_pos[$clog2(Npar)-1:0] = pos[i][$clog2(Npar) -1 :0];
					cur_val = px[cur_pos[$clog2(Npar)-1:0]][PX_W - 1 : 0];
					cur_wg = wg[i][WG_W - 1:0];
					int_res = cur_val * cur_wg;
					trunc_res = int_res[(2*PX_W) - 4 - 1: PX_W - 4];
					round_res = int_res[(2*PX_W) - 4 - 1];
					sum_n = sum_n + trunc_res + round_res; 
				end
				
				if(f_fmi == Nif) begin
					// We have finish the convolution, we can write the result
					state_n = WRITE;
				end
				else begin
					// Otherwise we have to do another group (Npar channel)
					// Change state
					state_n = LOAD_DATA;
					// Loop variables
					f_fmi_n = f_fmi + 11'b1; tf_fmi_n = 1;
					np_kex_n = 1;	
					// Update address
					f_fmi_addr_n = f_fmi_addr + Size_FMI_T[$clog2(FMI_N_ELEM)-1:0]; // We change the Par (next channel)
					x_kex_mem_n = x_kex_mem + '1; // We change the group (next weight)
				end
			end
			
			// Write the result into 
		   WRITE: begin
				// Initialise variables for next convolution
				sum_n = '0;
				f_fmi_n = 1;
				tf_fmi_n = 1;
				f_fmi_addr_n = '0;
				x_kex_mem_n = '0;
				np_kex_n = 1;
				
				// Update loop & RAM variables
				if (x_fmi == Tix_T) begin // Change column
					x_fmi_n = 1; x_addr_n = '0;
					if (y_fmi == Tiy_T) begin // Change row
						y_fmi_n = 1; y_addr_n = '0;
						if (f_fmint == Npar) begin // Change output channel
							state_n = FINISHED;
						end
						else begin // Kernel change
							// Change state
							state_n = LOAD_DATA;
							// Update Loop variables
							f_fmint_n = f_fmint + 11'b1;
							// Update Memory variables
							f_kex_mem_n = f_kex_mem + Size_KEX;
							f_fmint_addr_n = f_fmint_addr + Size_FMI_T[$clog2(FMI_N_ELEM)-1:0];
						end
					end
					else begin // Spatial change
						// Change state
						state_n = LOAD_DATA;
						// Update Loop variables
						y_fmi_n = y_fmi + 8'b1;
						// Update Memory variables
						y_addr_n = y_addr + Tix_T[$clog2(FMI_N_ELEM)-1:0];
					end
				end
				else begin // Spatial change
					// Change state
					state_n = LOAD_DATA;
					// Update Loop variables
					x_fmi_n = x_fmi + 8'b1;
					// Update Memory variables
					x_addr_n = x_addr + {{$clog2(FMI_N_ELEM)-1 {1'b0}}, 1'b1};
				end
			end
		endcase
	end
endmodule
/* 
	###################################################################################################################################
	# Additional modules																																				 #
	###################################################################################################################################
*/
module SHIFT_REGISTER_PX(
								 input logic clk, load,
								 input logic signed[PX_W - 1:0] data,
								 output logic signed [PX_W - 1:0] pixels [Npar-1 : 0]
								);
	always_ff @(posedge clk) begin
		if (load) begin
		pixels [Npar-1] <= data;
		for (int i=0 ; i < Npar -1; i=i+1) begin
			pixels[i] <= pixels[i+1];
		end
		end
	end
endmodule

module SHIFT_REGISTER_WG(
								 input logic clk, load,
								 input logic signed [WG_W  - 1:0] data,
								 output logic signed [WG_W  - 1:0] weights [Nnp-1 : 0]
								);
	always_ff @(posedge clk) begin
		if (load) begin
		weights [Nnp-1] <= data;
		for (int i=0 ; i < Nnp-1; i=i+1) begin
			weights[i] <= weights[i+1];
		end
		end
	end
endmodule

module SHIFT_REGISTER_POS(
								 input logic clk, load,
								 input logic [$clog2(Npar) - 1:0] data,
								 output logic [$clog2(Npar) - 1:0] pos [Nnp-1 : 0]
								);
	always_ff @(posedge clk) begin
		if (load) begin
			pos [Nnp-1] <= data;
				for (int i=0 ; i < Nnp-1; i=i+1) begin
					pos[i] <= pos[i+1];
				end
			end
	end
endmodule

module RELU6(
				 input logic signed [PX_W - 1:0] in,
				 output logic signed [PX_W - 1:0] out);
	logic [PX_W -1 : 0] val = (4'b0110) << (PX_W - 4 - 1);
	assign out = in[PX_W - 1] ? '0 : ( (in[PX_W - 1:PX_W - 4 -1] == 4'b0110) ? val : in);
endmodule
