╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 9: El Momento Mágico: Self-Hosting - Bootstrapping the Compiler

## Objetivos de la Lección
- Entender el proceso de bootstrapping de un compilador
- Implementar un compilador que se compile a sí mismo
- Resolver los desafíos circulares del self-hosting
- Verificar la corrección del compilador bootstrapped

## 1. Teoría (20%)

### ¿Qué es Self-Hosting?

Un compilador self-hosted es aquel que está escrito en el mismo lenguaje que compila. Es el punto culminante del desarrollo de un lenguaje, demostrando que es lo suficientemente expresivo y maduro para implementar su propio compilador.

### El Problema del Huevo y la Gallina

¿Cómo compilamos un compilador de Chronos escrito en Chronos si no tenemos un compilador de Chronos?

**Solución: Bootstrapping en etapas**

```
1. Stage 0: Compilador mínimo en Assembly
2. Stage 1: Compilador simple en Chronos, compilado por Stage 0
3. Stage 2: Compilador completo en Chronos, compilado por Stage 1
4. Stage N: El compilador se compila a sí mismo
```

### Ventajas del Self-Hosting

1. **Dogfooding**: Usamos nuestro propio lenguaje
2. **Mejora continua**: Nuevas características benefician al compilador
3. **Confianza**: Si puede compilarse a sí mismo, es robusto
4. **Optimizaciones**: El compilador se beneficia de sus propias optimizaciones

### Verificación de Corrección

**Prueba de punto fijo**: Si compilamos el compilador consigo mismo repetidamente, debe producir exactamente el mismo binario.

```
Chronos Compiler (fuente) → Compiler A → Compiler B → Compiler C
                           Stage 0      Stage 1      Stage 2

Si B == C, entonces el compilador es estable
```

## 2. Práctica (60%)

### Stage 0: Compilador Mínimo en Assembly

```asm
; stage0_compiler.asm
; Compilador ultra-mínimo que puede compilar un subconjunto de Chronos

section .data
    ; Palabras clave mínimas
    kw_fn       db "fn", 0
    kw_return   db "return", 0
    kw_let      db "let", 0
    kw_if       db "if", 0
    
    ; Buffer de entrada
    input_buffer    times 65536 db 0
    input_size      dd 0
    input_pos       dd 0
    
    ; Buffer de salida
    output_buffer   times 65536 db 0
    output_pos      dd 0
    
    ; Tabla de símbolos mínima
    symbols         times 1024 db 0  ; 32 símbolos * 32 bytes
    symbol_count    dd 0

section .text
global _start

_start:
    ; Leer archivo fuente
    call read_input_file
    
    ; Compilar
    call compile_minimal
    
    ; Escribir salida
    call write_output_file
    
    ; Salir
    mov eax, 1
    xor ebx, ebx
    int 0x80

; compile_minimal: Compilador mínimo para subset de Chronos
compile_minimal:
    push ebp
    mov ebp, esp
    
    ; Emitir header
    call emit_asm_header
    
.parse_loop:
    ; Saltar whitespace
    call skip_whitespace
    
    ; Verificar EOF
    call peek_char
    cmp al, 0
    je .done
    
    ; Buscar palabra clave
    call parse_keyword
    cmp eax, 0
    je .parse_fn
    cmp eax, 1
    je .error
    
.parse_fn:
    ; Parsear función simple
    call parse_function_minimal
    jmp .parse_loop
    
.error:
    mov eax, -1
    
.done:
    mov esp, ebp
    pop ebp
    ret

; parse_function_minimal: Parsea función muy simple
; fn nombre() { return valor; }
parse_function_minimal:
    push ebp
    mov ebp, esp
    push ebx
    push edi
    
    ; Consumir "fn"
    call consume_token
    
    ; Parsear nombre
    call parse_identifier
    push eax                    ; Guardar nombre
    
    ; Emitir label de función
    call emit_label
    
    ; Consumir "()"
    call expect_char
    db '('
    call expect_char
    db ')'
    
    ; Consumir "{"
    call expect_char
    db '{'
    
    ; Emitir prólogo
    call emit_function_prologue
    
    ; Parsear cuerpo (solo return por ahora)
    call skip_whitespace
    call parse_return_statement
    
    ; Emitir epílogo
    call emit_function_epilogue
    
    ; Consumir "}"
    call expect_char
    db '}'
    
    pop eax                     ; Nombre de función
    pop edi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; parse_return_statement: Parsea return simple
parse_return_statement:
    push ebp
    mov ebp, esp
    
    ; Consumir "return"
    call consume_token
    
    ; Parsear expresión (solo números por ahora)
    call parse_number
    
    ; Emitir código de retorno
    push eax
    call emit_return_value
    pop eax
    
    ; Consumir ";"
    call expect_char
    db ';'
    
    mov esp, ebp
    pop ebp
    ret

; Funciones de emisión de código

emit_asm_header:
    call emit_string
    db "section .text", 10
    db "global _start", 10, 10
    db "_start:", 10
    db "    call main", 10
    db "    mov ebx, eax", 10
    db "    mov eax, 1", 10
    db "    int 0x80", 10, 10, 0
    ret

emit_function_prologue:
    call emit_string
    db "    push ebp", 10
    db "    mov ebp, esp", 10, 0
    ret

emit_function_epilogue:
    call emit_string
    db "    mov esp, ebp", 10
    db "    pop ebp", 10
    db "    ret", 10, 10, 0
    ret

emit_return_value:
    ; Entrada: [ESP+4] = valor
    push ebp
    mov ebp, esp
    
    call emit_string
    db "    mov eax, ", 0
    
    mov eax, [ebp + 8]
    call emit_decimal
    call emit_newline
    
    mov esp, ebp
    pop ebp
    ret 4
```

