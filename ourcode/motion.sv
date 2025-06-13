module motion(
    input i_rst_n,
    input i_clk,
    input i_mouse_left,
    input [15:0] i_mouse_x,
    input [15:0] i_mouse_y,
    input i_refresh,
    input i_en_collision,
    input i_collision_done,
    output signed [12:0] o_x_pos,
    output signed [12:0] o_y_pos,
    output o_z_neg
);

logic signed [15:0] x_vel_init, y_vel_init, z_vel_init;

speed init_speed(
    .i_rst_n(i_rst_n),
    .i_clk(i_refresh),
    .i_mouse_left(i_mouse_left),
    .i_mouse_x(i_mouse_x),
    .i_mouse_y(i_mouse_y),
    .i_collision_done(i_collision_done),
    .o_x_vel(x_vel_init),
    .o_y_vel(y_vel_init),
    .o_z_vel(z_vel_init)
);

assign o_x_pos = x_pos >>> 2;
assign o_y_pos = (y_pos + (z_pos >>> 1)) >>> 2;
assign o_z_neg = (z_pos < 0) ? 1 : 0;

parameter signed x_acc = 4'd1;
parameter signed y_acc = 4'd0;
parameter signed z_acc = 4'd3;

logic signed [15:0] x_pos, x_pos_next, x_pos_frame;
logic signed [15:0] y_pos, y_pos_next, y_pos_frame;
logic signed [15:0] z_pos, z_pos_next, z_pos_frame;

logic signed [15:0] x_vel, x_vel_next;
logic signed [15:0] y_vel, y_vel_next;
logic signed [15:0] z_vel, z_vel_next;

logic [5:0] cnt, cnt_next;

always_comb begin
    if (i_refresh) begin
        if (z_pos < 0) begin
            cnt_next = (cnt == 63) ? cnt : cnt + 1;
        end else begin
            cnt_next = 6'd0;
        end
    end else begin
        cnt_next = cnt;
    end
end

always_comb begin
    // x_pos_next = (i_refresh && z_pos >= 0) ? x_pos + x_vel : x_pos;
    // y_pos_next = (i_refresh && z_pos >= 0) ? y_pos + y_vel : y_pos;
    // z_pos_next = (i_refresh && z_pos >= 0) ? z_pos + z_vel : z_pos;
    // x_vel_next = (i_refresh && z_pos >= 0) ? x_vel - x_acc : x_vel;
    // y_vel_next = (i_refresh && z_pos >= 0) ? y_vel - y_acc : y_vel;
    // z_vel_next = (i_refresh && z_pos >= 0) ? z_vel - z_acc : z_vel;

    x_pos_next = (!i_refresh) ? x_pos :
                  (z_pos >= 0) ? x_pos + x_vel :
                  (cnt < 60) ? x_pos :
                  (i_en_collision) ? x_pos : 16'd0;
    y_pos_next = (!i_refresh) ? y_pos :
                  (z_pos >= 0) ? y_pos + y_vel :
                  (cnt < 60) ? y_pos :
                  (i_en_collision) ? y_pos : 16'd0;
    z_pos_next = (!i_refresh) ? z_pos :
                  (z_pos >= 0) ? z_pos + z_vel :
                  (cnt < 60) ? z_pos :
                  (i_en_collision) ? z_pos : 16'd0;
    x_vel_next = (!i_refresh) ? x_vel :
                  (z_pos >= 0) ? x_vel - x_acc :
                  (cnt < 60) ? x_vel :
                  (i_en_collision) ? x_vel : 16'd0;
    y_vel_next = (!i_refresh) ? y_vel :
                  (z_pos >= 0) ? y_vel - y_acc :
                  (cnt < 60) ? y_vel :
                  (i_en_collision) ? y_vel : 16'd0;
    z_vel_next = (!i_refresh) ? z_vel :
                  (z_pos >= 0) ? z_vel - z_acc :
                  (cnt < 60) ? z_vel :
                  (i_en_collision) ? z_vel : 16'd0;
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        cnt <= 6'd0;
    end else begin
        cnt <= cnt_next;
    end
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        x_pos <= 16'd0;
        y_pos <= 16'd0;
        z_pos <= 16'd0;
        x_vel <= x_vel_init;
        y_vel <= y_vel_init;
        z_vel <= z_vel_init; // 90
    end 
    else if (i_mouse_left) begin
        x_pos <= $signed(i_mouse_x) - 16'sd1590;
        y_pos <= 16'd0;
        z_pos <= 16'd0;
        x_vel <= x_vel_init;
        y_vel <= y_vel_init;
        z_vel <= z_vel_init; // 90
    end
    else if (i_collision_done) begin
        x_pos <= 16'd0;
        y_pos <= 16'd0;
        z_pos <= 16'd0;
        x_vel <= 16'd0;
        y_vel <= 16'd0;
        z_vel <= 16'd0;
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

// always_ff @(posedge i_refresh or negedge i_rst_n) begin
//     if (!i_rst_n) begin
//         x_pos_frame <= 16'd0;
//         y_pos_frame <= 16'd0;
//         z_pos_frame <= 16'd0;
//     end 
//     else if (i_mouse_left && i_collision_done) begin
//         x_pos_frame <= 16'd0;
//         y_pos_frame <= 16'd0;
//         z_pos_frame <= 16'd0;
//     end
//     else begin
//         x_pos_frame <= x_pos;
//         y_pos_frame <= y_pos;
//         z_pos_frame <= z_pos;
//     end
// end

endmodule
