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
    input signed [12:0] i_h_count,
    input signed [12:0] i_v_count,

    // input [12:0] i_h_min,
    // input [12:0] i_h_max,
    // input [12:0] i_v_min,
    // input [12:0] i_v_max,

    // image address
    inout [15:0] io_sram_data,
    output [19:0] o_sram_address,

    // switches
    input [17:0] i_sw,

    // restart signals
    input i_restart,
    output o_restart,

    // mouse control
    input i_mouse_left,
    input i_mouse_right,
    input i_mouse_middle,
    input [15:0] i_mouse_x,
    input [15:0] i_mouse_y
);

//	Horizontal Parameter	( Pixel )
parameter	signed H_SYNC_CYC	=	128;
parameter	signed H_SYNC_BACK	=	88;
parameter	signed H_SYNC_ACT	=	800;	
parameter	signed H_SYNC_FRONT=	40;
parameter	signed H_SYNC_TOTAL=	1056;
//	Vertical Parameter		( Line )
parameter	signed V_SYNC_CYC	=	4;
parameter	signed V_SYNC_BACK	=	23;
parameter	signed V_SYNC_ACT	=	600;	
parameter	signed V_SYNC_FRONT=	1;
parameter	signed V_SYNC_TOTAL=	628;

//	Start Offset
parameter	signed X_START		=	H_SYNC_CYC+H_SYNC_BACK;
parameter	signed Y_START		=	V_SYNC_CYC+V_SYNC_BACK;

logic refresh, after_refresh;

logic [2:0] random_pokemon;
logic en_badge, en_logo;
logic en_pokemon, en_ball, en_mouse, en_collision;
logic detected, anime_pokemon, anime_ball, collision_done, capture_now;
logic capture [0:6];

logic [19:0] sram_address_pokemon1, sram_address_pokemon2, sram_address_ball, sram_address_ball0, sram_address_ball30, sram_address_badge, sram_address_logo;
logic [31:0] q_pokemon, q_pokemon1, q_pokemon2, q_ball, q_ball0, q_ball30, q_badge, q_logo;

logic signed [12:0] delta_x, delta_y;
logic z_neg;

logic circle;
logic signed [7:0] x_radius, y_radius;
logic signed [17:0] radius_square;
// logic signed [7:0] min, max;
// logic signed [16:0] approx;

logic [9:0] red, green, blue;
logic [5:0] sample_rate;

assign refresh = (i_h_count == 0 && i_v_count == 0);
assign after_refresh = (i_h_count == 0 && i_v_count == 1);
assign o_restart = (capture[1] && capture[2] && capture[3] && capture[4] && capture[5] && capture[6]);

// assign en_badge[0] = 1'b0;
// assign en_badge[1] = (i_h_count >= X_START && i_h_count < X_START + 13'sd100 &&
//                 i_v_count >= Y_START + 13'sd000 && i_v_count < Y_START + 13'sd100 ) ? 1 : 0;
// assign en_badge[2] = (i_h_count >= X_START && i_h_count < X_START + 13'sd100 &&
//                 i_v_count >= Y_START + 13'sd100 && i_v_count < Y_START + 13'sd200 ) ? 1 : 0;
// assign en_badge[3] = (i_h_count >= X_START && i_h_count < X_START + 13'sd100 &&
//                 i_v_count >= Y_START + 13'sd200 && i_v_count < Y_START + 13'sd300 ) ? 1 : 0;
// assign en_badge[4] = (i_h_count >= X_START && i_h_count < X_START + 13'sd100 &&
//                 i_v_count >= Y_START + 13'sd300 && i_v_count < Y_START + 13'sd400 ) ? 1 : 0;
// assign en_badge[5] = (i_h_count >= X_START && i_h_count < X_START + 13'sd100 &&
//                 i_v_count >= Y_START + 13'sd400 && i_v_count < Y_START + 13'sd500 ) ? 1 : 0;
// assign en_badge[6] = (i_h_count >= X_START && i_h_count < X_START + 13'sd100 &&
//                 i_v_count >= Y_START + 13'sd500 && i_v_count < Y_START + 13'sd600 ) ? 1 : 0;

assign en_badge = (i_h_count >= X_START && i_h_count < X_START + 13'sd100 &&
                i_v_count >= Y_START && i_v_count < Y_START + 13'sd600 ) ? 1 : 0;
assign en_logo = (i_h_count >= X_START + 13'sd695 && i_h_count < X_START + 13'sd795 &&
                i_v_count >= Y_START && i_v_count < Y_START + 13'sd100 ) ? 1 : 0;

assign en_ball = (i_h_count >= X_START + delta_x + 13'sd300 && i_h_count < X_START + delta_x + 13'sd500 &&
                i_v_count >= Y_START - delta_y + 13'sd400 && i_v_count < Y_START - delta_y + 13'sd600 ) ? 1 : 0;
assign en_mouse = (i_h_count >= X_START + i_mouse_x[11:2] && i_h_count < X_START + i_mouse_x[11:2] + 10 &&
                i_v_count >= Y_START + (590 - i_mouse_y[11:2]) && i_v_count < Y_START + (590 - i_mouse_y[11:2]) + 10) ? 1 : 0;

assign x_radius = (i_h_count >= X_START + delta_x + 13'sd400) ? (i_h_count - (X_START + delta_x + 13'sd400)) : ((X_START + delta_x + 13'sd400) - i_h_count);
assign y_radius = (i_v_count >= Y_START - delta_y + 13'sd500) ? (i_v_count - (Y_START - delta_y + 13'sd500)) : ((Y_START - delta_y + 13'sd500) - i_v_count);
// assign min = (x_radius < y_radius) ? x_radius : y_radius;
// assign max = (x_radius >= y_radius) ? x_radius : y_radius;
// assign approx = (max<<<7) + (max<<<2) - (max<<<3) - max + (min<<<6) - (min<<<4) + (min<<<2) - min;
// assign circle = en_ball ? ( approx <= 17'sd11008 ) : 0; // radius approximation

assign radius_square = x_radius * x_radius + y_radius * y_radius;
assign circle = en_ball ? (radius_square <= 7400) : 0;

assign capture_now = (i_v_count >= Y_START + 13'sd000 && i_v_count < Y_START + 13'sd100) ? capture[1] :
                     (i_v_count >= Y_START + 13'sd100 && i_v_count < Y_START + 13'sd200) ? capture[2] :
                     (i_v_count >= Y_START + 13'sd200 && i_v_count < Y_START + 13'sd300) ? capture[3] :
                     (i_v_count >= Y_START + 13'sd300 && i_v_count < Y_START + 13'sd400) ? capture[4] :
                     (i_v_count >= Y_START + 13'sd400 && i_v_count < Y_START + 13'sd500) ? capture[5] :
                     (i_v_count >= Y_START + 13'sd500 && i_v_count < Y_START + 13'sd600) ? capture[6] : 
                     capture[0];

assign io_sram_data = 16'dz; // Always input (high z)
assign o_sram_address = (en_badge && capture_now) ? sram_address_badge :
                        (en_logo) ? sram_address_logo :
                        (en_collision) ? ((anime_ball) ? sram_address_ball0 : sram_address_ball30) :
                                         ((circle) ? sram_address_ball : (anime_pokemon) ? sram_address_pokemon1 : sram_address_pokemon2);
assign q_pokemon = (anime_pokemon) ? q_pokemon1 : q_pokemon2;

assign o_red   = (en_mouse) ? {8'hFF,2'b00} :
                (en_badge && capture_now) ? {q_badge[31:24],2'b00} :
                (en_logo && q_logo[7]) ? {q_logo[31:24],2'b00} :
                (en_collision) ? ((!circle) ? i_red :
                ((anime_ball) ? {q_ball0[31:24],2'b00} : {q_ball30[31:24],2'b00})) :
                (circle) ? {q_ball[31:24],2'b00} : 
                (en_pokemon && q_pokemon[7]) ? {q_pokemon[31:24],2'b00} : 
                i_red;
assign o_green = (en_mouse) ? {8'hFF,2'b00} :
                (en_badge && capture_now) ? {q_badge[23:16],2'b00} :
                (en_logo && q_logo[7]) ? {q_logo[23:16],2'b00} :
                (en_collision) ? ((!circle) ? i_green :
                ((anime_ball) ? {q_ball0[23:16],2'b00} : {q_ball30[23:16],2'b00})) :
                (circle) ? {q_ball[23:16],2'b00} :
                (en_pokemon && q_pokemon[7]) ? {q_pokemon[23:16],2'b00} :
                i_green;
assign o_blue  = (en_mouse) ? {8'hFF,2'b00} :
                (en_badge && capture_now) ? {q_badge[15:8],2'b00} :
                (en_logo && q_logo[7]) ? {q_logo[15:8],2'b00} :
                (en_collision) ? ((!circle) ? i_blue :
                ((anime_ball) ? {q_ball0[15:8],2'b00} : {q_ball30[15:8],2'b00})) :
                (circle) ? {q_ball[15:8],2'b00} :
                (en_pokemon && q_pokemon[7]) ? {q_pokemon[15:8] ,2'b00} :
                i_blue;

// assign sample_rate = (i_sw[10:5]) ? i_sw[10:5] : 1;
// downsample2D DD(
//     .i_rst_n(i_rst_n),
//     .i_clk(i_clk),
//     .i_refresh(refresh),
//     .i_sample_rate(sample_rate),
//     .i_red(i_red),
//     .i_green(i_green),
//     .i_blue(i_blue),
//     .o_red(red),
//     .o_green(green),
//     .o_blue(blue)
// );

random random (
    .i_clk(i_clk),
    .i_rst_n(i_rst_n),
    .i_start((!en_collision && detected) || collision_done),
    .o_random_out(random_pokemon)
);

memory memory (
    .i_rst_n(i_rst_n),
    .i_clk(i_clk),
    .i_restart(i_restart),
    .i_refresh(refresh),
    .i_random(random_pokemon),
    .i_capture(collision_done),
    .o_capture(capture)
);

image badge (
    .i_rst_n(i_rst_n),
    .i_clk(i_clk),
    .i_refresh(refresh),
    .i_en(en_badge),
    .i_address(20'hB98C0),
    .io_sram_data(io_sram_data),
    .o_sram_address(sram_address_badge),
    .o_q(q_badge)
);

image logo (
    .i_rst_n(i_rst_n),
    .i_clk(i_clk),
    .i_refresh(refresh),
    .i_en(en_logo),
    .i_address(20'hC8320),
    .io_sram_data(io_sram_data),
    .o_sram_address(sram_address_logo),
    .o_q(q_logo)
);

green_detect green_detect (
    .i_rst_n(i_rst_n),
    .i_clk(i_clk),
    .i_refresh(refresh),
    .i_red(i_red),
    .i_green(i_green),
    .i_blue(i_blue),
    .i_h_count(i_h_count),
    .i_v_count(i_v_count),
    .o_en_pokemon(en_pokemon),
    .o_detected(detected),
    .o_anime_pokemon(anime_pokemon)
);

image pokemon1 (
    .i_rst_n(i_rst_n),
    .i_clk(i_clk),
    .i_refresh(refresh),
    .i_en(en_pokemon),
    .i_address(280000 + 80000 * random_pokemon),
    .io_sram_data(io_sram_data),
    .o_sram_address(sram_address_pokemon1),
    .o_q(q_pokemon1)
);

image pokemon2 (
    .i_rst_n(i_rst_n),
    .i_clk(i_clk),
    .i_refresh(refresh),
    .i_en(en_pokemon),
    .i_address(320000 + 80000 * random_pokemon),
    .io_sram_data(io_sram_data),
    .o_sram_address(sram_address_pokemon2),
    .o_q(q_pokemon2)
);

motion motion (
    .i_rst_n(i_rst_n), // i_motion
    .i_clk(i_clk),
    .i_mouse_left(i_mouse_left && !en_collision),
    .i_mouse_x(i_mouse_x[11:0]),
    .i_mouse_y(i_mouse_y[11:0]),
    .i_refresh(refresh),
    .i_en_collision(en_collision),
    .i_collision_done(collision_done),
    .o_x_pos(delta_x),
    .o_y_pos(delta_y),
    .o_z_neg(z_neg)
);

rotation ball (
    .i_rst_n(i_rst_n),
    .i_clk(i_clk),
    .i_refresh(after_refresh),
    .i_en(en_ball),
    .i_address(40000),
    .i_h_count(i_h_count),
    .i_bias(delta_y - 13'sd400 - Y_START),
    .io_sram_data(io_sram_data),
    .o_sram_address(sram_address_ball),
    .o_q(q_ball)
);

ball ball0 (
    .i_rst_n(i_rst_n),
    .i_clk(i_clk),
    .i_refresh(refresh),
    .i_en(en_ball),
    .i_bias(delta_y - 13'sd400 - Y_START),
    .i_address(40000),
    .io_sram_data(io_sram_data),
    .o_sram_address(sram_address_ball0),
    .o_q(q_ball0)
);

ball ball30 (
    .i_rst_n(i_rst_n),
    .i_clk(i_clk),
    .i_refresh(refresh),
    .i_en(en_ball),
    .i_bias(delta_y - 13'sd400 - Y_START),
    .i_address(80000),
    .io_sram_data(io_sram_data),
    .o_sram_address(sram_address_ball30),
    .o_q(q_ball30)
);

collision collision (
    .i_rst_n(i_rst_n),
    .i_clk(i_clk),
    .i_refresh(refresh),
    .i_en_pokemon(en_pokemon),
    .i_en_ball(en_ball),
    .i_z_neg(z_neg),
    .o_anime_ball(anime_ball),
    .o_en_collision(en_collision),
    .o_collision_done(collision_done)
);

endmodule