import axi_xbar_param_pkg::*;

interface axi_xbar_if #(ID_W = ID_WIDTH) (input aclk);
	logic arst_n;

	logic [ID_W-1:0] awid;
	logic [ADDR_WIDTH-1:0] awaddr;
	logic [7:0] awlen;
	logic [2:0] awsize;
	logic [1:0] awburst;
	logic awvalid;
	logic awready;

	logic [DATA_WIDTH-1:0] wdata;
	logic [STRB_WIDTH-1:0] wstrb;
	logic wlast;
	logic wvalid;
	logic wready;

	logic [ID_W-1:0] bid;
	logic [1:0] bresp;
	logic bvalid;
	logic bready;

	logic [ID_W-1:0] arid;
	logic [ADDR_WIDTH-1:0] araddr;
	logic [7:0] arlen;
	logic [2:0] arsize;
	logic [1:0] arburst;
	logic arvalid;
	logic arready;

	logic [ID_W-1:0] rid;
	logic [DATA_WIDTH-1:0] rdata;
	logic [1:0] rresp;
	logic rlast;
	logic rvalid;
	logic rready;
endinterface
