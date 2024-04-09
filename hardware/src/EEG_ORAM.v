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
//========================================================
module EEG_ORAM #(
    parameter ORAM_CMD_DW =  8,
    parameter ORAM_NUM_DW =  4,
    parameter ORAM_MUX_DW =  4,
    parameter ORAM_ADD_AW = 10,
    parameter ORAM_ADD_MW =  8,
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
    input  [CONV_LEN_DW                                     -1:0] CFG_CONV_LEN,
    input  [POOL_LEN_DW                                     -1:0] CFG_POOL_LEN,
    input  [POOL_FAC_DW                                     -1:0] CFG_POOL_FAC,
    input                                                         CFG_RELU_ENA,
    input                                                         CFG_SPLT_ENA,
    input                                                         CFG_COMB_ENA,
    input                                                         CFG_MAXP_ENA,
    input                                                         CFG_AVGP_ENA,
    
    input  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   ETOO_DAT_VLD,
    input  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   ETOO_DAT_LST,
    output [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   ETOO_DAT_RDY,
    input  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_ADD_MW -1:0] ETOO_DAT_ADD,
    input  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_DAT_DW -1:0] ETOO_DAT_DAT,
    
    input  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   ETOO_ADD_VLD,
    input  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   ETOO_ADD_LST,
    output [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   ETOO_ADD_RDY,
    input  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_ADD_AW -1:0] ETOO_ADD_ADD,
    output [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   OTOE_DAT_VLD,
    output [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   OTOE_DAT_LST,
    input  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   OTOE_DAT_RDY,
    output [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_DAT_DW -1:0] OTOE_DAT_DAT
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
localparam ORAM_LEN_DW = 1<<ORAM_ADD_MW;
localparam ORAM_BUF_DW = ORAM_ADD_MW+ORAM_DAT_DW+1;
localparam ORAM_BUF_AW = 2;
localparam POOL_FAC_LW = 4;

localparam ORAM_STATE = ORAM_CMD_DW;
localparam ORAM_IDLE  = 8'b0000001;
localparam ORAM_ZERO  = 8'b0000010;
localparam ORAM_CONV  = 8'b0000100;
localparam ORAM_RESN  = 8'b0001000;
localparam ORAM_POOL  = 8'b0010000;
localparam ORAM_OTOA  = 8'b0100000;
localparam ORAM_STAT  = 8'b1000000;

reg [ORAM_STATE -1:0] oram_cs;
reg [ORAM_STATE -1:0] oram_ns;

wire oram_idle = oram_cs == ORAM_IDLE;
wire oram_zero = oram_cs == ORAM_ZERO;
wire oram_conv = oram_cs == ORAM_CONV;
wire oram_resn = oram_cs == ORAM_RESN;
wire oram_pool = oram_cs == ORAM_POOL;
wire oram_otoa = oram_cs == ORAM_OTOA;
wire oram_stat = oram_cs == ORAM_STAT;
wire oram_ptoo = oram_conv || oram_resn;
assign IS_IDLE = oram_idle;
reg [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0] zero_lst_done;
reg [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0] conv_lst_done;
reg [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0] pool_lst_done;
reg [ORAM_NUM_DW -1:0]                   otoa_lst_done;

wire oram_zero_done = &zero_lst_done;
wire oram_conv_done = &conv_lst_done;
wire oram_resn_done = &conv_lst_done;
wire oram_pool_done = &pool_lst_done;
wire oram_otoa_done = &otoa_lst_done;
wire oram_stat_done = &otoa_lst_done;//same with otoa

integer i;
//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
//CFG_IO
wire cfg_info_vld = CFG_INFO_VLD;
wire cfg_info_rdy = oram_idle;

assign CFG_INFO_RDY = cfg_info_rdy;

wire cfg_info_ena = cfg_info_vld & cfg_info_rdy;
reg  [6            -1:0] cfg_info_cmd;
reg  [CONV_LEN_DW  -1:0] cfg_conv_len;
reg  [POOL_LEN_DW  -1:0] cfg_pool_len;
reg  [POOL_FAC_DW  -1:0] cfg_pool_fac;
reg  [POOL_FAC_LW  -1:0] cal_pool_len;
reg                      cfg_relu_ena;
reg                      cfg_splt_ena;
reg                      cfg_comb_ena;
reg                      cfg_maxp_ena;
reg                      cfg_avgp_ena;

//ORAM_DIN
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   etoo_dat_vld = ETOO_DAT_VLD;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   etoo_dat_lst = ETOO_DAT_LST;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   etoo_dat_rdy;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_ADD_MW -1:0] etoo_dat_add = ETOO_DAT_ADD;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_DAT_DW -1:0] etoo_dat_dat = ETOO_DAT_DAT;
assign ETOO_DAT_RDY = etoo_dat_rdy;

wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0] etoo_dat_ena = etoo_dat_vld & etoo_dat_rdy;

//ORAM_OUT
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   etoo_add_vld = ETOO_ADD_VLD;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   etoo_add_lst = ETOO_ADD_LST;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   etoo_add_rdy;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_ADD_AW -1:0] etoo_add_add = ETOO_ADD_ADD;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   otoe_dat_vld;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   otoe_dat_lst;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   otoe_dat_rdy = OTOE_DAT_RDY;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_DAT_DW -1:0] otoe_dat_dat;

assign ETOO_ADD_RDY = etoo_add_rdy;
assign OTOE_DAT_VLD = otoe_dat_vld;
assign OTOE_DAT_LST = otoe_dat_lst;
assign OTOE_DAT_DAT = otoe_dat_dat;

wire [ORAM_NUM_DW -1:0] etoo_add_ena = etoo_add_vld & etoo_add_rdy;
wire [ORAM_NUM_DW -1:0] otoe_dat_ena = otoe_dat_vld & otoe_dat_rdy;
//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================
//ETOO_DAT_FIFO
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0] etoo_buf_wen;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0] etoo_buf_ren;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0] etoo_buf_empty;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0] etoo_buf_full;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_BUF_DW -1:0] etoo_buf_din;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_BUF_DW -1:0] etoo_buf_out;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   etoo_buf_lst;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_ADD_MW -1:0] etoo_buf_add;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_DAT_DW -1:0] etoo_buf_dat;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_BUF_AW   :0] etoo_buf_cnt;

//RES
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_DAT_DW   :0] oram_res_dat;

reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_ADD_MW -1:0] oram_din_cnt;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_ADD_MW -1:0] oram_add_cnt;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_ADD_MW -1:0] oram_dat_cnt;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_ADD_MW -1:0] oram_avg_cnt;

reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0] oram_din_cnt_last;

//RAM
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   ram_oram_din_vld;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   ram_oram_din_rdy;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_ADD_MW -1:0] ram_oram_din_add;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_DAT_DW -1:0] ram_oram_din_dat;

reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   ram_oram_add_vld;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   ram_oram_add_lst;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   ram_oram_add_rdy;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_ADD_MW -1:0] ram_oram_add_add;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   ram_oram_dat_vld;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   ram_oram_dat_lst;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   ram_oram_dat_rdy;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_DAT_DW -1:0] ram_oram_dat_dat;

wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   ram_oram_din_ena = ram_oram_din_vld & ram_oram_din_rdy;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   ram_oram_add_ena = ram_oram_add_vld & ram_oram_add_rdy;
wire [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   ram_oram_dat_ena = ram_oram_dat_vld & ram_oram_dat_rdy;
reg  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_DAT_DW+POOL_FAC_DW -1:0] ram_pool_dat_dat;

