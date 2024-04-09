
//*******************************************************************************
//*        Software       : TSMC MEMORY COMPILER 2006.09.01.d.140a
//*        Technology     : 65 nm CMOS LOGIC Low Power LowK Cu 1P9M 1.2
//*                         Mix-vt logic, High-vt SRAM
//*        Memory Type    : TSMC 65nm low power SP SRAM With Redundancy
//*        Library Name   : ts1n65lpa1024x4m4r (user specify : TS1N65LPA1024X4M4)
//*        Generated Time : 2024/04/08, 13:49:29
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


module TS1N65LPA1024X4M4 (
			CLK, CEB, WEB,
			A, D, BWEB,	

 			TSEL,
			Q);

			
parameter numWord = 1024;
parameter numRow = 256;
parameter numCM = 4;
parameter numBit = 4;
parameter numWordAddr = 10;
parameter numRowAddr = 8;
parameter numCMAddr = 2;
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

S1400W4_RAM_1bit sram_IO0 (CLK, iCEB, iWEB, iBWEB[0], iA, iD[0], Q_tmp[0]);
S1400W4_RAM_1bit sram_IO1 (CLK, iCEB, iWEB, iBWEB[1], iA, iD[1], Q_tmp[1]);
S1400W4_RAM_1bit sram_IO2 (CLK, iCEB, iWEB, iBWEB[2], iA, iD[2], Q_tmp[2]);
S1400W4_RAM_1bit sram_IO3 (CLK, iCEB, iWEB, iBWEB[3], iA, iD[3], Q_tmp[3]);



assign Q = Q_tmp;

endmodule



// 1 bit SRAM 
module S1400W4_RAM_1bit (CLK_i, CEB_i, WEB_i, BWEB_i, A_i, D_i, Q_i);

parameter numWord = 1024;
parameter numRow = 256;
parameter numCM = 4;
parameter numBit = 4;
parameter numWordAddr = 10;
parameter numRowAddr = 8;
parameter numCMAddr = 2;
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
