import axi_xbar_param_pkg::*;

class axi_xbar_master_agent;
	int master_id;
	axi_xbar_master_driver drv;
	axi_xbar_master_monitor mon;
	axi_xbar_master_generator gen;

	mailbox wr_gen_to_drv;
	mailbox rd_gen_to_drv;
	virtual axi_xbar_if #(ID_WIDTH) vif;

	function new(
		virtual axi_xbar_if #(ID_WIDTH) vif,
		mailbox wr_mon_to_sb,
		mailbox rd_mon_to_sb,
		axi_xbar_coverage cov,
		int master_id
	);
		$display("[M%0d_AGT] Master Agent initialized at time %0d", master_id, $time);
		this.vif = vif;
		this.master_id = master_id;

		wr_gen_to_drv = new();
		rd_gen_to_drv = new();

		gen = new(wr_gen_to_drv, rd_gen_to_drv, master_id);
		drv = new(vif, wr_gen_to_drv, rd_gen_to_drv, master_id);
		mon = new(vif, wr_mon_to_sb, rd_mon_to_sb, cov, master_id);
	endfunction

	task run;
		fork
			$display("[M%0d_AGT] Master agent started", master_id);
			mon.run();
			drv.run();
		join_none
	endtask
endclass
