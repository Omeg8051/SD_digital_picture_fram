module sd_if (
    input clk,
    input rst_n,
    
    //actions
    input init,         //init SD card
    input read_cmd,     //send read command for blk_addr
    input stream_512B,   //stream 512 bytes at 4 bytes each stream trigger
    input end_of_frame,      //pull high when initiating the last block transfer.
    
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
    input spi_busy,
    output spi_wide,
    output spi_cs


);

localparam SD_STATE_idle = 4'h0;
localparam SD_STATE_init_80_c = 4'h6;
localparam SD_STATE_init_seq = 4'h2;
localparam SD_STATE_init_poll = 4'h3;
localparam SD_STATE_send_rd_blk = 4'h4;
localparam SD_STATE_data_token = 4'h5;
localparam SD_STATE_strm_512_aquire = 4'h8;
localparam SD_STATE_strm_512_trig = 4'h9;
localparam SD_STATE_rm_crc = 4'hA;


localparam SD_OP_BITS_init = 3'b001;
localparam SD_OP_BITS_px_cmd = 3'b010;
localparam SD_OP_BITS_stream = 3'b100;


wire [2:0]sd_op_bits;
reg [2:0]sd_op_bits_r;
assign sd_op_bits = {stream_512B,read_cmd,init};

reg [3:0]sd_state;

reg [9:0]state_op_cnt;
wire [9:0]state_op_cnt_next;
assign state_op_cnt_next = state_op_cnt + 9'h1;
reg [9:0]state_op_top;

wire state_op_term;
assign state_op_term = ~|(state_op_cnt ^ state_op_top); //state terminate after state_op_cnt == state_op_top.
wire spi_begin_term;
assign spi_begin_term = |(state_op_cnt_next ^ state_op_top); //state terminate after 

localparam SD_OP_TOP_init_80_c = 10'd20;
localparam SD_OP_TOP_init_seq = 10'd18;//cmd0 + 1B resp + cmd8 + 1B resp + 4B status
localparam SD_OP_TOP_init_poll = 10'd1023;//(cmd55 + 1B resp + acmd41 + 1B resp) * 64
localparam SD_OP_TOP_send_rd_blk = 10'd7;//cmd17 + 1B resp
localparam SD_OP_TOP_data_token = 10'd1023;//< 1024B read till FEh
localparam SD_OP_TOP_strm_512_aquire = 10'd128;
localparam SD_OP_TOP_strm_512_trig = 10'd128;
localparam SD_OP_TOP_rm_crc = 10'd4;//2B read(FFh)

//sequence record
reg [9:0]rd_blk_seq[7:0];//{hold_on_FFh,data_from_var,data[7:0]};
reg [9:0]init_route_seq[17:0];//{hold_on_FFh,cs_state,data[7:0]};
reg [9:0]init_poll_seq[15:0];//{hold_on_FFh,cs_state,data[7:0]};

always @(negedge rst_n) begin
    rd_blk_seq[0] <= 10'h51;
    rd_blk_seq[1] <= 10'h1F0;
    rd_blk_seq[2] <= 10'h1F1;
    rd_blk_seq[3] <= 10'h1F2;
    rd_blk_seq[4] <= 10'h1F3;
    rd_blk_seq[5] <= 10'hFF;
    rd_blk_seq[6] <= 10'h2FF;
    rd_blk_seq[7] <= 10'hFF;

    init_route_seq[0] <= 10'h40;
    init_route_seq[1] <= 10'h00;
    init_route_seq[2] <= 10'h00;
    init_route_seq[3] <= 10'h00;
    init_route_seq[4] <= 10'h00;
    init_route_seq[5] <= 10'h95;
    init_route_seq[6] <= 10'h2FF;
    init_route_seq[7] <= 10'h48;
    init_route_seq[8] <= 10'h00;
    init_route_seq[9] <= 10'h00;
    init_route_seq[10] <= 10'h01;
    init_route_seq[11] <= 10'hAA;
    init_route_seq[12] <= 10'h87;
    init_route_seq[13] <= 10'h2FF;
    init_route_seq[14] <= 10'hFF;
    init_route_seq[15] <= 10'hFF;
    init_route_seq[16] <= 10'hFF;
    init_route_seq[17] <= 10'hFF;

    init_poll_seq[0] <= 10'h77;
    init_poll_seq[1] <= 10'h00;
    init_poll_seq[2] <= 10'h00;
    init_poll_seq[3] <= 10'h00;
    init_poll_seq[4] <= 10'h00;
    init_poll_seq[5] <= 10'h01;
    init_poll_seq[6] <= 10'h2FF;
    init_poll_seq[7] <= 10'h1FF;
    init_poll_seq[8] <= 10'h69;
    init_poll_seq[9] <= 10'h40;
    init_poll_seq[10] <= 10'h00;
    init_poll_seq[11] <= 10'h00;
    init_poll_seq[12] <= 10'h00;
    init_poll_seq[13] <= 10'h01;
    init_poll_seq[14] <= 10'h2FF;
    init_poll_seq[15] <= 10'h1FF;
