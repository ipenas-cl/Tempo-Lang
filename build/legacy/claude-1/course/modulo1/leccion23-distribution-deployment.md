╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 23: Distribución y Deployment

## Objetivos
- Crear sistema de distribución determinística
- Implementar deployment automático y rollback
- Diseñar infrastructure-as-code para Tempo
- Desarrollar monitoring y observability

## Teoría: Deployment Determinístico

El deployment de aplicaciones Tempo debe garantizar:

1. **Reproducibilidad exacta** en cualquier entorno
2. **Rollback inmediato** sin pérdida de determinismo  
3. **Zero-downtime deployment** con state preservation
4. **Configuration management** determinística

## Sistema de Build Reproducible

```tempo
// Build system determinístico
struct ReproducibleBuilder {
    build_environment: BuildEnvironment,
    dependency_resolver: DependencyResolver,
    artifact_cache: ArtifactCache,
    build_metadata: BuildMetadata,
}

struct BuildEnvironment {
    compiler_version: SemanticVersion,
    target_triple: String,
    build_flags: Vec<String>,
    environment_hash: Hash256,
    timestamp_override: Option<u64>, // For deterministic builds
}

struct BuildMetadata {
    source_hash: Hash256,
    dependency_hash: Hash256,
    build_environment_hash: Hash256,
    compiler_fingerprint: Hash256,
    build_timestamp: u64,
    reproducibility_proof: ReproducibilityProof,
}

impl ReproducibleBuilder {
    fn build_application(&mut self, source_dir: &Path) -> Result<BuildArtifact, BuildError> {
        // 1. Verify source integrity
        let source_hash = self.calculate_source_hash(source_dir)?;
        
        // 2. Resolve dependencies deterministically
        let dependencies = self.dependency_resolver.resolve_dependencies(source_dir)?;
        let dependency_hash = self.calculate_dependency_hash(&dependencies)?;
        
        // 3. Check cache first
        let cache_key = CacheKey {
            source_hash: source_hash.clone(),
            dependency_hash: dependency_hash.clone(),
            environment_hash: self.build_environment.environment_hash.clone(),
        };
        
        if let Some(cached_artifact) = self.artifact_cache.get(&cache_key) {
            return Ok(cached_artifact);
        }
        
        // 4. Set deterministic build environment
        self.setup_deterministic_environment()?;
        
        // 5. Execute build
        let artifact = self.execute_build(source_dir, &dependencies)?;
        
        // 6. Verify build reproducibility
        let reproducibility_proof = self.verify_reproducibility(&artifact)?;
        
        // 7. Create build metadata
        let metadata = BuildMetadata {
            source_hash,
            dependency_hash,
            build_environment_hash: self.build_environment.environment_hash.clone(),
            compiler_fingerprint: self.get_compiler_fingerprint(),
            build_timestamp: get_deterministic_timestamp(),
            reproducibility_proof,
        };
        
        let final_artifact = BuildArtifact {
            binary: artifact.binary,
            metadata,
            signatures: self.sign_artifact(&artifact)?,
        };
        
        // 8. Cache result
        self.artifact_cache.store(cache_key, &final_artifact);
        
        Ok(final_artifact)
    }
    
    fn setup_deterministic_environment(&mut self) -> Result<(), BuildError> {
        // Override timestamp para builds reproducibles
        if let Some(timestamp) = self.build_environment.timestamp_override {
            set_build_timestamp(timestamp);
        }
        
        // Set deterministic random seed
        set_build_random_seed(0x12345678);
        
        // Clear non-deterministic environment variables
        clear_env_var("USER");
        clear_env_var("HOME");
        clear_env_var("PWD");
        
        // Set deterministic locale
        set_env_var("LC_ALL", "C");
        set_env_var("TZ", "UTC");
        
        Ok(())
    }
    
    fn verify_reproducibility(&self, artifact: &BuildArtifact) -> Result<ReproducibilityProof, BuildError> {
        // Build twice and compare results
        let second_build = self.execute_build_isolated(&artifact.source_info)?;
        
        if artifact.binary != second_build.binary {
            return Err(BuildError::NonReproducible {
                first_hash: hash(&artifact.binary),
                second_hash: hash(&second_build.binary),
            });
        }
        
        Ok(ReproducibilityProof {
            verified_at: get_timestamp(),
            verification_method: "double-build",
            hash_algorithm: "SHA-256",
            reproducible: true,
        })
    }
}

// Dependency resolution determinística
struct DependencyResolver {
    package_registry: PackageRegistry,
    version_constraints: VersionConstraints,
    resolution_cache: ResolutionCache,
}

impl DependencyResolver {
    fn resolve_dependencies(&mut self, project_dir: &Path) -> Result<ResolvedDependencies, DependencyError> {
        let manifest = self.parse_manifest(project_dir)?;
        
        // SAT solver para dependency resolution
        let mut solver = SATSolver::new();
        
        // Add constraints for each dependency
        for dep in &manifest.dependencies {
            let versions = self.package_registry.get_available_versions(&dep.name)?;
            let compatible_versions = self.filter_compatible_versions(&versions, &dep.version_constraint)?;
            
            solver.add_dependency_constraint(&dep.name, compatible_versions);
        }
        
        // Add conflict constraints
        for conflict in &manifest.conflicts {
            solver.add_conflict_constraint(&conflict.package_a, &conflict.package_b);
        }
        
        // Solve for optimal solution (prefer newer stable versions)
        let solution = solver.solve_with_preference(VersionPreference::NewestStable)?;
        
        // Download and verify packages
        let mut resolved = ResolvedDependencies::new();
        for (package_name, version) in solution {
            let package = self.download_and_verify_package(&package_name, &version)?;
            resolved.add_package(package);
        }
        
        Ok(resolved)
    }
    
    fn download_and_verify_package(&mut self, name: &str, version: &Version) -> Result<Package, DependencyError> {
        // Check local cache first
        if let Some(cached) = self.package_registry.get_cached_package(name, version) {
            return Ok(cached);
        }
        
        // Download from registry
        let package_data = self.package_registry.download_package(name, version)?;
        
        // Verify signatures
        let signatures = self.package_registry.get_package_signatures(name, version)?;
        self.verify_package_signatures(&package_data, &signatures)?;
        
        // Verify content hash
        let expected_hash = self.package_registry.get_package_hash(name, version)?;
        let actual_hash = hash(&package_data);
        if expected_hash != actual_hash {
            return Err(DependencyError::HashMismatch {
                package: name.to_string(),
                expected: expected_hash,
                actual: actual_hash,
            });
        }
        
        let package = Package::from_data(name, version, package_data)?;
        
        // Cache for future use
        self.package_registry.cache_package(&package);
        
        Ok(package)
    }
}
```

