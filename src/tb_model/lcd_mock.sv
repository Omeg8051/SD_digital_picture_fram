/*
Read SPI and pin input and verify it against a 
hard coded list and mark difference with $display
system routune.
*/

//use bit sequence and verify at each byte boundary
module lcd_mock (
    input wire clk,
    input wire rst_n,

    //spi_bus
    input wire spi_clk,
    input wire spi_mosi,
    input wire spi_cs,
    input wire spi_d1c0,

    //control port
    input wire test_init,
    input wire test_pixel,
    input wire test_stream,

    //status port
    output reg correct,
    output wire [31:0]current_byte
);
    

reg [11:0]lcd_px_routine_seq[10:0];
reg [11:0]lcd_init_routine_seq[49:0];
//test with no delay

localparam IDX_MAX_init = 50;
localparam IDX_MAX_px = 11;

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

end


reg [7:0]spi_byte;
reg [31:0]bit_counter;
wire byte_bound;
assign byte_bound = &bit_counter[2:0];
wire [29:0]byte_idx;
assign byte_idx = bit_counter[31:3];
wire [7:0]spi_current_byte;
assign spi_current_byte = {spi_byte[6:0],spi_mosi};
assign current_byte = spi_current_byte;

wire no_more_display;
assign no_more_display = byte_idx >= (test_init_r? IDX_MAX_init : IDX_MAX_px);

reg [7:0]golden_byte;

always @(*)begin
    case ({test_pixel_r,test_init_r})
        2'b01: begin
            golden_byte = lcd_init_routine_seq[byte_idx][7:0];
            correct = ~|(spi_current_byte ^ lcd_init_routine_seq[byte_idx][7:0]);
            
        end 
        2'b10: begin
            golden_byte = lcd_px_routine_seq[byte_idx][7:0];
            correct = ~|(spi_current_byte ^ lcd_px_routine_seq[byte_idx][7:0]);
            
        end 
        default: begin
            correct = 0;
            golden_byte = 8'hFF;
        end 
    endcase
end

reg test_init_r;
reg test_pixel_r;

always @(negedge clk or negedge rst_n)begin
    if(~rst_n) begin
        bit_counter <= 0;
    end else begin
        if(~spi_cs & spi_clk) begin
            bit_counter <= bit_counter + 1;
            test_init_r <= test_init_r;
            test_pixel_r <= test_pixel_r;
        end else if(~spi_cs) begin
            bit_counter <= bit_counter;
            test_init_r <= test_init_r;
            test_pixel_r <= test_pixel_r;
        end else begin
            bit_counter <= 0;
            test_init_r <= test_init;
            test_pixel_r <= test_pixel;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        spi_byte <= 0;
    end else begin
        if(~spi_cs) begin
            if(byte_bound) begin
                if(~no_more_display)$display("%s ,status: %b ,idx: %0d ,golden: 0x%0h ,recieved: 0x%0h",test_init_r? "init_seq":"pixl_seq",correct,byte_idx,golden_byte,spi_current_byte);
                
                
            end else begin
                spi_byte <= spi_current_byte;
            end
            
        end
    end
end


endmodule