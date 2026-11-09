`include "../env/axi_xbar_environment.sv"
import axi_xbar_param_pkg::*;

class axi_xbar_base_test;
	virtual axi_xbar_if #(ID_WIDTH) vif_m0;
	virtual axi_xbar_if #(ID_WIDTH) vif_m1;
	virtual axi_xbar_if #(EXT_ID_WIDTH) vif_s0;
	virtual axi_xbar_if #(EXT_ID_WIDTH) vif_s1;
	axi_xbar_environment env;

	function new(
		virtual axi_xbar_if #(ID_WIDTH) vif_m0,
		virtual axi_xbar_if #(ID_WIDTH) vif_m1,
		virtual axi_xbar_if #(EXT_ID_WIDTH) vif_s0,
		virtual axi_xbar_if #(EXT_ID_WIDTH) vif_s1
	);
		this.vif_m0 = vif_m0;
		this.vif_m1 = vif_m1;
		this.vif_s0 = vif_s0;
		this.vif_s1 = vif_s1;
		env = new(vif_m0, vif_m1, vif_s0, vif_s1);
	endfunction

	task reset_dut();
		env.agt_m0.gen.reset();
	endtask

	task master_write(
		int m_idx,
		logic [ID_WIDTH-1:0] awid,
		logic [ADDR_WIDTH-1:0] awaddr,
		logic [7:0] awlen,
		logic [2:0] awsize,
		logic [1:0] awburst,
		logic [DATA_WIDTH-1:0] wdata_q[$],
		logic [STRB_WIDTH-1:0] wstrb_q[$]
	);
		if(m_idx == 0)
			env.agt_m0.gen.write(awid, awaddr, awlen, awsize, awburst, wdata_q, wstrb_q);
		else
			env.agt_m1.gen.write(awid, awaddr, awlen, awsize, awburst, wdata_q, wstrb_q);
	endtask

	task master_read(
		int m_idx,
		logic [ID_WIDTH-1:0] arid,
		logic [ADDR_WIDTH-1:0] araddr,
		logic [7:0] arlen,
		logic [2:0] arsize,
		logic [1:0] arburst
	);
		if(m_idx == 0)
			env.agt_m0.gen.read(arid, araddr, arlen, arsize, arburst);
		else
			env.agt_m1.gen.read(arid, araddr, arlen, arsize, arburst);
	endtask

	task slave_write_resp(
		int s_idx,
		logic [1:0] bresp,
		logic awready,
		logic wready
	);
		if(s_idx == 0)
			env.agt_s0.gen.write_resp(bresp, awready, wready);
		else
			env.agt_s1.gen.write_resp(bresp, awready, wready);
	endtask

	task slave_read_resp(
		int s_idx,
		logic [7:0] arlen,
		logic [DATA_WIDTH-1:0] rdata_q[$],
		logic [1:0] rresp_q[$],
		logic arready
	);
		if(s_idx == 0)
			env.agt_s0.gen.read_resp(arlen, rdata_q, rresp_q, arready);
		else
			env.agt_s1.gen.read_resp(arlen, rdata_q, rresp_q, arready);
	endtask

endclass
