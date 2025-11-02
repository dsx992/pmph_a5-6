#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

int main(int argc, char** argv) 
{
    if (argc != 3) {
        return 1;
    }

    srand(time(NULL));
    
    long long n = atoll(argv[1]);  // Total number of elements
    int m = atoi(argv[2]);          // Number of segments
    

    float* A = malloc(sizeof(float) * n);
    int* II1 = malloc(sizeof(int) * n);
    int* shp = malloc(sizeof(int) * m);
    int* ks = malloc(sizeof(int) * m);

    long long seg_size = n / m;
    long long remainder = n % m;
    
    for (int i = 0; i < m; i++) {
        shp[i] = seg_size + (i < remainder ? 1 : 0);
        
        ks[i] = (rand() % shp[i]) + 1;
    }

    int idx = 0;
    for (int seg = 0; seg < m; seg++) {
        for (int i = 0; i < shp[seg]; i++) {
            II1[idx++] = seg;
        }
    }

    for (long long i = 0; i < n; i++) {
        float r = (float)(rand() % 4096) - 2048.0f;
        A[i] = r / 2.0f;
    }

    // ks array
    printf("[");
    for (int i = 0; i < m; i++) {
        printf("%i%s", ks[i], i != m - 1 ? ", " : "");
    }
    printf("] ");

    // shp array
    printf("[");
    for (int i = 0; i < m; i++) {
        printf("%i%s", shp[i], i != m - 1 ? ", " : "");
    }
    printf("] ");

    // II1 array
    printf("[");
    for (long long i = 0; i < n; i++) {
        printf("%i%s", II1[i], i != n - 1 ? ", " : "");
    }
    printf("] ");

    // A array
    printf("[");
    for (long long i = 0; i < n; i++) {
        printf("%.2ff32%s", A[i], i != n - 1 ? ", " : "");
    }
    printf("]\n");

    free(A);
    free(II1);
    free(shp);
    free(ks);
    
    return 0;
}