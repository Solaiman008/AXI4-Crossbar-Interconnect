import axi_xbar_param_pkg::*;

class axi_xbar_slave_monitor;
	int slave_id;
	virtual axi_xbar_if #(EXT_ID_WIDTH) vif;
	mailbox wr_mon_to_sb;
	mailbox rd_mon_to_sb;
	axi_xbar_write_transaction wr_tr;
	axi_xbar_read_transaction rd_tr;

	function new(
		virtual axi_xbar_if #(EXT_ID_WIDTH) vif,
		mailbox wr_mon_to_sb,
		mailbox rd_mon_to_sb,
		int slave_id
	);
		$display("[S%0d_MON] Slave Monitor initialized at time %0d", slave_id, $time);
		this.vif = vif;
		this.wr_mon_to_sb = wr_mon_to_sb;
		this.rd_mon_to_sb = rd_mon_to_sb;
		this.slave_id = slave_id;
	endfunction

	task run;
		fork
			write();
			read();
		join_none
	endtask

	task write();
		forever begin
			@(posedge vif.aclk);
			if(vif.awvalid && vif.awready) begin
				wr_tr = new();
				wr_tr.awid = vif.awid;
				wr_tr.awaddr = vif.awaddr;
				wr_tr.awlen = vif.awlen;
				wr_tr.awsize = vif.awsize;
				wr_tr.awburst = vif.awburst;

				for(int i = 0; i <= vif.awlen; i++) begin
					do
						@(posedge vif.aclk);
					while(!(vif.wvalid && vif.wready));
					wr_tr.wdata.push_back(vif.wdata);
					wr_tr.wstrb.push_back(vif.wstrb);
					wr_tr.wlast.push_back(vif.wlast);
				end

				do
					@(posedge vif.aclk);
				while(!(vif.bvalid && vif.bready));
				wr_tr.bid = vif.bid;
				wr_tr.bresp = vif.bresp;

				wr_mon_to_sb.put(wr_tr);
			end
		end
	endtask

	task read();
		forever begin
			@(posedge vif.aclk);
			if(vif.arvalid && vif.arready) begin
				rd_tr = new();
				rd_tr.arid = vif.arid;
				rd_tr.araddr = vif.araddr;
				rd_tr.arlen = vif.arlen;
				rd_tr.arsize = vif.arsize;
				rd_tr.arburst = vif.arburst;

				for(int i = 0; i <= vif.arlen; i++) begin
					do
						@(posedge vif.aclk);
					while(!(vif.rvalid && vif.rready));
					rd_tr.rid = vif.rid;
					rd_tr.rdata.push_back(vif.rdata);
					rd_tr.rresp.push_back(vif.rresp);
					rd_tr.rlast.push_back(vif.rlast);
				end

				rd_mon_to_sb.put(rd_tr);
			end
		end
	endtask
endclass
