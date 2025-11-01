//#include "../../cub-1.8.0/cub/cub.cuh"   // or equivalently <cub/device/device_histogram.cuh>
#include "cub/cub.cuh"
#include "helper.cu.h"

template<class Z>
bool validateZ(Z* A, uint32_t sizeAB) {
    for(uint32_t i = 1; i < sizeAB; i++)
      if (A[i-1] > A[i]){
        printf("INVALID RESULT for i:%d, (A[i-1]=%d > A[i]=%d)\n", i, A[i-1], A[i]);
        return false;
      }
    return true;
}

bool validateSegmentedZ(uint32_t* A, uint32_t* offsets, uint32_t num_segments) {
    for(uint32_t seg = 0; seg < num_segments; seg++) {
        uint32_t start = offsets[seg];
        uint32_t end = offsets[seg + 1];
        for(uint32_t i = start + 1; i < end; i++) {
            if (A[i-1] > A[i]){
                printf("INVALID RESULT in segment %d for i:%d, (A[i-1]=%d > A[i]=%d)\n", 
                       seg, i, A[i-1], A[i]);
                return false;
            }
        }
    }
    return true;
}

void randomInitNat(uint32_t* data, const uint32_t size, const uint32_t H) {
    for (int i = 0; i < size; ++i) {
        unsigned long int r = rand();
        data[i] = r % H;
    }
}

void initSegmentOffsets(uint32_t* offsets, uint32_t num_segments, uint64_t N) {
    uint64_t seg_size = N / num_segments;
    for(uint32_t i = 0; i < num_segments; i++) {
        offsets[i] = i * seg_size;
    }
    offsets[num_segments] = N;  // last offset is the total size
}

double sortRedByKeySegmentedCUB( uint32_t* data_keys_in
                               , uint32_t* data_keys_out
                               , uint32_t* d_offsets
                               , const uint64_t N
                               , const uint32_t num_segments
) {
    int beg_bit = 0;
    int end_bit = 32;

    void * tmp_sort_mem = NULL;
    size_t tmp_sort_len = 0;

    { // sort prelude
        cub::DeviceSegmentedRadixSort::SortKeys( tmp_sort_mem, tmp_sort_len
                                               , data_keys_in, data_keys_out
                                               , N, num_segments, d_offsets, d_offsets + 1
                                               , beg_bit, end_bit
                                               );
        cudaMalloc(&tmp_sort_mem, tmp_sort_len);
    }
    cudaCheckError();

    { // one dry run
        cub::DeviceSegmentedRadixSort::SortKeys( tmp_sort_mem, tmp_sort_len
                                               , data_keys_in, data_keys_out
                                               , N, num_segments, d_offsets, d_offsets + 1
                                               , beg_bit, end_bit
                                               );
        cudaDeviceSynchronize();
    }
    cudaCheckError();

    // timing
    double elapsed;
    struct timeval t_start, t_end, t_diff;
    gettimeofday(&t_start, NULL);

    for(int k=0; k<GPU_RUNS; k++) {
        cub::DeviceSegmentedRadixSort::SortKeys( tmp_sort_mem, tmp_sort_len
                                               , data_keys_in, data_keys_out
                                               , N, num_segments, d_offsets, d_offsets + 1
                                               , beg_bit, end_bit
                                               );
    }
    cudaDeviceSynchronize();
    cudaCheckError();

    gettimeofday(&t_end, NULL);
    timeval_subtract(&t_diff, &t_end, &t_start);
    elapsed = (t_diff.tv_sec*1e6+t_diff.tv_usec) / ((double)GPU_RUNS);

    cudaFree(tmp_sort_mem);

    return elapsed;
}


int main (int argc, char * argv[]) {
    if (argc != 3) {
        printf("Usage: %s <size-of-array> <num-segments>\n", argv[0]);
        exit(1);
    }
    const uint64_t N = atoi(argv[1]);
    const uint32_t num_segments = atoi(argv[2]);

    if (N % num_segments != 0) {
        printf("Warning: N should be divisible by num_segments for even segment sizes\n");
    }

    //Allocate and Initialize Host data with random values
    uint32_t* h_keys  = (uint32_t*) malloc(N*sizeof(uint32_t));
    uint32_t* h_keys_res  = (uint32_t*) malloc(N*sizeof(uint32_t));
    uint32_t* h_offsets = (uint32_t*) malloc((num_segments + 1)*sizeof(uint32_t));
    randomInitNat(h_keys, N, N/10);
    initSegmentOffsets(h_offsets, num_segments, N);

    //Allocate and Initialize Device data
    uint32_t* d_keys_in;
    uint32_t* d_keys_out;
    uint32_t* d_offsets;
    cudaSucceeded(cudaMalloc((void**) &d_keys_in,  N * sizeof(uint32_t)));
    cudaSucceeded(cudaMemcpy(d_keys_in, h_keys, N * sizeof(uint32_t), cudaMemcpyHostToDevice));
    cudaSucceeded(cudaMalloc((void**) &d_keys_out, N * sizeof(uint32_t)));
    cudaSucceeded(cudaMalloc((void**) &d_offsets, (num_segments + 1) * sizeof(uint32_t)));
    cudaSucceeded(cudaMemcpy(d_offsets, h_offsets, (num_segments + 1) * sizeof(uint32_t), cudaMemcpyHostToDevice));

    double elapsed = sortRedByKeySegmentedCUB( d_keys_in, d_keys_out, d_offsets, N, num_segments );

    cudaMemcpy(h_keys_res, d_keys_out, N*sizeof(uint32_t), cudaMemcpyDeviceToHost);
    cudaDeviceSynchronize();
    cudaCheckError();

    bool success = validateSegmentedZ(h_keys_res, h_offsets, num_segments);

    printf("CUB Segmented Sorting for N=%lu, segments=%u runs in: %.2f us, VALID: %d\n", 
           N, num_segments, elapsed, success);

    // Cleanup and closing
    cudaFree(d_keys_in); cudaFree(d_keys_out); cudaFree(d_offsets);
    free(h_keys); free(h_keys_res); free(h_offsets);

    return success ? 0 : 1;
}