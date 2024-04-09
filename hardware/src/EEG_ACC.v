//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description : PE ACC
//========================================================
module EEG_ACC #(
    parameter CHIP_DAT_DW = 8,
    parameter CHIP_OUT_DW = 8
  )(
    input                       clk,
    input                       rst_n,

    input                       CHIP_DAT_VLD,
    input                       CHIP_DAT_LST,
    output                      CHIP_DAT_RDY,
    input  [CHIP_DAT_DW   -1:0] CHIP_DAT_DAT,
    input                       CHIP_DAT_CMD,

    output                      CHIP_OUT_VLD,
    output                      CHIP_OUT_LST,
    input                       CHIP_OUT_RDY,
    output [CHIP_OUT_DW   -1:0] CHIP_OUT_DAT
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
localparam BANK_NUM_DW =  4;
localparam DATA_ACT_DW =  8;
localparam DATA_WEI_DW =  8;
localparam DATA_OUT_DW =  8;

localparam ARAM_NUM_DW = BANK_NUM_DW;
localparam WRAM_NUM_DW = BANK_NUM_DW;
localparam ORAM_NUM_DW = BANK_NUM_DW;
localparam FRAM_NUM_DW = BANK_NUM_DW;
localparam WBUF_NUM_DW = BANK_NUM_DW;
localparam ARAM_NUM_AW = $clog2(ARAM_NUM_DW);
localparam WRAM_NUM_AW = $clog2(WRAM_NUM_DW);
localparam ORAM_NUM_AW = $clog2(ORAM_NUM_DW);
localparam FRAM_NUM_AW = $clog2(FRAM_NUM_DW);
localparam WBUF_NUM_AW = $clog2(WBUF_NUM_DW);

localparam ARAM_ADD_AW = 12;//4k
localparam WRAM_ADD_AW = 13;//8k
localparam ORAM_ADD_AW = 10;//4x0.25k
localparam FRAM_ADD_AW = ARAM_ADD_AW;//4x1k

localparam MOVE_DAT_DW = CHIP_DAT_DW;
localparam ARAM_DAT_DW = DATA_ACT_DW;
localparam WRAM_DAT_DW = DATA_WEI_DW;
localparam ORAM_DAT_DW = DATA_OUT_DW;
localparam FRAM_DAT_DW =  4;
localparam ORAM_MUX_DW =  4;
localparam ORAM_ADD_MW = ORAM_ADD_AW-2;

localparam CONV_ICH_DW =  8;//256
localparam CONV_OCH_DW =  8;//256
localparam CONV_LEN_DW = 10;//1024
localparam CONV_SUM_DW = 24;
localparam CONV_MUL_DW = CONV_SUM_DW;
localparam CONV_ADD_DW = CONV_SUM_DW;
localparam DILA_FAC_DW =  2;//1/2/4/8
localparam STRD_FAC_DW =  2;//1/2/4/8
localparam CONV_WEI_DW =  3;//8
localparam CONV_SPT_DW =  8;//256
localparam POOL_LEN_DW = ORAM_ADD_AW;
localparam POOL_FAC_DW =  2;//1/2/4/8

localparam PE_ROW = BANK_NUM_DW;
localparam PE_COL = BANK_NUM_DW;

localparam STAT_DAT_DW = CONV_ICH_DW+CONV_WEI_DW;
localparam STAT_NUM_DW = 32;
localparam STAT_NUM_AW = $clog2(STAT_NUM_DW);

localparam STAT_CMD_DW =  9;
localparam CHIP_CMD_DW = 32;
localparam PEAY_CMD_DW =  3;
localparam ARAM_CMD_DW =  7;
localparam WRAM_CMD_DW =  5;
localparam FRAM_CMD_DW =  4;
localparam ORAM_CMD_DW =  8;
localparam MOVE_CMD_DW =  7;

localparam ACC_STATE = 12;
localparam ACC_IDLE  = 12'b0000_0000_0001;
localparam ACC_LOAD  = 12'b0000_0000_0010;
localparam ACC_ACMD  = 12'b0000_0000_0100;
localparam ACC_ITOA  = 12'b0000_0000_1000;
localparam ACC_ITOW  = 12'b0000_0001_0000;
localparam ACC_OTOA  = 12'b0000_0010_0000;
localparam ACC_ATOW  = 12'b0000_0100_0000;
localparam ACC_WTOA  = 12'b0000_1000_0000;
localparam ACC_CONV  = 12'b0001_0000_0000;
localparam ACC_POOL  = 12'b0010_0000_0000;
localparam ACC_STAT  = 12'b0100_0000_0000;
localparam ACC_READ  = 12'b1000_0000_0000;

reg [ACC_STATE -1:0] acc_cs;
reg [ACC_STATE -1:0] acc_ns;

wire acc_idle = acc_cs == ACC_IDLE;
wire acc_load = acc_cs == ACC_LOAD;
wire acc_acmd = acc_cs == ACC_ACMD;
wire acc_itoa = acc_cs == ACC_ITOA;
wire acc_itow = acc_cs == ACC_ITOW;
wire acc_otoa = acc_cs == ACC_OTOA;
wire acc_atow = acc_cs == ACC_ATOW;
wire acc_wtoa = acc_cs == ACC_WTOA;
wire acc_conv = acc_cs == ACC_CONV;
wire acc_pool = acc_cs == ACC_POOL;
wire acc_stat = acc_cs == ACC_STAT;
wire acc_read = acc_cs == ACC_READ;

reg acc_idle_done;
reg acc_load_done;
reg acc_acmd_done;
reg acc_itoa_done;
reg acc_itow_done;
reg acc_otoa_done;
reg acc_atow_done;
reg acc_wtoa_done;
reg acc_conv_done;
reg acc_pool_done;
reg acc_stat_done;
reg acc_read_done;

wire peay_idle;
wire wram_idle;
wire fram_idle;
wire aram_idle;
wire oram_idle;
wire move_idle;

integer i;
genvar gen_i, gen_j;
//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
//DAT_IO
wire                      chip_dat_vld = CHIP_DAT_VLD;
wire                      chip_dat_lst = CHIP_DAT_LST;
reg                       chip_dat_rdy;
wire [CHIP_DAT_DW   -1:0] chip_dat_dat = CHIP_DAT_DAT;
wire                      chip_dat_cmd = CHIP_DAT_CMD;
assign CHIP_DAT_RDY = chip_dat_rdy;

wire chip_dat_ena = chip_dat_vld & chip_dat_rdy;
//OUT_IO
reg                       chip_out_vld;
reg                       chip_out_lst;
wire                      chip_out_rdy = CHIP_OUT_RDY;
reg  [CHIP_OUT_DW   -1:0] chip_out_dat;

assign CHIP_OUT_VLD = chip_out_vld;
assign CHIP_OUT_LST = chip_out_lst;
assign CHIP_OUT_DAT = chip_out_dat;
//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================
//DATA
reg  [4 -1:0][CHIP_DAT_DW -1:0] acc_load_reg;
wire [2 -1:0] acc_load_cnt;
wire          acc_load_cnt_ena = chip_dat_ena && chip_dat_cmd;
CPM_CNT #( 2 ) ACC_LOAD_CNT_U ( clk, rst_n, acc_load_cnt_ena, acc_load_cnt );

//CMD
wire [CHIP_CMD_DW    -1:0] cfg_acmd_dat = acc_load_reg;
wire                       cfg_info_vld;
wire [STAT_CMD_DW    -1:0] cfg_info_cmd;
wire cmd_itoa_ena;
wire cmd_itow_ena;
wire cmd_otoa_ena;
wire cmd_atow_ena;
wire cmd_wtoa_ena;
wire cmd_conv_ena;
wire cmd_pool_ena;
wire cmd_stat_ena;
wire cmd_read_ena;
wire cmd_otof_ena;

wire cfg_load_vld = chip_dat_ena && chip_dat_cmd && &acc_load_cnt;
wire cfg_acmd_vld;
wire cfg_acfg_vld;
CPM_REG #( 1 ) CFG_ACMD_VLD_REG( clk, rst_n, cfg_load_vld, cfg_acmd_vld );
CPM_REG #( 1 ) CFG_ACFG_VLD_REG( clk, rst_n, cfg_acmd_vld, cfg_acfg_vld );

wire chip_data_lst = chip_dat_ena && chip_dat_lst && ~chip_dat_cmd;
CPM_REG_CE #( 1 ) CHIP_ITOX_LST_REG( clk, rst_n, acc_idle, chip_data_lst, 1'd1, chip_itox_lst );
//CFG
wire [ARAM_NUM_DW    -1:0] cfg_aram_idx;
wire [WRAM_NUM_DW    -1:0] cfg_wram_idx;
wire [ORAM_NUM_DW    -1:0] cfg_oram_idx;
wire [ARAM_ADD_AW    -1:0] cfg_aram_add;
wire [WRAM_ADD_AW    -1:0] cfg_wram_add;
wire [ORAM_ADD_AW    -1:0] cfg_oram_add;
wire [ARAM_ADD_AW    -1:0] cfg_aram_len;
wire [WRAM_ADD_AW    -1:0] cfg_wram_len;
wire [ORAM_ADD_AW    -1:0] cfg_oram_len;

wire [CONV_ICH_DW    -1:0] cfg_conv_ich;
wire [CONV_OCH_DW    -1:0] cfg_conv_och;
wire [CONV_LEN_DW    -1:0] cfg_conv_len;
wire [CONV_MUL_DW    -1:0] cfg_conv_mul;
wire [CONV_ADD_DW    -1:0] cfg_conv_add;
wire [DILA_FAC_DW    -1:0] cfg_dila_fac;
wire [STRD_FAC_DW    -1:0] cfg_strd_fac;
wire [CONV_WEI_DW    -1:0] cfg_conv_wei;
wire                       cfg_flag_vld;

wire                       cfg_relu_ena;
wire                       cfg_splt_ena;
wire                       cfg_comb_ena;
wire                       cfg_flag_ena;
wire                       cfg_stat_ena;
wire                       cfg_maxp_ena;
wire                       cfg_avgp_ena;
wire                       cfg_resn_ena;

wire [CONV_SPT_DW    -1:0] cfg_splt_len;

wire [POOL_LEN_DW    -1:0] cfg_pool_len;
wire [POOL_FAC_DW    -1:0] cfg_pool_fac;

assign cmd_otof_ena = cmd_otoa_ena && cfg_flag_ena;

wire [PEAY_CMD_DW   -2:0] peay_cfg_info_cmd_tmp = {cmd_conv_ena, 1'd0};
wire [WRAM_CMD_DW   -2:0] wram_cfg_info_cmd_tmp = {cmd_wtoa_ena, cmd_atow_ena, cmd_conv_ena, cmd_itow_ena};
wire [FRAM_CMD_DW   -2:0] fram_cfg_info_cmd_tmp = {cmd_otof_ena, cmd_conv_ena, 1'd0};
wire [ARAM_CMD_DW   -2:0] aram_cfg_info_cmd_tmp = {1'd0, cmd_atow_ena, cmd_wtoa_ena, cmd_otoa_ena, cmd_conv_ena, cmd_itoa_ena};
wire [ORAM_CMD_DW   -2:0] oram_cfg_info_cmd_tmp = {cmd_stat_ena, cmd_otoa_ena, cmd_pool_ena, cmd_conv_ena&&cfg_resn_ena, cmd_conv_ena, 1'd0};
wire [MOVE_CMD_DW   -2:0] move_cfg_info_cmd_tmp = {cmd_stat_ena, cmd_wtoa_ena, cmd_atow_ena, cmd_otoa_ena, cmd_itow_ena, cmd_itoa_ena};

wire [PEAY_CMD_DW   -1:0] peay_cfg_info_cmd = {peay_cfg_info_cmd_tmp, ~|peay_cfg_info_cmd_tmp};
wire [WRAM_CMD_DW   -1:0] wram_cfg_info_cmd = {wram_cfg_info_cmd_tmp, ~|wram_cfg_info_cmd_tmp};
wire [FRAM_CMD_DW   -1:0] fram_cfg_info_cmd = {fram_cfg_info_cmd_tmp, ~|fram_cfg_info_cmd_tmp};
wire [ARAM_CMD_DW   -1:0] aram_cfg_info_cmd = {aram_cfg_info_cmd_tmp, ~|aram_cfg_info_cmd_tmp};
wire [ORAM_CMD_DW   -1:0] oram_cfg_info_cmd = {oram_cfg_info_cmd_tmp, ~|oram_cfg_info_cmd_tmp};
wire [MOVE_CMD_DW   -1:0] move_cfg_info_cmd = {move_cfg_info_cmd_tmp, ~|move_cfg_info_cmd_tmp};

//PEA
wire peay_cfg_info_vld;
wire peay_cfg_info_rdy;
wire peay_cfg_info_ena = peay_cfg_info_vld && peay_cfg_info_rdy;
CPM_REG_CE #( 1 ) PEAY_CFG_INFO_VLD_REG( clk, rst_n, peay_cfg_info_ena, cfg_acmd_vld, 1'd1, peay_cfg_info_vld );

wire              [PE_COL -1:0][2              -1:0] peay_fram_add_rid;
wire              [PE_COL -1:0]                      peay_fram_add_vld;
reg               [PE_COL -1:0]                      peay_fram_add_rdy;
wire              [PE_COL -1:0]                      peay_fram_add_lst;
wire              [PE_COL -1:0][FRAM_ADD_AW    -1:0] peay_fram_add_add;
reg               [PE_COL -1:0]                      peay_fram_dat_vld;
reg               [PE_COL -1:0]                      peay_fram_dat_lst;
wire              [PE_COL -1:0]                      peay_fram_dat_rdy;
reg               [PE_COL -1:0][FRAM_DAT_DW    -1:0] peay_fram_dat_dat;

wire              [PE_COL -1:0][2              -1:0] peay_aram_add_rid;
wire              [PE_COL -1:0]                      peay_aram_add_vld;
wire              [PE_COL -1:0]                      peay_aram_add_lst;
reg               [PE_COL -1:0]                      peay_aram_add_rdy;
wire              [PE_COL -1:0][ARAM_ADD_AW    -1:0] peay_aram_add_add;
reg               [PE_COL -1:0]                      peay_aram_dat_vld;
reg               [PE_COL -1:0]                      peay_aram_dat_lst;
wire              [PE_COL -1:0]                      peay_aram_dat_rdy;
reg               [PE_COL -1:0][ARAM_DAT_DW    -1:0] peay_aram_dat_dat;

wire [PE_ROW -1:0][PE_COL -1:0]                      peay_wram_add_vld;
wire [PE_ROW -1:0][PE_COL -1:0]                      peay_wram_add_lst;
reg  [PE_ROW -1:0][PE_COL -1:0]                      peay_wram_add_rdy;
wire [PE_ROW -1:0][PE_COL -1:0][WRAM_ADD_AW    -1:0] peay_wram_add_add;
wire [PE_ROW -1:0][PE_COL -1:0][STAT_DAT_DW    -1:0] peay_wram_add_buf;
reg  [PE_ROW -1:0][PE_COL -1:0]                      peay_wram_dat_vld;
reg  [PE_ROW -1:0][PE_COL -1:0]                      peay_wram_dat_lst;
wire [PE_ROW -1:0][PE_COL -1:0]                      peay_wram_dat_rdy;
reg  [PE_ROW -1:0][PE_COL -1:0][WRAM_DAT_DW    -1:0] peay_wram_dat_dat;

wire [PE_ROW -1:0][PE_COL -1:0]                      peay_oram_dat_vld;
wire [PE_ROW -1:0][PE_COL -1:0]                      peay_oram_dat_lst;
reg  [PE_ROW -1:0][PE_COL -1:0]                      peay_oram_dat_rdy;
wire [PE_ROW -1:0][PE_COL -1:0][ORAM_ADD_AW    -1:0] peay_oram_dat_add;
wire [PE_ROW -1:0][PE_COL -1:0][ORAM_DAT_DW    -1:0] peay_oram_dat_dat;

//WRAM_WBUF
wire wbuf_cfg_info_vld;
wire wbuf_cfg_info_rdy;
wire wbuf_cfg_info_ena = wbuf_cfg_info_vld && wbuf_cfg_info_rdy;
CPM_REG_CE #( 1 ) WBUF_CFG_INFO_VLD_REG( clk, rst_n, wbuf_cfg_info_ena, cfg_acmd_vld, 1'd1, wbuf_cfg_info_vld );

reg  [PE_ROW -1:0][PE_COL -1:0]                      wbuf_ptow_add_vld;
reg  [PE_ROW -1:0][PE_COL -1:0]                      wbuf_ptow_add_lst;
wire [PE_ROW -1:0][PE_COL -1:0]                      wbuf_ptow_add_rdy;
reg  [PE_ROW -1:0][PE_COL -1:0][WRAM_ADD_AW    -1:0] wbuf_ptow_add_add;
reg  [PE_ROW -1:0][PE_COL -1:0][STAT_DAT_DW    -1:0] wbuf_ptow_add_buf;
wire [PE_ROW -1:0][PE_COL -1:0]                      wbuf_ptow_dat_vld;
wire [PE_ROW -1:0][PE_COL -1:0]                      wbuf_ptow_dat_lst;
reg  [PE_ROW -1:0][PE_COL -1:0]                      wbuf_ptow_dat_rdy;
wire [PE_ROW -1:0][PE_COL -1:0][WRAM_DAT_DW    -1:0] wbuf_ptow_dat_dat;

reg  [PE_ROW -1:0]                                   wbuf_mtow_dat_vld;
reg  [PE_ROW -1:0]                                   wbuf_mtow_dat_lst;
wire [PE_ROW -1:0]                                   wbuf_mtow_dat_rdy;
reg  [PE_ROW -1:0]             [STAT_DAT_DW    -1:0] wbuf_mtow_dat_dat;
wire [PE_ROW -1:0]                                   wbuf_wram_add_vld;
wire [PE_ROW -1:0]                                   wbuf_wram_add_lst;
reg  [PE_ROW -1:0]                                   wbuf_wram_add_rdy;
wire [PE_ROW -1:0]             [WRAM_ADD_AW    -1:0] wbuf_wram_add_add;
reg  [PE_ROW -1:0]                                   wbuf_wram_dat_vld;
reg  [PE_ROW -1:0]                                   wbuf_wram_dat_lst;
wire [PE_ROW -1:0]                                   wbuf_wram_dat_rdy;
reg  [PE_ROW -1:0]             [WRAM_DAT_DW    -1:0] wbuf_wram_dat_dat;

//WRAM
wire                     wram_cfg_info_vld;
wire                     wram_cfg_info_rdy;
wire                     wram_cfg_info_ena = wram_cfg_info_vld && wram_cfg_info_rdy;
CPM_REG_CE #( 1 ) WRAM_CFG_INFO_VLD_REG( clk, rst_n, wram_cfg_info_ena, cfg_acmd_vld, 1'd1, wram_cfg_info_vld );

reg  [WRAM_NUM_DW -1:0]                      wram_etow_dat_vld;
reg  [WRAM_NUM_DW -1:0]                      wram_etow_dat_lst;
wire [WRAM_NUM_DW -1:0]                      wram_etow_dat_rdy;
reg  [WRAM_NUM_DW -1:0][WRAM_ADD_AW    -1:0] wram_etow_dat_add;
reg  [WRAM_NUM_DW -1:0][WRAM_DAT_DW    -1:0] wram_etow_dat_dat;

reg  [WRAM_NUM_DW -1:0]                      wram_etow_add_vld;
reg  [WRAM_NUM_DW -1:0]                      wram_etow_add_lst;
wire [WRAM_NUM_DW -1:0]                      wram_etow_add_rdy;
reg  [WRAM_NUM_DW -1:0][WRAM_ADD_AW    -1:0] wram_etow_add_add;
wire [WRAM_NUM_DW -1:0]                      wram_wtoe_dat_vld;
wire [WRAM_NUM_DW -1:0]                      wram_wtoe_dat_lst;
reg  [WRAM_NUM_DW -1:0]                      wram_wtoe_dat_rdy;
wire [WRAM_NUM_DW -1:0][WRAM_DAT_DW    -1:0] wram_wtoe_dat_dat;

//FRAM
wire                     fram_cfg_info_vld;
wire                     fram_cfg_info_rdy;
wire                     fram_cfg_info_ena = fram_cfg_info_vld && fram_cfg_info_rdy;
CPM_REG_CE #( 1 ) FRAM_CFG_INFO_VLD_REG( clk, rst_n, fram_cfg_info_ena, cfg_acmd_vld, 1'd1, fram_cfg_info_vld );

reg  [FRAM_NUM_DW -1:0]                      fram_etof_dat_vld;
reg  [FRAM_NUM_DW -1:0]                      fram_etof_dat_lst;
wire [FRAM_NUM_DW -1:0]                      fram_etof_dat_rdy;
reg  [FRAM_NUM_DW -1:0][FRAM_ADD_AW    -1:0] fram_etof_dat_add;
reg  [FRAM_NUM_DW -1:0][FRAM_DAT_DW    -1:0] fram_etof_dat_dat;

reg  [FRAM_NUM_DW -1:0]                      fram_etof_add_vld;
reg  [FRAM_NUM_DW -1:0]                      fram_etof_add_lst;
wire [FRAM_NUM_DW -1:0]                      fram_etof_add_rdy;
reg  [FRAM_NUM_DW -1:0][FRAM_ADD_AW    -1:0] fram_etof_add_add;
wire [FRAM_NUM_DW -1:0]                      fram_ftoe_dat_vld;
wire [FRAM_NUM_DW -1:0]                      fram_ftoe_dat_lst;
reg  [FRAM_NUM_DW -1:0]                      fram_ftoe_dat_rdy;
wire [FRAM_NUM_DW -1:0][FRAM_DAT_DW    -1:0] fram_ftoe_dat_dat;

//ARAM ROUNTER
reg  [FRAM_NUM_DW -1:0][FRAM_NUM_AW    -1:0] farb_aram_add_rid;
reg  [FRAM_NUM_DW -1:0]                      farb_aram_add_vld;
reg  [FRAM_NUM_DW -1:0]                      farb_aram_add_lst;
wire [FRAM_NUM_DW -1:0]                      farb_aram_add_rdy;
reg  [FRAM_NUM_DW -1:0][FRAM_ADD_AW    -1:0] farb_aram_add_dat;
wire [FRAM_NUM_DW -1:0]                      farb_aram_dat_vld;
wire [FRAM_NUM_DW -1:0]                      farb_aram_dat_lst;
reg  [FRAM_NUM_DW -1:0]                      farb_aram_dat_rdy;
wire [FRAM_NUM_DW -1:0][FRAM_DAT_DW    -1:0] farb_aram_dat_dat;

wire [FRAM_NUM_DW -1:0]                      farb_aarb_add_vld;
wire [FRAM_NUM_DW -1:0]                      farb_aarb_add_lst;
reg  [FRAM_NUM_DW -1:0]                      farb_aarb_add_rdy;
wire [FRAM_NUM_DW -1:0][FRAM_ADD_AW    -1:0] farb_aarb_add_dat;
reg  [FRAM_NUM_DW -1:0]                      farb_aarb_dat_vld;
reg  [FRAM_NUM_DW -1:0]                      farb_aarb_dat_lst;
wire [FRAM_NUM_DW -1:0]                      farb_aarb_dat_rdy;
reg  [FRAM_NUM_DW -1:0][FRAM_DAT_DW    -1:0] farb_aarb_dat_dat;

//ARAM
wire                     aram_cfg_info_vld;
wire                     aram_cfg_info_rdy;
wire                     aram_cfg_info_ena = aram_cfg_info_vld && aram_cfg_info_rdy;
CPM_REG_CE #( 1 ) ARAM_CFG_INFO_VLD_REG( clk, rst_n, aram_cfg_info_ena, cfg_acmd_vld, 1'd1, aram_cfg_info_vld );

reg  [ARAM_NUM_DW -1:0]                      aram_etoa_dat_vld;
reg  [ARAM_NUM_DW -1:0]                      aram_etoa_dat_lst;
wire [ARAM_NUM_DW -1:0]                      aram_etoa_dat_rdy;
reg  [ARAM_NUM_DW -1:0][ARAM_ADD_AW    -1:0] aram_etoa_dat_add;
reg  [ARAM_NUM_DW -1:0][ARAM_DAT_DW    -1:0] aram_etoa_dat_dat;

reg  [ARAM_NUM_DW -1:0]                      aram_etoa_add_vld;
reg  [ARAM_NUM_DW -1:0]                      aram_etoa_add_lst;
wire [ARAM_NUM_DW -1:0]                      aram_etoa_add_rdy;
reg  [ARAM_NUM_DW -1:0][ARAM_ADD_AW    -1:0] aram_etoa_add_add;
wire [ARAM_NUM_DW -1:0]                      aram_atoe_dat_vld;
wire [ARAM_NUM_DW -1:0]                      aram_atoe_dat_lst;
reg  [ARAM_NUM_DW -1:0]                      aram_atoe_dat_rdy;
wire [ARAM_NUM_DW -1:0][ARAM_DAT_DW    -1:0] aram_atoe_dat_dat;

//ARAM ROUNTER
reg  [ARAM_NUM_DW -1:0][ARAM_NUM_AW    -1:0] aarb_aram_add_rid;
reg  [ARAM_NUM_DW -1:0]                      aarb_aram_add_vld;
reg  [ARAM_NUM_DW -1:0]                      aarb_aram_add_lst;
wire [ARAM_NUM_DW -1:0]                      aarb_aram_add_rdy;
reg  [ARAM_NUM_DW -1:0][ARAM_ADD_AW    -1:0] aarb_aram_add_dat;
wire [ARAM_NUM_DW -1:0]                      aarb_aram_dat_vld;
wire [ARAM_NUM_DW -1:0]                      aarb_aram_dat_lst;
reg  [ARAM_NUM_DW -1:0]                      aarb_aram_dat_rdy;
wire [ARAM_NUM_DW -1:0][ARAM_DAT_DW    -1:0] aarb_aram_dat_dat;

wire [ARAM_NUM_DW -1:0]                      aarb_aarb_add_vld;
wire [ARAM_NUM_DW -1:0]                      aarb_aarb_add_lst;
reg  [ARAM_NUM_DW -1:0]                      aarb_aarb_add_rdy;
wire [ARAM_NUM_DW -1:0][ARAM_ADD_AW    -1:0] aarb_aarb_add_dat;
reg  [ARAM_NUM_DW -1:0]                      aarb_aarb_dat_vld;
reg  [ARAM_NUM_DW -1:0]                      aarb_aarb_dat_lst;
wire [ARAM_NUM_DW -1:0]                      aarb_aarb_dat_rdy;
reg  [ARAM_NUM_DW -1:0][ARAM_DAT_DW    -1:0] aarb_aarb_dat_dat;

//ORAM
wire                     oram_cfg_info_vld;
wire                     oram_cfg_info_rdy;
wire                     oram_cfg_info_ena = oram_cfg_info_vld && oram_cfg_info_rdy;
CPM_REG_CE #( 1 ) ORAM_CFG_INFO_VLD_REG( clk, rst_n, oram_cfg_info_ena, cfg_acmd_vld, 1'd1, oram_cfg_info_vld );

reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   oram_etoo_dat_vld;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   oram_etoo_dat_lst;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   oram_etoo_dat_rdy;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_ADD_MW -1:0] oram_etoo_dat_add;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_DAT_DW -1:0] oram_etoo_dat_dat;

reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   oram_etoo_add_vld;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   oram_etoo_add_lst;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   oram_etoo_add_rdy;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_ADD_AW -1:0] oram_etoo_add_add;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   oram_otoe_dat_vld;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   oram_otoe_dat_lst;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   oram_otoe_dat_rdy;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_DAT_DW -1:0] oram_otoe_dat_dat;

//ORAM_DEMUX
reg  [ORAM_NUM_DW -1:0]                                     omux_mtoo_dat_vld;
reg  [ORAM_NUM_DW -1:0]                                     omux_mtoo_dat_lst;
wire [ORAM_NUM_DW -1:0]                                     omux_mtoo_dat_rdy;
reg  [ORAM_NUM_DW -1:0]                  [ORAM_ADD_AW -1:0] omux_mtoo_dat_add;
reg  [ORAM_NUM_DW -1:0]                  [ORAM_DAT_DW -1:0] omux_mtoo_dat_dat;

reg  [ORAM_NUM_DW -1:0]                                     omux_mtoo_add_vld;
reg  [ORAM_NUM_DW -1:0]                                     omux_mtoo_add_lst;
wire [ORAM_NUM_DW -1:0]                                     omux_mtoo_add_rdy;
reg  [ORAM_NUM_DW -1:0]                  [ORAM_ADD_AW -1:0] omux_mtoo_add_add;
wire [ORAM_NUM_DW -1:0]                                     omux_otom_dat_vld;
wire [ORAM_NUM_DW -1:0]                                     omux_otom_dat_lst;
reg  [ORAM_NUM_DW -1:0]                                     omux_otom_dat_rdy;
wire [ORAM_NUM_DW -1:0]                  [ORAM_DAT_DW -1:0] omux_otom_dat_dat;

wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   odmx_mtoo_dat_vld;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   odmx_mtoo_dat_lst;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   odmx_mtoo_dat_rdy;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_ADD_MW -1:0] odmx_mtoo_dat_add;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_DAT_DW -1:0] odmx_mtoo_dat_dat;

wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   odmx_mtoo_add_vld;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   odmx_mtoo_add_lst;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   odmx_mtoo_add_rdy;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_ADD_MW -1:0] odmx_mtoo_add_add;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   odmx_otom_dat_vld;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   odmx_otom_dat_lst;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   odmx_otom_dat_rdy;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_DAT_DW -1:0] odmx_otom_dat_dat;

//MOVER
wire                      move_cfg_info_vld;
wire                      move_cfg_info_rdy;
wire                      move_cfg_info_ena = move_cfg_info_vld && move_cfg_info_rdy;
CPM_REG_CE #( 1 ) MOVE_CFG_INFO_VLD_REG( clk, rst_n, move_cfg_info_ena, cfg_acmd_vld, 1'd1, move_cfg_info_vld );

reg                                          move_itom_dat_vld;
reg                                          move_itom_dat_lst;
wire                                         move_itom_dat_rdy;
reg  [MOVE_DAT_DW                      -1:0] move_itom_dat_dat;

wire                                         move_mtos_dat_vld;
wire                                         move_mtos_dat_lst;
reg                                          move_mtos_dat_rdy;
wire [STAT_NUM_AW                      -1:0] move_mtos_dat_add;
wire [STAT_DAT_DW                      -1:0] move_mtos_dat_dat;

