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
    output lcd_spi_cs,
    output lcd_cm_da,

    //status
    output sys_wait_led,

    //UART pins
    //output uart_tx,
    input uart_rx,

    //debug
    output [2:0]ip_c_state,
    output wire [3:0]lcd_cmd,
    output wire [3:0]sd_cmd,

    output uart_samp
);

wire [3:0]SD_if_im_idx_fast;
wire SD_if_init_fast;
wire SD_if_send_rd_cmd_fast;
wire SD_if_stream_fast;
wire SD_if_end_of_frame_fast;
wire SD_if_begin_fast;
wire SD_if_busy_fast;


wire [3:0]SD_if_im_idx_slow;
wire SD_if_init_slow;
wire SD_if_send_rd_cmd_slow;
wire SD_if_stream_slow;
wire SD_if_end_of_frame_slow;
wire SD_if_begin_slow;
wire SD_if_busy_slow;

wire [4:0]sd_if_ctl_sync;
wire sd_if_begin_allow;
assign sd_if_begin_allow = &sd_if_ctl_sync;

cdc_dff_f2s sd_if_cdc_0(
    /*input wire */.rst_n(rst_n),
    /*input wire */.clk_slow(clk_1M),
    /*output wire */.data_out(SD_if_init_slow),
    /*input wire */.data_in(SD_if_init_fast));
cdc_dff_f2s sd_if_cdc_1(
    /*input wire */.rst_n(rst_n),
    /*input wire */.clk_slow(clk_1M),
    /*output wire */.data_out(SD_if_send_rd_cmd_slow),
    /*input wire */.data_in(SD_if_send_rd_cmd_fast));
cdc_dff_f2s sd_if_cdc_2(
    /*input wire */.rst_n(rst_n),
    /*input wire */.clk_slow(clk_1M),
    /*output wire */.data_out(SD_if_stream_slow),
    /*input wire */.data_in(SD_if_stream_fast));
cdc_dff_f2s sd_if_cdc_3(
    /*input wire */.rst_n(rst_n),
    /*input wire */.clk_slow(clk_1M),
    /*output wire */.data_out(SD_if_end_of_frame_slow),
    /*input wire */.data_in(SD_if_end_of_frame_fast));
cdc_dff_f2s sd_if_cdc_4(
    /*input wire */.rst_n(rst_n),
    /*input wire */.clk_slow(clk_1M),
    /*output wire */.data_out(SD_if_begin_slow),
    /*input wire */.data_in(SD_if_begin_fast));

cdc_dff_f2s_x4 sd_imid_0(
    /*input wire */.rst_n(rst_n),
    /*input wire */.clk_slow(clk_1M),
    /*output wire */.data_out(SD_if_im_idx_slow),
    /*input wire */.data_in(SD_if_im_idx_fast));

assign SD_if_busy_fast = SD_if_busy_slow;

wire LCD_if_init_fast;
wire LCD_if_send_px_cmd_fast;
wire LCD_if_stream_fast;
wire LCD_if_end_of_frame_fast;
wire LCD_if_begin_fast;
wire LCD_if_busy_fast;

wire LCD_if_init_slow;
wire LCD_if_send_px_cmd_slow;
wire LCD_if_stream_slow;
wire LCD_if_end_of_frame_slow;
wire LCD_if_begin_slow;
wire LCD_if_busy_slow;

wire [3:0]lcd_if_ctl_sync;
wire lcd_if_begin_allow;
assign lcd_if_begin_allow = &lcd_if_ctl_sync;


cdc_dff_f2s lcd_if_cdc_0(
    /*input wire */.rst_n(rst_n),
    /*input wire */.clk_slow(clk_1M),
    /*output wire */.data_out(LCD_if_init_slow),
    /*input wire */.data_in(LCD_if_init_fast));
cdc_dff_f2s lcd_if_cdc_1(
    /*input wire */.rst_n(rst_n),
    /*input wire */.clk_slow(clk_1M),
    /*output wire */.data_out(LCD_if_send_px_cmd_slow),
    /*input wire */.data_in(LCD_if_send_px_cmd_fast));
cdc_dff_f2s lcd_if_cdc_2(
    /*input wire */.rst_n(rst_n),
    /*input wire */.clk_slow(clk_1M),
    /*output wire */.data_out(LCD_if_stream_slow),
    /*input wire */.data_in(LCD_if_stream_fast));
cdc_dff_f2s lcd_if_cdc_3(
    /*input wire */.rst_n(rst_n),
    /*input wire */.clk_slow(clk_1M),
    /*output wire */.data_out(LCD_if_end_of_frame_slow),
    /*input wire */.data_in(LCD_if_end_of_frame_fast));
