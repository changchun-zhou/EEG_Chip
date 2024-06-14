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

reg [2 -1:0] cmd_data_cnt;
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        cmd_data_cnt <= 'd0;
    else if( top.EEG_TOP_U.CHIP_DAT_VLD_PAD && top.EEG_TOP_U.CHIP_DAT_RDY_PAD && top.EEG_TOP_U.CHIP_DAT_CMD_PAD )
        cmd_data_cnt <= cmd_data_cnt +'d1;
end


reg [32 -1:0] cmd_data;
always @ ( posedge clk or negedge rst_n )begin
    if( ~rst_n )
        cmd_data <= 'd0;
    else if( top.EEG_TOP_U.CHIP_DAT_VLD_PAD && top.EEG_TOP_U.CHIP_DAT_RDY_PAD && top.EEG_TOP_U.CHIP_DAT_CMD_PAD && top.EEG_TOP_U.CHIP_DAT_LST_PAD )
        cmd_data <= 'd0;
    else if( top.EEG_TOP_U.CHIP_DAT_VLD_PAD && top.EEG_TOP_U.CHIP_DAT_RDY_PAD && top.EEG_TOP_U.CHIP_DAT_CMD_PAD )
        cmd_data <= cmd_data | {24'd0,top.EEG_TOP_U.CHIP_DAT_DAT_PAD}<<(8*cmd_data_cnt);
end

wire [4 -1:0] oram_idx_tmp = cmd_data[8 +:4];
wire [4 -1:0] wram_idx_tmp = cmd_data[12+:4];
wire [4 -1:0] aram_idx_tmp = cmd_data[16+:4];

//MOVE_BUF
localparam XIDX_BUF_DW = 12;
localparam XIDX_BUF_AW = 4;
wire  xidx_buf_wen = top.EEG_TOP_U.CHIP_DAT_VLD_PAD && top.EEG_TOP_U.CHIP_DAT_RDY_PAD && top.EEG_TOP_U.CHIP_DAT_LST_PAD && top.EEG_TOP_U.CHIP_DAT_CMD_PAD && cmd_data[0 +:4]=='d8;
wire  xidx_buf_ren = top.EEG_TOP_U.CHIP_OUT_VLD_PAD && top.EEG_TOP_U.CHIP_OUT_RDY_PAD && top.EEG_TOP_U.CHIP_OUT_LST_PAD;
wire  xidx_buf_empty;
wire  xidx_buf_full;
wire [XIDX_BUF_DW -1:0] xidx_buf_din = {aram_idx_tmp, wram_idx_tmp, oram_idx_tmp};
wire [XIDX_BUF_DW -1:0] xidx_buf_out;
wire [XIDX_BUF_AW   :0] xidx_buf_cnt;

wire [4 -1:0] oram_idx = xidx_buf_out[0+:4];
wire [4 -1:0] wram_idx = xidx_buf_out[4+:4];
wire [4 -1:0] aram_idx = xidx_buf_out[8+:4];

CPM_FIFO #( .DATA_WIDTH( XIDX_BUF_DW ), .ADDR_WIDTH( XIDX_BUF_AW ) ) XIDX_FIFO_U ( clk, rst_n, 1'd0, xidx_buf_wen, xidx_buf_ren, xidx_buf_din, xidx_buf_out, xidx_buf_empty, xidx_buf_full, xidx_buf_cnt);


always @ ( posedge clk or negedge rst_n )begin
    if( top.EEG_TOP_U.CHIP_OUT_VLD_PAD && top.EEG_TOP_U.CHIP_OUT_RDY_PAD && |oram_idx )begin
        f_data = $psprintf("%s/oram_%1d.txt", dump_path, $clog2(oram_idx));
        p_data = $fopen(f_data, "ab+");
        $fwrite(p_data, "%2h\n", $signed(top.EEG_TOP_U.CHIP_OUT_DAT_PAD));
        //if( top.EEG_TOP_U.EEG_ACC_U.CHIP_OUT_DAT inside {[{`CHIP_OUT_DW{1'd0}}:{`CHIP_OUT_DW{1'd1}}]}  )
        //    $fwrite(p_data, "%2h\n", $signed(top.EEG_TOP_U.EEG_ACC_U.CHIP_OUT_DAT));
        //else
        //    $fwrite(p_data, "%2h\n", $signed('d0));
        $fclose(p_data);
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( top.EEG_TOP_U.CHIP_OUT_VLD_PAD && top.EEG_TOP_U.CHIP_OUT_RDY_PAD && |aram_idx )begin
        f_data = $psprintf("%s/aram_%1d.txt", dump_path, $clog2(aram_idx));
        p_data = $fopen(f_data, "ab+");
        $fwrite(p_data, "%2h\n", $signed(top.EEG_TOP_U.CHIP_OUT_DAT_PAD));
        //if( top.EEG_TOP_U.EEG_ACC_U.CHIP_OUT_DAT inside {[{`CHIP_OUT_DW{1'd0}}:{`CHIP_OUT_DW{1'd1}}]}  )
        //    $fwrite(p_data, "%2h\n", $signed(top.EEG_TOP_U.EEG_ACC_U.CHIP_OUT_DAT));
        //else
        //    $fwrite(p_data, "%2h\n", $signed('d0));
        $fclose(p_data);
    end
end

always @ ( posedge clk or negedge rst_n )begin
    if( top.EEG_TOP_U.CHIP_OUT_VLD_PAD && top.EEG_TOP_U.CHIP_OUT_RDY_PAD && |wram_idx )begin
        f_data = $psprintf("%s/wram_%1d.txt", dump_path, $clog2(wram_idx));
        p_data = $fopen(f_data, "ab+");
        $fwrite(p_data, "%2h\n", $signed(top.EEG_TOP_U.CHIP_OUT_DAT_PAD));
        //if( top.EEG_TOP_U.EEG_ACC_U.CHIP_OUT_DAT inside {[{`CHIP_OUT_DW{1'd0}}:{`CHIP_OUT_DW{1'd1}}]}  )
        //    $fwrite(p_data, "%2h\n", $signed(top.EEG_TOP_U.EEG_ACC_U.CHIP_OUT_DAT));
        //else
        //    $fwrite(p_data, "%2h\n", $signed('d0));
        $fclose(p_data);
    end
end

`ifndef SIM_POST
//flag_cnt
`define EEG_ACC_U  top.EEG_TOP_U.EEG_ACC_U
`define EEG_PEAY_U top.EEG_TOP_U.EEG_ACC_U.EEG_PEAY_U
`define EEG_WRAM_U top.EEG_TOP_U.EEG_ACC_U.EEG_WRAM_U
`define EEG_DGEN_U top.EEG_TOP_U.EEG_ACC_U.EEG_PEAY_U.EEG_PEA_DAT_GEN_U

reg [ `BANK_NUM_DW -1:0][32 -1:0] wram_read_cnt;
generate
    for( gen_i=0 ; gen_i < `BANK_NUM_DW; gen_i = gen_i+1 ) begin
        always @ ( posedge clk or negedge rst_n )begin
            if( `EEG_ACC_U.acc_cs != `EEG_ACC_U.ACC_CONV  )begin
                wram_read_cnt[gen_i] <= 'd0;
            end
            else if( `EEG_WRAM_U.etow_add_ena[gen_i] && `EEG_DGEN_U[gen_i].ff_cs!=`EEG_DGEN_U[gen_i].FF_MULT && `EEG_DGEN_U[gen_i].ff_cs!=`EEG_DGEN_U[gen_i].FF_BIAS )begin
                wram_read_cnt[gen_i] <= wram_read_cnt[gen_i] +'d1;
            end
        end
    end
