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
parameter ISA_WIDTH     = 2;
parameter DATA_WIDTH    = 8;
parameter WEI_ADDR_WIDTH= 8;
parameter HIT_ADDR_WIDTH= 5;
parameter NUM_PORT      = 4;

//=====================================================================================================================
// Variable Definition :
//=====================================================================================================================
reg                                 clk;
reg                                 rst_n;

reg                                               TOPWCA_CfgVld   ;
reg  [ISA_WIDTH   -1 : 0]                         TOPWCA_CfgISA   ;
wire                                              WCATOP_CfgRdy   ;
reg                                               FBFWCA_IdxVld   ; // Idx from Flag Buffer
reg  [WEI_ADDR_WIDTH                      -1 : 0] FBFWCA_Idx      ;
wire                                              WCAFBF_IdxRdy   ;
reg  [NUM_PORT    -1 : 0]                         PERWCA_AdrVld   ; // addr from PE row
reg  [NUM_PORT    -1 : 0][WEI_ADDR_WIDTH  -1 : 0] PERWCA_Adr      ;
wire [NUM_PORT    -1 : 0]                         WCAPER_AdrRdy   ;
wire [NUM_PORT    -1 : 0]                         WCAPER_DatVld   ; // data to PE row
wire [NUM_PORT    -1 : 0][DATA_WIDTH      -1 : 0] WCAPER_Dat      ;
reg  [NUM_PORT    -1 : 0]                         PERWCA_DatRdy   ;
wire                                              WCAWBF_AdrVld   ; // read addr to Weight Buffer
wire [WEI_ADDR_WIDTH                      -1 : 0] WCAWBF_Adr      ;
wire                                              WBFWCA_AdrRdy   ;
reg                                               WBFWCA_DatVld   ; // read data from Weight Buffer
reg  [DATA_WIDTH                          -1 : 0] WBFWCA_Dat      ;
wire                                              WCAWBF_DatRdy   ;

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
    TOPWCA_CfgVld = 0;
    TOPWCA_CfgISA = 0;
    @(posedge rst_n);
    @(posedge clk);
    // @(WCATOP_CfgRdy == 1);
    TOPWCA_CfgVld = 1'b1;
       TOPWCA_CfgISA = 2'b00; 
    @(posedge clk);
    @(posedge clk);
    TOPWCA_CfgVld = 1'b0;
end

// FBF
initial begin
    FBFWCA_IdxVld = 0;
    FBFWCA_Idx    = 0;
    @(posedge rst_n);
    repeat(64) begin
        @(posedge clk);
        if(!FBFWCA_IdxVld | WCAFBF_IdxRdy) begin
            FBFWCA_IdxVld = {$random(seed)} % 2;
            FBFWCA_Idx    = {$random(seed)} % 128; 
        end
    end
    FBFWCA_IdxVld = 0;
    FBFWCA_Idx    = 0;
end

// PER
genvar gv_i;
generate
    for(gv_i=0; gv_i<NUM_PORT; gv_i=gv_i+1) begin
        initial begin
            PERWCA_AdrVld[gv_i] = 0;
            PERWCA_Adr   [gv_i] = 0;
            @(posedge rst_n);
            forever begin
                @(posedge clk);
                if(!PERWCA_AdrVld  [gv_i] | WCAPER_AdrRdy[gv_i]) begin
                    PERWCA_AdrVld  [gv_i] = {$random(seed)} % 2;
                    PERWCA_Adr     [gv_i] = {$random(seed)} % 128; 
                end
            end
        end
        initial begin
            PERWCA_DatRdy[gv_i] = 0;
            @(posedge rst_n);
            forever begin
                @(posedge clk);
                PERWCA_DatRdy[gv_i] = {$random(seed)} % 2;
            end
        end 
    end       
endgenerate

// WBF
// initial begin
//     WBFWCA_AdrRdy = 0;
//     @(posedge rst_n);
//     forever begin
//         @(posedge clk);
//         if(!WBFWCA_DatVld | WCAWBF_DatRdy)
//             WBFWCA_AdrRdy <= #1 1'b1;
//         else
//             WBFWCA_AdrRdy <= #1 1'b0;
//     end
// end    
assign WBFWCA_AdrRdy = !WBFWCA_DatVld | WCAWBF_DatRdy;

initial begin
    WBFWCA_DatVld   = 0;
    WBFWCA_Dat      = 0;
    @(posedge rst_n);
    forever begin
        @(posedge clk);
        if(WCAWBF_AdrVld & WBFWCA_AdrRdy) begin
            WBFWCA_DatVld <= 1'b1;
            WBFWCA_Dat    <= {$random(seed)} % 256;
        end else if(WBFWCA_DatVld & WCAWBF_DatRdy) begin
            WBFWCA_DatVld <= 1'b0;
            WBFWCA_Dat    <= 0;
        end
    end     
end 

WCA u_WCA(
    .clk             ( clk             ),
    .rst_n           ( rst_n           ),
    .TOPWCA_CfgVld   ( TOPWCA_CfgVld   ),
    .TOPWCA_CfgISA   ( TOPWCA_CfgISA   ),
    .WCATOP_CfgRdy   ( WCATOP_CfgRdy   ),
    .FBFWCA_IdxVld   ( FBFWCA_IdxVld   ),
    .FBFWCA_Idx      ( FBFWCA_Idx      ),
    .WCAFBF_IdxRdy   ( WCAFBF_IdxRdy   ),
    .PERWCA_AdrVld   ( PERWCA_AdrVld   ),
    .PERWCA_Adr      ( PERWCA_Adr      ),
    .WCAPER_AdrRdy   ( WCAPER_AdrRdy   ),
    .WCAPER_DatVld   ( WCAPER_DatVld   ),
    .WCAPER_Dat      ( WCAPER_Dat      ),
    .PERWCA_DatRdy   ( PERWCA_DatRdy   ),
    .WCAWBF_AdrVld   ( WCAWBF_AdrVld   ),
    .WCAWBF_Adr      ( WCAWBF_Adr      ),
    .WBFWCA_AdrRdy   ( WBFWCA_AdrRdy   ),
    .WBFWCA_DatVld   ( WBFWCA_DatVld   ),
    .WBFWCA_Dat      ( WBFWCA_Dat      ),
    .WCAWBF_DatRdy   ( WCAWBF_DatRdy   )
);

endmodule