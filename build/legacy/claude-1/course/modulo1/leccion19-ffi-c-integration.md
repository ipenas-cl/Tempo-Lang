╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 19: FFI y Integración con C/C++

## Objetivos
- Implementar Foreign Function Interface (FFI) seguro
- Integrar código C/C++ existente manteniendo determinismo
- Crear wrappers seguros para librerías legacy

## Teoría: FFI Determinístico

FFI en Tempo debe mantener las garantías de determinismo:

1. **Análisis estático** de funciones C
2. **Wrapping seguro** con bounds verificables
3. **Memory layout compatible** con C
4. **Exception safety** entre fronteras de lenguaje

## Declaración de Funciones Externas

```tempo
// Declaración básica FFI
extern "C" {
    fn strlen(s: *const u8) -> usize;
    fn malloc(size: usize) -> *mut u8;
    fn free(ptr: *mut u8);
    fn memcpy(dest: *mut u8, src: *const u8, n: usize) -> *mut u8;
}

// FFI con atributos de análisis
extern "C" {
    #[wcet_bound(100)]  // Máximo 100 ciclos
    #[no_side_effects]  // Función pura
    fn sin(x: f64) -> f64;
    
    #[wcet_bound(50)]
    #[deterministic]    // Garantía de determinismo
    fn abs(x: i32) -> i32;
    
    #[blocking]         // Puede bloquear
    #[timeout(1000)]    // Timeout en ms
    fn read_file(path: *const u8, buffer: *mut u8, size: usize) -> i32;
}
```

## Tipos Compatible con C

```tempo
// Representación compatible con C
#[repr(C)]
struct Point {
    x: f64,
    y: f64,
}

#[repr(C)]
struct NetworkPacket {
    header: PacketHeader,
    payload: [u8; 1024],
    checksum: u32,
}

#[repr(C)]
union Value {
    int_val: i32,
    float_val: f32,
    ptr_val: *mut u8,
}

// Enums compatibles con C
#[repr(C)]
enum Status {
    Success = 0,
    Error = 1,
    Timeout = 2,
}

// Función callback compatible
type Callback = extern "C" fn(data: *mut u8, size: usize) -> i32;

extern "C" {
    fn register_callback(cb: Callback, user_data: *mut u8) -> i32;
    fn process_packet(packet: *const NetworkPacket) -> Status;
}
```

## Wrapper Seguro para malloc/free

```tempo
// Wrapper determinístico para malloc
struct CAllocator {
    allocations: HashMap<*mut u8, AllocationInfo>,
    total_allocated: usize,
    peak_usage: usize,
    allocation_count: u64,
}

struct AllocationInfo {
    size: usize,
    timestamp: u64,
    call_site: &'static str,
}

impl CAllocator {
    fn new() -> Self {
        CAllocator {
            allocations: HashMap::new(),
            total_allocated: 0,
            peak_usage: 0,
            allocation_count: 0,
        }
    }
    
    fn allocate(&mut self, size: usize, call_site: &'static str) -> Result<*mut u8, AllocError> {
        // Verificar límites
        if self.total_allocated + size > MAX_C_ALLOCATION {
            return Err(AllocError::LimitExceeded);
        }
        
        let ptr = unsafe { malloc(size) };
        if ptr.is_null() {
            return Err(AllocError::OutOfMemory);
        }
        
        // Rastrear allocación
        self.allocations.insert(ptr, AllocationInfo {
            size,
            timestamp: get_timestamp(),
            call_site,
        });
        
        self.total_allocated += size;
        self.peak_usage = max(self.peak_usage, self.total_allocated);
        self.allocation_count += 1;
        
        Ok(ptr)
    }
    
    fn deallocate(&mut self, ptr: *mut u8) -> Result<(), AllocError> {
        if let Some(info) = self.allocations.remove(&ptr) {
            unsafe { free(ptr); }
            self.total_allocated -= info.size;
            Ok(())
        } else {
            Err(AllocError::InvalidPointer)
        }
    }
    
    fn check_leaks(&self) -> Vec<AllocationInfo> {
        self.allocations.values().cloned().collect()
    }
}

// Uso seguro
fn safe_c_allocation() -> Result<(), AllocError> {
    let mut allocator = CAllocator::new();
    
    let buffer = allocator.allocate(1024, file_line!())?;
    
    // Usar buffer...
    unsafe {
        let data = slice::from_raw_parts_mut(buffer, 1024);
        data.fill(0);
    }
    
    allocator.deallocate(buffer)?;
    
    // Verificar que no hay leaks
    let leaks = allocator.check_leaks();
    if !leaks.is_empty() {
        return Err(AllocError::MemoryLeak);
    }
    
    Ok(())
}
```

