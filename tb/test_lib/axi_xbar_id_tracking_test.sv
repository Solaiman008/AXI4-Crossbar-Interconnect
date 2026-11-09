class axi_xbar_id_tracking_test extends axi_xbar_base_test;

	function new(
		virtual axi_xbar_if #(ID_WIDTH) vif_m0,
		virtual axi_xbar_if #(ID_WIDTH) vif_m1,
		virtual axi_xbar_if #(EXT_ID_WIDTH) vif_s0,
		virtual axi_xbar_if #(EXT_ID_WIDTH) vif_s1
	);
		super.new(vif_m0, vif_m1, vif_s0, vif_s1);
	endfunction

	task run();
		logic [DATA_WIDTH-1:0] wdata_0[$];
		logic [DATA_WIDTH-1:0] wdata_1[$];
		logic [STRB_WIDTH-1:0] wstrb_0[$];
		logic [STRB_WIDTH-1:0] wstrb_1[$];
		logic [DATA_WIDTH-1:0] rdata_0[$];
		logic [DATA_WIDTH-1:0] rdata_1[$];
		logic [1:0] rresp_0[$];
		logic [1:0] rresp_1[$];
		logic [DATA_WIDTH-1:0] rand_data;
		logic [ADDR_WIDTH-1:0] addr_s0_0;
		logic [ADDR_WIDTH-1:0] addr_s0_1;
		logic [ADDR_WIDTH-1:0] addr_s1_0;
		logic [ADDR_WIDTH-1:0] addr_s1_1;
		logic [ID_WIDTH-1:0] id_0;
		logic [ID_WIDTH-1:0] id_1;
		logic [7:0] burst_len;

		env.run();
		env.agt_m0.gen.reset();
		env.agt_m1.gen.reset();

		for(int i = 0; i < 6; i++) begin
			for(int r = 0; r < REPEAT_COUNT; r++) begin
				burst_len = $urandom_range(255, 1);

				id_0 = $urandom_range((1<<ID_WIDTH)-1, 0);
				if(r % 2 == 0) begin
					id_1 = ~id_0;
				end
				else begin
					id_1 = id_0;
				end

				wdata_0.delete();
				wstrb_0.delete();
				rdata_0.delete();
				rresp_0.delete();
				for(int b = 0; b <= burst_len; b++) begin
					rand_data = {$urandom, $urandom};
					wdata_0.push_back(rand_data);
					wstrb_0.push_back('1);
					rdata_0.push_back(rand_data);
					rresp_0.push_back(2'b00);
				end

				wdata_1.delete();
				wstrb_1.delete();
				rdata_1.delete();
				rresp_1.delete();
				for(int b = 0; b <= burst_len; b++) begin
					rand_data = {$urandom, $urandom};
					wdata_1.push_back(rand_data);
					wstrb_1.push_back('1);
					rdata_1.push_back(rand_data);
					rresp_1.push_back(2'b00);
				end

				addr_s0_0 = $urandom_range(32'h0FFF_FFFF, 32'h0000_0000);
				addr_s0_1 = $urandom_range(32'h0FFF_FFFF, 32'h0000_0000);
				addr_s1_0 = $urandom_range(32'h1FFF_FFFF, 32'h1000_0000);
				addr_s1_1 = $urandom_range(32'h1FFF_FFFF, 32'h1000_0000);

				if(i == 0) begin
					fork
						begin
							env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
							env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						end
						begin
							env.agt_m0.gen.write(id_0, addr_s0_0, burst_len, 3'd3, 2'b01, wdata_0, wstrb_0);
							env.agt_m0.gen.write(id_1, addr_s0_1, burst_len, 3'd3, 2'b01, wdata_1, wstrb_1);
						end
					join
					fork
						begin
							env.agt_s0.gen.read_resp(burst_len, rdata_0, rresp_0, 1'b1);
							env.agt_s0.gen.read_resp(burst_len, rdata_1, rresp_1, 1'b1);
						end
						begin
							env.agt_m0.gen.read(id_0, addr_s0_0, burst_len, 3'd3, 2'b01);
							env.agt_m0.gen.read(id_1, addr_s0_1, burst_len, 3'd3, 2'b01);
						end
					join
				end
				else if(i == 1) begin
					fork
						begin
							env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
							env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
						end
						begin
							env.agt_m0.gen.write(id_0, addr_s1_0, burst_len, 3'd3, 2'b01, wdata_0, wstrb_0);
							env.agt_m0.gen.write(id_1, addr_s1_1, burst_len, 3'd3, 2'b01, wdata_1, wstrb_1);
						end
					join
					fork
						begin
							env.agt_s1.gen.read_resp(burst_len, rdata_0, rresp_0, 1'b1);
							env.agt_s1.gen.read_resp(burst_len, rdata_1, rresp_1, 1'b1);
						end
						begin
							env.agt_m0.gen.read(id_0, addr_s1_0, burst_len, 3'd3, 2'b01);
							env.agt_m0.gen.read(id_1, addr_s1_1, burst_len, 3'd3, 2'b01);
						end
					join
				end
				else if(i == 2) begin
					fork
						env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
						begin
							env.agt_m0.gen.write(id_0, addr_s0_0, burst_len, 3'd3, 2'b01, wdata_0, wstrb_0);
							env.agt_m0.gen.write(id_1, addr_s1_0, burst_len, 3'd3, 2'b01, wdata_1, wstrb_1);
						end
					join
					fork
						env.agt_s0.gen.read_resp(burst_len, rdata_0, rresp_0, 1'b1);
						env.agt_s1.gen.read_resp(burst_len, rdata_1, rresp_1, 1'b1);
						begin
							env.agt_m0.gen.read(id_0, addr_s0_0, burst_len, 3'd3, 2'b01);
							env.agt_m0.gen.read(id_1, addr_s1_0, burst_len, 3'd3, 2'b01);
						end
					join
				end
				else if(i == 3) begin
					fork
						begin
							env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
							env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						end
						begin
							env.agt_m1.gen.write(id_0, addr_s0_0, burst_len, 3'd3, 2'b01, wdata_0, wstrb_0);
							env.agt_m1.gen.write(id_1, addr_s0_1, burst_len, 3'd3, 2'b01, wdata_1, wstrb_1);
						end
					join
					fork
						begin
							env.agt_s0.gen.read_resp(burst_len, rdata_0, rresp_0, 1'b1);
							env.agt_s0.gen.read_resp(burst_len, rdata_1, rresp_1, 1'b1);
						end
						begin
							env.agt_m1.gen.read(id_0, addr_s0_0, burst_len, 3'd3, 2'b01);
							env.agt_m1.gen.read(id_1, addr_s0_1, burst_len, 3'd3, 2'b01);
						end
					join
				end
				else if(i == 4) begin
					fork
						begin
							env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
							env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
						end
						begin
							env.agt_m1.gen.write(id_0, addr_s1_0, burst_len, 3'd3, 2'b01, wdata_0, wstrb_0);
							env.agt_m1.gen.write(id_1, addr_s1_1, burst_len, 3'd3, 2'b01, wdata_1, wstrb_1);
						end
					join
					fork
						begin
							env.agt_s1.gen.read_resp(burst_len, rdata_0, rresp_0, 1'b1);
							env.agt_s1.gen.read_resp(burst_len, rdata_1, rresp_1, 1'b1);
						end
						begin
							env.agt_m1.gen.read(id_0, addr_s1_0, burst_len, 3'd3, 2'b01);
							env.agt_m1.gen.read(id_1, addr_s1_1, burst_len, 3'd3, 2'b01);
						end
					join
				end
				else begin
					fork
						env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
						env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						begin
							env.agt_m1.gen.write(id_0, addr_s1_0, burst_len, 3'd3, 2'b01, wdata_0, wstrb_0);
							env.agt_m1.gen.write(id_1, addr_s0_0, burst_len, 3'd3, 2'b01, wdata_1, wstrb_1);
						end
					join
					fork
						env.agt_s1.gen.read_resp(burst_len, rdata_0, rresp_0, 1'b1);
						env.agt_s0.gen.read_resp(burst_len, rdata_1, rresp_1, 1'b1);
						begin
							env.agt_m1.gen.read(id_0, addr_s1_0, burst_len, 3'd3, 2'b01);
							env.agt_m1.gen.read(id_1, addr_s0_0, burst_len, 3'd3, 2'b01);
						end
					join
				end
			end
		end

		wait(
			(env.sb.m_aw_passed + env.sb.m_aw_failed == 2 * 6 * REPEAT_COUNT) &&
			(env.sb.m_w_passed + env.sb.m_w_failed == 2 * 6 * REPEAT_COUNT) &&
			(env.sb.s_b_passed + env.sb.s_b_failed == 2 * 6 * REPEAT_COUNT) &&
			(env.sb.m_ar_passed + env.sb.m_ar_failed == 2 * 6 * REPEAT_COUNT) &&
			(env.sb.s_r_passed + env.sb.s_r_failed == 2 * 6 * REPEAT_COUNT)
		);
		$display("ID Tracking Test Complete for M0 and M1");
		env.sb.report();
	endtask

endclass