wire [FRAM_NUM_DW -1:0]                      move_mtof_dat_vld;
wire [FRAM_NUM_DW -1:0]                      move_mtof_dat_lst;
reg  [FRAM_NUM_DW -1:0]                      move_mtof_dat_rdy;
wire [FRAM_NUM_DW -1:0][FRAM_ADD_AW    -1:0] move_mtof_dat_add;
wire [FRAM_NUM_DW -1:0][FRAM_DAT_DW    -1:0] move_mtof_dat_dat;

wire [ARAM_NUM_DW -1:0]                      move_mtoa_dat_vld;
wire [ARAM_NUM_DW -1:0]                      move_mtoa_dat_lst;
reg  [ARAM_NUM_DW -1:0]                      move_mtoa_dat_rdy;
wire [ARAM_NUM_DW -1:0][ARAM_ADD_AW    -1:0] move_mtoa_dat_add;
wire [ARAM_NUM_DW -1:0][ARAM_DAT_DW    -1:0] move_mtoa_dat_dat;

wire [ARAM_NUM_DW -1:0]                      move_mtoa_add_vld;
wire [ARAM_NUM_DW -1:0]                      move_mtoa_add_lst;
reg  [ARAM_NUM_DW -1:0]                      move_mtoa_add_rdy;
wire [ARAM_NUM_DW -1:0][ARAM_ADD_AW    -1:0] move_mtoa_add_dat;
reg  [ARAM_NUM_DW -1:0]                      move_atom_dat_vld;
reg  [ARAM_NUM_DW -1:0]                      move_atom_dat_lst;
wire [ARAM_NUM_DW -1:0]                      move_atom_dat_rdy;
reg  [ARAM_NUM_DW -1:0][ARAM_DAT_DW    -1:0] move_atom_dat_dat;

