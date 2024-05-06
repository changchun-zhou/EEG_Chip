//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description : ORAM
//                      Pixel first for ORAM ¡Ì
//========================================================
module EEG_ORAM #(
    parameter ORAM_CMD_DW =  9,
    parameter ORAM_NUM_DW =  4,
    parameter OMUX_NUM_DW =  4,
    parameter ORAM_ADD_AW = 10,
    parameter OMUX_ADD_AW =  8,
    parameter ORAM_DAT_DW =  8,
    parameter ARAM_DAT_DW =  8,
    parameter POOL_FAC_DW =  2,
    parameter CONV_LEN_DW = 10,
    parameter POOL_LEN_DW = ORAM_ADD_AW,
    parameter ORAM_NUM_AW = $clog2(ORAM_NUM_DW)
  )(
    input                                                         clk,
    input                                                         rst_n,

    output                                                        IS_IDLE,

    input                                                         CFG_INFO_VLD,
    output                                                        CFG_INFO_RDY,
    input  [ORAM_CMD_DW                                     -1:0] CFG_INFO_CMD,
    input  [OMUX_NUM_DW                                     -1:0] CFG_OMUX_IDX,//FOR POOL_OMUX
    input  [CONV_LEN_DW                                     -1:0] CFG_CONV_LEN,
    input  [POOL_LEN_DW                                     -1:0] CFG_POOL_LEN,
    input  [POOL_FAC_DW                                     -1:0] CFG_POOL_FAC,
    input                                                         CFG_RELU_ENA,
    input                                                         CFG_SPLT_ENA,
    input                                                         CFG_COMB_ENA,
    input                                                         CFG_MAXP_ENA,
    input                                                         CFG_AVGP_ENA,
    
    input  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   ETOO_DAT_VLD,
    input  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   ETOO_DAT_LST,
    output [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   ETOO_DAT_RDY,
    input  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][OMUX_ADD_AW -1:0] ETOO_DAT_ADD,
    input  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_DAT_DW -1:0] ETOO_DAT_DAT,
    
    input  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   ETOO_ADD_VLD,
    input  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   ETOO_ADD_LST,
    output [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   ETOO_ADD_RDY,
    input  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][OMUX_ADD_AW -1:0] ETOO_ADD_ADD,
    output [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   OTOE_DAT_VLD,
    output [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   OTOE_DAT_LST,
    input  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   OTOE_DAT_RDY,
    output [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_DAT_DW -1:0] OTOE_DAT_DAT
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
localparam OMUX_ADD_DW = 1<<OMUX_ADD_AW;
localparam ORAM_BUF_DW = OMUX_ADD_AW+ORAM_DAT_DW+1;
localparam ORAM_BUF_AW = 2;
localparam POOL_WEI_DW = 3;
localparam POOL_DAT_DW = ORAM_DAT_DW+POOL_WEI_DW;

localparam ORAM_STATE = ORAM_CMD_DW;
localparam ORAM_IDLE  = 9'b00000001;
localparam ORAM_ZERO  = 9'b00000010;
localparam ORAM_CONV  = 9'b00000100;
localparam ORAM_RESN  = 9'b00001000;
localparam ORAM_POOL  = 9'b00010000;
localparam ORAM_OTOA  = 9'b00100000;
localparam ORAM_STAT  = 9'b01000000;
localparam ORAM_READ  = 9'b10000000;

reg [ORAM_STATE -1:0] oram_cs;
reg [ORAM_STATE -1:0] oram_ns;

wire oram_idle = oram_cs == ORAM_IDLE;
wire oram_zero = oram_cs == ORAM_ZERO;//W
wire oram_conv = oram_cs == ORAM_CONV;//W
wire oram_resn = oram_cs == ORAM_RESN;//RW
wire oram_pool = oram_cs == ORAM_POOL;//RW
wire oram_otoa = oram_cs == ORAM_OTOA;//R
wire oram_stat = oram_cs == ORAM_STAT;//R
wire oram_read = oram_cs == ORAM_READ;//R
wire oram_ptoo = oram_conv || oram_resn;
assign IS_IDLE = oram_idle;
reg [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0] zero_lst_done;
reg [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0] conv_lst_done;
reg [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0] resn_lst_done;
reg [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0] pool_lst_done, pool_add_done;
reg [ORAM_NUM_DW -1:0]                   otoa_lst_done;
reg                                      read_lst_done;

wire oram_zero_done = &zero_lst_done;
wire oram_conv_done = &conv_lst_done;
wire oram_resn_done = &resn_lst_done;
wire oram_pool_done = &pool_lst_done;
wire oram_otoa_done = &otoa_lst_done;
wire oram_stat_done = &otoa_lst_done;//same with otoa
wire oram_read_done =  read_lst_done;
integer i;
//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
//CFG_IO
wire cfg_info_vld = CFG_INFO_VLD;
wire cfg_info_rdy = oram_idle;

assign CFG_INFO_RDY = cfg_info_rdy;

wire cfg_info_ena = cfg_info_vld & cfg_info_rdy;
reg  [ORAM_CMD_DW  -1:0] cfg_info_cmd;
reg  [OMUX_NUM_DW  -1:0] cfg_omux_idx;
reg  [CONV_LEN_DW  -1:0] cfg_conv_len;
reg  [POOL_LEN_DW  -1:0] cfg_pool_len;
reg  [POOL_FAC_DW  -1:0] cfg_pool_fac;
reg  [POOL_WEI_DW  -1:0] cfg_pool_wei;
reg                      cfg_relu_ena;
reg                      cfg_splt_ena;
reg                      cfg_comb_ena;
reg                      cfg_maxp_ena;
reg                      cfg_avgp_ena;

//ORAM_DIN
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   etoo_dat_vld = ETOO_DAT_VLD;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   etoo_dat_lst = ETOO_DAT_LST;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   etoo_dat_rdy;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][OMUX_ADD_AW -1:0] etoo_dat_add = ETOO_DAT_ADD;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_DAT_DW -1:0] etoo_dat_dat = ETOO_DAT_DAT;
assign ETOO_DAT_RDY = etoo_dat_rdy;

wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0] etoo_dat_ena = etoo_dat_vld & etoo_dat_rdy;

//ORAM_OUT
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   etoo_add_vld = ETOO_ADD_VLD;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   etoo_add_lst = ETOO_ADD_LST;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   etoo_add_rdy;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][OMUX_ADD_AW -1:0] etoo_add_add = ETOO_ADD_ADD;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   otoe_dat_vld;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   otoe_dat_lst;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   otoe_dat_rdy = OTOE_DAT_RDY;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_DAT_DW -1:0] otoe_dat_dat;

assign ETOO_ADD_RDY = etoo_add_rdy;
assign OTOE_DAT_VLD = otoe_dat_vld;
assign OTOE_DAT_LST = otoe_dat_lst;
assign OTOE_DAT_DAT = otoe_dat_dat;

reg [ORAM_NUM_DW -1:0] etoo_add_ena;
reg [ORAM_NUM_DW -1:0] otoe_dat_ena;
//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================
//ETOO_DAT_FIFO
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0] etoo_buf_wen;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0] etoo_buf_ren;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0] etoo_buf_empty;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0] etoo_buf_full;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_BUF_DW -1:0] etoo_buf_din;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_BUF_DW -1:0] etoo_buf_out;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   etoo_buf_lst;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][OMUX_ADD_AW -1:0] etoo_buf_add;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_DAT_DW -1:0] etoo_buf_dat;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_BUF_AW   :0] etoo_buf_cnt;

//RES
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   oram_res_vld;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_DAT_DW -1:0] oram_res_dat;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][OMUX_ADD_AW -1:0] oram_res_add;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   oram_res_lst;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_DAT_DW   :0] oram_res_dat_add;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_DAT_DW -1:0] oram_res_dat_clp;
CPM_CLP #( ORAM_DAT_DW+1, ORAM_DAT_DW ) ORAM_RES_DAT_CLP_U[ORAM_NUM_DW*OMUX_NUM_DW -1:0] ( oram_res_dat_add, oram_res_dat_clp );

reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][OMUX_ADD_AW -1:0] oram_din_cnt;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][OMUX_ADD_AW -1:0] oram_add_cnt;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][OMUX_ADD_AW -1:0] oram_dat_cnt;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][OMUX_ADD_AW -1:0] oram_avg_cnt;

reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0] oram_din_cnt_last;

//RAM
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   ram_oram_din_vld;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   ram_oram_din_rdy;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][OMUX_ADD_AW -1:0] ram_oram_din_add;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_DAT_DW -1:0] ram_oram_din_dat;

reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   ram_oram_add_vld;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   ram_oram_add_lst;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   ram_oram_add_rdy;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][OMUX_ADD_AW -1:0] ram_oram_add_add;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   ram_oram_dat_vld;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   ram_oram_dat_lst;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   ram_oram_dat_rdy;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_DAT_DW -1:0] ram_oram_dat_dat;

wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   ram_oram_din_ena = ram_oram_din_vld & ram_oram_din_rdy;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   ram_oram_add_ena = ram_oram_add_vld & ram_oram_add_rdy;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   ram_oram_dat_ena = ram_oram_dat_vld & ram_oram_dat_rdy;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][POOL_DAT_DW -1:0] pool_dat_reg;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][POOL_DAT_DW -1:0] pool_dat_add;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][POOL_DAT_DW -1:0] pool_dat_sft;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_DAT_DW -1:0] pool_dat_avg;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_DAT_DW -1:0] pool_dat_max;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_DAT_DW -1:0] pool_dat_dat;
CPM_CLP #( POOL_DAT_DW, ORAM_DAT_DW ) POOL_DAT_CLP_U[ORAM_NUM_DW*OMUX_NUM_DW -1:0] ( pool_dat_sft, pool_dat_avg );

CPM_FIFO #( .DATA_WIDTH( ORAM_BUF_DW ), .ADDR_WIDTH( ORAM_BUF_AW ) ) ORAM_FIFO_U[ORAM_NUM_DW*OMUX_NUM_DW -1:0] ( clk, rst_n, 1'd0, etoo_buf_wen, etoo_buf_ren, etoo_buf_din, etoo_buf_out, etoo_buf_empty, etoo_buf_full, etoo_buf_cnt);
//=====================================================================================================================
// IO Logic Design :
//=====================================================================================================================
genvar gen_i, gen_j;           
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_info_cmd <= 'd0;
        cfg_omux_idx <= 'd0;
        cfg_conv_len <= 'd0;
        cfg_pool_len <= 'd0;
        cfg_pool_fac <= 'd0;
        cfg_pool_wei <= 'd0;
        cfg_relu_ena <= 'd0;
        cfg_splt_ena <= 'd0;
        cfg_comb_ena <= 'd0;
        cfg_maxp_ena <= 'd0;
        cfg_avgp_ena <= 'd0;
    end else if( cfg_info_ena )begin
        cfg_info_cmd <= CFG_INFO_CMD;
        cfg_omux_idx <= CFG_OMUX_IDX;
        cfg_conv_len <= CFG_CONV_LEN;
        cfg_pool_len <= CFG_POOL_LEN;
        cfg_pool_fac <= CFG_POOL_FAC;
        cfg_pool_wei <= (1<<CFG_POOL_FAC) -'d1;
        cfg_relu_ena <= CFG_RELU_ENA;
        cfg_splt_ena <= CFG_SPLT_ENA;
        cfg_comb_ena <= CFG_COMB_ENA;
        cfg_maxp_ena <= CFG_MAXP_ENA;
        cfg_avgp_ena <= CFG_AVGP_ENA;
    end
