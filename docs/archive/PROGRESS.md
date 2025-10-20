# CHRONOS - Development Progress

## Commits Timeline

### v0.1 (Commit 70a3fb1) - MVP Compiler
- ✅ Lexer complete
- ✅ Parser basic
- ✅ Codegen x64
- ✅ Pipeline works
- ✅ hello.ch → executable

### v0.2 (Commit 0f96bf1) - Control Flow
- ✅ if/else statements
- ✅ while loops
- ✅ Comparison operators
- ✅ Logical operators
- ✅ Function call syntax

## Current Status: v0.3 Development

### In Progress:
- 🔧 Variables with symbol table
- 🔧 Stack frame management
- 🔧 Function parameters
- 🔧 Recursion support

### Testing:
```chronos
// Target: Make this work
fn factorial(n: i32) -> i32 {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

fn main() -> i32 {
    return factorial(5);  // Should return 120
}
```

## Next Milestones:

### v0.3 - Functions & Recursion
- [ ] Symbol table per function
- [ ] Stack-based variables
- [ ] Function parameters (1-6 via registers)
- [ ] Call frames with rbp
- [ ] Recursion working

### v0.4 - Stdlib Basic
- [ ] print(string)
- [ ] String literals
- [ ] Basic I/O

### v0.5 - Benchmarks
- [ ] Compare vs C
- [ ] Compare vs Rust
- [ ] Performance data

## War Progress: Destroying C/C++/Go/Rust

Status: **Early Development**
- C: Still using for bootstrap (temporary)
- C++: Target identified
- Go: Target identified
- Rust: Primary target

Victory conditions:
1. Performance: 2x C in deterministic code
2. Safety: No segfaults ever
3. Determinism: WCET analysis
4. Adoption: 1000 programs written in Chronos

Current: 0.01% to victory
