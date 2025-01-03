/*----------------------------------------------------------------------------
* TDPRAM_DUALCLK_PKG.sv
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

package TDPRAM_DUALCLK_PKG;
    typedef enum int {
        NO_CHANGE,  // 0
        READ_FIRST, // 1
        WRITE_FIRST // 2
    } WRITE_MODE;

    typedef enum bit {
        FALSE, // 0
        TRUE   // 1
    } OUTPUT_REG;
endpackage

`default_nettype wire
