// =============================================================================
// SD Card SPI Interface Model - SystemVerilog
// =============================================================================
//
// Scope:
//   - SPI Mode 0 (CPOL=0, CPHA=0), CS active-low
//   - Initialization sequence:
//       CMD0  (GO_IDLE_STATE)      -> R1 = 0x01
//       CMD8  (SEND_IF_COND)       -> R7 (5 bytes)
//       CMD55 (APP_CMD)            -> R1 = 0x01
//       ACMD41(SD_SEND_OP_COND)    -> R1 = 0x00 when ready
//       CMD58 (READ_OCR)           -> R3 (5 bytes)
//   - Single block read:
//       CMD17 (READ_SINGLE_BLOCK)  -> R1, data token 0xFE, 512 bytes, CRC16
//
// All variables are statically declared with explicit widths.
// No automatic variables, no dynamic arrays, no 'int' type.
//
// Parameters:
//   MEM_BLOCKS  - number of 512-byte blocks of internal storage
//   NCR_MAX     - number of 0xFF clocks before response (Ncr, 1..8 per spec)
//
// =============================================================================

`timescale 1ns / 1ps

module sd_mock #(
    parameter integer MEM_BLOCKS = 64,   // Number of 512-byte blocks
    parameter integer NCR_MAX    = 8     // Response delay in SCK clocks
) (
    input  logic cs_n,  // Chip select, active low
    input  logic sck,   // SPI clock (model samples on rising edge)
    input  logic mosi,  // Master out, slave in
    output logic miso   // Master in, slave out
);

    // =========================================================================
    // Constants
    // =========================================================================

    // Block and memory geometry
    localparam integer BLOCK_BYTES  = 512;
    localparam integer MEM_BYTES    = MEM_BLOCKS * BLOCK_BYTES;

    // Fixed card register values
    // OCR: power-up done (bit31), CCS=1 SDHC (bit30), 3.2-3.4V range
    localparam logic [31:0] OCR_VAL = 32'hC0FF_8000;

    // R1 response flag values
    localparam logic [7:0] R1_OK          = 8'h00;
    localparam logic [7:0] R1_IDLE        = 8'h01;
    localparam logic [7:0] R1_ILLEGAL_CMD = 8'h04;

    // SPI framing
    localparam logic [7:0] DATA_TOKEN = 8'hFE;  // single block read token

    // Response buffer size (largest response = R3/R7 = 5 bytes)
    localparam integer RESP_BUF_LEN = 5;

    // Data buffer: 1 token byte + 512 data bytes + 2 CRC bytes = 515
    localparam integer DATA_BUF_LEN = BLOCK_BYTES + 3;

    // =========================================================================
    // State encoding
    // =========================================================================

    typedef enum logic [2:0] {
        ST_POWERUP,   // Waiting for command start bit
        ST_CMD_RECV,  // Receiving a 48-bit command frame
        ST_NCR,       // Ncr delay: output 0xFF before response
        ST_RESPOND,   // Clocking out response bytes
        ST_DATA_OUT   // Clocking out data token + block + CRC
    } state_t;

    state_t state;

    // =========================================================================
    // Internal memory (statically declared)
    // =========================================================================

    logic [7:0] mem [0 : MEM_BYTES-1];

    // =========================================================================
    // Decoded command fields (registered after full 48-bit frame)
    // =========================================================================

    logic [5:0]  cmd_index;   // command index bits [45:40]
    logic [31:0] cmd_arg;     // argument         bits [39:8]

    // =========================================================================
    // Command receive shift register
    // =========================================================================

    logic [47:0] cmd_sr;         // 48-bit shift register
    logic [5:0]  cmd_bit_cnt;    // counts bits received (0..47)

    // =========================================================================
    // Response buffer and pointers
    // =========================================================================

    logic [7:0]  resp_buf [0 : RESP_BUF_LEN-1];
    logic [2:0]  resp_total;      // number of bytes in current response (1..5)
    logic [2:0]  resp_byte_idx;   // which byte we are sending now
    logic [2:0]  resp_bit_idx;    // which bit within that byte (7 downto 0)

    // =========================================================================
    // Data output buffer and pointers
    // data_buf[0]      = 0xFE data token
    // data_buf[1..512] = block payload
    // data_buf[513..514] = CRC16 (high byte first)
    // =========================================================================

    logic [7:0]  data_buf [0 : DATA_BUF_LEN-1];
    logic [9:0]  data_total;      // total bytes to clock out (always 515)
    logic [9:0]  data_byte_idx;   // current byte index
    logic [2:0]  data_bit_idx;    // current bit within byte (7 downto 0)

    // =========================================================================
    // Ncr delay counter
    // =========================================================================

    logic [3:0]  ncr_cnt;         // counts Ncr clocks (0..NCR_MAX-1)

    // =========================================================================
    // Card status flags
    // =========================================================================

    logic        app_cmd_pending;  // set by CMD55, cleared after ACMD
    logic        card_init_done;   // set when ACMD41 completes successfully

    // =========================================================================
    // Task-scope static variables
    // (declared at module level to avoid 'automatic' storage)
    // =========================================================================

    // Used in load_response_r1 / load_response_r3r7
    // (no extra variables needed beyond parameters passed in)

    // Used in prepare_read_block
    logic [31:0] rb_base_byte;     // byte offset into mem[]
    logic [9:0]  rb_bi;            // byte iterator within block
    logic [15:0] rb_crc;           // running CRC16
    logic [7:0]  rb_dbyte;         // current data byte
    logic [3:0]  rb_bbit;          // bit iterator within byte

    // Used in decode_and_respond
    logic [7:0]  dr_r1_flags;      // R1 flags computed before case statement

    // Next-state output from decode_and_respond
    state_t      cmd_next_state;

    // miso_next: the bit value to be placed on MISO at the next falling edge.
    // The posedge block computes it; the negedge block drives it onto miso.
    logic        miso_next;

    // =========================================================================
    // Memory and register initialisation
    // =========================================================================

    integer init_i;

    initial begin
        // Fill memory with 0xFF (erased flash default)
        for (init_i = 0; init_i < MEM_BYTES; init_i = init_i + 1)
            mem[init_i] = 8'hFF;

        // Seed block 0 with an incrementing pattern for readback verification
        for (init_i = 0; init_i < BLOCK_BYTES; init_i = init_i + 1)
            mem[init_i] = init_i[7:0];

        // Reset all state registers
        state            = ST_POWERUP;
        miso             = 1'b1;
        miso_next        = 1'b1;
        cmd_sr           = 48'h0;
        cmd_bit_cnt      = 6'h0;
        cmd_index        = 6'h0;
        cmd_arg          = 32'h0;
        resp_total       = 3'h0;
        resp_byte_idx    = 3'h0;
        resp_bit_idx     = 3'h7;
        data_total       = 10'd515;
        data_byte_idx    = 10'h0;
        data_bit_idx     = 3'h7;
        ncr_cnt          = 4'h0;
        app_cmd_pending  = 1'b0;
        card_init_done   = 1'b0;
        rb_base_byte     = 32'h0;
        rb_bi            = 10'h0;
        rb_crc           = 16'h0;
        rb_dbyte         = 8'h0;
        rb_bbit          = 4'h0;
        dr_r1_flags      = 8'h0;
        cmd_next_state   = ST_POWERUP;
        miso_next        = 1'b1;
    end

    // =========================================================================
    // Tasks
    // All variables used inside tasks are declared at module level (above)
    // so they have static, not automatic, storage.
    // =========================================================================

    // -------------------------------------------------------------------------
    // load_response_r1
    //   Writes a 1-byte R1 response into resp_buf and initialises pointers.
    // -------------------------------------------------------------------------
    task load_response_r1;
        input logic [7:0] flags;
        begin
            resp_buf[0]   = flags;
            resp_total    = 3'd1;
            resp_byte_idx = 3'd0;
            resp_bit_idx  = 3'd7;
        end
    endtask

    // -------------------------------------------------------------------------
    // load_response_r3r7
    //   Writes a 5-byte R3/R7 response (R1 + 32-bit payload) into resp_buf.
    // -------------------------------------------------------------------------
    task load_response_r3r7;
        input logic [7:0]  flags;
        input logic [31:0] payload;
        begin
            resp_buf[0]   = flags;
            resp_buf[1]   = payload[31:24];
            resp_buf[2]   = payload[23:16];
            resp_buf[3]   = payload[15: 8];
            resp_buf[4]   = payload[ 7: 0];
            resp_total    = 3'd5;
            resp_byte_idx = 3'd0;
            resp_bit_idx  = 3'd7;
        end
    endtask

    // -------------------------------------------------------------------------
    // prepare_read_block
    //   Fills data_buf with: token (0xFE) + 512 bytes from mem[] + CRC16.
    //   Uses module-level variables: rb_base_byte, rb_bi, rb_crc, rb_dbyte,
    //   rb_bbit.
    // -------------------------------------------------------------------------
    task prepare_read_block;
        input logic [31:0] block_addr;
        begin
            rb_base_byte = block_addr * BLOCK_BYTES;

            // Byte 0 of data_buf: data start token
            data_buf[0] = DATA_TOKEN;

            // Bytes 1..512: block payload with CRC16-CCITT computed on the fly
            rb_crc = 16'h0000;
            for (rb_bi = 10'd0; rb_bi < 10'd512; rb_bi = rb_bi + 10'd1) begin
                if ((rb_base_byte + rb_bi) < MEM_BYTES)
                    rb_dbyte = mem[rb_base_byte + rb_bi];
                else
                    rb_dbyte = 8'hFF;

                data_buf[rb_bi + 10'd1] = rb_dbyte;

                // CRC16-CCITT update for this byte (poly 0x1021)
                rb_crc = rb_crc ^ ({8'h00, rb_dbyte} << 8);
                for (rb_bbit = 4'd0; rb_bbit < 4'd8; rb_bbit = rb_bbit + 4'd1) begin
                    if (rb_crc[15])
                        rb_crc = (rb_crc << 1) ^ 16'h1021;
                    else
                        rb_crc = rb_crc << 1;
                end
            end

            // Bytes 513..514: CRC16 (high byte first)
            data_buf[513] = rb_crc[15:8];
            data_buf[514] = rb_crc[ 7:0];

            // Initialise output pointers
            data_total    = 10'd515;
            data_byte_idx = 10'd0;
            data_bit_idx  = 3'd7;
        end
    endtask

    // -------------------------------------------------------------------------
    // decode_and_respond
    //   Decodes the fully received 48-bit command frame (in cmd_sr).
    //   Populates resp_buf via load_response_r1/r3r7.
    //   Optionally calls prepare_read_block for CMD17.
    //   Returns the next state through the output argument.
    //   Uses module-level variable: dr_r1_flags.
    // -------------------------------------------------------------------------
    task decode_and_respond;
        input  logic [47:0] frame;      // fully assembled 48-bit command frame
        output state_t      next_state;
        begin
            // Extract fields from the supplied frame.
            // The caller constructs this as {cmd_sr[46:0], mosi} so that the
            // last MOSI bit (not yet written to cmd_sr via the non-blocking
            // assignment) is included correctly.
            cmd_index = frame[45:40];
            cmd_arg   = frame[39: 8];
            // frame[7:1] = CRC7 (not checked in this model)
            // frame[0]   = stop bit

            dr_r1_flags = card_init_done ? R1_OK : R1_IDLE;

            case (cmd_index)

                // --------------------------------------------------------------
                // CMD0 - GO_IDLE_STATE
                //   Resets card into SPI mode. R1 = 0x01 (idle).
                // --------------------------------------------------------------
                6'd0: begin
                    card_init_done  = 1'b0;
                    app_cmd_pending = 1'b0;
                    load_response_r1(R1_IDLE);
                    next_state = ST_NCR;
                end

                // --------------------------------------------------------------
                // CMD8 - SEND_IF_COND
                //   Voltage range check. Arg[11:8] = VHS, Arg[7:0] = pattern.
                //   Voltage code 0x1 = 2.7-3.6 V accepted.
                //   Echoes arg[11:0] back in R7 payload.
                // --------------------------------------------------------------
                6'd8: begin
                    if (cmd_arg[11:8] == 4'h1) begin
                        load_response_r3r7(R1_IDLE, {20'h0_0000, cmd_arg[11:0]});
                    end else begin
                        load_response_r1(R1_IDLE | R1_ILLEGAL_CMD);
                    end
                    next_state = ST_NCR;
                end

                // --------------------------------------------------------------
                // CMD55 - APP_CMD
                //   Signals that the next command is an application command.
                // --------------------------------------------------------------
                6'd55: begin
                    app_cmd_pending = 1'b1;
                    load_response_r1(dr_r1_flags);
                    next_state = ST_NCR;
                end

                // --------------------------------------------------------------
                // CMD41 - SD_SEND_OP_COND (treated as ACMD41 when app_cmd_pending)
                //   Completes initialisation on the first attempt.
                //   R1 = 0x00 (not idle) when done.
                // --------------------------------------------------------------
                6'd41: begin
                    if (app_cmd_pending) begin
                        card_init_done  = 1'b1;
                        app_cmd_pending = 1'b0;
                        load_response_r1(R1_OK);
                    end else begin
                        app_cmd_pending = 1'b0;
                        load_response_r1(dr_r1_flags | R1_ILLEGAL_CMD);
                    end
                    next_state = ST_NCR;
                end

                // --------------------------------------------------------------
                // CMD58 - READ_OCR
                //   Returns R3: R1 followed by the 32-bit OCR register.
                // --------------------------------------------------------------
                6'd58: begin
                    load_response_r3r7(dr_r1_flags, OCR_VAL);
                    next_state = ST_NCR;
                end

                // --------------------------------------------------------------
                // CMD17 - READ_SINGLE_BLOCK
                //   Arg = SDHC block address.
                //   Returns R1 then data token + 512 bytes + CRC16.
                // --------------------------------------------------------------
                6'd17: begin
                    if (!card_init_done) begin
                        load_response_r1(R1_IDLE);
                        next_state = ST_NCR;
                    end else begin
                        load_response_r1(R1_OK);
                        prepare_read_block(cmd_arg);
                        next_state = ST_NCR;
                    end
                end

                // --------------------------------------------------------------
                // Default: unsupported / unrecognised command
                // --------------------------------------------------------------
                default: begin
                    app_cmd_pending = 1'b0;
                    load_response_r1(dr_r1_flags | R1_ILLEGAL_CMD);
                    next_state = ST_NCR;
                end

            endcase
        end
    endtask

    // =========================================================================
    // Main SPI state machine
    // Clocked on rising edge of SCK (SPI Mode 0, CPOL=0, CPHA=0).
    // Asynchronous reset on CS deassertion.
    // =========================================================================

    // =========================================================================
    // Rising edge: sample MOSI, advance state, compute miso_next.
    // miso_next holds the bit that will be placed on MISO at the *next*
    // falling edge, giving a full half-period of setup time before the
    // master samples on the following rising edge (SPI Mode 0 requirement).
    // =========================================================================

    always @(posedge sck or posedge cs_n) begin

        if (cs_n) begin
            // -----------------------------------------------------------------
            // CS deasserted: reset receive path; preserve card status flags
            // -----------------------------------------------------------------
            state       <= ST_POWERUP;
            miso_next   <= 1'b1;
            cmd_sr      <= 48'h0;
            cmd_bit_cnt <= 6'h0;
            ncr_cnt     <= 4'h0;

        end else begin

            case (state)

                // -------------------------------------------------------------
                // ST_POWERUP
                // Wait for a valid command frame start bit (MOSI = 0).
                // Between frames the host clocks dummy 0xFF bytes (MOSI=1);
                // these are ignored here.
                // -------------------------------------------------------------
                ST_POWERUP: begin
                    miso_next <= 1'b1;
                    if (mosi == 1'b0) begin
                        // Start bit detected; begin command receive
                        cmd_sr      <= {47'h0, 1'b0};
                        cmd_bit_cnt <= 6'd1;
                        state       <= ST_CMD_RECV;
                    end
                end

                // -------------------------------------------------------------
                // ST_CMD_RECV
                // Shift 48 bits in MSB-first.
                // Frame structure:
                //   bit 47     : start bit (0)      - already captured
                //   bit 46     : transmitter bit (1)
                //   bits 45:40 : command index
                //   bits 39:8  : argument
                //   bits 7:1   : CRC7
                //   bit 0      : stop bit (1)
                // While receiving a command the card keeps MISO high (0xFF).
                // After the last bit is clocked in, decode the command and
                // pre-load the first NCR bit (1) into miso_next so the
                // falling edge immediately after can drive it correctly.
                // -------------------------------------------------------------
                ST_CMD_RECV: begin
                    miso_next   <= 1'b1;
                    cmd_sr      <= {cmd_sr[46:0], mosi};
                    cmd_bit_cnt <= cmd_bit_cnt + 6'd1;

                    if (cmd_bit_cnt == 6'd47) begin
                        // All 48 bits received; decode command.
                        // Pass {cmd_sr[46:0], mosi} so the final MOSI bit is
                        // included without waiting for the non-blocking update
                        // to cmd_sr to take effect.
                        cmd_bit_cnt <= 6'd0;
                        ncr_cnt     <= 4'd0;
                        decode_and_respond({cmd_sr[46:0], mosi}, cmd_next_state);
                        state       <= cmd_next_state;
                        // miso_next stays 1'b1: first NCR bit is always 1
                    end
                end

                // -------------------------------------------------------------
                // ST_NCR
                // Count NCR_MAX clocks of MISO=1 (0xFF) before response.
                // On the last NCR clock, pre-load the first response bit into
                // miso_next so it transitions on the very next falling edge.
                // -------------------------------------------------------------
                ST_NCR: begin
                    ncr_cnt <= ncr_cnt + 4'd1;

                    if (ncr_cnt == 4'(NCR_MAX - 1)) begin
                        // Last NCR clock: pre-load bit 7 of first response byte
                        ncr_cnt       <= 4'd0;
                        resp_byte_idx <= 3'd0;
                        resp_bit_idx  <= 3'd7;
                        miso_next     <= resp_buf[0][7];
                        state         <= ST_RESPOND;
                    end else begin
                        miso_next <= 1'b1;
                    end
                end

                // -------------------------------------------------------------
                // ST_RESPOND
                // The current rising edge confirms the master has sampled the
                // bit that was set up on the previous falling edge.
                // Advance the pointer and pre-load the *next* bit into
                // miso_next for the upcoming falling edge.
                // -------------------------------------------------------------
                ST_RESPOND: begin
                    if (resp_bit_idx == 3'd0) begin
                        // Finished this byte
                        resp_bit_idx <= 3'd7;

                        if (resp_byte_idx == (resp_total - 3'd1)) begin
                            // Last byte of response done
                            resp_byte_idx <= 3'd0;

                            if ((cmd_index == 6'd17) && card_init_done) begin
                                // Pre-load first data bit (token byte bit 7)
                                data_byte_idx <= 10'd0;
                                data_bit_idx  <= 3'd7;
                                miso_next     <= data_buf[0][7];
                                state         <= ST_DATA_OUT;
                            end else begin
                                miso_next <= 1'b1;
                                state     <= ST_POWERUP;
                            end

                        end else begin
                            // Advance to next response byte; pre-load its bit 7
                            miso_next     <= resp_buf[resp_byte_idx + 3'd1][7];
                            resp_byte_idx <= resp_byte_idx + 3'd1;
                        end

                    end else begin
                        // Mid-byte: pre-load the next lower bit
                        miso_next    <= resp_buf[resp_byte_idx][resp_bit_idx - 3'd1];
                        resp_bit_idx <= resp_bit_idx - 3'd1;
                    end
                end

                // -------------------------------------------------------------
                // ST_DATA_OUT
                // Same scheme as ST_RESPOND: on each rising edge the master has
                // sampled the previous bit; advance the pointer and pre-load
                // the next bit into miso_next.
                //   data_buf[0]        = 0xFE  (data start token)
                //   data_buf[1..512]   = block payload
                //   data_buf[513..514] = CRC16-CCITT (high byte first)
                // -------------------------------------------------------------
                ST_DATA_OUT: begin
                    if (data_bit_idx == 3'd0) begin
                        data_bit_idx <= 3'd7;

                        if (data_byte_idx == (data_total - 10'd1)) begin
                            // All bytes sent
                            data_byte_idx <= 10'd0;
                            miso_next     <= 1'b1;
                            state         <= ST_POWERUP;
                        end else begin
                            // Pre-load bit 7 of the next byte
                            miso_next     <= data_buf[data_byte_idx + 10'd1][7];
                            data_byte_idx <= data_byte_idx + 10'd1;
                        end

                    end else begin
                        // Pre-load the next lower bit of the current byte
                        miso_next    <= data_buf[data_byte_idx][data_bit_idx - 3'd1];
                        data_bit_idx <= data_bit_idx - 3'd1;
                    end
                end

                // -------------------------------------------------------------
                // Default: should never be reached
                // -------------------------------------------------------------
                default: begin
                    state     <= ST_POWERUP;
                    miso_next <= 1'b1;
                end

            endcase
        end
    end

    // =========================================================================
    // Falling edge: transfer miso_next onto MISO.
    // This ensures MISO transitions on the falling edge, giving a full
    // half-period of setup time before the master samples on the next
    // rising edge, satisfying the SPI Mode 0 protocol requirement.
    // CS deassertion also forces MISO high immediately.
    // =========================================================================

    always @(negedge sck or posedge cs_n) begin
        if (cs_n)
            miso <= 1'b1;
        else
            miso <= miso_next;
    end

endmodule


// =============================================================================
// Testbench
// Compile with +define+SD_SPI_TB  (iverilog: -DSD_SPI_TB)
// =============================================================================
`ifdef SD_SPI_TB