end

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                etoo_add_rdy[gen_i][gen_j] = ram_oram_add_rdy[gen_i][gen_j];
                etoo_dat_rdy[gen_i][gen_j] =~etoo_buf_full[gen_i][gen_j];
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 )begin
            always @ ( * )begin
              otoe_dat_vld[gen_i][gen_j] = ram_oram_dat_vld[gen_i][gen_j];
              otoe_dat_lst[gen_i][gen_j] = ram_oram_dat_lst[gen_i][gen_j];
              otoe_dat_dat[gen_i][gen_j] = ram_oram_dat_dat[gen_i][gen_j];
            end
        end
    end
endgenerate
//=====================================================================================================================
// Logic Design :
//=====================================================================================================================
//done
generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 )begin
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    zero_lst_done[gen_i][gen_j] <= 'd1;
                else if( cfg_info_ena )
                    zero_lst_done[gen_i][gen_j] <= ~(CFG_INFO_CMD==ORAM_ZERO);
                else if( ram_oram_din_ena[gen_i][gen_j] && &oram_din_cnt[gen_i][gen_j] )
                    zero_lst_done[gen_i][gen_j] <= 'd1;
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 )begin
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    conv_lst_done[gen_i][gen_j] <= 'd1;
                else if( cfg_info_ena )
                    conv_lst_done[gen_i][gen_j] <= ~(CFG_INFO_CMD==ORAM_CONV);
                else if( etoo_buf_ren[gen_i][gen_j] && etoo_buf_lst[gen_i][gen_j] )
                    conv_lst_done[gen_i][gen_j] <= 'd1;
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 )begin
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    resn_lst_done[gen_i][gen_j] <= 'd1;
                else if( cfg_info_ena )
                    resn_lst_done[gen_i][gen_j] <= ~(CFG_INFO_CMD==ORAM_RESN);
                else if( oram_res_vld[gen_i][gen_j] && oram_res_lst[gen_i][gen_j] )
                    resn_lst_done[gen_i][gen_j] <= 'd1;
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 )begin
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    pool_add_done[gen_i][gen_j] <= 'd1;
                else if( cfg_info_ena )
                    pool_add_done[gen_i][gen_j] <= ~(CFG_INFO_CMD==ORAM_POOL);
                else if( ram_oram_add_ena[gen_i][gen_j] && ram_oram_add_lst[gen_i][gen_j] )
                    pool_add_done[gen_i][gen_j] <= 'd1;
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 )begin
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    pool_lst_done[gen_i][gen_j] <= 'd1;
                else if( cfg_info_ena )
                    pool_lst_done[gen_i][gen_j] <= ~(CFG_INFO_CMD==ORAM_POOL);
                else if( ram_oram_din_ena[gen_i][gen_j] && etoo_buf_lst[gen_i][gen_j] )
                    pool_lst_done[gen_i][gen_j] <= 'd1;
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                otoa_lst_done[gen_i] <= 'd0;
            else if( cfg_info_ena )
                otoa_lst_done[gen_i] <= 'd0;
            else if( otoe_dat_ena[gen_i] && otoe_dat_lst[gen_i] )
                otoa_lst_done[gen_i] <= 'd1;
        end
    end
endgenerate

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        read_lst_done <= 'd0;
    else if( cfg_info_ena )
        read_lst_done <= 'd0;
    else if( |(otoe_dat_ena & otoe_dat_lst) )
        read_lst_done <= 'd1;
end

