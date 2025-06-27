╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 6: Construyendo un Tokenizer en Assembly

## 🎯 Objetivos de esta lección

- Implementar un lexer/tokenizer real en assembly x86-64
- Manejar buffers y procesamiento de caracteres eficientemente
- Reconocer tokens: números, identificadores, operadores, palabras clave
- Construir la base del stage0 de nuestro compilador

## 🧠 Teoría: Tokenización Eficiente (20%)

### Arquitectura del Tokenizer

Un tokenizer eficiente necesita:
1. **Buffer de entrada**: Para leer el archivo fuente
2. **Estado actual**: Posición, línea, columna
3. **Tabla de símbolos**: Para palabras clave
4. **Máquina de estados**: Para reconocer tokens

### Tipos de Tokens

```assembly
; Token types (valores en registro)
%define TOK_EOF         0
%define TOK_NUMBER      1
%define TOK_IDENTIFIER  2
%define TOK_STRING      3
%define TOK_PLUS        4
%define TOK_MINUS       5
%define TOK_MULTIPLY    6
%define TOK_DIVIDE      7
%define TOK_LPAREN      8
%define TOK_RPAREN      9
%define TOK_LBRACE      10
%define TOK_RBRACE      11
%define TOK_SEMICOLON   12
%define TOK_EQUALS      13
%define TOK_LET         14
%define TOK_FUNCTION    15
%define TOK_RETURN      16
%define TOK_IF          17
%define TOK_ELSE        18
```

### Estrategia de Implementación

1. **Lectura adelantada**: Siempre tener el siguiente carácter listo
2. **Salto de espacios**: Ignorar whitespace automáticamente
3. **Reconocimiento directo**: Sin expresiones regulares, solo comparaciones
4. **Gestión de errores**: Reportar posición exacta

## 💻 Práctica: Tokenizer Completo (60%)

### 1. Estructura de Datos y Setup

```assembly
; tokenizer.s - Tokenizer para Tempo en assembly
section .data
    ; Tabla de palabras clave
    keywords:
        db "let", 0, TOK_LET, 0
        db "function", 0, TOK_FUNCTION, 0
        db "return", 0, TOK_RETURN, 0
        db "if", 0, TOK_IF, 0
        db "else", 0, TOK_ELSE, 0
        db 0  ; Fin de tabla

    ; Mensajes de error
    error_invalid_char db "Error: Invalid character '", 0
    error_unterminated_string db "Error: Unterminated string", 10, 0
    error_number_too_large db "Error: Number too large", 10, 0

section .bss
    ; Buffer de entrada
    input_buffer resb 65536     ; 64KB buffer
    input_size resq 1           ; Tamaño del archivo
    input_pos resq 1            ; Posición actual
    
    ; Estado del tokenizer
    current_line resq 1         ; Línea actual (1-based)
    current_column resq 1       ; Columna actual (1-based)
    
    ; Token actual
    token_type resb 1           ; Tipo de token
    token_value resb 256        ; Valor del token (string)
    token_length resq 1         ; Longitud del valor
    token_line resq 1           ; Línea donde empieza
    token_column resq 1         ; Columna donde empieza

section .text
    global tokenizer_init
    global next_token
    global peek_char
    global advance_char

; tokenizer_init(char *filename) -> bool success
tokenizer_init:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    ; Abrir archivo
    mov rax, 2              ; sys_open
    ; rdi ya tiene filename
    xor rsi, rsi            ; O_RDONLY
    xor rdx, rdx
    syscall
    
    test rax, rax
    js .error               ; Error si negativo
    
    mov rbx, rax            ; Guardar file descriptor
    
    ; Leer archivo completo
    mov rax, 0              ; sys_read
    mov rdi, rbx            ; fd
    mov rsi, input_buffer   ; buffer
    mov rdx, 65536          ; max size
    syscall
    
    mov [input_size], rax   ; Guardar tamaño
    
    ; Cerrar archivo
    mov rax, 3              ; sys_close
    mov rdi, rbx
    syscall
    
    ; Inicializar estado
    mov qword [input_pos], 0
    mov qword [current_line], 1
    mov qword [current_column], 1
    
    mov rax, 1              ; Success
    jmp .done
    
.error:
    xor rax, rax            ; Failure
    
.done:
    pop r12
    pop rbx
    pop rbp
    ret

; peek_char() -> char en AL, 0 si EOF
peek_char:
    mov rax, [input_pos]
    cmp rax, [input_size]
    jae .eof
    
    mov al, [input_buffer + rax]
    ret
    
.eof:
    xor al, al
    ret

; advance_char()
advance_char:
    mov rax, [input_pos]
    cmp rax, [input_size]
    jae .done
    
    ; Obtener carácter actual
    mov al, [input_buffer + rax]
    
    ; Incrementar posición
    inc qword [input_pos]
    
    ; Actualizar línea/columna
    cmp al, 10              ; ¿newline?
    je .newline
    
    inc qword [current_column]
    jmp .done
    
.newline:
    inc qword [current_line]
    mov qword [current_column], 1
    
.done:
    ret
```

