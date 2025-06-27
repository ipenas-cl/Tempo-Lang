╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 12: Análisis WCET - Worst-case execution time analysis

## Objetivos de la Lección
- Comprender la importancia del análisis WCET en sistemas críticos
- Implementar análisis estático de tiempo de ejecución
- Desarrollar técnicas de análisis de flujo y cache
- Garantizar tiempos de respuesta predecibles en Tempo

## 1. Teoría (20%)

### ¿Qué es WCET?

El Worst-Case Execution Time (WCET) es el tiempo máximo que puede tardar un programa en ejecutarse. Es crucial para:

1. **Sistemas de tiempo real**: Garantizar deadlines
2. **Sistemas embebidos**: Predecir consumo de recursos
3. **Sistemas críticos**: Certificación y seguridad
4. **Optimización**: Identificar hot paths

### Componentes del Análisis WCET

```tempo
WCET = Path Analysis + Low-Level Analysis + Cache Analysis + Pipeline Analysis
```

1. **Path Analysis**: Encontrar el camino más largo
2. **Low-Level Analysis**: Modelar la microarquitectura
3. **Cache Analysis**: Predecir hits/misses
4. **Pipeline Analysis**: Modelar hazards y stalls

### Técnicas de Análisis

1. **Medición**: Ejecutar y medir (no garantiza el peor caso)
2. **Análisis estático**: Analizar sin ejecutar (conservador pero seguro)
3. **Híbrido**: Combinar medición con análisis
4. **Probabilístico**: WCET estadístico

### Desafíos Modernos

- CPUs superescalares con predicción especulativa
- Jerarquías de cache complejas
- Efectos de interferencia en multicores
- Optimizaciones del compilador que afectan timing

## 2. Práctica (60%)

### Representación del CFG para WCET

```tempo
// wcet_analyzer.tempo - Análisis WCET para Tempo

struct WCETAnalyzer {
    cfg: *ControlFlowGraph,
    arch: *Architecture,
    cache_model: *CacheModel,
    pipeline_model: *PipelineModel,
    ilp_solver: *ILPSolver
}

struct BasicBlock {
    id: i32,
    instructions: *Instruction,
    inst_count: i32,
    
    // Información de timing
    local_wcet: i64,        // WCET local del bloque
    cache_states: *CacheState,
    pipeline_state: *PipelineState,
    
    // Información de flujo
    predecessors: **BasicBlock,
    pred_count: i32,
    successors: **BasicBlock,
    succ_count: i32,
    
    // Loop info
    loop_header: *BasicBlock,
    loop_bound: i32,
    is_loop_header: bool
}

struct Instruction {
    opcode: Opcode,
    operands: [3]Operand,
    address: u64,
    size: i32,
    
    // Timing info
    latency: i32,
    throughput: i32,
    memory_access: bool,
    branch: bool
}

struct ControlFlowGraph {
    entry: *BasicBlock,
    blocks: **BasicBlock,
    block_count: i32,
    edges: *CFGEdge,
    edge_count: i32
}

struct CFGEdge {
    from: *BasicBlock,
    to: *BasicBlock,
    taken: bool,        // Para branches condicionales
    frequency: i64      // Para profiling
}

// Construir CFG desde IR
fn build_cfg(function: *Function) -> *ControlFlowGraph {
    let cfg = alloc(sizeof(ControlFlowGraph));
    let builder = create_cfg_builder();
    
    // Crear bloques básicos
    let current_bb = create_basic_block(builder);
    cfg.entry = current_bb;
    
    let inst = function.instructions;
    while inst != 0 {
        if is_bb_terminator(inst) {
            add_instruction_to_bb(current_bb, inst);
            
            // Procesar terminador
            if inst.opcode == OP_BRANCH {
                let target = get_branch_target(inst);
                add_edge(builder, current_bb, target, true);
                
                if is_conditional_branch(inst) {
                    let fallthrough = get_next_bb(inst);
                    add_edge(builder, current_bb, fallthrough, false);
                }
            } else if inst.opcode == OP_RETURN {
                current_bb.successors = 0;
                current_bb.succ_count = 0;
            }
            
            // Nuevo bloque si hay más instrucciones
            if inst.next != 0 {
                current_bb = create_basic_block(builder);
            }
        } else {
            add_instruction_to_bb(current_bb, inst);
        }
        
        inst = inst.next;
    }
    
    finalize_cfg(builder, cfg);
    detect_loops(cfg);
    
    return cfg;
}

// Detectar loops y sus bounds
fn detect_loops(cfg: *ControlFlowGraph) {
    // Encontrar back edges usando DFS
    let visited = alloc(cfg.block_count * sizeof(bool));
    let on_stack = alloc(cfg.block_count * sizeof(bool));
    
    find_back_edges(cfg.entry, visited, on_stack, cfg);
    
    // Para cada back edge, identificar el loop
    let edge = cfg.edges;
    while edge != 0 {
        if is_back_edge(edge) {
            let header = edge.to;
            let tail = edge.from;
            
            header.is_loop_header = true;
            mark_loop_blocks(header, tail);
            
            // Intentar determinar loop bound
            header.loop_bound = analyze_loop_bound(header);
        }
        edge = edge.next;
    }
}

fn analyze_loop_bound(header: *BasicBlock) -> i32 {
    // Análisis simple de inducción
    let phi = find_induction_variable(header);
    if phi == 0 {
        return -1;  // Unbounded
    }
    
    let init = get_phi_init_value(phi);
    let update = get_phi_update(phi);
    let condition = find_loop_condition(header);
    
    if is_simple_counting_loop(init, update, condition) {
        return compute_iteration_count(init, update, condition);
    }
    
    // Si no podemos determinar, usar anotación o default conservador
    let annotation = get_loop_annotation(header);
    if annotation != 0 {
        return annotation.max_iterations;
    }
    
    return -1;  // Unbounded (conservador)
}
```

