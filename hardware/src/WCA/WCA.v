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
    parameter ISA_WIDTH     = 2,
    parameter DATA_WIDTH    = 8,
    parameter WEI_ADDR_WIDTH= 8,
    parameter HIT_ADDR_WIDTH= 5,
    parameter NUM_PORT      = 4
    )(
    input                                               clk             ,
    input                                               rst_n           ,

    input                                               TOPWCA_CfgVld   ,
    input  [ISA_WIDTH   -1 : 0]                         TOPWCA_CfgISA   ,
    output                                              WCATOP_CfgRdy   ,

    input                                               FBFWCA_IdxVld   , // Idx from Flag Buffer
    input  [WEI_ADDR_WIDTH                      -1 : 0] FBFWCA_Idx      ,
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
reg [ISA_WIDTH                              -1 : 0] cfg_isa;
wire                                                byp;
wire                                                byp_hit;
reg[HIT_ARRAY_LEN   -1 : 0] [WEI_ADDR_WIDTH -1 : 0] hit_idx_array;
reg[HIT_ARRAY_LEN   -1 : 0] [DATA_WIDTH     -1 : 0] hit_data_array;
reg[HIT_ARRAY_LEN   -1 : 0]                         hit_data_vld;
reg                         [HIT_ADDR_WIDTH -1 : 0] addr_idx;
reg                                                 upd_hit_data;
wire[NUM_PORT       -1 : 0] [HIT_ADDR_WIDTH -1 : 0] addr_hit_array;
wire[$clog2(NUM_PORT)                       -1 : 0] ArbIdx;
wire[$clog2(NUM_PORT)                       -1 : 0] ArbIdx_d;
wire[NUM_PORT                               -1 : 0] hit_array;
reg [WEI_ADDR_WIDTH                         -1 : 0] last_idx;
reg                                                 last_data_vld;
reg [DATA_WIDTH                             -1 : 0] last_data;
reg [WEI_ADDR_WIDTH                         -1 : 0] WCAWBF_Adr_s2;
wire[NUM_PORT                               -1 : 0] PortRdAddrVld;
reg [HIT_ADDR_WIDTH                         -1 : 0] upd_hit_data_addr;
integer                                             i;

//=====================================================================================================================
// Logic Design: FSM
//=====================================================================================================================
reg [ 3     -1 : 0] state       ;
reg [ 3     -1 : 0] next_state  ;
always @(*) begin
    case ( state )
        IDLE:   if( TOPWCA_CfgVld )
                    next_state <= CFG;
                else
                    next_state <= IDLE;
        CFG :   next_state <= WORK;
        WORK:   if( TOPWCA_CfgVld )
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

assign WCATOP_CfgRdy = state == IDLE;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        cfg_isa <= 0;
    end else if( state == IDLE ) begin
        cfg_isa <= 0;
    end else if(state == CFG & next_state == WORK) begin
        cfg_isa <= TOPWCA_CfgISA;
    end
end
assign {byp_hit, byp} = cfg_isa;

wire [NUM_PORT  -1 : 0] addr_match_hit;
//=====================================================================================================================
// High Hit Array
//=====================================================================================================================
assign WCAFBF_IdxRdy = state == WORK;

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

    end else if (!byp & byp_hit & WCAWBF_AdrVld & WBFWCA_AdrRdy) begin
        hit_idx_array[addr_idx] <= WCAWBF_Adr;
        addr_idx                <= addr_idx + 1;
    end else if(!byp & !byp_hit & FBFWCA_IdxVld & WCAFBF_IdxRdy) begin
        hit_idx_array[addr_idx] <= FBFWCA_Idx;
        addr_idx                <= addr_idx + 1;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        for(i=0; i<HIT_ARRAY_LEN; i=i+1) begin
            hit_data_array[i]<= 0;
            hit_data_vld      <= 1'b0;
        end
    end else if(state == IDLE) begin
        for(i=0; i<HIT_ARRAY_LEN; i=i+1) begin
            hit_data_array[i]<= 0;
            hit_data_vld      <= 1'b0;
        end
    end else if(!byp & !byp_hit & FBFWCA_IdxVld & WCAFBF_IdxRdy) begin // Over Write -> Set 0
        hit_data_array [addr_idx] <= 0;
        hit_data_vld   [addr_idx] <= 1'b0;
    end else if ( !byp & (byp_hit | upd_hit_data & !hit_data_vld[upd_hit_data_addr]) & WBFWCA_DatVld & WCAWBF_DatRdy) begin
        hit_data_array[upd_hit_data_addr] <= WBFWCA_Dat;
        hit_data_vld   [upd_hit_data_addr] <= 1'b1;
    end
end
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        upd_hit_data   <= 1'b0;
        upd_hit_data_addr <= 0;
    end else if(state == IDLE) begin
        upd_hit_data   <= 1'b0;
        upd_hit_data_addr <= 0;
    end else if(WCAWBF_AdrVld & WBFWCA_AdrRdy) begin
        upd_hit_data   <= addr_match_hit   [ArbIdx];
        upd_hit_data_addr <= addr_hit_array[ArbIdx];
    end else if(WBFWCA_DatVld & WCAWBF_DatRdy) begin
        upd_hit_data   <= 1'b0;
        upd_hit_data_addr <= addr_hit_array[ArbIdx];
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
        last_data_vld <= 1'b0;
    end else if ( WBFWCA_DatVld & WCAWBF_DatRdy ) begin
        last_idx    <= WCAWBF_Adr_s2;
        last_data   <= WBFWCA_Dat;
        last_data_vld<= 1'b1;
    end
end

ArbCore#(
    .NUM_CORE    ( NUM_PORT     ),
    .ADDR_WIDTH  ( WEI_ADDR_WIDTH),
    .DATA_WIDTH  ( DATA_WIDTH   )
) u_ArbPort(
    .clk         ( clk                  ),
    .rst_n       ( rst_n                ),
    .CoreOutVld  ( PortRdAddrVld        ),
    .CoreOutAddr ( PERWCA_Adr           ),
    .CoreOutDat  (                      ),
    .CoreOutRdy  ( PERWCA_DatRdy & {NUM_PORT{state == WORK}}),
    .TopOutVld   ( WCAWBF_AdrVld        ),
    .TopOutAddr  ( WCAWBF_Adr           ),
    .TopOutDat   (                      ),
    .TopOutRdy   ( WCAWBF_DatRdy        ),
    .TOPInRdy    ( WBFWCA_AdrRdy & state == WORK),
    .ArbCoreIdx  ( ArbIdx               ),
    .ArbCoreIdx_d( ArbIdx_d             )
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        WCAWBF_Adr_s2 <= 0;
    end else if(state == IDLE) begin
        WCAWBF_Adr_s2 <= 0;
    end else if(WCAWBF_AdrVld & WBFWCA_AdrRdy) begin
        WCAWBF_Adr_s2 <= WCAWBF_Adr;
    end
end

genvar gv_port;
genvar gv_ele;

generate
    for(gv_port=0; gv_port<NUM_PORT; gv_port=gv_port+1) begin: GV_PORT
        //=====================================================================================================================
        // Variable Definition :
        //=====================================================================================================================
        wire [HIT_ARRAY_LEN     -1 : 0] compare_vector;
        wire                            hit;
        wire                            hit_last;
        wire [HIT_ADDR_WIDTH    -1 : 0] hit_addr;
        wire                            hit_rdata_s2;
        reg                             hit_last_vld_s2;
        reg [DATA_WIDTH         -1 : 0] last_data_s2;

        //=====================================================================================================================
        // Logic Design: S1
        //=====================================================================================================================
        for(gv_ele=0; gv_ele<HIT_ARRAY_LEN; gv_ele=gv_ele + 1) begin
            assign compare_vector[gv_ele] = PERWCA_Adr[gv_port] == hit_idx_array[gv_ele];
        end
        assign addr_match_hit[gv_port] = state == WORK & |compare_vector;
        assign hit          = state == WORK & |compare_vector & hit_data_vld[hit_addr];
        assign hit_last     = state == WORK & PERWCA_Adr[gv_port] == last_idx & last_data_vld;

        First1#(
            .LEN   ( HIT_ARRAY_LEN  )
        ) u_First1(
            .Array ( compare_vector ),
            .Addr  ( hit_addr       )
        );
        assign PortRdAddrVld[gv_port] = state == WORK & (byp | PERWCA_AdrVld[gv_port] & !hit & !hit_last & !hit_rdata_s2);
        assign WCAPER_AdrRdy[gv_port] = state == WORK & ( (WBFWCA_AdrRdy & ArbIdx == gv_port) | hit | hit_last | hit_rdata_s2 ) & (WCAPER_DatVld[gv_port]? PERWCA_DatRdy[gv_port] : 1'b1); // 4 to 1 & valid data is fetched      
        //=====================================================================================================================
        // Logic Design: S2
        //=====================================================================================================================
        reg                         hit_vld_s2;
        wire                        hit_rdy_s2;
        wire                        hit_handshake_s2;
        wire                        hit_ena_s2;
        reg [DATA_WIDTH     -1 : 0] hit_data_s2;

        assign hit_handshake_s2 = hit_vld_s2 & hit_rdy_s2;
        assign hit_ena_s2       = hit_handshake_s2 | !hit_vld_s2;
        assign hit_rdy_s2       = PERWCA_DatRdy[gv_port];
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                hit_data_s2 <= 0;
            end else if(state == IDLE) begin
                hit_data_s2 <= 0;
            end else if( hit_ena_s2 ) begin
                hit_data_s2 <= hit_data_array[hit_addr];
            end
        end
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                hit_vld_s2 <= 0;
            end else if(state == IDLE) begin
                hit_vld_s2 <= 0;
            end else if( hit_ena_s2 ) begin
                hit_vld_s2 <= hit & PERWCA_AdrVld[gv_port];
            end
        end

        wire                        hit_last_handshake_s2;
        wire                        hit_last_ena_s2;
        wire                        hit_last_rdy_s2;
        assign hit_last_handshake_s2   = hit_last_vld_s2 & hit_last_rdy_s2;
        assign hit_last_ena_s2         = hit_last_handshake_s2 | !hit_last_vld_s2;
        assign hit_last_rdy_s2         = PERWCA_DatRdy[gv_port];
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n) begin
                hit_last_vld_s2 <= 1'b0;
                last_data_s2<= 0;
            end else if(state == IDLE) begin
                hit_last_vld_s2 <= 1'b0;
                last_data_s2<= 0;
            end else if( hit_last_ena_s2 ) begin
                hit_last_vld_s2 <= hit_last;
                last_data_s2<= last_data;
            end
        end

        assign hit_array     [gv_port] = hit;
        assign addr_hit_array[gv_port] = hit_addr;

        assign hit_rdata_s2           = state == WORK & ( (WCAWBF_Adr_s2 == PERWCA_Adr[gv_port]) & WBFWCA_DatVld) ; // directly hit rdata
        assign WCAPER_Dat   [gv_port] = state == WORK ? ( ( (byp & ArbIdx_d == gv_port | hit_rdata_s2 | ArbIdx_d == gv_port)? WBFWCA_Dat    : hit_last_vld_s2? last_data_s2 : hit_vld_s2? hit_data_s2 : 0  ) ) : 0;
        assign WCAPER_DatVld[gv_port] = state == WORK & ( (  byp & ArbIdx_d == gv_port | hit_rdata_s2 | ArbIdx_d == gv_port) & WBFWCA_DatVld | hit_last_vld_s2               | hit_vld_s2                  );

    end
endgenerate

wire debug_hit_last_real = GV_PORT[0].hit_last & PERWCA_AdrVld[0];
wire debug_update_hit_data = state == WORK & |GV_PORT[0].compare_vector & PERWCA_AdrVld[0] & !hit_data_vld[GV_PORT[0].hit_addr];

endmodule
