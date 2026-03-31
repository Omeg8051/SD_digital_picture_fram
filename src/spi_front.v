module spi_front (
    input spi_clk_in,
    input rst_n,

    //spi interface
    output spi_clk_o,
    output reg spi_mosi_o,
    input spi_miso_i,

    //data interface
    input [31:0] data_mosi,
    output [31:0] data_miso,

    //control interface
    input spi_begin,
    input spi_wide,
    output spi_busy

);


localparam SPI_STATE_IDLE = 0;
localparam SPI_STATE_ACTIVE = 1;


reg [31:0]spi_rx_data;
reg [31:0]spi_rx_data_r;
assign data_miso = spi_rx_data_r;

reg spi_state;
reg [5:0] spi_bit_ptr;
reg spi_clk_gate;
reg spi_clk_gate_neg;
reg spi_busy_r;
reg [31:0]spi_tx_data;

assign spi_busy = spi_busy_r;
assign spi_clk_o = spi_clk_in & spi_clk_gate_neg;

reg spi_begin_r;

always @(posedge spi_clk_in or negedge rst_n) begin
    if(~rst_n)begin
        spi_begin_r <= 1'b0;
    end else begin
        spi_begin_r <= spi_begin;
    end
end


always @(posedge spi_clk_in or negedge rst_n) begin
    if(~rst_n) begin
        spi_state <= SPI_STATE_IDLE;
        spi_bit_ptr <= 3'b0;
        spi_clk_gate <= 1'b0;
        spi_busy_r <= 1'b0;
        spi_tx_data <= 8'b0;
        spi_rx_data_r <= 32'b0;
    end else begin
        case (spi_state)
            SPI_STATE_IDLE:begin
                if(spi_begin_r)begin
                    spi_state <= SPI_STATE_ACTIVE;
                    spi_bit_ptr <= {{2{spi_wide}},3'h7};
                    //spi_bit_ptr <= spi_wide? 6'h20 : 6'h8;
                    spi_clk_gate <= 1'b1;
                    spi_busy_r <= 1'b1;
                    spi_tx_data <= data_mosi;
                end
            end
            SPI_STATE_ACTIVE:begin
                if(~|spi_bit_ptr)begin
                    spi_state <= SPI_STATE_IDLE;
                    spi_bit_ptr <= 3'h0;
                    spi_clk_gate <= 1'b0;
                    spi_busy_r <= 1'b0;
                    spi_rx_data_r <= spi_rx_data;
                end else begin
                    spi_bit_ptr <= spi_bit_ptr - 3'b1;
                    
                end
            end
            default: begin
                spi_state <= SPI_STATE_IDLE;
                spi_bit_ptr <= 3'b0;
                spi_clk_gate <= 1'b0;
                spi_busy_r <= 1'b0; 
            end

        endcase
    end
end

reg spi_mosi_r;
//assign spi_mosi_o = spi_mosi_r;
always @(negedge spi_clk_in or negedge rst_n) begin
    if(~rst_n)begin
        spi_mosi_o <= 1'b1;
        spi_clk_gate_neg <= 1'b0;
    end else begin
        spi_clk_gate_neg <= spi_clk_gate;
        spi_mosi_o <= spi_mosi_r;
    end
end
always @(*) begin
    case (spi_bit_ptr)
        6'd1: spi_mosi_r = spi_tx_data[1];
        6'd2: spi_mosi_r = spi_tx_data[2];
        6'd3: spi_mosi_r = spi_tx_data[3];
        6'd4: spi_mosi_r = spi_tx_data[4];
        6'd5: spi_mosi_r = spi_tx_data[5];
        6'd6: spi_mosi_r = spi_tx_data[6];
        6'd7: spi_mosi_r = spi_tx_data[7];
        6'd8: spi_mosi_r = spi_tx_data[8];
        6'd9: spi_mosi_r = spi_tx_data[9];
        6'd10: spi_mosi_r = spi_tx_data[10];
        6'd11: spi_mosi_r = spi_tx_data[11];
        6'd12: spi_mosi_r = spi_tx_data[12];
        6'd13: spi_mosi_r = spi_tx_data[13];
        6'd14: spi_mosi_r = spi_tx_data[14];
        6'd15: spi_mosi_r = spi_tx_data[15];
        6'd16: spi_mosi_r = spi_tx_data[16];
        6'd17: spi_mosi_r = spi_tx_data[17];
        6'd18: spi_mosi_r = spi_tx_data[18];
        6'd19: spi_mosi_r = spi_tx_data[19];
        6'd20: spi_mosi_r = spi_tx_data[20];
        6'd21: spi_mosi_r = spi_tx_data[21];
        6'd22: spi_mosi_r = spi_tx_data[22];
        6'd23: spi_mosi_r = spi_tx_data[23];
        6'd24: spi_mosi_r = spi_tx_data[24];
        6'd25: spi_mosi_r = spi_tx_data[25];
        6'd26: spi_mosi_r = spi_tx_data[26];
        6'd27: spi_mosi_r = spi_tx_data[27];
        6'd28: spi_mosi_r = spi_tx_data[28];
        6'd29: spi_mosi_r = spi_tx_data[29];
        6'd30: spi_mosi_r = spi_tx_data[30];
        6'd31: spi_mosi_r = spi_tx_data[31];
        default: spi_mosi_r = spi_tx_data[0];
    endcase
end

always @(posedge spi_clk_in or negedge rst_n) begin
    if(~rst_n) begin
        spi_rx_data <= 8'b0;
    end else if(spi_busy_r) begin
        //Might have DC issue since only have half a clock to propagate.
        spi_rx_data <= {spi_rx_data[30:0],spi_miso_i};
    end else begin
        spi_rx_data <= spi_rx_data;
    end
end


endmodule