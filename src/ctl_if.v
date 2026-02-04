module ctl_if (
    input clk,
    input rst_n,

    //uart interface
    input [7:0]uart_rx,
    input uart_valid,
    output uart_ready,

    //control interface
    output ctl_valid,
    input ctl_ready,
    output ctl_incr,
    output ctl_decr
);

localparam CTL_STATE_idle = 2'h0 ;
localparam CTL_STATE_if_valid = 2'h1 ;
localparam CTL_STATE_fnt_ready = 2'h3 ;


localparam CMD_CHAR_increment = 8'd49 ;//'1' to increment
localparam CMD_CHAR_decrement = 8'd50 ;//'2' to decrement

//'1' increment.
//'2' decrement.
//others "here".

//hold control interface brfore ready.

/*
state trans:
(rst)idle -> (uart_valid == 1)if_valid -> (ctl_valid == 1 && ctl_ready == 1)fnt_ready -> (uart_valid == 1 && uart_ready == 1)idle
*/

reg [1:0]ctl_state;
reg ctl_valid_r;
assign ctl_valid = ctl_valid_r;
reg uart_ready_r;
assign uart_ready = uart_ready_r;
reg ctl_incr_r;
assign ctl_incr = ctl_incr_r;
reg ctl_decr_r;
assign ctl_decr = ctl_decr_r;

wire inc_cond;
assign inc_cond = ~|(uart_rx ^ CMD_CHAR_increment); 
wire dec_cond;
assign dec_cond = ~|(uart_rx ^ CMD_CHAR_decrement); 

reg uart_valid_r;
reg ctl_ready_r;

always @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        uart_valid_r <= 1'b1;
        ctl_ready_r <= 1'b0;
    end else begin
        uart_valid_r <= uart_valid;
        ctl_ready_r <= ctl_ready;
    end
end


always @(posedge clk or negedge rst_n) begin

    if(~rst_n) begin
        ctl_state <= CTL_STATE_idle;
        ctl_incr_r <= 1'b0;
        ctl_decr_r <= 1'b0;
        ctl_valid_r <= 1'b0;
        uart_ready_r <= 1'b0;
    end else begin
        case (ctl_state)
            CTL_STATE_idle : begin
                if (uart_valid_r) begin
                    ctl_state <=  (inc_cond | dec_cond) ?CTL_STATE_if_valid : CTL_STATE_idle;
                    //setup for next state
                    ctl_incr_r <= inc_cond;
                    ctl_decr_r <= dec_cond;
                    ctl_valid_r <= inc_cond | dec_cond;
                    uart_ready_r <= 1'b1;
                end else begin
                    //current state "CTL_STATE_idle" routine
                    uart_ready_r <= 1'b0;
                end
            end
            CTL_STATE_if_valid : begin
                if (ctl_valid_r & ctl_ready_r) begin
                    ctl_state <= CTL_STATE_idle;
                    //setup for next state
                    ctl_valid_r <= 1'b0;
                end else begin
                    //current state "CTL_STATE_if_valid" routine
                    uart_ready_r <= 1'b0;
                end
            end
            /*
            CTL_STATE_fnt_ready : begin
                if (uart_valid_r & uart_ready_r) begin
                    ctl_state <= CTL_STATE_idle;
                    //setup for next state
                    uart_ready_r <= 1'b0;
                end else begin
                    //current state "CTL_STATE_fnt_ready" routine
                end
            end
            */
            default: 
                ctl_state <= CTL_STATE_idle;
        endcase
    end
    
end


    
endmodule