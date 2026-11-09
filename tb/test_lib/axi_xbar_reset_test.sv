class axi_xbar_reset_test extends axi_xbar_base_test;

	virtual axi_xbar_if #(ID_WIDTH) vif_m0;
	virtual axi_xbar_if #(ID_WIDTH) vif_m1;
	virtual axi_xbar_if #(EXT_ID_WIDTH) vif_s0;
	virtual axi_xbar_if #(EXT_ID_WIDTH) vif_s1;

	function new(
		virtual axi_xbar_if #(ID_WIDTH) vif_m0,
		virtual axi_xbar_if #(ID_WIDTH) vif_m1,
		virtual axi_xbar_if #(EXT_ID_WIDTH) vif_s0,
		virtual axi_xbar_if #(EXT_ID_WIDTH) vif_s1
	);
		super.new(vif_m0, vif_m1, vif_s0, vif_s1);
		this.vif_m0 = vif_m0;
		this.vif_m1 = vif_m1;
		this.vif_s0 = vif_s0;
		this.vif_s1 = vif_s1;
	endfunction

	task check_reset_pins(string phase_name);
		wait(vif_m0.arst_n === 1'b0);
		@(posedge vif_m0.aclk);

		if(vif_s0.awvalid !== 1'b0 || vif_s0.wvalid !== 1'b0 || vif_s0.arvalid !== 1'b0 ||
		   vif_s1.awvalid !== 1'b0 || vif_s1.wvalid !== 1'b0 || vif_s1.arvalid !== 1'b0 ||
		   vif_m0.bvalid !== 1'b0 || vif_m0.rvalid !== 1'b0 ||
		   vif_m1.bvalid !== 1'b0 || vif_m1.rvalid !== 1'b0) begin
			$error("[RESET_TEST][%s] FAIL: Crossbar VALID output remained high/unknown during reset at time %0d", phase_name, $time);
		end
		else begin
			$display("[RESET_TEST][%s] PASS: All crossbar VALID outputs are 0 during reset at time %0d", phase_name, $time);
		end

		wait(vif_m0.arst_n === 1'b1);
	endtask

	task drive_all_paths(logic [7:0] burst_len);
		logic [DATA_WIDTH-1:0] wdata_0[$];
		logic [DATA_WIDTH-1:0] wdata_1[$];
		logic [STRB_WIDTH-1:0] wstrb_q[$];
		logic [DATA_WIDTH-1:0] rdata_0[$];
		logic [DATA_WIDTH-1:0] rdata_1[$];
		logic [1:0] rresp_q[$];
		logic [DATA_WIDTH-1:0] beat_data0;
		logic [DATA_WIDTH-1:0] beat_data1;
		logic [ADDR_WIDTH-1:0] addr_s0_m0;
		logic [ADDR_WIDTH-1:0] addr_s1_m0;
		logic [ADDR_WIDTH-1:0] addr_err_m0;
		logic [ADDR_WIDTH-1:0] addr_s0_m1;
		logic [ADDR_WIDTH-1:0] addr_s1_m1;
		logic [ADDR_WIDTH-1:0] addr_err_m1;

		wdata_0.delete();
		wdata_1.delete();
		wstrb_q.delete();
		rdata_0.delete();
		rdata_1.delete();
		rresp_q.delete();

		for(int b = 0; b <= burst_len; b++) begin
			beat_data0 = {$urandom, $urandom};
			beat_data1 = {$urandom, $urandom};
			wdata_0.push_back(beat_data0);
			wdata_1.push_back(beat_data1);
			wstrb_q.push_back('1);
			rdata_0.push_back(beat_data0);
			rdata_1.push_back(beat_data1);
			rresp_q.push_back(2'b00);
		end

		addr_s0_m0 = $urandom_range(32'h07FF_FFFF, 32'h0000_0000);
		addr_s0_m1 = $urandom_range(32'h0FFF_FFFF, 32'h0800_0000);
		addr_s1_m0 = $urandom_range(32'h17FF_FFFF, 32'h1000_0000);
		addr_s1_m1 = $urandom_range(32'h1FFF_FFFF, 32'h1800_0000);
		addr_err_m0 = $urandom_range(32'h3FFF_FFFF, 32'h2000_0000);
		addr_err_m1 = $urandom_range(32'h7FFF_FFFF, 32'h4000_0000);

		fork
			env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
			env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
			env.agt_m0.gen.write(4'h1, addr_s0_m0, burst_len, 3'd3, 2'b01, wdata_0, wstrb_q);
			env.agt_m1.gen.write(4'h2, addr_s1_m1, burst_len, 3'd3, 2'b01, wdata_1, wstrb_q);
		join

		fork
			env.agt_s0.gen.read_resp(burst_len, rdata_0, rresp_q, 1'b1);
			env.agt_s1.gen.read_resp(burst_len, rdata_1, rresp_q, 1'b1);
			env.agt_m0.gen.read(4'h1, addr_s0_m0, burst_len, 3'd3, 2'b01);
			env.agt_m1.gen.read(4'h2, addr_s1_m1, burst_len, 3'd3, 2'b01);
		join

		fork
			env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
			env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
			env.agt_m0.gen.write(4'h3, addr_s1_m0, burst_len, 3'd3, 2'b01, wdata_0, wstrb_q);
			env.agt_m1.gen.write(4'h4, addr_s0_m1, burst_len, 3'd3, 2'b01, wdata_1, wstrb_q);
		join

		fork
			env.agt_s1.gen.read_resp(burst_len, rdata_0, rresp_q, 1'b1);
			env.agt_s0.gen.read_resp(burst_len, rdata_1, rresp_q, 1'b1);
			env.agt_m0.gen.read(4'h3, addr_s1_m0, burst_len, 3'd3, 2'b01);
			env.agt_m1.gen.read(4'h4, addr_s0_m1, burst_len, 3'd3, 2'b01);
		join

		env.agt_m0.gen.write(4'h5, addr_err_m0, burst_len, 3'd3, 2'b01, wdata_0, wstrb_q);
		env.agt_m0.gen.read(4'h5, addr_err_m0, burst_len, 3'd3, 2'b01);
		env.agt_m1.gen.write(4'h6, addr_err_m1, burst_len, 3'd3, 2'b01, wdata_1, wstrb_q);
		env.agt_m1.gen.read(4'h6, addr_err_m1, burst_len, 3'd3, 2'b01);

	endtask

	task run();
		env.run();
		fork
			begin
				env.agt_m0.gen.reset();
				env.agt_m1.gen.reset();
			end
			check_reset_pins("COLD_RESET");
		join

		drive_all_paths($urandom_range(255, 0));
		wait(
			(env.sb.m_aw_passed + env.sb.m_aw_failed == 6) &&
			(env.sb.m_w_passed + env.sb.m_w_failed == 6) &&
			(env.sb.s_b_passed + env.sb.s_b_failed == 6) &&
			(env.sb.m_ar_passed + env.sb.m_ar_failed == 6) &&
			(env.sb.s_r_passed + env.sb.s_r_failed == 6)
		);
		$display("[RESET_TEST] Pre-reset traffic completed. Asserting Warm Reset...");

		fork
			begin
				env.agt_m0.gen.reset();
				env.agt_m1.gen.reset();
			end
			check_reset_pins("WARM_RESET");
		join

		drive_all_paths($urandom_range(255, 0));
		drive_all_paths($urandom_range(255, 0));

		wait(
			(env.sb.m_aw_passed + env.sb.m_aw_failed == 18) &&
			(env.sb.m_w_passed + env.sb.m_w_failed == 18) &&
			(env.sb.s_b_passed + env.sb.s_b_failed == 18) &&
			(env.sb.m_ar_passed + env.sb.m_ar_failed == 18) &&
			(env.sb.s_r_passed + env.sb.s_r_failed == 18)
		);
		$display("Reset Test (Cold Reset + Warm Reset + Post-Reset Recovery) Complete");
		env.sb.report();
	endtask

endclass
