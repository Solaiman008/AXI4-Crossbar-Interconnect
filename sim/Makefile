FLIST := flist.f
TOP   := tb_top
TEST ?= axi_xbar_reset_test

TEST_DIR := ../tb/test_lib
TESTS := $(filter-out axi_xbar_base_test axi_xbar_test_pkg,$(patsubst %.sv,%,$(notdir $(wildcard $(TEST_DIR)/*.sv))))

REGRESSION_COUNT ?= 1

# xsim creates xsim.covdb and xsim.codeCov inside COV_DIR
COV_DIR      := ./coverage_runs
FUNC_COV_DIR := ./xsim.covdb
CODE_COV_DIR := ./xsim.codeCov

LOG_DIR := ./logs

# Text reports go here (set both to . to write into the working directory)
FUNC_REPORT_DIR := ./functional_coverage_report
CODE_REPORT_DIR := ./code_coverage_report

SIMULATOR := $(TOP)_sim

.PHONY: compile elaborate simulate all regression \
        functional_report code_report coverage_report \
        gui clean

all: simulate

# --------------------------------------------------
# Compile
# --------------------------------------------------
compile:
	@echo "========================================"
	@echo " Compiling AXI4 CROSSBAR design and testbench"
	@echo "========================================"
	@xvlog -sv -f $(FLIST)

# --------------------------------------------------
# Elaborate with code coverage instrumentation
# s=statement b=branch c=condition t=toggle
# --------------------------------------------------
elaborate: compile
	@echo "========================================"
	@echo " Elaborating design"
	@echo "========================================"
	@xelab $(TOP) -s $(SIMULATOR) \
	    -debug typical \
	    -cc_type sbc #t

# --------------------------------------------------
# Run one test (functional + code coverage)
# --------------------------------------------------
simulate: elaborate
	@echo "========================================"
	@echo " Running test: $(TEST)"
	@echo "========================================"
	@mkdir -p $(COV_DIR) $(LOG_DIR)
	@xsim $(SIMULATOR) \
	    -testplusarg TEST=$(TEST) \
	    -cov_db_name $(TEST)_run \
	    -log $(LOG_DIR)/$(TEST)_run.log \
	    -runall

# --------------------------------------------------
# Run all discovered tests
# --------------------------------------------------
regression: elaborate
	@echo "========================================"
	@echo "          AXI4 CROSSBAR REGRESSION"
	@echo "========================================"
	@echo "Tests discovered: $(TESTS)"
	@echo "Regression iterations per test: $(REGRESSION_COUNT)"
	@echo "========================================"
	@mkdir -p $(COV_DIR) $(LOG_DIR)
	@set +e; \
	failures=0; \
	passes=0; \
	for test in $(TESTS); do \
	    iter=1; \
	    while [ $$iter -le $(REGRESSION_COUNT) ]; do \
	        echo ""; \
	        echo "----------------------------------------"; \
	        echo "Running test: $$test (iteration $$iter)"; \
	        echo "----------------------------------------"; \
	        logf=$(LOG_DIR)/$${test}_run$$iter.log; \
			seed=$$(( $$(date +%s) + $$iter )); \
	        xsim $(SIMULATOR) \
	            -testplusarg TEST=$$test \
				--sv_seed $$seed \
	            -cov_db_name $${test}_run$$iter \
	            -log $$logf \
	            -runall; \
	        status=$$?; \
	        if [ $$status -ne 0 ] || grep -Eq "^(UVM_ERROR|UVM_FATAL)[[:space:]]*:[[:space:]]*[1-9]" $$logf; then \
	            echo "SIMULATION FAILED: $$test (iteration $$iter)"; \
	            failures=$$((failures + 1)); \
	        else \
	            echo "SIMULATION PASSED: $$test (iteration $$iter)"; \
	            passes=$$((passes + 1)); \
	        fi; \
	        iter=$$((iter + 1)); \
	    done; \
	done; \
	echo ""; \
	echo "========================================"; \
	echo "       REGRESSION SUMMARY"; \
	echo "========================================"; \
	echo "Completed runs : $$passes"; \
	echo "Failed runs : $$failures"; \
	echo "========================================"; \
	if [ $$failures -ne 0 ]; then \
	    exit 1; \
	fi

# --------------------------------------------------
# Functional coverage report (text)
# --------------------------------------------------
functional_report:
	@echo "========================================"
	@echo " Generating functional coverage report"
	@echo "========================================"
	@mkdir -p $(FUNC_REPORT_DIR)
	@xcrg \
	    -dir $(FUNC_COV_DIR) \
	    -report_format text \
	    -report_dir $(FUNC_REPORT_DIR) \
	    -log functional_coverage.log

# --------------------------------------------------
# Code coverage report (text), one per database
# --------------------------------------------------
code_report:
	@echo "========================================"
	@echo " Generating code coverage report"
	@echo "========================================"
	@mkdir -p $(CODE_REPORT_DIR)
	@for db in $(notdir $(wildcard $(CODE_COV_DIR)/*)); do \
	    echo "  db: $$db"; \
	    xcrg \
	        -cc_dir $(CODE_COV_DIR) \
	        -cc_db $$db \
	        -report_format html \
	        -report_dir $(CODE_REPORT_DIR)/$$db \
	        -log code_coverage_$$db.log; \
	done

coverage_report: functional_report code_report

wave:
	gtkwave dump.vcd &

gui: elaborate
	@echo "========================================"
	@echo " Starting Vivado simulation GUI"
	@echo "========================================"
	@xsim $(SIMULATOR) --gui

# --------------------------------------------------
# Clean generated files
# --------------------------------------------------
clean:
	@echo "Cleaning simulation and coverage files..."
	@rm -rf xsim.dir .Xil
	@rm -rf $(COV_DIR)
	@rm -rf $(FUNC_REPORT_DIR) $(CODE_REPORT_DIR)
	@rm -rf xsim.covdb xsim.codeCov
	@rm -rf logs
	@rm -f *.jou *.log *.pb *.wdb *.vcd
	@echo "Clean complete."

