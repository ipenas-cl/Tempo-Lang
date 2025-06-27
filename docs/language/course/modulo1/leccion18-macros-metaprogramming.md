╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 18: Macros y Metaprogramación

## Objetivos
- Diseñar sistema de macros para Tempo
- Implementar metaprogramación determinística
- Crear DSLs (Domain Specific Languages)

## Teoría: Macros en Tempo

Los macros en Tempo están diseñados para:

1. **Generación de código en compile-time**
2. **Preservar determinismo** en todo momento
3. **Zero-cost abstractions** verificables
4. **Análisis estático** completo del código generado

## Sistema de Macros

```tempo
// Declarative macros (pattern matching)
macro for_range {
    // Patrón: for $var in $start..$end { $body }
    ($var:ident in $start:expr..$end:expr { $($body:stmt)* }) => {
        {
            let mut $var = $start;
            while $var < $end {
                $($body)*
                $var += 1;
            }
        }
    };
    
    // Patrón: for $var in $start..=$end { $body }
    ($var:ident in $start:expr..=$end:expr { $($body:stmt)* }) => {
        {
            let mut $var = $start;
            while $var <= $end {
                $($body)*
                $var += 1;
            }
        }
    };
}

// Uso del macro
fn test_macro() {
    for_range!(i in 0..10 {
        println!("i = {}", i);
    });
}
```

## Procedural Macros

```tempo
// Proc macro para generar serialización determinística
#[derive(DeterministicSerialize)]
struct NetworkMessage {
    id: u64,
    timestamp: u64,
    payload: [u8; 256],
    checksum: u32,
}

// El macro genera:
impl DeterministicSerialize for NetworkMessage {
    fn serialize(&self, buffer: &mut [u8]) -> Result<usize, SerializeError> {
        let mut offset = 0;
        
        // Serialización en orden determinístico (orden de declaración)
        buffer[offset..offset+8].copy_from_slice(&self.id.to_le_bytes());
        offset += 8;
        
        buffer[offset..offset+8].copy_from_slice(&self.timestamp.to_le_bytes());
        offset += 8;
        
        buffer[offset..offset+256].copy_from_slice(&self.payload);
        offset += 256;
        
        buffer[offset..offset+4].copy_from_slice(&self.checksum.to_le_bytes());
        offset += 4;
        
        Ok(offset)
    }
    
    fn deserialize(buffer: &[u8]) -> Result<(Self, usize), SerializeError> {
        if buffer.len() < Self::SERIALIZED_SIZE {
            return Err(SerializeError::InsufficientData);
        }
        
        let mut offset = 0;
        
        let id = u64::from_le_bytes([
            buffer[0], buffer[1], buffer[2], buffer[3],
            buffer[4], buffer[5], buffer[6], buffer[7]
        ]);
        offset += 8;
        
        let timestamp = u64::from_le_bytes([
            buffer[8], buffer[9], buffer[10], buffer[11],
            buffer[12], buffer[13], buffer[14], buffer[15]
        ]);
        offset += 8;
        
        let mut payload = [0u8; 256];
        payload.copy_from_slice(&buffer[offset..offset+256]);
        offset += 256;
        
        let checksum = u32::from_le_bytes([
            buffer[offset], buffer[offset+1], 
            buffer[offset+2], buffer[offset+3]
        ]);
        offset += 4;
        
        Ok((NetworkMessage { id, timestamp, payload, checksum }, offset))
    }
    
    const SERIALIZED_SIZE: usize = 8 + 8 + 256 + 4;
}
```

## Macro para WCET Analysis