wire [WRAM_NUM_DW -1:0]                      move_mtow_dat_vld;
wire [WRAM_NUM_DW -1:0]                      move_mtow_dat_lst;
reg  [WRAM_NUM_DW -1:0]                      move_mtow_dat_rdy;
wire [WRAM_NUM_DW -1:0][WRAM_ADD_AW    -1:0] move_mtow_dat_add;
wire [WRAM_NUM_DW -1:0][WRAM_DAT_DW    -1:0] move_mtow_dat_dat;

wire [WRAM_NUM_DW -1:0]                      move_mtow_add_vld;
wire [WRAM_NUM_DW -1:0]                      move_mtow_add_lst;
reg  [WRAM_NUM_DW -1:0]                      move_mtow_add_rdy;
wire [WRAM_NUM_DW -1:0][WRAM_ADD_AW    -1:0] move_mtow_add_dat;
reg  [WRAM_NUM_DW -1:0]                      move_wtom_dat_vld;
reg  [WRAM_NUM_DW -1:0]                      move_wtom_dat_lst;
wire [WRAM_NUM_DW -1:0]                      move_wtom_dat_rdy;
reg  [WRAM_NUM_DW -1:0][WRAM_DAT_DW    -1:0] move_wtom_dat_dat;

wire [ORAM_NUM_DW -1:0]                      move_mtoo_dat_vld;
wire [ORAM_NUM_DW -1:0]                      move_mtoo_dat_lst;
reg  [ORAM_NUM_DW -1:0]                      move_mtoo_dat_rdy;
wire [ORAM_NUM_DW -1:0][ORAM_ADD_AW    -1:0] move_mtoo_dat_add;
wire [ORAM_NUM_DW -1:0][ORAM_DAT_DW    -1:0] move_mtoo_dat_dat;

wire [ORAM_NUM_DW -1:0]                      move_mtoo_add_vld;
wire [ORAM_NUM_DW -1:0]                      move_mtoo_add_lst;
reg  [ORAM_NUM_DW -1:0]                      move_mtoo_add_rdy;
wire [ORAM_NUM_DW -1:0][ORAM_ADD_AW    -1:0] move_mtoo_add_add;
reg  [ORAM_NUM_DW -1:0]                      move_otom_dat_vld;
reg  [ORAM_NUM_DW -1:0]                      move_otom_dat_lst;
wire [ORAM_NUM_DW -1:0]                      move_otom_dat_rdy;
reg  [ORAM_NUM_DW -1:0][ORAM_DAT_DW    -1:0] move_otom_dat_dat;
//=====================================================================================================================
// IO Logic Design :
//=====================================================================================================================
always @ ( * )begin
    case( acc_cs )
        ACC_IDLE: chip_dat_rdy = 'd1;
        ACC_LOAD: chip_dat_rdy = 'd1;
        ACC_ITOA: chip_dat_rdy = ~chip_itox_lst;
        ACC_ITOW: chip_dat_rdy = ~chip_itox_lst;
         default: chip_dat_rdy = 'd0;
    endcase
end

//=====================================================================================================================
// Logic Design :
//=====================================================================================================================
always @ ( * )begin
  acc_idle_done = chip_dat_ena && chip_dat_cmd;
  acc_load_done = cfg_load_vld;
  acc_acmd_done = cfg_acfg_vld;
  acc_itoa_done =/*~cfg_acmd_vld && */move_idle && aram_idle;
  acc_itow_done =/*~cfg_acmd_vld && */move_idle && wram_idle;
  acc_otoa_done =/*~cfg_acmd_vld && */move_idle && oram_idle && aram_idle;
  acc_atow_done =/*~cfg_acmd_vld && */move_idle && aram_idle && wram_idle;
  acc_wtoa_done =/*~cfg_acmd_vld && */move_idle && wram_idle && aram_idle;
  acc_conv_done =/*~cfg_acmd_vld && */peay_idle;
  acc_pool_done =/*~cfg_acmd_vld && */oram_idle;
  acc_stat_done =/*~cfg_acmd_vld && */oram_idle;
  acc_read_done =/*~cfg_acmd_vld && */move_idle;
end

generate
    for( gen_i=0 ; gen_i < 4; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                acc_load_reg[gen_i] <= 'd0;
            else if( chip_dat_ena && chip_dat_cmd && acc_load_cnt==gen_i )
                acc_load_reg[gen_i] <= chip_dat_dat;
        end
    end
endgenerate

//PEA
generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        always @ ( * )begin
            peay_fram_add_rdy[gen_i] = farb_aram_add_rdy[gen_i];
            peay_fram_dat_vld[gen_i] = farb_aram_dat_vld[gen_i];
            peay_fram_dat_lst[gen_i] = farb_aram_dat_lst[gen_i];
            peay_fram_dat_dat[gen_i] = farb_aram_dat_dat[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        always @ ( * )begin
            peay_aram_add_rdy[gen_i] = aarb_aram_add_rdy[gen_i];
            peay_aram_dat_vld[gen_i] = aarb_aram_dat_vld[gen_i];
            peay_aram_dat_lst[gen_i] = aarb_aram_dat_lst[gen_i];
            peay_aram_dat_dat[gen_i] = aarb_aram_dat_dat[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < PE_COL; gen_j = gen_j+1 )begin
            always @ ( * )begin
                peay_wram_add_rdy[gen_i][gen_j] = wbuf_ptow_add_rdy[gen_i][gen_j];
                peay_wram_dat_vld[gen_i][gen_j] = wbuf_ptow_dat_vld[gen_i][gen_j];
                peay_wram_dat_lst[gen_i][gen_j] = wbuf_ptow_dat_lst[gen_i][gen_j];
                peay_wram_dat_dat[gen_i][gen_j] = wbuf_ptow_dat_dat[gen_i][gen_j];
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < PE_COL; gen_j = gen_j+1 )begin
            always @ ( * )begin
                peay_oram_dat_rdy[gen_i][gen_j] = oram_etoo_dat_rdy[gen_i][gen_j];
            end
        end
    end
endgenerate

//WRAM_WBUF
generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            wbuf_mtow_dat_vld[gen_i] = move_mtos_dat_vld;
            wbuf_mtow_dat_lst[gen_i] = move_mtos_dat_lst;
            wbuf_mtow_dat_dat[gen_i] = move_mtos_dat_dat;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < PE_COL; gen_j = gen_j+1 )begin
            always @ ( * )begin
                wbuf_ptow_add_vld[gen_i][gen_j] = peay_wram_add_vld[gen_i][gen_j];
                wbuf_ptow_add_lst[gen_i][gen_j] = peay_wram_add_lst[gen_i][gen_j];
                wbuf_ptow_add_add[gen_i][gen_j] = peay_wram_add_add[gen_i][gen_j];
                wbuf_ptow_add_buf[gen_i][gen_j] = peay_wram_add_buf[gen_i][gen_j];
                wbuf_ptow_dat_rdy[gen_i][gen_j] = peay_wram_dat_rdy[gen_i][gen_j];
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            wbuf_wram_add_rdy[gen_i] = acc_conv ? wram_etow_add_rdy[gen_i] : 'd0;
            wbuf_wram_dat_vld[gen_i] = acc_conv ? wram_wtoe_dat_vld[gen_i] : 'd0;
            wbuf_wram_dat_lst[gen_i] = acc_conv ? wram_wtoe_dat_lst[gen_i] : 'd0;
            wbuf_wram_dat_dat[gen_i] = acc_conv ? wram_wtoe_dat_dat[gen_i] : 'd0;
        end
    end
endgenerate

