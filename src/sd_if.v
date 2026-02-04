
module sd_if (
    input clk,
    input rst_n,
    
    //actions
    input init,         //init SD card
    input read_cmd,     //send read command for blk_addr
    input stream_512B,   //stream 512 bytes at 4 bytes each stream trigger
    input rm_crc,       //read 2 bytes of trailing CRC

    //flow control
    input [3:0]img_id,
    input if_begin,
    output if_busy,

    //data stream
    output [31:0]stream_data,
    output stream_trigger,
    input stream_busy,

    //spi phy
    output [31:0]spi_mosi,
    input [31:0]spi_miso,
    output spi_begin,
    output spi_ready,
    input spi_busy


);
    
endmodule