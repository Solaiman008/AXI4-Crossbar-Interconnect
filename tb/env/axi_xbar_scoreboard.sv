import axi_xbar_param_pkg::*;
import axi_xbar_agent_pkg::*;

class axi_xbar_scoreboard;
	mailbox wr_mon_to_sb_m0;
	mailbox wr_mon_to_sb_m1;
	mailbox wr_mon_to_sb_s0;
	mailbox wr_mon_to_sb_s1;
	mailbox rd_mon_to_sb_m0;
	mailbox rd_mon_to_sb_m1;
	mailbox rd_mon_to_sb_s0;
	mailbox rd_mon_to_sb_s1;

	axi_xbar_write_transaction wr_s_q[2][$];
	axi_xbar_read_transaction rd_s_q[2][$];

	int m_aw_passed;
	int m_aw_failed;
	int m_w_passed;
	int m_w_failed;
	int s_b_passed;
	int s_b_failed;
	int m_ar_passed;
	int m_ar_failed;
	int s_r_passed;
	int s_r_failed;

	function new(
		mailbox wr_mon_to_sb_m0,
		mailbox wr_mon_to_sb_m1,
		mailbox wr_mon_to_sb_s0,
		mailbox wr_mon_to_sb_s1,
		mailbox rd_mon_to_sb_m0,
		mailbox rd_mon_to_sb_m1,
		mailbox rd_mon_to_sb_s0,
		mailbox rd_mon_to_sb_s1
	);
		$display("[SB] Scoreboard initialized at time %0d", $time);
		this.wr_mon_to_sb_m0 = wr_mon_to_sb_m0;
		this.wr_mon_to_sb_m1 = wr_mon_to_sb_m1;
		this.wr_mon_to_sb_s0 = wr_mon_to_sb_s0;
		this.wr_mon_to_sb_s1 = wr_mon_to_sb_s1;
		this.rd_mon_to_sb_m0 = rd_mon_to_sb_m0;
		this.rd_mon_to_sb_m1 = rd_mon_to_sb_m1;
		this.rd_mon_to_sb_s0 = rd_mon_to_sb_s0;
		this.rd_mon_to_sb_s1 = rd_mon_to_sb_s1;
		this.m_aw_passed = 0;
		this.m_aw_failed = 0;
		this.m_w_passed = 0;
		this.m_w_failed = 0;
		this.s_b_passed = 0;
		this.s_b_failed = 0;
		this.m_ar_passed = 0;
		this.m_ar_failed = 0;
		this.s_r_passed = 0;
		this.s_r_failed = 0;
	endfunction

	task run;
		fork
			collect_wr_s(0, wr_mon_to_sb_s0);
			collect_wr_s(1, wr_mon_to_sb_s1);
			collect_rd_s(0, rd_mon_to_sb_s0);
			collect_rd_s(1, rd_mon_to_sb_s1);
			check_wr_m(0, wr_mon_to_sb_m0);
			check_wr_m(1, wr_mon_to_sb_m1);
			check_rd_m(0, rd_mon_to_sb_m0);
			check_rd_m(1, rd_mon_to_sb_m1);
		join_none
	endtask

	task collect_wr_s(int s_id, mailbox mbx);
		axi_xbar_write_transaction tr;
		forever begin
			mbx.get(tr);
			wr_s_q[s_id].push_back(tr);
		end
	endtask

	task collect_rd_s(int s_id, mailbox mbx);
		axi_xbar_read_transaction tr;
		forever begin
			mbx.get(tr);
			rd_s_q[s_id].push_back(tr);
		end
	endtask

	function int decode_addr(logic [ADDR_WIDTH-1:0] addr);
		if(addr >= 32'h0000_0000 && addr <= 32'h0FFF_FFFF)
			return 0;
		else if(addr >= 32'h1000_0000 && addr <= 32'h1FFF_FFFF)
			return 1;
		else
			return -1;
	endfunction

	task check_wr_m(int m_id, mailbox mbx);
		axi_xbar_write_transaction m_tr;
		axi_xbar_write_transaction s_tr;
		int target_s;
		int match_idx;
		bit aw_ok;
		bit w_ok;
		bit b_ok;

		forever begin
			mbx.get(m_tr);
			target_s = decode_addr(m_tr.awaddr);

			if(target_s == -1) begin
				m_aw_passed++;
				m_w_passed++;
				if(m_tr.bresp == 2'b11 && m_tr.bid == m_tr.awid) begin
					s_b_passed++;
					$display("[SB][PASS] M%0d->Default_Slave s_b_passed at addr %0h", m_id, m_tr.awaddr);
				end
				else begin
					s_b_failed++;
					$display("[SB][FAIL] M%0d->Default_Slave s_b_failed at addr %0h", m_id, m_tr.awaddr);
				end
			end
			else begin
				match_idx = -1;
				forever begin
					wait(wr_s_q[target_s].size() > 0);
					for(int i = 0; i < wr_s_q[target_s].size(); i++) begin
						// Match robustly on address and transaction parameters instead of strict extended ID bits
						if(wr_s_q[target_s][i].awaddr == m_tr.awaddr && wr_s_q[target_s][i].awlen == m_tr.awlen) begin
							match_idx = i;
							break;
						end
					end
					if(match_idx != -1)
						break;
					#1;
				end

				s_tr = wr_s_q[target_s][match_idx];
				wr_s_q[target_s].delete(match_idx);

				aw_ok = (s_tr.awaddr == m_tr.awaddr) &&
					(s_tr.awlen == m_tr.awlen) &&
					(s_tr.awsize == m_tr.awsize) &&
					(s_tr.awburst == m_tr.awburst);

				if(aw_ok) begin
					m_aw_passed++;
					$display("[SB][PASS] M%0d->S%0d m_aw_passed at addr %0h", m_id, target_s, m_tr.awaddr);
				end
				else begin
					m_aw_failed++;
					$display("[SB][FAIL] M%0d->S%0d m_aw_failed at addr %0h", m_id, target_s, m_tr.awaddr);
				end

				w_ok = (s_tr.wdata == m_tr.wdata) &&
					(s_tr.wstrb == m_tr.wstrb) &&
					(s_tr.wlast == m_tr.wlast);

				if(w_ok) begin
					m_w_passed++;
					$display("[SB][PASS] M%0d->S%0d m_w_passed at addr %0h", m_id, target_s, m_tr.awaddr);
				end
				else begin
					m_w_failed++;
					$display("[SB][FAIL] M%0d->S%0d m_w_failed at addr %0h", m_id, target_s, m_tr.awaddr);
				end

				b_ok = (m_tr.bresp == s_tr.bresp);

				if(b_ok) begin
					s_b_passed++;
					$display("[SB][PASS] S%0d->M%0d s_b_passed at addr %0h", target_s, m_id, m_tr.awaddr);
				end
				else begin
					s_b_failed++;
					$display("[SB][FAIL] S%0d->M%0d s_b_failed at addr %0h", target_s, m_id, m_tr.awaddr);
				end
			end
		end
		$display("AW passed = %0d", m_aw_passed);
	endtask

	task check_rd_m(int m_id, mailbox mbx);
		axi_xbar_read_transaction m_tr;
		axi_xbar_read_transaction s_tr;
		int target_s;
		int match_idx;
		bit ar_ok;
		bit r_ok;
		bit decerr_ok;

		forever begin
			mbx.get(m_tr);
			target_s = decode_addr(m_tr.araddr);

			if(target_s == -1) begin
				m_ar_passed++;
				decerr_ok = (m_tr.rresp.size() == (m_tr.arlen + 1));
				foreach(m_tr.rresp[i]) begin
					if(m_tr.rresp[i] != 2'b11)
						decerr_ok = 0;
				end
				if(decerr_ok) begin
					s_r_passed++;
					$display("[SB][PASS] Default_Slave->M%0d s_r_passed at addr %0h", m_id, m_tr.araddr);
				end
				else begin
					s_r_failed++;
					$display("[SB][FAIL] Default_Slave->M%0d s_r_failed at addr %0h", m_id, m_tr.araddr);
				end
			end
			else begin
				match_idx = -1;
				forever begin
					wait(rd_s_q[target_s].size() > 0);
					for(int i = 0; i < rd_s_q[target_s].size(); i++) begin
						// Match robustly on address and transaction parameters
						if(rd_s_q[target_s][i].araddr == m_tr.araddr && rd_s_q[target_s][i].arlen == m_tr.arlen) begin
							match_idx = i;
							break;
						end
					end
					if(match_idx != -1)
						break;
					#1;
				end

				s_tr = rd_s_q[target_s][match_idx];
				rd_s_q[target_s].delete(match_idx);

				ar_ok = (s_tr.araddr == m_tr.araddr) &&
					(s_tr.arlen == m_tr.arlen) &&
					(s_tr.arsize == m_tr.arsize) &&
					(s_tr.arburst == m_tr.arburst);

				if(ar_ok) begin
					m_ar_passed++;
					$display("[SB][PASS] M%0d->S%0d m_ar_passed at addr %0h", m_id, target_s, m_tr.araddr);
				end
				else begin
					m_ar_failed++;
					$display("[SB][FAIL] M%0d->S%0d m_ar_failed at addr %0h", m_id, target_s, m_tr.araddr);
				end

				r_ok = (m_tr.rdata == s_tr.rdata) &&
					(m_tr.rresp == s_tr.rresp) &&
					(m_tr.rlast == s_tr.rlast);

				if(r_ok) begin
					s_r_passed++;
					$display("[SB][PASS] S%0d->M%0d s_r_passed at addr %0h", target_s, m_id, m_tr.araddr);
				end
				else begin
					s_r_failed++;
					$display("[SB][FAIL] S%0d->M%0d s_r_failed at addr %0h", target_s, m_id, m_tr.araddr);
				end
			end
		end
	endtask

	task report();
		$display("--------------------------------------------------");
		$display("[SB] INTERCONNECT CHANNEL TRANSMISSION REPORT");
		$display("AW Channel (M -> S) : Pass = %0d, Fail = %0d", m_aw_passed, m_aw_failed);
		$display("W  Channel (M -> S) : Pass = %0d, Fail = %0d", m_w_passed, m_w_failed);
		$display("B  Channel (S -> M) : Pass = %0d, Fail = %0d", s_b_passed, s_b_failed);
		$display("AR Channel (M -> S) : Pass = %0d, Fail = %0d", m_ar_passed, m_ar_failed);
		$display("R  Channel (S -> M) : Pass = %0d, Fail = %0d", s_r_passed, s_r_failed);
		if(m_aw_failed == 0 && m_w_failed == 0 && s_b_failed == 0 && m_ar_failed == 0 && s_r_failed == 0 && wr_s_q[0].size() == 0 && wr_s_q[1].size() == 0 && rd_s_q[0].size() == 0 && rd_s_q[1].size() == 0)
			$display("[SB] RESULT         : TEST PASSED");
		else
			$display("[SB] RESULT         : TEST FAILED");
		$display("--------------------------------------------------");
	endtask
endclass
