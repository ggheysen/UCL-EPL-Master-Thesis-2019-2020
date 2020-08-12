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
module Main_controller(input logic clk, rst, start,
							  input logic f_dma, f_c11, f_dsc,
							  input logic [63:0] inf_conv,
							  output logic s_dma, s_c11, s_dsc,
							  output logic finish,
							  output logic [2:0] dma_op,
							  output logic [31:0] dma_info1, dma_mem_info1, dma_info2, dma_mem_info2,
							  output logic 		first_par,
							  output logic [63:0] measure_cnt_dma, measure_cnt_c11, measure_cnt_dsc 
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
									  LOAD_KPW,
									  LOAD_KDW,
									  CONV_DSC,
									  WRITE_FMO
									  } statetype;
	statetype state, state_n; // Variables containing the state
	
	// Registers
	logic [31:0] Size_Ti, Size_To, Size_par_kex;
	logic [7:0] tix, tiy, tox, toy, Tox, Toy, Nintf, NTix, NTiy, Nox, Noy;
	logic [10:0] par;
	logic [31:0] ix_mem, iy_mem, ox_mem, oy_mem;
	logic [31:0] par_mem, grint_mem, par_dw_mem;
	logic [31:0] grint;
	
	
	// Next value for registers
	logic [31:0] Size_Ti_n, Size_To_n, Size_par_kex_n;
	logic [7:0] Nintf_n, NTix_n, NTiy_n, Nox_n, Noy_n, Tox_n, Toy_n;
	logic s_dma_n, s_c11_n, s_dsc_n;
	logic [7:0] tix_n, tiy_n, tox_n, toy_n;
	logic [10:0] par_n;
	logic [31:0] ix_mem_n, iy_mem_n, ox_mem_n, oy_mem_n;
	logic [2:0] op_n;
	logic [31:0] par_mem_n, dma_info1_n, dma_info2_n, dma_mem_info1_n, dma_mem_info2_n;
	logic [31:0] grint_mem_n, par_dw_mem_n;
	logic [31:0] grint_n;
	logic first_par_n;
	logic [63:0] measure_cnt_dma_n, measure_cnt_c11_n, measure_cnt_dsc_n;
	
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
			s_dma  <= '0  ; s_c11  <= '0; s_dsc <= '0;
			tix	 <= '0  ; tiy    <= '0;
			tox	 <= '0  ; toy    <= '0;
			ix_mem <= '0  ; iy_mem <= '0;
			ox_mem <= '0  ; oy_mem <= '0;
			dma_op <= '0  ; par_mem <= '0;
			dma_info1 <= '0; dma_info2 <= '0;
			dma_mem_info1 <= '0; dma_mem_info2 <= '0;
			par <= '0;
			par_dw_mem <= '0;
			grint <= '0; grint_mem <= '0;
			first_par <= '0;
			Nintf <= '0; NTix <= '0; 
			NTiy <= '0; Nox <= '0; 
			Noy <= '0;
			Tox <= '0; Toy <= '0;
			Size_Ti <= '0; Size_To <= '0; Size_par_kex <= '0;
			measure_cnt_dma <= '0; 
			measure_cnt_c11 <= '0; 
			measure_cnt_dsc <= '0;		
		end
		else begin
			state  <= state_n  ;
			s_dma  <= s_dma_n  ; s_c11  <= s_c11_n; s_dsc <= s_dsc_n;
			tix	 <= tix_n    ; tiy    <= tiy_n;
			tox	 <= tox_n    ; toy    <= toy_n;
			ix_mem <= ix_mem_n ; iy_mem <= iy_mem_n;
			ox_mem <= ox_mem_n ; oy_mem <= oy_mem_n;
			dma_op <= op_n     ; par_mem <= par_mem_n;
			dma_info1 <= dma_info1_n; dma_info2 <= dma_info2_n;
			dma_mem_info1 <= dma_mem_info1_n; dma_mem_info2 <= dma_mem_info2_n;
			par <= par_n;
			par_dw_mem <= par_dw_mem_n;
			grint <= grint_n; grint_mem <= grint_mem_n;
			first_par <= first_par_n;
			Nintf <= Nintf_n; NTix <= NTix_n; 
			NTiy <= NTiy_n; Nox <= Nox_n; 
			Noy <= Noy_n;
			Tox <= Tox_n; Toy <= Toy_n;
			Size_Ti <= Size_Ti_n; Size_To <= Size_To_n; Size_par_kex <= Size_par_kex_n;
			measure_cnt_dma <= measure_cnt_dma_n; 
			measure_cnt_c11 <= measure_cnt_c11_n; 
			measure_cnt_dsc <= measure_cnt_dsc_n;
		end
	end
	
	/* 
		###################################################################################################################################
		# Combinational logic																																				 #
		###################################################################################################################################
	*/
	
	assign finish = (state == FINISH);
	//Nox & Noy
	assign Nox_n = (inf_conv[7:0] >> inf_conv[41]); assign Noy_n = (inf_conv[15:8] >> inf_conv[41]);
	// Nintf
	assign Nintf_inter = inf_conv[40:38] * inf_conv[26:16];
	assign Nintf_n = Nintf_inter[7:0];
	//
	assign NTix_n = (Tix_T[7:0] - Nkx[7:0]);
	//
	assign NTiy_n = (Tiy_T[7:0] - Nky[7:0]);
	// Tox
	assign Tox_n = (NTix + 8'b1) >> inf_conv[41];
	// Toy
	assign Toy_n = (NTiy + 8'b1) >> inf_conv[41];
	// Size
	assign Size_Ti_n = inf_conv[7:0] * NTiy;
	assign Size_To_n = (inf_conv[7:0] >> inf_conv[41]) * Toy ;
	assign Size_par_kex_n = inf_conv[26:16] * Nnp;
	
	//FSM
	always_comb begin
		state_n = state;
		s_dma_n = '0                   ; s_c11_n = '0; s_dsc_n = '0;
		tix_n    = tix                 ; tiy_n    = tiy;
		ix_mem_n = ix_mem              ; iy_mem_n = iy_mem;
		op_n = '0                      ; 
		dma_info1_n = dma_info1        ; dma_info2_n = dma_info2;
		dma_mem_info1_n = dma_mem_info1; dma_mem_info2_n = dma_mem_info2;
		tox_n = tox; toy_n = toy; ox_mem_n = ox_mem; oy_mem_n = oy_mem;
		par_n = par; par_mem_n = par_mem;
		par_dw_mem_n = par_dw_mem;
		grint_n = grint; grint_mem_n = grint_mem; 
		first_par_n = '0;
		measure_cnt_dma_n = measure_cnt_dma; 
		measure_cnt_c11_n = measure_cnt_c11; 
		measure_cnt_dsc_n = measure_cnt_dsc;
		case (state)
			IDLE: begin
				if(start) begin
					// Next state & start module
					state_n = LOAD_INF;
					s_dma_n = 1;
					op_n = '0;
					// Loop variables initialization
					tix_n = '0; tiy_n = '0;
					tox_n = '0; toy_n = '0;
					par_n = '0; grint_n = '0;
					// Memory variables initialization
					ix_mem_n = '0; iy_mem_n = '0;
					ox_mem_n = '0; oy_mem_n = '0;
					par_mem_n = '0; par_dw_mem_n = '0;
					grint_mem_n = '0;
				end
			end
			
			FINISH: begin
				state_n = IDLE;
			end
			
			LOAD_INF: begin
				measure_cnt_dma_n = measure_cnt_dma + 1;
				if (f_dma) begin
					// Next state & start module
					state_n = LOAD_FMI;
					s_dma_n = 1;
					// Assign variables
					dma_info1_n = tix;
					dma_info2_n = tiy ;
					dma_mem_info1_n = ix_mem;
					dma_mem_info2_n = iy_mem;
					// Update variables
					tix_n = tix + NTix + 8'b1;
					ix_mem_n = ix_mem + NTix;
					// Assign op
					op_n = 1;
				end
			end
			
			LOAD_FMI: begin
				measure_cnt_dma_n = measure_cnt_dma + 1;
				if (f_dma) begin
					state_n = LOAD_KEX;
					s_dma_n = 1;
					op_n = 2;
					// Assign varialbes
					dma_info1_n = par + 1;
					dma_mem_info1_n = par_mem;
					// Update variables
					par_mem_n = par_mem + Size_par_kex; //Par updated after DSC
				end
			end
			
			LOAD_KEX: begin
//				measure_cnt_dma_n = measure_cnt_dma + 1;
				if (f_dma) begin
					state_n = CONV_11;
					s_c11_n = 1;
				end
			end
			
			CONV_11: begin
				measure_cnt_c11_n = measure_cnt_c11 + 1;
				if (f_c11) begin
					state_n = LOAD_KPW;
					s_dma_n = 1;
					op_n = 3;
					// Assign Loop Variables
					dma_info1_n = grint + 1;
					// Assign Memory variables
					dma_mem_info1_n = grint_mem;
					// Update the variables
					grint_n = grint + Nnp;
					grint_mem_n = grint_mem + Nnp;
				end
			end
			
			LOAD_KPW: begin
				measure_cnt_dma_n = measure_cnt_dma + 1;
				if (f_dma) begin
					state_n = LOAD_KDW;
					s_dma_n = 1;
					op_n = 4;
					// Assign varialbes
					dma_info1_n = par + 1;
					dma_mem_info1_n = par_dw_mem;
				end
			end
			
			LOAD_KDW: begin
				measure_cnt_dma_n = measure_cnt_dma + 1;
				if (f_dma) begin
					state_n = CONV_DSC;
					s_dsc_n = 1;
					// Update Variable
					par_n = par + Npar[10:0];
					par_dw_mem_n = par_dw_mem + SIZE_PAR_DW;
					first_par_n = (par == '0);
				end
			end
			
			CONV_DSC: begin
				measure_cnt_dsc_n = measure_cnt_dsc + 1;
				if (f_dsc) begin
					if (par == Nintf) begin
						state_n = WRITE_FMO;
						s_dma_n = 1;
						op_n = 5;
						// Assign Variables
						dma_info1_n = tox + 1;
						dma_info2_n = toy + 1;
					   dma_mem_info1_n = ox_mem;
						dma_mem_info2_n = oy_mem;
						// Update Variable
						par_n = '0;
						grint_mem_n = '0;
						grint_n = '0;
						par_mem_n = '0;
						par_dw_mem_n = '0;
						if (tox == (Nox-Tox)) begin
							// Loop variable
							tix_n = '0;
							tiy_n = tiy + NTiy + 8'b1; 
							// Addr variable
							ix_mem_n = '0;
							iy_mem_n = iy_mem + Size_Ti;
						end
					end
					else begin
						state_n = LOAD_KEX;
						s_dma_n = 1;
						op_n = 2;
						dma_info1_n = par + 1;
						dma_mem_info1_n = par_mem;
						par_mem_n = par_mem + Size_par_kex; //Par updated after DSC
					end 
				end
			end
			
			WRITE_FMO: begin
				measure_cnt_dma_n = measure_cnt_dma + 1;
				if (f_dma) begin
					if (tox == (Nox-Tox)) begin
						tox_n = '0; ox_mem_n = '0;
						if (toy == (Noy-Toy)) begin
							state_n = FINISH;
						end
						else begin
							// Next state & start module
						state_n = LOAD_FMI;
						s_dma_n = 1;
						// Assign variables
						dma_info1_n = tix;
						dma_info2_n = tiy ;
						dma_mem_info1_n = ix_mem;
						dma_mem_info2_n = iy_mem;
						// Update Loop variables
						tix_n = tix + NTix + 8'b1;
						toy_n = toy + Toy;
						// Update Memory variables
						ix_mem_n = ix_mem + NTix;
						oy_mem_n = oy_mem + Size_To;
						// Assign op
						op_n = 1;
						end
					end
					else begin
						// Next state & start module
						state_n = LOAD_FMI;
						s_dma_n = 1;
						// Assign variables
						dma_info1_n = tix;
						dma_info2_n = tiy ;
						dma_mem_info1_n = ix_mem;
						dma_mem_info2_n = iy_mem;
						// Update Loop variables
						tix_n = tix + NTix + 8'b1;
						tox_n = tox + Tox;
						// Update Memory variables
						ix_mem_n = ix_mem + NTix;
						ox_mem_n = ox_mem + Tox;
						// Assign op
						op_n = 1;
					end
				end
			end
			
		endcase
	end
endmodule
