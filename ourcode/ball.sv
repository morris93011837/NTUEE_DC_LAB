module ball(
    input i_rst_n,
    input i_clk,

    input i_refresh,
    input i_en,
    input signed [12:0] i_bias,
    input [19:0] i_address,
    inout [15:0] io_sram_data,
    output [19:0] o_sram_address,
    output [31:0] o_q
);

logic [19:0] address, address_next;

assign io_sram_data = 16'dz; // Always input (high z)
assign o_sram_address = address;
assign o_q[31:24] = {io_sram_data[15:11], 3'b000}; // R
assign o_q[23:16] = {io_sram_data[10: 6], 3'b000}; // G
assign o_q[15: 8] = {io_sram_data[ 5: 1], 3'b000}; // B
assign o_q[ 7: 0] = {io_sram_data[0]    , 7'b000}; // A

// rom image(
//     .address(address_next),
//     .clock(i_clk),
//     .q(o_q)
// );

always_comb begin
    address_next = (i_en) ? address + 1 : address;
end

always_ff @(posedge i_clk or posedge i_refresh) begin
    if (i_refresh) begin
        address <= i_address + ((i_bias > 0) ? 200 * i_bias : 0);
    end 
    else begin
        address <= address_next;
    end
end

endmodule
