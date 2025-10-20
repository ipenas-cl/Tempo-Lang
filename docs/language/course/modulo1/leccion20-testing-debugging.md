╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 20: Testing y Debugging Determinístico

## Objetivos
- Diseñar framework de testing determinístico
- Implementar debugging tools para Chronos
- Crear property-based testing
- Desarrollar herramientas de profiling determinístico

## Teoría: Testing Determinístico

En Chronos, el testing debe ser completamente reproducible:

1. **Mismos inputs** → **mismos outputs** → **mismo timing**
2. **Seeds determinísticos** para generación de datos de prueba
3. **Isolation completa** entre tests
4. **Verificación de propiedades temporales**

## Framework de Testing Base

```tempo
// Framework de testing determinístico
struct TestFramework {
    test_registry: HashMap<String, TestFunction>,
    rng_seed: u64,
    timeout_per_test: Duration,
    memory_limit_per_test: usize,
    current_test: Option<TestContext>,
}

struct TestContext {
    name: String,
    start_time: Instant,
    start_cycles: u64,
    memory_tracker: MemoryTracker,
    assertions: Vec<Assertion>,
}

struct TestResult {
    name: String,
    status: TestStatus,
    duration: Duration,
    cycles_used: u64,
    memory_peak: usize,
    assertions_passed: usize,
    assertions_failed: usize,
    error_message: Option<String>,
}

enum TestStatus {
    Passed,
    Failed,
    Timeout,
    MemoryExceeded,
    Panic,
}

// Macros para testing
macro test {
    (
        fn $name:ident() 
        timeout: $timeout:expr,
        memory_limit: $memory:expr,
        {
            $($body:stmt)*
        }
    ) => {
        fn $name() {
            let mut ctx = TestContext::new(stringify!($name));
            ctx.set_timeout($timeout);
            ctx.set_memory_limit($memory);
            
            let result = panic::catch_unwind(|| {
                $($body)*
            });
            
            match result {
                Ok(_) => ctx.complete_success(),
                Err(e) => ctx.complete_panic(e),
            }
        }
        
        inventory::submit! {
            TestRegistration {
                name: stringify!($name),
                function: $name,
            }
        }
    };
}

// Assertions determinísticas
macro assert_eq_deterministic {
    ($left:expr, $right:expr) => {
        {
            let left_val = $left;
            let right_val = $right;
            
            if left_val != right_val {
                panic!("assertion failed: `(left == right)`\n  left: `{:?}`,\n right: `{:?}`", 
                       left_val, right_val);
            }
            
            // Verificar que la comparación sea determinística
            assert_eq!(left_val, right_val);
            assert_eq!($left, $right);  // Segunda evaluación debe dar igual
        }
    };
}

macro assert_wcet {
    ($expr:expr, $max_cycles:expr) => {
        {
            let start = rdtsc();
            let result = $expr;
            let cycles = rdtsc() - start;
            
            assert!(cycles <= $max_cycles, 
                   "WCET violation: {} cycles > {} max", cycles, $max_cycles);
            
            result
        }
    };
}
```

## Property-Based Testing

