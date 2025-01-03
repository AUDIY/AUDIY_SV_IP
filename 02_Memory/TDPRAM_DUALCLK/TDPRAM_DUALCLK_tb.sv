/*----------------------------------------------------------------------------
* TDPRAM_DUALCLK_tb.sv
*
* Testbench for TDPRAM_DUALCLK.sv
*
* Version: 0.01
* Author : AUDIY
* Date   : 2025/01/03
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

module TDPRAM_DUALCLK_tb;

    timeunit 1ns/1ps;
    import TDPRAM_DUALCLK_PKG::*;

    localparam int        unsigned DATA_WIDTH   = 8;
    localparam int        unsigned DEPTH        = 512;
    localparam WRITE_MODE          WRITE_MODE_A = READ_FIRST;
    localparam WRITE_MODE          WRITE_MODE_B = READ_FIRST;
    localparam OUTPUT_REG          OUTPUT_REG_A = FALSE;
    localparam OUTPUT_REG          OUTPUT_REG_B = FALSE;

    localparam int unsigned AD_WIDTH = (DEPTH >= 2) ? $clog2(DEPTH) : 1;
    localparam int MAX_DATA = (1 << DATA_WIDTH) - 1;

    logic                             CLKA_I = 1'b0;
    logic                             WENA_I;
    logic unsigned [AD_WIDTH - 1:0]   ADDRA_I;
    logic          [DATA_WIDTH - 1:0] DINA_I;
    logic          [DATA_WIDTH - 1:0] DOUTA_O;

    logic                             CLKB_I = 1'b0;
    logic                             WENB_I;
    logic unsigned [AD_WIDTH - 1:0]   ADDRB_I;
    logic          [DATA_WIDTH - 1:0] DINB_I;
    logic          [DATA_WIDTH - 1:0] DOUTB_O;

    logic                      CLOCK = 1'b0;
    integer                    CNT1;
    integer                    CNT2;
    logic                      RESET = 1'b0;
    logic   [DATA_WIDTH - 1:0] EXP1;
    logic   [DATA_WIDTH - 1:0] EXP2;


    TDPRAM_DUALCLK #(
        .DATA_WIDTH  (DATA_WIDTH  ),
        .DEPTH       (DEPTH       ),
        .WRITE_MODE_A(WRITE_MODE_A),
        .WRITE_MODE_B(WRITE_MODE_B),
        .OUTPUT_REG_A(OUTPUT_REG_A),
        .OUTPUT_REG_B(OUTPUT_REG_B)
    ) u0 (
        .CLKA_I (CLKA_I ),
        .WENA_I (WENA_I ),
        .ADDRA_I(ADDRA_I),
        .DINA_I (DINA_I ),
        .DOUTA_O(DOUTA_O),
        .CLKB_I (CLKB_I ),
        .WENB_I (WENB_I ),
        .ADDRB_I(ADDRB_I),
        .DINB_I (DINB_I ),
        .DOUTB_O(DOUTB_O)
    );

    initial begin
        $dumpfile("TDPRAM_DUALCLK.vcd");
        $dumpvars(0, TDPRAM_DUALCLK_tb);

        CNT1 = -2;
        CNT2 = -2;

        #1  RESET = 1'b1;
        #1  RESET = 1'b0;
        #10 RESET = 1'b1;
    end

    initial begin
        forever #75 begin
            CLOCK  = ~CLOCK ;
            CLKA_I = ~CLKA_I;
            CLKB_I = ~CLKB_I;
        end
    end

    always @( posedge CLOCK ) begin
        CNT1 = CNT1 + 1;
        CNT2 = CNT2 + 1;

        // Allow 3 complete traversals of the memory address space
        if ((CNT1 == 761) && (CNT2 == 761)) begin
            $display("TEST : PASS");
            $finish;
        end
    end

    always_ff @( posedge CLKA_I or negedge RESET ) begin
        if ( !RESET ) begin
            WENA_I <= 1'b0;
            DINA_I <= 15;
            ADDRA_I <= '0;
        end else begin
            if ( CNT1 == -1 ) begin
                WENA_I <= 1'b1;
            end else if ( CNT1 >= 0 ) begin
                $display("%t === === === Write Cycle Port A:%d === === ===", $time, CNT1);
                $display("WDATA : %d\tWADDR : %d\tWE : %d", DINA_I, ADDRA_I, WENA_I);
                
                // Increment data and address
                DINA_I  <= DINA_I  + 2;
                ADDRA_I <= ADDRA_I + 1;
            end
        end
    end

    always_ff @( posedge CLKB_I or negedge RESET ) begin
        if ( !RESET ) begin
            WENB_I <= 1'b0;
            DINB_I <= 15;
            ADDRB_I <= '0;
        end else begin
            if ( CNT2 == -1 ) begin
                WENB_I <= 1'b1;
            end else if ( CNT2 >= 0 ) begin
                $display("%t === === === Write Cycle Port A:%d === === ===", $time, CNT2);
                $display("WDATA : %d\tWADDR : %d\tWE : %d", DINB_I, ADDRB_I, WENB_I);
                
                // Increment data and address
                DINB_I  <= DINB_I  + 2;
                ADDRB_I <= ADDRB_I + 1;
            end
        end
    end

    always_ff @(negedge CLKA_I or negedge RESET ) begin
        if ( !RESET ) begin
            EXP1 <= '0;
        end else begin
            // let some cycles go before starting the writing and reading
            if (CNT1 >= 0) begin
                $display("%t === === === Read Cycle Port A: %d === === ===", $time, CNT1);
                $display("RADDR : %d\tRDATA : %d", ADDRA_I, DOUTA_O);
                
                if (CNT1 < 512) begin
                    EXP1 <= MAX_DATA - CNT1;
                end
                
                if (CNT1 >= 512) begin
                    EXP1 <= 15 + ((CNT1 - 512) * 2);
                end
                
                if (EXP1 != DOUTA_O) begin
                    $display("\tMISMATCH: Expected %d got RDATA Port A : %d", EXP1, DOUTA_O);
                    $display("TEST : FAIL");
                    $finish();
                end
            end
        end
    end

    always_ff @(negedge CLKB_I or negedge RESET ) begin
        if ( !RESET ) begin
            EXP2 <= '0;
        end else begin
            // let some cycles go before starting the writing and reading
            if (CNT2 >= 0) begin
                $display("%t === === === Read Cycle Port A: %d === === ===", $time, CNT2);
                $display("RADDR : %d\tRDATA : %d", ADDRB_I, DOUTB_O);
                
                if (CNT2 < 512) begin
                    EXP2 <= MAX_DATA - CNT2;
                end
                
                if (CNT2 >= 512) begin
                    EXP2 <= 15 + ((CNT2 - 512) * 2);
                end
                
                if (EXP2 != DOUTB_O) begin
                    $display("\tMISMATCH: Expected %d got RDATA Port A : %d", EXP2, DOUTB_O);
                    $display("TEST : FAIL");
                    $finish();
                end
            end
        end
    end

endmodule

`default_nettype wire
