/*----------------------------------------------------------------------------
* SPROM_tb.sv
*
* Single-Port ROM
*
* Version: 0.01
* Author : AUDIY
* Date   : 2025/01/08
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
`default_nettype none

module SPROM_tb ();

    timeunit 1ns / 10ps;

    localparam int    unsigned DATA_WIDTH = 8;
    localparam int    unsigned DEPTH = 256;
    localparam bit             OUTPUT_REG = 1'b0;
    localparam string          ROM_INIT_FILE = "initrom.hex";

    localparam int unsigned AD_WIDTH = (DEPTH >= 2) ? $clog2(DEPTH) : 1;

    logic                             CLK_I = 1'b0;
    logic unsigned [AD_WIDTH - 1:0]   RADDR_I;
    logic          [DATA_WIDTH - 1:0] RDATA_O;

    logic RESET = 1'b0;
    integer cycle_count;
    logic   [DATA_WIDTH - 1:0] expected;

    SPROM #(
        .DATA_WIDTH   (DATA_WIDTH   ),
        .DEPTH        (DEPTH        ),
        .OUTPUT_REG   (OUTPUT_REG   ),
        .ROM_INIT_FILE(ROM_INIT_FILE)
    ) u0 (
        .CLK_I  (CLK_I  ),
        .RADDR_I(RADDR_I),
        .RDATA_O(RDATA_O)
    );

    initial begin
        $dumpfile("SPROM.vcd");
        $dumpvars(0, SPROM_tb);

        #1 RESET = 1'b1;
        #1 RESET = 1'b0;
        #1 RESET = 1'b1;
    end

    initial begin
        forever begin
            #100 CLK_I = ~CLK_I;
        end
    end

    always @( negedge CLK_I or negedge RESET ) begin
        if ( !RESET ) begin
            RADDR_I = '0;
            expected = '0;
            cycle_count = -2;
        end else begin
            if ( cycle_count >= 0 ) begin
                $display("=== === === Cycle:%d === === ===", cycle_count);
                $display("ADDR : %x", RADDR_I);
                $display("\tOUT : %x", RDATA_O);
                
                // ROM with the pattern 3F .. 30
                expected = 16'hFF - (cycle_count % 256);
                
                // increament address every cycle
                RADDR_I = RADDR_I + 1;
                
                if (expected !== RDATA_O) begin
                    $display("\tMISMATCH: Expected %x got OUT : %x", expected, RDATA_O);
                    $display("TEST : FAIL");
                    $finish();
                end
                
                if (cycle_count == 320) begin
                    $display("TEST : PASS");
                    $finish;
                end
            end
            
            cycle_count = cycle_count + 1;
        end
    end
    
endmodule

`default_nettype wire
