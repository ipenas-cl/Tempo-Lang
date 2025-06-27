╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 17: Concurrencia Determinística y CSP

## Objetivos
- Implementar Communicating Sequential Processes (CSP)
- Diseñar channels determinísticos
- Garantizar ausencia de race conditions

## Teoría: CSP en Tempo

Tempo usa CSP (Communicating Sequential Processes) para concurrencia determinística:

1. **Processes independientes** que se comunican solo via channels
2. **Channels síncronos** con semántica determinística  
3. **Select determinístico** para multiple channels
4. **Timeouts bounded** para evitar deadlocks

## Implementación de Channels

```tempo
struct Channel<T> {
    buffer: [Option<T>; CHANNEL_SIZE],
    read_pos: usize,
    write_pos: usize,
    count: usize,
    senders_waiting: u32,
    receivers_waiting: u32,
    closed: bool,
}

impl<T> Channel<T> {
    fn new() -> Self {
        Channel {
            buffer: [None; CHANNEL_SIZE],
            read_pos: 0,
            write_pos: 0,
            count: 0,
            senders_waiting: 0,
            receivers_waiting: 0,
            closed: false,
        }
    }
    
    fn send(&mut self, value: T) -> Result<(), ChannelError> {
        if self.closed {
            return Err(ChannelError::Closed);
        }
        
        // Buffered channel
        if self.count < CHANNEL_SIZE {
            self.buffer[self.write_pos] = Some(value);
            self.write_pos = (self.write_pos + 1) % CHANNEL_SIZE;
            self.count += 1;
            
            // Wake up waiting receivers
            if self.receivers_waiting > 0 {
                wake_receiver();
                self.receivers_waiting -= 1;
            }
            
            return Ok(());
        }
        
        // Channel full - sender must wait (deterministic blocking)
        self.senders_waiting += 1;
        yield_to_scheduler(); // Deterministic yield
        
        Err(ChannelError::WouldBlock)
    }
    
    fn receive(&mut self) -> Result<T, ChannelError> {
        if self.count > 0 {
            let value = self.buffer[self.read_pos].take().unwrap();
            self.read_pos = (self.read_pos + 1) % CHANNEL_SIZE;
            self.count -= 1;
            
            // Wake up waiting senders
            if self.senders_waiting > 0 {
                wake_sender();
                self.senders_waiting -= 1;
            }
            
            return Ok(value);
        }
        
        if self.closed {
            return Err(ChannelError::Closed);
        }
        
        // Channel empty - receiver must wait
        self.receivers_waiting += 1;
        yield_to_scheduler();
        
        Err(ChannelError::WouldBlock)
    }
    
    fn close(&mut self) {
        self.closed = true;
        // Wake all waiting processes
        wake_all_waiting();
    }
}
```

## Select Determinístico

```tempo
macro select {
    $(
        $channel:expr => $handler:expr,
    )*
    default => $default:expr,
} => {
    {
        let mut ready_channels = Vec::new();
        
        // Check all channels in deterministic order
        $(
            if $channel.is_ready() {
                ready_channels.push(($channel.id(), || $handler));
            }
        )*
        
        if !ready_channels.is_empty() {
            // Deterministic selection (lowest ID wins)
            ready_channels.sort_by_key(|&(id, _)| id);
            let (_, handler) = ready_channels[0];
            handler()
        } else {
            $default
        }
    }
}

// Uso del select determinístico
fn message_processor(ch1: &mut Channel<Message>, ch2: &mut Channel<Signal>) {
    loop {
        select! {
            ch1 => |msg| {
                process_message(msg);
            },
            ch2 => |signal| {
                handle_signal(signal);
            },
            default => {
                // No hay mensajes - trabajo background
                background_task();
                sleep_tics(1); // Sleep determinístico
            },
        }
    }
}
```

## Worker Pool Determinístico

