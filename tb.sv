
`timescale 1ns/1ps
//`define TEST_UART_FRONT
`define TEST_CTL_IF
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
    $display("===================\nTesting: uart_front.\n===================\n");
    $dumpfile("dump.vcd");
    $dumpvars(0);
end

initial begin
    clk = 1'b0; rst_n = 1'b1; ready <= 1'b0; rx <= 1'b1;

    #50 rst_n = 1'b0; ready <= 1'b0; rx <= 1'b1;
    #50 rst_n = 1'b1; ready <= 1'b0; rx <= 1'b1;

    
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

`elsif TEST_CTL_IF

reg clk;
reg rst_n;
reg rx;
wire ctl_valid;
reg ctl_ready;
wire uart_valid;
wire uart_ready;
wire ctl_incr;
wire ctl_decr;

wire [7:0]data_rx;

initial begin
    forever begin
        #5 clk = ~clk;
    end
end

initial begin
    $display("===================\nTesting: ctl_if.\n===================\n");
    $dumpfile("dump.vcd");
    $dumpvars(0);
end

initial begin
    clk = 1'b0; rst_n = 1'b1; ctl_ready <= 1'b0; rx <= 1'b1;

    #50 rst_n = 1'b0; ctl_ready <= 1'b0; rx <= 1'b1;
    #50 rst_n = 1'b1; ctl_ready <= 1'b0; rx <= 1'b1;

    
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

    #357.2 ctl_ready = 1'b1;
    #20 ctl_ready = 1'b0;

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

    #357.2 ctl_ready = 1'b1;
    #20 ctl_ready = 1'b0;

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

    #357.2 ctl_ready = 1'b1;
    #20 ctl_ready = 1'b0;
    //'1'
    #160 rx = 1'b0;//start
    #160 rx = 1'b1;//bit 0
    #160 rx = 1'b0;//bit 1
    #160 rx = 1'b0;//bit 2
    #160 rx = 1'b0;//bit 3
    #160 rx = 1'b1;//bit 4
    #160 rx = 1'b1;//bit 5
    #160 rx = 1'b0;//bit 6
    #160 rx = 1'b0;//bit 7
    #160 rx = 1'b1;//stop bit

    #357.2 ctl_ready = 1'b1;
    #20 ctl_ready = 1'b0;

    #160 rx = 1'b0;//start
    #160 rx = 1'b1;//bit 0
    #160 rx = 1'b1;//bit 1
    #160 rx = 1'b1;//bit 2
    #160 rx = 1'b0;//bit 3
    #160 rx = 1'b1;//bit 4
    #160 rx = 1'b0;//bit 5
    #160 rx = 1'b1;//bit 6
    #160 rx = 1'b1;//bit 7
    #160 rx = 1'b1;//stop bit

    #357.2 ctl_ready = 1'b1;
    #20 ctl_ready = 1'b0;
    //'2'
    #160 rx = 1'b0;//start
    #160 rx = 1'b0;//bit 0
    #160 rx = 1'b1;//bit 1
    #160 rx = 1'b0;//bit 2
    #160 rx = 1'b0;//bit 3
    #160 rx = 1'b1;//bit 4
    #160 rx = 1'b1;//bit 5
    #160 rx = 1'b0;//bit 6
    #160 rx = 1'b0;//bit 7
    #160 rx = 1'b1;//stop bit

    #357.2 ctl_ready = 1'b1;
    #20 ctl_ready = 1'b0;

    #160 rx = 1'b0;//start
    #160 rx = 1'b1;//bit 0
    #160 rx = 1'b0;//bit 1
    #160 rx = 1'b1;//bit 2
    #160 rx = 1'b0;//bit 3
    #160 rx = 1'b1;//bit 4
    #160 rx = 1'b1;//bit 5
    #160 rx = 1'b0;//bit 6
    #160 rx = 1'b1;//bit 7
    #160 rx = 1'b1;//stop bit

    #357.2 ctl_ready = 1'b1;
    #20 ctl_ready = 1'b0;

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
    .uart_valid(uart_valid),
    .uart_ready(uart_ready)//,
);

ctl_if dut_1(
    .clk(clk),
    .rst_n(rst_n),

    //uart interface
    .uart_rx(data_rx),
    .uart_valid(uart_valid),
    .uart_ready(uart_ready),

    //control interface
    .ctl_valid(ctl_valid),
    .ctl_ready(ctl_ready),
    .ctl_incr(ctl_incr),
    .ctl_decr(ctl_decr)
);



`else
    initial begin
        $display("===================\nno_module_to _test\n===================\n");
        $finish();
    end
    

`endif// TEST_UART_FRONT
/*
uart_front test bench END
*/

endmodule
