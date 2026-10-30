package axi_xbar_param_pkg;
	parameter int NUM_MASTERS = 2,
	parameter int NUM_SLAVES = 2,
	parameter int ADDR_WIDTH = 32, 
	parameter int DATA_WIDTH = 64, 
	parameter int ID_WIDTH = 4,
	parameter int FIFO_DEPTH = 8,
	parameter int CNT_WIDTH = 4,
	parameter int MASTER_WIDTH = (NUM_MASTERS > 1) ? $clog2(NUM_MASTERS) : 1,
	parameter int EXT_ID_WIDTH = ID_WIDTH + MASTER_WIDTH
	parameter int NUM_TARGETS = NUM_SLAVES + 1;
	parameter int TARGET_WIDTH = (NUM_TARGETS > 1) ? $clog2(NUM_TARGETS) : 1;
	parameter int STRB_WIDTH = DATA_WIDTH / 8;
	parameter int RST_CYCLE = 5;
endpackage