```tempo
// Generación determinística de datos de prueba
struct DeterministicGenerator {
    rng: DeterministicRng,
    generation_strategy: GenerationStrategy,
}

enum GenerationStrategy {
    Uniform,
    EdgeCases,
    Boundary,
    Stress,
}

impl DeterministicGenerator {
    fn new(seed: u64) -> Self {
        DeterministicGenerator {
            rng: DeterministicRng::new(seed),
            generation_strategy: GenerationStrategy::Uniform,
        }
    }
    
    fn generate<T: Arbitrary>(&mut self) -> T {
        T::arbitrary(&mut self.rng, &self.generation_strategy)
    }
    
    fn generate_with_constraints<T>(&mut self, constraints: &Constraints<T>) -> T 
    where T: Arbitrary + Validate {
        loop {
            let value = self.generate::<T>();
            if constraints.validate(&value) {
                return value;
            }
        }
    }
}

// Trait para generar valores arbitrarios
trait Arbitrary: Sized {
    fn arbitrary(rng: &mut DeterministicRng, strategy: &GenerationStrategy) -> Self;
    
    fn shrink(&self) -> Vec<Self> {
        vec![]  // Default: no shrinking
    }
}

impl Arbitrary for i32 {
    fn arbitrary(rng: &mut DeterministicRng, strategy: &GenerationStrategy) -> Self {
        match strategy {
            GenerationStrategy::Uniform => rng.gen_range(-1000..1000),
            GenerationStrategy::EdgeCases => {
                let cases = [0, 1, -1, i32::MAX, i32::MIN];
                cases[rng.gen_range(0..cases.len())]
            },
            GenerationStrategy::Boundary => {
                let boundaries = [-1000, -1, 0, 1, 1000];
                boundaries[rng.gen_range(0..boundaries.len())]
            },
            GenerationStrategy::Stress => rng.gen_range(i32::MIN..i32::MAX),
        }
    }
    
    fn shrink(&self) -> Vec<Self> {
        if *self == 0 {
            return vec![];
        }
        
        let mut shrunk = vec![0];
        if *self > 0 {
            shrunk.push(self / 2);
            shrunk.push(self - 1);
        } else {
            shrunk.push(self / 2);
            shrunk.push(self + 1);
        }
        shrunk
    }
}

impl Arbitrary for Vec<i32> {
    fn arbitrary(rng: &mut DeterministicRng, strategy: &GenerationStrategy) -> Self {
        let len = match strategy {
            GenerationStrategy::Uniform => rng.gen_range(0..100),
            GenerationStrategy::EdgeCases => {
                let sizes = [0, 1, 2, 1000];
                sizes[rng.gen_range(0..sizes.len())]
            },
            _ => rng.gen_range(0..1000),
        };
        
        (0..len).map(|_| i32::arbitrary(rng, strategy)).collect()
    }
}

// Property-based test macro
macro property_test {
    (
        fn $name:ident($($param:ident: $param_type:ty),*)
        where $($constraint:expr),*
        property $property:expr
    ) => {
        test! {
            fn $name()
            timeout: Duration::from_secs(30),
            memory_limit: 100_000_000,
            {
                const NUM_CASES: usize = 1000;
                let mut generator = DeterministicGenerator::new(0x12345678);
                
                for case_num in 0..NUM_CASES {
                    generator.rng.reseed(0x12345678 + case_num as u64);
                    
                    // Generar parámetros
                    $(
                        let $param: $param_type = loop {
                            let candidate = generator.generate();
                            if $($constraint)&&* {
                                break candidate;
                            }
                        };
                    )*
                    
                    // Verificar propiedad
                    if !($property) {
                        // Shrinking para encontrar caso mínimo
                        let minimal_case = shrink_failure(($($param,)*));
                        panic!("Property failed on case {}: {:?}", case_num, minimal_case);
                    }
                }
            }
        }
    };
}

// Ejemplo de uso
property_test! {
    fn test_sorting_preserves_length(input: Vec<i32>)
    where input.len() <= 1000
    property {
        let sorted = quicksort(input.clone());
        sorted.len() == input.len()
    }
}

property_test! {
    fn test_sorting_is_idempotent(input: Vec<i32>)
    where input.len() <= 100
    property {
        let sorted1 = quicksort(input.clone());
        let sorted2 = quicksort(sorted1.clone());
        sorted1 == sorted2
    }
}
```

## Debugging Determinístico

```tempo
// Debugger que preserva determinismo
struct DeterministicDebugger {
    execution_trace: Vec<ExecutionEvent>,
    breakpoints: HashMap<Location, BreakpointCondition>,
    watch_points: HashMap<String, WatchCondition>,
    current_position: usize,
    replay_mode: bool,
}

#[derive(Debug, Clone)]
struct ExecutionEvent {
    timestamp: u64,
    cycle_count: u64,
    event_type: EventType,
    location: Location,
    state_snapshot: StateSnapshot,
}

#[derive(Debug, Clone)]
enum EventType {
    FunctionCall { name: String, args: Vec<Value> },
    FunctionReturn { value: Value },
    VariableAssignment { name: String, old_value: Value, new_value: Value },
    MemoryAccess { address: usize, access_type: AccessType },
    Branch { condition: bool, taken: bool },
    Loop { iteration: u64 },
}

impl DeterministicDebugger {
    fn record_execution<F, R>(&mut self, func: F) -> R 
    where F: FnOnce() -> R {
        self.replay_mode = false;
        self.execution_trace.clear();
        
        // Instrumentar ejecución
        let result = self.with_instrumentation(func);
        
        result
    }
    
    fn replay_execution(&mut self) -> Result<(), DebugError> {
        self.replay_mode = true;
        self.current_position = 0;
        
        // Replay determinístico
        for event in &self.execution_trace.clone() {
            self.replay_event(event)?;
        }
        
        Ok(())
    }
    
    fn step_forward(&mut self) -> Option<&ExecutionEvent> {
        if self.current_position < self.execution_trace.len() {
            let event = &self.execution_trace[self.current_position];
            self.current_position += 1;
            Some(event)
        } else {
            None
        }
    }
    
    fn step_backward(&mut self) -> Option<&ExecutionEvent> {
        if self.current_position > 0 {
            self.current_position -= 1;
            Some(&self.execution_trace[self.current_position])
        } else {
            None
        }
    }
    
    fn set_breakpoint(&mut self, location: Location, condition: BreakpointCondition) {
        self.breakpoints.insert(location, condition);
    }
    
    fn set_watchpoint(&mut self, variable: String, condition: WatchCondition) {
        self.watch_points.insert(variable, condition);
    }
}

// Macros de debugging
macro debug_trace {
    ($($arg:tt)*) => {
        #[cfg(debug_assertions)]
        {
            GLOBAL_DEBUGGER.record_event(ExecutionEvent {
                timestamp: get_timestamp(),
                cycle_count: rdtsc(),
                event_type: EventType::DebugTrace(format!($($arg)*)),
                location: Location::current(),
                state_snapshot: StateSnapshot::capture(),
            });
        }
    };
}

macro debug_assert_deterministic {
    ($expr:expr) => {
        #[cfg(debug_assertions)]
        {
            // Ejecutar expresión múltiples veces
            let first_result = $expr;
            for _ in 0..10 {
                let result = $expr;
                assert_eq!(result, first_result, 
                          "Non-deterministic behavior detected in assertion");
            }
        }
    };
}
```

## Profiling Determinístico

```tempo
// Profiler que mantiene determinismo
struct DeterministicProfiler {
    call_stack: Vec<ProfiledCall>,
    timing_data: HashMap<String, TimingStats>,
    memory_data: HashMap<String, MemoryStats>,
    start_time: Instant,
    start_cycles: u64,
}

struct ProfiledCall {
    function_name: String,
    start_time: Instant,
    start_cycles: u64,
    start_memory: usize,
}

struct TimingStats {
    call_count: u64,
    total_cycles: u64,
    min_cycles: u64,
    max_cycles: u64,
    variance: f64,
}

struct MemoryStats {
    total_allocations: u64,
    peak_usage: usize,
    average_usage: f64,
}

impl DeterministicProfiler {
    fn enter_function(&mut self, name: &str) {
        let call = ProfiledCall {
            function_name: name.to_string(),
            start_time: Instant::now(),
            start_cycles: rdtsc(),
            start_memory: get_memory_usage(),
        };
        
        self.call_stack.push(call);
    }
    
    fn exit_function(&mut self, name: &str) {
        if let Some(call) = self.call_stack.pop() {
            assert_eq!(call.function_name, name);
            
            let end_cycles = rdtsc();
            let cycles_elapsed = end_cycles - call.start_cycles;
            
            // Actualizar estadísticas
            let stats = self.timing_data.entry(name.to_string())
                           .or_insert(TimingStats::new());
            stats.update(cycles_elapsed);
            
            // Verificar varianza (debugging de no-determinismo)
            if stats.call_count > 10 && stats.variance > VARIANCE_THRESHOLD {
                eprintln!("Warning: High timing variance in {}: {}", name, stats.variance);
            }
        }
    }
    
    fn generate_report(&self) -> ProfileReport {
        ProfileReport {
            timing_stats: self.timing_data.clone(),
            memory_stats: self.memory_data.clone(),
            call_graph: self.build_call_graph(),
            hotspots: self.identify_hotspots(),
        }
    }
}

// Macro para profiling automático
macro profile_function {
    (fn $name:ident($($param:ident: $param_type:ty),*) -> $ret:ty { $($body:stmt)* }) => {
        fn $name($($param: $param_type),*) -> $ret {
            GLOBAL_PROFILER.enter_function(stringify!($name));
            
            let result = {
                $($body)*
            };
            
            GLOBAL_PROFILER.exit_function(stringify!($name));
            result
        }
    };
}
```

## Testing de Concurrencia

