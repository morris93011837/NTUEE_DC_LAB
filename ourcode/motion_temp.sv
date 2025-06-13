module motion(
    input i_rst_n,
    input i_clk,

    input i_refresh,
    output [12:0] o_x_pos,
    output [12:0] o_y_pos
);

assign o_x_pos = x_pos >>> 2;
assign o_y_pos = (y_pos + (z_pos >>> 1)) >>> 2;

parameter signed x_acc = 4'd1;
parameter signed y_acc = 4'd0;
parameter signed z_acc = 4'd3;

logic signed [15:0] x_pos, x_pos_next;
logic signed [15:0] y_pos, y_pos_next;
logic signed [15:0] z_pos, z_pos_next;

logic signed [7:0] x_vel, x_vel_next;
logic signed [7:0] y_vel, y_vel_next;
logic signed [7:0] z_vel, z_vel_next;

always_comb begin
    x_pos_next = (i_refresh && z_pos >= 0) ? x_pos + x_vel : x_pos;
    y_pos_next = (i_refresh && z_pos >= 0) ? y_pos + y_vel : y_pos;
    z_pos_next = (i_refresh && z_pos >= 0) ? z_pos + z_vel : z_pos;
    x_vel_next = (i_refresh && z_pos >= 0) ? x_vel - x_acc : x_vel;
    y_vel_next = (i_refresh && z_pos >= 0) ? y_vel - y_acc : y_vel;
    z_vel_next = (i_refresh && z_pos >= 0) ? z_vel - z_acc : z_vel;
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        x_pos <= 8'd0;
        y_pos <= 8'd0;
        z_pos <= 8'd0;
        x_vel <= 8'd30;
        y_vel <= 8'd20;
        z_vel <= 8'd90;
    end 
    else begin
        x_pos <= x_pos_next;
        y_pos <= y_pos_next;
        z_pos <= z_pos_next;
        x_vel <= x_vel_next;
        y_vel <= y_vel_next;
        z_vel <= z_vel_next;
    end
end

endmodule