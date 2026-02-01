module lcd_if (
    input clk,
    input rst_n,
    
    //actions
    input init,             //initialize LCD
    input px_stream_cmd,    //transmit pixel commands
    input stream_512B,      //stream 512 bytes at 4 bytes each stream trigger

    //flow control
    input trigger,
    output busy,

    //data stream
    input [31:0]stream_data,
    input stream_trigger,
    output stream_busy,

    //spi phy
    output spi_clk,
    output spi_mosi,
    input spi_miso,
    output spi_cs


);
    
endmodule