end

//spi control signal
reg spi_wide_r;
reg spi_begin_r;
reg spi_cs_r;
reg [31:0]spi_mosi_r;

assign spi_cs = spi_cs_r;// output wired to register.
assign spi_wide = spi_wide_r;// output wired to register.
assign spi_begin = spi_begin_r;// output wired to register.
assign spi_mosi = spi_mosi_r;// output wired to register.

/*
input sample block
*/
reg if_begin_r;
reg [31:0]stream_data_r;
reg stream_trigger_r;
assign stream_data = stream_data_r;
reg stream_busy_r;
assign stream_trigger = stream_trigger_r;
reg [31:0]spi_miso_r;
wire spi_miso_is_FF;
assign spi_miso_is_FF = &spi_miso[7:0];
reg spi_busy_r;
wire [31:0]blk_index;
assign blk_index = img_id * 300 + 2048;//keep first 2048 blk for MBR + GPT part table 
reg [31:0]blk_index_r;
reg [8:0]blk_off_r;
reg end_of_frame_r;
wire [31:0]blk_loc;
assign blk_loc = blk_index_r + {23'h0,blk_off_r};

always @(posedge clk) begin
    sd_op_bits_r <= sd_op_bits;
    if_begin_r <= if_begin;
    stream_busy_r <= stream_busy;
    spi_miso_r <= spi_miso;
    spi_busy_r <= spi_busy;
    end_of_frame_r <= end_of_frame;
end

assign if_busy = |(sd_state ^ SD_STATE_idle);

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        sd_state <= SD_STATE_idle;
        spi_wide_r <= 1'b0;
        spi_begin_r <= 1'b0;
        spi_cs_r <= 1'b1;
        spi_mosi_r <= 32'b0;
        blk_index_r <= 32'b0;
        stream_data_r <= 32'b0;
        stream_trigger_r <= 1'b0;
        blk_off_r <= 9'h0;
    end else begin
        case (sd_state)
            SD_STATE_idle : begin
                if(~if_busy & if_begin) begin
                    spi_cs_r <= 1'b0;
                    state_op_cnt <= 10'h0;
                    case (sd_op_bits_r)
                        SD_OP_BITS_init : begin
                            sd_state <= SD_STATE_init_80_c;
                            state_op_top <= SD_OP_TOP_init_80_c;
                            spi_cs_r <= 1'b1;
                            spi_begin_r <= 1'b0;
                            spi_mosi_r <= 32'hFFFFFFFF;
                        end
                        SD_OP_BITS_px_cmd : begin
                            sd_state <= SD_STATE_send_rd_blk;
                            state_op_top <= SD_OP_TOP_send_rd_blk;
                            blk_index_r <= blk_index;
                        end
                        SD_OP_BITS_stream : begin
                            sd_state <= SD_STATE_strm_512_aquire;
                            state_op_top <= SD_OP_TOP_strm_512_aquire;
                            spi_wide_r <= 1'b1;
                            spi_mosi_r <=   {32'hFFFFFFFF};
                        end
                        default: begin
                            sd_state <= SD_STATE_idle;
                            spi_wide_r <= 1'b0;
                            spi_begin_r <= 1'b0;
                            spi_cs_r <= 1'b1;
                            spi_mosi_r <= 32'b0;
                            blk_index_r <= 32'b0;

                        end
                    endcase
                end else begin
                    
                end
                
            end
            SD_STATE_init_80_c : begin
                if(state_op_term & ~spi_busy_r) begin
                    sd_state <= SD_STATE_init_seq;
                    state_op_top <= SD_OP_TOP_init_seq;
                    state_op_cnt <= 10'h0;
                    spi_cs_r <= 1'b0; 
                end else if(~spi_busy_r & ~spi_begin_r) begin
                    spi_begin_r <= 1'b1;
                    
                end else if(spi_busy_r & spi_begin_r) begin
                    spi_begin_r <= 1'b0;
                    state_op_cnt <= state_op_cnt_next;
                end
                
            end
            SD_STATE_init_seq : begin
                if(state_op_term & ~spi_busy_r) begin
                    sd_state <= SD_STATE_init_poll;
                    state_op_top <= SD_OP_TOP_init_poll;
                    state_op_cnt <= 10'h0;
                end else if(~spi_busy_r & ~spi_begin_r) begin
                    spi_begin_r <= 1'b1;
                    spi_mosi_r <= {24'hFFFFFF,init_route_seq[state_op_cnt][7:0]};
                    
                end else if(spi_busy_r & spi_begin_r) begin
                    spi_begin_r <= 1'b0;
                    state_op_cnt <= (init_route_seq[state_op_cnt][9] & spi_miso_is_FF)? state_op_cnt : state_op_cnt_next;
                end
                
            end
            SD_STATE_init_poll : begin
                if((state_op_term | (~|spi_miso_r[7:0])) & ~spi_busy_r) begin
                    sd_state <= SD_STATE_idle;
                    state_op_top <= SD_OP_TOP_init_poll;
                    state_op_cnt <= 10'h0;
                    spi_cs_r <= 1'b1;
                end else if(~spi_busy_r & ~spi_begin_r) begin
                    spi_begin_r <= 1'b1;
                    spi_cs_r <= (init_poll_seq[state_op_cnt][9] & ~spi_miso_is_FF) | init_poll_seq[state_op_cnt][8];
                    spi_mosi_r <= {24'hFFFFFF,init_poll_seq[state_op_cnt][7:0]};
                    state_op_cnt <= (init_poll_seq[state_op_cnt][9] & spi_miso_is_FF)? state_op_cnt : (state_op_cnt_next & 4'hF);
                end else if(spi_busy_r & spi_begin_r) begin
                    spi_begin_r <= 1'b0;
                    
                end
                
            end
            SD_STATE_send_rd_blk : begin
                if(state_op_term & ~spi_busy_r) begin
                    sd_state <= SD_STATE_data_token;
                    state_op_top <= SD_OP_TOP_data_token;
                    state_op_cnt <= 10'h0;
                    
                end else begin
                    if(rd_blk_seq[state_op_cnt][8]) begin
                        case (rd_blk_seq[state_op_cnt][1:0])
                            2'h0: spi_mosi_r <= {24'h0,blk_loc[31:24]};
                            2'h1: spi_mosi_r <= {24'h0,blk_loc[23:16]};
                            2'h2: spi_mosi_r <= {24'h0,blk_loc[15:8]};
                            2'h3: spi_mosi_r <= {24'h0,blk_loc[7:0]};
                            default: spi_mosi_r <= {24'h0,blk_loc[7:0]};
                        endcase
                    end else begin
                        spi_mosi_r <= {24'h0,rd_blk_seq[state_op_cnt][7:0]};
                    end
                       
                                    
                    if(spi_busy_r & spi_begin_r) begin
                        spi_begin_r <= 1'b0;
                        state_op_cnt <= (rd_blk_seq[state_op_cnt][9] & spi_miso_is_FF) ? state_op_cnt : state_op_cnt_next;
                    end else if(~spi_busy_r & ~spi_begin_r) begin
                        spi_begin_r <= ~state_op_term;
                    end
                    
                end
                
            end
            SD_STATE_data_token : begin
                if(state_op_term) begin
                    sd_state <= SD_STATE_idle;
                end else begin
                    spi_mosi_r <=   {32'hFFFFFFFF};
                    
                    if(spi_busy_r & spi_begin_r) begin
                        spi_begin_r <= 1'b0;
                        state_op_cnt <= state_op_cnt_next;
                    end else if(~spi_busy_r & ~spi_begin_r) begin
                        spi_begin_r <= spi_miso_is_FF;
                        sd_state <= spi_miso_is_FF ? SD_STATE_data_token : SD_STATE_idle;
                    end
                    
                end
                
            end
            SD_STATE_strm_512_aquire : begin
                if(state_op_term) begin
                    sd_state <= SD_STATE_rm_crc;
                    state_op_top <= SD_OP_TOP_rm_crc;
                    state_op_cnt <= 10'b0;
                    spi_wide_r <= 1'b0;
                    stream_trigger_r <= 1'b0;
                end else if(~spi_busy_r & ~spi_begin_r) begin
                    
                    spi_begin_r <= ~state_op_term;
                end else if(spi_busy_r & spi_begin_r) begin
                    sd_state <= SD_STATE_strm_512_trig;
                    spi_begin_r <= 1'b0;
                    
                end
                
            end
            SD_STATE_strm_512_trig : begin
                if(~spi_busy_r) begin
                    sd_state <= SD_STATE_strm_512_aquire;
                    state_op_cnt <= state_op_cnt_next;
                    stream_data_r <= spi_miso_r;
                    stream_trigger_r <= 1'b1;
                end else begin
                    stream_trigger_r <= 1'b0;
                    
                end
                
            end
            SD_STATE_rm_crc  : begin
                if(state_op_term & ~spi_busy_r) begin
                    sd_state <= SD_STATE_idle;
                    blk_off_r <= end_of_frame_r ? 9'h0 : (blk_off_r + 9'h1);
                    spi_begin_r <= 1'b0;
                    spi_cs_r <= 1'b1;
                end else if(spi_begin_r & spi_busy_r) begin
                    state_op_cnt <= state_op_cnt_next;
                    spi_begin_r <= 1'b0;
                end else if(~spi_begin_r & ~spi_busy_r) begin
                    spi_begin_r <= 1'b1;
                end
                
            end
            default: begin
                sd_state <= SD_STATE_idle;
                spi_wide_r <= 1'b0;
                spi_begin_r <= 1'b0;
                spi_cs_r <= 1'b1;
                spi_mosi_r <= 32'b0;
            end
        endcase
    end
end


    
endmodule