cc=gcc -o1 -fopenmp

default: make_input

make_input: make_input.c
	$(cc) -o make_input make_input.c
