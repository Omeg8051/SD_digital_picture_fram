
module d_pic_f (
    input clk_4M,
    input clk_1M,
    input rst_n,

    //SD if port
    output [3:0]SD_if_im_idx,
    output SD_if_init,
    output SD_if_send_rd_cmd,
    output SD_if_stream,
    output SD_if_end_of_frame,
    output SD_if_begin,
    input SD_if_busy,
    
    //LCD if port
    output LCD_if_init,
    output LCD_if_send_px_cmd,
    output LCD_if_stream,
    output LCD_if_end_of_frame,
    output LCD_if_begin,
    input LCD_if_busy,

    //UART control port
    input ctl_decr,
    input ctl_incr,
    input ctl_valid,
    output ctl_ready,

    //ip status report
    output sys_wait_led
);

/*
state encoding:
one bit per state(use parallel case)
*/

/*
##init_peripheral
(reset from any_state to here.)

Behavior:
    Command each spi controllers to initiallize their respective peripherals.

Transition to blk_offset_reset:
    After all peripheral module reports not busy.
*/

/*
##blk_offset_reset

Behavior:
    Set $blk_offset to 0

Transition to start_SD_blk_read:
    On the next clock
*/

/*
##start_SD_blk_read

Behavior:
    Send SD blk read command (on blk address $blk_id + $blk_offset)
    Send ILI9341 data transfer sequence

Transition to stream_data_2_lcd:
    After SD_interface reports not busy. (Got data token FEh)
    and after LCD_interface reports not bust. (Data transfer sequence complete)
*/

/*
##stream_data_2_lcd

Behavior:
    Stream 512 bytes block in 4 bytes words from SD to LCD.

Transition to dispose_2b_crc:
    After SD_interface reports not busy. (512 bytes read)
    and after LCD_interface reports not bust. (512 bytes written)
*/

/*
##dispose_2b_crc

Behavior:
    Read 2B CRC from SD card
    increment $blk_offset

Transition to start_SD_blk_read:
    After SD_interface reports not busy. (2 bytes read)
    and $blk_offset < 300

Transition to wait_4_uart:
    After SD_interface reports not busy. (2 bytes read)
    and $blk_offset >= 300
*/

/*
##wait_4_uart

Behavior:
    Stay here untill any of the UART operation bits got set.
    Respond (set) UART ack bit.

Transition to blk_idx_mod:
    Either pic_incr or pic_decr is set.
*/

/*
##blk_idx_mod

Behavior:
    Modify $blk_id according to uart_op bits
    Clear UART ack bit.

Transition to blk_offset_reset:
    On next clock.
*/

//interaction bit list
//include command bits
localparam sd_bit_p_on = 16'd64;//6B cmd0 + 1B FFh + 1B R1
localparam sd_bit_init_0 = 16'd128;//6B cmd55 + 1B FFh + 1B R1 + 6B acmd41 + 1B FFh + 1B R1
localparam sd_bit_ready = 16'd64;//6B cmd17/18 + 1B FFh + 1B R1
localparam sd_bit_s_blk_setup = 16'd1200;//149B FFh + 1B FEh
localparam sd_bit_s_blk_rd = 16'd4112;//512B 5Ah + 2B 69h


localparam PIC_STATE_init_perph = 3'h0;
localparam PIC_STATE_img_id = 3'h1;
localparam PIC_STATE_sd_lcd_cmd = 3'h2;
localparam PIC_STATE_sd_cmd = 3'h3;
localparam PIC_STATE_stream = 3'h4;
localparam PIC_STATE_wait_uart = 3'h5;




//output reg
reg [3:0] SD_if_im_idx_r;
reg SD_if_init_r;
reg SD_if_send_rd_cmd_r;
reg SD_if_stream_r;
reg end_of_frame_r;
reg SD_if_begin_r;
reg LCD_if_init_r;
reg LCD_if_send_px_cmd_r;
reg LCD_if_stream_r;
reg LCD_if_begin_r;
reg ctl_ready_r;

