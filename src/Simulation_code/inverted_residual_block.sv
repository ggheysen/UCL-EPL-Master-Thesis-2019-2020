
module inverted_residual_block(input 	logic clk, rst,
										 input 	logic i_w, i_r, r_valid,
										 input 	logic [15:0] r_value,
										 output 	logic w_valid, r_req,
										 output 	logic [15:0] ram_val,
										 output 	logic [2:0]  adr_val,
										 output 	logic	ffill, fwrite);

	// Internal signals
	typedef enum logic [2:0] {IDLE, FILL, FILL2, WRITE, WRITE2, FFILL, FWRITE} statetype; 
	statetype state, state_n;
	logic [2:0] cnt_r, cnt_w, cnt_r_n, cnt_w_n;
	logic write_e;
	logic [15:0] r_value_r, r_req_n;
	
	//Init modules
	RAM ram1(.clk(clk), .addr(adr_val), .data(r_value_r), .write(write_e), .res(ram_val));
	
	// SEQ LOGIQE
	always_ff @(posedge clk, posedge rst)
		if(rst) begin
			state <= IDLE;
			r_value_r <= '0;
			cnt_r <= '0;
			cnt_w <= '0;
			r_req <= '0;
		end
		else begin
			state <= state_n;
			r_value_r <= r_value;
			cnt_r <= cnt_r_n;
			cnt_w <= cnt_w_n;
			r_req <= r_req_n;	
		end
	
	// COMB LOGIQUE
	assign w_valid = (state == WRITE2);
	assign adr_val = cnt_w;
	assign write_e = (state == FILL2);
	assign fwrite 	= (state == FWRITE);
	assign ffill 	= (state == FFILL);
	
	always_comb begin
		cnt_r_n = cnt_r;
		cnt_w_n = cnt_w;
		state_n = state;
		r_req_n = '0;
		case(state)
			// If no values has changed
			// IDLE state
			
			IDLE: begin
				if(i_r) begin
					state_n = WRITE;
					cnt_r_n = 0;
					cnt_w_n = 0;
				end
				else if (i_w) begin
					state_n = FILL;
					cnt_r_n = 0;
					cnt_w_n = 0;
					r_req_n = 1;
				end
			end
			
			// Fill state
			FILL: begin
				if(r_valid) begin //Wait for data
					state_n = FILL2;
					cnt_r_n = cnt_r + 1;
				end
			end
			
			FILL2: begin
				if(cnt_w == 3'b111) begin
					state_n = FFILL;
				end
				else begin
					cnt_w_n = cnt_w + 1;
					state_n = FILL;
					r_req_n = 1;
				end
			end
			
			FFILL: begin
				state_n = IDLE;
			end
			
			// Write state
			WRITE: begin
					cnt_r_n = cnt_r + 1;
					state_n = WRITE2;
			end
			
			WRITE2:begin
				if(cnt_w == 3'b111) begin
					state_n = FWRITE;
				end 
				else begin
					cnt_w_n = cnt_w + 1;
					state_n = WRITE;
				end
			end
		
			FWRITE: begin
				state_n = IDLE;
			end
			
			// Default state
			default: state_n = IDLE;
		endcase
	end
endmodule
