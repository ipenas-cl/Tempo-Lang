╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 21: Optimización de Performance

## Objetivos
- Implementar optimizaciones avanzadas manteniendo determinismo
- Diseñar herramientas de profiling automático
- Crear estrategias de optimización verificables
- Desarrollar análisis de hotspots determinístico

## Teoría: Optimización Determinística

En Chronos, las optimizaciones deben:

1. **Preservar semántica** exacta del programa
2. **Mantener bounds WCET** verificables
3. **No introducir no-determinismo** temporal
4. **Ser completamente verificables** en compile-time

## Análisis de Performance

```tempo
// Analizador de performance estático
struct PerformanceAnalyzer {
    hot_paths: Vec<HotPath>,
    bottlenecks: Vec<Bottleneck>,
    optimization_opportunities: Vec<OptimizationOpportunity>,
    wcet_model: WcetModel,
}

struct HotPath {
    function_chain: Vec<String>,
    call_frequency: f64,
    total_cycles: u64,
    percentage_of_total: f64,
    optimization_potential: f64,
}

struct Bottleneck {
    location: SourceLocation,
    bottleneck_type: BottleneckType,
    impact_score: f64,
    suggested_fixes: Vec<OptimizationSuggestion>,
}

enum BottleneckType {
    MemoryAccess { cache_misses: u64 },
    BranchMisprediction { misprediction_rate: f64 },
    DataDependency { stall_cycles: u64 },
    Loop { iterations: u64, unroll_potential: bool },
    FunctionCall { call_overhead: u64, inline_candidate: bool },
}

impl PerformanceAnalyzer {
    fn analyze_function(&mut self, func: &Function) -> FunctionAnalysis {
        let mut analysis = FunctionAnalysis::new(func.name.clone());
        
        // Análisis de complejidad temporal
        analysis.time_complexity = self.analyze_time_complexity(func);
        analysis.space_complexity = self.analyze_space_complexity(func);
        
        // Análisis de cache behavior
        analysis.cache_behavior = self.analyze_cache_access_patterns(func);
        
        // Detección de loops
        analysis.loops = self.analyze_loops(func);
        
        // Análisis de dependencias de datos
        analysis.data_dependencies = self.analyze_data_dependencies(func);
        
        // Identificar oportunidades de optimización
        analysis.optimizations = self.identify_optimizations(func, &analysis);
        
        analysis
    }
    
    fn analyze_cache_access_patterns(&self, func: &Function) -> CacheBehavior {
        let mut behavior = CacheBehavior::new();
        
        for block in &func.basic_blocks {
            for instruction in &block.instructions {
                match instruction {
                    Instruction::Load { address_expr, .. } => {
                        let access_pattern = self.analyze_memory_access(address_expr);
                        behavior.record_access(access_pattern);
                    },
                    Instruction::Store { address_expr, .. } => {
                        let access_pattern = self.analyze_memory_access(address_expr);
                        behavior.record_access(access_pattern);
                    },
                    _ => {}
                }
            }
        }
        
        behavior.calculate_cache_metrics()
    }
    
    fn identify_optimizations(&self, func: &Function, analysis: &FunctionAnalysis) -> Vec<OptimizationOpportunity> {
        let mut opportunities = Vec::new();
        
        // Loop unrolling
        for loop_info in &analysis.loops {
            if loop_info.is_unrollable() && loop_info.iterations < MAX_UNROLL_ITERATIONS {
                opportunities.push(OptimizationOpportunity::LoopUnroll {
                    location: loop_info.location.clone(),
                    unroll_factor: loop_info.calculate_optimal_unroll_factor(),
                    estimated_speedup: loop_info.estimate_unroll_speedup(),
                });
            }
        }
        
        // Function inlining
        for call in &analysis.function_calls {
            if call.is_inline_candidate() {
                opportunities.push(OptimizationOpportunity::Inline {
                    function_name: call.function_name.clone(),
                    call_site: call.location.clone(),
                    size_increase: call.estimated_size_increase(),
                    speedup: call.estimated_speedup(),
                });
            }
        }
        
        // Vectorization
        for loop_info in &analysis.loops {
            if loop_info.is_vectorizable() {
                opportunities.push(OptimizationOpportunity::Vectorize {
                    loop_location: loop_info.location.clone(),
                    vector_width: loop_info.optimal_vector_width(),
                    estimated_speedup: loop_info.estimate_vectorization_speedup(),
                });
            }
        }
        
        opportunities
    }
}
```

