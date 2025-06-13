module memory(
    input i_rst_n,
    input i_clk,
    input i_refresh,
    input i_restart,
    input [2:0] i_random,
    input i_capture,
    output o_capture[0:6]
);

logic capture_next[0:6], capture[0:6];
logic [2:0] random, random_next;
integer i;
assign o_capture[0] = capture[0];
assign o_capture[1] = capture[1];
assign o_capture[2] = capture[2];
assign o_capture[3] = capture[3];
assign o_capture[4] = capture[4];
assign o_capture[5] = capture[5];
assign o_capture[6] = capture[6];

always_comb begin
    random_next = random;
    for (i=0; i<=6; i=i+1) begin
        capture_next[i] = capture[i];
    end
    if (i_refresh) begin
        random_next = i_random;
        if (i_capture) begin
            capture_next[random + 1] = 1'b1;
        end
    end
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        random <= 3'd0;
        for (i=0; i<=6; i=i+1) begin
            capture[i] <= 1'b0;
        end
    end 
    else if (i_restart) begin
        random <= 3'd0;
        for (i=0; i<=6; i=i+1) begin
            capture[i] <= 1'b0;
        end
    end
    else begin
        random <= random_next;
        for (i=0; i<=6; i=i+1) begin
            capture[i] <= capture_next[i];
        end
    end
end

endmodule