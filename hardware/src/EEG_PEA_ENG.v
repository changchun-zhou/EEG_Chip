//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description : PEA ENGINE
//========================================================
module EEG_PEA_ENG #(
    parameter PE_ROW = 4,
    parameter PE_COL = 4,
    parameter DATA_ACT_DW =  8,
    parameter DATA_WEI_DW =  8,
    parameter DATA_OUT_DW =  8,
    parameter ARAM_ADD_AW = 12,
    parameter ORAM_ADD_AW = 10,
    parameter OMUX_ADD_AW =  8,
    parameter CONV_WEI_DW =  3,
    parameter CONV_RUN_DW =  4,
    parameter CONV_MUL_DW = 24,
    parameter CONV_SFT_DW =  8,
    parameter CONV_ADD_DW = 24,
    parameter PE_ACT_IW = ARAM_ADD_AW,
    parameter PE_WEI_IW = CONV_WEI_DW
  )(
    input                                                  clk,
    input                                                  rst_n,
    
    output                                                 IS_IDLE,

    input  [CONV_RUN_DW                              -1:0] CFG_CONV_RUN,
    input  [CONV_WEI_DW                              -1:0] CFG_CONV_WEI,
    input  [CONV_WEI_DW                              -1:0] CFG_CONV_PAD,
    input  [CONV_MUL_DW                              -1:0] CFG_CONV_MUL,
    input  [CONV_SFT_DW                              -1:0] CFG_CONV_SFT,
    input  [CONV_ADD_DW                              -1:0] CFG_CONV_ADD,
    input  [ORAM_ADD_AW                              -1:0] CFG_CONV_LST,

    input               [PE_COL -1:0]                      ACT_VLD,
    output              [PE_COL -1:0]                      ACT_RDY,
    input               [PE_COL -1:0]                      ACT_LST,
    input               [PE_COL -1:0][DATA_ACT_DW    -1:0] ACT_DAT,
    input               [PE_COL -1:0][PE_ACT_IW      -1:0] ACT_INF,

    input  [PE_COL -1:0][PE_ROW -1:0]                      WEI_VLD,
    output [PE_COL -1:0][PE_ROW -1:0]                      WEI_RDY,
    input  [PE_COL -1:0][PE_ROW -1:0]                      WEI_LST,
    input  [PE_COL -1:0][PE_ROW -1:0][DATA_WEI_DW    -1:0] WEI_DAT,
    input  [PE_COL -1:0][PE_ROW -1:0][PE_WEI_IW      -1:0] WEI_INF,

    output [PE_COL -1:0][PE_ROW -1:0]                      OUT_VLD,
    output [PE_COL -1:0][PE_ROW -1:0]                      OUT_LST,
    input  [PE_COL -1:0][PE_ROW -1:0]                      OUT_RDY,
    output [PE_COL -1:0][PE_ROW -1:0][DATA_OUT_DW    -1:0] OUT_DAT,
    output [PE_COL -1:0][PE_ROW -1:0][OMUX_ADD_AW    -1:0] OUT_ADD
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
localparam DATA_SUM_DW = 24;
localparam DATA_SUM_NW = 8;
localparam PACT_BUF_DW = DATA_ACT_DW+DATA_WEI_DW+ARAM_ADD_AW+CONV_WEI_DW+2;
localparam PACT_BUF_NW = 2;
localparam PACT_BUF_AW = $clog2(PACT_BUF_NW);

genvar gen_i, gen_j;
//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
//ACT_IO
wire [PE_COL -1:0]                      act_vld = ACT_VLD;
reg  [PE_COL -1:0]                      act_rdy;
wire [PE_COL -1:0]                      act_lst = ACT_LST;
wire [PE_COL -1:0][DATA_ACT_DW    -1:0] act_dat = ACT_DAT;
wire [PE_COL -1:0][PE_ACT_IW      -1:0] act_inf = ACT_INF;
wire [PE_COL -1:0]                      act_ena = act_vld & act_rdy;

assign ACT_RDY = act_rdy;

//WEI_IO
wire [PE_COL -1:0][PE_ROW -1:0]                      wei_vld = WEI_VLD;
reg  [PE_COL -1:0][PE_ROW -1:0]                      wei_rdy;
wire [PE_COL -1:0][PE_ROW -1:0]                      wei_lst = WEI_LST;
wire [PE_COL -1:0][PE_ROW -1:0][DATA_WEI_DW    -1:0] wei_dat = WEI_DAT;
wire [PE_COL -1:0][PE_ROW -1:0][PE_WEI_IW      -1:0] wei_inf = WEI_INF;
wire [PE_COL -1:0][PE_ROW -1:0] wei_ena = wei_vld & wei_rdy;
assign WEI_RDY = wei_rdy;

//ACT_IO
reg  [PE_COL -1:0][PE_ROW -1:0]                      out_vld;
reg  [PE_COL -1:0][PE_ROW -1:0]                      out_lst;
wire [PE_COL -1:0][PE_ROW -1:0]                      out_rdy = OUT_RDY;
reg  [PE_COL -1:0][PE_ROW -1:0][DATA_OUT_DW    -1:0] out_dat;
reg  [PE_COL -1:0][PE_ROW -1:0][OMUX_ADD_AW    -1:0] out_add;

assign OUT_VLD = out_vld;
assign OUT_LST = out_lst;
assign OUT_DAT = out_dat;
assign OUT_ADD = out_add;
//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================
wire [CONV_RUN_DW -1:0] cfg_conv_run = CFG_CONV_RUN;
wire [CONV_WEI_DW -1:0] cfg_conv_wei = CFG_CONV_WEI;
wire [CONV_WEI_DW -1:0] cfg_conv_pad = CFG_CONV_PAD;
wire [ORAM_ADD_AW -1:0] cfg_conv_lst = CFG_CONV_LST;
wire [PE_COL -1:0][PE_ROW -1:0][CONV_MUL_DW -1:0] cfg_conv_mul;
wire [PE_COL -1:0][PE_ROW -1:0][CONV_SFT_DW -1:0] cfg_conv_sft;
wire [PE_COL -1:0][PE_ROW -1:0][CONV_ADD_DW -1:0] cfg_conv_add;

CPM_REG #( CONV_MUL_DW ) CFG_CONV_MUL_REG [PE_COL*PE_ROW-1:0]( clk, rst_n, CFG_CONV_MUL, cfg_conv_mul );
CPM_REG #( CONV_SFT_DW ) CFG_CONV_SFT_REG [PE_COL*PE_ROW-1:0]( clk, rst_n, CFG_CONV_SFT, cfg_conv_sft );
CPM_REG #( CONV_ADD_DW ) CFG_CONV_ADD_REG [PE_COL*PE_ROW-1:0]( clk, rst_n, CFG_CONV_ADD, cfg_conv_add );

wire [PE_ROW -1:0][PE_COL -1:0] pe_conv_idle;

reg  [PE_COL -1:0][PE_ROW -1:0][PACT_BUF_DW -1:0] pe_fifo_din;
wire [PE_COL -1:0][PE_ROW -1:0][PACT_BUF_DW -1:0] pe_fifo_out;
reg  [PE_COL -1:0][PE_ROW -1:0] pe_fifo_wen;
reg  [PE_COL -1:0][PE_ROW -1:0] pe_fifo_ren;
wire [PE_COL -1:0][PE_ROW -1:0] pe_fifo_full;
wire [PE_COL -1:0][PE_ROW -1:0] pe_fifo_empty;
wire [PE_COL -1:0][PE_ROW -1:0][PACT_BUF_AW   :0] pe_fifo_cnt;

reg  [PE_COL -1:0][PE_ROW -1:0] pe_din_vld;
reg  [PE_COL -1:0][PE_ROW -1:0] pe_act_lst;
reg  [PE_COL -1:0][PE_ROW -1:0] pe_wei_lst;
wire [PE_COL -1:0][PE_ROW -1:0] pe_din_rdy;
reg  [PE_COL -1:0][PE_ROW -1:0][DATA_ACT_DW -1:0] pe_act_dat;
reg  [PE_COL -1:0][PE_ROW -1:0][DATA_WEI_DW -1:0] pe_wei_dat;
reg  [PE_COL -1:0][PE_ROW -1:0][ARAM_ADD_AW -1:0] pe_act_add;
reg  [PE_COL -1:0][PE_ROW -1:0][CONV_WEI_DW -1:0] pe_wei_idx;

reg  [PE_COL -1:0] pe_act_rdy;
reg  [PE_COL -1:0][PE_ROW -1:0] pe_wei_rdy;

wire [PE_COL -1:0][PE_ROW -1:0]                   pe_out_vld;
wire [PE_COL -1:0][PE_ROW -1:0]                   pe_out_lst;
wire [PE_COL -1:0][PE_ROW -1:0]                   pe_out_rdy = OUT_RDY;
wire [PE_COL -1:0][PE_ROW -1:0][DATA_OUT_DW -1:0] pe_out_dat;
wire [PE_COL -1:0][PE_ROW -1:0][OMUX_ADD_AW -1:0] pe_out_add;

assign IS_IDLE = &pe_conv_idle;

CPM_FIFO #( .DATA_WIDTH( PACT_BUF_DW ), .ADDR_WIDTH( PACT_BUF_AW ) )PE_BUF_U[PE_COL*PE_ROW-1:0]( clk, rst_n, 1'd0, pe_fifo_wen, pe_fifo_ren, pe_fifo_din, pe_fifo_out, pe_fifo_empty, pe_fifo_full, pe_fifo_cnt);

//=====================================================================================================================
// IO Logic Design :
//=====================================================================================================================
always @ ( * )begin
    act_rdy = pe_act_rdy;
    wei_rdy = pe_wei_rdy;
end

generate
    for( gen_i=0 ; gen_i <PE_COL; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j <  PE_ROW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                out_vld[gen_i][gen_j] = pe_out_vld[gen_i][gen_j];
                out_lst[gen_i][gen_j] = pe_out_lst[gen_i][gen_j];
                out_dat[gen_i][gen_j] = pe_out_dat[gen_i][gen_j];
                out_add[gen_i][gen_j] = pe_out_add[gen_i][gen_j];
            end
        end
    end
endgenerate            
//=====================================================================================================================
// Logic Design :
//=====================================================================================================================
generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < PE_ROW; gen_j = gen_j+1 )begin
            
            always @ ( * )begin
                pe_fifo_din[gen_i][gen_j] = {wei_lst[gen_i][gen_j], act_lst[gen_i], wei_inf[gen_i][gen_j], act_inf[gen_i], wei_dat[gen_i][gen_j], act_dat[gen_i]};
                pe_fifo_wen[gen_i][gen_j] = act_vld[gen_i] && wei_ena[gen_i][gen_j];
            end
            always @ ( * )begin
                pe_fifo_ren[gen_i][gen_j] = pe_din_rdy[gen_i][gen_j] && ~pe_fifo_empty[gen_i][gen_j];
            end            
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < PE_ROW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                pe_din_vld[gen_i][gen_j] = ~pe_fifo_empty[gen_i][gen_j];
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        always @ ( * )begin
            pe_act_rdy[gen_i] = ~|pe_fifo_full[gen_i] && &wei_vld[gen_i] && &wei_lst[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < PE_ROW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                pe_wei_rdy[gen_i][gen_j] = ~pe_fifo_full[gen_i][gen_j] && act_vld[gen_i] && &wei_vld[gen_i] && (&wei_lst[gen_i] || ~|wei_lst[gen_i]);
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < PE_COL; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < PE_ROW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                pe_act_dat[gen_i][gen_j] = pe_fifo_out[gen_i][gen_j][0+:DATA_ACT_DW];
                pe_wei_dat[gen_i][gen_j] = pe_fifo_out[gen_i][gen_j][   DATA_ACT_DW +:DATA_WEI_DW];
                pe_act_add[gen_i][gen_j] = pe_fifo_out[gen_i][gen_j][   DATA_ACT_DW + DATA_WEI_DW +:ARAM_ADD_AW];
                pe_wei_idx[gen_i][gen_j] = pe_fifo_out[gen_i][gen_j][   DATA_ACT_DW + DATA_WEI_DW + ARAM_ADD_AW +:CONV_WEI_DW];
                pe_act_lst[gen_i][gen_j] = pe_fifo_out[gen_i][gen_j][PACT_BUF_DW -2];
                pe_wei_lst[gen_i][gen_j] = pe_fifo_out[gen_i][gen_j][PACT_BUF_DW -1];
            end
        end
    end
endgenerate

//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================
EEG_PEA_ENG_PE #(
    .DATA_ACT_DW     ( DATA_ACT_DW    ),
    .DATA_WEI_DW     ( DATA_WEI_DW    ),
    .DATA_OUT_DW     ( DATA_OUT_DW    ),
    .DATA_SUM_DW     ( DATA_SUM_DW    ),
    .DATA_SUM_NW     ( DATA_SUM_NW    ),
    .ARAM_ADD_AW     ( ARAM_ADD_AW    ),
    .ORAM_ADD_AW     ( ORAM_ADD_AW    ),
    .OMUX_ADD_AW     ( OMUX_ADD_AW    ),
    .CONV_WEI_DW     ( CONV_WEI_DW    ),
    .CONV_RUN_DW     ( CONV_RUN_DW    ),
    .CONV_MUL_DW     ( CONV_MUL_DW    ),
    .CONV_SFT_DW     ( CONV_SFT_DW    ),
    .CONV_ADD_DW     ( CONV_ADD_DW    )
) EEG_PEA_ENG_PE_U[PE_COL*PE_ROW -1:0] (

    .clk             ( clk            ),
    .rst_n           ( rst_n          ),
    
    .IS_IDLE         ( pe_conv_idle   ),
    
    .CFG_CONV_RUN    ( cfg_conv_run   ),
    .CFG_CONV_WEI    ( cfg_conv_wei   ),
    .CFG_CONV_PAD    ( cfg_conv_pad   ),
    .CFG_CONV_MUL    ( cfg_conv_mul   ),
    .CFG_CONV_SFT    ( cfg_conv_sft   ),
    .CFG_CONV_ADD    ( cfg_conv_add   ),
    .CFG_CONV_LST    ( cfg_conv_lst   ),
    
    .DIN_VLD         ( pe_din_vld     ),
    .ACT_LST         ( pe_act_lst     ),
    .WEI_LST         ( pe_wei_lst     ),
    .DIN_RDY         ( pe_din_rdy     ),
    .ACT_DAT         ( pe_act_dat     ),
    .ACT_ADD         ( pe_act_add     ),
    .WEI_DAT         ( pe_wei_dat     ),
    .WEI_IDX         ( pe_wei_idx     ),

    .OUT_VLD         ( pe_out_vld     ),
    .OUT_LST         ( pe_out_lst     ),
    .OUT_ADD         ( pe_out_add     ),
    .OUT_RDY         ( pe_out_rdy     ),
    .OUT_DAT         ( pe_out_dat     )
);

//=====================================================================================================================
// FSM :
//=====================================================================================================================

`ifdef ASSERT_ON


`endif
endmodule
