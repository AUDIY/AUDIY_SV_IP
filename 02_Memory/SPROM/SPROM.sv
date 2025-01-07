/*----------------------------------------------------------------------------
* SPROM.sv
*
* Single-Port ROM
*
* Version: 0.01
* Author : AUDIY
* Date   : 2025/01/08
*
* Port
*   Input
*       CLK_I        : RAM Write/Read Clock Input
*       RADDR_I      : Read Address Input
*
*   Output
*       RDATA_O      : Stored Data Output
*
*   Parameter
*       DATA_WIDTH   : Stored DATA Width
*       DEPTH        : ROM Address Depth
*       OUTPUT_REG   : Output Register Enable
*       ROM_INIT_FILE: ROM Initialization File name
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

module SPROM #(
    /* Parameter Definitions */
    parameter int    unsigned DATA_WIDTH    = 16,
    parameter int    unsigned DEPTH         = 256,
    parameter int    unsigned ADDR_WIDTH    = (DEPTH >= 2) ? $clog2(DEPTH) : 1,
    parameter bit             OUTPUT_REG    = 1'b0,
    parameter string          ROM_INIT_FILE = "initrom.hex"
) (
    /* Port Definitions */
    input  var                             CLK_I,
    input  var unsigned [ADDR_WIDTH - 1:0] RADDR_I,
    output var          [DATA_WIDTH - 1:0] RDATA_O
);

    /* Internal logic */
    logic [DATA_WIDTH - 1:0] RDATAO_REG_1P;
    logic [DATA_WIDTH - 1:0] RDATAO_REG_2P;
    logic [DATA_WIDTH - 1:0] ROM[DEPTH - 1:0];

    /* ROM Initialization */
    initial begin
        $readmemh(ROM_INIT_FILE, ROM);
    end

    /* Read Data */
    always_ff @(posedge CLK_I) begin
        RDATAO_REG_1P <= ROM[RADDR_I];
    end

    generate
        if ( OUTPUT_REG == 1'b1 ) begin: l_OUTREG_TRUE
            /* Additional Output Register */
            always_ff @( posedge CLK_I ) begin
                RDATAO_REG_2P <= RDATAO_REG_1P;
            end

            assign RDATA_O = RDATAO_REG_2P;
        end else begin: l_OUTREG_FALSE
            assign RDATA_O = RDATAO_REG_1P;
        end
    endgenerate
    
endmodule

`default_nettype wire
