
/* 
	Description : Component DMA which handles the transactions between the external and the on-chip memory
	Author : 	  Guillaume Gheysen
*/
 
/* 
	###################################################################################################################################
	# import 																																								 #
   ###################################################################################################################################
*/
import ram_pkg::*;
import dma_pkg::*;
/* 
	###################################################################################################################################
	# module definition 																																					 #
   ###################################################################################################################################
*/
module inverted_residual_block(input 	logic clk, rst, start,
										 input 	logic valid_extmem,
										 input	logic [31:0] data_extmem,
										 output 	logic finish,
										 output 	logic request_extmem, write_extmem,
										 output logic [31:0] addr_extmem,
										 output logic [31:0] w_data,
										 output logic w_fmi, w_kex, w_kpw, w_kdw, w_fmint,
										 output logic [31:0] ram_addr_dma,
										 output logic finish_dma, finish_conv11
									 );
									 
	/* 
		###################################################################################################################################
		# internal signals																																					 #
		###################################################################################################################################
	*/
	// Control signals
	logic start_dma;//, finish_dma;
	logic start_conv11;//, finish_conv11;
	//logic w_fmi, w_kex, w_kpw, w_kdw, w_fmint;
	logic [2:0] op;
	// Addr
	//logic [31:0] ram_addr_dma;
	logic [$clog2(KEX_N_ELEM)-1:0] ram_addr_kex_conv11, ram_addr_kex;
	logic [$clog2(FMI_N_ELEM)-1:0] ram_addr_fmi, ram_addr_fmi_conv11;
	logic [$clog2(FMINT_N_ELEM)-1:0] ram_addr_fmint, ram_addr_fmint_conv11; 
	// Data
	logic [PX_W-1:0] res_fmi, res_fmint, px_fmint;
	logic [WG_W + $clog2(Npar) -1:0] res_kex;
	logic [41:0] inf_conv;
	logic [31:0] dma_info1, dma_mem_info1, dma_info2, dma_mem_info2;
	/* 
		###################################################################################################################################
		# Modules instatiation																																					 #
		###################################################################################################################################
	*/
	Main_controller mc(.clk(clk), .rst(rst), .start(start),
							 .f_dma(finish_dma), .f_c11(finish_conv11),
							 .inf_conv(inf_conv),
							 .s_dma(start_dma), .s_c11(start_conv11),
							 .finish(finish),
							 .dma_op(op),
							 .dma_info1(dma_info1), .dma_mem_info1(dma_mem_info1), 
							 .dma_info2(dma_info2), .dma_mem_info2(dma_mem_info2) 
							);
	
	// DMA
	DMA dma(.clk(clk), .rst(rst),
				.s_op(start_dma),
				.op(op),
				.r_valid_extmem(valid_extmem),
				.r_request_extmem(request_extmem),							
				.e_op(finish_dma),											
				.w_fmi(w_fmi), .w_kex(w_kex), .w_kpw(w_kpw), .w_kdw(w_kdw), .w_ext(write_extmem),		
				.tx_i(dma_info1), .ty_i(dma_info2), .x_mem_i(dma_mem_info1), .y_mem_i(dma_mem_info1),
				.data_extmem(data_extmem),
				.ram_data_i(res_fmint),
				.addr_extmem(addr_extmem),
				.ram_addr(ram_addr_dma),
				.w_data(w_data),
				.inf_conv(inf_conv)
				);
				
	// 1*1 Convolution
	Convolution_1_1 conv_11(.clk(clk), .rst(rst), .start(start_conv11),
							  .fmi_data(res_fmi),
							  .kex_data(res_kex[WG_W-1:0]),
							  .kex_pos(res_kex[WG_W + $clog2(Npar) -1:WG_W ]),
							  .Nif(inf_conv[26:16]),
							  .fmi_addr(ram_addr_fmi_conv11),
							  .kex_addr(ram_addr_kex_conv11),
							  .fmint_addr(ram_addr_fmint_conv11),
							  .finish(finish_conv11), .write(w_fmint),
							  .res(px_fmint)
							 );
	
	// RAM_FMI			
	RAM_FMI ram_fmi( .clk(clk),
						  .addr(ram_addr_fmi),
						  .data(w_data[PX_W-1:0]),
						  .write(w_fmi),
						  .res(res_fmi)
						);
	
	// RAM_KEX				
	RAM_KEX ram_kex( .clk(clk),
						  .addr(ram_addr_kex),
						  .data(w_data[WG_W + $clog2(Npar) -1:0]),
						  .write(w_kex),
						  .res(res_kex)
						);
	
	// RAM_FMINT	
	RAM_FMINT ram_fmint( .clk(clk),
								.addr(ram_addr_fmint),
								.data(px_fmint),
								.write(w_fmint),
								.res(res_fmint)
							);
	/* 
		###################################################################################################################################
		# Combinational logic																																				 #
		###################################################################################################################################
	*/
	assign ram_addr_fmi 	 = w_fmi   ? ram_addr_dma[$clog2(FMI_N_ELEM)-1:0] : ram_addr_fmi_conv11 ;
	assign ram_addr_fmint = w_fmint ? ram_addr_fmint_conv11 					  : ram_addr_dma[$clog2(FMINT_N_ELEM)-1:0];
	assign ram_addr_kex 	 = w_kex   ? ram_addr_dma[$clog2(KEX_N_ELEM)-1:0] : ram_addr_kex_conv11 ;
	//assign ram_addr_fmo = w_fmo ? ram_addr_fmo_dsc : ram_addr_dma ;
	//assign ram_addr_kpw = w_kpw ? ram_addr_dma : ram_addr_conv11 ;
	//assign ram_addr_kdw = w_kdw ? ram_addr_dma : ram_addr_conv11 ;
	
endmodule