```tempo
struct WorkerPool<Job, Result> {
    workers: [Worker<Job, Result>; NUM_WORKERS],
    job_queue: Channel<Job>,
    result_queue: Channel<Result>,
    next_worker: usize,
}

impl<Job, Result> WorkerPool<Job, Result> {
    fn new() -> Self {
        let mut workers = [Worker::new(); NUM_WORKERS];
        
        // Inicializar workers con IDs determinísticos
        for i in 0..NUM_WORKERS {
            workers[i].id = i;
        }
        
        WorkerPool {
            workers,
            job_queue: Channel::new(),
            result_queue: Channel::new(),
            next_worker: 0,
        }
    }
    
    fn submit_job(&mut self, job: Job) -> Result<(), PoolError> {
        self.job_queue.send(job)
    }
    
    fn get_result(&mut self) -> Result<Result, PoolError> {
        self.result_queue.receive()
    }
    
    fn round_robin_assign(&mut self, job: Job) {
        let worker_id = self.next_worker;
        self.workers[worker_id].assign_job(job);
        self.next_worker = (self.next_worker + 1) % NUM_WORKERS;
    }
}

struct Worker<Job, Result> {
    id: usize,
    job_channel: Channel<Job>,
    result_channel: Channel<Result>,
    state: WorkerState,
}

impl<Job, Result> Worker<Job, Result> {
    fn worker_loop(&mut self) {
        loop {
            match self.job_channel.receive() {
                Ok(job) => {
                    let result = self.process_job(job);
                    self.result_channel.send(result);
                },
                Err(ChannelError::Closed) => break,
                Err(ChannelError::WouldBlock) => {
                    yield_to_scheduler();
                }
            }
        }
    }
    
    fn process_job(&self, job: Job) -> Result {
        // Procesamiento determinístico del trabajo
        // Tiempo de ejecución bounded y predecible
        timed_execution(|| {
            // Lógica del trabajo aquí
        }, MAX_JOB_TIME)
    }
}
```

## Barrier Sincronización

```tempo
struct Barrier {
    participants: usize,
    waiting: usize,
    generation: u64,
    channels: [Channel<BarrierToken>; MAX_PARTICIPANTS],
}

impl Barrier {
    fn new(participants: usize) -> Self {
        Barrier {
            participants,
            waiting: 0,
            generation: 0,
            channels: [Channel::new(); MAX_PARTICIPANTS],
        }
    }
    
    fn wait(&mut self, participant_id: usize) -> Result<(), BarrierError> {
        let current_gen = self.generation;
        
        self.waiting += 1;
        
        if self.waiting == self.participants {
            // Último participante - despierta a todos
            self.generation += 1;
            self.waiting = 0;
            
            for i in 0..self.participants {
                if i != participant_id {
                    self.channels[i].send(BarrierToken::new(current_gen));
                }
            }
            
            Ok(())
        } else {
            // Espera a que el barrier se complete
            match self.channels[participant_id].receive() {
                Ok(token) => {
                    if token.generation == current_gen + 1 {
                        Ok(())
                    } else {
                        Err(BarrierError::GenerationMismatch)
                    }
                },
                Err(_) => Err(BarrierError::Timeout),
            }
        }
    }
}
```

## Pipeline Processing

```tempo
struct Pipeline<T> {
    stages: Vec<PipelineStage<T>>,
    input_channel: Channel<T>,
    output_channel: Channel<T>,
}

impl<T> Pipeline<T> {
    fn new() -> Self {
        Pipeline {
            stages: Vec::new(),
            input_channel: Channel::new(),
            output_channel: Channel::new(),
        }
    }
    
    fn add_stage<F>(&mut self, processor: F) 
    where F: Fn(T) -> T + Send + 'static {
        let stage = PipelineStage::new(processor);
        self.stages.push(stage);
    }
    
    fn start(&mut self) {
        // Conectar stages en cadena
        for i in 0..self.stages.len() {
            let input_ch = if i == 0 { 
                &self.input_channel 
            } else { 
                &self.stages[i-1].output_channel 
            };
            
            let output_ch = if i == self.stages.len() - 1 { 
                &self.output_channel 
            } else { 
                &self.stages[i+1].input_channel 
            };
            
            self.stages[i].connect(input_ch, output_ch);
            spawn_worker(|| self.stages[i].run());
        }
    }
    
    fn process(&mut self, item: T) -> Result<T, PipelineError> {
        self.input_channel.send(item)?;
        self.output_channel.receive()
    }
}

struct PipelineStage<T> {
    processor: Box<dyn Fn(T) -> T>,
    input_channel: Channel<T>,
    output_channel: Channel<T>,
}

impl<T> PipelineStage<T> {
    fn run(&mut self) {
        loop {
            match self.input_channel.receive() {
                Ok(item) => {
                    let result = (self.processor)(item);
                    if self.output_channel.send(result).is_err() {
                        break; // Pipeline cerrado
                    }
                },
                Err(ChannelError::Closed) => break,
                Err(_) => yield_to_scheduler(),
            }
        }
    }
}
```

