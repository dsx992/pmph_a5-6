# -----------------------------
# Compiler and configuration
# -----------------------------
CC = gcc -o1 -fopenmp -pedantic -Wall -std=c99
BACKEND = cuda
TESTFILE = auto_test.fut
TESTS = 100
SEGMENT_SIZE = 10
JSONFILE = jsonout

default: clean_autotest all_autotest write_default_input compute_output bench bench_cub

# -----------------------------
# Get help page for our makefile??
# -----------------------------
help:
	@echo "Used to make, test and benchmark our solution, as well as CUB from Nvidia.$0"
	@echo "make      	- Makes and runs all required files for a full benchmarking of most of our solutions (naive is not included)"
	@echo "make help 	- Shows this page"

# Naive burde nok være med her faktisk
	@echo "make test	- Makes and runs all required files for a full test of our solutions (naive is not included)"

	@echo "make profile	- Makes and runs all required files for a full profileing of our solutions, writes summary to stdout"
	@echo "make clean	- Cleans up the project to its base form, removing temp files and compiled versions of our solutions"

# -----------------------------
# User targets
# -----------------------------

test: clean_autotest naive_autotest all_autotest write_default_input compute_output
	futhark test --backend=$(BACKEND) $(TESTFILE)

bench:
	futhark bench --backend=$(BACKEND) $(TESTFILE)

profile:
	futhark bench --backend=$(BACKEND) $(TESTFILE) --json $(JSONFILE).json -P $(TESTFILE)
	futhark profile $(JSONFILE).json
	cat ./$(JSONFILE).prof/human/test1.in.summary
	cat ./$(JSONFILE).prof/human_optimal/test1.in.summary
	cat ./$(JSONFILE).prof/compiler/test1.in.summary


test_generic: test_generic.fut make_generic_f32
	futhark test --backend=${BACKEND} $<
	futhark test --backend=$(BACKEND) $(TESTFILE)

make_generic_f32: input make_input naive
	@echo 'import "generic_f32"' > $(TESTFILE)
	@echo "-- ==" >> $(TESTFILE)
	@echo "-- entry: human_generic" >> $(TESTFILE)
	@filenum=1 ; \
	for t in $(TESTS) ; do \
		./make_input -n  $$t -m 100000 -f | ./format_input -f > test$$filenum.in ; \
		cat test$$filenum.in | ./naive 2> /dev/null 1> test$$filenum.out ; \
		echo "-- compiled input @ test$$filenum.in" >> $(TESTFILE) ; \
		echo "-- output @ test$$filenum.out" >> $(TESTFILE) ; \
		echo "--" >> $(TESTFILE) ; \
		((filenum=filenum+1)) ; \
	done 
	echo "entry human_generic = generic_f32.run " >> $(TESTFILE)

naive: naive.fut
	futhark ${BACKEND} $<

naive_compiler: naiveCompiler.fut
	futhark ${BACKEND} $<

# -----------------------------
# Autotest generation
# -----------------------------
clean_autotest:
	@echo > $(TESTFILE)

compute_output:
	@(cat test1.in | futhark run naive.fut > test1.out 2>/dev/null)

all_autotest: clean_autotest input \
	compiler_autotest human_autotest human_optimal_autotest

write_default_input:
	@echo "TESTS = $(TESTS), SEGMENT_SIZE = $(SEGMENT_SIZE)"
	@echo "Generating test data, may take a while if array size is at 10M and above..."
	@filenum=1 ; \
	for t in $(TESTS) ; do \
		./make_input -n  $$t -m $(SEGMENT_SIZE) -f | ./format_input -f > test$$filenum.in ; \
		((filenum=filenum+1)) ; \
	done 
	@echo "Finished generating test data"

# https://medium.com/@ganga.jaiswal/understanding-user-defined-functions-in-makefiles-1f30c082d4de
# Helper macro for autotest generation
define GENERATE_AUTOTEST
	echo 'import "$(1)"' >> $(TESTFILE); \
	echo "-- ==" >> $(TESTFILE); \
	echo "-- entry: $(1)" >> $(TESTFILE); \
	filenum=1; \
	for t in $(TESTS); do \
		echo "-- compiled input @ test$$filenum.in" >> $(TESTFILE); \
		echo "-- output @ test$$filenum.out" >> $(TESTFILE); \
		echo "--" >> $(TESTFILE); \
		((filenum=filenum+1)); \
	done; \
	echo "entry $(1) = $(1).rankSearchBatch" >> $(TESTFILE)
endef

naive_autotest:
	@$(call GENERATE_AUTOTEST,naive)

human_autotest:
	@$(call GENERATE_AUTOTEST,human)

human_optimal_autotest:
	@$(call GENERATE_AUTOTEST,human_optimal)

compiler_autotest:
	@$(call GENERATE_AUTOTEST,compiler)

generic_autotest:
	@$(call GENERATE_AUTOTEST,human_generic)

# -----------------------------
# Cub benching
# -----------------------------
# https://stackoverflow.com/questions/35636229/while-read-line-with-grep, tror det er okay måde at gøre det på,
# men er bare script kitty på hvordanever det her virker
# Og goated at man kan fjerne prefix og suffix med pattern matching https://stackoverflow.com/questions/16623835/remove-a-fixed-prefix-suffix-from-a-string-in-bash
bench_cub:
	@echo "$0"
	@echo "$$(tput bold)sorting_test.cu (NVIDIA CUB Segmented Sorting):$$(tput sgr0)"
	@echo "Running CUB sort with SIZE=$(TESTS), SEGMENT_SIZE=$(SEGMENT_SIZE)"
	@runnum=1 ; \
	for t in $(TESTS) ; do \
		$(MAKE) -C ./cub-code_radixsort SIZE=$$t SEGMENT_SIZE=$(SEGMENT_SIZE) | \
		while read line; do \
			if [ -n "$$(echo "$$line" | grep 'runs in:')" ]; then \
				time=$${line#*runs in: }; \
				time=$${time% us*}; \
				echo "test$$runnum CUB bench SIZE=$$t:	$$timeμs$0"; \
				((runnum=runnum+1)) ; \
			fi; \
		done \
	done

# -----------------------------
# Build tools
# -----------------------------

format_input: format_input.c
	$(CC) -o format_input format_input.c

make_input: make_input.c
	$(CC) -o make_input make_input.c

make_input_compiler: make_input_compiler.c
	$(CC) -o make_input_compiler make_input_compiler.c

input: format_input make_input make_input_compiler

# -----------------------------
# Cleanup
# -----------------------------
clean:
# Filer
	rm -f test*.in test*.out auto_test.c naive.c human.c \
		naive make_input auto_test test test.c make_input_compiler \
		*.actual *.expected auto_test.fut naiveCompiler naiveCompiler.c \
		format_input result.json *.json ./cub-code_radixsort/test-cub \
		test_generic test_generic.c 
# Directory
	rm -f -r *.prof
