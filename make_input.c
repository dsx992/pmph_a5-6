#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <time.h>

enum Type {
    NOT_ASSIGNED,
    INT,
    UINT,
    FLOAT
};

int writeIntA(int n)
{
    size_t sz = 1 << 20;
    time_t seed = time(NULL);
    int *buf = malloc(sizeof(int) * sz);

    srand(seed);
    for (int i = 0; i < n; i+=sz) {
        #pragma omp parallel for schedule(static)
        for (int j = 0; j < sz; j++) {
            buf[j] = rand() - (RAND_MAX / 2);
        }
        int rest = n - i;
        int min = rest < sz ? rest : sz;
        fwrite(buf, sizeof(int), min, stdout);
    }
    free(buf);
    return 0;
}

int writeUintA(int n)
{
    size_t sz = 2024;
    time_t seed = time(NULL);
    unsigned int buf[sz];

    srand(seed);
    for (int i = 0; i < n; i+=sz) {
        #pragma omp parallel for schedule(static)
        for (int j = 0; j < sz; j++) {
            buf[j] = rand() - (RAND_MAX / 2);
        }
        int rest = n - i;
        int min = rest < sz ? rest : sz;
        fwrite(buf, sizeof(int), min, stdout);
    }
    return 0;
}

int writeFloatA(int n)
{
    size_t sz = 2024;
    time_t seed = time(NULL);
    float buf[sz];

    srand(seed);
    for (int i = 0; i < n; i+=sz) {
        #pragma omp parallel for schedule(static)
        for (int j = 0; j < sz; j++) {
            buf[j] = rand() - (RAND_MAX / 2);
        }
        int rest = n - i;
        int min = rest < sz ? rest : sz;
        fwrite(buf, sizeof(int), min, stdout);
    }
    return 0;
}

int mkShpmInTmp(int n, int* tmp, int *m) {
    for (int _n = n; _n > 0; (*m)++) {
        int v = (rand() % _n) + 1;
        tmp[*m] = v;
        _n -= v;
    }
    return 0;
}

int main(int argc, char** argv) 
{
    int n, m, t;

    n = 0, m = 0, t = NOT_ASSIGNED;
    for (int opt; (opt = getopt(argc, argv, "m:n:uif")) != -1; ) {
        switch(opt) {
            case 'm':
                m = atoi(optarg);
                break;
            case 'n':
                n = atoi(optarg);
                break;
            case 'u':
                t = UINT;
                break;
            case 'i':
                t = INT;
                break;
            case 'f':
                t = FLOAT;
                break;
            default:
                fprintf(stderr, "Usage: %s [-n int] [-m int] [-u] [-i] [-f]\n", 
                        argv[0]);
                exit(5);
        }
    }

    if (m && n % m) fprintf(stderr, "m=%i går ikke op i n=%i.\n", m, n);

    int* II1 = malloc(sizeof(int) * n);
    int* shp;
    int* ks;

    if (m) {
        shp = malloc(sizeof(int) * m);
        int r = n / m;
        #pragma omp parallel for schedule(static)
        for (int i = 0; i < m; i++) {
            shp[i] = r;
        }
    } else {
        // Bruger II1 som en temp array lige nu,
        // dette er ikke dens rigtige værdier
        mkShpmInTmp(n, II1, &m);
        shp = malloc(sizeof(int) * m);
 
        #pragma omp parallel for schedule(static)
        for (int i = 0; i < m; i++) {
            shp[i] = II1[i];
        }
    }
    ks = malloc(sizeof(int) * m);

    printf("%i\n", n);
    printf("%i\n", m);

    switch(t) {
        case NOT_ASSIGNED:
            fprintf(stderr, "der skal angives en type; -i, -u, el. -f\n");
            return(8);
        case INT:
            writeIntA(n);
            break;
        case UINT:
            writeUintA(n);
            break;
        case FLOAT:
            writeFloatA(n);
            break;
        default:
            fprintf(stderr, "ikke en ægte type\n");
            return(7);
    }

    #pragma omp parallel for schedule(static)
    for (int i = 0; i < m; i++) {
        ks[i] = (rand() % shp[i]) + 1;
    }

    #pragma omp parallel for schedule(static)
    for (int i = 0; i < n; i++) {
        int c = 0, j = 0;
        while (!(i < (c += shp[j]))) j++;
        II1[i] = j;
    }

    fwrite(II1, sizeof(int), n, stdout);
    fwrite(shp, sizeof(int), m, stdout);
    fwrite(ks, sizeof(int), m, stdout);

    free(II1);
    free(shp);
    free(ks);
    return 0;
}
