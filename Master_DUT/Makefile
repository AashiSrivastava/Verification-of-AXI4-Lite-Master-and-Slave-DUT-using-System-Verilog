####### coverage enable
ifeq ($(COV),1)
comp_args += " -coverage all -covdut axilite_m_tb_top -covfile cov.ccf"
covargs  	+= " -covoverwrite "
endif

####### gui and probing enable
ifeq ($(gui),1) 
comp_gui_args = " +access+r "
sim_gui_args = " -g -gui -input run_xcelium.tcl "
endif

all: comp sim


comp:
	@rm -rf xcelium.d
	xrun -sv -elaborate +access+rwc -top axilite_m_tb_top -f filelist.txt -licqueue +dut+axilite_m +top+axilite_m_tb_top  +timescale+1ns/1ps -l xrun.log $(comp_args);

sim:
	echo "Xcelium: running test"; \
	xrun -sv -licqueue -R -xmlibdirpath /projects/G030/users/asrivastava/axilite_master -process_save -status -status3 -AAFAST -l run.log $(sim_gui_args) $(covargs); \
	perl parse_log.pl "\\[TIMEOUT_MSG\\]\\s\\+1" "DATA MISMATCHED" "Simulation complete" run.log "DEC ERROR" "fatal"|| (echo "parse.pl failed $$?"; exit 1); \
	cd $(PWD);


