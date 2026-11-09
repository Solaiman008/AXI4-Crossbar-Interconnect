import axi_xbar_param_pkg::*;

class axi_xbar_master_monitor;
	int master_id;
	virtual axi_xbar_if #(ID_WIDTH) vif;
	mailbox wr_mon_to_sb;
	mailbox rd_mon_to_sb;
	axi_xbar_write_transaction wr_tr;
	axi_xbar_read_transaction rd_tr;
	axi_xbar_coverage cov;

	function new(
		virtual axi_xbar_if #(ID_WIDTH) vif,
		mailbox wr_mon_to_sb,
		mailbox rd_mon_to_sb,
		axi_xbar_coverage cov,
		int master_id
	);
		$display("[M%0d_MON] Master Monitor initialized at time %0d", master_id, $time);
		this.vif = vif;
		this.wr_mon_to_sb = wr_mon_to_sb;
		this.rd_mon_to_sb = rd_mon_to_sb;
		this.master_id = master_id;
		this.cov = cov;
	endfunction

	task run;
		fork
			write();
			read();
		join_none
	endtask

	task write();
		//$display("Monitor started monitoring");
		forever begin
			@(posedge vif.aclk);
			if(vif.arst_n && vif.awvalid && vif.awready) begin
				wr_tr = new();
				wr_tr.awid = vif.awid;
				wr_tr.awaddr = vif.awaddr;
				wr_tr.awlen = vif.awlen;
				wr_tr.awsize = vif.awsize;
				wr_tr.awburst = vif.awburst;

				for(int i = 0; i <= wr_tr.awlen; i++) begin
					if(!(i == 0 && vif.wvalid && vif.wready)) begin
						do
							@(posedge vif.aclk);
						while(!(vif.wvalid && vif.wready));
					end
					wr_tr.wdata.push_back(vif.wdata);
					wr_tr.wstrb.push_back(vif.wstrb);
					wr_tr.wlast.push_back(vif.wlast);
				end

				do
					@(posedge vif.aclk);
				while(!(vif.bvalid && vif.bready));
				wr_tr.bid = vif.bid;
				wr_tr.bresp = vif.bresp;
				//$display("bresp = %0b", vif.bresp);
				//$display("Master write monitored");

				cov.sample_master_write(master_id, wr_tr);
				wr_mon_to_sb.put(wr_tr);
			end
		end
	endtask

	task read();
		forever begin
			@(posedge vif.aclk);
			if(vif.arst_n && vif.arvalid && vif.arready) begin
				rd_tr = new();
				rd_tr.arid = vif.arid;
				rd_tr.araddr = vif.araddr;
				rd_tr.arlen = vif.arlen;
				rd_tr.arsize = vif.arsize;
				rd_tr.arburst = vif.arburst;

			/*	for(int i = 0; i <= rd_tr.arlen; i++) begin
					do
						@(posedge vif.aclk);
					while(!(vif.rvalid && vif.rready));
					rd_tr.rid = vif.rid;
					rd_tr.rdata.push_back(vif.rdata);
					rd_tr.rresp.push_back(vif.rresp);
					rd_tr.rlast.push_back(vif.rlast);
				end*/
				forever begin
					@(posedge vif.aclk);
					if(vif.rvalid && vif.rready) begin
						rd_tr.rdata.push_back(vif.rdata);
						rd_tr.rresp.push_back(vif.rresp);
						rd_tr.rlast.push_back(vif.rlast);
						if(vif.rlast)
							break;
					end
				end
				//$display("Master read monitored");
				cov.sample_master_read(master_id, rd_tr);
				rd_mon_to_sb.put(rd_tr);
			end
		end
	endtask
endclass