## Actor Model Determinístico

```tempo
struct Actor<State, Message> {
    id: ActorId,
    state: State,
    mailbox: Channel<Message>,
    message_handler: fn(&mut State, Message) -> Vec<ActorMessage>,
}

impl<State, Message> Actor<State, Message> {
    fn new(id: ActorId, initial_state: State, handler: fn(&mut State, Message) -> Vec<ActorMessage>) -> Self {
        Actor {
            id,
            state: initial_state,
            mailbox: Channel::new(),
            message_handler: handler,
        }
    }
    
    fn run(&mut self) {
        loop {
            match self.mailbox.receive() {
                Ok(message) => {
                    let outgoing = (self.message_handler)(&mut self.state, message);
                    
                    // Enviar mensajes de salida en orden determinístico
                    for msg in outgoing {
                        ACTOR_SYSTEM.send_message(msg);
                    }
                },
                Err(ChannelError::Closed) => break,
                Err(_) => yield_to_scheduler(),
            }
        }
    }
    
    fn send(&mut self, message: Message) -> Result<(), ActorError> {
        self.mailbox.send(message)
    }
}

// Sistema de actores global
struct ActorSystem {
    actors: HashMap<ActorId, Box<dyn ActorTrait>>,
    message_router: MessageRouter,
}

impl ActorSystem {
    fn send_message(&mut self, msg: ActorMessage) {
        if let Some(actor) = self.actors.get_mut(&msg.target) {
            actor.receive(msg.payload);
        }
    }
    
    fn spawn_actor<S, M>(&mut self, actor: Actor<S, M>) -> ActorId {
        let id = actor.id;
        self.actors.insert(id, Box::new(actor));
        spawn_worker(move || {
            // Actor loop
        });
        id
    }
}
```

## Deadlock Detection

```tempo
struct DeadlockDetector {
    wait_graph: [[bool; MAX_PROCESSES]; MAX_PROCESSES],
    process_states: [ProcessState; MAX_PROCESSES],
}

impl DeadlockDetector {
    fn add_wait_edge(&mut self, waiting: ProcessId, holding: ProcessId) {
        self.wait_graph[waiting][holding] = true;
    }
    
    fn detect_cycle(&self) -> Option<Vec<ProcessId>> {
        // Algoritmo DFS para detectar ciclos
        for start in 0..MAX_PROCESSES {
            if let Some(cycle) = self.dfs_cycle_detection(start, &mut vec![false; MAX_PROCESSES]) {
                return Some(cycle);
            }
        }
        None
    }
    
    fn resolve_deadlock(&mut self, cycle: Vec<ProcessId>) {
        // Estrategia determinística de resolución:
        // 1. Elegir víctima con menor prioridad
        // 2. Rollback determinístico
        
        let victim = cycle.iter().min_by_key(|&&id| self.process_states[id].priority).unwrap();
        self.terminate_process(*victim);
    }
}
```

## Práctica: Sistema de Chat Determinístico

Implementa un sistema de chat que use CSP con:

1. Actores para usuarios
2. Channels para mensajes
3. Pipeline para procesamiento de mensajes
4. Garantías de orden determinístico

## Ejercicio Final

Diseña un sistema de procesamiento de logs distribuido que:

1. Use worker pools determinísticos
2. Pipeline de transformación de datos
3. Channels para comunicación entre workers
4. Barrier synchronization para checkpoints

**Próxima lección**: Macros y Metaprogramación