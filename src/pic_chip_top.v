module pic_chip_top (
    input clk_1M,
    input clk_4M,
    input rst_n,

    //SD spi
    output sd_spi_clk,
    output sd_spi_mosi,
    input sd_spi_miso,
    output sd_spi_cs,

    //LCD spi
    output lcd_spi_clk,
    output lcd_spi_mosi,
    input lcd_spi_miso,
    output lcd_spi_cs,
    output lcd_cm_da,

    //status
    output sys_wait_led,

    //UART pins
    output uart_tx,
    input uart_rx
);

wire [3:0]SD_if_im_idx;
wire SD_if_init;
wire SD_if_send_rd_cmd;
wire SD_if_stream;
wire SD_if_end_of_frame;
wire SD_if_begin;

wire LCD_if_init;
wire LCD_if_send_px_cmd;
wire LCD_if_stream;
wire LCD_if_end_of_frame;
wire LCD_if_begin;

wire CTL_if_decr;
wire CTL_if_incr;
wire CTL_if_valid;
wire CTL_if_ready;

d_pic_f main_fsm(
    /*input */.clk_4M(clk_4M),
    /*input */.clk_1M(clk_1M),
    /*input */.rst_n(rst_n),

    //SD if port
    /*output [3:0]*/.SD_if_im_idx(SD_if_im_idx),
    /*output */.SD_if_init(SD_if_init),
    /*output */.SD_if_send_rd_cmd(SD_if_send_rd_cmd),
    /*output */.SD_if_stream(SD_if_stream),
    /*output */.SD_if_end_of_frame(SD_if_end_of_frame),
    /*output */.SD_if_begin(SD_if_begin),
    /*input */.SD_if_busy(SD_if_busy),
    
    //LCD if port
    /*output */.LCD_if_init(LCD_if_init),
    /*output */.LCD_if_send_px_cmd(LCD_if_send_px_cmd),
    /*output */.LCD_if_stream(LCD_if_stream),
    /*output */.LCD_if_end_of_frame(LCD_if_end_of_frame),
    /*output */.LCD_if_begin(LCD_if_begin),
    /*input */.LCD_if_busy(LCD_if_busy),

    //UART control port
    /*input */.ctl_decr(CTL_if_decr),
    /*input */.ctl_incr(CTL_if_incr),
    /*input */.ctl_valid(CTL_if_valid),
    /*output */.ctl_ready(CTL_if_ready),

    //ip status report
    /*output */.sys_wait_led(sys_wait_led)
);


wire sd_spi_begin;
wire sd_spi_busy;
wire sd_spi_wide;
wire [31:0]sd_spi_mosi_d;
wire [31:0]sd_spi_miso_d;


sd_if sd_if_0(
    /*input */.clk(clk_1M),
    /*input */.rst_n(rst_n),
    
    //actions
    /*input */.init(SD_if_init),         //init SD card
    /*input */.read_cmd(SD_if_send_rd_cmd),     //send read command for blk_addr
    /*input */.stream_512B(SD_if_stream),   //stream 512 bytes at 4 bytes each stream trigger
    /*input */.end_of_frame(SD_if_end_of_frame),   //stream 512 bytes at 4 bytes each stream trigger

    //flow control
    /*input [3:0]*/.img_id(SD_if_im_idx),
    /*input */.if_begin(SD_if_begin),
    /*output */.if_busy(SD_if_busy),

    //data stream
    /*output [31:0]*/.stream_data({stream_data_w[23:16],stream_data_w[31:24],stream_data_w[7:0],stream_data_w[15:8]}),
    /*output */.stream_trigger(stream_trigger),
    /*input */.stream_busy(stream_busy),      //pull high when initiating the last block transfer.


    //spi phy
    /*output [31:0]*/.spi_mosi(sd_spi_mosi_d),
    /*input [31:0]*/.spi_miso(sd_spi_miso_d),
    /*output */.spi_begin(sd_spi_begin),
    /*input */.spi_busy(sd_spi_busy),
    /*output */.spi_wide(sd_spi_wide),
    /*output */.spi_cs(sd_spi_cs)
);


spi_front sd_phy_0(
    .spi_clk_in(clk_1M),
    .rst_n(rst_n),

    //spi interface
    .spi_clk_o(sd_spi_clk),
    .spi_mosi_o(spi_bus_mosi),
    .spi_miso_i(spi_bus_miso),

    //data interface
    .data_mosi(sd_spi_mosi_d),
    .data_miso(sd_spi_miso_d),

    //control interface
    .spi_begin(sd_spi_begin),
    .spi_wide(sd_spi_wide),
    //.spi_wide(1'b0),
    .spi_busy(sd_spi_busy)
);

wire lcd_spi_begin;
wire lcd_spi_busy;
wire lcd_spi_wide;
wire [31:0]lcd_spi_mosi_d;
wire [31:0]stream_data;
wire stream_busy;
wire stream_trigger;

wire lcd_busy;

lcd_if lcd_if_0(
    .clk(clk_1M),
    .rst_n(rst_n),
    
    //actions
    .init(LCD_if_init),             //initialize LCD
    .px_stream_cmd(LCD_if_send_px_cmd),    //transmit pixel commands
    .stream_512B(LCD_if_stream),      //stream 512 bytes at 4 bytes each stream trigger
    .end_of_frame(LCD_if_end_of_frame),      //pull high when initiating the last block transfer.

    //flow control
    .if_begin(LCD_if_begin),
    .if_busy(LCD_if_busy),

    //data stream
    .stream_data(stream_data),
    .stream_trigger(stream_trigger),
    .stream_busy(stream_busy),

    //lcd control pin
    .lcd_data_cmd(lcd_cm_da),

    //spi phy
    .spi_mosi(lcd_spi_mosi_d),
    //input [31:0]spi_miso, This IF output only. No read back
    .spi_begin(lcd_spi_begin),
    .spi_wide(lcd_spi_wide),
    .spi_busy(lcd_spi_busy),
    .spi_cs(lcd_spi_cs)
);


spi_front lcd_phy_0(
    .spi_clk_in(clk_1M),
    .rst_n(rst_n),

    //spi interface
    .spi_clk_o(lcd_spi_clk),
    .spi_mosi_o(lcd_spi_mosi),
    .spi_miso_i(1'b1),

    //data interface
    .data_mosi(lcd_spi_mosi_d),
    //.data_miso(spi_phy1_miso),

    //control interface
    .spi_begin(lcd_spi_begin),
    .spi_wide(lcd_spi_wide),
    .spi_busy(lcd_spi_busy)
);

wire [7:0]uart_rx_d ;
wire uart_valid;
wire uart_ready;


uart_front dut(
    .clk(clk_1M),
    .rst_n(rst_n),

    //uart interface
    .uart_rx(uart_rx),

    //data interface
    .data_rx(uart_rx_d),

    //control interface
    .uart_valid(uart_valid),
    .uart_ready(uart_ready)//,
);

ctl_if dut_1(
    .clk(clk),
    .rst_n(rst_n),

    //uart interface
    .uart_rx(uart_rx_d),
    .uart_valid(uart_valid),
    .uart_ready(uart_ready),

    //control interface
    .ctl_valid(CTL_if_valid),
    .ctl_ready(CTL_if_ready),
    .ctl_incr(CTL_if_incr),
    .ctl_decr(CTL_if_decr)
);



    
endmodule