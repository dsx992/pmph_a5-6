#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

enum Type {
    NOT_ASSIGNED,
    INT,
    UINT,
    FLOAT
};

int rdstdin(void* dest, size_t sz, size_t count) {
    size_t r = fread(dest, sz, count, stdin);
    if (count != r) {
        printf("read %zu bytes, but expected %zu.\n", 
                r, count);
        return 0;
    }
    else return 1;
}

int main(int argc, char* argv[])
{
    int n, m, t;

    for (int opt; (opt = getopt(argc, argv, "uif")) != -1; ) {
        switch(opt) {
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

    char buff[1024];
    fgets(buff, 1024, stdin);
    n = atoi(buff);

    fgets(buff, 1024, stdin);
    m = atoi(buff);

    void* A;
    int* II1 = malloc(sizeof(int) * n);
    int* shp = malloc(sizeof(int) * m);
    int* ks = malloc(sizeof(int) * m);

    // sizeof for pædagogiske årsager
    switch(t) {
        case NOT_ASSIGNED:
            fprintf(stderr, "der skal angives en type; -i, -u, el. -f\n");
            return(8);
        case INT:
            A = malloc(sizeof(int) * n);
            break;
        case UINT:
            A = malloc(sizeof(unsigned int) * n);
            break;
        case FLOAT:
            A = malloc(sizeof(float) * n);
            break;
        default:
            fprintf(stderr, "ikke en ægte type\n");
            return(7);
    }

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
    switch(t) {
        case INT:        
            for (int i = 0; i < n; i++) {
                printf("%i%s%s", ((int*)A)[i], "i32", i != n - 1 ? ", " : "");
            }
            break;

        case UINT:
            for (int i = 0; i < n; i++) {
                printf("%i%s%s", ((unsigned int*)A)[i], "u32", i != n - 1 ? ", " : "");
            }
            break;

        case FLOAT:
            for (int i = 0; i < n; i++) {
                printf("%0.2f%s%s", ((float*)A)[i], "f32", i != n - 1 ? ", " : "");
            }
            break;

        default:
            fprintf(stderr, "fejl i type\n");
            return 10;

    }

    printf("] ");
    printf("\n");

    free(A);
    free(II1);
    free(shp);
    free(ks);
}