assign SD_if_im_idx = SD_if_im_idx_r;
assign SD_if_init = SD_if_init_r;
assign SD_if_send_rd_cmd = SD_if_send_rd_cmd_r;
assign SD_if_stream = SD_if_stream_r;
assign SD_if_end_of_frame = end_of_frame_r;
assign SD_if_begin = SD_if_begin_r;
assign LCD_if_init = LCD_if_init_r;
assign LCD_if_send_px_cmd = LCD_if_send_px_cmd_r;
assign LCD_if_stream = LCD_if_stream_r;
assign LCD_if_end_of_frame = end_of_frame_r;
assign LCD_if_begin = LCD_if_begin_r;
assign ctl_ready = ctl_ready_r;
//sys busy led driver
assign sys_wait_led = ~|(pic_state ^ PIC_STATE_wait_uart);

//input sample reg


reg SD_if_busy_r;
reg LCD_if_busy_r;

reg ctl_decr_r;
reg ctl_incr_r;
reg ctl_valid_r;


//internal reg
reg [2:0] pic_state;
reg [8:0] stream_op_cnt_r;
wire [8:0] stream_op_cnt_next;
assign stream_op_cnt_next = stream_op_cnt_r - 9'b1;
wire stream_op_nz;
assign stream_op_nz = |stream_op_cnt_r;

wire [3:0] im_idx_decr;
assign im_idx_decr = SD_if_im_idx_r - 4'h1;
wire [3:0] im_idx_incr;
assign im_idx_incr = SD_if_im_idx_r + 4'h1;

wire if_busy;
assign if_busy = SD_if_busy_r | LCD_if_busy_r;

wire if_begin;
assign if_begin = SD_if_begin_r | LCD_if_begin_r;

always @(posedge clk_4M ) begin

    //input sample blk
    
    SD_if_busy_r <= SD_if_busy;
    LCD_if_busy_r <= LCD_if_busy;
    ctl_decr_r <= ctl_decr;
    ctl_incr_r <= ctl_incr;
    ctl_valid_r <= ctl_valid;
end



/*
state transition beyond this point
*/

