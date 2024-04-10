//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description : FRAM 
//========================================================
module EEG_FRAM #(
    parameter FRAM_CMD_DW =  4,
    parameter FRAM_NUM_DW =  4,
    parameter FRAM_ADD_AW = 12,
    parameter FRAM_DAT_DW =  4,
    parameter FRAM_NUM_AW = $clog2(FRAM_NUM_DW)
  )(
    input                                          clk,
    input                                          rst_n,
    
    output                                         IS_IDLE,
    
    input                                          CFG_INFO_VLD,
    output                                         CFG_INFO_RDY,
    input  [FRAM_CMD_DW                      -1:0] CFG_INFO_CMD,
    input                                          CFG_FLAG_VLD,

    input  [FRAM_NUM_DW -1:0]                      ETOF_DAT_VLD,
    input  [FRAM_NUM_DW -1:0]                      ETOF_DAT_LST,
    output [FRAM_NUM_DW -1:0]                      ETOF_DAT_RDY,
    input  [FRAM_NUM_DW -1:0][FRAM_ADD_AW    -1:0] ETOF_DAT_ADD,
    input  [FRAM_NUM_DW -1:0][FRAM_DAT_DW    -1:0] ETOF_DAT_DAT,
    
    input  [FRAM_NUM_DW -1:0]                      ETOF_ADD_VLD,
    input  [FRAM_NUM_DW -1:0]                      ETOF_ADD_LST,
    output [FRAM_NUM_DW -1:0]                      ETOF_ADD_RDY,
    input  [FRAM_NUM_DW -1:0][FRAM_ADD_AW    -1:0] ETOF_ADD_ADD,
    output [FRAM_NUM_DW -1:0]                      FTOE_DAT_VLD,
    output [FRAM_NUM_DW -1:0]                      FTOE_DAT_LST,
    input  [FRAM_NUM_DW -1:0]                      FTOE_DAT_RDY,
    output [FRAM_NUM_DW -1:0][FRAM_DAT_DW    -1:0] FTOE_DAT_DAT
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
integer i;
genvar gen_i, gen_j;

localparam FRAM_STATE = FRAM_CMD_DW;
localparam FRAM_IDLE  = 4'b0001;
localparam FRAM_ITOF  = 4'b0010;
localparam FRAM_CONV  = 4'b0100;
localparam FRAM_OTOF  = 4'b1000;

reg [FRAM_STATE -1:0] fram_cs;
reg [FRAM_STATE -1:0] fram_ns;

wire fram_idle = fram_cs == FRAM_IDLE;
wire fram_itof = fram_cs == FRAM_ITOF;
wire fram_conv = fram_cs == FRAM_CONV;
wire fram_otof = fram_cs == FRAM_OTOF;
assign IS_IDLE = fram_idle;
wire [FRAM_NUM_DW -1:0] itof_lst_done;
wire [FRAM_NUM_DW -1:0] conv_lst_done;
wire [FRAM_NUM_DW -1:0] otof_lst_done;

wire fram_itof_done = &itof_lst_done;
wire fram_conv_done = &conv_lst_done;
wire fram_otof_done = &otof_lst_done;
//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
//CFG_IO
wire cfg_info_vld = CFG_INFO_VLD;
wire cfg_info_rdy = fram_idle;
reg  [FRAM_CMD_DW  -1:0] cfg_info_cmd;
reg                      cfg_flag_vld;
reg                      cfg_flag_non;

assign CFG_INFO_RDY = cfg_info_rdy;
wire cfg_info_ena = cfg_info_vld & cfg_info_rdy;
//FRAM_DIN
wire [FRAM_NUM_DW -1:0]                   etof_dat_vld = ETOF_DAT_VLD;
wire [FRAM_NUM_DW -1:0]                   etof_dat_lst = ETOF_DAT_LST;
reg  [FRAM_NUM_DW -1:0]                   etof_dat_rdy;
wire [FRAM_NUM_DW -1:0][FRAM_ADD_AW -1:0] etof_dat_add = ETOF_DAT_ADD;
wire [FRAM_NUM_DW -1:0][FRAM_DAT_DW -1:0] etof_dat_dat = ETOF_DAT_DAT;
assign ETOF_DAT_RDY = etof_dat_rdy;

wire [FRAM_NUM_DW -1:0] etof_dat_ena = etof_dat_vld & etof_dat_rdy;
wire [FRAM_NUM_DW -1:0] etof_dat_end = etof_dat_vld & etof_dat_rdy & etof_dat_lst;

//FRAM_OUT
wire [FRAM_NUM_DW -1:0]                   etof_add_vld = ETOF_ADD_VLD;
wire [FRAM_NUM_DW -1:0]                   etof_add_lst = ETOF_ADD_LST;
reg  [FRAM_NUM_DW -1:0]                   etof_add_rdy;
wire [FRAM_NUM_DW -1:0][FRAM_ADD_AW -1:0] etof_add_add = ETOF_ADD_ADD;
reg  [FRAM_NUM_DW -1:0]                   ftoe_dat_vld;
reg  [FRAM_NUM_DW -1:0]                   ftoe_dat_lst;
wire [FRAM_NUM_DW -1:0]                   ftoe_dat_rdy = FTOE_DAT_RDY;
reg  [FRAM_NUM_DW -1:0][FRAM_DAT_DW -1:0] ftoe_dat_dat;

assign ETOF_ADD_RDY = etof_add_rdy;
assign FTOE_DAT_VLD = ftoe_dat_vld;
assign FTOE_DAT_LST = ftoe_dat_lst;
assign FTOE_DAT_DAT = ftoe_dat_dat;

wire [FRAM_NUM_DW -1:0] etof_add_ena = etof_add_vld & etof_add_rdy;
wire [FRAM_NUM_DW -1:0] ftoe_dat_ena = ftoe_dat_vld & ftoe_dat_rdy;
wire [FRAM_NUM_DW -1:0] etof_add_end = etof_add_vld & etof_add_rdy & etof_add_lst;
wire [FRAM_NUM_DW -1:0] ftoe_dat_end = ftoe_dat_vld & ftoe_dat_rdy & ftoe_dat_lst;
//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================
//RAM
reg  [FRAM_NUM_DW -1:0]                      ram_fram_din_vld;
wire [FRAM_NUM_DW -1:0]                      ram_fram_din_rdy;
reg  [FRAM_NUM_DW -1:0][FRAM_ADD_AW    -1:0] ram_fram_din_add;
reg  [FRAM_NUM_DW -1:0][FRAM_DAT_DW    -1:0] ram_fram_din_dat;

reg  [FRAM_NUM_DW -1:0]                      ram_fram_add_vld;
reg  [FRAM_NUM_DW -1:0]                      ram_fram_add_lst;
wire [FRAM_NUM_DW -1:0]                      ram_fram_add_rdy;
reg  [FRAM_NUM_DW -1:0][FRAM_ADD_AW    -1:0] ram_fram_add_add;
wire [FRAM_NUM_DW -1:0]                      ram_fram_dat_vld;
wire [FRAM_NUM_DW -1:0]                      ram_fram_dat_lst;
reg  [FRAM_NUM_DW -1:0]                      ram_fram_dat_rdy;
wire [FRAM_NUM_DW -1:0][FRAM_DAT_DW    -1:0] ram_fram_dat_dat;
wire [FRAM_NUM_DW -1:0]                      ram_fram_add_ena = ram_fram_add_vld & ram_fram_add_rdy;
wire [FRAM_NUM_DW -1:0]                      ram_fram_dat_ena = ram_fram_dat_vld & ram_fram_dat_rdy;

CPM_REG_RCE #( 1 ) ITOF_LST_DONE_REG [FRAM_NUM_DW-1:0]( clk, rst_n, 1'd1, cfg_info_ena, 1'd0, etof_dat_end, 1'd1, itof_lst_done );
CPM_REG_RCE #( 1 ) CONV_LST_DONE_REG [FRAM_NUM_DW-1:0]( clk, rst_n, 1'd1, cfg_info_ena, 1'd0, ftoe_dat_end, 1'd1, conv_lst_done );
CPM_REG_RCE #( 1 ) OTOF_LST_DONE_REG [FRAM_NUM_DW-1:0]( clk, rst_n, 1'd1, cfg_info_ena, 1'd0, etof_dat_end, 1'd1, otof_lst_done );
//=====================================================================================================================
// IO Logic Design :
//=====================================================================================================================        
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )begin
        cfg_info_cmd <= 'd0;
        cfg_flag_vld <= 'd0;
        cfg_flag_non <= 'd0;
    end else if( cfg_info_ena )begin
        cfg_info_cmd <= CFG_INFO_CMD;
        cfg_flag_vld <= CFG_FLAG_VLD;
        cfg_flag_non <=~CFG_FLAG_VLD;
    end