## Optimizaciones de Loop

```tempo
// Loop optimizations que preservan determinismo
struct LoopOptimizer {
    unroll_threshold: usize,
    vectorization_threshold: usize,
    fusion_threshold: usize,
}

impl LoopOptimizer {
    fn optimize_loop(&mut self, loop_info: &LoopInfo) -> OptimizedLoop {
        let mut optimized = OptimizedLoop::from(loop_info);
        
        // 1. Loop unrolling determinístico
        if self.should_unroll(&loop_info) {
            optimized = self.unroll_loop(optimized);
        }
        
        // 2. Loop fusion cuando sea beneficioso
        if let Some(fusion_candidate) = self.find_fusion_candidate(&loop_info) {
            optimized = self.fuse_loops(optimized, fusion_candidate);
        }
        
        // 3. Vectorización si es posible
        if self.can_vectorize(&loop_info) {
            optimized = self.vectorize_loop(optimized);
        }
        
        // 4. Strength reduction
        optimized = self.apply_strength_reduction(optimized);
        
        // Verificar que optimizaciones preservan determinismo
        self.verify_determinism_preservation(&loop_info, &optimized);
        
        optimized
    }
    
    fn unroll_loop(&self, loop_info: OptimizedLoop) -> OptimizedLoop {
        let unroll_factor = self.calculate_unroll_factor(&loop_info);
        
        // Generar código unrolled
        let mut unrolled_body = Vec::new();
        for i in 0..unroll_factor {
            let iteration_body = self.substitute_loop_variables(&loop_info.body, i);
            unrolled_body.extend(iteration_body);
        }
        
        // Manejar iteraciones restantes (remainder loop)
        let remainder_loop = if loop_info.trip_count % unroll_factor != 0 {
            Some(self.create_remainder_loop(&loop_info, unroll_factor))
        } else {
            None
        };
        
        OptimizedLoop {
            original: loop_info.original.clone(),
            unrolled_body,
            remainder_loop,
            unroll_factor,
            estimated_speedup: self.calculate_unroll_speedup(&loop_info, unroll_factor),
        }
    }
    
    fn vectorize_loop(&self, loop_info: OptimizedLoop) -> OptimizedLoop {
        // Análisis de dependencias
        let dependencies = self.analyze_loop_dependencies(&loop_info);
        if !dependencies.is_vectorizable() {
            return loop_info;
        }
        
        // Determinar vector width óptimo
        let vector_width = self.calculate_optimal_vector_width(&loop_info);
        
        // Generar código vectorizado
        let vectorized_body = self.generate_vector_code(&loop_info, vector_width);
        
        // Manejar elementos no-vectorizables (scalar tail)
        let scalar_tail = self.generate_scalar_tail(&loop_info, vector_width);
        
        OptimizedLoop {
            vectorized_body: Some(vectorized_body),
            scalar_tail,
            vector_width,
            ..loop_info
        }
    }
}

// Ejemplo de loop unrolling
fn optimize_matrix_multiply() {
    // Original loop
    for i in 0..N {
        for j in 0..N {
            for k in 0..N {
                C[i][j] += A[i][k] * B[k][j];
            }
        }
    }
    
    // Optimizado con unrolling y blocking
    const BLOCK_SIZE: usize = 64;
    const UNROLL_FACTOR: usize = 4;
    
    for ii in (0..N).step_by(BLOCK_SIZE) {
        for jj in (0..N).step_by(BLOCK_SIZE) {
            for kk in (0..N).step_by(BLOCK_SIZE) {
                for i in ii..min(ii + BLOCK_SIZE, N) {
                    for j in (jj..min(jj + BLOCK_SIZE, N)).step_by(UNROLL_FACTOR) {
                        // Unrolled inner loop
                        for k in kk..min(kk + BLOCK_SIZE, N) {
                            C[i][j] += A[i][k] * B[k][j];
                            if j + 1 < N { C[i][j + 1] += A[i][k] * B[k][j + 1]; }
                            if j + 2 < N { C[i][j + 2] += A[i][k] * B[k][j + 2]; }
                            if j + 3 < N { C[i][j + 3] += A[i][k] * B[k][j + 3]; }
                        }
                    }
                }
            }
        }
    }
}
```

