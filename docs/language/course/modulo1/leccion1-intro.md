╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 1: Introducción a Compiladores

## 🎯 Objetivos de esta lección

- Entender qué es un compilador y por qué es importante
- Conocer las fases de compilación
- Ver nuestro primer programa en Tempo
- Preparar el ambiente de desarrollo

## 🧠 Teoría: ¿Qué es un compilador?

Un compilador es un programa que traduce código fuente escrito en un lenguaje de alto nivel a código máquina que el procesador puede ejecutar.

### El Pipeline de Compilación

```
Código Fuente (.tempo)
        ↓
    [LEXER]     → Convierte texto en tokens
        ↓
    [PARSER]    → Construye un árbol sintáctico (AST)
        ↓
    [ANALYZER]  → Verifica tipos y semántica
        ↓
    [OPTIMIZER] → Mejora el código
        ↓
    [CODEGEN]   → Genera código máquina
        ↓
Ejecutable (.exe)
```

### ¿Por qué Tempo?

Los lenguajes actuales tienen problemas:
- **C/C++**: Inseguros, undefined behavior
- **Java/C#**: Garbage collector impredecible
- **Python**: Demasiado lento
- **Rust**: Complejo de aprender

Tempo resuelve estos problemas:
- **Determinístico**: Mismo input → mismo output → mismo tiempo
- **Seguro**: Sin null pointers, sin buffer overflows
- **Rápido**: Performance cercana al hardware
- **Simple**: Fácil de aprender y usar

## 💻 Práctica: Nuestro primer programa

### 1. Hello World en diferentes lenguajes

**C:**
```c
#include <stdio.h>
int main() {
    printf("Hello, World!\n");
    return 0;
}
```

**Python:**
```python
print("Hello, World!")
```

**Tempo:**
```tempo
function main() {
    print("Hello, deterministic world!");
}
```

### 2. Anatomía de un programa Tempo

```tempo
// Esto es un comentario

// Función principal - punto de entrada
function main() {
    // Declaración de variable con tipo inferido
    let message = "Hello, Tempo!";
    
    // Llamada a función built-in
    print(message);
    
    // Tempo garantiza que esto siempre toma el mismo tiempo
    let result = fibonacci(10) within 100µs;
    print("Fibonacci(10) = ${result}");
}

// Función con tipo explícito y garantía de tiempo
function fibonacci(n: i32) -> i32 within O(n) {
    if (n <= 1) {
        return n;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}
```

### 3. El proceso de compilación paso a paso

Veamos qué hace el compilador con nuestro Hello World:

**Paso 1 - Lexer (Tokenización):**
```
"function" → KEYWORD
"main"     → IDENTIFIER  
"("        → LPAREN
")"        → RPAREN
"{"        → LBRACE
"print"    → IDENTIFIER
"("        → LPAREN
"Hello!"   → STRING
")"        → RPAREN
";"        → SEMICOLON
"}"        → RBRACE
```

**Paso 2 - Parser (AST):**
```
Program
└── Function("main")
    └── Block
        └── Call("print")
            └── String("Hello, deterministic world!")
```

**Paso 3 - Code Generation:**
```assembly
section .data
    msg db "Hello, deterministic world!", 10
    len equ $ - msg

section .text
global _start

main:
    ; print(msg)
    mov rax, 1      ; sys_write
    mov rdi, 1      ; stdout
    mov rsi, msg    ; string pointer
    mov rdx, len    ; string length
    syscall
    
    ; exit(0)
    mov rax, 60     ; sys_exit
    xor rdi, rdi    ; status = 0
    syscall
```

## 🔧 Preparando el ambiente

### 1. Instalar herramientas necesarias

**Linux/WSL:**
```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade

# Instalar herramientas de desarrollo
sudo apt install build-essential nasm gdb qemu-system-x86

# Verificar instalación
nasm --version
gcc --version
qemu-system-x86_64 --version
```

**macOS:**
```bash
# Instalar Homebrew si no lo tienes
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Instalar herramientas
brew install nasm gdb qemu

# En macOS necesitarás firmar gdb para debugging
```

### 2. Estructura del proyecto

```
tempo-compiler/
├── stage0/          # Bootstrap en assembly
│   ├── bootstrap.s
│   └── Makefile
├── stage1/          # Compilador en Tempo básico
│   └── compiler.tempo
├── stage2/          # Compilador completo
│   ├── lexer.tempo
│   ├── parser.tempo
│   └── codegen.tempo
├── examples/        # Programas de ejemplo
└── tests/          # Tests automáticos
```

### 3. Compilar y ejecutar Hello World

Por ahora usaremos un script que simula Tempo:

```bash
# Crear hello.tempo
cat > hello.tempo << 'EOF'
function main() {
    print("Hello, deterministic world!");
}
EOF

# "Compilar" (por ahora es un script)
./tempo-simulator hello.tempo hello

# Ejecutar
./hello
```

## 🏋️ Ejercicios

### Ejercicio 1: Modificar Hello World
Modifica el programa para que:
1. Imprima tu nombre
2. Imprima la fecha actual
3. Imprima un número aleatorio (¿por qué esto sería problemático en Tempo?)

### Ejercicio 2: Análisis de lenguajes
Compara estos fragmentos y responde:
- ¿Cuál es más seguro?
- ¿Cuál es más rápido?
- ¿Cuál es más predecible?

```c
// C
char buffer[10];
gets(buffer);  // Peligroso!
```

```rust
// Rust
let mut buffer = String::new();
std::io::stdin().read_line(&mut buffer)?;
```

```tempo
// Tempo
let buffer: string<10> = read_line() within 1ms;
// Tamaño fijo, tiempo garantizado
```

### Ejercicio 3: Pensar en determinismo
¿Cuáles de estas operaciones son determinísticas?
1. `2 + 2`
2. `random()`
3. `current_time()`
4. `sort([3, 1, 4, 1, 5])`
5. `hash_map.get("key")`

## 📚 Lecturas recomendadas

1. **"Structure and Interpretation of Computer Programs"** - Capítulo 5
2. **"Engineering a Compiler"** - Capítulos 1-2
3. **Dragon Book** - Introducción

## 🎯 Para la próxima clase

1. Asegúrate de tener el ambiente configurado
2. Lee sobre autómatas finitos y expresiones regulares
3. Piensa: ¿Qué hace que un lenguaje sea "bueno"?

## 💡 Dato curioso

El primer compilador fue escrito por Grace Hopper en 1952. Se llamaba A-0 y traducía código simbólico a código máquina. ¡Antes de eso, todo se programaba en binario!

---

**Resumen**: Un compilador es un traductor. Tempo es un lenguaje diseñado para ser determinístico, seguro y rápido. En las próximas lecciones construiremos nuestro propio compilador desde cero.

[← Índice](../README.md) | [Lección 2: Teoría de Lenguajes →](leccion2-teoria.md)