```tempo
// Framework para testing de código concurrente
struct ConcurrencyTester {
    thread_scenarios: Vec<ThreadScenario>,
    interleavings: Vec<Interleaving>,
    current_interleaving: usize,
}

struct ThreadScenario {
    thread_id: usize,
    operations: Vec<Operation>,
}

struct Interleaving {
    execution_order: Vec<(usize, usize)>, // (thread_id, operation_index)
    result: TestResult,
}

impl ConcurrencyTester {
    fn test_all_interleavings<F>(&mut self, test_func: F) -> Vec<TestResult>
    where F: Fn(&Interleaving) -> TestResult {
        let mut results = Vec::new();
        
        // Generar todas las interleavings posibles determinísticamente
        let interleavings = self.generate_interleavings();
        
        for interleaving in interleavings {
            let result = test_func(&interleaving);
            results.push(result);
            
            // Parar en primera falla para debugging
            if !result.is_success() {
                break;
            }
        }
        
        results
    }
    
    fn generate_interleavings(&self) -> Vec<Interleaving> {
        // Algoritmo determinístico para generar interleavings
        // Evita explosión combinatoria usando heurísticas
        
        let mut interleavings = Vec::new();
        let total_ops: usize = self.thread_scenarios.iter()
                                   .map(|s| s.operations.len())
                                   .sum();
        
        // Usar algoritmo de bounded model checking
        for bound in 1..=min(total_ops, MAX_INTERLEAVING_BOUND) {
            let bounded_interleavings = self.generate_bounded_interleavings(bound);
            interleavings.extend(bounded_interleavings);
        }
        
        interleavings
    }
}

// Test de race condition
test! {
    fn test_counter_race_condition()
    timeout: Duration::from_secs(10),
    memory_limit: 10_000_000,
    {
        let mut tester = ConcurrencyTester::new();
        
        // Scenario: dos threads incrementando contador
        tester.add_thread_scenario(vec![
            Operation::Read("counter"),
            Operation::Add(1),
            Operation::Write("counter"),
        ]);
        
        tester.add_thread_scenario(vec![
            Operation::Read("counter"),
            Operation::Add(1),
            Operation::Write("counter"),
        ]);
        
        let results = tester.test_all_interleavings(|interleaving| {
            execute_interleaving(interleaving)
        });
        
        // Verificar que todos los resultados son consistentes
        let final_values: HashSet<i32> = results.iter()
                                               .map(|r| r.final_counter_value)
                                               .collect();
        
        assert_eq!(final_values.len(), 1, "Race condition detected: multiple possible outcomes");
    }
}
```

## Coverage Determinístico

```tempo
// Análisis de cobertura determinística
struct CoverageAnalyzer {
    line_coverage: HashMap<String, LineInfo>,
    branch_coverage: HashMap<String, BranchInfo>,
    path_coverage: HashSet<ExecutionPath>,
    function_coverage: HashMap<String, FunctionCoverage>,
}

struct LineInfo {
    hit_count: u64,
    cycles_spent: u64,
    first_hit_timestamp: Option<u64>,
}

struct BranchInfo {
    true_count: u64,
    false_count: u64,
    coverage_percentage: f64,
}

impl CoverageAnalyzer {
    fn instrument_function(&mut self, name: &str, body: &TokenStream) -> TokenStream {
        // Instrumentar cada línea y branch
        let instrumented = self.add_coverage_probes(body);
        
        quote! {
            fn #name() {
                COVERAGE_ANALYZER.enter_function(stringify!(#name));
                #instrumented
                COVERAGE_ANALYZER.exit_function(stringify!(#name));
            }
        }
    }
    
    fn generate_coverage_report(&self) -> CoverageReport {
        CoverageReport {
            overall_percentage: self.calculate_overall_coverage(),
            line_coverage: self.line_coverage.clone(),
            branch_coverage: self.branch_coverage.clone(),
            uncovered_lines: self.find_uncovered_lines(),
            critical_paths: self.find_critical_paths(),
        }
    }
}
```

## Práctica: Test Suite para Red-Black Tree

Crea una suite de tests completa para Red-Black Tree que incluya:

1. Property-based testing para invariantes
2. Concurrency testing para operaciones paralelas
3. Performance testing con bounds WCET
4. Coverage analysis completo

## Ejercicio Final

Implementa un framework de regression testing que:

1. Capture snapshots determinísticos de estado
2. Detecte cambios en comportamiento
3. Identifique performance regressions
4. Genere reportes automatizados

**Próxima lección**: Optimización de Performance