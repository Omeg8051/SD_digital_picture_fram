
`timescale 1ns/1ps

module tb;
/*
Test bench for a simulation model?
Nuts.
*/
reg clk;
reg bus_clk;
reg bus_mosi;
reg bus_cs;
wire bus_miso;
wire [7:0]debug_status;

initial begin
    #200 $finish();
end



endmodule
