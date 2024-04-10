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
module EEG_WRAM_WBUF #( // Weight Cache
    parameter WBUF_NUM_DW   = 4 ,
    parameter WRAM_ADD_AW   = 13,
    parameter WRAM_DAT_DW   = 8 ,
    parameter STAT_DAT_DW   = 8 ,
    parameter STAT_NUM_DW   = 32, 
    parameter HIT_ADDR_WIDTH= $clog2(STAT_NUM_DW)
    )(
    input                                               clk             ,
    input                                               rst_n           ,

    input                                               CFG_INFO_VLD    ,
    output                                              CFG_INFO_RDY    ,
    input                                               CFG_WBUF_ENA    ,
    input                                               CFG_STAT_VLD    ,

    input                                               MTOW_DAT_VLD    , // Idx from Flag Buffer
    input                                               MTOW_DAT_LST    , // Not Used
    output                                              MTOW_DAT_RDY    ,
    input  [STAT_DAT_DW                         -1 : 0] MTOW_DAT_DAT    ,

    input  [WBUF_NUM_DW    -1 : 0]                      PTOW_ADD_VLD    , // addr from PE row
    input  [WBUF_NUM_DW    -1 : 0]                      PTOW_ADD_LST    ,
    output [WBUF_NUM_DW    -1 : 0]                      PTOW_ADD_RDY    ,
    input  [WBUF_NUM_DW    -1 : 0][WRAM_ADD_AW  -1 : 0] PTOW_ADD_ADD    ,
    input  [WBUF_NUM_DW    -1 : 0][STAT_DAT_DW  -1 : 0] PTOW_ADD_BUF    ,

    output [WBUF_NUM_DW    -1 : 0]                      PTOW_DAT_VLD    , // data to PE row
    output reg[WBUF_NUM_DW -1 : 0]                      PTOW_DAT_LST    ,   
    input  [WBUF_NUM_DW    -1 : 0]                      PTOW_DAT_RDY    ,
    output reg[WBUF_NUM_DW -1 : 0][WRAM_DAT_DW  -1 : 0] PTOW_DAT_DAT    ,

    output                                              WRAM_ADD_VLD    , // read addr to Weight Buffer
    input                                               WRAM_ADD_RDY    ,
    output                                              WRAM_ADD_LST    ,
    output [WRAM_ADD_AW                         -1 : 0] WRAM_ADD_ADD    ,

    input                                               WRAM_DAT_VLD    , // read data from Weight Buffer
    input                                               WRAM_DAT_LST    ,
    input  [WRAM_DAT_DW                         -1 : 0] WRAM_DAT_DAT    ,
    output                                              WRAM_DAT_RDY 

);
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
localparam HIT_ARRAY_LEN = 2**HIT_ADDR_WIDTH;
localparam ISA_WIDTH     = 2;

localparam IDLE    = 3'b000;
localparam CFG     = 3'b001;
localparam WORK    = 3'b010;

//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================
reg [ISA_WIDTH                              -1 : 0] cfg_isa;
wire                                                byp;
wire                                                byp_hit;
reg[HIT_ARRAY_LEN   -1 : 0] [STAT_DAT_DW    -1 : 0] hit_idx_array;
reg[HIT_ARRAY_LEN   -1 : 0] [WRAM_DAT_DW    -1 : 0] hit_data_array;
reg[HIT_ARRAY_LEN   -1 : 0]                         hit_data_vld;
reg                         [HIT_ADDR_WIDTH -1 : 0] addr_idx;
reg                                                 upd_hit_data;
wire[WBUF_NUM_DW    -1 : 0] [HIT_ADDR_WIDTH -1 : 0] addr_hit_array;
wire[$clog2(WBUF_NUM_DW)                    -1 : 0] ArbIdx;
wire[$clog2(WBUF_NUM_DW)                    -1 : 0] ArbIdx_d;
wire[WBUF_NUM_DW                            -1 : 0] hit_array;
reg [STAT_DAT_DW                            -1 : 0] last_idx;
reg                                                 last_data_vld;
reg [WRAM_DAT_DW                            -1 : 0] last_data;
reg [WRAM_ADD_AW                            -1 : 0] WCAWBF_Adr_s2;
wire[WBUF_NUM_DW                            -1 : 0] PortRdAddrVld;
reg [HIT_ADDR_WIDTH                         -1 : 0] upd_hit_data_addr;
wire [WBUF_NUM_DW   -1 : 0][WRAM_ADD_AW + 1 -1 : 0] PortRdAddrLst;

