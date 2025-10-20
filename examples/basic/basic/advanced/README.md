# Advanced Chronos Examples

These examples are for contributors and advanced users who want to understand Chronos's full capabilities.

## 🎮 DOOM Port

A complete port of the classic DOOM game, demonstrating:
- Deterministic game engine (reproducible demos)
- Real-time rendering with guaranteed frame times
- Network multiplayer with tick-perfect synchronization
- Zero garbage collection pauses

### Architecture:
```
doom/
├── main.tempo           # Entry point and game loop
├── renderer.tempo       # Software renderer
├── game_logic.tempo     # Game state and physics
├── wad_loader.tempo     # WAD file parser
├── audio.tempo          # Sound system
└── network.tempo        # Multiplayer support
```

### Key Features:
- Fixed 35Hz game logic (like original DOOM)
- Deterministic RNG for demo playback
- Memory-safe implementation
- Runs on AtomicOS

## 🐳 AtomicOrchestrator

A deterministic container orchestrator (like Kubernetes) with real-time guarantees:

### Features:
- **Bounded scheduling time**: Maximum 10ms to schedule any pod
- **Resource guarantees**: Hard limits on CPU, memory, network
- **Fault tolerance**: Automatic failover with bounded recovery time
- **Network policies**: Deterministic packet routing

### Architecture:
```
orchestrator/
├── atomicorchestrator.tempo  # Main orchestrator logic
├── scheduler.tempo           # Pod scheduling algorithm
├── container.tempo           # Container management
├── network_policy.tempo      # Network isolation
└── storage.tempo             # Persistent volume management
```

### Use Cases:
- Real-time workloads requiring guaranteed scheduling
- IoT edge computing with resource constraints
- Financial systems needing predictable performance
- Safety-critical container workloads

## Building and Running

All examples follow the same pattern:

```bash
# Compile
bin/tempo examples/advanced/<example>/main.tempo

# Run
./stage1
```

## Contributing

These examples serve as reference implementations. When contributing:

1. **Maintain determinism**: All code paths must have bounded execution time
2. **Document WCET**: Add timing annotations where appropriate
3. **Test thoroughly**: Include edge cases and error conditions
4. **Follow patterns**: Study existing code for style and conventions

## Learning Path

1. Start with the DOOM renderer to understand graphics programming in Chronos
2. Study the orchestrator's scheduler for concurrent programming patterns
3. Examine network code for high-performance I/O techniques

## Performance Notes

These applications achieve their performance through:
- **No heap allocation** in hot paths
- **Data structure reuse** instead of allocation/deallocation
- **Compile-time optimizations** from Chronos's WCET analysis
- **Direct hardware access** where needed

## Platform Support

- **DOOM**: Runs on Linux, macOS, AtomicOS
- **AtomicOrchestrator**: Requires AtomicOS for full features

Both demonstrate how Chronos enables systems programming without sacrificing safety or predictability.