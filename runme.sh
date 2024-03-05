#!/bin/sh

#Create the work library
if [ ! -d "work" ]; then
  echo "work library does not exist"
  vlib work
fi

# List of SV files to compile
sv_files=("tb.sv" "controller.sv" "covergroups.sv" "properties.sv")
# Compile SV files
for file in "${sv_files[@]}"; do
  if [ -s "$file" ]; then
    vlog "$file" +fcover -cover sbcef +cover=f -O0
  fi
done

#Simulation and coverage command
vsim work.tb -c -coverage -voptargs=+acc=npr -t ns -do cover.do +allcases
#mv cov.rpt all.rpt
#vsim work.tb -c -coverage -voptargs=+acc=npr -t ns -do cover.do +tc_reset_in_all_states
#mv cov.rpt id5.rpt
#vsim work.tb -c -coverage -voptargs=+acc=npr -t ns -do cover.do +tc_M1_can_interrupt
#mv cov.rpt id8.rpt
#vsim work.tb -c -coverage -voptargs=+acc=npr -t ns -do cover.do +tc_M2_and_M3_cannot_interrupt
#mv cov.rpt id24.rpt
#vsim work.tb -c -coverage -voptargs=+acc=npr -t ns -do cover.do +tc_smooth_transition_no_idle
#mv cov.rpt id36.rpt


#export MGLS_LICENSE_FILE="2717@linlic.engr.oregonstate.edu"
#export PATH="/usr/local/apps/mgc/questa/questasim/bin:$PATH"
#export PATH="/usr/local/apps/mgc/questa/linux_x86_64/bin:$PATH"
#qverify -c -od log -do propcheck.do


exit
