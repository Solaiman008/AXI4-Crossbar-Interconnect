class axi_xbar_data_pattern_test extends axi_xbar_base_test;

	function new(
		virtual axi_xbar_if #(ID_WIDTH) vif_m0,
		virtual axi_xbar_if #(ID_WIDTH) vif_m1,
		virtual axi_xbar_if #(EXT_ID_WIDTH) vif_s0,
		virtual axi_xbar_if #(EXT_ID_WIDTH) vif_s1
	);
		super.new(vif_m0, vif_m1, vif_s0, vif_s1);
	endfunction

	task run();
		logic [DATA_WIDTH-1:0] wdata_q[$];
		logic [STRB_WIDTH-1:0] wstrb_q[$];
		logic [DATA_WIDTH-1:0] rdata_q[$];
		logic [1:0] rresp_q[$];
		logic [ADDR_WIDTH-1:0] addr_s0;
		logic [ADDR_WIDTH-1:0] addr_s1;
		logic [ADDR_WIDTH-1:0] addr_err;
		logic [DATA_WIDTH-1:0] patterns[4] = '{
			{DATA_WIDTH{1'b1}},
			{DATA_WIDTH{1'b0}},
			{(DATA_WIDTH/2){2'b10}},
			{(DATA_WIDTH/2){2'b01}}
		};

		env.run();
		env.agt_m0.gen.reset();
		env.agt_m1.gen.reset();

		for(int i = 0; i < NUM_TARGETS; i++) begin
			for(int p = 0; p < 4; p++) begin
				wdata_q = {patterns[p]};
				wstrb_q = {'1};
				rdata_q = {patterns[p]};
				rresp_q = {2'b00};

				addr_s0 = $urandom_range(32'h0FFF_FFFF, 32'h0000_0000);
				addr_s1 = $urandom_range(32'h1FFF_FFFF, 32'h1000_0000);
				addr_err = $urandom_range(32'h7FFF_FFFF, 32'h2000_0000);

				if(i == 0) begin
					fork
						env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						env.agt_m0.gen.write(4'h1, addr_s0, 8'd0, 3'd3, 2'b01, wdata_q, wstrb_q);
					join
					fork
						env.agt_s0.gen.read_resp(8'd0, rdata_q, rresp_q, 1'b1);
						env.agt_m0.gen.read(4'h1, addr_s0, 8'd0, 3'd3, 2'b01);
					join
				end
				else if(i == 1) begin
					fork
						env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
						env.agt_m0.gen.write(4'h2, addr_s1, 8'd0, 3'd3, 2'b01, wdata_q, wstrb_q);
					join
					fork
						env.agt_s1.gen.read_resp(8'd0, rdata_q, rresp_q, 1'b1);
						env.agt_m0.gen.read(4'h2, addr_s1, 8'd0, 3'd3, 2'b01);
					join
				end
				else begin
					env.agt_m0.gen.write(4'h3, addr_err, 8'd0, 3'd3, 2'b01, wdata_q, wstrb_q);
					env.agt_m0.gen.read(4'h3, addr_err, 8'd0, 3'd3, 2'b01);
				end
			end
		end

		for(int i = 0; i < NUM_TARGETS; i++) begin
			for(int p = 0; p < 4; p++) begin
				wdata_q = {patterns[p]};
				wstrb_q = {'1};
				rdata_q = {patterns[p]};
				rresp_q = {2'b00};

				addr_s0 = $urandom_range(32'h0FFF_FFFF, 32'h0000_0000);
				addr_s1 = $urandom_range(32'h1FFF_FFFF, 32'h1000_0000);
				addr_err = $urandom_range(32'h7FFF_FFFF, 32'h2000_0000);

				if(i == 0) begin
					fork
						env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						env.agt_m1.gen.write(4'h1, addr_s0, 8'd0, 3'd3, 2'b01, wdata_q, wstrb_q);
					join
					fork
						env.agt_s0.gen.read_resp(8'd0, rdata_q, rresp_q, 1'b1);
						env.agt_m1.gen.read(4'h1, addr_s0, 8'd0, 3'd3, 2'b01);
					join
				end
				else if(i == 1) begin
					fork
						env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
						env.agt_m1.gen.write(4'h2, addr_s1, 8'd0, 3'd3, 2'b01, wdata_q, wstrb_q);
					join
					fork
						env.agt_s1.gen.read_resp(8'd0, rdata_q, rresp_q, 1'b1);
						env.agt_m1.gen.read(4'h2, addr_s1, 8'd0, 3'd3, 2'b01);
					join
				end
				else begin
					env.agt_m1.gen.write(4'h3, addr_err, 8'd0, 3'd3, 2'b01, wdata_q, wstrb_q);
					env.agt_m1.gen.read(4'h3, addr_err, 8'd0, 3'd3, 2'b01);
				end
			end
		end

		wait(
			(env.sb.m_aw_passed + env.sb.m_aw_failed == 2 * 3 * 4) &&
			(env.sb.m_w_passed + env.sb.m_w_failed == 2 * 3 * 4) &&
			(env.sb.s_b_passed + env.sb.s_b_failed == 2 * 3 * 4) &&
			(env.sb.m_ar_passed + env.sb.m_ar_failed == 2 * 3 * 4) &&
			(env.sb.s_r_passed + env.sb.s_r_failed == 2 * 3 * 4)
		);
		$display("Data Pattern Test Complete for M0 and M1");
		env.sb.report();
	endtask

endclass
