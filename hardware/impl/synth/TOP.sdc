set period_clk $PERIOD_CLK
set DESIGN     $DESIGN_NAME

create_clock -period $period_clk -add -name clock_clk -waveform [list 0 [expr $period_clk*0.5]] [get_pins CHIP_CLK_PAD_U/C]

set clock_list clock_clk

set_clock_uncertainty -setup 0.2    [get_pins CHIP_CLK_PAD_U/C]
set_clock_uncertainty -hold  0.1    [get_pins CHIP_CLK_PAD_U/C]

set_false_path -from [list \
    [get_ports RST_N_PAD]\
]

set_input_delay  -clock clock_clk -rise -add_delay [expr $period_clk-$IODELAY] [filter_collection [all_inputs] "full_name !~CLK_PAD && full_name !~RST_N_PAD"]
set_output_delay -clock clock_clk -rise -add_delay [expr $period_clk-$IODELAY] [all_outputs]

set_input_transition -min 0.05 [all_inputs]
set_input_transition -max 0.2  [all_inputs]

set_load -pin_load -max 1 [all_outputs]

set_max_transition 1.1 ${DESIGN}
set_max_fanout 32 ${DESIGN}