end

generate
    for( gen_i=0 ; gen_i < FRAM_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            etof_dat_rdy[gen_i] = ram_fram_din_rdy[gen_i];
            etof_add_rdy[gen_i] = ram_fram_add_rdy[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < FRAM_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            ftoe_dat_vld[gen_i] = ram_fram_dat_vld[gen_i];
            ftoe_dat_lst[gen_i] = ram_fram_dat_lst[gen_i];
            ftoe_dat_dat[gen_i] = cfg_flag_vld ? ram_fram_dat_dat[gen_i] : {FRAM_DAT_DW{1'b1}};
        end
    end
endgenerate
//=====================================================================================================================
// Logic Design :
//=====================================================================================================================
generate
    for( gen_i=0 ; gen_i < FRAM_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            ram_fram_din_vld[gen_i] = etof_dat_vld[gen_i];
            ram_fram_din_add[gen_i] = etof_dat_add[gen_i];
            ram_fram_din_dat[gen_i] = etof_dat_dat[gen_i];
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < FRAM_NUM_DW; gen_i = gen_i+1 )begin
        always @ ( * )begin
            ram_fram_add_vld[gen_i] = etof_add_vld[gen_i];
            ram_fram_add_lst[gen_i] = etof_add_lst[gen_i];
            ram_fram_add_add[gen_i] = etof_add_add[gen_i];
            ram_fram_dat_rdy[gen_i] = ftoe_dat_rdy[gen_i];
        end
    end
endgenerate
//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================
EEG_XRAM_RAM #(
    .XRAM_NUM_DW          ( FRAM_NUM_DW      ),
    .XRAM_ADD_AW          ( FRAM_ADD_AW -2   ),
    .XRAM_DAT_DW          ( FRAM_DAT_DW      )
) EEG_FRAM_RAM_U(
    .clk                  ( clk              ),
    .rst_n                ( rst_n            ),
    
    .PASS_DAT_ENA         ( cfg_flag_non     ),

    .XRAM_DIN_VLD         ( ram_fram_din_vld ),
    .XRAM_DIN_RDY         ( ram_fram_din_rdy ),
    .XRAM_DIN_ADD         ( ram_fram_din_add ),
    .XRAM_DIN_DAT         ( ram_fram_din_dat ),

    .XRAM_ADD_VLD         ( ram_fram_add_vld ),
    .XRAM_ADD_LST         ( ram_fram_add_lst ),
    .XRAM_ADD_RDY         ( ram_fram_add_rdy ),
    .XRAM_ADD_ADD         ( ram_fram_add_add ),
    .XRAM_DAT_VLD         ( ram_fram_dat_vld ),
    .XRAM_DAT_LST         ( ram_fram_dat_lst ),
    .XRAM_DAT_RDY         ( ram_fram_dat_rdy ),
    .XRAM_DAT_DAT         ( ram_fram_dat_dat )
);

//=====================================================================================================================
// FSM :
//=====================================================================================================================
always @ ( * )begin
    case( fram_cs )
        FRAM_IDLE: fram_ns = cfg_info_ena? CFG_INFO_CMD : fram_cs;
        FRAM_ITOF: fram_ns = fram_itof_done ? FRAM_IDLE : fram_cs;
        FRAM_CONV: fram_ns = fram_conv_done ? FRAM_IDLE : fram_cs;
        FRAM_OTOF: fram_ns = fram_otof_done ? FRAM_IDLE : fram_cs;
        default  : fram_ns = FRAM_IDLE;
    endcase
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        fram_cs <= FRAM_IDLE;
    else
        fram_cs <= fram_ns;
end

`ifdef ASSERT_ON

property fram_rdy_check(dat_vld, dat_rdy);
@(posedge clk)
disable iff(rst_n!=1'b1)
    dat_vld |-> ( dat_rdy );
endproperty

generate
  for( gen_i=0 ; gen_i < FRAM_NUM_DW; gen_i = gen_i+1 ) begin : ASSERT_BLOCK

    assert property ( fram_rdy_check(ram_fram_dat_vld[gen_i], ram_fram_dat_rdy[gen_i]) );

  end
endgenerate

`endif
endmodule
