<div align="center">

╔═════╦═════╦═════╗  
║ 🛡️  ║ ⚖️  ║ ⚡  ║  
║  C  ║  E  ║  G  ║  
╚═════╩═════╩═════╝  
╔═════════════════╗  
║ wcet [T∞] bound ║  
╚═════════════════╝  

**Author:** Ignacio Peña Sepúlveda  
**Date:** June 25, 2025

</div>

---

# The Tempo "No-Import" Philosophy

## Overview

Tempo embraces a radical approach to standard library design: **everything is built-in**. There are no imports, no dependencies, and no network requirements. Every Tempo program has access to the complete standard library functionality through the compiler's prelude.

## Why No Imports?

### 1. **True Offline Development**
- Write code anywhere, anytime - on a plane, in a bunker, or on Mars
- No package managers, no dependency resolution, no network fetching
- Your code works exactly the same regardless of internet connectivity

### 2. **Zero Configuration**
- No `package.json`, `Cargo.toml`, `go.mod`, or `requirements.txt`
- No version conflicts or dependency hell
- Just write code and run it

### 3. **Instant Productivity**
- No time wasted searching for the right import
- No cognitive overhead remembering module paths
- Autocomplete shows all available functions immediately

### 4. **Deterministic Builds**
- Every Tempo compiler produces identical output for the same input
- No external dependencies means no version mismatches
- Perfect reproducibility across time and space

### 5. **Security by Design**
- No supply chain attacks through compromised dependencies
- No typosquatting (malicious packages with similar names)
- What you see in the prelude is what you get

## How It Works

### The Prelude System

Every Tempo program implicitly includes `prelude.tempo`, which contains:

```tempo
// Automatically available in every Tempo file:
- Core types (Vec, HashMap, Option, Result, etc.)
- String operations (string_split, string_trim, etc.)
- I/O operations (print, println, format)
- Network primitives (TCPListener, TCPConn)
- Synchronization (Mutex, RWMutex, atomic operations)
- Time functions (now, sleep, Duration)
- Math functions (sin, cos, sqrt, etc.)
- And much more...
```

### Tree-Shaking at Compile Time

The Tempo compiler performs aggressive dead code elimination:

1. **Parse Phase**: Identifies all functions and types actually used
2. **Dependency Analysis**: Builds a graph of what depends on what
3. **Pruning**: Removes all unused code paths
4. **Optimization**: Inlines small functions and optimizes the remainder

Result: Your binary only contains the code you actually use!

## Example: Before and After

### Traditional Approach (with imports)
```tempo
import "std/net"
import "std/time"
import "std/sync"
import "std/fmt"

func main() {
    fmt.println("Starting server...")
    let listener = net.listen_tcp("0.0.0.0:8080")
    // ...
}
```

### Tempo Approach (no imports)
```tempo
func main() {
    println("Starting server...")
    let listener = listen_tcp("0.0.0.0:8080")
    // ...
}
```

## Benefits for Different Use Cases

### Embedded Systems
- Predictable binary size through tree-shaking
- No runtime dependency resolution
- Perfect for resource-constrained environments

### High-Performance Computing
- No dynamic linking overhead
- All functions can be inlined by the compiler
- Zero-cost abstractions become truly zero-cost

### Security-Critical Applications
- Auditable - all code is in one place
- No hidden dependencies or transitive imports
- Reduced attack surface

## Tree-Shaking Example

Given this code:
```tempo
func main() {
    println("Hello, World!")
}
```

The compiler will:
1. Include only `println` and its dependencies
2. Exclude all network, file I/O, and other unused subsystems
3. Produce a minimal binary (likely < 50KB)

## Comparison with Other Languages

| Language | Import System | Offline? | Tree-Shaking | Binary Size |
|----------|--------------|----------|--------------|-------------|
| Go       | Explicit imports | No | Limited | Large |
| Rust     | Explicit imports + Cargo | No | Good | Medium |
| Python   | Import + pip | No | No | N/A (interpreted) |
| JavaScript | Import + npm | No | With bundlers | Varies |
| **Tempo** | **None - all built-in** | **Yes** | **Excellent** | **Minimal** |

## Philosophy in Practice

The "no-import" philosophy extends beyond just the standard library:

1. **Single File Programs**: Any Tempo program can be a single file
2. **Copy-Paste Friendly**: Share code snippets without import context
3. **Teaching Friendly**: Students focus on logic, not module systems
4. **Competition Ready**: Perfect for programming contests
5. **Script-Like Simplicity**: With compiled language performance

## FAQ

### Q: Doesn't this make the compiler huge?
A: The prelude is just declarations. The actual implementations are in the compiler, but tree-shaking ensures only used code is included in binaries.

### Q: What about third-party libraries?
A: Tempo encourages vendoring - copy the code you need into your project. This ensures your code always works, forever.

### Q: How do I organize large projects?
A: Use modules within your project. The no-import philosophy applies to standard library only.

### Q: What about versioning?
A: Different Tempo compiler versions may add new functions to the prelude, but existing functions never change behavior (backward compatibility).

## Conclusion

The "no-import" philosophy makes Tempo unique among systems programming languages. It trades the flexibility of external dependencies for the reliability of self-contained programs. In a world where a single npm dependency can break thousands of projects, Tempo offers a refreshing alternative: **your code, depending on nothing, working forever**.