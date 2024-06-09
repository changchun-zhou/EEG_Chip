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
    parameter DATA_ACT_DW =  8,
    parameter DATA_WEI_DW =  8,
    parameter DATA_OUT_DW =  8,
    parameter DATA_SUM_DW = 24,
    parameter DATA_SUM_NW =  8,
    parameter ARAM_ADD_AW = 10,
    parameter ORAM_ADD_AW = 10,
    parameter OMUX_ADD_AW =  8,
    parameter CONV_WEI_DW =  3,
    parameter CONV_RUN_DW =  3,
    parameter CONV_MUL_DW = 24,
    parameter CONV_SFT_DW =  8,
    parameter CONV_ADD_DW = 24
  )(
    input                             clk,
    input                             rst_n,

    output                            IS_IDLE,

    input  [CONV_RUN_DW         -1:0] CFG_CONV_RUN,//CONV_DILA_FAC or CONV_DILA_STRIDE
    input  [CONV_WEI_DW         -1:0] CFG_CONV_WEI,//WEI_LEN
    input  [CONV_WEI_DW         -1:0] CFG_CONV_PAD,//WEI_LEN/2
    input  [CONV_MUL_DW         -1:0] CFG_CONV_MUL,
    input  [CONV_SFT_DW         -1:0] CFG_CONV_SFT,
    input  [CONV_ADD_DW         -1:0] CFG_CONV_ADD,
    input  [ORAM_ADD_AW         -1:0] CFG_CONV_LST,

    input                             DIN_VLD,
    input                             ACT_LST,
    input                             WEI_LST,
    output                            DIN_RDY,
    input  [DATA_ACT_DW         -1:0] ACT_DAT,
    input  [ARAM_ADD_AW         -1:0] ACT_ADD,
    input  [DATA_WEI_DW         -1:0] WEI_DAT,
    input  [CONV_WEI_DW         -1:0] WEI_IDX,

    output                            OUT_VLD,
    output                            OUT_LST,
    output [OMUX_ADD_AW         -1:0] OUT_ADD,
    input                             OUT_RDY,
    output [DATA_OUT_DW         -1:0] OUT_DAT
  );
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
localparam CONV_SUM_AW = $clog2(DATA_SUM_NW);
localparam CONV_CAL_DW = DATA_SUM_DW +CONV_MUL_DW +1;

localparam PE_STATE = 3;
localparam PE_IDLE  = 3'b001;
localparam PE_FLOW  = 3'b010;
localparam PE_PSUM  = 3'b100;

reg [PE_STATE -1:0] pe_cs;
reg [PE_STATE -1:0] pe_ns;

wire pe_idle = pe_cs == PE_IDLE;
wire pe_flow = pe_cs == PE_FLOW;
wire pe_psum = pe_cs == PE_PSUM;

genvar gen_i, gen_j;
//=====================================================================================================================
// IO Signal :
//=====================================================================================================================
wire [CONV_RUN_DW -1:0] cfg_conv_run = CFG_CONV_RUN;
wire [CONV_WEI_DW -1:0] cfg_conv_wei = CFG_CONV_WEI;
wire [CONV_WEI_DW -1:0] cfg_conv_pad = CFG_CONV_PAD;
wire [CONV_MUL_DW -1:0] cfg_conv_mul = CFG_CONV_MUL;
wire [5 -1:0] cfg_conv_sft = CFG_CONV_SFT[0 +:5];
wire [CONV_ADD_DW -1:0] cfg_conv_add = CFG_CONV_ADD;
wire [ORAM_ADD_AW -1:0] cfg_conv_lst = CFG_CONV_LST;
assign IS_IDLE = pe_idle;
//din
wire                    din_vld = DIN_VLD;
reg                     din_rdy;
wire                    act_lst = ACT_LST;
wire                    wei_lst = WEI_LST;
wire [DATA_ACT_DW -1:0] act_dat = ACT_DAT;
wire [ARAM_ADD_AW -1:0] act_add = ACT_ADD;
wire [DATA_WEI_DW -1:0] wei_dat = WEI_DAT;
wire [CONV_WEI_DW -1:0] wei_idx = WEI_IDX;
assign DIN_RDY = din_rdy; 

wire din_ena = DIN_VLD & DIN_RDY;
//out
reg                     out_vld;
reg                     out_lst;
reg  [OMUX_ADD_AW -1:0] out_add;
wire                    out_rdy = OUT_RDY;
reg  [DATA_OUT_DW -1:0] out_dat;

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
reg psum_cal_vld;