### Stage 1: Compilador en Chronos (Mínimo)

```tempo
// stage1_compiler.ch
// Compilador escrito en subset mínimo de Chronos
// Compilado por stage0

fn main() {
    let tokens = tokenize();
    let ast = parse(tokens);
    let code = generate(ast);
    output(code);
    return 0;
}

fn tokenize() {
    let pos = 0;
    let tokens = 0;  // Simplificado: array estático
    
    while pos < input_size {
        let ch = input_buffer[pos];
        
        if is_whitespace(ch) {
            pos = pos + 1;
        } else if is_alpha(ch) {
            let token = scan_identifier(pos);
            add_token(tokens, token);
        } else if is_digit(ch) {
            let token = scan_number(pos);
            add_token(tokens, token);
        } else {
            let token = scan_operator(pos);
            add_token(tokens, token);
        }
    }
    
    return tokens;
}

fn parse(tokens) {
    let pos = 0;
    let ast = create_program_node();
    
    while tokens[pos].type != TOKEN_EOF {
        if tokens[pos].type == TOKEN_FN {
            let func = parse_function(tokens, pos);
            add_child(ast, func);
        } else {
            error("Expected function");
        }
    }
    
    return ast;
}

fn parse_function(tokens, pos) {
    let node = create_function_node();
    
    pos = pos + 1;  // Consumir 'fn'
    
    // Parsear nombre
    if tokens[pos].type != TOKEN_IDENT {
        error("Expected identifier");
    }
    node.name = tokens[pos].value;
    pos = pos + 1;
    
    // Parsear parámetros
    if tokens[pos].type != TOKEN_LPAREN {
        error("Expected (");
    }
    pos = pos + 1;
    
    // Por ahora, sin parámetros
    
    if tokens[pos].type != TOKEN_RPAREN {
        error("Expected )");
    }
    pos = pos + 1;
    
    // Parsear cuerpo
    node.body = parse_block(tokens, pos);
    
    return node;
}

fn generate(ast) {
    let output = create_string_buffer();
    
    // Generar header
    append(output, "section .text\n");
    append(output, "global _start\n\n");
    
    // Generar funciones
    let node = ast.first_child;
    while node != 0 {
        generate_function(output, node);
        node = node.next;
    }
    
    // Generar _start
    append(output, "_start:\n");
    append(output, "    call main\n");
    append(output, "    mov ebx, eax\n");
    append(output, "    mov eax, 1\n");
    append(output, "    int 0x80\n");
    
    return output;
}

fn generate_function(output, func) {
    // Emitir label
    append(output, func.name);
    append(output, ":\n");
    
    // Prólogo
    append(output, "    push ebp\n");
    append(output, "    mov ebp, esp\n");
    
    // Generar cuerpo
    generate_block(output, func.body);
    
    // Epílogo
    append(output, "    mov esp, ebp\n");
    append(output, "    pop ebp\n");
    append(output, "    ret\n\n");
}
```

