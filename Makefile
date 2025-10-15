cc=gcc -o1 -fopenmp -pedantic -Wall -std=c99
testfile=auto_test.fut
backend=cuda
tests := 5 7

default: make_input

test_large: make_input naive
	echo 'import "naive"' > $(testfile)
	echo 'import "human"' >> $(testfile)
	echo "-- ==" >> $(testfile)
	filenum=1 ; \
	for t in $(tests) ; do \
		./$< $$t > test$$filenum.in ; \
		cat test$$filenum.in | ./$^ 1> test$$filenum.out ; \
		echo "-- compiled input @ test$$filenum.in" ; \
		echo "-- output @ test$$filenum.out" ; \
		((filenum=filenum+1)) ; \
	done

naive: naive.fut
	futhark $(backend) $<

make_input: make_input.c
	$(cc) -o make_input make_input.c

counting:
	filenum=0 ;\
	for n in $(tests) ; do \
		echo $$n ; \
		echo $$c ; \
		((c=c+1)) ; \
	done
