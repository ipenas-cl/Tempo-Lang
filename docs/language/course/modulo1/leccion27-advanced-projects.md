╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 27: Casos de Uso Avanzados y Proyectos Finales

## Objetivos
- Implementar proyectos complejos en Chronos
- Demostrar capacidades avanzadas del lenguaje
- Crear aplicaciones del mundo real
- Integrar todos los conceptos aprendidos

## Proyecto 1: Trading Engine Determinístico

```tempo
// High-frequency trading engine con garantías determinísticas
struct DeterministicTradingEngine {
    order_book: OrderBook,
    risk_manager: RiskManager,
    market_data_feed: MarketDataFeed,
    execution_engine: ExecutionEngine,
    latency_monitor: LatencyMonitor,
    
    // Configuración determinística
    max_order_processing_time: Duration,
    deterministic_scheduler: TradingScheduler,
    memory_pool: TradingMemoryPool,
}

struct OrderBook {
    instrument: String,
    bids: BTreeMap<Price, OrderLevel>,
    asks: BTreeMap<Price, OrderLevel>,
    last_update_sequence: u64,
    total_bid_volume: Volume,
    total_ask_volume: Volume,
}

struct Order {
    order_id: OrderId,
    client_id: ClientId,
    instrument: String,
    side: OrderSide,
    order_type: OrderType,
    price: Price,
    quantity: Volume,
    time_in_force: TimeInForce,
    timestamp: DeterministicTimestamp,
}

impl DeterministicTradingEngine {
    fn process_order(&mut self, order: Order) -> Result<OrderResponse, TradingError> {
        let processing_start = self.latency_monitor.start_timing();
        
        // 1. Risk validation (must complete within deterministic time)
        let risk_check = timed_execution!(
            self.max_order_processing_time / 4,
            self.risk_manager.validate_order(&order)
        )?;
        
        if !risk_check.approved {
            return Ok(OrderResponse::Rejected {
                order_id: order.order_id,
                reason: risk_check.rejection_reason,
                processing_time: processing_start.elapsed(),
            });
        }
        
        // 2. Order book matching (deterministic algorithm)
        let matching_result = timed_execution!(
            self.max_order_processing_time / 2,
            self.order_book.match_order(&order)
        )?;
        
        // 3. Trade execution and reporting
        let executions = if !matching_result.fills.is_empty() {
            timed_execution!(
                self.max_order_processing_time / 4,
                self.execution_engine.execute_trades(&matching_result.fills)
            )?
        } else {
            Vec::new()
        };
        
        // 4. Update order book state
        self.order_book.apply_matching_result(&matching_result);
        
        let processing_time = processing_start.elapsed();
        
        // Verify WCET constraint
        if processing_time > self.max_order_processing_time {
            log_wcet_violation!("Order processing", processing_time, self.max_order_processing_time);
        }
        
        Ok(OrderResponse::Processed {
            order_id: order.order_id,
            fills: executions,
            remaining_quantity: matching_result.remaining_quantity,
            processing_time,
        })
    }
    
    fn process_market_data(&mut self, market_data: MarketData) -> Result<(), TradingError> {
        let update_start = rdtsc();
        
        // Update order book with deterministic ordering
        match market_data.update_type {
            UpdateType::NewLevel { side, price, volume } => {
                self.order_book.add_level(side, price, volume);
            },
            UpdateType::UpdateLevel { side, price, new_volume } => {
                self.order_book.update_level(side, price, new_volume);
            },
            UpdateType::DeleteLevel { side, price } => {
                self.order_book.remove_level(side, price);
            },
            UpdateType::Trade { price, volume, aggressor_side } => {
                self.order_book.record_trade(price, volume, aggressor_side);
            },
        }
        
        // Trigger any dependent calculations
        self.recalculate_derived_data();
        
        let update_cycles = rdtsc() - update_start;
        self.latency_monitor.record_market_data_latency(update_cycles);
        
        Ok(())
    }
    
    fn recalculate_derived_data(&mut self) {
        // Calculate VWAP (Volume Weighted Average Price)
        let vwap = self.calculate_vwap();
        
        // Update spread metrics
        let spread = self.calculate_spread();
        
        // Update liquidity metrics
        let liquidity = self.calculate_liquidity_metrics();
        
        // All calculations must be deterministic
        self.market_metrics = MarketMetrics {
            vwap,
            spread,
            liquidity,
            last_update: self.get_deterministic_timestamp(),
        };
    }
}

// Risk manager con límites determinísticos
struct RiskManager {
    position_limits: HashMap<ClientId, PositionLimits>,
    exposure_calculator: ExposureCalculator,
    risk_parameters: RiskParameters,
}

impl RiskManager {
    fn validate_order(&self, order: &Order) -> Result<RiskValidation, RiskError> {
        let client_limits = self.position_limits.get(&order.client_id)
            .ok_or(RiskError::ClientNotFound)?;
        
        // Check position limits
        let current_position = self.get_current_position(&order.client_id, &order.instrument)?;
        let new_position = self.calculate_new_position(&current_position, order);
        
        if !self.is_within_position_limits(&new_position, client_limits) {
            return Ok(RiskValidation {
                approved: false,
                rejection_reason: "Position limit exceeded".to_string(),
            });
        }
        
        // Check exposure limits
        let current_exposure = self.exposure_calculator.calculate_exposure(&order.client_id)?;
        let additional_exposure = self.calculate_additional_exposure(order)?;
        
        if current_exposure + additional_exposure > client_limits.max_exposure {
            return Ok(RiskValidation {
                approved: false,
                rejection_reason: "Exposure limit exceeded".to_string(),
            });
        }
        
        // Check order size limits
        if order.quantity > client_limits.max_order_size {
            return Ok(RiskValidation {
                approved: false,
                rejection_reason: "Order size limit exceeded".to_string(),
            });
        }
        
        Ok(RiskValidation {
            approved: true,
            rejection_reason: String::new(),
        })
    }
}
```

