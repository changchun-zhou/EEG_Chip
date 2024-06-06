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
`ifndef top
  `define top

`include "../../tb/TEST.sv"
`include "../../tb/EEG_DUMP.sv"

module top;

  bit                      clk;
  bit                      rst_n;

  bit                      CLK_PAD;
  bit                      RST_N_PAD;

  bit                      CHIP_DAT_VLD_PAD;
  bit                      CHIP_DAT_LST_PAD;
  bit                      CHIP_DAT_RDY_PAD;
  bit [`CHIP_DAT_DW  -1:0] CHIP_DAT_DAT_PAD;
  bit                      CHIP_DAT_CMD_PAD;

  bit                      CHIP_OUT_VLD_PAD;
  bit                      CHIP_OUT_LST_PAD;
  bit                      CHIP_OUT_RDY_PAD;
  bit [`CHIP_OUT_DW  -1:0] CHIP_OUT_DAT_PAD;



  bit DumpStart;
  bit DumpEnd;
  int frame_cnt = 0;
  int layer_cnt = 0;
  event frame_start;
  event layer_start;

  // System Clock and Reset
  initial begin
    clk <= 'd1;
  end
  always #`CLK_PERIOD_HALF clk = ~clk;
  
  EEG_IF eeg_if(clk);
  `ifdef DUMP_EN
    EEG_DUMP EEG_DUMP_U(clk, rst_n, DumpStart, DumpEnd);
  `endif
  TEST TEST_U(clk, eeg_if);
  
  //DUT
  EEG_TOP
  //EEG_ACC #(
  //  .CHIP_DAT_DW ( `CHIP_DAT_DW ),
  //  .CHIP_DAT_DW ( `CHIP_DAT_DW )
  //) 
  EEG_TOP_U (
  
  .*
);

always @ ( * ) begin
  RST_N_PAD = rst_n;
end

always @ ( * ) begin
  CLK_PAD = clk;
end

always @ ( CHIP_DAT_RDY_PAD or clk ) begin
  eeg_if.DUT.chip_dat_rdy = CHIP_DAT_RDY_PAD;
end
//OUT
always @ ( CHIP_OUT_VLD_PAD or clk ) begin
  eeg_if.DUT.chip_out_vld = CHIP_OUT_VLD_PAD;
end
always @ ( CHIP_OUT_LST_PAD or clk ) begin
  eeg_if.DUT.chip_out_lst = CHIP_OUT_LST_PAD;
end
always @ ( CHIP_OUT_DAT_PAD or clk ) begin
  eeg_if.DUT.chip_out_dat = CHIP_OUT_DAT_PAD;
end

always @ ( * )begin
    CHIP_DAT_VLD_PAD = eeg_if.DUT.chip_dat_vld;
end
always @ ( * )begin
    CHIP_DAT_LST_PAD = eeg_if.DUT.chip_dat_lst;
end
always @ ( * )begin
    CHIP_DAT_DAT_PAD = eeg_if.DUT.chip_dat_dat;
end
always @ ( * )begin
    CHIP_DAT_CMD_PAD = eeg_if.DUT.chip_dat_cmd;
end
always @ ( * )begin
    CHIP_OUT_RDY_PAD = eeg_if.DUT.chip_out_rdy;
end

endmodule

`endif
