#!/bin/bash
# Check List:
# 1. TOP.sdc: False Path
# 2. RAM.v: `define RTSELDB (Debuging)
#    TapeOut: ndef for synth and Force to 10 when Simulation
#    RTSEL: 00 tapeout, 10: Only synth for Simulation
# 3. PERIOD_CLK

set DESIGN_NAME="EEG_ACC"
################################################################################
set PERIOD_CLK="300"
set UNGROUP="group"
set SDC_FILE=../synth/TOP.sdc
set TECH_SETTING="3PD_ss"
set NOTE=""

################################################################################
if($PERIOD_CLK == "") then 
    echo "<<<<<<<<<<<<<<<<<<<empty PERIOD_CLK>>>>>>>>>>>>>>>>>>>>>>"
    exit
endif

set DATE_VALUE = `date "+%y%m%d_%H%M" ` 
set STA_OUTDIR = ../../work/STA
set STA_PROJDIR = ${STA_OUTDIR}/$DESIGN_NAME/Date${DATE_VALUE}_${TECH_SETTING}_Periodclk${PERIOD_CLK}_${UNGROUP}_Note_${NOTE}
rm -rf ${STA_PROJDIR}
mkdir -p ${STA_OUTDIR}/$DESIGN_NAME ${STA_PROJDIR}

rm ./config_temp.tcl
rm ./define.vh

echo "set DESIGN_NAME   $DESIGN_NAME"   >> ./config_temp.tcl
echo "set PERIOD_CLK    $PERIOD_CLK"    >> ./config_temp.tcl
echo "set DATE_VALUE    $DATE_VALUE"    >> ./config_temp.tcl
echo "set TECH_SETTING  $TECH_SETTING"  >> ./config_temp.tcl
echo "set SDC_FILE      $SDC_FILE"      >> ./config_temp.tcl
echo "set STA_PROJDIR   $STA_PROJDIR"   >> ./config_temp.tcl
echo "              "                   >> ./define.vh # Create

cp -r ../../impl ${STA_PROJDIR}

if( $UNGROUP == "group") then 
  echo "set UNGROUP none" >> ./config_temp.tcl
else if( $UNGROUP == "ungroup") then 
  echo "set UNGROUP both" >> ./config_temp.tcl
else
    echo "<<<<<<<<<<<<<<<<<<<error UNGROUP>>>>>>>>>>>>>>>>>>>>>>"
    exit  
endif 

tempus -64 -nowin -overwrite -init ./script/STA.scr -log ${STA_PROJDIR}/logs/STA.log -cmd ${STA_PROJDIR}/logs/STA.cmd

