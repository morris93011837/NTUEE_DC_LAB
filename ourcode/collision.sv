module collision (
    input  i_rst_n,
    input  i_clk,
    input  i_refresh,
    input  i_en_pokemon,
    input  i_en_ball,
    input  i_z_neg,
    output o_anime_ball,
    output o_en_collision,
    output o_collision_done
);

logic [1:0] state, state_next;
logic [15:0] collision_cnt, collision_cnt_next;
logic [5:0] refresh_cnt, refresh_cnt_next;
logic [1:0] anime_cnt, anime_cnt_next;
logic collision_done, collision_done_next;

parameter S_IDLE = 2'b00;
parameter S_COL_30 = 2'b01;
parameter S_COL_0 = 2'b10;

assign o_anime_ball = (state == S_COL_0);
assign o_en_collision =  (state == S_COL_30 || state == S_COL_0);
assign o_collision_done = collision_done;

always_comb begin
    collision_cnt_next = collision_cnt;

    if (i_refresh) begin
        collision_cnt_next = 0;
    end
    else if (i_z_neg && i_en_pokemon && i_en_ball) begin
        collision_cnt_next = collision_cnt + 1;
    end
end

always_comb begin
    refresh_cnt_next = refresh_cnt;
    anime_cnt_next = anime_cnt;
    collision_done_next = (i_refresh) ? 0 : collision_done;

    case(state)
        S_IDLE: begin
        end
        S_COL_30: begin
            refresh_cnt_next = (i_refresh) ? refresh_cnt + 1 : refresh_cnt;
        end
        S_COL_0: begin
            refresh_cnt_next = (i_refresh) ? refresh_cnt + 1 : refresh_cnt;
            if (refresh_cnt == 63) begin
                if (anime_cnt == 2) begin
                    collision_done_next = (i_refresh) ? 1 : collision_done;
                    anime_cnt_next = (i_refresh) ? 2'b00 : anime_cnt;
                end
                else begin
                    anime_cnt_next = (i_refresh) ? anime_cnt + 1 : anime_cnt;
                end
            end
        end
    endcase  
end

always_comb begin
    state_next = state;
    case (state)
        S_IDLE: begin
            if (collision_cnt > 10000) begin
                state_next = (i_refresh) ? S_COL_30 : state;
            end 
        end
        S_COL_30: begin
            if (refresh_cnt > 11) begin
                state_next = (i_refresh) ? S_COL_0 : state;
            end
        end
        S_COL_0: begin
            if (refresh_cnt == 63) begin
                if (anime_cnt == 2) begin
                    state_next = (i_refresh) ? S_IDLE : state;
                end
                else begin
                    state_next = (i_refresh) ? S_COL_30 : state;
                end
            end
        end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        collision_cnt <= 16'b0;
        state <= S_IDLE;
        refresh_cnt <= 0;
        anime_cnt <= 0;
        collision_done <= 0;
    end 
    else begin
        collision_cnt <= collision_cnt_next;
        state <= state_next;
        refresh_cnt <= refresh_cnt_next;
        anime_cnt <= anime_cnt_next;
        collision_done <= collision_done_next;
    end
end

endmodule