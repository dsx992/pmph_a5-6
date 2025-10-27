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

int main()
{
    char buff[1024];
    fgets(buff, 1024, stdin);
    int n = atoi(buff);

    fgets(buff, 1024, stdin);
    int m = atoi(buff);

    float* A = malloc(sizeof(float) * n);
    int* II1 = malloc(sizeof(int) * n);
    int shp[m];
    int ks[m];

    if (!rdstdin(A, sizeof(float), n)) return 1;
    if (!rdstdin(II1, sizeof(int), n)) return 1;
    if (!rdstdin(shp, sizeof(int), m)) return 1;
    if (!rdstdin(ks, sizeof(int), m)) return 1;

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
    free(A);
    free(II1);
}
