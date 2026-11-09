class axi_xbar_stress_traffic_test extends axi_xbar_base_test;

	function new(
		virtual axi_xbar_if #(ID_WIDTH) vif_m0,
		virtual axi_xbar_if #(ID_WIDTH) vif_m1,
		virtual axi_xbar_if #(EXT_ID_WIDTH) vif_s0,
		virtual axi_xbar_if #(EXT_ID_WIDTH) vif_s1
	);
		super.new(vif_m0, vif_m1, vif_s0, vif_s1);
	endfunction

	task run();
		logic [DATA_WIDTH-1:0] wdata_m0[$];
		logic [DATA_WIDTH-1:0] wdata_m1[$];
		logic [STRB_WIDTH-1:0] wstrb_m0[$];
		logic [STRB_WIDTH-1:0] wstrb_m1[$];
		logic [DATA_WIDTH-1:0] rdata_m0[$];
		logic [DATA_WIDTH-1:0] rdata_m1[$];
		logic [1:0] rresp_m0[$];
		logic [1:0] rresp_m1[$];
		logic [DATA_WIDTH-1:0] rand_data;
		logic [ADDR_WIDTH-1:0] addr_s0;
		logic [ADDR_WIDTH-1:0] addr_s0_m1;
		logic [ADDR_WIDTH-1:0] addr_s1;
		logic [ADDR_WIDTH-1:0] addr_s1_m1;
		logic [ADDR_WIDTH-1:0] addr_err;
		logic [ID_WIDTH-1:0] id_m0;
		logic [ID_WIDTH-1:0] id_m1;
		logic [7:0] len_m0;
		logic [7:0] len_m1;

		env.run();
		env.agt_m0.gen.reset();
		env.agt_m1.gen.reset();

		for(int i = 0; i < 5; i++) begin
			repeat(REPEAT_COUNT) begin
				id_m0 = $urandom_range((1<<ID_WIDTH)-1, 0);
				id_m1 = $urandom_range((1<<ID_WIDTH)-1, 0);
				len_m0 = $urandom_range(255, 0);
				len_m1 = $urandom_range(255, 0);

				wdata_m0.delete();
				wstrb_m0.delete();
				rdata_m0.delete();
				rresp_m0.delete();
				for(int b = 0; b <= len_m0; b++) begin
					rand_data = {$urandom, $urandom};
					wdata_m0.push_back(rand_data);
					wstrb_m0.push_back('1);
					rdata_m0.push_back(rand_data);
					rresp_m0.push_back(2'b00);
				end

				wdata_m1.delete();
				wstrb_m1.delete();
				rdata_m1.delete();
				rresp_m1.delete();
				for(int b = 0; b <= len_m1; b++) begin
					rand_data = {$urandom, $urandom};
					wdata_m1.push_back(rand_data);
					wstrb_m1.push_back('1);
					rdata_m1.push_back(rand_data);
					rresp_m1.push_back(2'b00);
				end

				addr_s0 = $urandom_range(32'h0FFF_FF00, 32'h0000_0000);
				addr_s0_m1 = $urandom_range(32'h0FFF_FF00, 32'h0000_0000);
				addr_s1 = $urandom_range(32'h1FFF_FF00, 32'h1000_0000);
				addr_s1_m1 = $urandom_range(32'h1FFF_FF00, 32'h1000_0000);
				addr_err = $urandom_range(32'h7FFF_FF00, 32'h2000_0000);

				if(i == 0) begin
					fork
						env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
						env.agt_m0.gen.write(id_m0, addr_s0, len_m0, 3'd3, 2'b01, wdata_m0, wstrb_m0);
						env.agt_m1.gen.write(id_m1, addr_s1, len_m1, 3'd3, 2'b01, wdata_m1, wstrb_m1);
					join
					fork
						env.agt_s0.gen.read_resp(len_m0, rdata_m0, rresp_m0, 1'b1);
						env.agt_s1.gen.read_resp(len_m1, rdata_m1, rresp_m1, 1'b1);
						env.agt_m0.gen.read(id_m0, addr_s0, len_m0, 3'd3, 2'b01);
						env.agt_m1.gen.read(id_m1, addr_s1, len_m1, 3'd3, 2'b01);
					join
				end
				else if(i == 1) begin
					fork
						env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
						env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						env.agt_m0.gen.write(id_m0, addr_s1, len_m0, 3'd3, 2'b01, wdata_m0, wstrb_m0);
						env.agt_m1.gen.write(id_m1, addr_s0, len_m1, 3'd3, 2'b01, wdata_m1, wstrb_m1);
					join
					fork
						env.agt_s1.gen.read_resp(len_m0, rdata_m0, rresp_m0, 1'b1);
						env.agt_s0.gen.read_resp(len_m1, rdata_m1, rresp_m1, 1'b1);
						env.agt_m0.gen.read(id_m0, addr_s1, len_m0, 3'd3, 2'b01);
						env.agt_m1.gen.read(id_m1, addr_s0, len_m1, 3'd3, 2'b01);
					join
				end
				else if(i == 2) begin
					fork
						env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						env.agt_m0.gen.write(id_m0, addr_err, len_m0, 3'd3, 2'b01, wdata_m0, wstrb_m0);
						env.agt_m1.gen.write(id_m1, addr_s0, len_m1, 3'd3, 2'b01, wdata_m1, wstrb_m1);
					join
					fork
						env.agt_s0.gen.read_resp(len_m1, rdata_m1, rresp_m1, 1'b1);
						env.agt_m0.gen.read(id_m0, addr_err, len_m0, 3'd3, 2'b01);
						env.agt_m1.gen.read(id_m1, addr_s0, len_m1, 3'd3, 2'b01);
					join
				end
				else if(i == 3) begin
					fork
						begin
							env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
							env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						end
						env.agt_m0.gen.write(id_m0, addr_s0, len_m0, 3'd3, 2'b01, wdata_m0, wstrb_m0);
						env.agt_m1.gen.write(id_m1, addr_s0_m1, len_m1, 3'd3, 2'b01, wdata_m1, wstrb_m1);
					join
					fork
						begin
							env.agt_s0.gen.read_resp(len_m0, rdata_m0, rresp_m0, 1'b1);
							env.agt_s0.gen.read_resp(len_m1, rdata_m1, rresp_m1, 1'b1);
						end
						env.agt_m0.gen.read(id_m0, addr_s0, len_m0, 3'd3, 2'b01);
						env.agt_m1.gen.read(id_m1, addr_s0_m1, len_m1, 3'd3, 2'b01);
					join
				end
				else begin
					fork
						begin
							env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
							env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
						end
						env.agt_m0.gen.write(id_m0, addr_s1, len_m0, 3'd3, 2'b01, wdata_m0, wstrb_m0);
						env.agt_m1.gen.write(id_m1, addr_s1_m1, len_m1, 3'd3, 2'b01, wdata_m1, wstrb_m1);
					join
					fork
						begin
							env.agt_s1.gen.read_resp(len_m0, rdata_m0, rresp_m0, 1'b1);
							env.agt_s1.gen.read_resp(len_m1, rdata_m1, rresp_m1, 1'b1);
						end
						env.agt_m0.gen.read(id_m0, addr_s1, len_m0, 3'd3, 2'b01);
						env.agt_m1.gen.read(id_m1, addr_s1_m1, len_m1, 3'd3, 2'b01);
					join
				end
			end
		end

		wait(
			(env.sb.m_aw_passed + env.sb.m_aw_failed == 2 * 5 * REPEAT_COUNT) &&
			(env.sb.m_w_passed + env.sb.m_w_failed == 2 * 5 * REPEAT_COUNT) &&
			(env.sb.s_b_passed + env.sb.s_b_failed == 2 * 5 * REPEAT_COUNT) &&
			(env.sb.m_ar_passed + env.sb.m_ar_failed == 2 * 5 * REPEAT_COUNT) &&
			(env.sb.s_r_passed + env.sb.s_r_failed == 2 * 5 * REPEAT_COUNT)
		);
		$display("Stress Traffic Test Complete for M0 and M1");
		env.sb.report();
	endtask

endclass
