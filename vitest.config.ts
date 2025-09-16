import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    globals: true,
    environment: 'node',
    include: ['src/**/*.{test,spec}.{js,mjs,cjs,ts,mts,cts,jsx,tsx}'],
    exclude: ['node_modules', 'dist', 'build*', 'install'],
    testTimeout: 15000, // Increased for SIMD compilation tests
    setupFiles: ['./src/__tests__/setup.ts'],
    coverage: {
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'src/__tests__/',
        'dist/',
        'build*/',
        'install/',
        '*.config.*',
        'src/zlib_simd_fallbacks.c', // Exclude fallback implementations from coverage
        'src/zlib_simd_metrics.c'   // Exclude metrics from main coverage
      ]
    },
    // Add SIMD-specific test configuration
    env: {
      ZLIB_NG_WASM_SIMD: '1'
      // NOTE: NODE_OPTIONS with --experimental-wasm-simd not allowed in recent Node.js versions
    }
  }
})