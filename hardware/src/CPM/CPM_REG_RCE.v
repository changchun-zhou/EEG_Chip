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
module CPM_REG_RCE #(
    parameter DW = 1
) (
    input            Clk   ,
    input            Rstn  ,
    input  [DW -1:0] DataRst,
    input            Clear ,
    input  [DW -1:0] DataClr,
    input            Enable,
    input  [DW -1:0] DataIn,
    output [DW -1:0] DataOut
);
  reg [DW -1:0] data_out;
  assign DataOut = data_out;
  always @ ( posedge Clk or negedge Rstn )begin
    if( ~Rstn )
      data_out <= 0;
    else if( Clear )
      data_out <= DataClr;
    else if( Enable )
      data_out <= DataIn;
  end
endmodule
