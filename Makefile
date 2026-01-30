default: compile execute display


compile: $(wildcard *.v) $(wildcard ./src/*.v) $(wildcard ./src/*.sv)
	iverilog $^

execute: $(wildcard *.out)
	vvp $<

display: $(wildcard *.vcd)
	gtkwave $<

clean: $(wildcard *.out) $(wildcard *.vcd)
	rm $^