## Optimizaciones de Memoria

```tempo
// Memory layout optimizations
struct MemoryOptimizer {
    cache_line_size: usize,
    page_size: usize,
    prefetch_distance: usize,
}

impl MemoryOptimizer {
    fn optimize_data_layout(&mut self, structures: &[StructDefinition]) -> Vec<OptimizedStruct> {
        structures.iter().map(|s| self.optimize_struct(s)).collect()
    }
    
    fn optimize_struct(&self, original: &StructDefinition) -> OptimizedStruct {
        let mut fields = original.fields.clone();
        
        // 1. Sort fields by alignment to minimize padding
        fields.sort_by(|a, b| {
            let align_a = self.get_field_alignment(a);
            let align_b = self.get_field_alignment(b);
            align_b.cmp(&align_a)  // Descending order
        });
        
        // 2. Group frequently accessed fields together
        let access_patterns = self.analyze_field_access_patterns(original);
        fields = self.group_by_access_locality(fields, &access_patterns);
        
        // 3. Cache line alignment for hot fields
        let hot_fields = self.identify_hot_fields(&access_patterns);
        fields = self.align_hot_fields_to_cache_lines(fields, &hot_fields);
        
        OptimizedStruct {
            original: original.clone(),
            optimized_fields: fields,
            size_reduction: self.calculate_size_reduction(original, &fields),
            cache_efficiency_gain: self.estimate_cache_efficiency_gain(original, &fields),
        }
    }
    
    fn insert_prefetch_hints(&self, func: &Function) -> Function {
        let mut optimized = func.clone();
        
        for block in &mut optimized.basic_blocks {
            for i in 0..block.instructions.len() {
                if let Instruction::Load { address_expr, .. } = &block.instructions[i] {
                    // Analizar patrón de acceso
                    if let Some(prefetch_target) = self.analyze_access_pattern(address_expr, i, block) {
                        // Insertar prefetch hint
                        let prefetch_inst = Instruction::Prefetch {
                            address: prefetch_target,
                            hint_type: PrefetchHint::Chronosral,
                        };
                        
                        block.instructions.insert(i, prefetch_inst);
                    }
                }
            }
        }
        
        optimized
    }
}

// Array of Structures vs Structure of Arrays optimization
fn optimize_particle_system() {
    // Subóptimo: Array of Structures (AoS)
    struct Particle {
        x: f32, y: f32, z: f32,    // position
        vx: f32, vy: f32, vz: f32, // velocity  
        mass: f32,
        charge: f32,
    }
    
    let particles: Vec<Particle> = vec![Particle::default(); NUM_PARTICLES];
    
    // Optimizado: Structure of Arrays (SoA)
    struct ParticleSystem {
        // Hot data - updated every frame
        positions_x: Vec<f32>,
        positions_y: Vec<f32>, 
        positions_z: Vec<f32>,
        velocities_x: Vec<f32>,
        velocities_y: Vec<f32>,
        velocities_z: Vec<f32>,
        
        // Cold data - rarely accessed
        masses: Vec<f32>,
        charges: Vec<f32>,
    }
    
    // Mejor cache locality para operaciones vectoriales
    fn update_positions(system: &mut ParticleSystem, dt: f32) {
        // Vectorizable loop - datos contiguos
        for i in 0..system.positions_x.len() {
            system.positions_x[i] += system.velocities_x[i] * dt;
            system.positions_y[i] += system.velocities_y[i] * dt;
            system.positions_z[i] += system.velocities_z[i] * dt;
        }
    }
}
```

