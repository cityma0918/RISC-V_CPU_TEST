PYTHON ?= python

.PHONY: smoke hazard dual neg extended all

smoke:
	$(PYTHON) tools/run_test_local.py --test tests/smoke_basic.S

hazard:
	$(PYTHON) tools/run_test_local.py --test tests/hazard_data.S
	$(PYTHON) tools/run_test_local.py --test tests/hazard_control.S

dual:
	$(PYTHON) tools/run_test_local.py --test tests/dual_issue_load_alu.S --dual --min-lane1-commits 1
	$(PYTHON) tools/run_test_local.py --test tests/dual_issue_mixed.S --dual --min-lane1-commits 1

neg:
	$(PYTHON) tools/run_test_local.py --test tests/dual_issue_seq.S --dual
	$(PYTHON) tools/run_test_local.py --test tests/alu_then_ls_block.S --dual

extended:
	$(PYTHON) tools/run_test_local.py --test tests/subset37_full_long.S
	$(PYTHON) tools/run_test_local.py --test tests/hazard_stress_long.S
	$(PYTHON) tools/run_test_local.py --test tests/dual_issue_stress_long.S --dual --min-lane1-commits 6

all: smoke hazard dual neg extended