## Proyecto 2: Blockchain Determinístico

```tempo
// Blockchain implementation con consensus determinístico
struct DeterministicBlockchain {
    chain: Vec<Block>,
    pending_transactions: TransactionPool,
    consensus_engine: DeterministicConsensus,
    state_manager: StateManager,
    network_layer: P2PNetwork,
    
    // Configuración determinística
    block_time: Duration,
    max_transactions_per_block: usize,
    transaction_timeout: Duration,
}

struct Block {
    header: BlockHeader,
    transactions: Vec<Transaction>,
    state_root: StateRoot,
    signature: BlockSignature,
}

struct BlockHeader {
    previous_hash: Hash256,
    merkle_root: Hash256,
    timestamp: DeterministicTimestamp,
    block_number: u64,
    nonce: u64,
    difficulty: Difficulty,
}

struct Transaction {
    from: Address,
    to: Address,
    value: Amount,
    gas_limit: u64,
    gas_price: u64,
    data: Vec<u8>,
    nonce: u64,
    signature: TransactionSignature,
}

impl DeterministicBlockchain {
    fn propose_block(&mut self) -> Result<Block, BlockchainError> {
        let proposal_start = get_deterministic_timestamp();
        
        // 1. Select transactions deterministically
        let selected_transactions = self.select_transactions_for_block()?;
        
        // 2. Execute transactions and update state
        let execution_results = self.execute_transactions(&selected_transactions)?;
        
        // 3. Calculate new state root
        let new_state_root = self.state_manager.calculate_state_root(&execution_results)?;
        
        // 4. Create block header
        let previous_block = self.chain.last().ok_or(BlockchainError::EmptyChain)?;
        
        let header = BlockHeader {
            previous_hash: previous_block.calculate_hash(),
            merkle_root: self.calculate_merkle_root(&selected_transactions),
            timestamp: proposal_start,
            block_number: previous_block.header.block_number + 1,
            nonce: 0, // Will be set by consensus
            difficulty: self.calculate_next_difficulty(),
        };
        
        // 5. Create block
        let block = Block {
            header,
            transactions: selected_transactions,
            state_root: new_state_root,
            signature: BlockSignature::empty(), // Will be set after consensus
        };
        
        Ok(block)
    }
    
    fn select_transactions_for_block(&mut self) -> Result<Vec<Transaction>, BlockchainError> {
        let mut selected = Vec::new();
        let mut total_gas = 0u64;
        
        // Sort transactions by gas price (deterministic ordering)
        let mut pending: Vec<_> = self.pending_transactions.get_all().collect();
        pending.sort_by(|a, b| {
            // Primary: gas price (descending)
            let gas_cmp = b.gas_price.cmp(&a.gas_price);
            if gas_cmp != std::cmp::Ordering::Equal {
                return gas_cmp;
            }
            
            // Secondary: nonce (ascending for same sender)
            if a.from == b.from {
                return a.nonce.cmp(&b.nonce);
            }
            
            // Tertiary: hash (for deterministic tie-breaking)
            a.calculate_hash().cmp(&b.calculate_hash())
        });
        
        // Select transactions that fit in block
        for transaction in pending {
            if selected.len() >= self.max_transactions_per_block {
                break;
            }
            
            if total_gas + transaction.gas_limit > self.get_block_gas_limit() {
                continue;
            }
            
            // Validate transaction
            if self.validate_transaction(&transaction)? {
                total_gas += transaction.gas_limit;
                selected.push(transaction);
            }
        }
        
        Ok(selected)
    }
    
    fn execute_transactions(&mut self, transactions: &[Transaction]) -> Result<Vec<ExecutionResult>, BlockchainError> {
        let mut results = Vec::new();
        let mut current_state = self.state_manager.get_current_state()?;
        
        for transaction in transactions {
            // Execute transaction deterministically
            let execution_result = self.execute_single_transaction(transaction, &current_state)?;
            
            // Update state
            current_state = self.state_manager.apply_execution_result(&current_state, &execution_result)?;
            
            results.push(execution_result);
        }
        
        Ok(results)
    }
    
    fn execute_single_transaction(&self, transaction: &Transaction, state: &WorldState) -> Result<ExecutionResult, BlockchainError> {
        // Create deterministic execution environment
        let mut vm = DeterministicVM::new(state.clone());
        vm.set_gas_limit(transaction.gas_limit);
        vm.set_caller(transaction.from);
        vm.set_value(transaction.value);
        
        // Execute transaction
        let execution_start = rdtsc();
        let vm_result = vm.execute(&transaction.data)?;
        let execution_cycles = rdtsc() - execution_start;
        
        Ok(ExecutionResult {
            success: vm_result.success,
            gas_used: vm_result.gas_used,
            return_data: vm_result.return_data,
            state_changes: vm_result.state_changes,
            execution_cycles,
            logs: vm_result.logs,
        })
    }
}

// Consensus engine determinístico
struct DeterministicConsensus {
    validators: Vec<Validator>,
    consensus_algorithm: ConsensusAlgorithm,
    voting_state: VotingState,
}

enum ConsensusAlgorithm {
    DeterministicPBFT,
    DeterministicPoS,
    DeterministicPoW,
}

impl DeterministicConsensus {
    fn reach_consensus(&mut self, proposed_block: &Block) -> Result<ConsensusResult, ConsensusError> {
        match self.consensus_algorithm {
            ConsensusAlgorithm::DeterministicPBFT => self.pbft_consensus(proposed_block),
            ConsensusAlgorithm::DeterministicPoS => self.pos_consensus(proposed_block),
            ConsensusAlgorithm::DeterministicPoW => self.pow_consensus(proposed_block),
        }
    }
    
    fn pbft_consensus(&mut self, block: &Block) -> Result<ConsensusResult, ConsensusError> {
        // Deterministic PBFT implementation
        let consensus_round = ConsensusRound::new(block.header.block_number);
        
        // Phase 1: Pre-prepare
        self.broadcast_pre_prepare(&consensus_round, block)?;
        
        // Phase 2: Prepare
        let prepare_votes = self.collect_prepare_votes(&consensus_round)?;
        if !self.has_sufficient_prepare_votes(&prepare_votes) {
            return Err(ConsensusError::InsufficientPrepareVotes);
        }
        
        // Phase 3: Commit
        let commit_votes = self.collect_commit_votes(&consensus_round)?;
        if !self.has_sufficient_commit_votes(&commit_votes) {
            return Err(ConsensusError::InsufficientCommitVotes);
        }
        
        Ok(ConsensusResult {
            approved: true,
            final_block: block.clone(),
            consensus_proof: ConsensusProof::PBFT {
                prepare_votes,
                commit_votes,
            },
        })
    }
}
```

## Proyecto 3: Compilador de Lenguaje DSL

```tempo
// Compilador para DSL específico de dominio
struct DSLCompiler {
    lexer: DSLLexer,
    parser: DSLParser,
    semantic_analyzer: DSLSemanticAnalyzer,
    code_generator: DSLCodeGenerator,
    optimizer: DSLOptimizer,
}

// DSL para configuración de sistemas embebidos
enum DSLNode {
    Module {
        name: String,
        items: Vec<DSLNode>,
    },
    Device {
        name: String,
        device_type: DeviceType,
        pins: Vec<PinMapping>,
        properties: HashMap<String, Value>,
    },
    Task {
        name: String,
        priority: Priority,
        stack_size: usize,
        period: Duration,
        function: String,
    },
    Interrupt {
        vector: u8,
        handler: String,
        priority: u8,
    },
    Communication {
        protocol: Protocol,
        config: ProtocolConfig,
    },
}

impl DSLCompiler {
    fn compile_dsl(&mut self, source: &str) -> Result<CompilationOutput, DSLError> {
        // 1. Lexical analysis
        let tokens = self.lexer.tokenize(source)?;
        
        // 2. Parsing
        let ast = self.parser.parse(tokens)?;
        
        // 3. Semantic analysis
        let analyzed_ast = self.semantic_analyzer.analyze(ast)?;
        
        // 4. Optimization
        let optimized_ast = self.optimizer.optimize(analyzed_ast)?;
        
        // 5. Code generation
        let generated_code = self.code_generator.generate_tempo_code(&optimized_ast)?;
        
        // 6. Generate configuration files
        let config_files = self.generate_config_files(&optimized_ast)?;
        
        Ok(CompilationOutput {
            tempo_code: generated_code,
            config_files,
            memory_layout: self.calculate_memory_layout(&optimized_ast)?,
            timing_analysis: self.analyze_timing(&optimized_ast)?,
        })
    }
    
    fn generate_tempo_code(&self, ast: &DSLNode) -> Result<String, DSLError> {
        let mut code_builder = ChronosCodeBuilder::new();
        
        match ast {
            DSLNode::Module { name, items } => {
                code_builder.add_module_header(name);
                
                for item in items {
                    match item {
                        DSLNode::Device { name, device_type, pins, properties } => {
                            code_builder.add_device_definition(name, device_type, pins, properties)?;
                        },
                        DSLNode::Task { name, priority, stack_size, period, function } => {
                            code_builder.add_task_definition(name, *priority, *stack_size, *period, function)?;
                        },
                        DSLNode::Interrupt { vector, handler, priority } => {
                            code_builder.add_interrupt_handler(*vector, handler, *priority)?;
                        },
                        DSLNode::Communication { protocol, config } => {
                            code_builder.add_communication_setup(protocol, config)?;
                        },
                        _ => return Err(DSLError::UnsupportedNodeType),
                    }
                }
                
                code_builder.add_main_function()?;
            },
            _ => return Err(DSLError::InvalidTopLevelNode),
        }
        
        Ok(code_builder.build())
    }
    
    fn analyze_timing(&self, ast: &DSLNode) -> Result<TimingAnalysis, DSLError> {
        let mut analyzer = TimingAnalyzer::new();
        
        // Extract all tasks and their timing requirements
        let tasks = self.extract_tasks(ast)?;
        
        // Perform schedulability analysis
        let schedulability = analyzer.analyze_schedulability(&tasks)?;
        
        // Calculate WCET for each task
        let wcet_analysis = analyzer.calculate_wcet_bounds(&tasks)?;
        
        // Check for timing conflicts
        let conflicts = analyzer.detect_timing_conflicts(&tasks)?;
        
        Ok(TimingAnalysis {
            schedulability,
            wcet_analysis,
            conflicts,
            recommendations: analyzer.generate_recommendations(&tasks)?,
        })
    }
}

// Ejemplo de DSL para sistema embebido
const EMBEDDED_SYSTEM_DSL: &str = r#"
module sensor_node {
    device temperature_sensor {
        type: I2C_Device
        address: 0x48
        pins: [SDA: GPIO2, SCL: GPIO3]
        sample_rate: 10Hz
        precision: 12bit
    }
    
    device radio {
        type: LoRa
        frequency: 915MHz
        power: 14dBm
        pins: [MISO: GPIO19, MOSI: GPIO23, SCK: GPIO18, CS: GPIO5]
    }
    
    task sensor_reading {
        priority: HIGH
        period: 100ms
        stack_size: 2048
        function: read_temperature_sensor
        wcet: 50ms
    }
    
    task data_transmission {
        priority: MEDIUM
        period: 1s
        stack_size: 4096
        function: transmit_sensor_data
        wcet: 200ms
    }
    
    task battery_monitoring {
        priority: LOW
        period: 10s
        stack_size: 1024
        function: check_battery_level
        wcet: 10ms
    }
    
    interrupt timer_overflow {
        vector: 16
        handler: handle_timer_overflow
        priority: 15
    }
    
    communication lora_protocol {
        protocol: LoRaWAN
        config: {
            spreading_factor: 7
            bandwidth: 125kHz
            coding_rate: 4/5
            sync_word: 0x12
        }
    }
}
"#;
```