### Análisis de Timing de Instrucciones

```tempo
// Modelado de latencias de CPU

struct Architecture {
    name: *char,
    pipeline_depth: i32,
    issue_width: i32,
    
    // Unidades funcionales
    alu_units: i32,
    mul_units: i32,
    div_units: i32,
    load_units: i32,
    store_units: i32,
    branch_units: i32,
    
    // Latencias
    latencies: *LatencyTable,
    
    // Cache hierarchy
    l1i_cache: *CacheConfig,
    l1d_cache: *CacheConfig,
    l2_cache: *CacheConfig,
    l3_cache: *CacheConfig
}

struct LatencyTable {
    entries: *LatencyEntry,
    count: i32
}

struct LatencyEntry {
    opcode: Opcode,
    latency: i32,      // Ciclos hasta resultado disponible
    throughput: i32,   // Ciclos entre issues
    unit: FunctionalUnit,
    pipelined: bool
}

// Análisis local de un bloque básico
fn analyze_basic_block_timing(bb: *BasicBlock, arch: *Architecture) -> i64 {
    let scheduler = create_instruction_scheduler(arch);
    let cycle = 0;
    
    let i = 0;
    while i < bb.inst_count {
        let inst = bb.instructions[i];
        let latency = get_instruction_latency(arch, inst);
        
        // Modelar dependencias de datos
        let ready_cycle = compute_ready_cycle(scheduler, inst);
        
        // Modelar disponibilidad de unidades funcionales
        let issue_cycle = find_issue_slot(scheduler, inst, ready_cycle);
        
        // Actualizar estado del scheduler
        schedule_instruction(scheduler, inst, issue_cycle, latency);
        
        cycle = max(cycle, issue_cycle + latency.throughput);
        i = i + 1;
    }
    
    bb.local_wcet = cycle;
    return cycle;
}

// Análisis de cache
struct CacheModel {
    config: *CacheConfig,
    states: *CacheStateTable,
    persistence: *PersistenceAnalysis
}

struct CacheConfig {
    size: i32,
    line_size: i32,
    associativity: i32,
    replacement: ReplacementPolicy,
    latency_hit: i32,
    latency_miss: i32
}

struct CacheState {
    sets: **CacheSet,
    age: **i32,        // Abstract cache state (must/may analysis)
}

fn analyze_cache_behavior(bb: *BasicBlock, cache: *CacheModel) {
    let state = get_cache_state_at_entry(bb, cache);
    
    let i = 0;
    while i < bb.inst_count {
        let inst = bb.instructions[i];
        
        if inst.memory_access {
            let addr = get_memory_address(inst);
            let set = (addr / cache.config.line_size) % cache.config.sets;
            
            // Must analysis: ¿Seguro que está en cache?
            let must_hit = is_in_must_cache(state, addr);
            
            // May analysis: ¿Posible que esté en cache?  
            let may_hit = is_in_may_cache(state, addr);
            
            if must_hit {
                inst.cache_behavior = ALWAYS_HIT;
                inst.cache_penalty = cache.config.latency_hit;
            } else if !may_hit {
                inst.cache_behavior = ALWAYS_MISS;
                inst.cache_penalty = cache.config.latency_miss;
            } else {
                inst.cache_behavior = UNKNOWN;
                // Asumir miss para WCET
                inst.cache_penalty = cache.config.latency_miss;
            }
            
            // Actualizar abstract cache state
            update_cache_state(state, addr, cache.config);
        }
        
        i = i + 1;
    }
    
    bb.cache_states = state;
}

// Análisis de persistencia
fn analyze_persistence(cfg: *ControlFlowGraph, cache: *CacheModel) {
    // Identificar bloques de memoria que persisten en cache
    let persistence = alloc(sizeof(PersistenceAnalysis));
    
    let bb = cfg.blocks;
    let i = 0;
    while i < cfg.block_count {
        let accesses = collect_memory_accesses(bb[i]);
        
        let j = 0;
        while j < accesses.count {
            let addr = accesses.addresses[j];
            
            // ¿Esta dirección puede ser desalojada?
            if can_persist_in_cache(addr, bb[i], cache) {
                mark_persistent(persistence, addr, bb[i]);
            }
            
            j = j + 1;
        }
        i = i + 1;
    }
    
    cache.persistence = persistence;
}
```