module sd_card_spi_tb;

    // -------------------------------------------------------------------------
    // DUT connections
    // -------------------------------------------------------------------------
    logic cs_n;
    logic sck;
    logic mosi;
    logic miso;

    sd_card_spi #(
        .MEM_BLOCKS (4),
        .NCR_MAX    (4)
    ) dut (
        .cs_n (cs_n),
        .sck  (sck),
        .mosi (mosi),
        .miso (miso)
    );

    // -------------------------------------------------------------------------
    // SPI timing: 10 MHz clock -> 50 ns half-period
    // -------------------------------------------------------------------------
    localparam integer T_HALF = 50; // ns

    // -------------------------------------------------------------------------
    // Testbench static variables (no automatic storage)
    // -------------------------------------------------------------------------
    integer      tb_i;           // general loop counter
    integer      tb_tries;       // NCR poll counter
    integer      tb_b;           // bit loop counter inside spi_transfer_byte

    logic [7:0]  tb_tx_byte;     // byte to transmit
    logic [7:0]  tb_rx_byte;     // byte received
    logic [7:0]  tb_r1;          // R1 response byte
    logic [7:0]  tb_r7  [0:3];   // R7 trailing payload bytes
    logic [7:0]  tb_ocr [0:3];   // OCR payload bytes
    logic [7:0]  tb_token;       // data token byte
    logic [7:0]  tb_data [0:511];// received block data
    logic [7:0]  tb_crc_hi;      // block CRC high byte
    logic [7:0]  tb_crc_lo;      // block CRC low byte
    logic [5:0]  tb_cmd;         // command index
    logic [31:0] tb_arg;         // command argument
    logic [7:0]  tb_crc_stop;    // command CRC+stop byte

    // -------------------------------------------------------------------------
    // Task: spi_transfer_byte
    //   Sends tb_tx_byte MSB-first on MOSI and captures the received byte
    //   into tb_rx_byte.  Variables tb_b, tb_tx_byte, tb_rx_byte are
    //   module-level statics.
    // -------------------------------------------------------------------------
    task spi_transfer_byte;
        begin
            for (tb_b = 7; tb_b >= 0; tb_b = tb_b - 1) begin
                mosi = tb_tx_byte[tb_b];
                #(T_HALF);
                sck           = 1'b1;          // rising edge
                tb_rx_byte[tb_b] = miso;
                #(T_HALF);
                sck           = 1'b0;          // falling edge
            end
        end
    endtask

    // -------------------------------------------------------------------------
    // Task: sd_send_command
    //   Sends a 6-byte SD command frame using module-level variables
    //   tb_cmd, tb_arg, tb_crc_stop.
    //   Polls for R1 (up to 16 bytes) and stores the result in tb_r1.
    //   CS must be asserted by the caller before this task.
    // -------------------------------------------------------------------------
    task sd_send_command;
        begin
            tb_tx_byte = {2'b01, tb_cmd};   spi_transfer_byte;
            tb_tx_byte = tb_arg[31:24];     spi_transfer_byte;
            tb_tx_byte = tb_arg[23:16];     spi_transfer_byte;
            tb_tx_byte = tb_arg[15: 8];     spi_transfer_byte;
            tb_tx_byte = tb_arg[ 7: 0];     spi_transfer_byte;
            tb_tx_byte = tb_crc_stop;       spi_transfer_byte;

            // Poll for R1: first byte with MSB=0 is the response
            tb_r1 = 8'hFF;
            for (tb_tries = 0; tb_tries < 16 && tb_r1[7]; tb_tries = tb_tries + 1) begin
                tb_tx_byte = 8'hFF;
                spi_transfer_byte;
                tb_r1 = tb_rx_byte;
            end

            $display("[TB] CMD%0d arg=0x%08X  R1=0x%02X", tb_cmd, tb_arg, tb_r1);
        end
    endtask

    // -------------------------------------------------------------------------
    // Test sequence
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("sd_card_spi.vcd");
        $dumpvars(0, sd_card_spi_tb);

        // Initial signal state
        cs_n = 1'b1;
        sck  = 1'b0;
        mosi = 1'b1;
        #200;

        // =====================================================================
        // Step 1: Power-up dummy clocks (>= 74) with CS deasserted
        // =====================================================================
        $display("[TB] --- Power-up: 80 dummy clocks with CS=1 ---");
        for (tb_i = 0; tb_i < 80; tb_i = tb_i + 1) begin
            #(T_HALF); sck = 1'b1;
            #(T_HALF); sck = 1'b0;
        end
        #200;

        // =====================================================================
        // Step 2: CMD0 - GO_IDLE_STATE  (expected R1 = 0x01)
        // =====================================================================
        $display("[TB] --- CMD0 GO_IDLE_STATE ---");
        cs_n        = 1'b0;
        tb_cmd      = 6'd0;
        tb_arg      = 32'h0000_0000;
        tb_crc_stop = 8'h95;          // correct CRC for CMD0 arg=0
        sd_send_command;
        cs_n = 1'b1;
        #200;

        if (tb_r1 !== 8'h01)
            $display("[TB] FAIL CMD0: expected R1=0x01 got 0x%02X", tb_r1);
        else
            $display("[TB] PASS CMD0");

        // =====================================================================
        // Step 3: CMD8 - SEND_IF_COND  (expected R7 echo 0x000001AA)
        // =====================================================================
        $display("[TB] --- CMD8 SEND_IF_COND ---");
        cs_n        = 1'b0;
        tb_cmd      = 6'd8;
        tb_arg      = 32'h0000_01AA;  // VHS=0x1, check pattern=0xAA
        tb_crc_stop = 8'h87;          // correct CRC for CMD8 arg=0x1AA
        sd_send_command;

        // Read 4 trailing R7 payload bytes
        for (tb_i = 0; tb_i < 4; tb_i = tb_i + 1) begin
            tb_tx_byte = 8'hFF;
            spi_transfer_byte;
            tb_r7[tb_i] = tb_rx_byte;
        end
        cs_n = 1'b1;
        #200;

        $display("[TB] CMD8 R7 payload: 0x%02X%02X%02X%02X",
                 tb_r7[0], tb_r7[1], tb_r7[2], tb_r7[3]);

        if (tb_r1 !== 8'h01)
            $display("[TB] FAIL CMD8: R1 expected 0x01 got 0x%02X", tb_r1);
        else if (tb_r7[2] !== 8'h01 || tb_r7[3] !== 8'hAA)
            $display("[TB] FAIL CMD8: echo pattern mismatch");
        else
            $display("[TB] PASS CMD8");

        // =====================================================================
        // Step 4: ACMD41 loop (CMD55 + CMD41) until R1 == 0x00
        // =====================================================================
        $display("[TB] --- ACMD41 initialisation ---");
        tb_r1 = 8'h01;
        while (tb_r1 !== 8'h00) begin
            // CMD55 - APP_CMD
            cs_n        = 1'b0;
            tb_cmd      = 6'd55;
            tb_arg      = 32'h0000_0000;
            tb_crc_stop = 8'hFF;
            sd_send_command;
            cs_n = 1'b1;
            #200;

            // ACMD41 - HCS=1 (bit 30) for SDHC
            cs_n        = 1'b0;
            tb_cmd      = 6'd41;
            tb_arg      = 32'h4000_0000;
            tb_crc_stop = 8'hFF;
            sd_send_command;
            cs_n = 1'b1;
            #200;
        end
        $display("[TB] PASS: card initialised (R1=0x00)");

        // =====================================================================
        // Step 5: CMD58 - READ_OCR  (expected OCR = 0xC0FF8000)
        // =====================================================================
        $display("[TB] --- CMD58 READ_OCR ---");
        cs_n        = 1'b0;
        tb_cmd      = 6'd58;
        tb_arg      = 32'h0000_0000;
        tb_crc_stop = 8'hFF;
        sd_send_command;

        for (tb_i = 0; tb_i < 4; tb_i = tb_i + 1) begin
            tb_tx_byte = 8'hFF;
            spi_transfer_byte;
            tb_ocr[tb_i] = tb_rx_byte;
        end
        cs_n = 1'b1;
        #200;

        $display("[TB] CMD58 OCR = 0x%02X%02X%02X%02X",
                 tb_ocr[0], tb_ocr[1], tb_ocr[2], tb_ocr[3]);

        if ({tb_ocr[0],tb_ocr[1],tb_ocr[2],tb_ocr[3]} !== 32'hC0FF_8000)
            $display("[TB] FAIL CMD58: OCR mismatch");
        else
            $display("[TB] PASS CMD58");

        // =====================================================================
        // Step 6: CMD17 - READ_SINGLE_BLOCK block 0
        //   Block 0 seeded: mem[0]=0x00, mem[1]=0x01, ..., mem[255]=0xFF,
        //                   mem[256]=0x00, ..., mem[511]=0xFF
        // =====================================================================
        $display("[TB] --- CMD17 READ_SINGLE_BLOCK addr=0 ---");
        cs_n        = 1'b0;
        tb_cmd      = 6'd17;
        tb_arg      = 32'h0000_0000;
        tb_crc_stop = 8'hFF;
        sd_send_command;

        // Poll for data token 0xFE (up to 32 bytes)
        tb_token = 8'hFF;
        for (tb_tries = 0; tb_tries < 32 && tb_token !== 8'hFE; tb_tries = tb_tries + 1) begin
            tb_tx_byte = 8'hFF;
            spi_transfer_byte;
            tb_token = tb_rx_byte;
        end

        if (tb_token !== 8'hFE) begin
            $display("[TB] FAIL CMD17: no data token (got 0x%02X)", tb_token);
        end else begin
            $display("[TB] CMD17: data token 0xFE received");

            // Read 512 data bytes
            for (tb_i = 0; tb_i < 512; tb_i = tb_i + 1) begin
                tb_tx_byte = 8'hFF;
                spi_transfer_byte;
                tb_data[tb_i] = tb_rx_byte;
            end

            // Read 2 CRC bytes
            tb_tx_byte = 8'hFF; spi_transfer_byte; tb_crc_hi = tb_rx_byte;
            tb_tx_byte = 8'hFF; spi_transfer_byte; tb_crc_lo = tb_rx_byte;

            $display("[TB] CMD17 data[0]=0x%02X data[1]=0x%02X data[255]=0x%02X data[511]=0x%02X",
                     tb_data[0], tb_data[1], tb_data[255], tb_data[511]);
            $display("[TB] CMD17 CRC16 = 0x%02X%02X", tb_crc_hi, tb_crc_lo);

            if (tb_data[0]   !== 8'h00 ||
                tb_data[1]   !== 8'h01 ||
                tb_data[255] !== 8'hFF ||
                tb_data[256] !== 8'h00)
                $display("[TB] FAIL CMD17: data pattern mismatch");
            else
                $display("[TB] PASS CMD17: data pattern correct");
        end

        cs_n = 1'b1;
        #200;

        // =====================================================================
        // Step 7: CMD17 - read non-existent block (beyond MEM_BLOCKS)
        //   Should still return R1=0x00 and 0xFF-filled data.
        // =====================================================================
        $display("[TB] --- CMD17 READ_SINGLE_BLOCK addr=0xFF (out of range) ---");
        cs_n        = 1'b0;
        tb_cmd      = 6'd17;
        tb_arg      = 32'h0000_00FF;
        tb_crc_stop = 8'hFF;
        sd_send_command;

        tb_token = 8'hFF;
        for (tb_tries = 0; tb_tries < 32 && tb_token !== 8'hFE; tb_tries = tb_tries + 1) begin
            tb_tx_byte = 8'hFF;
            spi_transfer_byte;
            tb_token = tb_rx_byte;
        end

        if (tb_token === 8'hFE) begin
            for (tb_i = 0; tb_i < 512; tb_i = tb_i + 1) begin
                tb_tx_byte = 8'hFF;
                spi_transfer_byte;
                tb_data[tb_i] = tb_rx_byte;
            end
            tb_tx_byte = 8'hFF; spi_transfer_byte; tb_crc_hi = tb_rx_byte;
            tb_tx_byte = 8'hFF; spi_transfer_byte; tb_crc_lo = tb_rx_byte;
            $display("[TB] Out-of-range read: data[0]=0x%02X (expect 0xFF)", tb_data[0]);
        end

        cs_n = 1'b1;
        #200;

        // =====================================================================
        // Done
        // =====================================================================
        $display("[TB] --- Simulation complete ---");
        #1000;
        $finish;
    end

endmodule

`endif // SD_SPI_TB