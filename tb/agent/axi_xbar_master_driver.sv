import axi_xbar_param_pkg::*;

class axi_xbar_master_driver;
	int master_id;
	virtual axi_xbar_if #(ID_WIDTH) vif;
	mailbox wr_gen_to_drv;
	mailbox rd_gen_to_drv;
	axi_xbar_write_transaction wr_tr;
	axi_xbar_read_transaction rd_tr;

	function new(
		virtual axi_xbar_if #(ID_WIDTH) vif,
		mailbox wr_gen_to_drv,
		mailbox rd_gen_to_drv,
		int master_id
	);
		$display("[M%0d_DRV] Master Driver initialized at time %0d", master_id, $time);
		this.vif = vif;
		this.wr_gen_to_drv = wr_gen_to_drv;
		this.rd_gen_to_drv = rd_gen_to_drv;
		this.master_id = master_id;
	endfunction

	task run;
		fork
			forever begin
				wr_gen_to_drv.get(wr_tr);
				if(!wr_tr.arst_n)
					reset();
				else
					write(wr_tr);
			end

			forever begin
				rd_gen_to_drv.get(rd_tr);
				read(rd_tr);
			end
		join_none
	endtask

	task reset();
		vif.arst_n = 0;
		vif.awvalid = 0;
		vif.wvalid = 0;
		vif.bready = 0;
		vif.arvalid = 0;
		vif.rready = 0;
		repeat(RST_CYCLE)
			@(posedge vif.aclk);
		vif.arst_n = 1;
	endtask

	task write(axi_xbar_write_transaction tr);
		wait(vif.arst_n);
		fork
			begin
				@(posedge vif.aclk);
				vif.awid <= tr.awid;
				vif.awaddr <= tr.awaddr;
				vif.awlen <= tr.awlen;
				vif.awsize <= tr.awsize;
				vif.awburst <= tr.awburst;
				vif.awvalid <= tr.awvalid;

				do
					@(posedge vif.aclk);
				while(!vif.awready);

				vif.awvalid <= 0;
			end
			begin
				foreach(tr.wdata[i]) begin
					@(posedge vif.aclk);
					vif.wdata <= tr.wdata[i];
					vif.wstrb <= tr.wstrb[i];
					vif.wlast <= tr.wlast[i];
					vif.wvalid <= tr.wvalid;

					do
						@(posedge vif.aclk);
					while(!vif.wready);
				end

				vif.wvalid <= 0;
				vif.wlast <= 0;
			end
			begin
				@(posedge vif.aclk);
				vif.bready <= tr.bready;

				do
					@(posedge vif.aclk);
				while(!vif.bvalid);

				vif.bready <= 0;
			end
		join
	endtask

	task read(axi_xbar_read_transaction tr);
		wait(vif.arst_n);
		fork
			begin
				@(posedge vif.aclk);
				vif.arid <= tr.arid;
				vif.araddr <= tr.araddr;
				vif.arlen <= tr.arlen;
				vif.arsize <= tr.arsize;
				vif.arburst <= tr.arburst;
				vif.arvalid <= tr.arvalid;

				do
					@(posedge vif.aclk);
				while(!vif.arready);

				vif.arvalid <= 0;
			end
			begin
				@(posedge vif.aclk);
				vif.rready <= tr.rready;

				for(int i = 0; i <= tr.arlen; i++) begin
					do
						@(posedge vif.aclk);
					while(!vif.rvalid);
				end

				vif.rready <= 0;
			end
		join
	endtask

endclass
