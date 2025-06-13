module Top (
	input i_rst_n,
	input i_clk,
	input i_key_1,
	input i_key_2,
	input [3:0] i_speed, // design how user can decide mode on your own
    input i_fast,
    input i_slow_0,
    input i_slow_1,
	
	// AudDSP and ROM
	output [19:0] o_ROM_ADDR,
	input  [15:0] i_ROM_DATA,
	// output [19:0] o_SRAM_ADDR,
	// inout  [15:0] io_SRAM_DQ,
	
	// I2C
	input  i_clk_100k,
	output o_I2C_SCLK,
	inout  io_I2C_SDAT,
	
	// AudPlayer
	input  i_AUD_ADCDAT,
	inout  i_AUD_ADCLRCK,
	inout  i_AUD_BCLK,
	inout  i_AUD_DACLRCK,
	output o_AUD_DACDAT,

	input i_opening

	// LCD (optional display)
	// input        i_clk_800k,
	// inout  [7:0] o_LCD_DATA,
	// output       o_LCD_EN,
	// output       o_LCD_RS,
	// output       o_LCD_RW,
	// output       o_LCD_ON,
	// output       o_LCD_BLON,

);


// design the FSM and states as you like
parameter S_IDLE       = 0;
parameter S_I2C        = 1;
parameter S_PLAY       = 2;
parameter S_PLAY_PAUSE = 3;


// key0: record/pause
// key1: play/pause
// key2: stop
// key3: reset

// Initilzation Setting 
// 0011_010: slave address (WM8731) 
// R/W: 0 (write)

logic i2c_oen;
wire  i2c_sdat;
logic [19:0] addr_record, addr_play;
logic [15:0] data_record, data_play, dac_data;
logic [1:0] state_r, state_w;

// counter for play and record
logic [23:0] cnt, cnt_next;
logic [3:0]  mini_cnt, mini_cnt_next;
logic [7:0] recordtime, recordtime_next;
logic [7:0] playtime, playtime_next;

// I2C wire
logic i2c_en;
logic i2c_finished;

// DSP wire & register
logic [3:0] speed; 
logic [2:0] mode;  // mode[2]: slow_1, mode[1]: slow_0, mode[0]: fast

logic dsp_start; // dsp_start_next;
logic dsp_pause; // dsp_pause_next;
logic dsp_stop;  // dsp_stop_next;

// AudPlayer register
logic player_en; // player_en_next;

// logic [1:0] player_state;
// logic [3:0] player_index;

// AudRecorder register
logic recorder_start; // recorder_start_next;
logic recorder_pause; // recorder_pause_next;
logic recorder_stop;  // recorder_stop_next;

// wire assignment
// assign io_I2C_SDAT = i2c_sdat;
assign io_I2C_SDAT = (i2c_oen) ? i2c_sdat : 1'bz;

assign o_ROM_ADDR = addr_play[19:0];
// assign o_SRAM_ADDR = addr_play[19:0];
// assign io_SRAM_DQ  = 16'dz; // always input (high z)
assign data_play   = i_ROM_DATA; // sram_dq as input
// assign data_play   = io_SRAM_DQ; 

