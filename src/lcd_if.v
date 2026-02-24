
module lcd_if (
    input clk,
    input rst_n,
    
    //actions
    input init,             //initialize LCD
    input px_stream_cmd,    //transmit pixel commands
    input stream_512B,      //stream 512 bytes at 4 bytes each stream trigger
    input end_of_frame,      //pull high when initiating the last block transfer.
    //input [4:0]img_id,      //max image count is 32 for a minimum 4GiB card

    //flow control
    input if_begin,
    output if_busy,

    //data stream
    input [31:0]stream_data,
    input stream_trigger,
    output stream_busy,

    //lcd control pin
    output lcd_data_cmd,

    //spi phy
    output [31:0]spi_mosi,
    //input [31:0]spi_miso, This IF output only. No read back
    output spi_begin,
    input spi_busy,
    output spi_wide,
    output spi_cs

);

localparam LCD_STATE_idle = 3'h0;
localparam LCD_STATE_init = 3'h1;
localparam LCD_STATE_send_px = 3'h2;
localparam LCD_STATE_wait_stream = 3'h4;
localparam LCD_STATE_tx_4B = 3'h5;


localparam LCD_OP_BITS_init = 3'b001;
localparam LCD_OP_BITS_px_cmd = 3'b010;
localparam LCD_OP_BITS_stream = 3'b100;

localparam LCD_CMD_DEL_250MS_COUNT = 20'd250000;//assuming 1MHz clk
localparam LCD_CMD_DEL_50MS_COUNT = 20'd5000;//assuming 1MHz clk


(* dont_touch = "true" *)wire [2:0]lcd_op_bits;
assign lcd_op_bits = {stream_512B,px_stream_cmd,init};


(* dont_touch = "true" *)reg [2:0]lcd_state;
reg [2:0]lcd_op_bits_r;
reg [31:0]stream_data_r;
reg [7:0]state_op_cnt;
wire [7:0]state_op_cnt_next;
assign state_op_cnt_next = state_op_cnt + 8'h1;
reg [7:0]state_op_top;
wire state_op_term;
assign state_op_term = ~|(state_op_cnt ^ state_op_top); //state terminate after state_op_cnt == state_op_top.
assign spi_begin_term = |(state_op_cnt_next ^ state_op_top); //state terminate after state_op_cnt == state_op_top.



//spi control sigs
reg spi_wide_r;
reg spi_begin_r;
reg spi_cs_r;
reg [31:0]spi_mosi_r;
reg lcd_data_cmd_r;
reg [19:0]lcd_cmd_del_cnt;

assign spi_cs = spi_cs_r;// output wired to register.
assign spi_wide = spi_wide_r;// output wired to register.
assign spi_begin = spi_begin_r;// output wired to register.
assign spi_mosi = spi_mosi_r;// output wired to register.
assign lcd_data_cmd = lcd_data_cmd_r;// output wited to register.

wire lcd_cmd_del_cnt_nz;
assign lcd_cmd_del_cnt_nz = |lcd_cmd_del_cnt;

//encoding scheme:
//{x,delay_250_ms,delay_50ms,command_is_data,payload[7:0]}
reg [11:0]lcd_px_routine_seq[10:0];
reg [11:0]lcd_init_routine_seq[49:0];

always @(negedge rst_n ) begin
    lcd_px_routine_seq[0] <= {4'h0,8'h2A};
    lcd_px_routine_seq[1] <= {4'h1,8'h00};
    lcd_px_routine_seq[2] <= {4'h1,8'h00};
    lcd_px_routine_seq[3] <= {4'h1,8'h01};
    lcd_px_routine_seq[4] <= {4'h1,8'h3F};
    lcd_px_routine_seq[5] <= {4'h0,8'h2B};
    lcd_px_routine_seq[6] <= {4'h1,8'h00};
    lcd_px_routine_seq[7] <= {4'h1,8'h00};
    lcd_px_routine_seq[8] <= {4'h1,8'h00};
    lcd_px_routine_seq[9] <= {4'h1,8'hEF};
    lcd_px_routine_seq[10] <= {4'h0,8'h2C};

    lcd_init_routine_seq[0] <=  {4'h0,  8'hCB};
    lcd_init_routine_seq[1] <=  {4'h1,	8'h39};
    lcd_init_routine_seq[2] <=  {4'h1,	8'h2C};
    lcd_init_routine_seq[3] <=  {4'h1,	8'h00};
    lcd_init_routine_seq[4] <=  {4'h1,	8'h34};
    lcd_init_routine_seq[5] <=  {4'h0,	8'h02};
    lcd_init_routine_seq[6] <=  {4'h0,	8'hCF};
    lcd_init_routine_seq[7] <=  {4'h1,	8'h00};
    lcd_init_routine_seq[8] <=  {4'h1,	8'hC1};
    lcd_init_routine_seq[9] <=  {4'h1,	8'h30};
    lcd_init_routine_seq[10] <= {4'h0,	8'hE8};
    lcd_init_routine_seq[11] <= {4'h1,	8'h85};
    lcd_init_routine_seq[12] <= {4'h1,	8'h00};
    lcd_init_routine_seq[13] <= {4'h1,	8'h78};
    lcd_init_routine_seq[14] <= {4'h0,	8'hEA};
    lcd_init_routine_seq[15] <= {4'h1,	8'h00};
    lcd_init_routine_seq[16] <= {4'h1,	8'h00};
    lcd_init_routine_seq[17] <= {4'h0,	8'hED};
    lcd_init_routine_seq[18] <= {4'h1,	8'h64};
    lcd_init_routine_seq[19] <= {4'h1,	8'h03};
    lcd_init_routine_seq[20] <= {4'h1,	8'h12};
    lcd_init_routine_seq[21] <= {4'h1,	8'h81};
    lcd_init_routine_seq[22] <= {4'h0,	8'hF7};
    lcd_init_routine_seq[23] <= {4'h1,	8'h20};
    lcd_init_routine_seq[24] <= {4'h0,	8'hC0};
    lcd_init_routine_seq[25] <= {4'h1,	8'h23};
    lcd_init_routine_seq[26] <= {4'h0,	8'hC1};
    lcd_init_routine_seq[27] <= {4'h1,	8'h10};
    lcd_init_routine_seq[28] <= {4'h0,	8'hC5};
    lcd_init_routine_seq[29] <= {4'h1,	8'h3E};
    lcd_init_routine_seq[30] <= {4'h1,	8'h28};
    lcd_init_routine_seq[31] <= {4'h0,	8'hC7};
    lcd_init_routine_seq[32] <= {4'h1,	8'h86};
    lcd_init_routine_seq[33] <= {4'h0,	8'h36};
    lcd_init_routine_seq[34] <= {4'h1,	8'h80};
    lcd_init_routine_seq[35] <= {4'h0,	8'h3A};
    lcd_init_routine_seq[36] <= {4'h1,	8'h55};
    lcd_init_routine_seq[37] <= {4'h0,	8'hB1};
    lcd_init_routine_seq[38] <= {4'h1,	8'h00};
    lcd_init_routine_seq[39] <= {4'h1,	8'h18};
    lcd_init_routine_seq[40] <= {4'h0,	8'hB6};
    lcd_init_routine_seq[41] <= {4'h1,	8'h08};
    lcd_init_routine_seq[42] <= {4'h1,	8'h82};
    lcd_init_routine_seq[43] <= {4'h1,	8'h27};
    lcd_init_routine_seq[44] <= {4'h0,	8'hF2};
    lcd_init_routine_seq[45] <= {4'h1,	8'h00};
    lcd_init_routine_seq[46] <= {4'h0,	8'h26};
    lcd_init_routine_seq[47] <= {4'h1,	8'h01};
    lcd_init_routine_seq[48] <= {4'h2,	8'h11};
    lcd_init_routine_seq[49] <= {4'h4,	8'h29};

end

/*
input sample block
*/
reg if_begin_r;
reg stream_trigger_r;
reg stream_busy_r;
reg end_of_frame_r;
assign stream_busy = stream_busy_r;
//reg spi_miso_r;
reg spi_busy_r;
//reg [31:0]blk_index;

always @(posedge clk) begin
    lcd_op_bits_r <= lcd_op_bits;
    if_begin_r <= if_begin;
    stream_data_r <= stream_data;
    stream_trigger_r <= stream_trigger;
    //spi_miso_r <= spi_miso;
    spi_busy_r <= spi_busy;
    end_of_frame_r <= end_of_frame;
end

//reg if_busy_r;
assign if_busy = |(lcd_state ^ LCD_STATE_idle);

reg last_frame_r;

