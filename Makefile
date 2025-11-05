# -----------------------------
# Compiler and configuration
# -----------------------------
CC = gcc -o1 -fopenmp -pedantic -Wall -std=c99
BACKEND = cuda
TESTFILE = auto_test.fut
JSONFILE = jsonout
ARRAY_SIZES = 100 200
SEGMENT_SIZES = 10 20

# CUB NVIDIA
CUB = cub-1.8.0
CUB_FOLDER = ./cub-code_radixsort

default: bench

default_autotest: clean_autotest naive_autotest compiler_autotest human_autotest human_optimal_autotest generic_autotest write_default_input compute_output
default_autobench: clean_autotest compiler_autobench naive_autobench human_autobench human_optimal_autobench generic_autobench write_default_input 

# -----------------------------
# Get help page for our makefile??
# -----------------------------
help:
	@echo "Used to make, test and benchmark our solution, as well as CUB from Nvidia.$0"
	@echo "make      	- Makes and runs all required files for a full benchmarking of most of our solutions (naive is not included)"
	@echo "make help 	- Shows this page"

# Naive burde nok være med her faktisk
	@echo "make test	- Makes and runs all required files for a full test of our solutions (naive is not included)"

	@echo "make profile	- Makes and runs all required files for a full profileing of our solutions"
	@echo "make clean	- Cleans up the project to its base form, removing temp files and compiled versions of our solutions"

# -----------------------------
# User targets
# -----------------------------

test: default_autotest
	futhark test --backend=$(BACKEND) $(TESTFILE)
	@$(MAKE) -s test_generic_extra

bench: default_autobench
	futhark bench --backend=$(BACKEND) $(TESTFILE)
	@$(MAKE) -s bench_cub

