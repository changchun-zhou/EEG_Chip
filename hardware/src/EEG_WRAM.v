//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description : WRAM 
//========================================================
module EEG_WRAM #(
    parameter WRAM_CMD_DW =  5,
    parameter WRAM_NUM_DW =  4,
    parameter WRAM_ADD_AW = 13,
    parameter WRAM_DAT_DW =  8,
    parameter WRAM_NUM_AW = $clog2(WRAM_NUM_DW)
  )(
    input                                          clk,
    input                                          rst_n,
    
    output                                         IS_IDLE,
    
    input                                          CFG_INFO_VLD,
    output                                         CFG_INFO_RDY,
    input  [WRAM_CMD_DW                      -1:0] CFG_INFO_CMD,
    input  [WRAM_NUM_DW                      -1:0] CFG_WRAM_IDX,

    input  [WRAM_NUM_DW -1:0]                      ETOW_DAT_VLD,
    input  [WRAM_NUM_DW -1:0]                      ETOW_DAT_LST,
    output [WRAM_NUM_DW -1:0]                      ETOW_DAT_RDY,
    input  [WRAM_NUM_DW -1:0][WRAM_ADD_AW    -1:0] ETOW_DAT_ADD,
    input  [WRAM_NUM_DW -1:0][WRAM_DAT_DW    -1:0] ETOW_DAT_DAT,
    
    input  [WRAM_NUM_DW -1:0]                      ETOW_ADD_VLD,
    input  [WRAM_NUM_DW -1:0]                      ETOW_ADD_LST,
    output [WRAM_NUM_DW -1:0]                      ETOW_ADD_RDY,
    input  [WRAM_NUM_DW -1:0][WRAM_ADD_AW    -1:0] ETOW_ADD_ADD,
    output [WRAM_NUM_DW -1:0]                      WTOE_DAT_VLD,
    output [WRAM_NUM_DW -1:0]                      WTOE_DAT_LST,
    input  [WRAM_NUM_DW -1:0]                      WTOE_DAT_RDY,
    output [WRAM_NUM_DW -1:0][WRAM_DAT_DW    -1:0] WTOE_DAT_DAT
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
integer i;
genvar gen_i, gen_j;

localparam WRAM_STATE = 5;
localparam WRAM_IDLE  = 5'b00001;
localparam WRAM_ITOW  = 5'b00010;
localparam WRAM_CONV  = 5'b00100;
localparam WRAM_ATOW  = 5'b01000;
localparam WRAM_WTOA  = 5'b10000;

reg [WRAM_STATE -1:0] wram_cs;
reg [WRAM_STATE -1:0] wram_ns;

wire wram_idle = wram_cs == WRAM_IDLE;
wire wram_itow = wram_cs == WRAM_ITOW;
wire wram_conv = wram_cs == WRAM_CONV;
wire wram_atow = wram_cs == WRAM_ATOW;
wire wram_wtoa = wram_cs == WRAM_WTOA;
assign IS_IDLE = wram_idle;
wire [WRAM_NUM_DW -1:0] itow_lst_done;
wire [WRAM_NUM_DW -1:0] conv_lst_done;
wire [WRAM_NUM_DW -1:0] atow_lst_done;
wire [WRAM_NUM_DW -1:0] wtoa_lst_done;

wire wram_itow_done = &itow_lst_done;
wire wram_conv_done = &conv_lst_done;
wire wram_atow_done = &atow_lst_done;
wire wram_wtoa_done = &wtoa_lst_done;
//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
//CFG_IO
wire cfg_info_vld = CFG_INFO_VLD;
wire cfg_info_rdy = wram_idle;
reg  [WRAM_CMD_DW  -1:0] cfg_info_cmd;
reg  [WRAM_CMD_DW  -1:0] cfg_wram_idx;

assign CFG_INFO_RDY = cfg_info_rdy;
wire cfg_info_ena = cfg_info_vld & cfg_info_rdy;
//WRAM_DIN
wire [WRAM_NUM_DW -1:0]                   etow_dat_vld = ETOW_DAT_VLD;
wire [WRAM_NUM_DW -1:0]                   etow_dat_lst = ETOW_DAT_LST;
reg  [WRAM_NUM_DW -1:0]                   etow_dat_rdy;
wire [WRAM_NUM_DW -1:0][WRAM_ADD_AW -1:0] etow_dat_add = ETOW_DAT_ADD;
wire [WRAM_NUM_DW -1:0][WRAM_DAT_DW -1:0] etow_dat_dat = ETOW_DAT_DAT;
assign ETOW_DAT_RDY = etow_dat_rdy;

wire [WRAM_NUM_DW -1:0] etow_dat_ena = etow_dat_vld & etow_dat_rdy;
wire [WRAM_NUM_DW -1:0] etow_dat_end = etow_dat_vld & etow_dat_rdy & etow_dat_lst;

//WRAM_OUT
wire [WRAM_NUM_DW -1:0]                   etow_add_vld = ETOW_ADD_VLD;
wire [WRAM_NUM_DW -1:0]                   etow_add_lst = ETOW_ADD_LST;
reg  [WRAM_NUM_DW -1:0]                   etow_add_rdy;
wire [WRAM_NUM_DW -1:0][WRAM_ADD_AW -1:0] etow_add_add = ETOW_ADD_ADD;
reg  [WRAM_NUM_DW -1:0]                   wtoe_dat_vld;
reg  [WRAM_NUM_DW -1:0]                   wtoe_dat_lst;
wire [WRAM_NUM_DW -1:0]                   wtoe_dat_rdy = WTOE_DAT_RDY;
reg  [WRAM_NUM_DW -1:0][WRAM_DAT_DW -1:0] wtoe_dat_dat;

assign ETOW_ADD_RDY = etow_add_rdy;
assign WTOE_DAT_VLD = wtoe_dat_vld;
assign WTOE_DAT_LST = wtoe_dat_lst;
assign WTOE_DAT_DAT = wtoe_dat_dat;

wire [WRAM_NUM_DW -1:0] etow_add_ena = etow_add_vld & etow_add_rdy;
wire [WRAM_NUM_DW -1:0] wtoe_dat_ena = wtoe_dat_vld & wtoe_dat_rdy;
wire [WRAM_NUM_DW -1:0] etow_add_end = etow_add_vld & etow_add_rdy & etow_add_lst;
wire [WRAM_NUM_DW -1:0] wtoe_dat_end = wtoe_dat_vld & wtoe_dat_rdy & wtoe_dat_lst;
//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================
//RAM
reg  [WRAM_NUM_DW -1:0]                      ram_wram_din_vld;
wire [WRAM_NUM_DW -1:0]                      ram_wram_din_rdy;
reg  [WRAM_NUM_DW -1:0][WRAM_ADD_AW    -1:0] ram_wram_din_add;
reg  [WRAM_NUM_DW -1:0][WRAM_DAT_DW    -1:0] ram_wram_din_dat;

reg  [WRAM_NUM_DW -1:0]                      ram_wram_add_vld;
reg  [WRAM_NUM_DW -1:0]                      ram_wram_add_lst;
wire [WRAM_NUM_DW -1:0]                      ram_wram_add_rdy;
reg  [WRAM_NUM_DW -1:0][WRAM_ADD_AW    -1:0] ram_wram_add_add;
wire [WRAM_NUM_DW -1:0]                      ram_wram_dat_vld;
wire [WRAM_NUM_DW -1:0]                      ram_wram_dat_lst;
reg  [WRAM_NUM_DW -1:0]                      ram_wram_dat_rdy;
wire [WRAM_NUM_DW -1:0][WRAM_DAT_DW    -1:0] ram_wram_dat_dat;
wire [WRAM_NUM_DW -1:0]                      ram_wram_add_ena = ram_wram_add_vld & ram_wram_add_rdy;
wire [WRAM_NUM_DW -1:0]                      ram_wram_dat_ena = ram_wram_dat_vld & ram_wram_dat_rdy;

CPM_REG_RCE #( 1 ) ITOW_LST_DONE_REG [WRAM_NUM_DW-1:0]( clk, rst_n, 1'd1, cfg_info_ena, ~CFG_WRAM_IDX, etow_dat_end, 1'd1, itow_lst_done );
CPM_REG_RCE #( 1 ) CONV_LST_DONE_REG [WRAM_NUM_DW-1:0]( clk, rst_n, 1'd1, cfg_info_ena, ~CFG_WRAM_IDX, wtoe_dat_end, 1'd1, conv_lst_done );
CPM_REG_RCE #( 1 ) ATOW_LST_DONE_REG [WRAM_NUM_DW-1:0]( clk, rst_n, 1'd1, cfg_info_ena, ~CFG_WRAM_IDX, etow_dat_end, 1'd1, atow_lst_done );
CPM_REG_RCE #( 1 ) WTOA_LST_DONE_REG [WRAM_NUM_DW-1:0]( clk, rst_n, 1'd1, cfg_info_ena, ~CFG_WRAM_IDX, wtoe_dat_end, 1'd1, wtoa_lst_done );
//=====================================================================================================================
// IO Logic Design :
//=====================================================================================================================        
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_info_cmd <= 'd0;
        cfg_wram_idx <= 'd0;
    end
    else if( cfg_info_ena )begin
        cfg_info_cmd <= CFG_INFO_CMD;
        cfg_wram_idx <= CFG_WRAM_IDX;
    end
end

generate
    for( gen_i=0 ; gen_i < WRAM_NUM_DW; gen_i = gen_i+1 ) begin : ATOW_DAT_WRAM
        always @ ( * )begin
            etow_dat_rdy[gen_i] = ram_wram_din_rdy[gen_i];
            etow_add_rdy[gen_i] = ram_wram_add_rdy[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < WRAM_NUM_DW; gen_i = gen_i+1 ) begin : RAM_DAT_WRAM
        always @ ( * )begin
            wtoe_dat_vld[gen_i] = ram_wram_dat_vld[gen_i];
            wtoe_dat_lst[gen_i] = ram_wram_dat_lst[gen_i];
            wtoe_dat_dat[gen_i] = ram_wram_dat_dat[gen_i];
        end
    end
endgenerate
//=====================================================================================================================
// Logic Design :
//=====================================================================================================================
generate
    for( gen_i=0 ; gen_i < WRAM_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            ram_wram_din_vld[gen_i] = etow_dat_vld[gen_i];
            ram_wram_din_add[gen_i] = etow_dat_add[gen_i];
            ram_wram_din_dat[gen_i] = etow_dat_dat[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < WRAM_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            ram_wram_add_vld[gen_i] = etow_add_vld[gen_i];
            ram_wram_add_lst[gen_i] = etow_add_lst[gen_i];
            ram_wram_add_add[gen_i] = etow_add_add[gen_i];
            ram_wram_dat_rdy[gen_i] = wtoe_dat_rdy[gen_i];
        end
    end
endgenerate
//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================
EEG_XRAM_RAM #(
    .XRAM_NUM_DW          ( WRAM_NUM_DW      ),
    .XRAM_ADD_AW          ( WRAM_ADD_AW      ),
    .XRAM_DAT_DW          ( WRAM_DAT_DW      )
) EEG_WRAM_RAM_U(
    .clk                  ( clk              ),
    .rst_n                ( rst_n            ),

    .PASS_DAT_ENA         ( 1'd0     ),

    .XRAM_DIN_VLD         ( ram_wram_din_vld ),
    .XRAM_DIN_RDY         ( ram_wram_din_rdy ),
    .XRAM_DIN_ADD         ( ram_wram_din_add ),
    .XRAM_DIN_DAT         ( ram_wram_din_dat ),

    .XRAM_ADD_VLD         ( ram_wram_add_vld ),
    .XRAM_ADD_LST         ( ram_wram_add_lst ),
    .XRAM_ADD_RDY         ( ram_wram_add_rdy ),
    .XRAM_ADD_ADD         ( ram_wram_add_add ),
    .XRAM_DAT_VLD         ( ram_wram_dat_vld ),
    .XRAM_DAT_LST         ( ram_wram_dat_lst ),
    .XRAM_DAT_RDY         ( ram_wram_dat_rdy ),
    .XRAM_DAT_DAT         ( ram_wram_dat_dat )
);

//=====================================================================================================================
// FSM :
//=====================================================================================================================
always @ ( * )begin
    case( wram_cs )
        WRAM_IDLE: wram_ns = cfg_info_ena? CFG_INFO_CMD : wram_cs;
        WRAM_ITOW: wram_ns = wram_itow_done ? WRAM_IDLE : wram_cs;
        WRAM_CONV: wram_ns = wram_conv_done ? WRAM_IDLE : wram_cs;
        WRAM_ATOW: wram_ns = wram_atow_done ? WRAM_IDLE : wram_cs;
        WRAM_WTOA: wram_ns = wram_wtoa_done ? WRAM_IDLE : wram_cs;
        default  : wram_ns = WRAM_IDLE;
    endcase
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        wram_cs <= WRAM_IDLE;
    else
        wram_cs <= wram_ns;
end

`ifdef ASSERT_ON

property wram_rdy_check(dat_vld, dat_rdy);
@(posedge clk)
disable iff(rst_n!=1'b1)
    dat_vld |-> ( dat_rdy );
endproperty

generate
  for( gen_i=0 ; gen_i < WRAM_NUM_DW; gen_i = gen_i+1 ) begin : ASSERT_BLOCK

    assert property ( wram_rdy_check(ram_wram_dat_vld[gen_i], ram_wram_dat_rdy[gen_i]) );

  end
endgenerate

`endif
endmodule
