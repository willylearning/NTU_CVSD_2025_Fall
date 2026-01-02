rm -f rtl.f
echo "../01_RTL/test.v" >> rtl.f
echo "../02_SYN/Netlist/bch_syn.v" >> rtl.f
echo "-v /home/raid7_2/course/cvsd/CBDK_IC_Contest/CIC/Verilog/tsmc13_neg.v" >> rtl.f

ln -sf ../01_RTL/testdata/ testdata

cycleT=$(grep -oE "[0-9]+\.[0-9]+" cycle.txt)

vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=100 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=200 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=300 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=101 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=201 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=301 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=401 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=402 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=403 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=404 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=405 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=406 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=407 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=409 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=501 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=600 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=601 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=602 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=603 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=604 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=605 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=606 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=607 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=608 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=609 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=610 +define+SDF_GATE -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk