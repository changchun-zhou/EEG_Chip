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
`ifndef EEG_DUMP
  `define EEG_DUMP

module EEG_DUMP(
  input   clk,
  input   rst_n,
  
  input   DumpStart,
  input   DumpEnd
);

localparam CHIP_DAT_DW = `CHIP_DAT_DW;
localparam CHIP_OUT_DW = `CHIP_OUT_DW;
localparam CHIP_SUM_DW = `CHIP_SUM_DW;
localparam CHIP_CMD_DW = `CHIP_CMD_DW;
localparam BANK_NUM_DW = `BANK_NUM_DW;
localparam ORAM_NUM_DW = `ORAM_NUM_DW;
localparam OMUX_NUM_DW = `OMUX_NUM_DW;
localparam OMUX_RAM_DW = `OMUX_RAM_DW;
localparam FRAM_RAM_DW = `FRAM_RAM_DW;
localparam STAT_NUM_DW = `STAT_NUM_DW;
localparam WRAM_NUM_DW = `WRAM_NUM_DW;
localparam ARAM_NUM_DW = `ARAM_NUM_DW;
localparam WBUF_NUM_DW = `WBUF_NUM_DW;
localparam WRAM_ADD_AW = `WRAM_ADD_AW;
localparam WRAM_DAT_DW = `WRAM_DAT_DW;
localparam ARAM_ADD_AW = `ARAM_ADD_AW;
localparam ARAM_DAT_DW = `ARAM_DAT_DW;

localparam WADD_BUF_AW = 8;
localparam WRAM_ADD_DW = 1<<WRAM_ADD_AW;
localparam ARAM_ADD_DW = 1<<ARAM_ADD_AW;

string  f_data, f_flag;
integer p_data, p_flag;
string dump_path;
string cmd;
genvar gen_i, gen_j;
integer i, j;
int layer_num;
int layer_from;
int file_cnt;
int file_ptr;
string layer_num_file;

initial begin
    $system("rm ./dump -rf");
    cmd = $psprintf("mkdir ./dump");
    $display(cmd);
    $system(cmd);
end

always begin
    @(top.frame_start)begin
        //layer_num
        layer_num_file = $psprintf("./case/Frame%02d/layer_num.txt", top.frame_cnt);
        file_ptr = $fopen(layer_num_file, "r");
        if( file_ptr )begin
            file_cnt = $fscanf(file_ptr,"%d\n", layer_num);
            file_cnt = $fscanf(file_ptr,"%d\n", layer_from);
            $fclose(file_ptr);
        end
        
        dump_path = $psprintf("./dump/Frame%02d/Layer%02d/true", top.frame_cnt, top.layer_cnt +layer_from);
        cmd = $psprintf("mkdir ./dump/Frame%02d", top.frame_cnt);
        $display(cmd);
        $system(cmd);
    end
end

always begin
    @(top.layer_start)begin
        dump_path = $psprintf("./dump/Frame%02d/Layer%02d/true", top.frame_cnt, top.layer_cnt +layer_from);
        cmd = $psprintf("mkdir ./dump/Frame%02d/Layer%02d", top.frame_cnt, top.layer_cnt +layer_from);
        $display(cmd);
        $system(cmd);
        cmd = $psprintf("mkdir ./dump/Frame%02d/Layer%02d/true", top.frame_cnt, top.layer_cnt +layer_from);
        $display(cmd);
        $system(cmd);
    end
end

`ifndef SIM_POST
reg [ `ORAM_NUM_DW -1:0][`OMUX_NUM_DW -1:0][`OMUX_RAM_DW -1:0][24 -1:0] omux_data;
generate
    for( gen_i=0 ; gen_i < `ORAM_NUM_DW; gen_i = gen_i+1 ) begin
        for( gen_j=0 ; gen_j < `OMUX_NUM_DW; gen_j = gen_j+1 ) begin
            always @ ( posedge clk or negedge rst_n )begin
                if( ~rst_n )begin
                    omux_data[gen_i][gen_j] <= 'd0;
                end
                else if( top.DumpEnd )begin
                    omux_data[gen_i][gen_j] <= 'd0;
                end
                else if( top.EEG_TOP_U.EEG_ACC_U.EEG_PEAY_U.EEG_PEA_ENG_U.EEG_PEA_ENG_PE_U[gen_i*`ORAM_NUM_DW+gen_j].OUT_VLD && top.EEG_TOP_U.EEG_ACC_U.EEG_PEAY_U.EEG_PEA_ENG_U.EEG_PEA_ENG_PE_U[gen_i*`ORAM_NUM_DW+gen_j].OUT_RDY )begin
                    omux_data[gen_i][gen_j][top.EEG_TOP_U.EEG_ACC_U.EEG_PEAY_U.EEG_PEA_ENG_U.EEG_PEA_ENG_PE_U[gen_i*`ORAM_NUM_DW+gen_j].OUT_ADD] <= top.EEG_TOP_U.EEG_ACC_U.EEG_PEAY_U.EEG_PEA_ENG_U.EEG_PEA_ENG_PE_U[gen_i*`ORAM_NUM_DW+gen_j].ass_psum_out_reg;
                end
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < `ORAM_NUM_DW; gen_i = gen_i+1 ) begin
        for( gen_j=0 ; gen_j < `OMUX_NUM_DW; gen_j = gen_j+1 ) begin
            always @ ( posedge clk or negedge rst_n )begin
                if( top.DumpEnd )begin
                    f_data = $psprintf("%s/omux_%1d_%1d.txt", dump_path, gen_i, gen_j);
                    p_data = $fopen(f_data, "ab+");
                    for( i = 0; i < `OMUX_RAM_DW; i = i + 1 )begin
                        $fwrite(p_data, "%8d\n", $signed(omux_data[gen_i][gen_j][i]));
                    end
                    $fclose(p_data);
                end
            end
        end
    end
