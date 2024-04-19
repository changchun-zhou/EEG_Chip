//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description : EEG_TOP
//========================================================
module EEG_TOP #(
    parameter CHIP_DAT_DW = 8,
    parameter CHIP_OUT_DW = 8
  )(
    input                       CLK_PAD,
    input                       RST_N_PAD,

    input                       CHIP_DAT_VLD_PAD,
    input                       CHIP_DAT_LST_PAD,
    output                      CHIP_DAT_RDY_PAD,
    input  [CHIP_DAT_DW   -1:0] CHIP_DAT_DAT_PAD,
    input                       CHIP_DAT_CMD_PAD,

    output                      CHIP_OUT_VLD_PAD,
    output                      CHIP_OUT_LST_PAD,
    input                       CHIP_OUT_RDY_PAD,
    output [CHIP_OUT_DW   -1:0] CHIP_OUT_DAT_PAD
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
integer i;
genvar gen_i, gen_j;
//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
wire clk_pad = CLK_PAD;
wire rst_n_pad = RST_N_PAD;

//DAT_IO
wire                      chip_dat_vld_pad = CHIP_DAT_VLD_PAD;
wire                      chip_dat_lst_pad = CHIP_DAT_LST_PAD;
wire                      chip_dat_rdy_pad;
wire [CHIP_DAT_DW   -1:0] chip_dat_dat_pad = CHIP_DAT_DAT_PAD;
wire                      chip_dat_cmd_pad = CHIP_DAT_CMD_PAD;

assign CHIP_DAT_RDY_PAD = chip_dat_rdy_pad;
//OUT_IO
wire                      chip_out_vld_pad;
wire                      chip_out_lst_pad;
wire                      chip_out_rdy_pad = CHIP_OUT_RDY_PAD;
wire [CHIP_OUT_DW   -1:0] chip_out_dat_pad;

assign CHIP_OUT_VLD_PAD = chip_out_vld_pad;
assign CHIP_OUT_LST_PAD = chip_out_lst_pad;
assign CHIP_OUT_DAT_PAD = chip_out_dat_pad;
//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================
wire clk;
wire rst_n;
//ACC_DAT_IO
wire                      chip_dat_vld;
wire                      chip_dat_lst;
wire                      chip_dat_rdy;
wire [CHIP_DAT_DW   -1:0] chip_dat_dat;
wire                      chip_dat_cmd;

//ACC_OUT_IO
wire                      chip_out_vld;
wire                      chip_out_lst;
wire                      chip_out_rdy;
wire [CHIP_OUT_DW   -1:0] chip_out_dat;

//=====================================================================================================================
// IO Logic Design :
//=====================================================================================================================
localparam IPAD = 1'b1;
localparam OPAD = 1'b0;

    PDUW0408CDG CHIP_CLK_PAD_U    (.PE(1'd0), .IE(IPAD), .C(clk                ), .PAD(clk_pad                ), .DS(1'b1), .I(1'b0               ), .OEN(IPAD));
    PDUW0408CDG CHIP_RST_PAD_U    (.PE(1'd0), .IE(IPAD), .C(rst_n              ), .PAD(rst_n_pad              ), .DS(1'b1), .I(1'b0               ), .OEN(IPAD));

    PDUW0408CDG CHIP_DAT_VLD_PAD_U(.PE(1'd0), .IE(IPAD), .C(chip_dat_vld       ), .PAD(chip_dat_vld_pad       ), .DS(1'b1), .I(1'b0               ), .OEN(IPAD));
    PDUW0408CDG CHIP_DAT_LST_PAD_U(.PE(1'd0), .IE(IPAD), .C(chip_dat_lst       ), .PAD(chip_dat_lst_pad       ), .DS(1'b1), .I(1'b0               ), .OEN(IPAD));
    PDUW0408CDG CHIP_DAT_CMD_PAD_U(.PE(1'd0), .IE(IPAD), .C(chip_dat_cmd       ), .PAD(chip_dat_cmd_pad       ), .DS(1'b1), .I(1'b0               ), .OEN(IPAD));
    PDUW0408CDG CHIP_OUT_RDY_PAD_U(.PE(1'd0), .IE(IPAD), .C(chip_out_rdy       ), .PAD(chip_out_rdy_pad       ), .DS(1'b1), .I(1'b0               ), .OEN(IPAD));

generate for( gen_i=0 ; gen_i < CHIP_DAT_DW; gen_i = gen_i+1 )begin
    PDUW0408CDG CHIP_DAT_VLD_PAD_U(.PE(1'd0), .IE(IPAD), .C(chip_dat_dat[gen_i]), .PAD(chip_dat_dat_pad[gen_i]), .DS(1'b1), .I(1'b0               ), .OEN(IPAD));
end
endgenerate

    PDUW0408CDG CHIP_DAT_RDY_PAD_U(.PE(1'd0), .IE(OPAD), .C(                   ), .PAD(chip_dat_rdy_pad       ), .DS(1'b1), .I(chip_dat_rdy       ), .OEN(OPAD));
    PDUW0408CDG CHIP_OUT_VLD_PAD_U(.PE(1'd0), .IE(OPAD), .C(                   ), .PAD(chip_out_vld_pad       ), .DS(1'b1), .I(chip_out_vld       ), .OEN(OPAD));
    PDUW0408CDG CHIP_OUT_LST_PAD_U(.PE(1'd0), .IE(OPAD), .C(                   ), .PAD(chip_out_lst_pad       ), .DS(1'b1), .I(chip_out_lst       ), .OEN(OPAD));

generate for( gen_i=0 ; gen_i < CHIP_OUT_DW; gen_i = gen_i+1 )begin
    PDUW0408CDG CHIP_OUT_DAT_PAD_U(.PE(1'd0), .IE(OPAD), .C(                   ), .PAD(chip_out_dat_pad[gen_i]), .DS(1'b1), .I(chip_out_dat[gen_i]), .OEN(OPAD));
end
endgenerate

//=====================================================================================================================
// Logic Design :
//=====================================================================================================================

//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================
EEG_ACC #(
    .CHIP_DAT_DW          ( CHIP_DAT_DW      ),
    .CHIP_OUT_DW          ( CHIP_OUT_DW      )
) EEG_ACC_U(
    .clk                  ( clk              ),
    .rst_n                ( rst_n            ),

    .CHIP_DAT_VLD         ( chip_dat_vld     ),
    .CHIP_DAT_LST         ( chip_dat_lst     ),
    .CHIP_DAT_RDY         ( chip_dat_rdy     ),
    .CHIP_DAT_DAT         ( chip_dat_dat     ),
    .CHIP_DAT_CMD         ( chip_dat_cmd     ),
                                             
    .CHIP_OUT_VLD         ( chip_out_vld     ),
    .CHIP_OUT_LST         ( chip_out_lst     ),
    .CHIP_OUT_RDY         ( chip_out_rdy     ),
    .CHIP_OUT_DAT         ( chip_out_dat     )
);
//=====================================================================================================================
// FSM :
//=====================================================================================================================


`ifdef ASSERT_ON


`endif
endmodule