//buf
generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                case( oram_cs )
                    ORAM_CONV: etoo_buf_wen[gen_i][gen_j] = etoo_dat_vld[gen_i][gen_j] && etoo_dat_rdy[gen_i][gen_j];
                    ORAM_RESN: etoo_buf_wen[gen_i][gen_j] = etoo_dat_vld[gen_i][gen_j] && etoo_dat_rdy[gen_i][gen_j];
                    ORAM_POOL: etoo_buf_wen[gen_i][gen_j] = ram_oram_dat_ena[gen_i][gen_j] && oram_avg_cnt[gen_i][gen_j]==cfg_pool_wei;
                    default  : etoo_buf_wen[gen_i][gen_j] = 'd0;
                endcase
            end
            
            always @ ( * )begin
                case( oram_cs )
                    ORAM_CONV: etoo_buf_din[gen_i][gen_j] = {etoo_dat_lst[gen_i][gen_j], etoo_dat_add[gen_i][gen_j], etoo_dat_dat[gen_i][gen_j]};
                    ORAM_RESN: etoo_buf_din[gen_i][gen_j] = {etoo_dat_lst[gen_i][gen_j], etoo_dat_add[gen_i][gen_j], etoo_dat_dat[gen_i][gen_j]};
                    ORAM_POOL: etoo_buf_din[gen_i][gen_j] = {ram_oram_dat_lst[gen_i][gen_j], oram_din_cnt[gen_i][gen_j], pool_dat_dat[gen_i][gen_j]};
                    default  : etoo_buf_din[gen_i][gen_j] = 'd0;
                endcase
            end
            
            always @ ( * )begin
                case( oram_cs )
                    ORAM_CONV: etoo_buf_ren[gen_i][gen_j] = ram_oram_din_vld[gen_i][gen_j] && ram_oram_din_rdy[gen_i][gen_j];
                    ORAM_RESN: etoo_buf_ren[gen_i][gen_j] = ram_oram_dat_vld[gen_i][gen_j] && ram_oram_dat_rdy[gen_i][gen_j];
                    ORAM_POOL: etoo_buf_ren[gen_i][gen_j] = ram_oram_din_vld[gen_i][gen_j] && ram_oram_din_rdy[gen_i][gen_j];
                    default  : etoo_buf_ren[gen_i][gen_j] = 'd0;
                endcase
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                etoo_buf_lst[gen_i][gen_j] = etoo_buf_out[gen_i][gen_j][ORAM_DAT_DW + OMUX_ADD_AW];
                etoo_buf_add[gen_i][gen_j] = etoo_buf_out[gen_i][gen_j][ORAM_DAT_DW +:OMUX_ADD_AW];
                etoo_buf_dat[gen_i][gen_j] = etoo_buf_out[gen_i][gen_j][0 +:ORAM_DAT_DW];
            end
        end
    end
endgenerate

//res
generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                oram_res_dat_add[gen_i][gen_j] = $signed(ram_oram_dat_dat[gen_i][gen_j]) +$signed(etoo_buf_dat[gen_i][gen_j]);
            end
          
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    oram_res_dat[gen_i][gen_j] <= 'd0;
                else if( ram_oram_dat_ena[gen_i][gen_j] )
                    oram_res_dat[gen_i][gen_j] <= oram_res_dat_clp[gen_i][gen_j];
            end

            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    oram_res_add[gen_i][gen_j] <= 'd0;
                else if( ram_oram_dat_ena[gen_i][gen_j] )
                    oram_res_add[gen_i][gen_j] <= etoo_buf_add[gen_i][gen_j];
            end

            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    oram_res_lst[gen_i][gen_j] <= 'd0;
                else if( ram_oram_dat_ena[gen_i][gen_j] )
                    oram_res_lst[gen_i][gen_j] <= etoo_buf_lst[gen_i][gen_j];
            end

            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    oram_res_vld[gen_i][gen_j] <= 'd0;
                else if( ram_oram_dat_ena[gen_i][gen_j] )
                    oram_res_vld[gen_i][gen_j] <= 'd1;
                else if( ram_oram_din_ena[gen_i][gen_j] )
                    oram_res_vld[gen_i][gen_j] <= 'd0;
            end            
        end
    end
endgenerate

