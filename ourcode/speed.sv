module speed(
    input i_rst_n,
    input i_clk,
    input i_mouse_left,
    input [15:0] i_mouse_x,
    input [15:0] i_mouse_y,
    input i_collision_done,
    output signed [15:0] o_x_vel,
    output signed [15:0] o_y_vel,
    output signed [15:0] o_z_vel
);

logic [1:0] cnt, cnt_next;
logic [31:0] shift_x_pos, shift_x_pos_next;
logic [31:0] shift_y_pos, shift_y_pos_next;

assign o_x_vel = ($signed(shift_x_pos[15:0]) - $signed(shift_x_pos[31:16])) >>> 0;
assign o_y_vel = ($signed(shift_y_pos[15:0]) - $signed(shift_y_pos[31:16])) >>> 1;
assign o_z_vel = ($signed(shift_y_pos[15:0]) - $signed(shift_y_pos[31:16])) <<< 1;

always_comb begin
    if (cnt == 0) begin
        shift_x_pos_next = (i_mouse_left) ? {shift_x_pos[15:0], i_mouse_x} : shift_x_pos;
        shift_y_pos_next = (i_mouse_left) ? {shift_y_pos[15:0], i_mouse_y} : shift_y_pos;
    end
    else begin
        shift_x_pos_next = shift_x_pos;
        shift_y_pos_next = shift_y_pos;
    end
end

always_comb begin
    cnt_next = cnt + 1;
end



always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        shift_x_pos <= 0;
        shift_y_pos <= 0;
        cnt         <= 0;
    end
    else if (i_collision_done) begin
        shift_x_pos <= 0;
        shift_y_pos <= 0;
        cnt         <= 0;
    end
    else begin
        shift_x_pos <= shift_x_pos_next;
        shift_y_pos <= shift_y_pos_next;
        cnt         <= cnt_next;
    end
end

endmodule