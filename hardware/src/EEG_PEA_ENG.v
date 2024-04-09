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
    parameter PE_ACT_DW = 8,
    parameter PE_WEI_DW = 8,
    parameter PE_OUT_DW = 8,
    parameter ARAM_ADD_AW = 12,
    parameter ORAM_ADD_AW =  8,
    parameter CONV_WEI_DW =  3,
    parameter CONV_RUN_DW =  4,
    parameter CONV_MUL_DW = 24,
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
    input  [CONV_ADD_DW                              -1:0] CFG_CONV_ADD,
    input  [ORAM_ADD_AW                              -1:0] CFG_CONV_LST,

    input               [PE_COL -1:0]                      ACT_VLD,
    output              [PE_COL -1:0]                      ACT_RDY,
    input               [PE_COL -1:0]                      ACT_LST,
    input               [PE_COL -1:0][PE_ACT_DW      -1:0] ACT_DAT,
    input               [PE_COL -1:0][PE_ACT_IW      -1:0] ACT_INF,

    input  [PE_COL -1:0][PE_ROW -1:0]                      WEI_VLD,
    output [PE_COL -1:0][PE_ROW -1:0]                      WEI_RDY,
    input  [PE_COL -1:0][PE_ROW -1:0]                      WEI_LST,
    input  [PE_COL -1:0][PE_ROW -1:0][PE_WEI_DW      -1:0] WEI_DAT,
    input  [PE_COL -1:0][PE_ROW -1:0][PE_WEI_IW      -1:0] WEI_INF,

    output [PE_ROW -1:0][PE_COL -1:0]                      OUT_VLD,
    output [PE_ROW -1:0][PE_COL -1:0]                      OUT_LST,
    input  [PE_ROW -1:0][PE_COL -1:0]                      OUT_RDY,
    output [PE_ROW -1:0][PE_COL -1:0][PE_OUT_DW      -1:0] OUT_DAT,
    output [PE_ROW -1:0][PE_COL -1:0][ORAM_ADD_AW    -1:0] OUT_ADD
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
localparam PE_SUM_DW = 24;
localparam PE_SUM_NW = 8;
localparam PE_BUF_DW = PE_ACT_DW+PE_WEI_DW+ARAM_ADD_AW+CONV_WEI_DW+2;
localparam PE_BUF_NW = 4;
localparam PE_BUF_AW = $clog2(PE_BUF_NW);

//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================
wire [CONV_RUN_DW -1:0] cfg_conv_run = CFG_CONV_RUN;
wire [CONV_WEI_DW -1:0] cfg_conv_wei = CFG_CONV_WEI;
wire [CONV_WEI_DW -1:0] cfg_conv_pad = CFG_CONV_PAD;
wire [CONV_MUL_DW -1:0] cfg_conv_mul = CFG_CONV_MUL;
wire [CONV_ADD_DW -1:0] cfg_conv_add = CFG_CONV_ADD;
wire [ORAM_ADD_AW -1:0] cfg_conv_lst = CFG_CONV_LST;

wire [PE_ROW -1:0][PE_COL -1:0] pe_conv_idle;

reg  [PE_ROW -1:0][PE_COL -1:0][PE_BUF_DW -1:0] pe_fifo_din;
wire [PE_ROW -1:0][PE_COL -1:0][PE_BUF_DW -1:0] pe_fifo_out;
reg  [PE_ROW -1:0][PE_COL -1:0] pe_fifo_wen;
reg  [PE_ROW -1:0][PE_COL -1:0] pe_fifo_ren;
wire [PE_ROW -1:0][PE_COL -1:0] pe_fifo_full;
wire [PE_ROW -1:0][PE_COL -1:0] pe_fifo_empty;

reg  [PE_ROW -1:0][PE_COL -1:0] pe_din_vld;
reg  [PE_ROW -1:0][PE_COL -1:0] pe_act_lst;
reg  [PE_ROW -1:0][PE_COL -1:0] pe_wei_lst;
wire [PE_ROW -1:0][PE_COL -1:0] pe_din_rdy;
reg  [PE_ROW -1:0][PE_COL -1:0][PE_ACT_DW   -1:0] pe_act_dat;
reg  [PE_ROW -1:0][PE_COL -1:0][PE_WEI_DW   -1:0] pe_wei_dat;
reg  [PE_ROW -1:0][PE_COL -1:0][ARAM_ADD_AW -1:0] pe_act_add;
reg  [PE_ROW -1:0][PE_COL -1:0][CONV_WEI_DW -1:0] pe_wei_idx;

reg  [PE_ROW -1:0][PE_COL -1:0] pe_act_rdy;
reg  [PE_COL -1:0][PE_ROW -1:0] pe_wei_rdy;

