╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 5: Assembly x86-64 Esencial

## 🎯 Objetivos de esta lección

- Comprender la arquitectura x86-64 y sus registros
- Dominar las instrucciones básicas de ensamblador
- Entender las convenciones de llamada (calling conventions)
- Escribir programas básicos en assembly para el bootstrap

## 🧠 Teoría: Arquitectura x86-64 (20%)

### Registros de Propósito General

x86-64 tiene 16 registros de 64 bits:

```
64-bit  32-bit  16-bit  8-bit   Uso típico
------  ------  ------  -----   -----------
RAX     EAX     AX      AL      Acumulador, valor de retorno
RBX     EBX     BX      BL      Base, preservado
RCX     ECX     CX      CL      Contador
RDX     EDX     DX      DL      Datos, 2° valor retorno
RSI     ESI     SI      SIL     Source index
RDI     EDI     DI      DIL     Destination index
RBP     EBP     BP      BPL     Base pointer (frame)
RSP     ESP     SP      SPL     Stack pointer
R8-R15  R8D-R15D R8W-R15W R8B-R15B  Registros adicionales
```

### Instrucciones Básicas

**Movimiento de datos:**
```assembly
mov  dest, src    ; dest = src
lea  dest, [addr] ; dest = address
push src          ; Poner en pila
pop  dest         ; Sacar de pila
```

**Aritmética:**
```assembly
add  dest, src    ; dest += src
sub  dest, src    ; dest -= src
imul dest, src    ; dest *= src (signed)
inc  dest         ; dest++
dec  dest         ; dest--
```

**Control de flujo:**
```assembly
cmp  a, b         ; Compara a con b
jmp  label        ; Salto incondicional
je   label        ; Salta si igual
jne  label        ; Salta si no igual
jg   label        ; Salta si mayor
call function     ; Llamar función
ret               ; Retornar
```

### System V AMD64 ABI (Linux/macOS)

**Parámetros en registros:**
1. RDI - 1er parámetro
2. RSI - 2° parámetro
3. RDX - 3er parámetro
4. RCX - 4° parámetro
5. R8  - 5° parámetro
6. R9  - 6° parámetro
7. Pila - resto de parámetros

**Preservación de registros:**
- **Caller-saved**: RAX, RCX, RDX, RSI, RDI, R8-R11
- **Callee-saved**: RBX, RBP, R12-R15

## 💻 Práctica: Programando en Assembly (60%)

### 1. Hello World en Assembly Puro

```assembly
; hello.s - Hello World en x86-64 Linux
section .data
    msg db "Hello, Assembly!", 10  ; 10 = newline
    len equ $ - msg                ; Calcular longitud

section .text
    global _start

_start:
    ; write(1, msg, len)
    mov rax, 1      ; syscall número (sys_write)
    mov rdi, 1      ; file descriptor (stdout)
    mov rsi, msg    ; puntero al mensaje
    mov rdx, len    ; longitud del mensaje
    syscall         ; llamar al kernel
    
    ; exit(0)
    mov rax, 60     ; syscall número (sys_exit)
    xor rdi, rdi    ; status = 0
    syscall         ; llamar al kernel
```

**Compilar y ejecutar:**
```bash
nasm -f elf64 hello.s -o hello.o
ld hello.o -o hello
./hello
```

### 2. Funciones y Stack Frames

```assembly
; functions.s - Manejo de funciones
section .text
    global main

; Función: int add(int a, int b)
; Parámetros: a en EDI, b en ESI
; Retorna: a + b en EAX
add:
    ; Prólogo (no necesario para función simple)
    mov eax, edi    ; eax = a
    add eax, esi    ; eax += b
    ret             ; retornar

; Función: int factorial(int n)
; Implementación recursiva
factorial:
    ; Prólogo
    push rbp        ; Guardar base pointer anterior
    mov rbp, rsp    ; Establecer nuevo frame
    
    ; Caso base: if (n <= 1) return 1
    cmp edi, 1
    jg .recursive
    mov eax, 1
    jmp .done
    
.recursive:
    ; Guardar n en stack
    push rdi
    
    ; factorial(n - 1)
    dec edi
    call factorial
    
    ; Recuperar n
    pop rdi
    
    ; return n * factorial(n - 1)
    imul eax, edi
    
.done:
    ; Epílogo
    mov rsp, rbp    ; Restaurar stack
    pop rbp         ; Restaurar base pointer
    ret

main:
    ; Probar add(5, 3)
    mov edi, 5
    mov esi, 3
    call add
    ; Resultado en EAX = 8
    
    ; Probar factorial(5)
    mov edi, 5
    call factorial
    ; Resultado en EAX = 120
    
    ; exit(0)
    mov eax, 60
    xor edi, edi
    syscall
```

