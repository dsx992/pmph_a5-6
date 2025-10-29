#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>

#define A_MAX 2024
static char* regular_f = "--regular";

int main(int argc, char** argv) 
{
    if (strcmp("--help", argv[1]) == 0) {
        printf("./make_input [n size] giver et irregular array\n");
        printf("./make_input --regular [n size] [m size] giver et regulært array\n");
        return 2;
    }
    int n, m, r;
    if (argc == 4 
        && strcmp(regular_f, argv[1]) == 0) {

        n = atoi(argv[2]);
        r = atoi(argv[3]);
        if (n % r) return 1;
        m = n / r;
    } else {
        n = atoi(argv[1]);
        m = 0;
        r = 0;
    }

    float* A = malloc(sizeof(float) * n);
    int* II1 = malloc(sizeof(int) * n);

    for (int _n = n; !r && _n; m++) {
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
        int d = r ? r : II1[i];
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
    fwrite(A, sizeof(float), n, stdout);
    fwrite(II1, sizeof(int), n, stdout);
    fwrite(shp, sizeof(int), m, stdout);
    fwrite(ks, sizeof(int), m, stdout);

    free(A);
    free(II1);
    return 0;
}