reg [2 -1:0] psum_cal_cnt;
wire [DATA_OUT_DW -1:0] psum_out_clp;

reg [ARAM_ADD_AW   :0] aram_add_reg;
reg [ARAM_ADD_AW   :0] psum_add_reg;

reg [DATA_SUM_NW -1:0][DATA_SUM_DW -1:0] psum_cal_reg;
reg [DATA_SUM_DW -1:0] psum_cal_tmp;
reg [DATA_SUM_DW -1:0] psum_out_reg;
reg [DATA_OUT_DW -1:0] psum_out_dat;

wire is_addr_out_range = act_add>(aram_add_reg+cfg_conv_pad*cfg_conv_run);
wire is_addr_hit_range_next = act_add<=(aram_add_reg+cfg_conv_pad*cfg_conv_run+cfg_conv_run);

wire pe_data_ena = din_ena;
reg  pe_last_din;
wire pe_flow_end = pe_last_din && ~psum_cal_vld && ~psum_out_vld;
wire pe_psum_rst = out_ena&&out_idx_cnt==cfg_conv_pad&&pe_psum;//is_addr_out_range make sure aram_add_reg within (cfg_conv_pad) bit act_add

wire psum_out_lst = psum_add_reg==cfg_conv_lst;
//=====================================================================================================================   
// IO Logic Design :                                                                                                      
//=====================================================================================================================   
always @( * )begin 
    din_rdy = ~pe_psum && (~psum_cal_vld || ~is_addr_out_range || (psum_cal_vld && out_ena)) && (is_addr_hit_range_next || pe_idle);// || (~is_psum_out_vld && is_addr_out_range);//C2 may be too long; C1 need 4 BANK ORAM
end

always @( * )begin    
    out_dat = psum_out_dat;
    out_vld = psum_out_vld;
    out_add = psum_add_reg;
    out_lst = psum_out_lst;
end
//=====================================================================================================================
// Logic Design :
//=====================================================================================================================
generate
    for( gen_i=0 ; gen_i < DATA_SUM_NW; gen_i = gen_i+1 ) begin : PSUM_BLOCK
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                psum_cal_reg[gen_i] <= 'd0;
            else if( pe_psum_rst )
                psum_cal_reg[gen_i] <= 'd0;
            else if( pe_idle && din_ena && gen_i==0 )
                psum_cal_reg[gen_i] <= psum_cal_tmp;
            else if( pe_flow && din_ena )begin
                if(  is_addr_out_range )begin
                    if( gen_i==DATA_SUM_NW-1 )
                        psum_cal_reg[gen_i] <= 'd0;
                    else if(  gen_i==0 )//when is_addr_out_range->wei_idx==0, for wei no zero value
                        psum_cal_reg[gen_i] <= psum_cal_tmp;
                    else
                        psum_cal_reg[gen_i] <= psum_cal_reg[gen_i+1];
                end
                else begin
                    if( gen_i==wei_idx_cnt )
                        psum_cal_reg[gen_i] <= psum_cal_tmp;
                end
            end
            else if( pe_flow && din_vld && is_addr_out_range && (~psum_cal_vld || out_ena) && ~is_addr_hit_range_next )begin//addr jump
                if( gen_i==DATA_SUM_NW-1 )
                    psum_cal_reg[gen_i] <= 'd0;
                else
                    psum_cal_reg[gen_i] <= psum_cal_reg[gen_i+1];
            end
            else if( pe_psum && (~psum_cal_vld || out_ena) )begin
                if( gen_i==DATA_SUM_NW-1 )
                    psum_cal_reg[gen_i] <= 'd0;
                else
                    psum_cal_reg[gen_i] <= psum_cal_reg[gen_i+1];
            end
        end
    end
  
endgenerate

always @ ( * )begin
    wei_idx_cnt = wei_idx;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        pe_last_din <= 'd0;
    else if( pe_psum_rst )
        pe_last_din <= 'd0;
    else if( din_ena&&act_lst&&wei_lst )
        pe_last_din <= 'd1;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        out_idx_cnt <= 'd0;
    else if( pe_psum_rst )
        out_idx_cnt <= 'd0;
    else if( pe_psum && out_ena )
        out_idx_cnt <= out_idx_cnt +'d1;
end

always @ ( * )begin
    psum_out_dat = psum_out_clp;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        psum_out_reg <= 'd0;
    else if( pe_psum_rst )
        psum_out_reg <= 'd0;
    else if( is_addr_out_range && din_vld && (~psum_cal_vld || out_ena) )
        psum_out_reg <= psum_cal_reg[0];
    else if( pe_psum && (~psum_cal_vld || out_ena) )
        psum_out_reg <= psum_cal_reg[0];
