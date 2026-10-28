module axi4_xbar_top #(
    parameter int NUM_MASTERS = 2,
    parameter int NUM_SLAVES = 2,
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 64,
    parameter int ID_WIDTH = 4,
    parameter int FIFO_DEPTH = 8,
    parameter int CNT_WIDTH = 4,
    parameter int MASTER_WIDTH = (NUM_MASTERS > 1) ? $clog2(NUM_MASTERS) : 1,
    parameter int EXT_ID_WIDTH = ID_WIDTH + MASTER_WIDTH
) (
    input logic aclk,
    input logic arst_n,

    // Master AW channel
    input logic [NUM_MASTERS-1:0][ID_WIDTH-1:0] m_awid,
    input logic [NUM_MASTERS-1:0][ADDR_WIDTH-1:0] m_awaddr,
    input logic [NUM_MASTERS-1:0][7:0] m_awlen,
    input logic [NUM_MASTERS-1:0][2:0] m_awsize,
    input logic [NUM_MASTERS-1:0][1:0] m_awburst,
    input logic [NUM_MASTERS-1:0] m_awvalid,
    output logic [NUM_MASTERS-1:0] m_awready,

    // Master W channel
    input logic [NUM_MASTERS-1:0][DATA_WIDTH-1:0] m_wdata,
    input logic [NUM_MASTERS-1:0][DATA_WIDTH/8-1:0] m_wstrb,
    input logic [NUM_MASTERS-1:0] m_wlast,
    input logic [NUM_MASTERS-1:0] m_wvalid,
    output logic [NUM_MASTERS-1:0] m_wready,

    // Master B channel
    output logic [NUM_MASTERS-1:0][ID_WIDTH-1:0] m_bid,
    output logic [NUM_MASTERS-1:0][1:0] m_bresp,
    output logic [NUM_MASTERS-1:0] m_bvalid,
    input logic [NUM_MASTERS-1:0] m_bready,

    // Master AR channel
    input logic [NUM_MASTERS-1:0][ID_WIDTH-1:0] m_arid,
    input logic [NUM_MASTERS-1:0][ADDR_WIDTH-1:0] m_araddr,
    input logic [NUM_MASTERS-1:0][7:0] m_arlen,
    input logic [NUM_MASTERS-1:0][2:0] m_arsize,
    input logic [NUM_MASTERS-1:0][1:0] m_arburst,
    input logic [NUM_MASTERS-1:0] m_arvalid,
    output logic [NUM_MASTERS-1:0] m_arready,

    // Master R channel
    output logic [NUM_MASTERS-1:0][ID_WIDTH-1:0] m_rid,
    output logic [NUM_MASTERS-1:0][DATA_WIDTH-1:0] m_rdata,
    output logic [NUM_MASTERS-1:0][1:0] m_rresp,
    output logic [NUM_MASTERS-1:0] m_rlast,
    output logic [NUM_MASTERS-1:0] m_rvalid,
    input logic [NUM_MASTERS-1:0] m_rready,

    // External slave AW channel
    output logic [NUM_SLAVES-1:0][EXT_ID_WIDTH-1:0] s_awid,
    output logic [NUM_SLAVES-1:0][ADDR_WIDTH-1:0] s_awaddr,
    output logic [NUM_SLAVES-1:0][7:0] s_awlen,
    output logic [NUM_SLAVES-1:0][2:0] s_awsize,
    output logic [NUM_SLAVES-1:0][1:0] s_awburst,
    output logic [NUM_SLAVES-1:0] s_awvalid,
    input logic [NUM_SLAVES-1:0] s_awready,

    // External slave W channel
    output logic [NUM_SLAVES-1:0][DATA_WIDTH-1:0] s_wdata,
    output logic [NUM_SLAVES-1:0][DATA_WIDTH/8-1:0] s_wstrb,
    output logic [NUM_SLAVES-1:0] s_wlast,
    output logic [NUM_SLAVES-1:0] s_wvalid,
    input logic [NUM_SLAVES-1:0] s_wready,

    // External slave B channel
    input logic [NUM_SLAVES-1:0][EXT_ID_WIDTH-1:0] s_bid,
    input logic [NUM_SLAVES-1:0][1:0] s_bresp,
    input logic [NUM_SLAVES-1:0] s_bvalid,
    output logic [NUM_SLAVES-1:0] s_bready,

    // External slave AR channel
    output logic [NUM_SLAVES-1:0][EXT_ID_WIDTH-1:0] s_arid,
    output logic [NUM_SLAVES-1:0][ADDR_WIDTH-1:0] s_araddr,
    output logic [NUM_SLAVES-1:0][7:0] s_arlen,
    output logic [NUM_SLAVES-1:0][2:0] s_arsize,
    output logic [NUM_SLAVES-1:0][1:0] s_arburst,
    output logic [NUM_SLAVES-1:0] s_arvalid,
    input logic [NUM_SLAVES-1:0] s_arready,

    // External slave R channel
    input logic [NUM_SLAVES-1:0][EXT_ID_WIDTH-1:0] s_rid,
    input logic [NUM_SLAVES-1:0][DATA_WIDTH-1:0] s_rdata,
    input logic [NUM_SLAVES-1:0][1:0] s_rresp,
    input logic [NUM_SLAVES-1:0] s_rlast,
    input logic [NUM_SLAVES-1:0] s_rvalid,
    output logic [NUM_SLAVES-1:0] s_rready
);

    // Target parameters and address decoding helper function
    localparam int NUM_TARGETS = NUM_SLAVES + 1;
    localparam int TARGET_WIDTH = (NUM_TARGETS > 1) ? $clog2(NUM_TARGETS) : 1;
    localparam int STRB_WIDTH = DATA_WIDTH / 8;

    typedef struct packed {
        logic [ID_WIDTH-1:0] id;
        logic [ADDR_WIDTH-1:0] addr;
        logic [7:0] len;
        logic [2:0] size;
        logic [1:0] burst;
    } addr_item;

    typedef struct packed {
        logic [DATA_WIDTH-1:0] data;
        logic [STRB_WIDTH-1:0] strb;
        logic last;
    } w_item;

    typedef struct packed {
        logic [EXT_ID_WIDTH-1:0] id;
        logic [1:0] resp;
        logic [TARGET_WIDTH-1:0] target;
    } b_item;

    typedef struct packed {
        logic [EXT_ID_WIDTH-1:0] id;
        logic [DATA_WIDTH-1:0] data;
        logic [1:0] resp;
        logic last;
        logic [TARGET_WIDTH-1:0] target;
    } r_item;

    // Master-side ingress FIFO storage and control wires
    addr_item aw_q_out [NUM_MASTERS];
    addr_item ar_q_out [NUM_MASTERS];
    w_item w_q_out [NUM_MASTERS];

    logic aw_q_full [NUM_MASTERS];
    logic aw_q_empty [NUM_MASTERS];
    logic ar_q_full [NUM_MASTERS];
    logic ar_q_empty [NUM_MASTERS];
    logic w_q_full [NUM_MASTERS];
    logic w_q_empty [NUM_MASTERS];

    logic aw_q_pop [NUM_MASTERS];
    logic ar_q_pop [NUM_MASTERS];
    logic w_q_pop [NUM_MASTERS];

    logic [NUM_MASTERS-1:0] aw_hazard_stall;
    logic [NUM_MASTERS-1:0] ar_hazard_stall;
    logic [NUM_MASTERS-1:0] aw_alloc_en, ar_alloc_en;
    logic [NUM_MASTERS-1:0][ID_WIDTH-1:0] aw_alloc_id, ar_alloc_id;
    logic [NUM_MASTERS-1:0][TARGET_WIDTH-1:0] aw_alloc_slv, ar_alloc_slv;
    logic [NUM_MASTERS-1:0] b_dealloc_en, r_dealloc_en;
    logic [NUM_MASTERS-1:0][ID_WIDTH-1:0] b_dealloc_id, r_dealloc_id;

    // Per-master ingress FIFO instances and ID hazard trackers
    for (genvar m = 0; m < NUM_MASTERS; m++) begin : g_master_fifos
        addr_item aw_in;
        addr_item ar_in;
        w_item w_in;

        assign aw_in = {m_awid[m], m_awaddr[m], m_awlen[m], m_awsize[m], m_awburst[m]};
        assign ar_in = {m_arid[m], m_araddr[m], m_arlen[m], m_arsize[m], m_arburst[m]};
        assign w_in = {m_wdata[m], m_wstrb[m], m_wlast[m]};

        axi_xbar_id_tracker #(
            .ID_WIDTH(ID_WIDTH),
            .NUM_SLAVES(NUM_SLAVES),
            .CNT_WIDTH(CNT_WIDTH)
        ) u_id_tracker (
            .aclk(aclk),
            .arst_n(arst_n),
            .aw_chk_id(aw_q_out[m].id),
            .aw_chk_slv(decode_addr(aw_q_out[m].addr)),
            .aw_hazard_stall(aw_hazard_stall[m]),
            .ar_chk_id(ar_q_out[m].id),
            .ar_chk_slv(decode_addr(ar_q_out[m].addr)),
            .ar_hazard_stall(ar_hazard_stall[m]),
            .aw_alloc_en(aw_alloc_en[m]),
            .aw_alloc_id(aw_alloc_id[m]),
            .aw_alloc_slv(aw_alloc_slv[m]),
            .ar_alloc_en(ar_alloc_en[m]),
            .ar_alloc_id(ar_alloc_id[m]),
            .ar_alloc_slv(ar_alloc_slv[m]),
            .b_dealloc_en(b_dealloc_en[m]),
            .b_dealloc_id(b_dealloc_id[m]),
            .r_dealloc_en(r_dealloc_en[m]),
            .r_dealloc_id(r_dealloc_id[m])
        );

        assign b_dealloc_en[m] = m_bvalid[m] && m_bready[m];
        assign b_dealloc_id[m] = m_bid[m];
        assign r_dealloc_en[m] = m_rvalid[m] && m_rready[m] && m_rlast[m];
        assign r_dealloc_id[m] = m_rid[m];

        assign m_awready[m] = arst_n && !aw_q_full[m];
        assign m_arready[m] = arst_n && !ar_q_full[m];
        assign m_wready[m] = arst_n && !w_q_full[m];

        sync_fifo #(
            .DATA_WIDTH($bits(addr_item)),
            .FIFO_DEPTH(FIFO_DEPTH)
        ) u_aw_fifo (
            .data_in(aw_in),
            .write(m_awvalid[m] && m_awready[m]),
            .read(aw_q_pop[m]),
            .clk(aclk),
            .resetn(arst_n),
            .data_out(aw_q_out[m]),
            .full(aw_q_full[m]),
            .empty(aw_q_empty[m])
        );

        sync_fifo #(
            .DATA_WIDTH($bits(addr_item)),
            .FIFO_DEPTH(FIFO_DEPTH)
        ) u_ar_fifo (
            .data_in(ar_in),
            .write(m_arvalid[m] && m_arready[m]),
            .read(ar_q_pop[m]),
            .clk(aclk),
            .resetn(arst_n),
            .data_out(ar_q_out[m]),
            .full(ar_q_full[m]),
            .empty(ar_q_empty[m])
        );

        sync_fifo #(
            .DATA_WIDTH($bits(w_item)),
            .FIFO_DEPTH(FIFO_DEPTH)
        ) u_w_fifo (
            .data_in(w_in),
            .write(m_wvalid[m] && m_wready[m]),
            .read(w_q_pop[m]),
            .clk(aclk),
            .resetn(arst_n),
            .data_out(w_q_out[m]),
            .full(w_q_full[m]),
            .empty(w_q_empty[m])
        );
    end

    // Internal target-side bus declarations
    logic [NUM_TARGETS-1:0][EXT_ID_WIDTH-1:0] t_awid, t_arid;
    logic [NUM_TARGETS-1:0][ADDR_WIDTH-1:0] t_awaddr, t_araddr;
    logic [NUM_TARGETS-1:0][7:0] t_awlen, t_arlen;
    logic [NUM_TARGETS-1:0][2:0] t_awsize, t_arsize;
    logic [NUM_TARGETS-1:0][1:0] t_awburst, t_arburst;
    logic [NUM_TARGETS-1:0] t_awvalid, t_awready;
    logic [NUM_TARGETS-1:0] t_arvalid, t_arready;

    logic [NUM_TARGETS-1:0][DATA_WIDTH-1:0] t_wdata;
    logic [NUM_TARGETS-1:0][STRB_WIDTH-1:0] t_wstrb;
    logic [NUM_TARGETS-1:0] t_wlast, t_wvalid, t_wready;

    logic [NUM_TARGETS-1:0][EXT_ID_WIDTH-1:0] t_bid, t_rid;
    logic [NUM_TARGETS-1:0][1:0] t_bresp, t_rresp;
    logic [NUM_TARGETS-1:0][DATA_WIDTH-1:0] t_rdata;
    logic [NUM_TARGETS-1:0] t_bvalid, t_bready;
    logic [NUM_TARGETS-1:0] t_rvalid, t_rready, t_rlast;

    // Connect external slaves to targets 0 and 1
    assign s_awid = t_awid[NUM_SLAVES-1:0];
    assign s_awaddr = t_awaddr[NUM_SLAVES-1:0];
    assign s_awlen = t_awlen[NUM_SLAVES-1:0];
    assign s_awsize = t_awsize[NUM_SLAVES-1:0];
    assign s_awburst = t_awburst[NUM_SLAVES-1:0];
    assign s_awvalid = t_awvalid[NUM_SLAVES-1:0];
    assign t_awready[NUM_SLAVES-1:0] = s_awready;

    assign s_wdata = t_wdata[NUM_SLAVES-1:0];
    assign s_wstrb = t_wstrb[NUM_SLAVES-1:0];
    assign s_wlast = t_wlast[NUM_SLAVES-1:0];
    assign s_wvalid = t_wvalid[NUM_SLAVES-1:0];
    assign t_wready[NUM_SLAVES-1:0] = s_wready;

    assign t_bid[NUM_SLAVES-1:0] = s_bid;
    assign t_bresp[NUM_SLAVES-1:0] = s_bresp;
    assign t_bvalid[NUM_SLAVES-1:0] = s_bvalid;
    assign s_bready = t_bready[NUM_SLAVES-1:0];

    assign s_arid = t_arid[NUM_SLAVES-1:0];
    assign s_araddr = t_araddr[NUM_SLAVES-1:0];
    assign s_arlen = t_arlen[NUM_SLAVES-1:0];
    assign s_arsize = t_arsize[NUM_SLAVES-1:0];
    assign s_arburst = t_arburst[NUM_SLAVES-1:0];
    assign s_arvalid = t_arvalid[NUM_SLAVES-1:0];
    assign t_arready[NUM_SLAVES-1:0] = s_arready;

    assign t_rid[NUM_SLAVES-1:0] = s_rid;
    assign t_rdata[NUM_SLAVES-1:0] = s_rdata;
    assign t_rresp[NUM_SLAVES-1:0] = s_rresp;
    assign t_rlast[NUM_SLAVES-1:0] = s_rlast;
    assign t_rvalid[NUM_SLAVES-1:0] = s_rvalid;
    assign s_rready = t_rready[NUM_SLAVES-1:0];

    // Internal default slave instance (Target 2 for DECERR handling)
    axi_xbar_default_slave #(
        .ID_WIDTH(ID_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_MASTERS(NUM_MASTERS),
        .MASTER_WIDTH(MASTER_WIDTH),
        .EXT_ID_WIDTH(EXT_ID_WIDTH)
    ) u_default_slave (
        .aclk(aclk),
        .arst_n(arst_n),
        .awid(t_awid[2]),
        .awvalid(t_awvalid[2]),
        .awready(t_awready[2]),
        .wlast(t_wlast[2]),
        .wvalid(t_wvalid[2]),
        .wready(t_wready[2]),
        .bid(t_bid[2]),
        .bresp(t_bresp[2]),
        .bvalid(t_bvalid[2]),
        .bready(t_bready[2]),
        .arid(t_arid[2]),
        .arlen(t_arlen[2]),
        .arvalid(t_arvalid[2]),
        .arready(t_arready[2]),
        .rid(t_rid[2]),
        .rdata(t_rdata[2]),
        .rresp(t_rresp[2]),
        .rlast(t_rlast[2]),
        .rvalid(t_rvalid[2]),
        .rready(t_rready[2])
    );

    // ID extenders to prepend master indices to transaction IDs
    logic [NUM_MASTERS-1:0][EXT_ID_WIDTH-1:0] ext_awid;
    logic [NUM_MASTERS-1:0][EXT_ID_WIDTH-1:0] ext_arid;

    for (genvar m = 0; m < NUM_MASTERS; m++) begin : g_id_extension
        axi_xbar_id_extender #(
            .ID_WIDTH(ID_WIDTH),
            .NUM_MASTERS(NUM_MASTERS),
            .MASTER_WIDTH(MASTER_WIDTH),
            .EXT_ID_WIDTH(EXT_ID_WIDTH)
        ) u_aw_ext (
            .id_in(aw_q_out[m].id),
            .master_id(MASTER_WIDTH'(m)),
            .id_out(ext_awid[m])
        );

        axi_xbar_id_extender #(
            .ID_WIDTH(ID_WIDTH),
            .NUM_MASTERS(NUM_MASTERS),
            .MASTER_WIDTH(MASTER_WIDTH),
            .EXT_ID_WIDTH(EXT_ID_WIDTH)
        ) u_ar_ext (
            .id_in(ar_q_out[m].id),
            .master_id(MASTER_WIDTH'(m)),
            .id_out(ext_arid[m])
        );
    end

    // Target-side W Route FIFOs to preserve AW-to-W data ordering
    logic [MASTER_WIDTH-1:0] w_route_in [NUM_TARGETS];
    logic [MASTER_WIDTH-1:0] w_route_out [NUM_TARGETS];
    logic w_route_push [NUM_TARGETS];
    logic w_route_pop [NUM_TARGETS];
    logic w_route_full [NUM_TARGETS];
    logic w_route_empty [NUM_TARGETS];

    for (genvar t = 0; t < NUM_TARGETS; t++) begin : g_w_route_fifos
        sync_fifo #(
            .DATA_WIDTH(MASTER_WIDTH),
            .FIFO_DEPTH(FIFO_DEPTH)
        ) u_w_route_fifo (
            .data_in(w_route_in[t]),
            .write(w_route_push[t]),
            .read(w_route_pop[t]),
            .clk(aclk),
            .resetn(arst_n),
            .data_out(w_route_out[t]),
            .full(w_route_full[t]),
            .empty(w_route_empty[t])
        );
    end

    // Shared AW and AR Arbiters for centralized address control
    logic [NUM_MASTERS-1:0] aw_req, aw_grant;
    logic [NUM_MASTERS-1:0] ar_req, ar_grant;
    logic aw_gvalid, ar_gvalid;
    logic [MASTER_WIDTH-1:0] aw_gidx, ar_gidx;
    logic aw_unlock, ar_unlock;

    always_comb begin
        aw_req = '0;
        ar_req = '0;

        for (int m = 0; m < NUM_MASTERS; m++) begin
            if (!aw_q_empty[m] && !aw_hazard_stall[m] && !w_route_full[decode_addr(aw_q_out[m].addr)])
                aw_req[m] = 1'b1;

            if (!ar_q_empty[m] && !ar_hazard_stall[m] && !( !aw_q_empty[m] && !aw_hazard_stall[m] && (aw_q_out[m].id == ar_q_out[m].id) ))
                ar_req[m] = 1'b1;
        end
    end

    rr_arbiter #(
        .NUM_REQ(NUM_MASTERS)
    ) u_aw_arb (
        .aclk(aclk),
        .arst_n(arst_n),
        .req(aw_req),
        .unlock_en(aw_unlock),
        .grant(aw_grant),
        .grant_idx(aw_gidx),
        .grant_valid(aw_gvalid)
    );

    rr_arbiter #(
        .NUM_REQ(NUM_MASTERS)
    ) u_ar_arb (
        .aclk(aclk),
        .arst_n(arst_n),
        .req(ar_req),
        .unlock_en(ar_unlock),
        .grant(ar_grant),
        .grant_idx(ar_gidx),
        .grant_valid(ar_gvalid)
    );

    // Shared AW/AR multiplexing, address decoding, and route pushing logic
    always_comb begin
        t_awid = '0; 
		t_awaddr = '0; 
		t_awlen = '0;
        t_awsize = '0; 
		t_awburst = '0; 
		t_awvalid = '0;
        aw_q_pop = '{default:0};
        aw_unlock = 1'b0;
        aw_alloc_en = '0; 
		aw_alloc_id = '0; 
		aw_alloc_slv = '0;
        w_route_in = '{default:0};
        w_route_push = '{default:0};

        t_arid = '0; 
		t_araddr = '0; 
		t_arlen = '0;
        t_arsize = '0; 
		t_arburst = '0; 
		t_arvalid = '0;
        ar_q_pop = '{default:0};
        ar_unlock = 1'b0;
        ar_alloc_en = '0; 
		ar_alloc_id = '0; 
		ar_alloc_slv = '0;

        if (aw_gvalid) begin
            int m, t;
            m = int'(aw_gidx);
            t = int'(decode_addr(aw_q_out[m].addr));

            t_awid[t] = ext_awid[m];
            t_awaddr[t] = aw_q_out[m].addr;
            t_awlen[t] = aw_q_out[m].len;
            t_awsize[t] = aw_q_out[m].size;
            t_awburst[t] = aw_q_out[m].burst;
            t_awvalid[t] = !aw_q_empty[m] && !w_route_full[t];

            if (t_awvalid[t] && t_awready[t]) begin
                aw_q_pop[m] = 1'b1;
                aw_unlock = 1'b1;
                aw_alloc_en[m] = 1'b1;
                aw_alloc_id[m] = aw_q_out[m].id;
                aw_alloc_slv[m] = TARGET_WIDTH'(t);
                w_route_in[t] = MASTER_WIDTH'(m);
                w_route_push[t] = 1'b1;
            end
        end

        if (ar_gvalid) begin
            int m, t;
            m = int'(ar_gidx);
            t = int'(decode_addr(ar_q_out[m].addr));

            t_arid[t] = ext_arid[m];
            t_araddr[t] = ar_q_out[m].addr;
            t_arlen[t] = ar_q_out[m].len;
            t_arsize[t] = ar_q_out[m].size;
            t_arburst[t] = ar_q_out[m].burst;
            t_arvalid[t] = !ar_q_empty[m];

            if (t_arvalid[t] && t_arready[t]) begin
                ar_q_pop[m] = 1'b1;
                ar_unlock = 1'b1;
                ar_alloc_en[m] = 1'b1;
                ar_alloc_id[m] = ar_q_out[m].id;
                ar_alloc_slv[m] = TARGET_WIDTH'(t);
            end
        end
    end

    // Target-side W channel routing based on W Route FIFOs
    always_comb begin
        t_wdata = '0;
        t_wstrb = '0;
        t_wlast = '0;
        t_wvalid = '0;
        w_q_pop = '{default:0};
        w_route_pop = '{default:0};

        for (int t = 0; t < NUM_TARGETS; t++) begin
            if (!w_route_empty[t]) begin
                int m;
                m = int'(w_route_out[t]);

                t_wdata[t] = w_q_out[m].data;
                t_wstrb[t] = w_q_out[m].strb;
                t_wlast[t] = w_q_out[m].last;
                t_wvalid[t] = !w_q_empty[m];

                if (t_wvalid[t] && t_wready[t]) begin
                    w_q_pop[m] = 1'b1;
                    if (w_q_out[m].last) begin
                        w_route_pop[t] = 1'b1;
                    end
                end
            end
        end
    end

    // Target-side B and R response buffer FIFOs
    b_item tb_in [NUM_TARGETS];
    b_item tb_out [NUM_TARGETS];
    r_item tr_in [NUM_TARGETS];
    r_item tr_out [NUM_TARGETS];

    logic tb_full [NUM_TARGETS];
    logic tb_empty [NUM_TARGETS];
    logic tr_full [NUM_TARGETS];
    logic tr_empty [NUM_TARGETS];

    logic tb_push [NUM_TARGETS];
    logic tb_pop [NUM_TARGETS];
    logic tr_push [NUM_TARGETS];
    logic tr_pop [NUM_TARGETS];

    for (genvar t = 0; t < NUM_TARGETS; t++) begin : g_response_fifos
        sync_fifo #(
            .DATA_WIDTH($bits(b_item)),
            .FIFO_DEPTH(FIFO_DEPTH)
        ) u_target_b_fifo (
            .data_in(tb_in[t]),
            .write(tb_push[t]),
            .read(tb_pop[t]),
            .clk(aclk),
            .resetn(arst_n),
            .data_out(tb_out[t]),
            .full(tb_full[t]),
            .empty(tb_empty[t])
        );

        sync_fifo #(
            .DATA_WIDTH($bits(r_item)),
            .FIFO_DEPTH(FIFO_DEPTH)
        ) u_target_r_fifo (
            .data_in(tr_in[t]),
            .write(tr_push[t]),
            .read(tr_pop[t]),
            .clk(aclk),
            .resetn(arst_n),
            .data_out(tr_out[t]),
            .full(tr_full[t]),
            .empty(tr_empty[t])
        );

        assign tb_in[t] = {t_bid[t], t_bresp[t], TARGET_WIDTH'(t)};
        assign tr_in[t] = {t_rid[t], t_rdata[t], t_rresp[t], t_rlast[t], TARGET_WIDTH'(t)};
        assign tb_push[t] = t_bvalid[t] && t_bready[t];
        assign tr_push[t] = t_rvalid[t] && t_rready[t];
        assign t_bready[t] = arst_n && !tb_full[t];
        assign t_rready[t] = arst_n && !tr_full[t];
    end

    // Master-side response arbiters and ID strippers for B and R channels
    logic [NUM_MASTERS-1:0][NUM_TARGETS-1:0] b_resp_req, b_resp_grant;
    logic [NUM_MASTERS-1:0][NUM_TARGETS-1:0] r_resp_req, r_resp_grant;
    logic [NUM_MASTERS-1:0] b_resp_gvalid, r_resp_gvalid;
    logic [NUM_MASTERS-1:0] b_resp_unlock, r_resp_unlock;
    logic [NUM_MASTERS-1:0][$clog2(NUM_TARGETS)-1:0] b_resp_gidx, r_resp_gidx;

    //logic [NUM_MASTERS-1:0][EXT_ID_WIDTH-1:0] b_mux_id, r_mux_id;
    //logic [NUM_MASTERS-1:0][MASTER_WIDTH-1:0] b_unused_m, r_unused_m;

    always_comb begin
        b_resp_req = '0;
        r_resp_req = '0;

        for (int t = 0; t < NUM_TARGETS; t++) begin
            logic [MASTER_WIDTH-1:0] bm, rm;
            bm = tb_out[t].id[EXT_ID_WIDTH-1 : ID_WIDTH];
            rm = tr_out[t].id[EXT_ID_WIDTH-1 : ID_WIDTH];

            if (!tb_empty[t] && (int'(bm) < NUM_MASTERS))
                b_resp_req[bm][t] = 1'b1;

            if (!tr_empty[t] && (int'(rm) < NUM_MASTERS))
                r_resp_req[rm][t] = 1'b1;
        end
    end

    for (genvar m = 0; m < NUM_MASTERS; m++) begin : g_response_arbiters
        rr_arbiter #(
            .NUM_REQ(NUM_TARGETS)
        ) u_b_resp_arb (
            .aclk(aclk),
            .arst_n(arst_n),
            .req(b_resp_req[m]),
            .unlock_en(b_resp_unlock[m]),
            .grant(b_resp_grant[m]),
            .grant_idx(b_resp_gidx[m]),
            .grant_valid(b_resp_gvalid[m])
        );

        rr_arbiter #(
            .NUM_REQ(NUM_TARGETS)
        ) u_r_resp_arb (
            .aclk(aclk),
            .arst_n(arst_n),
            .req(r_resp_req[m]),
            .unlock_en(r_resp_unlock[m]),
            .grant(r_resp_grant[m]),
            .grant_idx(r_resp_gidx[m]),
            .grant_valid(r_resp_gvalid[m])
        );
		/*
        axi_xbar_id_stripper #(
            .ID_WIDTH(ID_WIDTH),
            .NUM_MASTERS(NUM_MASTERS),
            .MASTER_WIDTH(MASTER_WIDTH),
            .EXT_ID_WIDTH(EXT_ID_WIDTH)
        ) u_b_strip (
            .id_in(b_mux_id[m]),
            .id_out(m_bid[m]),
            .master_id(b_unused_m[m])
        );

        axi_xbar_id_stripper #(
            .ID_WIDTH(ID_WIDTH),
            .NUM_MASTERS(NUM_MASTERS),
            .MASTER_WIDTH(MASTER_WIDTH),
            .EXT_ID_WIDTH(EXT_ID_WIDTH)
        ) u_r_strip (
            .id_in(r_mux_id[m]),
            .id_out(m_rid[m]),
            .master_id(r_unused_m[m])
        );*/
    end

    // Master-side response routing and handshaking logic
    always_comb begin
        m_bvalid = '0;
        m_bresp = '0;
		m_bid = '0;
        //b_mux_id = '0;
        b_resp_unlock = '0;
        tb_pop = '{default:0};

        m_rvalid = '0;
        m_rdata = '0;
		m_rid = '0;
        m_rresp = '0;
        m_rlast = '0;
        //r_mux_id = '0;
        r_resp_unlock = '0;
        tr_pop = '{default:0};

        for (int m = 0; m < NUM_MASTERS; m++) begin
            if (b_resp_gvalid[m]) begin
                int t;
                t = int'(b_resp_gidx[m]);

                if (!tb_empty[t]) begin
					m_bid[m] = tb_out[t].id[ID_WIDTH-1:0];
                    m_bresp[m] = tb_out[t].resp;
                    m_bvalid[m] = 1'b1;

                    if (m_bready[m]) begin
                        tb_pop[t] = 1'b1;
                        b_resp_unlock[m] = 1'b1;
                    end
                end
            end

            if (r_resp_gvalid[m]) begin
                int t;
                t = int'(r_resp_gidx[m]);

                if (!tr_empty[t]) begin
                    //r_mux_id[m] = tr_out[t].id;
					m_rid[m] = tr_out[t].id[ID_WIDTH-1:0];
                    m_rdata[m] = tr_out[t].data;
                    m_rresp[m] = tr_out[t].resp;
                    m_rlast[m] = tr_out[t].last;
                    m_rvalid[m] = 1'b1;

                    if (m_rready[m]) begin
                        tr_pop[t] = 1'b1;
                        if (tr_out[t].last)
                            r_resp_unlock[m] = 1'b1;
                    end
                end
            end
        end
    end

endmodule
