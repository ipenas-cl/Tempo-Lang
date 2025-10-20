╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 16: Gestión de Memoria Determinística

## Objetivos
- Implementar memory pools determinísticos
- Entender GC determinístico vs allocación manual
- Diseñar layouts de memoria predecibles

## Teoría: Memory Pools

En Chronos, la gestión de memoria debe ser completamente determinística. Esto significa:

1. **Sin malloc/free dinámicos** - tiempo de ejecución variable
2. **Memory pools** - bloques pre-asignados 
3. **Stack allocation** cuando sea posible
4. **Compile-time size checking**

## Implementación de Memory Pool

```tempo
struct MemoryPool<T> {
    data: [Option<T>; MAX_SIZE],
    free_list: [usize; MAX_SIZE],
    free_count: usize,
    high_water_mark: usize,
}

impl<T> MemoryPool<T> {
    fn new() -> Self {
        let mut pool = MemoryPool {
            data: [None; MAX_SIZE],
            free_list: [0; MAX_SIZE],
            free_count: MAX_SIZE,
            high_water_mark: 0,
        };
        
        // Initialize free list
        for i in 0..MAX_SIZE {
            pool.free_list[i] = i;
        }
        
        pool
    }
    
    fn allocate(&mut self) -> Result<PoolHandle, PoolError> {
        if self.free_count == 0 {
            return Err(PoolError::OutOfMemory);
        }
        
        let index = self.free_list[self.free_count - 1];
        self.free_count -= 1;
        
        self.high_water_mark = max(self.high_water_mark, MAX_SIZE - self.free_count);
        
        Ok(PoolHandle { index, generation: 0 })
    }
    
    fn deallocate(&mut self, handle: PoolHandle) -> Result<(), PoolError> {
        if handle.index >= MAX_SIZE {
            return Err(PoolError::InvalidHandle);
        }
        
        self.data[handle.index] = None;
        self.free_list[self.free_count] = handle.index;
        self.free_count += 1;
        
        Ok(())
    }
    
    fn get(&self, handle: PoolHandle) -> Option<&T> {
        if handle.index >= MAX_SIZE {
            return None;
        }
        
        self.data[handle.index].as_ref()
    }
    
    fn get_mut(&mut self, handle: PoolHandle) -> Option<&mut T> {
        if handle.index >= MAX_SIZE {
            return None;
        }
        
        self.data[handle.index].as_mut()
    }
}

struct PoolHandle {
    index: usize,
    generation: u32,
}

enum PoolError {
    OutOfMemory,
    InvalidHandle,
}
```

## Region-Based Memory Management

```tempo
struct Region {
    data: [u8; REGION_SIZE],
    offset: usize,
    high_water: usize,
}

impl Region {
    fn alloc<T>(&mut self, value: T) -> Result<&mut T, RegionError> {
        let size = size_of::<T>();
        let align = align_of::<T>();
        
        // Align offset
        let aligned_offset = (self.offset + align - 1) & !(align - 1);
        
        if aligned_offset + size > REGION_SIZE {
            return Err(RegionError::OutOfSpace);
        }
        
        // SAFETY: We checked bounds above
        let ptr = unsafe { 
            self.data.as_mut_ptr().add(aligned_offset) as *mut T 
        };
        
        unsafe { ptr.write(value); }
        
        self.offset = aligned_offset + size;
        self.high_water = max(self.high_water, self.offset);
        
        Ok(unsafe { &mut *ptr })
    }
    
    fn reset(&mut self) {
        self.offset = 0;
        // Note: We keep high_water for analysis
    }
    
    fn capacity_used(&self) -> f32 {
        self.high_water as f32 / REGION_SIZE as f32
    }
}
```

## Stack Allocation Prioritization

