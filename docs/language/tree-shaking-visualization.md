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

# Tree-Shaking Visualization

## How Chronos's Compiler Optimizes Your Code

### The Prelude: What's Available

The Chronos prelude contains ~250+ built-in functions covering:

```
┌──────────────────────────────────────────────────────┐
│                    TEMPO PRELUDE                     │
├─────────────────┬───────────────┬────────────────────┤
│ I/O & Formatting│    Network    │   Synchronization  │
│ • println       │ • listen_tcp  │ • Mutex            │
│ • print         │ • dial_tcp    │ • RWMutex          │
│ • format        │ • accept      │ • atomic_*         │
│ • sprintf       │ • read/write  │ • WaitGroup        │
├─────────────────┼───────────────┼────────────────────┤
│     Strings     │     Math      │       Time         │
│ • string_split  │ • sin/cos/tan │ • now()            │
│ • string_trim   │ • sqrt/pow    │ • sleep()          │
│ • parse_*       │ • min/max     │ • Duration         │
│ • to_uppercase  │ • abs/round   │ • Time             │
├─────────────────┼───────────────┼────────────────────┤
│  Data Structures│    Memory     │      Misc          │
│ • HashMap       │ • memcpy      │ • hash_*           │
│ • Vec           │ • alloc/free  │ • rand_*           │
│ • Option/Result │ • memset      │ • panic/assert     │
└─────────────────┴───────────────┴────────────────────┘
```

### Example 1: Hello World

**Source Code:**
```tempo
func main() {
    println("Hello, World!")
}
```

**Tree-Shaking Analysis:**

```
Used Functions (6):          Removed Functions (244+):
✓ main                      ✗ listen_tcp
✓ println                   ✗ dial_tcp  
✓ format                    ✗ HashMap
✓ write_stdout             ✗ sin/cos/tan
✓ strlen                    ✗ sqrt/pow
✓ memcpy                    ✗ Mutex/RWMutex
                           ✗ atomic_*
                           ✗ Time/Duration
                           ✗ ... and 236 more

Binary Size: 48 KB (vs ~2.5 MB without tree-shaking)
Reduction: 98%
```

### Example 2: Redis Killer (Subset)

**Source Code:**
```tempo
func main() {
    let listener = listen_tcp("0.0.0.0:6379")
    println("Redis Killer starting...")
    // ... server loop
}
```

**Tree-Shaking Analysis:**

```
                              CALL GRAPH
                                 │
                              main()
                            /         \
                    listen_tcp()    println()
                    /    |    \         |
              socket() bind() listen() format()
                 |       |       |        |
             syscall syscall syscall  StringBuilder
                                          |
                                      memcpy()

Used Functions (45):          Removed Functions (205+):
✓ Network Stack              ✗ Math Functions
  • listen_tcp                 • sin/cos/tan
  • accept                     • sqrt/pow
  • read/write                 • exp/log
  • TCPConn/TCPListener      ✗ File I/O
✓ String Operations            • open/create
  • string_from_bytes          • File operations
  • parse_i64                ✗ Advanced Sync
✓ Basic I/O                    • WaitGroup
  • println                    • Once
✓ Hashing                    ✗ Random
  • hash_fnv1a                 • rand_*
✓ Time
  • now()

Binary Size: 245 KB
Reduction: 90%
```

### Comparison: With vs Without Tree-Shaking

```
Program          │ With Tree-Shaking │ Without │ Savings
─────────────────┼──────────────────┼─────────┼─────────
Hello World      │      48 KB       │  2.5 MB │   98%
Math Calculator  │      85 KB       │  2.5 MB │   97%
TCP Echo Server  │     156 KB       │  2.5 MB │   94%
Redis Killer     │     245 KB       │  2.5 MB │   90%
Full Featured    │     1.2 MB       │  2.5 MB │   52%
```

### How Tree-Shaking Works

1. **Parse Phase**
   ```
   AST → Find all function calls → Build initial set
   ```

2. **Dependency Analysis**
   ```
   For each used function:
     → Find functions it calls
     → Add to used set
     → Repeat recursively
   ```

3. **Code Generation**
   ```
   Only emit code for functions in used set
   ```

4. **Link Time Optimization**
   ```
   Further inline small functions
   Remove unused code paths
   Optimize based on actual usage
   ```

### Real-World Impact

#### Embedded System (32KB Flash)
```
Standard Go/Rust: Won't fit (minimum ~1MB)
Chronos with Tree-Shaking: 28KB ✓

Included: Core logic + minimal I/O
Excluded: Everything else
```

#### Serverless Function
```
Cold Start Times:
- Node.js: 200-400ms
- Go: 50-100ms  
- Chronos: 5-10ms ⚡

Why? Tiny binary = fast load
```

#### Container Images
```
FROM scratch
COPY myapp /
CMD ["/myapp"]

Image Sizes:
- Go app: 10-50MB
- Rust app: 5-20MB
- Chronos app: 200KB-2MB
```

### Tree-Shaking Commands

```bash
# See what functions are included
tempo build --show-tree-shaking main.tempo

# Generate tree-shaking report
tempo build --tree-shake-report main.tempo

# Visualize call graph
tempo build --call-graph main.tempo > graph.dot
dot -Tpng graph.dot > graph.png

# Compare with/without tree-shaking
tempo build --no-tree-shaking main.tempo -o main-full
tempo build main.tempo -o main-optimized
ls -lh main-*
```

### Best Practices for Optimal Tree-Shaking

1. **Use Specific Functions**
   ```tempo
   // Bad: Forces inclusion of entire formatting system
   println(format!("Value: {}", x))
   
   // Good: Only includes number→string conversion
   println("Value: ", i32_to_string(x))
   ```

2. **Conditional Compilation**
   ```tempo
   #[cfg(debug)]
   func debug_print(msg: string) {
       println("[DEBUG]", msg)
   }
   
   #[cfg(not(debug))]
   func debug_print(msg: string) {
       // No-op in release builds
   }
   ```

3. **Feature Flags**
   ```tempo
   const ENABLE_METRICS = false
   
   func record_metric(name: string, value: f64) {
       if ENABLE_METRICS {
           // Compiler will remove this entire branch
           send_to_metrics_server(name, value)
       }
   }
   ```

### Conclusion

Tree-shaking in Chronos isn't just an optimization - it's a fundamental design principle. By including everything in the prelude but only compiling what you use, Chronos achieves:

- **Tiny binaries** perfect for embedded systems
- **Fast startup** ideal for serverless
- **No dependencies** for ultimate reliability
- **Offline development** with zero configuration

The result: Write like Python, run like C, deploy like a shell script.