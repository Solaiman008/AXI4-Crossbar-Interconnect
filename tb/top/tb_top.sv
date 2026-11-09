module tb_top;
	import axi_xbar_param_pkg::*;
	import axi_xbar_test_pkg::*;

	bit aclk;

	initial begin
		aclk = 0;
		forever #5 aclk = ~aclk;
	end

	axi_xbar_if #(ID_WIDTH) m0_if(aclk);
	axi_xbar_if #(ID_WIDTH) m1_if(aclk);
	axi_xbar_if #(EXT_ID_WIDTH) s0_if(aclk);
	axi_xbar_if #(EXT_ID_WIDTH) s1_if(aclk);

	assign m1_if.arst_n = m0_if.arst_n;
	assign s1_if.arst_n = s0_if.arst_n;

axi_xbar_top #(
		.NUM_MASTERS(NUM_MASTERS),
		.NUM_SLAVES(NUM_SLAVES),
		.ADDR_WIDTH(ADDR_WIDTH),
		.DATA_WIDTH(DATA_WIDTH),
		.ID_WIDTH(ID_WIDTH),
		.FIFO_DEPTH(FIFO_DEPTH),
		.CNT_WIDTH(CNT_WIDTH)
	) dut(
		.aclk(aclk),
		.arst_n(m0_if.arst_n),

		.m_awid({m1_if.awid, m0_if.awid}),
		.m_awaddr({m1_if.awaddr, m0_if.awaddr}),
		.m_awlen({m1_if.awlen, m0_if.awlen}),
		.m_awsize({m1_if.awsize, m0_if.awsize}),
		.m_awburst({m1_if.awburst, m0_if.awburst}),
		.m_awvalid({m1_if.awvalid, m0_if.awvalid}),
		.m_awready({m1_if.awready, m0_if.awready}),
		
		.m_wdata({m1_if.wdata, m0_if.wdata}),
		.m_wstrb({m1_if.wstrb, m0_if.wstrb}),
		.m_wlast({m1_if.wlast, m0_if.wlast}),
		.m_wvalid({m1_if.wvalid, m0_if.wvalid}),
		.m_wready({m1_if.wready, m0_if.wready}),
		
		.m_bid({m1_if.bid, m0_if.bid}),
		.m_bresp({m1_if.bresp, m0_if.bresp}),
		.m_bvalid({m1_if.bvalid, m0_if.bvalid}),
		.m_bready({m1_if.bready, m0_if.bready}),
		
		.m_arid({m1_if.arid, m0_if.arid}),
		.m_araddr({m1_if.araddr, m0_if.araddr}),
		.m_arlen({m1_if.arlen, m0_if.arlen}),
		.m_arsize({m1_if.arsize, m0_if.arsize}),
		.m_arburst({m1_if.arburst, m0_if.arburst}),
		.m_arvalid({m1_if.arvalid, m0_if.arvalid}),
		.m_arready({m1_if.arready, m0_if.arready}),
		
		.m_rid({m1_if.rid, m0_if.rid}),
		.m_rdata({m1_if.rdata, m0_if.rdata}),
		.m_rresp({m1_if.rresp, m0_if.rresp}),
		.m_rlast({m1_if.rlast, m0_if.rlast}),
		.m_rvalid({m1_if.rvalid, m0_if.rvalid}),
		.m_rready({m1_if.rready, m0_if.rready}),
		
		.s_awid({s1_if.awid, s0_if.awid}),
		.s_awaddr({s1_if.awaddr, s0_if.awaddr}),
		.s_awlen({s1_if.awlen, s0_if.awlen}),
		.s_awsize({s1_if.awsize, s0_if.awsize}),
		.s_awburst({s1_if.awburst, s0_if.awburst}),
		.s_awvalid({s1_if.awvalid, s0_if.awvalid}),
		.s_awready({s1_if.awready, s0_if.awready}),
		
		.s_wdata({s1_if.wdata, s0_if.wdata}),
		.s_wstrb({s1_if.wstrb, s0_if.wstrb}),
		.s_wlast({s1_if.wlast, s0_if.wlast}),
		.s_wvalid({s1_if.wvalid, s0_if.wvalid}),
		.s_wready({s1_if.wready, s0_if.wready}),
		
		.s_bid({s1_if.bid, s0_if.bid}),
		.s_bresp({s1_if.bresp, s0_if.bresp}),
		.s_bvalid({s1_if.bvalid, s0_if.bvalid}),
		.s_bready({s1_if.bready, s0_if.bready}),
		
		.s_arid({s1_if.arid, s0_if.arid}),
		.s_araddr({s1_if.araddr, s0_if.araddr}),
		.s_arlen({s1_if.arlen, s0_if.arlen}),
		.s_arsize({s1_if.arsize, s0_if.arsize}),
		.s_arburst({s1_if.arburst, s0_if.arburst}),
		.s_arvalid({s1_if.arvalid, s0_if.arvalid}),
		.s_arready({s1_if.arready, s0_if.arready}),
		
		.s_rid({s1_if.rid, s0_if.rid}),
		.s_rdata({s1_if.rdata, s0_if.rdata}),
		.s_rresp({s1_if.rresp, s0_if.rresp}),
		.s_rlast({s1_if.rlast, s0_if.rlast}),
		.s_rvalid({s1_if.rvalid, s0_if.rvalid}),
		.s_rready({s1_if.rready, s0_if.rready}),

		.s_arst_n(s0_if.arst_n)
	);

	initial begin
		string test_name;

		if_init();

		if(!$value$plusargs("TEST=%s", test_name))
			test_name = "axi_xbar_reset_test";

		case(test_name)
			"axi_xbar_reset_test": begin
									   axi_xbar_reset_test test;
									   test = new(m0_if, m1_if, s0_if, s1_if);
									   test.run();
								   end
			"axi_xbar_single_read_write_test": begin
												   axi_xbar_single_read_write_test test;
												   test = new(m0_if, m1_if, s0_if, s1_if);
												   test.run();
											   end
			"axi_xbar_addr_decoding_test": begin
											   axi_xbar_addr_decoding_test test;
											   test = new(m0_if, m1_if, s0_if, s1_if);
											   test.run();
										   end
			"axi_xbar_arbitration_test": begin
											 axi_xbar_arbitration_test test;
											 test = new(m0_if, m1_if, s0_if, s1_if);
											 test.run();
										 end
			"axi_xbar_req_arbitration_test": begin
											 axi_xbar_req_arbitration_test test;
											 test = new(m0_if, m1_if, s0_if, s1_if);
											 test.run();
										 end
			"axi_xbar_resp_arbitration_test": begin
											 axi_xbar_resp_arbitration_test test;
											 test = new(m0_if, m1_if, s0_if, s1_if);
											 test.run();
										 end
			"axi_xbar_concurrent_routing_test": begin
													axi_xbar_concurrent_routing_test test;
													test = new(m0_if, m1_if, s0_if, s1_if);
													test.run();
												end
			"axi_xbar_burst_transfer_test": begin
												axi_xbar_burst_transfer_test test;
												test = new(m0_if, m1_if, s0_if, s1_if);
												test.run();
											end
			"axi_xbar_id_interleaving_test": begin
												 axi_xbar_id_interleaving_test test;
												 test = new(m0_if, m1_if, s0_if, s1_if);
												 test.run();
											 end
			"axi_xbar_backpressure_test": begin
											  axi_xbar_backpressure_test test;
											  test = new(m0_if, m1_if, s0_if, s1_if);
											  test.run();
										  end
			"axi_xbar_err_test": begin
									 axi_xbar_err_test test;
									 test = new(m0_if, m1_if, s0_if, s1_if);
									 test.run();
									 end
			"axi_xbar_stress_traffic_test": begin
												axi_xbar_stress_traffic_test test;
												test = new(m0_if, m1_if, s0_if, s1_if);
												test.run();
											end
			"axi_xbar_edge_addr_test": begin
										   axi_xbar_edge_addr_test test;
										   test = new(m0_if, m1_if, s0_if, s1_if);
										   test.run();
									   end
			"axi_xbar_data_pattern_test": begin
											  axi_xbar_data_pattern_test test;
											  test = new(m0_if, m1_if, s0_if, s1_if);
                                          	  test.run();
                                          end
			"axi_xbar_id_tracking_test": begin
											  axi_xbar_id_tracking_test test;
											  test = new(m0_if, m1_if, s0_if, s1_if);
                                          	  test.run();
                                          end

			default:
				$display("UNKNOWN TEST NAME");
		endcase

		$finish;
	end

	initial begin
		$dumpfile("dump.vcd");
		$dumpvars(0, tb_top);
		#1000000000;
		$fatal("Simulation time exceeded");
	end

	task if_init();
		m0_if.arst_n = 0;
		m0_if.awid = 0;
		m0_if.awaddr = 0;
		m0_if.awlen = 0;
		m0_if.awsize = 0;
		m0_if.awburst = 0;
		m0_if.awvalid = 0;
		m0_if.wdata = 0;
		m0_if.wstrb = 0;
		m0_if.wlast = 0;
		m0_if.wvalid = 0;
		m0_if.bready = 0;
		m0_if.arid = 0;
		m0_if.araddr = 0;
		m0_if.arlen = 0;
		m0_if.arsize = 0;
		m0_if.arburst = 0;
		m0_if.arvalid = 0;
		m0_if.rready = 0;

		m1_if.awid = 0;
		m1_if.awaddr = 0;
		m1_if.awlen = 0;
		m1_if.awsize = 0;
		m1_if.awburst = 0;
		m1_if.awvalid = 0;
		m1_if.wdata = 0;
		m1_if.wstrb = 0;
		m1_if.wlast = 0;
		m1_if.wvalid = 0;
		m1_if.bready = 0;
		m1_if.arid = 0;
		m1_if.araddr = 0;
		m1_if.arlen = 0;
		m1_if.arsize = 0;
		m1_if.arburst = 0;
		m1_if.arvalid = 0;
		m1_if.rready = 0;

		s0_if.awready = 0;
		s0_if.wready = 0;
		s0_if.bid = 0;
		s0_if.bresp = 0;
		s0_if.bvalid = 0;
		s0_if.arready = 0;
		s0_if.rid = 0;
		s0_if.rdata = 0;
		s0_if.rresp = 0;
		s0_if.rlast = 0;
		s0_if.rvalid = 0;

		s1_if.awready = 0;
		s1_if.wready = 0;
		s1_if.bid = 0;
		s1_if.bresp = 0;
		s1_if.bvalid = 0;
		s1_if.arready = 0;
		s1_if.rid = 0;
		s1_if.rdata = 0;
		s1_if.rresp = 0;
		s1_if.rlast = 0;
		s1_if.rvalid = 0;
	endtask
endmodule
