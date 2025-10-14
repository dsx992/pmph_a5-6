#include <stdio.h>
#include <stdlib.h>

#define A_MAX 2024

int main(int argc, char** argv) 
{
    int n = atoi(argv[1]);
    int m = 0;

    int ms[n];
    float A[n];
    int II1[n];

    for (int _n = n; _n; m++) {
        int v = (rand() % _n) + 1;
        ms[m] = v;
        _n -= v;
    }
    int shp[m];
    int ks[m];


    #pragma omp parallel for schedule(static)
    for (int i = 0; i < m; i++) {
        int d = ms[i];
        shp[i] = d;
        ks[i] = (rand() % d) + 1;
    }


    #pragma omp parallel for schedule(static)
    for (int i = 0; i < n; i++) {
        int r = rand() % (2024 << 2) + 1;
        A[i] = ((float) r) / 2;
    }

    #pragma omp parallel for schedule(static)
    for (int i = 0; i < n; i++) {
        int c, j;
        while (!(i < (c += shp[j]))) j++;
        II1[i] = j;
    }

    // ks
    printf("[");
    for (int i = 0; i < m; i++) {
        printf("%i%s", ks[i], i != m - 1 ? ", " : "");
    }
    printf("] ");

    // shp
    printf("[");
    for (int i = 0; i < m; i++) {
        printf("%i%s", shp[i], i != m - 1 ? ", " : "");
    }
    printf("] ");

    // II1
    printf("[");
    for (int i = 0; i < n; i++) {
        printf("%i%s", II1[i], i != n - 1 ? ", " : "");
    }
    printf("] ");

    // A
    printf("[");
    for (int i = 0; i < n; i++) {
        printf("%0.2ff32%s", A[i], i != n - 1 ? ", " : "");
    }
    printf("] ");
    printf("\n");
    return 0;
}