//WRAM
generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            wram_etow_dat_vld[gen_i] = move_mtow_dat_vld[gen_i];
            wram_etow_dat_lst[gen_i] = move_mtow_dat_lst[gen_i];
            wram_etow_dat_add[gen_i] = move_mtow_dat_add[gen_i];
            wram_etow_dat_dat[gen_i] = move_mtow_dat_dat[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            wram_etow_add_vld[gen_i] = wbuf_wram_add_vld[gen_i];
            wram_etow_add_lst[gen_i] = wbuf_wram_add_lst[gen_i];
            wram_etow_add_add[gen_i] = wbuf_wram_add_add[gen_i];
            wram_wtoe_dat_rdy[gen_i] = wbuf_wram_dat_rdy[gen_i];
        end
    end
endgenerate

//FRAM
generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        always @ ( * )begin
            fram_etof_dat_vld[gen_i] = move_mtof_dat_vld[gen_i];
            fram_etof_dat_lst[gen_i] = move_mtof_dat_lst[gen_i];
            fram_etof_dat_add[gen_i] = move_mtof_dat_add[gen_i];
            fram_etof_dat_dat[gen_i] = move_mtof_dat_dat[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        always @ ( * )begin
            fram_etof_add_vld[gen_i] = farb_aarb_add_vld[gen_i];
            fram_etof_add_lst[gen_i] = farb_aarb_add_lst[gen_i];
            fram_etof_add_add[gen_i] = farb_aarb_add_dat[gen_i];
            fram_ftoe_dat_rdy[gen_i] = farb_aarb_dat_rdy[gen_i];
        end
    end
endgenerate

//FRAM ROUNTER
generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        always @ ( * )begin
            farb_aram_add_rid[gen_i] = peay_fram_add_rid[gen_i];
            farb_aram_add_vld[gen_i] = peay_fram_add_vld[gen_i];
            farb_aram_add_lst[gen_i] = peay_fram_add_lst[gen_i];
            farb_aram_add_dat[gen_i] = peay_fram_add_add[gen_i];
            farb_aram_dat_rdy[gen_i] = peay_fram_dat_rdy[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        always @ ( * )begin
            farb_aarb_add_rdy[gen_i] = fram_etof_add_rdy[gen_i];
            farb_aarb_dat_vld[gen_i] = fram_ftoe_dat_vld[gen_i];
            farb_aarb_dat_lst[gen_i] = fram_ftoe_dat_lst[gen_i];
            farb_aarb_dat_dat[gen_i] = fram_ftoe_dat_dat[gen_i];
        end
    end
endgenerate

//ARAM
generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        always @ ( * )begin
            aram_etoa_dat_vld[gen_i] = move_mtoa_dat_vld[gen_i];
            aram_etoa_dat_lst[gen_i] = move_mtoa_dat_lst[gen_i];
            aram_etoa_dat_add[gen_i] = move_mtoa_dat_add[gen_i];
            aram_etoa_dat_dat[gen_i] = move_mtoa_dat_dat[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        always @ ( * )begin
            aram_etoa_add_vld[gen_i] = aarb_aarb_add_vld[gen_i];
            aram_etoa_add_lst[gen_i] = aarb_aarb_add_lst[gen_i];
            aram_etoa_add_add[gen_i] = aarb_aarb_add_dat[gen_i];
            aram_atoe_dat_rdy[gen_i] = aarb_aarb_dat_rdy[gen_i];
        end
    end
endgenerate

//ARAM ROUNTER
generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        always @ ( * )begin
            aarb_aram_add_rid[gen_i] = peay_aram_add_rid[gen_i];
            aarb_aram_add_vld[gen_i] = peay_aram_add_vld[gen_i];
            aarb_aram_add_lst[gen_i] = peay_aram_add_lst[gen_i];
            aarb_aram_add_dat[gen_i] = peay_aram_add_add[gen_i];
            aarb_aram_dat_rdy[gen_i] = peay_aram_dat_rdy[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        always @ ( * )begin
            aarb_aarb_add_rdy[gen_i] = aram_etoa_add_rdy[gen_i];
            aarb_aarb_dat_vld[gen_i] = aram_atoe_dat_vld[gen_i];
            aarb_aarb_dat_lst[gen_i] = aram_atoe_dat_lst[gen_i];
            aarb_aarb_dat_dat[gen_i] = aram_atoe_dat_dat[gen_i];
        end
    end
endgenerate

//ORAM
generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < PE_COL; gen_j = gen_j+1 )begin
            always @ ( * )begin
                oram_etoo_dat_vld[gen_i][gen_j] = odmx_mtoo_dat_vld[gen_i][gen_j];
                oram_etoo_dat_lst[gen_i][gen_j] = odmx_mtoo_dat_lst[gen_i][gen_j];
                oram_etoo_dat_add[gen_i][gen_j] = odmx_mtoo_dat_add[gen_i][gen_j];
                oram_etoo_dat_dat[gen_i][gen_j] = odmx_mtoo_dat_dat[gen_i][gen_j];
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < PE_COL; gen_j = gen_j+1 )begin
            always @ ( * )begin
                oram_etoo_add_vld[gen_i][gen_j] = odmx_mtoo_add_vld[gen_i][gen_j];
                oram_etoo_add_lst[gen_i][gen_j] = odmx_mtoo_add_lst[gen_i][gen_j];
                oram_etoo_add_add[gen_i][gen_j] = odmx_mtoo_add_add[gen_i][gen_j];
                oram_otoe_dat_rdy[gen_i][gen_j] = odmx_otom_dat_rdy[gen_i][gen_j];
            end
        end
    end
endgenerate

//ORAM DEMUX
generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            omux_mtoo_dat_vld[gen_i] = move_mtoo_dat_vld[gen_i];
            omux_mtoo_dat_lst[gen_i] = move_mtoo_dat_lst[gen_i];
            omux_mtoo_dat_add[gen_i] = move_mtoo_dat_add[gen_i];
            omux_mtoo_dat_dat[gen_i] = move_mtoo_dat_dat[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        always @ ( * )begin
            omux_mtoo_add_vld[gen_i] = move_mtoo_add_vld[gen_i];
            omux_mtoo_add_lst[gen_i] = move_mtoo_add_lst[gen_i];
            omux_mtoo_add_add[gen_i] = move_mtoo_add_add[gen_i];
            omux_otom_dat_rdy[gen_i] = move_otom_dat_rdy[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < PE_COL; gen_j = gen_j+1 )begin
            always @ ( * )begin
                odmx_mtoo_dat_rdy[gen_i][gen_j] = oram_etoo_dat_rdy[gen_i][gen_j];
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < PE_COL; gen_j = gen_j+1 )begin
            always @ ( * )begin
                odmx_mtoo_add_rdy[gen_i][gen_j] = oram_etoo_add_rdy[gen_i][gen_j];
                odmx_otom_dat_vld[gen_i][gen_j] = oram_otoe_dat_vld[gen_i][gen_j];
                odmx_otom_dat_lst[gen_i][gen_j] = oram_otoe_dat_lst[gen_i][gen_j];
                odmx_otom_dat_dat[gen_i][gen_j] = oram_otoe_dat_dat[gen_i][gen_j];
            end
        end
    end
endgenerate

//MOVE
always @ ( * )begin
    move_itom_dat_vld = acc_itoa || acc_itow ? chip_dat_vld : 'd0;
    move_itom_dat_lst = acc_itoa || acc_itow ? chip_dat_lst : 'd0;
    move_itom_dat_dat = acc_itoa || acc_itow ? chip_dat_dat : 'd0;
end

always @ ( * )begin
    move_mtos_dat_rdy = &wbuf_mtow_dat_rdy;
end

generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        always @ ( * )begin
            move_mtof_dat_rdy[gen_i] = fram_etof_dat_rdy[gen_i];
            move_mtoa_dat_rdy[gen_i] = aram_etoa_dat_rdy[gen_i];
            move_mtow_dat_rdy[gen_i] = wram_etow_dat_rdy[gen_i];
            move_mtoo_dat_rdy[gen_i] = omux_mtoo_dat_rdy[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        always @ ( * )begin
            move_mtoa_add_rdy[gen_i] = acc_atow || acc_read ? farb_aram_add_rdy[gen_i] : 'd0;
            move_atom_dat_vld[gen_i] = acc_atow || acc_read ? farb_aram_dat_vld[gen_i] : 'd0;
            move_atom_dat_lst[gen_i] = acc_atow || acc_read ? farb_aram_dat_lst[gen_i] : 'd0;
            move_atom_dat_dat[gen_i] = acc_atow || acc_read ? farb_aram_dat_dat[gen_i] : 'd0;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        always @ ( * )begin
            move_mtow_add_rdy[gen_i] = acc_wtoa || acc_read ? wram_etow_add_rdy[gen_i] : 'd0;
            move_wtom_dat_vld[gen_i] = acc_wtoa || acc_read ? wram_wtoe_dat_vld[gen_i] : 'd0;
            move_wtom_dat_lst[gen_i] = acc_wtoa || acc_read ? wram_wtoe_dat_lst[gen_i] : 'd0;
            move_wtom_dat_dat[gen_i] = acc_wtoa || acc_read ? wram_wtoe_dat_dat[gen_i] : 'd0;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        always @ ( * )begin
            move_mtoo_add_rdy[gen_i] = omux_mtoo_add_rdy[gen_i];
            move_otom_dat_vld[gen_i] = omux_otom_dat_vld[gen_i];
            move_otom_dat_lst[gen_i] = omux_otom_dat_lst[gen_i];
            move_otom_dat_dat[gen_i] = omux_otom_dat_dat[gen_i];
        end
    end
endgenerate

//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================
EEG_CMD #(
    .CHIP_CMD_DW          ( CHIP_CMD_DW      ),
    .BANK_NUM_DW          ( BANK_NUM_DW      ),
    .CONV_ICH_DW          ( CONV_ICH_DW      ),
    .CONV_OCH_DW          ( CONV_OCH_DW      ),
    .CONV_LEN_DW          ( CONV_LEN_DW      ),
    .CONV_SUM_DW          ( CONV_SUM_DW      ),
    .CONV_MUL_DW          ( CONV_MUL_DW      ),
    .CONV_ADD_DW          ( CONV_ADD_DW      ),
    .DILA_FAC_DW          ( DILA_FAC_DW      ),
    .STRD_FAC_DW          ( STRD_FAC_DW      ),
    .CONV_WEI_DW          ( CONV_WEI_DW      ),
    .POOL_LEN_DW          ( POOL_LEN_DW      ),
    .POOL_FAC_DW          ( POOL_FAC_DW      ),
    .STAT_CMD_DW          ( STAT_CMD_DW      ),
    .ARAM_NUM_DW          ( ARAM_NUM_DW      ),
    .WRAM_NUM_DW          ( WRAM_NUM_DW      ),
    .ORAM_NUM_DW          ( ORAM_NUM_DW      ),
    .ARAM_ADD_AW          ( ARAM_ADD_AW      ),
    .WRAM_ADD_AW          ( WRAM_ADD_AW      ),
    .ORAM_ADD_AW          ( ORAM_ADD_AW      )
) EEG_CMD_U(
    .clk                  ( clk              ),
    .rst_n                ( rst_n            ),

    .CFG_ACMD_VLD         ( cfg_acmd_vld     ),
    .CFG_ACMD_DAT         ( cfg_acmd_dat     ),
    .CFG_INFO_VLD         ( cfg_info_vld     ),
    .CFG_INFO_CMD         ( cfg_info_cmd     ),
    .CMD_ITOA_ENA         ( cmd_itoa_ena     ),
    .CMD_ITOW_ENA         ( cmd_itow_ena     ),
    .CMD_OTOA_ENA         ( cmd_otoa_ena     ),
    .CMD_ATOW_ENA         ( cmd_atow_ena     ),
    .CMD_WTOA_ENA         ( cmd_wtoa_ena     ),
    .CMD_CONV_ENA         ( cmd_conv_ena     ),
    .CMD_POOL_ENA         ( cmd_pool_ena     ),
    .CMD_STAT_ENA         ( cmd_stat_ena     ),
    .CMD_READ_ENA         ( cmd_read_ena     ),

    .CFG_ARAM_IDX         ( cfg_aram_idx     ),
    .CFG_WRAM_IDX         ( cfg_wram_idx     ),
    .CFG_ORAM_IDX         ( cfg_oram_idx     ),
    .CFG_ARAM_ADD         ( cfg_aram_add     ),
    .CFG_WRAM_ADD         ( cfg_wram_add     ),
    .CFG_ORAM_ADD         ( cfg_oram_add     ),
    .CFG_ARAM_LEN         ( cfg_aram_len     ),
    .CFG_WRAM_LEN         ( cfg_wram_len     ),
    .CFG_ORAM_LEN         ( cfg_oram_len     ),

    .CFG_CONV_ICH         ( cfg_conv_ich     ),
    .CFG_CONV_OCH         ( cfg_conv_och     ),
    .CFG_CONV_LEN         ( cfg_conv_len     ),
    .CFG_CONV_MUL         ( cfg_conv_mul     ),
    .CFG_CONV_ADD         ( cfg_conv_add     ),
    .CFG_DILA_FAC         ( cfg_dila_fac     ),
    .CFG_STRD_FAC         ( cfg_strd_fac     ),
    .CFG_CONV_WEI         ( cfg_conv_wei     ),

    .CFG_RELU_ENA         ( cfg_relu_ena     ),
    .CFG_SPLT_ENA         ( cfg_splt_ena     ),
    .CFG_COMB_ENA         ( cfg_comb_ena     ),
    .CFG_FLAG_ENA         ( cfg_flag_ena     ),
    .CFG_MAXP_ENA         ( cfg_maxp_ena     ),
    .CFG_AVGP_ENA         ( cfg_avgp_ena     ),
    .CFG_RESN_ENA         ( cfg_resn_ena     ),
    .CFG_FLAG_VLD         ( cfg_flag_vld     ),
    .CFG_STAT_VLD         ( cfg_stat_vld     ),
    .CFG_WBUF_ENA         ( cfg_wbuf_ena     ),

    .CFG_SPLT_LEN         ( cfg_splt_len     ),

    .CFG_POOL_LEN         ( cfg_pool_len     ),
    .CFG_POOL_FAC         ( cfg_pool_fac     )
);

EEG_PEA #(
    .PEAY_CMD_DW          ( PEAY_CMD_DW       ),
    .BANK_NUM_DW          ( BANK_NUM_DW       ),
    .CONV_ICH_DW          ( CONV_ICH_DW       ),
    .CONV_OCH_DW          ( CONV_OCH_DW       ),
    .CONV_LEN_DW          ( CONV_LEN_DW       ),
    .CONV_SUM_DW          ( CONV_SUM_DW       ),
    .CONV_MUL_DW          ( CONV_MUL_DW       ),
    .CONV_ADD_DW          ( CONV_ADD_DW       ),
    .DILA_FAC_DW          ( DILA_FAC_DW       ),
    .STRD_FAC_DW          ( STRD_FAC_DW       ),
    .CONV_WEI_DW          ( CONV_WEI_DW       ),
    .ARAM_ADD_AW          ( ARAM_ADD_AW       ),
    .WRAM_ADD_AW          ( WRAM_ADD_AW       ),
    .ORAM_ADD_AW          ( ORAM_ADD_AW       ),
    .FRAM_ADD_AW          ( FRAM_ADD_AW       ),
    .ARAM_DAT_DW          ( ARAM_DAT_DW       ),
    .WRAM_DAT_DW          ( WRAM_DAT_DW       ),
    .FRAM_DAT_DW          ( FRAM_DAT_DW       )
) EEG_PEAY_U(
    .clk                  ( clk               ),
    .rst_n                ( rst_n             ),

    .IS_IDLE              ( peay_idle         ),

    .CFG_INFO_VLD         ( peay_cfg_info_vld ),
    .CFG_INFO_RDY         ( peay_cfg_info_rdy ),
    .CFG_INFO_CMD         ( peay_cfg_info_cmd ),
    .CFG_ARAM_ADD         ( cfg_aram_add      ),
    .CFG_WRAM_ADD         ( cfg_wram_add      ),
    .CFG_SPLT_ENA         ( cfg_splt_ena      ),
    .CFG_CONV_ICH         ( cfg_conv_ich      ),
    .CFG_CONV_OCH         ( cfg_conv_och      ),
    .CFG_CONV_LEN         ( cfg_conv_len      ),
    .CFG_CONV_MUL         ( cfg_conv_mul      ),
    .CFG_CONV_ADD         ( cfg_conv_add      ),
    .CFG_CONV_WEI         ( cfg_conv_wei      ),
    .CFG_FLAG_VLD         ( cfg_flag_vld      ),
    .CFG_DILA_FAC         ( cfg_dila_fac      ),
    .CFG_STRD_FAC         ( cfg_strd_fac      ),

    .FRAM_ADD_RID         ( peay_fram_add_rid ),
    .FRAM_ADD_VLD         ( peay_fram_add_vld ),
    .FRAM_ADD_RDY         ( peay_fram_add_rdy ),
    .FRAM_ADD_LST         ( peay_fram_add_lst ),
    .FRAM_ADD_ADD         ( peay_fram_add_add ),
    .FRAM_DAT_VLD         ( peay_fram_dat_vld ),
    .FRAM_DAT_LST         ( peay_fram_dat_lst ),
    .FRAM_DAT_RDY         ( peay_fram_dat_rdy ),
    .FRAM_DAT_DAT         ( peay_fram_dat_dat ),

    .ARAM_ADD_RID         ( peay_aram_add_rid ),
    .ARAM_ADD_VLD         ( peay_aram_add_vld ),
    .ARAM_ADD_LST         ( peay_aram_add_lst ),
    .ARAM_ADD_RDY         ( peay_aram_add_rdy ),
    .ARAM_ADD_ADD         ( peay_aram_add_add ),
    .ARAM_DAT_VLD         ( peay_aram_dat_vld ),
    .ARAM_DAT_LST         ( peay_aram_dat_lst ),
    .ARAM_DAT_RDY         ( peay_aram_dat_rdy ),
    .ARAM_DAT_DAT         ( peay_aram_dat_dat ),

    .WRAM_ADD_VLD         ( peay_wram_add_vld ),
    .WRAM_ADD_LST         ( peay_wram_add_lst ),
    .WRAM_ADD_RDY         ( peay_wram_add_rdy ),
    .WRAM_ADD_ADD         ( peay_wram_add_add ),
    .WRAM_ADD_BUF         ( peay_wram_add_buf ),
    .WRAM_DAT_VLD         ( peay_wram_dat_vld ),
    .WRAM_DAT_LST         ( peay_wram_dat_lst ),
    .WRAM_DAT_RDY         ( peay_wram_dat_rdy ),
    .WRAM_DAT_DAT         ( peay_wram_dat_dat ),

    .ORAM_DAT_VLD         ( peay_oram_dat_vld ),
    .ORAM_DAT_LST         ( peay_oram_dat_lst ),
    .ORAM_DAT_RDY         ( peay_oram_dat_rdy ),
    .ORAM_DAT_ADD         ( peay_oram_dat_add ),
    .ORAM_DAT_DAT         ( peay_oram_dat_dat )
);

EEG_WRAM_WBUF #(
    .WBUF_NUM_DW          ( WBUF_NUM_DW       ),
    .WRAM_ADD_AW          ( WRAM_ADD_AW       ),
    .WRAM_DAT_DW          ( WRAM_DAT_DW       ),
    .STAT_NUM_DW          ( STAT_NUM_DW       ),
    .STAT_DAT_DW          ( STAT_DAT_DW       )
) EEG_WRAM_WBUF_U[PE_ROW -1:0] (
    .clk                  ( clk               ),
    .rst_n                ( rst_n             ),

    .CFG_INFO_VLD         ( wbuf_cfg_info_vld ),
    .CFG_INFO_RDY         ( wbuf_cfg_info_rdy ),
    .CFG_STAT_VLD         ( cfg_stat_vld ),
    .CFG_WBUF_ENA         ( cfg_wbuf_ena ),

    .MTOW_DAT_VLD         ( wbuf_mtow_dat_vld ),
    .MTOW_DAT_LST         ( wbuf_mtow_dat_lst ),
    .MTOW_DAT_RDY         ( wbuf_mtow_dat_rdy ),
    .MTOW_DAT_DAT         ( wbuf_mtow_dat_dat ),

    .PTOW_ADD_VLD         ( wbuf_ptow_add_vld ),
    .PTOW_ADD_LST         ( wbuf_ptow_add_lst ),
    .PTOW_ADD_RDY         ( wbuf_ptow_add_rdy ),
    .PTOW_ADD_ADD         ( wbuf_ptow_add_add ),
    .PTOW_ADD_BUF         ( wbuf_ptow_add_buf ),
    .PTOW_DAT_VLD         ( wbuf_ptow_dat_vld ),
    .PTOW_DAT_LST         ( wbuf_ptow_dat_lst ),
    .PTOW_DAT_RDY         ( wbuf_ptow_dat_rdy ),
    .PTOW_DAT_DAT         ( wbuf_ptow_dat_dat ),
    
    .WRAM_ADD_VLD         ( wbuf_wram_add_vld ),
    .WRAM_ADD_LST         ( wbuf_wram_add_lst ),
    .WRAM_ADD_RDY         ( wbuf_wram_add_rdy ),
    .WRAM_ADD_ADD         ( wbuf_wram_add_add ),
    .WRAM_DAT_VLD         ( wbuf_wram_dat_vld ),
    .WRAM_DAT_LST         ( wbuf_wram_dat_lst ),
    .WRAM_DAT_RDY         ( wbuf_wram_dat_rdy ),
    .WRAM_DAT_DAT         ( wbuf_wram_dat_dat )
);

EEG_WRAM #(
    .WRAM_CMD_DW          ( WRAM_CMD_DW       ),
    .WRAM_NUM_DW          ( WRAM_NUM_DW       ),
    .WRAM_ADD_AW          ( WRAM_ADD_AW       ),
    .WRAM_DAT_DW          ( WRAM_DAT_DW       )
) EEG_WRAM_U(
    .clk                  ( clk               ),
    .rst_n                ( rst_n             ),

    .IS_IDLE              ( wram_idle         ),

    .CFG_INFO_VLD         ( wram_cfg_info_vld ),
    .CFG_INFO_RDY         ( wram_cfg_info_rdy ),
    .CFG_INFO_CMD         ( wram_cfg_info_cmd ),
    .CFG_WRAM_IDX         ( cfg_wram_idx      ),

    .ETOW_DAT_VLD         ( wram_etow_dat_vld ),
    .ETOW_DAT_LST         ( wram_etow_dat_lst ),
    .ETOW_DAT_RDY         ( wram_etow_dat_rdy ),
    .ETOW_DAT_ADD         ( wram_etow_dat_add ),
    .ETOW_DAT_DAT         ( wram_etow_dat_dat ),

    .ETOW_ADD_VLD         ( wram_etow_add_vld ),
    .ETOW_ADD_LST         ( wram_etow_add_lst ),
    .ETOW_ADD_RDY         ( wram_etow_add_rdy ),
    .ETOW_ADD_ADD         ( wram_etow_add_add ),
    .WTOE_DAT_VLD         ( wram_wtoe_dat_vld ),
    .WTOE_DAT_LST         ( wram_wtoe_dat_lst ),
    .WTOE_DAT_RDY         ( wram_wtoe_dat_rdy ),
    .WTOE_DAT_DAT         ( wram_wtoe_dat_dat )
);