endgenerate

reg [ `BANK_NUM_DW -1:0][32 -1:0] fram_flag_cnt;
reg [ `BANK_NUM_DW -1:0][32 -1:0] fram_full_cnt;
reg [32 -1:0] fram_flag_sum;
reg [32 -1:0] fram_full_sum;
generate
    for( gen_i=0 ; gen_i < `BANK_NUM_DW; gen_i = gen_i+1 ) begin
        always @ ( posedge clk or negedge rst_n )begin
            if( top.EEG_TOP_U.EEG_ACC_U.acc_cs != top.EEG_TOP_U.EEG_ACC_U.ACC_CONV  )begin
                fram_flag_cnt[gen_i] <= 'd0;
                fram_full_cnt[gen_i] <= 'd0;
            end
            else if( `EEG_PEAY_U.fram_dat_vld[gen_i] && `EEG_PEAY_U.fram_dat_rdy[gen_i] )begin
                fram_flag_cnt[gen_i] <= fram_flag_cnt[gen_i] +`EEG_PEAY_U.fram_dat_dat[gen_i][0] +`EEG_PEAY_U.fram_dat_dat[gen_i][1] +`EEG_PEAY_U.fram_dat_dat[gen_i][2] +`EEG_PEAY_U.fram_dat_dat[gen_i][3];
                fram_full_cnt[gen_i] <= fram_full_cnt[gen_i] +'d4;
            end
        end
    end
endgenerate

always @ ( * )begin
    fram_flag_sum = 0;
    fram_full_sum = 0;
    for( i = 0; i < `BANK_NUM_DW; i = i + 1 )begin
        fram_flag_sum += fram_flag_cnt[i];
        fram_full_sum += fram_full_cnt[i];
    end
