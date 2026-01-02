`timescale 1ns/1ps

module test;

// --------------------------
// parameters
parameter CYCLE = 10;
parameter PATTERN = 1;
integer NTEST = 1;

// --------------------------
// signals
reg clk, rstn;
reg mode;
reg [1:0] code;
reg set;
reg [63:0] idata;
wire ready;
wire finish;
wire [9:0] odata;

// --------------------------
// test data
reg [63:0] testdata [0:819100];
reg [9:0] testa [0:51100];
integer i1, i2, i3;
integer errcnt, correctcnt;

// --------------------------
// read files and dump files
initial begin
	if (PATTERN == 1) begin
		NTEST = 1;
		$readmemb("testdata/example.txt", testdata);
		$readmemb("testdata/examplea.txt", testa);
	end
	if(PATTERN == 2) begin
		NTEST = 2;
		$readmemb("testdata/no_error_63.txt", testdata);
		$readmemb("testdata/no_error_63a.txt", testa);
	end
	if (PATTERN == 100) begin
		NTEST = 2;
		$readmemb("testdata/p100.txt", testdata);
		$readmemb("testdata/p100a.txt", testa);
	end
	if (PATTERN == 101) begin 
		NTEST = 1000;
		$readmemb("testdata/hard/bch63_hard/p101.txt", testdata);
		$readmemb("testdata/hard/bch63_hard/p101a.txt", testa);
	end
	if(PATTERN == 198) begin
		NTEST = 2;
		$readmemb("testdata/no_error_255.txt", testdata);
		$readmemb("testdata/no_error_255a.txt", testa);
	end
	if (PATTERN == 199) begin
		NTEST = 1;
		$readmemb("testdata/test_err_hard_255.txt", testdata);
		$readmemb("testdata/test_err_hard_255a.txt", testa);
	end
	if (PATTERN == 200) begin
		NTEST = 2;
		$readmemb("testdata/p200.txt", testdata);
		$readmemb("testdata/p200a.txt", testa);
	end
	if (PATTERN == 201)begin 
		NTEST = 1000;
		$readmemb("testdata/hard/bch255_hard/p201.txt", testdata);
		$readmemb("testdata/hard/bch255_hard/p201a.txt", testa);
	end
	if(PATTERN == 298) begin
		NTEST = 1;
		$readmemb("testdata/no_error_1023.txt", testdata);
		$readmemb("testdata/no_error_1023a.txt", testa);
	end
	if (PATTERN == 299) begin
		NTEST = 1;
		$readmemb("testdata/test_err_hard_1023.txt", testdata);
		$readmemb("testdata/test_err_hard_1023a.txt", testa);
	end
	if (PATTERN == 300) begin
		NTEST = 2;
		$readmemb("testdata/p300.txt", testdata);
		$readmemb("testdata/p300a.txt", testa);
	end
	if (PATTERN == 301)begin 
		NTEST = 1000;
		$readmemb("testdata/hard/bch1023_hard/p301.txt", testdata);
		$readmemb("testdata/hard/bch1023_hard/p301a.txt", testa);
	end
	if(PATTERN == 397) begin
		NTEST = 1;
		$readmemb("testdata/pattern_mixed_63.txt", testdata);
		$readmemb("testdata/pattern_mixed_63a.txt", testa);
	end
	if(PATTERN == 398) begin
		NTEST = 1;
		$readmemb("testdata/pattern_lrb_63.txt", testdata);
		$readmemb("testdata/pattern_lrb_63a.txt", testa);
	end
	if (PATTERN == 399) begin
		NTEST = 1;
		$readmemb("testdata/pattern_weak_63.txt", testdata);
		$readmemb("testdata/pattern_weak_63a.txt", testa); //要檢查
	end
	if (PATTERN == 400) begin
		NTEST = 1;
		$readmemb("testdata/mixed_n63_soft.txt", testdata);
		$readmemb("testdata/mixed_n63_softa.txt", testa);
	end
	if (PATTERN == 401) begin
		NTEST = 100;
		$readmemb("testdata/soft/bch63_soft/p401.txt", testdata);
		$readmemb("testdata/soft/bch63_soft/p401a.txt", testa);
	end
	if (PATTERN == 403) begin
		NTEST = 1;
		$readmemb("testdata/p403.txt", testdata);
		$readmemb("testdata/p403a.txt", testa);
	end
	if (PATTERN == 410) begin
		NTEST = 64;
		$readmemb("testdata/p400_64.txt", testdata);
		$readmemb("testdata/p400a_64.txt", testa);
	end

	if (PATTERN == 497) begin
		NTEST = 1;
		$readmemb("testdata/test_err_soft_255.txt", testdata);
		$readmemb("testdata/test_err_soft_255a.txt", testa);
	end
	if (PATTERN == 498) begin
		NTEST = 1;
		$readmemb("testdata/test_err_hybrid1_255.txt", testdata);
		$readmemb("testdata/test_err_hybrid1_255a.txt", testa); //要檢查
	end
	if (PATTERN == 499) begin
		NTEST = 1;
		$readmemb("testdata/test_err_hybrid2_255.txt", testdata);
		$readmemb("testdata/test_err_hybrid2_255a.txt", testa);
	end
	if (PATTERN == 500) begin
		NTEST = 1;
		$readmemb("testdata/mixed_n255_soft.txt", testdata);
		$readmemb("testdata/mixed_n255_softa.txt", testa);
	end
	if (PATTERN == 501) begin
		NTEST = 100;
		$readmemb("testdata/soft/bch255_soft/p501.txt", testdata);
		$readmemb("testdata/soft/bch255_soft/p501a.txt", testa);
	end
	if (PATTERN == 510) begin
		NTEST = 64;
		$readmemb("testdata/p500_64.txt", testdata);
		$readmemb("testdata/p500a_64.txt", testa);
	end

	if (PATTERN == 598) begin
		NTEST = 1;
		$readmemb("testdata/test_err_hybrid1_1023.txt", testdata);
		$readmemb("testdata/test_err_hybrid1_1023a.txt", testa); //要檢查
	end
	if (PATTERN == 599) begin
		NTEST = 1;
		$readmemb("testdata/test_err_soft_1023.txt", testdata);
		$readmemb("testdata/test_err_soft_1023a.txt", testa);
	end
	if (PATTERN == 600) begin
		NTEST = 1;
		$readmemb("testdata/mixed_n1023_soft.txt", testdata);
		$readmemb("testdata/mixed_n1023_softa.txt", testa);
	end
	if (PATTERN == 601) begin
		NTEST = 100;
		$readmemb("testdata/soft/bch1023_soft/p601.txt", testdata);
		$readmemb("testdata/soft/bch1023_soft/p601a.txt", testa);
	end
	if (PATTERN == 610) begin
		NTEST = 64;
		$readmemb("testdata/p600_64.txt", testdata);
		$readmemb("testdata/p600a_64.txt", testa);
	end
end

initial begin
	$fsdbDumpfile("waveform.fsdb");
	$fsdbDumpvars("+mda");
end

// --------------------------
// modules
bch U_bch(
	.clk(clk),
	.rstn(rstn),
	.mode(mode),
	.code(code),
	.set(set),
	.idata(idata),
	.ready(ready),
	.finish(finish),
	.odata(odata)
);
`ifdef SDF_GATE
	initial $sdf_annotate("../02_SYN/Netlist/bch_syn.sdf", U_bch);
