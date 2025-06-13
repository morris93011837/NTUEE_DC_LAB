module opening(
    input i_rst_n,
    input i_clk,

    // VGA input output
    output [9:0] o_red,
    output [9:0] o_green,
    output [9:0] o_blue,

    // VGA control
    input signed [12:0] i_h_count,
    input signed [12:0] i_v_count,

    // image address
    inout [15:0] io_sram_data,
    output [19:0] o_sram_address,

    // restart signals
    input i_key_2,
    input i_restart,
    output o_opening
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

parameter S_OPENING = 1'b0;
parameter S_PRESSED = 1'b1;

logic state, state_next;
logic refresh, en_badge, en_logo, en_opening;
logic [31:0] q_badge, q_logo, q_opening;
logic [19:0] sram_address_badge, sram_address_logo, sram_address_opening;

assign o_opening = (state == S_OPENING);
assign refresh = (i_h_count == 0 && i_v_count == 0) ? 1 : 0;

assign en_badge = (i_h_count >= X_START && i_h_count < X_START + 13'sd100 &&
                i_v_count >= Y_START && i_v_count < Y_START + 13'sd600 ) ? 1 : 0;
assign en_logo = (i_h_count >= X_START + 13'sd695 && i_h_count < X_START + 13'sd795 &&
                i_v_count >= Y_START && i_v_count < Y_START + 13'sd100 ) ? 1 : 0;
assign en_opening = (i_h_count >= X_START + 300 && i_h_count < X_START + 500 &&
                i_v_count >= Y_START + 200 && i_v_count < Y_START + 400) ? 1 : 0;

assign io_sram_data = 16'dz; // Always input (high z)
assign o_sram_address = (en_opening) ? sram_address_opening :
                        (en_logo) ? sram_address_logo :
                        (en_badge) ? sram_address_badge :
                        20'dz; // High Z when not enabled

assign o_red   = (en_opening && q_opening[7]) ? {q_opening[31:24],2'b00} : 
                (en_logo && q_logo[7]) ? {q_logo[31:24],2'b00} : 
                (en_badge && q_badge[7]) ? {q_badge[31:24],2'b00} :
                {8'hF8,2'b00};
assign o_green = (en_opening && q_opening[7]) ? {q_opening[23:16],2'b00} : 
                (en_logo && q_logo[7]) ? {q_logo[23:16],2'b00} : 
                (en_badge && q_badge[7]) ? {q_badge[23:16],2'b00} : 
                {8'hF8,2'b00};
assign o_blue  = (en_opening && q_opening[7]) ? {q_opening[15:8] ,2'b00} : 
                (en_logo && q_logo[7]) ? {q_logo[15:8] ,2'b00} : 
                (en_badge && q_badge[7]) ? {q_badge[15:8] ,2'b00} : 
                {8'hF8,2'b00};

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

image opening (
    .i_rst_n(i_rst_n),
    .i_clk(i_clk),
    .i_refresh(refresh),
    .i_en(en_opening),
    .i_address(0),
    .io_sram_data(io_sram_data),
    .o_sram_address(sram_address_opening),
    .o_q(q_opening)
);

always_comb begin
    case (state)
        S_OPENING: begin
            state_next = (i_key_2) ? S_PRESSED : S_OPENING;
        end
        S_PRESSED: begin
            state_next = S_PRESSED;
        end
    endcase
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state <= S_OPENING;
    end
    else begin
        if (i_restart) begin
            state <= S_OPENING;
        end
        else begin
            state <= state_next;
        end
    end
end

endmodule