### 3. Manejo de Strings y Arrays

```assembly
; strings.s - Operaciones con strings
section .data
    string1 db "Hello", 0
    string2 db "World", 0
    buffer times 256 db 0  ; Buffer de 256 bytes

section .text
    global main

; strlen(char *str) -> longitud en RAX
strlen:
    xor rax, rax        ; contador = 0
    
.loop:
    cmp byte [rdi + rax], 0  ; ¿es null terminator?
    je .done
    inc rax             ; contador++
    jmp .loop
    
.done:
    ret

; strcpy(char *dest, char *src)
strcpy:
    push rdi            ; Guardar destino original
    
.loop:
    mov al, [rsi]       ; AL = *src
    mov [rdi], al       ; *dest = AL
    
    test al, al         ; ¿es 0?
    jz .done
    
    inc rsi             ; src++
    inc rdi             ; dest++
    jmp .loop
    
.done:
    pop rax             ; Retornar destino original
    ret

; strcat(char *dest, char *src)
strcat:
    push rdi            ; Guardar destino
    
    ; Encontrar final de dest
    call strlen         ; RAX = strlen(dest)
    add rdi, rax        ; dest += strlen(dest)
    
    ; Copiar src al final
    call strcpy
    
    pop rax             ; Retornar destino original
    ret

main:
    ; strlen("Hello")
    mov rdi, string1
    call strlen
    ; RAX = 5
    
    ; strcpy(buffer, "Hello")
    mov rdi, buffer
    mov rsi, string1
    call strcpy
    
    ; strcat(buffer, " ")
    mov rdi, buffer
    mov rsi, space
    call strcat
    
    ; strcat(buffer, "World")
    mov rdi, buffer
    mov rsi, string2
    call strcat
    
    ; buffer ahora contiene "Hello World"
    
    ret

section .data
    space db " ", 0
```

### 4. Input/Output Básico

```assembly
; io.s - Entrada/Salida básica
section .bss
    input_buffer resb 256   ; Reserve 256 bytes

section .text
    global main

; print_string(char *str)
print_string:
    ; Primero calcular longitud
    push rdi
    call strlen
    mov rdx, rax        ; rdx = longitud
    pop rsi             ; rsi = string
    
    ; write(1, str, len)
    mov rax, 1          ; sys_write
    mov rdi, 1          ; stdout
    syscall
    ret

; read_line(char *buffer, int max_len) -> bytes leídos
read_line:
    ; read(0, buffer, max_len)
    mov rax, 0          ; sys_read
    push rdi            ; Guardar buffer
    mov rdi, 0          ; stdin
    pop rsi             ; rsi = buffer
    ; rdx ya tiene max_len
    syscall
    
    ; Quitar newline si existe
    test rax, rax
    jz .done
    
    dec rax
    cmp byte [rsi + rax], 10  ; ¿es newline?
    jne .no_newline
    mov byte [rsi + rax], 0   ; Reemplazar con null
    
.no_newline:
.done:
    ret

; print_number(int n)
print_number:
    ; Convertir número a string
    push rbp
    mov rbp, rsp
    sub rsp, 32         ; Buffer local
    
    mov rax, rdi        ; número a convertir
    lea rdi, [rbp - 1]  ; final del buffer
    mov byte [rdi], 0   ; null terminator
    
    mov rcx, 10         ; divisor
    
.convert_loop:
    xor rdx, rdx        ; limpiar para división
    div rcx             ; rax/10, resto en rdx
    
    add dl, '0'         ; convertir a ASCII
    dec rdi
    mov [rdi], dl       ; guardar dígito
    
    test rax, rax       ; ¿quedan dígitos?
    jnz .convert_loop
    
    ; Imprimir string resultante
    call print_string
    
    mov rsp, rbp
    pop rbp
    ret

main:
    ; Pedir nombre
    mov rdi, prompt
    call print_string
    
    ; Leer entrada
    mov rdi, input_buffer
    mov rsi, 255
    call read_line
    
    ; Saludar
    mov rdi, greeting
    call print_string
    
    mov rdi, input_buffer
    call print_string
    
    mov rdi, newline
    call print_string
    
    ; Imprimir un número
    mov rdi, 12345
    call print_number
    
    ret

section .data
    prompt db "Enter your name: ", 0
    greeting db "Hello, ", 0
    newline db 10, 0
```

### 5. Convenciones de Llamada y ABI