### Stage 2: Compilador Completo en Chronos

```tempo
// stage2_compiler.ch
// Compilador completo con todas las características
// Este es el que se compilará a sí mismo

struct Token {
    type: i32,
    value: i32,
    line: i32,
    column: i32
}

struct ASTNode {
    type: i32,
    value: i32,
    left: *ASTNode,
    right: *ASTNode,
    next: *ASTNode
}

struct Compiler {
    tokens: *Token,
    token_count: i32,
    token_pos: i32,
    
    ast: *ASTNode,
    
    output: *u8,
    output_size: i32,
    output_capacity: i32,
    
    symbols: *Symbol,
    symbol_count: i32,
    
    errors: i32
}

fn create_compiler() -> *Compiler {
    let c = allocate(sizeof(Compiler));
    c.tokens = allocate(MAX_TOKENS * sizeof(Token));
    c.output = allocate(OUTPUT_BUFFER_SIZE);
    c.symbols = allocate(MAX_SYMBOLS * sizeof(Symbol));
    return c;
}

fn compile(c: *Compiler, input: *u8, input_size: i32) -> i32 {
    // Fase 1: Tokenización
    tokenize(c, input, input_size);
    if c.errors > 0 {
        return -1;
    }
    
    // Fase 2: Parsing
    c.ast = parse(c);
    if c.errors > 0 {
        return -1;
    }
    
    // Fase 3: Análisis semántico
    analyze(c);
    if c.errors > 0 {
        return -1;
    }
    
    // Fase 4: Generación de código
    generate_code(c);
    if c.errors > 0 {
        return -1;
    }
    
    return 0;
}

fn tokenize(c: *Compiler, input: *u8, size: i32) {
    let pos = 0;
    let line = 1;
    let column = 1;
    
    while pos < size {
        // Saltar whitespace
        while pos < size && is_whitespace(input[pos]) {
            if input[pos] == '\n' {
                line = line + 1;
                column = 1;
            } else {
                column = column + 1;
            }
            pos = pos + 1;
        }
        
        if pos >= size {
            break;
        }
        
        let start_pos = pos;
        let start_column = column;
        
        // Identificadores y keywords
        if is_alpha(input[pos]) || input[pos] == '_' {
            while pos < size && (is_alnum(input[pos]) || input[pos] == '_') {
                pos = pos + 1;
                column = column + 1;
            }
            
            let token = create_token(c, start_pos, pos - start_pos);
            token.type = classify_identifier(input + start_pos, pos - start_pos);
            token.line = line;
            token.column = start_column;
            add_token(c, token);
        }
        // Números
        else if is_digit(input[pos]) {
            let value = 0;
            while pos < size && is_digit(input[pos]) {
                value = value * 10 + (input[pos] - '0');
                pos = pos + 1;
                column = column + 1;
            }
            
            let token = create_token(c, start_pos, pos - start_pos);
            token.type = TOKEN_NUMBER;
            token.value = value;
            token.line = line;
            token.column = start_column;
            add_token(c, token);
        }
        // Operadores y delimitadores
        else {
            let token = scan_operator(c, input, pos, size);
            token.line = line;
            token.column = column;
            add_token(c, token);
            
            // Actualizar posición
            let op_len = operator_length(token.type);
            pos = pos + op_len;
            column = column + op_len;
        }
    }
    
    // Agregar EOF
    let eof_token: Token;
    eof_token.type = TOKEN_EOF;
    eof_token.line = line;
    eof_token.column = column;
    add_token(c, eof_token);
}

fn parse(c: *Compiler) -> *ASTNode {
    c.token_pos = 0;
    return parse_program(c);
}

fn parse_program(c: *Compiler) -> *ASTNode {
    let program = create_node(NODE_PROGRAM);
    let last: *ASTNode = 0;
    
    while current_token(c).type != TOKEN_EOF {
        let decl: *ASTNode = 0;
        
        if current_token(c).type == TOKEN_FN {
            decl = parse_function(c);
        } else if current_token(c).type == TOKEN_STRUCT {
            decl = parse_struct(c);
        } else if current_token(c).type == TOKEN_LET {
            decl = parse_global_var(c);
        } else {
            error(c, "Expected declaration");
            skip_to_sync_token(c);
            continue;
        }
        
        if decl != 0 {
            if last == 0 {
                program.left = decl;
            } else {
                last.next = decl;
            }
            last = decl;
        }
    }
    
    return program;
}

fn generate_code(c: *Compiler) {
    // Emitir header
    emit_string(c, "section .text\n");
    emit_string(c, "global _start\n\n");
    
    // Generar código para cada declaración
    let node = c.ast.left;
    while node != 0 {
        if node.type == NODE_FUNCTION {
            generate_function(c, node);
        } else if node.type == NODE_STRUCT {
            // Las estructuras no generan código directamente
        } else if node.type == NODE_GLOBAL_VAR {
            generate_global_var(c, node);
        }
        
        node = node.next;
    }
    
    // Generar _start si no hay main
    if !has_main_function(c) {
        error(c, "No main function found");
    } else {
        emit_string(c, "_start:\n");
        emit_string(c, "    call main\n");
        emit_string(c, "    mov ebx, eax\n");
        emit_string(c, "    mov eax, 1\n");
        emit_string(c, "    int 0x80\n\n");
    }
    
    // Emitir sección de datos
    emit_string(c, "section .data\n");
    generate_data_section(c);
}

// Función principal del compilador
fn main() -> i32 {
    // Leer argumentos
    if argc < 2 {
        print("Usage: tempo <input.ch>\n");
        return 1;
    }
    
    // Leer archivo de entrada
    let input = read_file(argv[1]);
    if input == 0 {
        print("Error: Cannot read input file\n");
        return 1;
    }
    
    // Crear compilador
    let compiler = create_compiler();
    
    // Compilar
    let result = compile(compiler, input, file_size);
    if result < 0 {
        print("Compilation failed with ");
        print_number(compiler.errors);
        print(" errors\n");
        return 1;
    }
    
    // Escribir salida
    let output_name = replace_extension(argv[1], ".s");
    write_file(output_name, compiler.output, compiler.output_size);
    
    print("Compilation successful\n");
    return 0;
}
```