CPM_FIFO #( .DATA_WIDTH( ORAM_BUF_DW ), .ADDR_WIDTH( ORAM_BUF_AW ) ) ORAM_FIFO_U[ORAM_NUM_DW*ORAM_MUX_DW -1:0] ( clk, rst_n, 1'd0, etoo_buf_wen, etoo_buf_ren, etoo_buf_din, etoo_buf_out, etoo_buf_empty, etoo_buf_full, etoo_buf_cnt);
//=====================================================================================================================
// IO Logic Design :
//=====================================================================================================================
genvar gen_i, gen_j;           
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_info_cmd <= 'd0;
        cfg_conv_len <= 'd0;
        cfg_pool_len <= 'd0;
        cfg_pool_fac <= 'd0;
        cfg_relu_ena <= 'd0;
        cfg_splt_ena <= 'd0;
        cfg_comb_ena <= 'd0;
        cfg_maxp_ena <= 'd0;
        cfg_avgp_ena <= 'd0;
        cal_pool_len <= 'd0;
    end else if( cfg_info_ena )begin
        cfg_info_cmd <= CFG_INFO_CMD;
        cfg_conv_len <= CFG_CONV_LEN;
        cfg_pool_len <= CFG_POOL_LEN;
        cfg_pool_fac <= CFG_POOL_FAC;
        cfg_relu_ena <= CFG_RELU_ENA;
        cfg_splt_ena <= CFG_SPLT_ENA;
        cfg_comb_ena <= CFG_COMB_ENA;
        cfg_maxp_ena <= CFG_MAXP_ENA;
        cfg_avgp_ena <= CFG_AVGP_ENA;
        cal_pool_len <= 1<<CFG_POOL_FAC;
    end
end

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < ORAM_MUX_DW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                etoo_add_rdy[gen_i][gen_j] = ram_oram_add_rdy[gen_i][gen_j];
                etoo_dat_rdy[gen_i][gen_j] =~etoo_buf_full[gen_i][gen_j];
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < ORAM_MUX_DW; gen_j = gen_j+1 )begin
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
        for( gen_j=0 ; gen_j < ORAM_MUX_DW; gen_j = gen_j+1 )begin
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    zero_lst_done[gen_i][gen_j] <= 'd0;
                else if( cfg_info_ena )
                    zero_lst_done[gen_i][gen_j] <= 'd0;
                else if( ram_oram_din_ena[gen_i][gen_j] && &oram_din_cnt[gen_i][gen_j] )
                    zero_lst_done[gen_i][gen_j] <= 'd1;
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < ORAM_MUX_DW; gen_j = gen_j+1 )begin
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    conv_lst_done[gen_i][gen_j] <= 'd0;
                else if( cfg_info_ena )
                    conv_lst_done[gen_i][gen_j] <= 'd0;
                else if( etoo_buf_ren[gen_i][gen_j] && etoo_buf_lst[gen_i][gen_j] )
                    conv_lst_done[gen_i][gen_j] <= 'd1;
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < ORAM_MUX_DW; gen_j = gen_j+1 )begin
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    pool_lst_done[gen_i][gen_j] <= 'd0;
                else if( cfg_info_ena )
                    pool_lst_done[gen_i][gen_j] <= 'd0;
                else if( ram_oram_din_ena[gen_i][gen_j] && (oram_din_cnt[gen_i][gen_j]==oram_din_cnt_last[gen_i][gen_j]) )
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


//buf
generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < ORAM_MUX_DW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                etoo_buf_wen[gen_i][gen_j] = oram_ptoo && etoo_dat_vld[gen_i][gen_j] && etoo_dat_rdy[gen_i][gen_j];
                etoo_buf_ren[gen_i][gen_j] = oram_ptoo && etoo_dat_vld[gen_i][gen_j] && etoo_dat_rdy[gen_i][gen_j];
                etoo_buf_din[gen_i][gen_j] = {etoo_dat_lst[gen_i][gen_j], etoo_dat_add[gen_i][gen_j], etoo_dat_dat[gen_i][gen_j]};
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < ORAM_MUX_DW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                etoo_buf_lst[gen_i][gen_j] = etoo_buf_out[gen_i][gen_j][ORAM_DAT_DW + ORAM_ADD_MW];
                etoo_buf_add[gen_i][gen_j] = etoo_buf_out[gen_i][gen_j][ORAM_DAT_DW +:ORAM_ADD_MW];
                etoo_buf_dat[gen_i][gen_j] = etoo_buf_out[gen_i][gen_j][0 +:ORAM_DAT_DW];
            end
        end
    end
endgenerate

//res
generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < ORAM_MUX_DW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                oram_res_dat[gen_i][gen_j] = etoo_buf_dat[gen_i][gen_j]+etoo_buf_dat[gen_i][gen_j];
            end
        end
    end
