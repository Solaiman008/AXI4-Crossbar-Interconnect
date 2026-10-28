parameter int TARGET_WIDTH = 2;
parameter int ADDR_WIDTH = 32;

function automatic logic [TARGET_WIDTH-1:0] decode_addr(input logic [ADDR_WIDTH-1:0] addr);   
	if (addr[31:28] == 4'h0)
		decode_addr = TARGET_WIDTH'(0);
	else if (addr[31:28] == 4'h1)
		decode_addr = TARGET_WIDTH'(1);
	else
		decode_addr = TARGET_WIDTH'(2);
endfunction

