//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description : PE ARRAY
//========================================================
module EEG_PEA #(
    parameter PEAY_CMD_DW =  3,
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
    parameter ARAM_ADD_AW = 12,//4k
    parameter WRAM_ADD_AW = 13,//8k
    parameter ORAM_ADD_AW = 10,//1k
    parameter OMUX_ADD_AW =  8,
    parameter FRAM_ADD_AW = ARAM_ADD_AW,
    parameter ARAM_DAT_DW = 8,
    parameter WRAM_DAT_DW = 8,
    parameter ORAM_DAT_DW = 8,
    parameter FRAM_DAT_DW = 4,
    parameter STAT_DAT_DW = CONV_ICH_DW+CONV_WEI_DW,
    parameter PE_COL = BANK_NUM_DW,
    parameter PE_ROW = BANK_NUM_DW
  )(
    input                                                  clk,
    input                                                  rst_n,
    
    output                                                 IS_IDLE,
                                                                  
    input                                                  CFG_INFO_VLD,
    output                                                 CFG_INFO_RDY,
    input  [PEAY_CMD_DW                              -1:0] CFG_INFO_CMD,
    
    input  [ARAM_ADD_AW                              -1:0] CFG_ARAM_ADD,
    input  [WRAM_ADD_AW                              -1:0] CFG_WRAM_ADD,
    input                                                  CFG_CPAD_ENA,
    input  [CONV_ICH_DW                              -1:0] CFG_CONV_ICH,
    input  [CONV_OCH_DW                              -1:0] CFG_CONV_OCH,
    input  [CONV_LEN_DW                              -1:0] CFG_CONV_LEN,
    input  [CONV_MUL_DW                              -1:0] CFG_CONV_MUL,
    input  [CONV_SFT_DW                              -1:0] CFG_CONV_SFT,
    input  [CONV_ADD_DW                              -1:0] CFG_CONV_ADD,
    input  [CONV_WEI_DW                              -1:0] CFG_CONV_WEI,
    input                                                  CFG_FLAG_VLD,
    input  [DILA_FAC_DW                              -1:0] CFG_DILA_FAC,
    input  [STRD_FAC_DW                              -1:0] CFG_STRD_FAC,

    output              [PE_COL -1:0][2              -1:0] FRAM_ADD_RID,
    output              [PE_COL -1:0]                      FRAM_ADD_VLD,
    input               [PE_COL -1:0]                      FRAM_ADD_RDY,
    output              [PE_COL -1:0]                      FRAM_ADD_LST,
    output              [PE_COL -1:0][FRAM_ADD_AW    -1:0] FRAM_ADD_ADD,
    input               [PE_COL -1:0]                      FRAM_DAT_VLD,
    input               [PE_COL -1:0]                      FRAM_DAT_LST,
    output              [PE_COL -1:0]                      FRAM_DAT_RDY,
    input               [PE_COL -1:0][FRAM_DAT_DW    -1:0] FRAM_DAT_DAT,

    output              [PE_COL -1:0][2              -1:0] ARAM_ADD_RID,
    output              [PE_COL -1:0]                      ARAM_ADD_VLD,
    output              [PE_COL -1:0]                      ARAM_ADD_LST,
    input               [PE_COL -1:0]                      ARAM_ADD_RDY,
    output              [PE_COL -1:0][ARAM_ADD_AW    -1:0] ARAM_ADD_ADD,
    input               [PE_COL -1:0]                      ARAM_DAT_VLD,
    input               [PE_COL -1:0]                      ARAM_DAT_LST,
    output              [PE_COL -1:0]                      ARAM_DAT_RDY,
    input               [PE_COL -1:0][ARAM_DAT_DW    -1:0] ARAM_DAT_DAT,

    output [PE_ROW -1:0][PE_COL -1:0]                      WRAM_ADD_VLD,
    output [PE_ROW -1:0][PE_COL -1:0]                      WRAM_ADD_LST,
    input  [PE_ROW -1:0][PE_COL -1:0]                      WRAM_ADD_RDY,
    output [PE_ROW -1:0][PE_COL -1:0][WRAM_ADD_AW    -1:0] WRAM_ADD_ADD,
    output [PE_ROW -1:0][PE_COL -1:0][STAT_DAT_DW    -1:0] WRAM_ADD_BUF,
    input  [PE_ROW -1:0][PE_COL -1:0]                      WRAM_DAT_VLD,
    input  [PE_ROW -1:0][PE_COL -1:0]                      WRAM_DAT_LST,
    output [PE_ROW -1:0][PE_COL -1:0]                      WRAM_DAT_RDY,
    input  [PE_ROW -1:0][PE_COL -1:0][WRAM_DAT_DW    -1:0] WRAM_DAT_DAT,

    output [PE_COL -1:0][PE_ROW -1:0]                      ORAM_DAT_VLD,
    output [PE_COL -1:0][PE_ROW -1:0]                      ORAM_DAT_LST,
    input  [PE_COL -1:0][PE_ROW -1:0]                      ORAM_DAT_RDY,
    output [PE_COL -1:0][PE_ROW -1:0][OMUX_ADD_AW    -1:0] ORAM_DAT_ADD,
    output [PE_COL -1:0][PE_ROW -1:0][ORAM_DAT_DW    -1:0] ORAM_DAT_DAT
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
localparam CONV_RUN_DW = 4;
localparam DATA_ACT_IW = ARAM_ADD_AW;
localparam DATA_WEI_IW = CONV_WEI_DW;
localparam DATA_ACT_DW = ARAM_DAT_DW;
localparam DATA_WEI_DW = WRAM_DAT_DW;
localparam DATA_OUT_DW = ORAM_DAT_DW;
localparam ARAM_NUM_DW = BANK_NUM_DW;
localparam ARAM_NUM_AW = $clog2(ARAM_NUM_DW);

integer i;
genvar gen_i, gen_j;

localparam PEA_STATE = 3;
localparam PEA_IDLE  = 3'b001;
localparam PEA_LOAD  = 3'b010;
localparam PEA_CONV  = 3'b100;

reg [PEA_STATE -1:0] pea_cs;
reg [PEA_STATE -1:0] pea_ns;

wire pea_idle = pea_cs == PEA_IDLE;
wire pea_load = pea_cs == PEA_LOAD;
wire pea_conv = pea_cs == PEA_CONV;
assign IS_IDLE = pea_idle;
reg pea_info_done;
reg pea_load_done;
reg pea_conv_done;
//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
//CFG_IO
wire cfg_info_vld = CFG_INFO_VLD;
reg  cfg_info_rdy;

wire [PEAY_CMD_DW -1:0] cfg_info_cmd = CFG_INFO_CMD;
reg  [ARAM_ADD_AW -1:0] cfg_aram_add;
reg  [WRAM_ADD_AW -1:0] cfg_wram_add;
reg                     cfg_cpad_ena;
reg  [CONV_ICH_DW -1:0] cfg_conv_ich;
reg  [CONV_OCH_DW -1:0] cfg_conv_och;
reg  [CONV_LEN_DW -1:0] cfg_conv_len;
reg  [CONV_MUL_DW -1:0] cfg_conv_mul;
reg  [CONV_SFT_DW -1:0] cfg_conv_sft;
reg  [CONV_ADD_DW -1:0] cfg_conv_add;
reg  [CONV_WEI_DW -1:0] cfg_conv_wei;
reg                     cfg_flag_vld;
reg  [DILA_FAC_DW -1:0] cfg_dila_fac;
reg  [STRD_FAC_DW -1:0] cfg_strd_fac;
reg  [CONV_RUN_DW -1:0] cfg_conv_run;
reg  [ORAM_ADD_AW -1:0] cfg_conv_lst;
wire [CONV_WEI_DW -1:0] cfg_conv_pad = cfg_conv_wei[CONV_WEI_DW -1:1];

assign CFG_INFO_RDY = cfg_info_rdy;

wire cfg_info_ena = cfg_info_vld && cfg_info_rdy && cfg_info_cmd[PEAY_CMD_DW-1];
wire dgen_cfg_info_ena;// cfg_info_ena && cfg_info_cmd[PEAY_CMD_DW-1];

CPM_REG #( 1 ) ARAM_IDX_SEL_REG ( clk, rst_n, cfg_info_ena, dgen_cfg_info_ena);
//FRAM_IO
wire  [PE_COL -1:0][ARAM_NUM_AW -1:0] fram_add_rid;
wire  [PE_COL -1:0]                   fram_add_vld;
wire  [PE_COL -1:0]                   fram_add_lst;
wire  [PE_COL -1:0]                   fram_add_rdy= FRAM_ADD_RDY;
wire  [PE_COL -1:0][FRAM_ADD_AW -1:0] fram_add_add;
wire  [PE_COL -1:0]                   fram_dat_vld= FRAM_DAT_VLD;
wire  [PE_COL -1:0]                   fram_dat_lst= FRAM_DAT_LST;
wire  [PE_COL -1:0]                   fram_dat_rdy;
wire  [PE_COL -1:0][FRAM_DAT_DW -1:0] fram_dat_dat= FRAM_DAT_DAT;

assign FRAM_ADD_VLD = fram_add_vld;
assign FRAM_ADD_LST = fram_add_lst;
assign FRAM_ADD_ADD = fram_add_add;
assign FRAM_ADD_RID = fram_add_rid;
assign FRAM_DAT_RDY = fram_dat_rdy;

//ARAM_IO
wire [PE_COL -1:0][ARAM_NUM_AW -1:0] aram_add_rid;
wire [PE_COL -1:0]                   aram_add_vld;
wire [PE_COL -1:0]                   aram_add_lst;
wire [PE_COL -1:0]                   aram_add_rdy= ARAM_ADD_RDY;
wire [PE_COL -1:0][ARAM_ADD_AW -1:0] aram_add_add;
wire [PE_COL -1:0]                   aram_dat_vld= ARAM_DAT_VLD;
wire [PE_COL -1:0]                   aram_dat_lst= ARAM_DAT_LST;
wire [PE_COL -1:0]                   aram_dat_rdy;
wire [PE_COL -1:0][ARAM_DAT_DW -1:0] aram_dat_dat= ARAM_DAT_DAT;

assign ARAM_ADD_VLD = aram_add_vld;
assign ARAM_ADD_LST = aram_add_lst;
assign ARAM_ADD_RID = aram_add_rid;
assign ARAM_ADD_ADD = aram_add_add;
assign ARAM_DAT_RDY = aram_dat_rdy;

//WRAM_IO
reg  [PE_ROW -1:0][PE_COL -1:0]                     wram_add_vld;
reg  [PE_ROW -1:0][PE_COL -1:0]                     wram_add_lst;
wire [PE_ROW -1:0][PE_COL -1:0]                     wram_add_rdy= WRAM_ADD_RDY;
reg  [PE_ROW -1:0][PE_COL -1:0][WRAM_ADD_AW   -1:0] wram_add_add;
reg  [PE_ROW -1:0][PE_COL -1:0][STAT_DAT_DW   -1:0] wram_add_buf;
wire [PE_ROW -1:0][PE_COL -1:0]                     wram_dat_vld= WRAM_DAT_VLD;
wire [PE_ROW -1:0][PE_COL -1:0]                     wram_dat_lst= WRAM_DAT_LST;
reg  [PE_ROW -1:0][PE_COL -1:0]                     wram_dat_rdy;
wire [PE_ROW -1:0][PE_COL -1:0][WRAM_DAT_DW   -1:0] wram_dat_dat= WRAM_DAT_DAT;

assign WRAM_ADD_VLD = wram_add_vld;
assign WRAM_ADD_LST = wram_add_lst;
assign WRAM_ADD_ADD = wram_add_add;
assign WRAM_ADD_BUF = wram_add_buf;
assign WRAM_DAT_RDY = wram_dat_vld;

//ORAM_IO
reg  [PE_COL -1:0][PE_ROW -1:0]                     oram_dat_vld;
reg  [PE_COL -1:0][PE_ROW -1:0]                     oram_dat_lst;
wire [PE_COL -1:0][PE_ROW -1:0]                     oram_dat_rdy= ORAM_DAT_RDY;
reg  [PE_COL -1:0][PE_ROW -1:0][OMUX_ADD_AW   -1:0] oram_dat_add;
reg  [PE_COL -1:0][PE_ROW -1:0][ORAM_DAT_DW   -1:0] oram_dat_dat;

assign ORAM_DAT_VLD = oram_dat_vld;
assign ORAM_DAT_LST = oram_dat_lst;
assign ORAM_DAT_ADD = oram_dat_add;
assign ORAM_DAT_DAT = oram_dat_dat;

//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================
wire pea_eng_idle;
wire [PE_COL -1:0] pea_gen_idle;
reg  [PE_ROW -1:0][PE_COL -1:0] pea_run_done;

//WRAM
wire [PE_COL -1:0][PE_ROW -1:0]                     gen_wram_add_vld;
wire [PE_COL -1:0][PE_ROW -1:0]                     gen_wram_add_lst;
reg  [PE_COL -1:0][PE_ROW -1:0]                     gen_wram_add_rdy;
wire [PE_COL -1:0][PE_ROW -1:0][WRAM_ADD_AW   -1:0] gen_wram_add_add;
wire [PE_COL -1:0][PE_ROW -1:0][STAT_DAT_DW   -1:0] gen_wram_add_buf;
reg  [PE_COL -1:0][PE_ROW -1:0]                     gen_wram_dat_vld;
reg  [PE_COL -1:0][PE_ROW -1:0]                     gen_wram_dat_lst;
wire [PE_COL -1:0][PE_ROW -1:0]                     gen_wram_dat_rdy;
reg  [PE_COL -1:0][PE_ROW -1:0][WRAM_DAT_DW   -1:0] gen_wram_dat_dat;

//DATA
wire [PE_COL -1:0]                               act_vld;
wire [PE_COL -1:0]                               act_lst;
wire [PE_COL -1:0]                               act_rdy;
wire [PE_COL -1:0]             [DATA_ACT_DW-1:0] act_dat;
wire [PE_COL -1:0]             [DATA_ACT_IW-1:0] act_inf;
                                           
wire [PE_COL -1:0][PE_ROW -1:0]                  wei_vld;
wire [PE_COL -1:0][PE_ROW -1:0]                  wei_lst;
wire [PE_COL -1:0][PE_ROW -1:0]                  wei_rdy;
wire [PE_COL -1:0][PE_ROW -1:0][DATA_WEI_DW-1:0] wei_dat;
wire [PE_COL -1:0][PE_ROW -1:0][DATA_WEI_IW-1:0] wei_inf;
                                           
wire [PE_ROW -1:0][PE_COL -1:0]                  out_vld;
wire [PE_ROW -1:0][PE_COL -1:0]                  out_lst;
wire [PE_ROW -1:0][PE_COL -1:0]                  out_rdy = oram_dat_rdy;
wire [PE_ROW -1:0][PE_COL -1:0][DATA_OUT_DW-1:0] out_dat;
wire [PE_ROW -1:0][PE_COL -1:0][OMUX_ADD_AW-1:0] out_add;
//=====================================================================================================================
// IO Logic Design :
//=====================================================================================================================
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_aram_add <= 'd0;
        cfg_wram_add <= 'd0;
        cfg_cpad_ena <= 'd0;
        cfg_conv_ich <= 'd0;
        cfg_conv_och <= 'd0;
        cfg_conv_len <= 'd0;
        cfg_conv_mul <= 'd0;
        cfg_conv_sft <= 'd0;
        cfg_conv_add <= 'd0;
        cfg_conv_wei <= 'd0;
        cfg_flag_vld <= 'd0;
        cfg_dila_fac <= 'd0;
        cfg_strd_fac <= 'd0;
        cfg_conv_run <= 'd0;
        cfg_conv_lst <= 'd0;
    end
    else if( cfg_info_ena )begin
        cfg_aram_add <= CFG_ARAM_ADD;
        cfg_wram_add <= CFG_WRAM_ADD;
        cfg_cpad_ena <= CFG_CPAD_ENA;
        cfg_conv_ich <= CFG_CONV_ICH;
        cfg_conv_och <= CFG_CONV_OCH;
        cfg_conv_len <= CFG_CONV_LEN;
        cfg_conv_mul <= CFG_CONV_MUL;
        cfg_conv_sft <= CFG_CONV_SFT;
        cfg_conv_add <= CFG_CONV_ADD;
        cfg_conv_wei <= CFG_CONV_WEI;
        cfg_flag_vld <= CFG_FLAG_VLD;
        cfg_dila_fac <= CFG_DILA_FAC;
        cfg_strd_fac <= CFG_STRD_FAC;
        cfg_conv_run <=|CFG_DILA_FAC ? 1<<CFG_DILA_FAC : 1<<CFG_STRD_FAC;
        cfg_conv_lst <=(CFG_CONV_LEN+'d1)*(CFG_CONV_OCH[CONV_OCH_DW -1:2]+'d1)-'d1;
    end
end

always @ ( * )begin
    cfg_info_rdy = &pea_gen_idle && pea_eng_idle;
end

always @ ( * )begin
    oram_dat_vld = out_vld;
    oram_dat_lst = out_lst;
    oram_dat_add = out_add;
    oram_dat_dat = out_dat;
end

//=====================================================================================================================
// Logic Design :
//=====================================================================================================================
always @ ( * )begin
    pea_info_done = cfg_info_ena;
    pea_load_done = 'd1;
    pea_conv_done = &pea_run_done;
end

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < PE_COL; gen_j = gen_j+1 )begin
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    pea_run_done[gen_i][gen_j] <= 'd1;
                else if( pea_idle )
                    pea_run_done[gen_i][gen_j] <= 'd0;
                else if( oram_dat_vld[gen_i][gen_j] && oram_dat_rdy[gen_i][gen_j] && oram_dat_lst[gen_i][gen_j] )begin
                    pea_run_done[gen_i][gen_j] <= 'd1;
                end
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < PE_COL; gen_j = gen_j+1 )begin
            always @ ( * )begin
                wram_add_vld[gen_i][gen_j] = gen_wram_add_vld[gen_j][gen_i];
                wram_add_lst[gen_i][gen_j] = gen_wram_add_lst[gen_j][gen_i];
                wram_add_add[gen_i][gen_j] = gen_wram_add_add[gen_j][gen_i];
                wram_add_buf[gen_i][gen_j] = gen_wram_add_buf[gen_j][gen_i];
                wram_dat_rdy[gen_i][gen_j] = gen_wram_dat_rdy[gen_j][gen_i];
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < PE_COL; gen_j = gen_j+1 )begin
            always @ ( * )begin
                gen_wram_add_rdy[gen_i][gen_j] = wram_add_rdy[gen_j][gen_i];
                gen_wram_dat_vld[gen_i][gen_j] = wram_dat_vld[gen_j][gen_i];
                gen_wram_dat_lst[gen_i][gen_j] = wram_dat_lst[gen_j][gen_i];
                gen_wram_dat_dat[gen_i][gen_j] = wram_dat_dat[gen_j][gen_i];
            end
        end
    end
