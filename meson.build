project('zlib-ng.wasm', 'c', version: '2.1.6', meson_version: '>=1.3.0', default_options: ['buildtype=release'])

fs = import('fs')

if get_option('simd')
  add_project_arguments('-msimd128', language: 'c')
endif

incs = [ include_directories('.') ]

# Core sources (portable C files; avoid x86-specific .lo/asm)
core_sources = [
  'adler32.c',
  'compress.c',
  'crc32.c',
  'deflate.c',
  'deflate_fast.c',
  'deflate_huff.c',
  'deflate_medium.c',
  'deflate_quick.c',
  'deflate_rle.c',
  'deflate_slow.c',
  'deflate_stored.c',
  'functable.c',
  'gzlib.c',
  'gzread.c',
  'gzwrite.c',
  'infback.c',
  'inflate.c',
  'inftrees.c',
  'insert_string.c',
  'trees.c',
  'uncompr.c',
]

core = static_library('zlibng_core', core_sources, include_directories: incs)

if get_option('main_module')
  executable('zlibng-main', 'src/zlibng_wasm_module.c',
    link_with: core,
    include_directories: incs,
    install: true,
    link_args: [
      '--no-entry',
      '-sMODULARIZE=1',
      '-sEXPORT_ES6=1',
      '-sALLOW_MEMORY_GROWTH=1',
      '-sENVIRONMENT=web,webview,worker',
      '-sNO_FILESYSTEM=1',
      '-sEXPORTED_RUNTIME_METHODS=["cwrap","ccall","UTF8ToString"]',
      '-sEXPORTED_FUNCTIONS=@' + meson.project_source_root() / get_option('exports'),
    ])
endif

if get_option('side_module')
  shared_module('zlibng-side', 'src/zlibng_wasm_side.c',
    link_whole: core,
    include_directories: incs,
    name_prefix: '',
    install: true,
    link_args: ['-sSIDE_MODULE=2', '-fPIC'])
endif

