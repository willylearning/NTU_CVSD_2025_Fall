if {![namespace exists ::IMEX]} { namespace eval ::IMEX {} }
set ::IMEX::dataVar [file dirname [file normalize [info script]]]
set ::IMEX::libVar ${::IMEX::dataVar}/libs

create_library_set -name lib_min\
   -timing\
    [list ${::IMEX::libVar}/mmmc/fast.lib\
    ${::IMEX::libVar}/mmmc/tpz013g3lt.lib\
    ${::IMEX::libVar}/mmmc/RF2SH64x16_fast@0C_syn.lib]\
   -si\
    [list ${::IMEX::libVar}/mmmc/fast.cdB]
create_library_set -name lib_max\
   -timing\
    [list ${::IMEX::libVar}/mmmc/slow.lib\
    ${::IMEX::libVar}/mmmc/tpz013g3wc.lib\
    ${::IMEX::libVar}/mmmc/RF2SH64x16_slow_syn.lib]\
   -si\
    [list ${::IMEX::libVar}/mmmc/slow.cdB]
create_rc_corner -name RC_Corner\
   -cap_table ${::IMEX::libVar}/mmmc/tsmc013.capTbl\
   -preRoute_res 1\
   -postRoute_res 1\
   -preRoute_cap 1\
   -postRoute_cap 1\
   -postRoute_xcap 1\
   -preRoute_clkres 0\
   -preRoute_clkcap 0\
   -qx_tech_file ${::IMEX::libVar}/mmmc/RC_Corner/icecaps_8lm.tch
create_delay_corner -name Delay_Corner_min\
   -library_set lib_min\
   -rc_corner RC_Corner
create_delay_corner -name Delay_Corner_max\
   -library_set lib_max\
   -rc_corner RC_Corner
create_constraint_mode -name func_mode\
   -sdc_files\
    [list ${::IMEX::dataVar}/mmmc/modes/func_mode/func_mode.sdc]
create_analysis_view -name av_func_mode_max -constraint_mode func_mode -delay_corner Delay_Corner_max -latency_file ${::IMEX::dataVar}/mmmc/views/av_func_mode_max/latency.sdc
create_analysis_view -name av_func_mode_min -constraint_mode func_mode -delay_corner Delay_Corner_min -latency_file ${::IMEX::dataVar}/mmmc/views/av_func_mode_min/latency.sdc
set_analysis_view -setup [list av_func_mode_max] -hold [list av_func_mode_min]
