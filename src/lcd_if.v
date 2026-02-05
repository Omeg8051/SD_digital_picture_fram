module lcd_if (
    input clk,
    input rst_n,
    
    //actions
    input init,             //initialize LCD
    input px_stream_cmd,    //transmit pixel commands
    input stream_512B,      //stream 512 bytes at 4 bytes each stream trigger

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
    input [31:0]spi_miso,
    output spi_begin,
    output spi_ready,
    input spi_busy,
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

wire [2:0]lcd_op_bits;
assign lcd_op_bits = {stream_512B,px_stream_cmd,init};


reg [2:0]lcd_state;
reg [2:0]lcd_op_bits_r;
reg [31:0]strm_data_r;
reg [5:0]state_op_cnt;
reg [5:0]state_op_top;
wire state_op_term;
assign state_op_term = ~|(state_op_cnt ^ state_op_top); //state terminate after state_op_cnt == state_op_top.

reg spi_cs_r;
reg lcd_data_cmd_r;

assign spi_cs = spi_cs_r;// output wired to register.
assign lcd_data_cmd = lcd_data_cmd_r;// output wited to register.

//spi control sigs
reg spi_wide_r;

/*
input sample block
*/
reg if_begin_r;
reg stream_data_r;
reg stream_trigger_r;
reg spi_miso_r;
reg spi_busy_r;

always @(posedge clk) begin
    lcd_op_bits_r <= lcd_op_bits;
    if_begin_r <= if_begin;
    stream_data_r <= stream_data;
    stream_trigger_r <= stream_trigger;
    spi_miso_r <= spi_miso;
    spi_busy_r <= spi_busy;
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
        if_busy_r       <=  1'b0;
        spi_cs_r        <=  1'b1;
        lcd_data_cmd_r  <=  1'b0;
    end else begin
        case (lcd_state)
            LCD_STATE_idle: begin
                if(if_begin_r)begin
                    spi_cs_r        <= 1'b0; //transfer to active state always asserts chip select
                    state_op_cnt    <= 6'b0;

                    case (lcd_op_bits_r)
                        LCD_OP_BITS_init : begin
                            lcd_state <= LCD_STATE_init;
                            state_op_top <= 6'd50;
                        end
                        LCD_OP_BITS_px_cmd : begin
                            lcd_state <= LCD_STATE_send_px;
                            state_op_top <= 6'd10;
                        end
                        LCD_OP_BITS_stream : begin
                            lcd_state <= LCD_STATE_wait_stream;
                            state_op_top <= 6'd;
                        end 
                        default: 
                    endcase
                    
                    //setup for next state
                end else begin
                    //state routine

                end
            end
            LCD_STATE_init: begin
                if(<state transition condition>)begin
                    lcd_state <= ;
                    //setup for next state
                end else begin
                    //state routine

                end
            end
            LCD_STATE_send_px: begin
                if(state_op_term)begin
                    lcd_state <= LCD_STATE_idle;
                    //setup for next state
                end else begin
                    //state routine

                end
            end
            LCD_STATE_wait_stream: begin
                if(<state transition condition>)begin
                    lcd_state <= ;
                    //setup for next state
                end else begin
                    //state routine

                end
            end
            LCD_STATE_tx_4B: begin
                if(<state transition condition>)begin
                    lcd_state <= ;
                    //setup for next state
                end else begin
                    //state routine

                end
            end
            default: begin
                lcd_state       <=  3'h0;
                lcd_op_bits_r   <=  3'b0;
                strm_data_r     <=  32'h0;
                state_op_cnt    <=  6'h0;
                state_op_top    <=  6'h0;
                if_busy_r       <=  1'b0;
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



//cmd define
`define ILI9341_CMD_NOP								12'h00
`define ILI9341_CMD_SOFT_RST						12'h01
//read 4 bytes afterward
`define ILI9341_CMD_RD_DISP_ID						12'h04
//read 5 bytes afterward
`define ILI9341_CMD_RD_DISP_STAT					12'h09
//read 2 bytes afterward
`define ILI9341_CMD_RD_DISP_PMOD					12'h0A
//read 2 bytes afterward
`define ILI9341_CMD_RD_DISP_MADCTL					12'h0B
//read 2 bytes afterward
`define ILI9341_CMD_RD_DISP_PX_FMT					12'h0C
//read 2 bytes afterward
`define ILI9341_CMD_RD_DISP_IM_FMT					12'h0D
//read 2 bytes afterward
`define ILI9341_CMD_RD_DISP_SNG_MODE				12'h0E
//read 2 bytes afterward
`define ILI9341_CMD_SLF_DIAG_RESULT					12'h0F


`define ILI9341_CMD_ENTER_SLP						12'h10
`define ILI9341_CMD_EXIT_SLP						12'h11
`define ILI9341_CMD_PARTIAL_MODE					12'h12
`define ILI9341_CMD_NRM_DISP						12'h13


`define ILI9341_CMD_DISP_INV_OFF					12'h20
`define ILI9341_CMD_DISP_INV_ON						12'h21
//write 1 byte afterward
`define ILI9341_CMD_GAMMA_SET						12'h26
`define ILI9341_CMD_DISP_OFF						12'h28
`define ILI9341_CMD_DISP_ON							12'h29
//write 4 bytes afterward {start_addr_MSB	start_addr_LSB	end_addr_MSB	end_addr_LSB}
`define ILI9341_CMD_SET_CA							12'h2A
//write 4 bytes afterward {start_addr_MSB	start_addr_LSB	end_addr_MSB	end_addr_LSB}
`define ILI9341_CMD_SET_PA							12'h2B
//write 3*PX bytes afterward
`define ILI9341_CMD_WRITE_PX						12'h2C
//write 9 bytes afterward
//`define ILI9341_CMD_SET_COLOR						12'h2D
//read 4 bytes afterward
`define ILI9341_CMD_READ_PX							12'h2E


//write 4 bytes afterward {start_addr_MSB	start_addr_LSB	end_addr_MSB	end_addr_LSB}
`define ILI9341_CMD_SET_PARTIAL						12'h30
//write 6 bytes afterward {TFA_MSB	TFA_LSB	TSA_MSB	TSA_LSB	BFA_MSB	BFA_LSB}
`define ILI9341_CMD_V_SCROLL_DEF					12'h33
`define ILI9341_CMD_TEAR_LINE_OFF					12'h34
//write 1 byte afterward
`define ILI9341_CMD_TEAR_LINE_ON					12'h35
//write 1 byte afterward
`define ILI9341_CMD_MEM_ACCESS_CTL					12'h36
//write 2 bytes afterward {VSP_MSB	VSP_LSB}
`define ILI9341_CMD_START_V_SCROLL					12'h37
`define ILI9341_CMD_IDLE_OFF						12'h38
`define ILI9341_CMD_IDLE_ON							12'h39
//write 1 byte afterward
`define ILI9341_CMD_SET_PX_FMT						12'h3A
//write 3*PX bytes afterward
//`define ILI9341_CMD_WRITE_PX_C					12'h3C
//read 3*PX bytes afterward
//`define ILI9341_CMD_READ_PX_C						12'h3E


//write 2 bytes afterward
`define ILI9341_CMD_SET_TEAR_LINE					12'h44
//read 3 bytes afterward
`define ILI9341_CMD_GET_TEAR_LINE					12'h45


//write 1 byte afterward
`define ILI9341_CMD_SET_DISP_BRIT_LVL				12'h51
//read 2 bytes afterward
`define ILI9341_CMD_GET_DISP_BRIT_LVL				12'h52
//write 1 byte afterward
`define ILI9341_CMD_SET_CTRL_DISP					12'h53
//read 2 bytes afterward
`define ILI9341_CMD_GET_CTRL_DISP					12'h54


//ID
//read 2 bytes afterward
`define ILI9341_CMD_READ_ID_1						12'hDA
//read 2 bytes afterward
`define ILI9341_CMD_READ_ID_2						12'hDB
//read 2 bytes afterward
`define ILI9341_CMD_READ_ID_3						12'hDC
//read 4 bytes afterward
`define ILI9341_CMD_READ_ID_4						12'hDD


//ext cmd
//write 1 byte afterward
`define ILI9341_CMD_RGB_IF_CTL						12'hB0
//write 2 bytes afterward
`define ILI9341_CMD_FRM_CTL_NRM						12'hB1
//write 2 byte afterward
`define ILI9341_CMD_FRM_CTL_IDLE					12'hB2
//write 2 byte afterward
`define ILI9341_CMD_FRM_CTL_PART					12'hB3
//write 2 byte afterward
`define ILI9341_CMD_DISP_INV_CTL					12'hB4
//write 3 byte afterward
`define ILI9341_CMD_SET_DISP_FUNC					12'hB6
//write 1 byte afterward
`define ILI9341_CMD_SET_ENTRY_MODE					12'hB7


//write 1 byte afterward
`define ILI9341_CMD_PWR_CTL_1						12'hC0
//write 1 byte afterward
`define ILI9341_CMD_PWR_CTL_2						12'hC1
//write 2 byte afterward
`define ILI9341_CMD_V_COM_CTL_1						12'hC5
//write 2 byte afterward
`define ILI9341_CMD_V_COM_CTL_2						12'hC7


/*
12'hxxx since it is 4 bit aligned and can be represeneted by 4 digits of HEX.
{x, delay 250ms, delay 50ms, is_data, data 8bit}
undocumented part that is necessary.
Nice job, ilitek.
    12'hCB,
	12'h39 | BYTE_IS_DATA,
	12'h2C | BYTE_IS_DATA,
	12'h00 | BYTE_IS_DATA,
	12'h34 | BYTE_IS_DATA,
	12'h02 | BYTE_IS_DATA,

	12'hCF,
	12'h00 | BYTE_IS_DATA,
	12'hC1 | BYTE_IS_DATA,
	12'h30 | BYTE_IS_DATA,

	12'hE8,
	12'h85 | BYTE_IS_DATA,
	12'h00 | BYTE_IS_DATA,
	12'h78 | BYTE_IS_DATA,

	12'hEA,
	12'h00 | BYTE_IS_DATA,
	12'h00 | BYTE_IS_DATA,
	
	12'hED,
	12'h64 | BYTE_IS_DATA,
	12'h03 | BYTE_IS_DATA,
	12'h12 | BYTE_IS_DATA,
	12'h81 | BYTE_IS_DATA,

	12'hF7,
	12'h20 | BYTE_IS_DATA,

	ILI9341_CMD_PWR_CTL_1,
	12'h23 | BYTE_IS_DATA,
	ILI9341_CMD_PWR_CTL_2,
	12'h10 | BYTE_IS_DATA,

	ILI9341_CMD_V_COM_CTL_1,
	12'h3E | BYTE_IS_DATA,
	12'h28 | BYTE_IS_DATA,
	ILI9341_CMD_V_COM_CTL_2,
	12'h86 | BYTE_IS_DATA,

	ILI9341_CMD_MEM_ACCESS_CTL,
	12'h80 | BYTE_IS_DATA,

	ILI9341_CMD_SET_PX_FMT,
	12'h55 | BYTE_IS_DATA,

	ILI9341_CMD_FRM_CTL_NRM,
	12'h00 | BYTE_IS_DATA,
	12'h18 | BYTE_IS_DATA,

	ILI9341_CMD_SET_DISP_FUNC,
	12'h08 | BYTE_IS_DATA,
	12'h82 | BYTE_IS_DATA,
	12'h27 | BYTE_IS_DATA,

	12'hF2,
	12'h00 | BYTE_IS_DATA,

	ILI9341_CMD_GAMMA_SET,
	12'h01 | BYTE_IS_DATA,

	ILI9341_CMD_EXIT_SLP | BYTE_DELAY_50_MS,
	ILI9341_CMD_DISP_ON | BYTE_DELAY_200_MS,
	ILI9341_CMD_NOP
*/

