╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 22: Sistemas Embebidos y IoT

## Objetivos
- Adaptar Chronos para sistemas embebidos
- Implementar real-time constraints estrictos
- Diseñar IoT determinístico y seguro
- Crear optimizaciones para recursos limitados

## Teoría: Chronos Embebido

Para sistemas embebidos, Chronos debe optimizar:

1. **Footprint de memoria** extremadamente pequeño
2. **Consumo de energía** determinístico
3. **Real-time constraints** hard garantizados
4. **Seguridad** contra ataques embebidos

## Runtime Mínimo para Embebidos

```tempo
// Runtime mínimo para microcontroladores
#[no_std]
#[no_main]
mod embedded_runtime {
    // Allocator estático sin heap
    use linked_list_allocator::LockedHeap;
    
    #[global_allocator]
    static ALLOCATOR: LockedHeap = LockedHeap::empty();
    
    // Stack estático predefinido
    static mut STACK: [u8; 4096] = [0; 4096];
    
    // Memory pools para diferentes tamaños
    static mut SMALL_POOL: [u8; 1024] = [0; 1024];
    static mut MEDIUM_POOL: [u8; 2048] = [0; 2048];
    
    struct EmbeddedRuntime {
        small_allocator: StackAllocator<1024>,
        medium_allocator: StackAllocator<2048>,
        timer_tick: u32,
        interrupt_handlers: [Option<fn()>; 32],
    }
    
    impl EmbeddedRuntime {
        const fn new() -> Self {
            EmbeddedRuntime {
                small_allocator: StackAllocator::new(),
                medium_allocator: StackAllocator::new(),
                timer_tick: 0,
                interrupt_handlers: [None; 32],
            }
        }
        
        fn init(&mut self) {
            // Inicializar allocators
            unsafe {
                self.small_allocator.init(&mut SMALL_POOL);
                self.medium_allocator.init(&mut MEDIUM_POOL);
            }
            
            // Configurar timer para determinismo
            self.setup_deterministic_timer();
            
            // Configurar interrupts
            self.setup_interrupts();
        }
        
        fn setup_deterministic_timer(&mut self) {
            // Timer de alta resolución para WCET measurement
            timer_init(1_000_000); // 1MHz = 1μs resolution
            timer_set_compare(1000); // 1ms tick
            timer_enable_interrupt();
        }
        
        fn register_interrupt_handler(&mut self, vector: u8, handler: fn()) {
            if (vector as usize) < self.interrupt_handlers.len() {
                self.interrupt_handlers[vector as usize] = Some(handler);
            }
        }
    }
    
    // Stack allocator para sistemas embebidos
    struct StackAllocator<const SIZE: usize> {
        buffer: *mut u8,
        offset: usize,
        high_water_mark: usize,
    }
    
    impl<const SIZE: usize> StackAllocator<SIZE> {
        const fn new() -> Self {
            StackAllocator {
                buffer: core::ptr::null_mut(),
                offset: 0,
                high_water_mark: 0,
            }
        }
        
        fn init(&mut self, buffer: &mut [u8; SIZE]) {
            self.buffer = buffer.as_mut_ptr();
            self.offset = 0;
            self.high_water_mark = 0;
        }
        
        fn allocate(&mut self, size: usize, align: usize) -> Option<*mut u8> {
            // Align offset
            let aligned_offset = (self.offset + align - 1) & !(align - 1);
            
            if aligned_offset + size > SIZE {
                return None; // Out of memory
            }
            
            let ptr = unsafe { self.buffer.add(aligned_offset) };
            self.offset = aligned_offset + size;
            self.high_water_mark = core::cmp::max(self.high_water_mark, self.offset);
            
            Some(ptr)
        }
        
        fn reset(&mut self) {
            self.offset = 0;
            // Keep high_water_mark for analysis
        }
        
        fn memory_usage(&self) -> (usize, f32) {
            (self.high_water_mark, self.high_water_mark as f32 / SIZE as f32)
        }
    }
}
```