always @(posedge clk_4M or negedge rst_n) begin
    if(~rst_n) begin
        pic_state <= PIC_STATE_init_perph;

        stream_op_cnt_r = 9'b0;

        SD_if_im_idx_r <= 4'h0;
        SD_if_init_r <= 1'b1;               //init routine set to 1
        SD_if_send_rd_cmd_r <= 1'b0;
        SD_if_stream_r <= 1'b0;
        end_of_frame_r <= 1'b0;
        SD_if_begin_r <= 1'b1;              //init routine set to 1
        LCD_if_init_r <= 1'b1;              //init routine set to 1
        LCD_if_send_px_cmd_r <= 1'b0;
        LCD_if_stream_r <= 1'b0;
        LCD_if_begin_r <= 1'b1;             //init routine set to 1
        ctl_ready_r <= 1'b0;

    end else begin

        case (pic_state)
            PIC_STATE_init_perph: begin
                if(~if_busy & ~if_begin) begin
                    //objective complete
                    //start next and switch state
                    pic_state <= PIC_STATE_sd_lcd_cmd;

                    SD_if_begin_r <= 1'b1;
                    SD_if_send_rd_cmd_r <= 1'b1;
                    LCD_if_begin_r <= 1'b1;
                    LCD_if_send_px_cmd_r <= 1'b1;

                end else if(if_busy & if_begin) begin
                    //begin retract
                    SD_if_init_r <= 1'b0;
                    SD_if_begin_r <= 1'b0;
                    LCD_if_init_r <= 1'b0;
                    LCD_if_begin_r <= 1'b0;
                end
            end 
            PIC_STATE_sd_lcd_cmd: begin
                if(~if_busy & ~if_begin) begin
                    //objective complete
                    //start next and switch state
                    pic_state <= PIC_STATE_stream;
                    stream_op_cnt_r <= 9'd300;

                    SD_if_begin_r <= 1'b1;
                    SD_if_stream_r <= 1'b1;
                    end_of_frame_r <= 1'b0;
                    LCD_if_begin_r <= 1'b1;
                    LCD_if_stream_r <= 1'b1;
                end else if(if_busy & if_begin) begin
                    //begin retract
                    SD_if_begin_r <= 1'b0;
                    SD_if_send_rd_cmd_r <= 1'b0;
                    LCD_if_begin_r <= 1'b0;
                    LCD_if_send_px_cmd_r <= 1'b0;
                end
            end 
            PIC_STATE_sd_cmd: begin
                if(~if_busy & ~if_begin) begin
                    //objective complete
                    //start next and switch state
                    pic_state <= PIC_STATE_stream;

                    SD_if_begin_r <= 1'b1;
                    SD_if_stream_r <= 1'b1;
                    LCD_if_begin_r <= 1'b1;
                    LCD_if_stream_r <= 1'b1;

                end else if(if_busy & if_begin) begin
                    //begin retract
                    SD_if_begin_r <= 1'b0;
                    SD_if_send_rd_cmd_r <= 1'b0;
                    end_of_frame_r <= ~|stream_op_cnt_next;
                end
            end 
            PIC_STATE_stream: begin
                if(~if_busy & ~if_begin) begin
                    //objective complete
                    //start next and switch state
                    if(stream_op_nz)begin
                        pic_state <= PIC_STATE_sd_cmd;

                        SD_if_begin_r <= 1'b1;
                        SD_if_send_rd_cmd_r <= 1'b1;

                    end else begin
                        pic_state <= PIC_STATE_wait_uart;
                        ctl_ready_r <= 1'b1;
                        
                    end
                end else if(if_busy & if_begin) begin
                    //begin retract
                    stream_op_cnt_r <= stream_op_cnt_next;
                    SD_if_begin_r <= 1'b0;
                    SD_if_stream_r <= 1'b0;
                    LCD_if_begin_r <= 1'b0;
                    LCD_if_stream_r <= 1'b0;
                    end_of_frame_r <= 1'b0;
                end
            end 
            PIC_STATE_wait_uart: begin
                if(ctl_ready_r & ctl_valid_r) begin
                    //objective complete
                    //start next and switch state
                    pic_state <= PIC_STATE_sd_lcd_cmd;
                    ctl_ready_r <= 1'b1;
                    case ({ctl_incr_r, ctl_decr_r})
                        2'b01: SD_if_im_idx_r <= im_idx_decr;
                        2'b10: SD_if_im_idx_r <= im_idx_incr;
                        default: SD_if_im_idx_r <= SD_if_im_idx_r;
                    endcase
                

                end else begin
                    pic_state <= pic_state;
                end
            end 
            default: begin
                pic_state <= PIC_STATE_init_perph;

                stream_op_cnt_r = 9'b0;

                SD_if_im_idx_r <= 4'h0;
                SD_if_init_r <= 1'b1;               //init routine set to 1
                SD_if_send_rd_cmd_r <= 1'b0;
                SD_if_stream_r <= 1'b0;
                end_of_frame_r <= 1'b0;
                SD_if_begin_r <= 1'b1;              //init routine set to 1
                LCD_if_init_r <= 1'b1;              //init routine set to 1
                LCD_if_send_px_cmd_r <= 1'b0;
                LCD_if_stream_r <= 1'b0;
                end_of_frame_r <= 1'b0;
                LCD_if_begin_r <= 1'b1;             //init routine set to 1
                ctl_ready_r <= 1'b0;
            end

        endcase
        
    end
end

/**
*8==================================================================================D
*8==================================================================================D
*8===================                                             ==================D
*8=================      REMEMBER TO DO STREAM BYTR REORDERING      ================D
*8===================                                             ==================D
*8==================================================================================D
*8==================================================================================D
*/



endmodule
