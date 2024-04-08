`timescale  1 ns / 100 ps

`define CLOCK_PERIOD 5
`define SIM
// `define FUNC_SIM
// `define POST_SIM

`define CEIL(a, b) ( \
 (a % b)? (a / b + 1) : (a / b) \
)
module WCA_tb();
//=====================================================================================================================
// Constant Definition :
//=====================================================================================================================
parameter WBUF_NUM_DW   = 4 ;
parameter WRAM_ADD_AW   = 13;
parameter WRAM_DAT_DW   = 8 ;
parameter STAT_DAT_DW   = 8 ;
parameter HIT_ADDR_WIDTH= 5 ;
//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================
reg                                 clk;
reg                                 rst_n;

reg                                             CFG_INFO_VLD   ;
reg                                             CFG_WBUF_ENA   ;
reg                                             CFG_STAT_VLD   ;
wire                                            CFG_INFO_RDY   ;
reg                                             MTOW_DAT_VLD   ; // Idx from Flag Buffer
reg  [WRAM_ADD_AW                       -1 : 0] MTOW_DAT_DAT   ;
reg                                             MTOW_DAT_LST   ;
wire                                            MTOW_DAT_RDY   ;
reg  [WBUF_NUM_DW    -1 : 0]                    PTOW_ADD_VLD   ; // addr from PE row
reg  [WBUF_NUM_DW    -1 : 0][WRAM_ADD_AW-1 : 0] PTOW_ADD_ADD   ;
reg  [WBUF_NUM_DW    -1 : 0][STAT_DAT_DW-1 : 0] PTOW_ADD_BUF   ;
wire [WBUF_NUM_DW    -1 : 0]                    PTOW_ADD_RDY   ;
reg  [WBUF_NUM_DW    -1 : 0]                    PTOW_ADD_LST   ;
wire [WBUF_NUM_DW    -1 : 0]                    PTOW_DAT_VLD   ; // data to PE row
wire [WBUF_NUM_DW    -1 : 0]                    PTOW_DAT_LST   ;
wire [WBUF_NUM_DW    -1 : 0][WRAM_DAT_DW-1 : 0] PTOW_DAT_DAT   ;
reg  [WBUF_NUM_DW    -1 : 0]                    PTOW_DAT_RDY   ;
wire                                            WRAM_ADD_VLD   ; // read addr to Weight Buffer
wire                                            WRAM_ADD_LST   ; 
wire [WRAM_ADD_AW                       -1 : 0] WRAM_ADD_ADD   ;
wire                                            WRAM_ADD_RDY   ;
reg                                             WRAM_DAT_VLD   ; // read data from Weight Buffer
reg                                             WRAM_DAT_LST   ; 
reg  [WRAM_DAT_DW                       -1 : 0] WRAM_DAT_DAT   ;
wire                                            WRAM_DAT_RDY   ;

//=====================================================================================================================
// Logic Design: Debounce
//=====================================================================================================================
initial begin
    clk = 1;
    forever #(`CLOCK_PERIOD/2) clk=~clk;
end

initial begin
    rst_n                      =  1;
    #(`CLOCK_PERIOD*2)  rst_n  =  0;
    #(`CLOCK_PERIOD*10) rst_n  =  1;
end

initial begin
    $shm_open("TEMPLATE.shm");
    $shm_probe(WCA_tb.u_WCA, "AS");
end

`ifdef POST_SIM
    initial begin 
        $sdf_annotate ("/workspace/home/zhoucc/Proj_HW/PointCloudAcc/hardware/work/synth/TOP/Date230729_0931_Periodclk3.3_Periodsck10_PLL1_group_Track3vt_MaxDynPwr0_OptWgt0.5_Note_FROZEN_V9_PLL&REDUCEPAD/gate/TOP.sdf", u_TOP, , "TOP_sdf.log", "MAXIMUM", "1.0:1.0:1.0", "FROM_MAXIMUM");
    end 

    reg EnTcf;
    initial begin
        EnTcf = 1'b0;
    end
`endif

//=====================================================================================================================
// Logic Design:
//=====================================================================================================================
integer seed;
initial begin
    seed = 0;
end

// TOP
initial begin
    CFG_INFO_VLD <= 0;
    {CFG_STAT_VLD, CFG_WBUF_ENA} <= 0;
    @(posedge rst_n);
    @(posedge clk);
    // @(CFG_INFO_RDY == 1);
    CFG_INFO_VLD = #0.3 1'b1;
    {CFG_STAT_VLD, CFG_WBUF_ENA} = 2'b11; 
    @(posedge clk);
    @(posedge clk);
    CFG_INFO_VLD =      1'b0;
end

