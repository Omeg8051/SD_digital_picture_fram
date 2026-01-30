module lcd_if (
    input clk,
    input rst_n,
    
    //actions
    input init,
    input others,

    //flow control
    input trigger,
    output busy,

    //data stream
    input [31:0]stream_data,

    //spi phy
    output spi_clk,
    output spi_mosi,
    input spi_miso,
    output spi_cs


);
    
endmodule