EEG_FRAM #(
    .FRAM_CMD_DW          ( FRAM_CMD_DW       ),
    .FRAM_NUM_DW          ( FRAM_NUM_DW       ),
    .FRAM_ADD_AW          ( FRAM_ADD_AW       ),
    .FRAM_DAT_DW          ( FRAM_DAT_DW       )
) EEG_FRAM_U(
    .clk                  ( clk               ),
    .rst_n                ( rst_n             ),

    .IS_IDLE              ( fram_idle         ),

    .CFG_INFO_VLD         ( fram_cfg_info_vld ),
    .CFG_INFO_RDY         ( fram_cfg_info_rdy ),
    .CFG_INFO_CMD         ( fram_cfg_info_cmd ),
    .CFG_FLAG_VLD         ( cfg_flag_vld      ),

    .ETOF_DAT_VLD         ( fram_etof_dat_vld ),
    .ETOF_DAT_LST         ( fram_etof_dat_lst ),
    .ETOF_DAT_RDY         ( fram_etof_dat_rdy ),
    .ETOF_DAT_ADD         ( fram_etof_dat_add ),
    .ETOF_DAT_DAT         ( fram_etof_dat_dat ),

    .ETOF_ADD_VLD         ( fram_etof_add_vld ),
    .ETOF_ADD_LST         ( fram_etof_add_lst ),
    .ETOF_ADD_RDY         ( fram_etof_add_rdy ),
    .ETOF_ADD_ADD         ( fram_etof_add_add ),
    .FTOE_DAT_VLD         ( fram_ftoe_dat_vld ),
    .FTOE_DAT_LST         ( fram_ftoe_dat_lst ),
    .FTOE_DAT_RDY         ( fram_ftoe_dat_rdy ),
    .FTOE_DAT_DAT         ( fram_ftoe_dat_dat )
);