```tempo
// Macro que genera análisis WCET automático
macro wcet_function {
    (
        fn $name:ident($($param:ident: $param_type:ty),*) -> $ret:ty 
        wcet_bound: $max_cycles:expr
        {
            $($body:stmt)*
        }
    ) => {
        fn $name($($param: $param_type),*) -> $ret {
            let start_cycles = rdtsc();
            
            let result = {
                $($body)*
            };
            
            let end_cycles = rdtsc();
            let actual_cycles = end_cycles - start_cycles;
            
            // Compile-time assertion
            static_assert!(actual_cycles <= $max_cycles, 
                         "WCET bound exceeded in function");
            
            // Runtime checking en debug mode
            #[cfg(debug_assertions)]
            {
                if actual_cycles > $max_cycles {
                    panic!("WCET violation: {} > {} cycles", 
                           actual_cycles, $max_cycles);
                }
            }
            
            result
        }
        
        // Generar metadata para análisis estático
        #[wcet_metadata]
        const fn $name_wcet_bound() -> u64 {
            $max_cycles
        }
    };
}

// Uso del macro WCET
wcet_function! {
    fn quicksort(arr: &mut [i32]) -> ()
    wcet_bound: 10000
    {
        if arr.len() <= 1 {
            return;
        }
        
        let pivot_index = partition(arr);
        quicksort(&mut arr[0..pivot_index]);
        quicksort(&mut arr[pivot_index + 1..]);
    }
}
```

## DSL para State Machines

```tempo
// DSL para máquinas de estado determinísticas
macro state_machine {
    (
        name: $name:ident,
        states: { $($state:ident),* },
        events: { $($event:ident),* },
        transitions: {
            $($from:ident --$ev:ident--> $to:ident { $($action:stmt)* })*
        }
    ) => {
        #[derive(Debug, Clone, Copy, PartialEq)]
        enum State {
            $($state),*
        }
        
        #[derive(Debug, Clone, Copy, PartialEq)]
        enum Event {
            $($event),*
        }
        
        struct $name {
            current_state: State,
            transition_count: u64,
        }
        
        impl $name {
            fn new() -> Self {
                Self {
                    current_state: State::$(first_state!($($state),*)),
                    transition_count: 0,
                }
            }
            
            fn handle_event(&mut self, event: Event) -> Result<(), StateMachineError> {
                let old_state = self.current_state;
                
                match (self.current_state, event) {
                    $(
                        (State::$from, Event::$ev) => {
                            // Execute transition actions
                            $($action)*
                            
                            self.current_state = State::$to;
                            self.transition_count += 1;
                            
                            println!("Transition: {:?} --{:?}--> {:?}", 
                                   State::$from, Event::$ev, State::$to);
                        }
                    )*
                    _ => {
                        return Err(StateMachineError::InvalidTransition {
                            state: self.current_state,
                            event,
                        });
                    }
                }
                
                Ok(())
            }
            
            fn current_state(&self) -> State {
                self.current_state
            }
        }
    };
}

// Uso del DSL
state_machine! {
    name: TrafficLight,
    states: { Red, Yellow, Green },
    events: { Timer, Emergency },
    transitions: {
        Red --Timer--> Green {
            println!("Light is now green");
        }
        Green --Timer--> Yellow {
            println!("Light is now yellow");
        }
        Yellow --Timer--> Red {
            println!("Light is now red");
        }
        Red --Emergency--> Green {
            println!("Emergency override to green");
        }
        Green --Emergency--> Red {
            println!("Emergency stop - red light");
        }
        Yellow --Emergency--> Red {
            println!("Emergency stop - red light");
        }
    }
}
```

## Generación de Código para Protocolos

```tempo
// Macro para generar parsers de protocolos binarios
macro binary_protocol {
    (
        name: $name:ident,
        fields: {
            $($field:ident: $type:ty = $size:expr),*
        }
    ) => {
        struct $name {
            $($field: $type),*
        }
        
        impl $name {
            const PACKET_SIZE: usize = 0 $(+ $size)*;
            
            fn parse(data: &[u8]) -> Result<Self, ProtocolError> {
                if data.len() < Self::PACKET_SIZE {
                    return Err(ProtocolError::InsufficientData);
                }
                
                let mut offset = 0;
                $(
                    let $field = parse_field::<$type>(&data[offset..offset + $size])?;
                    offset += $size;
                )*
                
                Ok($name { $($field),* })
            }
            
            fn serialize(&self) -> Vec<u8> {
                let mut buffer = Vec::with_capacity(Self::PACKET_SIZE);
                
                $(
                    buffer.extend_from_slice(&serialize_field(&self.$field));
                )*
                
                buffer
            }
            
            fn checksum(&self) -> u32 {
                let data = self.serialize();
                crc32(&data)
            }
        }
    };
}

// Uso para protocolo TCP simplificado
binary_protocol! {
    name: TcpHeader,
    fields: {
        src_port: u16 = 2,
        dst_port: u16 = 2,
        seq_num: u32 = 4,
        ack_num: u32 = 4,
        flags: u16 = 2,
        window: u16 = 2,
        checksum: u16 = 2
    }
}
```