//oram
generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 ) begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 ) begin
            always @ ( * )begin
                case( oram_cs )
                    ORAM_ZERO: ram_oram_din_vld[gen_i][gen_j] = 'd1;
                    ORAM_CONV: ram_oram_din_vld[gen_i][gen_j] =~etoo_buf_empty[gen_i][gen_j];
                    ORAM_RESN: ram_oram_din_vld[gen_i][gen_j] = oram_res_vld[gen_i][gen_j];
                    ORAM_POOL: ram_oram_din_vld[gen_i][gen_j] =~etoo_buf_empty[gen_i][gen_j];
                    default  : ram_oram_din_vld[gen_i][gen_j] = 'd0;
                endcase
            end
            
            always @ ( * )begin
                case( oram_cs )
                    ORAM_ZERO: ram_oram_din_add[gen_i][gen_j] = oram_din_cnt[gen_i][gen_j];
                    ORAM_CONV: ram_oram_din_add[gen_i][gen_j] = etoo_buf_add[gen_i][gen_j];
                    ORAM_RESN: ram_oram_din_add[gen_i][gen_j] = oram_res_add[gen_i][gen_j];
                    ORAM_POOL: ram_oram_din_add[gen_i][gen_j] = etoo_buf_add[gen_i][gen_j];
                    default  : ram_oram_din_add[gen_i][gen_j] = 'd0;
                endcase
            end

            always @ ( * )begin
                case( oram_cs )
                    ORAM_CONV: ram_oram_din_dat[gen_i][gen_j] = cfg_relu_ena && etoo_buf_dat[gen_i][gen_j][ORAM_DAT_DW -1] ? 'd0 : etoo_buf_dat[gen_i][gen_j];
                    ORAM_RESN: ram_oram_din_dat[gen_i][gen_j] = cfg_relu_ena && oram_res_dat[gen_i][gen_j][ORAM_DAT_DW -1] ? 'd0 : oram_res_dat[gen_i][gen_j];
                    ORAM_POOL: ram_oram_din_dat[gen_i][gen_j] = cfg_relu_ena && etoo_buf_dat[gen_i][gen_j][ORAM_DAT_DW -1] ? 'd0 : etoo_buf_dat[gen_i][gen_j];
                    default  : ram_oram_din_dat[gen_i][gen_j] = 'd0;//ORAM_ZERO
                endcase
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                case( oram_cs )
                    ORAM_RESN: ram_oram_add_vld[gen_i][gen_j] =~etoo_buf_empty[gen_i][gen_j] && ~ram_oram_dat_vld[gen_i][gen_j];
                    ORAM_POOL: ram_oram_add_vld[gen_i][gen_j] = etoo_buf_empty[gen_i][gen_j] && ~etoo_buf_full[gen_i][gen_j] && ~pool_add_done[gen_i][gen_j];
                    ORAM_OTOA: ram_oram_add_vld[gen_i][gen_j] = etoo_add_vld[gen_i][gen_j];
                    ORAM_STAT: ram_oram_add_vld[gen_i][gen_j] = etoo_add_vld[gen_i][gen_j];
                    ORAM_READ: ram_oram_add_vld[gen_i][gen_j] = etoo_add_vld[gen_i][gen_j];
                    default  : ram_oram_add_vld[gen_i][gen_j] = 'd0;
                endcase
            end

            always @ ( * )begin
                case( oram_cs )
                    ORAM_RESN: ram_oram_add_lst[gen_i][gen_j] = etoo_buf_lst[gen_i][gen_j];
                    ORAM_POOL: ram_oram_add_lst[gen_i][gen_j] = oram_add_cnt[gen_i][gen_j]==cfg_pool_len;
                    ORAM_OTOA: ram_oram_add_lst[gen_i][gen_j] = etoo_add_lst[gen_i][gen_j];
                    ORAM_STAT: ram_oram_add_lst[gen_i][gen_j] = etoo_add_lst[gen_i][gen_j];
                    ORAM_READ: ram_oram_add_lst[gen_i][gen_j] = etoo_add_lst[gen_i][gen_j];
                    default  : ram_oram_add_lst[gen_i][gen_j] = 'd0;
                endcase
            end
            
            always @ ( * )begin
                case( oram_cs )
                    ORAM_RESN: ram_oram_add_add[gen_i][gen_j] = etoo_buf_add[gen_i][gen_j];
                    ORAM_POOL: ram_oram_add_add[gen_i][gen_j] = oram_add_cnt[gen_i][gen_j];
                    ORAM_OTOA: ram_oram_add_add[gen_i][gen_j] = etoo_add_add[gen_i][gen_j];
                    ORAM_STAT: ram_oram_add_add[gen_i][gen_j] = etoo_add_add[gen_i][gen_j];
                    ORAM_READ: ram_oram_add_add[gen_i][gen_j] = etoo_add_add[gen_i][gen_j];
                    default  : ram_oram_add_add[gen_i][gen_j] = 'd0;
                endcase
            end
            
            always @ ( * )begin
                case( oram_cs )
                    ORAM_RESN: ram_oram_dat_rdy[gen_i][gen_j] = 'd1;
                    ORAM_POOL: ram_oram_dat_rdy[gen_i][gen_j] =~etoo_buf_full[gen_i][gen_j];
                    ORAM_OTOA: ram_oram_dat_rdy[gen_i][gen_j] = otoe_dat_rdy[gen_i][gen_j];
                    ORAM_STAT: ram_oram_dat_rdy[gen_i][gen_j] = otoe_dat_rdy[gen_i][gen_j];
                    ORAM_READ: ram_oram_dat_rdy[gen_i][gen_j] = otoe_dat_rdy[gen_i][gen_j];
                    default  : ram_oram_dat_rdy[gen_i][gen_j] = 'd0;
                endcase
            end
        end
    end
