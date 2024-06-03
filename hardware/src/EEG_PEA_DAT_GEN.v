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
    parameter DATA_ACT_DW =  8,
    parameter DATA_WEI_DW =  8,
    parameter CONV_ICH_DW =  8,//256
    parameter CONV_OCH_DW =  8,//256
    parameter CONV_LEN_DW = 10,//1024
    parameter CONV_WEI_DW =  3,//8
    parameter CONV_RUN_DW =  4,//1-8
    parameter CONV_MUL_DW = 24,
    parameter CONV_SFT_DW =  8,
    parameter CONV_ADD_DW = 32,
    parameter DILA_FAC_DW =  2,//8
    parameter STRD_FAC_DW =  2,//8
    parameter ARAM_NUM_AW =  2,
    parameter ARAM_ADD_AW = 12,//4k
    parameter WRAM_ADD_AW = 13,//8k
    parameter FRAM_ADD_AW = ARAM_ADD_AW,
    parameter ARAM_DAT_DW = DATA_ACT_DW,
    parameter WRAM_DAT_DW = DATA_WEI_DW,
    parameter FRAM_DAT_DW = 4,
    parameter STAT_DAT_DW = CONV_ICH_DW+CONV_WEI_DW,
    parameter DATA_ACT_IW = ARAM_ADD_AW,
    parameter DATA_WEI_IW = CONV_WEI_DW,
    parameter WBUF_OCH_DW = CONV_OCH_DW-2
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
    input  [FRAM_ADD_AW                 -1:0] CFG_FRAM_ADD,
    input  [WRAM_ADD_AW                 -1:0] CFG_MULT_ADD,
    input  [WRAM_ADD_AW                 -1:0] CFG_BIAS_ADD,
    
    input                                     CFG_FLAG_VLD,
    input                                     CFG_CPAD_ENA,
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
    output [PE_ROW -1:0][WBUF_OCH_DW    -1:0] WRAM_ADD_OCH,
    input  [PE_ROW -1:0]                      WRAM_DAT_VLD,
    input  [PE_ROW -1:0]                      WRAM_DAT_LST,
    output [PE_ROW -1:0]                      WRAM_DAT_RDY,
    input  [PE_ROW -1:0][WRAM_DAT_DW    -1:0] WRAM_DAT_DAT,

    output [PE_ROW -1:0][CONV_MUL_DW    -1:0] ACT_MUL,
    output [PE_ROW -1:0][CONV_SFT_DW    -1:0] ACT_SFT,
    output [PE_ROW -1:0][CONV_ADD_DW    -1:0] ACT_OFF,

    output                                    ACT_VLD,
    output                                    ACT_LST,
    input                                     ACT_RDY,
    output              [DATA_ACT_DW    -1:0] ACT_DAT,
    output              [DATA_ACT_IW    -1:0] ACT_INF,
                                        
    output [PE_ROW -1:0]                      WEI_VLD,
    output [PE_ROW -1:0]                      WEI_LST,
    input  [PE_ROW -1:0]                      WEI_RDY,
    output [PE_ROW -1:0][DATA_WEI_DW    -1:0] WEI_DAT,
    output [PE_ROW -1:0][DATA_WEI_IW    -1:0] WEI_INF
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
localparam ARAM_ADD_GAP = 1;
localparam WRAM_ADD_GAP = 1;
localparam DILA_LEN_DW = CONV_RUN_DW;
localparam STRD_LEN_DW = CONV_RUN_DW;
localparam WNCH_BUF_DW = CONV_ICH_DW +CONV_OCH_DW-2 +1;
localparam WNCH_BUF_NUM = 4;
localparam WNCH_BUF_AW = $clog2(WNCH_BUF_NUM);

localparam WWEI_BUF_DW = CONV_WEI_DW +CONV_WEI_DW +1;
localparam WWEI_BUF_NUM = 16;
localparam WWEI_BUF_AW = $clog2(WWEI_BUF_NUM);
localparam WWEI_MAXLEN = 1<<CONV_WEI_DW;

localparam WADD_BUF_DW = WRAM_ADD_AW +STAT_DAT_DW +WBUF_OCH_DW +CONV_WEI_DW +2;
localparam WADD_BUF_NUM = 2;
localparam WADD_BUF_AW = $clog2(WADD_BUF_NUM);

localparam AADD_BUF_DW = ARAM_ADD_AW+ARAM_ADD_AW +2+1+1+1;
localparam AADD_BUF_NUM = 4;
localparam AADD_BUF_AW = $clog2(AADD_BUF_NUM);

localparam FADD_BUF_DW = FRAM_ADD_AW +2 +8;
localparam FADD_BUF_NUM = 2;
localparam FADD_BUF_AW = $clog2(FADD_BUF_NUM);

localparam FRAM_BUF_DW = FRAM_DAT_DW +FRAM_ADD_AW +2 +CONV_OCH_DW-2 +CONV_ICH_DW +CONV_LEN_DW +DILA_LEN_DW +CONV_LEN_DW +6;
localparam ARAM_BUF_DW = ARAM_DAT_DW +ARAM_ADD_AW +1 +1;
localparam WRAM_BUF_DW = WRAM_DAT_DW +CONV_WEI_DW +1;
localparam FRAM_BUF_NUM = 4;
localparam ARAM_BUF_NUM = 4;
localparam WRAM_BUF_NUM = 4;
localparam FRAM_BUF_AW = $clog2(FRAM_BUF_NUM);
localparam ARAM_BUF_AW = $clog2(ARAM_BUF_NUM);
localparam WRAM_BUF_AW = $clog2(WRAM_BUF_NUM);

localparam FRAM_DAT_AW = $clog2(FRAM_DAT_DW);

localparam MULT_CNT_DW = 4;
localparam MULT_CNT_AW = $clog2(MULT_CNT_DW);
localparam BIAS_CNT_DW = CONV_ADD_DW>>3;
localparam BIAS_CNT_AW = $clog2(BIAS_CNT_DW);

localparam FF_STATE = 8;
localparam FF_IDLE  = 8'b0000_0001;
localparam FF_LOAD  = 8'b0000_0010;
localparam FF_MULT  = 8'b0000_0100;
localparam FF_BIAS  = 8'b0000_1000;
localparam FF_LPAD  = 8'b0001_0000;
localparam FF_TILE  = 8'b0010_0000;
localparam FF_RPAD  = 8'b0100_0000;
localparam FF_DONE  = 8'b1000_0000;

reg [FF_STATE -1:0] ff_cs;
reg [FF_STATE -1:0] ff_ns;

wire ff_idle = ff_cs == FF_IDLE;
wire ff_load = ff_cs == FF_LOAD;
wire ff_mult = ff_cs == FF_MULT;
wire ff_bias = ff_cs == FF_BIAS;
wire ff_lpad = ff_cs == FF_LPAD;
wire ff_tile = ff_cs == FF_TILE;
wire ff_rpad = ff_cs == FF_RPAD;
wire ff_done = ff_cs == FF_DONE;
wire ff_conv = ff_cs == FF_LPAD || ff_cs == FF_TILE || ff_cs == FF_RPAD;

integer i;
genvar gen_i, gen_j;
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
reg  [PE_ROW -1:0][WBUF_OCH_DW   -1:0] wram_add_och;
wire [PE_ROW -1:0]                     wram_dat_vld= WRAM_DAT_VLD;
wire [PE_ROW -1:0]                     wram_dat_lst= WRAM_DAT_LST;
reg  [PE_ROW -1:0]                     wram_dat_rdy;
wire [PE_ROW -1:0][WRAM_DAT_DW   -1:0] wram_dat_dat= WRAM_DAT_DAT;

