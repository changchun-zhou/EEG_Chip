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

  task done();

    $display("done");
    //repeat(1000+$urandom%20) @ (posedge clk);
    @ (posedge clk);
    top.DumpEnd <= 1'd1;
    @ (posedge clk);
    top.DumpEnd <= 1'd0;
  endtask: done

  task done_compare(int index);
    int dump_en = 0;
    $system("echo 'run python compare.py'");
    cmd = $psprintf("python ../../python/compare.py %0d", index);
    $display(cmd);
    $system(cmd);
  endtask: done_compare
  
  task run_model(int index);
    int dump_en = 0;
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
        dump_en();
        
        //run_model(i);
        env = new(eeg_if, run_done, i);
        
        env.build();
        env.init();
        
        fork
            env.eeg_cfg();
            env.eeg_run();
        join_none;
        wait fork;
        done();
    end
    done_compare(frame_num);
    @ (posedge clk);

  end

endprogram

`endif
