
//*******************************************************************************
//*        Software       : TSMC MEMORY COMPILER 2006.09.01.d.140a
//*        Technology     : 65 nm CMOS LOGIC Low Power LowK Cu 1P9M 1.2
//*                         Mix-vt logic, High-vt SRAM
//*        Memory Type    : TSMC 65nm low power SP SRAM Without Redundancy
//*        Library Name   : ts1n65lpa4096x8m8 ( user specify: TS1N65LPA4096X8M8)
//*        Library Version: 140a
//*        Generated Time : 2024/04/08, 13:50:39
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
//
//*     CLK         (I) - Clock
//*  	CEB 	    (I) - Chip enable
//*  	WEB 	    (I) - Write enable
//*  	A[i]	    (I) - Address input
//*  	D[j]	    (I) - Data input
//*  	BWEB[j]     (I) - Bit-write enable
//*  	Q[j]	    (O) - Output data
//*  	TSEL[1:0]   (I) - Read margin selection (default is 01)
//*






`timescale 1ns/1ps
`celldefine
`ifdef UNIT_DELAY
`define SRAM_DELAY 0.001
`else
`endif

module TS1N65LPA4096X8M8 ( 
			CLK, CEB, WEB,

			A, D, BWEB,

			Q,

			TSEL
	         		    );

// Define Parameter
parameter numWord = 4096;
parameter numRow = 512;
parameter numCM = 8;
parameter numBit = 8;
parameter numWordAddr = 12;
parameter numRowAddr = 9;
parameter numCMAddr = 3;

`ifdef UNIT_DELAY
`else
parameter Thold = 3.135;
`endif	//end `ifdef UNIT_DELAY

parameter preloadFile = "sram.preload.data";
parameter numStuckAt = 20;


//=== IO Ports ===//

// Normal Mode Input
input CLK;
input CEB;
input WEB;
input [numWordAddr-1:0] A;
input [numBit-1:0] D;
input [numBit-1:0] BWEB;

// Data Output
output [numBit-1:0] Q;

// Test Mode
input [1:0] TSEL;


//=== Internal Signals ===//

// Normal Mode Input
wire CLK_i;
wire CEB_i;
wire WEB_i;
wire [numWordAddr-1:0] A_i;
wire [numBit-1:0] D_i;
wire [numBit-1:0] BWEB_i;

// Data Output
wire [numBit-1:0] Q_i;

// Test Mode
wire [1:0] TSEL_i;


//=== IO Buffers ===//

// Normal Mode Input
buf (CLK_i, CLK);
buf (CEB_i, CEB);
buf (WEB_i, WEB);

buf (A_i[0], A[0]);
buf (A_i[1], A[1]);
buf (A_i[2], A[2]);
buf (A_i[3], A[3]);
buf (A_i[4], A[4]);
buf (A_i[5], A[5]);
buf (A_i[6], A[6]);
buf (A_i[7], A[7]);
buf (A_i[8], A[8]);
buf (A_i[9], A[9]);
buf (A_i[10], A[10]);
buf (A_i[11], A[11]);

buf (D_i[0], D[0]);
buf (D_i[1], D[1]);
buf (D_i[2], D[2]);
buf (D_i[3], D[3]);
buf (D_i[4], D[4]);
buf (D_i[5], D[5]);
buf (D_i[6], D[6]);
buf (D_i[7], D[7]);

buf (BWEB_i[0], BWEB[0]);
buf (BWEB_i[1], BWEB[1]);
buf (BWEB_i[2], BWEB[2]);
buf (BWEB_i[3], BWEB[3]);
buf (BWEB_i[4], BWEB[4]);
buf (BWEB_i[5], BWEB[5]);
buf (BWEB_i[6], BWEB[6]);
buf (BWEB_i[7], BWEB[7]);

