module ctl_if (
    input clk,
    input rst_n,

    //uart interface
    output uart_tx,
    input uart_rx,
    input uart_valid,
    output uart_ready,
    input uart_busy,
    output uart_begin,

    //control interface
    output ctl_valid,
    input ctl_ready,
    output ctl_incr,
    output ctl_decr
);

//'1' increment.
//'2' decrement.
//others "here".

//hold control interface brfore ready.
    
endmodule