`elsif SDF_POST
	initial $sdf_annotate("../04_APR/Netlist/bch_apr.sdf", U_bch);
`endif

// --------------------------
// clock
initial clk = 1;
always #(CYCLE/2.0) clk = ~clk;

// --------------------------
// test
initial begin
	i1 = 0;
	i2 = 0;
	i3 = 0;
	errcnt = 0;
	correctcnt = 0;

	rstn = 0;
	mode = 0;
	code = 0;
	set = 0;
	idata = 0;
	#(CYCLE*5);
	@(negedge clk);
	rstn = 1;

	@(negedge clk);
	#(CYCLE*5);
	for (i2 = 0; i2 < NTEST; i2 = i2 + 1) begin
		if (PATTERN == 1) begin
			code = 1;
			mode = 0;
		end else if (PATTERN == 2) begin
			code = 1;
			mode = 0;
		end else if (PATTERN <= 110) begin
			code = 1;
			mode = 0;
		end else if (PATTERN <= 210) begin
			code = 2;
			mode = 0;
		end else if (PATTERN <= 310) begin
			code = 3;
			mode = 0;
		end else if (PATTERN <= 410) begin
			code = 1;
			mode = 1;
		end else if (PATTERN <= 510) begin
			code = 2;
			mode = 1;
		end else if (PATTERN <= 610) begin
			code = 3;
			mode = 1;
		end
		set = 1;
		#(CYCLE);
		set = 0;

		wait(finish === 1);
		@(negedge clk);
		#(CYCLE*10);
	end
end
always @(negedge clk) begin
	if (ready === 1) begin
		idata = testdata[i1];
		i1 = i1 + 1;
	end
end
always @(negedge clk) begin
	if (finish === 1 && $time >= CYCLE * 5) begin
		if (odata !== testa[i3]) begin
			errcnt = errcnt + 1;
			$write("design output = %4d, golden output = %4d. Error\n", odata, testa[i3]);
		end else begin
			correctcnt = correctcnt + 1;
			$write("design output = %4d, golden output = %4d\n", odata, testa[i3]);
		end
		i3 = i3 + 1;
	end
end
initial begin
	wait(i2 == NTEST);
	$write("Correct count = %0d\n", correctcnt);
	$write("Error count = %0d\n", errcnt);
	$write("Time = %0d\n", $time - CYCLE * 5);
	#(CYCLE*5);
	$finish;
end
initial begin
	#(CYCLE*1000000);
	$write("Timeout\n");
	$finish;
end

endmodule