assign WRAM_ADD_VLD = wram_add_vld;
assign WRAM_ADD_LST = wram_add_lst;
assign WRAM_ADD_ADD = wram_add_add;
assign WRAM_ADD_BUF = wram_add_buf;
assign WRAM_ADD_OCH = wram_add_och;
assign WRAM_DAT_RDY = wram_dat_rdy;

//DATA_IO
reg                                  act_vld;
wire                                 act_rdy= ACT_RDY;
reg               [DATA_ACT_DW -1:0] act_dat;
reg                                  act_lst;
reg               [DATA_ACT_IW -1:0] act_inf;
reg  [PE_ROW -1:0][CONV_MUL_DW -1:0] act_mul;
reg  [PE_ROW -1:0][CONV_SFT_DW -1:0] act_sft;
reg  [PE_ROW -1:0][CONV_ADD_DW -1:0] act_off;
wire                                 act_end;
reg  [PE_ROW -1:0]                   wei_vld;
reg  [PE_ROW -1:0]                   wei_lst;
wire [PE_ROW -1:0]                   wei_rdy= WEI_RDY;
reg  [PE_ROW -1:0][DATA_WEI_DW -1:0] wei_dat;
reg  [PE_ROW -1:0][DATA_WEI_IW -1:0] wei_inf;
wire [PE_ROW -1:0]                   wei_end;
wire [PE_ROW -1:0]                   wei_ena = wei_vld & wei_rdy;

assign ACT_DAT = act_dat;
assign ACT_VLD = act_vld;
assign ACT_LST = act_lst;
assign ACT_INF = act_inf;
assign ACT_MUL = act_mul;
assign ACT_SFT = act_sft;
assign ACT_OFF = act_off;
assign WEI_DAT = wei_dat;
assign WEI_VLD = wei_vld;
assign WEI_LST = wei_lst;
assign WEI_INF = wei_inf;

assign IS_IDLE = ff_idle;

assign act_end = act_vld & act_rdy & act_lst;
assign wei_end = wei_vld & wei_rdy & wei_lst;
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
wire [CONV_LEN_DW             -1:0] ff_pcnt_d1;

reg  [ARAM_ADD_AW -1:0] cfg_aram_add;
reg  [ARAM_ADD_AW -1:0] cfg_fram_add;
reg  [WRAM_ADD_AW -1:0] cfg_wram_add;
reg  [WRAM_ADD_AW -1:0] cfg_mult_add;
reg  [WRAM_ADD_AW -1:0] cfg_bias_add;
reg                     cfg_flag_vld;
reg                     cfg_cpad_ena;
reg  [CONV_ICH_DW -1:0] cfg_conv_ich;
reg  [CONV_OCH_DW -1:0] cfg_conv_och;
reg  [CONV_LEN_DW -1:0] cfg_conv_len;
reg  [CONV_WEI_DW -1:0] cfg_conv_wei;
reg  [DILA_FAC_DW -1:0] cfg_dila_fac;
reg  [STRD_FAC_DW -1:0] cfg_strd_fac;
wire [STRD_FAC_DW -1:0] CFG_STEP_LEN = CFG_DILA_FAC | CFG_STRD_FAC;
reg  [STRD_FAC_DW -1:0] cfg_step_len;

reg  [CONV_WEI_DW -2:0] cal_lpad_len;//real num
reg  [CONV_WEI_DW -2:0] cal_rpad_len;//real num
wire [3           -1:0] cal_dila_len = cfg_dila_fac == 'd3 ? 'd7 : cfg_dila_fac == 'd2 ? 'd3 : cfg_dila_fac == 'd1 ? 'd1 : 'd0;
reg  [3           -1:0] cal_step_ich;
reg  [4           -1:0] cal_step_pix;
reg  [CONV_ICH_DW -1:0] cal_last_ich;
reg  [CONV_LEN_DW -1:0] cal_last_pix;
reg  [FRAM_DAT_DW -1:0] cal_flag_nzf;
reg  [CONV_ICH_DW -1:0] cal_conv_ich;

reg  [FRAM_ADD_AW -1:0] ff_addr;
reg  [CONV_ICH_DW -1:0] ff_cntr_ich;
reg  [CONV_LEN_DW -1:0] ff_cntr_pix;

wire ff_last_didx = ff_didx==cal_dila_len;
wire ff_last_oidx = ff_oidx==cfg_conv_och[CONV_OCH_DW -1:2];

