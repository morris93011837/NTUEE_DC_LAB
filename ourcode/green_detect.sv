module green_detect(
    input i_rst_n,
    input i_clk,
    input i_refresh,

    // VGA input
    input [9:0] i_red,
    input [9:0] i_green,
    input [9:0] i_blue,

    // VGA control
    input signed [12:0] i_h_count,
    input signed [12:0] i_v_count,

    output o_en_pokemon,
    output o_detected,
    output o_anime_pokemon
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

parameter S_IDLE = 1'b0;
parameter S_DETECT = 1'b1;

logic flag, detected, detected_next, state, state_next;
logic box[0:9], green_detected[0:9], green_detected_next[0:9];
logic [15:0] green_cnt[0:9], green_cnt_next[0:9];
logic [5:0] refresh_cnt, refresh_cnt_next; 

assign box[0] = 0;
assign box[1] = (i_h_count >= X_START + 100 && i_h_count < X_START + 300 &&
                i_v_count >= Y_START + 000 && i_v_count < Y_START + 200) ? 1 : 0;
assign box[2] = (i_h_count >= X_START + 300 && i_h_count < X_START + 500 &&
                i_v_count >= Y_START + 000 && i_v_count < Y_START + 200) ? 1 : 0;
assign box[3] = (i_h_count >= X_START + 500 && i_h_count < X_START + 700 &&
                i_v_count >= Y_START + 000 && i_v_count < Y_START + 200) ? 1 : 0;
assign box[4] = (i_h_count >= X_START + 100 && i_h_count < X_START + 300 &&
                i_v_count >= Y_START + 200 && i_v_count < Y_START + 400) ? 1 : 0;
assign box[5] = (i_h_count >= X_START + 300 && i_h_count < X_START + 500 &&
                i_v_count >= Y_START + 200 && i_v_count < Y_START + 400) ? 1 : 0;
assign box[6] = (i_h_count >= X_START + 500 && i_h_count < X_START + 700 &&
                i_v_count >= Y_START + 200 && i_v_count < Y_START + 400) ? 1 : 0;
assign box[7] = (i_h_count >= X_START + 100 && i_h_count < X_START + 300 &&
                i_v_count >= Y_START + 400 && i_v_count < Y_START + 600) ? 1 : 0;
assign box[8] = (i_h_count >= X_START + 300 && i_h_count < X_START + 500 &&
                i_v_count >= Y_START + 400 && i_v_count < Y_START + 600) ? 1 : 0;
assign box[9] = (i_h_count >= X_START + 500 && i_h_count < X_START + 700 &&
                i_v_count >= Y_START + 400 && i_v_count < Y_START + 600) ? 1 : 0;

assign o_en_pokemon = (green_detected[1]) ? box[1] :
                    (green_detected[2]) ? box[2] :
                    (green_detected[3]) ? box[3] :
                    (green_detected[4]) ? box[4] :
                    (green_detected[5]) ? box[5] :
                    (green_detected[6]) ? box[6] : box[0];
                    // (green_detected[7]) ? box[7] :
                    // (green_detected[8]) ? box[8] :
                    // (green_detected[9]) ? box[9] :
                    // box[0];

assign o_detected = detected;
assign flag = green_detected[1] | green_detected[2] | green_detected[3] |
              green_detected[4] | green_detected[5] | green_detected[6] |
              green_detected[7] | green_detected[8] | green_detected[9] ;
assign o_anime_pokemon = refresh_cnt[5];

integer i;

always_comb begin
    if (i_refresh) begin
        for (i=0; i<=9; i=i+1) begin
            green_detected_next[i] = (green_cnt[i] >= 5000);
            green_cnt_next[i] = 0;
        end
    end
    else begin
        for (i=0; i<=9; i=i+1) begin
            green_detected_next[i] = green_detected[i];
            green_cnt_next[i] = (box[i] & (i_green[9:2] >= 80) & (i_red[9:2] < 128) & (i_blue[9:2] < 128)) ? green_cnt[i] + 1 : green_cnt[i];
        end
    end
end

always_comb begin
    state_next = state;
    detected_next = detected;
    refresh_cnt_next = refresh_cnt;
    if (i_refresh) begin
        case (state)
            S_IDLE: begin
                if (flag) begin
                    state_next = S_DETECT;
                    detected_next = 1'b1;
                end
                else begin
                    state_next = S_IDLE;
                end
            end
            S_DETECT: begin
                if (!flag) begin
                    state_next = S_IDLE;
                    detected_next = 1'b0;
                    refresh_cnt_next = 6'b0;
                end
                else begin
                    state_next = S_DETECT;
                    detected_next = 1'b0;
                    refresh_cnt_next = refresh_cnt + 1;
                end
            end
        endcase
    end
end


always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state <= S_IDLE;
        detected <= 1'b0;
        refresh_cnt <= 6'b0;
        for (i=0; i<=9; i=i+1) begin
            green_detected[i] <= 0;
            green_cnt[i]      <= 0;
        end
    end 
    else begin
        state <= state_next;
        detected <= detected_next;
        refresh_cnt <= refresh_cnt_next;
        for (i=0; i<=9; i=i+1) begin
            green_detected[i] <= green_detected_next[i];
            green_cnt[i]      <= green_cnt_next[i];
        end
    end
end

endmodule