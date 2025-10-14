default: test

test: test.fut ref2000000.out
	futhark test --backend=cuda $<

clean:
	rm -rf ref2000000.out
	rm -rf *.c test
	rm -rf *.actual
	rm -rf *.expected
