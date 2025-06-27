╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 26: Performance y Benchmarking

## Objetivos
- Diseñar benchmarking determinístico
- Implementar herramientas de performance analysis
- Crear comparative benchmarks contra otros lenguajes
- Desarrollar performance regression detection

## Teoría: Benchmarking Determinístico

En Tempo, el benchmarking debe ser completamente reproducible:

1. **Mismos resultados** en múltiples ejecuciones
2. **Métricas determinísticas** sin varianza estadística
3. **Comparabilidad** entre diferentes sistemas
4. **Regression detection** automática

## Framework de Benchmarking Determinístico

```tempo
// Framework para benchmarks reproducibles
struct DeterministicBenchmark {
    name: String,
    description: String,
    setup_function: Option<fn() -> BenchmarkContext>,
    benchmark_function: fn(&BenchmarkContext) -> BenchmarkResult,
    teardown_function: Option<fn(&BenchmarkContext)>,
    
    // Configuración determinística
    iterations: u32,
    warmup_iterations: u32,
    timeout: Duration,
    memory_limit: usize,
    
    // Métricas a recolectar
    metrics: Vec<MetricType>,
    expected_bounds: Option<PerformanceBounds>,
}

struct BenchmarkContext {
    data: HashMap<String, BenchmarkData>,
    random_seed: u64,
    memory_allocator: DeterministicAllocator,
    timer: DeterministicTimer,
}

struct BenchmarkResult {
    execution_time: Duration,
    cpu_cycles: u64,
    memory_usage: MemoryMetrics,
    cache_metrics: CacheMetrics,
    custom_metrics: HashMap<String, f64>,
    
    // Determinism verification
    hash_of_output: u64,
    determinism_verified: bool,
}

impl DeterministicBenchmark {
    fn run(&self) -> Result<BenchmarkReport, BenchmarkError> {
        // Setup deterministic environment
        let environment = self.setup_deterministic_environment()?;
        
        // Warmup phase
        for _ in 0..self.warmup_iterations {
            self.run_single_iteration(&environment, false)?;
        }
        
        // Main benchmark iterations
        let mut results = Vec::new();
        
        for iteration in 0..self.iterations {
            let result = self.run_single_iteration(&environment, true)?;
            results.push(result);
            
            // Verify determinism between iterations
            if iteration > 0 {
                self.verify_determinism(&results[0], &result)?;
            }
        }
        
        // Analyze results
        let analysis = self.analyze_results(&results)?;
        
        // Cleanup
        if let Some(teardown) = self.teardown_function {
            teardown(&environment);
        }
        
        Ok(BenchmarkReport {
            benchmark_name: self.name.clone(),
            results,
            analysis,
            environment_info: environment.get_info(),
            determinism_verified: true,
        })
    }
    
    fn run_single_iteration(&self, context: &BenchmarkContext, record_metrics: bool) -> Result<BenchmarkResult, BenchmarkError> {
        // Reset context for deterministic state
        let mut iteration_context = context.clone();
        iteration_context.reset_for_iteration();
        
        // Start measurement
        let start_time = iteration_context.timer.now();
        let start_cycles = rdtsc();
        let start_memory = iteration_context.memory_allocator.get_usage();
        
        // Reset CPU caches if requested
        if record_metrics {
            flush_cpu_caches();
        }
        
        // Execute benchmark function
        let function_result = (self.benchmark_function)(&iteration_context);
        
        // Stop measurement
        let end_cycles = rdtsc();
        let end_time = iteration_context.timer.now();
        let end_memory = iteration_context.memory_allocator.get_usage();
        
        // Collect metrics
        let cache_metrics = if record_metrics {
            collect_cache_metrics()
        } else {
            CacheMetrics::default()
        };
        
        Ok(BenchmarkResult {
            execution_time: end_time - start_time,
            cpu_cycles: end_cycles - start_cycles,
            memory_usage: MemoryMetrics {
                peak_usage: end_memory.peak - start_memory.peak,
                allocations: end_memory.allocations - start_memory.allocations,
                deallocations: end_memory.deallocations - start_memory.deallocations,
            },
            cache_metrics,
            custom_metrics: function_result.custom_metrics,
            hash_of_output: function_result.output_hash,
            determinism_verified: false, // Will be set later
        })
    }
    
    fn verify_determinism(&self, baseline: &BenchmarkResult, current: &BenchmarkResult) -> Result<(), BenchmarkError> {
        // Verify output determinism
        if baseline.hash_of_output != current.hash_of_output {
            return Err(BenchmarkError::NonDeterministicOutput {
                expected_hash: baseline.hash_of_output,
                actual_hash: current.hash_of_output,
            });
        }
        
        // Verify timing determinism (within acceptable bounds)
        let timing_variance = (current.cpu_cycles as f64 - baseline.cpu_cycles as f64).abs() / baseline.cpu_cycles as f64;
        if timing_variance > 0.01 { // 1% variance threshold
            return Err(BenchmarkError::TimingVariance {
                baseline_cycles: baseline.cpu_cycles,
                current_cycles: current.cpu_cycles,
                variance_percent: timing_variance * 100.0,
            });
        }
        
        // Verify memory determinism
        if baseline.memory_usage.peak_usage != current.memory_usage.peak_usage {
            return Err(BenchmarkError::MemoryVariance {
                baseline_memory: baseline.memory_usage.peak_usage,
                current_memory: current.memory_usage.peak_usage,
            });
        }
        
        Ok(())
    }
    
    fn analyze_results(&self, results: &[BenchmarkResult]) -> Result<BenchmarkAnalysis, BenchmarkError> {
        let analysis = BenchmarkAnalysis {
            mean_execution_time: self.calculate_mean_execution_time(results),
            mean_cpu_cycles: self.calculate_mean_cpu_cycles(results),
            memory_statistics: self.calculate_memory_statistics(results),
            cache_statistics: self.calculate_cache_statistics(results),
            determinism_score: 1.0, // Perfect determinism in Tempo
            performance_classification: self.classify_performance(results)?,
        };
        
        Ok(analysis)
    }
}

// Macro para definir benchmarks fácilmente
macro benchmark {
    (
        name: $name:literal,
        description: $desc:literal,
        iterations: $iterations:expr,
        $(setup: $setup:expr,)?
        $(teardown: $teardown:expr,)?
        benchmark: $benchmark_fn:expr
    ) => {
        DeterministicBenchmark {
            name: $name.to_string(),
            description: $desc.to_string(),
            setup_function: None $(.or(Some($setup)))?,
            benchmark_function: $benchmark_fn,
            teardown_function: None $(.or(Some($teardown)))?,
            iterations: $iterations,
            warmup_iterations: 10,
            timeout: Duration::from_secs(300),
            memory_limit: 1_000_000_000, // 1GB
            metrics: vec![MetricType::ExecutionTime, MetricType::MemoryUsage, MetricType::CacheMetrics],
            expected_bounds: None,
        }
    };
}

// Ejemplo de uso del macro
benchmark! {
    name: "sorting_algorithms_comparison",
    description: "Compare different sorting algorithms on various data sizes",
    iterations: 1000,
    setup: || {
        let mut context = BenchmarkContext::new();
        // Generate deterministic test data
        let mut rng = DeterministicRng::new(0x12345678);
        for size in [100, 1000, 10000, 100000] {
            let data = (0..size).map(|_| rng.gen_range(0..1000000)).collect::<Vec<u32>>();
            context.data.insert(format!("data_{}", size), BenchmarkData::IntArray(data));
        }
        context
    },
    benchmark: |context| {
        let mut total_hash = 0u64;
        let mut custom_metrics = HashMap::new();
        
        for size in [100, 1000, 10000, 100000] {
            let data = context.data.get(&format!("data_{}", size)).unwrap().as_int_array();
            
            // Test quicksort
            let start_cycles = rdtsc();
            let mut data_copy = data.clone();
            quicksort(&mut data_copy);
            let quicksort_cycles = rdtsc() - start_cycles;
            
            // Test mergesort
            let start_cycles = rdtsc();
            let mut data_copy = data.clone();
            mergesort(&mut data_copy);
            let mergesort_cycles = rdtsc() - start_cycles;
            
            // Record metrics
            custom_metrics.insert(format!("quicksort_cycles_{}", size), quicksort_cycles as f64);
            custom_metrics.insert(format!("mergesort_cycles_{}", size), mergesort_cycles as f64);
            
            // Update output hash
            total_hash ^= hash_vec(&data_copy);
        }
        
        BenchmarkFunctionResult {
            output_hash: total_hash,
            custom_metrics,
        }
    }
}
```

## Comparative Benchmarking

```tempo
// Framework para comparar Tempo con otros lenguajes
struct ComparativeBenchmarkSuite {
    benchmarks: Vec<LanguageComparison>,
    runtime_environments: HashMap<Language, RuntimeEnvironment>,
    result_normalizer: ResultNormalizer,
}

struct LanguageComparison {
    benchmark_name: String,
    implementations: HashMap<Language, ImplementationDetails>,
    workload_generator: fn() -> Workload,
    validation_function: fn(&[LanguageResult]) -> bool,
}

struct ImplementationDetails {
    source_file: PathBuf,
    compilation_command: String,
    execution_command: String,
    optimization_flags: Vec<String>,
}

impl ComparativeBenchmarkSuite {
    fn run_comparison(&mut self, benchmark_name: &str) -> Result<ComparisonReport, ComparisonError> {
        let benchmark = self.benchmarks.iter()
            .find(|b| b.benchmark_name == benchmark_name)
            .ok_or(ComparisonError::BenchmarkNotFound)?;
        
        let workload = (benchmark.workload_generator)();
        let mut results = HashMap::new();
        
        // Run benchmark for each language
        for (language, implementation) in &benchmark.implementations {
            let runtime = self.runtime_environments.get(language)
                .ok_or(ComparisonError::RuntimeNotConfigured)?;
            
            let result = self.run_language_benchmark(language, implementation, &workload, runtime)?;
            results.insert(*language, result);
        }
        
        // Validate results are equivalent
        let validation_results: Vec<_> = results.values().cloned().collect();
        if !(benchmark.validation_function)(&validation_results) {
            return Err(ComparisonError::ResultsNotEquivalent);
        }
        
        // Normalize results for comparison
        let normalized_results = self.result_normalizer.normalize_results(&results)?;
        
        // Generate comparison analysis
        let analysis = self.analyze_comparative_results(&normalized_results)?;
        
        Ok(ComparisonReport {
            benchmark_name: benchmark_name.to_string(),
            raw_results: results,
            normalized_results,
            analysis,
            workload_description: workload.description(),
        })
    }
    
    fn run_language_benchmark(
        &self,
        language: &Language,
        implementation: &ImplementationDetails,
        workload: &Workload,
        runtime: &RuntimeEnvironment
    ) -> Result<LanguageResult, ComparisonError> {
        // Setup environment
        runtime.setup_environment()?;
        
        // Compile if necessary
        if !implementation.compilation_command.is_empty() {
            let compilation_result = runtime.execute_command(&implementation.compilation_command)?;
            if !compilation_result.success {
                return Err(ComparisonError::CompilationFailed(compilation_result.stderr));
            }
        }
        
        // Warm up
        for _ in 0..5 {
            runtime.execute_command(&implementation.execution_command)?;
        }
        
        // Run benchmark iterations
        let mut execution_times = Vec::new();
        let mut memory_usage = Vec::new();
        
        for _ in 0..100 {
            let start_time = Instant::now();
            let start_memory = runtime.get_memory_usage()?;
            
            let execution_result = runtime.execute_command(&implementation.execution_command)?;
            
            let end_time = Instant::now();
            let end_memory = runtime.get_memory_usage()?;
            
            if !execution_result.success {
                return Err(ComparisonError::ExecutionFailed(execution_result.stderr));
            }
            
            execution_times.push(end_time - start_time);
            memory_usage.push(end_memory - start_memory);
        }
        
        Ok(LanguageResult {
            language: *language,
            execution_times,
            memory_usage,
            output: execution_result.stdout,
            compiler_version: runtime.get_compiler_version()?,
        })
    }
    
    fn analyze_comparative_results(&self, results: &HashMap<Language, NormalizedResult>) -> Result<ComparativeAnalysis, ComparisonError> {
        let tempo_result = results.get(&Language::Tempo)
            .ok_or(ComparisonError::TempoResultMissing)?;
        
        let mut language_comparisons = HashMap::new();
        
        for (language, result) in results {
            if *language == Language::Tempo {
                continue;
            }
            
            let comparison = LanguageComparison {
                speed_ratio: tempo_result.mean_execution_time / result.mean_execution_time,
                memory_ratio: tempo_result.mean_memory_usage / result.mean_memory_usage,
                determinism_score: self.calculate_determinism_score(result),
                predictability_score: self.calculate_predictability_score(result),
            };
            
            language_comparisons.insert(*language, comparison);
        }
        
        Ok(ComparativeAnalysis {
            tempo_baseline: tempo_result.clone(),
            language_comparisons,
            summary: self.generate_comparison_summary(&language_comparisons),
        })
    }
}

// Benchmarks específicos para casos de uso común
fn create_standard_benchmark_suite() -> Vec<DeterministicBenchmark> {
    vec![
        // Algorithm benchmarks
        benchmark! {
            name: "sorting_performance",
            description: "Sorting algorithms on various data sizes and patterns",
            iterations: 1000,
            setup: setup_sorting_data,
            benchmark: run_sorting_benchmarks
        },
        
        benchmark! {
            name: "hash_map_operations",
            description: "HashMap insert, lookup, and delete operations",
            iterations: 10000,
            setup: setup_hashmap_data,
            benchmark: run_hashmap_benchmarks
        },
        
        benchmark! {
            name: "string_processing",
            description: "String manipulation and parsing operations",
            iterations: 5000,
            setup: setup_string_data,
            benchmark: run_string_benchmarks
        },
        
        benchmark! {
            name: "matrix_multiplication",
            description: "Matrix operations with different sizes",
            iterations: 100,
            setup: setup_matrix_data,
            benchmark: run_matrix_benchmarks
        },
        
        benchmark! {
            name: "json_serialization",
            description: "JSON parsing and serialization",
            iterations: 1000,
            setup: setup_json_data,
            benchmark: run_json_benchmarks
        },
        
        benchmark! {
            name: "network_io_simulation",
            description: "Simulated network I/O with deterministic timing",
            iterations: 500,
            setup: setup_network_simulation,
            benchmark: run_network_benchmarks
        },
        
        benchmark! {
            name: "compression_algorithms",
            description: "Data compression and decompression",
            iterations: 100,
            setup: setup_compression_data,
            benchmark: run_compression_benchmarks
        },
        
        benchmark! {
            name: "concurrent_data_structures",
            description: "Thread-safe data structures performance",
            iterations: 1000,
            setup: setup_concurrent_data,
            benchmark: run_concurrent_benchmarks
        },
    ]
}
```

