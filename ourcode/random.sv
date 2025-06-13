module random (
	input        i_clk,
	input        i_rst_n,
	input        i_start,
	output [2:0] o_random_out
);

// ===== Output Buffers =====
logic [2:0] out, out_next;
logic [2:0] counter, counter_next;

// ===== Output Assignments =====
assign o_random_out = (out >= 3'd5) ? 3'd5 : out; // Limit the output to a maximum of 5

// ===== Combinational Circuits =====
always_comb begin
	// Default Values
    counter_next = (i_start) ? counter : counter + 1;
    out_next = out;
    if (i_start) begin
        out_next = counter;
    end
end

// ===== Sequential Circuits =====
always_ff @(posedge i_clk or negedge i_rst_n) begin
	// reset
	if (!i_rst_n) begin
		out <= 3'd0;
        counter <= 3'd0;
	end
	else begin
		out <= out_next;
        counter <= counter_next;
	end
end

endmodule