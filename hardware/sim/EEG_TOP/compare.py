import os
import re
import sys
import copy
import numpy as np
import random

def getFiles(path, suffix):
    files_list = [os.path.join(root, file).replace("\\", "/") for root, dirs, files in os.walk(path) for file in files if file.endswith(suffix)]
    files_list.sort(key=str2int)
    return files_list
    
def write_file(file_name, file_txt, w_type="a"):
    file_ptr = open(file_name, w_type)
    print( file_txt, file=file_ptr)
    file_ptr.close()

def read_file_lines(file_name):
    file_ptr = open(file_name, 'r')
    file_lines = file_ptr.readlines()
    file_ptr.close()
    return file_lines
    
def mkdir(path, is_print=True):
    path=path.strip()
    path=path.rstrip("\\")
    isExists=os.path.exists(path)
    if not isExists:
        os.makedirs(path)
        if( is_print ):
            print(path+' success')
        return True
    else:
        if( is_print ):
            print(path+' path exist')
        return False

def delete_file(filename, is_print=False):
    if os.path.exists(filename):
        os.remove(filename)
        if( is_print ):
            print("file %s delete success." %(filename))
    else:
        if( is_print ):
            print("file %s delete do not exist!" %(filename))
    
def tryint(s):
    try:
        return int(s)
    except ValueError:
        return s

def str2int(v_str):
    return [tryint(sub_str) for sub_str in re.split('([0-9]+)', v_str)]

def sort_dict_by_keys(old_dict, reverse=False):
    keys = list(old_dict.keys())
    keys.sort(reverse=reverse)
    sort_dict = {}
    for key in keys:
        sort_dict[key] = old_dict[key]
    return sort_dict

def getFilesHint(files, file_str=""):

    pick_files = []
    for file in files:
        if( file_str in file ):
            pick_files.append(file)

    return pick_files

def check_file(vdump_path, cdump_path, file_name="", is_oram=False):
    is_case_pass = True
    true_name = "%s/%s" %(vdump_path, file_name)
    oram_name = "%s/%s" %(cdump_path, file_name)
    
    if( not os.path.exists(oram_name) ):
        if( os.path.exists(true_name) ):
            print("%s do not exist." %(oram_name))
        return True

    if( not os.path.exists(true_name) ):
        if( is_oram ):
            return True
        else:
            print("%s do not exist." %(true_name))
            return True

    if( len(read_file_lines(true_name))!=len(read_file_lines(oram_name)) ):
        print("%s Data number mismatch." %(true_name))
        return True

    if( read_file_lines(true_name)!=read_file_lines(oram_name)):
        print("%s failed!!!!!!" %(true_name))
        is_case_pass = False
    return is_case_pass

#basic_path = "../../sim/EEG_TOP"
basic_path = "."

frame_idx = int(sys.argv[1])
layer_idx = int(sys.argv[2])

frame_str = "Frame%02d" %(frame_idx)
layer_str = "Layer%02d" %(layer_idx)
#print("frame_idx: %s; layer_idx: %d" %(frame_idx, layer_idx))

vdump_path = "%s/dump/%s/%s/true" %(basic_path, frame_str, layer_str)
cdump_path = "%s/case/%s/%s/true" %(basic_path, frame_str, layer_str)

#check case pass
is_case_pass = True
ram_num = 4

#check omux
for r_i in range(ram_num):
    for m_i in range(4):
        is_case_pass &= check_file(vdump_path, cdump_path, file_name="omux_%s_%s.txt" %(r_i, m_i), is_oram=True)

#check file
for r_i in range(ram_num):
    is_case_pass &= check_file(vdump_path, cdump_path, file_name="aram_%s.txt" %(r_i))
    is_case_pass &= check_file(vdump_path, cdump_path, file_name="wram_%s.txt" %(r_i))
    is_case_pass &= check_file(vdump_path, cdump_path, file_name="oram_%s.txt" %(r_i), is_oram=True)
    is_case_pass &= check_file(vdump_path, cdump_path, file_name="fram_%s.txt" %(r_i), is_oram=True)
   #is_case_pass &= check_file(vdump_path, cdump_path, file_name="wsta_%s.txt" %(r_i))
    is_case_pass &= check_file(vdump_path, cdump_path, file_name="topk_%s.txt" %(r_i), is_oram=True)

case_pass_file = "%s/dump/%s/%s/case_pass.txt" %(basic_path, frame_str, layer_str)
delete_file(case_pass_file)
if( is_case_pass ):
    write_file(case_pass_file, "case pass!!!")
    print("%s case pass!!!" %(layer_str))

case_pass_file = "%s/dump/case_pass.txt" %(basic_path)
past_case_pass = True if(layer_idx==0) else os.path.exists(case_pass_file)
if( (not is_case_pass) or (not past_case_pass)  ):
    delete_file(case_pass_file)
if( is_case_pass and past_case_pass ):
    write_file(case_pass_file, "%s case pass!!!" %(layer_str))