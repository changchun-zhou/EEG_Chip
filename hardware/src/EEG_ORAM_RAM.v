//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description : ORAM RAM
//========================================================
module EEG_ORAM_RAM #(
    parameter ORAM_NUM_DW =  4,
    parameter OMUX_NUM_DW =  4,
    parameter OMUX_ADD_AW =  8,
    parameter ORAM_DAT_DW =  8
  )(
    input                                                            clk,
    input                                                            rst_n,

    input  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                      ORAM_DIN_VLD,
    output [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                      ORAM_DIN_RDY,
    input  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][OMUX_ADD_AW    -1:0] ORAM_DIN_ADD,
    input  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_DAT_DW    -1:0] ORAM_DIN_DAT,

    input  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                      ORAM_ADD_VLD,
    input  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                      ORAM_ADD_LST,
    output [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                      ORAM_ADD_RDY,
    input  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][OMUX_ADD_AW    -1:0] ORAM_ADD_ADD,
    output [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                      ORAM_DAT_VLD,
    output [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                      ORAM_DAT_LST,
    input  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                      ORAM_DAT_RDY,
    output [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_DAT_DW    -1:0] ORAM_DAT_DAT
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
localparam OMUX_ADD_DW = 1<<OMUX_ADD_AW;

integer i;

//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
//ORAM_IO
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                      oram_din_vld= ORAM_DIN_VLD;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                      oram_din_rdy;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][OMUX_ADD_AW    -1:0] oram_din_add= ORAM_DIN_ADD;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_DAT_DW    -1:0] oram_din_dat= ORAM_DIN_DAT;

wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                      oram_add_vld= ORAM_ADD_VLD;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                      oram_add_lst= ORAM_ADD_LST;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                      oram_add_rdy=~ORAM_DIN_VLD;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][OMUX_ADD_AW    -1:0] oram_add_dat= ORAM_ADD_ADD;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                      oram_dat_vld;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                      oram_dat_lst;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                      oram_dat_rdy= ORAM_DAT_RDY;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_DAT_DW    -1:0] oram_dat_dat;

wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0] oram_din_ena = oram_din_vld & oram_din_rdy;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0] oram_add_ena = oram_add_vld & oram_add_rdy;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0] oram_dat_ena = oram_dat_vld & oram_dat_rdy;

assign ORAM_DIN_RDY = oram_din_rdy;
assign ORAM_ADD_RDY = oram_add_rdy;
assign ORAM_DAT_VLD = oram_dat_vld;
assign ORAM_DAT_LST = oram_dat_lst;
assign ORAM_DAT_DAT = oram_dat_dat;

//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================

//RAM
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   oram_ram_wena;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0]                   oram_ram_rena;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][OMUX_ADD_AW -1:0] oram_ram_wadd;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][OMUX_ADD_AW -1:0] oram_ram_radd;
reg  [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_DAT_DW -1:0] oram_ram_data;
wire [ORAM_NUM_DW -1:0][OMUX_NUM_DW -1:0][ORAM_DAT_DW -1:0] oram_ram_dout;
//=====================================================================================================================
// IO Logic Design :
//=====================================================================================================================
genvar gen_i, gen_j;
generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 ) begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 ) begin
           assign oram_din_rdy[gen_i][gen_j] = 'd1;
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 ) begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 ) begin
            always @ ( * )begin
                oram_dat_dat[gen_i][gen_j] = oram_ram_dout[gen_i][gen_j];
            end

        end
    end
endgenerate
//=====================================================================================================================
// Logic Design :
//=====================================================================================================================
generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 ) begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 ) begin
            always @ ( * )begin
                oram_ram_wena[gen_i][gen_j] = oram_din_ena[gen_i][gen_j];
                oram_ram_rena[gen_i][gen_j] = oram_add_ena[gen_i][gen_j];
                oram_ram_wadd[gen_i][gen_j] = oram_din_add[gen_i][gen_j];
                oram_ram_radd[gen_i][gen_j] = oram_add_dat[gen_i][gen_j];
                oram_ram_data[gen_i][gen_j] = oram_din_dat[gen_i][gen_j];
            end
        end
    end
endgenerate

//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================
CPM_REG_E #( 1 ) ORAM_DAT_VLD_REG [ORAM_NUM_DW*OMUX_NUM_DW -1:0]( clk, rst_n, oram_dat_rdy, oram_add_vld, oram_dat_vld );
CPM_REG_E #( 1 ) ORAM_DAT_LST_REG [ORAM_NUM_DW*OMUX_NUM_DW -1:0]( clk, rst_n, oram_dat_rdy, oram_add_lst, oram_dat_lst );

RAM #( .SRAM_WORD( OMUX_ADD_DW ), .SRAM_BIT( ORAM_DAT_DW ), .SRAM_BYTE(1) ) XRAM_U [ORAM_NUM_DW*OMUX_NUM_DW -1:0] ( clk, rst_n, oram_ram_radd, oram_ram_wadd, oram_ram_rena, oram_ram_wena, oram_ram_data, oram_ram_dout);

`ifdef ASSERT_ON

//property oram_rdy_check(dat_vld, dat_rdy);
//@(posedge clk)
//disable iff(rst_n!=1'b1)
//    dat_vld |-> ( dat_rdy );
//endproperty
//
//generate
//    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 ) begin : ASSERT_BLOCK
//        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 ) begin
//            assert property ( oram_rdy_check(oram_dat_vld[gen_i][gen_j], oram_dat_rdy[gen_i][gen_j]) );
//        end
//    end
//endgenerate

property xram_dat_check(dat_vld, dat_rdy, dat_dat);
@(posedge clk)
disable iff(rst_n!=1'b1)
    dat_vld && dat_rdy |-> ( |dat_dat inside {0, 1} );
endproperty

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < OMUX_NUM_DW; gen_j = gen_j+1 ) begin
            assert property ( xram_dat_check(oram_dat_vld[gen_i][gen_j], oram_dat_rdy[gen_i][gen_j], oram_dat_dat[gen_i][gen_j]) );
        end
    end
endgenerate

`endif
endmodule
