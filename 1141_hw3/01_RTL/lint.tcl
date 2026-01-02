read_file -type verilog {core.v}
read_file -type gateslib {../sram_4096x8/sram_4096x8_slow_syn.lib ../sram_512x8/sram_512x8_slow_syn.lib ../sram_256x8/sram_256x8_slow_syn.lib}
set_option top core
current_goal Design_Read -top core
link_design -force
current_goal lint/lint_rtl -top core
run_goal
current_goal lint/lint_rtl -top core
capture ./spyglass-1/core/lint/lint_rtl/spyglass_reports/spyglass_violations.rpt {write_report spyglass_violations}
file copy -force ./spyglass-1/core/lint/lint_rtl/spyglass_reports/spyglass_violations.rpt ./spyglass_violations.rpt

exit -force