endgenerate

//cnt
generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                oram_din_cnt_last[gen_i][gen_j] <= oram_zero && &oram_din_cnt[gen_i][gen_j];
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 )begin
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    oram_din_cnt[gen_i][gen_j] <= 'd0;
                else if( cfg_info_ena )
                    oram_din_cnt[gen_i][gen_j] <= 'd0;
                else if( ram_oram_din_ena[gen_i][gen_j] && (oram_zero || oram_pool) )
                    oram_din_cnt[gen_i][gen_j] <= oram_din_cnt[gen_i][gen_j] +'d1;
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 )begin
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    oram_add_cnt[gen_i][gen_j] <= 'd0;
                else if( cfg_info_ena )
                    oram_add_cnt[gen_i][gen_j] <= 'd0;
                else if( ram_oram_add_ena[gen_i][gen_j] && oram_pool )
                    oram_add_cnt[gen_i][gen_j] <= oram_add_cnt[gen_i][gen_j] +'d1;
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 )begin
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    oram_dat_cnt[gen_i][gen_j] <= 'd0;
                else if( cfg_info_ena )
                    oram_dat_cnt[gen_i][gen_j] <= 'd0;
                else if( ram_oram_dat_ena[gen_i][gen_j] && oram_pool )
                    oram_dat_cnt[gen_i][gen_j] <= oram_dat_cnt[gen_i][gen_j] +'d1;
            end
        end
    end
endgenerate

