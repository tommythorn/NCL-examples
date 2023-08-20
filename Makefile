%: %.v
	iverilog -o $@ $^
	./$@


## For synthesis on ECP5 85F, specifically OrangeCrab

#BOARD=--lpf OrangeCrab.lpf --package CSFBGA285 --speed 6 --85k
BOARD= --lpf ulx3s_v20.lpf  --package CABGA381  --speed 6 --85k

SPEEDGRADE=6 # My OC is -6. 8 is the fastest available (85G?)

YOWASP=yowasp-
DESIGN=ring
prog: $(DESIGN).bit
	fujprog $<

%.bit: %.config
	$(YOWASP)ecppack $< $@

%.config: %.json Makefile
	$(YOWASP)nextpnr-ecp5 --ignore-loops --json $< $(BOARD) --textcfg $@

%.json: %.v ncl_lib.v
	$(YOWASP)yosys -DFPGA=1 -p "synth_ecp5 -top top -json $@" $^

ncl_lib.v: mk_lut
	./mk_lut > ncl_lib.v

mk_lut: mk_lut.rs
	rustc mk_lut.rs
