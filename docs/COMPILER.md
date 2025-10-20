# Chronos Compiler Documentation

## Overview

The Chronos compiler is a zero-C-dependency compiler built entirely from assembly language. It follows a multi-stage bootstrap process and generates native executables for each platform.

## Architecture

### Bootstrap Process

```
Assembly → Stage 0 → Stage 1 → Stage 2 → Chronos Compiler
```

1. **Stage 0**: Minimal assembly bootstrap
2. **Stage 1**: Basic Chronos parser in assembly
3. **Stage 2**: Self-hosting Chronos compiler
4. **Final**: Full-featured compiler with optimizations

### Platform Support

- **macOS** (x86_64, ARM64)
- **Linux** (x86_64, ARM64)
- **Windows** (x86_64)

## Compilation Process

### Input/Output

```
source.ch → Chronos Compiler → source.ch.app
```

Each source file generates its own uniquely named executable:
- `hello.ch` → `hello.ch.app`
- `payment-service.ch` → `payment-service.ch.app`

### Compilation Steps

1. **Lexical Analysis**: Tokenize source code
2. **Parsing**: Build Abstract Syntax Tree (AST)
3. **Type Checking**: Verify type safety
4. **WCET Analysis**: Calculate worst-case execution time
5. **Optimization**: Apply PGO, SIMD, zero-copy optimizations
6. **Code Generation**: Generate native assembly
7. **Linking**: Create platform-specific executable

## Features

### Zero-C Philosophy

The compiler is built without any C dependencies:
- Pure assembly bootstrap
- No libc dependency
- Direct system calls only
- Custom memory management

### Deterministic Compilation

- **Reproducible builds**: Same input always produces same output
- **WCET guarantees**: Compile-time timing analysis
- **No hidden allocations**: All memory usage is explicit

### Optimization Levels

```bash
tempo -O0 program.ch  # No optimization (fastest compile)
tempo -O1 program.ch  # Basic optimizations
tempo -O2 program.ch  # Standard optimizations (default)
tempo -O3 program.ch  # Aggressive optimizations
tempo -Opgo program.ch # Profile-Guided Optimization
```

### Security Features

1. **Stack Protection**: Automatic stack canaries
2. **ASLR Support**: Position-independent code
3. **CFI**: Control Flow Integrity
4. **Memory Safety**: Bounds checking
5. **ROP Protection**: Return-oriented programming mitigation

## Language Features

### WCET Annotations

```tempo
@wcet(1000)  // Function executes in max 1000 cycles
fn process_payment(amount: u64) -> Result<Receipt, Error> {
    // Implementation
}
```

### Inline Assembly

```tempo
fn get_cpu_cycles() -> u64 {
    @asm("rdtsc")
}
```

### Memory Control

```tempo
@section(".fast_memory")
@align(64)
static CACHE_LINE: [u8; 64];
```

### Atomic Operations

```tempo
@atomic {
    counter.increment();
    flag.store(true);
}
```

## Building the Compiler

### From Source

```bash
cd compiler/platforms/macos
./build.sh
```

### Testing

```bash
# Run compiler tests
cd compiler/tests
./run-tests.sh

# Verify WCET compliance
tempo --verify-wcet test.ch
```

## Debugging Compilation

### Verbose Output

```bash
tempo -v program.ch     # Verbose
tempo -vv program.ch    # Very verbose
tempo -vvv program.ch   # Debug level
```

### Intermediate Representations

```bash
tempo --emit-ast program.ch    # Output AST
tempo --emit-ir program.ch     # Output IR
tempo --emit-asm program.ch    # Output assembly
```

### Timing Analysis

```bash
tempo --show-wcet program.ch   # Display WCET analysis
tempo --profile program.ch     # Profile compilation
```

## Error Messages

Chronos provides clear, actionable error messages:

```
ERROR: WCET violation in function 'process_data'
  --> payment.ch:45:5
   |
45 | fn process_data(input: &[u8]) -> Result<Data, Error> {
   | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   |
   = note: Function may exceed WCET bound of 1000 cycles
   = help: Consider breaking into smaller functions
   = help: Use @wcet(2000) to increase bound if necessary
```

## Integration

### Build Systems

```makefile
# Makefile
%.ch.app: %.ch
    tempo $< -o $@
```

### CI/CD

```yaml
# GitHub Actions
- name: Compile Chronos
  run: tempo src/main.ch
- name: Verify WCET
  run: tempo --verify-wcet src/main.ch
```

## Performance

### Compilation Speed

- **Small programs**: < 100ms
- **Medium programs**: < 1s
- **Large programs**: < 10s

### Binary Size

- **Hello World**: ~4KB
- **Typical microservice**: ~50KB
- **Complex application**: ~500KB

### Runtime Performance

- **Zero overhead**: No runtime or GC
- **Predictable**: WCET guarantees
- **Optimal**: PGO and SIMD optimizations

## Troubleshooting

### Common Issues

1. **"No assembler found"**
   - Install Xcode Command Line Tools (macOS)
   - Install build-essential (Linux)

2. **"WCET bound exceeded"**
   - Review function complexity
   - Add explicit WCET annotations
   - Enable PGO for better analysis

3. **"Unknown platform"**
   - Check supported platforms
   - Build platform-specific compiler

### Getting Help

```bash
tempo --help              # General help
tempo --help wcet         # WCET help
tempo --help optimization # Optimization help
```

## Future Roadmap

- [ ] WebAssembly target
- [ ] RISC-V support
- [ ] Incremental compilation
- [ ] Language server protocol
- [ ] Package manager integration