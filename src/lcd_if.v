//cmd define
`define ILI9341_CMD_NOP								8'h00
`define ILI9341_CMD_SOFT_RST						8'h01
//read 4 bytes afterward
`define ILI9341_CMD_RD_DISP_ID						8'h04
//read 5 bytes afterward
`define ILI9341_CMD_RD_DISP_STAT					8'h09
//read 2 bytes afterward
`define ILI9341_CMD_RD_DISP_PMOD					8'h0A
//read 2 bytes afterward
`define ILI9341_CMD_RD_DISP_MADCTL					8'h0B
//read 2 bytes afterward
`define ILI9341_CMD_RD_DISP_PX_FMT					8'h0C
//read 2 bytes afterward
`define ILI9341_CMD_RD_DISP_IM_FMT					8'h0D
//read 2 bytes afterward
`define ILI9341_CMD_RD_DISP_SNG_MODE				8'h0E
//read 2 bytes afterward
`define ILI9341_CMD_SLF_DIAG_RESULT					8'h0F


`define ILI9341_CMD_ENTER_SLP						8'h10
`define ILI9341_CMD_EXIT_SLP						8'h11
`define ILI9341_CMD_PARTIAL_MODE					8'h12
`define ILI9341_CMD_NRM_DISP						8'h13


`define ILI9341_CMD_DISP_INV_OFF					8'h20
`define ILI9341_CMD_DISP_INV_ON						8'h21
//write 1 byte afterward
`define ILI9341_CMD_GAMMA_SET						8'h26
`define ILI9341_CMD_DISP_OFF						8'h28
`define ILI9341_CMD_DISP_ON							8'h29
//write 4 bytes afterward {start_addr_MSB	start_addr_LSB	end_addr_MSB	end_addr_LSB}
`define ILI9341_CMD_SET_CA							8'h2A
//write 4 bytes afterward {start_addr_MSB	start_addr_LSB	end_addr_MSB	end_addr_LSB}
`define ILI9341_CMD_SET_PA							8'h2B
//write 3*PX bytes afterward
`define ILI9341_CMD_WRITE_PX						8'h2C
//write 9 bytes afterward
//`define ILI9341_CMD_SET_COLOR						8'h2D
//read 4 bytes afterward
`define ILI9341_CMD_READ_PX							8'h2E


//write 4 bytes afterward {start_addr_MSB	start_addr_LSB	end_addr_MSB	end_addr_LSB}
`define ILI9341_CMD_SET_PARTIAL						8'h30
//write 6 bytes afterward {TFA_MSB	TFA_LSB	TSA_MSB	TSA_LSB	BFA_MSB	BFA_LSB}
`define ILI9341_CMD_V_SCROLL_DEF					8'h33
`define ILI9341_CMD_TEAR_LINE_OFF					8'h34
//write 1 byte afterward
`define ILI9341_CMD_TEAR_LINE_ON					8'h35
//write 1 byte afterward
`define ILI9341_CMD_MEM_ACCESS_CTL					8'h36
//write 2 bytes afterward {VSP_MSB	VSP_LSB}
`define ILI9341_CMD_START_V_SCROLL					8'h37
`define ILI9341_CMD_IDLE_OFF						8'h38
`define ILI9341_CMD_IDLE_ON							8'h39
//write 1 byte afterward
`define ILI9341_CMD_SET_PX_FMT						8'h3A
//write 3*PX bytes afterward
//`define ILI9341_CMD_WRITE_PX_C					8'h3C
//read 3*PX bytes afterward
//`define ILI9341_CMD_READ_PX_C						8'h3E


//write 2 bytes afterward
`define ILI9341_CMD_SET_TEAR_LINE					8'h44
//read 3 bytes afterward
`define ILI9341_CMD_GET_TEAR_LINE					8'h45