## Proyecto 4: Sistema de Control Industrial

```tempo
// Sistema de control para planta industrial
struct IndustrialControlSystem {
    plc_controller: PLCController,
    scada_interface: SCADAInterface,
    safety_system: SafetySystem,
    communication_stack: IndustrialNetworking,
    historian: DataHistorian,
    
    // Real-time constraints
    control_loop_period: Duration,
    safety_response_time: Duration,
    max_communication_latency: Duration,
}

struct PLCController {
    input_modules: Vec<InputModule>,
    output_modules: Vec<OutputModule>,
    control_logic: ControlLogic,
    program_memory: ProgramMemory,
    data_memory: DataMemory,
}

struct ControlLogic {
    ladder_logic: LadderProgram,
    function_blocks: Vec<FunctionBlock>,
    pid_controllers: Vec<PIDController>,
    sequencers: Vec<SequenceController>,
}

impl IndustrialControlSystem {
    fn run_control_cycle(&mut self) -> Result<(), ControlError> {
        let cycle_start = get_deterministic_timestamp();
        
        // 1. Read inputs (deterministic timing)
        let input_values = timed_execution!(
            self.control_loop_period / 4,
            self.read_all_inputs()
        )?;
        
        // 2. Execute control logic
        let control_outputs = timed_execution!(
            self.control_loop_period / 2,
            self.execute_control_logic(&input_values)
        )?;
        
        // 3. Safety validation
        let safety_check = timed_execution!(
            self.safety_response_time,
            self.safety_system.validate_outputs(&control_outputs)
        )?;
        
        if !safety_check.approved {
            // Immediate safety shutdown
            self.execute_emergency_shutdown(safety_check.reason)?;
            return Err(ControlError::SafetyViolation(safety_check.reason));
        }
        
        // 4. Write outputs
        timed_execution!(
            self.control_loop_period / 4,
            self.write_all_outputs(&control_outputs)
        )?;
        
        // 5. Log data for historian
        self.historian.log_cycle_data(&input_values, &control_outputs)?;
        
        let cycle_time = get_deterministic_timestamp() - cycle_start;
        
        // Verify cycle time constraint
        if cycle_time > self.control_loop_period {
            log_timing_violation!("Control cycle", cycle_time, self.control_loop_period);
        }
        
        Ok(())
    }
    
    fn execute_control_logic(&mut self, inputs: &InputValues) -> Result<OutputValues, ControlError> {
        let mut outputs = OutputValues::new();
        
        // Execute ladder logic program
        let ladder_outputs = self.plc_controller.control_logic.ladder_logic.execute(inputs)?;
        outputs.merge(ladder_outputs);
        
        // Execute PID controllers
        for pid in &mut self.plc_controller.control_logic.pid_controllers {
            let pid_output = pid.calculate(inputs.get_process_variable(pid.input_tag)?)?;
            outputs.set(pid.output_tag.clone(), pid_output);
        }
        
        // Execute function blocks
        for fb in &mut self.plc_controller.control_logic.function_blocks {
            let fb_outputs = fb.execute(inputs, &outputs)?;
            outputs.merge(fb_outputs);
        }
        
        // Execute sequence controllers
        for sequencer in &mut self.plc_controller.control_logic.sequencers {
            let seq_outputs = sequencer.execute(inputs, &outputs)?;
            outputs.merge(seq_outputs);
        }
        
        Ok(outputs)
    }
}

// Ladder logic interpreter determinístico
struct LadderProgram {
    rungs: Vec<LadderRung>,
    memory_map: MemoryMap,
}

struct LadderRung {
    conditions: Vec<LadderCondition>,
    outputs: Vec<LadderOutput>,
    rung_number: u32,
}

enum LadderCondition {
    NormallyOpen { address: Address },
    NormallyClosed { address: Address },
    Timer { timer_id: TimerId, preset: Duration },
    Counter { counter_id: CounterId, preset: u32 },
    Compare { left: Value, operator: CompareOp, right: Value },
}

impl LadderProgram {
    fn execute(&mut self, inputs: &InputValues) -> Result<OutputValues, LadderError> {
        let mut outputs = OutputValues::new();
        
        // Execute each rung deterministically
        for rung in &mut self.rungs {
            let rung_result = self.execute_rung(rung, inputs, &outputs)?;
            if rung_result.energized {
                outputs.merge(rung_result.outputs);
            }
        }
        
        Ok(outputs)
    }
    
    fn execute_rung(&mut self, rung: &mut LadderRung, inputs: &InputValues, current_outputs: &OutputValues) -> Result<RungResult, LadderError> {
        let mut rung_energized = true;
        
        // Evaluate all conditions (AND logic)
        for condition in &rung.conditions {
            let condition_result = self.evaluate_condition(condition, inputs, current_outputs)?;
            rung_energized = rung_energized && condition_result;
        }
        
        let mut rung_outputs = OutputValues::new();
        
        if rung_energized {
            // Execute outputs
            for output in &rung.outputs {
                self.execute_output(output, &mut rung_outputs)?;
            }
        }
        
        Ok(RungResult {
            energized: rung_energized,
            outputs: rung_outputs,
        })
    }
}
```