## Container Deployment Determinístico

```tempo
// Container system optimizado para Tempo
struct TempoContainer {
    image: ContainerImage,
    runtime_config: RuntimeConfig,
    resource_limits: ResourceLimits,
    network_config: NetworkConfig,
    storage_config: StorageConfig,
}

struct ContainerImage {
    layers: Vec<ImageLayer>,
    manifest: ImageManifest,
    signature: ContainerSignature,
    reproducibility_metadata: BuildMetadata,
}

struct RuntimeConfig {
    memory_pool_sizes: HashMap<PoolType, usize>,
    cpu_affinity: CpuSet,
    deterministic_scheduler: SchedulerConfig,
    environment_variables: BTreeMap<String, String>, // Sorted for determinism
}

impl TempoContainer {
    fn deploy(&mut self, target_environment: &Environment) -> Result<Deployment, DeploymentError> {
        // 1. Verify container image integrity
        self.verify_image_integrity()?;
        
        // 2. Check resource requirements
        target_environment.verify_resource_availability(&self.resource_limits)?;
        
        // 3. Setup deterministic runtime environment
        let runtime = self.setup_deterministic_runtime(target_environment)?;
        
        // 4. Deploy with zero-downtime strategy
        let deployment = self.execute_zero_downtime_deployment(&runtime)?;
        
        // 5. Verify deployment health
        self.verify_deployment_health(&deployment)?;
        
        Ok(deployment)
    }
    
    fn setup_deterministic_runtime(&self, environment: &Environment) -> Result<Runtime, RuntimeError> {
        let mut runtime = Runtime::new();
        
        // Configure memory pools
        for (pool_type, size) in &self.runtime_config.memory_pool_sizes {
            runtime.configure_memory_pool(*pool_type, *size);
        }
        
        // Set CPU affinity for deterministic scheduling
        runtime.set_cpu_affinity(self.runtime_config.cpu_affinity);
        
        // Configure network with deterministic settings
        runtime.configure_network(&self.network_config)?;
        
        // Setup storage with consistency guarantees
        runtime.configure_storage(&self.storage_config)?;
        
        // Set deterministic environment variables
        for (key, value) in &self.runtime_config.environment_variables {
            runtime.set_environment_variable(key, value);
        }
        
        Ok(runtime)
    }
    
    fn execute_zero_downtime_deployment(&self, runtime: &Runtime) -> Result<Deployment, DeploymentError> {
        // Blue-green deployment strategy
        let current_deployment = runtime.get_current_deployment()?;
        let new_deployment = runtime.create_deployment_slot()?;
        
        // Deploy to new slot
        new_deployment.install_application(&self.image)?;
        new_deployment.configure_runtime(&self.runtime_config)?;
        
        // Health check new deployment
        new_deployment.start_health_checks()?;
        
        // Wait for health checks to pass
        self.wait_for_health_checks(&new_deployment, Duration::from_secs(30))?;
        
        // Switch traffic atomically
        runtime.switch_traffic_to_deployment(&new_deployment)?;
        
        // Keep old deployment for rollback
        runtime.mark_deployment_for_cleanup(&current_deployment, Duration::from_minutes(10))?;
        
        Ok(new_deployment)
    }
    
    fn rollback_deployment(&self, runtime: &Runtime, target_deployment: &Deployment) -> Result<(), RollbackError> {
        // Instant rollback to previous known-good state
        let rollback_start = Instant::now();
        
        // Stop current deployment
        runtime.stop_current_deployment()?;
        
        // Switch to target deployment
        runtime.switch_traffic_to_deployment(target_deployment)?;
        
        // Verify rollback success
        self.verify_deployment_health(target_deployment)?;
        
        let rollback_duration = rollback_start.elapsed();
        
        // Log rollback metrics
        log::info!("Rollback completed in {:?}", rollback_duration);
        
        Ok(())
    }
}

// Registry distribuido para artefactos
struct DistributedRegistry {
    nodes: Vec<RegistryNode>,
    consensus_protocol: ConsensusProtocol,
    replication_factor: usize,
    artifact_store: ArtifactStore,
}

impl DistributedRegistry {
    fn store_artifact(&mut self, artifact: &BuildArtifact) -> Result<ArtifactId, RegistryError> {
        let artifact_id = ArtifactId::from_hash(&artifact.metadata.source_hash);
        
        // Validate artifact before storing
        self.validate_artifact(artifact)?;
        
        // Store in multiple nodes for redundancy
        let storage_nodes = self.select_storage_nodes(&artifact_id, self.replication_factor)?;
        
        let mut successful_stores = 0;
        for node in storage_nodes {
            match node.store_artifact(&artifact_id, artifact) {
                Ok(_) => successful_stores += 1,
                Err(e) => log::warn!("Failed to store in node {}: {}", node.id(), e),
            }
        }
        
        // Require majority success
        if successful_stores < (self.replication_factor / 2 + 1) {
            return Err(RegistryError::InsufficientReplicas);
        }
        
        // Update global index via consensus
        self.consensus_protocol.propose_index_update(IndexUpdate {
            artifact_id: artifact_id.clone(),
            metadata: artifact.metadata.clone(),
            storage_nodes: storage_nodes.iter().map(|n| n.id()).collect(),
        })?;
        
        Ok(artifact_id)
    }
    
    fn retrieve_artifact(&self, artifact_id: &ArtifactId) -> Result<BuildArtifact, RegistryError> {
        // Get storage locations from index
        let index_entry = self.consensus_protocol.get_index_entry(artifact_id)?;
        
        // Try to retrieve from available nodes
        for node_id in &index_entry.storage_nodes {
            if let Some(node) = self.get_node(node_id) {
                match node.retrieve_artifact(artifact_id) {
                    Ok(artifact) => {
                        // Verify integrity
                        if self.verify_artifact_integrity(&artifact)? {
                            return Ok(artifact);
                        }
                    },
                    Err(e) => log::warn!("Failed to retrieve from node {}: {}", node_id, e),
                }
            }
        }
        
        Err(RegistryError::ArtifactNotAvailable)
    }
}
```

