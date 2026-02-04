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

    //spi phy
    output [31:0]spi_mosi,
    input [31:0]spi_miso,
    output spi_begin,
    output spi_ready,
    input spi_busy,
    output spi_cs

);
    
endmodule