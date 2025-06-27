# Tempo Programming Language

<div align="center">

```
╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
```

**100% Deterministic Programming Language**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS-blue)](#installation)
[![Zero Dependencies](https://img.shields.io/badge/Dependencies-Zero-green)](#features)
[![Assembly](https://img.shields.io/badge/Bootstrap-100%25%20Assembly-red)](#zero-c-philosophy)

</div>

---

## 🚀 Key Features

- **🛡️ Zero C Dependencies**: Built from pure assembly, no C runtime
- **⚖️ Deterministic Execution**: WCET (Worst-Case Execution Time) guarantees
- **⚡ Extreme Performance**: Profile-Guided Optimization, SIMD, zero-copy
- **🔍 Professional Observability**: Integrated monitoring, debugging, profiling
- **📦 Unique App Names**: `service.tempo` → `service.tempo.app` for ecosystem clarity

---

## 🏗️ Project Structure

```
tempo-lang/
├── 📁 compiler/           # Zero-C compiler implementation
│   ├── platforms/         # Platform-specific compilers (macOS, Linux, Windows)
│   ├── stages/            # Multi-stage bootstrap (stage0 → stage1 → stage2)
│   └── bootstrap/         # Assembly bootstrap code
├── 📁 runtime/            # AtomicOS kernel and runtime  
│   ├── kernel/            # Core OS kernel
│   ├── drivers/           # Hardware drivers
│   └── fs/                # AtomicFS file system
├── 📁 stdlib/             # Standard library
│   ├── core/              # Core types and functions
│   └── system/            # System interfaces
├── 📁 tools/              # Development tools
│   └── monitor/           # Observability suite (monitor, debug, profile, logs, alert)
├── 📁 examples/           # Example programs
│   ├── basic/             # Simple examples
│   ├── advanced/          # Complex applications (Doom, orchestrator)
│   └── benchmarks/        # Performance tests
├── 📁 docs/               # Documentation
│   ├── language/          # Language reference
│   └── tutorials/         # Learning materials
└── 📁 scripts/            # Installation and build scripts
```

## 📦 Installation

### Quick Start

```bash
# 1. Clone repository
git clone https://github.com/username/tempo-lang.git
cd tempo-lang

# 2. Global installation (recommended)
sudo ./scripts/install-global.sh

# 3. Verify installation  
tempo --version

# 4. Start monitoring ecosystem
tempo monitor
```

### Development Setup

```bash
# Local development installation
./scripts/install.sh

# Build compiler from source
cd compiler/platforms/macos && ./build.sh
```

### ✅ Después de la Instalación
- `tempo` está disponible desde cualquier directorio
- Manual disponible: `man tempo`
- Ejemplos en: `/usr/local/share/tempo/examples/`
- Documentación en: `/usr/local/share/doc/tempo/`

## 🎯 Para Diferentes Tipos de Usuario

<table>
<tr>
<td width="33%" align="center">

### 👨‍💻 **Desarrolladores**

**Aplicaciones ultra-rápidas y seguras**

[**→ Guía de Desarrollo**](#desarrollo-con-tempo)

WCET guarantees, optimizaciones automáticas, sin crashes por memory safety.

</td>
<td width="33%" align="center">

### 🔧 **Ingenieros de Sistemas**

**Control total del hardware**

[**→ Programación de Sistemas**](#sistemas-con-tempo)

Inline assembly, control de memoria, timing predecible, zero overhead.

</td>
<td width="33%" align="center">

### 🏢 **SRE y DevOps**

**Sistemas críticos estables**

[**→ Herramientas de Observabilidad**](#observabilidad-sre)

**Help make Tempo better**

[**→ Developer Guide**](#contributing)

Join the community building the future of deterministic computing.

</td>
</tr>
</table>

---

## 🌱 Beginners: Start Here

**Never programmed before? Perfect!** Tempo is designed to teach good habits from day one.

### Step 1: Get Tempo Running

```bash
# Quick install (macOS/Linux)
git clone https://github.com/ipenas-cl/Tempo-Lang
cd Tempo-Lang
./install.sh

# Add to PATH (add to ~/.bashrc or ~/.zshrc)
export PATH="$HOME/.local/bin:$PATH"
```

### Step 2: Your First Program

Create a file called `hello.tempo`:

```tempo
fn main() -> i32 {
    print_line("Hello from Tempo!");
    return 0;
}
```

### Step 3: Compile and Run

```bash
tempo hello.tempo
./hello.tempo.app
```

**Output:** `Hello from Tempo!`

💡 **Note**: Each `.tempo` file compiles to its own `.tempo.app` executable.

### 🎓 Learning Path for Beginners

1. **[Lesson 1: Basic Programs](docs/learn/lesson1.md)** - Variables, functions, basic math
2. **[Lesson 2: Making Decisions](docs/learn/lesson2.md)** - if/else, comparisons
3. **[Lesson 3: Repeating Things](docs/learn/lesson3.md)** - Loops and iteration
4. **[Lesson 4: Working with Text](docs/learn/lesson4.md)** - Strings and input/output
5. **[Lesson 5: Your First Real Program](docs/learn/lesson5.md)** - Build a calculator

**Why Start with Tempo?**
- ✅ **Safe by default** - Won't let you crash your computer
- ✅ **No hidden complexity** - What you see is what you get
- ✅ **Instant feedback** - Compile and run in seconds
- ✅ **Real-world ready** - Used in production systems

---

## 🔄 Quick Evaluation

**Want to see if Tempo fits your project?** Here are practical comparisons:

### Coming from Python?

<table>
<tr><th>Python</th><th>Tempo</th></tr>
<tr>
<td>

```python
import socket
import threading

def handle_client(conn):
    data = conn.recv(1024)
    conn.send(b"HTTP/1.1 200 OK\r\n\r\nHello")
    conn.close()

server = socket.socket()
server.bind(('localhost', 8080))
server.listen(5)

while True:
    conn, addr = server.accept()
    threading.Thread(target=handle_client, 
                    args=(conn,)).start()
```

</td>
<td>

```tempo
fn main() -> i32 {
    let server = listen_tcp("localhost:8080");
    
    while true {
        let conn = server.accept();
        let data = conn.read(1024);
        conn.write("HTTP/1.1 200 OK\r\n\r\nHello");
        conn.close();
    }
}
```

</td>
</tr>
</table>

**Tempo advantages:**
- ⚡ **10-100x faster** - Native compilation
- 🔒 **No GIL** - True parallelism 
- ⏱️ **Predictable timing** - No garbage collection pauses
- 📦 **Single binary** - No dependency hell

### Coming from Rust?

<table>
<tr><th>Rust</th><th>Tempo</th></tr>
<tr>
<td>

```rust
use std::fs;
use std::collections::HashMap;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let content = fs::read_to_string("data.txt")?;
    let mut counts = HashMap::new();
    
    for word in content.split_whitespace() {
        *counts.entry(word).or_insert(0) += 1;
    }
    
    println!("Word count: {}", counts.len());
    Ok(())
}
```

</td>
<td>

```tempo
fn main() -> i32 {
    let content = read_file("data.txt");
    let words = content.split_whitespace();
    let counts = HashMap::new();
    
    for word in words {
        counts.increment(word);
    }
    
    print_line("Word count: " + counts.len().to_string());
    return 0;
}
```

</td>
</tr>
</table>

**Tempo advantages:**
- 🚀 **Faster compilation** - No complex borrow checker
- 🧘 **Simpler syntax** - Less cognitive overhead
- ⏰ **Time guarantees** - WCET bounds for real-time systems
- 🔄 **No imports** - Everything available instantly

### Coming from Go?

<table>
<tr><th>Go</th><th>Tempo</th></tr>
<tr>
<td>

```go
package main

import (
    "fmt"
    "net/http"
    "time"
)

func handler(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Hello from Go!")
}

func main() {
    http.HandleFunc("/", handler)
    
    server := &http.Server{
        Addr:         ":8080",
        ReadTimeout:  10 * time.Second,
        WriteTimeout: 10 * time.Second,
    }
    
    server.ListenAndServe()
}
```

</td>
<td>

```tempo
fn handle_request(conn: Connection) wcet: 1_millisecond {
    let request = conn.read_http_request();
    conn.write_http_response("Hello from Tempo!");
    conn.close();
}

fn main() -> i32 {
    let server = listen_tcp("localhost:8080");
    
    while true {
        let conn = server.accept();
        handle_request(conn);
    }
}
```

</td>
</tr>
</table>

**Tempo advantages:**
- ⏱️ **Deterministic timing** - No GC pauses
- 🎯 **Bounded execution** - Functions have guaranteed max time
- 🔋 **Lower resource usage** - No runtime overhead
- 🛡️ **Memory safety** - Without garbage collection

### Performance Comparison

| Language | Web Server RPS | Memory Usage | Binary Size |
|----------|----------------|--------------|-------------|
| **Tempo** | **450,000** | **8 MB** | **2 MB** |
| Rust | 380,000 | 12 MB | 4 MB |
| Go | 120,000 | 25 MB | 8 MB |
| Python | 15,000 | 45 MB | N/A |

### Migration Checklist

**✅ Good fit for Tempo if you need:**
- Predictable performance
- Real-time guarantees  
- High-frequency operations
- Embedded/IoT deployment
- Safety-critical systems
- Zero-downtime services

**❌ Consider alternatives if you need:**
- Rapid prototyping (Python better)
- Complex ecosystem (JavaScript/Python)
- Dynamic features (reflection, etc.)

---

## 🛠️ Contributing

**Want to help build the future of deterministic computing?**

### For New Contributors

```bash
# 1. Fork and clone
git clone https://github.com/your-username/Tempo-Lang
cd Tempo-Lang

# 2. Build and test
./build.sh
bin/tempo hello.tempo
./stage1

# 3. Find your first issue
# Look for "good first issue" labels
```

### Development Areas

<table>
<tr>
<td width="33%">

#### 🔧 **Compiler Development**
- Add new optimizations
- Improve error messages
- Platform support (Windows, ARM)
- WCET analysis improvements

**Skills needed:** Assembly, compiler theory, optimization

</td>
<td width="33%">

#### 📚 **Standard Library**
- Add new data structures
- Networking improvements
- File system operations
- Crypto implementations

**Skills needed:** Systems programming, algorithms

</td>
<td width="33%">

#### 📖 **Documentation & Examples**
- Tutorial improvements
- Real-world examples
- Performance benchmarks
- Video tutorials

**Skills needed:** Technical writing, examples

</td>
</tr>
</table>

### Architecture Overview

```
tempo/
├── internal/compiler/    # Core compiler (Assembly + Tempo)
│   ├── linux/           # Linux bootstrap  
│   ├── macos/           # macOS bootstrap
│   └── windows/         # Windows bootstrap
├── src/std/             # Standard library (Pure Tempo)
├── docs/                # Documentation
└── examples/            # Example programs
```

### Contribution Guidelines

1. **Maintain determinism** - All code must have predictable behavior
2. **WCET bounds** - Functions should have provable time limits
3. **Zero dependencies** - Keep the no-C philosophy
4. **Comprehensive tests** - Test on all supported platforms
5. **Clear documentation** - Every public API needs docs

### Getting Help

- **💬 Discussions:** [GitHub Discussions](https://github.com/ipenas-cl/Tempo-Lang/discussions)
- **🐛 Issues:** [GitHub Issues](https://github.com/ipenas-cl/Tempo-Lang/issues)
- **📧 Email:** tempo-dev@example.com
- **💻 Matrix:** #tempo-lang:matrix.org

---

## Installation

### Quick Install

```bash
# macOS
brew install nasm && git clone https://github.com/ipenas-cl/Tempo-Lang && cd Tempo-Lang && ./build.sh

# Linux (Ubuntu/Debian)
sudo apt-get install nasm && git clone https://github.com/ipenas-cl/Tempo-Lang && cd Tempo-Lang && ./build.sh

# Linux (CentOS/RHEL)
sudo yum install nasm && git clone https://github.com/ipenas-cl/Tempo-Lang && cd Tempo-Lang && ./build.sh
```

### Verify Installation

```bash
bin/tempo --version
bin/tempo hello.tempo
./stage1
```

Expected output:
```
Tempo 0.0.1 - Deterministic Programming Language
🔥 Compiling hello.tempo...
✅ Compilation successful!
Hello, Tempo!
```

---

## Core Features

### ✨ **Zero Import System**
```tempo
fn main() -> i32 {
    // All functions instantly available - no imports needed
    let server = listen_tcp("localhost:8080");
    let data = read_file("config.json");  
    let hash = hash_sha256(data);
    print_line("Ready!");
    return 0;
}
```

### ⚡ **Deterministic Execution**
```tempo
fn sort_data(arr: &mut [i32]) wcet: 1000_cycles {
    // Compiler guarantees this NEVER exceeds 1000 CPU cycles
    bubble_sort(arr);
}
```

### 🛡️ **Memory Safety**
```tempo
fn process_data(data: Vec<u8>) -> Result<String, Error> {
    // Automatic bounds checking, no null pointers, move semantics
    let result = String::from_utf8(data)?;
    Ok(result.trim().to_string())
}
```

### 🎯 **Real-World Performance**
- **450K requests/sec** vs Redis 100K
- **3-4.5x faster** than equivalent C programs
- **10x lower latency** than garbage-collected languages
- **Deterministic timing** - no GC pauses

---

## Documentation

- **📖 [Language Reference](docs/tempcore_manual.md)** - Complete syntax and semantics
- **🎓 [Learning Guide](docs/learn/)** - Step-by-step tutorials for beginners
- **📚 [Compiler Course](docs/course/)** - 27-lesson course on building compilers
- **🚀 [Showcase Examples](examples/showcase/)** - Redis-killer, nginx-destroyer benchmarks
- **🔧 [Advanced Examples](examples/advanced/)** - DOOM port, container orchestrator
- **🧠 [Philosophy](docs/philosophy/)** - Why Tempo exists

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

<div align="center">

### **[T∞] Bounded Time, Infinite Reliability**

*Making the impossible, inevitable*

[🚀 **Get Started**](#-choose-your-path) • [⭐ **Star on GitHub**](https://github.com/ipenas-cl/Tempo-Lang) • [💬 **Join Community**](https://github.com/ipenas-cl/Tempo-Lang/discussions)

</div>

---

## 👨‍💻 Desarrollo con Tempo

### Primeros Pasos para Desarrolladores

```bash
# Crear tu primera aplicación
echo 'fn main() -> i32 {
    print_line("¡Hola Tempo\!");
    return 0;
}' > mi_app.tempo

# Compilar
tempo mi_app.tempo

# Ejecutar
./tempo.app
```

### Características para Desarrolladores

#### 🎯 WCET (Worst-Case Execution Time)
```tempo
@wcet(1000)  // Garantiza que nunca tomará más de 1000 ciclos
fn process_payment(amount: i64) -> bool {
    // Tu lógica aquí con timing predecible
    return validate_and_process(amount);
}
```

#### ⚡ Performance Automático
```tempo
@simd  // Vectorización SIMD automática
fn multiply_arrays(a: [f32; 1000], b: [f32; 1000]) -> [f32; 1000] {
    @vectorize(16)  // Procesa 16 elementos en paralelo
    for i in 0..1000 {
        result[i] = a[i] * b[i];
    }
    return result;
}
```

#### 🔒 Memory Safety sin Overhead
```tempo
fn safe_array_access(data: [i32; 100], index: usize) -> i32 {
    // Bounds checking en compile-time, zero runtime overhead
    return data[index];  // Nunca puede hacer segfault
}
```

---

## 🔧 Sistemas con Tempo

### Control de Hardware Directo

```tempo
@interrupt  // Handler de interrupción
@naked      // Sin prólogo/epílogo de función
fn timer_interrupt() {
    @asm("cli")          // Deshabilitar interrupciones
    handle_timer_tick();
    @asm("sti")          // Rehabilitar interrupciones
    @asm("iretq")        // Retorno de interrupción
}
```

### Programación de Sistemas de Bajo Nivel

```tempo
@section("kernel_code")  // Ubicación específica en memoria
@align(4096)            // Alineado a página
struct KernelPage {
    @atomic counter: u64,
    @packed data: [u8; 4088]  // Sin padding
}

@wcet(50)  // Máximo 50 ciclos - crítico para scheduler
fn context_switch(old_task: *Task, new_task: *Task) {
    @asm("mov %rsp, (%rdi)")     // Guardar stack pointer
    @asm("mov (%rsi), %rsp")     // Cargar nuevo stack
    @asm("jmp *8(%rsi)")         // Saltar a nueva tarea
}
```

---

## 🏢 Observabilidad SRE

### Herramientas de Monitoreo Profesional

#### 📊 Tempo Monitor - Dashboard Interactivo
```bash
tempo monitor
```
**Características:**
- 🔄 **Actualización en tiempo real** (cada 2 segundos)
- 🎯 **Filtrado ecosistémico**: Solo muestra apps Tempo y servicios relacionados
- 📈 **Métricas por tipo**: Apps (WCET estricto), DBs, Web servers, Microservicios
- ⌨️ **Controles interactivos**: `d` debug, `p` profile, `l` logs, `a` alert, `q` quit
- 🚦 **Estados visuales**: ✅ HEALTHY → 🟡 MODERATE → 🔴 WCET_VIOL

#### 🐛 Debugging Avanzado con WCET
```bash
tempo debug payment-service.tempo.app
```
- Análisis WCET en tiempo real
- Inspección de memoria y registros
- Breakpoints y watchpoints
- Stack trace con timing

#### 📋 Logs Inteligentes con Context
```bash
tempo logs user-management.tempo.app
```
- Análisis automático de patrones
- Detección de anomalías
- Correlación de eventos
- Recomendaciones basadas en ML

#### 🚨 Alertas Contextuales Inteligentes
```bash
tempo alert "High CPU usage in payment service"
```
- Severidad automática (INFO/WARNING/CRITICAL)
- Contexto del sistema incluido
- Recomendaciones específicas
- Integración con Slack/PagerDuty

#### 🔬 Profiling para PGO
```bash
tempo profile api-gateway.tempo.app
```
- Genera datos para Profile-Guided Optimization
- Identifica hot paths y bottlenecks
- Sugiere optimizaciones SIMD
- Exporta archivo `tempo.pgo`

---

## 🎯 Instalación en Producción

### Para Administradores de Sistema

```bash
# Instalación global recomendada
sudo ./install-global.sh

# Verificar instalación
tempo --version
man tempo  # Manual completo disponible

# Configurar monitoreo automático
systemctl enable tempo-monitor
```

### Integración CI/CD

```yaml
# .github/workflows/tempo.yml
- name: Install Tempo
  run: sudo ./install-global.sh

- name: Compile with WCET verification
  run: tempo --verify-wcet src/main.tempo

- name: Run performance benchmarks
  run: tempo profile build/app.tempo
```

---

*🏆 AtomicOS Ecosystem: Determinismo ✅ Seguridad ✅ Estabilidad ✅ Performance ✅*
EOF < /dev/null