## Configuration Management

```tempo
// Configuration management determinística
struct ConfigurationManager {
    config_repository: ConfigRepository,
    environment_configs: HashMap<Environment, EnvironmentConfig>,
    secret_manager: SecretManager,
    config_validator: ConfigValidator,
}

struct EnvironmentConfig {
    name: String,
    variables: BTreeMap<String, ConfigValue>,
    secrets: BTreeMap<String, SecretReference>,
    feature_flags: BTreeMap<String, bool>,
    resource_limits: ResourceLimits,
}

enum ConfigValue {
    String(String),
    Integer(i64),
    Float(f64),
    Boolean(bool),
    Array(Vec<ConfigValue>),
    Object(BTreeMap<String, ConfigValue>),
}

impl ConfigurationManager {
    fn generate_environment_config(&mut self, environment: &Environment, application: &Application) -> Result<EnvironmentConfig, ConfigError> {
        let mut config = EnvironmentConfig {
            name: environment.name.clone(),
            variables: BTreeMap::new(),
            secrets: BTreeMap::new(),
            feature_flags: BTreeMap::new(),
            resource_limits: environment.default_resource_limits.clone(),
        };
        
        // Load base configuration
        let base_config = self.config_repository.get_base_config(application)?;
        config.merge_config(&base_config);
        
        // Apply environment-specific overrides
        if let Some(env_overrides) = self.config_repository.get_environment_overrides(environment, application)? {
            config.merge_config(&env_overrides);
        }
        
        // Resolve secret references
        for (key, secret_ref) in &config.secrets {
            let secret_value = self.secret_manager.retrieve_secret(secret_ref)?;
            config.variables.insert(key.clone(), ConfigValue::String(secret_value));
        }
        
        // Validate final configuration
        self.config_validator.validate_config(&config, application)?;
        
        // Generate deterministic hash for configuration versioning
        let config_hash = self.calculate_config_hash(&config);
        
        Ok(config)
    }
    
    fn apply_configuration(&mut self, deployment: &Deployment, config: &EnvironmentConfig) -> Result<(), ConfigError> {
        // Apply configuration atomically
        let transaction = deployment.begin_config_transaction()?;
        
        // Set environment variables
        for (key, value) in &config.variables {
            transaction.set_environment_variable(key, &value.to_string())?;
        }
        
        // Configure resource limits
        transaction.set_resource_limits(&config.resource_limits)?;
        
        // Apply feature flags
        for (flag_name, enabled) in &config.feature_flags {
            transaction.set_feature_flag(flag_name, *enabled)?;
        }
        
        // Commit configuration changes
        transaction.commit()?;
        
        // Verify configuration was applied correctly
        self.verify_configuration_applied(deployment, config)?;
        
        Ok(())
    }
    
    fn calculate_config_hash(&self, config: &EnvironmentConfig) -> Hash256 {
        let mut hasher = Sha256::new();
        
        // Hash all configuration in deterministic order
        for (key, value) in &config.variables {
            hasher.update(key.as_bytes());
            hasher.update(value.to_deterministic_bytes());
        }
        
        for (key, value) in &config.feature_flags {
            hasher.update(key.as_bytes());
            hasher.update(&[if *value { 1 } else { 0 }]);
        }
        
        hasher.update(config.resource_limits.to_bytes());
        
        Hash256::from(hasher.finalize())
    }
}

// Secret management seguro
struct SecretManager {
    vault_client: VaultClient,
    encryption_key: EncryptionKey,
    secret_cache: LRUCache<SecretReference, EncryptedSecret>,
}

impl SecretManager {
    fn store_secret(&mut self, name: &str, value: &str, environment: &Environment) -> Result<SecretReference, SecretError> {
        // Encrypt secret before storing
        let encrypted_value = self.encrypt_secret(value)?;
        
        // Store in vault with environment scoping
        let secret_path = format!("{}/{}", environment.name, name);
        self.vault_client.store_encrypted_secret(&secret_path, &encrypted_value)?;
        
        // Create reference
        let secret_ref = SecretReference {
            path: secret_path,
            version: self.vault_client.get_secret_version(&secret_path)?,
            environment: environment.name.clone(),
        };
        
        Ok(secret_ref)
    }
    
    fn retrieve_secret(&mut self, secret_ref: &SecretReference) -> Result<String, SecretError> {
        // Check cache first
        if let Some(cached_secret) = self.secret_cache.get(secret_ref) {
            return self.decrypt_secret(cached_secret);
        }
        
        // Retrieve from vault
        let encrypted_secret = self.vault_client.retrieve_secret(&secret_ref.path, secret_ref.version)?;
        
        // Cache encrypted version
        self.secret_cache.put(secret_ref.clone(), encrypted_secret.clone());
        
        // Decrypt and return
        self.decrypt_secret(&encrypted_secret)
    }
    
    fn rotate_secrets(&mut self, environment: &Environment) -> Result<SecretRotationReport, SecretError> {
        let mut rotation_report = SecretRotationReport::new();
        
        // Get all secrets for environment
        let secrets = self.vault_client.list_secrets(&environment.name)?;
        
        for secret_ref in secrets {
            match self.rotate_single_secret(&secret_ref) {
                Ok(new_ref) => {
                    rotation_report.add_success(secret_ref, new_ref);
                },
                Err(e) => {
                    rotation_report.add_failure(secret_ref, e);
                },
            }
        }
        
        Ok(rotation_report)
    }
}
```