end

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
reg [ `BANK_NUM_DW -1:0] fram_flag;
generate
    for( gen_i=0 ; gen_i < `BANK_NUM_DW; gen_i = gen_i+1 ) begin
        always @ ( posedge clk or negedge rst_n )begin
            if( ~rst_n )begin
                fram_data[gen_i] <= 'd0;
                fram_flag[gen_i] <= 'd0;
            end
            else if( top.DumpEnd )begin
                fram_data[gen_i] <= 'd0;
                fram_flag[gen_i] <= 'd0;
            end
            else if( top.EEG_TOP_U.EEG_ACC_U.EEG_FRAM_U.ETOF_DAT_VLD[gen_i] && top.EEG_TOP_U.EEG_ACC_U.EEG_FRAM_U.ETOF_DAT_RDY[gen_i] )begin
                fram_data[gen_i][top.EEG_TOP_U.EEG_ACC_U.EEG_FRAM_U.ETOF_DAT_ADD[gen_i]] <= top.EEG_TOP_U.EEG_ACC_U.EEG_FRAM_U.ETOF_DAT_DAT[gen_i];
                fram_flag[gen_i] <= 'd1;
            end
        end
    end
endgenerate

generate
    for( gen_i=0 ; gen_i < `BANK_NUM_DW; gen_i = gen_i+1 ) begin
        always @ ( posedge clk or negedge rst_n )begin
            if( top.DumpEnd && fram_flag[gen_i] )begin
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

reg [11:0] last_state;
reg [63:0] last_change_time;
reg [63:0] state_start_time;
int cal_sum;
int use_sum;
int est_sum;
real fram_rate;
real effi_rate;

initial begin
    $timeformat(-9, 0, "", 12);
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        last_state <= top.EEG_TOP_U.EEG_ACC_U.ACC_IDLE;
        last_change_time <= 0;
        state_start_time <= 0;
    end 
    else if (top.EEG_TOP_U.EEG_ACC_U.acc_cs != last_state) begin
        last_change_time <= $time;
        state_start_time <= $time;
        last_state <= top.EEG_TOP_U.EEG_ACC_U.acc_cs;
    end
end

wire [32 -1:0] all_sum = (top.EEG_TOP_U.EEG_ACC_U.cfg_conv_wei+1)*(top.EEG_TOP_U.EEG_ACC_U.cfg_conv_ich+1)*(top.EEG_TOP_U.EEG_ACC_U.cfg_conv_och+1)*(top.EEG_TOP_U.EEG_ACC_U.cfg_conv_len+1)*4;
always @(posedge clk or negedge rst_n) begin
    if (top.EEG_TOP_U.EEG_ACC_U.acc_cs != last_state) begin
        if (last_state == top.EEG_TOP_U.EEG_ACC_U.ACC_CONV ) begin
            f_data = $psprintf("./dump/Frame%02d/state_time.txt", top.frame_cnt);
            p_data = $fopen(f_data, "ab+");
            //$fdisplay(p_data, "Layer %02d, At time %t ns, State %s lasted for %t clk, flag_cnt: %6d, rate: %t/%6.0f", \
            //        top.layer_cnt, $time, state2string(last_state), ($time - state_start_time)/`CLK_PERIOD, fram_flag_sum, fram_flag_sum*(top.EEG_TOP_U.EEG_ACC_U.cfg_conv_wei+1)/16, ($time - state_start_time)/`CLK_PERIOD);
            cal_sum = top.EEG_TOP_U.EEG_ACC_U.cfg_conv_ich==0 ? fram_flag_sum*(top.EEG_TOP_U.EEG_ACC_U.cfg_conv_wei+1)/16 : fram_flag_sum*(top.EEG_TOP_U.EEG_ACC_U.cfg_conv_wei+1)/4;
            use_sum = ($time - state_start_time)/`CLK_PERIOD;
            est_sum = all_sum*1.0*fram_flag_sum/fram_full_sum/16;
            fram_rate = fram_flag_sum*1.0/fram_full_sum -0.0001;
            effi_rate = est_sum*1.0/use_sum;
            $fdisplay(p_data, "%t Layer %02d, act_rate: %03.2f%%, %6d/%6d, efficiency: %2.2f%%, %6d/%6d, wram: %6d,%6d,%6d,%6d", $time, top.layer_cnt, fram_rate*100, fram_flag_sum, fram_full_sum, effi_rate*100, est_sum, use_sum, wram_read_cnt[0], wram_read_cnt[1], wram_read_cnt[2], wram_read_cnt[3]);
            $fclose(p_data);
        end
    end
end

function [63:0] state2string(input [14 -1:0] last_state);
    case (last_state)
        top.EEG_TOP_U.EEG_ACC_U.ACC_IDLE: state2string = "ACC_IDLE";
        top.EEG_TOP_U.EEG_ACC_U.ACC_LOAD: state2string = "ACC_LOAD";
        top.EEG_TOP_U.EEG_ACC_U.ACC_ACMD: state2string = "ACC_ACMD";
        top.EEG_TOP_U.EEG_ACC_U.ACC_ITOA: state2string = "ACC_ITOA";
        top.EEG_TOP_U.EEG_ACC_U.ACC_ITOW: state2string = "ACC_ITOW";
        top.EEG_TOP_U.EEG_ACC_U.ACC_OTOA: state2string = "ACC_OTOA";
        top.EEG_TOP_U.EEG_ACC_U.ACC_ATOW: state2string = "ACC_ATOW";
        top.EEG_TOP_U.EEG_ACC_U.ACC_WTOA: state2string = "ACC_WTOA";
        top.EEG_TOP_U.EEG_ACC_U.ACC_CONV: state2string = "ACC_CONV";
        top.EEG_TOP_U.EEG_ACC_U.ACC_POOL: state2string = "ACC_POOL";
        top.EEG_TOP_U.EEG_ACC_U.ACC_STAT: state2string = "ACC_STAT";
        top.EEG_TOP_U.EEG_ACC_U.ACC_READ: state2string = "ACC_READ";
        top.EEG_TOP_U.EEG_ACC_U.ACC_WTOS: state2string = "ACC_WTOS";
        top.EEG_TOP_U.EEG_ACC_U.ACC_ACTF: state2string = "ACC_ACTF";
        default : state2string = "ACC_DEFT";
    endcase
endfunction

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

`endif

endmodule

`endif
