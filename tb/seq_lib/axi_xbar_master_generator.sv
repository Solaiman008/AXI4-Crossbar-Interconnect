import axi_xbar_param_pkg::*;

class axi_xbar_master_generator;
    int master_id;

    mailbox wr_gen_to_drv;
    mailbox rd_gen_to_drv;

    axi_xbar_write_transaction wr_tr;
    axi_xbar_read_transaction  rd_tr;

    function new(
        mailbox wr_gen_to_drv,
        mailbox rd_gen_to_drv,
        int master_id
    );
        this.wr_gen_to_drv = wr_gen_to_drv;
        this.rd_gen_to_drv = rd_gen_to_drv;
        this.master_id = master_id;
        $display("[M%0d_GEN] Master Generator initialized at time %0d", this.master_id, $time);
    endfunction

    task reset();
        wr_tr = new();
		rd_tr = new();
        wr_tr.arst_n = 1'b0;
        wr_tr.awvalid = 1'b0;
        wr_tr.wvalid = 1'b0;
        wr_tr.bready = 1'b0;
        wr_gen_to_drv.put(wr_tr);
    endtask

    task write(
        logic [ID_WIDTH-1:0] awid,
        logic [ADDR_WIDTH-1:0] awaddr,
        logic [7:0] awlen,
        logic [2:0] awsize,
        logic [1:0] awburst,
        logic [DATA_WIDTH-1:0] wdata_q[$],
        logic [STRB_WIDTH-1:0] wstrb_q[$]
    );
        wr_tr = new();
        wr_tr.arst_n = 1'b1;
        wr_tr.awid = awid;
        wr_tr.awaddr = awaddr;
        wr_tr.awlen = awlen;
        wr_tr.awsize = awsize;
        wr_tr.awburst = awburst;
        wr_tr.awvalid = 1'b1;

        for (int i = 0; i <= awlen; i++) begin
            wr_tr.wdata.push_back((i < wdata_q.size()) ? wdata_q[i] : '0);
            wr_tr.wstrb.push_back((i < wstrb_q.size()) ? wstrb_q[i] : '1);
            wr_tr.wlast.push_back((i == awlen) ? 1'b1 : 1'b0);
        end

        wr_tr.wvalid = 1'b1;
        wr_tr.bready = 1'b1;
		//$display("Write Transaction %p, time = %0d", wr_tr, $time);
        wr_gen_to_drv.put(wr_tr);
    endtask

    task read(
        logic [ID_WIDTH-1:0] arid,
        logic [ADDR_WIDTH-1:0] araddr,
        logic [7:0] arlen,
        logic [2:0] arsize,
        logic [1:0] arburst
    );
        rd_tr = new();
        rd_tr.arid = arid;
        rd_tr.araddr = araddr;
        rd_tr.arlen = arlen;
        rd_tr.arsize = arsize;
        rd_tr.arburst = arburst;
        rd_tr.arvalid = 1'b1;
        rd_tr.rready = 1'b1;
        rd_gen_to_drv.put(rd_tr);
    endtask

endclass
