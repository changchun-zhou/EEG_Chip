## Select the technology library
#
#search path library files
set_attribute lib_search_path { \
    /workspace/home/songxy/Desktop/65nm_char/LIBRARY/ecsm/ \
    /materials/technology/tsmc65/IP/StdCell/7t/tcbn65lpbwp7t_220a/tcbn65lpbwp7t_141a_ecsm/TSMCHOME/digital/Front_End/timing_power_noise/ECSM/tcbn65lpbwp7t_141a \
    ../../src/sram/ \
	};

#target library
set_attribute library { \
    tcbn65lpbwp7twc_ecsm.lib \
    ts1n65lpa256x8m4_140a/SYNOPSYS/ts1n65lpa256x8m4_140a_ss1p08v125c.lib \
    ts1n65lpa1024x4m4_140a/SYNOPSYS/ts1n65lpa1024x4m4_140a_ss1p08v125c.lib \
    ts1n65lpa4096x8m8_140a/SYNOPSYS/ts1n65lpa4096x8m8_140a_ss1p08v125c.lib \
    ts1n65lpa8192x8m16_140a/SYNOPSYS/ts1n65lpa8192x8m16_140a_ss1p08v125c.lib \
	};	
    # tcbn65lpbwp7t_addfuncnew_0.45c125_wc_ecsm.lib\
#-----------------------------------------------------------------------
# Physical libraries
#-----------------------------------------------------------------------
# LEF for standard cells and macros

set tech_lef { \
    /materials/technology/tsmc65/IP/StdCell/7t/tcbn65lpbwp7t_220a/tcbn65lpbwp7t_141a_sef/TSMCHOME/digital/Back_End/lef/tcbn65lpbwp7t_141a/lef/tcbn65lpbwp7t_9lmT2.lef \
    ../../src/sram/ts1n65lpa256x8m4_140a/LEF/ts1n65lpa256x8m4_140a_5m.lef \
    ../../src/sram/ts1n65lpa1024x4m4_140a/LEF/ts1n65lpa1024x4m4_140a_5m.lef \
    ../../src/sram/ts1n65lpa4096x8m8_140a/LEF/ts1n65lpa4096x8m8_140a_5m.lef \
    ../../src/sram/ts1n65lpa8192x8m16_140a/LEF/ts1n65lpa8192x8m16_140a_5m.lef \
    };