endgenerate

//oram
generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 ) begin
        for( gen_j=0 ; gen_j < ORAM_MUX_DW; gen_j = gen_j+1 ) begin
            always @ ( * )begin
                case( oram_cs )
                    ORAM_ZERO: ram_oram_din_vld[gen_i][gen_j] = 'd1;
                    ORAM_CONV: ram_oram_din_vld[gen_i][gen_j] =~etoo_buf_empty[gen_i][gen_j];
                    ORAM_RESN: ram_oram_din_vld[gen_i][gen_j] = ram_oram_dat_ena[gen_i][gen_j];
                    ORAM_POOL: ram_oram_din_vld[gen_i][gen_j] = ram_oram_dat_ena[gen_i][gen_j] && oram_avg_cnt[gen_i][gen_j]==cal_pool_len;
                    default  : ram_oram_din_vld[gen_i][gen_j] = 'd0;
                endcase
            end
            
            always @ ( * )begin
                case( oram_cs )
                    ORAM_ZERO: ram_oram_din_add[gen_i][gen_j] = oram_din_cnt[gen_i][gen_j];
                    ORAM_CONV: ram_oram_din_add[gen_i][gen_j] = etoo_buf_add[gen_i][gen_j];
                    ORAM_RESN: ram_oram_din_add[gen_i][gen_j] = etoo_buf_add[gen_i][gen_j];
                    ORAM_POOL: ram_oram_din_add[gen_i][gen_j] = oram_din_cnt[gen_i][gen_j];
                    default  : ram_oram_din_add[gen_i][gen_j] = 'd0;
                endcase
            end

            always @ ( * )begin
                case( oram_cs )
                    ORAM_CONV: ram_oram_din_dat[gen_i][gen_j] = cfg_relu_ena && etoo_buf_dat[gen_i][gen_j][ORAM_DAT_DW -1] ? 'd0 : etoo_buf_dat[gen_i][gen_j];
                    ORAM_RESN: ram_oram_din_dat[gen_i][gen_j] = cfg_relu_ena && oram_res_dat[gen_i][gen_j][ORAM_DAT_DW   ] ? 'd0 : oram_res_dat[gen_i][gen_j][ORAM_DAT_DW :1];
                    ORAM_POOL: ram_oram_din_dat[gen_i][gen_j] = ram_pool_dat_dat;
                    default  : ram_oram_din_dat[gen_i][gen_j] = 'd0;//ORAM_ZERO
                endcase
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < ORAM_MUX_DW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                case( oram_cs )
                    ORAM_RESN: ram_oram_add_vld[gen_i][gen_j] =~etoo_buf_empty[gen_i][gen_j] && ~ram_oram_dat_vld[gen_i][gen_j];
                    ORAM_POOL: ram_oram_add_vld[gen_i][gen_j] =~ram_oram_dat_vld[gen_i][gen_j];
                    ORAM_OTOA: ram_oram_add_vld[gen_i][gen_j] = etoo_add_vld[gen_i][gen_j];
                    ORAM_STAT: ram_oram_add_vld[gen_i][gen_j] = etoo_add_vld[gen_i][gen_j];
                    default  : ram_oram_add_vld[gen_i][gen_j] = 'd0;
                endcase
            end

            always @ ( * )begin
                case( oram_cs )
                    ORAM_RESN: ram_oram_add_lst[gen_i][gen_j] = etoo_buf_lst[gen_i][gen_j];
                    ORAM_POOL: ram_oram_add_lst[gen_i][gen_j] = oram_dat_cnt[gen_i][gen_j]==cfg_conv_len[CONV_LEN_DW -1:2];
                    ORAM_OTOA: ram_oram_add_lst[gen_i][gen_j] = etoo_add_lst[gen_i][gen_j];
                    ORAM_STAT: ram_oram_add_lst[gen_i][gen_j] = etoo_add_lst[gen_i][gen_j];
                    default  : ram_oram_add_lst[gen_i][gen_j] = 'd0;
                endcase
            end
            
            always @ ( * )begin
                case( oram_cs )
                    ORAM_RESN: ram_oram_add_add[gen_i][gen_j] = etoo_buf_add[gen_i][gen_j];
                    ORAM_POOL: ram_oram_add_add[gen_i][gen_j] = oram_dat_cnt[gen_i][gen_j];
                    ORAM_OTOA: ram_oram_add_add[gen_i][gen_j] = etoo_add_add[gen_i][gen_j];
                    ORAM_STAT: ram_oram_add_add[gen_i][gen_j] = etoo_add_add[gen_i][gen_j];
                    default  : ram_oram_add_add[gen_i][gen_j] = 'd0;
                endcase
            end
            assign ram_oram_dat_rdy[gen_i][gen_j] = ~oram_otoa || otoe_dat_rdy[gen_i];
        end
    end
