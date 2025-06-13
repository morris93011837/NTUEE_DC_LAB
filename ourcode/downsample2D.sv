module downsample2D(
    input i_rst_n,
    input i_clk,
    input i_refresh,
    input [5:0] i_sample_rate,
    input [9:0] i_red,
    input [9:0] i_green,
    input [9:0] i_blue,
    input [12:0] i_h_count,
    output [9:0] o_red,
    output [9:0] o_green,
    output [9:0] o_blue
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

parameter WIDTH = H_SYNC_TOTAL;
integer i;

logic [15:0] line_mem[0:WIDTH], line_mem_next[0:WIDTH];
logic [12:0] h_cnt, h_cnt_next;  // count from 0 to 799
logic [5:0] y_cnt, y_cnt_next;  // count for sample rate for vertical display
logic [5:0] x_cnt, x_cnt_next;  // count for sample rate for horizontal display

logic [15:0] data;
assign data = {i_red[9:5], i_green[9:4], i_blue[9:5]}; // RRRRR GGGGGG BBBBB

// output assignment
assign o_red = (x_cnt == 0 && y_cnt == 0) ? {data[15:11],5'b0} :
                (x_cnt == 0 && y_cnt != 0) ? {line_mem[h_cnt][15:11],5'b0} : {line_mem[h_cnt - 1][15:11],5'b0};
assign o_green = (x_cnt == 0 && y_cnt == 0) ? {data[10:5],4'b0} :
                (x_cnt == 0 && y_cnt != 0) ? {line_mem[h_cnt][10:5],4'b0} : {line_mem[h_cnt - 1][10:5],4'b0};
assign o_blue = (x_cnt == 0 && y_cnt == 0) ? {data[4:0],5'b0} :
                (x_cnt == 0 && y_cnt != 0) ? {line_mem[h_cnt][4:0],5'b0} : {line_mem[h_cnt - 1][4:0],5'b0};


always_comb begin
    h_cnt_next = (h_cnt == WIDTH) ? 0 : h_cnt + 1;
    x_cnt_next = (x_cnt == i_sample_rate - 1 || h_cnt == WIDTH) ? 0 : x_cnt + 1;
    y_cnt_next = y_cnt;
    if (h_cnt == WIDTH) begin
        y_cnt_next = (y_cnt == i_sample_rate - 1) ? 0 : y_cnt + 1;
    end
end

always_comb begin
    for(i=0; i<WIDTH; i=i+1) begin
        line_mem_next[i] = line_mem[i];
    end

    if(y_cnt == 0) begin
        if(x_cnt == 0) begin
            line_mem_next[h_cnt] = data;
        end
        else begin
            line_mem_next[h_cnt] = line_mem[h_cnt - 1];
        end
    end
    else begin
        line_mem_next[h_cnt] = line_mem[h_cnt];
    end

end

always_ff @(posedge i_clk or posedge i_refresh) begin
    if (i_refresh) begin
        for(i=0; i<WIDTH; i=i+1) begin
            line_mem[i] <= 0;
        end
        h_cnt <= 0;
        y_cnt <= 0;
        x_cnt <= 0;
    end 
    else begin
        for(i=0; i<WIDTH; i=i+1) begin
            line_mem[i] <= line_mem_next[i];
        end
        h_cnt <= h_cnt_next;
        y_cnt <= y_cnt_next;
        x_cnt <= x_cnt_next;
    end
end

endmodule