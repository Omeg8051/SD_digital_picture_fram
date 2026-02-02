module uart_front (
    input clk,
    input rst_n,

    //uart interface
    output uart_tx,
    input uart_rx,

    //data interface
    input [7:0] data_tx,
    output [7:0] data_rx,

    //control interface
    output uart_valid,
    input uart_ready,
    output uart_busy,
    input uart_begin
);

//present the first byte on data_rx after uart_valid deasserts.
//hold data_rx before uart_ready.

//transmit the first byte present on data_tx if uart_begin && !uart_busy
    
endmodule