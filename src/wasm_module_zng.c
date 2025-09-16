/**
 * zlib-ng.wasm WebAssembly Bridge
 *
 * High-performance WebAssembly interface for zlib-ng compression library
 * with advanced SIMD optimizations and superior algorithm implementations.
 */

#include <emscripten.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include "../zlib-ng.h"

// zlib-ng WebAssembly interface functions

/**
 * Compress data using zlib-ng advanced algorithms
 */
EMSCRIPTEN_KEEPALIVE
int compress_buffer(const uint8_t* src, size_t src_len,
                       uint8_t* dest, size_t* dest_len, int level) {
    if (!src || !dest || !dest_len || src_len == 0) {
        return Z_STREAM_ERROR;
    }

    if (level < 0 || level > 9) {
        level = Z_DEFAULT_COMPRESSION;
    }

    return compress2(dest, dest_len, src, src_len, level);
}

/**
 * Decompress data using zlib-ng optimized inflate
 */
EMSCRIPTEN_KEEPALIVE
int decompress_buffer(const uint8_t* src, size_t src_len,
                         uint8_t* dest, size_t* dest_len) {
    if (!src || !dest || !dest_len || src_len == 0) {
        return Z_STREAM_ERROR;
    }

    return uncompress(dest, dest_len, src, src_len);
}

/**
 * Calculate CRC32 using zlib-ng hardware-accelerated implementation
 */
EMSCRIPTEN_KEEPALIVE
uint32_t crc32(uint32_t crc, const uint8_t* buf, size_t len) {
    return crc32(crc, buf, len);
}

/**
 * Calculate Adler32 using zlib-ng SIMD-optimized implementation
 */
EMSCRIPTEN_KEEPALIVE
uint32_t adler32(uint32_t adler, const uint8_t* buf, size_t len) {
    return adler32(adler, buf, len);
}

/**
 * Get maximum compressed size for given input
 */
EMSCRIPTEN_KEEPALIVE
size_t compress_bound(size_t source_len) {
    return compressBound(source_len);
}

/**
 * Get zlib-ng version with feature information
 */
EMSCRIPTEN_KEEPALIVE
const char* get_version(void) {
    return zlibVersion();
}

/**
 * Detect available SIMD capabilities
 */
EMSCRIPTEN_KEEPALIVE
int has_simd(void) {
#ifdef __wasm_simd128__
    return 1;
#else
    return 0;
#endif
}

/**
 * Get zlib-ng feature flags and optimization status
 */
EMSCRIPTEN_KEEPALIVE
void get_features(int* has_simd, int* has_crc32_hw, int* has_adler32_simd) {
    *has_simd = has_simd();
    *has_crc32_hw = 1;  // zlib-ng always includes optimized CRC32
    *has_adler32_simd = 1;  // zlib-ng includes SIMD Adler32
}

// Streaming compression interface
typedef struct {
    stream stream;
    int initialized;
} stream_t;

EMSCRIPTEN_KEEPALIVE
stream_t* deflate_init(int level, int window_bits, int mem_level, int strategy) {
    stream_t* ctx = (stream_t*)malloc(sizeof(stream_t));
    if (!ctx) return NULL;

    memset(ctx, 0, sizeof(stream_t));

    if (level < 0 || level > 9) level = Z_DEFAULT_COMPRESSION;
    if (window_bits < 8 || window_bits > 15) window_bits = 15;
    if (mem_level < 1 || mem_level > 9) mem_level = 8;

    int ret = deflateInit2(&ctx->stream, level, Z_DEFLATED, window_bits,
                              mem_level, strategy);

    if (ret != Z_OK) {
        free(ctx);
        return NULL;
    }

    ctx->initialized = 1;
    return ctx;
}

EMSCRIPTEN_KEEPALIVE
int deflate_process(stream_t* ctx, const uint8_t* input,
                       size_t input_len, uint8_t* output,
                       size_t output_len, int flush) {
    if (!ctx || !ctx->initialized) return Z_STREAM_ERROR;

    ctx->stream.next_in = (Bytef*)input;
    ctx->stream.avail_in = input_len;
    ctx->stream.next_out = output;
    ctx->stream.avail_out = output_len;

    return deflate(&ctx->stream, flush);
}

EMSCRIPTEN_KEEPALIVE
void deflate_end(stream_t* ctx) {
    if (ctx) {
        if (ctx->initialized) {
            deflateEnd(&ctx->stream);
        }
        free(ctx);
    }
}

// Performance benchmarking functions
EMSCRIPTEN_KEEPALIVE
double benchmark_compression(const uint8_t* data, size_t len, int iterations) {
    if (!data || len == 0 || iterations <= 0) return -1.0;

    size_t max_output_size = compress_bound(len);
    uint8_t* output = malloc(max_output_size);
    if (!output) return -1.0;

    double start_time = emscripten_get_now();

    for (int i = 0; i < iterations; i++) {
        size_t output_size = max_output_size;
        int result = compress_buffer(data, len, output, &output_size, Z_DEFAULT_COMPRESSION);

        if (result != Z_OK) {
            free(output);
            return -1.0;
        }
    }

    double end_time = emscripten_get_now();
    free(output);

    // Return MB/s throughput
    double total_time = (end_time - start_time) / 1000.0;
    double total_bytes = (double)len * iterations;
    return (total_bytes / total_time) / (1024.0 * 1024.0);
}