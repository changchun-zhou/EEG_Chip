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
`ifndef CFG
  `define CFG

`include "../../tb/DEFINE.sv"

class CFG;

    type_cmd cfg_cmd;
    type_cmd cfg_len;
    type_cmd cfg_lst;
    type_cmd cfg_act_cmd [`BANK_NUM_DW -1:0];
    type_cmd cfg_wei_cmd [`BANK_NUM_DW -1:0];
    type_dat cfg_act_dat [`BANK_NUM_DW -1:0];
    type_dat cfg_wei_dat [`BANK_NUM_DW -1:0];
    int frame_idx;
    
    extern function new(input int frame_idx);
    extern virtual function void     read_cfg_cmd(input string file_path = "./");
    extern virtual function void     read_ram_dat(input string file_path = "./");
    extern virtual function type_cmd read_cmd(input string file_name = "", input int read_cmd_type = 0);
    extern virtual function type_dat read_dat(input string file_name = "");

endclass : CFG


//========================================================
function CFG::new(input int frame_idx);

  this.frame_idx = frame_idx;

endfunction : new

//========================================================

function void CFG::read_cfg_cmd(input string file_path = "./");

    string cmd_txt;
    cmd_txt = $psprintf("%s/cmd.txt", file_path);
    cfg_cmd = read_cmd(cmd_txt);
    cfg_len = read_cmd(cmd_txt, 1);
    cfg_lst = read_cmd(cmd_txt, 2);
endfunction : read_cfg_cmd

function void CFG::read_ram_dat(input string file_path = "./");

    string act_txt;
    string wei_txt;
    for(integer i = 0; i < `BANK_NUM_DW; i = i + 1 )begin
        act_txt = $psprintf("%s/act_cmd%1d.txt", file_path, i);
        cfg_act_cmd[i] = read_cmd(act_txt);
        act_txt = $psprintf("%s/act_dat%1d.txt", file_path, i);
        cfg_act_dat[i] = read_dat(act_txt);
    end
    for(integer i = 0; i < `BANK_NUM_DW; i = i + 1 )begin
        wei_txt = $psprintf("%s/wei_cmd%1d.txt", file_path, i);
        cfg_wei_cmd[i] = read_cmd(wei_txt);
        wei_txt = $psprintf("%s/wei_dat%1d.txt", file_path, i);
        cfg_wei_dat[i] = read_dat(wei_txt);
    end
  
endfunction : read_ram_dat

function type_cmd CFG::read_cmd(input string file_name = "", input int read_cmd_type = 0);
    
    type_cmd cmd_read;
    int file_ptr;
    int file_cnt;
    int line_cnt = 0;
    reg [32 -1:0] cmd_dat;
    int cmd_len;
    int cmd_lst;
    string cmd_str;
    file_ptr = $fopen(file_name,"r");
    if( file_ptr )begin
        while( !$feof(file_ptr) )
        begin
            file_cnt =  $fscanf(file_ptr,"%8h, %d, %d, %s\n", cmd_dat, cmd_len, cmd_lst, cmd_str);
            if( read_cmd_type==1 )
                cmd_read[line_cnt] = cmd_len;
            else if( read_cmd_type==2 )begin
                cmd_read[line_cnt] = cmd_lst;
            end
            else
                cmd_read[line_cnt] = cmd_dat;
            line_cnt = line_cnt+1;
        end
        $fclose(file_ptr);
    end
    return cmd_read;
  
endfunction : read_cmd

function type_dat CFG::read_dat(input string file_name = "");
    
    type_dat dat_read;
    int file_ptr;
    int file_cnt;
    int line_cnt = 0;
    reg [8 -1:0] cmd_dat;
    file_ptr = $fopen(file_name,"r");
    if( file_ptr )begin
        while( !$feof(file_ptr) )
        begin
            file_cnt =  $fscanf(file_ptr,"%4d\n", cmd_dat);
            dat_read[line_cnt] = cmd_dat;
            line_cnt = line_cnt+1;
        end
        $fclose(file_ptr);
    end
    return dat_read;
  
endfunction : read_dat


`endif