## Auto-vectorization

```tempo
// Auto-vectorization engine
struct VectorizationEngine {
    target_architecture: TargetArch,
    vector_width: usize,
    supported_operations: HashSet<VectorOperation>,
}

impl VectorizationEngine {
    fn vectorize_function(&mut self, func: &Function) -> VectorizedFunction {
        let mut vectorized = VectorizedFunction::from(func);
        
        for loop_info in self.find_vectorizable_loops(func) {
            if self.can_vectorize_safely(&loop_info) {
                vectorized.add_vectorized_loop(self.vectorize_loop(&loop_info));
            }
        }
        
        vectorized
    }
    
    fn can_vectorize_safely(&self, loop_info: &LoopInfo) -> bool {
        // 1. Verificar ausencia de dependencias que impidan vectorización
        let dependencies = self.analyze_loop_dependencies(loop_info);
        if dependencies.has_loop_carried_dependencies() {
            return false;
        }
        
        // 2. Verificar que todas las operaciones son vectorizables
        for operation in &loop_info.operations {
            if !self.supported_operations.contains(&operation.to_vector_operation()) {
                return false;
            }
        }
        
        // 3. Verificar alignment de memoria
        for memory_access in &loop_info.memory_accesses {
            if !memory_access.is_aligned_for_vectorization(self.vector_width) {
                return false;
            }
        }
        
        true
    }
    
    fn vectorize_loop(&self, loop_info: &LoopInfo) -> VectorizedLoop {
        let vector_width = self.calculate_optimal_vector_width(loop_info);
        
        let mut vectorized_body = Vec::new();
        
        // Generar código vectorizado
        for operation in &loop_info.operations {
            let vector_op = self.convert_to_vector_operation(operation, vector_width);
            vectorized_body.push(vector_op);
        }
        
        // Generar scalar remainder loop
        let remainder_loop = self.generate_scalar_remainder(loop_info, vector_width);
        
        VectorizedLoop {
            original: loop_info.clone(),
            vectorized_body,
            remainder_loop,
            vector_width,
            speedup_estimate: self.estimate_vectorization_speedup(loop_info, vector_width),
        }
    }
}

// Ejemplo de auto-vectorization
fn vector_add_example() {
    // Original scalar code
    fn scalar_add(a: &[f32], b: &[f32], result: &mut [f32]) {
        for i in 0..a.len() {
            result[i] = a[i] + b[i];
        }
    }
    
    // Auto-vectorized by compiler
    fn vectorized_add(a: &[f32], b: &[f32], result: &mut [f32]) {
        let vector_width = 8; // AVX-256: 8 x f32
        let vectorizable_len = (a.len() / vector_width) * vector_width;
        
        // Vectorized main loop
        let mut i = 0;
        while i < vectorizable_len {
            // Load vectors
            let va = load_vector_f32(&a[i..i + vector_width]);
            let vb = load_vector_f32(&b[i..i + vector_width]);
            
            // Vector addition
            let vresult = vector_add_f32(va, vb);
            
            // Store result
            store_vector_f32(&mut result[i..i + vector_width], vresult);
            
            i += vector_width;
        }
        
        // Scalar remainder
        while i < a.len() {
            result[i] = a[i] + b[i];
            i += 1;
        }
    }
}
```

## Optimización de Branches