## Real-Time Task Scheduler

```tempo
// Scheduler determinístico para real-time
struct RealTimeScheduler {
    tasks: [Option<Task>; MAX_TASKS],
    ready_queue: [TaskId; MAX_TASKS],
    waiting_queue: [TaskId; MAX_TASKS],
    current_task: Option<TaskId>,
    tick_counter: u64,
    schedule_table: ScheduleTable,
}

struct Task {
    id: TaskId,
    priority: Priority,
    period: u32,        // en ticks
    deadline: u32,      // relative deadline
    wcet: u32,          // worst-case execution time
    next_release: u64,  // absolute time
    state: TaskState,
    stack_base: *mut u8,
    stack_size: usize,
    entry_point: fn(),
}

#[derive(Copy, Clone, PartialEq)]
enum TaskState {
    Ready,
    Running,
    Waiting,
    Suspended,
}

#[derive(Copy, Clone, PartialOrd, PartialEq, Ord, Eq)]
struct Priority(u8);

impl RealTimeScheduler {
    fn new() -> Self {
        RealTimeScheduler {
            tasks: [None; MAX_TASKS],
            ready_queue: [TaskId::INVALID; MAX_TASKS],
            waiting_queue: [TaskId::INVALID; MAX_TASKS],
            current_task: None,
            tick_counter: 0,
            schedule_table: ScheduleTable::new(),
        }
    }
    
    fn create_task(&mut self, config: TaskConfig) -> Result<TaskId, SchedulerError> {
        // Verificar schedulability antes de crear task
        if !self.is_schedulable_with_new_task(&config) {
            return Err(SchedulerError::NotSchedulable);
        }
        
        let task_id = self.allocate_task_id()?;
        
        // Allocar stack determinístico
        let stack_ptr = self.allocate_task_stack(config.stack_size)?;
        
        let task = Task {
            id: task_id,
            priority: config.priority,
            period: config.period,
            deadline: config.deadline,
            wcet: config.wcet,
            next_release: self.tick_counter + config.period as u64,
            state: TaskState::Suspended,
            stack_base: stack_ptr,
            stack_size: config.stack_size,
            entry_point: config.entry_point,
        };
        
        self.tasks[task_id.0 as usize] = Some(task);
        
        // Actualizar schedule table
        self.schedule_table.add_task(&task);
        
        Ok(task_id)
    }
    
    fn schedule(&mut self) -> Option<TaskId> {
        // Earliest Deadline First (EDF) scheduling
        let mut earliest_deadline = u64::MAX;
        let mut selected_task = None;
        
        for task_opt in &self.tasks {
            if let Some(task) = task_opt {
                if task.state == TaskState::Ready {
                    let absolute_deadline = task.next_release + task.deadline as u64;
                    if absolute_deadline < earliest_deadline {
                        earliest_deadline = absolute_deadline;
                        selected_task = Some(task.id);
                    }
                }
            }
        }
        
        // Verificar deadline miss
        if let Some(task_id) = selected_task {
            if earliest_deadline <= self.tick_counter {
                self.handle_deadline_miss(task_id);
            }
        }
        
        selected_task
    }
    
    fn is_schedulable_with_new_task(&self, new_task: &TaskConfig) -> bool {
        // Rate Monotonic Analysis para verificar schedulability
        let mut utilization = 0.0;
        
        // Calcular utilización actual
        for task_opt in &self.tasks {
            if let Some(task) = task_opt {
                utilization += task.wcet as f64 / task.period as f64;
            }
        }
        
        // Agregar nueva task
        let new_utilization = new_task.wcet as f64 / new_task.period as f64;
        utilization += new_utilization;
        
        // Test de utilización simple
        let n = self.count_active_tasks() + 1;
        let bound = n as f64 * (2.0_f64.powf(1.0 / n as f64) - 1.0);
        
        utilization <= bound
    }
    
    fn tick(&mut self) {
        self.tick_counter += 1;
        
        // Release periodic tasks
        for task_opt in &mut self.tasks {
            if let Some(task) = task_opt {
                if task.next_release == self.tick_counter {
                    if task.state == TaskState::Waiting {
                        task.state = TaskState::Ready;
                        self.add_to_ready_queue(task.id);
                    }
                    task.next_release += task.period as u64;
                }
            }
        }
        
        // Check for deadline misses
        self.check_deadline_misses();
        
        // Schedule next task
        if let Some(next_task) = self.schedule() {
            self.context_switch(next_task);
        }
    }
    
    fn handle_deadline_miss(&mut self, task_id: TaskId) {
        // Estrategias de manejo de deadline miss
        match DEADLINE_MISS_POLICY {
            DeadlineMissPolicy::Abort => {
                self.abort_task(task_id);
            },
            DeadlineMissPolicy::Skip => {
                self.skip_task_instance(task_id);
            },
            DeadlineMissPolicy::Continue => {
                // Log warning pero continuar
                log_deadline_miss(task_id, self.tick_counter);
            },
        }
    }
}
```

