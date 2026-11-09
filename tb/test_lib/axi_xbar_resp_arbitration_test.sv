class axi_xbar_resp_arbitration_test extends axi_xbar_base_test;

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
        logic [DATA_WIDTH-1:0] wdata_2[$];
        logic [STRB_WIDTH-1:0] wstrb_q[$];
        logic [DATA_WIDTH-1:0] rdata_0[$];
        logic [DATA_WIDTH-1:0] rdata_1[$];
        logic [DATA_WIDTH-1:0] rdata_2[$];
        logic [1:0] rresp_q[$];
        logic [DATA_WIDTH-1:0] rand_data0;
        logic [DATA_WIDTH-1:0] rand_data1;
        logic [DATA_WIDTH-1:0] rand_data2;
        logic [ADDR_WIDTH-1:0] addr_s0;
        logic [ADDR_WIDTH-1:0] addr_s1;
        logic [ADDR_WIDTH-1:0] addr_err;

        env.run();
        env.agt_m0.gen.reset();
        env.agt_m1.gen.reset();

        for(int i = 0; i < 4; i++) begin
            repeat(REPEAT_COUNT) begin
                rand_data0 = {$urandom, $urandom};
                rand_data1 = {$urandom, $urandom};
                rand_data2 = {$urandom, $urandom};
                wdata_0 = {rand_data0};
                wdata_1 = {rand_data1};
                wdata_2 = {rand_data2};
                wstrb_q = {'1};
                rdata_0 = {rand_data0};
                rdata_1 = {rand_data1};
                rdata_2 = {rand_data2};
                rresp_q = {2'b00};

                addr_s0  = $urandom_range(32'h0FFF_FFFF, 32'h0000_0000);
                addr_s1  = $urandom_range(32'h1FFF_FFFF, 32'h1000_0000);
                addr_err = $urandom_range(32'h7FFF_FFFF, 32'h2000_0000);

                if(i == 0) begin
                    fork
                        env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
                        env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
                        begin
                            env.agt_m0.gen.write(4'h1, addr_s0, 8'd0, 3'd3, 2'b01, wdata_0, wstrb_q);
                            env.agt_m0.gen.write(4'h2, addr_s1, 8'd0, 3'd3, 2'b01, wdata_1, wstrb_q);
                        end
                    join
                    fork
                        env.agt_s0.gen.read_resp(8'd0, rdata_0, rresp_q, 1'b1);
                        env.agt_s1.gen.read_resp(8'd0, rdata_1, rresp_q, 1'b1);
                        begin
                            env.agt_m0.gen.read(4'h1, addr_s0, 8'd0, 3'd3, 2'b01);
                            env.agt_m0.gen.read(4'h2, addr_s1, 8'd0, 3'd3, 2'b01);
                        end
                    join
                end
                else if(i == 1) begin
                    fork
                        env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
                        begin
                            env.agt_m0.gen.write(4'h3, addr_s0, 8'd0, 3'd3, 2'b01, wdata_0, wstrb_q);
                            env.agt_m0.gen.write(4'h4, addr_err, 8'd0, 3'd3, 2'b01, wdata_1, wstrb_q);
                        end
                    join
                    fork
                        env.agt_s0.gen.read_resp(8'd0, rdata_0, rresp_q, 1'b1);
                        begin
                            env.agt_m0.gen.read(4'h3, addr_s0, 8'd0, 3'd3, 2'b01);
                            env.agt_m0.gen.read(4'h4, addr_err, 8'd0, 3'd3, 2'b01);
                        end
                    join
                end
                else if(i == 2) begin
                    fork
                        env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
                        begin
                            env.agt_m0.gen.write(4'h5, addr_s1, 8'd0, 3'd3, 2'b01, wdata_0, wstrb_q);
                            env.agt_m0.gen.write(4'h6, addr_err, 8'd0, 3'd3, 2'b01, wdata_1, wstrb_q);
                        end
                    join
                    fork
                        env.agt_s1.gen.read_resp(8'd0, rdata_0, rresp_q, 1'b1);
                        begin
                            env.agt_m0.gen.read(4'h5, addr_s1, 8'd0, 3'd3, 2'b01);
                            env.agt_m0.gen.read(4'h6, addr_err, 8'd0, 3'd3, 2'b01);
                        end
                    join
                end
                else begin
                    fork
                        env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
                        env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
                        begin
                            env.agt_m0.gen.write(4'h7, addr_s0,  8'd0, 3'd3, 2'b01, wdata_0, wstrb_q);
                            env.agt_m0.gen.write(4'h8, addr_s1,  8'd0, 3'd3, 2'b01, wdata_1, wstrb_q);
                            env.agt_m0.gen.write(4'h9, addr_err, 8'd0, 3'd3, 2'b01, wdata_2, wstrb_q);
                        end
                    join
                    fork
                        env.agt_s0.gen.read_resp(8'd0, rdata_0, rresp_q, 1'b1);
                        env.agt_s1.gen.read_resp(8'd0, rdata_1, rresp_q, 1'b1);
                        begin
                            env.agt_m0.gen.read(4'h7, addr_s0,  8'd0, 3'd3, 2'b01);
                            env.agt_m0.gen.read(4'h8, addr_s1,  8'd0, 3'd3, 2'b01);
                            env.agt_m0.gen.read(4'h9, addr_err, 8'd0, 3'd3, 2'b01);
                        end
                    join
                end
            end
        end

        for(int i = 0; i < 4; i++) begin
            repeat(REPEAT_COUNT) begin
                rand_data0 = {$urandom, $urandom};
                rand_data1 = {$urandom, $urandom};
                rand_data2 = {$urandom, $urandom};
                wdata_0 = {rand_data0};
                wdata_1 = {rand_data1};
                wdata_2 = {rand_data2};
                wstrb_q = {'1};
                rdata_0 = {rand_data0};
                rdata_1 = {rand_data1};
                rdata_2 = {rand_data2};
                rresp_q = {2'b00};

                addr_s0  = $urandom_range(32'h0FFF_FFFF, 32'h0000_0000);
                addr_s1  = $urandom_range(32'h1FFF_FFFF, 32'h1000_0000);
                addr_err = $urandom_range(32'h7FFF_FFFF, 32'h2000_0000);

                if(i == 0) begin
                    fork
                        env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
                        env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
                        begin
                            env.agt_m1.gen.write(4'h1, addr_s0, 8'd0, 3'd3, 2'b01, wdata_0, wstrb_q);
                            env.agt_m1.gen.write(4'h2, addr_s1, 8'd0, 3'd3, 2'b01, wdata_1, wstrb_q);
                        end
                    join
                    fork
                        env.agt_s0.gen.read_resp(8'd0, rdata_0, rresp_q, 1'b1);
                        env.agt_s1.gen.read_resp(8'd0, rdata_1, rresp_q, 1'b1);
                        begin
                            env.agt_m1.gen.read(4'h1, addr_s0, 8'd0, 3'd3, 2'b01);
                            env.agt_m1.gen.read(4'h2, addr_s1, 8'd0, 3'd3, 2'b01);
                        end
                    join
                end
                else if(i == 1) begin
                    fork
                        env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
                        begin
                            env.agt_m1.gen.write(4'h3, addr_s0, 8'd0, 3'd3, 2'b01, wdata_0, wstrb_q);
                            env.agt_m1.gen.write(4'h4, addr_err, 8'd0, 3'd3, 2'b01, wdata_1, wstrb_q);
                        end
                    join
                    fork
                        env.agt_s0.gen.read_resp(8'd0, rdata_0, rresp_q, 1'b1);
                        begin
                            env.agt_m1.gen.read(4'h3, addr_s0, 8'd0, 3'd3, 2'b01);
                            env.agt_m1.gen.read(4'h4, addr_err, 8'd0, 3'd3, 2'b01);
                        end
                    join
                end
                else if(i == 2) begin
                    fork
                        env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
                        begin
                            env.agt_m1.gen.write(4'h5, addr_s1, 8'd0, 3'd3, 2'b01, wdata_0, wstrb_q);
                            env.agt_m1.gen.write(4'h6, addr_err, 8'd0, 3'd3, 2'b01, wdata_1, wstrb_q);
                        end
                    join
                    fork
                        env.agt_s1.gen.read_resp(8'd0, rdata_0, rresp_q, 1'b1);
                        begin
                            env.agt_m1.gen.read(4'h5, addr_s1, 8'd0, 3'd3, 2'b01);
                            env.agt_m1.gen.read(4'h6, addr_err, 8'd0, 3'd3, 2'b01);
                        end
                    join
                end
                else begin
                    fork
                        env.agt_s0.gen.write_resp(2'b00, 1'b1, 1'b1);
                        env.agt_s1.gen.write_resp(2'b00, 1'b1, 1'b1);
                        begin
                            env.agt_m1.gen.write(4'h7, addr_s0,  8'd0, 3'd3, 2'b01, wdata_0, wstrb_q);
                            env.agt_m1.gen.write(4'h8, addr_s1,  8'd0, 3'd3, 2'b01, wdata_1, wstrb_q);
                            env.agt_m1.gen.write(4'h9, addr_err, 8'd0, 3'd3, 2'b01, wdata_2, wstrb_q);
                        end
                    join
                    fork
                        env.agt_s0.gen.read_resp(8'd0, rdata_0, rresp_q, 1'b1);
                        env.agt_s1.gen.read_resp(8'd0, rdata_1, rresp_q, 1'b1);
                        begin
                            env.agt_m1.gen.read(4'h7, addr_s0,  8'd0, 3'd3, 2'b01);
                            env.agt_m1.gen.read(4'h8, addr_s1,  8'd0, 3'd3, 2'b01);
                            env.agt_m1.gen.read(4'h9, addr_err,  8'd0, 3'd3, 2'b01);
                        end
                    join
                end
            end
        end

        wait(
            (env.sb.m_aw_passed + env.sb.m_aw_failed == 2 * (2 + 2 + 2 + 3) * REPEAT_COUNT) &&
            (env.sb.m_w_passed + env.sb.m_w_failed == 2 * (2 + 2 + 2 + 3) * REPEAT_COUNT) &&
            (env.sb.s_b_passed + env.sb.s_b_failed == 2 * (2 + 2 + 2 + 3) * REPEAT_COUNT) &&
            (env.sb.m_ar_passed + env.sb.m_ar_failed == 2 * (2 + 2 + 2 + 3) * REPEAT_COUNT) &&
            (env.sb.s_r_passed + env.sb.s_r_failed == 2 * (2 + 2 + 2 + 3) * REPEAT_COUNT)
        );
        $display("Response (Slave) Arbitration Test Complete for M0 and M1");
        env.sb.report();
    endtask

endclass
