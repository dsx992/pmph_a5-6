cc=gcc -o1 -fopenmp -pedantic -Wall -std=c99
testfile=auto_test.fut
backend=cuda
tests := 10000000
default: test

bench: make_test
	futhark bench --backend=$(backend) $(testfile)

test: make_test
	futhark test --backend=$(backend) $(testfile)

bench_compiler: make_compiler
	futhark bench --backend=$(backend) $(testfile)

make_compiler_atta: input make_input_regular
test_flex_f32: make_flex_f32
	futhark test --backend=$(backend) $(testfile)

make_flex_f32: input make_input naive
	echo 'import "flex_f32"' > $(testfile)
	echo "-- ==" >> $(testfile)
	echo "-- entry:  human_flex" >> $(testfile)
	filenum=1 ; \
	for t in $(tests) ; do \
		./make_input --regular $$t 100000 | ./format_input > test$$filenum.in ; \
		cat test$$filenum.in | ./naive 2> /dev/null 1> test$$filenum.out ; \
		echo "-- compiled input @ test$$filenum.in" >> $(testfile) ; \
		echo "-- output @ test$$filenum.out" >> $(testfile) ; \
		echo "--" >> $(testfile) ; \
		((filenum=filenum+1)) ; \
	done 
	echo "entry human_flex = flex_f32.run " >> $(testfile)

make_compiler_master: input make_input_compiler
	echo 'import "human"' > $(testfile)
	echo 'import "human_regular"' >> $(testfile)
	echo 'import "compiler"' >> $(testfile)
	echo "-- ==" >> $(testfile)
	echo "-- entry:  human human_regular" >> $(testfile)
	filenum=1 ; \
	for t in $(tests) ; do \
		./make_input_regular $$t 100000 2>/dev/null > test$$filenum.in ; \
		echo "-- compiled input @ test$$filenum.in" >> $(testfile) ; \
		echo "--" >> $(testfile) ; \
		((filenum=filenum+1)) ; \
	done 
	echo "entry human = human.rankSearchBatch " >> $(testfile)
	echo "entry human_regular = human_regular.rankSearchBatch" >> $(testfile)

make_compiler_validate_atta: input make_input_compiler naive naive_compiler
	echo 'import "human"' > $(testfile)
	echo 'import "human_regular"' >> $(testfile)
	echo 'import "compiler"' >> $(testfile)
	echo 'import "naive"' >> $(testfile)
	echo "-- ==" >> $(testfile)
	echo "-- entry:  human human_regular" >> $(testfile)
	filenum=1 ; \
	for t in $(tests) ; do \
		./make_input --regular $$t 100 | ./format_input > test$$filenum.in ; \
		cat test$$filenum.in | ./naive 2> /dev/null 1> test$$filenum.out ; \
		echo "-- compiled input @ test$$filenum.in" >> $(testfile) ; \
		echo "-- output @ test$$filenum.out" >> $(testfile) ; \
		echo "--" >> $(testfile) ; \
		((filenum=filenum+1)) ; \
	done
	echo "entry human = human.rankSearchBatch  " >> $(testfile)
	echo "entry human_regular = human_regular.rankSearchBatch  " >> $(testfile)
make_compiler_validate_master: make_input make_input_compiler naive naive_compiler
	echo 'import "compiler"' > $(testfile)

	echo "-- ==" >> $(testfile)
	echo "-- entry: compiler " >> $(testfile)
	filenum=1 ; \
	for t in $(tests) ; do \
		./make_input_compiler $$t > testCompiler$$filenum.in ; \
		cat testCompiler$$filenum.in | ./naiveCompiler 2> /dev/null 1> testCompiler$$filenum.out ; \
		echo "-- compiled input @ testCompiler$$filenum.in" >> $(testfile) ; \
		echo "-- output @ testCompiler$$filenum.out" >> $(testfile) ; \
		echo "--" >> $(testfile) ; \
		((filenum=filenum+1)) ; \
	done
	echo "entry compiler = compiler.rankSearchBatch" >> $(testfile)

make_test: make_input naive
	echo 'import "human"' > $(testfile)
	echo "-- ==" >> $(testfile)
	echo "-- entry:  human " >> $(testfile)
	./$< 100000 > inp.in
	filenum=1 ; \
	for t in $(tests) ; do \
		echo "-- compiled input {" >> $(testfile) ; \
		echo -n "--" >> $(testfile) ; \
		cat inp.in >> $(testfile) ; \
		echo -n "-- " >> $(testfile) ; \
		echo $${t}i64 >> $(testfile) ; \
		echo "-- }" >> $(testfile) ; \
		echo "--" >> $(testfile) ; \
	done
	echo "entry human = human.rankSearchBatch" >> $(testfile)

naive: naive.fut
	futhark ${backend} $<

naive_compiler: naiveCompiler.fut
	futhark ${backend} $<

make_input: make_input.c
	$(cc) -o make_input make_input.c

input: format_input make_input

format_input: format_input.c
	$(cc) -o format_input format_input.c

make_input_compiler: make_input_compiler.c
	$(cc) -o make_input_compiler make_input_compiler.c

make_input_regular: make_input_regular.c
	$(cc) -o make_input_regular make_input_regular.c

clean:
	rm -f test*.in test*.out auto_test.c naive.c human.c naive make_input auto_test test test.c make_input_compiler
	rm -f *.actual *.expected
	rm -f auto_test.fut
	rm -f naiveCompiler
	rm -f naiveCompiler.c
	rm -f result.prof*
	rm -f format_input
	rm -f result.json
	