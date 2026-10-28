module axi_xbar_id_tracker #(
    parameter int ID_WIDTH  = 4,
	parameter int NUM_SLAVES = 2,
    parameter int TARGET_WIDTH = (NUM_SLAVES+1 > 1) ? $clog2(NUM_SLAVES+1) : 1,
    parameter int CNT_WIDTH = 4,
    parameter int NUM_IDS = (1 << ID_WIDTH)
) (
    input logic aclk,
    input logic arst_n,

    input logic [ID_WIDTH-1:0] aw_chk_id,
    input logic [TARGET_WIDTH-1:0] aw_chk_slv,
    output logic aw_hazard_stall,

    input logic [ID_WIDTH-1:0] ar_chk_id,
    input logic [TARGET_WIDTH-1:0] ar_chk_slv,
    output logic ar_hazard_stall,

    input logic aw_alloc_en,
    input logic [ID_WIDTH-1:0] aw_alloc_id,
    input logic [TARGET_WIDTH-1:0] aw_alloc_slv,

    input logic ar_alloc_en,
    input logic [ID_WIDTH-1:0] ar_alloc_id,
    input logic [TARGET_WIDTH-1:0] ar_alloc_slv,

    input logic b_dealloc_en,
    input logic [ID_WIDTH-1:0] b_dealloc_id,

    input logic r_dealloc_en,
    input logic [ID_WIDTH-1:0] r_dealloc_id
);

    logic active_valid [0:NUM_IDS-1];
    logic [TARGET_WIDTH-1:0] active_slv [0:NUM_IDS-1];
    logic [CNT_WIDTH-1:0] outstanding_cnt [0:NUM_IDS-1];

    localparam logic [CNT_WIDTH-1:0] MAX_COUNT = {CNT_WIDTH{1'b1}};

    always_comb begin
        aw_hazard_stall = 1'b0;
        ar_hazard_stall = 1'b0;

        if(active_valid[aw_chk_id]) begin
            if(active_slv[aw_chk_id] != aw_chk_slv || outstanding_cnt[aw_chk_id] >= MAX_COUNT-1)
                aw_hazard_stall = 1'b1;
        end

        if(active_valid[ar_chk_id]) begin
            if(active_slv[ar_chk_id] != ar_chk_slv || outstanding_cnt[ar_chk_id] >= MAX_COUNT-1)
                ar_hazard_stall = 1'b1;
        end

    end

	always_ff @(posedge aclk or negedge arst_n) begin 
		if(!arst_n) begin
			for(int i = 0; i < NUM_IDS; i++) begin
				active_valid[i]    <= 1'b0;
				active_slv[i]      <= '0;
				outstanding_cnt[i] <= '0;
			end
		end
		else begin
			for(int i = 0; i < NUM_IDS; i++) begin
				logic aw_hit, ar_hit, b_hit, r_hit;
				logic [CNT_WIDTH-1:0] next_cnt;

				aw_hit = aw_alloc_en  && (aw_alloc_id  == ID_WIDTH'(i));
				ar_hit = ar_alloc_en  && (ar_alloc_id  == ID_WIDTH'(i));
				b_hit  = b_dealloc_en && (b_dealloc_id == ID_WIDTH'(i));
				r_hit  = r_dealloc_en && (r_dealloc_id == ID_WIDTH'(i));

				next_cnt = outstanding_cnt[i] + aw_hit + ar_hit - b_hit - r_hit;

				outstanding_cnt[i] <= next_cnt;
				active_valid[i]    <= (next_cnt != '0);

				if(!active_valid[i] && (aw_hit || ar_hit))
					active_slv[i] <= aw_hit ? aw_alloc_slv : ar_alloc_slv;
			end
		end
	end
endmodule