```tempo
// Branch optimization y prediction
struct BranchOptimizer {
    branch_statistics: HashMap<BranchId, BranchStats>,
    misprediction_cost: u64,
}

struct BranchStats {
    taken_count: u64,
    not_taken_count: u64,
    misprediction_rate: f64,
    branch_type: BranchType,
}

enum BranchType {
    ConditionalJump,
    Loop,
    Switch,
    FunctionCall,
}

impl BranchOptimizer {
    fn optimize_branches(&mut self, func: &Function) -> Function {
        let mut optimized = func.clone();
        
        // 1. Branch elimination
        optimized = self.eliminate_branches(optimized);
        
        // 2. Branch reordering for better prediction
        optimized = self.reorder_branches(optimized);
        
        // 3. Convert branches to conditional moves where beneficial
        optimized = self.convert_to_conditional_moves(optimized);
        
        // 4. Switch optimization
        optimized = self.optimize_switch_statements(optimized);
        
        optimized
    }
    
    fn eliminate_branches(&self, mut func: Function) -> Function {
        for block in &mut func.basic_blocks {
            let mut i = 0;
            while i < block.instructions.len() {
                if let Instruction::Branch { condition, .. } = &block.instructions[i] {
                    // Intentar evaluar condición en compile-time
                    if let Some(constant_result) = self.evaluate_condition_constant(condition) {
                        if constant_result {
                            // Branch always taken - convert to unconditional jump
                            block.instructions[i] = Instruction::Jump { target: block.instructions[i].get_taken_target() };
                        } else {
                            // Branch never taken - remove branch
                            block.instructions.remove(i);
                            continue;
                        }
                    }
                }
                i += 1;
            }
        }
        func
    }
    
    fn convert_to_conditional_moves(&self, mut func: Function) -> Function {
        for block in &mut func.basic_blocks {
            // Buscar patrones if-then-else simples
            for window in block.instructions.windows(3) {
                if let [
                    Instruction::Branch { condition, taken_target, not_taken_target },
                    Instruction::Assign { target, value: taken_value },
                    Instruction::Assign { target: target2, value: not_taken_value }
                ] = window {
                    if target == target2 && self.is_cmov_beneficial(condition) {
                        // Reemplazar con conditional move
                        let cmov = Instruction::ConditionalMove {
                            condition: condition.clone(),
                            target: target.clone(),
                            true_value: taken_value.clone(),
                            false_value: not_taken_value.clone(),
                        };
                        // Reemplazar las 3 instrucciones con 1 cmov
                        // [implementation would modify the instruction stream]
                    }
                }
            }
        }
        func
    }
    
    fn optimize_switch_statements(&self, mut func: Function) -> Function {
        for block in &mut func.basic_blocks {
            for instruction in &mut block.instructions {
                if let Instruction::Switch { value, cases, default } = instruction {
                    let optimized_switch = self.optimize_switch(value, cases, default);
                    *instruction = optimized_switch;
                }
            }
        }
        func
    }
    
    fn optimize_switch(&self, value: &Expression, cases: &[(i64, BasicBlockId)], default: &BasicBlockId) -> Instruction {
        // Analizar distribución de casos
        let case_distribution = self.analyze_case_distribution(cases);
        
        match case_distribution {
            CaseDistribution::Dense => {
                // Usar jump table
                self.generate_jump_table(value, cases, default)
            },
            CaseDistribution::Sparse => {
                // Usar binary search tree
                self.generate_binary_search_tree(value, cases, default)
            },
            CaseDistribution::Few => {
                // Usar if-else chain optimizado
                self.generate_if_else_chain(value, cases, default)
            },
        }
    }
}
```

## Profile-Guided Optimization