wire [PE_ROW -1:0][PE_COL -1:0]                      pe_out_vld;
wire [PE_ROW -1:0][PE_COL -1:0]                      pe_out_lst;
wire [PE_ROW -1:0][PE_COL -1:0]                      pe_out_rdy = OUT_RDY;
wire [PE_ROW -1:0][PE_COL -1:0][PE_OUT_DW      -1:0] pe_out_dat;
wire [PE_ROW -1:0][PE_COL -1:0][ORAM_ADD_AW    -1:0] pe_out_add;

assign ACT_RDY = pe_act_rdy;
assign WEI_RDY = pe_wei_rdy;
assign OUT_VLD = pe_out_vld;
assign OUT_LST = pe_out_lst;
assign OUT_ADD = pe_out_add;
assign OUT_DAT = pe_out_dat;

assign IS_IDLE = &pe_conv_idle;

CPM_FIFO #( .DATA_WIDTH( PE_BUF_DW ), .ADDR_WIDTH( PE_BUF_AW ) )PE_BUF_U[PE_ROW*PE_COL-1:0]( clk, rst_n, 1'd0, pe_fifo_wen, pe_fifo_ren, pe_fifo_din, pe_fifo_out, pe_fifo_empty, pe_fifo_full, );
//=====================================================================================================================
// Logic Design :
//=====================================================================================================================
genvar gen_i, gen_j;
generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < PE_COL; gen_j = gen_j+1 )begin
            
            always @ ( * )begin
                pe_fifo_din[gen_i][gen_j] = {WEI_LST[gen_j][gen_i], ACT_LST[gen_j], WEI_INF[gen_j][gen_i], ACT_INF[gen_j], WEI_DAT[gen_j][gen_i], ACT_DAT[gen_j]};
                pe_fifo_wen[gen_i][gen_j] = ACT_VLD[gen_j] && ACT_RDY[gen_j] && WEI_VLD[gen_j][gen_i] && WEI_RDY[gen_j][gen_i];
                pe_fifo_ren[gen_i][gen_j] = pe_din_rdy[gen_i][gen_j];
            end
            
        end
    end

endgenerate

generate
    for( gen_i=0 ; gen_i < PE_ROW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < PE_COL; gen_j = gen_j+1 )begin

            always @ ( * )begin
                pe_din_vld[gen_i][gen_j] = ~pe_fifo_empty[gen_i][gen_j];
            end
          
            always @ ( * )begin
                pe_act_dat[gen_i][gen_j] = pe_fifo_out[gen_i][gen_j][0+:PE_ACT_DW];
                pe_wei_dat[gen_i][gen_j] = pe_fifo_out[gen_i][gen_j][   PE_ACT_DW +:PE_WEI_DW];
                pe_act_add[gen_i][gen_j] = pe_fifo_out[gen_i][gen_j][   PE_ACT_DW + PE_WEI_DW +:ARAM_ADD_AW];
                pe_wei_idx[gen_i][gen_j] = pe_fifo_out[gen_i][gen_j][   PE_ACT_DW + PE_WEI_DW + ARAM_ADD_AW +:CONV_WEI_DW];
                // pe_din_vld[gen_i][gen_j] = pe_fifo_out[gen_i][gen_j][PE_BUF_DW -3];
                pe_act_lst[gen_i][gen_j] = pe_fifo_out[gen_i][gen_j][PE_BUF_DW -2];
                pe_wei_lst[gen_i][gen_j] = pe_fifo_out[gen_i][gen_j][PE_BUF_DW -1];
            end
            
            always @ ( * )begin
                pe_act_rdy[gen_i][gen_j] = ~pe_fifo_full[gen_i][gen_j];
            end

            always @ ( * )begin
                pe_wei_rdy[gen_i][gen_j] = ~pe_fifo_full[gen_i][gen_j];
            end

        end
    end

endgenerate

//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================
EEG_PEA_ENG_PE #(
    .ACT_DW          ( PE_ACT_DW      ),
    .WEI_DW          ( PE_WEI_DW      ),
    .OUT_DW          ( PE_OUT_DW      ),
    .SUM_DW          ( PE_SUM_DW      ),
    .SUM_NW          ( PE_SUM_NW      ),
    .ARAM_ADD_AW     ( ARAM_ADD_AW    ),
    .ORAM_ADD_AW     ( ORAM_ADD_AW    ),
    .CONV_WEI_DW     ( CONV_WEI_DW    ),
    .CONV_RUN_DW     ( CONV_RUN_DW    )
) EEG_PEA_ENG_PE_U[PE_ROW*PE_COL -1:0] (

    .clk             ( clk            ),
    .rst_n           ( rst_n          ),
    
    .IS_IDLE         ( pe_conv_idle   ),
    
    .CFG_CONV_RUN    ( cfg_conv_run   ),
    .CFG_CONV_WEI    ( cfg_conv_wei   ),
    .CFG_CONV_PAD    ( cfg_conv_pad   ),
    .CFG_CONV_MUL    ( cfg_conv_mul   ),
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
