/*-----------------------------------------------------------------------------
* NRST_SYNCHRONIZER_tb.sv
*
* Testbench for NRST_SYNCHRONIZER.sv
*
* Version: 1.01
* Author : AUDIY
* Date   : 2024/12/21
*
* License under CERN-OHL-P v2
--------------------------------------------------------------------------------
| Copyright AUDIY 2024.                                                        |
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

module NRST_SYNCHRONIZER_tb ();

    timeunit 1ns/1ps;
    localparam int unsigned STAGES = 3;

    logic CLK_I  = 1'b0;
    logic NRST_I = 1'b0;
    logic NRST_O;

    NRST_SYNCHRONIZER #(
        .STAGES(STAGES)
    ) u0 (
        .CLK_I (CLK_I ),
        .NRST_I(NRST_I),
        .NRST_O(NRST_O)
    );

    initial begin
        $dumpfile("NRST_SYNCHRONIZER.vcd");
        $dumpvars(0, NRST_SYNCHRONIZER_tb);

        #1  NRST_I = 1'b1;
        #23 NRST_I = 1'b0;
        #14 NRST_I = 1'b1;

        #64 $finish();
    end

    initial begin
        forever begin
            #2 CLK_I = ~CLK_I;
        end
    end

endmodule