// speed and mode assignment
assign speed = (i_speed == 4'd0) ? 4'd1 : ((i_speed[3]) ? 4'd8 : i_speed);
assign mode = (i_fast) ? 3'b100 : ((i_slow_0) ? 3'b010 : 3'b001);

// I2C wire assignment
assign i2c_en = (state_r == S_I2C) ? 1'b1 : 1'b0;

// DSP wire assignment
assign dsp_start = (state_r == S_PLAY & !i_AUD_DACLRCK);
assign dsp_pause = (state_r == S_PLAY_PAUSE & !i_AUD_DACLRCK);
assign dsp_stop = (state_r == S_IDLE);

// // AudRecorder register
// assign recorder_start = (state_r == S_RECD & i_AUD_ADCLRCK);
// assign recorder_pause = (state_r == S_RECD_PAUSE & !i_AUD_ADCLRCK);
// assign recorder_stop = (state_r == S_IDLE);

// AudPlayer register
assign player_en = (state_r == S_PLAY);



// below is a simple example for module division
// you can design these as you like

// === I2cInitializer ===
// sequentially sent out settings to initialize WM8731 with I2C protocal
I2cInitializer init0(
	.i_rst_n(i_rst_n),
	.i_clk(i_clk_100k),
	.i_start(i2c_en),
	.o_finished(i2c_finished),
	.o_sclk(o_I2C_SCLK),
	.o_sdat(i2c_sdat),
	.o_oen(i2c_oen) // you are outputing (you are not outputing only when you are "ack"ing.)
);

// === AudDSP ===
// responsible for DSP operations including fast play and slow play at different speed
// in other words, determine which data addr to be fetch for player 
AudDSP dsp0(
	.i_rst_n(i_rst_n),
	.i_clk(i_AUD_BCLK),
	.i_start(dsp_start),
	.i_pause(dsp_pause),
	.i_stop(dsp_stop),
	.i_speed(speed),
	.i_fast(mode[2]),
	.i_slow_0(mode[1]), // constant interpolation
	.i_slow_1(mode[0]), // linear interpolation
	.i_daclrck(i_AUD_DACLRCK),
	.i_sram_data(data_play),
	.o_dac_data(dac_data),
	.o_sram_addr(addr_play),
	.i_opening(i_opening)
);

// === AudPlayer ===
// receive data address from DSP and fetch data to sent to WM8731 with I2S protocal
AudPlayer player0(
	.i_rst_n(i_rst_n),
	.i_bclk(i_AUD_BCLK),
	.i_daclrck(i_AUD_DACLRCK),
	.i_en(player_en), // enable AudPlayer only when playing audio, work with AudDSP, only change at neg edge of i_daclrck
	.i_dac_data(dac_data), //dac_data
	.o_aud_dacdat(o_AUD_DACDAT)

    // .o_state(player_state),
    // .o_index(player_index)
);

// === AudRecorder ===
// receive data from WM8731 with I2S protocal and save to SRAM
// AudRecorder recorder0(
// 	.i_rst_n(i_rst_n), 
// 	.i_clk(i_AUD_BCLK),
// 	.i_lrc(i_AUD_ADCLRCK),
// 	.i_start(recorder_start),
// 	.i_pause(recorder_pause),
// 	.i_stop(recorder_stop),
// 	.i_data(i_AUD_ADCDAT),
// 	.o_address(addr_record),
// 	.o_data(data_record)
// );

// === LCD ===
// LCD lcd0(
//     .i_rst_n(i_rst_n),
//     .i_clk(i_clk_800k),
//     .i_state(state_r),
//     .o_data(o_LCD_DATA),
//     .o_en(o_LCD_EN),
//     .o_rs(o_LCD_RS),
//     .o_rw(o_LCD_RW),
//     .o_on(o_LCD_ON),
//     .o_blon(o_LCD_BLON)
// );

always_comb begin
	// design your control here
    cnt_next = cnt;
    mini_cnt_next = mini_cnt;
	recordtime_next = recordtime;
	playtime_next = playtime;
    case(state_r)
        S_IDLE: begin
            playtime_next = 0;
            if (i_key_1) begin
                cnt_next = 1;
                mini_cnt_next = 1;
            end
        end

        S_PLAY: begin
            if (mode[2]) begin
                cnt_next = (cnt >= 24'd12000000) ? 1 : cnt + speed;
                playtime_next = (cnt >= 24'd12000000) ? playtime + 1 : playtime;
            end
            else begin
                mini_cnt_next = (mini_cnt >= speed) ? 1 : mini_cnt + 1;
                if (mini_cnt >= speed) begin
                    cnt_next = (cnt >= 24'd12000000) ? 1 : cnt + 1;
                    playtime_next = (cnt >= 24'd12000000) ? playtime + 1 : playtime;
                end
            end
        end
    endcase
end

// FSM
always_comb begin
    state_w = state_r;
    case(state_r)
        S_IDLE: begin
            if (i_key_1) begin
                state_w = S_PLAY;
            end
        end

        S_I2C: begin
            if (i2c_finished) begin
                state_w = S_PLAY;
            end
        end

        S_PLAY: begin
            if (i_key_2) begin
                state_w = S_IDLE;
            end 
            if (i_key_1) begin
                state_w = S_PLAY_PAUSE;
            end
        end

        S_PLAY_PAUSE: begin
            if (i_key_2) begin
                state_w = S_IDLE;
            end 
            if (i_key_1) begin
                state_w = S_PLAY;
            end
        end
    endcase
end


always_ff @(posedge i_AUD_BCLK or negedge i_rst_n) begin
	if (!i_rst_n) begin
		state_r     <= S_I2C;
		cnt         <= 24'd1;
        mini_cnt    <= 4'd1;
		recordtime  <= 8'd0;
		playtime    <= 8'd0;
	end
	else begin
		state_r     <= state_w;
		cnt         <= cnt_next;
        mini_cnt    <= mini_cnt_next;
		recordtime  <= recordtime_next;
		playtime    <= playtime_next;
	end
end

endmodule