default: compile execute display


compile: $(wildcard *.v) $(wildcard *.sv) $(wildcard ./src/*.v)
	iverilog $^

execute: $(wildcard *.out)
	vvp $<

display: $(wildcard *.vcd)
	gtkwave $<

clean: $(wildcard *.out) $(wildcard *.vcd)
	rm $^