//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description : ARAM 
//========================================================
module EEG_ARAM #(
    parameter ARAM_CMD_DW =  7,
    parameter ARAM_NUM_DW =  4,
    parameter ARAM_ADD_AW = 12,
    parameter ARAM_DAT_DW =  8,
    parameter ARAM_NUM_AW = $clog2(ARAM_NUM_DW)
  )(
    input                                          clk,
    input                                          rst_n,
    
    output                                         IS_IDLE,
    
    input                                          CFG_INFO_VLD,
    output                                         CFG_INFO_RDY,
    input  [ARAM_CMD_DW                      -1:0] CFG_INFO_CMD,
    input  [ARAM_NUM_DW                      -1:0] CFG_ARAM_IDX,

    input  [ARAM_NUM_DW -1:0]                      ETOA_DAT_VLD,
    input  [ARAM_NUM_DW -1:0]                      ETOA_DAT_LST,
    output [ARAM_NUM_DW -1:0]                      ETOA_DAT_RDY,
    input  [ARAM_NUM_DW -1:0][ARAM_ADD_AW    -1:0] ETOA_DAT_ADD,
    input  [ARAM_NUM_DW -1:0][ARAM_DAT_DW    -1:0] ETOA_DAT_DAT,
    
    input  [ARAM_NUM_DW -1:0]                      ETOA_ADD_VLD,
    input  [ARAM_NUM_DW -1:0]                      ETOA_ADD_LST,
    output [ARAM_NUM_DW -1:0]                      ETOA_ADD_RDY,
    input  [ARAM_NUM_DW -1:0][ARAM_ADD_AW    -1:0] ETOA_ADD_ADD,
    output [ARAM_NUM_DW -1:0]                      ATOE_DAT_VLD,
    output [ARAM_NUM_DW -1:0]                      ATOE_DAT_LST,
    input  [ARAM_NUM_DW -1:0]                      ATOE_DAT_RDY,
    output [ARAM_NUM_DW -1:0][ARAM_DAT_DW    -1:0] ATOE_DAT_DAT
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
integer i;
genvar gen_i, gen_j;

localparam ARAM_STATE = ARAM_CMD_DW;
localparam ARAM_IDLE  = 7'b0000001;
localparam ARAM_ITOA  = 7'b0000010;
localparam ARAM_CONV  = 7'b0000100;
localparam ARAM_OTOA  = 7'b0001000;
localparam ARAM_WTOA  = 7'b0010000;
localparam ARAM_ATOW  = 7'b0100000;
localparam ARAM_ATOA  = 7'b1000000;

reg [ARAM_STATE -1:0] aram_cs;
reg [ARAM_STATE -1:0] aram_ns;

wire aram_idle = aram_cs == ARAM_IDLE;
wire aram_itoa = aram_cs == ARAM_ITOA;
wire aram_conv = aram_cs == ARAM_CONV;
wire aram_otoa = aram_cs == ARAM_OTOA;
wire aram_wtoa = aram_cs == ARAM_WTOA;
wire aram_atow = aram_cs == ARAM_ATOW;
wire aram_atoa = aram_cs == ARAM_ATOA;
assign IS_IDLE = aram_idle;
wire [ARAM_NUM_DW -1:0] itoa_lst_done;
wire [ARAM_NUM_DW -1:0] conv_lst_done;
wire [ARAM_NUM_DW -1:0] otoa_lst_done;
wire [ARAM_NUM_DW -1:0] wtoa_lst_done;
wire [ARAM_NUM_DW -1:0] atow_lst_done;
wire [ARAM_NUM_DW -1:0] atoa_lst_done;

wire aram_itoa_done = &itoa_lst_done;
wire aram_conv_done = &conv_lst_done;
wire aram_otoa_done = &otoa_lst_done;
wire aram_wtoa_done = &wtoa_lst_done;
wire aram_atow_done = &atow_lst_done;
wire aram_atoa_done = 'd1;
//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
//CFG_IO
wire cfg_info_vld = CFG_INFO_VLD;
wire cfg_info_rdy = aram_idle;
reg  [ARAM_CMD_DW  -1:0] cfg_info_cmd;
reg  [ARAM_CMD_DW  -1:0] cfg_aram_idx;

assign CFG_INFO_RDY = cfg_info_rdy;

wire cfg_info_ena = cfg_info_vld & cfg_info_rdy;

//ARAM_DIN
wire [ARAM_NUM_DW -1:0]                   etoa_dat_vld = ETOA_DAT_VLD;
wire [ARAM_NUM_DW -1:0]                   etoa_dat_lst = ETOA_DAT_LST;
reg  [ARAM_NUM_DW -1:0]                   etoa_dat_rdy;
wire [ARAM_NUM_DW -1:0][ARAM_ADD_AW -1:0] etoa_dat_add = ETOA_DAT_ADD;
wire [ARAM_NUM_DW -1:0][ARAM_DAT_DW -1:0] etoa_dat_dat = ETOA_DAT_DAT;
assign ETOA_DAT_RDY = etoa_dat_rdy;

wire [ARAM_NUM_DW -1:0] etoa_dat_ena = etoa_dat_vld & etoa_dat_rdy;
wire [ARAM_NUM_DW -1:0] etoa_dat_end = etoa_dat_vld & etoa_dat_rdy & etoa_dat_lst;

//ARAM_OUT
wire [ARAM_NUM_DW -1:0]                   etoa_add_vld = ETOA_ADD_VLD;
wire [ARAM_NUM_DW -1:0]                   etoa_add_lst = ETOA_ADD_LST;
reg  [ARAM_NUM_DW -1:0]                   etoa_add_rdy;
wire [ARAM_NUM_DW -1:0][ARAM_ADD_AW -1:0] etoa_add_add = ETOA_ADD_ADD;
reg  [ARAM_NUM_DW -1:0]                   atoe_dat_vld;
reg  [ARAM_NUM_DW -1:0]                   atoe_dat_lst;
wire [ARAM_NUM_DW -1:0]                   atoe_dat_rdy = ATOE_DAT_RDY;
reg  [ARAM_NUM_DW -1:0][ARAM_DAT_DW -1:0] atoe_dat_dat;

assign ETOA_ADD_RDY = etoa_add_rdy;
assign ATOE_DAT_VLD = atoe_dat_vld;
assign ATOE_DAT_LST = atoe_dat_lst;
assign ATOE_DAT_DAT = atoe_dat_dat;

wire [ARAM_NUM_DW -1:0] etoa_add_ena = etoa_add_vld & etoa_add_rdy;
wire [ARAM_NUM_DW -1:0] atoe_dat_ena = atoe_dat_vld & atoe_dat_rdy;
wire [ARAM_NUM_DW -1:0] etoa_add_end = etoa_add_vld & etoa_add_rdy & etoa_add_lst;
wire [ARAM_NUM_DW -1:0] atoe_dat_end = atoe_dat_vld & atoe_dat_rdy & atoe_dat_lst;
//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================
//RAM
reg  [ARAM_NUM_DW -1:0]                      ram_aram_din_vld;
wire [ARAM_NUM_DW -1:0]                      ram_aram_din_rdy;
reg  [ARAM_NUM_DW -1:0][ARAM_ADD_AW    -1:0] ram_aram_din_add;
reg  [ARAM_NUM_DW -1:0][ARAM_DAT_DW    -1:0] ram_aram_din_dat;

reg  [ARAM_NUM_DW -1:0]                      ram_aram_add_vld;
reg  [ARAM_NUM_DW -1:0]                      ram_aram_add_lst;
wire [ARAM_NUM_DW -1:0]                      ram_aram_add_rdy;
reg  [ARAM_NUM_DW -1:0][ARAM_ADD_AW    -1:0] ram_aram_add_add;
wire [ARAM_NUM_DW -1:0]                      ram_aram_dat_vld;
wire [ARAM_NUM_DW -1:0]                      ram_aram_dat_lst;
reg  [ARAM_NUM_DW -1:0]                      ram_aram_dat_rdy;
wire [ARAM_NUM_DW -1:0][ARAM_DAT_DW    -1:0] ram_aram_dat_dat;
wire [ARAM_NUM_DW -1:0]                      ram_aram_add_ena = ram_aram_add_vld & ram_aram_add_rdy;
wire [ARAM_NUM_DW -1:0]                      ram_aram_dat_ena = ram_aram_dat_vld & ram_aram_dat_rdy;

CPM_REG_RCE #( 1 ) ITOA_LST_DONE_REG [ARAM_NUM_DW-1:0]( clk, rst_n, 1'd1, cfg_info_ena, ~CFG_ARAM_IDX, etoa_dat_end, 1'd1, itoa_lst_done );
CPM_REG_RCE #( 1 ) CONV_LST_DONE_REG [ARAM_NUM_DW-1:0]( clk, rst_n, 1'd1, cfg_info_ena, ~CFG_ARAM_IDX, atoe_dat_end, 1'd1, conv_lst_done );
CPM_REG_RCE #( 1 ) OTOA_LST_DONE_REG [ARAM_NUM_DW-1:0]( clk, rst_n, 1'd1, cfg_info_ena, ~CFG_ARAM_IDX, etoa_dat_end, 1'd1, otoa_lst_done );
CPM_REG_RCE #( 1 ) WTOA_LST_DONE_REG [ARAM_NUM_DW-1:0]( clk, rst_n, 1'd1, cfg_info_ena, ~CFG_ARAM_IDX, etoa_dat_end, 1'd1, wtoa_lst_done );
CPM_REG_RCE #( 1 ) ATOW_LST_DONE_REG [ARAM_NUM_DW-1:0]( clk, rst_n, 1'd1, cfg_info_ena, ~CFG_ARAM_IDX, atoe_dat_end, 1'd1, atow_lst_done );
CPM_REG_RCE #( 1 ) ATOA_LST_DONE_REG [ARAM_NUM_DW-1:0]( clk, rst_n, 1'd1, cfg_info_ena, ~CFG_ARAM_IDX, etoa_dat_end, 1'd1, atoa_lst_done );
//=====================================================================================================================
// IO Logic Design :
//=====================================================================================================================        
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_info_cmd <= 'd0;
        cfg_aram_idx <= 'd0;
    end
    else if( cfg_info_ena )begin
        cfg_info_cmd <= CFG_INFO_CMD;
        cfg_aram_idx <= CFG_ARAM_IDX;
    end
end

generate
    for( gen_i=0 ; gen_i < ARAM_NUM_DW; gen_i = gen_i+1 ) begin : ATOW_DAT_ARAM
        always @ ( * )begin
            etoa_dat_rdy[gen_i] = ram_aram_din_rdy[gen_i];
            etoa_add_rdy[gen_i] = ram_aram_add_rdy[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ARAM_NUM_DW; gen_i = gen_i+1 ) begin : RAM_DAT_ARAM
        always @ ( * )begin
            atoe_dat_vld[gen_i] = ram_aram_dat_vld[gen_i];
            atoe_dat_lst[gen_i] = ram_aram_dat_lst[gen_i];
            atoe_dat_dat[gen_i] = ram_aram_dat_dat[gen_i];
        end
    end
endgenerate
//=====================================================================================================================
// Logic Design :
//=====================================================================================================================
generate
    for( gen_i=0 ; gen_i < ARAM_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            ram_aram_din_vld[gen_i] = etoa_dat_vld[gen_i];
            ram_aram_din_add[gen_i] = etoa_dat_add[gen_i];
            ram_aram_din_dat[gen_i] = etoa_dat_dat[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < ARAM_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            ram_aram_add_vld[gen_i] = etoa_add_vld[gen_i];
            ram_aram_add_lst[gen_i] = etoa_add_lst[gen_i];
            ram_aram_add_add[gen_i] = etoa_add_add[gen_i];
            ram_aram_dat_rdy[gen_i] = atoe_dat_rdy[gen_i];
        end
    end
endgenerate
//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================
EEG_XRAM_RAM #(
    .XRAM_NUM_DW          ( ARAM_NUM_DW      ),
    .XRAM_ADD_AW          ( ARAM_ADD_AW      ),
    .XRAM_DAT_DW          ( ARAM_DAT_DW      )
) EEG_ARAM_RAM_U(
    .clk                  ( clk              ),
    .rst_n                ( rst_n            ),

    .PASS_DAT_ENA         ( 1'd0     ),

    .XRAM_DIN_VLD         ( ram_aram_din_vld ),
    .XRAM_DIN_RDY         ( ram_aram_din_rdy ),
    .XRAM_DIN_ADD         ( ram_aram_din_add ),
    .XRAM_DIN_DAT         ( ram_aram_din_dat ),

    .XRAM_ADD_VLD         ( ram_aram_add_vld ),
    .XRAM_ADD_LST         ( ram_aram_add_lst ),
    .XRAM_ADD_RDY         ( ram_aram_add_rdy ),
    .XRAM_ADD_ADD         ( ram_aram_add_add ),
    .XRAM_DAT_VLD         ( ram_aram_dat_vld ),
    .XRAM_DAT_LST         ( ram_aram_dat_lst ),
    .XRAM_DAT_RDY         ( ram_aram_dat_rdy ),
    .XRAM_DAT_DAT         ( ram_aram_dat_dat )
);

//=====================================================================================================================
// FSM :
//=====================================================================================================================
always @ ( * )begin
    case( aram_cs )
        ARAM_IDLE: aram_ns = cfg_info_ena? CFG_INFO_CMD : aram_cs;
        ARAM_ITOA: aram_ns = aram_itoa_done ? ARAM_IDLE : aram_cs;
        ARAM_CONV: aram_ns = aram_conv_done ? ARAM_IDLE : aram_cs;
        ARAM_OTOA: aram_ns = aram_otoa_done ? ARAM_IDLE : aram_cs;
        ARAM_WTOA: aram_ns = aram_wtoa_done ? ARAM_IDLE : aram_cs;
        ARAM_ATOW: aram_ns = aram_atow_done ? ARAM_IDLE : aram_cs;
        ARAM_ATOA: aram_ns = aram_atoa_done ? ARAM_IDLE : aram_cs;
        default  : aram_ns = ARAM_IDLE;
    endcase
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        aram_cs <= ARAM_IDLE;
    else
        aram_cs <= aram_ns;
end

`ifdef ASSERT_ON

property aram_rdy_check(dat_vld, dat_rdy);
@(posedge clk)
disable iff(rst_n!=1'b1)
    dat_vld |-> ( dat_rdy );
endproperty

generate
  for( gen_i=0 ; gen_i < ARAM_NUM_DW; gen_i = gen_i+1 ) begin : ASSERT_BLOCK

    assert property ( aram_rdy_check(ram_aram_dat_vld[gen_i], ram_aram_dat_rdy[gen_i]) );

  end
endgenerate

`endif
endmodule
