import axi_xbar_param_pkg::*;

class axi_xbar_slave_driver;
	int slave_id;
	virtual axi_xbar_if #(EXT_ID_WIDTH) vif;
	mailbox wr_gen_to_drv;
	mailbox rd_gen_to_drv;
	axi_xbar_write_transaction #(EXT_ID_WIDTH) wr_tr;
	axi_xbar_read_transaction #(EXT_ID_WIDTH) rd_tr;

	function new(
		virtual axi_xbar_if #(EXT_ID_WIDTH) vif,
		mailbox wr_gen_to_drv,
		mailbox rd_gen_to_drv,
		int slave_id
	);
		$display("[S%0d_DRV] Slave Driver initialized at time %0d", slave_id, $time);
		this.vif = vif;
		this.wr_gen_to_drv = wr_gen_to_drv;
		this.rd_gen_to_drv = rd_gen_to_drv;
		this.slave_id = slave_id;
	endfunction

	task run;
		fork
			forever begin
				wr_gen_to_drv.get(wr_tr);
				write(wr_tr);
			end
			forever begin
				rd_gen_to_drv.get(rd_tr);
				read(rd_tr);
			end
		join_none
	endtask

	task write(axi_xbar_write_transaction #(EXT_ID_WIDTH) tr);
		logic [EXT_ID_WIDTH-1:0] captured_awid;
		wait(vif.arst_n === 1'b1);
		fork
			//$display("Driver Write Transaction Drived");
			begin
				@(posedge vif.aclk);
				vif.awready <= tr.awready;
				do
					@(posedge vif.aclk);
				while(!(vif.awvalid && vif.awready));

				captured_awid = vif.awid;
				vif.awready <= 0;
			end
			begin
				@(posedge vif.aclk);
				vif.wready <= tr.wready;
				do
					@(posedge vif.aclk);
				while(!(vif.wvalid && vif.wready && vif.wlast));

				vif.wready <= 0;
			end
		join

		@(posedge vif.aclk);
		vif.bid <= captured_awid;
		vif.bresp <= tr.bresp;
		vif.bvalid <= tr.bvalid;

		do
			@(posedge vif.aclk);
		while(!(vif.bvalid && vif.bready));
		//$display("===================================================================================================================");
        //$display("from driver id = %0b", vif.bid);
        //$display("===================================================================================================================");

		vif.bvalid <= 0;
	endtask

	task read(axi_xbar_read_transaction #(EXT_ID_WIDTH) tr);
		logic [EXT_ID_WIDTH-1:0] captured_arid;
		wait(vif.arst_n === 1'b1);

		//$display("Driver Read Transaction Drived");
		@(posedge vif.aclk);
		vif.arready <= tr.arready;

		do
			@(posedge vif.aclk);
		while(!(vif.arvalid && vif.arready));

		captured_arid = vif.arid;
		vif.arready <= 0;

		foreach(tr.rdata[i]) begin
			@(posedge vif.aclk);
			vif.rid <= captured_arid;
			vif.rdata <= tr.rdata[i];
			vif.rresp <= tr.rresp[i];
			vif.rlast <= tr.rlast[i];
			vif.rvalid <= tr.rvalid;

			do
				@(posedge vif.aclk);
			while(!(vif.rvalid && vif.rready));
		end

		vif.rvalid <= 0;
		vif.rlast <= 0;
	endtask
endclass
