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
`ifndef TEST
  `define TEST
  
`include "../../tb/ENV.sv"
`include "../../tb/EEG_IF.sv"
`include "../../tb/DEFINE.sv"

program automatic TEST(
  input bit clk, 
  EEG_IF eeg_if
);

  ENV env;
  event run_done;
  string cmd;
  int frame_num;
  int layer_idx_fix = 0;

  task reset();
 
    eeg_if.txcb_dat.chip_dat_cmd <= 'd0;
    eeg_if.txcb_dat.chip_dat_vld <= 'd0;
    eeg_if.txcb_dat.chip_dat_lst <= 'd0;
    eeg_if.txcb_dat.chip_dat_dat <= 'd0;

    eeg_if.txcb_out.chip_out_rdy <= 'd0;
  
    top.rst_n <= 1'd0;
    repeat(80+$urandom%20) @ (posedge clk);
    top.rst_n <= 1'd1;
    repeat(20+$urandom%20) @ (posedge clk);
    top.rst_n <= 1'd0;
    repeat(10+$urandom%20) @ (posedge clk);
    top.rst_n <= 1'd1;
    repeat(30+$urandom%20) @ (posedge clk);
  endtask: reset

  task dump_en();

    top.DumpStart <= 1'd1;
    @ (posedge clk);
    top.DumpStart <= 1'd0;

  endtask: dump_en

  task frame_start();

    $display("frame_start");
    ->top.frame_start;
  endtask: frame_start

  task frame_done();

    $display("frame_done");
    top.frame_cnt <= top.frame_cnt +1'd1;
  endtask: frame_done

  task layer_start();

    $display($time, "layer_start");
    ->top.layer_start;
  endtask: layer_start

  task layer_done();

    $display($time, "layer_done");
    //repeat(1000+$urandom%20) @ (posedge clk);
    @ (posedge clk);
    top.DumpEnd <= 1'd1;
    @ (posedge clk);
    top.DumpEnd <= 1'd0;
    top.layer_cnt <= top.layer_cnt +1'd1;    
  endtask: layer_done

  task done_compare(int frame_idx, int layer_raw, int layer_idx);

    //$system("echo 'run python compare.py'");
    cmd = $psprintf("python ../../python/compare.py %0d %0d %0d", frame_idx, layer_raw, layer_idx);
    $display(cmd);
    $system(cmd);
  endtask: done_compare
  
  task run_model(int index);

    $system("echo 'run python model'");
    cmd = $psprintf("python ../../python/eeg_gen.py %0d",index);
    $display(cmd);
    $system(cmd);
    $display("python model done");
  endtask: run_model

  initial begin
    frame_num = 1;
    reset();
    for (int i=0; i<frame_num; i++) begin
        frame_start();
        
        //run_model(i);
        env = new(eeg_if, run_done, i);
        
        env.read_cfg_ram();
        env.eeg_cfg_ram();
        for (int j=0; j<env.layer_num; j++) begin
            layer_idx_fix = j +env.layer_from;
            layer_start();
            env.read_cfg_cmd(layer_idx_fix);
            fork
                env.eeg_cfg_cmd();
                if( ( env.is_read==1 ) || (j==(env.layer_num-1)))
                    env.eeg_run();
            join_none;
            wait fork;
            layer_done();
            done_compare(i, j, layer_idx_fix);
        end
        frame_done();
    end
    @ (posedge clk);

  end

endprogram

`endif