## Integración con OpenSSL

```tempo
// Binding para OpenSSL con wrappers seguros
extern "C" {
    fn SSL_library_init() -> i32;
    fn SSL_CTX_new(method: *const u8) -> *mut SslCtx;
    fn SSL_CTX_free(ctx: *mut SslCtx);
    fn SSL_new(ctx: *mut SslCtx) -> *mut Ssl;
    fn SSL_free(ssl: *mut Ssl);
    fn SSL_read(ssl: *mut Ssl, buf: *mut u8, num: i32) -> i32;
    fn SSL_write(ssl: *mut Ssl, buf: *const u8, num: i32) -> i32;
}

// Tipos opacos
enum SslCtx {}
enum Ssl {}

// Wrapper seguro
struct TlsConnection {
    ssl: *mut Ssl,
    ctx: *mut SslCtx,
    read_timeout: Duration,
    write_timeout: Duration,
}

impl TlsConnection {
    fn new() -> Result<Self, TlsError> {
        // Inicializar OpenSSL de forma determinística
        let init_result = unsafe { SSL_library_init() };
        if init_result != 1 {
            return Err(TlsError::InitializationFailed);
        }
        
        let ctx = unsafe { SSL_CTX_new(TLS_method()) };
        if ctx.is_null() {
            return Err(TlsError::ContextCreation);
        }
        
        let ssl = unsafe { SSL_new(ctx) };
        if ssl.is_null() {
            unsafe { SSL_CTX_free(ctx); }
            return Err(TlsError::SslCreation);
        }
        
        Ok(TlsConnection {
            ssl,
            ctx,
            read_timeout: Duration::from_secs(30),
            write_timeout: Duration::from_secs(30),
        })
    }
    
    fn read_bounded(&mut self, buffer: &mut [u8]) -> Result<usize, TlsError> {
        let start_time = Instant::now();
        
        // Read con timeout determinístico
        let bytes_read = timed_operation(self.read_timeout, || {
            unsafe { SSL_read(self.ssl, buffer.as_mut_ptr(), buffer.len() as i32) }
        })?;
        
        if bytes_read < 0 {
            return Err(TlsError::ReadFailed);
        }
        
        // Verificar WCET
        let elapsed = start_time.elapsed();
        if elapsed > self.read_timeout {
            return Err(TlsError::Timeout);
        }
        
        Ok(bytes_read as usize)
    }
    
    fn write_all(&mut self, data: &[u8]) -> Result<(), TlsError> {
        let mut total_written = 0;
        let start_time = Instant::now();
        
        while total_written < data.len() {
            let remaining = &data[total_written..];
            
            let written = timed_operation(self.write_timeout, || {
                unsafe { SSL_write(self.ssl, remaining.as_ptr(), remaining.len() as i32) }
            })?;
            
            if written <= 0 {
                return Err(TlsError::WriteFailed);
            }
            
            total_written += written as usize;
            
            // Verificar timeout total
            if start_time.elapsed() > self.write_timeout {
                return Err(TlsError::Timeout);
            }
        }
        
        Ok(())
    }
}

impl Drop for TlsConnection {
    fn drop(&mut self) {
        unsafe {
            SSL_free(self.ssl);
            SSL_CTX_free(self.ctx);
        }
    }
}
```

## Integración con SQLite

