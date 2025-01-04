/*----------------------------------------------------------------------------
* SDPRAM_SINGLECLK.sv
*
* Simple Dual-Port RAM (Single Clock)
*
* Version: 0.01
* Author : AUDIY
* Date   : 2025/01/04
*
* Port
*   Input
*       CLK_I        : RAM Write/Read Clock Input
*       WADDR_I      : Write Address Input
*       WENABLE_I    : Write Enable Input
*       WDATA_I      : Stored Data Input
*       RADDR_I      : Read Address Input
*       RENABLE_I    : Read Enable Input
*
*   Output
*       RDATA_O      : Stored Data Output
*
*   Parameter
*       DATA_WIDTH   : Coefficient DATA Width
*       DEPTH        : RAM Queue Length
*       OUTPUT_REG   : Output Register Enable
*       RAM_INIT_FILE: RAM Initialization File
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

module SDPRAM_SINGLECLK #(
    /* Parameter Definitions */
    parameter int unsigned DATA_WIDTH    = 8,
    parameter int unsigned DEPTH         = 128,
    parameter int unsigned ADDR_WIDTH    = (DEPTH >= 2) ? $clog2(DEPTH) : 1,
    parameter bit          OUTPUT_REG    = 1'b1, // 1: True, 0: False
    parameter string       RAM_INIT_FILE = "RAMINIT.hex"
) (
    /* Port Definitions */
    input  var                             CLK_I  ,
    input  var unsigned [ADDR_WIDTH - 1:0] WADDR_I,
    input  var                             WEN_I  ,
    input  var          [DATA_WIDTH - 1:0] WDATA_I,
    input  var unsigned [ADDR_WIDTH - 1:0] RADDR_I,
    input  var                             REN_I  ,
    output var          [DATA_WIDTH - 1:0] RDATA_O
);
    /* Internal logic definitions */
    logic [DATA_WIDTH - 1:0] RAM[DEPTH - 1:0];
    logic [DATA_WIDTH - 1:0] RDATA_REG_1P;
    logic [DATA_WIDTH - 1:0] RDATA_REG_2P;

    /* Memory Initialization */
    initial begin
        if ( RAM_INIT_FILE != "" ) begin
            $readmemh(RAM_INIT_FILE, RAM);
        end
    end

    /* Store the Data */
    always @(posedge CLK_I) begin
        if ( WEN_I ) begin
            RAM[WADDR_I] <= WDATA_I;
        end
    end

    /* Output the Data */
    always_ff @( posedge CLK_I ) begin
        if ( REN_I ) begin
            RDATA_REG_1P <= RAM[RADDR_I];
        end
    end

    /* Additional Register */
    generate
        if ( OUTPUT_REG ) begin: l_gen_reg2p
            always_ff @( posedge CLK_I ) begin
                RDATA_REG_2P <= RDATA_REG_1P;
            end

            assign RDATA_O = RDATA_REG_2P;
        end else begin: l_gen_reg1p
            assign RDATA_O = RDATA_REG_1P;
        end
    endgenerate

endmodule

`default_nettype wire
