
`timescale 1ns/1ps
`define TEST_UART_FRONT
module tb;
/*
uart_front test bench:
*/

`ifdef TEST_UART_FRONT

reg clk;
reg rst_n;
reg rx;
reg ready;
wire [7:0]data_rx;
wire valid;
initial begin
    forever begin
        #5 clk = ~clk;
    end
end

initial begin
    $display("Testing: uart_front.");
    $dumpvars(0);
    $dumpfile("tb_uart_front.vcd");
end

initial begin
    clk = 1'b0; rst_n = 1'b1; ready <= 1'b0; rx <= 1'b1;

    #50 clk = 1'b0; rst_n = 1'b0; ready <= 1'b0; rx <= 1'b1;
    #50 clk = 1'b0; rst_n = 1'b1; ready <= 1'b0; rx <= 1'b1;

    
    #160 rx = 1'b0;//start
    #160 rx = 1'b1;//bit 0
    #160 rx = 1'b0;//bit 1
    #160 rx = 1'b1;//bit 2
    #160 rx = 1'b0;//bit 3
    #160 rx = 1'b1;//bit 4
    #160 rx = 1'b0;//bit 5
    #160 rx = 1'b1;//bit 6
    #160 rx = 1'b0;//bit 7
    #160 rx = 1'b1;//stop bit

    #357.2 ready = 1'b1;
    #20 ready = 1'b0;

    #160 rx = 1'b0;//start
    #160 rx = 1'b1;//bit 0
    #160 rx = 1'b1;//bit 1
    #160 rx = 1'b1;//bit 2
    #160 rx = 1'b1;//bit 3
    #160 rx = 1'b0;//bit 4
    #160 rx = 1'b0;//bit 5
    #160 rx = 1'b0;//bit 6
    #160 rx = 1'b0;//bit 7
    #160 rx = 1'b1;//stop bit

    #357.2 ready = 1'b1;
    #20 ready = 1'b0;

    #160 rx = 1'b0;//start
    #160 rx = 1'b0;//bit 0
    #160 rx = 1'b1;//bit 1
    #160 rx = 1'b1;//bit 2
    #160 rx = 1'b0;//bit 3
    #160 rx = 1'b1;//bit 4
    #160 rx = 1'b0;//bit 5
    #160 rx = 1'b0;//bit 6
    #160 rx = 1'b1;//bit 7
    #160 rx = 1'b1;//stop bit

    #357.2 ready = 1'b1;
    #20 ready = 1'b0;

    
    #200 $finish();
end

    uart_front dut(
        .clk(clk),
        .rst_n(rst_n),

        //uart interface
        .uart_rx(rx),

        //data interface
        .data_rx(data_rx),

        //control interface
        .uart_valid(valid),
        .uart_ready(ready)//,
    );
`else
    initial begin
        $display("no_module_to _test");
        $finish();
    end
    

`endif// TEST_UART_FRONT
/*
uart_front test bench END
*/

endmodule
