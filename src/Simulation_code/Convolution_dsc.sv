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
module Convolution_dsc(input logic clk, rst, start, S, 									// clock, reset, start, and Stride  the module signals
							  input logic first_par_i,									// Control Signal enabled if the PE must not load the partial sum in the FMO buffer
							  input logic signed [PX_W - 1:0] fmint_data,   			// Data sent from the FMINT Buffer
							  input logic signed [PX_W - 1:0] fmo_data,					// Data sent from the FMO Buffer
							  input logic signed [WG_W -1:0] kdw_data,					// Data sent from the KDW Buffer
							  input logic signed [WG_W -1:0] kpw_data,					// Data sent from the KPW Buffer (value of weight)
							  input logic [$clog2(Npar+1) - 1:0] kpw_pos,				// Data sent from the KPW Buffer (pos of weight)
							  input logic [10:0] Nif, Nof, 								// Layer information
							  input logic [7:0] Nox, Noy,								// Layer information
							  input logic [7:0] Tox, Toy, 								// Layer information
							  output logic [$clog2(FMO_N_ELEM+1)-1:0] fmo_addr,			// Address of the fmo buffer to read & write the partial results
							  output logic [$clog2(KDW_N_ELEM+1)-1:0] kdw_addr,			// Address of the kdw buffer to read the weights
							  output logic [$clog2(KPW_N_ELEM+1)-1:0] kpw_addr,			// Address of the kpw buffer to read the weights
							  output logic [$clog2(FMINT_N_ELEM+1)-1:0] fmint_addr,		// Address of the fmint buffer to read results
							  output logic finish, write,								// Finish enabled when the module has finished its computation and write enabled if intermediate results can be written to main memory
							  output logic signed [PX_W - 1:0] res						// output pixel to be written to fmo buffer
							 );
	
	/* 
		###################################################################################################################################
		# internal signals																																					 #
		###################################################################################################################################
	*/
	// States
	typedef enum logic [3:0] {IDLE,             				// Idle state
									  FINISHED,					// State telling the PE has finished its operation
									  LOAD_K_DW,				// State loading the depthwise weights
									  LOAD_FMINT,				// State loading the intermediate pixels
									  DW_CONV_MUL,				// State performing the first part of the depthwise convolution (multiplication)
									  DW_CONV_ADD,				// State performing the second part of the depthwise convolution (add)
									  LOAD_K_PW,				// State loading the pointwise weights
									  PW_CONV,					// State performing the pointwise convolution
									  WRITE						// State writing results to output buffer
									  } statetype;
	statetype state, state_n; // Variables containing the state
	
	//Banked registers
	logic signed [PX_W-1 : 0] fmint_px 				[0 : (Nkx * Nky * Npar) - 1];	// Registers containing the intermediate pixels  (for next depthwise convolution)
	logic signed [WG_W-1 : 0] dw_wg    				[0 : (Nkx * Nky * Npar) - 1];	// Registers containing the depthwise weights  (for next depthwise convolution)
	logic signed [PX_W-1 : 0] res_dw_mul			[0 : (Nkx * Nky * Npar) - 1];	// Registers containing the resulting pixels of the first step of depthwise convolution
	logic signed [PX_W-1 : 0] res_dw   				[0 : Npar - 1];					// Registers containing the resulting pixels of the depthwise convolution		
	logic signed [PX_W-1 : 0] res_dw_rel			[0 : Npar - 1];					// Registers containing the resulting pixels of activation function of the depthwise convolution
	logic signed [WG_W-1 : 0] pw_wg					[0 : Nnp - 1];					// Registers containing the pointwise weights (for next pointwise convolution)
	logic signed [$clog2(Npar+1)-1 : 0] pw_pos		[0 : Nnp - 1];					// Registers containing the pointwise position
	// Registers
	logic [PX_W-1 : 0] sum;															// Result of the pointwise convolution		
	logic load_fmint, load_dw, load_pw;												// Signals telling if the banked registers need to load the next value
	logic [$clog2(Npar+1)-1:0] kf, tintf;											// Control signals (depthwise convolution, intermediate fm channels and corresponding depthwise kernel)
	logic [$clog2(Nky+1)-1:0] ky, tinty;											// Control signals (depthwise convolution, intermediate fm height and corresponding depthwise kernel height)
	logic [$clog2(Nkx+1)-1:0] kx, tintx;											// Control signals (depthwise convolution, intermediate fm width and corresponding depthwise kernel width)
	logic [$clog2(Tox_T+1)-1:0] tox;												// Control signals (output fm width)
	logic [$clog2(Toy_T+1)-1:0] toy;												// Control signals (output fm height)
	logic [$clog2(Tof+1)-1:0] tof;													// Control signals (output fm channel)
	logic [$clog2(KDW_N_ELEM+1)-1:0] addr_k_dw;										// Address of KDW buffer signals
	logic [$clog2(KPW_N_ELEM+1)-1:0] addr_k_pw, tkpw;								// Address of KPW buffer signals
	logic [$clog2(FMO_N_ELEM+1)-1:0] addr_fmo_x, addr_fmo_y, addr_fmo_f;			// Addresses of FMO buffer signals
	logic [$clog2(FMINT_N_ELEM+1)-1:0] addr_fmint_x, addr_fmint_y, addr_fmint_f;	// Addresses of FMINT buffer signals 
	logic [$clog2(FMINT_N_ELEM+1)-1:0] addr_fmint_x_ref, addr_fmint_y_ref;			// Address references of FMINT buffer signals
	logic first_par;
	// Next value for registers 
	logic signed [PX_W-1 : 0] res_dw_n 				[0 : Npar - 1];
	logic signed [PX_W-1 : 0] res_dw_mul_n 		[0 : (Nkx * Nky * Npar) - 1];
	logic signed [PX_W-1 : 0] res_dw_rel_n			[0 : Npar - 1];
	logic [PX_W-1 : 0] sum_n;
	logic load_fmint_n, load_dw_n, load_pw_n;
	logic [$clog2(Npar+1)-1:0] kf_n, tintf_n;
	logic [$clog2(Nky+1)-1:0] ky_n, tinty_n;
	logic [$clog2(Nkx+1)-1:0] kx_n, tintx_n;
	logic [$clog2(Tox_T+1)-1:0] tox_n;
	logic [$clog2(Toy_T+1)-1:0] toy_n;
	logic [$clog2(Tof+1)-1:0] tof_n;
	logic [$clog2(KDW_N_ELEM+1)-1:0] addr_k_dw_n;
	logic [$clog2(KPW_N_ELEM+1)-1:0] addr_k_pw_n, tkpw_n;
	logic [$clog2(FMO_N_ELEM+1)-1:0] addr_fmo_x_n, addr_fmo_y_n, addr_fmo_f_n;
	logic [$clog2(FMINT_N_ELEM+1)-1:0] addr_fmint_x_n, addr_fmint_y_n, addr_fmint_f_n;
	logic [$clog2(FMINT_N_ELEM+1)-1:0] addr_fmint_x_ref_n, addr_fmint_y_ref_n;
	logic first_par_n;
	logic [PX_W-1 : 0] local_sum [0 : Npar - 1];
	/* 
		###################################################################################################################################
		# Modules instatiation																																					 #
		###################################################################################################################################
	*/
	SHIFT_REGISTER_FMINT reg_fmint(.clk(clk), .load(load_fmint), .data(fmint_data), .pixels(fmint_px));
	SHIFT_REGISTER_DW_WG reg_dw_wg(.clk(clk), .load(load_dw),    .data(kdw_data), .weights(dw_wg));
	SHIFT_REGISTER_PW_PS reg_pw_ps(.clk(clk), .load(load_pw),    .data(kpw_pos),  .pos(pw_pos));
	SHIFT_REGISTER_PW_WG reg_pw_wg(.clk(clk), .load(load_pw),    .data(kpw_data), .weights(pw_wg));
	
	genvar i;
	generate begin
			for(i=0; i<Npar;i++) begin : activation_for
				RELU6_DSC activation(.in(res_dw[i]), .out(res_dw_rel_n[i]));
			end
		end
	endgenerate
	
	/* 
		###################################################################################################################################
		# Sequential logic																																					 #
		###################################################################################################################################
	*/
	always_ff @(posedge clk, posedge rst) begin
		if(rst) begin
			state <= IDLE;
			sum <= '0;
			load_fmint <= '0; 
			load_dw <= '0; 
			load_pw <= '0;
			kf <= '0; ky <= '0; kx <= '0;
			tintf <= '0; tinty <= '0; tintx <= '0;
			tox <= '0; toy <= '0; tof <= '0;
			addr_fmint_x <= '0; addr_fmint_y <= '0; addr_fmint_f <= '0;
			addr_k_dw <= '0; addr_fmo_x <= '0; addr_fmo_y <= '0; addr_fmo_f <= '0;
			addr_fmint_x_ref <= '0; addr_fmint_y_ref <= '0;
			addr_k_pw <= '0;
			tkpw <= '0;
			first_par <= '0;
			for(int i =0; i < Npar ; i=i+1 ) begin
				res_dw[i] <= '0;
				res_dw_rel[i] <= '0;
			end
			for(int i = 0; i < (Nkx * Nky * Npar); i=i+1) begin
				res_dw_mul[i] = '0;
			end
		end
		else begin
			state <= state_n;
			sum <= sum_n;
			load_fmint <= load_fmint_n; 
			load_dw <= load_dw_n; 
			load_pw <= load_pw_n;
			kf <= kf_n; ky <= ky_n; kx <= kx_n;
			tintf <= tintf_n; tinty <= tinty_n; tintx <= tintx_n;
			tox <= tox_n; toy <= toy_n; tof <= tof_n;
			addr_fmint_x <= addr_fmint_x_n; addr_fmint_y <= addr_fmint_y_n; addr_fmint_f <= addr_fmint_f_n;
			addr_k_dw <= addr_k_dw_n; addr_fmo_x <= addr_fmo_x_n; addr_fmo_y <= addr_fmo_y_n; addr_fmo_f <= addr_fmo_f_n;
			addr_fmint_x_ref <= addr_fmint_x_ref_n; addr_fmint_y_ref <= addr_fmint_y_ref_n;
			addr_k_pw <= addr_k_pw_n;
			tkpw <= tkpw_n;
			first_par <= first_par_n;
			for(int i =0; i < Npar ; i=i+1 ) begin
				res_dw[i] <= res_dw_n[i];
				res_dw_rel[i] <= res_dw_rel_n[i];
			end
			for(int i = 0; i < (Nkx * Nky * Npar); i=i+1) begin
				res_dw_mul[i] = res_dw_mul_n[i];
			end
		end
	end
	
	/* 
		###################################################################################################################################
		# Combinational logic																																				 #
		###################################################################################################################################
	*/
	assign finish     = state == FINISHED;
	assign write      = state == WRITE;
	assign fmint_addr = addr_fmint_f + addr_fmint_x + addr_fmint_y;
	assign fmo_addr   = addr_fmo_f + addr_fmo_y + addr_fmo_x;
	assign kdw_addr 	= addr_k_dw;
	assign kpw_addr	= addr_k_pw;
	assign res = sum;
	
	always_comb begin
		state_n = state;
		load_dw_n = '0;
		load_pw_n = '0;
		load_fmint_n = '0;
		sum_n = sum;
		first_par_n = first_par;
		// KDW paramters
		kx_n = kx;
		ky_n = ky;
		kf_n = kf;
		// FMint parameters
		tintx_n = tintx;
		tinty_n = tinty;
		tintf_n = tintf;
		// KPW parameters
		tkpw_n = tkpw;
		// FMO Parameters
		tox_n = tox; 
		toy_n = toy;
		tof_n = tof;
		// Addresses
		addr_k_dw_n = addr_k_dw;
		addr_fmint_x_n = addr_fmint_x;
		addr_fmint_y_n = addr_fmint_y;
		addr_fmint_f_n = addr_fmint_f;
		addr_fmint_x_ref_n = addr_fmint_x_ref;
		addr_fmint_y_ref_n = addr_fmint_y_ref;
		addr_k_pw_n = addr_k_pw;
		addr_fmo_x_n = addr_fmo_x; 
		addr_fmo_y_n = addr_fmo_y;
		addr_fmo_f_n = addr_fmo_f;
		// Intermediate result
		for(int i =0; i < Npar ; i=i+1 ) begin
				res_dw_n[i] = res_dw[i];
				local_sum[i] = '0;
		end
		for(int i = 0; i < (Nkx * Nky * Npar); i=i+1) begin
				res_dw_mul_n[i] = res_dw_mul[i];
			end
		case(state) 
			// IDLE state - when no computation is occuring
			IDLE: begin
				if(start) begin
					state_n = LOAD_K_DW;
					first_par_n = first_par_i;
					// tox & toy determines the pixel written
					tox_n = 1;
					toy_n = 1;
					tof_n = 1;
					// Kx & Ky & Kf
					kx_n = 1;
					ky_n = 1;
					kf_n = 1;
					// For fmint pixels
					addr_k_dw_n = '0;
					addr_fmo_x_n = '0;
					addr_fmo_y_n = '0;
				end
			end
			
			// Load into registers the pixels
			LOAD_K_DW: begin
				if (kx == Nkx) begin // One ligne read, go to next line
					kx_n = 1;
					if (ky == Nky) begin // One kernel loaded, go to next kernel
						ky_n = 1;
						if (kf == Npar) begin // All kernels loaded
							// Set new state
							state_n = LOAD_FMINT;
							// set the output pixel to produce and the associated input pixel
							tintx_n = 1;
							tinty_n = 1;
							tintf_n = 1;
							// Set the addresses
							addr_fmint_f_n = '0;
							addr_fmint_x_n = '0;
							addr_fmint_y_n = '0;
							// Set references
							addr_fmint_x_ref_n = '0;
							addr_fmint_y_ref_n = '0;
						end
						else begin
							// Set new state & enable load
							load_dw_n = 1;
							state_n = LOAD_K_DW;
							// Set the addresses & control signals
							kf_n = kf + load_dw;
							addr_k_dw_n = addr_k_dw + {{$clog2(KDW_N_ELEM+1) - 1{1'b0}}, 1'b1};
						end
					end
					else begin
						// Set new state & enable load
						state_n = LOAD_K_DW;
						load_dw_n = 1;
						// Set the addresses & control signals
						ky_n = ky + load_dw;
						addr_k_dw_n = addr_k_dw +  {{$clog2(KDW_N_ELEM+1) - 1{1'b0}}, 1'b1};
					end
				end
				else if ((kx + 1 == Nkx) && (ky == Nky) && (kf == Npar)) begin // Avoid address overflow
					// Set new state & enable load
					state_n = LOAD_K_DW;
					load_dw_n = 1;
					// Set the addresses & control signals 
					kx_n = kx + load_dw;
				end
				else begin
					// Set new state & enable load
					state_n = LOAD_K_DW;
					load_dw_n = 1;
					// Set the addresses & control signals
					kx_n = kx + load_dw;
					addr_k_dw_n = addr_k_dw + {{$clog2(KDW_N_ELEM+1) - 1{1'b0}}, 1'b1}; 
				end
			end
			
			// Load Pixels to perform the DW convolution
			LOAD_FMINT: begin
				// Handling loop variables & next state
				if(tintx == Nkx) begin
					tintx_n = 1;
					if (tinty == Nky) begin
						tinty_n = 1;
						if (tintf == Npar) begin
							state_n = DW_CONV_MUL;
						end
						else begin
							tintf_n = tintf+ {{$clog2(Npar+1) - 1{1'b0}}, 1'b1}; 
							state_n = LOAD_FMINT;
							load_fmint_n = 1;
						end
					end
					else begin
						tinty_n = tinty+load_fmint; 
						state_n = LOAD_FMINT; 
						load_fmint_n = 1;
					end
				end
				else begin
					tintx_n = tintx + load_fmint;
					state_n = LOAD_FMINT;
					load_fmint_n = 1;
				end
				
				// Handling the next address
				if (tintx + 1 == Nkx) begin
					addr_fmint_x_n = addr_fmint_x_ref;
					if (tinty == Nky) begin
						addr_fmint_y_n = addr_fmint_y_ref;
						if ( ~(tintf == Npar)) begin
							addr_fmint_f_n = addr_fmint_f + Size_FMINT_T[$clog2(FMINT_N_ELEM+1)-1:0];
						end
					end
					else begin
						addr_fmint_y_n = addr_fmint_y + Tiy_T[$clog2(FMINT_N_ELEM+1)-1:0];
					end
				end
				else if (~((tintx == Nkx) && (tinty == Nky) && (tintf == Npar))) begin
					addr_fmint_x_n = addr_fmint_x + {{$clog2(FMINT_N_ELEM+1) - 1{1'b0}}, 1'b1};
				end
			end
			
			// DW convolution (step 1)
			DW_CONV_MUL: begin
				state_n = DW_CONV_ADD;
				for(int f = 0; f < Npar ; f=f+1) begin
					for (int y = 0; y < Nky ; y=y+1) begin
						for (int x = 0; x < Nkx ; x=x+1) begin
							// Intermediate values
							logic signed [PX_W - 1 : 0] cur_val;
							logic signed [WG_W - 1 : 0] cur_wg;
							logic signed [PX_W + WG_W - 1 : 0] int_res;
							logic signed [PX_W - 1 : 0] trunc_res;
							// Computation
							cur_val = fmint_px[(f*Nkx*Nky) + (y * Nkx) + x];
							cur_wg  = dw_wg   [(f*Nkx*Nky) + (y * Nkx) + x];
							int_res = cur_val * cur_wg;
							trunc_res = int_res[PX_W + WG_W - 4 - 1: PX_W - 4];
							res_dw_mul_n[f*Nky*Nky + y*Nkx + x] = trunc_res;
						end
					end
				end
			end
			
			// DW convolution (step 1)
			DW_CONV_ADD: begin
				state_n = LOAD_K_PW;
				addr_fmo_f_n = '0;
				tkpw_n = 1;
				addr_k_pw_n = '0;
				for(int f = 0; f < Npar ; f=f+1) begin
					for (int y = 0; y < Nky ; y=y+1) begin
						for (int x = 0; x < Nkx ; x=x+1) begin
							local_sum[f] = local_sum[f] + res_dw_mul[f*Nky*Nky + y*Nkx + x];
						end
					end
					res_dw_n[f] = local_sum[f];
				end
			end
			
			// Load the PW weights
			LOAD_K_PW: begin
				if (tkpw >= Nnp) begin
					if (tkpw == 1) begin
						// enable load
						load_pw_n = 1;
						// Set the addresses & control signals 
						tkpw_n = tkpw + {{$clog2(KPW_N_ELEM+1) - 1{1'b0}}, 1'b1};
					end
					else begin
						// Set new state
						state_n = PW_CONV;
					end
				end
				else if (tkpw +1 == Nnp) begin
					// Set new state & enable load
					state_n = LOAD_K_PW;
					load_pw_n = 1;
					// Set the addresses & control signals 
					tkpw_n = tkpw + load_pw;
					addr_k_pw_n = addr_k_pw + {{$clog2(KPW_N_ELEM+1) - 1{1'b0}}, ~load_pw}; 
				end
				else begin
					// Set new state & enable load
					state_n = LOAD_K_PW;
					load_pw_n = 1;
					// Set the addresses & control signals 
					addr_k_pw_n = addr_k_pw + {{$clog2(KPW_N_ELEM+1) - 1{1'b0}}, 1'b1};
					tkpw_n = tkpw + load_pw;
				end
			end

			// PW CONVOLUTION
			PW_CONV: begin
				state_n = WRITE;
				if (first_par) begin
					sum_n = '0;
				end
				else begin
					sum_n = fmo_data;
				end
				for (int np = 0; np < Nnp; np = np+1) begin
					logic signed [PX_W - 1 : 0] cur_val;
					logic signed [WG_W - 1 : 0] cur_wg;
					logic signed [$clog2(Npar+1)-1:0] cur_pos;
					logic signed [PX_W + WG_W - 1 : 0] int_res;
					logic signed [PX_W - 1 : 0] trunc_res;
					// Computation
					cur_pos[$clog2(Npar+1)-1:0] = pw_pos[np][$clog2(Npar+1) -1 :0];
					cur_val = res_dw_rel[cur_pos[$clog2(Npar+1)-1:0]][PX_W - 1 : 0];
					cur_wg = pw_wg[np][WG_W - 1:0];
					int_res = cur_val * cur_wg;
					trunc_res = int_res[PX_W + WG_W - 4 - 1: PX_W - 4];
					sum_n = sum_n + trunc_res;
				end
			end

			// Write Result to FMO buffer
			WRITE: begin
				if (tof == Nof) begin // We wrote all channel of output fm tile
					addr_fmo_f_n = '0; tof_n = 1; addr_fmint_f_n = '0;
					if(tox == Tox) begin // We wrote the a line of the output fm tile
						addr_fmo_x_n = '0; tox_n = 1; addr_fmint_x_n = '0; addr_fmint_x_ref_n = '0;
						if(toy == Toy) begin // We wrote the output fm tile
							// Set finish states
							state_n = FINISHED;
						end
						else begin
							// Init the load
							state_n = LOAD_FMINT;
							// set the output pixel to produce and the associated input pixel
							tintx_n = 1;
							tinty_n = 1;
							tintf_n = 1;
							toy_n = toy + {{$clog2(Tox_T+1) - 1{1'b0}}, 1'b1};
							// Set the addresses
							addr_fmint_y_ref_n = addr_fmint_y_ref + (Tix_T[$clog2(FMINT_N_ELEM+1)-1:0] << S); 
							addr_fmint_y_n     = addr_fmint_y     + (Tix_T[$clog2(FMINT_N_ELEM+1)-1:0] << S);
							addr_fmo_y_n = addr_fmo_y + Tox; 
						end
					end
					else begin
						// Init the load
						state_n = LOAD_FMINT;
						// Set the output pixel to produce and the associated input pixel
						tintx_n = 1;
						tinty_n = 1;
						tintf_n = 1;
						tox_n = tox + {{$clog2(Tox_T+1) - 1{1'b0}}, 1'b1};
						// Set the addresses
						addr_fmint_x_ref_n = addr_fmint_x_ref + ({{$clog2(FMINT_N_ELEM+1) - 1{1'b0}}, 1'b1} << S);
						addr_fmint_x_n     = addr_fmint_x     + ({{$clog2(FMINT_N_ELEM+1) - 1{1'b0}}, 1'b1} << S);
						addr_fmo_x_n = addr_fmo_x + {{$clog2(FMO_N_ELEM+1) - 1{1'b0}}, 1'b1};
					end
				end
				else begin
					// Init the load
					state_n = LOAD_K_PW;
					// Set the output pixel to produce and the associated input pixel
					tkpw_n = 1;
					tof_n = tof + {{$clog2(Tof+1) - 1{1'b0}}, 1'b1};
					// Set the addresses
					addr_fmo_f_n = addr_fmo_f + Size_FMO_T[$clog2(FMO_N_ELEM+1)-1:0];
					addr_k_pw_n = addr_k_pw + {{$clog2(KPW_N_ELEM+1) - 1{1'b0}}, 1'b1}; 
				end
			end
			
			// When the DSC has finished to perform the convolution
		   FINISHED: begin
				state_n = IDLE;
			end
			
		   
		endcase
	end
endmodule
/* 
	###################################################################################################################################
	# Additional modules : shift registers holding the data for the current convolution	& RELU6 function																																			 #
	###################################################################################################################################
*/


module SHIFT_REGISTER_FMINT(
								 input logic clk, load,
								 input logic signed[PX_W - 1:0] data,
								 output logic signed [PX_W - 1:0] pixels [0 : (Nkx * Nky * Npar) - 1]
								);
	always_ff @(posedge clk) begin
		if (load) begin
		pixels [(Nkx * Nky * Npar) -1] <= data;
		for (int i=0 ; i < (Nkx * Nky * Npar)-1; i=i+1) begin
			pixels[i] <= pixels[i+1];
		end
		end
	end
endmodule

module SHIFT_REGISTER_DW_WG(
								 input logic clk, load,
								 input logic signed[WG_W - 1:0] data,
								 output logic signed [WG_W - 1:0] weights [0 : (Nkx * Nky * Npar) - 1]
								);
	always_ff @(posedge clk) begin
		if (load) begin
		weights [(Nkx * Nky * Npar) -1] <= data;
		for (int i=0 ; i < (Nkx * Nky * Npar) - 1; i=i+1) begin
			weights[i] <= weights[i+1];
		end
		end
	end
endmodule

module SHIFT_REGISTER_PW_PS(
								 input logic clk, load,
								 input logic signed [$clog2(Npar+1) - 1:0] data,
								 output logic signed [$clog2(Npar+1) - 1:0] pos [0 : Nnp-1 ]
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

module SHIFT_REGISTER_PW_WG(
								 input logic clk, load,
								 input logic signed [WG_W  - 1:0] data,
								 output logic signed [WG_W  - 1:0] weights [0 : Nnp-1 ]
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

module RELU6_DSC(
				 input logic signed [PX_W - 1:0] in,
				 output logic signed [PX_W - 1:0] out);
	logic [PX_W -1 : 0] val = (4'b0110) << (PX_W - 4 - 1);
	assign out = in[PX_W - 1] ? '0 : ( (in[PX_W - 1:PX_W - 4 -1] == 4'b0110) ? val : in);
endmodule
