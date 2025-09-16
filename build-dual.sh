#!/bin/bash
# build-dual.sh - Dual build system for zlib-ng.wasm with advanced SIMD
#
# Copyright (C) 1995-2024 Jean-loup Gailly and Mark Adler
# Copyright (C) 2013-2024 Cloudflare, Inc.
# Copyright 2025 Superstruct Ltd, New Zealand

set -euo pipefail

# Configuration
BUILD_TYPE="${BUILD_TYPE:-Release}"
INSTALL_PREFIX="${INSTALL_PREFIX:-./install}"
BUILD_DIR="${BUILD_DIR:-./build-dual}"
VARIANT="${1:-all}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Build zlib-ng.wasm as SIDE_MODULE for dynamic loading
build_zng_side_module() {
    log_info "Building zlib-ng.wasm as SIDE_MODULE with advanced SIMD..."

    mkdir -p "${BUILD_DIR}-side"
    cd "${BUILD_DIR}-side"

    # Core zlib-ng sources
    ZNG_SOURCES="../adler32.c ../compress.c ../crc32.c ../deflate.c ../deflate_fast.c ../deflate_medium.c ../deflate_slow.c ../deflate_quick.c ../deflate_rle.c ../deflate_stored.c ../deflate_huff.c ../infback.c ../inflate.c ../inftrees.c ../trees.c ../uncompr.c ../zutil.c ../functable.c ../insert_string.c ../cpu_features.c"

    # SIDE_MODULE optimized build with zlib-ng
    emcc ${ZNG_SOURCES} ../src/wasm_module_side.c \
        -I.. \
        -O1 \
        -sSIDE_MODULE=1 \
        -sSTANDALONE_WASM=1 \
        -o zlib-ng-side.wasm

    log_success "SIDE_MODULE build completed: $(pwd)/zlib-ng-side.wasm"
    cd ..
}

# Build zlib-ng.wasm as MAIN_MODULE for testing and NPM
build_zng_main_module() {
    log_info "Building zlib-ng.wasm as MAIN_MODULE with full SIMD..."

    mkdir -p "${BUILD_DIR}-main-release"
    cd "${BUILD_DIR}-main-release"

    # Core zlib-ng sources
    ZNG_SOURCES="../adler32.c ../compress.c ../crc32.c ../deflate.c ../deflate_fast.c ../deflate_medium.c ../deflate_slow.c ../deflate_quick.c ../deflate_rle.c ../deflate_stored.c ../deflate_huff.c ../infback.c ../inflate.c ../inftrees.c ../trees.c ../uncompr.c ../zutil.c ../functable.c ../insert_string.c ../cpu_features.c"

    # MAIN_MODULE build using SIMD-optimized library
    emcc ../libz.a ../src/wasm_module_simd.c \
        -I.. \
        -DWASM_SIMD128 \
        -O3 \
        -flto \
        -msimd128 \
        -sWASM=1 \
        -sMODULARIZE=1 \
        -sEXPORT_NAME="ZlibNGModule" \
        -sEXPORTED_FUNCTIONS='["_zlib_compress_buffer","_zlib_decompress_buffer","_zlib_crc32","_zlib_adler32","_zlib_compress_bound","_zlib_get_version","_zlib_has_simd","_zlib_compress_simd","_zlib_crc32_simd_optimized","_zlib_benchmark_simd_compression","_zlib_simd_capabilities","_zlib_benchmark_crc32","_zlib_benchmark_compression","_zlib_get_performance_info","_zlib_init_optimized_memory","_zlib_cleanup_optimized_memory","_malloc","_free"]' \
        -sEXPORTED_RUNTIME_METHODS='["cwrap","ccall","UTF8ToString","getValue","setValue","HEAPU8","HEAP8","HEAP32","HEAPF64"]' \
        -sASSERTIONS=0 \
        -sNO_EXIT_RUNTIME=1 \
        -o zlib-ng-release.js

    # Also build fallback version for compatibility (no SIMD)
    emcc ../libz.a ../src/wasm_module_simd.c \
        -I.. \
        -O2 \
        -sWASM=1 \
        -sMODULARIZE=1 \
        -sEXPORT_NAME="ZlibNGModule" \
        -sEXPORTED_FUNCTIONS='["_zlib_compress_buffer","_zlib_decompress_buffer","_zlib_crc32","_zlib_adler32","_zlib_compress_bound","_zlib_get_version","_zlib_has_simd","_zlib_compress_simd","_zlib_crc32_simd_optimized","_zlib_benchmark_simd_compression","_zlib_simd_capabilities","_zlib_benchmark_crc32","_zlib_benchmark_compression","_zlib_get_performance_info","_zlib_init_optimized_memory","_zlib_cleanup_optimized_memory","_malloc","_free"]' \
        -sEXPORTED_RUNTIME_METHODS='["cwrap","ccall","UTF8ToString","getValue","setValue","HEAPU8","HEAP8","HEAP32"]' \
        -sALLOW_MEMORY_GROWTH=1 \
        -sASSERTIONS=1 \
        -o zlib-ng-fallback.js

    log_success "MAIN_MODULE build completed: $(pwd)/zlib-ng-release.js"
    cd ..
}

