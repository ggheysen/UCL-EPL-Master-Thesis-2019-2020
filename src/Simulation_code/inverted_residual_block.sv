
/* 
	Description : Component DMA which handles the transactions between the external and the on-chip memory
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
module inverted_residual_block(input 	logic clk, rst, start,
										 input 	logic valid_extmem,
										 input	logic [31:0] data_extmem,
										 output 	logic finish,
										 output 	logic request_extmem, write_extmem,
										 output logic [31:0] addr_extmem,
										 output logic [31:0] w_data,
										 output logic finish_dma, finish_conv11, finish_dsc
									 );
									 
	/* 
		###################################################################################################################################
		# internal signals																																					 #
		###################################################################################################################################
	*/
	// Control signals
	logic start_dma;//, finish_dma;
	logic start_conv11;//, finish_conv11;
	logic start_dsc;//, finish_dsc;
	logic dma_r_fmo;
	logic w_fmi, w_kex, w_kpw, w_kdw, w_fmint, w_fmo;
	logic [2:0] op;
	
	// Addr
	logic [$clog2(FMINT_N_ELEM) - 1:0] ram_addr_dma;
	logic [$clog2(KEX_N_ELEM)-1:0] ram_addr_kex_conv11, ram_addr_kex;
	logic [$clog2(FMI_N_ELEM)-1:0] ram_addr_fmi, ram_addr_fmi_conv11;
	logic [$clog2(FMINT_N_ELEM)-1:0] ram_addr_fmint, ram_addr_fmint_conv11, ram_addr_fmint_dsc;
	logic [$clog2(KDW_N_ELEM)-1:0] ram_addr_kdw, ram_addr_kdw_dsc;
	logic [$clog2(KPW_N_ELEM)-1:0] ram_addr_kpw, ram_addr_kpw_dsc; 	
	logic [$clog2(FMO_N_ELEM)-1:0] ram_addr_fmo, ram_addr_fmo_dsc;
	
	// Data
	logic [PX_W-1:0] res_fmi, res_fmint, px_fmint, res_kdw;
	logic [PX_W-1:0] res_fmo, px_fmo;
	logic [WG_W + $clog2(Npar) -1:0] res_kex, res_kpw;
	logic [63:0] inf_conv;
	logic [31:0] dma_info1, dma_mem_info1, dma_info2, dma_mem_info2;
	logic [(2*$clog2(KEX_N_ELEM))-1:0] size_kex;
	logic [$clog2(KEX_N_ELEM)-1:0] size_KEX;
	
	/* 
		###################################################################################################################################
		# Modules instatiation																																					 #
		###################################################################################################################################
	*/
	Main_controller mc(.clk(clk), .rst(rst), .start(start),
							 .f_dma(finish_dma), .f_c11(finish_conv11), .f_dsc(finish_dsc),
							 .inf_conv(inf_conv),
							 .s_dma(start_dma), .s_c11(start_conv11),  .s_dsc(start_dsc),
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
				.r_fmo_buff(dma_r_fmo),
				.e_op(finish_dma),											
				.w_fmi(w_fmi), .w_kex(w_kex), .w_kpw(w_kpw), .w_kdw(w_kdw), .w_ext(write_extmem),		
				.tx_i(dma_info1), .ty_i(dma_info2), .x_mem_i(dma_mem_info1), .y_mem_i(dma_mem_info2),
				.data_extmem(data_extmem),
				.ram_data_i(res_fmo),
				.addr_extmem(addr_extmem),
				.addr_ram(ram_addr_dma),
				.w_data(w_data),
				.inf_conv(inf_conv)
				);
				
	// 1*1 Convolution
	Convolution_1_1 conv_11(.clk(clk), .rst(rst), .start(start_conv11),
							  .fmi_data(res_fmi),
							  .kex_data(res_kex[WG_W-1:0]),
							  .kex_pos(res_kex[WG_W + $clog2(Npar) -1:WG_W ]),
							  .Size_KEX(size_KEX),
							  .Nif(inf_conv[26:16]),
							  .fmi_addr(ram_addr_fmi_conv11),
							  .kex_addr(ram_addr_kex_conv11),
							  .fmint_addr(ram_addr_fmint_conv11),
							  .finish(finish_conv11), .write(w_fmint),
							  .res(px_fmint)
							 );
	
	// DSC Convolution
	Convolution_dsc conv_dsc(	.clk(clk), .rst(rst), .start(start_dsc), .S(inf_conv[41]),
										.fmint_data(res_fmint),
										.fmo_data(res_fmo),
										.kdw_data(res_kdw),
										.kpw_data(res_kpw[WG_W-1:0]),
										.kpw_pos(res_kpw[WG_W + $clog2(Npar) -1:WG_W ]),
										.Nif(inf_conv[26:16]),
										.Nof(inf_conv[37:27]), 
										.Nox(inf_conv[7:0] >> inf_conv[41]), .Noy(inf_conv[15:8] >> inf_conv[41]),
										.Tox(Tox_T[7:0] >> inf_conv[41]),
										.Toy(Toy_T[7:0] >> inf_conv[41]),
										.fmo_addr(ram_addr_fmo_dsc),
										.kdw_addr(ram_addr_kdw_dsc),
							         .kpw_addr(ram_addr_kpw_dsc),
							         .fmint_addr(ram_addr_fmint_dsc),
										.finish(finish_dsc), .write(w_fmo),
										.res(px_fmo)
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
	// RAM_FMO
	RAM_FMO ram_fmo( .clk(clk),
						  .addr(ram_addr_fmo),
						  .data(px_fmo),
						  .write(w_fmo),
						  .res(res_fmo)
						);
	// RAM_KDW
	RAM_KDW ram_kdw( .clk(clk),
						  .addr(ram_addr_kdw),
						  .data(w_data[WG_W -1:0]),
						  .write(w_kdw),
						  .res(res_kdw)
						);
	// RAM_KPW
	RAM_KPW ram_kpw( .clk(clk),
						  .addr(ram_addr_kpw),
						  .data(w_data[WG_W + $clog2(Npar) -1:0]),
						  .write(w_kpw),
						  .res(res_kpw)
						);
	/* 
		###################################################################################################################################
		# Combinational logic																																				 #
		###################################################################################################################################
	*/
	assign ram_addr_fmi 	 = w_fmi   ? ram_addr_dma[$clog2(FMI_N_ELEM)-1:0] : ram_addr_fmi_conv11 ;
	assign ram_addr_fmint = w_fmint ? ram_addr_fmint_conv11 					  : ram_addr_fmint_dsc;
	assign ram_addr_kex 	 = w_kex   ? ram_addr_dma[$clog2(KEX_N_ELEM)-1:0] : ram_addr_kex_conv11 ;
	assign ram_addr_fmo = dma_r_fmo ? ram_addr_dma[$clog2(FMO_N_ELEM)-1:0] : ram_addr_fmo_dsc;
	assign ram_addr_kpw = w_kpw ? ram_addr_dma[$clog2(KPW_N_ELEM)-1:0] : ram_addr_kpw_dsc ;
	assign ram_addr_kdw = w_kdw ? ram_addr_dma[$clog2(KDW_N_ELEM)-1:0] : ram_addr_kdw_dsc ;
	assign size_kex = Nnp[$clog2(KEX_N_ELEM)-1:0] * inf_conv[42 + $clog2(KEX_N_ELEM)-1:42];
	assign size_KEX = size_kex[$clog2(KEX_N_ELEM)-1:0];
	
endmodule
