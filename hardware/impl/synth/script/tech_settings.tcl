########################
## Read Library Files ##
########################

set libdir_0p5 ../../project/lib/0p5
set libdir_1p2 /materials/technology/tsmc65/IP/StdCell/7t/tcbn65lpbwp7t_220a/tcbn65lpbwp7t_141a_ecsm/TSMCHOME/digital/Front_End/timing_power_noise/ECSM/tcbn65lpbwp7t_141a
set libdir_sram ../../src/sram
#############################################################################################
##                                  Define worst-case library sets                         ## 
#############################################################################################
set worst_1p08_125_memory_libs   [exec find $libdir_sram -name *ss*125c*.lib]
set worst_ls_libs                $libdir_1p2/tcbn65lpbwp7twcl1d080d9_ecsm.lib
set worst_0p45_125_standard_libs $libdir_0p5/tcbn65lpbwp7t_editCKLHall_0.45c125_wc_ecsm.lib
set worst_1p08_125_standard_libs $libdir_1p2/tcbn65lpbwp7twc_ecsm.lib

set slow_HV_lib [concat \
    $worst_1p08_125_standard_libs\
    $worst_ls_libs\
    $worst_1p08_125_memory_libs\
    ]

set slow_LV_lib [concat \
    $worst_0p45_125_standard_libs\
    $worst_ls_libs\
    ]

# #############################################################################################
# ##                                  Define typical-case library sets                       ## 
# #############################################################################################
# set typical_1p2_25_memory_libs   [exec find $libdir_sram -name *tt*25c*.lib]
# set typical_ls_libs              $libdir_1p2/tcbn65lpbwp7ttc1d01d2_ecsm.lib
# set typical_0p5_25_standard_libs $libdir_0p5/tcbn65lpbwp7t_editCKLHall_0.50c25_tc_ecsm.lib
# set typical_1p2_25_standard_libs $libdir_1p2/tcbn65lpbwp7ttc_ecsm.lib

# set typical_HV_lib [concat \
#     $typical_1p2_25_standard_libs\
#     $typical_ls_libs\
#     $typical_1p2_25_memory_libs\
#     ]

# set typical_LV_lib [concat \
#     $typical_0p5_25_standard_libs\
#     $typical_ls_libs\
#     ]

# #############################################################################################
# ##                                  Define best-case library sets                          ## 
# #############################################################################################
# set fast_1p32_0_memory_libs     [exec find $libdir_sram -name *ff*v0c*.lib]
# set fast_ls_libs                $libdir_1p2/tcbn65lpbwp7tbc1d11d32_ecsm.lib
# set fast_0p55_m40_standard_libs $libdir_0p5/tcbn65lpbwp7t_editCKLHall_0.50c-40_bc_ecsm.lib
# set fast_1p32_0_standard_libs   $libdir_1p2/tcbn65lpbwp7tbc_ecsm.lib

# set fast_HV_lib [concat \
#     $fast_1p32_0_standard_libs\
#     $fast_ls_libs\
#     $fast_1p32_0_memory_libs\
#     ]

# set fast_LV_lib [concat \
#     $fast_0p55_m40_standard_libs\
#     $fast_ls_libs\
#     ]