## Performance Regression Detection

```tempo
// Sistema automático de detección de regresiones
struct PerformanceRegressionDetector {
    baseline_database: BaselineDatabase,
    statistical_analyzer: StatisticalAnalyzer,
    alert_thresholds: AlertThresholds,
    notification_system: NotificationSystem,
}

struct PerformanceBaseline {
    benchmark_name: String,
    commit_hash: String,
    timestamp: u64,
    performance_metrics: PerformanceMetrics,
    environment_fingerprint: EnvironmentFingerprint,
}

struct PerformanceMetrics {
    mean_execution_time: Duration,
    mean_cpu_cycles: u64,
    mean_memory_usage: usize,
    cache_hit_rate: f64,
    determinism_score: f64,
    
    // Statistical measures
    standard_deviation: f64,
    confidence_interval_95: (f64, f64),
}

impl PerformanceRegressionDetector {
    fn check_for_regressions(&mut self, current_results: &[BenchmarkReport]) -> Result<RegressionReport, RegressionError> {
        let mut detected_regressions = Vec::new();
        let mut improvements = Vec::new();
        
        for report in current_results {
            let baseline = self.baseline_database.get_latest_baseline(&report.benchmark_name)?;
            
            let comparison = self.compare_with_baseline(&report, &baseline)?;
            
            match comparison.classification {
                PerformanceChange::Regression { severity, metrics } => {
                    detected_regressions.push(Regression {
                        benchmark_name: report.benchmark_name.clone(),
                        severity,
                        affected_metrics: metrics,
                        performance_delta: comparison.performance_delta,
                        statistical_significance: comparison.statistical_significance,
                    });
                },
                PerformanceChange::Improvement { metrics } => {
                    improvements.push(Improvement {
                        benchmark_name: report.benchmark_name.clone(),
                        improved_metrics: metrics,
                        performance_delta: comparison.performance_delta,
                    });
                },
                PerformanceChange::NoSignificantChange => {
                    // No action needed
                },
            }
        }
        
        // Generate alerts for significant regressions
        for regression in &detected_regressions {
            if regression.severity >= Severity::Warning {
                self.notification_system.send_regression_alert(regression)?;
            }
        }
        
        Ok(RegressionReport {
            commit_hash: get_current_commit_hash(),
            test_timestamp: get_timestamp(),
            detected_regressions,
            improvements,
            baseline_comparison_count: current_results.len(),
        })
    }
    
    fn compare_with_baseline(&self, current: &BenchmarkReport, baseline: &PerformanceBaseline) -> Result<PerformanceComparison, RegressionError> {
        let current_metrics = self.extract_performance_metrics(current)?;
        
        // Calculate performance deltas
        let execution_time_delta = (current_metrics.mean_execution_time.as_nanos() as f64 - 
                                   baseline.performance_metrics.mean_execution_time.as_nanos() as f64) /
                                   baseline.performance_metrics.mean_execution_time.as_nanos() as f64;
        
        let memory_delta = (current_metrics.mean_memory_usage as f64 - 
                           baseline.performance_metrics.mean_memory_usage as f64) /
                           baseline.performance_metrics.mean_memory_usage as f64;
        
        let cycles_delta = (current_metrics.mean_cpu_cycles as f64 - 
                           baseline.performance_metrics.mean_cpu_cycles as f64) /
                           baseline.performance_metrics.mean_cpu_cycles as f64;
        
        // Statistical significance testing
        let statistical_significance = self.statistical_analyzer.calculate_significance(
            &current_metrics,
            &baseline.performance_metrics
        )?;
        
        // Classify change
        let classification = self.classify_performance_change(
            execution_time_delta,
            memory_delta,
            cycles_delta,
            statistical_significance
        );
        
        Ok(PerformanceComparison {
            performance_delta: PerformanceDelta {
                execution_time_percent: execution_time_delta * 100.0,
                memory_usage_percent: memory_delta * 100.0,
                cpu_cycles_percent: cycles_delta * 100.0,
            },
            statistical_significance,
            classification,
        })
    }
    
    fn classify_performance_change(
        &self,
        time_delta: f64,
        memory_delta: f64,
        cycles_delta: f64,
        significance: StatisticalSignificance
    ) -> PerformanceChange {
        // Only consider changes that are statistically significant
        if significance.p_value > 0.05 {
            return PerformanceChange::NoSignificantChange;
        }
        
        let mut regression_metrics = Vec::new();
        let mut improvement_metrics = Vec::new();
        
        // Check execution time
        if time_delta > self.alert_thresholds.execution_time_regression_threshold {
            regression_metrics.push(MetricType::ExecutionTime);
        } else if time_delta < -self.alert_thresholds.execution_time_improvement_threshold {
            improvement_metrics.push(MetricType::ExecutionTime);
        }
        
        // Check memory usage
        if memory_delta > self.alert_thresholds.memory_regression_threshold {
            regression_metrics.push(MetricType::MemoryUsage);
        } else if memory_delta < -self.alert_thresholds.memory_improvement_threshold {
            improvement_metrics.push(MetricType::MemoryUsage);
        }
        
        // Check CPU cycles
        if cycles_delta > self.alert_thresholds.cycles_regression_threshold {
            regression_metrics.push(MetricType::CpuCycles);
        } else if cycles_delta < -self.alert_thresholds.cycles_improvement_threshold {
            improvement_metrics.push(MetricType::CpuCycles);
        }
        
        // Determine overall classification
        if !regression_metrics.is_empty() {
            let severity = self.calculate_regression_severity(&regression_metrics, time_delta, memory_delta, cycles_delta);
            PerformanceChange::Regression {
                severity,
                metrics: regression_metrics,
            }
        } else if !improvement_metrics.is_empty() {
            PerformanceChange::Improvement {
                metrics: improvement_metrics,
            }
        } else {
            PerformanceChange::NoSignificantChange
        }
    }
    
    fn update_baseline(&mut self, benchmark_report: &BenchmarkReport) -> Result<(), RegressionError> {
        let performance_metrics = self.extract_performance_metrics(benchmark_report)?;
        let environment_fingerprint = self.get_environment_fingerprint()?;
        
        let baseline = PerformanceBaseline {
            benchmark_name: benchmark_report.benchmark_name.clone(),
            commit_hash: get_current_commit_hash(),
            timestamp: get_timestamp(),
            performance_metrics,
            environment_fingerprint,
        };
        
        self.baseline_database.store_baseline(baseline)?;
        
        Ok(())
    }
}
```

