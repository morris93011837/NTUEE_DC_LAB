// === I2cInitializer ===
module I2cInitializer(
	input i_rst_n,
	input i_clk,
	input i_start,
	output o_finished,
	output o_sclk,
	inout  o_sdat,
	output o_oen
);

// wire command
logic [23:0] COMM [0:9];
assign COMM[0] = 24'b0011_0100_000_0000_0_1001_0111; // Left Line in
assign COMM[1] = 24'b0011_0100_000_0001_0_1001_0111; // Right Line in
assign COMM[2] = 24'b0011_0100_000_0010_0_0111_1001; // Left Headphone out
assign COMM[3] = 24'b0011_0100_000_0011_0_0111_1001; // Right Headphone out
assign COMM[4] = 24'b0011_0100_000_0100_0_0001_0101; // Analogue Audio Path Control
assign COMM[5] = 24'b0011_0100_000_0101_0_0000_0000; // Digital Audio Path Control
assign COMM[6] = 24'b0011_0100_000_0110_0_0000_0000; // Power Down Control
assign COMM[7] = 24'b0011_0100_000_0111_0_0100_0010; // Digital Audio Interface Control
assign COMM[8] = 24'b0011_0100_000_1000_0_0001_1001; // Sampling Control
assign COMM[9] = 24'b0011_0100_000_1001_0_0000_0001; // Active Control

// wire & register
logic [2:0] state, state_next;
logic [4:0] counter, counter_next; // count from 0 to 23
logic [4:0] COMcnt, COMcnt_next; // count from 0 to 9
logic       sclk, sclk_next;
logic       stop, stop_next;
logic [3:0] waiter, waiter_next;
logic       data;

// === FSM ===
parameter S_IDLE  = 3'd0;
parameter S_START = 3'd1;
parameter S_DATA  = 3'd2;
parameter S_ACK   = 3'd3;
parameter S_READY = 3'd4;
parameter S_STOP  = 3'd5;
parameter S_WAIT  = 3'd6;

// wire assignment
assign data   = (state == S_IDLE | state == S_START | state == S_STOP | state == S_WAIT) ? stop : COMM[COMcnt][23 - counter];
//assign o_sdat = (state == S_IDLE | state == S_START | state == S_STOP | state == S_WAIT) ? stop : ((o_oen) ? COMM[COMcnt][23 - counter] : 1'bz); // sdat is output when o_oen is high
assign o_sdat = (o_oen) ? data : 1'bz;
assign o_oen  = (state == S_ACK || state == S_READY) ? 1'b0 : 1'b1; // sdat is input when state is ACK
assign o_sclk = sclk; // sclk is output when state is not ACK
assign o_finished = (COMcnt == 5'd10);

// combinational logic
always_comb begin
	sclk_next = sclk;
	counter_next = counter;
	COMcnt_next = COMcnt;
	stop_next = stop;
    waiter_next = waiter;
	case(state)
		S_IDLE: begin
			sclk_next = 1'b1; // start condition
			if(i_start & !o_finished) stop_next = 1'b0; // start condition
		end
		S_START: begin
			sclk_next = 1'b0;
			counter_next = 5'd0;
		end
		S_DATA: begin
			sclk_next = ~sclk; // toggle sclk
			counter_next = (sclk) ? counter + 1 : counter; // increment counter on sclk falling edge
		end
		S_ACK: begin
			// at this state counter is 8's multiple
			sclk_next = ~sclk; // toggle sclk
			if (sclk) begin
				//counter_next = (o_sdat == 1'b0) ? counter : counter - 8'd8; // increment counter on sclk falling edge
                sclk_next = sclk;
            counter_next = counter;
			end
		end
        S_READY: begin
            sclk_next = ~sclk;
		end
		S_STOP: begin
			sclk_next = 1'b1;
			counter_next = 5'd0;
            if (sclk) begin
                COMcnt_next = COMcnt + 1; 
            end
			stop_next = (sclk) ? 1'b1 : 1'b0; // stop condition
		end
        S_WAIT: begin
            sclk_next = 1'b1;
            counter_next = 5'd0;
            stop_next = 1'b1;
            waiter_next = (waiter == 4'd15) ? 4'd0 : waiter + 1;
        end
		default: begin
			sclk_next = sclk;
			counter_next = counter;
			COMcnt_next = COMcnt;
		end
	endcase
end

// FSM state transition
always_comb begin
	state_next = state;
	case(state)
		S_IDLE: begin
			if (i_start & !o_finished) begin
				state_next = S_START;
			end
		end
		S_START: begin
			state_next = S_DATA;
		end
		S_DATA: begin
			if (sclk & counter[2:0] == 5'd7) state_next = S_ACK; // 8 bits data sent
		end
		S_ACK: begin
			if(~sclk) state_next = S_ACK; // wait for ACK
			// else if (o_sdat == 1'b0 & counter == 5'd24) state_next = S_STOP;
			// else if (counter == 5'd24) state_next = S_STOP;
			// else state_next = S_DATA; 
            else state_next = S_READY;
		end
        S_READY: begin
            if (counter == 5'd24) state_next = S_STOP;
			// else if (counter == 5'd24) state_next = S_STOP;
			else state_next = S_DATA; 
        end 
		S_STOP: begin
			if (sclk) state_next = S_WAIT; // stop condition
			else state_next = S_STOP;
		end
        S_WAIT: begin
            if (waiter == 4'd15) begin
                state_next = S_IDLE;
            end
        end
		default: state_next = S_IDLE;
	endcase
end


// sequential logic
always_ff @(posedge i_clk or negedge i_rst_n) begin
	if (!i_rst_n) begin
		state <= S_IDLE;
		counter <= 5'd0;
		COMcnt <= 5'd0;
		sclk <= 1'b1;
		stop <= 1'b1;
        waiter <= 4'd0;
	end
	else begin
		state <= state_next;
		counter <= counter_next;
		COMcnt <= COMcnt_next;
		sclk <= sclk_next;
		stop <= stop_next;
        waiter <= waiter_next;
	end
end

endmodule