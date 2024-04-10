//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description : PE ARRAY DATA GENERATE
//========================================================
module EEG_PEA_DAT_GEN #(
    parameter PE_COL    = 4,    
    parameter PE_ROW    = 4,
    parameter PE_ACT_DW = 8,
    parameter PE_WEI_DW = 8,
    parameter CONV_ICH_DW =  8,//256
    parameter CONV_OCH_DW =  8,//256
    parameter CONV_LEN_DW = 10,//1024
    parameter CONV_WEI_DW =  3,//8
    parameter CONV_RUN_DW =  4,//1-8
    parameter DILA_FAC_DW =  2,//8
    parameter STRD_FAC_DW =  2,//8
    parameter ARAM_NUM_AW =  2,
    parameter ARAM_ADD_AW = 12,//4k
    parameter WRAM_ADD_AW = 13,//8k
    parameter FRAM_ADD_AW = ARAM_ADD_AW,
    parameter ARAM_DAT_DW = PE_ACT_DW,
    parameter WRAM_DAT_DW = PE_WEI_DW,
    parameter FRAM_DAT_DW = 4,
    parameter STAT_DAT_DW = CONV_ICH_DW+CONV_WEI_DW,
    parameter PE_ACT_IW = ARAM_ADD_AW,
    parameter PE_WEI_IW = CONV_WEI_DW
  )(
    input                                     clk,
    input                                     rst_n,
    
    output                                    IS_IDLE,
    
    input  [2                           -1:0] PEA_GEN_CIDX,
    input                                     PEA_GEN_LPAD,
    input                                     PEA_GEN_RPAD,
                                        
    input                                     CFG_INFO_VLD,
    output                                    CFG_INFO_RDY,
    input  [ARAM_ADD_AW                 -1:0] CFG_ARAM_ADD,
    input  [WRAM_ADD_AW                 -1:0] CFG_WRAM_ADD,
    
    input                                     CFG_FLAG_VLD,
    input                                     CFG_SPLT_ENA,
    input  [CONV_ICH_DW                 -1:0] CFG_CONV_ICH,
    input  [CONV_OCH_DW                 -1:0] CFG_CONV_OCH,
    input  [CONV_LEN_DW                 -1:0] CFG_CONV_LEN,
    input  [CONV_WEI_DW                 -1:0] CFG_CONV_WEI,
    input  [DILA_FAC_DW                 -1:0] CFG_DILA_FAC,
    input  [STRD_FAC_DW                 -1:0] CFG_STRD_FAC,

    output [ARAM_NUM_AW                 -1:0] FRAM_ADD_RID,
    output                                    FRAM_ADD_VLD,
    output                                    FRAM_ADD_LST,
    input                                     FRAM_ADD_RDY,
    output [FRAM_ADD_AW                 -1:0] FRAM_ADD_ADD,
    input                                     FRAM_DAT_VLD,
    input                                     FRAM_DAT_LST,
    output                                    FRAM_DAT_RDY,
    input  [FRAM_DAT_DW                 -1:0] FRAM_DAT_DAT,

    output [ARAM_NUM_AW                 -1:0] ARAM_ADD_RID,
    output                                    ARAM_ADD_VLD,
    output                                    ARAM_ADD_LST,
    input                                     ARAM_ADD_RDY,
    output [ARAM_ADD_AW                 -1:0] ARAM_ADD_ADD,
    input                                     ARAM_DAT_VLD,
    input                                     ARAM_DAT_LST,
    output                                    ARAM_DAT_RDY,
    input  [ARAM_DAT_DW                 -1:0] ARAM_DAT_DAT,

    output [PE_ROW -1:0]                      WRAM_ADD_VLD,
    output [PE_ROW -1:0]                      WRAM_ADD_LST,
    input  [PE_ROW -1:0]                      WRAM_ADD_RDY,
    output [PE_ROW -1:0][WRAM_ADD_AW    -1:0] WRAM_ADD_ADD,
    output [PE_ROW -1:0][STAT_DAT_DW    -1:0] WRAM_ADD_BUF,
    input  [PE_ROW -1:0]                      WRAM_DAT_VLD,
    input  [PE_ROW -1:0]                      WRAM_DAT_LST,
    output [PE_ROW -1:0]                      WRAM_DAT_RDY,
    input  [PE_ROW -1:0][WRAM_DAT_DW    -1:0] WRAM_DAT_DAT,

    output                                    ACT_VLD,
    output                                    ACT_LST,
    input                                     ACT_RDY,
    output              [PE_ACT_DW      -1:0] ACT_DAT,
    output              [PE_ACT_IW      -1:0] ACT_INF,
                                        
    output [PE_ROW -1:0]                      WEI_VLD,
    output [PE_ROW -1:0]                      WEI_LST,
    input  [PE_ROW -1:0]                      WEI_RDY,
    output [PE_ROW -1:0][PE_WEI_DW      -1:0] WEI_DAT,
    output [PE_ROW -1:0][PE_WEI_IW      -1:0] WEI_INF
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
localparam FRAM_BUF_DW = FRAM_DAT_DW +FRAM_ADD_AW +2+1 +CONV_OCH_DW-2 +CONV_ICH_DW +CONV_LEN_DW;
localparam ARAM_BUF_DW = ARAM_DAT_DW +ARAM_ADD_AW +1;
localparam WRAM_BUF_DW = WRAM_DAT_DW +CONV_WEI_DW +1;
localparam FRAM_BUF_NUM = 4;
localparam ARAM_BUF_NUM = 4;
localparam WRAM_BUF_NUM = 4;
localparam FRAM_BUF_AW = $clog2(FRAM_BUF_NUM);
localparam ARAM_BUF_AW = $clog2(ARAM_BUF_NUM);
localparam WRAM_BUF_AW = $clog2(WRAM_BUF_NUM);

localparam FADD_BUF_DW = FRAM_ADD_AW +2;
localparam FADD_BUF_NUM = 2;
localparam FADD_BUF_AW = $clog2(FADD_BUF_NUM);

localparam AADD_BUF_DW = FRAM_ADD_AW +2+1;
localparam AADD_BUF_NUM = 4;
localparam AADD_BUF_AW = $clog2(AADD_BUF_NUM);

localparam WNCH_BUF_DW = CONV_ICH_DW +CONV_OCH_DW +1;
localparam WNCH_BUF_NUM = 4;
localparam WNCH_BUF_AW = $clog2(WNCH_BUF_NUM);

localparam WWEI_BUF_DW = CONV_WEI_DW +CONV_WEI_DW +1;
localparam WWEI_BUF_NUM = 16;
localparam WWEI_BUF_AW = $clog2(WWEI_BUF_NUM);
localparam WWEI_MAXLEN = 1<<CONV_WEI_DW;

localparam FRAM_DAT_AW = $clog2(FRAM_DAT_DW);

localparam DILA_LEN_DW = CONV_RUN_DW;
localparam STRD_LEN_DW = CONV_RUN_DW;

integer i;
genvar gen_i, gen_j;

localparam FF_STATE = 6;
localparam FF_IDLE  = 6'b000001;
localparam FF_LOAD  = 6'b000010;
localparam FF_LPAD  = 6'b000100;
localparam FF_TILE  = 6'b001000;
localparam FF_RPAD  = 6'b010000;
localparam FF_DONE  = 6'b100000;

reg [FF_STATE -1:0] ff_cs;
reg [FF_STATE -1:0] ff_ns;

wire ff_idle = ff_cs == FF_IDLE;
wire ff_load = ff_cs == FF_LOAD;
wire ff_lpad = ff_cs == FF_LPAD;
wire ff_tile = ff_cs == FF_TILE;
wire ff_rpad = ff_cs == FF_RPAD;
wire ff_done = ff_cs == FF_DONE;
wire ff_conv = ff_cs == FF_LPAD || ff_cs == FF_TILE || ff_cs == FF_RPAD;

//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
wire cfg_info_vld = CFG_INFO_VLD;
wire cfg_info_rdy = ff_idle;

assign CFG_INFO_RDY = cfg_info_rdy;
//FRAM_IO
reg  [ARAM_NUM_AW -1:0] fram_add_rid;
reg                     fram_add_vld;
reg                     fram_add_lst;
wire                    fram_add_rdy= FRAM_ADD_RDY;
reg  [FRAM_ADD_AW -1:0] fram_add_add;
wire                    fram_dat_vld= FRAM_DAT_VLD;
wire                    fram_dat_lst= FRAM_DAT_LST;
reg                     fram_dat_rdy;
wire [FRAM_DAT_DW -1:0] fram_dat_dat= FRAM_DAT_DAT;

assign FRAM_ADD_VLD = fram_add_vld;
assign FRAM_ADD_LST = fram_add_lst;
assign FRAM_ADD_ADD = fram_add_add;
assign FRAM_ADD_RID = fram_add_rid;
assign FRAM_DAT_RDY = fram_dat_rdy;

//ARAM_IO
reg  [ARAM_NUM_AW -1:0] aram_add_rid;
reg                     aram_add_vld;
reg                     aram_add_lst;
wire                    aram_add_rdy= ARAM_ADD_RDY;
reg  [ARAM_ADD_AW -1:0] aram_add_add;
wire                    aram_dat_vld= ARAM_DAT_VLD;
wire                    aram_dat_lst= ARAM_DAT_LST;
reg                     aram_dat_rdy;
wire [ARAM_DAT_DW -1:0] aram_dat_dat= ARAM_DAT_DAT;

assign ARAM_ADD_VLD = aram_add_vld;
assign ARAM_ADD_LST = aram_add_lst;
assign ARAM_ADD_RID = aram_add_rid;
assign ARAM_ADD_ADD = aram_add_add;
assign ARAM_DAT_RDY = aram_dat_rdy;

//WRAM_IO
reg  [PE_ROW -1:0]                     wram_add_vld;
reg  [PE_ROW -1:0]                     wram_add_lst;
wire [PE_ROW -1:0]                     wram_add_rdy= WRAM_ADD_RDY;
reg  [PE_ROW -1:0][WRAM_ADD_AW   -1:0] wram_add_add;
reg  [PE_ROW -1:0][STAT_DAT_DW   -1:0] wram_add_buf;
wire [PE_ROW -1:0]                     wram_dat_vld= WRAM_DAT_VLD;
wire [PE_ROW -1:0]                     wram_dat_lst= WRAM_DAT_LST;
reg  [PE_ROW -1:0]                     wram_dat_rdy;
wire [PE_ROW -1:0][WRAM_DAT_DW   -1:0] wram_dat_dat= WRAM_DAT_DAT;

assign WRAM_ADD_VLD = wram_add_vld;
assign WRAM_ADD_LST = wram_add_lst;
assign WRAM_ADD_ADD = wram_add_add;
assign WRAM_ADD_BUF = wram_add_buf;
assign WRAM_DAT_RDY = wram_dat_rdy;

//DATA_IO
reg                                act_vld;
wire                               act_rdy= ACT_RDY;
reg               [PE_ACT_DW -1:0] act_dat;
reg                                act_lst;
reg               [PE_ACT_IW -1:0] act_inf;
reg  [PE_ROW -1:0]                 wei_vld;
reg  [PE_ROW -1:0]                 wei_lst;
wire [PE_ROW -1:0]                 wei_rdy= WEI_RDY;
reg  [PE_ROW -1:0][PE_WEI_DW -1:0] wei_dat;
reg  [PE_ROW -1:0][PE_WEI_IW -1:0] wei_inf;

assign ACT_DAT = act_dat;
assign ACT_VLD = act_vld;
assign ACT_LST = act_lst;
assign ACT_INF = act_inf;
assign WEI_DAT = wei_dat;
assign WEI_VLD = wei_vld;
assign WEI_LST = wei_lst;
assign WEI_INF = wei_inf;

assign IS_IDLE = ff_idle;
//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================
wire cfg_info_ena = CFG_INFO_VLD & CFG_INFO_RDY;

wire fram_add_ena = FRAM_ADD_VLD & FRAM_ADD_RDY;
wire fram_dat_ena = FRAM_DAT_VLD & FRAM_DAT_RDY;
wire aram_add_ena = ARAM_ADD_VLD & ARAM_ADD_RDY;
wire aram_dat_ena = ARAM_DAT_VLD & ARAM_DAT_RDY;

wire [PE_ROW -1:0] wram_add_ena = WRAM_ADD_VLD & WRAM_ADD_RDY;
wire [PE_ROW -1:0] wram_dat_ena = WRAM_DAT_VLD & WRAM_DAT_RDY;

reg  [2                       -1:0] ff_ridx;
reg  [DILA_LEN_DW             -1:0] ff_didx;
reg  [CONV_OCH_DW-2           -1:0] ff_oidx;
wire [CONV_OCH_DW+DILA_LEN_DW -1:0] ff_tidx; //= ff_oidx<<cfg_dila_fac +ff_didx;
reg  [CONV_ICH_DW             -1:0] ff_iidx;
reg  [CONV_LEN_DW             -1:0] ff_pidx;

wire [2                       -1:0] ff_ridx_d1;
wire [DILA_LEN_DW             -1:0] ff_didx_d1;
wire [CONV_OCH_DW-2           -1:0] ff_oidx_d1;
wire [CONV_OCH_DW+DILA_LEN_DW -1:0] ff_tidx_d1;
wire [CONV_ICH_DW             -1:0] ff_iidx_d1;
wire [CONV_LEN_DW             -1:0] ff_pidx_d1;

reg  [ARAM_ADD_AW -1:0] cfg_aram_add;
reg  [WRAM_ADD_AW -1:0] cfg_wram_add;
reg                     cfg_flag_vld;
reg                     cfg_splt_ena;
reg  [CONV_ICH_DW -1:0] cfg_conv_ich;
reg  [CONV_OCH_DW -1:0] cfg_conv_och;
reg  [CONV_LEN_DW -1:0] cfg_conv_len;
reg  [CONV_WEI_DW -1:0] cfg_conv_wei;
reg  [DILA_FAC_DW -1:0] cfg_dila_fac;
reg  [STRD_FAC_DW -1:0] cfg_strd_fac;

reg  [CONV_WEI_DW -1:0] cal_lpad_len;//real num
reg  [CONV_WEI_DW -1:0] cal_rpad_len;//real num
wire [3           -1:0] cal_dila_len = cfg_dila_fac == 'd3 ? 'd7 : cfg_dila_fac == 'd2 ? 'd3 : cfg_dila_fac == 'd2 ? 'd1 : 'd0;
reg  [3           -1:0] cal_step_ich;
reg  [4           -1:0] cal_step_pix;
reg  [CONV_ICH_DW -1:0] cal_last_ich;
reg  [CONV_LEN_DW -1:0] cal_last_pix;
reg  [FRAM_DAT_DW -1:0] cal_flag_nzf;


reg  [FRAM_ADD_AW -1:0] ff_addr;
reg  [CONV_ICH_DW -1:0] ff_cntr_ich;
reg  [CONV_LEN_DW -1:0] ff_cntr_pix;

wire ff_last_didx = ff_didx==cal_dila_len;
wire ff_last_oidx = ff_oidx==cfg_conv_och[CONV_OCH_DW -1:2];

wire ff_last_ich = ff_cntr_ich==cal_last_ich;
wire ff_last_pix = ff_cntr_pix==cal_last_pix;

wire ff_lpad_done = fram_add_ena&&ff_last_ich&&ff_cntr_pix==(cal_lpad_len-'d1);
wire ff_tile_done = fram_add_ena&&ff_last_ich&&ff_last_pix;
wire ff_rpad_done = fram_add_ena&&ff_last_ich&&ff_cntr_pix==(cal_rpad_len-'d1);
wire ff_conv_done = ff_last_didx&&ff_last_oidx;


//FADD_FIFO
wire fadd_fifo_wen = fram_add_ena;
wire fadd_fifo_ren = fram_dat_ena;
wire fadd_fifo_empty;
wire fadd_fifo_full;
wire [FADD_BUF_DW -1:0] fadd_fifo_din = {fram_add_rid, fram_add_add};
wire [FADD_BUF_DW -1:0] fadd_fifo_out;
wire [FADD_BUF_AW   :0] fadd_fifo_cnt;
wire [FRAM_ADD_AW -1:0] fram_dat_add = fadd_fifo_out[0 +:FRAM_ADD_AW];
wire [2           -1:0] fram_dat_rid = fadd_fifo_out[FRAM_ADD_AW +:2];
wire [CONV_OCH_DW -3:0] fram_dat_odx = ff_oidx_d1;
wire [CONV_ICH_DW -1:0] fram_dat_idx = ff_iidx_d1;
wire [CONV_LEN_DW -1:0] fram_dat_pdx = ff_pidx_d1;

CPM_FIFO #( .DATA_WIDTH( FADD_BUF_DW ), .ADDR_WIDTH( FADD_BUF_AW ) ) FADD_FIFO_U( clk, rst_n, 1'd0, fadd_fifo_wen, fadd_fifo_ren, fadd_fifo_din, fadd_fifo_out, fadd_fifo_empty, fadd_fifo_full, fadd_fifo_cnt);

CPM_REG_E #( 2                       ) FF_RIDX_REG( clk, rst_n, fram_add_ena, ff_ridx, ff_ridx_d1 );
CPM_REG_E #( DILA_LEN_DW             ) FF_DIDX_REG( clk, rst_n, fram_add_ena, ff_didx, ff_didx_d1 );
CPM_REG_E #( CONV_OCH_DW-2           ) FF_OIDX_REG( clk, rst_n, fram_add_ena, ff_oidx, ff_oidx_d1 );
CPM_REG_E #( CONV_OCH_DW+DILA_LEN_DW ) FF_TIDX_REG( clk, rst_n, fram_add_ena, ff_tidx, ff_tidx_d1 );
CPM_REG_E #( CONV_ICH_DW             ) FF_IIDX_REG( clk, rst_n, fram_add_ena, ff_iidx, ff_iidx_d1 );
CPM_REG_E #( CONV_LEN_DW             ) FF_PIDX_REG( clk, rst_n, fram_add_ena, ff_pidx, ff_pidx_d1 );

wire fa_fifo_rdy;
wire fw_fifo_rdy;
wire ff_fifo_wen = fram_dat_ena;
wire ff_fifo_ren;
wire ff_fifo_empty;
wire ff_fifo_full;
wire [FRAM_BUF_DW -1:0] ff_fifo_din = {ff_done, fram_dat_pdx, fram_dat_idx, fram_dat_odx, fram_dat_rid, fram_dat_add, fram_dat_dat | cal_flag_nzf};
wire [FRAM_BUF_DW -1:0] ff_fifo_out;
wire [FRAM_DAT_DW -1:0] ff_fifo_nzf = ff_fifo_out[0 +:FRAM_DAT_DW];
wire [FRAM_ADD_AW -1:0] ff_fifo_add = ff_fifo_out[FRAM_DAT_DW +:FRAM_ADD_AW];
wire [2           -1:0] ff_fifo_rid = ff_fifo_out[FRAM_DAT_DW + FRAM_ADD_AW +:2];
wire [CONV_OCH_DW -3:0] ff_fifo_odx = ff_fifo_out[FRAM_DAT_DW + FRAM_ADD_AW + 2 +:CONV_OCH_DW-2];
wire [CONV_ICH_DW -1:0] ff_fifo_idx = ff_fifo_out[FRAM_DAT_DW + FRAM_ADD_AW + 2 + CONV_OCH_DW-2 +:CONV_ICH_DW];
wire [CONV_LEN_DW -1:0] ff_fifo_pdx = ff_fifo_out[FRAM_DAT_DW + FRAM_ADD_AW + 2 + CONV_OCH_DW-2 + CONV_ICH_DW +:CONV_LEN_DW];
wire                    ff_fifo_lst = ff_fifo_out[FRAM_BUF_DW-1];
reg  [FRAM_DAT_DW -1:0] ff_mask_nzf;
reg  [FRAM_DAT_DW -1:0] ff_flag_fix;
reg  [FRAM_DAT_AW -1:0] ff_flag_idx;
reg  [FRAM_DAT_AW   :0] ff_flag_sum;
wire [FRAM_BUF_AW   :0] ff_fifo_cnt;

wire [ARAM_ADD_AW -1:0] ff_fifo_aram_add = ff_fifo_pdx +ff_flag_idx*(cfg_conv_len+'d1);

assign ff_fifo_ren = ~ff_fifo_empty && fw_fifo_rdy && fa_fifo_rdy && ff_flag_sum<='d1;
wire ff_fifo_wen_rdy = ~ff_fifo_empty && fw_fifo_rdy && fa_fifo_rdy && |ff_flag_fix;
//AADD_FIFO
wire aadd_fifo_wen = ff_fifo_wen_rdy;
wire aadd_fifo_ren;
wire aadd_fifo_empty;
wire aadd_fifo_full;
wire [AADD_BUF_DW -1:0] aadd_fifo_din = {ff_fifo_lst, ff_fifo_rid, ff_fifo_aram_add};
wire [AADD_BUF_DW -1:0] aadd_fifo_out;
wire [AADD_BUF_AW   :0] aadd_fifo_cnt;
assign fa_fifo_rdy = ~aadd_fifo_full;

//FWEI_FIFO
wire fwei_fifo_wen = ff_fifo_wen_rdy;
reg  fwei_fifo_ren;
wire fwei_fifo_empty;
wire fwei_fifo_full;
reg  [WWEI_MAXLEN -1:0][WWEI_BUF_DW -1:0] fwei_fifo_din;
reg  [WWEI_MAXLEN -1:0][CONV_WEI_DW -1:0] fwei_widx_din;
reg  [WWEI_MAXLEN -1:0][CONV_WEI_DW -1:0] fwei_wfid_din;
reg  [WWEI_MAXLEN -1:0] fwei_last_din;
wire [WWEI_BUF_DW -1:0] fwei_fifo_out;
wire                    fwei_fifo_lst = fwei_fifo_out[WWEI_BUF_DW-1];
wire [CONV_WEI_DW -1:0] fwei_fifo_wid = fwei_fifo_out[0 +:CONV_WEI_DW];//raw wei_idx for cal add
wire [CONV_WEI_DW -1:0] fwei_fifo_fid = fwei_fifo_out[CONV_WEI_DW +:CONV_WEI_DW];//fix wei_idx for cal psum
wire [WWEI_BUF_AW   :0] fwei_fifo_cnt;
wire [WWEI_BUF_AW   :0] fwei_fifo_cnt_empty;
reg  [CONV_WEI_DW -1:0] fwei_fifo_num;

//FNCH_FIFO
wire fnch_fifo_wen = ff_fifo_wen_rdy;
wire fnch_fifo_ren = fwei_fifo_ren && fwei_fifo_lst;
wire fnch_fifo_empty;
wire fnch_fifo_full;
wire [WNCH_BUF_DW -1:0] fnch_fifo_din = {ff_fifo_lst, ff_fifo_odx, ff_fifo_idx};
wire [WNCH_BUF_DW -1:0] fnch_fifo_out;
wire [CONV_ICH_DW -1:0] fnch_fifo_ich = fnch_fifo_out[0 +:CONV_ICH_DW];
wire [CONV_OCH_DW -1:0] fnch_fifo_och = fnch_fifo_out[CONV_ICH_DW +:CONV_OCH_DW];
wire [CONV_OCH_DW -1:0] fnch_fifo_lst = fnch_fifo_out[WNCH_BUF_DW -1];
wire [WNCH_BUF_AW   :0] fnch_fifo_cnt;
assign fw_fifo_rdy = ~fnch_fifo_full && fwei_fifo_cnt_empty>fwei_fifo_num;

CPM_FIFO #( .DATA_WIDTH( FRAM_BUF_DW ), .ADDR_WIDTH( FRAM_BUF_AW ) )FNZF_FIFO_U( clk, rst_n, 1'd0, ff_fifo_wen, ff_fifo_ren, ff_fifo_din, ff_fifo_out, ff_fifo_empty, ff_fifo_full, ff_fifo_cnt);

CPM_FIFO      #( .DATA_WIDTH( AADD_BUF_DW ), .ADDR_WIDTH( AADD_BUF_AW )                           )AADD_FIFO_U( clk, rst_n, 1'd0, aadd_fifo_wen, aadd_fifo_ren, aadd_fifo_din,                aadd_fifo_out, aadd_fifo_empty, aadd_fifo_full, aadd_fifo_cnt);
CPM_MISO_FIFO #( .DATA_WIDTH( WWEI_BUF_DW ), .ADDR_WIDTH( WWEI_BUF_AW ), .DATA_NUMAW(CONV_WEI_DW) )FWEI_FIFO_U( clk, rst_n, 1'd0, fwei_fifo_wen, fwei_fifo_ren, fwei_fifo_din, fwei_fifo_num, fwei_fifo_out, fwei_fifo_empty, fwei_fifo_full, fwei_fifo_cnt, fwei_fifo_cnt_empty);
CPM_FIFO      #( .DATA_WIDTH( WNCH_BUF_DW ), .ADDR_WIDTH( WNCH_BUF_AW )                           )FNCH_FIFO_U( clk, rst_n, 1'd0, fnch_fifo_wen, fnch_fifo_ren, fnch_fifo_din,                fnch_fifo_out, fnch_fifo_empty, fnch_fifo_full, fnch_fifo_cnt);

wire [ARAM_ADD_AW -1:0] aram_dat_add;
CPM_REG_E #( ARAM_ADD_AW ) ARAM_ADDR_REG( clk, rst_n, aram_add_ena, aram_add_add, aram_dat_add );

wire [PE_ROW-1:0] wram_wei_lst;//last for cal psum
wire [PE_ROW-1:0][CONV_WEI_DW -1:0] wram_wei_fid;
CPM_REG_E #( 1           ) WRAM_LAST_REG [PE_ROW-1:0]( clk, rst_n, wram_add_ena, fwei_fifo_lst, wram_wei_lst );
CPM_REG_E #( CONV_WEI_DW ) WRAM_WFID_REG [PE_ROW-1:0]( clk, rst_n, wram_add_ena, fwei_fifo_fid, wram_wei_fid );

//ARAM
wire aram_fifo_wen = aram_dat_ena;
wire aram_fifo_ren = act_rdy;
wire aram_fifo_empty;
wire aram_fifo_full;
wire [ARAM_BUF_DW -1:0] aram_fifo_din = {aram_dat_lst, aram_dat_add, aram_dat_dat};
wire [ARAM_BUF_DW -1:0] aram_fifo_out;
wire [ARAM_BUF_AW   :0] aram_fifo_cnt;
wire [ARAM_BUF_AW   :0] aram_fifo_cnt_empty;
assign aadd_fifo_ren = aram_fifo_cnt_empty > 'd1;

//WRAM
wire [PE_ROW -1:0] wram_fifo_wen = wram_dat_ena;
wire [PE_ROW -1:0] wram_fifo_ren = wei_rdy;
wire [PE_ROW -1:0] wram_fifo_empty;
wire [PE_ROW -1:0] wram_fifo_full;
reg  [PE_ROW -1:0] wram_fifo_not_almost_full;
reg  [PE_ROW -1:0][WRAM_BUF_DW -1:0] wram_fifo_din;
wire [PE_ROW -1:0][WRAM_BUF_DW -1:0] wram_fifo_out;
wire [PE_ROW -1:0][WRAM_BUF_AW   :0] wram_fifo_cnt;
wire [PE_ROW -1:0][WRAM_BUF_AW   :0] wram_fifo_cnt_empty;

CPM_FIFO_EX #( .DATA_WIDTH( ARAM_BUF_DW ), .ADDR_WIDTH( ARAM_BUF_AW ) )ARAM_FIFO_U             ( clk, rst_n, 1'd0, aram_fifo_wen, aram_fifo_ren, aram_fifo_din, aram_fifo_out, aram_fifo_empty, aram_fifo_full, aram_fifo_cnt, aram_fifo_cnt_empty );
CPM_FIFO_EX #( .DATA_WIDTH( WRAM_BUF_DW ), .ADDR_WIDTH( WRAM_BUF_AW ) )WRAM_FIFO_U [PE_ROW-1:0]( clk, rst_n, 1'd0, wram_fifo_wen, wram_fifo_ren, wram_fifo_din, wram_fifo_out, wram_fifo_empty, wram_fifo_full, wram_fifo_cnt, wram_fifo_cnt_empty );

//=====================================================================================================================
// IO Logic Design :
//=====================================================================================================================
generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            wei_vld[gen_i] = ~wram_fifo_empty[gen_i];
            wei_dat[gen_i] = wram_fifo_out[gen_i][0 +:PE_WEI_DW];
            wei_inf[gen_i] = wram_fifo_out[gen_i][PE_WEI_DW +:CONV_WEI_DW];
            wei_lst[gen_i] = wram_fifo_out[gen_i][WRAM_BUF_DW-1];
        end
    end
endgenerate

always @ ( * )begin
    act_vld =~aram_fifo_empty;
    act_dat = aram_fifo_out[0 +:PE_ACT_DW];
    act_inf = aram_fifo_out[PE_ACT_DW +:ARAM_ADD_AW];
    act_lst = aram_fifo_out[ARAM_BUF_DW-1];
end

always @( * )begin
    fram_add_vld = ff_conv && ~fadd_fifo_full && ff_fifo_cnt<(FRAM_BUF_NUM-'d1);
    fram_add_lst = |cal_rpad_len ? ff_last_ich&&ff_cntr_pix==(cal_rpad_len-'d1) : ff_last_ich&&ff_last_pix;
    fram_add_add = ff_addr;
    fram_add_rid = ff_ridx;
    fram_dat_rdy = 'd1;
end

always @( * )begin
    aram_add_vld =~aadd_fifo_empty;
    aram_add_rid = aadd_fifo_out[ARAM_DAT_DW +:2];
    aram_add_add = aadd_fifo_out[0 +:ARAM_DAT_DW];
    aram_add_lst = aadd_fifo_out[AADD_BUF_DW  -1];
    aram_dat_rdy =~aram_fifo_full;
end

wire [WRAM_ADD_AW -1:0] wram_add_ich = fnch_fifo_ich*cfg_conv_wei +fwei_fifo_wid;
generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            wram_dat_rdy[gen_i] = ~wram_fifo_full[gen_i];
            wram_add_vld[gen_i] = ~fnch_fifo_empty && ~fwei_fifo_empty;
            wram_add_lst[gen_i] = fnch_fifo_lst;
            wram_add_add[gen_i] = wram_add_ich +fnch_fifo_och*cfg_conv_ich*cfg_conv_wei +cfg_wram_add;
            wram_add_buf[gen_i] = wram_add_ich;
        end
    end
endgenerate

//=====================================================================================================================
// Logic Design :
//=====================================================================================================================
always @ ( * )begin
    cfg_aram_add = CFG_ARAM_ADD;
    cfg_wram_add = CFG_WRAM_ADD;
    cfg_flag_vld = CFG_FLAG_VLD;
    cfg_splt_ena = CFG_SPLT_ENA;
    cfg_conv_ich = CFG_CONV_ICH;
    cfg_conv_och = CFG_CONV_OCH;
    cfg_conv_len = CFG_CONV_LEN;
    cfg_conv_wei = CFG_CONV_WEI;
    cfg_dila_fac = CFG_DILA_FAC;
    cfg_strd_fac = CFG_STRD_FAC;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cal_lpad_len <= 'd0;
        cal_rpad_len <= 'd0;
        cal_step_ich <= 'd0;
        cal_step_pix <= 'd0;
        cal_last_ich <= 'd0;
        cal_last_pix <= 'd0;
        cal_flag_nzf <= 'd0;
    end
    else if( cfg_info_ena )begin
        cal_lpad_len <= CFG_SPLT_ENA && PEA_GEN_LPAD ? CFG_CONV_WEI[CONV_WEI_DW -1:1] : 'd0;
        cal_rpad_len <= CFG_SPLT_ENA && PEA_GEN_RPAD ? CFG_CONV_WEI[CONV_WEI_DW -1:1] : 'd0;
        cal_step_ich <= &CFG_CONV_ICH[0 +:2] ? 'd4 : 'd0;
        cal_step_pix <= CFG_DILA_FAC +'d1;
        cal_last_ich <= &CFG_CONV_ICH[0 +:2] ? {CFG_CONV_ICH[CONV_ICH_DW -1:2],2'd0} : 'd0;
        cal_last_pix <= CFG_CONV_LEN;
        cal_flag_nzf <= CFG_FLAG_VLD ? {FRAM_DAT_DW{1'b0}} : {FRAM_DAT_DW{1'b1}};
    end
end

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
      always @( * )begin
          wram_fifo_not_almost_full[gen_i] = wram_fifo_cnt_empty[gen_i] >1;
          wram_fifo_din[gen_i] = {wram_wei_lst[gen_i], wram_wei_fid[gen_i], wram_dat_dat[gen_i]};
      end
    end
endgenerate

//for padding
wire [CONV_WEI_DW -1:0] ff_conv_wei_left = cfg_conv_wei - cfg_conv_wei[CONV_WEI_DW -1:1];
wire [CONV_WEI_DW -1:0] ff_conv_wei_half = cfg_conv_wei[CONV_WEI_DW -1:1];
generate
    for( gen_i=0 ; gen_i < WWEI_MAXLEN; gen_i = gen_i+1 )begin
        always @( * )begin
            if( ff_lpad )
                fwei_widx_din[gen_i] = gen_i+cfg_conv_wei-ff_pidx;
            else if( ff_tile && (ff_pidx<ff_conv_wei_half) )
                fwei_widx_din[gen_i] = gen_i +ff_conv_wei_half-ff_pidx;
            else
                fwei_widx_din[gen_i] = gen_i;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < WWEI_MAXLEN; gen_i = gen_i+1 )begin
        always @( * )begin
            fwei_last_din[gen_i] = fwei_fifo_num<=gen_i;
            fwei_wfid_din[gen_i] = gen_i;
        end
    end
endgenerate

always @( * )begin
    fwei_fifo_ren = &wram_fifo_not_almost_full;
end

generate
    for( gen_i=0 ; gen_i < WWEI_MAXLEN; gen_i = gen_i+1 )begin
        always @( * )begin
            fwei_fifo_din[gen_i] = {fwei_last_din[gen_i], fwei_wfid_din[gen_i], fwei_widx_din[gen_i]};
        end
    end
endgenerate

always @ ( * )begin//for wei_len==5:1\2\3\4\5\5\5\5\4\3\2\1
    if( ff_lpad )
        fwei_fifo_num = ff_fifo_pdx;
    else if( ff_tile )begin
        if( ff_fifo_pdx<ff_conv_wei_half )
            fwei_fifo_num = ff_fifo_pdx +ff_conv_wei_half;
        else if( cfg_conv_len-ff_fifo_pdx < ff_conv_wei_half )
            fwei_fifo_num = ff_fifo_pdx +cfg_conv_wei-cfg_conv_len;
        else
            fwei_fifo_num = cfg_conv_wei;
    end
    else //ff_rpad
        fwei_fifo_num = ff_conv_wei_half -ff_fifo_pdx -'d1;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        ff_mask_nzf <= {FRAM_DAT_DW{1'd1}};
    else if( ff_load )
        ff_mask_nzf <= {FRAM_DAT_DW{1'd1}};
    else if( ff_fifo_ren )
        ff_mask_nzf <= {FRAM_DAT_DW{1'd1}};
    else if( fnch_fifo_wen )
        ff_mask_nzf <= ff_mask_nzf & ~(1<<ff_flag_idx);
end

always @ ( * )begin
    ff_flag_fix = ff_fifo_nzf & ff_mask_nzf;
end

always @ ( * )begin
    ff_flag_idx = 'd0;
    for( i = FRAM_DAT_DW-1; i >= 0; i = i - 1 )begin
        if( ff_flag_fix[i] )
            ff_flag_idx = i;
    end
end

always @ ( * )begin
    ff_flag_sum = 'd0;
    for( i = FRAM_DAT_DW-1; i >= 0; i = i - 1 )begin
        ff_flag_sum = ff_flag_sum +ff_flag_fix[i];
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        ff_iidx <= 'd0;
    else if( ff_load )
        ff_iidx <= 'd0;
    else if( ff_last_ich )
        ff_iidx <= 'd0;
    else if( ff_tile && fram_add_ena )
        ff_iidx <= ff_iidx +cal_step_ich;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        ff_cntr_ich <= 'd0;
    else if( ff_load )
        ff_cntr_ich <= 'd0;
    else if( ff_last_ich )
        ff_cntr_ich <= 'd0;
    else if( ff_tile && fram_add_ena )
        ff_cntr_ich <= ff_cntr_ich+'d1;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        ff_ridx <= 'd0;
    else if( ff_load )
        ff_ridx <= |cal_lpad_len ? PEA_GEN_CIDX-1 : PEA_GEN_CIDX;
    else if( ff_lpad_done )
        ff_ridx <= PEA_GEN_CIDX;
    else if( ff_tile_done )
        ff_ridx <= |cal_rpad_len ? PEA_GEN_CIDX+1 : PEA_GEN_CIDX;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        ff_pidx <= 'd0;
    else if( ff_load )
        ff_pidx <= |cal_lpad_len ? CFG_CONV_LEN-{{(DILA_FAC_DW){1'd0}}, cal_lpad_len}<<cfg_dila_fac +ff_didx : ff_didx;
    else if( ff_lpad_done )
        ff_pidx <= ff_didx;
    else if( ff_tile_done )
        ff_pidx <= ff_didx;
    else if( ff_conv && fram_add_ena && ff_last_ich )
        ff_pidx <= ff_pidx +cal_step_pix;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        ff_addr <= 'd0;
    else if( ff_load )
        ff_addr <= |cal_lpad_len ? CFG_CONV_LEN-{{(DILA_FAC_DW){1'd0}}, cal_lpad_len}<<cfg_dila_fac +ff_didx : ff_didx;
    else if( ff_lpad_done )
        ff_addr <= ff_didx;
    else if( ff_tile_done )
        ff_addr <= ff_didx;
    else if( ff_tile && fram_add_ena )
        ff_addr <= ff_addr+cal_step_ich;
    else if( ff_conv && fram_add_ena && ff_last_ich )
        ff_addr <= ff_pidx +cal_step_pix;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        ff_cntr_pix <= 'd0;
    else if( ff_load )
        ff_cntr_pix <= 'd0;
    else if( ff_lpad_done || ff_tile_done )
        ff_cntr_pix <= 'd0;
    else if( ff_conv && fram_add_ena && ff_last_ich )
        ff_cntr_pix <= ff_cntr_pix+'d1;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        ff_oidx <= 'd0;
    else if( cfg_info_ena )
        ff_oidx <= 'd0;
    else if( ff_done && ff_last_oidx )
        ff_oidx <= 'd0;
    else if( ff_done && ff_last_didx )
        ff_oidx <= ff_oidx +'d4;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        ff_didx <= 'd0;
    else if( cfg_info_ena )
        ff_didx <= 'd0;
    else if( ff_done && ff_last_didx )
        ff_didx <= 'd0;
    else if( ff_done )
        ff_didx <= ff_didx +'d1;
end

//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================

//=====================================================================================================================
// FSM :
//=====================================================================================================================
always @ ( * )begin
  case( ff_cs )
    FF_IDLE: ff_ns = cfg_info_ena ? FF_LOAD : ff_cs;
    FF_LOAD: ff_ns =|cal_lpad_len ? FF_LPAD : FF_TILE;
    FF_LPAD: ff_ns = ff_lpad_done ? FF_TILE : ff_cs;
    FF_TILE: ff_ns = ff_tile_done ? (|cal_rpad_len ? FF_RPAD : FF_DONE) : ff_cs;
    FF_RPAD: ff_ns = ff_rpad_done ? FF_DONE : ff_cs;
    FF_DONE: ff_ns = ff_conv_done ? FF_IDLE : FF_LOAD;
    default: ff_ns = FF_IDLE;
  endcase
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        ff_cs <= FF_IDLE;
    else
        ff_cs <= ff_ns;
end

`ifdef ASSERT_ON


`endif
endmodule