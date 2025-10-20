# Chronos Project Structure

## Root Directory Structure

```
tempo-lang/
├── 📁 compiler/           # Chronos compiler implementation
│   ├── bootstrap/         # Bootstrap assembly code
│   ├── stages/           # Multi-stage compilation
│   └── platforms/        # Platform-specific code
├── 📁 runtime/           # AtomicOS kernel and runtime
│   ├── kernel/           # OS kernel implementation
│   ├── drivers/          # Hardware drivers
│   ├── fs/              # File system
│   └── net/             # Network stack
├── 📁 stdlib/            # Chronos standard library
│   ├── core/            # Core data types
│   ├── collections/     # Data structures
│   └── system/          # System interfaces
├── 📁 tools/             # Development tools
│   ├── monitor/         # Observability tools
│   ├── debugger/        # Debugging tools
│   └── profiler/        # Performance tools
├── 📁 examples/          # Example programs
│   ├── basic/           # Simple examples
│   ├── advanced/        # Complex applications
│   └── benchmarks/      # Performance benchmarks
├── 📁 docs/              # Documentation
│   ├── language/        # Language reference
│   ├── tutorials/       # Learning materials
│   └── api/             # API documentation
├── 📁 build/             # Build outputs and artifacts
├── 📁 scripts/           # Build and utility scripts
└── 📁 legacy/            # Legacy code (archived)
```

## Organization Principles

1. **Clear separation** - Each directory has a single responsibility
2. **Consistent naming** - Lower case, descriptive names
3. **Logical grouping** - Related functionality together
4. **Build separation** - Build artifacts separate from source
5. **Legacy isolation** - Old code archived but preserved