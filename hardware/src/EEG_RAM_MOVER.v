//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description : RAM MOVER 
//========================================================
module EEG_RAM_MOVER #(
    parameter MOVE_CMD_DW =  8,
    parameter MOVE_DAT_DW =  8,
    parameter BANK_NUM_DW =  4,
    parameter ARAM_ADD_AW = 12,
    parameter WRAM_ADD_AW = 13,
    parameter ORAM_ADD_AW = 10,
    parameter OMUX_ADD_AW =  8,
    parameter FRAM_ADD_AW = ARAM_ADD_AW,
    parameter CONV_LEN_DW = 10,
    parameter CONV_ICH_DW =  8,
    parameter CONV_OCH_DW =  8,
    parameter CONV_WEI_DW =  3,
    parameter CONV_SPT_DW =  8,
    parameter STAT_NUM_DW = 32,
    parameter STAT_CNT_DW = CONV_OCH_DW,
    parameter STAT_INF_DW = CONV_OCH_DW,
    parameter ARAM_NUM_DW = BANK_NUM_DW,
    parameter WRAM_NUM_DW = BANK_NUM_DW,
    parameter ORAM_NUM_DW = BANK_NUM_DW,
    parameter OMUX_NUM_DW = BANK_NUM_DW,
    parameter FRAM_NUM_DW = BANK_NUM_DW,
    parameter ARAM_DAT_DW = MOVE_DAT_DW,
    parameter WRAM_DAT_DW = MOVE_DAT_DW,
    parameter ORAM_DAT_DW = MOVE_DAT_DW,
    parameter FRAM_DAT_DW = 4,
    parameter BANK_NUM_AW = $clog2(BANK_NUM_DW),
    parameter ARAM_NUM_AW = BANK_NUM_AW,
    parameter WRAM_NUM_AW = BANK_NUM_AW,
    parameter ORAM_NUM_AW = BANK_NUM_AW,
    parameter OMUX_NUM_AW = BANK_NUM_AW,
    parameter STAT_DAT_DW = CONV_ICH_DW+CONV_WEI_DW,
    parameter STAT_NUM_AW = $clog2(STAT_NUM_DW)
  )(
    input                                          clk,
    input                                          rst_n,
    
    output                                         IS_IDLE,
    
    input                                          CFG_INFO_VLD,
    output                                         CFG_INFO_RDY,
    input  [MOVE_CMD_DW                      -1:0] CFG_INFO_CMD,//IDLE/ITOA/ITOW/OTOA/ATOW/WTOA/STAT
    input  [ARAM_NUM_DW                      -1:0] CFG_ARAM_IDX,
    input  [WRAM_NUM_DW                      -1:0] CFG_WRAM_IDX,
    input  [ORAM_NUM_DW                      -1:0] CFG_ORAM_IDX,
    input  [OMUX_NUM_DW                      -1:0] CFG_OMUX_IDX,
    input  [ARAM_ADD_AW                      -1:0] CFG_ARAM_ADD,
    input  [WRAM_ADD_AW                      -1:0] CFG_WRAM_ADD,
    input  [ORAM_ADD_AW                      -1:0] CFG_ORAM_ADD,
    input  [ARAM_ADD_AW                      -1:0] CFG_ARAM_LEN,
    input  [WRAM_ADD_AW                      -1:0] CFG_WRAM_LEN,
    input  [ORAM_ADD_AW                      -1:0] CFG_ORAM_LEN,
    input  [CONV_LEN_DW                      -1:0] CFG_CONV_LEN,
    input  [CONV_OCH_DW                      -1:0] CFG_CONV_OCH,
    input  [CONV_WEI_DW                      -1:0] CFG_CONV_WEI,
    input                                          CFG_FLAG_ENA,
    input                                          CFG_WSTA_ENA,
    input                                          CFG_SPLT_ENA,
    input  [CONV_SPT_DW                      -1:0] CFG_SPLT_LEN,

    input                                          ITOM_DAT_VLD,
    input                                          ITOM_DAT_LST,
    output                                         ITOM_DAT_RDY,
    input  [MOVE_DAT_DW                      -1:0] ITOM_DAT_DAT,

    output                                         MTOC_DAT_VLD,
    output                                         MTOC_DAT_LST,
    input                                          MTOC_DAT_RDY,
    output [MOVE_DAT_DW                      -1:0] MTOC_DAT_DAT,

    //WSTA
    output [BANK_NUM_DW -1:0]                      MTOS_DAT_VLD,
    output [BANK_NUM_DW -1:0]                      MTOS_DAT_LST,
    input  [BANK_NUM_DW -1:0]                      MTOS_DAT_RDY,
    output [BANK_NUM_DW -1:0][STAT_NUM_AW    -1:0] MTOS_DAT_ADD,
    output [BANK_NUM_DW -1:0][STAT_DAT_DW    -1:0] MTOS_DAT_DAT,

    //FRAM
    output [FRAM_NUM_DW -1:0]                      MTOF_DAT_VLD,
    output [FRAM_NUM_DW -1:0]                      MTOF_DAT_LST,
    input  [FRAM_NUM_DW -1:0]                      MTOF_DAT_RDY,
    output [FRAM_NUM_DW -1:0][FRAM_ADD_AW    -1:0] MTOF_DAT_ADD,
    output [FRAM_NUM_DW -1:0][FRAM_DAT_DW    -1:0] MTOF_DAT_DAT,
    
    //ARAM
    output [ARAM_NUM_DW -1:0]                      MTOA_DAT_VLD,
    output [ARAM_NUM_DW -1:0]                      MTOA_DAT_LST,
    input  [ARAM_NUM_DW -1:0]                      MTOA_DAT_RDY,
    output [ARAM_NUM_DW -1:0][ARAM_ADD_AW    -1:0] MTOA_DAT_ADD,
    output [ARAM_NUM_DW -1:0][ARAM_DAT_DW    -1:0] MTOA_DAT_DAT,

    output [ARAM_NUM_DW -1:0]                      MTOA_ADD_VLD,
    output [ARAM_NUM_DW -1:0]                      MTOA_ADD_LST,
    input  [ARAM_NUM_DW -1:0]                      MTOA_ADD_RDY,
    output [ARAM_NUM_DW -1:0][ARAM_ADD_AW    -1:0] MTOA_ADD_ADD,
    input  [ARAM_NUM_DW -1:0]                      ATOM_DAT_VLD,
    input  [ARAM_NUM_DW -1:0]                      ATOM_DAT_LST,
    output [ARAM_NUM_DW -1:0]                      ATOM_DAT_RDY,
    input  [ARAM_NUM_DW -1:0][ARAM_DAT_DW    -1:0] ATOM_DAT_DAT,
    //WRAM
    output [WRAM_NUM_DW -1:0]                      MTOW_DAT_VLD,
    output [WRAM_NUM_DW -1:0]                      MTOW_DAT_LST,
    input  [WRAM_NUM_DW -1:0]                      MTOW_DAT_RDY,
    output [WRAM_NUM_DW -1:0][WRAM_ADD_AW    -1:0] MTOW_DAT_ADD,
    output [WRAM_NUM_DW -1:0][WRAM_DAT_DW    -1:0] MTOW_DAT_DAT,

    output [WRAM_NUM_DW -1:0]                      MTOW_ADD_VLD,
    output [WRAM_NUM_DW -1:0]                      MTOW_ADD_LST,
    input  [WRAM_NUM_DW -1:0]                      MTOW_ADD_RDY,
    output [WRAM_NUM_DW -1:0][WRAM_ADD_AW    -1:0] MTOW_ADD_ADD,
    input  [WRAM_NUM_DW -1:0]                      WTOM_DAT_VLD,
    input  [WRAM_NUM_DW -1:0]                      WTOM_DAT_LST,
    output [WRAM_NUM_DW -1:0]                      WTOM_DAT_RDY,
    input  [WRAM_NUM_DW -1:0][WRAM_DAT_DW    -1:0] WTOM_DAT_DAT,
    //ORAM
    output [ORAM_NUM_DW -1:0]                      MTOO_DAT_VLD,
    output [ORAM_NUM_DW -1:0]                      MTOO_DAT_LST,
    input  [ORAM_NUM_DW -1:0]                      MTOO_DAT_RDY,
    output [ORAM_NUM_DW -1:0][ORAM_ADD_AW    -1:0] MTOO_DAT_ADD,
    output [ORAM_NUM_DW -1:0][ORAM_DAT_DW    -1:0] MTOO_DAT_DAT,

    output [ORAM_NUM_DW -1:0]                      MTOO_ADD_VLD,
    output [ORAM_NUM_DW -1:0]                      MTOO_ADD_LST,
    input  [ORAM_NUM_DW -1:0]                      MTOO_ADD_RDY,
    output [ORAM_NUM_DW -1:0][ORAM_ADD_AW    -1:0] MTOO_ADD_ADD,
    input  [ORAM_NUM_DW -1:0]                      OTOM_DAT_VLD,
    input  [ORAM_NUM_DW -1:0]                      OTOM_DAT_LST,
    output [ORAM_NUM_DW -1:0]                      OTOM_DAT_RDY,
    input  [ORAM_NUM_DW -1:0][ORAM_DAT_DW    -1:0] OTOM_DAT_DAT
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
localparam OMUX_ADD_DW = 1<<OMUX_ADD_AW;
localparam MOVE_BUF_DW = MOVE_DAT_DW+1;
localparam MOVE_BUF_AW = 2;

integer i, j;
genvar gen_i, gen_j;  

localparam MOVE_STATE = MOVE_CMD_DW;
localparam MOVE_IDLE  = 8'b00000001;
localparam MOVE_ITOA  = 8'b00000010;
localparam MOVE_ITOW  = 8'b00000100;
localparam MOVE_OTOA  = 8'b00001000;
localparam MOVE_ATOW  = 8'b00010000;
localparam MOVE_WTOA  = 8'b00100000;
localparam MOVE_STAT  = 8'b01000000;
localparam MOVE_READ  = 8'b10000000;

reg [MOVE_STATE -1:0] move_cs;
reg [MOVE_STATE -1:0] move_ns;

wire move_idle = move_cs == MOVE_IDLE;
wire move_itoa = move_cs == MOVE_ITOA;
wire move_itow = move_cs == MOVE_ITOW;
wire move_otoa = move_cs == MOVE_OTOA;//PIXEL FIRST OTOA/WSTA
wire move_atow = move_cs == MOVE_ATOW;
wire move_wtoa = move_cs == MOVE_WTOA;
wire move_stat = move_cs == MOVE_STAT;//CHANNEL FIRST
wire move_read = move_cs == MOVE_READ;
wire move_itoo = 1'd0;
assign IS_IDLE = move_idle;
reg  [BANK_NUM_DW -1:0] atom_lst_done;
reg  [BANK_NUM_DW -1:0] wtom_lst_done;
reg  [BANK_NUM_DW -1:0] otom_lst_done;
reg  [BANK_NUM_DW -1:0] mtoa_lst_done;
reg  [BANK_NUM_DW -1:0] mtow_lst_done;
reg  [BANK_NUM_DW -1:0] mtof_lst_done;
reg  [BANK_NUM_DW -1:0] wsta_lst_done;
reg                     read_lst_done;
//reg  [BANK_NUM_DW -1:0] mtoo_dat_done;
wire move_itoa_done = &mtoa_lst_done;
wire move_itow_done = &mtow_lst_done;
wire move_otoa_done = &mtoa_lst_done && &wsta_lst_done;
wire move_atow_done = &mtow_lst_done;
wire move_wtoa_done = &mtoa_lst_done;
wire move_stat_done = &mtof_lst_done;
wire move_read_done =  read_lst_done;
//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
//MODE_IO
wire                                         cfg_info_vld = CFG_INFO_VLD;
reg                                          cfg_info_rdy;
wire                                         cfg_info_ena = cfg_info_vld && cfg_info_rdy;
reg  [MOVE_CMD_DW                      -1:0] cfg_info_cmd;
reg  [ARAM_NUM_DW                      -1:0] cfg_aram_idx;
reg  [WRAM_NUM_DW                      -1:0] cfg_wram_idx;
reg  [ORAM_NUM_DW                      -1:0] cfg_oram_idx;
reg  [OMUX_NUM_DW                      -1:0] cfg_omux_idx;
reg  [ARAM_ADD_AW                      -1:0] cfg_aram_add;
reg  [WRAM_ADD_AW                      -1:0] cfg_wram_add;
reg  [ORAM_ADD_AW                      -1:0] cfg_oram_add;
reg  [ARAM_ADD_AW                      -1:0] cfg_aram_len;
reg  [WRAM_ADD_AW                      -1:0] cfg_wram_len;
reg  [ORAM_ADD_AW                      -1:0] cfg_oram_len;
reg  [CONV_LEN_DW                      -1:0] cfg_conv_len;
reg  [CONV_OCH_DW                      -1:0] cfg_conv_och;
reg  [CONV_WEI_DW                      -1:0] cfg_conv_wei;
reg                                          cfg_flag_ena;
reg                                          cfg_wsta_ena;
reg                                          cfg_splt_ena;
reg  [CONV_SPT_DW                      -1:0] cfg_splt_len;

reg  [OMUX_NUM_AW                      -1:0] cal_omux_num, cal_omux_num_tmp;
reg                                          cal_aram_ena;
reg                                          cal_wram_ena;
reg                                          cal_oram_ena;

assign CFG_INFO_RDY = cfg_info_rdy;
//ITOM_IO
wire                                         itom_dat_vld = ITOM_DAT_VLD;
wire                                         itom_dat_lst = ITOM_DAT_LST;
reg                                          itom_dat_rdy;
wire [MOVE_DAT_DW                      -1:0] itom_dat_dat = ITOM_DAT_DAT;
assign ITOM_DAT_RDY = itom_dat_rdy;

wire itom_dat_ena = itom_dat_vld & itom_dat_rdy;

//MTOC_IO
reg                                          mtoc_dat_vld;
reg                                          mtoc_dat_lst;
wire                                         mtoc_dat_rdy = MTOC_DAT_RDY;
reg  [MOVE_DAT_DW                      -1:0] mtoc_dat_dat;

assign MTOC_DAT_VLD = mtoc_dat_vld;
assign MTOC_DAT_LST = mtoc_dat_lst;
assign MTOC_DAT_DAT = mtoc_dat_dat;

wire mtoc_dat_ena = mtoc_dat_vld & mtoc_dat_rdy;
//STAT_IO
reg  [BANK_NUM_DW -1:0]                      mtos_dat_vld;
reg  [BANK_NUM_DW -1:0]                      mtos_dat_lst;
wire [BANK_NUM_DW -1:0]                      mtos_dat_rdy = MTOS_DAT_RDY;
reg  [BANK_NUM_DW -1:0][STAT_NUM_AW    -1:0] mtos_dat_add;
reg  [BANK_NUM_DW -1:0][STAT_DAT_DW    -1:0] mtos_dat_dat;

assign MTOS_DAT_VLD = mtos_dat_vld;
assign MTOS_DAT_LST = mtos_dat_lst;
assign MTOS_DAT_ADD = mtos_dat_add;
assign MTOS_DAT_DAT = mtos_dat_dat;

wire [BANK_NUM_DW -1:0] mtos_dat_ena = mtos_dat_vld & mtos_dat_rdy;
wire [BANK_NUM_DW -1:0] mtos_dat_end = mtos_dat_vld & mtos_dat_rdy & mtos_dat_lst;
//FRAM_IO
reg  [FRAM_NUM_DW -1:0]                      mtof_dat_vld;
reg  [FRAM_NUM_DW -1:0]                      mtof_dat_lst;
wire [FRAM_NUM_DW -1:0]                      mtof_dat_rdy = MTOF_DAT_RDY;
reg  [FRAM_NUM_DW -1:0][FRAM_ADD_AW    -1:0] mtof_dat_add;
reg  [FRAM_NUM_DW -1:0][FRAM_DAT_DW    -1:0] mtof_dat_dat;
assign MTOF_DAT_VLD = mtof_dat_vld;
assign MTOF_DAT_LST = mtof_dat_lst;
assign MTOF_DAT_ADD = mtof_dat_add;
assign MTOF_DAT_DAT = mtof_dat_dat;

wire [FRAM_NUM_DW -1:0] mtof_dat_ena = mtof_dat_vld & mtof_dat_rdy;
//ARAM_IO
reg  [ARAM_NUM_DW -1:0]                      mtoa_dat_vld;
reg  [ARAM_NUM_DW -1:0]                      mtoa_dat_lst;
wire [ARAM_NUM_DW -1:0]                      mtoa_dat_rdy = MTOA_DAT_RDY;
reg  [ARAM_NUM_DW -1:0][ARAM_ADD_AW    -1:0] mtoa_dat_add;
reg  [ARAM_NUM_DW -1:0][ARAM_DAT_DW    -1:0] mtoa_dat_dat;
assign MTOA_DAT_VLD = mtoa_dat_vld;
assign MTOA_DAT_LST = mtoa_dat_lst;
assign MTOA_DAT_ADD = mtoa_dat_add;
assign MTOA_DAT_DAT = mtoa_dat_dat;

reg  [ARAM_NUM_DW -1:0]                      mtoa_add_vld;
reg  [ARAM_NUM_DW -1:0]                      mtoa_add_lst;
wire [ARAM_NUM_DW -1:0]                      mtoa_add_rdy = MTOA_ADD_RDY;
reg  [ARAM_NUM_DW -1:0][ARAM_ADD_AW    -1:0] mtoa_add_add;
wire [ARAM_NUM_DW -1:0]                      atom_dat_vld = ATOM_DAT_VLD;
wire [ARAM_NUM_DW -1:0]                      atom_dat_lst = ATOM_DAT_LST;
reg  [ARAM_NUM_DW -1:0]                      atom_dat_rdy;
wire [ARAM_NUM_DW -1:0][ARAM_DAT_DW    -1:0] atom_dat_dat = ATOM_DAT_DAT;
assign MTOA_ADD_VLD = mtoa_add_vld;
assign MTOA_ADD_LST = mtoa_add_lst;
assign MTOA_ADD_ADD = mtoa_add_add;
assign ATOM_DAT_RDY = atom_dat_rdy;

wire [ARAM_NUM_DW -1:0] mtoa_dat_ena = mtoa_dat_vld & mtoa_dat_rdy;
wire [ARAM_NUM_DW -1:0] mtoa_add_ena = mtoa_add_vld & mtoa_add_rdy;
wire [ARAM_NUM_DW -1:0] atom_dat_ena = atom_dat_vld & atom_dat_rdy;
//WRAM_IO
reg  [WRAM_NUM_DW -1:0]                      mtow_dat_vld;
reg  [WRAM_NUM_DW -1:0]                      mtow_dat_lst;
wire [WRAM_NUM_DW -1:0]                      mtow_dat_rdy = MTOW_DAT_RDY;
reg  [WRAM_NUM_DW -1:0][WRAM_ADD_AW    -1:0] mtow_dat_add;
reg  [WRAM_NUM_DW -1:0][WRAM_DAT_DW    -1:0] mtow_dat_dat;
assign MTOW_DAT_VLD = mtow_dat_vld;
assign MTOW_DAT_LST = mtow_dat_lst;
assign MTOW_DAT_ADD = mtow_dat_add;
assign MTOW_DAT_DAT = mtow_dat_dat;

reg  [WRAM_NUM_DW -1:0]                      mtow_add_vld;
reg  [WRAM_NUM_DW -1:0]                      mtow_add_lst;
wire [WRAM_NUM_DW -1:0]                      mtow_add_rdy = MTOW_ADD_RDY;
reg  [WRAM_NUM_DW -1:0][WRAM_ADD_AW    -1:0] mtow_add_add;
wire [WRAM_NUM_DW -1:0]                      wtom_dat_vld = WTOM_DAT_VLD;
wire [WRAM_NUM_DW -1:0]                      wtom_dat_lst = WTOM_DAT_LST;
reg  [WRAM_NUM_DW -1:0]                      wtom_dat_rdy;
wire [WRAM_NUM_DW -1:0][WRAM_DAT_DW    -1:0] wtom_dat_dat = WTOM_DAT_DAT;
assign MTOW_ADD_VLD = mtow_add_vld;
assign MTOW_ADD_LST = mtow_add_lst;
assign MTOW_ADD_ADD = mtow_add_add;
assign WTOM_DAT_RDY = wtom_dat_rdy;

wire [WRAM_NUM_DW -1:0] mtow_dat_ena = mtow_dat_vld & mtow_dat_rdy;
wire [WRAM_NUM_DW -1:0] mtow_add_ena = mtow_add_vld & mtow_add_rdy;
wire [WRAM_NUM_DW -1:0] wtom_dat_ena = wtom_dat_vld & wtom_dat_rdy;
//ORAM_IO
reg  [ORAM_NUM_DW -1:0]                      mtoo_dat_vld;
reg  [ORAM_NUM_DW -1:0]                      mtoo_dat_lst;
wire [ORAM_NUM_DW -1:0]                      mtoo_dat_rdy = MTOO_DAT_RDY;
reg  [ORAM_NUM_DW -1:0][ORAM_ADD_AW    -1:0] mtoo_dat_add;
reg  [ORAM_NUM_DW -1:0][ORAM_DAT_DW    -1:0] mtoo_dat_dat;
assign MTOO_DAT_VLD = mtoo_dat_vld;
assign MTOO_DAT_LST = mtoo_dat_lst;
assign MTOO_DAT_ADD = mtoo_dat_add;
assign MTOO_DAT_DAT = mtoo_dat_dat;

reg  [ORAM_NUM_DW -1:0]                      mtoo_add_vld;
reg  [ORAM_NUM_DW -1:0]                      mtoo_add_lst;
wire [ORAM_NUM_DW -1:0]                      mtoo_add_rdy = MTOO_ADD_RDY;
reg  [ORAM_NUM_DW -1:0][ORAM_ADD_AW    -1:0] mtoo_add_add;
wire [ORAM_NUM_DW -1:0]                      otom_dat_vld = OTOM_DAT_VLD;
wire [ORAM_NUM_DW -1:0]                      otom_dat_lst = OTOM_DAT_LST;
reg  [ORAM_NUM_DW -1:0]                      otom_dat_rdy;
wire [ORAM_NUM_DW -1:0][ORAM_DAT_DW    -1:0] otom_dat_dat = OTOM_DAT_DAT;
assign MTOO_ADD_VLD = mtoo_add_vld;
assign MTOO_ADD_LST = mtoo_add_lst;
assign MTOO_ADD_ADD = mtoo_add_add;
assign OTOM_DAT_RDY = otom_dat_rdy;

wire [ORAM_NUM_DW -1:0] mtoo_dat_ena = mtoo_dat_vld & mtoo_dat_rdy;
wire [ORAM_NUM_DW -1:0] mtoo_add_ena = mtoo_add_vld & mtoo_add_rdy;
wire [ORAM_NUM_DW -1:0] otom_dat_ena = otom_dat_vld & otom_dat_rdy;
//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================
wire [ARAM_NUM_AW -1:0] cfg_aram_sel_tmp, cfg_aram_sel;
wire [WRAM_NUM_AW -1:0] cfg_wram_sel_tmp, cfg_wram_sel;
wire [ORAM_NUM_AW -1:0] cfg_oram_sel_tmp, cfg_oram_sel;
reg  [BANK_NUM_DW -1:0][BANK_NUM_AW -1:0] cfg_from_idx;
CPM_SEL #( ARAM_NUM_DW, ARAM_NUM_AW ) ARAM_IDX_SEL_U (CFG_ARAM_IDX, cfg_aram_sel_tmp);
CPM_SEL #( WRAM_NUM_DW, WRAM_NUM_AW ) WRAM_IDX_SEL_U (CFG_WRAM_IDX, cfg_wram_sel_tmp);
CPM_SEL #( ORAM_NUM_DW, ORAM_NUM_AW ) ORAM_IDX_SEL_U (CFG_ORAM_IDX, cfg_oram_sel_tmp);

CPM_REG_E #( ARAM_NUM_AW ) ARAM_IDX_SEL_REG ( clk, rst_n, cfg_info_ena, cfg_aram_sel_tmp, cfg_aram_sel);
CPM_REG_E #( WRAM_NUM_AW ) WRAM_IDX_SEL_REG ( clk, rst_n, cfg_info_ena, cfg_wram_sel_tmp, cfg_wram_sel);
CPM_REG_E #( ORAM_NUM_AW ) ORAM_IDX_SEL_REG ( clk, rst_n, cfg_info_ena, cfg_oram_sel_tmp, cfg_oram_sel);

//MOVE_BUF
reg  [BANK_NUM_DW -1:0] move_buf_wen;
reg  [BANK_NUM_DW -1:0] move_buf_ren;
wire [BANK_NUM_DW -1:0] move_buf_empty;
wire [BANK_NUM_DW -1:0] move_buf_full;
reg  [BANK_NUM_DW -1:0][MOVE_BUF_DW -1:0] move_buf_din;
wire [BANK_NUM_DW -1:0][MOVE_BUF_DW -1:0] move_buf_out;
reg  [BANK_NUM_DW -1:0][MOVE_BUF_DW -1:0] move_buf_dat;
reg  [BANK_NUM_DW -1:0][MOVE_BUF_DW -1:0] move_buf_lst;
wire [BANK_NUM_DW -1:0][MOVE_BUF_AW   :0] move_buf_cnt;

CPM_FIFO #( .DATA_WIDTH( MOVE_BUF_DW ), .ADDR_WIDTH( MOVE_BUF_AW ) ) MOVE_FIFO_U[BANK_NUM_DW -1:0] ( clk, rst_n, 1'd0, move_buf_wen, move_buf_ren, move_buf_din, move_buf_out, move_buf_empty, move_buf_full, move_buf_cnt);

reg  [BANK_NUM_DW -1:0] from_cnt_add_ena;
reg  [BANK_NUM_DW -1:0] dest_cnt_add_ena;
wire [BANK_NUM_DW -1:0][WRAM_ADD_AW -1:0] from_cnt_num;
wire [BANK_NUM_DW -1:0][WRAM_ADD_AW -1:0] dest_cnt_num;
reg  [BANK_NUM_DW -1:0][WRAM_ADD_AW -1:0] from_cnt_add;
reg  [BANK_NUM_DW -1:0][WRAM_ADD_AW -1:0] from_add_add;
reg  [BANK_NUM_DW -1:0][WRAM_ADD_AW -1:0] dest_cnt_add;
reg  [BANK_NUM_DW -1:0][CONV_OCH_DW -1:0] dest_cnt_och;
reg  [BANK_NUM_DW -1:0][CONV_LEN_DW -1:0] dest_cnt_pix;
reg  [BANK_NUM_DW -1:0][OMUX_NUM_AW -1:0] dest_cnt_mux;
reg  [BANK_NUM_DW -1:0] dest_lst_och, dest_lst_pix, dest_lst_mux;
reg  [BANK_NUM_DW -1:0] from_cnt_add_last;
reg  [BANK_NUM_DW -1:0] from_cnt_add_done;
CPM_CNT_C #( WRAM_ADD_AW ) FROM_CNT_NUM_U[BANK_NUM_DW -1:0] ( clk, rst_n, cfg_info_ena, from_cnt_add_ena, from_cnt_num );
CPM_CNT_C #( WRAM_ADD_AW ) DEST_CNT_NUM_U[BANK_NUM_DW -1:0] ( clk, rst_n, cfg_info_ena, dest_cnt_add_ena, dest_cnt_num );

reg  [BANK_NUM_DW -1:0][OMUX_NUM_AW -1:0] mtoo_mux_cnt;
//FLAG
reg  [BANK_NUM_DW -1:0][FRAM_DAT_DW -1:0] flag_dat_dat;
reg  [BANK_NUM_DW -1:0][FRAM_DAT_DW -1:0] flag_buf_dat;
reg  [BANK_NUM_DW -1:0][WRAM_ADD_AW -1:0] mtoo_och_cnt, mtof_och_cnt;
reg  [BANK_NUM_DW -1:0][WRAM_ADD_AW -1:0] mtoo_pix_cnt, mtof_pix_cnt;
reg  [BANK_NUM_DW -1:0][WRAM_ADD_AW -1:0] mtoo_add_cnt, mtof_add_cnt, mtoa_add_cnt;
reg  [BANK_NUM_DW -1:0][BANK_NUM_AW -1:0] otoa_spt_idx;

reg  [BANK_NUM_DW -1:0] flag_dat_vld;
//STAT
reg  [BANK_NUM_DW -1:0] wsta_dat_nzd;
reg                     wsta_dat_vld;
wire                    wsta_dat_rdy;
reg                     wsta_dat_lst;
reg  [BANK_NUM_DW -1:0][STAT_CNT_DW -1:0] wsta_dat_dat, wsta_dat_dat_reg;
reg  [BANK_NUM_DW -1:0][STAT_INF_DW -1:0] wsta_dat_inf;

wire [BANK_NUM_DW -1:0]                                     topk_dat_vld;
wire [BANK_NUM_DW -1:0][STAT_NUM_DW -1:0][STAT_CNT_DW -1:0] topk_dat_dat;
wire [BANK_NUM_DW -1:0][STAT_NUM_DW -1:0][STAT_INF_DW -1:0] topk_dat_inf;

wire [STAT_NUM_AW -1:0] topk_dat_cnt;
wire [CONV_WEI_DW -1:0] topk_wei_cnt;
wire [STAT_NUM_AW -1:0] topk_och_cnt;

wire topk_dat_cnt_clr = cfg_info_ena;
wire topk_wei_cnt_clr = cfg_info_ena || (topk_wei_cnt==cfg_conv_wei &mtos_dat_ena);
wire topk_och_cnt_clr = cfg_info_ena;
wire topk_dat_cnt_ena =&mtos_dat_ena;
wire topk_wei_cnt_ena =&mtos_dat_ena;
wire topk_och_cnt_ena =&mtos_dat_ena && topk_wei_cnt==cfg_conv_wei;
CPM_CNT_C #( STAT_NUM_AW ) TOPK_DAT_CNT_U ( clk, rst_n, topk_dat_cnt_clr, topk_dat_cnt_ena, topk_dat_cnt);
CPM_CNT_C #( CONV_WEI_DW ) TOPK_WEI_CNT_U ( clk, rst_n, topk_wei_cnt_clr, topk_wei_cnt_ena, topk_wei_cnt);
CPM_CNT_C #( STAT_NUM_AW ) TOPK_OCH_CNT_U ( clk, rst_n, topk_och_cnt_clr, topk_och_cnt_ena, topk_och_cnt);
//=====================================================================================================================
// IO Logic Design :
//=====================================================================================================================
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_info_cmd <= 'd0;
        cfg_aram_idx <= 'd0;
        cfg_wram_idx <= 'd0;
        cfg_oram_idx <= 'd0;
        cfg_omux_idx <= 'd0;
        cfg_aram_add <= 'd0;
        cfg_wram_add <= 'd0;
        cfg_oram_add <= 'd0;
        cfg_aram_len <= 'd0;
        cfg_wram_len <= 'd0;
        cfg_oram_len <= 'd0;
        cfg_conv_len <= 'd0;
        cfg_conv_och <= 'd0;
        cfg_conv_wei <= 'd0;
        cfg_flag_ena <= 'd0;
        cfg_wsta_ena <= 'd0;
        cfg_splt_ena <= 'd0;
        cfg_splt_len <= 'd0;
    end else if( cfg_info_ena )begin
        cfg_info_cmd <= CFG_INFO_CMD;
        cfg_aram_idx <= CFG_ARAM_IDX;
        cfg_wram_idx <= CFG_WRAM_IDX;
        cfg_oram_idx <= CFG_ORAM_IDX;
        cfg_omux_idx <= CFG_OMUX_IDX;
        cfg_aram_add <= CFG_ARAM_ADD;
        cfg_wram_add <= CFG_WRAM_ADD;
        cfg_oram_add <= CFG_ORAM_ADD;
        cfg_aram_len <= CFG_ARAM_LEN;
        cfg_wram_len <= CFG_WRAM_LEN;
        cfg_oram_len <= CFG_ORAM_LEN;
        cfg_conv_len <= CFG_CONV_LEN;
        cfg_conv_och <= CFG_CONV_OCH;
        cfg_conv_wei <= CFG_CONV_WEI;
        cfg_flag_ena <= CFG_FLAG_ENA;
        cfg_wsta_ena <= CFG_WSTA_ENA;
        cfg_splt_ena <= CFG_SPLT_ENA;
        cfg_splt_len <= CFG_SPLT_LEN;
    end
end

//read xram
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cal_aram_ena <= 'd0;
        cal_wram_ena <= 'd0;
        cal_oram_ena <= 'd0;
    end else if( cfg_info_ena )begin
        cal_aram_ena <= |CFG_ARAM_IDX && (CFG_INFO_CMD==MOVE_ATOW || CFG_INFO_CMD==MOVE_READ);
        cal_wram_ena <= |CFG_WRAM_IDX && (CFG_INFO_CMD==MOVE_WTOA || CFG_INFO_CMD==MOVE_READ);
        cal_oram_ena <= |CFG_ORAM_IDX && (CFG_INFO_CMD==MOVE_OTOA || CFG_INFO_CMD==MOVE_READ || CFG_INFO_CMD==MOVE_STAT);
    end
end

always @ ( * )begin
    cal_omux_num_tmp = &CFG_OMUX_IDX ? 'd3 : 'd0;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        cal_omux_num <= 'd0;
    else if( cfg_info_ena )
        cal_omux_num <= cal_omux_num_tmp;
end

always @ ( * )begin
    cfg_info_rdy = move_idle;
end

//stat
generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            mtos_dat_vld[gen_i] = topk_dat_vld[gen_i] && ~wsta_lst_done[gen_i];
            mtos_dat_lst[gen_i] = topk_dat_cnt==(STAT_NUM_DW-1);
            mtos_dat_add[gen_i] = topk_dat_cnt;
            mtos_dat_dat[gen_i] ={topk_wei_cnt, topk_dat_inf[gen_i][topk_och_cnt]};
        end
    end
endgenerate


generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                cfg_from_idx[gen_i] <= 'd0;
            else if( cfg_info_ena )begin
                case( CFG_INFO_CMD )
                    MOVE_ATOW: cfg_from_idx[gen_i] <= &CFG_WRAM_IDX ? gen_i : cfg_wram_sel_tmp;
                    MOVE_READ: cfg_from_idx[gen_i] <= |CFG_WRAM_IDX ? cfg_wram_sel_tmp : (|CFG_ARAM_IDX ? cfg_aram_sel_tmp : cfg_oram_sel_tmp);
                      default: cfg_from_idx[gen_i] <= &CFG_ARAM_IDX ? gen_i : cfg_aram_sel_tmp;
                endcase
            end
        end
    end
endgenerate

always @ ( * )begin
    mtoc_dat_vld = move_read && ~move_buf_empty[cfg_from_idx[0]];
    mtoc_dat_lst = move_read && ~move_buf_empty[cfg_from_idx[0]] && move_buf_lst[cfg_from_idx[0]];
    mtoc_dat_dat = move_buf_dat[cfg_from_idx[0]];
end

always @ ( * )begin
    case( move_cs )
        MOVE_ITOA: itom_dat_rdy = mtoa_dat_rdy;
        MOVE_ITOW: itom_dat_rdy = mtow_dat_rdy;
          default: itom_dat_rdy = 'd0;
    endcase
end

//write_ram
generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            mtof_dat_vld[gen_i] = move_stat && cfg_flag_ena && ~move_buf_empty[otoa_spt_idx[cfg_from_idx[gen_i]]] && &mtof_och_cnt[gen_i][0 +:BANK_NUM_AW];
            mtof_dat_lst[gen_i] = move_buf_lst[cfg_from_idx[gen_i]];
            mtof_dat_dat[gen_i] = flag_dat_dat[cfg_from_idx[gen_i]];
            mtof_dat_add[gen_i] = mtof_add_cnt[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            mtoo_dat_vld[gen_i] = move_itoo && itom_dat_vld && cfg_oram_idx[gen_i];
            mtoo_dat_lst[gen_i] = itom_dat_lst;
            mtoo_dat_dat[gen_i] = itom_dat_dat;
            mtoo_dat_add[gen_i] = dest_cnt_add[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            mtoa_dat_vld[gen_i] = move_itoa ? itom_dat_vld && cfg_aram_idx[gen_i] : cfg_aram_idx[gen_i] && ~move_buf_empty[otoa_spt_idx[cfg_from_idx[gen_i]]] && (move_wtoa || move_otoa);
            mtoa_dat_lst[gen_i] = move_itoa ? itom_dat_lst : move_buf_lst[otoa_spt_idx[cfg_from_idx[gen_i]]];
            mtoa_dat_dat[gen_i] = move_itoa ? itom_dat_dat : move_buf_dat[otoa_spt_idx[cfg_from_idx[gen_i]]];
            mtoa_dat_add[gen_i] = dest_cnt_add[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            mtow_dat_vld[gen_i] = move_itow ? itom_dat_vld && cfg_wram_idx[gen_i] :  cfg_wram_idx[gen_i] && ~move_buf_empty[cfg_from_idx[gen_i]] && move_atow;
            mtow_dat_lst[gen_i] = move_itow ? itom_dat_lst : move_buf_lst[cfg_from_idx[gen_i]];
            mtow_dat_dat[gen_i] = move_itow ? itom_dat_dat : move_buf_dat[cfg_from_idx[gen_i]];
            mtow_dat_add[gen_i] = dest_cnt_add[gen_i];
        end
    end
endgenerate

//read_ram
generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            mtoa_add_vld[gen_i] = cal_aram_ena && ~from_cnt_add_done[gen_i] && move_buf_cnt[gen_i]<2;
            mtoa_add_lst[gen_i] = from_cnt_add_last[gen_i];
            mtoa_add_add[gen_i] = from_add_add[gen_i];
            atom_dat_rdy[gen_i] = cal_aram_ena && ~move_buf_full[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            mtow_add_vld[gen_i] = cal_wram_ena && ~from_cnt_add_done[gen_i] && move_buf_cnt[gen_i]<2;
            mtow_add_lst[gen_i] = from_cnt_add_last[gen_i];
            mtow_add_add[gen_i] = from_add_add[gen_i];
            wtom_dat_rdy[gen_i] = cal_wram_ena && ~move_buf_full[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            mtoo_add_vld[gen_i] = cal_oram_ena && ~from_cnt_add_done[gen_i] && move_buf_cnt[gen_i]<2;
            mtoo_add_lst[gen_i] = from_cnt_add_last[gen_i];
            mtoo_add_add[gen_i] = move_otoa || (move_read && cal_oram_ena) ? from_add_add[gen_i] +mtoo_mux_cnt[gen_i]*OMUX_ADD_DW : mtoo_add_cnt[gen_i] +mtoo_mux_cnt[gen_i]*OMUX_ADD_DW;
            otom_dat_rdy[gen_i] = cal_oram_ena && ~move_buf_full[gen_i];
        end
    end
endgenerate

//=====================================================================================================================
// Logic Design :
//=====================================================================================================================
//read
generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                from_cnt_add_done[gen_i] <= 'd1;
            else if( cfg_info_ena )begin
                case( CFG_INFO_CMD )
                MOVE_OTOA: from_cnt_add_done[gen_i] <= ~CFG_ORAM_IDX[gen_i];
                MOVE_ATOW: from_cnt_add_done[gen_i] <= ~CFG_ARAM_IDX[gen_i];
                MOVE_WTOA: from_cnt_add_done[gen_i] <= ~CFG_WRAM_IDX[gen_i];
                MOVE_STAT: from_cnt_add_done[gen_i] <= ~CFG_ORAM_IDX[gen_i];
                MOVE_READ: from_cnt_add_done[gen_i] <=~(CFG_ARAM_IDX[gen_i] || CFG_WRAM_IDX[gen_i] || CFG_ORAM_IDX[gen_i]);
                  default: from_cnt_add_done[gen_i] <= 'd1;
                endcase
            end
            else if( from_cnt_add_ena[gen_i] && from_cnt_add_last[gen_i] )begin
                case( move_cs )
                MOVE_OTOA: from_cnt_add_done[gen_i] <= 'd1;//mtoo_add_ena[gen_i];
                MOVE_ATOW: from_cnt_add_done[gen_i] <= 'd1;//mtoa_add_ena[gen_i];
                MOVE_WTOA: from_cnt_add_done[gen_i] <= 'd1;//mtow_add_ena[gen_i];
                MOVE_STAT: from_cnt_add_done[gen_i] <= 'd1;//mtoo_add_ena[gen_i];
                MOVE_READ: from_cnt_add_done[gen_i] <= 'd1;
                  default: from_cnt_add_done[gen_i] <= 'd1;
                endcase
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                atom_lst_done[gen_i] <= 'd1;
            else if( cfg_info_ena )
                atom_lst_done[gen_i] <= ~( (CFG_INFO_CMD==MOVE_ATOW ) && CFG_ARAM_IDX[gen_i]);
            else if( atom_dat_ena[gen_i] & atom_dat_lst[gen_i] )
                atom_lst_done[gen_i] <= 'd1;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                wtom_lst_done[gen_i] <= 'd1;
            else if( cfg_info_ena )
                wtom_lst_done[gen_i] <= ~( (CFG_INFO_CMD==MOVE_WTOA ) && CFG_WRAM_IDX[gen_i]);
            else if( wtom_dat_ena[gen_i] & wtom_dat_lst[gen_i] )
                wtom_lst_done[gen_i] <= 'd1;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                otom_lst_done[gen_i] <= 'd1;
            else if( cfg_info_ena )
                otom_lst_done[gen_i] <= ~( (CFG_INFO_CMD==MOVE_OTOA || CFG_INFO_CMD==MOVE_STAT) && CFG_ORAM_IDX[gen_i]);
            else if( otom_dat_ena[gen_i] & otom_dat_lst[gen_i] )
                otom_lst_done[gen_i] <= 'd1;
        end
    end
endgenerate

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        read_lst_done <= 'd1;
    else if( cfg_info_ena && CFG_INFO_CMD==MOVE_READ )
        read_lst_done <= 'd0;
    else if( mtoc_dat_ena && mtoc_dat_lst )
        read_lst_done <= 'd1;
end
//write
generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                mtoa_lst_done[gen_i] <= 'd1;
            else if( cfg_info_ena )
                mtoa_lst_done[gen_i] <= ~( (CFG_INFO_CMD==MOVE_WTOA || CFG_INFO_CMD==MOVE_OTOA || CFG_INFO_CMD==MOVE_ITOA) && CFG_ARAM_IDX[gen_i]);
            else if( mtoa_dat_ena[gen_i] && mtoa_dat_lst[gen_i] )
                mtoa_lst_done[gen_i] <= 'd1;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                mtow_lst_done[gen_i] <= 'd1;
            else if( cfg_info_ena )
                mtow_lst_done[gen_i] <= ~( (CFG_INFO_CMD==MOVE_ATOW || CFG_INFO_CMD==MOVE_ITOW) && CFG_WRAM_IDX[gen_i]);
            else if( mtow_dat_ena[gen_i] && mtow_dat_lst[gen_i] )
                mtow_lst_done[gen_i] <= 'd1;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                mtof_lst_done[gen_i] <= 'd1;
            else if( cfg_info_ena && CFG_INFO_CMD==MOVE_STAT )
                mtof_lst_done[gen_i] <= ~CFG_FLAG_ENA;
            else if( mtof_dat_ena[gen_i] && mtof_dat_lst[gen_i] )
                mtof_lst_done[gen_i] <= 'd1;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                wsta_lst_done[gen_i] <= 'd1;
            else if( cfg_info_ena && (CFG_INFO_CMD==MOVE_OTOA || CFG_INFO_CMD==MOVE_STAT) )
                wsta_lst_done[gen_i] <= ~CFG_WSTA_ENA;
            else if( mtos_dat_ena[gen_i] && mtos_dat_lst[gen_i] )
                wsta_lst_done[gen_i] <= 'd1;
        end
    end
endgenerate
//buf
generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            case( move_cs )
                MOVE_OTOA: move_buf_wen[gen_i] = otom_dat_ena[gen_i];
                MOVE_ATOW: move_buf_wen[gen_i] = atom_dat_ena[gen_i];
                MOVE_WTOA: move_buf_wen[gen_i] = wtom_dat_ena[gen_i];
                MOVE_READ: move_buf_wen[gen_i] = cal_aram_ena ? atom_dat_ena[gen_i] : cal_wram_ena ? wtom_dat_ena[gen_i] : otom_dat_ena[gen_i];
                MOVE_STAT: move_buf_wen[gen_i] = otom_dat_ena[gen_i];
                  default: move_buf_wen[gen_i] = 'd0;
            endcase
        end
        always @ ( * )begin
            case( move_cs )
                MOVE_OTOA: move_buf_din[gen_i] = {otom_dat_lst[gen_i], otom_dat_dat[gen_i]};
                MOVE_ATOW: move_buf_din[gen_i] = {atom_dat_lst[gen_i], atom_dat_dat[gen_i]};
                MOVE_WTOA: move_buf_din[gen_i] = {wtom_dat_lst[gen_i], wtom_dat_dat[gen_i]};
                MOVE_READ: move_buf_din[gen_i] = cal_aram_ena ? {atom_dat_lst[gen_i], atom_dat_dat[gen_i]} : cal_wram_ena ?{wtom_dat_lst[gen_i], wtom_dat_dat[gen_i]} : {otom_dat_lst[gen_i], otom_dat_dat[gen_i]};
                MOVE_STAT: move_buf_din[gen_i] = {otom_dat_lst[gen_i], otom_dat_dat[gen_i]};
                  default: move_buf_din[gen_i] = 'd0;
            endcase
        end
        always @ ( * )begin
            case( move_cs )
                MOVE_OTOA: move_buf_ren[gen_i] = mtoa_dat_ena[gen_i];
                MOVE_ATOW: move_buf_ren[gen_i] = mtow_dat_ena[gen_i];
                MOVE_WTOA: move_buf_ren[gen_i] = mtoa_dat_ena[gen_i];
                MOVE_READ: move_buf_ren[gen_i] = mtoc_dat_ena;
                MOVE_STAT: move_buf_ren[gen_i] = cfg_flag_ena ? (mtof_dat_rdy[gen_i] && &mtof_och_cnt[0 +:BANK_NUM_AW]) || ~&mtof_och_cnt[0 +:BANK_NUM_AW]: 'd1;
                  default: move_buf_ren[gen_i] = 'd0;
            endcase
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            move_buf_dat[gen_i] = move_buf_out[gen_i][0 +:MOVE_DAT_DW];
            move_buf_lst[gen_i] = move_buf_out[gen_i][MOVE_BUF_DW  -1];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            case( move_cs )
                MOVE_OTOA: from_cnt_add_ena[gen_i] = mtoo_add_ena[gen_i];
                MOVE_ATOW: from_cnt_add_ena[gen_i] = mtoa_add_ena[gen_i];
                MOVE_WTOA: from_cnt_add_ena[gen_i] = mtow_add_ena[gen_i];
                MOVE_READ: from_cnt_add_ena[gen_i] = |cfg_aram_idx ? mtoa_add_ena[gen_i] : |cfg_wram_idx ? mtow_add_ena[gen_i] : mtoo_add_ena[gen_i];
                MOVE_STAT: from_cnt_add_ena[gen_i] = mtoo_add_ena[gen_i];
                  default: from_cnt_add_ena[gen_i] = 'd0;
            endcase
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            case( move_cs )
                MOVE_OTOA: from_cnt_add_last[gen_i] = from_cnt_add[gen_i]==cfg_oram_len && mtoo_mux_cnt[gen_i]==cal_omux_num;
                MOVE_ATOW: from_cnt_add_last[gen_i] = mtow_dat_ena[gen_i]==cfg_aram_len;
                MOVE_WTOA: from_cnt_add_last[gen_i] = mtoa_dat_ena[gen_i]==cfg_wram_len;
                MOVE_READ: from_cnt_add_last[gen_i] = |cfg_aram_idx ? from_cnt_add[gen_i]==cfg_aram_len : |cfg_wram_idx ? from_cnt_add[gen_i]==cfg_wram_len : from_cnt_add[gen_i]==cfg_oram_len;
                MOVE_STAT: from_cnt_add_last[gen_i] = from_cnt_add[gen_i]==cfg_oram_len;
                  default: from_cnt_add_last[gen_i] = 'd0;
            endcase
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            case( move_cs )
                MOVE_ITOA: dest_cnt_add_ena[gen_i] = mtoa_dat_ena[gen_i];
                MOVE_ITOW: dest_cnt_add_ena[gen_i] = mtow_dat_ena[gen_i];
                MOVE_OTOA: dest_cnt_add_ena[gen_i] = mtoa_dat_ena[gen_i];
                MOVE_ATOW: dest_cnt_add_ena[gen_i] = mtow_dat_ena[gen_i];
                MOVE_WTOA: dest_cnt_add_ena[gen_i] = mtoa_dat_ena[gen_i];
                  default: dest_cnt_add_ena[gen_i] = 'd0;
            endcase
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                from_add_add[gen_i] <= 'd0;
            else if( cfg_info_ena )begin
                case( CFG_INFO_CMD )
                    MOVE_OTOA: from_add_add[gen_i] <= CFG_ORAM_ADD;
                    MOVE_ATOW: from_add_add[gen_i] <= CFG_ARAM_ADD;
                    MOVE_WTOA: from_add_add[gen_i] <= CFG_WRAM_ADD;
                    MOVE_READ: from_add_add[gen_i] <=|CFG_ARAM_IDX ? CFG_ARAM_ADD : |CFG_WRAM_IDX ? CFG_WRAM_ADD : CFG_ORAM_ADD;
                    MOVE_STAT: from_add_add[gen_i] <= CFG_ORAM_ADD;
                      default: from_add_add[gen_i] <= 'd0;
                endcase
            end
            else if( from_cnt_add_ena && from_add_add[gen_i]==cfg_oram_len && move_otoa )
                from_add_add[gen_i] <= cfg_oram_add;
            else if( from_cnt_add_ena )
                from_add_add[gen_i] <= from_add_add[gen_i] +'d1;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                from_cnt_add[gen_i] <= 'd0;
            else if( cfg_info_ena )begin
                from_cnt_add[gen_i] <= 'd0;
            end
            else if( from_cnt_add_ena && from_cnt_add[gen_i]==cfg_oram_len && move_otoa )
                from_cnt_add[gen_i] <= 'd0;
            else if( from_cnt_add_ena )
                from_cnt_add[gen_i] <= from_cnt_add[gen_i] +'d1;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                dest_cnt_add[gen_i] <= 'd0;
            else if( cfg_info_ena )
                dest_cnt_add[gen_i] <= (CFG_INFO_CMD==MOVE_ATOW || CFG_INFO_CMD==MOVE_ITOW) ? CFG_WRAM_ADD : CFG_ARAM_ADD;
            else if( dest_cnt_add_ena )begin
                if( move_otoa )begin
                    if( dest_cnt_add_ena && dest_lst_pix[gen_i] && dest_lst_och[gen_i] )//NEXT OMUX
                        dest_cnt_add[gen_i] <= cfg_aram_add +dest_cnt_mux[gen_i]*OMUX_ADD_DW +OMUX_ADD_DW;
                    else
                        dest_cnt_add[gen_i] <= dest_cnt_add[gen_i] +'d1;
                end else
                    dest_cnt_add[gen_i] <= dest_cnt_add[gen_i] +'d1;
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin//for OTOA-WSTA
        always @ ( * )begin
            dest_lst_och[gen_i] = dest_cnt_och[gen_i]==cfg_conv_och[CONV_OCH_DW -1:OMUX_NUM_AW];
            dest_lst_pix[gen_i] = dest_cnt_pix[gen_i]==cfg_conv_len;
            dest_lst_mux[gen_i] =&dest_cnt_mux[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin//for OTOA-WSTA
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                dest_cnt_och[gen_i] <= 'd0;
            else if( cfg_info_ena )
                dest_cnt_och[gen_i] <= 'd0;
            else if( dest_cnt_add_ena && dest_lst_pix[gen_i] && dest_lst_och[gen_i] )//NEXT OMUX
                dest_cnt_och[gen_i] <= 'd0;
            else if( dest_cnt_add_ena && dest_lst_pix[gen_i] )
                dest_cnt_och[gen_i] <= dest_cnt_och[gen_i] +'d1;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin//for OTOA-WSTA
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                dest_cnt_pix[gen_i] <= 'd0;
            else if( cfg_info_ena )
                dest_cnt_pix[gen_i] <= 'd0;
            else if( dest_cnt_add_ena && dest_lst_pix[gen_i] )
                dest_cnt_pix[gen_i] <= 'd0;
            else if( dest_cnt_add_ena )
                dest_cnt_pix[gen_i] <= dest_cnt_pix[gen_i] +'d1;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin//for OTOA-WSTA
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                dest_cnt_mux[gen_i] <= 'd0;
            else if( cfg_info_ena )
                dest_cnt_mux[gen_i] <= 'd0;
            else if( dest_cnt_add_ena && dest_lst_pix[gen_i] && dest_lst_och[gen_i] )//NEXT OMUX
                dest_cnt_mux[gen_i] <= dest_cnt_mux[gen_i] +'d1;
        end
    end
endgenerate
//flag
generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            flag_dat_dat[gen_i] = |move_buf_dat[gen_i] ? flag_buf_dat[gen_i] | ('d1<<mtof_och_cnt[gen_i][0 +:2]) :  flag_buf_dat[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                flag_buf_dat[gen_i] <= 'd0;
            else if( cfg_info_ena )
                flag_buf_dat[gen_i] <= 'd0;
            else if( flag_dat_vld[gen_i] && &mtof_och_cnt[gen_i][0 +:2] )
                flag_buf_dat[gen_i] <= 'd0;
            else if( flag_dat_vld[gen_i] )
                flag_buf_dat[gen_i] <= flag_dat_dat[gen_i];
        end
    end
endgenerate

//otom_flag
generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                mtoo_mux_cnt[gen_i] <= 'd0;
            else if( cfg_info_ena )
                mtoo_mux_cnt[gen_i] <= 'd0;
            else if( move_otoa && mtoo_add_ena[gen_i] && from_cnt_add[gen_i]==cfg_oram_len )
                mtoo_mux_cnt[gen_i] <= mtoo_mux_cnt[gen_i] +'d1;
            else if( move_stat && mtoo_add_ena[gen_i] )
                mtoo_mux_cnt[gen_i] <= mtoo_mux_cnt[gen_i] +'d1;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                mtoo_och_cnt[gen_i] <= 'd0;
            else if( cfg_info_ena )
                mtoo_och_cnt[gen_i] <= 'd0;
            else if( move_stat && mtoo_add_ena[gen_i] && mtoo_och_cnt[gen_i]==cfg_conv_och )//for stat
                mtoo_och_cnt[gen_i] <= 'd0;
            else if( move_stat && mtoo_add_ena[gen_i] )
                mtoo_och_cnt[gen_i] <= mtoo_och_cnt[gen_i] +'d1;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                mtoo_pix_cnt[gen_i] <= 'd0;
            else if( cfg_info_ena )
                mtoo_pix_cnt[gen_i] <= 'd0;
            else if( move_stat && mtoo_add_ena[gen_i] && mtoo_pix_cnt[gen_i]==cfg_conv_len )//for stat
                mtoo_pix_cnt[gen_i] <= 'd0;
            else if( move_stat && mtoo_add_ena[gen_i] && mtoo_och_cnt[gen_i]==cfg_conv_och )
                mtoo_pix_cnt[gen_i] <= mtoo_pix_cnt[gen_i] +'d1;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                mtoo_add_cnt[gen_i] <= 'd0;
            else if( cfg_info_ena )
                mtoo_add_cnt[gen_i] <= cfg_oram_add;
            else if( move_stat && mtoo_add_ena[gen_i] && mtoo_och_cnt[gen_i]==cfg_conv_och )//channel first: for flag/stat
                mtoo_add_cnt[gen_i] <= cfg_oram_add +mtoo_pix_cnt[gen_i] +'d1;
            else if( move_stat && mtoo_add_ena[gen_i] && &mtoo_mux_cnt[gen_i] )//channel first: for flag/stat
                mtoo_add_cnt[gen_i] <= mtoo_add_cnt[gen_i] +cfg_conv_len +'d1;
        end
    end
endgenerate

//mtof_flag
generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                mtof_och_cnt[gen_i] <= 'd0;
            else if( cfg_info_ena )
                mtof_och_cnt[gen_i] <= 'd0;
            else if( flag_dat_vld[gen_i] && mtof_och_cnt[gen_i]==cfg_conv_och )
                mtof_och_cnt[gen_i] <= 'd0;
            else if( flag_dat_vld[gen_i] )
                mtof_och_cnt[gen_i] <= mtof_och_cnt[gen_i] +'d1;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                mtof_pix_cnt[gen_i] <= 'd0;
            else if( cfg_info_ena )
                mtof_pix_cnt[gen_i] <= 'd0;
            else if( mtof_dat_ena[gen_i] && mtof_och_cnt[gen_i]==cfg_conv_och && mtof_pix_cnt[gen_i]==cfg_conv_len )
                mtof_pix_cnt[gen_i] <= 'd0;
            else if( mtof_dat_ena[gen_i] && mtof_och_cnt[gen_i]==cfg_conv_och )
                mtof_pix_cnt[gen_i] <= mtof_pix_cnt[gen_i] +'d1;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                mtof_add_cnt[gen_i] <= 'd0;
            else if( cfg_info_ena )
                mtof_add_cnt[gen_i] <= cfg_oram_add;
            //else if( mtof_dat_ena[gen_i] && mtof_och_cnt[gen_i]==cfg_conv_och )//fram channel first
                //mtof_add_cnt[gen_i] <= cfg_oram_add +mtof_pix_cnt[gen_i] +'d1;
            else if( mtof_dat_ena[gen_i] )//fram channel first
                mtof_add_cnt[gen_i] <= mtof_add_cnt[gen_i] +'d1;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                mtoa_add_cnt[gen_i] <= 'd0;
            else if( cfg_info_ena )
                mtoa_add_cnt[gen_i] <= cfg_aram_add;
            //else if( mtoa_dat_ena[gen_i] && mtof_och_cnt[gen_i]==cfg_conv_och )
                //mtoa_add_cnt[gen_i] <= cfg_aram_add +mtof_pix_cnt[gen_i];
            else if( mtoa_dat_ena[gen_i] )
                mtoa_add_cnt[gen_i] <= mtoa_add_cnt[gen_i] +cfg_conv_len;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                otoa_spt_idx[gen_i] <= 'd0;
            else if( cfg_info_ena )
                otoa_spt_idx[gen_i] <= gen_i;
            else if( cfg_splt_ena && mtoa_dat_ena[gen_i] && (mtof_och_cnt[gen_i]==cfg_conv_och) && (mtof_pix_cnt[gen_i]==cfg_splt_len) )begin
                if( gen_i==0 )
                    otoa_spt_idx[gen_i] <= otoa_spt_idx[BANK_NUM_DW-1];
                else
                    otoa_spt_idx[gen_i] <= otoa_spt_idx[gen_i-1];                
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            flag_dat_vld[gen_i] = move_buf_ren[gen_i] && ~move_buf_empty[gen_i];
        end
    end
endgenerate

//STAT
generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            wsta_dat_nzd[gen_i] = cfg_oram_idx[gen_i] && |move_buf_dat[gen_i];
            wsta_dat_inf[gen_i] = dest_cnt_mux[cfg_from_idx[gen_i]] +dest_cnt_och[cfg_from_idx[gen_i]]*OMUX_NUM_DW;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            wsta_dat_dat[gen_i] = wsta_dat_dat_reg[gen_i] + wsta_dat_nzd[gen_i];
        end
    end
endgenerate

always @ ( * )begin
    wsta_dat_vld = ~&wsta_lst_done && |dest_lst_pix && dest_cnt_add_ena;
    wsta_dat_lst = |dest_lst_och && |dest_lst_pix && |dest_lst_mux;
end

generate
    for( gen_i=0 ; gen_i < BANK_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                wsta_dat_dat_reg[gen_i] <= 'd0;
            else if( cfg_info_ena )
                wsta_dat_dat_reg[gen_i] <= 'd0;
            else if( ~&wsta_lst_done && dest_cnt_add_ena && wsta_dat_vld )
                wsta_dat_dat_reg[gen_i] <= 'd0;
            else if( ~&wsta_lst_done && dest_cnt_add_ena )
                wsta_dat_dat_reg[gen_i] <= wsta_dat_dat_reg[gen_i] +wsta_dat_nzd[gen_i];
        end
    end
endgenerate
//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================
CPM_TOP_K #(
    .DATA_DW              ( STAT_CNT_DW      ),
    .INFO_DW              ( STAT_INF_DW      ),
    .SORT_DW              ( STAT_NUM_DW      )
) CPM_TOP_K_U[BANK_NUM_DW -1:0] (
    .clk                  ( clk              ),
    .rst_n                ( rst_n            ),

    .clear                ( move_idle        ),

    .SORT_DAT_VLD         ( wsta_dat_vld     ),
    .SORT_DAT_RDY         ( wsta_dat_rdy     ),
    .SORT_DAT_LST         ( wsta_dat_lst     ),
    .SORT_DAT_DAT         ( wsta_dat_dat     ),
    .SORT_DAT_INF         ( wsta_dat_inf     ),

    .TOPK_DAT_VLD         ( topk_dat_vld     ),
    .TOPK_DAT_DAT         ( topk_dat_dat     ),
    .TOPK_DAT_INF         ( topk_dat_inf     )
);

//=====================================================================================================================
// FSM :
//=====================================================================================================================
always @ ( * )begin
    case( move_cs )
        MOVE_IDLE: move_ns = cfg_info_ena? CFG_INFO_CMD : move_cs;
        MOVE_ITOA: move_ns = move_itoa_done ? MOVE_IDLE : move_cs;
        MOVE_ITOW: move_ns = move_itow_done ? MOVE_IDLE : move_cs;
        MOVE_OTOA: move_ns = move_otoa_done ? MOVE_IDLE : move_cs;
        MOVE_ATOW: move_ns = move_atow_done ? MOVE_IDLE : move_cs;
        MOVE_WTOA: move_ns = move_wtoa_done ? MOVE_IDLE : move_cs;
        MOVE_STAT: move_ns = move_stat_done ? MOVE_IDLE : move_cs;
        MOVE_READ: move_ns = move_read_done ? MOVE_IDLE : move_cs;
          default: move_ns = MOVE_IDLE;
    endcase
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        move_cs <= MOVE_IDLE;
    else
        move_cs <= move_ns;
end

`ifdef ASSERT_ON

property aram_rdy_check(dat_vld, dat_rdy);
@(posedge clk)
disable iff(rst_n!=1'b1)
    dat_vld |-> ( dat_rdy );
endproperty

generate
  for( gen_i=0 ; gen_i < ARAM_NUM_DW; gen_i = gen_i+1 )begin

    assert property ( aram_rdy_check(mtoa_dat_vld[gen_i], mtoa_dat_rdy[gen_i]) );

  end
endgenerate

generate
  for( gen_i=0 ; gen_i < FRAM_NUM_DW; gen_i = gen_i+1 )begin

    assert property ( aram_rdy_check(mtof_dat_vld[gen_i], mtof_dat_rdy[gen_i]) );

  end
endgenerate

generate
  for( gen_i=0 ; gen_i < WRAM_NUM_DW; gen_i = gen_i+1 )begin

    assert property ( aram_rdy_check(mtow_dat_vld[gen_i], mtow_dat_rdy[gen_i]) );

  end
endgenerate

generate
  for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin

    assert property ( aram_rdy_check(mtoo_dat_vld[gen_i], mtoo_dat_rdy[gen_i]) );

  end
endgenerate

`endif
endmodule
