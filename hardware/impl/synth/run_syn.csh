# CHECK LIST:
# 1. PERIOD_CLK
# 2. CPF: HV LV libs
# 2. tech_settings.tcl: vts of std libs ; LS 0.6/1.2V

#############################################################################################
##                                  Need to Adjust                                         ## 
#############################################################################################
set WORK="synth"
# set WORK="STA"

set DESIGN_NAME="EEG_TOP"
set PERIOD_CLK="10"
set MAXLEAKAGE="0"   # 0.16mW
set MAXDYNAMIC="1.5" # 100MHz -> 14mW
set OPTWGT="0.949" # Larger optimization weight, lower leakage
set NOTE="3PD_HV_RHVT"

#############################################################################################
##                                  Read Files                                             ## 
#############################################################################################
set UNGROUP="group"
set SDC_FILE="../synth/TOP.sdc"
set TECH=../synth/script/tech_settings.tcl
set LEF=./script/lef_settings.tcl
set IODELAY="250"

set LV_SS="0.55"
set LV_TT="0.6"
set LV_FF="0.65"

# synth
set HDL=./script/read_hdl.scr
set DONTUSE=./script/DontUse.scr

# STA
set NETLIST=../../work/synth/EEG_TOP/Date240426_0123_3PD_HV_C3MLS_Periodclk10_group_MaxDynPwr0_OptWgt0.5_Note_/p+r_enc/EEG_TOP_synth.v
set rc_corner_cworst_QRC=/materials/technology/tsmc65/RC_Extraction/Cadence/RC_QRC_crn65lp_1p9m_6x1z1u_mim7_alrdl_5corners_1.0a1/RC_QRC_crn65lp_1p09m+alrdl_6x1z1u_mim7_cworst/qrcTechFile
set rc_corner_cbest_QRC=/materials/technology/tsmc65/RC_Extraction/Cadence/RC_QRC_crn65lp_1p9m_6x1z1u_mim7_alrdl_5corners_1.0a1/RC_QRC_crn65lp_1p09m+alrdl_6x1z1u_mim7_cbest/qrcTechFile

#############################################################################################
##                                  Create Directory                                       ## 
#############################################################################################
set DATE_VALUE = `date "+%y%m%d_%H%M" ` 
set SYNTH_OUTDIR = ../../work/$WORK
set SYNTH_PROJDIR = ${SYNTH_OUTDIR}/$DESIGN_NAME/Date${DATE_VALUE}_Periodclk${PERIOD_CLK}_${UNGROUP}_MaxLeakPwr${MAXLEAKAGE}_MaxDynPwr${MAXDYNAMIC}_OptWgt${OPTWGT}_Note_${NOTE}
rm -rf ${SYNTH_PROJDIR}
mkdir -p ${SYNTH_OUTDIR}/$DESIGN_NAME ${SYNTH_PROJDIR}

cp -r ../../src  ${SYNTH_PROJDIR}
cp -r ../../impl ${SYNTH_PROJDIR}

#############################################################################################
##                                  Write Variable File                                    ## 
#############################################################################################
rm ./config_temp.tcl
rm ./define.vh

echo "set DESIGN_NAME   $DESIGN_NAME"   >> ./config_temp.tcl
echo "set PERIOD_CLK    $PERIOD_CLK"    >> ./config_temp.tcl
echo "set MAXLEAKAGE    $MAXLEAKAGE"    >> ./config_temp.tcl
echo "set MAXDYNAMIC    $MAXDYNAMIC"    >> ./config_temp.tcl
echo "set OPTWGT        $OPTWGT"        >> ./config_temp.tcl
echo "set DATE_VALUE    $DATE_VALUE"    >> ./config_temp.tcl
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

if( $UNGROUP == "group") then 
  echo "set UNGROUP none" >> ./config_temp.tcl
else if( $UNGROUP == "ungroup") then 
  echo "set UNGROUP both" >> ./config_temp.tcl
else
    echo "<<<<<<<<<<<<<<<<<<<error UNGROUP>>>>>>>>>>>>>>>>>>>>>>"
    exit  
endif 

#############################################################################################
##                                  Start Synth/STA                                        ## 
#############################################################################################
if($WORK == "synth") then
    genus -legacy_ui -no_gui -overwrite -f ../synth/script/syn_RISC.scr -log ${SYNTH_PROJDIR}/$DESIGN_NAME.log
else if($WORK == "STA") then
    tempus -64 -overwrite -init ../synth/script/STA.scr -log ${SYNTH_PROJDIR}/logs/STA.log -cmd ${SYNTH_PROJDIR}/logs/STA.cmd
else
    echo "<<<<<<<<<<<<<<<<<<<error WORK>>>>>>>>>>>>>>>>>>>>>>"
    exit  
endif