//pool
generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 )begin
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    oram_avg_cnt[gen_i][gen_j] <= 'd0;
                else if( cfg_info_ena )
                    oram_avg_cnt[gen_i][gen_j] <= 'd0;
                else if( ram_oram_dat_ena[gen_i][gen_j] && oram_pool )begin
                    if( oram_avg_cnt[gen_i][gen_j]==cfg_pool_wei )
                        oram_avg_cnt[gen_i][gen_j] <= 'd0;
                    else
                        oram_avg_cnt[gen_i][gen_j] <= oram_avg_cnt[gen_i][gen_j] +'d1;
                end
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                pool_dat_add[gen_i][gen_j] = $signed(ram_oram_dat_dat[gen_i][gen_j]) + $signed(pool_dat_reg[gen_i][gen_j]);
                pool_dat_sft[gen_i][gen_j] = $signed(pool_dat_add[gen_i][gen_j])>>>cfg_pool_fac;
                pool_dat_max[gen_i][gen_j] = $signed(ram_oram_dat_dat[gen_i][gen_j]) > $signed(pool_dat_reg[gen_i][gen_j]) ? ram_oram_dat_dat[gen_i][gen_j] : pool_dat_reg[gen_i][gen_j];
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                pool_dat_dat[gen_i][gen_j] = cfg_avgp_ena ? pool_dat_avg[gen_i][gen_j] : pool_dat_max[gen_i][gen_j];
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 )begin
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    pool_dat_reg[gen_i][gen_j] <= 'd0;
                else if( cfg_info_ena )
                    pool_dat_reg[gen_i][gen_j] <= 'd0;
                else if( ram_oram_dat_ena[gen_i][gen_j] && oram_pool )begin
                    if( cfg_avgp_ena )
                        pool_dat_reg[gen_i][gen_j] <= oram_avg_cnt[gen_i][gen_j]==cfg_pool_wei ? 'd0 : pool_dat_add[gen_i][gen_j];
                    else
                        pool_dat_reg[gen_i][gen_j] <= oram_avg_cnt[gen_i][gen_j]==cfg_pool_wei ? 'd0 : pool_dat_max[gen_i][gen_j];
                end
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            etoo_add_ena[gen_i] = |etoo_add_vld[gen_i] && |etoo_add_rdy[gen_i];
            otoe_dat_ena[gen_i] = |otoe_dat_vld[gen_i] && |otoe_dat_rdy[gen_i];
        end
    end
endgenerate
//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================
EEG_ORAM_RAM #(
    .ORAM_NUM_DW          ( ORAM_NUM_DW      ),
    .OMUX_NUM_DW          ( OMUX_NUM_DW      ),
    .OMUX_ADD_AW          ( OMUX_ADD_AW      ),
    .ORAM_DAT_DW          ( ORAM_DAT_DW      )
) EEG_ORAM_RAM_U(
    .clk                  ( clk              ),
    .rst_n                ( rst_n            ),

    .ORAM_DIN_VLD         ( ram_oram_din_vld ),
    .ORAM_DIN_RDY         ( ram_oram_din_rdy ),
    .ORAM_DIN_ADD         ( ram_oram_din_add ),
    .ORAM_DIN_DAT         ( ram_oram_din_dat ),

    .ORAM_ADD_VLD         ( ram_oram_add_vld ),
    .ORAM_ADD_LST         ( ram_oram_add_lst ),
    .ORAM_ADD_RDY         ( ram_oram_add_rdy ),
    .ORAM_ADD_ADD         ( ram_oram_add_add ),
    .ORAM_DAT_VLD         ( ram_oram_dat_vld ),
    .ORAM_DAT_LST         ( ram_oram_dat_lst ),
    .ORAM_DAT_RDY         ( ram_oram_dat_rdy ),
    .ORAM_DAT_DAT         ( ram_oram_dat_dat )
);

//=====================================================================================================================
// FSM :
//=====================================================================================================================
always @ ( * )begin
  case( oram_cs )
    ORAM_IDLE: oram_ns = cfg_info_ena? CFG_INFO_CMD : oram_cs;
    ORAM_ZERO: oram_ns = oram_zero_done ? ORAM_IDLE : oram_cs;
    ORAM_CONV: oram_ns = oram_conv_done ? ORAM_IDLE : oram_cs;
    ORAM_RESN: oram_ns = oram_resn_done ? ORAM_IDLE : oram_cs;
    ORAM_POOL: oram_ns = oram_pool_done ? ORAM_IDLE : oram_cs;
    ORAM_OTOA: oram_ns = oram_otoa_done ? ORAM_IDLE : oram_cs;
    ORAM_STAT: oram_ns = oram_stat_done ? ORAM_IDLE : oram_cs;
    ORAM_READ: oram_ns = oram_read_done ? ORAM_IDLE : oram_cs;
    default  : oram_ns = ORAM_IDLE;
  endcase
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        oram_cs <= ORAM_IDLE;
    else
        oram_cs <= oram_ns;
end

`ifdef ASSERT_ON


`endif
endmodule
