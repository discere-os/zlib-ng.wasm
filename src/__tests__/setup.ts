/**
 * Test setup for zlib-ng.wasm
 * Configures test environment and provides global utilities
 */

// Global test utilities
console.log('🧪 zlib-ng.wasm test environment initialized');

// Extend expect with custom matchers if needed
declare module 'vitest' {
  interface Assertion<T = any> {
    // Add custom matchers here if needed
  }
}

// Test environment configuration
const testConfig = {
  timeout: 15000, // 15 second timeout for WASM compilation tests
  retries: 1,     // Retry failed tests once
};

export { testConfig };