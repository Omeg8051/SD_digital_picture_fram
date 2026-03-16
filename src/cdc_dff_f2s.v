module cdc_dff_f2s (
    input wire rst_n,
    input wire clk_slow,

    output wire data_out,
    input wire data_in
);

reg data_slow_ff1;
reg data_slow_ff2;


always @(posedge clk_slow or negedge rst_n) begin
    if(~rst_n) begin
        data_slow_ff1 <= 1'b0;
        data_slow_ff2 <= 1'b0;
    end else begin
        data_slow_ff1 <= data_in;
        data_slow_ff2 <= data_slow_ff1;
    end
end

assign data_out = data_slow_ff2;
    
endmodule

module cdc_dff_f2s_x4(
    input wire rst_n,
    input wire clk_fast,
    input wire clk_slow,

    output reg [3:0]data_out,
    input wire [3:0]data_in
);
wire [3:0]data_out_t;

cdc_dff_f2s cdc_bit_0(
    /*input wire */.rst_n(rst_n),
    /*input wire */.clk_slow(clk_slow),
    /*output wire */.data_out(data_out_t[0]),
    /*input wire */.data_in(data_in[0]));
cdc_dff_f2s cdc_bit_1(
    /*input wire */.rst_n(rst_n),
    /*input wire */.clk_slow(clk_slow),
    /*output wire */.data_out(data_out_t[1]),
    /*input wire */.data_in(data_in[1]));
cdc_dff_f2s cdc_bit_2(
    /*input wire */.rst_n(rst_n),
    /*input wire */.clk_slow(clk_slow),
    /*output wire */.data_out(data_out_t[2]),
    /*input wire */.data_in(data_in[2]));
cdc_dff_f2s cdc_bit_3(
    /*input wire */.rst_n(rst_n),
    /*input wire */.clk_slow(clk_slow),
    /*output wire */.data_out(data_out_t[3]),
    /*input wire */.data_in(data_in[3]));

always @(posedge clk_slow or negedge rst_n) begin
    if(~rst_n) begin
        data_out <= 4'b0;
    end else begin
        data_out <= data_out_t;
    end
end

endmodule