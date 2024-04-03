## Select the technology library
#
#search path library files
set_attribute lib_search_path { \
    /workspace/home/songxy/Desktop/65nm_char/LIBRARY/ecsm/ \
	};

#target library
set_attribute library { \
    tcbn65lpbwp7t_0.45c125_wc_ecsm.lib \
	};	

#-----------------------------------------------------------------------
# Physical libraries
#-----------------------------------------------------------------------
# LEF for standard cells and macros

set tech_lef { \
    /materials/technology/tsmc65/IP/StdCell/7t/tcbn65lpbwp7t_220a/tcbn65lpbwp7t_141a_sef/TSMCHOME/digital/Back_End/lef/tcbn65lpbwp7t_141a/lef/tcbn65lpbwp7t_9lmT2.lef \
    };