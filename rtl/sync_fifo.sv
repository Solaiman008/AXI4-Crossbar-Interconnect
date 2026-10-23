module sync_fifo #(
	parameter int DATA_WIDTH = 8,
	parameter int FIFO_DEPTH = 8
)(
	input logic [DATA_WIDTH-1:0] data_in,
	input logic write,
	input logic read,
	input logic clk,
	input logic resetn,

	output logic [DATA_WIDTH-1:0] data_out,
	output logic full,
	output logic empty
);
	
	localparam int ADDR_SIZE = $clog2(FIFO_DEPTH);
	logic [ADDR_SIZE-1:0] read_addr, write_addr;
	logic [ADDR_SIZE:0] read_ptr, write_ptr;
	logic [DATA_WIDTH-1:0] reg_file[2**ADDR_SIZE-1:0];
	logic write_en;
	logic read_en;

	always_comb begin
		write_addr = write_ptr[ADDR_SIZE-1:0];
		read_addr = read_ptr[ADDR_SIZE-1:0];

		if((write_ptr[ADDR_SIZE] != read_ptr[ADDR_SIZE]) && (write_addr == read_addr))
			full = 1;
		else
			full = 0;

		if(write_ptr == read_ptr)
            empty = 1;
        else
 			empty = 0;

		write_en = ~full & write;
		read_en = ~empty & read;

		data_out = reg_file[read_addr];
	end

	always_ff @(posedge clk) begin
		if(!resetn) 
			write_ptr <= 0;
		else if(write_en)
			write_ptr <= write_ptr + 1;
	end

	always_ff @(posedge clk) begin
    	if(!resetn) 
             read_ptr <= 0;
        else if(read_en)
             read_ptr <= read_ptr +1;
 	end
	
	always_ff @(posedge clk) begin
		if(write_en)
			reg_file[write_addr] <= data_in;
	end

endmodule