EEG_ARAM_ROUTER #(
    .ARAM_NUM_DW          ( FRAM_NUM_DW       ),
    .ARAM_ADD_AW          ( FRAM_ADD_AW       ),
    .ARAM_DAT_DW          ( FRAM_DAT_DW       )
) EEG_FRAM_ROUTER_U(
    .clk                  ( clk               ),
    .rst_n                ( rst_n             ),

    .ARAM_ADD_RID         ( farb_aram_add_rid ),
    .ARAM_ADD_VLD         ( farb_aram_add_vld ),
    .ARAM_ADD_LST         ( farb_aram_add_lst ),
    .ARAM_ADD_RDY         ( farb_aram_add_rdy ),
    .ARAM_ADD_DAT         ( farb_aram_add_dat ),
    .ARAM_DAT_VLD         ( farb_aram_dat_vld ),
    .ARAM_DAT_LST         ( farb_aram_dat_lst ),
    .ARAM_DAT_RDY         ( farb_aram_dat_rdy ),
    .ARAM_DAT_DAT         ( farb_aram_dat_dat ),

    .AARB_ADD_VLD         ( farb_aarb_add_vld ),
    .AARB_ADD_LST         ( farb_aarb_add_lst ),
    .AARB_ADD_RDY         ( farb_aarb_add_rdy ),
    .AARB_ADD_DAT         ( farb_aarb_add_dat ),
    .AARB_DAT_VLD         ( farb_aarb_dat_vld ),
    .AARB_DAT_LST         ( farb_aarb_dat_lst ),
    .AARB_DAT_RDY         ( farb_aarb_dat_rdy ),
    .AARB_DAT_DAT         ( farb_aarb_dat_dat )
);

EEG_ARAM #(
    .ARAM_CMD_DW          ( ARAM_CMD_DW       ),
    .ARAM_NUM_DW          ( ARAM_NUM_DW       ),
    .ARAM_ADD_AW          ( ARAM_ADD_AW       ),
    .ARAM_DAT_DW          ( ARAM_DAT_DW       )
) EEG_ARAM_U(
    .clk                  ( clk               ),
    .rst_n                ( rst_n             ),

    .IS_IDLE              ( aram_idle         ),

    .CFG_INFO_VLD         ( aram_cfg_info_vld ),
    .CFG_INFO_RDY         ( aram_cfg_info_rdy ),
    .CFG_INFO_CMD         ( aram_cfg_info_cmd ),
    .CFG_ARAM_IDX         ( cfg_aram_idx     ),

    .ETOA_DAT_VLD         ( aram_etoa_dat_vld ),
    .ETOA_DAT_LST         ( aram_etoa_dat_lst ),
    .ETOA_DAT_RDY         ( aram_etoa_dat_rdy ),
    .ETOA_DAT_ADD         ( aram_etoa_dat_add ),
    .ETOA_DAT_DAT         ( aram_etoa_dat_dat ),

    .ETOA_ADD_VLD         ( aram_etoa_add_vld ),
    .ETOA_ADD_LST         ( aram_etoa_add_lst ),
    .ETOA_ADD_RDY         ( aram_etoa_add_rdy ),
    .ETOA_ADD_ADD         ( aram_etoa_add_add ),
    .ATOE_DAT_VLD         ( aram_atoe_dat_vld ),
    .ATOE_DAT_LST         ( aram_atoe_dat_lst ),
    .ATOE_DAT_RDY         ( aram_atoe_dat_rdy ),
    .ATOE_DAT_DAT         ( aram_atoe_dat_dat )
);

EEG_ARAM_ROUTER #(
    .ARAM_NUM_DW          ( ARAM_NUM_DW       ),
    .ARAM_ADD_AW          ( ARAM_ADD_AW       ),
    .ARAM_DAT_DW          ( ARAM_DAT_DW       )
) EEG_ARAM_ROUTER_U(
    .clk                  ( clk               ),
    .rst_n                ( rst_n             ),

    .ARAM_ADD_RID         ( aarb_aram_add_rid ),
    .ARAM_ADD_VLD         ( aarb_aram_add_vld ),
    .ARAM_ADD_LST         ( aarb_aram_add_lst ),
    .ARAM_ADD_RDY         ( aarb_aram_add_rdy ),
    .ARAM_ADD_DAT         ( aarb_aram_add_dat ),
    .ARAM_DAT_VLD         ( aarb_aram_dat_vld ),
    .ARAM_DAT_LST         ( aarb_aram_dat_lst ),
    .ARAM_DAT_RDY         ( aarb_aram_dat_rdy ),
    .ARAM_DAT_DAT         ( aarb_aram_dat_dat ),

    .AARB_ADD_VLD         ( aarb_aarb_add_vld ),
    .AARB_ADD_LST         ( aarb_aarb_add_lst ),
    .AARB_ADD_RDY         ( aarb_aarb_add_rdy ),
    .AARB_ADD_DAT         ( aarb_aarb_add_dat ),
    .AARB_DAT_VLD         ( aarb_aarb_dat_vld ),
    .AARB_DAT_LST         ( aarb_aarb_dat_lst ),
    .AARB_DAT_RDY         ( aarb_aarb_dat_rdy ),
    .AARB_DAT_DAT         ( aarb_aarb_dat_dat )
);

EEG_ORAM #(
    .ORAM_CMD_DW          ( ORAM_CMD_DW       ),
    .ORAM_NUM_DW          ( ORAM_NUM_DW       ),
    .ORAM_MUX_DW          ( ORAM_MUX_DW       ),
    .ORAM_ADD_AW          ( ORAM_ADD_AW       ),
    .ORAM_ADD_MW          ( ORAM_ADD_MW       ),
    .ORAM_DAT_DW          ( ORAM_DAT_DW       ),
    .ARAM_DAT_DW          ( ARAM_DAT_DW       ),
    .POOL_FAC_DW          ( POOL_FAC_DW       ),
    .CONV_LEN_DW          ( CONV_LEN_DW       )
) EEG_ORAM_U(
    .clk                  ( clk               ),
    .rst_n                ( rst_n             ),

    .IS_IDLE              ( oram_idle         ),

    .CFG_INFO_VLD         ( oram_cfg_info_vld ),
    .CFG_INFO_RDY         ( oram_cfg_info_rdy ),
    .CFG_INFO_CMD         ( oram_cfg_info_cmd ),
    .CFG_CONV_LEN         ( cfg_conv_len      ),
    .CFG_POOL_LEN         ( cfg_pool_len      ),
    .CFG_POOL_FAC         ( cfg_pool_fac      ),
    .CFG_RELU_ENA         ( cfg_relu_ena      ),
    .CFG_SPLT_ENA         ( cfg_splt_ena      ),
    .CFG_COMB_ENA         ( cfg_comb_ena      ),
    .CFG_MAXP_ENA         ( cfg_maxp_ena      ),
    .CFG_AVGP_ENA         ( cfg_avgp_ena      ),

    .ETOO_DAT_VLD         ( oram_etoo_dat_vld ),
    .ETOO_DAT_LST         ( oram_etoo_dat_lst ),
    .ETOO_DAT_RDY         ( oram_etoo_dat_rdy ),
    .ETOO_DAT_ADD         ( oram_etoo_dat_add ),
    .ETOO_DAT_DAT         ( oram_etoo_dat_dat ),

    .ETOO_ADD_VLD         ( oram_etoo_add_vld ),
    .ETOO_ADD_LST         ( oram_etoo_add_lst ),
    .ETOO_ADD_RDY         ( oram_etoo_add_rdy ),
    .ETOO_ADD_ADD         ( oram_etoo_add_add ),
    .OTOE_DAT_VLD         ( oram_otoe_dat_vld ),
    .OTOE_DAT_LST         ( oram_otoe_dat_lst ),
    .OTOE_DAT_RDY         ( oram_otoe_dat_rdy ),
    .OTOE_DAT_DAT         ( oram_otoe_dat_dat )
);

