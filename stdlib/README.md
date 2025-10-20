# Chronos Standard Library

Core data types, collections, and system interfaces for Chronos applications.

## Structure

- `core/` - Fundamental types (strings, bytes, time, sync)
- `collections/` - Data structures (vectors, maps, sets)
- `system/` - System interfaces (CPU, platform, hardware)

## Philosophy

- **Zero Dependencies**: No external libraries
- **WCET Annotated**: All functions have worst-case execution time
- **Memory Safe**: No manual memory management
- **Performance**: Optimized for real-time systems

## Usage

```tempo
import std.core.strings
import std.collections.vector
import std.system.platform
```
