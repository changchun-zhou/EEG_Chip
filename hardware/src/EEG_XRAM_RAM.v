//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description : ARAM/WRAM/FRAM RAM
//========================================================
module EEG_XRAM_RAM #(
    parameter XRAM_NUM_DW =  4,
    parameter XRAM_ADD_AW = 12,//4k
    parameter XRAM_DAT_DW =  8
  )(
    input                                          clk,
    input                                          rst_n,

    input  [XRAM_NUM_DW -1:0]                      XRAM_DIN_VLD,
    output [XRAM_NUM_DW -1:0]                      XRAM_DIN_RDY,
    input  [XRAM_NUM_DW -1:0][XRAM_ADD_AW    -1:0] XRAM_DIN_ADD,
    input  [XRAM_NUM_DW -1:0][XRAM_DAT_DW    -1:0] XRAM_DIN_DAT,

    input  [XRAM_NUM_DW -1:0]                      XRAM_ADD_VLD,
    input  [XRAM_NUM_DW -1:0]                      XRAM_ADD_LST,
    output [XRAM_NUM_DW -1:0]                      XRAM_ADD_RDY,
    input  [XRAM_NUM_DW -1:0][XRAM_ADD_AW    -1:0] XRAM_ADD_ADD,
    output [XRAM_NUM_DW -1:0]                      XRAM_DAT_VLD,
    output [XRAM_NUM_DW -1:0]                      XRAM_DAT_LST,
    input  [XRAM_NUM_DW -1:0]                      XRAM_DAT_RDY,
    output [XRAM_NUM_DW -1:0][XRAM_DAT_DW    -1:0] XRAM_DAT_DAT
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
localparam XRAM_ADD_DW = 1<<XRAM_ADD_AW;

integer i;
genvar gen_i, gen_j;
//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
//XRAM_IO
wire [XRAM_NUM_DW -1:0]                      xram_din_vld= XRAM_DIN_VLD;
reg  [XRAM_NUM_DW -1:0]                      xram_din_rdy;
wire [XRAM_NUM_DW -1:0][XRAM_ADD_AW    -1:0] xram_din_add= XRAM_DIN_ADD;
wire [XRAM_NUM_DW -1:0][XRAM_DAT_DW    -1:0] xram_din_dat= XRAM_DIN_DAT;

wire [XRAM_NUM_DW -1:0]                      xram_add_vld= XRAM_ADD_VLD;
wire [XRAM_NUM_DW -1:0]                      xram_add_lst= XRAM_ADD_LST;
reg  [XRAM_NUM_DW -1:0]                      xram_add_rdy;
wire [XRAM_NUM_DW -1:0][XRAM_ADD_AW    -1:0] xram_add_add= XRAM_ADD_ADD;
wire [XRAM_NUM_DW -1:0]                      xram_dat_vld;
wire [XRAM_NUM_DW -1:0]                      xram_dat_lst;
wire [XRAM_NUM_DW -1:0]                      xram_dat_rdy= XRAM_DAT_RDY;
reg  [XRAM_NUM_DW -1:0][XRAM_DAT_DW    -1:0] xram_dat_dat;

wire [XRAM_NUM_DW -1:0]                      xram_add_ena= xram_add_vld & xram_add_rdy;
wire [XRAM_NUM_DW -1:0]                      xram_dat_ena= xram_dat_vld & xram_dat_rdy;

assign XRAM_DIN_RDY = xram_din_rdy;
assign XRAM_ADD_RDY = xram_add_rdy;
assign XRAM_DAT_VLD = xram_dat_vld;
assign XRAM_DAT_LST = xram_dat_lst;
assign XRAM_DAT_DAT = xram_dat_dat;

//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================

//RAM
reg  [XRAM_NUM_DW -1:0]                   xram_ram_wena;
reg  [XRAM_NUM_DW -1:0]                   xram_ram_rena;
reg  [XRAM_NUM_DW -1:0][XRAM_ADD_AW -1:0] xram_ram_wadd;
reg  [XRAM_NUM_DW -1:0][XRAM_ADD_AW -1:0] xram_ram_radd;
reg  [XRAM_NUM_DW -1:0][XRAM_DAT_DW -1:0] xram_ram_data;
wire [XRAM_NUM_DW -1:0][XRAM_DAT_DW -1:0] xram_ram_dout;
//=====================================================================================================================
// IO Logic Design :
//=====================================================================================================================
generate
    for( gen_i=0 ; gen_i < XRAM_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            xram_dat_dat[gen_i] = xram_ram_dout[gen_i];
            xram_add_rdy[gen_i] = xram_dat_rdy[gen_i] || ~xram_dat_vld[gen_i];
            xram_din_rdy[gen_i] = 'd1;
        end
    end
endgenerate
//=====================================================================================================================
// Logic Design :
//=====================================================================================================================
generate
    for( gen_i=0 ; gen_i < XRAM_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            xram_ram_wena[gen_i] = xram_din_vld[gen_i] && xram_din_rdy[gen_i];
            xram_ram_wadd[gen_i] = xram_din_add[gen_i];
            xram_ram_data[gen_i] = xram_din_dat[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < XRAM_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            xram_ram_rena[gen_i] = xram_add_vld[gen_i] && xram_add_rdy[gen_i];
            xram_ram_radd[gen_i] = xram_add_add[gen_i];
        end
    end
endgenerate

//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================
CPM_REG_E #( 1 ) XRAM_DAT_VLD_REG [XRAM_NUM_DW-1:0]( clk, rst_n, xram_add_rdy, xram_add_vld, xram_dat_vld );
CPM_REG_E #( 1 ) XRAM_DAT_LST_REG [XRAM_NUM_DW-1:0]( clk, rst_n, xram_add_rdy, xram_add_lst, xram_dat_lst );

RAM #( .SRAM_WORD( XRAM_ADD_DW ), .SRAM_BIT( XRAM_DAT_DW ), .SRAM_BYTE(1)) XRAM_U [XRAM_NUM_DW-1:0] ( clk, rst_n, xram_ram_radd, xram_ram_wadd, xram_ram_rena, xram_ram_wena, xram_ram_data, xram_ram_dout);

`ifdef ASSERT_ON

//property xram_rdy_check(dat_vld, dat_rdy);
//@(posedge clk)
//disable iff(rst_n!=1'b1)
//    dat_vld |-> ( dat_rdy );
//endproperty
//
//generate
//  for( gen_i=0 ; gen_i < XRAM_NUM_DW; gen_i = gen_i+1 ) begin : ASSERT_BLOCK
//
//    assert property ( xram_rdy_check(xram_dat_vld[gen_i], xram_dat_rdy[gen_i]) );
//
//  end
//endgenerate

property xram_dat_check(dat_vld, dat_rdy, dat_dat);
@(posedge clk)
disable iff(rst_n!=1'b1)
    dat_vld && dat_rdy |-> ( |dat_dat inside {0, 1} );
endproperty

generate
  for( gen_i=0 ; gen_i < XRAM_NUM_DW; gen_i = gen_i+1 )begin

    assert property ( xram_dat_check(xram_dat_vld[gen_i], xram_dat_rdy[gen_i], xram_dat_dat[gen_i]) );

  end
endgenerate

`endif
endmodule