## Proyecto 5: Sistema de Machine Learning Determinístico

```tempo
// Framework de ML con garantías de determinismo
struct DeterministicMLFramework {
    models: HashMap<ModelId, MLModel>,
    training_engine: DeterministicTrainingEngine,
    inference_engine: DeterministicInferenceEngine,
    data_pipeline: DeterministicDataPipeline,
}

struct DeterministicTrainingEngine {
    optimizers: HashMap<OptimizerType, Optimizer>,
    loss_functions: HashMap<LossType, LossFunction>,
    regularizers: Vec<Regularizer>,
    random_seed: u64,
}

impl DeterministicTrainingEngine {
    fn train_model(&mut self, config: &TrainingConfig) -> Result<TrainedModel, MLError> {
        // Setup deterministic environment
        self.setup_deterministic_training(config.random_seed)?;
        
        // Load and preprocess data deterministically
        let dataset = self.data_pipeline.load_dataset(&config.dataset_path)?;
        let preprocessed_data = self.data_pipeline.preprocess_deterministic(&dataset)?;
        
        // Initialize model with deterministic weights
        let mut model = self.initialize_model(&config.model_architecture, config.random_seed)?;
        
        // Training loop with deterministic updates
        for epoch in 0..config.num_epochs {
            let epoch_start = get_deterministic_timestamp();
            
            // Shuffle data deterministically
            let shuffled_batches = self.deterministic_shuffle(&preprocessed_data, epoch as u64)?;
            
            let mut epoch_loss = 0.0;
            
            for batch in shuffled_batches {
                // Forward pass
                let predictions = model.forward(&batch.inputs)?;
                
                // Calculate loss
                let loss = self.calculate_loss(&predictions, &batch.targets, &config.loss_type)?;
                epoch_loss += loss;
                
                // Backward pass
                let gradients = self.calculate_gradients(&model, &batch.inputs, &batch.targets, loss)?;
                
                // Update weights deterministically
                self.update_weights(&mut model, &gradients, &config.optimizer_config)?;
            }
            
            // Validation
            let validation_metrics = self.validate_model(&model, &preprocessed_data.validation_set)?;
            
            // Early stopping check
            if self.should_stop_early(&validation_metrics, epoch) {
                break;
            }
            
            let epoch_time = get_deterministic_timestamp() - epoch_start;
            log_training_metrics!(epoch, epoch_loss, validation_metrics, epoch_time);
        }
        
        Ok(TrainedModel {
            model,
            training_metrics: self.get_training_metrics(),
            model_hash: self.calculate_model_hash(&model),
        })
    }
    
    fn deterministic_shuffle(&self, data: &Dataset, seed: u64) -> Result<Vec<DataBatch>, MLError> {
        let mut rng = DeterministicRng::new(seed);
        let mut indices: Vec<usize> = (0..data.len()).collect();
        
        // Fisher-Yates shuffle with deterministic RNG
        for i in (1..indices.len()).rev() {
            let j = rng.gen_range(0..=i);
            indices.swap(i, j);
        }
        
        // Create batches
        let mut batches = Vec::new();
        for chunk in indices.chunks(data.batch_size) {
            let batch_data: Vec<_> = chunk.iter().map(|&i| data.samples[i].clone()).collect();
            batches.push(DataBatch::from_samples(batch_data));
        }
        
        Ok(batches)
    }
}

// Neural network con arithmetic determinística
struct DeterministicNeuralNetwork {
    layers: Vec<Layer>,
    activation_functions: Vec<ActivationFunction>,
    weight_initialization: WeightInitialization,
}

impl DeterministicNeuralNetwork {
    fn forward(&self, input: &Tensor) -> Result<Tensor, MLError> {
        let mut current_output = input.clone();
        
        for (i, layer) in self.layers.iter().enumerate() {
            // Linear transformation
            current_output = layer.linear_transform(&current_output)?;
            
            // Apply activation function
            current_output = self.activation_functions[i].apply(&current_output)?;
        }
        
        Ok(current_output)
    }
    
    fn backward(&self, gradient: &Tensor) -> Result<Vec<LayerGradients>, MLError> {
        let mut layer_gradients = Vec::new();
        let mut current_gradient = gradient.clone();
        
        // Backpropagate through layers in reverse order
        for (i, layer) in self.layers.iter().enumerate().rev() {
            let layer_grad = layer.calculate_gradients(&current_gradient)?;
            current_gradient = layer.propagate_gradient(&current_gradient)?;
            
            layer_gradients.insert(0, layer_grad);
        }
        
        Ok(layer_gradients)
    }
}

// Tensor operations con arithmetic determinística
struct DeterministicTensor {
    data: Vec<f64>,
    shape: Vec<usize>,
    stride: Vec<usize>,
}

impl DeterministicTensor {
    fn matrix_multiply(&self, other: &DeterministicTensor) -> Result<DeterministicTensor, TensorError> {
        // Verify shapes are compatible
        if self.shape.len() != 2 || other.shape.len() != 2 {
            return Err(TensorError::InvalidShape);
        }
        
        if self.shape[1] != other.shape[0] {
            return Err(TensorError::IncompatibleShapes);
        }
        
        let result_shape = vec![self.shape[0], other.shape[1]];
        let mut result_data = vec![0.0; result_shape[0] * result_shape[1]];
        
        // Deterministic matrix multiplication
        for i in 0..result_shape[0] {
            for j in 0..result_shape[1] {
                let mut sum = 0.0;
                
                for k in 0..self.shape[1] {
                    let a_val = self.data[i * self.shape[1] + k];
                    let b_val = other.data[k * other.shape[1] + j];
                    
                    // Use deterministic floating-point arithmetic
                    sum = deterministic_add(sum, deterministic_multiply(a_val, b_val));
                }
                
                result_data[i * result_shape[1] + j] = sum;
            }
        }
        
        Ok(DeterministicTensor {
            data: result_data,
            shape: result_shape,
            stride: vec![result_shape[1], 1],
        })
    }
}

// Deterministic floating-point operations
fn deterministic_add(a: f64, b: f64) -> f64 {
    // Implementation ensures exact same result across platforms
    // Handle edge cases (NaN, Infinity) deterministically
    if a.is_nan() || b.is_nan() {
        f64::NAN
    } else if a.is_infinite() && b.is_infinite() {
        if a.is_sign_positive() == b.is_sign_positive() {
            a  // Same sign infinities
        } else {
            f64::NAN  // Opposite sign infinities
        }
    } else {
        a + b
    }
}

fn deterministic_multiply(a: f64, b: f64) -> f64 {
    // Handle special cases deterministically
    if a.is_nan() || b.is_nan() {
        f64::NAN
    } else if a == 0.0 || b == 0.0 {
        0.0
    } else if a.is_infinite() || b.is_infinite() {
        if (a > 0.0) == (b > 0.0) {
            f64::INFINITY
        } else {
            f64::NEG_INFINITY
        }
    } else {
        a * b
    }
}
```

## Práctica Final: Sistema Integrado

Desarrolla un sistema que combine todos los proyectos anteriores:

1. **Trading Engine** que use ML para predicciones
2. **Blockchain** para settlement de trades
3. **Control System** para risk management
4. **DSL** para configuración de estrategias

## Ejercicio de Graduación

Crea un proyecto completo que demuestre:

1. **Determinismo completo** en todas las operaciones
2. **WCET analysis** y guarantees
3. **Performance optimization** avanzada
4. **Testing exhaustivo** con property-based testing
5. **Documentation completa** con arquitectura y decisiones de diseño
6. **Deployment automatizado** con CI/CD
7. **Monitoring y observability** integrada

## Evaluación Final

Tu proyecto será evaluado en:

- **Correctness**: ¿El código funciona correctamente?
- **Determinism**: ¿Se mantiene el determinismo en todas las operaciones?
- **Performance**: ¿Cumple con los requisitos de performance?
- **Testing**: ¿Tiene coverage completo y tests de calidad?
- **Documentation**: ¿Está bien documentado y explicado?
- **Architecture**: ¿El diseño es sólido y escalable?

¡Felicitaciones por completar el curso completo de compiladores Chronos! 🎉

Ahora tienes todas las herramientas para crear el futuro del software determinístico.