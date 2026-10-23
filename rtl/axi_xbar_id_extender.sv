module axi_xbar_id_extender #(
    parameter int ID_WIDTH  = 4,
    parameter int NUM_MASTERS = 2,
    parameter int MASTER_WIDTH = (NUM_MASTERS > 1) ? $clog2(NUM_MASTERS) : 1,
    parameter int EXT_ID_WIDTH = ID_WIDTH + MASTER_WIDTH
) (
    input logic [ID_WIDTH-1:0] id_in,
    input logic [MASTER_WIDTH-1:0] master_id,
    output logic [EXT_ID_WIDTH-1:0] id_out
);

    assign id_out = {master_id, id_in};

endmodule
