module axi_xbar_id_stripper #(
    parameter int ID_WIDTH = 4,
    parameter int NUM_MASTERS = 2,
    parameter int MASTER_WIDTH = (NUM_MASTERS > 1) ? $clog2(NUM_MASTERS) : 1,
    parameter int EXT_ID_WIDTH = ID_WIDTH + MASTER_WIDTH
) (
    input logic [EXT_ID_WIDTH-1:0] id_in,
    output logic [ID_WIDTH-1:0] id_out,
    output logic [MASTER_WIDTH-1:0] master_id
);

    assign id_out = id_in[ID_WIDTH-1:0];
    assign master_id = id_in[EXT_ID_WIDTH-1:ID_WIDTH];

endmodule
