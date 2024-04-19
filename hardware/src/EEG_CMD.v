//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description : CMD
//========================================================
module EEG_CMD #(
    parameter STAT_CMD_DW =  9,
    parameter CHIP_CMD_DW = 32,
    parameter BANK_NUM_DW =  4,
    parameter CONV_ICH_DW =  8,//256
    parameter CONV_OCH_DW =  8,//256
    parameter CONV_LEN_DW = 10,//1024
    parameter CONV_SUM_DW = 24,
    parameter CONV_MUL_DW = CONV_SUM_DW,
    parameter CONV_SFT_DW =  4,
    parameter CONV_ADD_DW = CONV_SUM_DW,
    parameter DILA_FAC_DW =  2,//1/2/4/8
    parameter STRD_FAC_DW =  2,//1/2/4/8
    parameter CONV_WEI_DW =  3,//8
    parameter CONV_SPT_DW =  8,//256
    parameter POOL_FAC_DW =  2,//1/2/4/8
    parameter ARAM_NUM_DW = BANK_NUM_DW,
    parameter WRAM_NUM_DW = BANK_NUM_DW,
    parameter ORAM_NUM_DW = BANK_NUM_DW,
    parameter OMUX_NUM_DW = BANK_NUM_DW,
    parameter ARAM_ADD_AW = 12,//4k
    parameter WRAM_ADD_AW = 13,//8k
    parameter ORAM_ADD_AW = 10,//1k
    parameter POOL_LEN_DW = ORAM_ADD_AW
  )(
    input                        clk,
    input                        rst_n,
                                        
    input                        CFG_ACMD_VLD,
    input  [CHIP_CMD_DW    -1:0] CFG_ACMD_DAT,
    output                       CFG_INFO_VLD,
    output [STAT_CMD_DW    -1:0] CFG_INFO_CMD,
    output                       CMD_ITOA_ENA,
    output                       CMD_ITOW_ENA,
    output                       CMD_OTOA_ENA,
    output                       CMD_ATOW_ENA,
    output                       CMD_WTOA_ENA,
    output                       CMD_CONV_ENA,
    output                       CMD_POOL_ENA,
    output                       CMD_STAT_ENA,
    output                       CMD_READ_ENA,
    //ENA
    output                       CFG_RELU_ENA,
    output                       CFG_SPLT_ENA,
    output                       CFG_COMB_ENA,
    output                       CFG_FLAG_ENA,
    output                       CFG_MAXP_ENA,
    output                       CFG_AVGP_ENA,
    output                       CFG_RESN_ENA,
    output                       CFG_FLAG_VLD,
    output                       CFG_STAT_VLD,
    output                       CFG_WBUF_ENA,
    //RAM
    output [ARAM_NUM_DW    -1:0] CFG_ARAM_IDX,
    output [WRAM_NUM_DW    -1:0] CFG_WRAM_IDX,
    output [ORAM_NUM_DW    -1:0] CFG_ORAM_IDX,
    output [OMUX_NUM_DW    -1:0] CFG_OMUX_IDX,
    output [ARAM_ADD_AW    -1:0] CFG_ARAM_ADD,
    output [WRAM_ADD_AW    -1:0] CFG_WRAM_ADD,
    output [ORAM_ADD_AW    -1:0] CFG_ORAM_ADD,
    output [ARAM_ADD_AW    -1:0] CFG_ARAM_LEN,
    output [WRAM_ADD_AW    -1:0] CFG_WRAM_LEN,
    output [ORAM_ADD_AW    -1:0] CFG_ORAM_LEN,
    //CONV
    output [CONV_ICH_DW    -1:0] CFG_CONV_ICH,
    output [CONV_OCH_DW    -1:0] CFG_CONV_OCH,
    output [CONV_LEN_DW    -1:0] CFG_CONV_LEN,
    output [CONV_MUL_DW    -1:0] CFG_CONV_MUL,
    output [CONV_SFT_DW    -1:0] CFG_CONV_SFT,
    output [CONV_ADD_DW    -1:0] CFG_CONV_ADD,
    output [DILA_FAC_DW    -1:0] CFG_DILA_FAC,
    output [STRD_FAC_DW    -1:0] CFG_STRD_FAC,
    output [CONV_WEI_DW    -1:0] CFG_CONV_WEI,
    //SPLT
    output [CONV_SPT_DW    -1:0] CFG_SPLT_LEN,
    //POOL
    output [POOL_LEN_DW    -1:0] CFG_POOL_LEN,
    output [POOL_FAC_DW    -1:0] CFG_POOL_FAC
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
localparam MODE_CMD_DW = 4;

localparam CMD_ITOA = 4'd0;
localparam CMD_ITOW = 4'd1;
localparam CMD_OTOA = 4'd2;
localparam CMD_ATOW = 4'd3;
localparam CMD_WTOA = 4'd4;
localparam CMD_CONV = 4'd5;
localparam CMD_POOL = 4'd6;
localparam CMD_STAT = 4'd7;
localparam CMD_READ = 4'd8;

localparam INF_MULT = 4'd10;
localparam INF_BIAS = 4'd11;
localparam INF_CONV = 4'd12;
localparam INF_ARAM = 4'd13;
localparam INF_WRAM = 4'd14;
localparam INF_ORAM = 4'd15;
integer i;
genvar gen_i, gen_j;
//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
//CFG_IO
wire                     cfg_acmd_vld = CFG_ACMD_VLD;
wire [CHIP_CMD_DW  -1:0] cfg_acmd_dat = CFG_ACMD_DAT;
wire                     cfg_info_vld;
wire [STAT_CMD_DW  -1:0] cfg_info_cmd;
wire [MODE_CMD_DW  -1:0] cfg_mode_cmd = CFG_ACMD_DAT[0 +:4];

assign CFG_INFO_VLD = cfg_info_vld;
assign CFG_INFO_CMD = cfg_info_cmd;

CPM_REG #( 1 ) CFG_VLD_REG( clk, rst_n, cfg_acmd_vld, cfg_info_vld );
//RAM
reg [ARAM_NUM_DW  -1:0] cfg_aram_idx;
reg [WRAM_NUM_DW  -1:0] cfg_wram_idx;
reg [ORAM_NUM_DW  -1:0] cfg_oram_idx;
reg [OMUX_NUM_DW  -1:0] cfg_omux_idx;
reg [ARAM_ADD_AW  -1:0] cfg_aram_add;
reg [WRAM_ADD_AW  -1:0] cfg_wram_add;
reg [ORAM_ADD_AW  -1:0] cfg_oram_add;
reg [ARAM_ADD_AW  -1:0] cfg_aram_len;
reg [WRAM_ADD_AW  -1:0] cfg_wram_len;
reg [ORAM_ADD_AW  -1:0] cfg_oram_len;

assign CFG_ARAM_IDX = cfg_aram_idx;
assign CFG_WRAM_IDX = cfg_wram_idx;
assign CFG_ORAM_IDX = cfg_oram_idx;
assign CFG_OMUX_IDX = cfg_omux_idx;
assign CFG_ARAM_ADD = cfg_aram_add;
assign CFG_WRAM_ADD = cfg_wram_add;
assign CFG_ORAM_ADD = cfg_oram_add;
assign CFG_ARAM_LEN = cfg_aram_len;
assign CFG_WRAM_LEN = cfg_wram_len;
assign CFG_ORAM_LEN = cfg_oram_len;

//CONV
reg [CONV_ICH_DW  -1:0] cfg_conv_ich;
reg [CONV_OCH_DW  -1:0] cfg_conv_och;
reg [CONV_LEN_DW  -1:0] cfg_conv_len;
reg [CONV_MUL_DW  -1:0] cfg_conv_mul;
reg [CONV_SFT_DW  -1:0] cfg_conv_sft;
reg [CONV_ADD_DW  -1:0] cfg_conv_add;
reg [DILA_FAC_DW  -1:0] cfg_dila_fac;
reg [STRD_FAC_DW  -1:0] cfg_strd_fac;
reg [CONV_WEI_DW  -1:0] cfg_conv_wei;

assign CFG_CONV_ICH = cfg_conv_ich;
assign CFG_CONV_OCH = cfg_conv_och;
assign CFG_CONV_LEN = cfg_conv_len;
assign CFG_CONV_MUL = cfg_conv_mul;
assign CFG_CONV_SFT = cfg_conv_sft;
assign CFG_CONV_ADD = cfg_conv_add;
assign CFG_DILA_FAC = cfg_dila_fac;
assign CFG_STRD_FAC = cfg_strd_fac;
assign CFG_CONV_WEI = cfg_conv_wei;

//SPLT
reg [CONV_SPT_DW  -1:0] cfg_splt_len;

assign CFG_SPLT_LEN = cfg_splt_len;
//POOL
reg [POOL_LEN_DW  -1:0] cfg_pool_len;
reg [POOL_FAC_DW  -1:0] cfg_pool_fac;

assign CFG_POOL_LEN = cfg_pool_len;
assign CFG_POOL_FAC = cfg_pool_fac;

//ENA
wire cfg_relu_ena;
wire cfg_splt_ena;
wire cfg_comb_ena;
wire cfg_flag_ena;
wire cfg_maxp_ena;
wire cfg_avgp_ena;
wire cfg_resn_ena;
wire cfg_flag_vld;
wire cfg_stat_vld;
wire cfg_wbuf_ena;

assign CFG_RELU_ENA = cfg_relu_ena;
assign CFG_SPLT_ENA = cfg_splt_ena;
assign CFG_COMB_ENA = cfg_comb_ena;
assign CFG_FLAG_ENA = cfg_flag_ena;
assign CFG_MAXP_ENA = cfg_maxp_ena;
assign CFG_AVGP_ENA = cfg_avgp_ena;
assign CFG_RESN_ENA = cfg_resn_ena;
assign CFG_FLAG_VLD = cfg_flag_vld;
assign CFG_STAT_VLD = cfg_stat_vld;
assign CFG_WBUF_ENA = cfg_wbuf_ena;
//CMD
wire cmd_itoa_ena;
wire cmd_itow_ena;
wire cmd_otoa_ena;
wire cmd_atow_ena;
wire cmd_wtoa_ena;
wire cmd_conv_ena;
wire cmd_pool_ena;
wire cmd_stat_ena;
wire cmd_read_ena;

assign CMD_ITOA_ENA = cmd_itoa_ena;
assign CMD_ITOW_ENA = cmd_itow_ena;
assign CMD_OTOA_ENA = cmd_otoa_ena;
assign CMD_ATOW_ENA = cmd_atow_ena;
assign CMD_WTOA_ENA = cmd_wtoa_ena;
assign CMD_CONV_ENA = cmd_conv_ena;
assign CMD_POOL_ENA = cmd_pool_ena;
assign CMD_STAT_ENA = cmd_stat_ena;
assign CMD_READ_ENA = cmd_read_ena;
assign cfg_info_cmd = {cmd_read_ena, cmd_stat_ena, cmd_pool_ena, cmd_conv_ena, cmd_wtoa_ena,
                       cmd_atow_ena, cmd_otoa_ena, cmd_itow_ena, cmd_itoa_ena};
//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================
wire cfg_relu_ena_ena = cfg_acmd_vld && cfg_mode_cmd==CMD_OTOA;
wire cfg_splt_ena_ena = cfg_acmd_vld && cfg_mode_cmd==CMD_OTOA;
wire cfg_comb_ena_ena = cfg_acmd_vld && cfg_mode_cmd==CMD_OTOA;
wire cfg_flag_ena_ena = cfg_acmd_vld && cfg_mode_cmd==CMD_OTOA;
wire cfg_maxp_ena_ena = cfg_acmd_vld && cfg_mode_cmd==CMD_POOL;
wire cfg_avgp_ena_ena = cfg_acmd_vld && cfg_mode_cmd==CMD_POOL;
wire cfg_resn_ena_ena = cfg_acmd_vld && cfg_mode_cmd==CMD_CONV;
wire cfg_flag_vld_ena = cfg_acmd_vld && cfg_mode_cmd==CMD_CONV;
wire cfg_stat_vld_ena = cfg_acmd_vld && cfg_mode_cmd==CMD_CONV;
wire cfg_wbuf_ena_ena = cfg_acmd_vld && cfg_mode_cmd==CMD_CONV;
CPM_REG_E #( 1 ) CFG_RELU_ENA_REG( clk, rst_n, cfg_relu_ena_ena, cfg_acmd_dat[20], cfg_relu_ena );
CPM_REG_E #( 1 ) CFG_SPLT_ENA_REG( clk, rst_n, cfg_splt_ena_ena, cfg_acmd_dat[21], cfg_splt_ena );
CPM_REG_E #( 1 ) CFG_COMB_ENA_REG( clk, rst_n, cfg_comb_ena_ena, cfg_acmd_dat[22], cfg_comb_ena );
CPM_REG_E #( 1 ) CFG_FLAG_ENA_REG( clk, rst_n, cfg_flag_ena_ena, cfg_acmd_dat[23], cfg_flag_ena );
CPM_REG_E #( 1 ) CFG_MAXP_ENA_REG( clk, rst_n, cfg_maxp_ena_ena, cfg_acmd_dat[16], cfg_maxp_ena );
CPM_REG_E #( 1 ) CFG_AVGP_ENA_REG( clk, rst_n, cfg_avgp_ena_ena, cfg_acmd_dat[17], cfg_avgp_ena );
CPM_REG_E #( 1 ) CFG_RESN_ENA_REG( clk, rst_n, cfg_resn_ena_ena, cfg_acmd_dat[11], cfg_resn_ena );
CPM_REG_E #( 1 ) CFG_FLAG_VLD_REG( clk, rst_n, cfg_flag_vld_ena, cfg_acmd_dat[11], cfg_flag_vld );
CPM_REG_E #( 1 ) CFG_STAT_VLD_REG( clk, rst_n, cfg_stat_vld_ena, cfg_acmd_dat[11], cfg_stat_vld );
CPM_REG_E #( 1 ) CFG_WBUF_ENA_REG( clk, rst_n, cfg_wbuf_ena_ena, cfg_acmd_dat[11], cfg_wbuf_ena );
//=====================================================================================================================
// IO Logic Design :
//=====================================================================================================================
wire cmd_itoa_ena_tmp = cfg_mode_cmd==CMD_ITOA;
wire cmd_itow_ena_tmp = cfg_mode_cmd==CMD_ITOW;
wire cmd_otoa_ena_tmp = cfg_mode_cmd==CMD_OTOA;
wire cmd_atow_ena_tmp = cfg_mode_cmd==CMD_ATOW;
wire cmd_wtoa_ena_tmp = cfg_mode_cmd==CMD_WTOA;
wire cmd_conv_ena_tmp = cfg_mode_cmd==CMD_CONV;
wire cmd_pool_ena_tmp = cfg_mode_cmd==CMD_POOL;
wire cmd_stat_ena_tmp = cfg_mode_cmd==CMD_STAT;
wire cmd_read_ena_tmp = cfg_mode_cmd==CMD_READ;
CPM_REG_E #( 1 ) CMD_ITOA_ENA_REG( clk, rst_n, cfg_acmd_vld, cmd_itoa_ena_tmp, cmd_itoa_ena );
CPM_REG_E #( 1 ) CMD_ITOW_ENA_REG( clk, rst_n, cfg_acmd_vld, cmd_itow_ena_tmp, cmd_itow_ena );
CPM_REG_E #( 1 ) CMD_OTOA_ENA_REG( clk, rst_n, cfg_acmd_vld, cmd_otoa_ena_tmp, cmd_otoa_ena );
CPM_REG_E #( 1 ) CMD_ATOW_ENA_REG( clk, rst_n, cfg_acmd_vld, cmd_atow_ena_tmp, cmd_atow_ena );
CPM_REG_E #( 1 ) CMD_WTOA_ENA_REG( clk, rst_n, cfg_acmd_vld, cmd_wtoa_ena_tmp, cmd_wtoa_ena );
CPM_REG_E #( 1 ) CMD_CONV_ENA_REG( clk, rst_n, cfg_acmd_vld, cmd_conv_ena_tmp, cmd_conv_ena );
CPM_REG_E #( 1 ) CMD_POOL_ENA_REG( clk, rst_n, cfg_acmd_vld, cmd_pool_ena_tmp, cmd_pool_ena );
CPM_REG_E #( 1 ) CMD_STAT_ENA_REG( clk, rst_n, cfg_acmd_vld, cmd_stat_ena_tmp, cmd_stat_ena );
CPM_REG_E #( 1 ) CMD_READ_ENA_REG( clk, rst_n, cfg_acmd_vld, cmd_read_ena_tmp, cmd_read_ena );
//=====================================================================================================================
// Logic Design :
//=====================================================================================================================
//always @ ( posedge clk or negedge rst_n )begin
//    if( ~rst_n )begin
//        cfg_aram_idx <= 'd0;
//    end else if( cfg_acmd_vld )begin
//        case( cfg_mode_cmd )
//            CMD_ITOA: cfg_aram_idx <= cfg_acmd_dat[0 +:12];
//            CMD_ITOW: cfg_aram_idx <= cfg_acmd_dat[0 +:12];
//            CMD_OTOA: cfg_aram_idx <= cfg_acmd_dat[0 +:12];
//            CMD_ATOW: cfg_aram_idx <= cfg_acmd_dat[0 +:12];
//            CMD_WTOA: cfg_aram_idx <= cfg_acmd_dat[0 +:12];
//            CMD_CONV: cfg_aram_idx <= cfg_acmd_dat[0 +:12];
//            CMD_POOL: cfg_aram_idx <= cfg_acmd_dat[0 +:12];
//            CMD_STAT: cfg_aram_idx <= cfg_acmd_dat[0 +:12];
//            CMD_READ: cfg_aram_idx <= cfg_acmd_dat[0 +:12];
//            INF_MULT: cfg_aram_idx <= cfg_acmd_dat[0 +:12];
//            INF_BIAS: cfg_aram_idx <= cfg_acmd_dat[0 +:12];
//            INF_CONV: cfg_aram_idx <= cfg_acmd_dat[0 +:12];
//            INF_ARAM: cfg_aram_idx <= cfg_acmd_dat[0 +:12];
//            INF_WRAM: cfg_aram_idx <= cfg_acmd_dat[0 +:12];
//            INF_ORAM: cfg_aram_idx <= cfg_acmd_dat[0 +:12];
//             default: cfg_aram_idx <= cfg_aram_idx;
//        endcase
//    end
//end
//RAM
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_aram_idx <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            CMD_ITOA: cfg_aram_idx <= cfg_acmd_dat[16 +:4];
            CMD_OTOA: cfg_aram_idx <= cfg_acmd_dat[16 +:4];
            CMD_ATOW: cfg_aram_idx <= cfg_acmd_dat[16 +:4];
            CMD_WTOA: cfg_aram_idx <= cfg_acmd_dat[16 +:4];
            CMD_READ: cfg_aram_idx <= cfg_acmd_dat[16 +:4];
             default: cfg_aram_idx <= cfg_aram_idx;
        endcase
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_wram_idx <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            CMD_ITOW: cfg_wram_idx <= cfg_acmd_dat[17 +:2] == 'd3 ? 4'b1000 : cfg_acmd_dat[17 +:2] == 'd2 ? 4'b0100 : cfg_acmd_dat[17 +:2] == 'd1 ? 4'b0010 : 4'b0001;
            CMD_ATOW: cfg_wram_idx <= cfg_acmd_dat[12 +:4];
            CMD_WTOA: cfg_wram_idx <= cfg_acmd_dat[12 +:4];
            CMD_READ: cfg_wram_idx <= cfg_acmd_dat[12 +:4];
             default: cfg_wram_idx <= cfg_wram_idx;
        endcase
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_oram_idx <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            CMD_OTOA: cfg_oram_idx <= cfg_acmd_dat[8 +:4];
            CMD_STAT: cfg_oram_idx <= cfg_acmd_dat[8 +:4];
            CMD_READ: cfg_oram_idx <= cfg_acmd_dat[8 +:4];
             default: cfg_oram_idx <= cfg_oram_idx;
        endcase
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_omux_idx <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            CMD_OTOA: cfg_omux_idx <= cfg_acmd_dat[12+:4];
             default: cfg_omux_idx <= cfg_omux_idx;
        endcase
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_aram_add <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            CMD_ITOA: cfg_aram_add <= cfg_acmd_dat[20 +:12];
            INF_ARAM: cfg_aram_add <= cfg_acmd_dat[20 +:12];
             default: cfg_aram_add <= cfg_aram_add;
        endcase
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_wram_add <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            CMD_ITOW: cfg_wram_add <= cfg_acmd_dat[19 +:13];
            INF_WRAM: cfg_wram_add <= cfg_acmd_dat[19 +:13];
             default: cfg_wram_add <= cfg_wram_add;
        endcase
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_oram_add <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            INF_ORAM: cfg_oram_add <= cfg_acmd_dat[22 +:10];
             default: cfg_oram_add <= cfg_oram_add;
        endcase
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_aram_len <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            CMD_ITOA: cfg_aram_len <= cfg_acmd_dat[4 +:12];
            INF_ARAM: cfg_aram_len <= cfg_acmd_dat[4 +:12];
             default: cfg_aram_len <= cfg_aram_len;
        endcase
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_wram_len <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            CMD_ITOW: cfg_wram_len <= cfg_acmd_dat[4 +:13];
            INF_WRAM: cfg_wram_len <= cfg_acmd_dat[4 +:13];
             default: cfg_wram_len <= cfg_wram_len;
        endcase
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_oram_len <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            INF_ORAM: cfg_oram_len <= cfg_acmd_dat[4 +:10];
             default: cfg_oram_len <= cfg_oram_len;
        endcase
    end
end
//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================
//CONV
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_conv_ich <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            INF_CONV: cfg_conv_ich <= cfg_acmd_dat[4 +:8];
             default: cfg_conv_ich <= cfg_conv_ich;
        endcase
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_conv_och <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            INF_CONV: cfg_conv_och <= cfg_acmd_dat[12 +:8];
             default: cfg_conv_och <= cfg_conv_och;
        endcase
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_conv_len <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            INF_CONV: cfg_conv_len <= cfg_acmd_dat[20 +:10];
             default: cfg_conv_len <= cfg_conv_len;
        endcase
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_conv_mul <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            INF_MULT: cfg_conv_mul <= cfg_acmd_dat[4 +:24];
             default: cfg_conv_mul <= cfg_conv_mul;
        endcase
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_conv_sft <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            INF_MULT: cfg_conv_sft <= cfg_acmd_dat[28 +:4];
             default: cfg_conv_sft <= cfg_conv_sft;
        endcase
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_conv_add <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            INF_BIAS: cfg_conv_add <= cfg_acmd_dat[4 +:24];
             default: cfg_conv_add <= cfg_conv_add;
        endcase
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_dila_fac <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            CMD_CONV: cfg_dila_fac <= cfg_acmd_dat[6 +:2];
             default: cfg_dila_fac <= cfg_dila_fac;
        endcase
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_strd_fac <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            CMD_CONV: cfg_strd_fac <= cfg_acmd_dat[4 +:2];
             default: cfg_strd_fac <= cfg_strd_fac;
        endcase
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_conv_wei <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            CMD_CONV: cfg_conv_wei <= cfg_acmd_dat[8 +:3];
             default: cfg_conv_wei <= cfg_conv_wei;
        endcase
    end
end

//=====================================================================================================================
// FSM :
//=====================================================================================================================
//SPLT
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_splt_len <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            CMD_OTOA: cfg_splt_len <= cfg_acmd_dat[24 +:8];
             default: cfg_splt_len <= cfg_splt_len;
        endcase
    end
end

//POOL
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_pool_len <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            CMD_POOL: cfg_pool_len <= cfg_acmd_dat[4 +:10];
             default: cfg_pool_len <= cfg_pool_len;
        endcase
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_pool_fac <= 'd0;
    end else if( cfg_acmd_vld )begin
        case( cfg_mode_cmd )
            CMD_POOL: cfg_pool_fac <= cfg_acmd_dat[14 +:2];
             default: cfg_pool_fac <= cfg_pool_fac;
        endcase
    end
end

`ifdef ASSERT_ON


`endif
endmodule
