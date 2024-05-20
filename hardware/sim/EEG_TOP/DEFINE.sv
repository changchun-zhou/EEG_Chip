//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description :
//========================================================
`ifndef DEFINE
  `define DEFINE

`define FrameNum       2
  
`define CHIP_DAT_DW    8
`define CHIP_OUT_DW    8
`define CHIP_SUM_DW   24
`define CHIP_CMD_DW   32
`define BANK_NUM_DW    4
`define ORAM_NUM_DW    4
`define OMUX_NUM_DW    4
`define OMUX_RAM_DW  256
`define FRAM_RAM_DW 1024
`define STAT_NUM_DW   32
`define WRAM_NUM_DW    4
`define ARAM_NUM_DW    4
`define WBUF_NUM_DW    4
`define WRAM_ADD_AW   13
`define WRAM_DAT_DW    8
`define ARAM_ADD_AW   12
`define ARAM_DAT_DW    8

typedef  bit [`CHIP_DAT_DW -1:0] type_dat [int];
typedef  bit [`CHIP_CMD_DW -1:0] type_cmd [int];

`endif