## Monitoring y Observability

```tempo
// Sistema de observability determinística
struct ObservabilityStack {
    metrics_collector: MetricsCollector,
    tracing_system: TracingSystem,
    logging_system: StructuredLogging,
    alerting_system: AlertManager,
}

struct MetricsCollector {
    metrics_registry: MetricsRegistry,
    exporters: Vec<MetricsExporter>,
    collection_interval: Duration,
    metric_retention: Duration,
}

impl MetricsCollector {
    fn collect_application_metrics(&mut self, deployment: &Deployment) -> Result<MetricsBatch, MetricsError> {
        let mut batch = MetricsBatch::new();
        
        // Collect deterministic metrics
        let runtime_metrics = deployment.get_runtime_metrics()?;
        batch.add_gauge("tempo.memory.pool_usage", runtime_metrics.memory_pool_usage);
        batch.add_gauge("tempo.memory.high_water_mark", runtime_metrics.memory_high_water_mark);
        batch.add_counter("tempo.requests.total", runtime_metrics.total_requests);
        batch.add_histogram("tempo.request.duration", runtime_metrics.request_durations);
        batch.add_histogram("tempo.wcet.actual", runtime_metrics.actual_execution_times);
        batch.add_gauge("tempo.wcet.budget_utilization", runtime_metrics.wcet_budget_utilization);
        
        // Performance metrics
        batch.add_counter("tempo.cache.hits", runtime_metrics.cache_hits);
        batch.add_counter("tempo.cache.misses", runtime_metrics.cache_misses);
        batch.add_histogram("tempo.gc.pause_time", runtime_metrics.gc_pause_times);
        
        // Determinism metrics
        batch.add_counter("tempo.determinism.violations", runtime_metrics.determinism_violations);
        batch.add_gauge("tempo.timing.variance", runtime_metrics.timing_variance);
        
        // Add metadata
        batch.add_label("deployment_id", &deployment.id());
        batch.add_label("environment", &deployment.environment());
        batch.add_label("application", &deployment.application_name());
        batch.add_timestamp(get_deterministic_timestamp());
        
        Ok(batch)
    }
    
    fn export_metrics(&mut self, batch: &MetricsBatch) -> Result<(), MetricsError> {
        for exporter in &mut self.exporters {
            exporter.export_batch(batch)?;
        }
        Ok(())
    }
}

// Tracing determinístico
struct TracingSystem {
    trace_collector: TraceCollector,
    span_processor: SpanProcessor,
    trace_storage: TraceStorage,
}

impl TracingSystem {
    fn create_deterministic_span(&mut self, operation_name: &str) -> DeterministicSpan {
        let span_id = self.generate_deterministic_span_id();
        let trace_id = self.get_current_trace_id();
        
        DeterministicSpan {
            span_id,
            trace_id,
            operation_name: operation_name.to_string(),
            start_time: get_deterministic_timestamp(),
            start_cycles: rdtsc(),
            parent_span_id: self.get_current_span_id(),
            attributes: BTreeMap::new(),
            events: Vec::new(),
        }
    }
    
    fn finish_span(&mut self, mut span: DeterministicSpan) -> Result<(), TracingError> {
        span.end_time = Some(get_deterministic_timestamp());
        span.end_cycles = Some(rdtsc());
        span.duration_cycles = span.end_cycles.unwrap() - span.start_cycles;
        
        // Add determinism verification
        span.add_attribute("determinism.verified", true);
        span.add_attribute("determinism.timing_variance", self.calculate_timing_variance(&span));
        
        self.span_processor.process_span(span)?;
        
        Ok(())
    }
}

// Structured logging
struct StructuredLogging {
    log_appenders: Vec<LogAppender>,
    log_level: LogLevel,
    structured_fields: BTreeMap<String, String>,
}

impl StructuredLogging {
    fn log_deterministic_event(&mut self, level: LogLevel, message: &str, fields: &BTreeMap<String, Value>) -> Result<(), LogError> {
        let mut log_entry = LogEntry {
            timestamp: get_deterministic_timestamp(),
            level,
            message: message.to_string(),
            fields: self.structured_fields.clone(),
            trace_id: self.get_current_trace_id(),
            span_id: self.get_current_span_id(),
        };
        
        // Merge additional fields
        for (key, value) in fields {
            log_entry.fields.insert(key.clone(), value.to_string());
        }
        
        // Add determinism context
        log_entry.fields.insert("determinism.enabled".to_string(), "true".to_string());
        log_entry.fields.insert("timing.cycles".to_string(), rdtsc().to_string());
        
        for appender in &mut self.log_appenders {
            appender.append_log(&log_entry)?;
        }
        
        Ok(())
    }
}
```

## Práctica: Pipeline de CI/CD Completo

Implementa un pipeline completo de CI/CD para aplicaciones Tempo que incluya:

1. Build reproducible con verificación
2. Testing automático en múltiples entornos
3. Deployment con zero-downtime
4. Rollback automático en caso de fallas
5. Monitoring y alerting integrado

## Ejercicio Final

Diseña una plataforma de deployment distribuida que:

1. Maneje múltiples regiones geográficas
2. Implemente disaster recovery automático
3. Tenga configuration management centralizada
4. Soporte A/B testing determinístico
5. Proporcione observability completa

**Próxima lección**: Interoperabilidad y Integración