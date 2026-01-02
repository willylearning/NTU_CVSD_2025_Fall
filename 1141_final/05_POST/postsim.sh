rm -f rtl.f
echo "../01_RTL/test.v" >> rtl.f
echo "../04_APR/Netlist/bch_apr.v" >> rtl.f
echo "-v /home/raid7_2/course/cvsd/CBDK_IC_Contest/CIC/Verilog/tsmc13_neg.v" >> rtl.f

ln -sf ../01_RTL/testdata/ testdata

cycleT=$(grep -oE "[0-9]+\.[0-9]+" cycle.txt)

#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=100 +define+SDF_POST -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=200 +define+SDF_POST -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=300 +define+SDF_POST -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk

#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=101 +define+SDF_POST -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=201 +define+SDF_POST -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=301 +define+SDF_POST -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk

#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=400 +define+SDF_POST -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=500 +define+SDF_POST -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=600 +define+SDF_POST -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk

#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=401 +define+SDF_POST -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=501 +define+SDF_POST -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk
#vcs -f rtl.f -pvalue+CYCLE=${cycleT} -pvalue+PATTERN=601 +define+SDF_POST -full64 -R -debug_access+all +v2k +maxdelays -negdelay +neg_tchk