//write 1 byte afterward
`define ILI9341_CMD_SET_DISP_BRIT_LVL				8'h51
//read 2 bytes afterward
`define ILI9341_CMD_GET_DISP_BRIT_LVL				8'h52
//write 1 byte afterward
`define ILI9341_CMD_SET_CTRL_DISP					8'h53
//read 2 bytes afterward
`define ILI9341_CMD_GET_CTRL_DISP					8'h54


//ID
//read 2 bytes afterward
`define ILI9341_CMD_READ_ID_1						8'hDA
//read 2 bytes afterward
`define ILI9341_CMD_READ_ID_2						8'hDB
//read 2 bytes afterward
`define ILI9341_CMD_READ_ID_3						8'hDC
//read 4 bytes afterward
`define ILI9341_CMD_READ_ID_4						8'hDD


//ext cmd
//write 1 byte afterward
`define ILI9341_CMD_RGB_IF_CTL						8'hB0
//write 2 bytes afterward
`define ILI9341_CMD_FRM_CTL_NRM						8'hB1
//write 2 byte afterward
`define ILI9341_CMD_FRM_CTL_IDLE					8'hB2
//write 2 byte afterward
`define ILI9341_CMD_FRM_CTL_PART					8'hB3
//write 2 byte afterward
`define ILI9341_CMD_DISP_INV_CTL					8'hB4
//write 3 byte afterward
`define ILI9341_CMD_SET_DISP_FUNC					8'hB6
//write 1 byte afterward
`define ILI9341_CMD_SET_ENTRY_MODE					8'hB7


//write 1 byte afterward
`define ILI9341_CMD_PWR_CTL_1						8'hC0
//write 1 byte afterward
`define ILI9341_CMD_PWR_CTL_2						8'hC1
//write 2 byte afterward
`define ILI9341_CMD_V_COM_CTL_1						8'hC5
//write 2 byte afterward
`define ILI9341_CMD_V_COM_CTL_2						8'hC7



module lcd_if (
    input clk,
    input rst_n,
    
    //actions
    input init,             //initialize LCD
    input px_stream_cmd,    //transmit pixel commands
    input stream_512B,      //stream 512 bytes at 4 bytes each stream trigger
    input [4:0]img_id,      //max image count is 32 for a minimum 4GiB card

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


wire [2:0]lcd_op_bits;
assign lcd_op_bits = {stream_512B,px_stream_cmd,init};


reg [2:0]lcd_state;
reg [2:0]lcd_op_bits_r;
reg [31:0]strm_data_r;
reg [7:0]state_op_cnt;
reg [7:0]state_op_top;
wire state_op_term;
assign state_op_term = ~|(state_op_cnt ^ state_op_top); //state terminate after state_op_cnt == state_op_top.



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
reg [11:0]lcd_init_routine_seq[50:0];

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
    lcd_init_routine_seq[50] <= {4'h4,	8'h00};

end

/*
input sample block
*/
reg if_begin_r;
reg [31:0]stream_data_r;
reg stream_trigger_r;
//reg spi_miso_r;
reg spi_busy_r;
reg [31:0]blk_index;

always @(posedge clk) begin
    lcd_op_bits_r <= lcd_op_bits;
    if_begin_r <= if_begin;
    stream_data_r <= stream_data;
    stream_trigger_r <= stream_trigger;
    //spi_miso_r <= spi_miso;
    spi_busy_r <= spi_busy;
    blk_index <= img_id * 300;//implement with faster sum of shifts and padd with 0 later.
end

//reg if_busy_r;
assign if_busy = |(lcd_state ^ LCD_STATE_idle);

/*
state transition beyond this point.
*/
always @(posedge clk or negedge rst_n) begin
    if(~rst_n)begin
        lcd_state       <=  3'h0;
        lcd_op_bits_r   <=  3'b0;
        strm_data_r     <=  32'h0;
        state_op_cnt    <=  6'h0;
        state_op_top    <=  6'h0;
        //if_busy_r       <=  1'b0;
        spi_cs_r        <=  1'b1;
        spi_begin_r     <=  1'b0;
        spi_wide_r      <=  1'b0;
        lcd_data_cmd_r  <=  1'b0;
        lcd_cmd_del_cnt <=  20'h0;
        spi_mosi_r      <= 32'h0;
    end else begin
        case (lcd_state)
            LCD_STATE_idle: begin
                if(if_begin_r)begin
                    spi_cs_r        <= 1'b0; //transfer to active state always asserts chip select
                    state_op_cnt    <= 8'b0;

                    case (lcd_op_bits_r)
                        LCD_OP_BITS_init : begin
                            lcd_state <= LCD_STATE_init;
                            state_op_top <= 8'd51;
                            spi_cs_r        <=  1'b0;
                            spi_begin_r     <=  1'b0;
                            spi_wide_r      <=  1'b0;
                        end
                        LCD_OP_BITS_px_cmd : begin
                            lcd_state <= LCD_STATE_send_px;
                            state_op_top <= 8'd11;
                            spi_cs_r        <=  1'b0;
                            spi_begin_r     <=  1'b0;
                            spi_wide_r      <=  1'b0;

                        end
                        LCD_OP_BITS_stream : begin
                            lcd_state <= LCD_STATE_wait_stream;
                            state_op_top <= 8'd128;//128 transfer for 4B each
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
                    if(~spi_busy_r & ~spi_begin_r & ~state_op_term)begin
                        /*
                        advance state op counter
                        load current transfer from sequence
                        set del_cnt if sequence has delay modifier.
                        */
                        state_op_cnt <= state_op_cnt + 8'b1;//Only increment if not term yet;
                        spi_mosi_r <= {24'h0,lcd_init_routine_seq[state_op_cnt][7:0]};
                        spi_begin_r <= 1'b1;
                        lcd_data_cmd_r <= lcd_init_routine_seq[state_op_cnt][8];

                        if(lcd_init_routine_seq[state_op_cnt][9])begin
                            lcd_cmd_del_cnt <= LCD_CMD_DEL_50MS_COUNT;
                        end else if(lcd_init_routine_seq[state_op_cnt][10])begin
                            lcd_cmd_del_cnt <= LCD_CMD_DEL_250MS_COUNT;
                        end else begin
                            lcd_cmd_del_cnt <= 20'h0;
                        end
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
                        state_op_cnt <= state_op_cnt + 8'b1;//Only increment if not term yet;
                        spi_mosi_r <= {24'h0,lcd_px_routine_seq[state_op_cnt][7:0]};
                        spi_begin_r <= 1'b1;
                        lcd_data_cmd_r <= lcd_px_routine_seq[state_op_cnt][8];

                        if(lcd_px_routine_seq[state_op_cnt][9])begin
                            lcd_cmd_del_cnt <= LCD_CMD_DEL_50MS_COUNT;
                        end else if(lcd_px_routine_seq[state_op_cnt][10])begin
                            lcd_cmd_del_cnt <= LCD_CMD_DEL_250MS_COUNT;
                        end else begin
                            lcd_cmd_del_cnt <= 20'h0;
                        end
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
                if(~spi_busy_r)begin
                    lcd_state <= state_op_term? LCD_STATE_idle : LCD_STATE_tx_4B;
                    //setup for next state
                    spi_mosi_r <= stream_data_r;
                    spi_wide_r <= 1'b1;
                    spi_begin_r <= 1'b0;
                    spi_cs_r <= state_op_term;
                    state_op_cnt <= state_op_cnt + 8'h1;
                end else begin
                    //state routine

                end
            end
            LCD_STATE_tx_4B: begin
                if(spi_busy_r)begin
                    lcd_state <= LCD_STATE_wait_stream;
                    //retract trigger
                    spi_begin_r <= 1'b0;  
                    //setup for next state
                end else begin
                    //state routine
                    //trigger transfer
                    spi_begin_r <= 1'b1;    
                    
                end
            end
            default: begin
                lcd_state       <=  3'h0;
                lcd_op_bits_r   <=  3'b0;
                strm_data_r     <=  32'h0;
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

