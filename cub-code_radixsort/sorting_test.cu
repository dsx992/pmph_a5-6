#include "cub/cub.cuh"
#include "helper.cu.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int rdstdin(void* dest, size_t sz, size_t count) {
    size_t r = fread(dest, sz, count, stdin);
    if (count != r) {
        printf("read %zu bytes, but expected %zu.\n", 
                r, count);
        return 0;
    }
    else return 1;
}

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

    void* tmp_sort_mem = NULL;
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

    //Allocate and Initialize Host data with random values
    char buff[1024];
    fgets(buff, 1024, stdin);
    int n = atoi(buff);

    fgets(buff, 1024, stdin);
    int m = atoi(buff);

    uint32_t* h_A = (uint32_t*)malloc(sizeof(uint32_t) * n);
    uint32_t* h_res = (uint32_t*)malloc(sizeof(uint32_t) * n);
    int* h_II1 = (int*)malloc(sizeof(int) * n);     // bruges ikke her, men gør til futhark
    int* h_shp = (int*)malloc(sizeof(int) * m);
    uint32_t * h_scn = (uint32_t*)malloc(sizeof(int) * m);
    int* h_ks = (int*)malloc(sizeof(int) * m);

    if (!rdstdin(h_A, sizeof(uint32_t), n)) return 1;
    if (!rdstdin(h_II1, sizeof(int), n)) return 1;
    free(h_II1);
    if (!rdstdin(h_shp, sizeof(int), m)) return 1;
    if (!rdstdin(h_ks, sizeof(int), m)) return 1;
    
    uint32_t acc = 0;
    h_scn[0] = 0;
    for (int i = 0; i < (m - 1); i++) {
        acc += h_shp[i];
        h_scn[i + 1] = acc;
    }

    free(h_shp);

    uint32_t* d_A;
    uint32_t* d_scn;
    int* d_ks;
    uint32_t* d_res;

    cudaSucceeded(cudaMalloc((void**) &d_A, sizeof(uint32_t) * n));
    cudaSucceeded(cudaMalloc((void**) &d_scn, sizeof(uint32_t) * m));
    cudaSucceeded(cudaMalloc((void**) &d_ks, sizeof(int) * m));
    cudaSucceeded(cudaMalloc((void**) &d_res, sizeof(uint32_t) * n));
    cudaSucceeded(cudaMemcpy(d_A, h_A, sizeof(uint32_t) * n, cudaMemcpyHostToDevice));
    cudaSucceeded(cudaMemcpy(d_scn, h_scn, sizeof(uint32_t) * m, cudaMemcpyHostToDevice));
    cudaSucceeded(cudaMemcpy(d_ks, h_ks, sizeof(int) * m, cudaMemcpyHostToDevice));

    double elapsed = sortRedByKeySegmentedCUB( d_A, d_res, d_scn, n, m );

    cudaMemcpy(h_res, d_res, n * sizeof(uint32_t), cudaMemcpyDeviceToHost);
    cudaDeviceSynchronize();
    cudaCheckError();

    bool success = validateSegmentedZ(h_res, h_scn, m);

    printf("CUB Segmented Sorting for N=%lu, segments=%u runs in: %.2f us, VALID: %d\n", 
           n, m, elapsed, success);

    cudaFree(d_A);
    cudaFree(d_scn);
    cudaFree(d_ks);
    cudaFree(d_res);
    free(h_A);
    free(h_scn);
    free(h_ks);
    free(h_res);

    return success ? 0 : 1;
}
