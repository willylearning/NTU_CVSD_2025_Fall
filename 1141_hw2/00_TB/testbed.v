`timescale 1ns/100ps
`define CYCLE       10.0
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   120000

`ifdef p0
    `define Inst "../00_TB/PATTERN/p0/inst.dat"
	`define Status "../00_TB/PATTERN/p0/status.dat"
	`define Data "../00_TB/PATTERN/p0/data.dat"
	`define S_len 69
`elsif p1
    `define Inst "../00_TB/PATTERN/p1/inst.dat"
	`define Status "../00_TB/PATTERN/p1/status.dat"
	`define Data "../00_TB/PATTERN/p1/data.dat"
	`define S_len 12
`elsif p2
	`define Inst "../00_TB/PATTERN/p2/inst.dat"
	`define Status "../00_TB/PATTERN/p2/status.dat"
	`define Data "../00_TB/PATTERN/p2/data.dat"
	`define S_len 45
`elsif p3
	`define Inst "../00_TB/PATTERN/p3/inst.dat"
	`define Status "../00_TB/PATTERN/p3/status.dat"
	`define Data "../00_TB/PATTERN/p3/data.dat"
	`define S_len 510
`else
	`define Inst "../00_TB/PATTERN/p0/inst.dat"
	`define Status "../00_TB/PATTERN/p0/status.dat"
	`define Data "../00_TB/PATTERN/p0/data.dat"
	`define S_len 69
`endif

module testbed;

	reg  rst_n;
	reg  clk = 0;
	wire            dmem_we;
	wire [ 31 : 0 ] dmem_addr;
	wire [ 31 : 0 ] dmem_wdata;
	wire [ 31 : 0 ] dmem_rdata;
	wire [  2 : 0 ] mips_status;
	wire            mips_status_valid;
	reg [2:0] gold_status[`S_len-1:0],state_out[`S_len-1:0];
	reg [31:0] gold_data[2047:0];
	wire [10:0] map_addrs = dmem_addr[12:2];
	integer i,k;
	integer file_status;
	integer S_error,D_error;
	integer status_num;
	core u_core (
		.i_clk(clk),
		.i_rst_n(rst_n),
		.o_status(mips_status),
		.o_status_valid(mips_status_valid),
		.o_we(dmem_we),
		.o_addr(dmem_addr),
		.o_wdata(dmem_wdata),
		.i_rdata(dmem_rdata)
	);

	data_mem  u_data_mem (
		.i_clk(clk),
		.i_rst_n(rst_n),
		.i_we(dmem_we),
		.i_addr(dmem_addr),
		.i_wdata(dmem_wdata),
		.o_rdata(dmem_rdata)
	);

	initial begin
       $fsdbDumpfile("core.fsdb");
       $fsdbDumpvars(0, testbed, "+mda");
    end

	always #(`HCYCLE) clk = ~clk;

	// load data memory
	initial begin 
		rst_n = 1;
		#(0.25 * `CYCLE) rst_n = 0;
		#(`CYCLE) rst_n = 1;
		$readmemb (`Inst, u_data_mem.mem_r);
	end
	
	initial begin
		k = 0;
		status_num = 0;
		while (k < `S_len)begin
			@(negedge clk);
			if(mips_status_valid === 1'b1)begin
				state_out[k] = mips_status;
				status_num = status_num + 1;
				k = k + 1;
			end
			
		end
	end
	initial begin
		while(1)begin
			if(mips_status_valid === 1'b1 && (mips_status == 3'd5 || mips_status == 3'd6))begin
				check_mem;
				#100;
				$finish;
			end
			@(negedge clk);
		end
	end
	initial begin
		wait(rst_n === 1'b0);
		wait(rst_n === 1'b1);
		#(`MAX_CYCLE * `CYCLE);
		$display("Error! Time limit exceeded!");
        $finish;
	end
	initial begin
		wait(rst_n === 1'b0);
		#(0.1 * `CYCLE);
		if(mips_status !== 0 || mips_status_valid !== 0 || dmem_we !== 0 || dmem_addr !== 0 ||dmem_wdata !== 0)begin
			$display("Reset: Error! Output not reset to 0 or 1");
			$finish;
		end
	end
	task check_mem;
		begin
			D_error = 0;
			$readmemb(`Data,gold_data);
			for(i= 0;i<2048;i=i+1)begin
				if(u_data_mem.mem_r[i] !== gold_data[i])begin
					D_error = D_error + 1;
					$display("[Data]Address %d error! golden:%b,your:%b",i,gold_data[i],u_data_mem.mem_r[i]);
				end
			end
			if(D_error == 0)begin
				$display("===========================================================");
				$display("	\n[Data] Congratulation! All result are correct\n");
				$display("===========================================================");
			end
			else begin
				$display("===========================================================");
				$display("	\n[Data] Error! There are %d errors QQ\n", D_error);
				$display("===========================================================");
			end
			S_error = 0;
			$readmemb(`Status,gold_status);
			for(i= 0;i<`S_len;i=i+1)begin
				if(gold_status[i] !== state_out[i])begin
					S_error = S_error + 1;
					$display("[Status]Status %d error! golden:%b,your:%b",i,gold_status[i],state_out[i]);
				end
			end
			if(S_error == 0)begin
				$display("===========================================================");
				$display("	\n[Status] Congratulation! All result are correct\n");
				$display("===========================================================");
			end
			else begin
				$display("===========================================================");
				$display("	\n[Status] Error! There are %d errors QQ\n", S_error);
				$display("===========================================================");
				
			end
		end
	endtask
endmodule;