### IPET (Implicit Path Enumeration Technique)

```tempo
// Formulación ILP para encontrar WCET

struct ILPProblem {
    variables: *ILPVariable,
    var_count: i32,
    constraints: *ILPConstraint,
    constraint_count: i32,
    objective: *ILPObjective
}

struct ILPVariable {
    name: *char,
    type: VarType,     // BINARY, INTEGER, CONTINUOUS
    lower_bound: f64,
    upper_bound: f64,
    coefficient: f64   // En función objetivo
}

fn build_ilp_problem(cfg: *ControlFlowGraph, analyzer: *WCETAnalyzer) -> *ILPProblem {
    let problem = alloc(sizeof(ILPProblem));
    
    // Variables: frecuencia de ejecución de cada bloque/edge
    create_block_variables(problem, cfg);
    create_edge_variables(problem, cfg);
    
    // Constraints estructurales (Kirchhoff)
    add_flow_constraints(problem, cfg);
    
    // Constraints de loops
    add_loop_constraints(problem, cfg);
    
    // Función objetivo: maximizar tiempo total
    set_objective_function(problem, cfg, analyzer);
    
    return problem;
}

fn create_block_variables(problem: *ILPProblem, cfg: *ControlFlowGraph) {
    let i = 0;
    while i < cfg.block_count {
        let bb = cfg.blocks[i];
        let var = create_ilp_variable("x_" + int_to_string(bb.id), INTEGER);
        var.lower_bound = 0;
        var.coefficient = bb.local_wcet;
        add_variable(problem, var);
        i = i + 1;
    }
}

fn add_flow_constraints(problem: *ILPProblem, cfg: *ControlFlowGraph) {
    // Para cada bloque: sum(in_edges) = sum(out_edges) = exec_count
    
    let i = 0;
    while i < cfg.block_count {
        let bb = cfg.blocks[i];
        
        // Constraint: sum(predecessors) = x_i
        let in_constraint = create_constraint(EQUAL);
        
        let j = 0;
        while j < bb.pred_count {
            let edge_var = get_edge_variable(bb.predecessors[j], bb);
            add_term(in_constraint, edge_var, 1.0);
            j = j + 1;
        }
        
        let block_var = get_block_variable(bb);
        add_term(in_constraint, block_var, -1.0);
        in_constraint.rhs = 0;
        
        add_constraint(problem, in_constraint);
        
        // Similar para successors
        add_outflow_constraint(problem, bb);
        
        i = i + 1;
    }
    
    // Entry constraint: x_entry = 1
    let entry_constraint = create_constraint(EQUAL);
    add_term(entry_constraint, get_block_variable(cfg.entry), 1.0);
    entry_constraint.rhs = 1;
    add_constraint(problem, entry_constraint);
}

fn add_loop_constraints(problem: *ILPProblem, cfg: *ControlFlowGraph) {
    let i = 0;
    while i < cfg.block_count {
        let bb = cfg.blocks[i];
        
        if bb.is_loop_header && bb.loop_bound > 0 {
            // x_header <= loop_bound * x_preheader
            let constraint = create_constraint(LESS_EQUAL);
            
            let header_var = get_block_variable(bb);
            add_term(constraint, header_var, 1.0);
            
            let preheader = find_loop_preheader(bb);
            let preheader_var = get_block_variable(preheader);
            add_term(constraint, preheader_var, -bb.loop_bound);
            
            constraint.rhs = 0;
            add_constraint(problem, constraint);
        }
        
        i = i + 1;
    }
}

// Resolver ILP
fn solve_wcet(analyzer: *WCETAnalyzer) -> i64 {
    let problem = build_ilp_problem(analyzer.cfg, analyzer);
    
    // Usar solver ILP (simplex, branch & bound, etc.)
    let solution = solve_ilp(analyzer.ilp_solver, problem);
    
    if solution.status != OPTIMAL {
        // Manejar infeasible o unbounded
        return -1;
    }
    
    return solution.objective_value;
}
```