EEG_ORAM_DEMUX #(
    .ORAM_NUM_DW          ( ORAM_NUM_DW       ),
    .ORAM_MUX_DW          ( ORAM_MUX_DW       ),
    .ORAM_ADD_AW          ( ORAM_ADD_AW       ),
    .ORAM_ADD_MW          ( ORAM_ADD_MW       ),
    .ORAM_DAT_DW          ( ORAM_DAT_DW       )
) EEG_ORAM_DEMUX_U(
    .clk                  ( clk               ),
    .rst_n                ( rst_n             ),

    .MUX_MTOO_DAT_VLD     ( omux_mtoo_dat_vld ),
    .MUX_MTOO_DAT_LST     ( omux_mtoo_dat_lst ),
    .MUX_MTOO_DAT_RDY     ( omux_mtoo_dat_rdy ),
    .MUX_MTOO_DAT_ADD     ( omux_mtoo_dat_add ),
    .MUX_MTOO_DAT_DAT     ( omux_mtoo_dat_dat ),

    .MUX_MTOO_ADD_VLD     ( omux_mtoo_add_vld ),
    .MUX_MTOO_ADD_LST     ( omux_mtoo_add_lst ),
    .MUX_MTOO_ADD_RDY     ( omux_mtoo_add_rdy ),
    .MUX_MTOO_ADD_ADD     ( omux_mtoo_add_add ),
    .MUX_OTOM_DAT_VLD     ( omux_otom_dat_vld ),
    .MUX_OTOM_DAT_LST     ( omux_otom_dat_lst ),
    .MUX_OTOM_DAT_RDY     ( omux_otom_dat_rdy ),
    .MUX_OTOM_DAT_DAT     ( omux_otom_dat_dat ),

    .DMX_MTOO_DAT_VLD     ( odmx_mtoo_dat_vld ),
    .DMX_MTOO_DAT_LST     ( odmx_mtoo_dat_lst ),
    .DMX_MTOO_DAT_RDY     ( odmx_mtoo_dat_rdy ),
    .DMX_MTOO_DAT_ADD     ( odmx_mtoo_dat_add ),
    .DMX_MTOO_DAT_DAT     ( odmx_mtoo_dat_dat ),

    .DMX_MTOO_ADD_VLD     ( odmx_mtoo_add_vld ),
    .DMX_MTOO_ADD_LST     ( odmx_mtoo_add_lst ),
    .DMX_MTOO_ADD_RDY     ( odmx_mtoo_add_rdy ),
    .DMX_MTOO_ADD_ADD     ( odmx_mtoo_add_add ),
    .DMX_OTOM_DAT_VLD     ( odmx_otom_dat_vld ),
    .DMX_OTOM_DAT_LST     ( odmx_otom_dat_lst ),
    .DMX_OTOM_DAT_RDY     ( odmx_otom_dat_rdy ),
    .DMX_OTOM_DAT_DAT     ( odmx_otom_dat_dat )
);

//MOVER
EEG_RAM_MOVER #(
    .MOVE_CMD_DW          ( MOVE_CMD_DW       ),
    .MOVE_DAT_DW          ( MOVE_DAT_DW       ),
    .BANK_NUM_DW          ( BANK_NUM_DW       ),
    .ARAM_ADD_AW          ( ARAM_ADD_AW       ),
    .WRAM_ADD_AW          ( WRAM_ADD_AW       ),
    .ORAM_ADD_AW          ( ORAM_ADD_AW       ),
    .CONV_LEN_DW          ( CONV_LEN_DW       ),
    .CONV_ICH_DW          ( CONV_ICH_DW       ),
    .CONV_OCH_DW          ( CONV_OCH_DW       ),
    .CONV_WEI_DW          ( CONV_WEI_DW       ),
    .CONV_SPT_DW          ( CONV_SPT_DW       ),
    .STAT_NUM_DW          ( STAT_NUM_DW       ),
    .FRAM_DAT_DW          ( FRAM_DAT_DW       )
) EEG_RAM_MOVER_U(
    .clk                  ( clk               ),
    .rst_n                ( rst_n             ),

    .IS_IDLE              ( move_idle         ),

    .CFG_INFO_VLD         ( move_cfg_info_vld ),
    .CFG_INFO_RDY         ( move_cfg_info_rdy ),
    .CFG_INFO_CMD         ( move_cfg_info_cmd ),
    .CFG_ARAM_IDX         ( cfg_aram_idx ),
    .CFG_WRAM_IDX         ( cfg_wram_idx ),
    .CFG_ORAM_IDX         ( cfg_oram_idx ),
    .CFG_ARAM_ADD         ( cfg_aram_add ),
    .CFG_WRAM_ADD         ( cfg_wram_add ),
    .CFG_ORAM_ADD         ( cfg_oram_add ),
    .CFG_ARAM_LEN         ( cfg_aram_len ),
    .CFG_WRAM_LEN         ( cfg_wram_len ),
    .CFG_ORAM_LEN         ( cfg_oram_len ),
    .CFG_CONV_LEN         ( cfg_conv_len ),
    .CFG_CONV_OCH         ( cfg_conv_och ),
    .CFG_CONV_WEI         ( cfg_conv_wei ),
    .CFG_FLAG_ENA         ( cfg_flag_ena ),
    .CFG_SPLT_ENA         ( cfg_splt_ena ),
    .CFG_SPLT_LEN         ( cfg_splt_len ),

    .ITOM_DAT_VLD         ( move_itom_dat_vld ),
    .ITOM_DAT_LST         ( move_itom_dat_lst ),
    .ITOM_DAT_RDY         ( move_itom_dat_rdy ),
    .ITOM_DAT_DAT         ( move_itom_dat_dat ),

    .MTOS_DAT_VLD         ( move_mtos_dat_vld ),
    .MTOS_DAT_LST         ( move_mtos_dat_lst ),
    .MTOS_DAT_RDY         ( move_mtos_dat_rdy ),
    .MTOS_DAT_ADD         ( move_mtos_dat_add ),
    .MTOS_DAT_DAT         ( move_mtos_dat_dat ),

    .MTOF_DAT_VLD         ( move_mtof_dat_vld ),
    .MTOF_DAT_LST         ( move_mtof_dat_lst ),
    .MTOF_DAT_RDY         ( move_mtof_dat_rdy ),
    .MTOF_DAT_ADD         ( move_mtof_dat_add ),
    .MTOF_DAT_DAT         ( move_mtof_dat_dat ),

    .MTOA_DAT_VLD         ( move_mtoa_dat_vld ),
    .MTOA_DAT_LST         ( move_mtoa_dat_lst ),
    .MTOA_DAT_RDY         ( move_mtoa_dat_rdy ),
    .MTOA_DAT_ADD         ( move_mtoa_dat_add ),
    .MTOA_DAT_DAT         ( move_mtoa_dat_dat ),

    .MTOA_ADD_VLD         ( move_mtoa_add_vld ),
    .MTOA_ADD_LST         ( move_mtoa_add_lst ),
    .MTOA_ADD_RDY         ( move_mtoa_add_rdy ),
    .MTOA_ADD_DAT         ( move_mtoa_add_dat ),
    .ATOM_DAT_VLD         ( move_atom_dat_vld ),
    .ATOM_DAT_LST         ( move_atom_dat_lst ),
    .ATOM_DAT_RDY         ( move_atom_dat_rdy ),
    .ATOM_DAT_DAT         ( move_atom_dat_dat ),

    .MTOW_DAT_VLD         ( move_mtow_dat_vld ),
    .MTOW_DAT_LST         ( move_mtow_dat_lst ),
    .MTOW_DAT_RDY         ( move_mtow_dat_rdy ),
    .MTOW_DAT_ADD         ( move_mtow_dat_add ),
    .MTOW_DAT_DAT         ( move_mtow_dat_dat ),

    .MTOW_ADD_VLD         ( move_mtow_add_vld ),
    .MTOW_ADD_LST         ( move_mtow_add_lst ),
    .MTOW_ADD_RDY         ( move_mtow_add_rdy ),
    .MTOW_ADD_DAT         ( move_mtow_add_dat ),
    .WTOM_DAT_VLD         ( move_wtom_dat_vld ),
    .WTOM_DAT_LST         ( move_wtom_dat_lst ),
    .WTOM_DAT_RDY         ( move_wtom_dat_rdy ),
    .WTOM_DAT_DAT         ( move_wtom_dat_dat ),

    .MTOO_DAT_VLD         ( move_mtoo_dat_vld ),
    .MTOO_DAT_LST         ( move_mtoo_dat_lst ),
    .MTOO_DAT_RDY         ( move_mtoo_dat_rdy ),
    .MTOO_DAT_ADD         ( move_mtoo_dat_add ),
    .MTOO_DAT_DAT         ( move_mtoo_dat_dat ),

    .MTOO_ADD_VLD         ( move_mtoo_add_vld ),
    .MTOO_ADD_LST         ( move_mtoo_add_lst ),
    .MTOO_ADD_RDY         ( move_mtoo_add_rdy ),
    .MTOO_ADD_ADD         ( move_mtoo_add_add ),
    .OTOM_DAT_VLD         ( move_otom_dat_vld ),
    .OTOM_DAT_LST         ( move_otom_dat_lst ),
    .OTOM_DAT_RDY         ( move_otom_dat_rdy ),
    .OTOM_DAT_DAT         ( move_otom_dat_dat )
);
//=====================================================================================================================
// FSM :
//=====================================================================================================================
wire [ACC_STATE -1:0] ACC_NEXT = {cfg_info_cmd, 2'b00, ~|cfg_info_cmd};
always @ ( * )begin
    case( acc_cs )
        ACC_IDLE: acc_ns = acc_idle_done ? ACC_LOAD : acc_cs;
        ACC_LOAD: acc_ns = acc_load_done ? ACC_ACMD : acc_cs;
        ACC_ACMD: acc_ns = acc_acmd_done ? ACC_NEXT : acc_cs;
        ACC_ITOA: acc_ns = acc_itoa_done ? ACC_IDLE : acc_cs;
        ACC_ITOW: acc_ns = acc_itow_done ? ACC_IDLE : acc_cs;
        ACC_OTOA: acc_ns = acc_otoa_done ? ACC_IDLE : acc_cs;
        ACC_ATOW: acc_ns = acc_atow_done ? ACC_IDLE : acc_cs;
        ACC_WTOA: acc_ns = acc_wtoa_done ? ACC_IDLE : acc_cs;
        ACC_CONV: acc_ns = acc_conv_done ? ACC_IDLE : acc_cs;
        ACC_POOL: acc_ns = acc_pool_done ? ACC_IDLE : acc_cs;
        ACC_STAT: acc_ns = acc_stat_done ? ACC_IDLE : acc_cs;
        ACC_READ: acc_ns = acc_read_done ? ACC_IDLE : acc_cs;
         default: acc_ns = ACC_IDLE;
    endcase
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        acc_cs <= ACC_IDLE;
    else
        acc_cs <= acc_ns;
end

`ifdef ASSERT_ON


`endif
endmodule
