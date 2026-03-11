default: compile execute display


compile: $(wildcard *.v) $(wildcard *.sv) $(wildcard ./src/*.v) $(wildcard ./src/tb_model/*.sv)
	iverilog $^ -D TEST_BENCH_DEBUG

execute: 
	vvp a.out

display:
	gtkwave dump.vcd

clean: $(wildcard *.out) $(wildcard *.vcd)
	rm $^