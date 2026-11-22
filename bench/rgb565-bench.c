/* RGB565 -> RGBA8888 microbenchmark for RK322X (issue #4).
 * Build in an ARMv7 hard-float container:
 *   gcc -O2 -mcpu=cortex-a7 -mfpu=neon -mfloat-abi=hard -o rgb565-bench rgb565-bench.c
 * Scalar fallback: drop -mfpu/-mfloat-abi and compile without __ARM_NEON.
 */
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

static inline uint32_t expand_scalar(uint16_t p)
{
    uint32_t r5 = (p >> 11) & 0x1f;
    uint32_t g6 = (p >> 5) & 0x3f;
    uint32_t b5 = p & 0x1f;
    /* RGBA8888 byte order in memory on little-endian ARM: R,G,B,A. */
    return 0xff000000u |
           ((b5 << 3) | (b5 >> 2)) << 16 |
           ((g6 << 2) | (g6 >> 4)) << 8 |
           ((r5 << 3) | (r5 >> 2));
}

static void convert_scalar(const uint16_t *src, uint32_t *dst, int n)
{
    for (int i = 0; i < n; i++)
        dst[i] = expand_scalar(src[i]);
}

#ifdef __ARM_NEON
#include <arm_neon.h>
static void convert_neon(const uint16_t *src, uint32_t *dst, int n)
{
    int i = 0;
    for (; i + 8 <= n; i += 8) {
        uint16x8_t p = vld1q_u16(src + i);
        uint16x8_t r5 = vshrq_n_u16(p, 11);
        uint16x8_t g6 = vandq_u16(vshrq_n_u16(p, 5), vdupq_n_u16(0x3f));
        uint16x8_t b5 = vandq_u16(p, vdupq_n_u16(0x1f));
        uint16x8_t r8 = vaddq_u16(vshlq_n_u16(r5, 3), vshrq_n_u16(r5, 2));
        uint16x8_t g8 = vaddq_u16(vshlq_n_u16(g6, 2), vshrq_n_u16(g6, 4));
        uint16x8_t b8 = vaddq_u16(vshlq_n_u16(b5, 3), vshrq_n_u16(b5, 2));
        uint8x8x4_t out;
        out.val[0] = vqmovn_u16(r8);
        out.val[1] = vqmovn_u16(g8);
        out.val[2] = vqmovn_u16(b8);
        out.val[3] = vdup_n_u8(255);
        vst4_u8((uint8_t *)(dst + i), out);
    }
    if (i < n)
        convert_scalar(src + i, dst + i, n - i);
}
#endif

static double now_s(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec + ts.tv_nsec * 1e-9;
}

static int cmp_double(const void *a, const void *b)
{
    double x = *(const double *)a, y = *(const double *)b;
    return (x > y) - (x < y);
}

static void run(const char *name, void (*fn)(const uint16_t *, uint32_t *, int),
                const uint16_t *src, uint32_t *dst, const uint32_t *ref,
                int n, int reps)
{
    double *times = calloc(reps, sizeof(double));
    for (int r = 0; r < reps; r++) {
        double t0 = now_s();
        fn(src, dst, n);
        times[r] = now_s() - t0;
        if (memcmp(dst, ref, n * sizeof(uint32_t)) != 0) {
            fprintf(stderr, "%s: pixel mismatch at rep %d\n", name, r);
            exit(2);
        }
    }
    qsort(times, reps, sizeof(double), cmp_double);
    printf("%s: width=%d reps=%d median_ms=%.4f p95_ms=%.4f min_ms=%.4f\n",
           name, n, reps, times[reps / 2] * 1000, times[reps * 95 / 100] * 1000,
           times[0] * 1000);
    free(times);
}

int main(int argc, char **argv)
{
    int width = (argc > 1) ? atoi(argv[1]) : 640;
    int height = (argc > 2) ? atoi(argv[2]) : 478;
    int reps = (argc > 3) ? atoi(argv[3]) : 1000;
    int n = width * height;
    uint16_t *src = malloc(n * sizeof(uint16_t));
    uint32_t *dst = malloc(n * sizeof(uint32_t));
    uint32_t *ref = malloc(n * sizeof(uint32_t));
    if (!src || !dst || !ref)
        return 1;

    /* Deterministic pattern covering 5->8 and 6->8 expansion edges. */
    for (int i = 0; i < n; i++) {
        src[i] = (uint16_t)(((i * 37) & 0x1f) << 11 |
                            (((i * 17) >> 3) & 0x3f) << 5 |
                            ((i * 7) & 0x1f));
        ref[i] = expand_scalar(src[i]);
    }

    printf("RGB565->RGBA8888 %dx%d (%d pixels), %d reps\n", width, height, n, reps);
    run("scalar", convert_scalar, src, dst, ref, n, reps);
#ifdef __ARM_NEON
    run("neon", convert_neon, src, dst, ref, n, reps);
#else
    printf("neon: not compiled (no __ARM_NEON)\n");
#endif
    /* Odd width tail check. */
    if (width % 2) {
        printf("odd width tail included in convert_neon scalar remainder\n");
    }
    free(src);
    free(dst);
    free(ref);
    return 0;
}
