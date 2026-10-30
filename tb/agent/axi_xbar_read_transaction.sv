import axi_xbar_param_pkg::*;

class axi_xbar_read_transaction;
    rand logic [ID_WIDTH-1:0] arid;
    rand logic [ADDR_WIDTH-1:0] araddr;
    rand logic [7:0] arlen;
    rand logic [2:0] arsize;
    rand logic [1:0] arburst;
    rand logic arvalid;
    logic arready;

    logic [ID_WIDTH-1:0] rid;
    logic [DATA_WIDTH-1:0] rdata[$];
    logic [1:0] rresp[$];
    logic rlast[$];
    logic rvalid;
    rand logic rready;
endclass