```tempo
// FFI para SQLite con garantías determinísticas
extern "C" {
    fn sqlite3_open(filename: *const u8, ppDb: *mut *mut sqlite3) -> i32;
    fn sqlite3_close(db: *mut sqlite3) -> i32;
    fn sqlite3_prepare_v2(db: *mut sqlite3, zSql: *const u8, nByte: i32, 
                         ppStmt: *mut *mut sqlite3_stmt, pzTail: *mut *const u8) -> i32;
    fn sqlite3_step(stmt: *mut sqlite3_stmt) -> i32;
    fn sqlite3_finalize(stmt: *mut sqlite3_stmt) -> i32;
    fn sqlite3_column_int(stmt: *mut sqlite3_stmt, iCol: i32) -> i32;
    fn sqlite3_column_text(stmt: *mut sqlite3_stmt, iCol: i32) -> *const u8;
}

enum sqlite3 {}
enum sqlite3_stmt {}

// Wrapper determinístico
struct Database {
    db: *mut sqlite3,
    prepared_statements: HashMap<String, *mut sqlite3_stmt>,
    query_timeout: Duration,
    max_memory_usage: usize,
}

impl Database {
    fn open(path: &str) -> Result<Self, DatabaseError> {
        let mut db: *mut sqlite3 = ptr::null_mut();
        let path_cstr = CString::new(path).unwrap();
        
        let result = unsafe { 
            sqlite3_open(path_cstr.as_ptr() as *const u8, &mut db) 
        };
        
        if result != SQLITE_OK {
            return Err(DatabaseError::OpenFailed(result));
        }
        
        // Configurar SQLite para comportamiento determinístico
        let config_queries = [
            "PRAGMA synchronous = FULL",
            "PRAGMA cache_size = 1000",
            "PRAGMA temp_store = MEMORY",
            "PRAGMA mmap_size = 0",  // Disable memory mapping for determinism
        ];
        
        for query in &config_queries {
            unsafe {
                let mut stmt: *mut sqlite3_stmt = ptr::null_mut();
                let query_cstr = CString::new(*query).unwrap();
                
                sqlite3_prepare_v2(db, query_cstr.as_ptr() as *const u8, -1, &mut stmt, ptr::null_mut());
                sqlite3_step(stmt);
                sqlite3_finalize(stmt);
            }
        }
        
        Ok(Database {
            db,
            prepared_statements: HashMap::new(),
            query_timeout: Duration::from_secs(10),
            max_memory_usage: 100 * 1024 * 1024, // 100MB
        })
    }
    
    fn execute_query(&mut self, sql: &str, params: &[SqlValue]) -> Result<Vec<Row>, DatabaseError> {
        let start_time = Instant::now();
        
        // Preparar statement si no existe
        let stmt = if let Some(&stmt) = self.prepared_statements.get(sql) {
            stmt
        } else {
            let mut stmt: *mut sqlite3_stmt = ptr::null_mut();
            let sql_cstr = CString::new(sql).unwrap();
            
            let result = unsafe {
                sqlite3_prepare_v2(self.db, sql_cstr.as_ptr() as *const u8, -1, &mut stmt, ptr::null_mut())
            };
            
            if result != SQLITE_OK {
                return Err(DatabaseError::PrepareFailed(result));
            }
            
            self.prepared_statements.insert(sql.to_string(), stmt);
            stmt
        };
        
        // Bind parameters (deterministic order)
        for (i, param) in params.iter().enumerate() {
            self.bind_parameter(stmt, i + 1, param)?;
        }
        
        // Execute with timeout
        let mut rows = Vec::new();
        loop {
            if start_time.elapsed() > self.query_timeout {
                return Err(DatabaseError::Timeout);
            }
            
            let step_result = unsafe { sqlite3_step(stmt) };
            
            match step_result {
                SQLITE_ROW => {
                    let row = self.extract_row(stmt)?;
                    rows.push(row);
                },
                SQLITE_DONE => break,
                _ => return Err(DatabaseError::StepFailed(step_result)),
            }
        }
        
        Ok(rows)
    }
    
    fn bind_parameter(&self, stmt: *mut sqlite3_stmt, index: i32, value: &SqlValue) -> Result<(), DatabaseError> {
        match value {
            SqlValue::Integer(i) => {
                unsafe { sqlite3_bind_int(stmt, index, *i) };
            },
            SqlValue::Text(s) => {
                let cstr = CString::new(s.as_str()).unwrap();
                unsafe { 
                    sqlite3_bind_text(stmt, index, cstr.as_ptr() as *const u8, -1, SQLITE_TRANSIENT) 
                };
            },
            SqlValue::Null => {
                unsafe { sqlite3_bind_null(stmt, index) };
            },
        }
        Ok(())
    }
}

#[derive(Debug)]
enum SqlValue {
    Integer(i32),
    Text(String),
    Null,
}

impl Drop for Database {
    fn drop(&mut self) {
        // Cleanup prepared statements
        for (_, stmt) in &self.prepared_statements {
            unsafe { sqlite3_finalize(*stmt); }
        }
        
        // Close database
        unsafe { sqlite3_close(self.db); }
    }
}
```

