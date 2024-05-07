//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description :
//========================================================
`ifndef EEG_IF
  `define EEG_IF

`include "../../tb/DEFINE.sv"

interface EEG_IF(input bit clk);

    logic                         chip_dat_vld;
    logic                         chip_dat_lst;
    logic                         chip_dat_rdy;
    logic  [`CHIP_DAT_DW   -1:0]  chip_dat_dat;
    logic                         chip_dat_cmd;

    logic                         chip_out_vld;
    logic                         chip_out_lst;
    logic                         chip_out_rdy;
    logic  [`CHIP_OUT_DW   -1:0]  chip_out_dat;

  clocking txcb_dat @(posedge clk);
    output chip_dat_vld, chip_dat_lst, chip_dat_dat, chip_dat_cmd;
    input  chip_dat_rdy;
  endclocking:txcb_dat

  clocking txcb_out @(posedge clk);
    output chip_out_rdy;
    input  chip_out_vld, chip_out_lst, chip_out_dat;
  endclocking:txcb_out

  modport DUT( output chip_dat_rdy, chip_out_vld, chip_out_lst, chip_out_dat,
                input chip_out_rdy, chip_dat_vld, chip_dat_lst, chip_dat_dat, chip_dat_cmd );
  modport TB(clocking txcb_dat, txcb_out);

endinterface: EEG_IF

typedef virtual EEG_IF    vEEG_IF;
typedef virtual EEG_IF.TB vEEG_TB;
`endif
