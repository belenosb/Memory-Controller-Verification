# Compile Section

#Create the work library
vlib work

# Compile SV files and include formal property files
vlog -sv +define+FORMAL controller.sv
vlog -sv -mfcu -cuname sva_bind +define+FORMAL properties.sv

# PropCheck Section
onerror {exit 1}
###### add directives
# fix one of the nets to a value
netlist reset reset -active_high -async
netlist clock clk -period 20 


###### Run PropCheck
formal compile -d controller -cuname sva_bind
formal verify -timeout 30s

exit 0