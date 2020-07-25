/* 
	Description : Component convolution_1_1 which perform the 1*1 convolution needed for inverted residual block and 1*1 convolution layer
	Author : 	  Guillaume Gheysen
*/ 

/* 
	###################################################################################################################################
	# import 																																								 #
   ###################################################################################################################################
*/
import dma_pkg::*;

/* 
	###################################################################################################################################
	# module definition 																																					 #
   ###################################################################################################################################
*/
module Main_controller(input logic clk, rst, start,
							  input logic f_dma, f_c11,
							  input logic [41:0] inf_conv,
							  output logic s_dma, s_c11,
							  output logic finish,
							  output logic [2:0] dma_op,
							  output logic [31:0] dma_info1, dma_mem_info1, dma_info2, dma_mem_info2
							 );
	
	/* 
		###################################################################################################################################
		# internal signals																																					 #
		###################################################################################################################################
	*/
	// States
	typedef enum logic [3:0] {IDLE,             
									  FINISH,
									  LOAD_INF,
									  LOAD_FMI,
									  LOAD_KEX,
									  CONV_11,
									  WRITE_FMINT,
									  ADDRESS
									  } statetype;
	statetype state, state_n; // Variables containing the state
	
	// Registers
	logic [31:0] Size_Ti, Size_To, Size_par_kex;
	logic [7:0] tix, tiy, tox, toy, Tox, Toy, Nintf;
	logic [10:0] par;
	logic [31:0] ix_mem, iy_mem, ox_mem, oy_mem;
	logic [31:0] par_mem;
	// Next value for registers
	logic s_dma_n, s_c11_n;
	logic [7:0] tix_n, tiy_n, tox_n, toy_n;
	logic [10:0] par_n;
	logic [31:0] ix_mem_n, iy_mem_n, ox_mem_n, oy_mem_n;
	logic [2:0] op_n;
	logic [31:0] par_mem_n, dma_info1_n, dma_info2_n, dma_mem_info1_n, dma_mem_info2_n;
	// Intermediate values
	logic [10:0] Nintf_inter;
	/* 
		###################################################################################################################################
		# Sequential logic																																					 #
		###################################################################################################################################
	*/
	always_ff @(posedge clk, posedge rst) begin
		if(rst) begin
			state  <= IDLE;
			s_dma  <= '0  ; s_c11  <= '0;
			tix	 <= '0  ; tiy    <= '0;
			tox	 <= '0  ; toy    <= '0;
			ix_mem <= '0  ; iy_mem <= '0;
			ox_mem <= '0  ; oy_mem <= '0;
			dma_op <= '0  ; par_mem <= '0;
			dma_info1 <= '0; dma_info2 <= '0;
			dma_mem_info1 <= '0; dma_mem_info2 <= '0;
			par <= '0;
		end
		else begin
			state  <= state_n  ;
			s_dma  <= s_dma_n  ; s_c11  <= s_c11_n;
			tix	 <= tix_n    ; tiy    <= tiy_n;
			tox	 <= tox_n    ; toy    <= toy_n;
			ix_mem <= ix_mem_n ; iy_mem <= iy_mem_n;
			ox_mem <= ox_mem_n ; oy_mem <= oy_mem_n;
			dma_op <= op_n     ; par_mem <= par_mem_n;
			dma_info1 <= dma_info1_n; dma_info2 <= dma_info2_n;
			dma_mem_info1 <= dma_mem_info1_n; dma_mem_info2 <= dma_mem_info2_n;
			par <= par_n;
		end
	end
	
	/* 
		###################################################################################################################################
		# Combinational logic																																				 #
		###################################################################################################################################
	*/
	
	assign finish = state == FINISH;
	assign Size_Ti = inf_conv[26:16] * Tiy;
	assign Size_To = inf_conv[37:27] * Toy;
	assign Size_par_kex = inf_conv[26:16] * Nnp;
	// Nintf
	assign Nintf_inter = inf_conv[40:38] * inf_conv[26:16];
	assign Nintf = Nintf_inter[7:0];
	// Tox
	assign Tox = Tix[7:0] >> inf_conv[41];
	// Toy
	assign Toy = Tiy[7:0] >> inf_conv[41];
	
	//FSM
	always_comb begin
		state_n = state;
		s_dma_n = '0                   ; s_c11_n = '0;
		tix_n    = tix                 ; tiy_n    = tiy;
		ix_mem_n = ix_mem              ; iy_mem_n = iy_mem;
		op_n = '0                      ; par_mem_n = par_mem;
		dma_info1_n = dma_info1        ; dma_info2_n = dma_info2;
		dma_mem_info1_n = dma_mem_info1; dma_mem_info2_n = dma_mem_info2;
		tox_n = tox; toy_n = toy; ox_mem_n = ox_mem; oy_mem_n = oy_mem;
		par_n = par; 
		case (state)
			IDLE: begin
				if(start) begin
					// Next state & start module
					state_n = LOAD_INF;
					s_dma_n = 1;
					op_n = '0;
				end
			end
			
			FINISH: begin
				state_n = IDLE;
			end
			
			LOAD_INF: begin
				if (f_dma) begin
					// Next state & start module
					state_n = LOAD_FMI;
					s_dma_n = 1;
					// Assign variables
					dma_info1_n = tix + 1;
					dma_info2_n = tiy + 1;
					dma_mem_info1_n = ix_mem;
					dma_mem_info2_n = iy_mem;
					// Update variables
					tix_n = tix + Tix[7:0];
					ix_mem_n = ix_mem + Tix;
					// Assign op
					op_n = 1;
				end
			end
			
			LOAD_FMI: begin
				if (f_dma) begin
					state_n = LOAD_KEX;
					s_dma_n = 1;
					op_n = 2;
					// Assign varialbes
					dma_info1_n = par + 1;
					dma_mem_info1_n = par_mem;
					// Assign variables
					par_n = par + Npar[10:0];
					par_mem_n = par_mem + Size_par_kex;
				end
			end
			
			LOAD_KEX: begin
				if (f_dma) begin
					state_n = CONV_11;
					s_c11_n = 1;
				end
			end
			
			CONV_11: begin
				if (f_c11) begin
					state_n = WRITE_FMINT;
					s_dma_n = 1;
					// Assign variables
					dma_info1_n = tox + 1;
					dma_info2_n = toy + 1;
					dma_mem_info1_n = ox_mem;
					dma_mem_info2_n = oy_mem;
					op_n = 5;
				end
			end
			
			WRITE_FMINT: begin
				if (f_dma) begin
					state_n = ADDRESS;
				end
			end
			
			ADDRESS: begin
				if (tix >= inf_conv[7:0]) begin
					// Update Fmi variables
					tix_n = '0;
					tox_n = '0;
					tiy_n = tiy_n + Tiy[7:0];
					toy_n = toy_n + Toy;
					ix_mem_n = '0;
					iy_mem_n = iy_mem_n + Size_Ti;
					oy_mem_n = oy_mem_n + Size_To;
					state_n = ADDRESS;
				end
				else if (tiy >= inf_conv[15:8]) begin
					state_n = FINISH;
				end
				else if (par >= Nintf) begin
					state_n = LOAD_FMI;
					s_dma_n = 1;
					// Assign variables
					dma_info1_n = tix + 1;
					dma_info2_n = tiy + 1;
					dma_mem_info1_n = ix_mem;
					dma_mem_info2_n = iy_mem;
					// Update variables
					tix_n = tix + Tix[7:0];
					ix_mem_n = ix_mem + Tix;
					tox_n = tox + Tox;
					ox_mem_n = ox_mem + Tox;
					par_n = '0;
					par_mem_n = '0;
				end
				else begin
					state_n = LOAD_KEX;
					s_dma_n = 1;
					op_n = 2;
					// Assign varialbes
					dma_info1_n = par + 1;
					dma_mem_info1_n = par_mem;
					// Assign variables
					par_n = par + Npar[10:0];
					par_mem_n = par_mem + Size_par_kex;
				end
			end
			
		endcase
	end
endmodule
