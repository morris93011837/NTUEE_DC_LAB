// === AudDSP ===
module AudDSP(
	input         i_rst_n,
	input         i_clk,
	input         i_start,
    input         i_pause,
    input         i_stop,
    input  [3:0]  i_speed,
    input         i_fast,
    input         i_slow_0,
    input         i_slow_1,
    input         i_daclrck,
    input signed  [15:0] i_sram_data,
	output signed [15:0] o_dac_data,
	output [19:0] o_sram_addr,
    input         i_opening
);

// parameter
parameter S_IDLE      = 3'd0;
parameter S_PROCESS   = 3'd1;
parameter S_PAUSE     = 3'd2;
parameter S_WAIT_LOW  = 3'd3;
parameter S_WAIT_HIGH = 3'd4;

parameter ADDRESS_MIN = 20'h0;
parameter ADDRESS_MAX = ADDRESS_MIN + 20'h143C0 - 1;
parameter ADDRESS_OPENING = 20'h143C0;
parameter ADDRESS_OPENING_END = 20'd164480 - 1;

// wire & register
logic [2:0]  state, state_next;
logic signed [19:0] dac_data, dac_data_next;
logic [19:0] sram_addr, sram_addr_next;
logic [3:0]  counter, counter_next;
logic signed [19:0] prev_sram_data, prev_sram_data_next;

// wire assignment
assign o_sram_addr = sram_addr;
assign o_dac_data = dac_data;

// combinational logic
always_comb begin
    dac_data_next = dac_data;
    sram_addr_next = sram_addr;
    counter_next = counter;
    prev_sram_data_next = prev_sram_data;

    case (state)
        S_IDLE:begin
            dac_data_next = 21'd0;
            sram_addr_next = ADDRESS_OPENING;
            counter_next = 4'd1;
            prev_sram_data_next = 21'd0;
        end
        S_PROCESS:begin
            if (i_pause) begin
            end
            else if (i_stop) begin
            end
            if (i_fast) begin
                dac_data_next = $signed(i_sram_data);
                if (i_opening) begin
                    if (sram_addr < ADDRESS_OPENING) begin
                        sram_addr_next = ADDRESS_OPENING;
                    end
                    else begin
                        sram_addr_next = (sram_addr + i_speed <= ADDRESS_OPENING_END) ? sram_addr + i_speed : sram_addr;
                    end
                end
                else begin
                    sram_addr_next = (sram_addr + i_speed <= ADDRESS_MAX) ? sram_addr + i_speed : ADDRESS_MIN;
                end
            end
            else if (i_slow_0) begin
                dac_data_next = i_sram_data;
                if (counter == i_speed) begin
                    sram_addr_next = (sram_addr + 1 <= ADDRESS_MAX) ? sram_addr + 1 : ADDRESS_MIN;
                    counter_next = 4'd1;
                end
                else begin
                    sram_addr_next = sram_addr;
                    counter_next = counter + 1;
                end
            end
            else if (i_slow_1) begin
                if (counter == 4'd1) begin
                    dac_data_next = $signed(i_sram_data);
                    sram_addr_next = (sram_addr + 1 <= ADDRESS_MAX) ? sram_addr + 1 : ADDRESS_MIN;
                    counter_next = (counter == i_speed) ? 4'd1 : counter + 1;
                    prev_sram_data_next = i_sram_data;
                end
                else begin
                    dac_data_next = $signed($signed(prev_sram_data) * $signed({1'b0,i_speed-counter+1}) + $signed(i_sram_data) * $signed({1'b0,(counter-1)}) / $signed({1'b0,i_speed}));
                    sram_addr_next = sram_addr;
                    counter_next = (counter == i_speed) ? 4'd1 : counter + 1;
                    prev_sram_data_next = prev_sram_data;
                end
            end
        end
        S_PAUSE:begin
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
            if (i_start) begin
                state_next = S_PROCESS;
            end
        end
        S_PROCESS:begin
            if (i_pause) begin
                state_next = S_PAUSE;
            end
            else if (i_stop) begin
                state_next = S_IDLE;
            end
            else begin
                state_next = S_WAIT_LOW;
            end
        end
        S_PAUSE:begin
            if (i_start) begin
                state_next = S_PROCESS;
            end
            else if (i_stop) begin
                state_next = S_IDLE;
            end
        end
        S_WAIT_LOW:begin
            if (i_pause) begin
                state_next = S_PAUSE;
            end
            else if (i_stop) begin
                state_next = S_IDLE;
            end
            else if (i_daclrck) begin
                state_next = S_WAIT_HIGH;
            end
        end
        S_WAIT_HIGH:begin
            if (i_pause) begin
                state_next = S_PAUSE;
            end
            else if (i_stop) begin
                state_next = S_IDLE;
            end
            else if (!i_daclrck) begin
                state_next = S_PROCESS;
            end
        end
    endcase
end

// sequential logic
always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state          <= S_IDLE;
        dac_data       <= 21'd0;
        sram_addr      <= ADDRESS_OPENING;
        counter        <= 4'd1;
        prev_sram_data <= 21'd0;
	end
	else begin
        state          <= state_next;
        dac_data       <= dac_data_next;
        sram_addr      <= sram_addr_next;
        counter        <= counter_next;
        prev_sram_data <= prev_sram_data_next;
	end
end

endmodule