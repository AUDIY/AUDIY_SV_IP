/*----------------------------------------------------------------------------
* SDPRAM_SINGLECLK_tb.sv
*
* Test bench for Simple Dual-Port RAM (Single Clock)
*
* Version: 0.01
* Author : AUDIY
* Date   : 2025/01/04
*
* License under CERN-OHL-P v2
--------------------------------------------------------------------------------
| Copyright AUDIY 2025.                                                        |
|                                                                              |
| This source describes Open Hardware and is licensed under the CERN-OHL-P v2. |
|                                                                              |
| You may redistribute and modify this source and make products using it under |
| the terms of the CERN-OHL-P v2 (https:/cern.ch/cern-ohl).                    |
|                                                                              |
| This source is distributed WITHOUT ANY EXPRESS OR IMPLIED WARRANTY,          |
| INCLUDING OF MERCHANTABILITY, SATISFACTORY QUALITY AND FITNESS FOR A         |
| PARTICULAR PURPOSE. Please see the CERN-OHL-P v2 for applicable conditions.  |
--------------------------------------------------------------------------------
*
-----------------------------------------------------------------------------*/

`resetall

module SDPRAM_SINGLECLK_tb ();

    timeunit 1ns/1ps;

    localparam int unsigned DATA_WIDTH = 8;
    localparam int unsigned DEPTH = 128;
    localparam int unsigned AD_WIDTH = (DEPTH >= 2) ? $clog2(DEPTH) : 1;
    localparam bit          OUTPUT_REG = 1'b0;
    localparam string       RAM_INIT_FILE = "ram_init_file.mem";

    logic                             CLK_I   = 1'b0;
    logic unsigned [AD_WIDTH - 1:0]   WADDR_I;
    logic                             WEN_I  ;
    logic          [DATA_WIDTH - 1:0] WDATA_I;
    logic unsigned [AD_WIDTH - 1:0]   RADDR_I;
    logic                             REN_I  ;
    logic          [DATA_WIDTH - 1:0] RDATA_O;

    logic CLOCK = 1'b0;
    logic RCLK  = 1'b0;
    logic [DATA_WIDTH - 1:0] EXP;
    logic NRST;
    integer cycle_count;

    /* Instantiate the DUT */
    SDPRAM_SINGLECLK #(
        .DATA_WIDTH   (DATA_WIDTH   ),
        .DEPTH        (DEPTH        ),
        .OUTPUT_REG   (OUTPUT_REG   ),
        .RAM_INIT_FILE(RAM_INIT_FILE)
    ) u0 (
        .CLK_I  (CLK_I  ),
        .WADDR_I(WADDR_I),
        .WEN_I  (WEN_I  ),
        .WDATA_I(WDATA_I),
        .RADDR_I(RADDR_I),
        .REN_I  (REN_I  ),
        .RDATA_O(RDATA_O)
    );

    initial begin
        $dumpfile("SDPRAM_SINGLECLK.vcd");
        $dumpvars(0, SDPRAM_SINGLECLK_tb);

        /* Initialize */
        #1 NRST = 1'b1;
        #1 NRST = 1'b0;
        #1 NRST = 1'b1;
    end

    /* Clock Generation */
    initial begin
        forever #75 begin
            CLOCK = ~CLOCK;
            #25 RCLK = ~RCLK;
            #25 CLK_I = ~CLK_I;
        end
    end

    /* Increment the cycle counter */
    always @( negedge CLOCK or negedge NRST) begin
        if ( !NRST ) begin
            cycle_count = -4;
        end else begin
            cycle_count = cycle_count + 1;

            /* Allow 3 complete traversals of the memory address space */
            if (cycle_count == 77) begin
                $display("TEST : PASS");
                $finish(0);
            end
        end
    end

    /* Simulate the write port */
    always @( negedge CLK_I or negedge NRST ) begin
        if ( !NRST ) begin
            WDATA_I = 70;
            WADDR_I = '0;
            WEN_I = 1'b0;
        end else begin
            /* let some cycles go before starting the writing and reading */
            if ( cycle_count == -1 ) begin
                /* Enable writing just before cycle 0 */
                WEN_I = 1'b1;
            end else if ( cycle_count >= 0 ) begin
                $display("%t === === === Write Cycle:%d === === ===", $time, cycle_count);
                $display("WDATA : %d\tWADDR : %d\tWE : %d", WDATA_I, WADDR_I, WEN_I);

                /* Increment data and address */
                WDATA_I = WDATA_I + 2;
                WADDR_I = WADDR_I + 1;
            end
        end
    end

    /* Simulate the read port */
    always @( negedge RCLK or negedge NRST ) begin
        if ( !NRST ) begin
            REN_I = 1'b0;
            EXP = 255;
            RADDR_I = '0;
        end else begin
            /* let some cycles go before starting the writing and reading */
            if ( cycle_count == -1 ) begin
                /* Enable reading just before cycle 0 */
                REN_I = 1'b1;
            end else if ( cycle_count >= 0 ) begin
                $display("%t === === === Read Cycle: %d === === ===", $time, cycle_count);
                $display("RADDR : %d\tRE : %d", RADDR_I, REN_I);
                $display("\tRDATA : %d", RDATA_O);

                if (cycle_count < 512) begin
                    /* First read 256 uninitialized memory locations */
                    EXP = 255 - cycle_count;
                end else begin
                    /* For the next 256 reads the data should be the value 00-FF */
                    EXP = 70 + ((cycle_count - 512) * 2);
                end

                if (EXP !== RDATA_O) begin
                    $display("\tMISMATCH: Expected %d got RDATA : %d", EXP, RDATA_O);
                    $display("TEST : FAIL");
                    $finish();
                end

                /* Increment address */
                RADDR_I = RADDR_I + 1;
            end
        end
    end
   
endmodule