## Power Management Determinístico

```tempo
// Gestión de energía predecible
struct PowerManager {
    power_states: [PowerState; NUM_POWER_STATES],
    current_state: PowerStateId,
    transition_table: [[TransitionCost; NUM_POWER_STATES]; NUM_POWER_STATES],
    energy_budget: EnergyBudget,
    consumption_predictor: ConsumptionPredictor,
}

struct PowerState {
    id: PowerStateId,
    voltage: u16,           // mV
    frequency: u32,         // Hz
    power_consumption: u32, // mW
    wakeup_latency: u32,    // cycles
    active_peripherals: PeripheralMask,
}

struct EnergyBudget {
    total_budget: u64,      // μJ
    consumed: u64,          // μJ
    budget_per_task: HashMap<TaskId, u64>,
    emergency_threshold: f64, // percentage
}

impl PowerManager {
    fn optimize_power_schedule(&mut self, schedule: &Schedule) -> PowerOptimizedSchedule {
        let mut optimized = PowerOptimizedSchedule::new();
        
        for time_slot in schedule.time_slots() {
            // Predecir consumo de energía para cada power state
            let predictions = self.predict_energy_consumption(time_slot);
            
            // Seleccionar estado óptimo que cumpla deadlines
            let optimal_state = self.select_optimal_power_state(&predictions, time_slot);
            
            // Verificar que transición es factible
            if self.can_transition_in_time(optimal_state, time_slot.duration) {
                optimized.add_power_transition(time_slot.start_time, optimal_state);
            }
        }
        
        optimized
    }
    
    fn predict_energy_consumption(&self, time_slot: &TimeSlot) -> Vec<EnergyPrediction> {
        let mut predictions = Vec::new();
        
        for &state_id in &[PowerStateId::ACTIVE, PowerStateId::IDLE, PowerStateId::SLEEP] {
            let state = &self.power_states[state_id as usize];
            
            // Calcular consumo base
            let base_consumption = state.power_consumption * time_slot.duration;
            
            // Agregar overhead de transiciones
            let transition_overhead = self.calculate_transition_overhead(self.current_state, state_id);
            
            // Considerar wake-up latency
            let wakeup_penalty = if state_id == PowerStateId::SLEEP {
                state.wakeup_latency * WAKEUP_POWER_PENALTY
            } else {
                0
            };
            
            predictions.push(EnergyPrediction {
                state_id,
                estimated_consumption: base_consumption + transition_overhead + wakeup_penalty,
                confidence: self.calculate_prediction_confidence(state_id, time_slot),
            });
        }
        
        predictions
    }
    
    fn enter_power_state(&mut self, target_state: PowerStateId) -> Result<(), PowerError> {
        let current = &self.power_states[self.current_state as usize];
        let target = &self.power_states[target_state as usize];
        
        // Verificar transición válida
        let transition_cost = self.transition_table[self.current_state as usize][target_state as usize];
        if transition_cost.is_forbidden() {
            return Err(PowerError::InvalidTransition);
        }
        
        // Ejecutar secuencia de transición determinística
        self.execute_power_transition(target_state, &transition_cost)?;
        
        // Actualizar consumo de energía
        self.energy_budget.consumed += transition_cost.energy_cost;
        
        self.current_state = target_state;
        
        Ok(())
    }
    
    fn execute_power_transition(&mut self, target_state: PowerStateId, cost: &TransitionCost) -> Result<(), PowerError> {
        // Secuencia determinística de cambios de hardware
        match target_state {
            PowerStateId::ACTIVE => {
                // 1. Set voltage
                set_core_voltage(self.power_states[target_state as usize].voltage);
                wait_voltage_stable(cost.voltage_settle_time);
                
                // 2. Set frequency
                set_cpu_frequency(self.power_states[target_state as usize].frequency);
                wait_pll_lock(cost.frequency_settle_time);
                
                // 3. Enable peripherals
                enable_peripherals(self.power_states[target_state as usize].active_peripherals);
            },
            
            PowerStateId::IDLE => {
                // Disable unnecessary peripherals
                disable_peripherals(!self.power_states[target_state as usize].active_peripherals);
                
                // Reduce frequency but keep core active
                set_cpu_frequency(self.power_states[target_state as usize].frequency);
            },
            
            PowerStateId::SLEEP => {
                // Save context
                self.save_processor_context();
                
                // Disable most peripherals
                disable_peripherals(!ESSENTIAL_PERIPHERALS);
                
                // Enter sleep mode
                enter_sleep_mode();
            },
        }
        
        Ok(())
    }
}
```

