module display(
    input i_rst_n,
    input i_clk,

    // VGA input output
    input [9:0] i_red,
    input [9:0] i_green,
    input [9:0] i_blue,
    output [9:0] o_red,
    output [9:0] o_green,
    output [9:0] o_blue,

    // VGA control
    input [12:0] i_h_count,
    input [12:0] i_v_count,

    // motion control
    input i_motion_n,

    // input [12:0] i_h_min,
    // input [12:0] i_h_max,
    // input [12:0] i_v_min,
    // input [12:0] i_v_max,

    // image address
    inout [15:0] io_sram_data,
    output [19:0] o_sram_address,

    // swutches
    input [17:0] i_sw,

    // mouse control
    input i_mouse_left,
    input i_mouse_right,
    input i_mouse_middle,
    input [15:0] i_mouse_x,
    input [15:0] i_mouse_y
);

//	Horizontal Parameter	( Pixel )
parameter	H_SYNC_CYC	=	128;
parameter	H_SYNC_BACK	=	88;
parameter	H_SYNC_ACT	=	800;	
parameter	H_SYNC_FRONT=	40;
parameter	H_SYNC_TOTAL=	1056;
//	Vertical Parameter		( Line )
parameter	V_SYNC_CYC	=	4;
parameter	V_SYNC_BACK	=	23;
parameter	V_SYNC_ACT	=	600;	
parameter	V_SYNC_FRONT=	1;
parameter	V_SYNC_TOTAL=	628;

//	Start Offset
parameter	X_START		=	H_SYNC_CYC+H_SYNC_BACK;
parameter	Y_START		=	V_SYNC_CYC+V_SYNC_BACK;

logic refresh;
logic en_pokemon, en_ball, en_mouse;
logic [19:0] sram_address_pokemon, sram_address_ball;
logic [31:0] q_pokemon, q_ball;
logic box, green_detected, green_detected_next;
logic [15:0] green_cnt, green_cnt_next;
logic [12:0] delta_x, delta_y;
logic circle;
logic [6:0] x_radius, y_radius;
logic [14:0] radius_square;

logic [9:0] red, green, blue;

logic [5:0] sample_rate;

assign refresh = (i_h_count == 0 && i_v_count == 0) ? 1 : 0;
assign box = (i_h_count >= X_START + 300 && i_h_count < X_START + 500 &&
                i_v_count >= Y_START + 100 && i_v_count < Y_START + 300) ? 1 : 0;
assign en_pokemon = box & green_detected;
assign en_ball = (i_h_count >= X_START + delta_x + 300 && i_h_count < X_START + delta_x + 500 &&
                i_v_count >= Y_START - delta_y + 400 && i_v_count < Y_START - delta_y + 600) ? 1 : 0;
assign en_mouse = (i_h_count >= X_START + i_mouse_x[11:2] && i_h_count < X_START + i_mouse_x[11:2] + 10 &&
                i_v_count >= Y_START + (590 - i_mouse_y[11:2]) && i_v_count < Y_START + (590 - i_mouse_y[11:2]) + 10) ? 1 : 0;

assign o_red   = (en_mouse) ? {8'hFF,2'b00} :
                (circle) ? {q_ball[31:24],2'b00} : 
                (en_pokemon && q_pokemon[7]) ? {q_pokemon[31:24],2'b00} : 
                i_red;
assign o_green = (en_mouse) ? {8'hFF,2'b00} :
                (circle) ? {q_ball[23:16],2'b00} :
                (en_pokemon && q_pokemon[7]) ? {q_pokemon[23:16],2'b00} :
                i_green;
assign o_blue  = (en_mouse) ? {8'hFF,2'b00} :
                (circle) ? {q_ball[15:8],2'b00} :
                (en_pokemon && q_pokemon[7]) ? {q_pokemon[15:8] ,2'b00} :
                i_blue;

assign x_radius = (i_h_count >= X_START + delta_x + 400) ? (i_h_count - (X_START + delta_x + 400)) : ((X_START + delta_x + 400) - i_h_count);
assign y_radius = (i_v_count >= Y_START - delta_y + 500) ? (i_v_count - (Y_START - delta_y + 500)) : ((Y_START - delta_y + 500) - i_v_count);
assign radius_square = x_radius * x_radius + y_radius * y_radius;
assign circle = en_ball ? (radius_square <= 7400) : 0;
            
assign io_sram_data = 16'dz; // Always input (high z)
assign o_sram_address = (circle) ? sram_address_ball : sram_address_pokemon;

// assign sample_rate = (i_sw[10:5]) ? i_sw[10:5] : 1;
// downsample2D DD(
//     .i_rst_n(i_rst_n),
//     .i_clk(i_clk),
//     .i_refresh(refresh),
//     .i_sample_rate(sample_rate),
//     .i_red(i_red),
// 	.i_green(i_green),
// 	.i_blue(i_blue),
// 	.o_red(red),
// 	.o_green(green),
// 	.o_blue(blue)
// );

image pokemon(
    .i_rst_n(i_rst_n),
    .i_clk(i_clk),
    .i_refresh(refresh),
    .i_en(en_pokemon),
    .i_address(0),
    .io_sram_data(io_sram_data),
    .o_sram_address(sram_address_pokemon),
    .o_q(q_pokemon)
);

ball ball (
    .i_rst_n(i_rst_n),
    .i_clk(i_clk),
    .i_refresh(refresh),
    .i_en(en_ball),
    .i_address(40000),
    .io_sram_data(io_sram_data),
    .o_sram_address(sram_address_ball),
    .o_q(q_ball)
);

motion motion(
    .i_rst_n(~i_mouse_left), // i_motion
    .i_clk(i_clk),
    .i_refresh(refresh),
    .o_x_pos(delta_x),
    .o_y_pos(delta_y)
);

always_comb begin
    if (refresh) begin
        green_detected_next = (green_cnt >= 5000);
        green_cnt_next = 0;
    end
    else begin
        green_detected_next = green_detected;
        green_cnt_next = (box & (i_green[9:2] >= 80) & (i_red[9:2] < 128) & (i_blue[9:2] < 128)) ? green_cnt + 1 : green_cnt;
    end
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        green_detected <= 0;
        green_cnt      <= 0;
    end 
    else begin
        green_detected <= green_detected_next;
        green_cnt      <= green_cnt_next;
    end
end

endmodule