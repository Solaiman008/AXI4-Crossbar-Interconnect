package axi_xbar_agent_pkg;
    `include "axi_xbar_write_transaction.sv"
    `include "axi_xbar_read_transaction.sv"
    `include "axi_xbar_master_driver.sv"
	`include "axi_xbar_slave_driver.sv"
    `include "../env/axi_xbar_coverage.sv"
    `include "axi_xbar_master_monitor.sv"
	`include "axi_xbar_slave_monitor.sv"
    `include "../seq_lib/axi_xbar_master_generator.sv"
	`include "../seq_lib/axi_xbar_slave_generator.sv"
    `include "axi_xbar_master_agent.sv"
	`include "axi_xbar_slave_agent.sv"
endpackage
