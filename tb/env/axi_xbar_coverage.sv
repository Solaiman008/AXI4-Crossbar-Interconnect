import axi_xbar_param_pkg::*;

class axi_xbar_coverage;

	int m_wr_id;
	logic [ID_WIDTH-1:0] m_awid;
	logic [ADDR_WIDTH-1:0] m_awaddr;
	logic [7:0] m_awlen;
	logic [2:0] m_awsize;
	logic [1:0] m_awburst;
	logic [DATA_WIDTH-1:0] m_wdata;
	logic [STRB_WIDTH-1:0] m_wstrb;
	logic [1:0] m_bresp;
	bit m_bid_match;

	int m_rd_id;
	logic [ID_WIDTH-1:0] m_arid;
	logic [ADDR_WIDTH-1:0] m_araddr;
	logic [7:0] m_arlen;
	logic [2:0] m_arsize;
	logic [1:0] m_arburst;
	logic [DATA_WIDTH-1:0] m_rdata;
	logic [1:0] m_rresp;

	int s_id;
	bit s_origin_master;
	logic [ID_WIDTH-1:0] s_base_id;
	logic [7:0] s_burst_len;

	covergroup cg_master_write;
		option.per_instance = 1;
		option.name = "cg_master_write";

		cp_m_id: coverpoint m_wr_id {
			bins m0 = {0};
			bins m1 = {1};
		}

		cp_awid: coverpoint m_awid {
			bins id_low = {[4'h0 : 4'h3]};
			bins id_mid_low = {[4'h4 : 4'h7]};
			bins id_mid_high = {[4'h8 : 4'hB]};
			bins id_high = {[4'hC : 4'hF]};
		}

		cp_awaddr_region: coverpoint m_awaddr {
			bins slave0_range = {[32'h0000_0000 : 32'h0FFF_FFFF]};
			bins slave1_range = {[32'h1000_0000 : 32'h1FFF_FFFF]};
			bins default_range = {[32'h2000_0000 : 32'hFFFF_FFFF]};
		}

		cp_awaddr_edges: coverpoint m_awaddr {
			bins s0_base_edge = {32'h0000_0000};
			bins s0_upper_edge = {32'h0FFF_FFFF};
			bins s1_base_edge = {32'h1000_0000};
			bins s1_upper_edge = {32'h1FFF_FFFF};
			bins err_base_edge = {32'h2000_0000};
			bins err_upper_edge = {32'hFFFF_FFFF};
		}

		cp_awlen: coverpoint m_awlen {
			bins single_beat = {8'd0};
			bins bursts[12] = {[8'd1 : 8'd255]};
		}

		cp_awsize: coverpoint m_awsize {
			bins size_8bytes = {3'd3};
		}

		cp_awburst: coverpoint m_awburst {
			bins incr_burst = {2'b01};
			bins fix_burst = {2'b00};
			bins wrap_burst = {2'b10};
		}

		cp_wdata: coverpoint m_wdata {
			bins data_regions[4] = {['0 : '1]};
			bins p_all_ones = {64'hFFFF_FFFF_FFFF_FFFF};
			bins p_all_zeros = {64'h0000_0000_0000_0000};
			bins p_alt_1010 = {64'hAAAA_AAAA_AAAA_AAAA};
			bins p_alt_0101 = {64'h5555_5555_5555_5555};
		}

		cp_wstrb: coverpoint m_wstrb {
			bins full_strobe = {8'hFF};
		}

		cp_bresp: coverpoint m_bresp {
			bins okay = {2'b00};
			bins slverr = {2'b10};
			bins decerr = {2'b11};
		}

		cp_bid_match: coverpoint m_bid_match {
			bins id_matched = {1'b1};
			illegal_bins id_mm = {1'b0};
		}

		cx_wr_master_x_target: cross cp_m_id, cp_awaddr_region;
		cx_wr_master_x_burst: cross cp_m_id, cp_awlen;
		cx_wr_target_x_burst: cross cp_awaddr_region, cp_awlen;

		cx_wr_target_x_bresp: cross cp_awaddr_region, cp_bresp {
			ignore_bins s0_decerr = binsof(cp_awaddr_region.slave0_range) && binsof(cp_bresp.decerr);
			ignore_bins s1_decerr = binsof(cp_awaddr_region.slave1_range) && binsof(cp_bresp.decerr);
			ignore_bins def_okay = binsof(cp_awaddr_region.default_range) && binsof(cp_bresp.okay);
			ignore_bins def_slverr = binsof(cp_awaddr_region.default_range) && binsof(cp_bresp.slverr);
		}
	endgroup

	covergroup cg_master_read;
		option.per_instance = 1;
		option.name = "cg_master_read";

		cp_m_id: coverpoint m_rd_id {
			bins m0 = {0};
			bins m1 = {1};
		}

		cp_arid: coverpoint m_arid {
			bins id_low = {[4'h0 : 4'h3]};
			bins id_mid_low = {[4'h4 : 4'h7]};
			bins id_mid_high = {[4'h8 : 4'hB]};
			bins id_high = {[4'hC : 4'hF]};
		}

		cp_araddr_region: coverpoint m_araddr {
			bins slave0_range = {[32'h0000_0000 : 32'h0FFF_FFFF]};
			bins slave1_range = {[32'h1000_0000 : 32'h1FFF_FFFF]};
			bins default_range = {[32'h2000_0000 : 32'hFFFF_FFFF]};
		}

		cp_araddr_edges: coverpoint m_araddr {
			bins s0_base_edge = {32'h0000_0000};
			bins s0_upper_edge = {32'h0FFF_FFFF};
			bins s1_base_edge = {32'h1000_0000};
			bins s1_upper_edge = {32'h1FFF_FFFF};
			bins err_base_edge = {32'h2000_0000};
			bins err_upper_edge = {32'hFFFF_FFFF};
		}

		cp_arlen: coverpoint m_arlen {
			bins single_beat = {8'd0};
			bins bursts[12] = {[8'd1 : 8'd255]};
		}

		cp_arsize: coverpoint m_arsize {
			bins size_8bytes = {3'd3};
		}

		cp_arburst: coverpoint m_arburst {
			bins incr_burst = {2'b01};
			bins fix_burst = {2'b00};
			bins wrap_burst = {2'b10};
		}

		cp_rdata: coverpoint m_rdata {
			bins data_regions[4] = {['0 : '1]};
			bins p_all_ones = {64'hFFFF_FFFF_FFFF_FFFF};
			bins p_all_zeros = {64'h0000_0000_0000_0000};
			bins p_alt_1010 = {64'hAAAA_AAAA_AAAA_AAAA};
			bins p_alt_0101 = {64'h5555_5555_5555_5555};
		}

		cp_rresp: coverpoint m_rresp {
			bins okay = {2'b00};
			bins slverr = {2'b10};
			bins decerr = {2'b11};
		}

		cx_rd_master_x_target: cross cp_m_id, cp_araddr_region;
		cx_rd_master_x_burst: cross cp_m_id, cp_arlen;
		cx_rd_target_x_burst: cross cp_araddr_region, cp_arlen;

		cx_rd_target_x_rresp: cross cp_araddr_region, cp_rresp {
			ignore_bins s0_decerr = binsof(cp_araddr_region.slave0_range) && binsof(cp_rresp.decerr);
			ignore_bins s1_decerr = binsof(cp_araddr_region.slave1_range) && binsof(cp_rresp.decerr);
			ignore_bins def_okay = binsof(cp_araddr_region.default_range) && binsof(cp_rresp.okay);
			ignore_bins def_slverr = binsof(cp_araddr_region.default_range) && binsof(cp_rresp.slverr);
		}
	endgroup

	covergroup cg_slave_routing;
		option.per_instance = 1;
		option.name = "cg_slave_routing";

		cp_s_id: coverpoint s_id {
			bins s0 = {0};
			bins s1 = {1};
		}

		cp_m_id: coverpoint s_origin_master {
			bins m0 = {0};
			bins m1 = {1};
		}

		cp_s_base_id: coverpoint s_base_id {
			bins id_low = {[4'h0 : 4'h3]};
			bins id_mid_low = {[4'h4 : 4'h7]};
			bins id_mid_high = {[4'h8 : 4'hB]};
			bins id_high = {[4'hC : 4'hF]};
		}

		cp_s_burst: coverpoint s_burst_len {
			bins single_beat = {8'd0};
			bins bursts[12] = {[8'd1 : 8'd255]};
		}

		cx_slave_x_master: cross cp_s_id, cp_m_id;
	endgroup

	function new();
		cg_master_write = new();
		cg_master_read = new();
		cg_slave_routing = new();
	endfunction

	function void sample_master_write(int master_id, axi_xbar_write_transaction tr);
		m_wr_id = master_id;
		m_awid = tr.awid;
		m_awaddr = tr.awaddr;
		m_awlen = tr.awlen;
		m_awsize = tr.awsize;
		m_awburst = tr.awburst;
		m_bresp = tr.bresp;
		m_bid_match = (tr.bid == tr.awid);

		if (tr.wdata.size() > 0) begin
			foreach (tr.wdata[i]) begin
				m_wdata = tr.wdata[i];
				m_wstrb = tr.wstrb[i];
				cg_master_write.sample();
			end
		end else begin
			m_wdata = '0;
			m_wstrb = '1;
			cg_master_write.sample();
		end
	endfunction

	function void sample_master_read(int master_id, axi_xbar_read_transaction tr);
		m_rd_id = master_id;
		m_arid = tr.arid;
		m_araddr = tr.araddr;
		m_arlen = tr.arlen;
		m_arsize = tr.arsize;
		m_arburst = tr.arburst;

		if (tr.rdata.size() > 0) begin
			foreach (tr.rdata[i]) begin
				m_rdata = tr.rdata[i];
				m_rresp = tr.rresp[i];
				cg_master_read.sample();
			end
		end else begin
			m_rdata = '0;
			m_rresp = 2'b00;
			cg_master_read.sample();
		end
	endfunction

	function void sample_slave_write(int slave_id, axi_xbar_write_transaction #(EXT_ID_WIDTH) tr);
		s_id = slave_id;
		s_origin_master = tr.awid[EXT_ID_WIDTH-1];
        //$display("===================================================================================================================");
        //$display("idd= %b", tr.awid);
        //$display("===================================================================================================================");
		s_base_id = tr.awid[ID_WIDTH-1:0];
		s_burst_len = tr.awlen;
		cg_slave_routing.sample();
	endfunction

	function void sample_slave_read(int slave_id, axi_xbar_read_transaction #(EXT_ID_WIDTH) tr);
		s_id = slave_id;
		s_origin_master = tr.arid[EXT_ID_WIDTH-1];
		//$display("===================================================================================================================");
		//$display("id = %0b", tr.arid);
		//$display("===================================================================================================================");
		s_base_id = tr.arid[ID_WIDTH-1:0];
		s_burst_len = tr.arlen;
		cg_slave_routing.sample();
	endfunction

	task report();
		$display("--------------------------------------------------");
		$display("[COV] AXI CROSSBAR FUNCTIONAL COVERAGE REPORT");
		$display("Master Write Coverage : %0.2f%%", cg_master_write.get_inst_coverage());
		$display("Master Read Coverage : %0.2f%%", cg_master_read.get_inst_coverage());
		$display("Slave Routing Coverage : %0.2f%%", cg_slave_routing.get_inst_coverage());
		$display("Total Overall Coverage : %0.2f%%", $get_coverage());
		$display("--------------------------------------------------");
	endtask

endclass
