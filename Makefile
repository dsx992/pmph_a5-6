cc=gcc -o1 -fopenmp -pedantic -Wall -std=c99
testfile=auto_test.fut
backend=cuda
tests := 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89 90 91 92 93 94 95 96 97 98 99 100 100 200 300 400 500 600 700 800 900 1000 1100 1200 1300 1400 1500 1600 1700 1800 1900 2000 2100 2200 2300 2400 2500 2600 2700 2800 2900 3000 3100 3200 3300 3400 3500 3600 3700 3800 3900 4000 4100 4200 4300 4400 4500 4600 4700 4800 4900 5000

default: test

bench: make_test
	futhark bench --backend=$(backend) $(testfile)

test: make_test
	futhark test --backend=$(backend) $(testfile)

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

make_input: make_input.c
	$(cc) -o make_input make_input.c

clean:
	rm -f test*.in test*.out auto_test.c naive.c human.c naive make_input auto_test
	rm -f *.actual *.expected