### 2. Reconocimiento de Tokens

```assembly
; next_token() -> tipo en AL
next_token:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    ; Guardar posición inicial del token
    mov rax, [current_line]
    mov [token_line], rax
    mov rax, [current_column]
    mov [token_column], rax
    
    ; Saltar whitespace
    call skip_whitespace
    
    ; Obtener primer carácter
    call peek_char
    test al, al
    jz .eof
    
    ; Decidir qué tipo de token es
    cmp al, '0'
    jb .check_operators
    cmp al, '9'
    jbe .number
    
    cmp al, 'A'
    jb .check_operators
    cmp al, 'Z'
    jbe .identifier
    
    cmp al, 'a'
    jb .check_operators
    cmp al, 'z'
    jbe .identifier
    
    cmp al, '_'
    je .identifier
    
    cmp al, '"'
    je .string
    
.check_operators:
    ; Operadores de un carácter
    cmp al, '+'
    je .plus
    cmp al, '-'
    je .minus
    cmp al, '*'
    je .multiply
    cmp al, '/'
    je .divide
    cmp al, '('
    je .lparen
    cmp al, ')'
    je .rparen
    cmp al, '{'
    je .lbrace
    cmp al, '}'
    je .rbrace
    cmp al, ';'
    je .semicolon
    cmp al, '='
    je .equals
    
    ; Carácter inválido
    jmp .invalid_char

.eof:
    mov byte [token_type], TOK_EOF
    jmp .done

.plus:
    call advance_char
    mov byte [token_type], TOK_PLUS
    jmp .done

.minus:
    call advance_char
    mov byte [token_type], TOK_MINUS
    jmp .done

.multiply:
    call advance_char
    mov byte [token_type], TOK_MULTIPLY
    jmp .done

.divide:
    call advance_char
    ; Verificar si es comentario
    call peek_char
    cmp al, '/'
    je .line_comment
    
    mov byte [token_type], TOK_DIVIDE
    jmp .done

.line_comment:
    ; Saltar hasta el final de línea
    call advance_char      ; Saltar segundo '/'
.comment_loop:
    call peek_char
    test al, al
    jz .done
    cmp al, 10             ; newline
    je .comment_end
    call advance_char
    jmp .comment_loop
.comment_end:
    call advance_char      ; Saltar newline
    jmp next_token         ; Recursión tail para siguiente token

.lparen:
    call advance_char
    mov byte [token_type], TOK_LPAREN
    jmp .done

.rparen:
    call advance_char
    mov byte [token_type], TOK_RPAREN
    jmp .done

.lbrace:
    call advance_char
    mov byte [token_type], TOK_LBRACE
    jmp .done

.rbrace:
    call advance_char
    mov byte [token_type], TOK_RBRACE
    jmp .done

.semicolon:
    call advance_char
    mov byte [token_type], TOK_SEMICOLON
    jmp .done

.equals:
    call advance_char
    mov byte [token_type], TOK_EQUALS
    jmp .done

.number:
    call scan_number
    jmp .done

.identifier:
    call scan_identifier
    jmp .done

.string:
    call scan_string
    jmp .done

.invalid_char:
    ; Reportar error
    mov rdi, error_invalid_char
    call print_string
    
    mov dil, al
    call print_char
    
    mov dil, "'"
    call print_char
    
    mov dil, 10
    call print_char
    
    ; Token de error
    mov byte [token_type], TOK_EOF
    
.done:
    movzx rax, byte [token_type]
    
    pop r12
    pop rbx
    pop rbp
    ret
```

