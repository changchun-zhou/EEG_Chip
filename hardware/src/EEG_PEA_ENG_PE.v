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
module EEG_PEA_ENG_PE #(
    parameter ACT_DW      =  8,
    parameter WEI_DW      =  8,
    parameter OUT_DW      =  8,
    parameter SUM_DW      = 24,
    parameter SUM_NW      =  8,
    parameter ARAM_ADD_AW = 10,
    parameter ORAM_ADD_AW = 10,
    parameter OMUX_ADD_AW =  8,
    parameter CONV_WEI_DW =  3,
    parameter CONV_RUN_DW =  3,
    parameter CONV_MUL_DW = 24,
    parameter CONV_ADD_DW = 24
  )(
    input                             clk,
    input                             rst_n,

    output                            IS_IDLE,

    input  [CONV_RUN_DW         -1:0] CFG_CONV_RUN,//CONV_DILA_FAC or CONV_DILA_STRIDE
    input  [CONV_WEI_DW         -1:0] CFG_CONV_WEI,//WEI_LEN
    input  [CONV_WEI_DW         -1:0] CFG_CONV_PAD,//WEI_LEN/2
    input  [CONV_MUL_DW         -1:0] CFG_CONV_MUL,
    input  [CONV_ADD_DW         -1:0] CFG_CONV_ADD,
    input  [ORAM_ADD_AW         -1:0] CFG_CONV_LST,

    input                             DIN_VLD,
    input                             ACT_LST,
    input                             WEI_LST,
    output                            DIN_RDY,
    input  [ACT_DW              -1:0] ACT_DAT,
    input  [ARAM_ADD_AW         -1:0] ACT_ADD,
    input  [WEI_DW              -1:0] WEI_DAT,
    input  [CONV_WEI_DW         -1:0] WEI_IDX,

    output                            OUT_VLD,
    output                            OUT_LST,
    output [OMUX_ADD_AW         -1:0] OUT_ADD,
    input                             OUT_RDY,
    output [OUT_DW              -1:0] OUT_DAT
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
localparam SUM_AW = $clog2(SUM_NW);

localparam PE_STATE = 3;
localparam PE_IDLE  = 3'b001;
localparam PE_FLOW  = 3'b010;
localparam PE_PSUM  = 3'b100;

reg [PE_STATE -1:0] pe_cs;
reg [PE_STATE -1:0] pe_ns;

wire pe_idle = pe_cs == PE_IDLE;
wire pe_flow = pe_cs == PE_FLOW;
wire pe_psum = pe_cs == PE_PSUM;

//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
wire                    cfg_conv_run = CFG_CONV_RUN;
wire [CONV_WEI_DW -1:0] cfg_conv_wei = CFG_CONV_WEI;
wire [CONV_WEI_DW -1:0] cfg_conv_pad = CFG_CONV_PAD;
wire [CONV_MUL_DW -1:0] cfg_conv_mul = CFG_CONV_MUL;
wire [CONV_ADD_DW -1:0] cfg_conv_add = CFG_CONV_ADD;
wire [ORAM_ADD_AW -1:0] cfg_conv_lst = CFG_CONV_LST;
assign IS_IDLE = pe_idle;
//din
wire                    din_vld = DIN_VLD;
reg                     din_rdy;
wire                    act_lst = ACT_LST;
wire                    wei_lst = WEI_LST;
wire [ACT_DW      -1:0] act_dat = ACT_DAT;
wire [ARAM_ADD_AW -1:0] act_add = ACT_ADD;
wire [WEI_DW      -1:0] wei_dat = WEI_DAT;
wire [CONV_WEI_DW -1:0] wei_idx = WEI_IDX;
assign DIN_RDY = din_rdy; 

wire din_ena = DIN_VLD & DIN_RDY;
//out
reg                     out_vld;
reg                     out_lst;
reg  [OMUX_ADD_AW -1:0] out_add;
wire                    out_rdy = OUT_RDY;
reg  [OUT_DW      -1:0] out_dat;

assign OUT_DAT = out_dat;
assign OUT_VLD = out_vld;
assign OUT_LST = out_lst;
assign OUT_ADD = out_add;

wire out_ena = OUT_VLD & OUT_RDY;
//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================
reg [CONV_WEI_DW -1:0] wei_idx_cnt;
reg [CONV_WEI_DW -1:0] out_idx_cnt;

reg psum_out_vld;

reg [ARAM_ADD_AW   :0] aram_add_reg;
reg [ARAM_ADD_AW   :0] psum_add_reg;

reg [SUM_NW      -1:0][SUM_DW -1:0] psum_cal_reg;
reg [SUM_DW      -1:0] psum_cal_tmp;
reg [OUT_DW      -1:0] psum_out_reg; 

wire is_addr_out_range = act_add>(aram_add_reg+cfg_conv_pad);

wire pe_data_ena = din_ena;
wire pe_last_din = din_ena&&act_lst&&wei_lst;
wire pe_psum_rst = out_ena&&out_idx_cnt==cfg_conv_pad;//is_addr_out_range make sure aram_add_reg within (cfg_conv_pad) bit act_add

wire psum_out_lst = psum_add_reg==cfg_conv_lst;
//=====================================================================================================================   
// IO Logic Design :                                                                                                      
//=====================================================================================================================   
always @( * )begin 
    din_rdy = out_rdy || ~psum_out_vld;// || (~is_psum_out_vld && is_addr_out_range);//C2 may be too long; C1 need 4 BANK ORAM
end

always @( * )begin    
    out_dat = psum_out_reg;
    out_vld = psum_out_vld;
    out_add = psum_add_reg;
    out_lst = psum_out_lst;
end
//=====================================================================================================================
// Logic Design :
//=====================================================================================================================
genvar gen_i;
generate
    for( gen_i=0 ; gen_i < SUM_NW; gen_i = gen_i+1 ) begin : PSUM_BLOCK
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                psum_cal_reg[gen_i] <= 'd0;
            else if( pe_psum_rst )
                psum_cal_reg[gen_i] <= 'd0;
            else if( pe_idle && din_ena && gen_i==0 )
                psum_cal_reg[gen_i] <= psum_cal_tmp;
            else if( pe_flow && din_ena )begin
                if(  is_addr_out_range )begin
                    if( gen_i==SUM_NW-1 )
                        psum_cal_reg[gen_i] <= 'd0;
                    else if(  (gen_i+1)==wei_idx_cnt )
                        psum_cal_reg[gen_i] <= psum_cal_tmp;
                    else
                        psum_cal_reg[gen_i] <= psum_cal_reg[gen_i+1];
                end
                else begin
                    if( gen_i==wei_idx_cnt )
                        psum_cal_reg[gen_i] <= psum_cal_tmp;
                end
            end
            else if( pe_psum && out_rdy )begin
                if( gen_i==SUM_NW-1 )
                    psum_cal_reg[gen_i] <= 'd0;
                else
                    psum_cal_reg[gen_i] <= psum_cal_reg[gen_i+1];
            end
        end
    end
  
endgenerate

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        wei_idx_cnt <= 'd0;
    else if( pe_psum_rst )
        wei_idx_cnt <= 'd0;
    else if( din_ena && WEI_LST )
        wei_idx_cnt <= 'd0;
    else if( din_ena )
        wei_idx_cnt <= wei_idx_cnt +'d1;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        out_idx_cnt <= 'd0;
    else if( pe_psum_rst )
        out_idx_cnt <= 'd0;
    else if( pe_psum && out_ena )
        out_idx_cnt <= out_idx_cnt +'d1;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        psum_out_reg <= 'd0;
    else if( pe_psum_rst )
        psum_out_reg <= 'd0;
    else if( is_addr_out_range && din_ena )
        psum_out_reg <= $signed(psum_cal_reg[0])*$signed(cfg_conv_mul) +$signed(cfg_conv_add);
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        psum_out_vld <= 'd0;
    else if( pe_psum_rst )
        psum_out_vld <= 'd0;
    else if( is_addr_out_range && din_ena )
        psum_out_vld <= 'd1;
    else if( pe_psum )
        psum_out_vld <= 'd1;
    else if( out_ena )
        psum_out_vld <= 'd0;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        aram_add_reg <= 'd0;
    else if( pe_psum_rst )
        aram_add_reg <= 'd0;
    else if( pe_idle && din_ena )
        aram_add_reg <= ACT_ADD;
    else if( pe_flow && din_ena && is_addr_out_range && (~psum_out_vld || out_rdy) )
        aram_add_reg <= aram_add_reg+CFG_CONV_RUN;
    else if( pe_psum && out_rdy )
        aram_add_reg <= aram_add_reg+CFG_CONV_RUN;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        psum_add_reg <= 'd0;
    else if( pe_psum_rst )
        psum_add_reg <= 'd0;
    else if( pe_flow && din_ena && is_addr_out_range && (~psum_out_vld || out_rdy) )
        psum_add_reg <= aram_add_reg;
    else if( pe_psum && out_rdy )
        psum_add_reg <= aram_add_reg;
end

//MAC
always @ ( * )begin
    psum_cal_tmp = $signed(ACT_DAT)*$signed(WEI_DAT) +$signed(psum_cal_reg[wei_idx_cnt]);
end
//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================

//=====================================================================================================================
// FSM :
//=====================================================================================================================
always @ ( * )begin
  case( pe_cs )
    PE_IDLE: pe_ns = pe_data_ena ? PE_FLOW : pe_cs;
    PE_FLOW: pe_ns = pe_last_din ? PE_PSUM : pe_cs;
    PE_PSUM: pe_ns = pe_psum_rst ? PE_IDLE : pe_cs;
    default: pe_ns = PE_IDLE;
  endcase
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        pe_cs <= PE_IDLE;
    else
        pe_cs <= pe_ns;
end


`ifdef ASSERT_ON


`endif
endmodule
