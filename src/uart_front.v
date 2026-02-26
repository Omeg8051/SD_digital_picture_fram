module uart_front #(
     	parameter p_baud_rate = 115200,
 		parameter p_clk_freq = 1000000
        )
        (
    input clk,
    input rst_n,

    //uart interface
    output uart_tx,
    input uart_rx,

    //data interface
    //input [7:0] data_tx,
    output [7:0] data_rx,

    //control interface
    output uart_valid,
    input uart_ready//,
    //output uart_busy,
    //input uart_begin
);

//present the first byte on data_rx after uart_valid deasserts.
//hold data_rx before uart_ready.

//transmit the first byte present on data_tx if uart_begin && !uart_busy

/*
state trans:
(falling edge)idle -> (0.5 bit elapsed)0.5bit start bit -> (1 bit elapsed)1bit data (x8)-> (1 bit elapsed)1bit stop bit -> (0.5bit elapsed)valid -> (valid && ready)idle
*/

localparam UART_STATE_idle = 4'hF ;
localparam UART_STATE_start_bit = 4'hC ;
localparam UART_STATE_bit_0 = 4'h0 ;
localparam UART_STATE_bit_1 = 4'h1 ;
localparam UART_STATE_bit_2 = 4'h2 ;
localparam UART_STATE_bit_3 = 4'h3 ;
localparam UART_STATE_bit_4 = 4'h4 ;
localparam UART_STATE_bit_5 = 4'h5 ;
localparam UART_STATE_bit_6 = 4'h6 ;
localparam UART_STATE_bit_7 = 4'h7 ;
localparam UART_STATE_stop_bit = 4'h8 ;
localparam UART_STATE_byte_valid = 4'hA ;

//localparam CMD_CHAR_increment = ;
//localparam CMD_CHAR_decrement = ;

reg [3:0] uart_state;
reg [11:0] bit_divider;//slowest is 1200 baud at 4M/3333
reg [11:0] bit_divider_cnt;
wire bit_divider_cnt_z;
assign bit_divider_cnt_z = ~|bit_divider_cnt;
//localparam p_baud_rate = 115200;
//localparam p_clk_freq = 1000000;

localparam p_bit_divider_init = p_clk_freq / p_baud_rate - 1;

reg [7:0]rx_byte_r;
reg [7:0]data_rx_r;
reg uart_valid_r;

assign data_rx = data_rx_r;
assign uart_valid = uart_valid_r;

reg uart_rx_r;
reg uart_ready_r;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        uart_rx_r <= 1'b1;
        uart_ready_r <= 1'b0;
    end else begin
        uart_rx_r <= uart_rx;
        uart_ready_r <= uart_ready;
    end
end

