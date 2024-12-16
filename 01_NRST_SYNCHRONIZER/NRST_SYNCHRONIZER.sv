/*-----------------------------------------------------------------------------
* NRST_SYNCHRONIZER.sv
*
* Asynchronous Reset (Active LOW) Synchronizer
*
* Version: 1.01
* Author : AUDIY
* Date   : 2024/12/16
* 
* Port
*   Input
*       CLK_I  : Data Clock Input
*       NRST_I : Asynchronous Reset Input (Active LOW)
*
*   Output
*       NRST_O : Reset Output (Synchronized when it negated.)
*
* Parameters
*   STAGES: Synchronization Stage Length (Default: 2)
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

module NRST_SYNCHRONIZER #(
    parameter int unsigned STAGES = 2
) (
    input  var   CLK_I ,
    input  var   NRST_I,
    output logic NRST_O
);

    logic unsigned [STAGES - 1:0] NRST_SYNC;

    always_ff @( posedge CLK_I or negedge NRST_I ) begin: blk_assert_rst
        if ( !NRST_I ) begin
            /* When NRST_I is asserted, assert reset immediately */
            NRST_SYNC <= '0;
        end else begin: blk_negate_reset
            /* Negate reset synchronized with CLK_I */
            NRST_SYNC <= {NRST_SYNC[STAGES - 2:0], 1'b1};
        end
    end

    assign NRST_O = NRST_SYNC[STAGES - 1];

endmodule