end

always @ ( * )begin
    psum_out_vld = psum_cal_vld && &psum_cal_cnt;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        psum_cal_vld <= 'd0;
    else if( pe_psum_rst )
        psum_cal_vld <= 'd0;
    else if( ~pe_idle && is_addr_out_range && din_vld )
        psum_cal_vld <= 'd1;
    else if( out_ena && ~pe_psum )
        psum_cal_vld <= 'd0;
    else if( pe_psum )
        psum_cal_vld <= 'd1;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        psum_cal_cnt <= 'd0;
    else if( out_ena )
        psum_cal_cnt <= 'd0;
    else if( psum_cal_vld && psum_cal_cnt!='d3 )
        psum_cal_cnt <= psum_cal_cnt +'d1;
end

wire [8 -1:0] cfg_conv_mul_sel = &psum_cal_cnt ? 'd0 : cfg_conv_mul[8*psum_cal_cnt +:8];
wire signed [DATA_SUM_DW+9 -1:0] psum_cal_mul = $signed(psum_out_reg)*$signed({1'd0, cfg_conv_mul_sel});
wire signed [CONV_CAL_DW   -1:0] psum_cal_sft = psum_cal_mul<<<(8*psum_cal_cnt);
reg  signed [CONV_CAL_DW   -1:0] psum_cal_sum;

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        psum_cal_sum <= 'd0;
    else if( pe_idle || psum_out_vld )
        psum_cal_sum <= {{(CONV_CAL_DW-CONV_ADD_DW){cfg_conv_add[CONV_ADD_DW-1]}},cfg_conv_add};
    else if( psum_cal_vld )
        psum_cal_sum <= psum_cal_sum +psum_cal_sft;
end

wire signed [CONV_CAL_DW -1:0] psum_out_mul = &psum_cal_cnt ? psum_cal_sum : {CONV_CAL_DW{1'd0}};
wire signed [CONV_CAL_DW -1:0] psum_out_sft = $signed(psum_out_mul)>>>cfg_conv_sft;
wire                           psum_rnd_bit = cfg_conv_sft=='d0 ? 'd0 : psum_out_mul[cfg_conv_sft-1];
wire signed [CONV_CAL_DW -1:0] psum_out_rnd = $signed(psum_out_sft) +$signed({1'd0, psum_rnd_bit});
CPM_CLP #( CONV_CAL_DW, DATA_OUT_DW ) PSUM_OUT_CLP_U( psum_out_rnd, psum_out_clp);

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        aram_add_reg <= 'd0;
    else if( pe_psum_rst )
        aram_add_reg <= 'd0;
    else if( pe_idle && din_ena )
        aram_add_reg <= ACT_ADD;
    else if( pe_flow && din_vld && is_addr_out_range && (~psum_cal_vld || out_ena) )
        aram_add_reg <= aram_add_reg+cfg_conv_run;
    else if( pe_psum && (~psum_cal_vld || out_ena) )
        aram_add_reg <= aram_add_reg+cfg_conv_run;
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        psum_add_reg <= 'd0;
    else if( pe_psum_rst )
        psum_add_reg <= 'd0;
    else if( pe_flow && din_vld && is_addr_out_range && (~psum_cal_vld || out_ena) )
        psum_add_reg <= aram_add_reg;
    else if( pe_psum && (~psum_cal_vld || out_ena) )
        psum_add_reg <= aram_add_reg;
end

//MAC
wire [CONV_WEI_DW -1:0] wei_idx_cnt_fix = is_addr_out_range ? 'd1 : wei_idx_cnt;
always @ ( * )begin
    psum_cal_tmp = $signed(ACT_DAT)*$signed(WEI_DAT) +$signed(psum_cal_reg[wei_idx_cnt_fix]);
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
    PE_FLOW: pe_ns = pe_flow_end ? PE_PSUM : pe_cs;
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

reg [DATA_SUM_DW -1:0] ass_psum_out_reg;
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        ass_psum_out_reg <= 'd0;
    else if( pe_psum_rst )
        ass_psum_out_reg <= 'd0;
    else if( is_addr_out_range && din_vld && (~psum_cal_vld || out_ena) )
        ass_psum_out_reg <= psum_cal_reg[0];
    else if( pe_psum && (~psum_cal_vld || out_ena) )
        ass_psum_out_reg <= psum_cal_reg[0];
end


`endif
endmodule