### Análisis Context-Sensitive

```tempo
// Análisis que considera diferentes contextos de llamada

struct CallContext {
    call_site: *Instruction,
    caller: *Function,
    cache_state: *CacheState,
    pipeline_state: *PipelineState
}

struct ContextSensitiveAnalysis {
    contexts: *CallContext,
    context_count: i32,
    max_contexts: i32,  // Límite para evitar explosión
    cache: *ContextCache
}

fn analyze_with_contexts(function: *Function, csa: *ContextSensitiveAnalysis) -> i64 {
    let wcet = 0;
    
    // Analizar cada contexto
    let i = 0;
    while i < csa.context_count {
        let ctx = csa.contexts[i];
        
        // Propagar estado desde el contexto
        let entry_state = create_entry_state(ctx);
        
        // Analizar función con este estado inicial
        let ctx_wcet = analyze_function_wcet(function, entry_state);
        
        // Track peor caso
        wcet = max(wcet, ctx_wcet);
        
        i = i + 1;
    }
    
    return wcet;
}

// Análisis de memoria scratchpad
struct ScratchpadAnalysis {
    spm_size: i32,
    allocation: *SPMAllocation,
    wcet_reduction: i64
}

fn optimize_spm_allocation(cfg: *ControlFlowGraph, spm_size: i32) -> *SPMAllocation {
    // Identificar bloques/datos hot
    let hotspots = identify_hotspots(cfg);
    
    // Formular como problema ILP
    let problem = create_spm_ilp(hotspots, spm_size);
    
    // Variables: x_i = 1 si bloque i está en SPM
    let i = 0;
    while i < hotspots.count {
        let var = create_binary_variable("spm_" + int_to_string(i));
        
        // Beneficio = (miss_penalty - spm_latency) * frequency
        let benefit = compute_spm_benefit(hotspots.items[i]);
        var.coefficient = -benefit;  // Minimizar WCET
        
        add_variable(problem, var);
        i = i + 1;
    }
    
    // Constraint: suma de tamaños <= spm_size
    let size_constraint = create_constraint(LESS_EQUAL);
    i = 0;
    while i < hotspots.count {
        let var = get_variable(problem, i);
        let size = get_block_size(hotspots.items[i]);
        add_term(size_constraint, var, size);
        i = i + 1;
    }
    size_constraint.rhs = spm_size;
    add_constraint(problem, size_constraint);
    
    // Resolver
    let solution = solve_ilp(problem);
    return extract_allocation(solution);
}
```

