CUB=cub-1.8.0
SIZE ?= 10000000
SEGMENT_SIZE ?= 100000


all: cub-sort

cub-sort: sorting_test.cu helper.cu.h
	nvcc -I$(CUB)/cub -o test-cub sorting_test.cu -Wno-deprecated-gpu-targets
	./test-cub $(SIZE) $(SEGMENT_SIZE)

clean:
	rm -f test-cub

