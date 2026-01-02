#PrimeTime Script
set power_enable_analysis TRUE
set power_analysis_mode time_based

read_file -format verilog  ../04_APR/Netlist/bch_apr.v
current_design bch
link

read_sdf -load_delay net ../04_APR/Netlist/bch_apr.sdf

## Measure  power
#report_switching_activity -list_not_annotated -show_pin

read_vcd  -strip_path test/U_bch  ../05_POST/waveform.fsdb
update_power
report_power 
report_power > P300.powerS

exit