endgenerate
//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================
wire [PE_COL -1:0][2 -1:0] pea_gen_cidx = {2'd3, 2'd2, 2'd1, 2'd0};
wire [PE_COL -1:0] pea_gen_lpad = 4'b1110;
wire [PE_COL -1:0] pea_gen_rpad = 4'b0111;

EEG_PEA_DAT_GEN #(
    .PE_COL          ( PE_COL         ),
    .PE_ROW          ( PE_ROW         ),
    .DATA_ACT_DW     ( DATA_ACT_DW    ),
    .DATA_WEI_DW     ( DATA_WEI_DW    ),
    .DATA_ACT_IW     ( DATA_ACT_IW    ),
    .DATA_WEI_IW     ( DATA_WEI_IW    ),
    .CONV_ICH_DW     ( CONV_ICH_DW    ),
    .CONV_OCH_DW     ( CONV_OCH_DW    ),
    .CONV_LEN_DW     ( CONV_LEN_DW    ),
    .CONV_WEI_DW     ( CONV_WEI_DW    ),
    .CONV_RUN_DW     ( CONV_RUN_DW    ),
    .DILA_FAC_DW     ( DILA_FAC_DW    ),
    .STRD_FAC_DW     ( STRD_FAC_DW    ),
    .ARAM_NUM_AW     ( ARAM_NUM_AW    ),
    .ARAM_ADD_AW     ( ARAM_ADD_AW    ),
    .WRAM_ADD_AW     ( WRAM_ADD_AW    ),
    .FRAM_ADD_AW     ( FRAM_ADD_AW    ),
    .ARAM_DAT_DW     ( ARAM_DAT_DW    ),
    .WRAM_DAT_DW     ( WRAM_DAT_DW    ),
    .FRAM_DAT_DW     ( FRAM_DAT_DW    )
) EEG_PEA_DAT_GEN_U[PE_COL -1:0] (
    
    .clk             ( clk               ),
    .rst_n           ( rst_n             ),

    .IS_IDLE         ( pea_gen_idle      ),

    .PEA_GEN_CIDX    ( pea_gen_cidx      ),
    .PEA_GEN_LPAD    ( pea_gen_lpad      ),
    .PEA_GEN_RPAD    ( pea_gen_rpad      ),

    .CFG_INFO_VLD    ( dgen_cfg_info_ena ),
    .CFG_INFO_RDY    (    ),
    .CFG_ARAM_ADD    ( cfg_aram_add      ),
    .CFG_WRAM_ADD    ( cfg_wram_add      ),
    .CFG_CPAD_ENA    ( cfg_cpad_ena      ),
    .CFG_CONV_ICH    ( cfg_conv_ich      ),
    .CFG_CONV_OCH    ( cfg_conv_och      ),
    .CFG_CONV_LEN    ( cfg_conv_len      ),
    .CFG_CONV_WEI    ( cfg_conv_wei      ),
    .CFG_FLAG_VLD    ( cfg_flag_vld      ),
    .CFG_DILA_FAC    ( cfg_dila_fac      ),
    .CFG_STRD_FAC    ( cfg_strd_fac      ),

    .FRAM_ADD_RID    ( fram_add_rid      ),
    .FRAM_ADD_VLD    ( fram_add_vld      ),
    .FRAM_ADD_LST    ( fram_add_lst      ),
    .FRAM_ADD_RDY    ( fram_add_rdy      ),
    .FRAM_ADD_ADD    ( fram_add_add      ),
    .FRAM_DAT_VLD    ( fram_dat_vld      ),
    .FRAM_DAT_LST    ( fram_dat_lst      ),
    .FRAM_DAT_RDY    ( fram_dat_rdy      ),
    .FRAM_DAT_DAT    ( fram_dat_dat      ),

    .ARAM_ADD_RID    ( aram_add_rid      ),
    .ARAM_ADD_VLD    ( aram_add_vld      ),
    .ARAM_ADD_LST    ( aram_add_lst      ),
    .ARAM_ADD_RDY    ( aram_add_rdy      ),
    .ARAM_ADD_ADD    ( aram_add_add      ),
    .ARAM_DAT_VLD    ( aram_dat_vld      ),
    .ARAM_DAT_LST    ( aram_dat_lst      ),
    .ARAM_DAT_RDY    ( aram_dat_rdy      ),
    .ARAM_DAT_DAT    ( aram_dat_dat      ),

    .WRAM_ADD_VLD    ( gen_wram_add_vld  ),//transposition
    .WRAM_ADD_LST    ( gen_wram_add_lst  ),
    .WRAM_ADD_RDY    ( gen_wram_add_rdy  ),
    .WRAM_ADD_ADD    ( gen_wram_add_add  ),
    .WRAM_ADD_BUF    ( gen_wram_add_buf  ),
    .WRAM_DAT_VLD    ( gen_wram_dat_vld  ),
    .WRAM_DAT_LST    ( gen_wram_dat_lst  ),
    .WRAM_DAT_RDY    ( gen_wram_dat_rdy  ),
    .WRAM_DAT_DAT    ( gen_wram_dat_dat  ),

    .ACT_VLD         ( act_vld           ),
    .ACT_LST         ( act_lst           ),
    .ACT_RDY         ( act_rdy           ),
    .ACT_DAT         ( act_dat           ),
    .ACT_INF         ( act_inf           ),

    .WEI_VLD         ( wei_vld           ),
    .WEI_LST         ( wei_lst           ),
    .WEI_RDY         ( wei_rdy           ),
    .WEI_DAT         ( wei_dat           ),
    .WEI_INF         ( wei_inf           )
);