endgenerate

//cnt
generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < ORAM_MUX_DW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                oram_din_cnt_last[gen_i][gen_j] <= oram_zero ? &oram_din_cnt[gen_i][gen_j] : oram_din_cnt[gen_i][gen_j]==cfg_pool_len;
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < ORAM_MUX_DW; gen_j = gen_j+1 )begin
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
        for( gen_j=0 ; gen_j < ORAM_MUX_DW; gen_j = gen_j+1 )begin
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
        for( gen_j=0 ; gen_j < ORAM_MUX_DW; gen_j = gen_j+1 )begin
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
        for( gen_j=0 ; gen_j < ORAM_MUX_DW; gen_j = gen_j+1 )begin
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    oram_avg_cnt[gen_i][gen_j] <= 'd0;
                else if( cfg_info_ena )
                    oram_avg_cnt[gen_i][gen_j] <= 'd0;
                else if( ram_oram_dat_ena[gen_i][gen_j] && oram_pool )begin
                    if( oram_avg_cnt[gen_i][gen_j]==cal_pool_len )
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
        for( gen_j=0 ; gen_j < ORAM_MUX_DW; gen_j = gen_j+1 )begin
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )
                    ram_pool_dat_dat[gen_i][gen_j] <= 'd0;
                else if( cfg_info_ena )
                    ram_pool_dat_dat[gen_i][gen_j] <= 'd0;
                else if( ram_oram_dat_ena[gen_i][gen_j] && oram_pool )begin
                    if( cfg_avgp_ena )begin
                        ram_pool_dat_dat[gen_i][gen_j] <= oram_avg_cnt[gen_i][gen_j]==cal_pool_len ? ram_oram_dat_dat : ram_oram_dat_dat+ram_pool_dat_dat;
                    end
                    else
                        ram_pool_dat_dat[gen_i][gen_j] <= ram_oram_dat_dat > ram_pool_dat_dat ? ram_oram_dat_dat : ram_pool_dat_dat;
                end
            end
        end
    end
endgenerate

//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================
EEG_ORAM_RAM #(
    .ORAM_NUM_DW          ( ORAM_NUM_DW      ),
    .ORAM_MUX_DW          ( ORAM_MUX_DW      ),
    .ORAM_ADD_MW          ( ORAM_ADD_MW      ),
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
    ORAM_RESN: oram_ns = oram_conv_done ? ORAM_IDLE : oram_cs;
    ORAM_POOL: oram_ns = oram_pool_done ? ORAM_IDLE : oram_cs;
    ORAM_OTOA: oram_ns = oram_otoa_done ? ORAM_IDLE : oram_cs;
    ORAM_STAT: oram_ns = oram_stat_done ? ORAM_IDLE : oram_cs;
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

property oram_rdy_check(dat_vld, dat_rdy);
@(posedge clk)
disable iff(rst_n!=1'b1)
    dat_vld |-> ( dat_rdy );
endproperty

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 ) begin : ASSERT_BLOCK
        for( gen_j=0 ; gen_j < ORAM_MUX_DW; gen_j = gen_j+1 )begin
            assert property ( oram_rdy_check(ram_oram_dat_vld[gen_i][gen_j], ram_oram_dat_rdy[gen_i][gen_j]) );
        end
    end
endgenerate

`endif
endmodule
