module cdc_dff_f2s (
    input wire rst_n,
    input wire clk_fast,
    input wire clk_slow,
    output wire sync,
    input wire allow,

    output wire data_out,
    input wire data_in
);

reg data_fast_ff1;
reg data_slow_ff1;
reg data_slow_ff2;

assign sync = ~(data_out ^ data_fast_ff1);

always @(posedge clk_fast or negedge rst_n ) begin
    if(~rst_n) begin
        data_fast_ff1 <= 1'b0;
    end else if(sync) begin
        //hold data untill data is fully passed through
        data_fast_ff1 <= data_in;
    end else begin
        data_fast_ff1 <= data_fast_ff1;
    end
end


always @(posedge clk_slow or negedge rst_n) begin
    if(~rst_n) begin
        data_slow_ff1 <= 1'b0;
        data_slow_ff2 <= 1'b0;
    end else begin
        data_slow_ff1 <= data_fast_ff1;
        data_slow_ff2 <= allow? data_slow_ff1: data_slow_ff2;
    end
end

assign data_out = data_slow_ff2;
    
endmodule

module cdc_dff_f2s_x4(
    input wire rst_n,
    input wire clk_fast,
    input wire clk_slow,
    output wire sync,
    input wire allow,

    output reg [3:0]data_out,
    input wire [3:0]data_in
);

wire [3:0]m_bit_sync;
wire m_bit_allow;
assign m_bit_allow = &m_bit_sync;
wire [3:0]data_out_t;
assign sync = ~|(data_out_t ^ data_out);

cdc_dff_f2s cdc_bit_0(
    /*input wire */.rst_n(rst_n),
    /*input wire */.clk_fast(clk_fast),
    /*input wire */.clk_slow(clk_slow),
    /*output wire */.sync(m_bit_sync[0]),
    /*input wire */.allow(allow),
    /*output wire */.data_out(data_out_t[0]),
    /*input wire */.data_in(data_in[0]));
cdc_dff_f2s cdc_bit_1(
    /*input wire */.rst_n(rst_n),
    /*input wire */.clk_fast(clk_fast),
    /*input wire */.clk_slow(clk_slow),
    /*output wire */.sync(m_bit_sync[1]),
    /*input wire */.allow(allow),
    /*output wire */.data_out(data_out_t[1]),
    /*input wire */.data_in(data_in[1]));
cdc_dff_f2s cdc_bit_2(
    /*input wire */.rst_n(rst_n),
    /*input wire */.clk_fast(clk_fast),
    /*input wire */.clk_slow(clk_slow),
    /*output wire */.sync(m_bit_sync[2]),
    /*input wire */.allow(allow),
    /*output wire */.data_out(data_out_t[2]),
    /*input wire */.data_in(data_in[2]));
cdc_dff_f2s cdc_bit_3(
    /*input wire */.rst_n(rst_n),
    /*input wire */.clk_fast(clk_fast),
    /*input wire */.clk_slow(clk_slow),
    /*output wire */.sync(m_bit_sync[3]),
    /*input wire */.allow(allow),
    /*output wire */.data_out(data_out_t[3]),
    /*input wire */.data_in(data_in[3]));

always @(posedge clk_slow or negedge rst_n) begin
    if(~rst_n) begin
        data_out <= 4'b0;
    end else begin
        data_out <= m_bit_allow? data_out_t : data_out;
    end
end

endmodule