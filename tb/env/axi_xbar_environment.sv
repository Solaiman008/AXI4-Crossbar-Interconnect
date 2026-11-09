`include "axi_xbar_scoreboard.sv"
import axi_xbar_agent_pkg::*;

class axi_xbar_environment;
    axi_xbar_master_agent agt_m0, agt_m1;
	axi_xbar_slave_agent agt_s0, agt_s1;
    axi_xbar_scoreboard sb; 
    axi_xbar_coverage cov;

    mailbox wr_mon_to_sb_m0, wr_mon_to_sb_m1, wr_mon_to_sb_s0, wr_mon_to_sb_s1;
    mailbox rd_mon_to_sb_m0, rd_mon_to_sb_m1, rd_mon_to_sb_s0, rd_mon_to_sb_s1;
    function new(
		virtual axi_xbar_if #(ID_WIDTH) vif_m0, 
		virtual axi_xbar_if #(ID_WIDTH) vif_m1, 
		virtual axi_xbar_if #(EXT_ID_WIDTH) vif_s0, 
		virtual axi_xbar_if #(EXT_ID_WIDTH) vif_s1
	);
        $display("Environment initialized at time %0d", $time);
        
		wr_mon_to_sb_m0 = new();
        wr_mon_to_sb_m1 = new();
        wr_mon_to_sb_s0 = new();
        wr_mon_to_sb_s1 = new();

        rd_mon_to_sb_m0 = new();
        rd_mon_to_sb_m1 = new();
        rd_mon_to_sb_s0 = new();
        rd_mon_to_sb_s1 = new();

        cov = new();
        agt_m0 = new(vif_m0, wr_mon_to_sb_m0, rd_mon_to_sb_m0, cov, 0);
        agt_m1 = new(vif_m1, wr_mon_to_sb_m1, rd_mon_to_sb_m1, cov, 1);
        agt_s0 = new(vif_s0, wr_mon_to_sb_s0, rd_mon_to_sb_s0, cov, 0);
        agt_s1 = new(vif_s1, wr_mon_to_sb_s1, rd_mon_to_sb_s1, cov, 1);
        //sb = new(mon_to_sb);
		sb = new(
			wr_mon_to_sb_m0, wr_mon_to_sb_m1, wr_mon_to_sb_s0, wr_mon_to_sb_s1,
			rd_mon_to_sb_m0, rd_mon_to_sb_m1, rd_mon_to_sb_s0, rd_mon_to_sb_s1
			);
		//sb = new();
    endfunction

    task run;
        fork
            $display("environment started");
            agt_m0.run();
            agt_m1.run();
            agt_s0.run();
            agt_s1.run();
            sb.run();
        join_none
    endtask
endclass

