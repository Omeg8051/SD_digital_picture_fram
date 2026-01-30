
module d_pic_f (
    input clk,
    input rst_n,

    //SD spi port
    output SD_spi_clk,
    output SD_spi_cs,
    output SD_spi_mosi,
    input SD_spi_miso,
    
    //LCD spi port
    output LCD_spi_clk,
    output LCD_spi_cs,
    output LCD_spi_mosi,
    input LCD_spi_miso,

    //UART control port
    output UART_tx,
    input UART_rx,
);

/*
state encoding:
one bit per state(use parallel case)
*/
/*
init_peripheral
reset from any_state to here.

Behavior:
Command each spi controllers to initiallize their respective peripherals.


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
