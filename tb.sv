
`timescale 1ns/1ps
//`define TEST_UART_FRONT
//`define TEST_CTL_IF
//`define TEST_LCD_IF_PX_SEQ
`define TEST_LCD_IF_INIT_SEQ
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
    
    //test hold data before ready function;
    #357.2 ready = 1'b0;
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
    #160 rx = 1'b1;//bit 0
    #160 rx = 1'b0;//bit 1
    #160 rx = 1'b0;//bit 2
    #160 rx = 1'b1;//bit 3
    #160 rx = 1'b0;//bit 4
    #160 rx = 1'b1;//bit 5
    #160 rx = 1'b1;//bit 6
    #160 rx = 1'b0;//bit 7
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

`elsif TEST_LCD_IF_PX_SEQ
reg clk;
reg rst_n;
reg lcd_init;
reg lcd_px;
reg lcd_stream;
wire lcd_busy;
reg lcd_begin;

wire spi_phy_begin;
wire spi_phy_busy;
wire spi_phy_wide;
wire spi_cs;
wire [31:0]spi_phy_mosi;

wire spi_mosi;
wire spi_phy_clk;
wire spi_phy_cs;
wire lcd_data_cmd;

initial begin
    forever begin
        #5 clk = ~clk;
    end
end

initial begin
    $display("===================\nTesting: lcd_if_pixel_sequence.\n===================\n");
    $dumpfile("dump.vcd");
    $dumpvars(0);
end

initial begin
    clk = 1'b0; rst_n = 1'b1; lcd_init = 1'b0; lcd_px = 1'b0; lcd_stream = 1'b0; lcd_begin = 1'b0;
    #100 rst_n = 1'b0;
    #100 rst_n = 1'b1; lcd_px = 1'b1;

    #100 lcd_begin = 1'b1;
    #10 lcd_begin = 1'b0;
    #1500 $finish();
end

