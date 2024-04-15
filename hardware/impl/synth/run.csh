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
set MAXPOWER="0" # 100MHz -> 100mW
set OPTWGT="0.5" # Larger optimization weight, lower leakage(1/20~1/10 of Total Synth Power)
set SDC_FILE=./TOP.sdc
set TECH_SETTING="3PD_ss"
set NOTE=""

################################################################################
if($PERIOD_CLK == "") then 
    echo "<<<<<<<<<<<<<<<<<<<empty PERIOD_CLK>>>>>>>>>>>>>>>>>>>>>>"
    exit
endif

set DATE_VALUE = `date "+%y%m%d_%H%M" ` 
set SYNTH_OUTDIR = ../../work/synth
set SYNTH_PROJDIR = ${SYNTH_OUTDIR}/$DESIGN_NAME/Date${DATE_VALUE}_${TECH_SETTING}_Periodclk${PERIOD_CLK}_${UNGROUP}_MaxDynPwr${MAXPOWER}_OptWgt${OPTWGT}_Note_${NOTE}
rm -rf ${SYNTH_PROJDIR}
mkdir -p ${SYNTH_OUTDIR}/$DESIGN_NAME ${SYNTH_PROJDIR}

rm ./config_temp.tcl
rm ./define.vh

echo "set DESIGN_NAME   $DESIGN_NAME"   >> ./config_temp.tcl
echo "set PERIOD_CLK    $PERIOD_CLK"    >> ./config_temp.tcl
echo "set MAXPOWER      $MAXPOWER"      >> ./config_temp.tcl
echo "set OPTWGT        $OPTWGT"        >> ./config_temp.tcl
echo "set DATE_VALUE    $DATE_VALUE"    >> ./config_temp.tcl
echo "set TECH_SETTING  $TECH_SETTING"  >> ./config_temp.tcl
echo "set SDC_FILE      $SDC_FILE"      >> ./config_temp.tcl
echo "set SYNTH_PROJDIR $SYNTH_PROJDIR" >> ./config_temp.tcl
echo "              "                   >> ./define.vh # Create

cp -r ../../src ${SYNTH_PROJDIR}
cp -r ../synth ${SYNTH_PROJDIR}

if( $UNGROUP == "group") then 
  echo "set UNGROUP none" >> ./config_temp.tcl
else if( $UNGROUP == "ungroup") then 
  echo "set UNGROUP both" >> ./config_temp.tcl
else
    echo "<<<<<<<<<<<<<<<<<<<error UNGROUP>>>>>>>>>>>>>>>>>>>>>>"
    exit  
endif 

echo "<<<<<<<<<<<<<<<<<<<rc syn>>>>>>>>>>>>>>>>>>>>>>"
genus -legacy_ui -no_gui -overwrite -f ./script/syn_RISC.scr -log ${SYNTH_PROJDIR}/$DESIGN_NAME.log
