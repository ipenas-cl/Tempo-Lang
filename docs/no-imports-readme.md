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

# Tempo: Zero Imports, Zero Dependencies, 100% Offline

## Quick Start

```tempo
// No imports needed - just write code!
func main() {
    println("Hello from Tempo!")
    
    // Everything is available immediately:
    let server = listen_tcp("0.0.0.0:8080").unwrap()
    let start_time = now()
    let hash = hash_fnv1a_string("my data")
    
    println("Server started in", time_since(start_time))
}
```

## The Revolutionary Approach

Tempo eliminates the concept of imports entirely. Every standard library function is available in every file through the compiler's built-in prelude. This means:

- ✅ **Write code anywhere** - No internet needed
- ✅ **Zero configuration** - No package.json, Cargo.toml, or go.mod
- ✅ **Instant productivity** - No time wasted on imports
- ✅ **Perfect reproducibility** - Same code, same binary, forever
- ✅ **No supply chain attacks** - No external dependencies

## How It Works

### 1. The Prelude System

Every Tempo program automatically includes `prelude.tempo`:

```tempo
// Automatically available - no imports needed:
- Core types: Vec, HashMap, Option, Result
- I/O: println, format, read, write
- Network: TCPListener, TCPConn, listen_tcp, dial_tcp
- Concurrency: Mutex, RWMutex, go, Channel
- Time: now, sleep, Duration
- Math: sin, cos, sqrt, min, max
- Strings: split, trim, parse, to_uppercase
- And 200+ more functions...
```

### 2. Compile-Time Tree Shaking

The compiler only includes what you actually use:

```bash
# Hello World: ~48KB binary (only includes println + deps)
tempo build hello.tempo

# TCP Server: ~156KB binary (includes networking)
tempo build server.tempo

# Full Redis Clone: ~245KB binary (includes everything needed)
tempo build redis-killer.tempo
```

### 3. Example: Building Redis Without Imports

```tempo
// redis-killer.tempo - No imports!
func main() {
    let server = Server{
        db: Database::new(),
        clients: [Client{}; MAX_CLIENTS],
    }
    server.listen("0.0.0.0:6379")
}

impl Server {
    func listen(addr: string) {
        // listen_tcp is built-in, no import needed
        self.listener = listen_tcp(addr).unwrap()
        println("Redis Killer listening on", addr)
        
        while self.running {
            // All networking is built-in
            let conn = self.listener.accept().unwrap()
            go self.handle_client(conn)  // go is built-in too!
        }
    }
}
```

## Tree-Shaking in Action

The compiler analyzes your code and includes only what's needed:

```
Your Code:                 Included:           Excluded:
println("Hello")     →     println             listen_tcp
                          format              HashMap
                          write_stdout        sin/cos
                          strlen              Time/Duration
                          memcpy              200+ others

Result: 48KB binary instead of 2.5MB!
```

## Comparison

| Feature | Traditional Languages | Tempo |
|---------|---------------------|--------|
| Write "Hello World" | Need to know imports | Just `println("Hello World!")` |
| Use networking | `import net` or `use std::net` | Just call `listen_tcp()` |
| Parse JSON | Install package, import | Built-in `parse_json()` |
| Offline development | Impossible | Perfect |
| Binary size | Bloated | Minimal |
| Dependency conflicts | Common | Impossible |

## Philosophy

> "In 2030, will npm still exist? Will crates.io be online? Will your dependencies resolve? With Tempo, these questions don't matter. Your code will compile and run exactly the same way, forever."

## Use Cases

### 1. Embedded Systems
```tempo
// Fits in 32KB of flash!
func main() {
    let sensor_value = read_adc(PIN_A0)
    if sensor_value > THRESHOLD {
        gpio_write(LED_PIN, HIGH)
    }
}
```

### 2. Serverless Functions
```tempo
// 5ms cold starts!
func handler(req: Request) -> Response {
    let data = parse_json(req.body).unwrap()
    Response{
        status: 200,
        body: format!("Hello, {}!", data["name"])
    }
}
```

### 3. System Utilities
```tempo
// Single-file programs that work forever
func main() {
    for arg in args() {
        let hash = hash_xxh64_string(arg, 0)
        println(arg, "->", u64_to_hex(hash))
    }
}
```

## Getting Started

1. **Install Tempo** (single binary, no dependencies)
   ```bash
   # Download from: https://github.com/ipenas-cl/Tempo-Lang/releases
   # Or build from source:
   git clone https://github.com/ipenas-cl/Tempo-Lang
   cd Tempo-Lang && ./build.sh
   ```

2. **Write code** (no project setup needed)
   ```bash
   echo 'func main() { println("Hello!") }' > hello.tempo
   ```

3. **Compile and run**
   ```bash
   tempo run hello.tempo
   ```

## Advanced Features

### See What's Included
```bash
tempo build --show-tree-shaking myapp.tempo
```

### Visualize Dependencies
```bash
tempo build --call-graph myapp.tempo | dot -Tpng > graph.png
```

### Compare Binary Sizes
```bash
# With tree-shaking (default)
tempo build myapp.tempo -o myapp-optimized

# Without tree-shaking (includes everything)
tempo build --no-tree-shaking myapp.tempo -o myapp-full

ls -lh myapp-*
```

## Examples

Check out these examples that work without any imports:

- [Redis Killer](../redis-killer-no-imports.tempo) - Full Redis-compatible server
- [Tree Shaking Demo](../examples/tree_shaking_demo.tempo) - See optimization in action
- [TCP Echo Server](../examples/echo-server.tempo) - Network programming made simple
- [Calculator](../examples/calculator.tempo) - Math without imports

## FAQ

**Q: What about third-party libraries?**
A: Vendor them - copy the code into your project. Your code remains self-contained forever.

**Q: How do I organize large projects?**
A: Use modules within your project. The no-import philosophy applies to the standard library.

**Q: Doesn't this make the compiler huge?**
A: The prelude is just declarations. Tree-shaking ensures only used code ends up in your binary.

**Q: What if I need a function that's not in the prelude?**
A: Write it! Tempo encourages self-contained, maintainable code.

## Join the Revolution

Tired of dependency hell? Sick of broken builds? Want to write code that works forever?

**Welcome to Tempo - where your code depends on nothing and runs everywhere.**

---

*"The best dependency is no dependency."* - The Tempo Philosophy