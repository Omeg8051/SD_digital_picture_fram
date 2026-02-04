default: compile execute display


compile: $(wildcard *.v) $(wildcard *.sv) $(wildcard ./src/*.v)
	iverilog $^

execute: 
	vvp a.out

display:
	gtkwave dump.vcd

clean: $(wildcard *.out) $(wildcard *.vcd)
	rm $^