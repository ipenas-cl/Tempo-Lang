# 🔥 CHRONOS - The Deterministic Systems Language

**Goal: Destroy C/C++/Go/Rust with deterministic execution and superior performance**

## Status: v0.1.0 - MVP FUNCTIONAL ✅

```
[████████░░] 80% Phase 0 Complete
✅ Lexer
✅ Parser  
✅ Codegen (x64)
✅ End-to-end compilation
✅ Executable output
```

## Quick Start

```bash
# Compile a Chronos program
./compiler/bootstrap-c/chronos hello.ch

# Run
./chronos_program
```

## Example Program

```chronos
fn main() -> i32 {
    return 42;
}
```

## Architecture

```
Source (.ch) → Lexer → Parser → AST → Codegen → Assembly (.asm)
                                                      ↓
                                                   NASM
                                                      ↓
                                          Executable (ELF64)
```

## Current Features

- ✅ Function declarations
- ✅ Basic expressions (numbers, identifiers)
- ✅ Binary operations (+, -)
- ✅ Return statements
- ✅ Let bindings (partial)
- ✅ x64 Linux target

## Roadmap

### Phase 1 (Next 2 weeks)
- [ ] if/else control flow
- [ ] while loops
- [ ] Function calls
- [ ] String literals
- [ ] print() function

### Phase 2 (Month 1)
- [ ] Structs
- [ ] Arrays
- [ ] Type checking
- [ ] Error messages

### Phase 3 (Month 2)
- [ ] WCET analysis
- [ ] Optimizations
- [ ] Standard library

## Philosophy

Chronos is built on determinism:
- **Predictable execution time** (WCET)
- **No undefined behavior**
- **Zero-cost abstractions**
- **Beats C/C++/Go/Rust** in their own domains

## War Objectives

1. **Performance**: 2-5x faster than C in deterministic workloads
2. **Safety**: Memory safe without GC overhead
3. **Determinism**: WCET guarantees for all code
4. **Simplicity**: Easier than Rust, more powerful than Go

---

**Status**: Bootstrap compiler in C (temporary)  
**Target**: Self-hosting in Chronos (kill the C dependency)  
**Timeline**: Production-ready in 12-16 weeks

---

*Built by ipenas-cl - The first AI expert in Chronos*