endgenerate

reg [ `BANK_NUM_DW -1:0][`FRAM_RAM_DW -1:0][4 -1:0] fram_data;
generate
    for( gen_i=0 ; gen_i < `BANK_NUM_DW; gen_i = gen_i+1 ) begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )begin
                fram_data[gen_i] <= 'd0;
            end
            else if( top.DumpEnd )begin
                fram_data[gen_i] <= 'd0;
            end
            else if( top.EEG_TOP_U.EEG_ACC_U.EEG_FRAM_U.ETOF_DAT_VLD[gen_i] && top.EEG_TOP_U.EEG_ACC_U.EEG_FRAM_U.ETOF_DAT_RDY[gen_i] )begin
                fram_data[gen_i][top.EEG_TOP_U.EEG_ACC_U.EEG_FRAM_U.ETOF_DAT_ADD[gen_i]] <= top.EEG_TOP_U.EEG_ACC_U.EEG_FRAM_U.ETOF_DAT_DAT[gen_i];
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < `BANK_NUM_DW; gen_i = gen_i+1 ) begin
        always @ ( posedge clk or negedge rst_n )begin
            if( top.DumpEnd )begin
                f_data = $psprintf("%s/fram_%1d.txt", dump_path, gen_i);
                p_data = $fopen(f_data, "ab+");
                for( i = 0; i < `FRAM_RAM_DW; i = i + 1 )begin
                    $fwrite(p_data, "%4b\n", $signed(fram_data[gen_i][i]));
                end
                $fclose(p_data);
            end
        end
    end
endgenerate

wire topk_vld_tmp = top.EEG_TOP_U.EEG_ACC_U.EEG_RAM_MOVER_U.wsta_dat_vld && top.EEG_TOP_U.EEG_ACC_U.EEG_RAM_MOVER_U.wsta_dat_lst && top.EEG_TOP_U.EEG_ACC_U.EEG_RAM_MOVER_U.move_otoa;
wire topk_vld;
CPM_REG #( 1 ) TOPK_VLD_REG ( clk, rst_n, topk_vld_tmp, topk_vld );
generate
    for( gen_i=0 ; gen_i < `BANK_NUM_DW; gen_i = gen_i+1 ) begin
        always @ ( posedge clk or negedge rst_n )begin
            if( topk_vld )begin
                f_data = $psprintf("%s/topk_%1d.txt", dump_path, gen_i);
                p_data = $fopen(f_data, "ab+");
                for( i = 0; i < `STAT_NUM_DW; i = i + 1 )begin
                    $fwrite(p_data, "%8d\n", $signed(top.EEG_TOP_U.EEG_ACC_U.EEG_RAM_MOVER_U.topk_dat_inf[gen_i][i]));
                end
                $fclose(p_data);
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < `BANK_NUM_DW; gen_i = gen_i+1 ) begin
        always @ ( posedge clk or negedge rst_n )begin
            if( top.EEG_TOP_U.EEG_ACC_U.EEG_RAM_MOVER_U.mtos_dat_ena[gen_i] )begin
                f_data = $psprintf("%s/wsta_%1d.txt", dump_path, gen_i);
                p_data = $fopen(f_data, "ab+");
                    $fwrite(p_data, "%8d\n", top.EEG_TOP_U.EEG_ACC_U.EEG_RAM_MOVER_U.mtos_dat_dat[gen_i]);
                $fclose(p_data);
            end
        end
    end
