/*
Read only simulation model of SD card.
No high Z behavior on bus_miso since it is not expected to have more then one present on the bus.
*/
module sim_modle_sd (
    input clk,//Internal logic use. Same phase and freq as bus_clk.
    input sim_rst,//Simulates power on event
    input bus_clk,
    input bus_cs,
    input bus_mosi,
    output bus_miso,
    output [7:0]debug_status
    /*
    debug status code:
        example_status: <number>
    */
);

/*
state encoding:
{sdio,xxx,
xxxx,
multi_blk_op,   single_blk_op, init_1,  init_0,
x,  data_strm,  ready,  spi_mode}
*/

/*
reset to this state

acceptable command -> response[ + next]:
    cmd0 -> read 2 bytes(FFh, 01h)
*/
localparam sd_state_p_on = 16'h0000;

/*
read 10B from sd_state_p_on to this state

acceptable command -> response[ + next]:
    cmd0 -> read 2 bytes(FFh, 01h)
*/
localparam sd_state_sdio = 16'h8000;//sdio

/*
cmd0 from sd_state_p_on to this state

acceptable command -> response[ + next]:
    cmd8 -> read 6 bytes(FFh, 01h, 00h, 80h, FFh, 80h)
*/
localparam sd_state_init_0 = 16'h0011;//SPI | init_0

/*
cmd8 from sd_state_init_0 to this state

acceptable command -> response[ + next]:
    cmd55 -> read 2 bytes(FFh, 01h) +
    acmd41 -> read 2 bytes(FFh, 01h/00h)
*/
localparam sd_state_init_1 = 16'h0021;// SPI | init_1

/*
acmd41 return 00h from sd_state_init_1 to this state
cmd12 and return 00h from sd_state_m_blk_rd to this state
read 512+2 bytes from sd_state_s_blk_rd to this state

acceptable command -> response[ + next]:
    cmd17 -> read 2 bytes(FFh, 01h)
    cmd18 -> read 2 bytes(FFh, 01h)
*/
localparam sd_state_ready = 16'h0003;//SPI | ready

/*
cmd17 from sd_state_ready to this state

acceptable command -> response[ + next]:
    read 1 byte (FFh)
    read 1 byte (FEh)
*/
localparam sd_state_s_blk_setup = 16'h0041;//SPI | single_blk_op

/*
cmd18 from sd_state_ready to this state

acceptable command -> response[ + next]:
    read 1 byte (FFh)
    read 1 byte (FEh)
*/
localparam sd_state_m_blk_setup = 16'h0081;//SPI | single_blk_op

/*
read 1 byte (FEh) from sd_state_s_blk_setup to this state

acceptable command -> response[ + next]:
    read 512 byte (55h, AAh ...) +
    read 2 byte (66h)
*/
localparam sd_state_s_blk_rd = 16'h0045;//SPI | single_blk_op | data_strm

/*
read 1 byte (FEh) from sd_state_m_blk_setup to this state

acceptable command -> response[ + next]:
    read 512 byte (55h, AAh ...) +
    read 2 byte (66h) + optional
    read 512 byte (55h, AAh ...) +
    read 2 byte (66h) + optional
    cmd12
*/
localparam sd_state_m_blk_rd = 16'h0085;//SPI | single_blk_op | data_strm

/*
OTHERWISE, REGARD AS ILLEGAL COMMAND.
*/

//interaction bit list
//include command bits
localparam sd_bit_p_on = 16'd64;//6B cmd0 + 1B FFh + 1B R1
localparam sd_bit_init_0 = 16'd96;//6B cmd8 + 1B FFh + 1B R1 + 4B volt_info
localparam sd_bit_init_1 = 16'd128;//6B cmd55 + 1B FFh + 1B R1 + 6B acmd41 + 1B FFh + 1B R1
localparam sd_bit_ready = 16'd64;//6B cmd17/18 + 1B FFh + 1B R1
localparam sd_bit_s_blk_setup = 16'd1200;//149B FFh + 1B FEh
localparam sd_bit_m_blk_setup = 16'd1200;//149B FFh + 1B FEh
localparam sd_bit_s_blk_rd = 16'd4112;//512B 5Ah + 2B 69h
localparam sd_bit_s_blk_rd = 16'd65535;//infinite untill cmd12 is accepted

//command list:
localparam sdspi_cmd0 = 8'h40;
localparam sdspi_cmd8 = 8'h48;
localparam sdspi_cmd55 = 8'h77;
localparam sdspi_acmd41 = 8'h69;
localparam sdspi_cmd12 = 8'h4C;
localparam sdspi_cmd17 = 8'h51;
localparam sdspi_cmd18 = 8'h52;

reg [15:0]sd_card_state;
reg [15:0]sd_card_state_next;
reg state_trans;
reg bus_cs_r;
reg [15:0]op_bit_counter;
reg [15:0]op_bit_counter_exp;
reg [15:0]timed_transition_counter;
reg [47:0]cmd_buffer;

wire [7:0]cmd_cur;
assign cmd_cur = cmd_buffer[47:40];

always @(posedge clk or negedge sim_rst ) begin
    if(~sim_rst) begin
        
    end else begin
        
    end
end

/*
state transition beyond this point
*/
always @(posedge clk or negedge sim_rst ) begin
    if(~sim_rst) begin
        //simulates power on
        sd_card_state <= sd_state_p_on;
        op_bit_counter <= 16'h0;
        op_bit_counter_exp <= 16'h0;
    end else if(state_trans) begin
        //load next state only.
        sd_card_state <= sd_card_state_next;
        op_bit_counter <= 16'h0;
        op_bit_counter_exp <= op_bit_counter_exp;
    end else if(bus_cs_r) begin
        // intrement bit interact counter
        sd_card_state <= sd_card_state_next;
        op_bit_counter <= op_bit_counter + 16'h1;
        op_bit_counter_exp <= op_bit_counter_exp;
    end else begin
        //hold
        sd_card_state <= sd_card_state_next;
        op_bit_counter <= op_bit_counter;
        op_bit_counter_exp <= op_bit_counter_exp;
    end
end

/*
next state combinational logic beyond this point
*/

/*
behavior logic beyond this point
*/

/*
debug status logic beyond this point
*/

endmodule