### 3. Escaneo de Números

```assembly
; scan_number() - Escanea un número decimal
scan_number:
    push rbp
    mov rbp, rsp
    push rbx
    
    xor rbx, rbx            ; Índice en token_value
    
.loop:
    call peek_char
    
    ; ¿Es dígito?
    cmp al, '0'
    jb .done
    cmp al, '9'
    ja .done
    
    ; Agregar a token_value
    mov [token_value + rbx], al
    inc rbx
    
    ; Verificar overflow
    cmp rbx, 255
    jae .too_large
    
    call advance_char
    jmp .loop
    
.done:
    ; Null terminator
    mov byte [token_value + rbx], 0
    mov [token_length], rbx
    mov byte [token_type], TOK_NUMBER
    
    pop rbx
    pop rbp
    ret
    
.too_large:
    mov rdi, error_number_too_large
    call print_string
    mov byte [token_type], TOK_EOF
    
    pop rbx
    pop rbp
    ret
```

### 4. Escaneo de Identificadores y Palabras Clave

```assembly
; scan_identifier() - Escanea identificador o palabra clave
scan_identifier:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    
    xor rbx, rbx            ; Índice
    
.loop:
    call peek_char
    
    ; ¿Es letra?
    cmp al, 'A'
    jb .check_lower
    cmp al, 'Z'
    jbe .valid
    
.check_lower:
    cmp al, 'a'
    jb .check_underscore
    cmp al, 'z'
    jbe .valid
    
.check_underscore:
    cmp al, '_'
    je .valid
    
    ; ¿Es dígito? (válido después del primer carácter)
    test rbx, rbx           ; ¿No es primer carácter?
    jz .done
    cmp al, '0'
    jb .done
    cmp al, '9'
    ja .done
    
.valid:
    ; Agregar carácter
    mov [token_value + rbx], al
    inc rbx
    
    cmp rbx, 255
    jae .done
    
    call advance_char
    jmp .loop
    
.done:
    ; Null terminator
    mov byte [token_value + rbx], 0
    mov [token_length], rbx
    
    ; Verificar si es palabra clave
    call check_keyword
    test al, al
    jz .not_keyword
    
    mov [token_type], al    ; Tipo de palabra clave
    jmp .exit
    
.not_keyword:
    mov byte [token_type], TOK_IDENTIFIER
    
.exit:
    pop r12
    pop rbx
    pop rbp
    ret

; check_keyword() -> tipo de keyword en AL, 0 si no es keyword
check_keyword:
    push rbp
    mov rbp, rsp
    push rbx
    push rsi
    push rdi
    
    lea rbx, [keywords]     ; Puntero a tabla
    
.loop:
    mov al, [rbx]          ; Primer carácter
    test al, al
    jz .not_found          ; Fin de tabla
    
    ; Comparar strings
    mov rsi, rbx           ; Keyword actual
    lea rdi, [token_value] ; Token escaneado
    call strcmp
    test al, al
    jz .found
    
    ; Avanzar a siguiente keyword
.skip:
    inc rbx
    mov al, [rbx - 1]
    test al, al
    jnz .skip
    
    add rbx, 2             ; Saltar tipo y padding
    jmp .loop
    
.found:
    ; Obtener tipo de token
    mov rsi, rbx
.find_type:
    lodsb
    test al, al
    jnz .find_type
    
    mov al, [rsi]          ; Tipo de token
    jmp .done
    
.not_found:
    xor al, al
    
.done:
    pop rdi
    pop rsi
    pop rbx
    pop rbp
    ret

; strcmp() - Compara RSI con RDI, retorna 0 en AL si iguales
strcmp:
    push rsi
    push rdi
    
.loop:
    mov al, [rsi]
    mov ah, [rdi]
    
    cmp al, ah
    jne .not_equal
    
    test al, al
    jz .equal
    
    inc rsi
    inc rdi
    jmp .loop
    
.equal:
    xor al, al
    jmp .done
    
.not_equal:
    mov al, 1
    
.done:
    pop rdi
    pop rsi
    ret
```

