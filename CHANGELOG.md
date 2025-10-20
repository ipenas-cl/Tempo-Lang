# Changelog

All notable changes to the Chronos programming language will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [0.10] - 2025-10-21

### Added
- Test runner script (`scripts/run_tests.sh`)
- Practical example programs in `examples/`:
  - FizzBuzz implementation
  - Prime number generator
  - Fibonacci sequence
  - Bubble sort algorithm
  - Binary search
  - GCD/LCM calculator
- Complete features documentation (`docs/FEATURES.md`)
- This CHANGELOG

### Changed
- Updated all author attribution to "Ignacio Peña"
- Cleaned documentation of legacy references

### Removed
- All `.tempo` files (legacy extension, now `.ch`)
- False AtomicOS documentation (OS doesn't exist)
- False certificate promises
- AI/Claude attribution references

### Fixed
- Repository now accurately represents what exists
- Documentation matches actual capabilities

---

## [0.9] - 2025-10-20

### Added
- String operations: `strcmp`, `strcpy`, `strlen`
- Self-hosting compiler components in `self_hosted/`:
  - Lexer (v1)
  - Parser (v0.6 with functions)
  - Codegen (v0.4 with functions)
  - Integration tests
- Unified compiler prototype (`chronos_compiler.ch`)

### Changed
- Bootstrap compiler improved with string handling
- Enhanced symbol table for struct support

---

## [0.8] - 2025-10-19

### Added
- Struct support with field access
- Pointer operations (`&` and `*`)
- Array indexing and manipulation
- Enhanced type system

### Fixed
- Improved codegen for complex expressions
- Better error handling in parser

---

## [0.7] - 2025-10-18

### Added
- Function parameters and return values
- Recursive function support
- Call expression handling
- Improved symbol table

### Changed
- Refactored codegen for better assembly output
- Enhanced parser for function declarations

---

## [0.6] - 2025-10-17

### Added
- While loops
- If-else statements
- Comparison operators (`==`, `!=`, `<`, `>`, `<=`, `>=`)
- Control flow in codegen

---

## [0.5] - 2025-10-16

### Added
- Let statements (variable declarations)
- Assignment expressions
- Variable lookup in symbol table
- Stack-based variable storage

---

## [0.4] - 2025-10-15

### Added
- Binary expressions (`+`, `-`, `*`, `/`)
- Operator precedence parsing
- Expression evaluation in codegen

---

## [0.3] - 2025-10-14

### Added
- Basic function definitions
- Return statements
- AST construction for functions

---

## [0.2] - 2025-10-13

### Added
- Token stream generation
- Basic parser structure
- Number and identifier parsing

---

## [0.1] - 2025-10-12

### Added
- Initial lexer implementation
- Token types definition
- Character classification functions
- Basic project structure

---

## Project Milestones

### 🎉 Self-Hosting Complete (v0.10)
- Compiler can compile itself
- All 3 stages (lexer, parser, codegen) working
- 93% test suite passing
- Zero C dependency for compilation

### 🚀 Bootstrap Compiler (v0.1-v0.10)
- Written in C for initial development
- Compiles `.ch` files to x86-64 assembly
- Generates NASM-compatible output
- Direct syscalls (no libc)

---

**Maintained by**: Ignacio Peña
**License**: MIT
**Repository**: https://github.com/ipenas-cl/Chronos
