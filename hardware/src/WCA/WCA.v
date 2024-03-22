// This is a simple example.
// You can make a your own header file and set its path to settings.
// (Preferences > Package Settings > Verilog Gadget > Settings - User)
//
//      "header": "Packages/Verilog Gadget/template/verilog_header.v"
//
// -----------------------------------------------------------------------------
// Copyright (c) 2014-2020 All rights reserved
// -----------------------------------------------------------------------------
// Author : zhouchch@pku.edu.cn
// File   : WCA.v
// Create : 2020-07-14 21:09:52
// Revise : 2020-08-13 10:33:19
// -----------------------------------------------------------------------------
module WCA #( // Weight Cache
    parameter DATA_WIDTH    = 8,
    parameter WEI_ADDR_WIDTH= 8,
    parameter HIT_ADDR_WIDTH= 5,
    parameter NUM_PORT      = 4
    )(
    input                                               clk             ,
    input                                               rst_n           ,

    input                                               TOPWCA_CfgVld   ,
    input                                               TOPWCA_CfgISA   ,
    output                                              WCATOP_CfgRdy   ,

    input                                               FBFWCA_IdxVld   , // Idx from Flag Buffer
    input                                               FBFWCA_Idx      ,
    output                                              WCAFBF_IdxRdy   ,

    input  [NUM_PORT    -1 : 0]                         PERWCA_AdrVld   , // addr from PE row
    input  [NUM_PORT    -1 : 0][WEI_ADDR_WIDTH  -1 : 0] PERWCA_Adr      ,
    output [NUM_PORT    -1 : 0]                         WCAPER_AdrRdy   ,

    output [NUM_PORT    -1 : 0]                         WCAPER_DatVld   , // data to PE row
    output [NUM_PORT    -1 : 0][DATA_WIDTH      -1 : 0] WCAPER_Dat      ,
    input  [NUM_PORT    -1 : 0]                         PERWCA_DatRdy   ,

    output                                              WCAWBF_AdrVld   , // read addr to Weight Buffer
    output [WEI_ADDR_WIDTH                      -1 : 0] WCAWBF_Adr      ,
    input                                               WBFWCA_AdrRdy   ,

    input                                               WBFWCA_DatVld   , // read data from Weight Buffer
    input  [DATA_WIDTH                          -1 : 0] WBFWCA_Dat      ,
    output                                              WCAWBF_DatRdy 

);
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
localparam HIT_ARRAY_LEN = 2**HIT_ADDR_WIDTH;

localparam IDLE    = 3'b000;
localparam CFG     = 3'b001;
localparam WORK    = 3'b010;

//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================

//=====================================================================================================================
// Logic Design: FSM
//=====================================================================================================================

reg [ 3     -1 : 0] state       ;
reg [ 3     -1 : 0] next_state  ;
always @(*) begin
    case ( state )
        IDLE:   if( ASICCCU_start)
                    next_state <= CFG; //A network config a time
                else
                    next_state <= IDLE;
        CFG :   if( fifo_full)
                    next_state <= COMP;
                else
                    next_state <= CFG;
        WORK:   if( all_finish) /// COMP_FRM COMP_PAT COMP_...
                    next_state <= IDLE;
                else
                    next_state <= COMP;
        default:    next_state <= IDLE;
    endcase
end
always @ ( posedge clk or negedge rst_n ) begin
    if ( !rst_n ) begin
        state <= IDLE;
    end else begin
        state <= next_state;
    end
end

//=====================================================================================================================
// Logic Design: S1
//=====================================================================================================================



//=====================================================================================================================
// Logic Design: S2
//=====================================================================================================================

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        WCAWBF_Adr_s2 <= 0;
    end else if(WCAWBF_AdrVld & WBFWCA_AdrRdy) begin
        WCAWBF_Adr_s2 <= WCAWBF_Adr;
    end
end


for(gv_ele=0; gv_ele<HIT_ARRAY_LEN; gv_ele=gv_ele + 1) begin
    assign compare_vector[gv_ele] = hit_idx_array[gv_ele] == PERWCA_Adr[gv_port];
end

assign hit = |compare_vector;
assign hit_rdata = WCAWBF_Adr_s2 == PERWCA_Adr[gv_port];
assign WCAPER_Dat[gv_port] = (hit | hit_rdata)? WBFWCA_Dat : hit_out_s2;


//=====================================================================================================================
// Logic Design: S3
//=====================================================================================================================




//=====================================================================================================================
// Sub-Module :
//=====================================================================================================================




endmodule
