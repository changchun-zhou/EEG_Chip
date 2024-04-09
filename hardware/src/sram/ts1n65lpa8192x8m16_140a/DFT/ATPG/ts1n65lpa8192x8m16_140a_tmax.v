
//*******************************************************************************
//*        Software       : TSMC MEMORY COMPILER 2006.09.01.d.140a
//*        Technology     : 65 nm CMOS LOGIC Low Power LowK Cu 1P9M 1.2
//*                         Mix-vt logic, High-vt SRAM
//*        Memory Type    : TSMC 65nm low power SP SRAM With Redundancy
//*        Library Name   : ts1n65lpa8192x8m16r (user specify : TS1N65LPA8192X8M16)
//*        Generated Time : 2024/04/08, 13:51:24
//*******************************************************************************
//*******************************************************************************
//*
//*STATEMENT OF USE
//*
//*This information contains confidential and proprietary information of TSMC.
//*No part of this information may be reproduced, transmitted, transcribed,
//*stored in a retrieval system, or translated into any human or computer
//*language, in any form or by any means, electronic, mechanical, magnetic,
//*optical, chemical, manual, or otherwise, without the prior written permission
//*of TSMC. This information was prepared for informational purpose and is for
//*use by TSMC's customers only. TSMC reserves the right to make changes in the
//*information at any time and without notice.
//*
//*******************************************************************************
//*
//* SPECIAL NOTE FOR TOOL LIMITATION
//*
//*   1. When do the backannotation, the OEB must keep as low
//*   2. Due to tool bug of NC-Verilog 5.4, the 'tCD'(access time) can not back annotated correctly in SDF3.0.
//*      The back annotation is working correctly in NC-Verilog 5.4(or older version) with SDF2.1.
//*      The back annotation is working correctly in VCS 7.1.1(or older version) with SDF3.0 or older version.
//*******************************************************************************


`timescale 1ns/1ps


module TS1N65LPA8192X8M16 (
			CLK, CEB, WEB,
			A, D, BWEB,	

 			TSEL,
			Q);

			
parameter numWord = 8192;
parameter numRow = 512;
parameter numCM = 16;
parameter numBit = 8;
parameter numWordAddr = 13;
parameter numRowAddr = 9;
parameter numCMAddr = 4;
parameter numSRSize = 10;


//=== IO Ports ===//

// Normal Mode Input
input CLK;
input CEB;
input WEB;
input [numWordAddr-1:0] A;
input [numBit-1:0] D;
input [numBit-1:0] BWEB;


// BIST Mode Input


// Data Output
output [numBit-1:0] Q;


// Test Mode		
input [1:0] TSEL;


//=== Data Structure ===//
//reg [numBit-1:0] MEMORY [numWord-1:0]  ;
reg [numBit-1:0] Q;
wire [numBit-1:0] Q_tmp;

reg [numBit-1:0] WB;
wire iCEB = CEB;
wire iWEB = WEB;
wire [numWordAddr-1:0] iA = A;
wire [numBit-1:0] iD = D;
wire [numBit-1:0] iBWEB = BWEB;
integer i, j;


//=== Operation ===//

S12000Y8_RAM_1bit sram_IO0 (CLK, iCEB, iWEB, iBWEB[0], iA, iD[0], Q_tmp[0]);
S12000Y8_RAM_1bit sram_IO1 (CLK, iCEB, iWEB, iBWEB[1], iA, iD[1], Q_tmp[1]);
S12000Y8_RAM_1bit sram_IO2 (CLK, iCEB, iWEB, iBWEB[2], iA, iD[2], Q_tmp[2]);
S12000Y8_RAM_1bit sram_IO3 (CLK, iCEB, iWEB, iBWEB[3], iA, iD[3], Q_tmp[3]);
S12000Y8_RAM_1bit sram_IO4 (CLK, iCEB, iWEB, iBWEB[4], iA, iD[4], Q_tmp[4]);
S12000Y8_RAM_1bit sram_IO5 (CLK, iCEB, iWEB, iBWEB[5], iA, iD[5], Q_tmp[5]);
S12000Y8_RAM_1bit sram_IO6 (CLK, iCEB, iWEB, iBWEB[6], iA, iD[6], Q_tmp[6]);
S12000Y8_RAM_1bit sram_IO7 (CLK, iCEB, iWEB, iBWEB[7], iA, iD[7], Q_tmp[7]);



assign Q = Q_tmp;

endmodule



// 1 bit SRAM 
module S12000Y8_RAM_1bit (CLK_i, CEB_i, WEB_i, BWEB_i, A_i, D_i, Q_i);

parameter numWord = 8192;
parameter numRow = 512;
parameter numCM = 16;
parameter numBit = 8;
parameter numWordAddr = 13;
parameter numRowAddr = 9;
parameter numCMAddr = 4;
parameter numSRSize = 10;

input CLK_i;
input CEB_i;
input WEB_i;
input [0:0] BWEB_i;
input [numWordAddr-1:0] A_i;
input [0:0] D_i;

output [0:0] Q_i;

reg [0:0]Q_i;
reg [0:0] MEMORY [numWord-1:0];


event WRITE_OP;

// Write Mode
and u_aw1_0 (WB, !WEB_i, !CEB_i, !BWEB_i);

always @ (posedge CLK_i)
  if (WB) begin
    MEMORY[A_i] = D_i;
    #0; -> WRITE_OP;
  end

// READ Mode
and u_rw1_0 (RB, WEB_i, !CEB_i);

always @ (posedge CLK_i)
  if (RB) begin
     Q_i = MEMORY[A_i];
  end


endmodule