## IoT Secure Communication

```tempo
// Comunicación IoT segura y determinística
struct IoTCommunicationStack {
    network_interface: NetworkInterface,
    security_layer: SecurityLayer,
    protocol_stack: ProtocolStack,
    message_queue: BoundedQueue<IoTMessage>,
    encryption_engine: LightweightCrypto,
}

struct LightweightCrypto {
    aes_ctx: AESContext,
    key_schedule: [u32; 44],  // Pre-computed for deterministic timing
    nonce_counter: u64,
    auth_keys: [u8; 32],
}

impl LightweightCrypto {
    fn encrypt_message(&mut self, plaintext: &[u8], output: &mut [u8]) -> Result<usize, CryptoError> {
        if output.len() < plaintext.len() + 16 {
            return Err(CryptoError::BufferTooSmall);
        }
        
        // Generate deterministic nonce (never reuse)
        let nonce = self.generate_nonce();
        
        // AES-GCM encryption con timing constante
        let ciphertext_len = self.aes_gcm_encrypt(
            &self.key_schedule,
            &nonce,
            plaintext,
            &mut output[16..],  // Leave space for tag
        )?;
        
        // Compute authentication tag
        let tag = self.compute_gcm_tag(&nonce, plaintext, &output[16..16 + ciphertext_len]);
        output[0..16].copy_from_slice(&tag);
        
        Ok(16 + ciphertext_len)  // tag + ciphertext
    }
    
    fn decrypt_message(&mut self, ciphertext: &[u8], output: &mut [u8]) -> Result<usize, CryptoError> {
        if ciphertext.len() < 16 {
            return Err(CryptoError::InvalidFormat);
        }
        
        let tag = &ciphertext[0..16];
        let encrypted_data = &ciphertext[16..];
        
        // Reconstruct nonce from message (deterministic)
        let nonce = self.extract_nonce_from_message(ciphertext);
        
        // Verify authentication tag first (constant time)
        let computed_tag = self.compute_gcm_tag(&nonce, &[], encrypted_data);
        if !constant_time_eq(tag, &computed_tag) {
            return Err(CryptoError::AuthenticationFailed);
        }
        
        // Decrypt only if authentication passes
        let plaintext_len = self.aes_gcm_decrypt(
            &self.key_schedule,
            &nonce,
            encrypted_data,
            output,
        )?;
        
        Ok(plaintext_len)
    }
    
    fn generate_nonce(&mut self) -> [u8; 12] {
        // Deterministic nonce generation (never repeat)
        self.nonce_counter += 1;
        
        let mut nonce = [0u8; 12];
        nonce[0..8].copy_from_slice(&self.nonce_counter.to_le_bytes());
        nonce[8..12].copy_from_slice(&get_device_id().to_le_bytes());
        
        nonce
    }
}

// Protocol stack optimizado para IoT
struct IoTProtocolStack {
    network_layer: LoRaWAN,
    transport_layer: CoAP,
    application_layer: MQTT,
    message_cache: LRUCache<MessageHash, CachedMessage>,
}

impl IoTProtocolStack {
    fn send_sensor_data(&mut self, sensor_id: u16, data: &SensorReading) -> Result<(), IoTError> {
        // 1. Serialize data determinísticamente
        let mut buffer = [0u8; 64];
        let serialized_len = data.serialize_deterministic(&mut buffer)?;
        
        // 2. Add timestamp and sequence number
        let message = IoTMessage {
            device_id: get_device_id(),
            sensor_id,
            timestamp: get_deterministic_timestamp(),
            sequence: self.get_next_sequence_number(),
            payload: &buffer[..serialized_len],
        };
        
        // 3. Encrypt message
        let mut encrypted_buffer = [0u8; 128];
        let encrypted_len = self.encrypt_message(&message, &mut encrypted_buffer)?;
        
        // 4. Send via LoRaWAN (with automatic retries)
        self.network_layer.send_with_retry(
            &encrypted_buffer[..encrypted_len],
            MAX_RETRIES,
            RETRY_BACKOFF_MS,
        )?;
        
        Ok(())
    }
    
    fn receive_commands(&mut self) -> Result<Vec<IoTCommand>, IoTError> {
        let mut commands = Vec::new();
        
        // Poll network interface (non-blocking)
        while let Some(raw_message) = self.network_layer.receive_non_blocking()? {
            // Decrypt and validate
            let mut decrypted_buffer = [0u8; 128];
            let decrypted_len = self.decrypt_message(&raw_message, &mut decrypted_buffer)?;
            
            // Parse command
            let command = IoTCommand::parse(&decrypted_buffer[..decrypted_len])?;
            
            // Validate command signature and freshness
            if self.validate_command(&command)? {
                commands.push(command);
            }
        }
        
        Ok(commands)
    }
}

// Sensor reading con deterministic serialization
struct SensorReading {
    temperature: i16,    // 0.1°C resolution
    humidity: u16,       // 0.1% resolution  
    pressure: u32,       // Pa
    battery_voltage: u16, // mV
    timestamp: u64,      // Unix timestamp
}

impl SensorReading {
    fn serialize_deterministic(&self, buffer: &mut [u8]) -> Result<usize, SerializationError> {
        if buffer.len() < 20 {
            return Err(SerializationError::BufferTooSmall);
        }
        
        let mut offset = 0;
        
        // Fixed-order serialization for determinism
        buffer[offset..offset+2].copy_from_slice(&self.temperature.to_le_bytes());
        offset += 2;
        
        buffer[offset..offset+2].copy_from_slice(&self.humidity.to_le_bytes());
        offset += 2;
        
        buffer[offset..offset+4].copy_from_slice(&self.pressure.to_le_bytes());
        offset += 4;
        
        buffer[offset..offset+2].copy_from_slice(&self.battery_voltage.to_le_bytes());
        offset += 2;
        
        buffer[offset..offset+8].copy_from_slice(&self.timestamp.to_le_bytes());
        offset += 8;
        
        // Add CRC for integrity
        let crc = crc16(&buffer[..offset]);
        buffer[offset..offset+2].copy_from_slice(&crc.to_le_bytes());
        offset += 2;
        
        Ok(offset)
    }
}
```

