module rr_arbiter #(
    parameter int NUM_REQ = 2
)(
    input  logic aclk,
    input  logic arst_n,
    input  logic [NUM_REQ-1:0] req,
    input  logic unlock_en,

    output logic [NUM_REQ-1:0] grant,
    output logic [$clog2(NUM_REQ)-1:0] grant_idx,
    output logic grant_valid
);

    localparam int IDX_W = $clog2(NUM_REQ);

    logic [IDX_W-1:0] last_idx;
    logic locked;
    logic [NUM_REQ-1:0] locked_grant;

    always_comb begin
        grant = '0;

        if (locked) begin
            grant = locked_grant;
        end 
		else begin
            for (int i = 1; i <= NUM_REQ; i++) begin
                if (req[(int'(last_idx) + i) % NUM_REQ] && (grant == '0)) begin

                    grant[(int'(last_idx) + i) % NUM_REQ] = 1'b1;
                end
            end
        end
    end

    assign grant_valid = |grant;

    always_comb begin
        grant_idx = '0;

        for (int i = 0; i < NUM_REQ; i++) begin
            if (grant[i])
                grant_idx = IDX_W'(i);
        end
    end

    always_ff @(posedge aclk or negedge arst_n) begin
        if (!arst_n) begin
            last_idx     <= NUM_REQ - 1;
            locked       <= 1'b0;
            locked_grant <= '0;
        end 
		else begin
            if (grant_valid && unlock_en) begin
                last_idx <= grant_idx;
                locked   <= 1'b0;
            end 
			else if (grant_valid && !locked) begin
                locked       <= 1'b1;
                locked_grant <= grant;
            end
        end
    end

endmodule