### Análisis Multi-Core

```tempo
// WCET en sistemas multi-core con interferencia

struct MultiCoreSystem {
    cores: **Core,
    core_count: i32,
    shared_bus: *Bus,
    shared_cache: *SharedCache,
    memory: *MemoryController
}

struct InterferenceAnalysis {
    task: *Task,
    interfering_tasks: **Task,
    interference_count: i32,
    bus_delays: *BusDelayModel,
    cache_interference: *CacheInterferenceModel
}

fn analyze_multicore_wcet(task: *Task, system: *MultiCoreSystem) -> i64 {
    // WCET = WCET_isolation + WCET_interference
    
    // 1. Analizar en aislamiento
    let isolation_wcet = analyze_single_core_wcet(task);
    
    // 2. Analizar interferencia de bus
    let bus_delay = analyze_bus_interference(task, system);
    
    // 3. Analizar interferencia de cache
    let cache_delay = analyze_cache_interference(task, system);
    
    // 4. Analizar interferencia de memoria
    let mem_delay = analyze_memory_interference(task, system);
    
    return isolation_wcet + bus_delay + cache_delay + mem_delay;
}

fn analyze_bus_interference(task: *Task, system: *MultiCoreSystem) -> i64 {
    let accesses = count_memory_accesses(task);
    let max_interference = 0;
    
    // Para cada acceso a memoria
    let i = 0;
    while i < accesses {
        // Peor caso: todos los otros cores acceden al mismo tiempo
        let concurrent_requests = min(system.core_count - 1, 
                                    system.bus.max_pending);
        
        // Modelo TDMA, Round-Robin, o Priority-based
        let delay = model_bus_arbitration(system.bus, concurrent_requests);
        max_interference = max_interference + delay;
        
        i = i + 1;
    }
    
    return max_interference;
}

// Técnicas de mitigación
struct WCETMitigation {
    cache_locking: bool,
    cache_partitioning: bool,
    tdma_schedule: *TDMASchedule,
    spm_allocation: *SPMAllocation
}

fn apply_mitigation_techniques(task: *Task, mitigation: *WCETMitigation) {
    if mitigation.cache_locking {
        // Lockear líneas críticas en cache
        let critical_blocks = identify_critical_blocks(task);
        lock_cache_lines(critical_blocks);
    }
    
    if mitigation.cache_partitioning {
        // Asignar partición de cache a la tarea
        let partition = allocate_cache_partition(task);
        configure_cache_partition(partition);
    }
    
    if mitigation.tdma_schedule != 0 {
        // Configurar slots TDMA para acceso a bus
        configure_tdma(mitigation.tdma_schedule);
    }
}
```

### Verificación y Validación