cdc_dff_f2s lcd_if_cdc_4(
    /*input wire */.rst_n(rst_n),
    /*input wire */.clk_slow(clk_1M),
    /*output wire */.data_out(LCD_if_begin_slow),
    /*input wire */.data_in(LCD_if_begin_fast));

assign LCD_if_busy_fast = LCD_if_busy_slow;



wire CTL_if_decr;
wire CTL_if_incr;
wire CTL_if_valid;
wire CTL_if_ready;

d_pic_f main_fsm(
    /*input */.clk_4M(clk_4M),
    /*input */.rst_n(rst_n),

    //SD if port
    /*output [3:0]*/.SD_if_im_idx(SD_if_im_idx_fast),
    /*output */.SD_if_init(SD_if_init_fast),
    /*output */.SD_if_send_rd_cmd(SD_if_send_rd_cmd_fast),
    /*output */.SD_if_stream(SD_if_stream_fast),
    /*output */.SD_if_end_of_frame(SD_if_end_of_frame_fast),
    /*output */.SD_if_begin(SD_if_begin_fast),
    /*input */.SD_if_busy(SD_if_busy_fast),
    
    //LCD if port
    /*output */.LCD_if_init(LCD_if_init_fast),
    /*output */.LCD_if_send_px_cmd(LCD_if_send_px_cmd_fast),
    /*output */.LCD_if_stream(LCD_if_stream_fast),
    /*output */.LCD_if_end_of_frame(LCD_if_end_of_frame_fast),
    /*output */.LCD_if_begin(LCD_if_begin_fast),
    /*input */.LCD_if_busy(LCD_if_busy_fast),

    //UART control port
    /*input */.ctl_decr(CTL_if_decr),
    /*input */.ctl_incr(CTL_if_incr),
    /*input */.ctl_valid(CTL_if_valid),
    /*output */.ctl_ready(CTL_if_ready),

    //ip status report
    /*output */.sys_wait_led(sys_wait_led),
    /*output [2:0]*/.ip_c_state(ip_c_state)
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
    /*input */.init(SD_if_init_slow),         //init SD card
    /*input */.read_cmd(SD_if_send_rd_cmd_slow),     //send read command for blk_addr
    /*input */.stream_512B(SD_if_stream_slow),   //stream 512 bytes at 4 bytes each stream trigger
    /*input */.end_of_frame(SD_if_end_of_frame_slow),   //stream 512 bytes at 4 bytes each stream trigger

    //flow control
    /*input [3:0]*/.img_id(SD_if_im_idx_slow),
    /*input */.if_begin(SD_if_begin_slow),
    /*output */.if_busy(SD_if_busy_slow),

    //data stream
    /*output [31:0]*/.stream_data({stream_data[23:16],stream_data[31:24],stream_data[7:0],stream_data[15:8]}),
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


assign sd_cmd = {SD_if_end_of_frame_slow,SD_if_stream_slow,SD_if_send_rd_cmd_slow,SD_if_init_slow};


spi_front sd_phy_0(
    .spi_clk_in(clk_1M),
    .rst_n(rst_n),

    //spi interface
    .spi_clk_o(sd_spi_clk),
    .spi_mosi_o(sd_spi_mosi),
    .spi_miso_i(sd_spi_miso),

    //data interface
    .data_mosi(sd_spi_mosi_d),
    .data_miso(sd_spi_miso_d),

    //control interface
    .spi_begin(sd_spi_begin),
    .spi_wide(sd_spi_wide),
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
    .init(LCD_if_init_slow),             //initialize LCD
    .px_stream_cmd(LCD_if_send_px_cmd_slow),    //transmit pixel commands
    .stream_512B(LCD_if_stream_slow),      //stream 512 bytes at 4 bytes each stream trigger
    .end_of_frame(LCD_if_end_of_frame_slow),      //pull high when initiating the last block transfer.

    //flow control
    .if_begin(LCD_if_begin_slow),
    .if_busy(LCD_if_busy_slow),

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

assign lcd_cmd = {LCD_if_stream_slow,LCD_if_end_of_frame_slow,LCD_if_send_px_cmd_slow,LCD_if_init_slow};


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


uart_front #(
    .p_baud_rate(250000.0),
    .p_clk_freq(5000000.0)
) dut(
    .clk(clk_1M),
    .rst_n(rst_n),

    //uart interface
    .uart_rx(uart_rx),

    //data interface
    .data_rx(uart_rx_d),

    //control interface
    .uart_valid(uart_valid),
    .uart_ready(uart_ready),
    .uart_samp(uart_samp)
);

ctl_if dut_1(
    .clk(clk_1M),
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