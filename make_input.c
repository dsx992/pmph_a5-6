#include <stdio.h>
#include <stdlib.h>

int main(int argc, char** argv) 
{
    int shpmax = argc > 1 ? atoi(argv[2]) : 255;
    int m = atoi(argv[1]);
    int n;
    int shp[m];
    int ks[m];

    #pragma omp parallel for schedule(static)
    for (int i = 0; i < m; i++) {
        int s = rand() % shpmax;
        s = s < 1 ? 1 : s;
        int k = rand() % s;
        k = k < 1 ? 1 : k;
        n += s;
        shp[i] = s;
        ks[i] = k;
    }

    float A[n];
    int II1[n];

    #pragma omp parallel for schedule(static)
    for (int i = 0; i < n; i++) {
        int r = rand() % 2024;
        r = r < 1 ? 1 : r;
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
