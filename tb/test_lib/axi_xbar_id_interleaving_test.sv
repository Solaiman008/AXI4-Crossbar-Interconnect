class axi_xbar_id_interleaving_test extends axi_xbar_base_test;

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
		logic [DATA_WIDTH-1:0] rand_data_m0;
		logic [DATA_WIDTH-1:0] rand_data_m1;
		logic [ADDR_WIDTH-1:0] addr_s0;
		logic [ADDR_WIDTH-1:0] addr_s0_m1;
		logic [ADDR_WIDTH-1:0] addr_s1;
		logic [ADDR_WIDTH-1:0] addr_s1_m1;
		logic [ADDR_WIDTH-1:0] addr_err;
		logic [ID_WIDTH-1:0] id_m0;
		logic [ID_WIDTH-1:0] id_m1;

		env.run();
		env.agt_m0.gen.reset();
		env.agt_m1.gen.reset();

		for(int i = 0; i < 5; i++) begin
			for(int r = 0; r < REPEAT_COUNT; r++) begin
				rand_data_m0 = {$urandom, $urandom};
				rand_data_m1 = {$urandom, $urandom};

				id_m0 = $urandom_range((1<<ID_WIDTH)-1, 0);
				if(r % 2 == 0) begin
					id_m1 = ~id_m0;
				end
				else begin
					id_m1 = id_m0;
				end

				wdata_m0 = {rand_data_m0};
				wstrb_m0 = {'1};
				rdata_m0 = {rand_data_m0};
				rresp_m0 = {2'b00};

				wdata_m1 = {rand_data_m1};
				wstrb_m1 = {'1};
				rdata_m1 = {rand_data_m1};
				rresp_m1 = {2'b00};

				addr_s0 = $urandom_range(32'h0FFF_FFFF, 32'h0000_0000);
				addr_s0_m1 = $urandom_range(32'h0FFF_FFFF, 32'h0000_0000);
				addr_s1 = $urandom_range(32'h1FFF_FFFF, 32'h1000_0000);
				addr_s1_m1 = $urandom_range(32'h1FFF_FFFF, 32'h1000_0000);
				addr_err = $urandom_range(32'h7FFF_FFFF, 32'h2000_0000);

				if(i == 0) begin
					fork
						env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
						env.agt_m0.gen.write(id_m0, addr_s0, 8'd0, 3'd3, 2'b01, wdata_m0, wstrb_m0);
						env.agt_m1.gen.write(id_m1, addr_s1, 8'd0, 3'd3, 2'b01, wdata_m1, wstrb_m1);
					join
					fork
						env.agt_s0.gen.read_resp(8'd0, rdata_m0, rresp_m0, 1'b1);
						env.agt_s1.gen.read_resp(8'd0, rdata_m1, rresp_m1, 1'b1);
						env.agt_m0.gen.read(id_m0, addr_s0, 8'd0, 3'd3, 2'b01);
						env.agt_m1.gen.read(id_m1, addr_s1, 8'd0, 3'd3, 2'b01);
					join
				end
				else if(i == 1) begin
					fork
						env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
						env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						env.agt_m0.gen.write(id_m0, addr_s1, 8'd0, 3'd3, 2'b01, wdata_m0, wstrb_m0);
						env.agt_m1.gen.write(id_m1, addr_s0, 8'd0, 3'd3, 2'b01, wdata_m1, wstrb_m1);
					join
					fork
						env.agt_s1.gen.read_resp(8'd0, rdata_m0, rresp_m0, 1'b1);
						env.agt_s0.gen.read_resp(8'd0, rdata_m1, rresp_m1, 1'b1);
						env.agt_m0.gen.read(id_m0, addr_s1, 8'd0, 3'd3, 2'b01);
						env.agt_m1.gen.read(id_m1, addr_s0, 8'd0, 3'd3, 2'b01);
					join
				end
				else if(i == 2) begin
					fork
						env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						env.agt_m0.gen.write(id_m0, addr_err, 8'd0, 3'd3, 2'b01, wdata_m0, wstrb_m0);
						env.agt_m1.gen.write(id_m1, addr_s0, 8'd0, 3'd3, 2'b01, wdata_m1, wstrb_m1);
					join
					fork
						env.agt_s0.gen.read_resp(8'd0, rdata_m1, rresp_m1, 1'b1);
						env.agt_m0.gen.read(id_m0, addr_err, 8'd0, 3'd3, 2'b01);
						env.agt_m1.gen.read(id_m1, addr_s0, 8'd0, 3'd3, 2'b01);
					join
				end
				else if(i == 3) begin
					fork
						begin
							env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
							env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
						end
						env.agt_m0.gen.write(id_m0, addr_s0, 8'd0, 3'd3, 2'b01, wdata_m0, wstrb_m0);
						env.agt_m1.gen.write(id_m1, addr_s0_m1, 8'd0, 3'd3, 2'b01, wdata_m1, wstrb_m1);
					join
					fork
						begin
							env.agt_s0.gen.read_resp(8'd0, rdata_m0, rresp_m0, 1'b1);
							env.agt_s0.gen.read_resp(8'd0, rdata_m1, rresp_m1, 1'b1);
						end
						env.agt_m0.gen.read(id_m0, addr_s0, 8'd0, 3'd3, 2'b01);
						env.agt_m1.gen.read(id_m1, addr_s0_m1, 8'd0, 3'd3, 2'b01);
					join
				end
				else begin
					fork
						begin
							env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
							env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
						end
						env.agt_m0.gen.write(id_m0, addr_s1, 8'd0, 3'd3, 2'b01, wdata_m0, wstrb_m0);
						env.agt_m1.gen.write(id_m1, addr_s1_m1, 8'd0, 3'd3, 2'b01, wdata_m1, wstrb_m1);
					join
					fork
						begin
							env.agt_s1.gen.read_resp(8'd0, rdata_m0, rresp_m0, 1'b1);
							env.agt_s1.gen.read_resp(8'd0, rdata_m1, rresp_m1, 1'b1);
						end
						env.agt_m0.gen.read(id_m0, addr_s1, 8'd0, 3'd3, 2'b01);
						env.agt_m1.gen.read(id_m1, addr_s1_m1, 8'd0, 3'd3, 2'b01);
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
		$display("ID Interleaving Test Complete for M0 and M1");
		env.sb.report();
	endtask

endclass
