module axi_xbar_default_slave #(
    parameter int ID_WIDTH   = 4,
    parameter int DATA_WIDTH = 64
)(
	input logic aclk,
	input logic arst_n,

	input logic [ID_WIDTH-1:0] awid,
	input logic awvalid,
	output logic awready,

	input logic wlast,
	input logic wvalid,
	output logic wready,

	output logic [ID_WIDTH-1:0] bid,
	output logic [1:0] bresp,
	output logic bvalid,
	input logic bready,

	input logic [ID_WIDTH-1:0] arid,
	input logic [7:0] arlen,
	input logic arvalid,
	output logic arready,

	output logic [ID_WIDTH-1:0] rid,
	output logic [DATA_WIDTH-1:0] rdata,
	output logic [1:0] rresp,
	output logic rlast,
	output logic rvalid,
	input logic rready
);

    typedef enum logic [1:0] {W_IDLE, W_SINK, W_RESP} w_states;
    w_states w_state;
    logic [ID_WIDTH-1:0] wid_reg;

    assign awready = (w_state == W_IDLE);
    assign wready = (w_state == W_SINK);
    assign bvalid = (w_state == W_RESP);
    assign bid = wid_reg;
    assign bresp = 2'b11;

    always_ff @(posedge aclk or negedge arst_n) begin
        if (!arst_n) begin
            w_state <= W_IDLE;
            wid_reg <= '0;
        end 
		else begin
            case (w_state)
                W_IDLE: if (awvalid && awready) begin
                    		wid_reg <= awid;
                    		w_state <= W_SINK;
                		end
                W_SINK: if (wvalid && wready && wlast) begin
                    		w_state <= W_RESP;
                		end
                W_RESP: if (bvalid && bready) begin
                    		w_state <= W_IDLE;
                		end
                default: w_state <= W_IDLE;
            endcase
        end
    end

    typedef enum logic {R_IDLE, R_BURST} r_states;
    r_states r_state;
    logic [ID_WIDTH-1:0] rid_reg;
    logic [7:0] rlen_cnt;

    assign arready = (r_state == R_IDLE);
    assign rvalid = (r_state == R_BURST);
    assign rid = rid_reg;
    assign rdata = '0;
    assign rresp = 2'b11;
    assign rlast = (r_state == R_BURST) && (rlen_cnt == 8'b0);

    always_ff @(posedge aclk or negedge arst_n) begin
        if (!arst_n) begin
            r_state  <= R_IDLE;
            rid_reg  <= '0;
            rlen_cnt <= '0;
        end 
		else begin
            case (r_state)
                R_IDLE: if (arvalid && arready) begin
                    		rid_reg  <= arid;
                    		rlen_cnt <= arlen;
                    		r_state  <= R_BURST;
                		end
                R_BURST: if (rvalid && rready) begin
                    	 	if (rlen_cnt == 8'd0) 
								r_state <= R_IDLE;
                    		else                  
								rlen_cnt <= rlen_cnt - 8'b1;
                		end
				default: r_state <= R_IDLE;
            endcase
        end
    end
endmodule