### El Proceso de Bootstrapping

```bash
#!/bin/bash
# bootstrap.sh - Script para bootstrapping del compilador

echo "=== Chronos Compiler Bootstrapping ==="

# Paso 1: Ensamblar el compilador stage0
echo "[1/5] Assembling stage0 compiler..."
nasm -f elf32 stage0_compiler.asm -o stage0_compiler.o
ld -m elf_i386 stage0_compiler.o -o stage0_compiler

# Paso 2: Compilar stage1 con stage0
echo "[2/5] Compiling stage1 with stage0..."
./stage0_compiler stage1_compiler.ch stage1_compiler.s
nasm -f elf32 stage1_compiler.s -o stage1_compiler.o
ld -m elf_i386 stage1_compiler.o -o stage1_compiler

# Paso 3: Compilar stage2 con stage1
echo "[3/5] Compiling stage2 with stage1..."
./stage1_compiler stage2_compiler.ch stage2_compiler.s
nasm -f elf32 stage2_compiler.s -o stage2_compiler.o
ld -m elf_i386 stage2_compiler.o -o stage2_compiler

# Paso 4: Auto-compilar stage2 (primera vez)
echo "[4/5] Self-compiling stage2 (first time)..."
./stage2_compiler stage2_compiler.ch stage2_compiler_self1.s
nasm -f elf32 stage2_compiler_self1.s -o stage2_compiler_self1.o
ld -m elf_i386 stage2_compiler_self1.o -o stage2_compiler_self1

# Paso 5: Auto-compilar stage2 (segunda vez)
echo "[5/5] Self-compiling stage2 (second time)..."
./stage2_compiler_self1 stage2_compiler.ch stage2_compiler_self2.s
nasm -f elf32 stage2_compiler_self2.s -o stage2_compiler_self2.o
ld -m elf_i386 stage2_compiler_self2.o -o stage2_compiler_self2

# Verificar punto fijo
echo "Verifying fixed point..."
if diff stage2_compiler_self1 stage2_compiler_self2 > /dev/null; then
    echo "SUCCESS: Fixed point reached! The compiler is self-hosting."
    cp stage2_compiler_self2 tempo
    echo "The Chronos compiler is now available as './tempo'"
else
    echo "ERROR: Fixed point not reached. The compiler is not stable."
    exit 1
fi
```