/*
state transition beyond this point.
*/
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        lcd_state       <=  3'h0;
        state_op_cnt    <=  6'h0;
        state_op_top    <=  6'h0;
        last_frame_r    <=  1'b0;
        spi_cs_r        <=  1'b1;
        spi_begin_r     <=  1'b0;
        spi_wide_r      <=  1'b0;
        lcd_data_cmd_r  <=  1'b0;
        lcd_cmd_del_cnt <=  20'h0;
        spi_mosi_r      <= 32'h0;
        stream_busy_r <= 1'b0;
    end else begin
        case (lcd_state)
            LCD_STATE_idle: begin
                if(if_begin_r)begin
                    spi_cs_r        <= 1'b0; //transfer to active state always asserts chip select
                    case (lcd_op_bits_r)
                        LCD_OP_BITS_init : begin
                            lcd_state <= LCD_STATE_init;
                            state_op_cnt    <= 8'b0;
                            state_op_top <= 8'd51;
                            spi_cs_r        <=  1'b0;
                            spi_begin_r     <=  1'b0;
                            spi_wide_r      <=  1'b0;
                        end
                        LCD_OP_BITS_px_cmd : begin
                            lcd_state <= LCD_STATE_send_px;
                            state_op_cnt    <= 8'b0;
                            state_op_top <= 8'd12;
                            spi_cs_r        <=  1'b0;
                            spi_begin_r     <=  1'b0;
                            spi_wide_r      <=  1'b0;
                        end
                        LCD_OP_BITS_stream : begin
                            lcd_state <= LCD_STATE_wait_stream;
                            state_op_cnt    <= 8'b0;
                            state_op_top <= 8'd128;//128 transfer for 4B each
                            lcd_data_cmd_r  <=  1'b1;
                            spi_cs_r        <=  1'b0;
                            last_frame_r    <=  end_of_frame_r;
                        end 
                        default: begin
                            lcd_state <= LCD_STATE_idle;
                        end
                    endcase
                    
                    //setup for next state
                end else begin
                    //state routine

                end
            end
            LCD_STATE_init: begin
                //work finish only after all sequence done and 
                if(state_op_term & ~spi_busy_r)begin
                    lcd_state <= LCD_STATE_idle;
                    spi_begin_r <= 1'b0;
                    spi_cs_r <= 1'b1;
                    //setup for next state
                end else begin
                    //state routine
                    if(spi_busy_r & spi_begin_r)begin
                        //Deasserts begin_r to wait for spi to complete;
                        spi_begin_r <= 1'b0;
                    end else if(lcd_cmd_del_cnt_nz)begin
                        //Count down if there is delay issued in the sequence modifier bits.
                        lcd_cmd_del_cnt <= lcd_cmd_del_cnt - 20'h1;
                    end else if(~spi_busy_r & ~spi_begin_r & ~state_op_term)begin
                        /*
                        advance state op counter
                        load current transfer from sequence
                        set del_cnt if sequence has delay modifier.
                        */
                        state_op_cnt <= state_op_cnt_next;//Only increment if not term yet;
                        spi_mosi_r <= {24'h0,lcd_init_routine_seq[state_op_cnt][7:0]};
                        spi_begin_r <= spi_begin_term;
                        lcd_data_cmd_r <= lcd_init_routine_seq[state_op_cnt][8];
                        `ifndef DISABLE_DELAY
                        if(lcd_init_routine_seq[state_op_cnt][9])begin
                            lcd_cmd_del_cnt <= LCD_CMD_DEL_50MS_COUNT;
                        end else if(lcd_init_routine_seq[state_op_cnt][10])begin
                            lcd_cmd_del_cnt <= LCD_CMD_DEL_250MS_COUNT;
                        end else begin
                            lcd_cmd_del_cnt <= 20'h0;
                        end
                        `endif
                    end else begin
                        //do nothing?
                    end
                    


                end
            end
            LCD_STATE_send_px: begin
                //work finish only after all sequence done and 
                if(state_op_term & ~spi_busy_r)begin
                    lcd_state <= LCD_STATE_idle;
                    spi_begin_r <= 1'b0;
                    //setup for next state
                end else begin
                    //state routine
                    if(~spi_busy_r & ~spi_begin_r & ~state_op_term)begin
                        /*
                        advance state op counter
                        load current transfer from sequence
                        set del_cnt if sequence has delay modifier.
                        */
                        state_op_cnt <= state_op_cnt_next;//Only increment if not term yet;
                        spi_mosi_r <= {24'h0,lcd_px_routine_seq[state_op_cnt][7:0]};
                        spi_begin_r <= spi_begin_term;
                        lcd_data_cmd_r <= lcd_px_routine_seq[state_op_cnt][8];
                        `ifndef DISABLE_DELAY
                        if(lcd_px_routine_seq[state_op_cnt][9])begin
                            lcd_cmd_del_cnt <= LCD_CMD_DEL_50MS_COUNT;
                        end else if(lcd_px_routine_seq[state_op_cnt][10])begin
                            lcd_cmd_del_cnt <= LCD_CMD_DEL_250MS_COUNT;
                        end else begin
                            lcd_cmd_del_cnt <= 20'h0;
                        end
                        `endif
                    end else if(spi_busy_r & spi_begin_r)begin
                        //Deasserts begin_r to wait for spi to complete;
                        spi_begin_r <= 1'b0;
                    end else if(lcd_cmd_del_cnt_nz)begin
                        //Count down if there is delay issued in the sequence modifier bits.
                        lcd_cmd_del_cnt <= lcd_cmd_del_cnt - 20'h1;
                    end else begin
                        //do nothing?
                    end
                    


                end
            end
            LCD_STATE_wait_stream: begin
                /*if(state_op_term & ~spi_busy_r)begin
                    //setup for next state
                    lcd_state <= LCD_STATE_tx_4B;
                    spi_mosi_r <= stream_data_r;
                    spi_wide_r <= 1'b1;
                    spi_cs_r <= last_frame_r;//end of spi cs depends on if it is the last fram or not
                    //trigger transfer
                    spi_begin_r <= 1'b0;    
                end else */if(~spi_busy_r & stream_trigger_r)begin
                    //setup for next state
                    spi_mosi_r <= stream_data_r;
                    spi_wide_r <= 1'b1;
                    spi_cs_r <= last_frame_r;//end of spi cs depends on if it is the last fram or not
                    stream_busy_r <= 1'b1;
                    //trigger transfer
                    spi_begin_r <= 1'b1;    
                end else if(spi_busy_r & spi_begin_r) begin
                    //state routine
                    lcd_state <= LCD_STATE_tx_4B;
                    state_op_cnt <= state_op_cnt_next;
                    //retract trigger
                    spi_begin_r <= 1'b0;  
                    
                end
            end
            LCD_STATE_tx_4B: begin
                if(~spi_busy_r)begin
                    lcd_state <= state_op_term ? LCD_STATE_idle : LCD_STATE_wait_stream;
                    //setup for next state
                    stream_busy_r <= 1'b0;
                end else begin
                    //state routine
                    
                end
            end
            default: begin
                lcd_state       <=  3'h0;
                state_op_cnt    <=  8'h0;
                state_op_top    <=  8'h0;
                spi_cs_r        <= 1'b1;
            end
        endcase
    end
end

/*
init_seq beyond this point.
*/


/*
stream_special beyond this point.
*/



endmodule




/*
8'hxxx since it is 4 bit aligned and can be represeneted by 4 digits of HEX.
{x, delay 250ms, delay 50ms, is_data, data 8bit}
undocumented part that is necessary.
Nice job, ilitek.
    8'hCB,
	8'h39 | BYTE_IS_DATA,
	8'h2C | BYTE_IS_DATA,
	8'h00 | BYTE_IS_DATA,
	8'h34 | BYTE_IS_DATA,
	8'h02 | BYTE_IS_DATA,
	8'hCF,
	8'h00 | BYTE_IS_DATA,
	8'hC1 | BYTE_IS_DATA,
	8'h30 | BYTE_IS_DATA,
	8'hE8,
	8'h85 | BYTE_IS_DATA,
	8'h00 | BYTE_IS_DATA,
	8'h78 | BYTE_IS_DATA,
	8'hEA,
	8'h00 | BYTE_IS_DATA,
	8'h00 | BYTE_IS_DATA,
	8'hED,
	8'h64 | BYTE_IS_DATA,
	8'h03 | BYTE_IS_DATA,
	8'h12 | BYTE_IS_DATA,
	8'h81 | BYTE_IS_DATA,
	8'hF7,
	8'h20 | BYTE_IS_DATA,
	ILI9341_CMD_PWR_CTL_1,
	8'h23 | BYTE_IS_DATA,
	ILI9341_CMD_PWR_CTL_2,
	8'h10 | BYTE_IS_DATA,
	ILI9341_CMD_V_COM_CTL_1,
	8'h3E | BYTE_IS_DATA,
	8'h28 | BYTE_IS_DATA,
	ILI9341_CMD_V_COM_CTL_2,
	8'h86 | BYTE_IS_DATA,
	ILI9341_CMD_MEM_ACCESS_CTL,
	8'h80 | BYTE_IS_DATA,
	ILI9341_CMD_SET_PX_FMT,
	8'h55 | BYTE_IS_DATA,
	ILI9341_CMD_FRM_CTL_NRM,
	8'h00 | BYTE_IS_DATA,
	8'h18 | BYTE_IS_DATA,
	ILI9341_CMD_SET_DISP_FUNC,
	8'h08 | BYTE_IS_DATA,
	8'h82 | BYTE_IS_DATA,
	8'h27 | BYTE_IS_DATA,
	8'hF2,
	8'h00 | BYTE_IS_DATA,
	ILI9341_CMD_GAMMA_SET,
	8'h01 | BYTE_IS_DATA,
	ILI9341_CMD_EXIT_SLP | BYTE_DELAY_50_MS,
	ILI9341_CMD_DISP_ON | BYTE_DELAY_200_MS,
	ILI9341_CMD_NOP
*/