## Macro para Generación de Tests

```tempo
// Macro para generar tests determinísticos
macro property_test {
    (
        fn $name:ident($($param:ident: $param_type:ty),*) 
        where $($constraint:expr),*
        ensures $postcondition:expr
    ) => {
        #[test]
        fn $name() {
            const NUM_TESTS: usize = 1000;
            let mut rng = DeterministicRng::new(0x12345678);
            
            for test_case in 0..NUM_TESTS {
                // Generar valores que satisfagan las constraints
                $(
                    let $param: $param_type = generate_constrained_value(&mut rng);
                    assert!($constraint, "Constraint violated for {}", stringify!($param));
                )*
                
                // Ejecutar función y verificar postcondition
                let result = test_function($($param),*);
                assert!($postcondition, 
                       "Postcondition failed for test case {}", test_case);
            }
        }
        
        fn test_function($($param: $param_type),*) -> TestResult {
            // Implementación de la función a testear
        }
    };
}

// Uso para test de ordenamiento
property_test! {
    fn test_sort(arr: Vec<i32>)
    where arr.len() <= 1000, arr.len() > 0
    ensures is_sorted(&result) && result.len() == arr.len()
}
```

## Compilación de Macros

```tempo
// Compilador de macros interno
struct MacroExpander {
    definitions: HashMap<String, MacroDefinition>,
    expansion_stack: Vec<MacroCall>,
    max_expansion_depth: usize,
}

impl MacroExpander {
    fn expand_macro(&mut self, call: MacroCall) -> Result<TokenStream, MacroError> {
        if self.expansion_stack.len() >= self.max_expansion_depth {
            return Err(MacroError::RecursionLimit);
        }
        
        self.expansion_stack.push(call.clone());
        
        let definition = self.definitions.get(&call.name)
            .ok_or(MacroError::UndefinedMacro)?;
        
        let expanded = match definition {
            MacroDefinition::Declarative(patterns) => {
                self.expand_declarative_macro(call, patterns)?
            },
            MacroDefinition::Procedural(proc_macro) => {
                self.expand_procedural_macro(call, proc_macro)?
            },
        };
        
        self.expansion_stack.pop();
        
        // Análisis estático del código expandido
        self.analyze_expanded_code(&expanded)?;
        
        Ok(expanded)
    }
    
    fn analyze_expanded_code(&self, code: &TokenStream) -> Result<(), MacroError> {
        // Verificar que el código expandido:
        // 1. No contenga operaciones no-determinísticas
        // 2. Mantenga bounds de WCET
        // 3. No introduzca memory leaks
        
        let analyzer = StaticAnalyzer::new();
        analyzer.analyze_determinism(code)?;
        analyzer.analyze_wcet_bounds(code)?;
        analyzer.analyze_memory_safety(code)?;
        
        Ok(())
    }
}
```

## Práctica: DSL para Configuración

Crea un DSL usando macros para configuración de sistema que:

1. Valide tipos en compile-time
2. Genere código de serialización
3. Mantenga determinismo en carga de config

```tempo
system_config! {
    name: ServerConfig,
    sections: {
        network: {
            port: u16 = 8080,
            max_connections: u32 = 1000,
            timeout_ms: u64 = 5000
        },
        memory: {
            pool_size: usize = 1_000_000,
            max_alloc: usize = 64_000
        }
    }
}
```

## Ejercicio Final

Implementa un macro que genere:

1. Parser para formato de logs custom
2. Validación de campos obligatorios
3. Conversión a estructura tipada
4. Serialización determinística

**Próxima lección**: FFI y Integración con C/C++