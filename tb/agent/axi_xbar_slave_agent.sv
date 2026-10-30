import axi_xbar_param_pkg::*;

class axi_xbar_slave_agent;
	int slave_id;
	axi_xbar_slave_driver drv;
	axi_xbar_slave_monitor mon;
	axi_xbar_slave_generator gen;

	mailbox wr_gen_to_drv;
	mailbox rd_gen_to_drv;
	virtual axi_xbar_if #(EXT_ID_WIDTH) vif;

	function new(
		virtual axi_xbar_if #(EXT_ID_WIDTH) vif,
		mailbox wr_mon_to_sb,
		mailbox rd_mon_to_sb,
		axi_xbar_coverage cov,
		int slave_id
	);
		$display("[S%0d_AGT] Slave Agent initialized at time %0d", slave_id, $time);
		this.vif = vif;
		this.slave_id = slave_id;

		wr_gen_to_drv = new();
		rd_gen_to_drv = new();

		gen = new(wr_gen_to_drv, rd_gen_to_drv, slave_id);
		drv = new(vif, wr_gen_to_drv, rd_gen_to_drv, slave_id);
		mon = new(vif, wr_mon_to_sb, rd_mon_to_sb, cov, slave_id);
	endfunction

	task run;
		fork
			$display("[S%0d_AGT] Slave agent started", slave_id);
			mon.run();
			drv.run();
		join_none
	endtask
endclass