### 5. Escaneo de Strings y Manejo de Escapes

```assembly
; scan_string() - Escanea string literal
scan_string:
    push rbp
    mov rbp, rsp
    push rbx
    
    call advance_char       ; Saltar comilla inicial
    xor rbx, rbx           ; Índice
    
.loop:
    call peek_char
    
    test al, al            ; ¿EOF?
    jz .unterminated
    
    cmp al, '"'            ; ¿Comilla final?
    je .done
    
    cmp al, '\'            ; ¿Escape?
    je .escape
    
    ; Carácter normal
    mov [token_value + rbx], al
    inc rbx
    
    cmp rbx, 255
    jae .too_long
    
    call advance_char
    jmp .loop
    
.escape:
    call advance_char      ; Saltar '\'
    call peek_char
    
    ; Procesar escape
    cmp al, 'n'
    je .newline_escape
    cmp al, 't'
    je .tab_escape
    cmp al, 'r'
    je .return_escape
    cmp al, '"'
    je .quote_escape
    cmp al, '\'
    je .backslash_escape
    
    ; Escape inválido, usar literal
    mov byte [token_value + rbx], '\'
    inc rbx
    jmp .loop
    
.newline_escape:
    mov byte [token_value + rbx], 10
    jmp .escape_done
    
.tab_escape:
    mov byte [token_value + rbx], 9
    jmp .escape_done
    
.return_escape:
    mov byte [token_value + rbx], 13
    jmp .escape_done
    
.quote_escape:
    mov byte [token_value + rbx], '"'
    jmp .escape_done
    
.backslash_escape:
    mov byte [token_value + rbx], '\'
    
.escape_done:
    inc rbx
    call advance_char
    jmp .loop
    
.done:
    call advance_char      ; Saltar comilla final
    mov byte [token_value + rbx], 0
    mov [token_length], rbx
    mov byte [token_type], TOK_STRING
    
    pop rbx
    pop rbp
    ret
    
.unterminated:
    mov rdi, error_unterminated_string
    call print_string
    mov byte [token_type], TOK_EOF
    pop rbx
    pop rbp
    ret
    
.too_long:
    ; String demasiado largo
    mov byte [token_type], TOK_EOF
    pop rbx
    pop rbp
    ret

; skip_whitespace() - Salta espacios, tabs y newlines
skip_whitespace:
.loop:
    call peek_char
    
    cmp al, ' '
    je .skip
    cmp al, 9              ; tab
    je .skip
    cmp al, 10             ; newline
    je .skip
    cmp al, 13             ; carriage return
    je .skip
    
    ret
    
.skip:
    call advance_char
    jmp .loop
```

### 6. Programa de Prueba