always @(posedge clk or negedge rst_n) begin

    if(~rst_n) begin
        uart_state <= UART_STATE_idle;
        bit_divider <= p_bit_divider_init[11:0];
        bit_divider_cnt <= 12'b0;
        rx_byte_r <= 8'b0;
        uart_valid_r <= 1'b0;
        data_rx_r <= 8'b0;
    end else begin
        case (uart_state)
            UART_STATE_idle : begin
                if(~uart_rx_r) begin
                    uart_state <= UART_STATE_start_bit;
                    //setup for next state
                    bit_divider_cnt <= {1'b0,bit_divider[11:1]};//0.5 bit
                end else begin
                    //current state routine for "UART_STATE_idle"
                end
            end
            UART_STATE_start_bit : begin
                if(bit_divider_cnt_z) begin
                    uart_state <= UART_STATE_bit_0;
                    //setup for next state
                    bit_divider_cnt <= bit_divider;//1 bit
                end else begin
                    //current state routine for "UART_STATE_start_bit"
                    bit_divider_cnt <= bit_divider_cnt - 32'b1;
                end
            end
            UART_STATE_bit_0 : begin
                if(bit_divider_cnt_z) begin
                    uart_state <= UART_STATE_bit_1;
                    //setup for next state
                    bit_divider_cnt <= bit_divider;//1 bit
                    rx_byte_r <= {uart_rx_r,rx_byte_r[7:1]};
                end else begin
                    //current state routine for "UART_STATE_bit_0"
                    bit_divider_cnt <= bit_divider_cnt - 32'b1;
                end
            end
            UART_STATE_bit_1 : begin
                if(bit_divider_cnt_z) begin
                    uart_state <= UART_STATE_bit_2;
                    //setup for next state
                    bit_divider_cnt <= bit_divider;//1 bit
                    rx_byte_r <= {uart_rx_r,rx_byte_r[7:1]};
                end else begin
                    //current state routine for "UART_STATE_bit_1"
                    bit_divider_cnt <= bit_divider_cnt - 32'b1;
                end
            end
            UART_STATE_bit_2 : begin
                if(bit_divider_cnt_z) begin
                    uart_state <= UART_STATE_bit_3;
                    //setup for next state
                    bit_divider_cnt <= bit_divider;//1 bit
                    rx_byte_r <= {uart_rx_r,rx_byte_r[7:1]};
                end else begin
                    //current state routine for "UART_STATE_bit_2"
                    bit_divider_cnt <= bit_divider_cnt - 32'b1;
                end
            end
            UART_STATE_bit_3 : begin
                if(bit_divider_cnt_z) begin
                    uart_state <= UART_STATE_bit_4;
                    //setup for next state
                    bit_divider_cnt <= bit_divider;//1 bit
                    rx_byte_r <= {uart_rx_r,rx_byte_r[7:1]};
                end else begin
                    //current state routine for "UART_STATE_bit_3"
                    bit_divider_cnt <= bit_divider_cnt - 32'b1;
                end
            end
            UART_STATE_bit_4 : begin
                if(bit_divider_cnt_z) begin
                    uart_state <= UART_STATE_bit_5;
                    //setup for next state
                    bit_divider_cnt <= bit_divider;//1 bit
                    rx_byte_r <= {uart_rx_r,rx_byte_r[7:1]};
                end else begin
                    //current state routine for "UART_STATE_bit_4"
                    bit_divider_cnt <= bit_divider_cnt - 32'b1;
                end
            end
            UART_STATE_bit_5 : begin
                if(bit_divider_cnt_z) begin
                    uart_state <= UART_STATE_bit_6;
                    //setup for next state
                    bit_divider_cnt <= bit_divider;//1 bit
                    rx_byte_r <= {uart_rx_r,rx_byte_r[7:1]};
                end else begin
                    //current state routine for "UART_STATE_bit_5"
                    bit_divider_cnt <= bit_divider_cnt - 32'b1;
                end
            end
            UART_STATE_bit_6 : begin
                if(bit_divider_cnt_z) begin
                    uart_state <= UART_STATE_bit_7;
                    //setup for next state
                    bit_divider_cnt <= bit_divider;//1 bit
                    rx_byte_r <= {uart_rx_r,rx_byte_r[7:1]};
                end else begin
                    //current state routine for "UART_STATE_bit_6"
                    bit_divider_cnt <= bit_divider_cnt - 32'b1;
                end
            end
            UART_STATE_bit_7 : begin
                if(bit_divider_cnt_z) begin
                    uart_state <= UART_STATE_stop_bit;
                    //setup for next state
                    bit_divider_cnt <= bit_divider;//1 bit
                    rx_byte_r <= {uart_rx_r,rx_byte_r[7:1]};
                end else begin
                    //current state routine for "UART_STATE_bit_7"
                    bit_divider_cnt <= bit_divider_cnt - 32'b1;
                end
            end
            UART_STATE_stop_bit : begin
                if(bit_divider_cnt_z) begin
                    uart_state <= UART_STATE_byte_valid;
                    //setup for next state
                    uart_valid_r <= 1'b1;
                    data_rx_r <= rx_byte_r;
                end else begin
                    //current state routine for "UART_STATE_stop_bit"
                    bit_divider_cnt <= bit_divider_cnt - 32'b1;
                end
            end
            UART_STATE_byte_valid : begin
                if(uart_valid_r & uart_ready_r) begin
                    uart_state <=  UART_STATE_idle;
                    //setup for next state
                    bit_divider_cnt <= bit_divider;//1 bit
                    uart_valid_r <= 1'b0;
                end else begin
                    //current state routine for "UART_STATE_byte_valid"
                end
            end
            default: 
                uart_state <=  UART_STATE_idle;
        endcase
    end
    
end

endmodule