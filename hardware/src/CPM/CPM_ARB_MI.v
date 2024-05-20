//======================================================
// Copyright (C) 2020 By 
// All Rights Reserved
//======================================================
// Module : 
// Author : 
// Contact : 
// Date : 
//=======================================================
// Description : Multi Input Arbiter
//========================================================
module CPM_ARB_MI #(
    parameter REQ_DW = 4,
    parameter IDX_AW = 2,
    parameter REQ_AW = $clog2(REQ_DW)
) (
    input                             clk,
    input                             rst_n,
                   
    input  [REQ_DW              -1:0] REQ_ARB,
    input  [REQ_DW -1:0][IDX_AW -1:0] REQ_IDX,
    output [REQ_DW              -1:0] GNT_ARB,
    output [REQ_DW -1:0][IDX_AW -1:0] GNT_IDX
);
integer i;
genvar gen_i;

wire req_vld = |REQ_ARB;
wire [REQ_DW -1:0]              req_arb = REQ_ARB;
wire [REQ_DW -1:0][IDX_AW -1:0] req_idx = REQ_IDX;
wire [REQ_DW -1:0]              gnt_arb;
reg  [REQ_DW -1:0][IDX_AW -1:0] gnt_idx;

assign GNT_ARB = gnt_arb;
assign GNT_IDX = gnt_idx;

reg  [REQ_DW -1:0] req_idx_equ;

reg  [REQ_DW -1:0][IDX_AW -1:0] gnt_pri;
reg  [REQ_DW -1:0][IDX_AW -1:0] req_pri;
reg  [REQ_DW -1:0][IDX_AW -1:0] arb_pri;
reg  [REQ_DW -1:0][IDX_AW -1:0] gen_pri;

always @ ( * )begin//next arbiter priority, high location indicates low priority
    case( gnt_arb )
        4'b0000: gnt_pri = req_pri;
        4'b0001: gnt_pri = {2'd0,2'd3,2'd2,2'd1};
        4'b0010: gnt_pri = {2'd1,2'd3,2'd2,2'd0};
        4'b0011: gnt_pri = {2'd1,2'd0,2'd3,2'd2};
        4'b0100: gnt_pri = {2'd2,2'd3,2'd1,2'd0};
        4'b0101: gnt_pri = {2'd2,2'd0,2'd3,2'd1};
        4'b0110: gnt_pri = {2'd2,2'd1,2'd3,2'd0};
        4'b0111: gnt_pri = {2'd2,2'd1,2'd0,2'd3};
        4'b1000: gnt_pri = {2'd3,2'd2,2'd1,2'd0};
        4'b1001: gnt_pri = {2'd3,2'd0,2'd2,2'd1};
        4'b1010: gnt_pri = {2'd3,2'd1,2'd2,2'd0};
        4'b1011: gnt_pri = {2'd3,2'd1,2'd0,2'd2};
        4'b1100: gnt_pri = {2'd3,2'd2,2'd1,2'd0};
        4'b1101: gnt_pri = {2'd3,2'd2,2'd0,2'd1};
        4'b1110: gnt_pri = {2'd3,2'd2,2'd1,2'd0};
        default: gnt_pri = {2'd3,2'd2,2'd1,2'd0};
    endcase
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        req_pri <= {2'd3,2'd2,2'd1,2'd0};
    else if( req_vld )
        req_pri <= gnt_pri;
end

always @ ( * )begin//next arbiter priority level, high number indicates high priority
    case( gnt_arb )
        4'b0000: arb_pri = gen_pri;
        4'b0001: arb_pri = {2'd1,2'd2,2'd3,2'd0};
        4'b0010: arb_pri = {2'd1,2'd2,2'd0,2'd3};
        4'b0011: arb_pri = {2'd2,2'd3,2'd0,2'd1};
        4'b0100: arb_pri = {2'd1,2'd0,2'd2,2'd3};
        4'b0101: arb_pri = {2'd2,2'd0,2'd3,2'd1};
        4'b0110: arb_pri = {2'd2,2'd0,2'd1,2'd3};
        4'b0111: arb_pri = {2'd3,2'd0,2'd1,2'd2};
        4'b1000: arb_pri = {2'd0,2'd1,2'd2,2'd3};
        4'b1001: arb_pri = {2'd0,2'd2,2'd3,2'd1};
        4'b1010: arb_pri = {2'd0,2'd2,2'd1,2'd3};
        4'b1011: arb_pri = {2'd0,2'd3,2'd1,2'd2};
        4'b1100: arb_pri = {2'd0,2'd1,2'd2,2'd3};
        4'b1101: arb_pri = {2'd0,2'd1,2'd3,2'd2};
        4'b1110: arb_pri = {2'd0,2'd1,2'd2,2'd3};
        default: arb_pri = {2'd0,2'd1,2'd2,2'd3};
    endcase
end

always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        gen_pri <= {2'd0,2'd1,2'd2,2'd3};
    else if( req_vld )
        gen_pri <= arb_pri;
end

generate for( gen_i=0 ; gen_i < REQ_DW; gen_i = gen_i+1 ) begin : ARB_BLOCK
      
    always @ ( * )begin
        req_idx_equ[gen_i] = 'd0;
        for( i = 0; i < REQ_DW; i = i + 1 )begin
            if( (req_idx[i]==req_idx[gen_i]) && (gen_pri[i]>gen_pri[gen_i]) && req_arb[i] )
                req_idx_equ[gen_i] = 'd1;
        end
    end
    
    assign gnt_arb[gen_i] = req_arb[gen_i] && ~req_idx_equ[gen_i];
    
    always @ ( * )begin
        gnt_idx[gen_i] = 'd0;
        for( i = REQ_DW-1; i >= 0; i = i - 1 )begin
            if( ( req_idx[ req_pri[i] ]==gen_i ) && req_arb[ req_pri[i] ] )
                gnt_idx[gen_i] = req_pri[i];
        end
    end
    
end
endgenerate

endmodule