### Verificación y Testing del Compilador Self-Hosted

```tempo
// test_self_hosting.ch
// Tests para verificar que el compilador self-hosted funciona correctamente

fn test_basic_arithmetic() -> bool {
    // Test que el compilador puede compilar aritmética básica
    let a = 10;
    let b = 20;
    let c = a + b;
    return c == 30;
}

fn test_control_flow() -> bool {
    // Test de estructuras de control
    let sum = 0;
    let i = 0;
    
    while i < 10 {
        if i % 2 == 0 {
            sum = sum + i;
        }
        i = i + 1;
    }
    
    return sum == 20;  // 0 + 2 + 4 + 6 + 8
}

fn test_functions() -> bool {
    // Test de llamadas a funciones
    fn add(a: i32, b: i32) -> i32 {
        return a + b;
    }
    
    fn multiply(a: i32, b: i32) -> i32 {
        return a * b;
    }
    
    let result = add(multiply(3, 4), 5);
    return result == 17;
}

fn test_recursion() -> bool {
    // Test de recursión
    fn factorial(n: i32) -> i32 {
        if n <= 1 {
            return 1;
        }
        return n * factorial(n - 1);
    }
    
    return factorial(5) == 120;
}

fn test_structs() -> bool {
    // Test de estructuras
    struct Point {
        x: i32,
        y: i32
    }
    
    let p: Point;
    p.x = 10;
    p.y = 20;
    
    return p.x + p.y == 30;
}

fn test_arrays() -> bool {
    // Test de arrays
    let arr: i32[5];
    let i = 0;
    
    // Llenar array
    while i < 5 {
        arr[i] = i * i;
        i = i + 1;
    }
    
    // Verificar valores
    return arr[0] == 0 && arr[1] == 1 && arr[2] == 4 && 
           arr[3] == 9 && arr[4] == 16;
}

fn run_all_tests() -> i32 {
    let passed = 0;
    let failed = 0;
    
    print("Running self-hosting tests...\n");
    
    if test_basic_arithmetic() {
        print("  [PASS] Basic arithmetic\n");
        passed = passed + 1;
    } else {
        print("  [FAIL] Basic arithmetic\n");
        failed = failed + 1;
    }
    
    if test_control_flow() {
        print("  [PASS] Control flow\n");
        passed = passed + 1;
    } else {
        print("  [FAIL] Control flow\n");
        failed = failed + 1;
    }
    
    if test_functions() {
        print("  [PASS] Functions\n");
        passed = passed + 1;
    } else {
        print("  [FAIL] Functions\n");
        failed = failed + 1;
    }
    
    if test_recursion() {
        print("  [PASS] Recursion\n");
        passed = passed + 1;
    } else {
        print("  [FAIL] Recursion\n");
        failed = failed + 1;
    }
    
    if test_structs() {
        print("  [PASS] Structs\n");
        passed = passed + 1;
    } else {
        print("  [FAIL] Structs\n");
        failed = failed + 1;
    }
    
    if test_arrays() {
        print("  [PASS] Arrays\n");
        passed = passed + 1;
    } else {
        print("  [FAIL] Arrays\n");
        failed = failed + 1;
    }
    
    print("\nResults: ");
    print_number(passed);
    print(" passed, ");
    print_number(failed);
    print(" failed\n");
    
    return failed;
}

fn main() -> i32 {
    return run_all_tests();
}
```

