# Add all waveforms in model
add wave tb/iDUT/*
run -all

coverage save a.ucdb
coverage report -details -html
coverage report -details -output cov.rpt
exit

