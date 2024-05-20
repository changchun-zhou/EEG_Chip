//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//======================================================
// Description :
//======================================================
module CPM_TOP_K #(
    DATA_DW  =  8,
    INFO_DW  =  8,
    SORT_DW  = 32,
    SORT_AW  = $clog2(SORT_DW)
) (
    input                               clk,
    input                               rst_n,

    input                               clear,

    input                               SORT_DAT_VLD,
    output                              SORT_DAT_RDY,
    input                               SORT_DAT_LST,
    input                [DATA_DW -1:0] SORT_DAT_DAT,
    input                [INFO_DW -1:0] SORT_DAT_INF,

    output                              TOPK_DAT_VLD,
    output [SORT_DW -1:0][DATA_DW -1:0] TOPK_DAT_DAT,
    output [SORT_DW -1:0][INFO_DW -1:0] TOPK_DAT_INF
);
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
integer i;
genvar gen_i, gen_j;

wire                               sort_dat_vld = SORT_DAT_VLD;
wire                               sort_dat_rdy = 'd1;
wire                               sort_dat_lst = SORT_DAT_LST;
wire                [DATA_DW -1:0] sort_dat_dat = SORT_DAT_DAT;
wire                [INFO_DW -1:0] sort_dat_inf = SORT_DAT_INF;
assign SORT_DAT_RDY = sort_dat_rdy;

wire sort_dat_ena = sort_dat_vld && sort_dat_rdy;
wire sort_dat_end = sort_dat_vld && sort_dat_lst;

wire                               topk_dat_vld;
reg   [SORT_DW -1:0][DATA_DW -1:0] topk_dat_dat;
reg   [SORT_DW -1:0][INFO_DW -1:0] topk_dat_inf;

assign TOPK_DAT_VLD = topk_dat_vld;
assign TOPK_DAT_DAT = topk_dat_dat;
assign TOPK_DAT_INF = topk_dat_inf;

reg [SORT_AW -1:0] sort_max_idx;
reg sort_max_vld;


CPM_REG_CE #( 1 ) TOPK_VLD_RED ( clk, rst_n, clear, sort_dat_vld, sort_dat_lst, topk_dat_vld);
//=====================================================================================================================
// Logic Design :
//=====================================================================================================================
generate
    for( gen_i=0 ; gen_i < SORT_DW; gen_i = gen_i+1 )begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )begin
                topk_dat_dat[gen_i] <= 'd0;
                topk_dat_inf[gen_i] <= 'd0;
            end
            else if( clear )begin
                topk_dat_dat[gen_i] <= 'd0;
                topk_dat_inf[gen_i] <= 'd0;
            end
            else if( sort_dat_vld && sort_max_vld )begin
                if( gen_i>sort_max_idx )begin
                    if( gen_i!=0 )begin
                        topk_dat_dat[gen_i] <= topk_dat_dat[gen_i-1];
                        topk_dat_inf[gen_i] <= topk_dat_inf[gen_i-1];
                    end
                end
                else if( gen_i==sort_max_idx )begin
                    topk_dat_dat[gen_i] <= sort_dat_dat;
                    topk_dat_inf[gen_i] <= sort_dat_inf;
                end
            end
        end
    end
endgenerate

always @ ( * )begin
    sort_max_vld = 'd0;
    sort_max_idx = SORT_DW-1;
    for( i = SORT_DW-1; i >= 0; i = i - 1 )begin
        if( sort_dat_dat>topk_dat_dat[i] )begin//equal add to right
            sort_max_vld = 'd1;
            sort_max_idx = i;
        end
    end
end
    
    
endmodule