EEG_PEA_ENG #(
    .PE_COL          ( PE_COL         ),
    .PE_ROW          ( PE_ROW         ),
    .DATA_ACT_DW     ( DATA_ACT_DW    ),
    .DATA_WEI_DW     ( DATA_WEI_DW    ),
    .DATA_OUT_DW     ( DATA_OUT_DW    ),
    .ARAM_ADD_AW     ( ARAM_ADD_AW    ),
    .ORAM_ADD_AW     ( ORAM_ADD_AW    ),
    .OMUX_ADD_AW     ( OMUX_ADD_AW    ),
    .CONV_WEI_DW     ( CONV_WEI_DW    ),
    .CONV_RUN_DW     ( CONV_RUN_DW    ),
    .CONV_MUL_DW     ( CONV_MUL_DW    ),
    .CONV_SFT_DW     ( CONV_SFT_DW    ),
    .CONV_ADD_DW     ( CONV_ADD_DW    )
) EEG_PEA_ENG_U (
    .clk             ( clk            ),
    .rst_n           ( rst_n          ),

    .IS_IDLE         ( pea_eng_idle   ),

    .CFG_CONV_RUN    ( cfg_conv_run   ),
    .CFG_CONV_WEI    ( cfg_conv_wei   ),
    .CFG_CONV_PAD    ( cfg_conv_pad   ),
    .CFG_CONV_MUL    ( cfg_conv_mul   ),
    .CFG_CONV_SFT    ( cfg_conv_sft   ),
    .CFG_CONV_ADD    ( cfg_conv_add   ),
    .CFG_CONV_LST    ( cfg_conv_lst   ),

    .ACT_VLD         ( act_vld        ),
    .ACT_LST         ( act_lst        ),
    .ACT_RDY         ( act_rdy        ),
    .ACT_DAT         ( act_dat        ),
    .ACT_INF         ( act_inf        ),
                                      
    .WEI_VLD         ( wei_vld        ),
    .WEI_LST         ( wei_lst        ),
    .WEI_RDY         ( wei_rdy        ),
    .WEI_DAT         ( wei_dat        ),
    .WEI_INF         ( wei_inf        ),
                                      
    .OUT_VLD         ( out_vld        ),
    .OUT_LST         ( out_lst        ),
    .OUT_ADD         ( out_add        ),
    .OUT_RDY         ( out_rdy        ),
    .OUT_DAT         ( out_dat        )
);

//=====================================================================================================================
// FSM :
//=====================================================================================================================
always @ ( * )begin
  case( pea_cs )
    PEA_IDLE: pea_ns = pea_info_done ? PEA_LOAD : pea_cs;
    PEA_LOAD: pea_ns = cfg_info_cmd;
    PEA_CONV: pea_ns = pea_conv_done ? PEA_IDLE : pea_cs;
    default : pea_ns = PEA_IDLE;
  endcase
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        pea_cs <= PEA_IDLE;
    else
        pea_cs <= pea_ns;
end

`ifdef ASSERT_ON


`endif
endmodule
