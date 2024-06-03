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

    input                       PAD_DAT_VLD,
    input                       PAD_DAT_LST,
    output                      PAD_DAT_RDY,
    input  [CHIP_DAT_DW   -1:0] PAD_DAT_DAT,
    input                       PAD_DAT_CMD,

    output                      ACC_DAT_VLD,
    output                      ACC_DAT_LST,
    input                       ACC_DAT_RDY,
    output [CHIP_DAT_DW   -1:0] ACC_DAT_DAT,
    output                      ACC_DAT_CMD,

    input                       ACC_OUT_VLD,
    input                       ACC_OUT_LST,
    output                      ACC_OUT_RDY,
    input  [CHIP_OUT_DW   -1:0] ACC_OUT_DAT,

    output                      PAD_OUT_VLD,
    output                      PAD_OUT_LST,
    input                       PAD_OUT_RDY,
    output [CHIP_OUT_DW   -1:0] PAD_OUT_DAT
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
localparam ODAT_BUF_DW = CHIP_DAT_DW +1+1;
localparam ODAT_BUF_AW = 1;
localparam OOUT_BUF_DW = CHIP_OUT_DW +1;
localparam OOUT_BUF_AW = 2;

integer i;
genvar gen_i, gen_j;
//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
//PAD_DAT_IO
wire                      pad_dat_vld = PAD_DAT_VLD;
wire                      pad_dat_lst = PAD_DAT_LST;
reg                       pad_dat_rdy;
wire [CHIP_DAT_DW   -1:0] pad_dat_dat = PAD_DAT_DAT;
wire                      pad_dat_cmd = PAD_DAT_CMD;
assign PAD_DAT_RDY = pad_dat_rdy;

wire pad_dat_ena = pad_dat_vld && pad_dat_rdy;

//ACC_DAT_IO
reg                       acc_dat_vld;
reg                       acc_dat_lst;
wire                      acc_dat_rdy = ACC_DAT_RDY;
reg  [CHIP_DAT_DW   -1:0] acc_dat_dat;
reg                       acc_dat_cmd;
assign ACC_DAT_VLD = acc_dat_vld;
assign ACC_DAT_LST = acc_dat_lst;
assign ACC_DAT_DAT = acc_dat_dat;
assign ACC_DAT_CMD = acc_dat_cmd;

wire acc_dat_ena = acc_dat_vld && acc_dat_rdy;

//PAD_OUT_IO
reg                       pad_out_vld;
reg                       pad_out_lst;
wire                      pad_out_rdy = PAD_OUT_RDY;
reg  [CHIP_OUT_DW   -1:0] pad_out_dat;
assign PAD_OUT_VLD = pad_out_vld;
assign PAD_OUT_LST = pad_out_lst;
assign PAD_OUT_DAT = pad_out_dat;

wire pad_out_ena = pad_out_vld && pad_out_rdy;

//ACC_OUT_IO
wire                      acc_out_vld = ACC_OUT_VLD;
wire                      acc_out_lst = ACC_OUT_LST;
reg                       acc_out_rdy;
wire [CHIP_OUT_DW   -1:0] acc_out_dat = ACC_OUT_DAT;
assign ACC_OUT_RDY = acc_out_rdy;

wire acc_out_ena = acc_out_vld && acc_out_rdy;
//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================
wire odat_fifo_wen = pad_dat_ena;
wire odat_fifo_ren = acc_dat_ena;
wire odat_fifo_empty;
wire odat_fifo_full;
wire [ODAT_BUF_DW -1:0] odat_fifo_din = {pad_dat_lst, pad_dat_cmd, pad_dat_dat};
wire [ODAT_BUF_DW -1:0] odat_fifo_out;
wire [ODAT_BUF_AW   :0] odat_fifo_cnt;
CPM_FIFO #( .DATA_WIDTH( ODAT_BUF_DW ), .ADDR_WIDTH( ODAT_BUF_AW ) ) ODAT_FIFO_U( clk, rst_n, 1'd0, odat_fifo_wen, odat_fifo_ren, odat_fifo_din, odat_fifo_out, odat_fifo_empty, odat_fifo_full, odat_fifo_cnt);

wire oout_fifo_wen = acc_out_ena;
wire oout_fifo_ren = pad_out_ena;
wire oout_fifo_empty;
wire oout_fifo_full;
wire [OOUT_BUF_DW -1:0] oout_fifo_din = {acc_out_lst, acc_out_dat};
wire [OOUT_BUF_DW -1:0] oout_fifo_out;
wire [OOUT_BUF_AW   :0] oout_fifo_cnt;
CPM_FIFO #( .DATA_WIDTH( OOUT_BUF_DW ), .ADDR_WIDTH( OOUT_BUF_AW ) ) OOUT_FIFO_U( clk, rst_n, 1'd0, oout_fifo_wen, oout_fifo_ren, oout_fifo_din, oout_fifo_out, oout_fifo_empty, oout_fifo_full, oout_fifo_cnt);
//=====================================================================================================================
// IO Logic Design :
//=====================================================================================================================
always @ ( * )begin
    pad_dat_rdy = ~odat_fifo_full;
end

always @ ( * )begin
    acc_out_rdy = ~oout_fifo_full;
end

always @ ( * )begin
    acc_dat_vld = ~odat_fifo_empty;
end

always @ ( * )begin
    pad_out_vld = ~oout_fifo_empty;
end

always @ ( * )begin
    acc_dat_dat = odat_fifo_out[0 +:CHIP_DAT_DW];
    acc_dat_cmd = odat_fifo_out[CHIP_DAT_DW +:1];
    acc_dat_lst = odat_fifo_out[CHIP_DAT_DW +1 +:1];
end

always @ ( * )begin
    pad_out_dat = oout_fifo_out[0 +:CHIP_OUT_DW];
    pad_out_lst = oout_fifo_out[CHIP_OUT_DW +:1];
end
//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================

//=====================================================================================================================
// FSM :
//=====================================================================================================================


`ifdef ASSERT_ON


`endif
endmodule