genvar                                              gv_port;
genvar                                              gv_ele;
integer                                             i;

//=====================================================================================================================
// Logic Design: FSM
//=====================================================================================================================
reg [ 3     -1 : 0] state       ;
reg [ 3     -1 : 0] next_state  ;
always @(*) begin
    case ( state )
        IDLE:   if( CFG_INFO_VLD )
                    next_state <= CFG;
                else
                    next_state <= IDLE;
        CFG :   next_state <= WORK;
        WORK:   if( CFG_INFO_VLD )
                    next_state <= IDLE;
                else
                    next_state <= WORK;
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

assign CFG_INFO_RDY = state == IDLE;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cfg_isa <= 0;
    end else if( state == IDLE ) begin
        cfg_isa <= 0;
    end else if(state == CFG & next_state == WORK) begin
        cfg_isa <= {!CFG_STAT_VLD, !CFG_WBUF_ENA};
    end
end
assign {byp_hit, byp} = cfg_isa;

wire [WBUF_NUM_DW  -1 : 0] addr_match_hit;

//=====================================================================================================================
// High Hit Array
//=====================================================================================================================
assign MTOW_DAT_RDY = state == WORK;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<HIT_ARRAY_LEN; i=i+1) begin
            hit_idx_array[i]<= 0;
        end
        addr_idx            <= 0;
    end else if(state == IDLE) begin
        for(i=0; i<HIT_ARRAY_LEN; i=i+1) begin
            hit_idx_array[i]<= 0;
        end
        addr_idx            <= 0;

    end else if (!byp & byp_hit & WRAM_ADD_VLD & WRAM_ADD_RDY) begin
        hit_idx_array[addr_idx] <= WRAM_ADD_ADD;
        addr_idx                <= addr_idx + 1;
    end else if(!byp & !byp_hit & MTOW_DAT_VLD & MTOW_DAT_RDY) begin
        hit_idx_array[addr_idx] <= MTOW_DAT_DAT;
        addr_idx                <= addr_idx + 1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<HIT_ARRAY_LEN; i=i+1) begin
            hit_data_array[i]<= 0;
            hit_data_vld     <= 1'b0;
        end
    end else if(state == IDLE) begin
        for(i=0; i<HIT_ARRAY_LEN; i=i+1) begin
            hit_data_array[i]<= 0;
            hit_data_vld     <= 1'b0;
        end
    end else if(!byp & !byp_hit & MTOW_DAT_VLD & MTOW_DAT_RDY) begin // Over Write -> Set 0
        hit_data_array [addr_idx] <= 0;
        hit_data_vld   [addr_idx] <= 1'b0;
    end else if ( !byp & (byp_hit | upd_hit_data & !hit_data_vld[upd_hit_data_addr]) & WRAM_DAT_VLD & WRAM_DAT_RDY) begin
        hit_data_array[upd_hit_data_addr] <= WRAM_DAT_DAT;
        hit_data_vld  [upd_hit_data_addr] <= 1'b1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        upd_hit_data        <= 1'b0;
        upd_hit_data_addr   <= 0;
    end else if(state == IDLE) begin
        upd_hit_data        <= 1'b0;
        upd_hit_data_addr   <= 0;
    end else if(WRAM_ADD_VLD & WRAM_ADD_RDY) begin
        upd_hit_data        <= addr_match_hit   [ArbIdx];
        upd_hit_data_addr   <= addr_hit_array[ArbIdx];
    end else if(WRAM_DAT_VLD & WRAM_DAT_RDY) begin
        upd_hit_data        <= 1'b0;
        upd_hit_data_addr   <= addr_hit_array[ArbIdx];
    end
end