spi_front dut_phy(
    .spi_clk_in(clk),
    .rst_n(rst_n),

    //spi interface
    .spi_clk_o(spi_phy_clk),
    //output.spi_clk_t(),
    .spi_mosi_o(spi_mosi),
    //output.spi_mosi_t(),
    .spi_miso_i(1'b1),

    //data interface
    .data_mosi(spi_phy_mosi),
    //output.data_miso(),

    //control interface
    .spi_begin(spi_phy_begin),
    .spi_wide(spi_phy_wide),
    .spi_busy(spi_phy_busy)
);

lcd_if dut_if(
    .clk(clk),
    .rst_n(rst_n),
    
    //actions
    .init(lcd_init),             //initialize LCD
    .px_stream_cmd(lcd_px),    //transmit pixel commands
    .stream_512B(lcd_stream),      //stream 512 bytes at 4 bytes each stream trigger

    //flow control
    .if_begin(lcd_begin),
    .if_busy(lcd_busy),

    //data stream
    .stream_data(32'h55AAE621),
    .stream_trigger(1'h0),
    //output .stream_busy(),

    //lcd control pin
    .lcd_data_cmd(lcd_data_cmd),

    //spi phy
    .spi_mosi(spi_phy_mosi),
    //input [31:0]spi_miso, This IF output only. No read back
    .spi_begin(spi_phy_begin),
    .spi_wide(spi_phy_wide),
    .spi_busy(spi_phy_busy),
    .spi_cs(spi_cs)
);


`elsif TEST_LCD_IF_INIT_SEQ
reg clk;
reg rst_n;
reg lcd_init;
reg lcd_px;
reg lcd_stream;
wire lcd_busy;
reg lcd_begin;

wire spi_phy_begin;
wire spi_phy_busy;
wire spi_phy_wide;
wire spi_cs;
wire [31:0]spi_phy_mosi;

wire spi_mosi;
wire spi_phy_clk;
wire spi_phy_cs;
wire lcd_data_cmd;

initial begin
    forever begin
        #5 clk = ~clk;
    end
end

initial begin
    $display("===================\nTesting: lcd_if_pixel_sequence.\n===================\n");
    $dumpfile("dump.vcd");
    $dumpvars(0);
end

initial begin
    clk = 1'b0; rst_n = 1'b1; lcd_init = 1'b0; lcd_px = 1'b0; lcd_stream = 1'b0; lcd_begin = 1'b0;
    #100 rst_n = 1'b0;
    #100 rst_n = 1'b1; lcd_init = 1'b1;

    #100 lcd_begin = 1'b1;
    #10 lcd_begin = 1'b0;
    #6000 $finish();
end

spi_front dut_phy(
    .spi_clk_in(clk),
    .rst_n(rst_n),

    //spi interface
    .spi_clk_o(spi_phy_clk),
    //output.spi_clk_t(),
    .spi_mosi_o(spi_mosi),
    //output.spi_mosi_t(),
    .spi_miso_i(1'b1),

    //data interface
    .data_mosi(spi_phy_mosi),
    //output.data_miso(),

    //control interface
    .spi_begin(spi_phy_begin),
    .spi_wide(spi_phy_wide),
    .spi_busy(spi_phy_busy)
);

lcd_if dut_if(
    .clk(clk),
    .rst_n(rst_n),
    
    //actions
    .init(lcd_init),             //initialize LCD
    .px_stream_cmd(lcd_px),    //transmit pixel commands
    .stream_512B(lcd_stream),      //stream 512 bytes at 4 bytes each stream trigger

    //flow control
    .if_begin(lcd_begin),
    .if_busy(lcd_busy),

    //data stream
    .stream_data(32'h55AAE621),
    .stream_trigger(1'h0),
    //output .stream_busy(),

    //lcd control pin
    .lcd_data_cmd(lcd_data_cmd),

    //spi phy
    .spi_mosi(spi_phy_mosi),
    //input [31:0]spi_miso, This IF output only. No read back
    .spi_begin(spi_phy_begin),
    .spi_wide(spi_phy_wide),
    .spi_busy(spi_phy_busy),
    .spi_cs(spi_cs)
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


/*
I love you
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKxOXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXKOkxkkkkkkkkkkkxl..cKNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKkOXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNX0Okkkkkkkkkkkkkkxl..cKNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKk0NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNX0Okxkkkkkkkkkkkkkko,.:KNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKxkXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXK0kkkkkkkkkkkkkkkkkkd,.:0NNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXddKNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXX0Okkkkkkkkkkkkkkkkkxkd,.cKNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXk;dNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXK0Okkkkkkkkkkkkkkkkkkxxko'.lKNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKo..xNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXK0Okkkkkkkkkkkkkkkkkkkkxkxl..dXNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXk;. .dXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXKOkkxkkkkkkkkkkkkkkkkkxkkxo;.,kXNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXd',;..ck0KK00000KKXXXXXXXXXXNNNNNNNXXKK0OOkkkkkkkkkkkkkkkkkkkkkkkkxo:..l0NNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXXKKd'';'...,;lxxxxkkkkkOOOkkOOOOOO0KKK0Okkkxxkkkkkkkkkkkkkxkxkkkkxxdl:,';oOXNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNXOdl:;;;'...,:,   'odxkkkkxxkkkkkkkkkxxxkkkxkkkkkkkkkkkkkkkkkkkxkkdc::;,'';okXNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNKd;',;:coddlldxl. .....,;:lodxxkkkkkkkkkxxkkkkkkkkkkkkkkkkkkxxxdolc;. .';lx0XNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNO;.'lxxxxxxxxxxx; .;lc:,,'...''';:cclllooooddddddoooolllc:::;,'....   .;oOXNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNO,.:dxxxxxxxxxxxd,.lxdollllcc::;,''.........................''','..       .:OXNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNK:.;dxxxxxxxxxxxxdllxxxxxollllllllllccccccc:::::::::::::cccccllc,.   ......  'kNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNk..oxxxxxxxxxxxxxxxxxxxxxxdllllllllllllllllllllllllllllllllclc,.  ..........  :0NNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNd.;xxxxxxxxxxxxxxxxxxxxxxxdlcllllllllllllllllllllllllllllllc:.   ............ .xNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNXo..cxxxxxxxxxxxxxxxxxxxxxdolllllllllllllllllllllllllllllc;'.        ....   .. .oXNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNKx' .,coxxxxxxxxxxxxxxxxdollllllllllllllllllllllllllllc;'..     .     ..    ..  ;0NNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNXo.     .,cdxxxxxxxxxxdolllllllllllllllllllllllllllllc;.    ...              ... .dNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNXx;.  .'..  .cxxdddddoolllllllllllllllllllllllllc;,,'...   .......        .   ...  :KNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNKo...,;cxdolccodollllllllllllllllllllcllcc:;;,,,'..    ................   ..   .... .kNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNx..,lxxxxxxxxxxdllllllllllllllllllllcc;'...    ......................... ...   ....  :KNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNXc.cxxxxxxxxxxxxdlllllllllllllllllc:;'..   ...................................  ..... .xNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNK:'lxxxxxxxxxxdollllllllllccc::;,,............................................   ....  lXNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNKc.:xxxxxxxddolllllc:;,''.....   ..............................................   .... ;0NNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNx'.cooollllllcc:;'.        ....................................................  .....'xNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNXx:,''..........   ............................................................. ......lXNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNXk,        .........................................................................'dKNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNXx,   ..........     ...................................           ................. ,OKNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNKl.    .......           ..............................                .............. 'x0XNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNk;.   ......               ..........................              .;;'.  ........... .kKXNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNXKc   ....                  ........................               .clll;. .......... .xKXNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNXl  ....                ..   .....................                ,lllll:. .........  .';cox0XNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNO' ...   .            .;c.  ....................                .:llllll;  .........      .'oKNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNK:  ..  .,.           .:l;.  ...................      .';:'     'cllllllc. ..........       .kNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNXOc.  .. .;c'..;:c,    .,llc.  ...................  .,;;:::;.    .clllllllc'................  .kNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNXx.   ... .codl:,.     .;clll;. ........................         .:llllllllc...............   'xXNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNXl   .....'lool:'....';clllldl. .....................          .'cllllllodd;..............  .c0NNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNKc    .....coollllccllllloodxd, ....................,;,'..  ..,:lllooooodd:.............   'xXNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNXk,    ....'oxdddooooodddxxxdo,......................:lllc::coddddxxxxxxd;............    ,xXNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNN0o,.    ..,oxxxxxxxxxxxxd:''........................,cllllodxxxxxxxxxo'..............   ..;kXNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNKkc;.  ...:dxxxxxxxxdl,.......................... ..;codxxxxxxxxoc,...................  .cXNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNXo. .... .;loddddl;. ...............................';::cccc;,. ..................    ,kNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNN0:  .............. ..................................    ... ...................    .:ONNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNXOc.  .......................................................................      .c0NNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNXOc. ...................                   ............................        'oOXNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNXk:.  ................                    ........................       .':xKNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNX0o,.  ................              ......................        .'cxOKNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXko,.  ..................   ........................       'ccoxOXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXkl,.   ..............   ....................           oNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNX0xl;.       ......   ...............          ...   ;d0XNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKd'                                     .......    ..:okXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKOo,  .  ..      ......            ...............     ....;dKNNNNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXOl,.  ...  ..................................................  'lkXNNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKl...............................................................  .;xKNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKd'  ............................................................ ...  .;d0XNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNKd,   ..............................................................      ..'lOXNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNN0l'   ..................................................................    .'..,ONNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNXOc.  .......................................................................   ':ccONNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNXk:.  ..........................................................................   .:ONNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNXd.   ....  ............................................................ ..........   .dXNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNN0c.  ......  ...........................................................   ..........   .:ONNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNXl  ........  ............................................................  ...........  . :0NNNNNNNNNNNNNNN
*/