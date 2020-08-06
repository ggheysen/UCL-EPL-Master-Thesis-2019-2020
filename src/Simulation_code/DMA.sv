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

module DMA( input  logic clk, rst, 										// Clock and reset signals
				input	 logic s_op,											// Enabled when the DMA has to perform a transfer
				input  logic [2:0] op,										// The operation 
				input  logic r_valid_extmem,								// When enabled, the DMA can read the signal sent by external memory
				output logic r_request_extmem,							// Enabled when the DMA has to read from the external memory
				output logic e_op,											// Enabled when the DMA has finished the transaction
				output logic w_fmi, w_kex, w_kpw, w_kdw, w_ext,		// enabled when the DMA has to Write on the different buffer and external memory
				output logic r_fmo_buff,
				input  logic [31:0]  tx_i, ty_i, x_mem_i, y_mem_i,	// Address signal to tell where to read from the external memory
				input	 logic [31:0] data_extmem,							// Data sent by external memory
				input  logic [PX_W-1:0] ram_data_i,
				output logic [31:0] addr_extmem,							// Address to read/write from external memory
				output logic [$clog2(FMI_N_ELEM+1)-1:0] addr_ram,	// Address to write to a RAM, FMI buffer is the largest buffer
				output logic [31:0] w_data,						 		// Data to write to a RAM & Extmem
				output logic [63:0] inf_conv								// Information of the convolution (for main controller)
			  );

	/* 
		###################################################################################################################################
		# internal signals																																					 #
		###################################################################################################################################
	*/
	typedef enum logic [4:0] {IDLE,             
									  FINISHED,					// State telling the DMA has finished its transaction
									  RAM_LOADING,				// State used for pipeling the RAM accesses
									  R_INIT, W_INIT, 		// States related about storing the information about the layer
									  R_FMI,  W_FMI,		 	// States related about writing to FM input buffer
									  R_KEXP, W_KEXP, 		// States related about writing to 1*1 expansion filter buffer
									  R_KPW,  W_KPW, 			// States related about writing to pointwise filter buffer
									  R_KDW,  W_KDW, 			// States related about writing to external memory the final results (in output buffer)
									  R_FMO,  W_FMO 			// States related about writing to external memory the final results (in output buffer)
									  } statetype; 
									  
	statetype state, state_n; // Variables containing the state
	
	// Registers
	logic [7:0]		Nix, Niy, Nox, Noy; 													 // Spatial Dimensions
	logic [7:0]		Tox, Toy;			  													 // Output Tiling, Calculated from Tix/Tiy
	logic [10:0]	Nif, Nintf, Nof;	  													 // channel dimensions & number of kernel groups of size Npar
	logic [10:0]	Ngr, Ngrint;		  													 // Number of groups in each 1*1 convolution (Ngr for expansion and Ngrint for pointwise)
	logic [2:0]		t;						  												    // Expansion factor
	logic 			S;						  													 // Stride
	logic [31:0] 	data;					  													 // Data request from a memory bank or Ram
	logic [31:0] 	x, y, x_mem, y_mem, tx, ty, tx_mem, ty_mem, x_ref, y_ref; // Information needed to construct the right address
	logic [31:0]	f, f_mem; 																 // Information needed to construct the right address
	logic [31:0]	offset;
	logic [$clog2(FMI_N_ELEM+1)-1:0]   x_ram, y_ram, f_ram;
	logic 			r_req_extmem;
	logic [31:0] Size_FMI, Size_FMO, Size_KEX, Size_KPW; //Size of the different element
	
	
	// Next value for registers
	logic [7:0]		Nix_n, Niy_n;
	logic [10:0]	Nif_n, Nof_n, Ngr_n, Ngrint_n, Nintf_n;
	logic [2:0]		t_n;
	logic 			S_n;
	logic [31:0] 	data_n;
	logic [31:0] 	x_n, y_n, x_mem_n, y_mem_n, tx_n, ty_n, tx_mem_n, ty_mem_n, x_ref_n, y_ref_n;
	logic [31:0]	f_n, f_mem_n;
	logic 			r_request_extmem_n;
	logic [31:0]	offset_n;
	logic [$clog2(FMI_N_ELEM+1)-1:0]   x_ram_n, y_ram_n, f_ram_n;
	logic [31:0] Size_FMI_n, Size_FMO_n, Size_KEX_n, Size_KPW_n; //Size of the different element
	
	// Memory (offset & multiplication)
	logic [31:0] mem_offset [4:0];
	logic [31:0] mem_offset_n [4:0];
	
	// Signals
	logic padding_condition; //If we insert padding
	
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
			data			  <= '0;
			x		 <= '0; y	   <= '0; 
			x_mem	 <= '0; y_mem  <= '0;
			tx		 <= '0; ty	   <= '0;
			tx_mem <= '0; ty_mem	<= '0;
			x_ref <= '0; y_ref	<= '0;
			f <= '0; f_mem <= '0;
			r_req_extmem <= '0;
			x_ram <= '0; y_ram <='0; f_ram <= '0;
			offset <= '0; 
			Nintf <= '0;
			Size_FMI <= '0; Size_FMO <= '0;
			Size_KEX <= '0; Size_KPW <= '0;
			for (int i = 0; i<5 ; i=i+1) begin
				mem_offset[i] <= '0;
			end
		end
		else begin // Else, take next values
			state <= state_n;
			Nix 	<= Nix_n; Niy 		<= Niy_n;
			Nif 	<= Nif_n; Nof 		<= Nof_n;
			Ngr 	<= Ngr_n; Ngrint	<= Ngrint_n;
			t 		<= t_n; 	 S 	<= S_n;
			data			<= data_n;
			x		 <= x_n; 		y	    <= y_n; 
			x_mem	 <= x_mem_n; 	y_mem  <= y_mem_n;
			tx		 <= tx_n; 		ty	    <= ty_n;
			tx_mem <= tx_mem_n;	ty_mem <= ty_mem_n;
			tx_mem <= tx_mem_n;	ty_mem <= ty_mem_n;
			x_ref <= x_ref_n	; y_ref	<= y_ref_n;
			f <= f_n; f_mem <= f_mem_n;
			r_req_extmem <= r_request_extmem_n;
			offset <= offset_n;
			x_ram <= x_ram_n; y_ram <= y_ram_n; f_ram <= f_ram_n;
			Nintf <= Nintf_n;
			Size_FMI <= Size_FMI_n; Size_FMO <= Size_FMO_n;
			Size_KEX <= Size_KEX_n; Size_KPW <= Size_KPW_n;
			for (int i = 0; i<5 ; i=i+1) begin
				mem_offset[i] <= mem_offset_n[i];
			end
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
	assign inf_conv[52:42] = Ngr;
	assign inf_conv[63:53] = Ngrint;
	
	// DMA finished transfer when in final states
	assign e_op = (state == FINISHED);
	
	// Tell the FMO buffer to read the dma_ram address instead of the dsc_fmo address
	assign r_fmo_buff = (state == RAM_LOADING) || (state == R_FMO) || (state == W_FMO);
	
	// tell when the request signal is enabled
	assign r_request_extmem = (~padding_condition) && (r_req_extmem);
	
	// Data to write the RAM
	assign w_data = data;
	
	// Assign padding condition (fill memory with 0, only when in FMI states)
	assign padding_condition = ((state == R_FMI) && ((tx == 0) || (ty == 0) || (tx > Nix) || (ty > Nix)));
	
	// Write to RAM (depending on state)
	assign w_fmi = (state == W_FMI);
	assign w_ext = (state == W_FMO);
	assign w_kex = (state == W_KEXP);
	assign w_kpw = (state == W_KPW);
	assign w_kdw = (state == W_KDW);
	
	// Determine the Output dimension
	assign Nox = Nix >> S;
	assign Noy = Niy >> S;
	assign Tox = (Tox_T[7:0] >> S);
	assign Toy = (Toy_T[7:0] >> S);
	
	//assign addresses
	assign addr_extmem = offset + x_mem + y_mem + f_mem;
	assign addr_ram    =          x_ram + y_ram + f_ram;
	
	// Store constant depending on the layer parameters
	assign Size_FMI_n = Nix * Niy; // The size of one channel of input FM
	assign Size_KEX_n = Ngr * Nnp; // The size of 1*1 exp kernel
	assign Nintf_n = Nif * t;   // The number of intermediate channels
	assign Size_KPW_n = Ngrint * Nnp; // The size of pointwise exp kernel
	assign Size_FMO_n = Nox * Noy; // The size of one channel of output FM
	
	always_comb begin
		// If no values has changed
		state_n = state;
		Nix_n   = Nix; Niy_n   = Niy;
		Nif_n   = Nif; Nof_n   = Nof;
		Ngr_n = Ngr; Ngrint_n = Ngrint;
		t_n 	  = t; 	 S_n 	  = S;
		data_n = data;
		x_n		  = x; 		y_n	   = y; 
		x_mem_n	  = x_mem; 	y_mem_n  = y_mem;
		tx_n		  = tx; 		ty_n     = ty;
		tx_mem_n	  = tx_mem;	ty_mem_n = ty_mem;
		x_ref_n		  = x_ref; 		y_ref_n	   = y_ref; 
		f_n = f; f_mem_n = f_mem;
		r_request_extmem_n = '0;
		offset_n = offset;
		x_ram_n = x_ram; y_ram_n = y_ram; f_ram_n = f_ram;
		for (int i = 0; i<5 ; i=i+1) begin
			mem_offset_n[i] = mem_offset[i]; 
		end
		// FSM
		case(state)
			/* ############################################### */
			// IDLE state
			IDLE: begin
				if(s_op) begin
					case(op)
						// Store layer information
						0: begin
							//Change state
							state_n 			 = R_INIT;
							// ask to read external memory
							r_request_extmem_n = 1;
							// Set the address
							offset_n = '0;
							x_mem_n = '0;
							y_mem_n = '0;
							f_mem_n = '0;
							x_n = 1;
						end
						
						// Fill IFM buffer
						1: begin
							// Change state
							state_n 			 = R_FMI;
							//Request external memory
							r_request_extmem_n = 1;
							// Loop Variables
							x_n = 1; y_n = 1; f_n = 1; //Position in the Tile
							tx_n = tx_i; ty_n = ty_i; // Position of the pixel in the FMI
							tx_mem_n = tx_i; ty_mem_n = ty_i;
							// Ram addresses
							x_ram_n = '0; y_ram_n = '0; f_ram_n = '0;
							// External memory address of the first element to extract
							x_mem_n = x_mem_i; y_mem_n = y_mem_i; f_mem_n = 0; 
							offset_n = mem_offset[0];
							x_ref_n =  x_mem_i; y_ref_n = y_mem_i;
						end
						
						// Fill Kexp buffer
						2: begin
							// Change state
							state_n 			 = R_KEXP;
							//Request external memory
							r_request_extmem_n = 1;
							// Loop Variables
							x_n = 1; f_n = 1;
							tx_n = tx_i; // tx is the first kernel channel to extract
							// Ram addresses
							x_ram_n = '0; y_ram_n = '0; f_ram_n = '0;
							// External memory address of the first element to extract
							x_mem_n = x_mem_i;
							y_mem_n = '0;
							f_mem_n = '0;
							offset_n = mem_offset[2]; // x_mem_i contains the adress of the channel represented by tx
						end
						
						// Fill KPW buffer
						3: begin
							// Change state
							state_n 			 = R_KPW;
							//Request external memory
							r_request_extmem_n = 1;
							// Loop Variables
							x_n = 1; f_n = 1; // we load every weight from 1 to Nof corresponding to that group in the kernel (Nnp weights)
							tx_n = tx_i; // Tx_i represents which group to select (each weight is composed of x group of size Nnp)
							tx_mem_n = tx_i;
							// Ram addresses
							x_ram_n = '0; y_ram_n = '0; f_ram_n = '0;
							// External memory address of the first element to extract
							x_mem_n = x_mem_i ; y_mem_n = '0; f_mem_n = '0; // x_mem_i contains the adress of the par channel
							x_ref_n = x_mem_i;
							offset_n = mem_offset[3];
						end
						
						// Fill KDW buffer
						4: begin
							// Change state
							state_n 			 = R_KDW;
							//Request external memory
							r_request_extmem_n = 1;
							// Loop Variables
							x_n = 1; y_n = 1; f_n = 1; tx_n = tx_i; // tx represent the first channel (to tx + Npar) to load the weights
							tx_mem_n = tx_i;
							// Ram addresses
							x_ram_n = '0; y_ram_n = '0; f_ram_n = '0;
							// External memory address of the first element to extract
							offset_n 	 = mem_offset[4]; 
							x_mem_n = '0 ; y_mem_n = '0; f_mem_n = x_mem_i; // X_mem_i the address of the first weight corresponding to channel tx
						end
						
						// Flush FMO buffer & write its content to external memory
						5: begin
							// Change state
							state_n 			 = RAM_LOADING;
							// Loop Variables
							x_n = 1; y_n = 1; f_n = 1;
							tx_n = tx_i; ty_n = ty_i;
							tx_mem_n = tx_i; ty_mem_n = ty_i;
							// Ram addresses
							x_ram_n = '0; y_ram_n = '0; f_ram_n = '0;		
							// External memory address of the first element to extract
							x_mem_n = x_mem_i; y_mem_n = y_mem_i; f_mem_n = 0; // address of the first element to write in memory (without offset and channel)
							x_ref_n =  x_mem_i; y_ref_n = y_mem_i;
							offset_n = mem_offset[1];
						end
						default: state_n = IDLE;
					endcase
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
				// Finish when reading all informations
				if (x == Size_inf_layer) begin
					state_n = FINISHED;
				end
				else begin
					// Changing the state & allowing next read request
					state_n = R_INIT; r_request_extmem_n = 1;
					// Loop variables
					x_n = x + 1;
					// memory variables
					x_mem_n = x_mem + 1;
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
						mem_offset_n[0] = data;
					end
					4:begin // OFM
						mem_offset_n[1] = data;
					end
					5:begin // KEXP
						mem_offset_n[2] = data;
					end
					6:begin; // KPW
						mem_offset_n[3] = data;
					end
					7:begin // KDW
						mem_offset_n[4] = data;
					end
					default: state_n = FINISHED;
				endcase
			end
			
			/* ############################################### */
			// Finish state
			FINISHED: begin
				state_n = IDLE;
			end
			
			/* ############################################### */
			// FMI states
			// Read the input pixel from external memory (or create a fake pixel);
			R_FMI: begin
				// Either we wait for a external data, either the pixel is a "padding pixel"
				if(r_valid_extmem) begin
						// Changing the state & load data
						state_n = W_FMI; data_n = data_extmem;
						// Update mem addresses
						x_mem_n = x_mem + {{32 - 1{1'b0}}, 1'b1};
				end
				else if(padding_condition) begin
					// Changing the state & load data
					state_n = W_FMI; data_n = '0;
				end
			end
			
			// Write the input pixel into the ram
			W_FMI: begin
				if (x == Tix_T || tx == Nix + (Nkx >> 1)) begin // We change row once we 
					x_n = 1; tx_n = tx_mem; x_ram_n = '0; x_mem_n = x_ref;
					if(y == Tiy_T || ty == Niy + (Nky >> 1)) begin // We change channel
						y_n = 1; ty_n = ty_mem; y_ram_n = '0; y_mem_n = y_ref;
						if (f == Nif) begin // If transaction is over
							// Changing the state
							state_n 			 = FINISHED;
						end
						else begin
							// Changing the state & ask request from external memory
							state_n = R_FMI; r_request_extmem_n = 1;
							// Update Loop variables
							f_n = f + 1;
							// Update RAM variables
							f_ram_n = f_ram + Size_FMI_T[$clog2(FMINT_N_ELEM+1)-1:0];
							// Update memory variables
							f_mem_n  = f_mem + Size_FMI;
						end
					end
					else begin
						// Changing the state & ask request from external memory
						state_n = R_FMI; r_request_extmem_n = 1;
						// Update Loop variables
						y_n = y + 1; ty_n = ty + 1;
						// Update RAM variables
						y_ram_n = y_ram + Tiy_T[$clog2(FMINT_N_ELEM+1)-1:0];
						// Update Memory variables
						if (~(ty == 0)) begin // First line is a padding line, we do not 
							 y_mem_n = y_mem + Nix;
						end
					end
				end
				else begin
					// Changing the state & ask request from external memory
					state_n = R_FMI; r_request_extmem_n = 1;
					// Update Loop variables
					x_n = x + 1; tx_n = tx + 1;
					// Update RAM variables
					x_ram_n = x_ram + {{$clog2(FMINT_N_ELEM+1)-1{1'b0}}, 1'b1};
					// No memory update since it depends on padding
				end
			end
			
			/* ############################################### */
			// KEXP States
			
			//Read the weight
			R_KEXP: begin
				if(r_valid_extmem) begin
						// Changing the state & load data
						state_n = W_KEXP; data_n = data_extmem;
				end
			end
			
			//Write the weight
			W_KEXP: begin
				if (f == Size_KEX) begin  // We change weight after fully loaded them
					f_n = 1; f_ram_n = '0;  f_mem_n = '0;
					if(x == Npar || tx == Nintf) begin // We have loaded Npar weights
							// Change state
							state_n = FINISHED;
					end
					else begin
						// Changing the state & ask request from external memory
						state_n = R_KEXP; r_request_extmem_n = 1;
						// Update Loop variables
						tx_n = tx + 1; x_n = x + 1;
						// Update RAM variables
						x_ram_n = x_ram + Size_KEX[$clog2(FMINT_N_ELEM+1)-1:0];
						// Update Memory variables
						x_mem_n = x_mem + Size_KEX;
					end
				end
				else begin
					// Changing the state & ask request from external memory
					state_n = R_KEXP; r_request_extmem_n = 1;
					// Update Loop variables
					f_n = f + 1;
					// Update RAM variables
					f_ram_n = f_ram + {{$clog2(FMINT_N_ELEM+1)-1{1'b0}}, 1'b1};
					// Update Memory variables
					f_mem_n = f_mem + 1;
				end
			end
			
			/* ############################################### */
			// KPW States
			
			R_KPW: begin
				if(r_valid_extmem) begin
						// Changing the state & load data
						state_n = W_KPW; data_n = data_extmem;
				end
			end
			
			W_KPW: begin
				if(x == Nnp || tx == Size_KPW) begin // We change weights after loaded Nnp weights (one group)
					x_n = 1; tx_n = tx_mem; x_ram_n = '0; x_mem_n = x_ref;
				   if (f == Nof) begin // We finish after we load the same group in every kernel.
						state_n = FINISHED;
					end
					else begin
						// Changing the state & ask request from external memory
						state_n = R_KPW; r_request_extmem_n = 1;
						// Update Loop variables
						f_n = f + 1;
						// Update RAM variables
						f_ram_n = f_ram + Nnp[$clog2(FMINT_N_ELEM+1)-1:0];
						// Update Memory variables
						f_mem_n = f_mem + Size_KPW;
					end
				end
				else begin
					// Changing the state & ask request from external memory
					state_n = R_KPW; r_request_extmem_n = 1;
					// Update Loop variables
					x_n = x + 1; tx_n = tx + 1;
					// Update RAM variables
					x_ram_n = x_ram + {{$clog2(FMINT_N_ELEM+1)-1{1'b0}}, 1'b1};
					// Update Memory variables
					x_mem_n = x_mem + 1;
				end
			end

			/* ############################################### */
			// KDW States
			R_KDW: begin
				if(r_valid_extmem) begin
						// Changing the state & load data
						state_n = W_KDW; data_n = data_extmem;
				end
			end
			
			W_KDW: begin
				if (x == Nkx) begin // We change the row 
					x_n = 1; x_ram_n = '0;  x_mem_n = '0;
					if(y == Nky) begin // We change the kernel
						y_n = 1; y_ram_n = '0; y_mem_n = '0;
						if (f == Npar || tx == Nintf) begin // transaction finished after loading Npar weights
							state_n 			 = FINISHED;
						end
						else begin
							// Change state & allow read request
							state_n = R_KDW; r_request_extmem_n = 1;
							// Loop variable	
							f_n = f + 1; tx_n = tx + 1;
							// ram variable
							f_ram_n = f_ram + SIZE_DW_T[$clog2(FMINT_N_ELEM+1)-1: 0];
						// memory variable	
							f_mem_n  = f_mem + SIZE_DW_T;
						end
					end
					else begin
						// Change state & allow read request
						state_n = R_KDW; r_request_extmem_n = 1;
						// Loop variable
						y_n = y + 1;
						// ram variable
						y_ram_n = y_ram + Nky[$clog2(FMINT_N_ELEM+1)-1: 0];
						// memory variable
						y_mem_n = y_mem + Nky;
						
					end
				end
				else begin
					// Change state & allow read request
					state_n = R_KDW; r_request_extmem_n = 1;
					// Loop variable
					x_n = x + 1;
					// ram variable
					x_ram_n = x_ram + {{$clog2(FMINT_N_ELEM+1)-1{1'b0}}, 1'b1};
					// memory variable
					x_mem_n = x_mem + 1;
				end
			end
			
			/* ############################################### */
			// FMO States
			RAM_LOADING: begin
				// Changing the state
				state_n = R_FMO;
			end
			
			R_FMO: begin
				// Changing the state & load data
				state_n = W_FMO; data_n = ram_data_i; 
				// Update RAM addresses 
				if (x == Tox || tx == Nox) begin 
					x_ram_n = '0;
					if(y == Toy || ty == Noy) begin
						y_ram_n = '0;
						if (~(f == Nof)) begin
							f_ram_n  = f_ram + Size_FMO_T[$clog2(FMINT_N_ELEM+1)-1:0];
						end
					end
					else begin
						y_ram_n = y_ram + Tox_T[$clog2(FMINT_N_ELEM+1)-1:0];
					end
				end
				else begin
					x_ram_n = x_ram + {{$clog2(FMINT_N_ELEM+1)-1{1'b0}}, 1'b1};
				end
			end
			
			W_FMO: begin
				// Update next address
				if (x == Tox || tx == Nox) begin 
					x_n = 1; tx_n = tx_mem; x_mem_n = x_ref;
					if(y == Toy || ty == Noy) begin
						y_n = 1; y_mem_n = y_ref; ty_n = ty_mem;
						if (f == Nof) begin
							// Changing the sate
							state_n 			 = FINISHED;
						end
						else begin
							// Changing the state
							state_n = R_FMO;
							// Update loop variables
							f_n = f + 1; 
							// Update memory variables
							f_mem_n  = f_mem + Size_FMO;
						end
					end
					else begin
						// Changing the state
						state_n = R_FMO;
						// Update loop variables
						y_n = y + 1; ty_n = ty + 1;
						// Update memory variables
						y_mem_n = y_mem + Nox;
					end
				end
				else begin
					// Changing the state
					state_n = R_FMO;
					// Update loop variables
					x_n = x + 1; tx_n = tx + 1;
					// Update memory variables
					x_mem_n = x_mem + 1;
				end
			end
		endcase
	end
endmodule