## 3. Ejercicios (20%)

### Ejercicio 1: Optimización Cross-Stage
Implementa una optimización que solo esté disponible en stage2, pero que mejore el rendimiento del compilador cuando se auto-compila.

### Ejercicio 2: Detección de Regresiones
Crea un sistema que detecte automáticamente si una nueva versión del compilador produce código diferente (potencialmente incorrecto) al compilar programas de prueba.

### Ejercicio 3: Compilación Incremental
Modifica el compilador para soportar compilación incremental, recompilando solo los archivos que han cambiado.

### Ejercicio 4: Profiling del Compilador
Añade instrumentación al compilador para medir:
- Tiempo en cada fase (lexing, parsing, codegen)
- Memoria utilizada
- Número de nodos AST creados

### Ejercicio 5: Meta-Circular Evaluator
Implementa un intérprete de Chronos escrito en Chronos que pueda ejecutar el compilador. Esto permite debugging y desarrollo sin recompilar.

## Proyecto Integrador: Compilador Production-Ready

Completa el compilador self-hosted con:

1. **Sistema de módulos**:
   - Import/export de símbolos
   - Compilación separada
   - Linking

2. **Optimizador completo**:
   - SSA form
   - Dead code elimination
   - Inlining
   - Loop optimizations

3. **Backend múltiple**:
   - x86-32
   - x86-64
   - ARM
   - WASM

4. **Herramientas de desarrollo**:
   - Debugger integration
   - Profiler
   - Package manager

## Recursos Adicionales

### Lecturas Recomendadas
- "Reflections on Trusting Trust" - Ken Thompson
- "The Art of the Interpreter" - SICP
- "Bootstrapping a Compiler" - Various papers

### Técnicas Avanzadas de Bootstrapping

```tempo
// Técnica: Compiler Versioning
struct CompilerVersion {
    major: i32,
    minor: i32,
    patch: i32,
    features: i32  // Bitmask de características soportadas
}

fn check_compiler_compatibility(required: CompilerVersion) -> bool {
    let current = get_compiler_version();
    
    // Verificar compatibilidad hacia atrás
    if current.major != required.major {
        return false;
    }
    
    if current.minor < required.minor {
        return false;
    }
    
    // Verificar características requeridas
    return (current.features & required.features) == required.features;
}
```

## Conclusión

¡Felicitaciones! Has logrado el Santo Grial del desarrollo de compiladores: un compilador self-hosted. Este logro demuestra:

1. **Completitud**: Chronos es lo suficientemente expresivo para implementar su propio compilador
2. **Corrección**: El compilador genera código correcto consistentemente
3. **Eficiencia**: El compilador puede compilarse a sí mismo en tiempo razonable
4. **Madurez**: El lenguaje está listo para aplicaciones serias

El proceso de bootstrapping no solo es un ejercicio técnico, sino una validación profunda de todo el diseño del lenguaje. Cada mejora futura al compilador beneficiará automáticamente al propio proceso de compilación, creando un ciclo virtuoso de mejora continua.

En la siguiente y última lección del módulo, añadiremos un sistema de tipos robusto a nuestro compilador self-hosted.