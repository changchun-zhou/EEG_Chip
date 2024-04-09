//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description : ORAM DEMUX 
//========================================================
module EEG_ORAM_DEMUX #(
    parameter ORAM_NUM_DW =  4,
    parameter ORAM_MUX_DW =  4,
    parameter ORAM_ADD_AW = 12,
    parameter ORAM_ADD_MW = 10,
    parameter ORAM_DAT_DW =  4,
    parameter ORAM_NUM_AW = $clog2(ORAM_NUM_DW)
  )(
    input                                                         clk,
    input                                                         rst_n,

    input  [ORAM_NUM_DW -1:0]                                     MUX_MTOO_DAT_VLD,
    input  [ORAM_NUM_DW -1:0]                                     MUX_MTOO_DAT_LST,
    output [ORAM_NUM_DW -1:0]                                     MUX_MTOO_DAT_RDY,
    input  [ORAM_NUM_DW -1:0]                  [ORAM_ADD_AW -1:0] MUX_MTOO_DAT_ADD,
    input  [ORAM_NUM_DW -1:0]                  [ORAM_DAT_DW -1:0] MUX_MTOO_DAT_DAT,

    input  [ORAM_NUM_DW -1:0]                                     MUX_MTOO_ADD_VLD,
    input  [ORAM_NUM_DW -1:0]                                     MUX_MTOO_ADD_LST,
    output [ORAM_NUM_DW -1:0]                                     MUX_MTOO_ADD_RDY,
    input  [ORAM_NUM_DW -1:0]                  [ORAM_ADD_AW -1:0] MUX_MTOO_ADD_ADD,
    output [ORAM_NUM_DW -1:0]                                     MUX_OTOM_DAT_VLD,
    output [ORAM_NUM_DW -1:0]                                     MUX_OTOM_DAT_LST,
    input  [ORAM_NUM_DW -1:0]                                     MUX_OTOM_DAT_RDY,
    output [ORAM_NUM_DW -1:0]                  [ORAM_DAT_DW -1:0] MUX_OTOM_DAT_DAT,

    output [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   DMX_MTOO_DAT_VLD,
    output [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   DMX_MTOO_DAT_LST,
    input  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   DMX_MTOO_DAT_RDY,
    output [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_ADD_MW -1:0] DMX_MTOO_DAT_ADD,
    output [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_DAT_DW -1:0] DMX_MTOO_DAT_DAT,

    output [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   DMX_MTOO_ADD_VLD,
    output [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   DMX_MTOO_ADD_LST,
    input  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   DMX_MTOO_ADD_RDY,
    output [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_ADD_MW -1:0] DMX_MTOO_ADD_ADD,
    input  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   DMX_OTOM_DAT_VLD,
    input  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   DMX_OTOM_DAT_LST,
    output [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                   DMX_OTOM_DAT_RDY,
    input  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_DAT_DW -1:0] DMX_OTOM_DAT_DAT
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
localparam ORAM_MUX_AW = $clog2(ORAM_MUX_DW);

integer i;
genvar gen_i, gen_j;
//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
//MUX_IO
wire  [ORAM_NUM_DW -1:0]                                        mux_mtoo_dat_vld = MUX_MTOO_DAT_VLD;
wire  [ORAM_NUM_DW -1:0]                                        mux_mtoo_dat_lst = MUX_MTOO_DAT_LST;
reg   [ORAM_NUM_DW -1:0]                                        mux_mtoo_dat_rdy;
wire  [ORAM_NUM_DW -1:0]                  [ORAM_ADD_AW    -1:0] mux_mtoo_dat_add = MUX_MTOO_DAT_ADD;
wire  [ORAM_NUM_DW -1:0]                  [ORAM_DAT_DW    -1:0] mux_mtoo_dat_dat = MUX_MTOO_DAT_DAT;

wire  [ORAM_NUM_DW -1:0]                                        mux_mtoo_add_vld = MUX_MTOO_ADD_VLD;
wire  [ORAM_NUM_DW -1:0]                                        mux_mtoo_add_lst = MUX_MTOO_ADD_LST;
reg   [ORAM_NUM_DW -1:0]                                        mux_mtoo_add_rdy;
wire  [ORAM_NUM_DW -1:0]                  [ORAM_ADD_AW    -1:0] mux_mtoo_add_add = MUX_MTOO_ADD_ADD;
reg   [ORAM_NUM_DW -1:0]                                        mux_otom_dat_vld;
reg   [ORAM_NUM_DW -1:0]                                        mux_otom_dat_lst;
wire  [ORAM_NUM_DW -1:0]                                        mux_otom_dat_rdy = MUX_OTOM_DAT_RDY;
reg   [ORAM_NUM_DW -1:0]                  [ORAM_DAT_DW    -1:0] mux_otom_dat_dat;

assign MUX_MTOO_DAT_RDY = mux_mtoo_dat_rdy;
assign MUX_MTOO_ADD_RDY = mux_mtoo_add_rdy;
assign MUX_OTOM_DAT_VLD = mux_otom_dat_vld;
assign MUX_OTOM_DAT_LST = mux_otom_dat_lst;
assign MUX_OTOM_DAT_DAT = mux_otom_dat_dat;
//DEMUX_IO
reg   [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                      dmx_mtoo_dat_vld;
reg   [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                      dmx_mtoo_dat_lst;
wire  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                      dmx_mtoo_dat_rdy = DMX_MTOO_DAT_RDY;
reg   [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_ADD_MW    -1:0] dmx_mtoo_dat_add;
reg   [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_DAT_DW    -1:0] dmx_mtoo_dat_dat;

reg   [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                      dmx_mtoo_add_vld;
reg   [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                      dmx_mtoo_add_lst;
wire  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                      dmx_mtoo_add_rdy = DMX_MTOO_ADD_RDY;
reg   [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_ADD_MW    -1:0] dmx_mtoo_add_add;
wire  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                      dmx_otom_dat_vld = DMX_OTOM_DAT_VLD;
wire  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                      dmx_otom_dat_lst = DMX_OTOM_DAT_LST;
reg   [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0]                      dmx_otom_dat_rdy;
wire  [ORAM_NUM_DW -1:0][ORAM_MUX_DW -1:0][ORAM_DAT_DW    -1:0] dmx_otom_dat_dat = DMX_OTOM_DAT_DAT;

assign DMX_MTOO_DAT_VLD = dmx_mtoo_dat_vld;
assign DMX_MTOO_DAT_LST = dmx_mtoo_dat_lst;
assign DMX_MTOO_DAT_ADD = dmx_mtoo_dat_add;
assign DMX_MTOO_DAT_DAT = dmx_mtoo_dat_dat;

assign DMX_MTOO_ADD_VLD = dmx_mtoo_add_vld;
assign DMX_MTOO_ADD_LST = dmx_mtoo_add_lst;
assign DMX_MTOO_ADD_ADD = dmx_mtoo_add_add;
assign DMX_OTOM_DAT_RDY = dmx_otom_dat_rdy;
//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================
wire [ORAM_NUM_DW -1:0][ORAM_MUX_AW -1:0] dmx_otom_dat_sel;

CPM_SEL #( ORAM_MUX_DW, ORAM_MUX_AW ) DMX_SEL [ORAM_NUM_DW-1:0]( dmx_otom_dat_vld, dmx_otom_dat_sel );
//=====================================================================================================================
// IO Logic Design :
//=====================================================================================================================
generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            mux_mtoo_dat_rdy[gen_i] = &dmx_mtoo_dat_rdy[gen_i];
            mux_mtoo_add_rdy[gen_i] = &dmx_mtoo_add_rdy[gen_i];
            mux_otom_dat_vld[gen_i] = |dmx_otom_dat_vld[gen_i];//no collision
            mux_otom_dat_dat[gen_i] =  dmx_otom_dat_dat[dmx_otom_dat_sel[gen_i]];
            mux_otom_dat_lst[gen_i] = |dmx_otom_dat_lst[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < ORAM_MUX_DW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                dmx_mtoo_dat_vld[gen_i][gen_j] = mux_mtoo_dat_vld[gen_i] && (mux_mtoo_dat_add[gen_i][ORAM_ADD_AW-1 -:2]==gen_j);
                dmx_mtoo_dat_lst[gen_i][gen_j] = mux_mtoo_dat_lst[gen_i];
                dmx_mtoo_dat_add[gen_i][gen_j] = mux_mtoo_dat_add[gen_i][0 +:ORAM_ADD_MW];
                dmx_mtoo_dat_dat[gen_i][gen_j] = mux_mtoo_dat_dat[gen_i];
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        for( gen_j=0 ; gen_j < ORAM_MUX_DW; gen_j = gen_j+1 )begin
            always @ ( * )begin
                dmx_mtoo_add_vld[gen_i][gen_j] = mux_mtoo_add_vld[gen_i] && mux_mtoo_add_add[gen_i][ORAM_ADD_AW-1 -:2] == gen_j;
                dmx_mtoo_add_lst[gen_i][gen_j] = mux_mtoo_add_lst[gen_i];
                dmx_mtoo_add_add[gen_i][gen_j] = mux_mtoo_add_add[gen_i][0 +:ORAM_ADD_MW];
                dmx_otom_dat_rdy[gen_i][gen_j] = mux_otom_dat_rdy[gen_i];
            end
        end
    end
endgenerate
//=====================================================================================================================
// Logic Design :
//=====================================================================================================================


//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================


`ifdef ASSERT_ON

property dmx_otom_dat_vld_check(dat_vld);
@(posedge clk)
disable iff(rst_n!=1'b1)
    1 |-> ( &dat_vld==0 );
endproperty

generate
    for( gen_i=0 ; gen_i < ORAM_NUM_DW; gen_i = gen_i+1 )begin
        assert property ( dmx_otom_dat_vld_check(dmx_otom_dat_vld[gen_i]) );
    end
endgenerate

`endif
endmodule