```tempo
// Verificar corrección del análisis WCET

struct WCETVerification {
    static_bound: i64,
    measured_max: i64,
    test_coverage: f64,
    confidence: f64
}

fn verify_wcet_analysis(function: *Function, analyzer: *WCETAnalyzer) -> *WCETVerification {
    let verification = alloc(sizeof(WCETVerification));
    
    // 1. Obtener bound estático
    verification.static_bound = solve_wcet(analyzer);
    
    // 2. Generar test cases para cubrir paths críticos
    let test_suite = generate_wcet_tests(function, analyzer);
    
    // 3. Ejecutar y medir
    let measurements = alloc(test_suite.count * sizeof(i64));
    let i = 0;
    while i < test_suite.count {
        measurements[i] = measure_execution_time(function, test_suite.tests[i]);
        verification.measured_max = max(verification.measured_max, measurements[i]);
        i = i + 1;
    }
    
    // 4. Calcular coverage y confidence
    verification.test_coverage = compute_path_coverage(test_suite, analyzer.cfg);
    verification.confidence = compute_statistical_confidence(measurements, 
                                                           test_suite.count);
    
    // 5. Verificar que mediciones < bound estático
    if verification.measured_max > verification.static_bound {
        report_wcet_violation(verification);
    }
    
    return verification;
}

// Generación de anotaciones para el programador
fn generate_wcet_annotations(function: *Function, analyzer: *WCETAnalyzer) {
    let cfg = analyzer.cfg;
    
    // Anotar cada bloque con su contribución al WCET
    let i = 0;
    while i < cfg.block_count {
        let bb = cfg.blocks[i];
        let annotation = create_annotation();
        
        annotation.wcet_contribution = bb.local_wcet * bb.execution_frequency;
        annotation.is_on_critical_path = is_on_wcet_path(bb, analyzer);
        annotation.cache_misses = count_cache_misses(bb);
        
        attach_annotation(bb, annotation);
        i = i + 1;
    }
    
    // Generar reporte
    generate_wcet_report(function, analyzer);
}
```

## 3. Ejercicios (20%)

### Ejercicio 1: Loop Bounds Analysis
Implementa análisis automático de bounds para loops complejos:
```tempo
// Detectar automáticamente que este loop ejecuta n*(n+1)/2 veces
for i in 0..n {
    for j in i..n {
        process(i, j);
    }
}
```

### Ejercicio 2: Context-Sensitive Cache Analysis
Extiende el análisis de cache para considerar diferentes contextos:
```tempo
fn recursive_function(n: i32) {
    if n <= 0 return;
    // El estado de cache depende de la profundidad de recursión
    process_data();
    recursive_function(n - 1);
}
```

### Ejercicio 3: Análisis de Código Condicional
Implementa análisis preciso para código con branches data-dependent:
```tempo
fn binary_search(arr: [i32; 1000], target: i32) -> i32 {
    // WCET depende de la distribución de branches taken/not taken
}
```

### Ejercicio 4: Hardware Effects
Modela efectos de hardware modernos:
- Branch prediction
- Prefetching
- Out-of-order execution
- Speculative execution

### Ejercicio 5: Composicionalidad
Implementa análisis WCET composicional:
```tempo
// WCET(f∘g) debe ser derivable de WCET(f) y WCET(g)
fn composed_function(x: i32) -> i32 {
    return f(g(x));
}
```

## Proyecto Final: WCET Analyzer Completo

Implementa un analizador WCET industrial-strength:

1. **Análisis de flujo**:
   - CFG construcción automática
   - Loop bound analysis
   - Infeasible path detection
   - Recursion analysis

2. **Modelado de hardware**:
   - Multi-level cache hierarchy
   - Pipeline con forwarding
   - Branch prediction
   - Memory controller

3. **Optimizaciones**:
   - Cache locking
   - SPM allocation
   - Code positioning
   - Loop transformations

4. **Herramientas**:
   - Visualización de paths críticos
   - What-if analysis
   - Anotaciones de código fuente
   - Integración con profiler

## Recursos Adicionales

### Papers Fundamentales
- "The Worst-Case Execution-Time Problem" - Wilhelm et al.
- "Cache-Related Preemption Delay in Real-Time Systems" - Lee et al.
- "Precise Microarchitectural Modeling for WCET Analysis" - Li & Malik
- "Timing Predictability of Cache Replacement Policies" - Reineke et al.

### Herramientas Existentes
- aiT (AbsInt)
- Bound-T
- SWEET
- Chronos
- OTAWA

## Conclusión

El análisis WCET es fundamental para sistemas críticos y de tiempo real. Las técnicas presentadas permiten:

1. **Garantías temporales**: Bounds seguros y precisos
2. **Optimización dirigida**: Identificar y optimizar hot paths
3. **Certificación**: Cumplir estándares (DO-178C, ISO 26262)
4. **Predictibilidad**: Diseñar sistemas con timing predecible

La implementación en Tempo combina análisis estático riguroso con conocimiento profundo del hardware target, permitiendo generar código eficiente con garantías temporales fuertes.