```assembly
; test_tokenizer.s - Programa para probar el tokenizer
section .data
    test_file db "test.tempo", 0
    
    token_names:
        db "EOF", 0
        db "NUMBER", 0
        db "IDENTIFIER", 0
        db "STRING", 0
        db "PLUS", 0
        db "MINUS", 0
        db "MULTIPLY", 0
        db "DIVIDE", 0
        db "LPAREN", 0
        db "RPAREN", 0
        db "LBRACE", 0
        db "RBRACE", 0
        db "SEMICOLON", 0
        db "EQUALS", 0
        db "LET", 0
        db "FUNCTION", 0
        db "RETURN", 0
        db "IF", 0
        db "ELSE", 0

section .text
    global _start
    extern tokenizer_init
    extern next_token
    extern print_string
    extern print_number

_start:
    ; Inicializar tokenizer
    mov rdi, test_file
    call tokenizer_init
    test rax, rax
    jz .error
    
.token_loop:
    ; Obtener siguiente token
    call next_token
    
    ; Imprimir información del token
    push rax               ; Guardar tipo
    
    ; Línea:Columna
    mov rdi, [token_line]
    call print_number
    mov dil, ':'
    call print_char
    mov rdi, [token_column]
    call print_number
    mov dil, ' '
    call print_char
    
    ; Tipo de token
    pop rax
    call print_token_name
    
    ; Valor si aplica
    cmp al, TOK_NUMBER
    je .print_value
    cmp al, TOK_IDENTIFIER
    je .print_value
    cmp al, TOK_STRING
    je .print_value
    jmp .next
    
.print_value:
    mov dil, ' '
    call print_char
    mov dil, '='
    call print_char
    mov dil, ' '
    call print_char
    
    lea rdi, [token_value]
    call print_string
    
.next:
    mov dil, 10            ; newline
    call print_char
    
    ; ¿EOF?
    cmp al, TOK_EOF
    jne .token_loop
    
    ; Exit success
    mov rax, 60
    xor rdi, rdi
    syscall
    
.error:
    ; Exit con error
    mov rax, 60
    mov rdi, 1
    syscall

print_token_name:
    ; Calcular offset en tabla
    movzx rax, al
    imul rax, 16           ; Asumiendo nombres de 16 bytes max
    lea rdi, [token_names + rax]
    call print_string
    ret
```

## 🏋️ Ejercicios (20%)

### Ejercicio 1: Operadores Multicarácter
Extiende el tokenizer para reconocer:
- `==` (igual igual)
- `!=` (no igual)
- `<=` y `>=`
- `&&` y `||`

### Ejercicio 2: Números Hexadecimales
Agrega soporte para números hexadecimales:
- `0x1234`
- `0xFF`
- `0xDEADBEEF`

### Ejercicio 3: Comentarios Multilinea
Implementa comentarios estilo C:
```
/* Este es un
   comentario
   multilinea */
```

### Ejercicio 4: Ubicación Precisa
Modifica el tokenizer para guardar:
- Posición de inicio y fin de cada token
- Útil para mensajes de error precisos

### Ejercicio 5: Optimización
Optimiza el tokenizer:
1. Usa una tabla de saltos para operadores
2. Implementa peek de múltiples caracteres
3. Mide la mejora en performance

## 📚 Lecturas recomendadas

1. **"Writing a Simple Operating System from Scratch"** - Lexical analysis
2. **"Crafting Interpreters"** - Scanning chapter
3. **Assembly optimization guides** - Intel/AMD manuals

## 🎯 Para la próxima clase

1. Implementa el tokenizer completo
2. Pruébalo con varios archivos Tempo
3. Piensa: ¿Cómo construirías el parser encima?

## 💡 Dato curioso

El primer tokenizer fue parte del compilador FORTRAN I (1957). Usaba una técnica llamada "operator precedence parsing" que combinaba tokenización y parsing. Los compiladores modernos separan estas fases para mayor modularidad, pero algunos lenguajes como Go vuelven a combinarlas para mejorar performance.

---

**Resumen**: Hemos construido un tokenizer completo en assembly x86-64. Este tokenizer es la base de nuestro compilador bootstrap, capaz de reconocer todos los tokens básicos de Tempo con manejo de errores y ubicación precisa.

[← Lección 5: Assembly x86-64](leccion5-assembly.md) | [Módulo 2 →](../modulo2/README.md)