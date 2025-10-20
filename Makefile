cc=gcc -o1 -fopenmp -pedantic -Wall -std=c99
testfile=auto_test.fut
backend=cuda
tests := 10000 100000 1000000

default: test

bench: make_test
	futhark bench --backend=$(backend) $(testfile)

test: make_test
	futhark test --backend=$(backend) $(testfile)

make_test: make_input naive
	echo 'import "naive"' > $(testfile)
	echo 'import "human"' >> $(testfile)
	echo 'import "compiler"' >> $(testfile)
	echo "-- ==" >> $(testfile)
	echo "-- entry: naive human compiler" >> $(testfile)
	filenum=1 ; \
	for t in $(tests) ; do \
		./$< $$t > test$$filenum.in ; \
		cat test$$filenum.in | ./naive 2> /dev/null 1> test$$filenum.out ; \
		echo "-- compiled input @ test$$filenum.in" >> $(testfile) ; \
		echo "-- output @ test$$filenum.out" >> $(testfile) ; \
		echo "--" >> $(testfile) ; \
		((filenum=filenum+1)) ; \
	done
	echo "entry naive = naive.rankSearchBatch" >> $(testfile)
	echo "entry human = human.rankSearchBatch" >> $(testfile)
	echo "entry compiler = compiler.rankSearchBatch" >> $(testfile)

naive: naive.fut
	futhark $(backend) $<

make_input: make_input.c
	$(cc) -o make_input make_input.c

clean:
	rm test*.in test*.out auto_test.c naive.c human.c naive make_input auto_test