profile: default_autotest $(TESTFILE)
	futhark bench --backend=$(BACKEND) --json $(JSONFILE).json -P $(TESTFILE)
	futhark profile $(JSONFILE).json
	@echo "The following summary files were produced:"
	@for d in ./$(JSONFILE).prof/*/ ; do \
		for f in $$d*.summary ; do \
			echo $$f ; \
		done \
	done

# -----------------------------
# Autotest generation
# -----------------------------
clean_autotest:
	@echo > $(TESTFILE)

test_generic_extra: testing/test_generic.fut
	futhark test --backend=${BACKEND} $<

naive: naive.fut
	futhark ${BACKEND} $<

compute_output: naive
	@echo "Computing test .out file"
	@fileindex=1 ; \
	for t in $(ARRAY_SIZES) ; do \
		for ss in $(SEGMENT_SIZES) ; do \
			cat "test"$$fileindex"f.in" | ./naive > "test"$$fileindex"f.out" ; \
			((fileindex++)) ; \
		done \
	done 
	@echo "Finished generating test data expected results"

all_autotest: 

write_default_input: make_input format_input
	@echo "ARRAY_SIZES = $(ARRAY_SIZES), SEGMENT_SIZE = $(SEGMENT_SIZE)"
	@echo "Generating test data."
	@fileindex=1 ; \
	for as in $(ARRAY_SIZES) ; do \
		for ss in $(SEGMENT_SIZES) ; do \
			if ((as > 500000)) && ((e == 0)) ; then \
				echo "Generating a large array size will take a bit, please wait. (SIZE = $$as)" ; \
			fi ; \
			./make_input -n $$as -m $$ss -u > test$$fileindex.in ; \
			cat test$$fileindex.in | ./format_input -u > "test"$$fileindex"f.in" ; \
			((fileindex++)) ; \
		done \
	done
	@echo "Finished generating test data"

# https://medium.com/@ganga.jaiswal/understanding-user-defined-functions-in-makefiles-1f30c082d4de
# Helper macro for autotest generation
define GENERATE_AUTOTEST
	echo 'import "$(1)"' >> $(TESTFILE); \
	echo "-- ==" >> $(TESTFILE); \
	echo "-- entry: $(1)" >> $(TESTFILE); \
	fileindex=1; \
	for t in $(ARRAY_SIZES); do \
		for ss in $(SEGMENT_SIZES) ; do \
			echo "-- compiled input @ test"$$fileindex"f.in" >> $(TESTFILE); \
			echo "-- output @ test"$$fileindex"f.out" >> $(TESTFILE); \
			echo "--" >> $(TESTFILE); \
			((fileindex++)) ; \
		done \
	done; \
	echo "entry $(1) = $(1)_$(2)" >> $(TESTFILE)
endef

naive_autotest:
	@$(call GENERATE_AUTOTEST,naive,f)

human_autotest:
	@$(call GENERATE_AUTOTEST,human,f)

human_optimal_autotest:
	@$(call GENERATE_AUTOTEST,human_optimal,f)

compiler_autotest:
	@$(call GENERATE_AUTOTEST,compiler,f)

generic_autotest:
	@$(call GENERATE_AUTOTEST,human_generic,f)

# -----------------------------
# Autobenching
# -----------------------------

define GENERATE_AUTOBENCH
	echo 'import "$(1)"' >> $(TESTFILE); \
	echo "-- ==" >> $(TESTFILE); \
	echo "-- entry: $(1)" >> $(TESTFILE); \
	fileindex=1; \
	for t in $(ARRAY_SIZES); do \
		for ss in $(SEGMENT_SIZES) ; do \
			echo "-- compiled input @ test"$$fileindex"f.in" >> $(TESTFILE); \
			echo "--" >> $(TESTFILE); \
			((fileindex++)) ; \
		done; \
	done; \
	echo "entry $(1) = $(1)_$(2)" >> $(TESTFILE)
endef

naive_autobench:
	@$(call GENERATE_AUTOBENCH,naive,f)

human_autobench:
	@$(call GENERATE_AUTOBENCH,human,f)

human_optimal_autobench:
	@$(call GENERATE_AUTOBENCH,human_optimal,f)

compiler_autobench:
	@$(call GENERATE_AUTOBENCH,compiler,f)

generic_autobench:
	@$(call GENERATE_AUTOBENCH,human_generic,f)

# -----------------------------
# Cub benching
# -----------------------------
# https://stackoverflow.com/questions/35636229/while-read-line-with-grep, tror det er okay måde at gøre det på,
# men er bare script kitty på hvordanever det her virker
# Og goated at man kan fjerne prefix og suffix med pattern matching https://stackoverflow.com/questions/16623835/remove-a-fixed-prefix-suffix-from-a-string-in-bash
bench_cub: test1.in
	@echo "$0"
	@echo "$$(tput bold)sorting_test.cu:CUB (Reference great implementation):$$(tput sgr0)"
	@echo "Running CUB sort with ARRAY_SIZES=$(ARRAY_SIZES), SEGMENT_SIZES=$(SEGMENT_SIZES)"
	@cd $(CUB_FOLDER) && nvcc -I$(CUB)/cub -o test-cub sorting_test.cu -Wno-deprecated-gpu-targets
	@fileindex=1 ; \
	for t in $(ARRAY_SIZES) ; do \
		for ss in $(SEGMENT_SIZES) ; do \
			cat test$$fileindex.in | $(CUB_FOLDER)/test-cub | \
			while read line; do \
				if [ -n "$$(echo "$$line" | grep 'runs in:')" ]; then \
					time=$${line#*runs in: }; \
					time=$${time% us*}; \
					echo "test$$fileindex CUB bench SIZE=$$t:	$$timeμs$0"; \
					((fileindex++)) ; \
				fi; \
			done \
		done \
	done

# -----------------------------
# Build tools
# -----------------------------

format_input: format_input.c
	$(CC) -o format_input format_input.c

make_input: make_input.c
	$(CC) -o make_input make_input.c

input: format_input make_input

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
