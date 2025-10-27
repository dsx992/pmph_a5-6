#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#define A_MAX 2024

int main(int argc, char** argv) 
{
    int n = atoi(argv[1]);
    int m = 0;

    float* A = malloc(sizeof(float) * n);
    int* II1 = malloc(sizeof(int) * n);

    for (int _n = n; _n; m++) {
        int v = (rand() % _n) + 1;
        // Bruger II1 som en temp array lige nu,
        // dette er ikke dens rigtige værdier
        II1[m] = v;
        _n -= v;
    }

    int shp[m];
    int ks[m];

    #pragma omp parallel for schedule(static)
    for (int i = 0; i < m; i++) {
        int d = II1[i];
        shp[i] = d;
        ks[i] = (rand() % d) + 1;
    }

    #pragma omp parallel for schedule(static)
    for (int i = 0; i < n; i++) {
        int r = rand() % (2024 << 2) + 1;
        int a = ((float) r) / 2;
        a = rand() % 2 ? a * -1 : a;
        A[i] = ((float) r) / 2;
    }

    #pragma omp parallel for schedule(static)
    for (int i = 0; i < n; i++) {
        int c = 0, j = 0;
        while (!(i < (c += shp[j]))) j++;
        II1[i] = j;
    }

    printf("%i\n", n);
    printf("%i\n", m);
    write(stdout, A, sizeof(float) * n);
    write(stdout, II1, sizeof(int) * n);
    write(stdout, shp, sizeof(int) * m);
    write(stdout, ks, sizeof(int) * m);

    free(A);
    free(II1);
    return 0;
}
