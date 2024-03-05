#clear environment
clear -all

#compile HDL files
analyze -sv controller.sv properties.sv
elaborate -top controller 
clock clk
reset reset
#reset reset
prove -all
report -all -file myReport.txt -force