wire ff_last_ich = ff_cntr_ich==cal_last_ich;
wire ff_last_pix = ff_cntr_pix==cal_last_pix;
wire ff_last_pad = ff_cntr_pix==(cal_rpad_len-'d1);

reg  fram_add_done;

wire ff_lpad_last = fram_add_ena&&ff_last_ich&&ff_cntr_pix==(cal_lpad_len-'d1);
wire ff_tile_last = fram_add_ena&&ff_last_ich&&ff_last_pix;
wire ff_rpad_last = fram_add_ena&&ff_last_ich&&ff_cntr_pix==(cal_rpad_len-'d1);
wire ff_loop_last = ff_last_didx&&ff_last_oidx;
wire ff_conv_last = |cal_rpad_len ? ff_rpad&&ff_rpad_last : ff_tile_last;
wire ff_conv_f2st = |cal_lpad_len ? ff_lpad && ~|ff_cntr_pix && ~|ff_cntr_ich : ff_tile && ~|ff_cntr_pix && ~|ff_cntr_ich;

reg  ff_mult_done;
reg  ff_bias_done;
reg  ff_lpad_done;
reg  ff_tile_done;
reg  ff_rpad_done;
reg  ff_conv_done;

wire fram_add_c1st = ff_conv_f2st;
wire fram_add_cend = ff_conv_last;
wire fram_add_last = ff_loop_last && ff_conv_last;//last pix & loop
wire fram_add_lpad = ff_lpad;
wire fram_add_tile = ff_tile;
wire fram_add_rpad = ff_rpad;
wire fram_add_fend = ff_conv_last;
wire fram_add_lend = ff_loop_last;
//FADD_FIFO
wire fadd_fifo_wen = fram_add_ena;
wire fadd_fifo_ren = fram_dat_ena;
wire fadd_fifo_empty;
wire fadd_fifo_full;
wire [FADD_BUF_DW -1:0] fadd_fifo_din = {fram_add_last, fram_add_c1st, fram_add_cend, fram_add_lend, fram_add_fend, fram_add_lpad, fram_add_tile, fram_add_rpad, fram_add_rid, fram_add_add};
wire [FADD_BUF_DW -1:0] fadd_fifo_out;
wire [FADD_BUF_AW   :0] fadd_fifo_cnt;
wire [FRAM_ADD_AW -1:0] fram_dat_add = fadd_fifo_out[0 +:FRAM_ADD_AW];
wire [2           -1:0] fram_dat_rid = fadd_fifo_out[FRAM_ADD_AW +:2];
wire [CONV_OCH_DW -3:0] fram_dat_odx = ff_oidx_d1;
wire [CONV_ICH_DW -1:0] fram_dat_idx = ff_iidx_d1;
wire [CONV_LEN_DW -1:0] fram_dat_pdx = ff_pidx_d1;
wire [DILA_LEN_DW -1:0] fram_dat_ddx = ff_didx_d1;
wire [CONV_LEN_DW -1:0] fram_dat_pct = ff_pcnt_d1;

wire fram_dat_last = fadd_fifo_out[FADD_BUF_DW-1];
wire fram_dat_c1st = fadd_fifo_out[FADD_BUF_DW-2];
wire fram_dat_cend = fadd_fifo_out[FADD_BUF_DW-3];
wire fram_dat_lend = fadd_fifo_out[FADD_BUF_DW-4];
wire fram_dat_fend = fadd_fifo_out[FADD_BUF_DW-5];
wire fram_dat_lpad = fadd_fifo_out[FADD_BUF_DW-6];
wire fram_dat_tile = fadd_fifo_out[FADD_BUF_DW-7];
wire fram_dat_rpad = fadd_fifo_out[FADD_BUF_DW-8];

CPM_FIFO #( .DATA_WIDTH( FADD_BUF_DW ), .ADDR_WIDTH( FADD_BUF_AW ) ) FADD_FIFO_U( clk, rst_n, 1'd0, fadd_fifo_wen, fadd_fifo_ren, fadd_fifo_din, fadd_fifo_out, fadd_fifo_empty, fadd_fifo_full, fadd_fifo_cnt);

CPM_REG_E #( 2                       ) FF_RIDX_REG( clk, rst_n, fram_add_ena, ff_ridx, ff_ridx_d1 );
CPM_REG_E #( DILA_LEN_DW             ) FF_DIDX_REG( clk, rst_n, fram_add_ena, ff_didx, ff_didx_d1 );
CPM_REG_E #( CONV_OCH_DW-2           ) FF_OIDX_REG( clk, rst_n, fram_add_ena, ff_oidx, ff_oidx_d1 );
CPM_REG_E #( CONV_OCH_DW+DILA_LEN_DW ) FF_TIDX_REG( clk, rst_n, fram_add_ena, ff_tidx, ff_tidx_d1 );
CPM_REG_E #( CONV_ICH_DW             ) FF_IIDX_REG( clk, rst_n, fram_add_ena, ff_iidx, ff_iidx_d1 );
CPM_REG_E #( CONV_LEN_DW             ) FF_PIDX_REG( clk, rst_n, fram_add_ena, ff_pidx, ff_pidx_d1 );
CPM_REG_E #( CONV_LEN_DW             ) FF_PCNT_REG( clk, rst_n, fram_add_ena, ff_cntr_pix, ff_pcnt_d1 );

wire fa_fifo_rdy;
wire fw_fifo_rdy;
wire ff_fifo_wen = fadd_fifo_ren;
wire ff_fifo_ren;
wire ff_fifo_empty;
wire ff_fifo_full;
wire [FRAM_DAT_DW -1:0] fram_dat_lst_nzf = {{(FRAM_DAT_DW-1){1'b0}}, fram_dat_cend || fram_dat_c1st};//make sure first/last flag exist, to trigger first/last signal; 0'th bit->1 to support ich==1
wire [FRAM_BUF_DW -1:0] ff_fifo_din = {fram_dat_last, fram_dat_lend, fram_dat_fend, fram_dat_lpad, fram_dat_tile, fram_dat_rpad, fram_dat_pct, fram_dat_ddx, fram_dat_pdx, fram_dat_idx, fram_dat_odx, fram_dat_rid, fram_dat_add, fram_dat_dat | cal_flag_nzf | fram_dat_lst_nzf};
wire [FRAM_BUF_DW -1:0] ff_fifo_out;
wire [FRAM_DAT_DW -1:0] ff_fifo_nzf = ff_fifo_out[0 +:FRAM_DAT_DW];
wire [FRAM_ADD_AW -1:0] ff_fifo_add = ff_fifo_out[FRAM_DAT_DW +:FRAM_ADD_AW];
wire [2           -1:0] ff_fifo_rid = ff_fifo_out[FRAM_DAT_DW + FRAM_ADD_AW +:2];
wire [CONV_OCH_DW -3:0] ff_fifo_odx = ff_fifo_out[FRAM_DAT_DW + FRAM_ADD_AW + 2 +:CONV_OCH_DW-2];
wire [CONV_ICH_DW -1:0] ff_fifo_idx = ff_fifo_out[FRAM_DAT_DW + FRAM_ADD_AW + 2 + CONV_OCH_DW-2 +:CONV_ICH_DW];
wire [CONV_LEN_DW -1:0] ff_fifo_pdx = ff_fifo_out[FRAM_DAT_DW + FRAM_ADD_AW + 2 + CONV_OCH_DW-2 + CONV_ICH_DW +:CONV_LEN_DW];
wire [DILA_LEN_DW -1:0] ff_fifo_ddx = ff_fifo_out[FRAM_DAT_DW + FRAM_ADD_AW + 2 + CONV_OCH_DW-2 + CONV_ICH_DW + CONV_LEN_DW +:DILA_LEN_DW];
wire [CONV_LEN_DW -1:0] ff_fifo_pct = ff_fifo_out[FRAM_DAT_DW + FRAM_ADD_AW + 2 + CONV_OCH_DW-2 + CONV_ICH_DW + CONV_LEN_DW + DILA_LEN_DW +:CONV_LEN_DW];
wire ff_fifo_last = ff_fifo_out[FRAM_BUF_DW-1];
wire ff_fifo_lend = ff_fifo_out[FRAM_BUF_DW-2];
wire ff_fifo_fend = ff_fifo_out[FRAM_BUF_DW-3];
wire ff_fifo_lpad = ff_fifo_out[FRAM_BUF_DW-4];
wire ff_fifo_tile = ff_fifo_out[FRAM_BUF_DW-5];
wire ff_fifo_rpad = ff_fifo_out[FRAM_BUF_DW-6];

reg  [FRAM_DAT_DW -1:0] ff_mask_nzf;
reg  [FRAM_DAT_DW -1:0] ff_flag_fix;//gen from ff_fifo_nzf
reg  [FRAM_DAT_AW -1:0] ff_flag_idx;
reg  [FRAM_DAT_AW   :0] ff_flag_sum;
wire [FRAM_BUF_AW   :0] ff_fifo_cnt;

wire [ARAM_ADD_AW -1:0] ff_fifo_aram_add = cfg_aram_add + ff_fifo_pdx +(ff_fifo_idx+ff_flag_idx)*(cfg_conv_len+'d1);// +ff_fifo_ddx;
wire [ARAM_ADD_AW -1:0] ff_fifo_aact_add = ff_fifo_lpad ? ff_fifo_ddx +ff_fifo_odx*(cfg_conv_len+'d1) : ff_fifo_pdx +ff_fifo_odx*(cfg_conv_len+'d1);// +ff_fifo_ddx;
wire [CONV_ICH_DW -1:0] ff_fifo_wram_idx = ff_fifo_idx + ff_flag_idx;

assign ff_fifo_ren = ~ff_fifo_empty && fw_fifo_rdy && fa_fifo_rdy && ff_flag_sum<='d1;
wire ff_fifo_wen_rdy = ~ff_fifo_empty && fw_fifo_rdy && fa_fifo_rdy && |ff_flag_fix;

//AADD_FIFO
wire ff_fifo_last_loop = ff_fifo_lend;
wire ff_fifo_last_flow = ff_fifo_fend && ff_flag_sum=='d1;//last pix & last valid ich
wire ff_fifo_last_aadd = ff_fifo_last && ff_flag_sum=='d1;//last pix & last valid ich
wire aadd_fifo_wen = ff_fifo_wen_rdy;
reg  aadd_fifo_ren;
wire aadd_fifo_empty;
wire aadd_fifo_full;
wire [AADD_BUF_DW -1:0] aadd_fifo_din = {ff_fifo_last_aadd, ff_fifo_last_loop, ff_fifo_last_flow, ff_fifo_rid, ff_fifo_aact_add, ff_fifo_aram_add};
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
wire [WNCH_BUF_DW -1:0] fnch_fifo_din = {ff_fifo_last_aadd, ff_fifo_odx, ff_fifo_wram_idx};
wire [WNCH_BUF_DW -1:0] fnch_fifo_out;
wire [CONV_ICH_DW -1:0] fnch_fifo_ich = fnch_fifo_out[0 +:CONV_ICH_DW];
wire [CONV_OCH_DW -3:0] fnch_fifo_och = fnch_fifo_out[CONV_ICH_DW +:CONV_OCH_DW-2];
wire [CONV_OCH_DW -1:0] fnch_fifo_lst = fnch_fifo_out[WNCH_BUF_DW -1];
wire [WNCH_BUF_AW   :0] fnch_fifo_cnt;
assign fw_fifo_rdy = ~fnch_fifo_full && fwei_fifo_cnt_empty>fwei_fifo_num;

//WADD_FIFO
reg  wadd_lst_din;
reg  wadd_end_din;//wei ned, flag for last wei_idx in wei
reg  [CONV_WEI_DW -1:0] wadd_fid_din;
reg  [WBUF_OCH_DW -1:0] wadd_och_din;
reg  [STAT_DAT_DW -1:0] wadd_buf_din;
reg  [WRAM_ADD_AW -1:0] wadd_add_din;
reg  [PE_ROW -1:0] wadd_fifo_wen;
reg  [PE_ROW -1:0] wadd_fifo_ren;
wire [PE_ROW -1:0] wadd_fifo_empty;
wire [PE_ROW -1:0] wadd_fifo_full;
reg  [PE_ROW -1:0][WADD_BUF_DW -1:0] wadd_fifo_din;
wire [PE_ROW -1:0][WADD_BUF_DW -1:0] wadd_fifo_out;
wire [PE_ROW -1:0][WADD_BUF_AW   :0] wadd_fifo_cnt;
reg  [PE_ROW -1:0]                   wadd_fifo_lst;
reg  [PE_ROW -1:0]                   wadd_fifo_end;//last for cal psum
reg  [PE_ROW -1:0][CONV_WEI_DW -1:0] wadd_fifo_fid;
reg  [PE_ROW -1:0][WBUF_OCH_DW -1:0] wadd_fifo_och;
reg  [PE_ROW -1:0][STAT_DAT_DW -1:0] wadd_fifo_buf;
reg  [PE_ROW -1:0][WRAM_ADD_AW -1:0] wadd_fifo_add;


CPM_FIFO #( .DATA_WIDTH( FRAM_BUF_DW ), .ADDR_WIDTH( FRAM_BUF_AW ) )FNZF_FIFO_U( clk, rst_n, 1'd0, ff_fifo_wen, ff_fifo_ren, ff_fifo_din, ff_fifo_out, ff_fifo_empty, ff_fifo_full, ff_fifo_cnt);

CPM_MISO_FIFO #( .DATA_WIDTH( WWEI_BUF_DW ), .ADDR_WIDTH( WWEI_BUF_AW ), .DATA_NUMAW(CONV_WEI_DW) )FWEI_FIFO_U( clk, rst_n, 1'd0, fwei_fifo_wen, fwei_fifo_ren, fwei_fifo_din, fwei_fifo_num, fwei_fifo_out, fwei_fifo_empty, fwei_fifo_full, fwei_fifo_cnt, fwei_fifo_cnt_empty);
CPM_FIFO      #( .DATA_WIDTH( WNCH_BUF_DW ), .ADDR_WIDTH( WNCH_BUF_AW )                           )FNCH_FIFO_U( clk, rst_n, 1'd0, fnch_fifo_wen, fnch_fifo_ren, fnch_fifo_din,                fnch_fifo_out, fnch_fifo_empty, fnch_fifo_full, fnch_fifo_cnt);
CPM_FIFO      #( .DATA_WIDTH( AADD_BUF_DW ), .ADDR_WIDTH( AADD_BUF_AW )                           )AADD_FIFO_U( clk, rst_n, 1'd0, aadd_fifo_wen, aadd_fifo_ren, aadd_fifo_din,                aadd_fifo_out, aadd_fifo_empty, aadd_fifo_full, aadd_fifo_cnt);
CPM_FIFO      #( .DATA_WIDTH( WADD_BUF_DW ), .ADDR_WIDTH( WADD_BUF_AW )             )WADD_FIFO_U [PE_ROW -1:0]( clk, rst_n, 1'd0, wadd_fifo_wen, wadd_fifo_ren, wadd_fifo_din,                wadd_fifo_out, wadd_fifo_empty, wadd_fifo_full, wadd_fifo_cnt);

reg  [ARAM_ADD_AW -1:0] aram_add_act;
wire [ARAM_ADD_AW -1:0] aram_dat_add;
wire [ARAM_ADD_AW -1:0] aram_act_add;
reg  aadd_flw_end, aadd_lop_end;
wire aram_flw_end, aram_lop_end;
CPM_REG_E #( ARAM_ADD_AW ) ARAM_DAT_ADD_REG( clk, rst_n, aram_add_ena, aram_add_add, aram_dat_add );
CPM_REG_E #( ARAM_ADD_AW ) ARAM_ACT_ADD_REG( clk, rst_n, aram_add_ena, aram_add_act, aram_act_add );
CPM_REG_E #( 1           ) ARAM_FLW_LST_REG( clk, rst_n, aram_add_ena, aadd_flw_end, aram_flw_end );
CPM_REG_E #( 1           ) ARAM_LOP_LST_REG( clk, rst_n, aram_add_ena, aadd_lop_end, aram_lop_end );
reg  [PE_ROW -1:0]                   wram_dat_end;//last for cal psum
reg  [PE_ROW -1:0][CONV_WEI_DW -1:0] wram_dat_fid;
CPM_REG_E #( 1           ) WRAM_WEND_REG [PE_ROW-1:0]( clk, rst_n, wram_add_ena, wadd_fifo_end, wram_dat_end );
CPM_REG_E #( CONV_WEI_DW ) WRAM_WFID_REG [PE_ROW-1:0]( clk, rst_n, wram_add_ena, wadd_fifo_fid, wram_dat_fid );

//ARAM
wire aram_fifo_wen = aram_dat_ena;
wire aram_fifo_ren = act_rdy;
wire aram_fifo_empty;
wire aram_fifo_full;
wire [ARAM_BUF_DW -1:0] aram_fifo_din = {aram_flw_end, aram_lop_end, aram_act_add, aram_dat_dat};
wire [ARAM_BUF_DW -1:0] aram_fifo_out;
wire [ARAM_BUF_AW   :0] aram_fifo_cnt;
wire [ARAM_BUF_AW   :0] aram_fifo_cnt_empty;

wire aram_fifo_flow_end = aram_fifo_out[ARAM_BUF_DW -1];
wire aram_fifo_loop_end = aram_fifo_out[ARAM_BUF_DW -2];

//WRAM
reg  [PE_ROW -1:0] wram_fifo_wen;
wire [PE_ROW -1:0] wram_fifo_ren = wei_rdy;
wire [PE_ROW -1:0] wram_fifo_empty;
wire [PE_ROW -1:0] wram_fifo_full;
reg  [PE_ROW -1:0][WRAM_BUF_DW -1:0] wram_fifo_din;
wire [PE_ROW -1:0][WRAM_BUF_DW -1:0] wram_fifo_out;
wire [PE_ROW -1:0][WRAM_BUF_AW   :0] wram_fifo_cnt;
wire [PE_ROW -1:0][WRAM_BUF_AW   :0] wram_fifo_cnt_empty;

CPM_FIFO_EX #( .DATA_WIDTH( ARAM_BUF_DW ), .ADDR_WIDTH( ARAM_BUF_AW ) )ARAM_FIFO_U             ( clk, rst_n, 1'd0, aram_fifo_wen, aram_fifo_ren, aram_fifo_din, aram_fifo_out, aram_fifo_empty, aram_fifo_full, aram_fifo_cnt, aram_fifo_cnt_empty );
CPM_FIFO_EX #( .DATA_WIDTH( WRAM_BUF_DW ), .ADDR_WIDTH( WRAM_BUF_AW ) )WRAM_FIFO_U [PE_ROW-1:0]( clk, rst_n, 1'd0, wram_fifo_wen, wram_fifo_ren, wram_fifo_din, wram_fifo_out, wram_fifo_empty, wram_fifo_full, wram_fifo_cnt, wram_fifo_cnt_empty );

wire act_last_vld_rst = ff_load || ff_conv_done;
wire act_last_vld;
CPM_REG_RCE #( 1, 0 ) ACT_LAST_VLD_REG ( clk, rst_n, act_last_vld_rst, 1'd0, act_end, 1'd1, act_last_vld );

//MULT
wire [PE_ROW -1:0][MULT_CNT_AW -1:0] mult_add_cnt;
wire [PE_ROW -1:0][MULT_CNT_AW -1:0] mult_dat_cnt;
reg  [PE_ROW -1:0] mult_add_cnt_ena;
reg  [PE_ROW -1:0] mult_dat_cnt_ena;
reg  [PE_ROW -1:0] mult_add_cnt_last;
reg  [PE_ROW -1:0] mult_dat_cnt_last;
CPM_CNT_C #( MULT_CNT_AW ) MULT_ADD_CNT_U[PE_ROW -1:0] ( clk, rst_n, ff_conv_done, mult_add_cnt_ena, mult_add_cnt );
CPM_CNT_C #( MULT_CNT_AW ) MULT_DAT_CNT_U[PE_ROW -1:0] ( clk, rst_n, ff_conv_done, mult_dat_cnt_ena, mult_dat_cnt );

wire [PE_ROW -1:0] mult_add_vld;
wire [PE_ROW -1:0] mult_dat_vld;
CPM_REG_RCE #( 1, 1 ) MULT_ADD_VLD_REG[PE_ROW -1:0] ( clk, rst_n, ff_conv_done, 1'd1, mult_add_cnt_last, 1'd0, mult_add_vld );
CPM_REG_RCE #( 1, 0 ) MULT_DAT_VLD_REG[PE_ROW -1:0] ( clk, rst_n, ff_conv_done, 1'd0, mult_dat_cnt_last, 1'd1, mult_dat_vld );

//BIAS
wire [PE_ROW -1:0][BIAS_CNT_AW -1:0] bias_add_cnt;
wire [PE_ROW -1:0][BIAS_CNT_AW -1:0] bias_dat_cnt;
reg  [PE_ROW -1:0] bias_add_cnt_ena;
reg  [PE_ROW -1:0] bias_dat_cnt_ena;
reg  [PE_ROW -1:0] bias_add_cnt_last;
reg  [PE_ROW -1:0] bias_dat_cnt_last;
CPM_CNT_C #( BIAS_CNT_AW ) BIAS_ADD_CNT_U[PE_ROW -1:0] ( clk, rst_n, ff_conv_done, bias_add_cnt_ena, bias_add_cnt );
CPM_CNT_C #( BIAS_CNT_AW ) BIAS_DAT_CNT_U[PE_ROW -1:0] ( clk, rst_n, ff_conv_done, bias_dat_cnt_ena, bias_dat_cnt );

wire [PE_ROW -1:0] bias_add_vld;
wire [PE_ROW -1:0] bias_dat_vld;
CPM_REG_RCE #( 1, 1 ) BIAS_ADD_VLD_REG[PE_ROW -1:0] ( clk, rst_n, ff_conv_done, 1'd1, bias_add_cnt_last, 1'd0, bias_add_vld );
CPM_REG_RCE #( 1, 0 ) BIAS_DAT_VLD_REG[PE_ROW -1:0] ( clk, rst_n, ff_conv_done, 1'd0, bias_dat_cnt_last, 1'd1, bias_dat_vld );

reg  [PE_ROW -1:0][MULT_CNT_DW -1:0][WRAM_DAT_DW -1:0] mult_dat_dat;
reg  [PE_ROW -1:0][BIAS_CNT_DW -1:0][WRAM_DAT_DW -1:0] bias_dat_dat;

reg  [PE_ROW -1:0][CONV_MUL_DW -1:0] mult_mul_dat;
reg  [PE_ROW -1:0][CONV_SFT_DW -1:0] mult_sft_dat;
//=====================================================================================================================
// IO Logic Design :
//=====================================================================================================================
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        act_mul <= 'd0;
        act_sft <= 'd0;
        act_off <= 'd0;
    end
    else if( ~ff_mult && ~ff_bias )begin
        act_mul <= mult_mul_dat;
        act_sft <= mult_sft_dat;
        act_off <= bias_dat_dat;
    end
end

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            wei_vld[gen_i] = ~wram_fifo_empty[gen_i];
            wei_dat[gen_i] = wram_fifo_out[gen_i][0 +:DATA_WEI_DW];
            wei_inf[gen_i] = wram_fifo_out[gen_i][DATA_WEI_DW +:CONV_WEI_DW];
            wei_lst[gen_i] = wram_fifo_out[gen_i][WRAM_BUF_DW -1];
        end
    end
endgenerate

always @ ( * )begin
    act_vld =~aram_fifo_empty;
    act_dat = aram_fifo_out[0 +:DATA_ACT_DW];
    act_inf = aram_fifo_out[DATA_ACT_DW +:ARAM_ADD_AW];
    act_lst = aram_fifo_out[ARAM_BUF_DW-1];
end

always @( * )begin
    fram_add_vld = ff_conv && (fadd_fifo_cnt+ff_fifo_cnt)<(FRAM_BUF_NUM-1) && ~fram_add_done;
    fram_add_lst = |cal_rpad_len ? ff_rpad&&ff_last_pad&&ff_last_ich&&ff_loop_last : ff_last_pix&&ff_last_ich&&ff_loop_last;
    fram_add_add = ff_addr[FRAM_ADD_AW -1:2] +cfg_aram_add[ARAM_ADD_AW -1:2];
    fram_add_rid = ff_ridx;
    fram_dat_rdy = 'd1;//~ff_fifo_full
end

always @( * )begin
    aram_add_vld = ~aadd_fifo_empty && aram_fifo_cnt_empty > ARAM_ADD_GAP;
    aram_add_add = aadd_fifo_out[0 +:ARAM_ADD_AW];
    aram_add_act = aadd_fifo_out[ARAM_ADD_AW +:ARAM_ADD_AW];
    aram_add_rid = aadd_fifo_out[ARAM_ADD_AW + ARAM_ADD_AW +:2];
    aadd_flw_end = aadd_fifo_out[AADD_BUF_DW  -3];
    aadd_lop_end = aadd_fifo_out[AADD_BUF_DW  -2];
    aram_add_lst = aadd_fifo_out[AADD_BUF_DW  -1];
    aram_dat_rdy =~aram_fifo_full;
end

wire [WRAM_ADD_AW -1:0] wadd_add_ich = fnch_fifo_ich*(cfg_conv_wei+'d1) +fwei_fifo_wid;
generate
    always @ ( * )begin
        wadd_lst_din = fnch_fifo_lst && fwei_fifo_lst;
        wadd_end_din = fwei_fifo_lst;
        wadd_fid_din = fwei_fifo_fid;
        wadd_och_din = fnch_fifo_och;
        wadd_buf_din ={fwei_fifo_wid, fnch_fifo_ich};
        wadd_add_din = wadd_add_ich +fnch_fifo_och*(cfg_conv_ich+'d1)*(cfg_conv_wei+'d1) +cfg_wram_add;
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            wram_add_vld[gen_i] = ff_mult ? mult_add_vld[gen_i] : ff_bias ? bias_add_vld[gen_i] : ~wadd_fifo_empty[gen_i] && wram_fifo_cnt_empty[gen_i] > WRAM_ADD_GAP;
            wram_add_add[gen_i] = ff_mult ? mult_add_cnt[gen_i] +ff_oidx*4 +cfg_mult_add : ff_bias ? bias_add_cnt[gen_i] +ff_oidx*4 +cfg_bias_add : wadd_fifo_add[gen_i];
            wram_add_och[gen_i] = ff_mult || ff_bias ? 'd0 : wadd_fifo_och[gen_i];
            wram_add_buf[gen_i] = ff_mult || ff_bias ? {STAT_DAT_DW{1'd1}} : wadd_fifo_buf[gen_i];//make sure not in stat_dat
            wram_add_lst[gen_i] = ff_mult || ff_bias ? 'd0 : wadd_fifo_lst[gen_i];
            wram_dat_rdy[gen_i] = ff_mult || ff_bias ? 'd1 : ~wram_fifo_full[gen_i];
        end
    end
endgenerate

//=====================================================================================================================
// Logic Design :
//=====================================================================================================================
always @ ( * )begin
    cfg_aram_add = CFG_ARAM_ADD;
    cfg_fram_add = CFG_FRAM_ADD;
    cfg_wram_add = CFG_WRAM_ADD;
    cfg_mult_add = CFG_MULT_ADD;
    cfg_bias_add = CFG_BIAS_ADD;
    cfg_flag_vld = CFG_FLAG_VLD;
    cfg_cpad_ena = CFG_CPAD_ENA;
    cfg_conv_ich = CFG_CONV_ICH;
    cfg_conv_och = CFG_CONV_OCH;
    cfg_conv_len = CFG_CONV_LEN;
    cfg_conv_wei = CFG_CONV_WEI;
    cfg_dila_fac = CFG_DILA_FAC;
    cfg_strd_fac = CFG_STRD_FAC;
    cfg_step_len = CFG_STEP_LEN;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cal_lpad_len <= 'd0;
        cal_rpad_len <= 'd0;
        cal_step_ich <= 'd0;
        cal_step_pix <= 'd0;
        cal_last_ich <= 'd0;
        cal_last_pix <= 'd0;
        cal_conv_ich <= 'd0;
    end
    else if( cfg_info_ena )begin
        cal_lpad_len <= CFG_CPAD_ENA && PEA_GEN_LPAD ? CFG_CONV_WEI[CONV_WEI_DW -1:1] : 'd0;
        cal_rpad_len <= CFG_CPAD_ENA && PEA_GEN_RPAD ? CFG_CONV_WEI[CONV_WEI_DW -1:1] : 'd0;
        cal_step_ich <= &CFG_CONV_ICH[0 +:2] ? 'd4 : 'd1;
        cal_step_pix <= CFG_STEP_LEN == 'd3 ? 'd8 : CFG_STEP_LEN == 'd2 ? 'd4 : CFG_STEP_LEN == 'd1 ? 'd2 : 'd1;
        cal_last_ich <= CFG_CONV_ICH[CONV_ICH_DW -1:2];
        cal_last_pix <= |CFG_DILA_FAC ? CFG_CONV_LEN>>CFG_DILA_FAC : CFG_CONV_LEN;
        cal_conv_ich <= CFG_CONV_ICH +'d1;
    end
end

always @( * )begin
    cal_flag_nzf = cfg_flag_vld ? {FRAM_DAT_DW{1'b0}} : {FRAM_DAT_DW{1'b1}};
end

always @( * )begin
    ff_mult_done =&mult_dat_vld;
    ff_bias_done =&bias_dat_vld;
    ff_lpad_done = ff_lpad_last;
    ff_tile_done = ff_tile_last;
    ff_rpad_done = ff_rpad_last;
    ff_conv_done = act_last_vld && aram_fifo_empty && &wram_fifo_empty;
end

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
      always @( * )begin
          wadd_fifo_wen[gen_i] = fwei_fifo_ren && ~fwei_fifo_empty;
          wadd_fifo_ren[gen_i] = wram_add_ena[gen_i];
          wadd_fifo_din[gen_i] = {wadd_lst_din, wadd_end_din, wadd_fid_din, wadd_och_din, wadd_buf_din, wadd_add_din};
      end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            wadd_fifo_add[gen_i] = wadd_fifo_out[gen_i][0 +:WRAM_ADD_AW];
            wadd_fifo_buf[gen_i] = wadd_fifo_out[gen_i][WRAM_ADD_AW +:STAT_DAT_DW];
            wadd_fifo_och[gen_i] = wadd_fifo_out[gen_i][WRAM_ADD_AW + STAT_DAT_DW +:WBUF_OCH_DW];
            wadd_fifo_fid[gen_i] = wadd_fifo_out[gen_i][WRAM_ADD_AW + STAT_DAT_DW + WBUF_OCH_DW +:CONV_WEI_DW];
            wadd_fifo_lst[gen_i] = wadd_fifo_out[gen_i][WADD_BUF_DW  -1];
            wadd_fifo_end[gen_i] = wadd_fifo_out[gen_i][WADD_BUF_DW  -2];
        end
    end
endgenerate

always @ ( * )begin
    aadd_fifo_ren = aram_add_ena;
end

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
      always @( * )begin
          wram_fifo_din[gen_i] = {wram_dat_end[gen_i], wram_dat_fid[gen_i], wram_dat_dat[gen_i]};
          wram_fifo_wen[gen_i] =  wram_dat_ena[gen_i] && ~ff_bias && ~ff_mult;
      end
    end
endgenerate

//for padding
wire [CONV_WEI_DW -1:0] ff_conv_wei_left = cfg_conv_wei - cfg_conv_wei[CONV_WEI_DW -1:1];
wire [CONV_WEI_DW -1:0] ff_conv_wei_half = cfg_conv_wei[CONV_WEI_DW -1:1];
generate
    for( gen_i=0 ; gen_i < WWEI_MAXLEN; gen_i = gen_i+1 )begin
        always @( * )begin
            if( ff_fifo_lpad )
                fwei_widx_din[gen_i] = gen_i+cfg_conv_wei-ff_fifo_pct;
            else if( ff_fifo_tile && (ff_fifo_pct<ff_conv_wei_half) )
                fwei_widx_din[gen_i] = gen_i +ff_conv_wei_half-ff_fifo_pct;
            else
                fwei_widx_din[gen_i] = gen_i;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < WWEI_MAXLEN; gen_i = gen_i+1 )begin
        always @( * )begin
            fwei_last_din[gen_i] = fwei_fifo_num<=gen_i;
            fwei_wfid_din[gen_i] = ff_fifo_rpad ? gen_i +ff_fifo_pct +'d1 : gen_i;//for act_add wont go forward for rpad
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < WWEI_MAXLEN; gen_i = gen_i+1 )begin
        always @( * )begin
            fwei_fifo_din[gen_i] = {fwei_last_din[gen_i], fwei_wfid_din[gen_i], fwei_widx_din[gen_i]};
        end
    end
endgenerate

always @ ( * )begin//for wei_len==5:1\2\3\4\5\5\5\5\4\3\2\1
    if( ff_fifo_lpad )
        fwei_fifo_num = ff_fifo_pct;
    else if( ff_fifo_tile )begin
        if( ff_fifo_pct<ff_conv_wei_half )
            fwei_fifo_num = ff_fifo_pct +ff_conv_wei_half;
        else if( (cfg_conv_len-ff_fifo_pct) < ff_conv_wei_half )
            fwei_fifo_num = cfg_conv_len +ff_conv_wei_half-ff_fifo_pct;
        else
            fwei_fifo_num = cfg_conv_wei;
    end
    else //ff_rpad
        fwei_fifo_num = ff_conv_wei_half -ff_fifo_pct -'d1;
end

always @( * )begin
    fwei_fifo_ren = ~|wadd_fifo_full;
end

wire [FRAM_DAT_DW -1:0] ff_mask_nzf_init = {{(FRAM_DAT_DW-1){1'd1}}, 1'd0}<<cfg_conv_ich[0 +:FRAM_DAT_AW];
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        ff_mask_nzf <= 'd0;
    else if( ff_load )
        ff_mask_nzf <= ~ff_mask_nzf_init;
    else if( ff_fifo_ren )
        ff_mask_nzf <= ~ff_mask_nzf_init;
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
    else if( fram_add_ena && ff_last_ich )
        ff_iidx <= 'd0;
    else if( ff_conv && fram_add_ena )
        ff_iidx <= ff_iidx +cal_step_ich;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        ff_cntr_ich <= 'd0;
    else if( ff_load )
        ff_cntr_ich <= 'd0;
    else if( fram_add_ena && ff_last_ich )
        ff_cntr_ich <= 'd0;
    else if( ff_conv && fram_add_ena )//ff_tile && fram_add_ena
        ff_cntr_ich <= ff_cntr_ich+'d1;
end

wire [2 -1:0] PEA_GEN_CIDX_M1 = PEA_GEN_CIDX-'d1;
wire [2 -1:0] PEA_GEN_CIDX_A1 = PEA_GEN_CIDX+'d1;
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        ff_ridx <= 'd0;
    else if( ff_load )
        ff_ridx <= |cal_lpad_len ? PEA_GEN_CIDX_M1 : PEA_GEN_CIDX;
    else if( ff_lpad && ff_lpad_done )
        ff_ridx <= PEA_GEN_CIDX;
    else if( ff_tile && ff_tile_done )
        ff_ridx <= |cal_rpad_len ? PEA_GEN_CIDX_A1 : |cal_lpad_len ? PEA_GEN_CIDX_M1 : PEA_GEN_CIDX;
    else if( ff_rpad && ff_rpad_done )
        ff_ridx <= |cal_lpad_len ? PEA_GEN_CIDX_M1 : PEA_GEN_CIDX;
end

wire [CONV_LEN_DW -1:0] ff_pidx_lpad = |cal_lpad_len ? CFG_CONV_LEN +'d1 -{{(DILA_FAC_DW){1'd0}}, cal_lpad_len}<<cfg_dila_fac : 'd0;
wire [DILA_LEN_DW -1:0] ff_pidx_didx = |cfg_step_len ? ff_didx +'d1 : 'd0;
wire [CONV_LEN_DW -1:0] ff_pidx_next = ff_pidx_lpad +ff_pidx_didx;
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        ff_pidx <= 'd0;
    else if( ff_load )
        ff_pidx <= ff_pidx_lpad;
    else if( ff_lpad && ff_lpad_done )
        ff_pidx <= ff_pidx_didx;
    else if( ff_tile && ff_tile_done )
        ff_pidx <= |cal_rpad_len ? ff_pidx_didx : ff_pidx_next;
    else if( ff_rpad && ff_rpad_done )
        ff_pidx <= ff_pidx_next;
    else if( ff_conv && fram_add_ena && ff_last_ich )
        ff_pidx <= ff_pidx +cal_step_pix;
end

wire [DILA_LEN_DW -1:0] ff_addr_didx = |cfg_step_len ? ff_didx*cal_conv_ich : 'd0;
wire [FRAM_ADD_AW -1:0] ff_addr_next = ff_pidx_lpad*cal_conv_ich +ff_addr_didx*cal_conv_ich;
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        ff_addr <= 'd0;
    else if( ff_load )
        ff_addr <= ff_pidx_lpad*cal_conv_ich;
    else if( ff_lpad && ff_lpad_done )
        ff_addr <= ff_addr_didx;
    else if( ff_tile && ff_tile_done )
        ff_addr <= |cal_rpad_len ? ff_addr_didx : ff_addr_next;
    else if( ff_rpad && ff_rpad_done )
        ff_addr <= ff_addr_next;
    else if( ff_conv && fram_add_ena )
        ff_addr <= ff_addr+cal_step_ich;
    else if( ff_conv && fram_add_ena && ff_last_ich )
        ff_addr <= (ff_pidx +cal_step_pix)*cal_conv_ich;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        ff_cntr_pix <= 'd0;
    else if( ff_load )
        ff_cntr_pix <= 'd0;
    else if( ff_lpad && ff_lpad_done )
        ff_cntr_pix <= 'd0;
    else if( ff_tile && ff_tile_done )
        ff_cntr_pix <= 'd0;
    else if( ff_rpad && ff_rpad_done )
        ff_cntr_pix <= 'd0;
    else if( ff_conv && fram_add_ena && ff_last_ich )
        ff_cntr_pix <= ff_cntr_pix+'d1;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        ff_oidx <= 'd0;
    else if( cfg_info_ena )
        ff_oidx <= 'd0;
    else if( fram_add_ena && ff_conv_last && ff_last_oidx )
        ff_oidx <= 'd0;
    else if( ff_conv_last && ff_last_didx )
        ff_oidx <= ff_oidx +'d1;//och//4
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        ff_didx <= 'd0;
    else if( cfg_info_ena )
        ff_didx <= 'd0;
    else if( fram_add_ena && ff_conv_last && ff_last_didx )
        ff_didx <= 'd0;
    else if( ff_conv_last )
        ff_didx <= ff_didx +'d1;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        fram_add_done <= 'd0;
    else if( ff_load )
        fram_add_done <= 'd0;
    else if( fram_add_ena && fram_add_lst )
        fram_add_done <= 'd1;
end

//MULT
generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        always @( * )begin
            mult_add_cnt_ena[gen_i] = ff_mult && wram_add_ena[gen_i];
            mult_dat_cnt_ena[gen_i] = ff_mult && wram_dat_ena[gen_i];
            mult_add_cnt_last[gen_i] = wram_add_ena[gen_i] && mult_add_cnt[gen_i]==(MULT_CNT_DW-1);
            mult_dat_cnt_last[gen_i] = wram_dat_ena[gen_i] && mult_dat_cnt[gen_i]==(MULT_CNT_DW-1);
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < MULT_CNT_DW; gen_j = gen_j+1 )begin
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    mult_dat_dat[gen_i][gen_j] <= 'd0;
                else if( ff_mult && wram_dat_ena[gen_i] && gen_j==mult_dat_cnt[gen_i] )
                    mult_dat_dat[gen_i][gen_j] <= wram_dat_dat[gen_i];
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        always @( * )begin
            mult_mul_dat[gen_i] = mult_dat_dat[gen_i][0 +:3];
            mult_sft_dat[gen_i] = mult_dat_dat[gen_i][3];
        end
    end
endgenerate

//BIAS
generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        always @( * )begin
            bias_add_cnt_ena[gen_i] = ff_bias && wram_add_ena[gen_i];
            bias_dat_cnt_ena[gen_i] = ff_bias && wram_dat_ena[gen_i];
            bias_add_cnt_last[gen_i] = wram_add_ena[gen_i] && bias_add_cnt[gen_i]==(BIAS_CNT_DW-1);
            bias_dat_cnt_last[gen_i] = wram_dat_ena[gen_i] && bias_dat_cnt[gen_i]==(BIAS_CNT_DW-1);
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < BIAS_CNT_DW; gen_j = gen_j+1 )begin
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    bias_dat_dat[gen_i][gen_j] <= 'd0;
                else if( ff_bias && wram_dat_ena[gen_i] && gen_j==bias_dat_cnt[gen_i] )
                    bias_dat_dat[gen_i][gen_j] <= wram_dat_dat[gen_i];
            end
        end
    end
endgenerate

//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================

//=====================================================================================================================
// FSM :
//=====================================================================================================================
always @ ( * )begin
  case( ff_cs )
    FF_IDLE: ff_ns = cfg_info_ena ? FF_LOAD : ff_cs;
    FF_LOAD: ff_ns = FF_MULT;
    FF_MULT: ff_ns = ff_mult_done ? FF_BIAS : ff_cs;
    FF_BIAS: ff_ns = ff_bias_done ? (|cal_lpad_len ? FF_LPAD : FF_TILE) : ff_cs;
    FF_LPAD: ff_ns = ff_lpad_done ? FF_TILE : ff_cs;
    FF_TILE: ff_ns = ff_tile_done ? (|cal_rpad_len ? FF_RPAD : FF_DONE) : ff_cs;
    FF_RPAD: ff_ns = ff_rpad_done ? FF_DONE : ff_cs;
    FF_DONE: ff_ns = ff_conv_done ? (aram_fifo_loop_end ? FF_IDLE : FF_MULT) : ff_cs;
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
localparam ASS_WNCH_BUF_DW = CONV_LEN_DW;

wire ass_fnch_fifo_wen = ff_fifo_wen_rdy;
wire ass_fnch_fifo_ren = fwei_fifo_ren && fwei_fifo_lst;
wire ass_fnch_fifo_empty;
wire ass_fnch_fifo_full;
wire [ASS_WNCH_BUF_DW -1:0] ass_fnch_fifo_din = {ff_fifo_pdx};
wire [ASS_WNCH_BUF_DW -1:0] ass_fnch_fifo_out;
wire [WNCH_BUF_AW   :0] ass_fnch_fifo_cnt;
wire [CONV_LEN_DW -1:0] fnch_fifo_pdx = ass_fnch_fifo_out;
CPM_FIFO      #( .DATA_WIDTH( ASS_WNCH_BUF_DW ), .ADDR_WIDTH( WNCH_BUF_AW ) )ASS_FNCH_FIFO_U( clk, rst_n, 1'd0, ass_fnch_fifo_wen, ass_fnch_fifo_ren, ass_fnch_fifo_din, ass_fnch_fifo_out, ass_fnch_fifo_empty, ass_fnch_fifo_full, ass_fnch_fifo_cnt);

//ASS_WRAM
//wire [PE_ROW -1:0] ass_wram_fifo_wen = wram_dat_ena;
//wire [PE_ROW -1:0] ass_wram_fifo_ren = wei_rdy;
//wire [PE_ROW -1:0] ass_wram_fifo_empty;
//wire [PE_ROW -1:0] ass_wram_fifo_full;
//reg  [PE_ROW -1:0][WRAM_BUF_DW -1:0] ass_wram_fifo_din;
//wire [PE_ROW -1:0][WRAM_BUF_DW -1:0] ass_wram_fifo_out;
//wire [PE_ROW -1:0][WRAM_BUF_AW   :0] ass_wram_fifo_cnt;
//wire [PE_ROW -1:0][WRAM_BUF_AW   :0] ass_wram_fifo_cnt_empty;
//
//CPM_FIFO_EX #( .DATA_WIDTH( WRAM_BUF_DW ), .ADDR_WIDTH( 32 ) )ASS_WRAM_FIFO_U[PE_ROW-1:0] ( clk, rst_n, 1'd0, ass_wram_fifo_wen, ass_wram_fifo_ren, ass_wram_fifo_din, ass_wram_fifo_out, ass_wram_fifo_empty, ass_wram_fifo_full, ass_wram_fifo_cnt, ass_wram_fifo_cnt_empty );

//ass cnt
wire [32 -1:0] ass_aram_add_cnt;
wire [32 -1:0] ass_aram_dat_cnt;
wire [32 -1:0] ass_fram_add_cnt;
wire [32 -1:0] ass_fram_dat_cnt;
wire [PE_ROW -1:0][32 -1:0] ass_wram_add_cnt;
wire [PE_ROW -1:0][32 -1:0] ass_wram_dat_cnt;
wire [PE_ROW -1:0][32 -1:0] ass_wram_buf_cnt;

CPM_CNT #( 32 ) ASS_ARAM_ADD_CNT_REG ( clk, rst_n, aram_add_ena, ass_aram_add_cnt );
CPM_CNT #( 32 ) ASS_ARAM_DAT_CNT_REG ( clk, rst_n, aram_dat_ena, ass_aram_dat_cnt );
CPM_CNT #( 32 ) ASS_FRAM_ADD_CNT_REG ( clk, rst_n, fram_add_ena, ass_fram_add_cnt );
CPM_CNT #( 32 ) ASS_FRAM_DAT_CNT_REG ( clk, rst_n, fram_dat_ena, ass_fram_dat_cnt );
CPM_CNT #( 32 ) ASS_WRAM_ADD_CNT_REG[PE_ROW -1:0] ( clk, rst_n, wram_add_ena, ass_wram_add_cnt );
CPM_CNT #( 32 ) ASS_WRAM_DAT_CNT_REG[PE_ROW -1:0] ( clk, rst_n, wram_dat_ena, ass_wram_dat_cnt );

wire [32 -1:0] ass_act_dat_cnt;
wire [PE_ROW -1:0][32 -1:0] ass_wei_dat_cnt;
wire [PE_ROW -1:0][32 -1:0] ass_wei_lst_cnt;
CPM_CNT #( 32 ) ASS_ACT_DAT_CNT_REG              ( clk, rst_n, act_vld & act_rdy, ass_act_dat_cnt );
CPM_CNT #( 32 ) ASS_WEI_DAT_CNT_REG[PE_ROW -1:0] ( clk, rst_n, wei_vld & wei_rdy, ass_wei_dat_cnt );
CPM_CNT #( 32 ) ASS_WEI_LST_CNT_REG[PE_ROW -1:0] ( clk, rst_n, wei_ena & wei_lst, ass_wei_lst_cnt );

property ram_cnt_check(is_idle, add_cnt, dat_cnt);
@(posedge clk)
disable iff(rst_n!=1'b1)
    is_idle |-> ( add_cnt==dat_cnt );
endproperty

assert property ( ram_cnt_check(ff_idle, ass_aram_add_cnt, ass_aram_dat_cnt ) );
assert property ( ram_cnt_check(ff_idle, ass_fram_add_cnt, ass_fram_dat_cnt ) );

generate
  for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 ) begin : ASSERT_BLOCK

    assert property ( ram_cnt_check(ff_idle, ass_wram_add_cnt, ass_wram_dat_cnt ) );

  end
endgenerate

`endif
endmodule