endgenerate
`endif

always @ ( posedge clk or negedge rst_n )begin
    if( top.EEG_TOP_U.EEG_ACC_U.CHIP_OUT_VLD && top.EEG_TOP_U.EEG_ACC_U.CHIP_OUT_RDY )begin
        f_data = $psprintf("%s/oram_%1d.txt", dump_path, $clog2(top.EEG_TOP_U.EEG_ACC_U.cfg_oram_idx));
        p_data = $fopen(f_data, "ab+");
        $fwrite(p_data, "%2h\n", $signed(top.EEG_TOP_U.EEG_ACC_U.CHIP_OUT_DAT));
        //if( top.EEG_TOP_U.EEG_ACC_U.CHIP_OUT_DAT inside {[{`CHIP_OUT_DW{1'd0}}:{`CHIP_OUT_DW{1'd1}}]}  )
        //    $fwrite(p_data, "%2h\n", $signed(top.EEG_TOP_U.EEG_ACC_U.CHIP_OUT_DAT));
        //else
        //    $fwrite(p_data, "%2h\n", $signed('d0));
        $fclose(p_data);
    end
end

`ifdef ASSERT_ON
reg [ ARAM_NUM_DW -1:0][ARAM_ADD_DW -1:0][ARAM_DAT_DW -1:0] aram_data_reg;
generate
    for( gen_i=0 ; gen_i < ARAM_NUM_DW; gen_i = gen_i+1 ) begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                aram_data_reg[gen_i] <= 'd0;
            else if( top.EEG_TOP_U.EEG_ACC_U.EEG_ARAM_U.ETOA_DAT_VLD[gen_i] && top.EEG_TOP_U.EEG_ACC_U.EEG_ARAM_U.ETOA_DAT_RDY[gen_i] )begin
                aram_data_reg[gen_i][top.EEG_TOP_U.EEG_ACC_U.EEG_ARAM_U.ETOA_DAT_ADD[gen_i]] <= top.EEG_TOP_U.EEG_ACC_U.EEG_ARAM_U.ETOA_DAT_DAT[gen_i];
            end
        end
    end
endgenerate

reg [ WRAM_NUM_DW -1:0][WRAM_ADD_DW -1:0][WRAM_DAT_DW -1:0] wram_data_reg;
generate
    for( gen_i=0 ; gen_i < WRAM_NUM_DW; gen_i = gen_i+1 ) begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )
                wram_data_reg[gen_i] <= 'd0;
            else if( top.EEG_TOP_U.EEG_ACC_U.EEG_WRAM_U.ETOW_DAT_VLD[gen_i] && top.EEG_TOP_U.EEG_ACC_U.EEG_WRAM_U.ETOW_DAT_RDY[gen_i] )begin
                wram_data_reg[gen_i][top.EEG_TOP_U.EEG_ACC_U.EEG_WRAM_U.ETOW_DAT_ADD[gen_i]] <= top.EEG_TOP_U.EEG_ACC_U.EEG_WRAM_U.ETOW_DAT_DAT[gen_i];
            end
        end
    end
endgenerate

reg  [WRAM_NUM_DW -1:0][WBUF_NUM_DW -1:0] wadd_fifo_wen;
reg  [WRAM_NUM_DW -1:0][WBUF_NUM_DW -1:0] wadd_fifo_ren;
wire [WRAM_NUM_DW -1:0][WBUF_NUM_DW -1:0] wadd_fifo_empty;
wire [WRAM_NUM_DW -1:0][WBUF_NUM_DW -1:0] wadd_fifo_full;
reg  [WRAM_NUM_DW -1:0][WBUF_NUM_DW -1:0][WRAM_ADD_AW -1:0] wadd_fifo_din;
wire [WRAM_NUM_DW -1:0][WBUF_NUM_DW -1:0][WRAM_ADD_AW -1:0] wadd_fifo_out;
wire [WRAM_NUM_DW -1:0][WBUF_NUM_DW -1:0][WADD_BUF_AW   :0] wadd_fifo_cnt;
reg  [WRAM_NUM_DW -1:0][WBUF_NUM_DW -1:0][WRAM_ADD_AW -1:0] wram_addr;
reg  [WRAM_NUM_DW -1:0][WBUF_NUM_DW -1:0][WRAM_DAT_DW -1:0] wram_data;
reg  [WRAM_NUM_DW -1:0][WBUF_NUM_DW -1:0][WRAM_DAT_DW -1:0] wbuf_data;
reg  [WRAM_NUM_DW -1:0][WBUF_NUM_DW -1:0] wbuf_read;
CPM_FIFO #( .DATA_WIDTH( WRAM_ADD_AW ), .ADDR_WIDTH( WADD_BUF_AW ) ) WADD_FIFO_U[WRAM_NUM_DW*WBUF_NUM_DW -1:0] ( clk, rst_n, 1'd0, wadd_fifo_wen, wadd_fifo_ren, wadd_fifo_din, wadd_fifo_out, wadd_fifo_empty, wadd_fifo_full, wadd_fifo_cnt);

generate
    for( gen_i=0 ; gen_i < WRAM_NUM_DW; gen_i = gen_i+1 ) begin
        for( gen_j=0 ; gen_j < WBUF_NUM_DW; gen_j = gen_j+1 ) begin
            always @ ( * )begin
                wadd_fifo_wen[gen_i][gen_j] = top.EEG_TOP_U.EEG_ACC_U.EEG_WRAM_WBUF_U[gen_i].PTOW_ADD_VLD[gen_j] && top.EEG_TOP_U.EEG_ACC_U.EEG_WRAM_WBUF_U[gen_i].PTOW_ADD_RDY[gen_j];
                wadd_fifo_ren[gen_i][gen_j] = top.EEG_TOP_U.EEG_ACC_U.EEG_WRAM_WBUF_U[gen_i].PTOW_DAT_VLD[gen_j] && top.EEG_TOP_U.EEG_ACC_U.EEG_WRAM_WBUF_U[gen_i].PTOW_DAT_RDY[gen_j];
                wadd_fifo_din[gen_i][gen_j] = top.EEG_TOP_U.EEG_ACC_U.EEG_WRAM_WBUF_U[gen_i].PTOW_ADD_ADD[gen_j];
            end
        end
    end
endgenerate
generate
    for( gen_i=0 ; gen_i < WRAM_NUM_DW; gen_i = gen_i+1 ) begin
        for( gen_j=0 ; gen_j < WBUF_NUM_DW; gen_j = gen_j+1 ) begin
            always @ ( * )begin
                wram_addr[gen_i][gen_j] = wadd_fifo_out[gen_i][gen_j];
                wram_data[gen_i][gen_j] = wram_data_reg[gen_i][wadd_fifo_out[gen_i][gen_j]];
                wbuf_data[gen_i][gen_j] = top.EEG_TOP_U.EEG_ACC_U.EEG_WRAM_WBUF_U[gen_i].PTOW_DAT_DAT[gen_j];
                wbuf_read[gen_i][gen_j] = wadd_fifo_ren[gen_i][gen_j];
            end
        end
    end
endgenerate

property wbuf_data_check(wbuf_ena, wbuf_dat, wram_data);
@(negedge clk)
disable iff(rst_n!=1'b1)
    wbuf_ena |-> ( wbuf_dat==wram_data );
endproperty

generate
    for( gen_i=0 ; gen_i < WRAM_NUM_DW; gen_i = gen_i+1 ) begin
        for( gen_j=0 ; gen_j < WBUF_NUM_DW; gen_j = gen_j+1 ) begin
            assert property ( wbuf_data_check(wbuf_read[gen_i][gen_j], wram_data[gen_i][gen_j], wbuf_data[gen_i][gen_j]) )begin
            end
            else begin
                $display("WBUF_DATA checl failed!!! i=%d, j=%d, wbuf_data=%x, wram_data=%x, wram_addr=%x", gen_i, gen_j, wbuf_data[gen_i][gen_j], wram_data[gen_i][gen_j], wram_addr[gen_i][gen_j]);
            end
        end
    end
endgenerate

`endif

endmodule

`endif
