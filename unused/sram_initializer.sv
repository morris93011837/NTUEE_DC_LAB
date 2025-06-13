module sram_initializer (
    input         avm_rst,
    input         avm_clk,
    input         avm_waitrequest,
    output  [4:0] avm_address,
    output        avm_read,
    input  [31:0] avm_readdata,
    output        avm_write,
    output [31:0] avm_writedata,
    output        init_done,
    output [19:0] o_addr,
	inout  [15:0] io_data,
	output        o_we_n,
	output        o_ce_n,
	output        o_oe_n,
	output        o_lb_n,
	output        o_ub_n
);

localparam RX_BASE     = 0*4;
localparam STATUS_BASE = 2*4;
localparam RX_OK_BIT   = 7;

// Feel free to design your own FSM!
localparam S_IDLE = 0;
localparam S_GET_DATA = 1;
localparam S_SRAM = 2;
localparam S_DONE = 3;

logic [15:0] data_r, data_w;
logic [1:0] state_r, state_w;
logic [21:0] counter_r, counter_w;
logic [4:0] avm_address_r, avm_address_w;
logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

assign avm_address = avm_address_r;
assign avm_read = avm_read_r;
assign avm_write = avm_write_r;
assign avm_writedata = 0;
assign init_done = (state_r == S_DONE);
assign o_addr = counter_r[20:1];
assign io_data = (state_r == S_SRAM) ? data_r : 16'dz;
assign o_we_n = (state_r == S_SRAM) ? 0 : 1; // Write enable = 0 when writing to SRAM
assign o_ce_n = 0;
assign o_oe_n = 0;
assign o_lb_n = 0;
assign o_ub_n = 0;

task StartRead;
    input [4:0] addr;
    begin
        avm_read_w = 1;
        avm_write_w = 0;
        avm_address_w = addr;
    end
endtask

always_comb begin
    data_w = data_r;
    counter_w = counter_r;
    avm_address_w = avm_address_r;
    avm_read_w = avm_read_r;
    avm_write_w = avm_write_r;

    case(state_r)
		S_IDLE: begin
			if (!avm_waitrequest && avm_readdata[RX_OK_BIT]) begin
                StartRead(avm_address_r - STATUS_BASE + RX_BASE);
            end
		end
		S_GET_DATA: begin
			if (!avm_waitrequest) begin
                StartRead(avm_address_r - RX_BASE + STATUS_BASE);
                counter_w = counter_r + 1;
                if (counter_r[0] == 0) begin
                    data_w = avm_readdata[7:0];
                end
                else begin
                    data_w = (data_r << 8) + avm_readdata[7:0];
                end
            end
		end		
        S_SRAM: begin
        end
        S_DONE: begin
        end
	endcase

    // FSM //
    state_w = state_r;
	case(state_r)
		S_IDLE: begin
			if (counter_r[21] == 1) begin
                state_w = S_DONE;
            end
            else if (!avm_waitrequest && avm_readdata[RX_OK_BIT]) begin
                state_w = S_GET_DATA;
            end
		end
		S_GET_DATA: begin
            if(!avm_waitrequest) begin
                if(counter_r[0] == 0)begin
			        state_w = S_IDLE;
                end
                else begin
                    state_w = S_SRAM;
                end
		    end
        end
        S_SRAM: begin
            state_w = S_IDLE;
        end
        S_DONE: begin
        end		
	endcase
end

always_ff @(posedge avm_clk or posedge avm_rst) begin
    if (avm_rst) begin
        avm_address_r <= STATUS_BASE;
        avm_read_r <= 1;
        avm_write_r <= 0;
        state_r <= S_IDLE;
        counter_r <= 0;
        data_r <= 0;
    end else begin
        avm_address_r <= avm_address_w;
        avm_read_r <= avm_read_w;
        avm_write_r <= avm_write_w;
        state_r <= state_w;
        counter_r <= counter_w;
        data_r <= data_w;
    end
end
endmodule