```tempo
// Profile-guided optimization system
struct ProfileGuidedOptimizer {
    profile_data: ProfileData,
    optimization_decisions: HashMap<String, OptimizationDecision>,
}

struct ProfileData {
    function_call_counts: HashMap<String, u64>,
    branch_taken_counts: HashMap<BranchId, (u64, u64)>,
    cache_miss_rates: HashMap<MemoryAccess, f64>,
    hot_paths: Vec<HotPath>,
}

impl ProfileGuidedOptimizer {
    fn optimize_with_profile(&mut self, program: &Program) -> OptimizedProgram {
        let mut optimized = OptimizedProgram::from(program);
        
        // 1. Inline hot functions
        for (func_name, call_count) in &self.profile_data.function_call_counts {
            if *call_count > INLINE_THRESHOLD {
                optimized.inline_function(func_name);
            }
        }
        
        // 2. Optimize branch layout based on taken frequency
        for (branch_id, (taken, not_taken)) in &self.profile_data.branch_taken_counts {
            let taken_probability = *taken as f64 / (*taken + *not_taken) as f64;
            optimized.optimize_branch_layout(*branch_id, taken_probability);
        }
        
        // 3. Optimize memory layout for hot data
        for hot_path in &self.profile_data.hot_paths {
            optimized.optimize_data_layout_for_path(hot_path);
        }
        
        // 4. Apply specialized optimizations for hot loops
        let hot_loops = self.identify_hot_loops();
        for loop_info in hot_loops {
            optimized.apply_aggressive_loop_optimizations(&loop_info);
        }
        
        optimized
    }
    
    fn collect_runtime_profile(&mut self, program: &Program) -> ProfileData {
        // Instrumentar programa para recolectar profile data
        let instrumented = self.instrument_for_profiling(program);
        
        // Ejecutar con workload representativo
        let execution_trace = self.execute_with_instrumentation(&instrumented);
        
        // Analizar trace para extraer profile data
        self.analyze_execution_trace(execution_trace)
    }
}

// Ejemplo de PGO en función de ordenamiento
#[profile_guided]
fn quicksort_pgo(arr: &mut [i32], low: usize, high: usize) {
    if low >= high {
        return;
    }
    
    // Profile muestra que arrays pequeños son comunes
    if high - low < 16 {
        insertion_sort(arr, low, high); // Más rápido para arrays pequeños
        return;
    }
    
    let pivot = partition(arr, low, high);
    
    // Profile muestra que partición izquierda suele ser mayor
    // Optimizar para ese caso común
    if pivot - low > high - pivot {
        quicksort_pgo(arr, low, pivot - 1);    // Lado mayor primero (mejor cache)
        quicksort_pgo(arr, pivot + 1, high);
    } else {
        quicksort_pgo(arr, pivot + 1, high);
        quicksort_pgo(arr, low, pivot - 1);
    }
}
```

## Herramientas de Profiling Automático

```tempo
// Auto-profiling durante desarrollo
struct AutoProfiler {
    sampling_rate: f64,
    profile_buffer: CircularBuffer<ProfileSample>,
    hot_spot_detector: HotSpotDetector,
    regression_detector: RegressionDetector,
}

impl AutoProfiler {
    fn start_continuous_profiling(&mut self) {
        // Profiling de bajo overhead durante desarrollo
        self.setup_timer_interrupt(self.sampling_rate);
        self.enable_hardware_counters();
        self.start_profile_collection();
    }
    
    fn analyze_performance_trends(&self) -> PerformanceTrends {
        let recent_samples = self.profile_buffer.last_n_samples(1000);
        
        PerformanceTrends {
            performance_regression: self.regression_detector.detect_regression(&recent_samples),
            new_hot_spots: self.hot_spot_detector.find_new_hot_spots(&recent_samples),
            optimization_suggestions: self.generate_optimization_suggestions(&recent_samples),
        }
    }
    
    fn generate_optimization_report(&self) -> OptimizationReport {
        OptimizationReport {
            executive_summary: self.create_executive_summary(),
            hot_functions: self.identify_hot_functions(),
            memory_bottlenecks: self.find_memory_bottlenecks(),
            optimization_priorities: self.rank_optimization_opportunities(),
            estimated_gains: self.estimate_optimization_gains(),
        }
    }
}
```

## Práctica: Optimizador de Matrix Multiplication

Implementa un optimizador completo para multiplicación de matrices que incluya:

1. Loop tiling/blocking para cache optimization
2. Vectorización automática 
3. Memory prefetching
4. Profile-guided specialization

## Ejercicio Final

Crea un sistema de optimización automática que:

1. Profile automáticamente el código
2. Identifique bottlenecks principales
3. Aplique optimizaciones automáticamente
4. Verifique que las optimizaciones preservan determinismo
5. Genere reportes de improvement

**Próxima lección**: Sistemas Embebidos y IoT