/*----------------------------------------------------------------------------
* TDPRAM_DUALCLK.sv
*
* True Dual-Port RAM (Dual Clock)
*
* Version: 0.01
* Author : AUDIY
* Date   : 2025/01/03
*
* Port
*   Input
*       CLKA_I : Clock Input for Port A
*       WENA_I : Write Enable Input for Port A
*       ADDRA_I: Address Input for Port A
*       DINA_I : Data Input for Port A
*       CLKB_I : Clock Input for Port B
*       WENB_I : Write Enable Input for Port B
*       ADDRB_I: Address Input for Port B
*       DINB_I : Data Input for Port B
*
*   Output
*       DOUTA_O: Data Output for Port A
*       DOUTB_O: Data Output for Port B
*
*   Parameter
*       DATA_WIDTH   : Data bit width
*       ADDR_WIDTH   : RAM Address width
*       WRITE_MODE_A : Read-during-Write Mode for Port A
*       WRITE_MODE_B : Read-during-Write Mode for Port B
*       OUTPUT_REG_A : Output Register Enable for Port A
*       OUTPUT_REG_B : Output Register Enable for Port B
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
module TDPRAM_DUALCLK 
    import TDPRAM_DUALCLK_PKG::*;
#(
    /* Parameter desinition */
    parameter int        unsigned DATA_WIDTH = 8,
    parameter int        unsigned DEPTH      = 128,
    parameter int        unsigned ADDR_WIDTH = (DEPTH >= 2) ? $clog2(DEPTH) : 1,
    parameter WRITE_MODE          WRITE_MODE_A = READ_FIRST,
    parameter WRITE_MODE          WRITE_MODE_B = READ_FIRST,
    parameter OUTPUT_REG          OUTPUT_REG_A = FALSE,
    parameter OUTPUT_REG          OUTPUT_REG_B = FALSE,
    parameter string              RAM_INIT_FILE = "RAMINIT.hex"
) (
    /* Port Definition */
    // Side A
    input  var                             CLKA_I ,
    input  var                             WENA_I ,
    input  var unsigned [ADDR_WIDTH - 1:0] ADDRA_I,
    input  var          [DATA_WIDTH - 1:0] DINA_I ,
    output var          [DATA_WIDTH - 1:0] DOUTA_O,

    // Side B
    input  var                             CLKB_I ,
    input  var                             WENB_I ,
    input  var unsigned [ADDR_WIDTH - 1:0] ADDRB_I,
    input  var          [DATA_WIDTH - 1:0] DINB_I ,
    output var          [DATA_WIDTH - 1:0] DOUTB_O
);

    logic [DATA_WIDTH - 1:0] RAM [DEPTH - 1:0];

    logic [DATA_WIDTH - 1:0] R_DOUTA_1P;
    logic [DATA_WIDTH - 1:0] R_DOUTA_2P;

    logic [DATA_WIDTH - 1:0] R_DOUTB_1P;
    logic [DATA_WIDTH - 1:0] R_DOUTB_2P;

    /* RAM Initialization */
    initial begin
        // If Initialization File is NOT defined, the initial values depend on the vendor.
        if (RAM_INIT_FILE != "") begin
            $readmemh(RAM_INIT_FILE, RAM);
        end
    end

    /* Update RAM data */
    // From side A
    always @( posedge CLKA_I ) begin
        if ( WENA_I ) begin
            RAM[ADDRA_I] <= DINA_I;
        end
    end

    // From side B
    always @( posedge CLKB_I ) begin
        if ( WENB_I ) begin
            RAM[ADDRB_I] <= DINB_I;
        end
    end

    /* RAM Output */
    // Side A
    generate
        if (WRITE_MODE_A == READ_FIRST) begin: l_RFA
            // READ_FIRST mode: Output the stored data.
            always_ff @( posedge CLKA_I ) begin
                R_DOUTA_1P <= RAM[ADDRA_I];
            end
        end else if (WRITE_MODE_A == WRITE_FIRST) begin: l_WFA
            // WRITE_FIRST mode: Output the written data immediately.
            always_ff @( posedge CLKA_I ) begin
                R_DOUTA_1P <= DINA_I;
            end
        end else begin: l_NCA
            // NO_CHANGE mode: mask the output by current output data while WEN
            // is enabled.
            always_ff @( posedge CLKA_I ) begin
                if ( !WENA_I ) begin
                    R_DOUTA_1P <= RAM[ADDRA_I];
                end
            end
        end
    endgenerate

    // Side B
    generate
        if (WRITE_MODE_B == READ_FIRST) begin: l_RFB
            // READ_FIRST mode: Output the stored data.
            always_ff @( posedge CLKB_I ) begin
                R_DOUTB_1P <= RAM[ADDRB_I];
            end
        end else if (WRITE_MODE_B == WRITE_FIRST) begin: l_WFB
            // WRITE_FIRST mode: Output the written data immediately.
            always_ff @( posedge CLKB_I ) begin
                R_DOUTB_1P <= DINB_I;
            end
        end else begin: l_NCB
            // NO_CHANGE mode: mask the output by current output data while WEN
            // is enabled.
            always_ff @( posedge CLKB_I ) begin
                if ( !WENB_I ) begin
                    R_DOUTB_1P <= RAM[ADDRB_I];
                end
            end
        end
    endgenerate

    /* Output Register */
    // Side A
    generate
        if ( OUTPUT_REG_A == TRUE ) begin: l_TRUE_OUTREGA
            // TRUE: Insert the 1-stage register
            always_ff @( posedge CLKA_I ) begin
                R_DOUTA_2P <= R_DOUTA_1P;
            end
            assign DOUTA_O = R_DOUTA_2P;
        end else begin: l_FALSE_OUTREGA
            // FALSE: Output the RAM Data without register.
            assign DOUTA_O = R_DOUTA_1P;
        end
    endgenerate

    // Side B
    generate
        if ( OUTPUT_REG_B == TRUE ) begin: l_TRUE_OUTREGB
            always_ff @( posedge CLKB_I ) begin
            // TRUE: Insert the 1-stage register
                R_DOUTB_2P <= R_DOUTB_1P;
            end
            assign DOUTB_O = R_DOUTB_2P;
        end else begin: l_FALSE_OUTREGB
        // FALSE: Output the RAM Data without register.
            assign DOUTB_O = R_DOUTB_1P;
        end
    endgenerate

endmodule
`default_nettype wire
