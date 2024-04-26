# Check List:
# 1. TOP.sdc: False Path
# 2. RAM.v: `define RTSELDB (Debuging)
#    TapeOut: ndef for synth and Force to 10 when Simulation
#    RTSEL: 00 tapeout, 10: Only synth for Simulation
# 3. PERIOD_CLK

# set WORK="synth"
set WORK="STA"
set DESIGN_NAME="EEG_TOP"
################################################################################
set PERIOD_CLK="600"
set UNGROUP="group"
set MAXPOWER="0" # 100MHz -> 100mW
set OPTWGT="0.5" # Larger optimization weight, lower leakage(1/20~1/10 of Total Synth Power)
set SDC_FILE="../synth/TOP.sdc"
set TECH_SETTING="3PD_HV_C3MLS"
set TECH=../synth/script/tech_settings.tcl
set LEF=./script/lef_settings.tcl
set IODELAY="500"

# synth
set HDL=./script/read_hdl.scr
set DONTUSE=./script/DontUse.scr
# set LV_SS="1.08"
# set LV_TT="1.2"
# set LV_FF="1.32"

# STA
set NETLIST=../../work/synth/EEG_TOP/Date240426_0123_3PD_HV_C3MLS_Periodclk10_group_MaxDynPwr0_OptWgt0.5_Note_/p+r_enc/EEG_TOP_synth.v
set rc_corner_cworst_QRC=/materials/technology/tsmc65/RC_Extraction/Cadence/RC_QRC_crn65lp_1p9m_6x1z1u_mim7_ut-alrdl_5corners_1.0a/RC_QRC_crn65lp_1p09m+ut-alrdl_6x1z1u_mim7_cworst/qrcTechFile
set rc_corner_cbest_QRC=/materials/technology/tsmc65/RC_Extraction/Cadence/RC_QRC_crn65lp_1p9m_6x1z1u_mim7_ut-alrdl_5corners_1.0a/RC_QRC_crn65lp_1p09m+ut-alrdl_6x1z1u_mim7_cbest/qrcTechFile
set LV_SS="0.45"
set LV_TT="0.5"
set LV_FF="0.55"


set NOTE=""

################################################################################
if($PERIOD_CLK == "") then 
    echo "<<<<<<<<<<<<<<<<<<<empty PERIOD_CLK>>>>>>>>>>>>>>>>>>>>>>"
    exit
endif

set DATE_VALUE = `date "+%y%m%d_%H%M" ` 
set SYNTH_OUTDIR = ../../work/$WORK
set SYNTH_PROJDIR = ${SYNTH_OUTDIR}/$DESIGN_NAME/Date${DATE_VALUE}_${TECH_SETTING}_Periodclk${PERIOD_CLK}_LV_TT${LV_TT}_${UNGROUP}_MaxDynPwr${MAXPOWER}_OptWgt${OPTWGT}_Note_${NOTE}
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
echo "set LV_SS         $LV_SS"         >> ./config_temp.tcl
echo "set LV_TT         $LV_TT"         >> ./config_temp.tcl
echo "set LV_FF         $LV_FF"         >> ./config_temp.tcl
echo "set TECH          $TECH"          >> ./config_temp.tcl
echo "set LEF           $LEF"           >> ./config_temp.tcl
echo "set HDL           $HDL"           >> ./config_temp.tcl
echo "set DONTUSE       $DONTUSE"       >> ./config_temp.tcl
echo "set IODELAY       $IODELAY"       >> ./config_temp.tcl
echo "set NETLIST       $NETLIST"       >> ./config_temp.tcl
echo "set rc_corner_cworst_QRC $rc_corner_cworst_QRC"      >> ./config_temp.tcl
echo "set rc_corner_cbest_QRC  $rc_corner_cbest_QRC"       >> ./config_temp.tcl
echo "              "                   >> ./define.vh # Create

cp -r ../../src  ${SYNTH_PROJDIR}
cp -r ../../impl ${SYNTH_PROJDIR}

if( $UNGROUP == "group") then 
  echo "set UNGROUP none" >> ./config_temp.tcl
else if( $UNGROUP == "ungroup") then 
  echo "set UNGROUP both" >> ./config_temp.tcl
else
    echo "<<<<<<<<<<<<<<<<<<<error UNGROUP>>>>>>>>>>>>>>>>>>>>>>"
    exit  
endif 

if($WORK == "synth") then
    genus -legacy_ui -no_gui -overwrite -f ../synth/script/syn_RISC.scr -log ${SYNTH_PROJDIR}/$DESIGN_NAME.log
else if($WORK == "STA") then
    tempus -64 -overwrite -init ../synth/script/STA.scr -log ${SYNTH_PROJDIR}/logs/STA.log -cmd ${SYNTH_PROJDIR}/logs/STA.cmd
else
    echo "<<<<<<<<<<<<<<<<<<<error WORK>>>>>>>>>>>>>>>>>>>>>>"
    exit  
endif