```tempo
// Compiler analiza y prioriza stack allocation
fn process_items(items: [Item; N]) -> [Result; N] {
    // Stack allocation - tamaño conocido en compile time
    let mut results: [Result; N] = [Result::default(); N];
    
    for i in 0..N {
        results[i] = process_item(&items[i]);
    }
    
    results
}

// En lugar de:
fn process_items_dynamic(items: Vec<Item>) -> Vec<Result> {
    // Heap allocation - no determinístico
    let mut results = Vec::new();
    for item in items {
        results.push(process_item(&item));
    }
    results
}
```

## WCET Analysis para Memory Operations

```tempo
fn memory_operation_wcet() -> u32 {
    // Pool allocation: O(1) bounded
    let handle = GLOBAL_POOL.allocate(); // WCET: 5 cycles
    
    // Stack allocation: O(1) 
    let local_array = [0u32; 100]; // WCET: 0 cycles (compile time)
    
    // Memory access: Cache-aware
    let value = local_array[index]; // WCET: L1=1, L2=10, L3=50, DRAM=200 cycles
    
    // Total WCET calculable
    return 5 + 200; // Worst case
}
```

## Garbage Collection Determinístico

```tempo
struct DeterministicGC {
    mark_bits: [u8; HEAP_SIZE / 8],
    sweep_position: usize,
    max_sweep_per_cycle: usize,
}

impl DeterministicGC {
    fn incremental_collect(&mut self, max_cycles: u32) -> CollectionStats {
        let start_time = rdtsc();
        let mut objects_freed = 0;
        
        while rdtsc() - start_time < max_cycles && 
              self.sweep_position < HEAP_SIZE {
            
            if !self.is_marked(self.sweep_position) {
                self.free_object(self.sweep_position);
                objects_freed += 1;
            }
            
            self.sweep_position += OBJECT_SIZE;
        }
        
        CollectionStats { 
            objects_freed,
            cycles_used: rdtsc() - start_time,
            progress: self.sweep_position as f32 / HEAP_SIZE as f32,
        }
    }
}
```

## Análisis de Memoria en Compile Time

```tempo
// Compiler realiza análisis estático
#[memory_analysis]
fn complex_function() {
    // Análisis automático:
    // - Stack usage: 2KB
    // - Pool allocations: 5 max
    // - Memory lifetime: local scope
    // - WCET memory cost: 1000 cycles worst case
    
    let buffer: [u8; 1024] = [0; 1024];     // Stack: 1KB
    let another: [u32; 256] = [0; 256];     // Stack: 1KB
    
    let handle1 = pool.allocate();          // Pool: 1 object
    let handle2 = pool.allocate();          // Pool: 2 objects
    
    // Compiler garantiza cleanup automático al salir del scope
}
```

## Práctica: Implementar Memory Pool para Red-Black Tree

Implementa un memory pool específico para nodos de Red-Black Tree que:

1. Pre-asigne 1000 nodos
2. Tenga O(1) allocation/deallocation
3. Mantenga estadísticas de uso
4. Detecte memory leaks en compile time

```tempo
struct RBNode {
    key: u64,
    value: u64,
    color: Color,
    left: Option<NodeHandle>,
    right: Option<NodeHandle>,
    parent: Option<NodeHandle>,
}

struct RBTreePool {
    // Tu implementación aquí
}
```

## Verificación de Seguridad

```tempo
// Chronos verifica automáticamente:
fn memory_safety_check() {
    let handle = pool.allocate().unwrap();
    
    // ✓ Uso válido
    pool.get(handle).unwrap().modify();
    
    pool.deallocate(handle);
    
    // ✗ Error de compilación - use after free
    // pool.get(handle); // COMPILE ERROR
    
    // ✗ Error de compilación - double free  
    // pool.deallocate(handle); // COMPILE ERROR
}
```

## Ejercicio Final

Diseña un sistema de memoria para un servidor HTTP que:

1. Use memory pools para requests/responses
2. Tenga bounded memory usage
3. Garantice cleanup automático
4. Proporcione métricas determinísticas

**Próxima lección**: Concurrencia Determinística y CSP