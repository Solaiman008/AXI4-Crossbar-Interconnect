import axi_xbar_param_pkg::*;

class axi_xbar_slave_generator;
    int slave_id;

    mailbox wr_gen_to_drv;
    mailbox rd_gen_to_drv;

    axi_xbar_write_transaction #(EXT_ID_WIDTH) wr_tr;
    axi_xbar_read_transaction #(EXT_ID_WIDTH) rd_tr;

    function new(
        mailbox wr_gen_to_drv,
        mailbox rd_gen_to_drv,
        int slave_id = 0
    );
        this.wr_gen_to_drv = wr_gen_to_drv;
        this.rd_gen_to_drv = rd_gen_to_drv;
        this.slave_id = slave_id;
        $display("[S%0d_GEN] Slave Generator initialized at time %0d", this.slave_id, $time);
    endfunction

    task reset();
        wr_tr = new();
        wr_tr.awready = 1'b0;
        wr_tr.wready = 1'b0;
        wr_tr.bvalid = 1'b0;
        wr_gen_to_drv.put(wr_tr);
    endtask

    task write_resp(
        //logic [ID_WIDTH-1:0] bid,
        logic [1:0] bresp,
        logic awready,
        logic wready
    );
        wr_tr = new();
        wr_tr.awready = awready;
        wr_tr.wready = wready;
        //wr_tr.bid = bid;
        wr_tr.bresp = bresp;
        wr_tr.bvalid = 1'b1;
        wr_gen_to_drv.put(wr_tr);
    endtask

    task read_resp(
        //logic [ID_WIDTH-1:0] rid,
        logic [7:0] arlen,
        logic [DATA_WIDTH-1:0] rdata_q[$],
        logic [1:0] rresp_q[$],
        logic arready
    );
        rd_tr = new();
        rd_tr.arready = arready;
        //rd_tr.rid = rid;

        for (int i = 0; i <= arlen; i++) begin
            rd_tr.rdata.push_back((i < rdata_q.size()) ? rdata_q[i] : '0);
            rd_tr.rresp.push_back((i < rresp_q.size()) ? rresp_q[i] : 2'b00);
            rd_tr.rlast.push_back((i == arlen) ? 1'b1 : 1'b0);
        end

        rd_tr.rvalid = 1'b1;
        rd_gen_to_drv.put(rd_tr);
    endtask

endclass