## Benchmarking de Aplicaciones Reales

```tempo
// Benchmarks para aplicaciones del mundo real
struct RealWorldBenchmarkSuite {
    web_server_benchmark: WebServerBenchmark,
    database_benchmark: DatabaseBenchmark,
    machine_learning_benchmark: MLBenchmark,
    crypto_benchmark: CryptographyBenchmark,
    compiler_benchmark: CompilerBenchmark,
}

// Benchmark de servidor web
struct WebServerBenchmark {
    server_config: ServerConfig,
    load_generators: Vec<LoadGenerator>,
    scenarios: Vec<LoadScenario>,
}

impl WebServerBenchmark {
    fn run_web_server_benchmark(&mut self) -> Result<WebServerBenchmarkReport, BenchmarkError> {
        // Start Tempo web server
        let server = self.start_tempo_web_server()?;
        
        let mut scenario_results = Vec::new();
        
        for scenario in &self.scenarios {
            let result = self.run_load_scenario(scenario, &server)?;
            scenario_results.push(result);
        }
        
        // Compare with other web servers
        let comparative_results = self.run_comparative_web_server_benchmarks()?;
        
        server.shutdown()?;
        
        Ok(WebServerBenchmarkReport {
            tempo_results: scenario_results,
            comparative_results,
            server_config: self.server_config.clone(),
        })
    }
    
    fn run_load_scenario(&self, scenario: &LoadScenario, server: &WebServer) -> Result<LoadScenarioResult, BenchmarkError> {
        let mut generators = Vec::new();
        
        // Start load generators
        for generator_config in &self.load_generators {
            let generator = LoadGenerator::new(generator_config.clone());
            generators.push(generator);
        }
        
        // Warm up
        for generator in &mut generators {
            generator.warm_up(Duration::from_secs(10))?;
        }
        
        // Run actual load test
        let start_time = Instant::now();
        
        for generator in &mut generators {
            generator.start_load_test(scenario)?;
        }
        
        // Wait for test duration
        sleep(scenario.duration);
        
        // Stop generators and collect results
        let mut generator_results = Vec::new();
        for generator in &mut generators {
            let result = generator.stop_and_get_results()?;
            generator_results.push(result);
        }
        
        let end_time = Instant::now();
        
        // Aggregate results
        let aggregated_result = self.aggregate_load_results(&generator_results)?;
        
        Ok(LoadScenarioResult {
            scenario: scenario.clone(),
            duration: end_time - start_time,
            total_requests: aggregated_result.total_requests,
            successful_requests: aggregated_result.successful_requests,
            failed_requests: aggregated_result.failed_requests,
            requests_per_second: aggregated_result.requests_per_second,
            response_time_percentiles: aggregated_result.response_time_percentiles,
            server_resource_usage: server.get_resource_usage()?,
        })
    }
}

// Benchmark de compilador
struct CompilerBenchmark {
    test_projects: Vec<TestProject>,
    compiler_configs: Vec<CompilerConfig>,
}

impl CompilerBenchmark {
    fn run_compiler_benchmark(&mut self) -> Result<CompilerBenchmarkReport, BenchmarkError> {
        let mut results = HashMap::new();
        
        for project in &self.test_projects {
            let mut project_results = HashMap::new();
            
            for config in &self.compiler_configs {
                let result = self.compile_project_with_config(project, config)?;
                project_results.insert(config.name.clone(), result);
            }
            
            results.insert(project.name.clone(), project_results);
        }
        
        // Compare with other compilers
        let comparative_results = self.run_comparative_compiler_benchmarks()?;
        
        Ok(CompilerBenchmarkReport {
            tempo_results: results,
            comparative_results,
        })
    }
    
    fn compile_project_with_config(&self, project: &TestProject, config: &CompilerConfig) -> Result<CompilationResult, BenchmarkError> {
        let start_time = Instant::now();
        let start_memory = get_memory_usage();
        
        // Run compilation
        let compilation_output = run_tempo_compiler(
            &project.source_directory,
            &config.flags,
            &config.optimization_level
        )?;
        
        let end_time = Instant::now();
        let end_memory = get_memory_usage();
        
        Ok(CompilationResult {
            compilation_time: end_time - start_time,
            memory_usage: end_memory - start_memory,
            binary_size: compilation_output.binary_size,
            compilation_success: compilation_output.success,
            error_messages: compilation_output.errors,
            warnings: compilation_output.warnings,
            
            // Tempo-specific metrics
            wcet_analysis_time: compilation_output.wcet_analysis_time,
            determinism_verification_time: compilation_output.determinism_verification_time,
            optimization_passes_applied: compilation_output.optimization_passes,
        })
    }
}
```

## Práctica: Benchmark Suite Completa

Implementa una suite completa de benchmarks que incluya:

1. Microbenchmarks para operaciones básicas
2. Algoritmos fundamentales (sorting, searching, graph algorithms)
3. Aplicaciones reales (web server, database, compiler)
4. Comparación con otros lenguajes
5. Regression detection automática

## Ejercicio Final

Diseña un sistema completo de performance engineering que:

1. Ejecute benchmarks automáticamente en CI/CD
2. Detecte regresiones antes del merge
3. Genere reportes comparativos automáticos
4. Mantenga historical performance data
5. Proporcione insights para optimización
6. Integre con herramientas de profiling

**Próxima lección**: Casos de Uso Avanzados y Proyectos Finales