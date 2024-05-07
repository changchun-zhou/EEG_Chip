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
`ifndef ENV
  `define ENV

`include "../../tb/EEG_IF.sv"
`include "../../tb/CFG.sv"

class ENV #(type IF_T = vEEG_IF, type IF_B = vEEG_TB);
    IF_B  eeg_if;
    CFG   cfg;
    int   frame_idx;
    
    event run_done;
    
    extern function new( IF_B eeg_if, event run_done, int frame_idx);
    extern virtual function void build();
    extern virtual function void init();
    extern virtual task eeg_cmd(input bit [31:0] chip_dat_dat);
    extern virtual task eeg_dat(input bit [ 7:0] chip_dat_dat, input bit chip_dat_lst);
    extern virtual task eeg_cfg();
    extern virtual task eeg_run();
   
endclass: ENV

function ENV::new( IF_B eeg_if, event run_done, int frame_idx);
    this.eeg_if = eeg_if;
    this.run_done = run_done;
    
    this.frame_idx = frame_idx;
    
    cfg = new(frame_idx);
endfunction: new

function void ENV::build();
    string cmd_path;
    
    $display("ENV build");
    
    cmd_path = $psprintf("./case/Frame%02d", this.frame_idx+1);
    cfg.read_cfg(cmd_path);

endfunction: build

function void ENV::init( );
    $display("ENV init");
   
endfunction: init

task ENV::eeg_cmd(input bit [31:0] chip_dat_dat);

        for (int k=0; k< 4; k++) begin
            eeg_if.txcb_dat.chip_dat_vld <= 'd1;
            eeg_if.txcb_dat.chip_dat_dat <= chip_dat_dat[8*k +:8];
            eeg_if.txcb_dat.chip_dat_cmd <= 'd1;
            eeg_if.txcb_dat.chip_dat_lst <= k==3;
            do begin
                @eeg_if.txcb_dat;
            end while( ~eeg_if.txcb_dat.chip_dat_rdy );
            eeg_if.txcb_dat.chip_dat_vld <= 'd0;
            eeg_if.txcb_dat.chip_dat_lst <= 'd0;
            //@eeg_if.txcb_dat;
        end
   
endtask: eeg_cmd

task ENV::eeg_dat(input bit [7:0] chip_dat_dat, input bit chip_dat_lst);

        eeg_if.txcb_dat.chip_dat_vld <= 'd1;
        eeg_if.txcb_dat.chip_dat_dat <= chip_dat_dat;
        eeg_if.txcb_dat.chip_dat_cmd <= 'd0;
        eeg_if.txcb_dat.chip_dat_lst <= chip_dat_lst;
        do begin
            @eeg_if.txcb_dat;
        end while( ~eeg_if.txcb_dat.chip_dat_rdy );
        eeg_if.txcb_dat.chip_dat_vld <= 'd0;
        eeg_if.txcb_dat.chip_dat_lst <= 'd0;
        //@eeg_if.txcb_dat;
   
endtask: eeg_dat

task ENV::eeg_cfg();

        //act
        for (int i=0; i<`BANK_NUM_DW; i++) begin
            eeg_cmd(cfg.cfg_act_cmd[i][0]);
            for (int j=0; j<cfg.cfg_act_dat[i].size(); j++) begin
                eeg_dat(cfg.cfg_act_dat[i][j], j==(cfg.cfg_act_dat[i].size()-1));
            end
        end
        //wei
        for (int i=0; i<`BANK_NUM_DW; i++) begin
            eeg_cmd(cfg.cfg_wei_cmd[i][0]);
            for (int j=0; j<cfg.cfg_wei_dat[i].size(); j++) begin
                eeg_dat(cfg.cfg_wei_dat[i][j], j==(cfg.cfg_wei_dat[i].size()-1));
            end
        end
        //cmd
        for (int j=0; j<cfg.cfg_cmd.size(); j++) begin
            eeg_cmd(cfg.cfg_cmd[j]);
        end


endtask: eeg_cfg

task ENV::eeg_run();
    $display("ENV eeg_run");
    
    fork
        for (int i=0; i<`BANK_NUM_DW; i++) begin
            for (int j=0; j<`OMUX_NUM_DW; j++) begin
                do begin
                    `ifdef RANDOM
                        eeg_if.txcb_out.chip_out_rdy <= $urandom%2;
                    `else
                        eeg_if.txcb_out.chip_out_rdy <= 1;
                    `endif
                    @eeg_if.txcb_out;
                end while( ~(eeg_if.txcb_out.chip_out_rdy && eeg_if.txcb_out.chip_out_vld && eeg_if.txcb_out.chip_out_lst) );
                eeg_if.txcb_out.chip_out_rdy <= 0;
            end
        end
    
    join_none
    
    wait fork;
    $display("ENV eeg_run done");
    ->run_done;
endtask: eeg_run

`endif
