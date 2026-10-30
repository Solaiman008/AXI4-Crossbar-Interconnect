import axi_xbar_param_pkg::*;

class axi_xbar_write_transaction;
    logic arst_n;

    rand logic [ID_WIDTH-1:0] awid;
    rand logic [ADDR_WIDTH-1:0] awaddr;
    rand logic [7:0] awlen;
    rand logic [2:0] awsize;
    rand logic [1:0] awburst;
    rand logic awvalid;
    logic awready;

    rand logic [DATA_WIDTH-1:0] wdata[$];
    rand logic [STRB_WIDTH-1:0] wstrb[$];
    rand logic wlast[$];
    rand logic wvalid;
    logic wready;

    logic [ID_WIDTH-1:0] bid;
    logic [1:0] bresp;
    logic bvalid;
    rand logic bready;
endclass