// FBF
reg [10: 0] cnt_idx;
initial begin
    MTOW_DAT_VLD = 0;
    MTOW_DAT_DAT    = 0;
    cnt_idx       = 0;
    @(posedge rst_n);
    repeat(90) begin
        @(posedge clk);
        if(!MTOW_DAT_VLD | MTOW_DAT_RDY) begin
            MTOW_DAT_VLD = #0.3 {$random(seed)} % 2;
            MTOW_DAT_DAT    = {$random(seed)} % 128; 
            cnt_idx       = cnt_idx + 1;
        end
    end
    MTOW_DAT_VLD = 0;
    MTOW_DAT_DAT    = 0;
end

// PER
genvar gv_i;
generate
    for(gv_i=0; gv_i<WBUF_NUM_DW; gv_i=gv_i+1) begin
        initial begin
            PTOW_ADD_VLD[gv_i] <= 0;
            {PTOW_ADD_ADD[gv_i], PTOW_ADD_BUF[gv_i], PTOW_ADD_LST[gv_i]} <= 0;
            @(posedge rst_n);
            forever begin
                @(posedge clk);
                if(!PTOW_ADD_VLD  [gv_i] | PTOW_ADD_RDY[gv_i]) begin
                    PTOW_ADD_VLD  [gv_i] = #0.3 {$random(seed)} % 2;
                    PTOW_ADD_ADD     [gv_i] =   {$random(seed)} % 128; 
                    PTOW_ADD_BUF     [gv_i] =   {$random(seed)} % 128; 
                    PTOW_ADD_LST     [gv_i] =   {$random(seed)} % 2;
                end
            end
        end
        initial begin
            PTOW_DAT_RDY[gv_i] <= 0;
            @(posedge rst_n);
            forever begin
                @(posedge clk);
                PTOW_DAT_RDY[gv_i] = #0.3 {$random(seed)} % 2;
            end
        end 
    end       
endgenerate

// WBF
assign WRAM_ADD_RDY = !WRAM_DAT_VLD | WRAM_DAT_RDY;
initial begin
    WRAM_DAT_VLD   = 0;
    WRAM_DAT_DAT      = 0;
    WRAM_DAT_LST    = 0;
    @(posedge rst_n);
    forever begin
        @(posedge clk);
        if(WRAM_ADD_VLD & WRAM_ADD_RDY) begin
            WRAM_DAT_VLD = #0.3 1'b1;
            WRAM_DAT_DAT    = {$random(seed)} % 256;
            WRAM_DAT_LST    = WRAM_ADD_LST;
        end else if(WRAM_DAT_VLD & WRAM_DAT_RDY) begin
            WRAM_DAT_VLD = #0.3 1'b0;
            WRAM_DAT_DAT    =       0;
            WRAM_DAT_LST = 0;
        end
    end     
end 

WCA u_WCA(
    .clk           ( clk           ),
    .rst_n         ( rst_n         ),
    .CFG_INFO_VLD  ( CFG_INFO_VLD  ),
    .CFG_INFO_RDY  ( CFG_INFO_RDY  ),
    .CFG_WBUF_ENA  ( CFG_WBUF_ENA  ),
    .CFG_STAT_VLD  ( CFG_STAT_VLD  ),
    .MTOW_DAT_VLD  ( MTOW_DAT_VLD  ),
    .MTOW_DAT_LST  ( MTOW_DAT_LST  ),
    .MTOW_DAT_RDY  ( MTOW_DAT_RDY  ),
    .MTOW_DAT_DAT  ( MTOW_DAT_DAT  ),
    .PTOW_ADD_VLD  ( PTOW_ADD_VLD  ),
    .PTOW_ADD_LST  ( PTOW_ADD_LST  ),
    .PTOW_ADD_RDY  ( PTOW_ADD_RDY  ),
    .PTOW_ADD_ADD  ( PTOW_ADD_ADD  ),
    .PTOW_ADD_BUF  ( PTOW_ADD_BUF  ),
    .PTOW_DAT_VLD  ( PTOW_DAT_VLD  ),
    .PTOW_DAT_LST  ( PTOW_DAT_LST  ),
    .PTOW_DAT_RDY  ( PTOW_DAT_RDY  ),
    .PTOW_DAT_DAT  ( PTOW_DAT_DAT  ),
    .WRAM_ADD_VLD  ( WRAM_ADD_VLD  ),
    .WRAM_ADD_RDY  ( WRAM_ADD_RDY  ),
    .WRAM_ADD_LST  ( WRAM_ADD_LST  ),
    .WRAM_ADD_ADD  ( WRAM_ADD_ADD  ),
    .WRAM_DAT_VLD  ( WRAM_DAT_VLD  ),
    .WRAM_DAT_LST  ( WRAM_DAT_LST  ),
    .WRAM_DAT_DAT  ( WRAM_DAT_DAT  ),
    .WRAM_DAT_RDY  ( WRAM_DAT_RDY  )
);

endmodule