## Edge Computing Determinístico

```tempo
// Edge computing node para procesamiento local
struct EdgeComputingNode {
    local_models: ModelRepository,
    inference_engine: DeterministicInference,
    data_pipeline: StreamProcessor,
    result_cache: BoundedCache<InputHash, InferenceResult>,
}

struct DeterministicInference {
    quantized_weights: QuantizedWeights,
    fixed_point_arithmetic: FixedPointMath,
    inference_budget: ComputeBudget,
}

impl DeterministicInference {
    fn run_inference(&mut self, input: &SensorData) -> Result<InferenceResult, InferenceError> {
        // Pre-process input deterministically
        let preprocessed = self.preprocess_input(input)?;
        
        // Track computation budget
        let start_cycles = rdtsc();
        
        // Run quantized neural network
        let result = self.run_quantized_network(&preprocessed)?;
        
        let cycles_used = rdtsc() - start_cycles;
        
        // Verify we stayed within computation budget
        if cycles_used > self.inference_budget.max_cycles {
            return Err(InferenceError::BudgetExceeded);
        }
        
        // Post-process result
        let final_result = self.postprocess_result(result)?;
        
        Ok(final_result)
    }
    
    fn run_quantized_network(&self, input: &QuantizedTensor) -> Result<QuantizedTensor, InferenceError> {
        let mut current_layer_output = input.clone();
        
        // Process each layer deterministically
        for layer in &self.quantized_weights.layers {
            match layer {
                QuantizedLayer::Dense { weights, bias } => {
                    current_layer_output = self.dense_layer_inference(
                        &current_layer_output, 
                        weights, 
                        bias
                    )?;
                },
                QuantizedLayer::Conv2D { filters, bias, stride, padding } => {
                    current_layer_output = self.conv2d_inference(
                        &current_layer_output,
                        filters,
                        bias,
                        *stride,
                        *padding
                    )?;
                },
                QuantizedLayer::ReLU => {
                    current_layer_output = self.relu_activation(&current_layer_output);
                },
            }
        }
        
        Ok(current_layer_output)
    }
    
    fn dense_layer_inference(
        &self, 
        input: &QuantizedTensor, 
        weights: &QuantizedWeights, 
        bias: &QuantizedBias
    ) -> Result<QuantizedTensor, InferenceError> {
        let output_size = weights.output_dimensions();
        let mut output = QuantizedTensor::zeros(output_size);
        
        // Matrix multiplication usando fixed-point arithmetic
        for i in 0..output_size {
            let mut accumulator = 0i64;
            
            for j in 0..input.len() {
                // Quantized multiply-accumulate
                let weight_val = weights.get(i, j) as i64;
                let input_val = input.get(j) as i64;
                accumulator += weight_val * input_val;
            }
            
            // Add bias
            accumulator += bias.get(i) as i64;
            
            // Requantize and clip
            let requantized = self.requantize(accumulator, weights.scale(), input.scale());
            output.set(i, requantized.clamp(-128, 127) as i8);
        }
        
        Ok(output)
    }
}
```

## Práctica: Sistema de Monitoreo Ambiental

Implementa un sistema completo de monitoreo ambiental IoT que incluya:

1. Sensores multi-modal (temperatura, humedad, presión, calidad del aire)
2. Edge computing para detección de anomalías
3. Comunicación segura con gateway
4. Power management inteligente
5. Over-the-air updates determinísticas

## Ejercicio Final

Diseña un sistema de control industrial embebido que:

1. Controle múltiples actuadores con real-time constraints
2. Procese sensores en tiempo real con guarantees de latencia
3. Implemente fail-safe mechanisms determinísticos
4. Tenga comunicación industrial segura (Modbus/EtherCAT)
5. Soporte diagnostics y mantenimiento predictivo

**Próxima lección**: Distribución y Deployment