module rotation(
    input i_rst_n,
    input i_clk,

    input i_refresh,
    input i_en,
    input [19:0] i_address,
    input [12:0] i_h_count,
    input signed [12:0] i_bias,
    inout [15:0] io_sram_data,
    output [19:0] o_sram_address,
    output [31:0] o_q
);

// parameter S_ROTATE_0 = 2'b00;
// parameter S_ROTATE_1 = 2'b01;
// parameter S_ROTATE_2 = 2'b10;
// parameter S_ROTATE_3 = 2'b11;

parameter S_ROTATE_0 = 1'b0;
parameter S_ROTATE_2 = 1'b1;

logic  state, state_next;
logic  [2:0] offset, offset_next;
logic  [3:0] cnt, cnt_next;
logic [19:0] starting_addr, sram_addr;
logic  [7:0] x_coord, x_coord_next, y_coord, y_coord_next;

assign io_sram_data = 16'dz; // Always input (high z)
assign o_sram_address = sram_addr;
assign o_q[31:24] = {io_sram_data[15:11], 3'b000}; // R
assign o_q[23:16] = {io_sram_data[10: 6], 3'b000}; // G
assign o_q[15: 8] = {io_sram_data[ 5: 1], 3'b000}; // B
assign o_q[ 7: 0] = {io_sram_data[0]    , 7'b000}; // A

// rom image(
//     .address(address_next),
//     .clock(i_clk),
//     .q(o_q)
// );

// Counter Logic
always_comb begin
    starting_addr = i_address + (offset * 40000);

    offset_next = (!i_refresh || (cnt != 4'b0010)) ? offset :
                (offset == 3'b101) ? 3'b000 : 
                offset + 1;

    cnt_next = (!i_refresh) ? cnt :
                (cnt == 4'b0010) ? 4'b0000 : 
                cnt + 1;

    x_coord_next = (i_refresh) ? 0 :
                (i_h_count == 0) ? 0 :
                (!i_en) ? x_coord :
                (x_coord == 199) ? 0 :
                x_coord + 1;

    y_coord_next = (i_refresh) ? ((i_bias > 0) ? i_bias : 0) :
                (!i_en) ? ((i_h_count == 0 && x_coord != 0) ? y_coord + 1 : y_coord) :
                (x_coord == 199) ? y_coord + 1 :
                y_coord;
end

// Rotation Logic
always_comb begin
    case (state)
        S_ROTATE_0: begin
            sram_addr = starting_addr + (y_coord * 200) + x_coord;
        end
        // S_ROTATE_1: begin
        //     sram_addr = starting_addr + (x_coord * 200) + (199 - y_coord);
        // end
        S_ROTATE_2: begin
            sram_addr = starting_addr + ((199 - y_coord) * 200) + (199 - x_coord);
        end
        // S_ROTATE_3: begin
        //     sram_addr = starting_addr + ((199 - x_coord) * 200) + y_coord;
        // end
    endcase
end

// Finite State Machine
always_comb begin
    state_next = (offset == 3'b101 && offset_next == 3'b000) ? state + 1 : state;
end

always_ff @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        state   <= S_ROTATE_0;
        offset  <= 0;
        cnt     <= 0;
        x_coord <= 0;
        y_coord <= (i_bias > 0) ? i_bias : 0;
    end 
    else begin
        state   <= state_next;
        offset  <= offset_next;
        cnt     <= cnt_next;
        x_coord <= x_coord_next;
        y_coord <= y_coord_next;
    end
end

endmodule