//=====================================================================================================================
// Last Access
//=====================================================================================================================
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        last_idx    <= 0;
        last_data   <= 0;
        last_data_vld<= 1'b0;
    end else if(state == IDLE) begin
        last_idx    <= 0;
        last_data   <= 0;
        last_data_vld<= 1'b0;
    end else if ( WRAM_DAT_VLD & WRAM_DAT_RDY ) begin
        last_idx    <= WCAWBF_Adr_s2;
        last_data   <= WRAM_DAT_DAT;
        last_data_vld<= 1'b1;
    end
end

generate
    for(gv_port=0; gv_port<WBUF_NUM_DW; gv_port=gv_port+1)begin
        assign PortRdAddrLst[gv_port] = PortRdAddrVld? {PTOW_ADD_ADD[gv_port], PTOW_ADD_LST[gv_port]} : 0;
    end
endgenerate
ArbCore#(
    .NUM_CORE    ( WBUF_NUM_DW      ),
    .ADDR_WIDTH  ( WRAM_ADD_AW + 1  ),
    .DATA_WIDTH  ( WRAM_DAT_DW      )
) u_ArbPort(
    .clk         ( clk                                          ),
    .rst_n       ( rst_n                                        ),
    .CoreOutVld  ( PortRdAddrVld                                ),
    .CoreOutAddr ( PortRdAddrLst                                ),
    .CoreOutDat  (                                              ),
    .CoreOutRdy  ( PTOW_DAT_RDY & {WBUF_NUM_DW{state == WORK}}  ),
    .TopOutVld   ( WRAM_ADD_VLD                                 ),
    .TopOutAddr  ( {WRAM_ADD_ADD, WRAM_ADD_LST}                 ),
    .TopOutDat   (                                              ),
    .TopOutRdy   ( WRAM_DAT_RDY                                 ),
    .TOPInRdy    ( WRAM_ADD_RDY & state == WORK                 ),
    .ArbCoreIdx  ( ArbIdx                                       ),
    .ArbCoreIdx_d( ArbIdx_d                                     )
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        WCAWBF_Adr_s2 <= 0;
    end else if(state == IDLE) begin
        WCAWBF_Adr_s2 <= 0;
    end else if(WRAM_ADD_VLD & WRAM_ADD_RDY) begin
        WCAWBF_Adr_s2 <= WRAM_ADD_ADD;
    end
end

generate
    for(gv_port=0; gv_port<WBUF_NUM_DW; gv_port=gv_port+1) begin: GV_PORT
        //=====================================================================================================================
        // Variable Definition :
        //=====================================================================================================================
        wire [HIT_ARRAY_LEN     -1 : 0] compare_vector;
        wire                            hit;
        wire                            hit_last;
        wire [HIT_ADDR_WIDTH    -1 : 0] hit_addr;
        reg                             hit_last_vld_s2;
        reg [WRAM_DAT_DW         -1 : 0] last_data_s2;
        reg                             last_data_LST_s2;

        //=====================================================================================================================
        // Logic Design: S1
        //=====================================================================================================================
        for(gv_ele=0; gv_ele<HIT_ARRAY_LEN; gv_ele=gv_ele + 1) begin
            assign compare_vector[gv_ele] = PTOW_ADD_BUF[gv_port] == hit_idx_array[gv_ele];
        end
        assign addr_match_hit[gv_port]  = state == WORK & |compare_vector;
        assign hit                      = state == WORK & |compare_vector & hit_data_vld[hit_addr];
        assign hit_last                 = state == WORK & PTOW_ADD_BUF[gv_port] == last_idx & last_data_vld;

        First1#(
            .LEN   ( HIT_ARRAY_LEN  )
        ) u_First1(
            .Array ( compare_vector ),
            .Addr  ( hit_addr       )
        );
        assign PortRdAddrVld[gv_port] = state == WORK & PTOW_ADD_VLD[gv_port] & (byp | !hit & !hit_last);
        assign PTOW_ADD_RDY [gv_port] = state == WORK & ( (WRAM_ADD_RDY & ArbIdx == gv_port) | hit | hit_last) & (PTOW_DAT_VLD[gv_port]? PTOW_DAT_RDY[gv_port] : 1'b1); // 4 to 1 & valid data is fetched      
        //=====================================================================================================================
        // Logic Design: S2
        //=====================================================================================================================
        reg                         hit_vld_s2;
        wire                        hit_rdy_s2;
        wire                        hit_handshake_s2;
        wire                        hit_ena_s2;
        reg [WRAM_DAT_DW    -1 : 0] hit_data_s2;
        reg                         hit_data_LST_s2;

        assign hit_handshake_s2     = hit_vld_s2 & hit_rdy_s2;
        assign hit_ena_s2           = hit_handshake_s2 | !hit_vld_s2;
        assign hit_rdy_s2           = PTOW_DAT_RDY[gv_port];
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                {hit_data_s2, hit_data_LST_s2} <= 0;
            end else if(state == IDLE) begin
                {hit_data_s2, hit_data_LST_s2} <= 0;
            end else if( hit_ena_s2 ) begin
                {hit_data_s2, hit_data_LST_s2} <= {hit_data_array[hit_addr], PTOW_ADD_LST[gv_port]};
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                hit_vld_s2 <= 0;
            end else if(state == IDLE) begin
                hit_vld_s2 <= 0;
            end else if( hit_ena_s2 ) begin
                hit_vld_s2 <= hit & PTOW_ADD_VLD[gv_port];
            end
        end

        wire                            hit_last_handshake_s2;
        wire                            hit_last_ena_s2;
        wire                            hit_last_rdy_s2;
        assign hit_last_handshake_s2    = hit_last_vld_s2 & hit_last_rdy_s2;
        assign hit_last_ena_s2          = hit_last_handshake_s2 | !hit_last_vld_s2;
        assign hit_last_rdy_s2          = PTOW_DAT_RDY[gv_port];
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                {last_data_s2, last_data_LST_s2, hit_last_vld_s2} <= 0;
            end else if(state == IDLE) begin
                {last_data_s2, last_data_LST_s2, hit_last_vld_s2} <= 0;
            end else if( hit_last_ena_s2 ) begin
                {last_data_s2, last_data_LST_s2, hit_last_vld_s2} <= {last_data, PTOW_ADD_LST[gv_port], hit_last & PTOW_ADD_VLD[gv_port]};
            end
        end

        assign hit_array     [gv_port] = hit;
        assign addr_hit_array[gv_port] = hit_addr;

        always @(*) begin
            if(state == WORK) begin
                if(( ArbIdx_d == gv_port)) begin
                    {PTOW_DAT_DAT  [gv_port], PTOW_DAT_LST[gv_port]} = {WRAM_DAT_DAT, WRAM_DAT_LST};
                end else if(hit_last_vld_s2) begin
                    {PTOW_DAT_DAT  [gv_port], PTOW_DAT_LST[gv_port]} = {last_data_s2, last_data_LST_s2};
                end else if(hit_vld_s2) begin
                    {PTOW_DAT_DAT  [gv_port], PTOW_DAT_LST[gv_port]} = {hit_data_s2 , hit_data_LST_s2};
                end else begin
                    {PTOW_DAT_DAT  [gv_port], PTOW_DAT_LST[gv_port]} = 0;
                end
            end else begin
                    {PTOW_DAT_DAT  [gv_port], PTOW_DAT_LST[gv_port]} = 0;
            end
        end
        assign PTOW_DAT_VLD  [gv_port]= state == WORK & ( (  byp & ArbIdx_d == gv_port | ArbIdx_d == gv_port) & WRAM_DAT_VLD | hit_last_vld_s2               | hit_vld_s2                  );

    end
endgenerate

`ifdef SIM
    wire debug_hit_last_real = GV_PORT[0].hit_last & PTOW_ADD_VLD[0];
    wire debug_update_hit_data = state == WORK & |GV_PORT[0].compare_vector & PTOW_ADD_VLD[0] & !hit_data_vld[GV_PORT[0].hit_addr];
    wire debug_hit_real = state == WORK & |GV_PORT[3].compare_vector & PTOW_ADD_VLD[3];
`endif

endmodule
