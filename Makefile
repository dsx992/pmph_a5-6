cc=gcc -o1 -fopenmp -pedantic -Wall -std=c99
testfile=auto_test.fut
backend=cuda
tests := 1000 1234 

default: test

bench: make_test
	futhark bench --backend=$(backend) $(testfile)

test: make_test
	futhark test --backend=$(backend) $(testfile)

make_test: input naive
	echo 'import "human"' >> $(testfile)
	echo "-- ==" >> $(testfile)
	echo "-- entry: human" >> $(testfile)
	filenum=1 ; \
	for t in $(tests) ; do \
		./$make_input $$t | ./format_input > test$$filenum.in ; \
		cat test$$filenum.in | ./naive 2> /dev/null 1> test$$filenum.out ; \
		echo "-- compiled input @ test$$filenum.in" >> $(testfile) ; \
		echo "-- output @ test$$filenum.out" >> $(testfile) ; \
		echo "--" >> $(testfile) ; \
		((filenum=filenum+1)) ; \
	done
	echo "entry human = human.rankSearchBatch" >> $(testfile)

naive: naive.fut
	futhark $(backend) $<

input: format_input make_input

format_input: format_input.c
	$(cc) -o format_input format_input.c

make_input: make_input.c
	$(cc) -o make_input make_input.c

clean:
	rm -f test*.in test*.out auto_test.c naive.c human.c naive make_input auto_test
	rm -f *.actual *.expected
