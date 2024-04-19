//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description : EEG_OBUF
//========================================================
module EEG_OBUF #(
    parameter CHIP_DAT_DW = 8,
    parameter CHIP_OUT_DW = 8
  )(
    input                       clk,
    input                       rst_n,

    input                       ACC_DAT_RDY,
    input                       ACC_OUT_VLD,
    input                       ACC_OUT_LST,
    input  [CHIP_OUT_DW   -1:0] ACC_OUT_DAT,

    output                      BUF_DAT_RDY,
    output                      BUF_OUT_VLD,
    output                      BUF_OUT_LST,
    output [CHIP_OUT_DW   -1:0] BUF_OUT_DAT
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
integer i;
genvar gen_i, gen_j;
//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
//ACC_IO
wire                      acc_dat_rdy = ACC_DAT_RDY;
wire                      acc_out_vld = ACC_OUT_VLD;
wire                      acc_out_lst = ACC_OUT_LST;
wire [CHIP_OUT_DW   -1:0] acc_out_dat = ACC_OUT_DAT;
//BUF_IO
wire                      buf_dat_rdy;
wire                      buf_out_vld;
wire                      buf_out_lst;
wire [CHIP_OUT_DW   -1:0] buf_out_dat;

assign BUF_DAT_RDY = buf_dat_rdy;
assign BUF_OUT_VLD = buf_out_vld;
assign BUF_OUT_LST = buf_out_lst;
assign BUF_OUT_DAT = buf_out_dat;
//=====================================================================================================================
// IO Logic Design :
//=====================================================================================================================

//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================
CPM_REG #( 1           ) BUF_DAT_RDY_REG ( clk, rst_n, acc_dat_rdy, buf_dat_rdy);
CPM_REG #( 1           ) BUF_OUT_VLD_REG ( clk, rst_n, acc_out_vld, buf_out_vld);
CPM_REG #( 1           ) BUF_OUT_LST_REG ( clk, rst_n, acc_out_lst, buf_out_lst);
CPM_REG #( CHIP_OUT_DW ) BUF_OUT_DAT_REG ( clk, rst_n, acc_out_dat, buf_out_dat);
//=====================================================================================================================
// FSM :
//=====================================================================================================================


`ifdef ASSERT_ON


`endif
endmodule
