// === AudPlayer ===
module AudPlayer(
	input         i_rst_n,
	input         i_bclk,
	input         i_daclrck,
	input         i_en,
	input [15:0]  i_dac_data,
	output        o_aud_dacdat

    // output [1:0]  o_state,
    // output [3:0]  o_index
);

// parameter
parameter S_IDLE      = 2'd0;
parameter S_PROCESS   = 2'd1;
parameter S_WAIT_HIGH = 2'd2;
parameter S_WAIT_LOW  = 2'd3;

// wire & register
logic [1:0] state, state_next;
logic [3:0] index, index_next;

// wire assignment
assign o_aud_dacdat = (state == S_PROCESS) ? i_dac_data[index] : 1'b0;

// assign o_state = state;
// assign o_index = index;

// combinational logic
always_comb begin
    index_next = index;
    
    case (state)
        S_IDLE:begin
        end
        S_PROCESS:begin
            if (index == 4'd0) begin
                index_next = 4'd15;
            end
            else begin
                index_next = index - 1;
            end
        end
        S_WAIT_LOW:begin
        end
        S_WAIT_HIGH:begin
        end
    endcase
end

// FSM state transition
always_comb begin
    state_next = state;
    case (state)
        S_IDLE:begin
            if (i_en && i_daclrck) begin
                state_next = S_PROCESS;
            end
        end
        S_PROCESS:begin
            if (index == 4'd0) begin
                state_next = S_WAIT_HIGH;
            end
        end
        S_WAIT_HIGH:begin
            if (!i_daclrck) begin
                state_next = S_WAIT_LOW;
            end
        end
        S_WAIT_LOW:begin
            if (i_daclrck) begin
                if (i_en) begin
                    state_next = S_PROCESS;
                end
                else begin
                    state_next = S_IDLE;
                end
            end
        end
    endcase
end

// sequential logic
always_ff @(negedge i_bclk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state <= S_IDLE;
        index <= 4'd15;
	end
	else begin
        state <= state_next;
        index <= index_next;
	end
end

endmodule