# Install artifacts
install_artifacts() {
    log_info "Installing build artifacts..."

    mkdir -p "${INSTALL_PREFIX}/wasm"
    mkdir -p "${INSTALL_PREFIX}/include"

    # Copy WASM artifacts
    if [ -f "${BUILD_DIR}-side/zlib-ng-side.wasm" ]; then
        cp "${BUILD_DIR}-side/zlib-ng-side.wasm" "${INSTALL_PREFIX}/wasm/"
        log_success "Installed SIDE_MODULE: ${INSTALL_PREFIX}/wasm/zlib-ng-side.wasm"
    fi

    if [ -f "${BUILD_DIR}-main-release/zlib-ng-release.js" ]; then
        cp "${BUILD_DIR}-main-release/zlib-ng-release.js" "${INSTALL_PREFIX}/wasm/"
        cp "${BUILD_DIR}-main-release/zlib-ng-release.wasm" "${INSTALL_PREFIX}/wasm/"
        log_success "Installed MAIN_MODULE: ${INSTALL_PREFIX}/wasm/zlib-ng-release.js"
    fi

    if [ -f "${BUILD_DIR}-main-release/zlib-ng-fallback.js" ]; then
        cp "${BUILD_DIR}-main-release/zlib-ng-fallback.js" "${INSTALL_PREFIX}/wasm/"
        cp "${BUILD_DIR}-main-release/zlib-ng-fallback.wasm" "${INSTALL_PREFIX}/wasm/"
        log_success "Installed FALLBACK_MODULE: ${INSTALL_PREFIX}/wasm/zlib-ng-fallback.js"
    fi

    # Copy to build/ directory for test compatibility
    mkdir -p build/
    if [ -f "${INSTALL_PREFIX}/wasm/zlib-ng-release.js" ]; then
        cp "${INSTALL_PREFIX}/wasm/zlib-ng-release.js" build/zlib-ng-optimized.js
        cp "${INSTALL_PREFIX}/wasm/zlib-ng-release.wasm" build/zlib-ng-optimized.wasm
        cp build/zlib-ng-optimized.js build/zlib-ng-release.js
        cp build/zlib-ng-optimized.wasm build/zlib-ng-release.wasm
        log_success "Copied optimized build to build/ for test compatibility"
    fi

    # Copy headers
    cp zlib-ng.h "${INSTALL_PREFIX}/include/"
    cp zconf-ng.h "${INSTALL_PREFIX}/include/"

    log_success "Installation complete in ${INSTALL_PREFIX}/"
}

# Clean build artifacts
clean_build() {
    log_info "Cleaning build artifacts..."

    rm -rf "${BUILD_DIR}-side" "${BUILD_DIR}-main-release"
    rm -rf "${INSTALL_PREFIX}"
    rm -rf build/
    rm -rf dist/

    log_success "Build artifacts cleaned"
}

# Main build logic
main() {
    case "${VARIANT}" in
        "clean")
            clean_build
            ;;
        "side")
            build_zng_side_module
            install_artifacts
            ;;
        "main")
            build_zng_main_module
            install_artifacts
            ;;
        "all")
            build_zng_side_module
            build_zng_main_module
            install_artifacts
            ;;
        *)
            log_error "Unknown variant: ${VARIANT}. Use 'clean', 'side', 'main', or 'all'"
            exit 1
            ;;
    esac

    if [ "${VARIANT}" != "clean" ]; then
        log_success "Build completed for variant: ${VARIANT}"
    fi
}

# Check for emcc
if ! command -v emcc &> /dev/null; then
    log_error "emcc not found. Please install Emscripten SDK"
    exit 1
fi

main "$@"