```assembly
; calling_convention.s - Demostración del ABI
section .text
    global main

; Función con muchos parámetros
; int complex_function(int a, int b, int c, int d, int e, int f, int g, int h)
; Parámetros 1-6 en registros, 7-8 en stack
complex_function:
    ; Prólogo completo
    push rbp
    mov rbp, rsp
    
    ; Los primeros 6 parámetros están en:
    ; a = EDI, b = ESI, c = EDX, d = ECX, e = R8D, f = R9D
    
    ; Los parámetros 7 y 8 están en el stack:
    ; g = [rbp + 16]
    ; h = [rbp + 24]
    
    ; Sumar todos los parámetros
    mov eax, edi        ; a
    add eax, esi        ; + b
    add eax, edx        ; + c
    add eax, ecx        ; + d
    add eax, r8d        ; + e
    add eax, r9d        ; + f
    add eax, [rbp + 16] ; + g
    add eax, [rbp + 24] ; + h
    
    ; Epílogo
    mov rsp, rbp
    pop rbp
    ret

; Función que preserva registros callee-saved
preserve_registers:
    ; Guardar registros que vamos a usar
    push rbx
    push r12
    push r13
    
    ; Usar los registros
    mov rbx, rdi        ; Primer parámetro
    mov r12, rsi        ; Segundo parámetro
    mov r13, rdx        ; Tercer parámetro
    
    ; Hacer algo con ellos...
    add rbx, r12
    add rbx, r13
    mov rax, rbx        ; Resultado
    
    ; Restaurar registros
    pop r13
    pop r12
    pop rbx
    ret

; Alineación del stack
stack_alignment_demo:
    ; El stack debe estar alineado a 16 bytes antes de CALL
    push rbp
    mov rbp, rsp
    
    ; Asegurar alineación
    and rsp, -16        ; Alinear a 16 bytes
    
    ; Ahora podemos llamar funciones
    call some_function
    
    mov rsp, rbp
    pop rbp
    ret

main:
    ; Llamar complex_function(1,2,3,4,5,6,7,8)
    ; Primeros 6 en registros
    mov edi, 1
    mov esi, 2
    mov edx, 3
    mov ecx, 4
    mov r8d, 5
    mov r9d, 6
    
    ; Últimos 2 en stack (orden inverso)
    push 8              ; h
    push 7              ; g
    
    call complex_function
    
    ; Limpiar stack
    add rsp, 16
    
    ; EAX = 36 (suma de 1+2+3+4+5+6+7+8)
    
    ret

some_function:
    ret
```

## 🏋️ Ejercicios (20%)

### Ejercicio 1: Función Power
Implementa una función `power(base, exponent)` que calcule base^exponent:
```assembly
; int power(int base, int exponent)
; Ejemplo: power(2, 10) = 1024
```

### Ejercicio 2: Búsqueda en Array
Implementa una función que busque un valor en un array:
```assembly
; int find_in_array(int *array, int length, int value)
; Retorna: índice si encuentra, -1 si no
```

### Ejercicio 3: Conversión Hexadecimal
Escribe una función que convierta un número a string hexadecimal:
```assembly
; void to_hex(int number, char *buffer)
; Ejemplo: to_hex(255, buffer) → buffer = "0xFF"
```

### Ejercicio 4: Stack Debugging
Este código tiene un bug. Encuéntralo y arréglalo:
```assembly
buggy_function:
    push rbx
    push rcx
    mov rbx, rdi
    mov rcx, rsi
    ; ... hacer algo ...
    pop rbx    ; ¡Bug aquí!
    pop rcx
    ret
```

### Ejercicio 5: Mini Printf
Implementa una versión simple de printf que soporte:
- %s para strings
- %d para enteros
- %c para caracteres

## 📚 Lecturas recomendadas

1. **"Intel® 64 and IA-32 Architectures Software Developer's Manual"**
2. **"x86-64 Assembly Language Programming with Ubuntu"** - Ed Jorgensen
3. **"System V ABI"** - Documentación oficial

## 🎯 Para la próxima clase

1. Practica escribiendo programas simples en assembly
2. Familiarízate con el debugger (gdb)
3. Piensa: ¿Cómo implementarías un lexer en assembly?

## 💡 Dato curioso

x86 comenzó como una arquitectura de 16 bits en 1978 (Intel 8086). Se extendió a 32 bits en 1985 (80386) y finalmente a 64 bits en 2003 (AMD Opteron). ¡La compatibilidad hacia atrás significa que tu CPU moderna aún puede ejecutar código del 8086!

---

**Resumen**: x86-64 proporciona 16 registros de propósito general y un conjunto rico de instrucciones. Las convenciones de llamada definen cómo pasar parámetros y preservar registros. Este conocimiento es esencial para nuestro compilador bootstrap.

[← Lección 4: Gramáticas](leccion4-gramaticas.md) | [Lección 6: Tokenizer en Assembly →](leccion6-tokenizer.md)