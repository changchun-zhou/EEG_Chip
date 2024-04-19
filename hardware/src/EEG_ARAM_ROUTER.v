//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description : ARAM ROUTER 
//========================================================
module EEG_ARAM_ROUTER #(
    parameter ARAM_NUM_DW =  4,
    parameter ARAM_ADD_AW = 12,
    parameter ARAM_DAT_DW =  4,
    parameter ARAM_NUM_AW = $clog2(ARAM_NUM_DW)
  )(
    input                                          clk,
    input                                          rst_n,

    input  [ARAM_NUM_DW -1:0][ARAM_NUM_AW    -1:0] ARAM_ADD_RID,
    input  [ARAM_NUM_DW -1:0]                      ARAM_ADD_VLD,
    input  [ARAM_NUM_DW -1:0]                      ARAM_ADD_LST,
    output [ARAM_NUM_DW -1:0]                      ARAM_ADD_RDY,
    input  [ARAM_NUM_DW -1:0][ARAM_ADD_AW    -1:0] ARAM_ADD_ADD,
    output [ARAM_NUM_DW -1:0]                      ARAM_DAT_VLD,
    output [ARAM_NUM_DW -1:0]                      ARAM_DAT_LST,
    input  [ARAM_NUM_DW -1:0]                      ARAM_DAT_RDY,
    output [ARAM_NUM_DW -1:0][ARAM_DAT_DW    -1:0] ARAM_DAT_DAT,

    output [ARAM_NUM_DW -1:0]                      AARB_ADD_VLD,
    output [ARAM_NUM_DW -1:0]                      AARB_ADD_LST,
    input  [ARAM_NUM_DW -1:0]                      AARB_ADD_RDY,
    output [ARAM_NUM_DW -1:0][ARAM_ADD_AW    -1:0] AARB_ADD_ADD,
    input  [ARAM_NUM_DW -1:0]                      AARB_DAT_VLD,
    input  [ARAM_NUM_DW -1:0]                      AARB_DAT_LST,
    output [ARAM_NUM_DW -1:0]                      AARB_DAT_RDY,
    input  [ARAM_NUM_DW -1:0][ARAM_DAT_DW    -1:0] AARB_DAT_DAT
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
localparam AARB_BUF_DW = 1+ARAM_NUM_AW;
localparam AARB_BUF_AW = 1;

integer i;

//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
//RAM_IO
wire [ARAM_NUM_DW -1:0]                      aram_add_vld= ARAM_ADD_VLD;
wire [ARAM_NUM_DW -1:0]                      aram_add_lst= ARAM_ADD_LST;
wire [ARAM_NUM_DW -1:0]                      aram_add_rdy= AARB_ADD_RDY;
wire [ARAM_NUM_DW -1:0][ARAM_NUM_AW    -1:0] aram_add_rid= ARAM_ADD_RID;
wire [ARAM_NUM_DW -1:0][ARAM_ADD_AW    -1:0] aram_add_add= ARAM_ADD_ADD;
reg  [ARAM_NUM_DW -1:0]                      aram_dat_vld;
reg  [ARAM_NUM_DW -1:0]                      aram_dat_lst;
wire [ARAM_NUM_DW -1:0]                      aram_dat_rdy= ARAM_DAT_RDY;
reg  [ARAM_NUM_DW -1:0][ARAM_DAT_DW    -1:0] aram_dat_dat;

assign ARAM_ADD_RDY = aram_add_rdy;
assign ARAM_DAT_VLD = aram_dat_vld;
assign ARAM_DAT_LST = aram_dat_lst;
assign ARAM_DAT_DAT = aram_dat_dat;

//ARB_IO
reg  [ARAM_NUM_DW -1:0]                      aarb_add_vld;
reg  [ARAM_NUM_DW -1:0]                      aarb_add_lst;
wire [ARAM_NUM_DW -1:0]                      aarb_add_rdy= AARB_ADD_RDY;
reg  [ARAM_NUM_DW -1:0][ARAM_ADD_AW    -1:0] aarb_add_add;
wire [ARAM_NUM_DW -1:0]                      aarb_dat_vld= AARB_DAT_VLD;
wire [ARAM_NUM_DW -1:0]                      aarb_dat_lst= AARB_DAT_LST;
wire [ARAM_NUM_DW -1:0]                      aarb_dat_rdy= ARAM_DAT_RDY;
wire [ARAM_NUM_DW -1:0][ARAM_DAT_DW    -1:0] aarb_dat_dat= AARB_DAT_DAT;

wire [ARAM_NUM_DW -1:0] aram_add_ena = aram_add_vld & aram_add_rdy;
wire [ARAM_NUM_DW -1:0] aram_dat_ena = aram_dat_vld & aram_dat_rdy;
wire [ARAM_NUM_DW -1:0] aarb_add_ena = aarb_add_vld & aarb_add_rdy;
wire [ARAM_NUM_DW -1:0] aarb_dat_ena = aarb_dat_vld & aarb_dat_rdy;

assign AARB_ADD_VLD = aarb_add_vld;
assign AARB_ADD_LST = aarb_add_lst;
assign AARB_ADD_ADD = aarb_add_add;
assign AARB_DAT_RDY = aarb_dat_rdy;

//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================

wire [ARAM_NUM_DW -1:0] aram_add_gnt_arb;
wire [ARAM_NUM_DW -1:0][ARAM_NUM_AW  -1:0] aram_add_gnt_idx;
CPM_ARB_MI #( .REQ_DW(ARAM_NUM_DW), .IDX_AW(ARAM_NUM_AW) ) ARAM_ARB_U ( clk, rst_n, aram_add_vld, aram_add_rid, aram_add_gnt_arb, aram_add_gnt_idx );

reg  [ARAM_NUM_DW -1:0] aarb_fifo_wen;
reg  [ARAM_NUM_DW -1:0] aarb_fifo_ren;
wire [ARAM_NUM_DW -1:0] aarb_fifo_empty;
wire [ARAM_NUM_DW -1:0] aarb_fifo_full;
reg  [ARAM_NUM_DW -1:0][AARB_BUF_DW -1:0] aarb_fifo_din;
wire [ARAM_NUM_DW -1:0][AARB_BUF_DW -1:0] aarb_fifo_out;
reg  [ARAM_NUM_DW -1:0][AARB_BUF_DW -1:0] abuf_add_gnt_arb;
reg  [ARAM_NUM_DW -1:0][AARB_BUF_DW -1:0] abuf_add_gnt_idx;
CPM_FIFO #( .DATA_WIDTH( AARB_BUF_DW ), .ADDR_WIDTH( AARB_BUF_AW ) ) AARB_FIFO_U[ARAM_NUM_DW-1:0]( clk, rst_n, 1'd0, aarb_fifo_wen, aarb_fifo_ren, aarb_fifo_din, aarb_fifo_out, aarb_fifo_empty, aarb_fifo_full, );

//=====================================================================================================================
// IO Logic Design :
//=====================================================================================================================
genvar gen_i, gen_j;
generate
    for( gen_i=0 ; gen_i < ARAM_NUM_DW; gen_i = gen_i+1 ) begin : RAM_DAT
        always @ ( * )begin
            aram_dat_vld[gen_i] = abuf_add_gnt_arb[gen_i] && ~aarb_fifo_empty[gen_i];
            aram_dat_lst[gen_i] = aarb_dat_lst[ abuf_add_gnt_idx[gen_i] ];
            aram_dat_dat[gen_i] = aarb_dat_dat[ abuf_add_gnt_idx[gen_i] ];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ARAM_NUM_DW; gen_i = gen_i+1 ) begin : ARB_DAT
        always @ ( * )begin
            aarb_add_vld[gen_i] = aram_add_gnt_arb[gen_i];
            aarb_add_lst[gen_i] = aram_add_lst[ aram_add_gnt_idx[gen_i] ];
            aarb_add_add[gen_i] = aram_add_add[ aram_add_gnt_idx[gen_i] ];
        end
    end
endgenerate
//=====================================================================================================================
// Logic Design :
//=====================================================================================================================
generate
    for( gen_i=0 ; gen_i < ARAM_NUM_DW; gen_i = gen_i+1 ) begin : BUF_DIN
        always @ ( * )begin
            aarb_fifo_din[gen_i] ={aram_add_gnt_arb[gen_i], aram_add_gnt_idx[gen_i]};
            aarb_fifo_wen[gen_i] = aram_add_ena[gen_i];
            aarb_fifo_ren[gen_i] = aram_dat_ena[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ARAM_NUM_DW; gen_i = gen_i+1 ) begin : BUF_OUT
        always @ ( * )begin
            abuf_add_gnt_arb[gen_i] = aarb_fifo_out[gen_i][AARB_BUF_DW  -1];
            abuf_add_gnt_idx[gen_i] = aarb_fifo_out[gen_i][0 +:ARAM_NUM_AW];
        end
    end
endgenerate

//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================

//=====================================================================================================================
// FSM :
//=====================================================================================================================

`ifdef ASSERT_ON

`endif
endmodule