## Callback Safety

```tempo
// Sistema de callbacks seguro entre C y Tempo
struct CallbackManager {
    callbacks: HashMap<u64, Box<dyn Fn(*mut u8, usize) -> i32>>,
    next_id: u64,
}

static mut CALLBACK_MANAGER: CallbackManager = CallbackManager {
    callbacks: HashMap::new(),
    next_id: 1,
};

// Callback wrapper seguro
extern "C" fn callback_wrapper(data: *mut u8, size: usize, user_data: *mut u8) -> i32 {
    let callback_id = user_data as u64;
    
    unsafe {
        if let Some(callback) = CALLBACK_MANAGER.callbacks.get(&callback_id) {
            // Verificar bounds de memoria
            if data.is_null() || size > MAX_CALLBACK_DATA_SIZE {
                return -1;
            }
            
            // Ejecutar callback con timeout
            let result = timed_operation(Duration::from_millis(100), || {
                callback(data, size)
            });
            
            match result {
                Ok(value) => value,
                Err(_) => -1,  // Timeout o error
            }
        } else {
            -1  // Callback ID inválido
        }
    }
}

fn register_safe_callback<F>(callback: F) -> u64 
where F: Fn(*mut u8, usize) -> i32 + 'static {
    unsafe {
        let id = CALLBACK_MANAGER.next_id;
        CALLBACK_MANAGER.next_id += 1;
        CALLBACK_MANAGER.callbacks.insert(id, Box::new(callback));
        
        // Registrar con la librería C
        register_c_callback(callback_wrapper, id as *mut u8);
        
        id
    }
}
```

## Análisis Estático de FFI

```tempo
// Analizador para verificar safety de FFI
struct FfiAnalyzer {
    unsafe_functions: HashSet<String>,
    bounded_functions: HashMap<String, WcetBound>,
    pure_functions: HashSet<String>,
}

impl FfiAnalyzer {
    fn analyze_extern_block(&mut self, block: &ExternBlock) -> Result<(), FfiError> {
        for function in &block.functions {
            self.analyze_extern_function(function)?;
        }
        Ok(())
    }
    
    fn analyze_extern_function(&mut self, func: &ExternFunction) -> Result<(), FfiError> {
        // Verificar que funciones unsafe estén marcadas
        if self.is_potentially_unsafe(func) && !func.has_attribute("unsafe") {
            return Err(FfiError::UnsafeNotMarked(func.name.clone()));
        }
        
        // Verificar bounds WCET
        if let Some(bound) = func.get_wcet_bound() {
            self.verify_wcet_bound(func, bound)?;
        }
        
        // Verificar determinismo
        if func.has_attribute("deterministic") {
            self.verify_deterministic(func)?;
        }
        
        Ok(())
    }
    
    fn is_potentially_unsafe(&self, func: &ExternFunction) -> bool {
        // Funciones que manejan punteros raw son unsafe
        func.parameters.iter().any(|p| p.is_raw_pointer()) ||
        func.return_type.is_raw_pointer() ||
        self.unsafe_functions.contains(&func.name)
    }
}
```

## Práctica: Wrapper para zlib

Crea un wrapper seguro para zlib que:

1. Maneje compresión/descompresión con bounds
2. Verifique integridad de datos
3. Tenga timeouts determinísticos
4. No tenga memory leaks

## Ejercicio Final

Integra una librería C de tu elección manteniendo:

1. Safety de memoria
2. Determinismo temporal
3. Error handling robusto
4. Análisis estático de correctness

**Próxima lección**: Testing y Debugging Determinístico