
`timescale 100ns/100ps
//`define TEST_UART_FRONT
//`define TEST_CTL_IF
//`define TEST_LCD_IF_PX_SEQ
//`define TEST_LCD_IF_INIT_SEQ
`define TEST_LCD_IF_STREAM_512B
//`define TEST_LCD_IF_STREAM_512B_END

`define DISABLE_DELAY
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
    .end_of_frame(1'b0),      //pull high when initiating the last block transfer.

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
    .end_of_frame(1'b0),      //pull high when initiating the last block transfer.

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



`elsif TEST_LCD_IF_STREAM_512B
reg clk;
reg rst_n;
reg lcd_init;
reg lcd_px;
reg lcd_stream;
wire lcd_busy;
reg lcd_begin;

reg [31:0]stream_data;
reg [31:0]spi_bit_cnt;
reg stream_trigger;

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

always @(posedge spi_phy_clk) begin
    spi_bit_cnt <= spi_bit_cnt + 32'h1;
end

initial begin
    spi_bit_cnt <= 32'h0;
    clk = 1'b0; rst_n = 1'b1; lcd_init = 1'b0; lcd_px = 1'b0; lcd_stream = 1'b0; lcd_begin = 1'b0; stream_trigger = 1'b0; stream_data = 32'h55AAE621;
    #100 rst_n = 1'b0;
    #100 rst_n = 1'b1; lcd_stream = 1'b1; stream_trigger = 1'b1;

    #100 lcd_begin = 1'b1;
    #10 lcd_begin = 1'b0;
    #50000 $finish();
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
`ifdef TEST_LCD_IF_STREAM_512B_END
    .end_of_frame(1'b1),      //pull high when initiating the last block transfer.
`else
    .end_of_frame(1'b0),      //pull high when initiating the last block transfer.
`endif
    //flow control
    .if_begin(lcd_begin),
    .if_busy(lcd_busy),

    //data stream
    .stream_data(stream_data),
    .stream_trigger(1'h1),
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
        $display("===================\nno_module_to _test\n===================\nModify (comment | uncomment) the begining of tb.sv to select test targets.\n===================\n");
        $finish();
    end
    

`endif// TEST_UART_FRONT
/*
uart_front test bench END
*/

endmodule


/*
I love you
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXOOXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXKOkkkkkkxkkkd,.oXNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNX00XNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXKOkxkkkxkkkkkx;.oXNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXOOXNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNX0Okxkkkkkkkkkkx:.lXNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNNOdKNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNNXK0kkkkkkkkkkkkkkx:.oXNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNXk;lXNNNNNNNNNNNNNNNNNNNNNNNNNNNNXK0kkkkkkkkkkkkkxxkd;'dXNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNN0l..cKXNNNNNNNNNNNNNNNNNNNNNNNXXK0kkkkkkkkkkkkkkkxkxl,;kXNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNN0c,,.'ok00OO00KKKKKKKXXXXXXXK0OOkkkkkkkkkkkkkkkkkxdc;,oKNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNKkdoo;..''. 'lxkkxxxkkkkkkkkkOOOkkkxxkkkkkkkkkkkkdoll:;;cx0NNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNXkc;;:cllcld:...',;:lodxxkkkkkkkkkkkkkkkkkkkkxxdool;..,:okKNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNKl';dxkxxxxko'.:lc;,,',,,,;;:::::cccccc::::;;;,''..   .cxKNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNXl.:xxxxxxxxxd:lxxdollllcc:;;,,,,,,'''',,,,,,;;:;'.   .  .;ONNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNO,,dxxxxxxxxxxxxxxxxolllllllllllllllllllllllllc,.  ....... :KNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNx':xxxxxxxxxxxxxxxxxollllllllllllllllllllllcc;.   ........ 'kNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNk'.:oxxxxxxxxxxxxxdolllllllllllllllllllll:;'.       ..   . .oNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNN0:.  .':oxxxxxxxxoollllllllllllllllllllc:'.  ..           .. ;0NNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNN0c. .,,..,oddoooolllllllllllllllcccc;,'...  ......      .  .. .dNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNN0:.,loxxxdddocclllllllllllllc:,'......  ..............  ..  ... :KNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNd,cxxxxxxxxdlllllllllllllc:,..   .........................  ... .xNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNo,okxxxxxxdllllccc::;,,''..................................  ... cXNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNx';ddddoollcc;'.....    .................................... ... ;0NNNNNNNNNNNNNNNN
NNNNNNNNNNNNNXd:;'.........    ................................................xNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNO;  .........................................   ...............,kXNNNNNNNNNNNNNNN
NNNNNNNNNNNNNXx'   .....        .......................           ........... ,kXNNNNNNNNNNNNNNN
NNNNNNNNNNNNN0c.  ....            ...................           .,'.......... ,OXNNNNNNNNNNNNNNN
NNNNNNNNNNNNNN0;  ...              .................            ,llc' ....... .lk0XNNNNNNNNNNNNN
NNNNNNNNNNNNNNXc ...            ''  ...............            .:lllc' .......  ..,ckXNNNNNNNNNN
NNNNNNNNNNNNNNNx. .  ..   .    .:c.  ..............    .',,.   'cllll:.........     ,ONNNNNNNNNN
NNNNNNNNNNNNNKd'  . .::,',,.  .,cl,  .............. ..',,'.   .clllll:............  ;0NNNNNNNNNN
NNNNNNNNNNNNNx.  ...'loo;. ...;lloc. ................        .:lllllo:........... .c0NNNNNNNNNNN
NNNNNNNNNNNNNd.  ...'collc:cclloodd, ...............,,.....';looooodl'.........  ,xXNNNNNNNNNNNN
NNNNNNNNNNNNN0c.  ...;oxdddddddxxoc'................':lcccldddxxxxdc..........  .l0XNNNNNNNNNNNN
NNNNNNNNNNNNNNXOl'. ..,ldxxxxxxd:.....................,clodxxxxxdc,.............  ,ONNNNNNNNNNNN
NNNNNNNNNNNNNNNNN0:.....,coddoc'........................';:ccc:,...............  .cKNNNNNNNNNNNN
NNNNNNNNNNNNNNNNN0:..........................................................   .cKNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNKd'.................         ..........................     .;xKNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNKo'. ...........                ..................     .,lOXNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNKx:.. ............        .................    ...;lx0XNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNN0x:.. ............  ................       ,kOKXNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNXKxl:.     ....   ............       ..  'd0XNNNNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNNNNN0o.                            .....   ..:oOXNNNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNNN0d:.... ...  ..................................:xKNNNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNNNKo'................................................,dKNNNNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNNNNKd'  ............................................. ..  ,oOXNNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNNNN0o'. ................................................    ...lKNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNNXOl. ...................................................... .';l0NNNNNNNNNNNNN
NNNNNNNNNNNNNNNNNKl.  ........................................................  'dXNNNNNNNNNNNNN
NNNNNNNNNNNNNNNNO;  .... .............................................  .......  .:ONNNNNNNNNNNN
NNNNNNNNNNNNNNNO,  ..... .............................................  ........   ;0NNNNNNNNNNN
*/