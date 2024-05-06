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
module CPM_CLP #(
    parameter DW = 12,
    parameter OW =  8
) (
    input  signed [DW -1:0] RAW_DAT,
    output signed [OW -1:0] CLP_DAT
);

wire signed [DW -1:0] raw_dat = RAW_DAT;
wire signed [OW -1:0] clp_dat;

assign CLP_DAT = clp_dat;

wire signed [DW -1:0] raw_dat_min = {{(DW-OW+1){1'd1}}, {(OW-1){1'd0}}};
wire signed [DW -1:0] raw_dat_max = {{(DW-OW+1){1'd0}}, {(OW-1){1'd1}}};
assign clp_dat = raw_dat<raw_dat_min ? {1'd1, {(OW-1){1'd0}}} : (raw_dat>raw_dat_max ? {1'd0, {(OW-1){1'd1}}} : raw_dat[0 +:OW]);

endmodule