// Data Output
nmos (Q[0], Q_i[0], 1'b1);
nmos (Q[1], Q_i[1], 1'b1);
nmos (Q[2], Q_i[2], 1'b1);
nmos (Q[3], Q_i[3], 1'b1);
nmos (Q[4], Q_i[4], 1'b1);
nmos (Q[5], Q_i[5], 1'b1);
nmos (Q[6], Q_i[6], 1'b1);
nmos (Q[7], Q_i[7], 1'b1);

// Test Mode
buf (TSEL_i[0], TSEL[0]);
buf (TSEL_i[1], TSEL[1]);

//=== Data Structure ===//
reg [numBit-1:0] MEMORY[numRow-1:0][numCM-1:0];
reg [numBit-1:0] Q_d, Q_d1;
reg [numBit-1:0] PRELOAD[0:numWord-1];

reg [numBit-1:0] DIN_tmp, ERR_tmp;
reg [numWordAddr-1:0] stuckAt0Addr [numStuckAt:0];
reg [numWordAddr-1:0] stuckAt1Addr [numStuckAt:0];
reg [numBit-1:0] stuckAt0Bit [numStuckAt:0];
reg [numBit-1:0] stuckAt1Bit [numStuckAt:0];

integer i, j;

reg read_flag, write_flag, idle_flag;

`ifdef UNIT_DELAY
`else
reg notify_clk;
reg notify_bist;
reg notify_ceb;
reg notify_web;
reg notify_addr;
reg notify_din;
reg notify_bweb;
`endif	//end `ifdef UNIT_DELAY


wire [numWordAddr-numCMAddr-1:0] iRowAddr = A_i[numWordAddr-1:numCMAddr];
wire [numCMAddr-1:0] iColAddr = A_i[numCMAddr-1:0];


`ifdef UNIT_DELAY
`else
wire check_read = read_flag;
wire check_write = write_flag;
wire check_noidle = ~idle_flag;
`endif	//end `ifdef UNIT_DELAY


assign Q_i = Q_d;


`ifdef UNIT_DELAY
`else
specify

    specparam tCYC = 3.484;
    specparam tCKH = 0.416;
    specparam tCKL = 0.908;
    specparam tCS  = 0.649;
    specparam tCH  = 0.000;
    specparam tWS  = 0.656;
    specparam tWH  = 0.000;
    specparam tAS  = 0.863;
    specparam tAH  = 0.000;
    specparam tDS  = 0.331;
    specparam tDH  = 0.000;
    specparam tBWS = 0.437;
    specparam tBWH = 0.000;
    specparam tCD  = 3.300;
    specparam tHOLD  = 3.135;

    (posedge CLK => (Q[0] : 1'bx)) = (tCD, tCD, tHOLD, tCD, tHOLD, tCD);
    (posedge CLK => (Q[1] : 1'bx)) = (tCD, tCD, tHOLD, tCD, tHOLD, tCD);
    (posedge CLK => (Q[2] : 1'bx)) = (tCD, tCD, tHOLD, tCD, tHOLD, tCD);
    (posedge CLK => (Q[3] : 1'bx)) = (tCD, tCD, tHOLD, tCD, tHOLD, tCD);
    (posedge CLK => (Q[4] : 1'bx)) = (tCD, tCD, tHOLD, tCD, tHOLD, tCD);
    (posedge CLK => (Q[5] : 1'bx)) = (tCD, tCD, tHOLD, tCD, tHOLD, tCD);
    (posedge CLK => (Q[6] : 1'bx)) = (tCD, tCD, tHOLD, tCD, tHOLD, tCD);
    (posedge CLK => (Q[7] : 1'bx)) = (tCD, tCD, tHOLD, tCD, tHOLD, tCD);

// normal mode timing check 

    $period(posedge CLK &&& check_noidle, tCYC, notify_clk);
    $width(posedge CLK &&& check_noidle, tCKH, 0, notify_clk);
    $width(negedge CLK &&& check_noidle, tCKL, 0, notify_clk);

    $setup(negedge CEB, posedge CLK, tCS, notify_ceb);
    $setup(posedge CEB, posedge CLK, tCS, notify_ceb);
    $hold(posedge CLK, negedge CEB, tCH, notify_ceb);
    $hold(posedge CLK, posedge CEB, tCH, notify_ceb);

    $setup(negedge WEB, posedge CLK &&& check_noidle, tWS, notify_web);
    $setup(posedge WEB, posedge CLK &&& check_noidle, tWS, notify_web);
    $hold(posedge CLK &&& check_noidle, negedge WEB, tWH, notify_web);
    $hold(posedge CLK &&& check_noidle, posedge WEB, tWH, notify_web);

    $setup(negedge A[0], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(negedge A[1], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(negedge A[2], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(negedge A[3], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(negedge A[4], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(negedge A[5], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(negedge A[6], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(negedge A[7], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(negedge A[8], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(negedge A[9], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(negedge A[10], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(negedge A[11], posedge CLK &&& check_noidle, tAS, notify_addr);

    $setup(posedge A[0], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(posedge A[1], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(posedge A[2], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(posedge A[3], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(posedge A[4], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(posedge A[5], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(posedge A[6], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(posedge A[7], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(posedge A[8], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(posedge A[9], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(posedge A[10], posedge CLK &&& check_noidle, tAS, notify_addr);
    $setup(posedge A[11], posedge CLK &&& check_noidle, tAS, notify_addr);

    $hold(posedge CLK &&& check_noidle, negedge A[0], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, negedge A[1], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, negedge A[2], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, negedge A[3], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, negedge A[4], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, negedge A[5], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, negedge A[6], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, negedge A[7], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, negedge A[8], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, negedge A[9], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, negedge A[10], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, negedge A[11], tAH, notify_addr);

    $hold(posedge CLK &&& check_noidle, posedge A[0], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, posedge A[1], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, posedge A[2], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, posedge A[3], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, posedge A[4], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, posedge A[5], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, posedge A[6], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, posedge A[7], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, posedge A[8], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, posedge A[9], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, posedge A[10], tAH, notify_addr);
    $hold(posedge CLK &&& check_noidle, posedge A[11], tAH, notify_addr);


    $setup(negedge D[0], posedge CLK &&& check_write, tDS, notify_din);
    $setup(negedge D[1], posedge CLK &&& check_write, tDS, notify_din);
    $setup(negedge D[2], posedge CLK &&& check_write, tDS, notify_din);
    $setup(negedge D[3], posedge CLK &&& check_write, tDS, notify_din);
    $setup(negedge D[4], posedge CLK &&& check_write, tDS, notify_din);
    $setup(negedge D[5], posedge CLK &&& check_write, tDS, notify_din);
    $setup(negedge D[6], posedge CLK &&& check_write, tDS, notify_din);
    $setup(negedge D[7], posedge CLK &&& check_write, tDS, notify_din);

    $setup(posedge D[0], posedge CLK &&& check_write, tDS, notify_din);
    $setup(posedge D[1], posedge CLK &&& check_write, tDS, notify_din);
    $setup(posedge D[2], posedge CLK &&& check_write, tDS, notify_din);
    $setup(posedge D[3], posedge CLK &&& check_write, tDS, notify_din);
    $setup(posedge D[4], posedge CLK &&& check_write, tDS, notify_din);
    $setup(posedge D[5], posedge CLK &&& check_write, tDS, notify_din);
    $setup(posedge D[6], posedge CLK &&& check_write, tDS, notify_din);
    $setup(posedge D[7], posedge CLK &&& check_write, tDS, notify_din);

    $hold(posedge CLK &&& check_write, negedge D[0], tDH, notify_din);
    $hold(posedge CLK &&& check_write, negedge D[1], tDH, notify_din);
    $hold(posedge CLK &&& check_write, negedge D[2], tDH, notify_din);
    $hold(posedge CLK &&& check_write, negedge D[3], tDH, notify_din);
    $hold(posedge CLK &&& check_write, negedge D[4], tDH, notify_din);
    $hold(posedge CLK &&& check_write, negedge D[5], tDH, notify_din);
    $hold(posedge CLK &&& check_write, negedge D[6], tDH, notify_din);
    $hold(posedge CLK &&& check_write, negedge D[7], tDH, notify_din);

    $hold(posedge CLK &&& check_write, posedge D[0], tDH, notify_din);
    $hold(posedge CLK &&& check_write, posedge D[1], tDH, notify_din);
    $hold(posedge CLK &&& check_write, posedge D[2], tDH, notify_din);
    $hold(posedge CLK &&& check_write, posedge D[3], tDH, notify_din);
    $hold(posedge CLK &&& check_write, posedge D[4], tDH, notify_din);
    $hold(posedge CLK &&& check_write, posedge D[5], tDH, notify_din);
    $hold(posedge CLK &&& check_write, posedge D[6], tDH, notify_din);
    $hold(posedge CLK &&& check_write, posedge D[7], tDH, notify_din);

    $setup(negedge BWEB[0], posedge CLK &&& check_write, tBWS, notify_bweb);
    $setup(negedge BWEB[1], posedge CLK &&& check_write, tBWS, notify_bweb);
    $setup(negedge BWEB[2], posedge CLK &&& check_write, tBWS, notify_bweb);
    $setup(negedge BWEB[3], posedge CLK &&& check_write, tBWS, notify_bweb);
    $setup(negedge BWEB[4], posedge CLK &&& check_write, tBWS, notify_bweb);
    $setup(negedge BWEB[5], posedge CLK &&& check_write, tBWS, notify_bweb);
    $setup(negedge BWEB[6], posedge CLK &&& check_write, tBWS, notify_bweb);
    $setup(negedge BWEB[7], posedge CLK &&& check_write, tBWS, notify_bweb);

    $setup(posedge BWEB[0], posedge CLK &&& check_write, tBWS, notify_bweb);
    $setup(posedge BWEB[1], posedge CLK &&& check_write, tBWS, notify_bweb);
    $setup(posedge BWEB[2], posedge CLK &&& check_write, tBWS, notify_bweb);
    $setup(posedge BWEB[3], posedge CLK &&& check_write, tBWS, notify_bweb);
    $setup(posedge BWEB[4], posedge CLK &&& check_write, tBWS, notify_bweb);
    $setup(posedge BWEB[5], posedge CLK &&& check_write, tBWS, notify_bweb);
    $setup(posedge BWEB[6], posedge CLK &&& check_write, tBWS, notify_bweb);
    $setup(posedge BWEB[7], posedge CLK &&& check_write, tBWS, notify_bweb);

    $hold(posedge CLK &&& check_write, negedge BWEB[0], tBWH, notify_bweb);
    $hold(posedge CLK &&& check_write, negedge BWEB[1], tBWH, notify_bweb);
    $hold(posedge CLK &&& check_write, negedge BWEB[2], tBWH, notify_bweb);
    $hold(posedge CLK &&& check_write, negedge BWEB[3], tBWH, notify_bweb);
    $hold(posedge CLK &&& check_write, negedge BWEB[4], tBWH, notify_bweb);
    $hold(posedge CLK &&& check_write, negedge BWEB[5], tBWH, notify_bweb);
    $hold(posedge CLK &&& check_write, negedge BWEB[6], tBWH, notify_bweb);
    $hold(posedge CLK &&& check_write, negedge BWEB[7], tBWH, notify_bweb);

    $hold(posedge CLK &&& check_write, posedge BWEB[0], tBWH, notify_bweb);
    $hold(posedge CLK &&& check_write, posedge BWEB[1], tBWH, notify_bweb);
    $hold(posedge CLK &&& check_write, posedge BWEB[2], tBWH, notify_bweb);
    $hold(posedge CLK &&& check_write, posedge BWEB[3], tBWH, notify_bweb);
    $hold(posedge CLK &&& check_write, posedge BWEB[4], tBWH, notify_bweb);
    $hold(posedge CLK &&& check_write, posedge BWEB[5], tBWH, notify_bweb);
    $hold(posedge CLK &&& check_write, posedge BWEB[6], tBWH, notify_bweb);
    $hold(posedge CLK &&& check_write, posedge BWEB[7], tBWH, notify_bweb);

endspecify
`endif	//end `ifdef UNIT_DELAY

initial begin

    read_flag = 0;
    write_flag = 0;
    idle_flag = 0;
    
end


always @(posedge CLK_i) begin

    if (CEB_i === 1'b0) begin
    	idle_flag = 0;
    	if (WEB_i === 1'b1) begin    	// read
	    read_flag = 1;

`ifdef UNIT_DELAY
`else
	    if ( ^A_i === 1'bx ) begin
    `ifdef no_warning
    `else
	    	$display("\tWarning %m : input A unknown/high-Z in read cycle at simulation time %.1f\n", $realtime);
    `endif
		Q_d1 = {numBit{1'bx}};
		xMemoryAll;
	    end
	    else if (A_i >= numWord) begin
    `ifdef no_warning
    `else
	    	$display("\tWarning %m : address exceed word depth in read cycle at simulation time %.1f\n", $realtime);
    `endif
	    end
	    else begin
`endif	//end `ifdef UNIT_DELAY
    	    	Q_d1 = MEMORY[iRowAddr][iColAddr];
	    end
`ifdef UNIT_DELAY
`else
	end
`endif	//end `ifdef UNIT_DELAY
	else if (WEB_i === 1'b0) begin	// write
	    write_flag = 1;
`ifdef UNIT_DELAY
`else
	    if ( ^A_i === 1'bx ) begin
    `ifdef no_warning
    `else
	    	$display("\tWarning %m : input A unknown/high-Z in write cycle at simulation time %.1f\n", $realtime);
    `endif
		xMemoryAll;
	    end
	    else if (A_i >= numWord) begin
    `ifdef no_warning
    `else
	    	$display("\tWarning %m : address exceed word depth in write cycle at simulation time %.1f\n", $realtime);
    `endif
	    end
	    else begin

		    if ( ^D_i === 1'bx ) begin
    `ifdef no_warning
    `else
		    	$display("\tWarning %m : input D unknown/high-Z in write cycle at simulation time %.1f\n", $realtime);
    `endif
		    end
		    if ( ^BWEB_i === 1'bx ) begin
    `ifdef no_warning
    `else
		    	$display("\tWarning %m : input BWEB unknown/high-Z in write cycle at simulation time %.1f\n", $realtime);
    `endif
		    end
`endif	//end `ifdef UNIT_DELAY

    	    	    DIN_tmp = MEMORY[iRowAddr][iColAddr];

    	    	    for (i = 0; i < numBit; i = i + 1) begin
    	    	    	if (BWEB_i[i] === 1'b0) begin
    	    	    	    DIN_tmp[i] = D_i[i];
    	    	    	end
    	    	    	else if (BWEB_i[i] === 1'bx) begin
    	    	    	    DIN_tmp[i] = 1'bx;
    	    	    	end

    	    	    end

    	    	    if ( isStuckAt0(A_i) || isStuckAt1(A_i) ) begin
    	    	    	combineErrors(A_i, ERR_tmp);
    	    	    	for (j = 0; j < numBit; j = j + 1) begin
    	    	    	    if (ERR_tmp[j] === 1'b0) begin
    	    	    	    	DIN_tmp[j] = 1'b0;					
    	    	    	    	end
    	    	    	    else if (ERR_tmp[j] === 1'b1) begin
    	    	    	    	DIN_tmp[j] = 1'b1;
    	    	    	    end
    	    	    	end
    	    	    end

    	    	    MEMORY[iRowAddr][iColAddr] = DIN_tmp;

	    end
	end
`ifdef UNIT_DELAY
`else
	else begin
    `ifdef no_warning
    `else
    	    $display("\tWarning %m : input WEB unknown/high-Z at simulation time %.1f\n", $realtime);
    `endif
	    if ( ^A_i === 1'bx ) begin
	    	Q_d1 = {numBit{1'bx}};
		xMemoryAll;
	    end
	    else begin
	    	Q_d1 = {numBit{1'bx}};
		xMemoryWord(A_i);
	    end
	end
    end
`endif	//end `ifdef UNIT_DELAY
    else if (CEB_i === 1'b1) begin
    	idle_flag = 1;
    end

`ifdef UNIT_DELAY
`else
    else begin
    `ifdef no_warning
    `else
    	$display("\tWarning %m : input CEB unknown/high-Z at simulation time %.1f\n", $realtime);
    `endif
	Q_d1 = {numBit{1'bx}};
	xMemoryAll;
    end
`endif	//end `ifdef UNIT_DELAY


end


always @(CLK_i) begin
`ifdef UNIT_DELAY
if (CLK_i === 1'b0) begin
`else
    if (CLK_i === 1'bx || CLK_i === 1'bz) begin
    	if (CEB_i !== 1'b1) begin
    `ifdef no_warning
    `else
    	    $display("\tWarning %m : input CLK unknown/high-Z at simulation time %.1f\n", $realtime);
    `endif
	    Q_d1 = {numBit{1'bx}};
	    xMemoryAll;
	end
`endif	//end `ifdef UNIT_DELAY

	read_flag = 0;
	write_flag = 0;
    end
`ifdef UNIT_DELAY
`else
    else if (CLK_i === 1'b0) begin
	read_flag = 0;
	write_flag = 0;
    end
`endif	//end `ifdef UNIT_DELAY

end

always @(posedge CLK_i) begin
`ifdef UNIT_DELAY
    #(`SRAM_DELAY);
    Q_d = Q_d1;
`else
    if (CEB_i === 1'b0 && WEB_i === 1'b1) begin
      #(Thold);
      Q_d = {numBit{1'bx}};
      #(0.001);
      Q_d = Q_d1;
    end
`endif	//end `ifdef UNIT_DELAY
end


`ifdef UNIT_DELAY
`else
always @(Q_d1) begin
    Q_d = Q_d1;
end

// this coding style works fine in both NC-Verilog and VCS
always @(notify_clk) begin

    Q_d1 = {numBit{1'bx}};
    xMemoryAll;

end

always @(notify_bist) begin

    Q_d1 = {numBit{1'bx}};
    xMemoryAll;

end

always @(notify_ceb) begin

    Q_d1 = {numBit{1'bx}};
    xMemoryAll;
    read_flag = 0;
    write_flag = 0;

end

always @(notify_web) begin

    Q_d1 = {numBit{1'bx}};
    xMemoryAll;
    read_flag = 0;
    write_flag = 0;

end

always @(notify_addr) begin

    if (WEB_i === 1'b1) begin
    	Q_d1 = {numBit{1'bx}};
    	xMemoryAll;
    end
    else if (WEB_i === 1'b0) begin
    	xMemoryAll;
    end
    else begin
    	Q_d1 = {numBit{1'bx}};
	xMemoryAll;
    end
    
    read_flag = 0;
    write_flag = 0;

end

always @(notify_din) begin

    if ( ^A_i === 1'bx ) begin
    	xMemoryAll;
    end
    else begin
    	xMemoryWord(A_i);
    end
    
    write_flag = 0;

end

always @(notify_bweb) begin

    if ( ^A_i === 1'bx ) begin
    	xMemoryAll;
    end
    else begin
    	xMemoryWord(A_i);
    end
    
    write_flag = 0;

end


task xMemoryAll;
reg [numRowAddr:0] row;
reg [numCMAddr:0] col;
begin
    for (row = 0; row < numRow; row = row + 1) begin
    	for (col = 0; col < numCM; col = col + 1) begin
    	    MEMORY[row][col] = {numBit{1'bx}};
	end
    end
end
endtask


task xMemoryWord;
input [numWordAddr-1:0] addr;
reg [numRowAddr-1:0] row;
reg [numCMAddr-1:0] col;
begin

    {row, col} = addr;
    MEMORY[row][col] = {numBit{1'bx}};

end
endtask
`endif	//end `ifdef UNIT_DELAY


task preloadData;
reg [numWordAddr:0] w;
reg [numWordAddr-numCMAddr-1:0] row;
reg [numCMAddr-1:0] col;
begin

    `ifdef no_warning
    `else
    $display("Preloading data from file %s", preloadFile);
    `endif
    $readmemb(preloadFile, PRELOAD);

    for (w = 0; w < numWord; w = w + 1) begin
    	{row, col} = w;
    	MEMORY[row][col] = PRELOAD[w];
    end
 
end
endtask


/*
 * task injectSA - to inject a stuck-at error, please use hierarchical reference to call the injectSA task from the wrapper module
 *  	input addr - the address location where the defect is to be introduced
 *  	input bit - the bit location of the specified address where the defect is to occur
 *  	input type - specify whether it's a s-a-0 (type = 0) or a s-a-1 (type = 1) fault
 *
 *  	Multiple faults can be injected at the same address, regardless of the type.  This means that an address location can have 
 *  	certain bits having stuck-at-0 faults while other bits have the stuck-at-1 defect.
 *
 * Examples:
 *  	injectSA(0, 0, 0);  - injects a s-a-0 fault at address 0, bit 0
 *  	injectSA(1, 0, 1);  - injects a s-a-1 fault at address 1, bit 0
 *  	injectSA(1, 1, 0);  - injects a s-a-0 fault at address 1, bit 1
 *  	injectSA(1, 2, 1);  - injects a s-a-1 fault at address 1, bit 2
 *  	injectSA(1, 3, 1);  - injects a s-a-1 fault at address 1, bit 3
 *  	injectSA(2, 2, 1);  - injects a s-a-1 fault at address 2, bit 2
 *  	injectSA(14, 2, 0); - injects a s-a-0 fault at address 14, bit 2
 *
 */
task injectSA;
input [numWordAddr-1:0] addr;
input [numBit-1:0] bitn;
input typen;
reg [numStuckAt:0] i;
reg [numBit-1:0] btmp;
begin

    if ( typen == 0 ) begin
    
    	for (i = 0; i < numStuckAt; i = i + 1) begin
	
    	    if ( ^stuckAt0Addr[i] === 1'bx ) begin
	    	stuckAt0Addr[i] = addr;
		btmp = {numBit{1'bx}};
		btmp[bitn] = 1'b0;
		stuckAt0Bit[i] = btmp;
	    	i = numStuckAt;

    `ifdef no_warning
    `else
		$display("First s-a-0 error injected at address location %d = %b", addr, btmp);
    `endif
	    	i = numStuckAt;
	    end
	    else if ( stuckAt0Addr[i] === addr ) begin
	    	btmp = stuckAt0Bit[i];
		btmp[bitn] = 1'b0;
		stuckAt0Bit[i] = btmp;
		
    `ifdef no_warning
    `else
		$display("More s-a-0 error injected at address location %d = %b", addr, btmp);
    `endif
	    	i = numStuckAt;
	    end	    
	end
	
    end
    else if (typen == 1) begin
    
    	for (i = 0; i < numStuckAt; i = i + 1) begin
	
    	    if ( ^stuckAt1Addr[i] === 1'bx ) begin
	    	stuckAt1Addr[i] = addr;
		btmp = {numBit{1'bx}};
		btmp[bitn] = 1'b1;
		stuckAt1Bit[i] = btmp;
	    	i = numStuckAt;

    `ifdef no_warning
    `else
		$display("First s-a-1 error injected at address location %d = %b", addr, btmp);
    `endif
	    	i = numStuckAt;
	    end
	    else if ( stuckAt1Addr[i] === addr ) begin
	    	btmp = stuckAt1Bit[i];
		btmp[bitn] = 1'b1;
		stuckAt1Bit[i] = btmp;
		
    `ifdef no_warning
    `else
		$display("More s-a-1 error injected at address location %d = %b", addr, btmp);
    `endif
	    	i = numStuckAt;
	    end	    
	end
	
    end

end
endtask


task combineErrors;
input [numWordAddr-1:0] addr;
output [numBit-1:0] errors;
reg [numBit:0] j;
reg [numBit-1:0] btmp;
begin

    errors = {numBit{1'bx}};
    if ( isStuckAt0(addr) ) begin
	btmp = stuckAt0Bit[getStuckAt0Index(addr)];
    	for ( j = 0; j < numBit; j = j + 1 ) begin
	    if ( btmp[j] === 1'b0 ) begin
	    	errors[j] = 1'b0;
	    end
	end
    end
    if ( isStuckAt1(addr) ) begin
    	btmp = stuckAt1Bit[getStuckAt1Index(addr)];
    	for ( j = 0; j < numBit; j = j + 1 ) begin
	    if ( btmp[j] === 1'b1 ) begin
	    	errors[j] = 1'b1;
	    end
	end
    end

end
endtask


function [numStuckAt-1:0] getStuckAt0Index;
input [numWordAddr-1:0] addr;
reg [numStuckAt:0] i;
begin

    for (i = 0; i < numStuckAt; i = i + 1) begin
    
    	if (stuckAt0Addr[i] === addr) begin
	    getStuckAt0Index = i;
	end
    
    end

end
endfunction


function [numStuckAt-1:0] getStuckAt1Index;
input [numWordAddr-1:0] addr;
reg [numStuckAt:0] i;
begin

    for (i = 0; i < numStuckAt; i = i + 1) begin
    
    	if (stuckAt1Addr[i] === addr) begin
	    getStuckAt1Index = i;
	end
    
    end

end
endfunction


function isStuckAt0;
input [numWordAddr-1:0] addr;
reg [numStuckAt:0] i;
reg flag;
begin

    flag = 0;
    for (i = 0; i < numStuckAt; i = i + 1) begin

    	if (stuckAt0Addr[i] === addr) begin
    	    flag = 1;
	    i = numStuckAt;
	end

    end

    isStuckAt0 = flag;

end
endfunction


function isStuckAt1;
input [numWordAddr-1:0] addr;
reg [numStuckAt:0] i;
reg flag;
begin

    flag = 0;
    for (i = 0; i < numStuckAt; i = i + 1) begin

    	if (stuckAt1Addr[i] === addr) begin
	    flag = 1;
	    i = numStuckAt;
	end

    end

    isStuckAt1 = flag;

end
endfunction


task printMemory;
reg [numRowAddr:0] row;
reg [numCMAddr:0] col;
reg [numBit-1:0] temp;
begin

    `ifdef no_warning
    `else
    $display("\n\nDumping memory content at %.1f...\n", $realtime);
    `endif
    
    for (row = 0; row < numRow; row = row + 1) begin
    	for (col = 0; col < numCM; col = col + 1) begin
    `ifdef no_warning
    `else
    	    //$display("[%d] = %b", {row, col}, MEMORY[row][col]);
            temp = MEMORY[row][col];
            $display("[%d] = %b", {row, col}, temp);
    `endif
	end
    end    
    
    `ifdef no_warning
    `else
    $display("\n\n");
    `endif
    
end
endtask


task printMemoryFromTo;
input [numWordAddr-1:0] addr1;
input [numWordAddr-1:0] addr2;
reg [numWordAddr:0] addr;
reg [numRowAddr-1:0] row;
reg [numCMAddr-1:0] col;
reg [numBit-1:0] temp;
begin

    `ifdef no_warning
    `else
    $display("\n\nDumping memory content at %.1f...\n", $realtime);
    `endif
    
    for (addr = addr1; addr < addr2; addr = addr + 1) begin
    	{row, col} = addr;
    `ifdef no_warning
    `else
    	//$display("[%d] = %b", addr, MEMORY[row][col]);
        temp = MEMORY[row][col];
        $display("[%d] = %b", {row, col}, temp);
    `endif
    end    
    
    `ifdef no_warning
    `else
    $display("\n\n");
    `endif
    
end
endtask


endmodule
`endcelldefine

