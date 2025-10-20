╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 7: Parser Recursivo en Assembly - Building the stage0 parser

## Objetivos de la Lección
- Entender los principios del parsing recursivo descendente
- Implementar un parser minimalista en assembly x86
- Construir un Abstract Syntax Tree (AST) básico
- Preparar las bases para el self-hosting del compilador

## 1. Teoría (20%)

### ¿Qué es un Parser Recursivo Descendente?

Un parser recursivo descendente es un tipo de analizador sintáctico que construye el árbol de análisis desde la raíz hacia las hojas, intentando hacer coincidir la entrada con las producciones de la gramática.

### Ventajas para un Compilador Minimalista
1. **Simplicidad**: Fácil de implementar manualmente
2. **Control total**: Podemos optimizar cada producción
3. **Eficiencia**: Sin overhead de tablas de parsing
4. **Predictibilidad**: Ideal para sistemas de tiempo real

### Gramática Simplificada de Chronos

```
programa     ::= declaracion*
declaracion  ::= funcion | estructura
funcion      ::= 'fn' IDENT '(' parametros? ')' tipo? bloque
parametros   ::= parametro (',' parametro)*
parametro    ::= IDENT ':' tipo
tipo         ::= 'i32' | 'i64' | 'bool' | IDENT
bloque       ::= '{' sentencia* '}'
sentencia    ::= asignacion | retorno | if | while | expresion ';'
expresion    ::= termino (('+' | '-') termino)*
termino      ::= factor (('*' | '/') factor)*
factor       ::= NUMERO | IDENT | '(' expresion ')'
```

### Estructura del AST en Memoria

```
AST Node (16 bytes):
+0:  tipo_nodo (4 bytes)
+4:  valor/puntero_dato (4 bytes)
+8:  hijo_izquierdo (4 bytes)
+12: hijo_derecho (4 bytes)
```

## 2. Práctica (60%)

### Implementación del Parser en Assembly

```asm
section .data
    ; Tipos de nodos AST
    NODE_PROGRAM    equ 0
    NODE_FUNCTION   equ 1
    NODE_BLOCK      equ 2
    NODE_RETURN     equ 3
    NODE_BINARY_OP  equ 4
    NODE_NUMBER     equ 5
    NODE_IDENT      equ 6
    
    ; Tokens actuales
    current_token   dd 0
    token_value     dd 0
    
    ; Memoria para AST
    ast_memory      times 65536 db 0
    ast_ptr         dd ast_memory

section .text

; parse_program: Punto de entrada del parser
; Entrada: ESI = puntero a tokens
; Salida: EAX = puntero al AST
parse_program:
    push ebp
    mov ebp, esp
    push ebx
    push edi
    
    ; Crear nodo programa
    call alloc_node
    mov dword [eax], NODE_PROGRAM
    push eax                    ; Guardar nodo raíz
    
.parse_declarations:
    ; Obtener siguiente token
    call get_token
    cmp eax, TOKEN_EOF
    je .done
    
    ; Verificar si es función
    cmp eax, TOKEN_FN
    jne .error
    
    ; Parsear función
    call parse_function
    
    ; Agregar función al programa
    pop ebx                     ; Recuperar nodo programa
    push ebx
    call add_child
    
    jmp .parse_declarations
    
.done:
    pop eax                     ; Retornar nodo programa
    pop edi
    pop ebx
    mov esp, ebp
    pop ebp
    ret
    
.error:
    mov eax, -1
    jmp .done

; parse_function: Parsea una declaración de función
; Salida: EAX = puntero al nodo función
parse_function:
    push ebp
    mov ebp, esp
    push ebx
    push edi
    
    ; Crear nodo función
    call alloc_node
    mov dword [eax], NODE_FUNCTION
    push eax                    ; Guardar nodo función
    
    ; Consumir 'fn'
    call consume_token
    
    ; Parsear nombre de función
    call get_token
    cmp eax, TOKEN_IDENT
    jne .error
    
    mov ebx, [token_value]      ; Guardar nombre
    pop eax                     ; Recuperar nodo función
    push eax
    mov [eax + 4], ebx          ; Guardar nombre en nodo
    
    ; Consumir identificador
    call consume_token
    
    ; Parsear paréntesis y parámetros
    call expect_token
    dd TOKEN_LPAREN
    
    ; TODO: Parsear parámetros
    
    call expect_token
    dd TOKEN_RPAREN
    
    ; Parsear tipo de retorno opcional
    call peek_token
    cmp eax, TOKEN_COLON
    jne .parse_body
    
    call consume_token          ; Consumir ':'
    call parse_type
    
.parse_body:
    ; Parsear bloque de función
    call parse_block
    
    ; Agregar bloque como hijo de función
    pop ebx                     ; Recuperar nodo función
    push ebx
    mov [ebx + 8], eax          ; hijo_izquierdo = bloque
    
.done:
    pop eax                     ; Retornar nodo función
    pop edi
    pop ebx
    mov esp, ebp
    pop ebp
    ret
    
.error:
    mov eax, -1
    jmp .done

; parse_block: Parsea un bloque de código
; Salida: EAX = puntero al nodo bloque
parse_block:
    push ebp
    mov ebp, esp
    push ebx
    push edi
    
    ; Crear nodo bloque
    call alloc_node
    mov dword [eax], NODE_BLOCK
    push eax                    ; Guardar nodo bloque
    
    ; Consumir '{'
    call expect_token
    dd TOKEN_LBRACE
    
.parse_statements:
    ; Verificar fin de bloque
    call peek_token
    cmp eax, TOKEN_RBRACE
    je .end_block
    
    ; Parsear sentencia
    call parse_statement
    
    ; Agregar sentencia al bloque
    pop ebx                     ; Recuperar nodo bloque
    push ebx
    call add_statement
    
    jmp .parse_statements
    
.end_block:
    ; Consumir '}'
    call consume_token
    
    pop eax                     ; Retornar nodo bloque
    pop edi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; parse_statement: Parsea una sentencia
; Salida: EAX = puntero al nodo sentencia
parse_statement:
    push ebp
    mov ebp, esp
    
    ; Verificar tipo de sentencia
    call peek_token
    
    cmp eax, TOKEN_RETURN
    je .parse_return
    
    cmp eax, TOKEN_IF
    je .parse_if
    
    cmp eax, TOKEN_WHILE
    je .parse_while
    
    ; Por defecto, parsear expresión
    call parse_expression
    
    ; Consumir ';'
    push eax
    call expect_token
    dd TOKEN_SEMICOLON
    pop eax
    
.done:
    mov esp, ebp
    pop ebp
    ret
    
.parse_return:
    call consume_token          ; Consumir 'return'
    
    ; Crear nodo return
    call alloc_node
    mov dword [eax], NODE_RETURN
    push eax
    
    ; Parsear expresión de retorno
    call parse_expression
    
    pop ebx                     ; Recuperar nodo return
    mov [ebx + 8], eax          ; hijo_izquierdo = expresión
    mov eax, ebx
    
    ; Consumir ';'
    push eax
    call expect_token
    dd TOKEN_SEMICOLON
    pop eax
    
    jmp .done
    
.parse_if:
    ; TODO: Implementar parsing de if
    jmp .done
    
.parse_while:
    ; TODO: Implementar parsing de while
    jmp .done

; parse_expression: Parsea una expresión (suma/resta)
; Salida: EAX = puntero al nodo expresión
parse_expression:
    push ebp
    mov ebp, esp
    push ebx
    push edi
    
    ; Parsear primer término
    call parse_term
    push eax                    ; Guardar término izquierdo
    
.check_operator:
    ; Verificar si hay operador + o -
    call peek_token
    cmp eax, TOKEN_PLUS
    je .parse_addition
    cmp eax, TOKEN_MINUS
    je .parse_subtraction
    
    ; No hay más operadores
    pop eax                     ; Retornar término
    jmp .done
    
.parse_addition:
    call consume_token          ; Consumir '+'
    
    ; Crear nodo operación binaria
    call alloc_node
    mov dword [eax], NODE_BINARY_OP
    mov dword [eax + 4], '+'    ; Guardar operador
    
    pop ebx                     ; Recuperar operando izquierdo
    mov [eax + 8], ebx          ; hijo_izquierdo
    push eax                    ; Guardar nodo operación
    
    ; Parsear operando derecho
    call parse_term
    
    pop ebx                     ; Recuperar nodo operación
    mov [ebx + 12], eax         ; hijo_derecho
    mov eax, ebx
    push eax                    ; Nuevo término izquierdo
    
    jmp .check_operator
    
.parse_subtraction:
    ; Similar a parse_addition pero con '-'
    call consume_token
    
    call alloc_node
    mov dword [eax], NODE_BINARY_OP
    mov dword [eax + 4], '-'
    
    pop ebx
    mov [eax + 8], ebx
    push eax
    
    call parse_term
    
    pop ebx
    mov [ebx + 12], eax
    mov eax, ebx
    push eax
    
    jmp .check_operator
    
.done:
    pop edi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; parse_term: Parsea un término (multiplicación/división)
; Salida: EAX = puntero al nodo término
parse_term:
    push ebp
    mov ebp, esp
    push ebx
    push edi
    
    ; Parsear primer factor
    call parse_factor
    push eax                    ; Guardar factor izquierdo
    
.check_operator:
    ; Verificar si hay operador * o /
    call peek_token
    cmp eax, TOKEN_STAR
    je .parse_multiplication
    cmp eax, TOKEN_SLASH
    je .parse_division
    
    ; No hay más operadores
    pop eax                     ; Retornar factor
    jmp .done
    
.parse_multiplication:
    call consume_token          ; Consumir '*'
    
    ; Crear nodo operación binaria
    call alloc_node
    mov dword [eax], NODE_BINARY_OP
    mov dword [eax + 4], '*'    ; Guardar operador
    
    pop ebx                     ; Recuperar operando izquierdo
    mov [eax + 8], ebx          ; hijo_izquierdo
    push eax                    ; Guardar nodo operación
    
    ; Parsear operando derecho
    call parse_factor
    
    pop ebx                     ; Recuperar nodo operación
    mov [ebx + 12], eax         ; hijo_derecho
    mov eax, ebx
    push eax                    ; Nuevo factor izquierdo
    
    jmp .check_operator
    
.parse_division:
    ; Similar a parse_multiplication pero con '/'
    call consume_token
    
    call alloc_node
    mov dword [eax], NODE_BINARY_OP
    mov dword [eax + 4], '/'
    
    pop ebx
    mov [eax + 8], ebx
    push eax
    
    call parse_factor
    
    pop ebx
    mov [ebx + 12], eax
    mov eax, ebx
    push eax
    
    jmp .check_operator
    
.done:
    pop edi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; parse_factor: Parsea un factor (número, identificador o expresión entre paréntesis)
; Salida: EAX = puntero al nodo factor
parse_factor:
    push ebp
    mov ebp, esp
    push ebx
    
    call get_token
    
    ; Verificar tipo de token
    cmp eax, TOKEN_NUMBER
    je .parse_number
    
    cmp eax, TOKEN_IDENT
    je .parse_ident
    
    cmp eax, TOKEN_LPAREN
    je .parse_paren_expr
    
    ; Error: token inesperado
    mov eax, -1
    jmp .done
    
.parse_number:
    ; Crear nodo número
    call alloc_node
    mov dword [eax], NODE_NUMBER
    mov ebx, [token_value]
    mov [eax + 4], ebx          ; Guardar valor
    
    call consume_token
    jmp .done
    
.parse_ident:
    ; Crear nodo identificador
    call alloc_node
    mov dword [eax], NODE_IDENT
    mov ebx, [token_value]
    mov [eax + 4], ebx          ; Guardar puntero al nombre
    
    call consume_token
    jmp .done
    
.parse_paren_expr:
    call consume_token          ; Consumir '('
    
    ; Parsear expresión interna
    call parse_expression
    push eax                    ; Guardar expresión
    
    ; Esperar ')'
    call expect_token
    dd TOKEN_RPAREN
    
    pop eax                     ; Retornar expresión
    
.done:
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; Funciones auxiliares

; alloc_node: Asigna memoria para un nuevo nodo AST
; Salida: EAX = puntero al nuevo nodo
alloc_node:
    mov eax, [ast_ptr]
    add dword [ast_ptr], 16     ; Avanzar puntero
    
    ; Limpiar nodo
    mov dword [eax], 0
    mov dword [eax + 4], 0
    mov dword [eax + 8], 0
    mov dword [eax + 12], 0
    
    ret

; get_token: Obtiene el token actual
; Salida: EAX = tipo de token
get_token:
    mov eax, [current_token]
    ret

; consume_token: Avanza al siguiente token
consume_token:
    ; Avanzar puntero de tokens
    add esi, 8                  ; Siguiente token (tipo + valor)
    mov eax, [esi]              ; Cargar tipo
    mov [current_token], eax
    mov eax, [esi + 4]          ; Cargar valor
    mov [token_value], eax
    ret

; peek_token: Mira el siguiente token sin consumirlo
; Salida: EAX = tipo de token
peek_token:
    mov eax, [esi + 8]          ; Siguiente token sin avanzar
    ret

; expect_token: Verifica que el token actual sea el esperado
; Entrada: [ESP + 4] = token esperado
expect_token:
    push ebp
    mov ebp, esp
    
    call get_token
    cmp eax, [ebp + 8]
    jne .error
    
    call consume_token
    
    mov esp, ebp
    pop ebp
    ret 4
    
.error:
    ; Manejar error de sintaxis
    mov eax, -1
    mov esp, ebp
    pop ebp
    ret 4

; add_child: Agrega un hijo a un nodo
; Entrada: EBX = nodo padre, EAX = nodo hijo
add_child:
    ; Buscar primer hijo vacío
    cmp dword [ebx + 8], 0
    jne .add_right
    
    mov [ebx + 8], eax          ; Agregar como hijo izquierdo
    ret
    
.add_right:
    mov [ebx + 12], eax         ; Agregar como hijo derecho
    ret

; add_statement: Agrega una sentencia a un bloque
; Entrada: EBX = nodo bloque, EAX = sentencia
add_statement:
    ; Implementación simplificada: usar lista enlazada
    ; En un parser real, usaríamos un array dinámico
    push eax
    push ebx
    
    ; Buscar último statement en el bloque
    mov edx, ebx
.find_last:
    cmp dword [edx + 12], 0     ; hijo_derecho vacío?
    je .insert
    mov edx, [edx + 12]
    jmp .find_last
    
.insert:
    mov [edx + 12], eax         ; Insertar al final
    
    pop ebx
    pop eax
    ret
```

### Optimizaciones del Parser

```asm
; Técnicas de optimización para el parser

; 1. Predicción de tokens para evitar backtracking
predict_statement:
    call peek_token
    
    ; Tabla de saltos para tipos de statement
    lea ebx, [statement_jump_table]
    mov eax, [ebx + eax * 4]
    jmp eax
    
section .data
statement_jump_table:
    dd parse_expr_statement     ; TOKEN_NUMBER
    dd parse_expr_statement     ; TOKEN_IDENT
    dd parse_return_statement   ; TOKEN_RETURN
    dd parse_if_statement       ; TOKEN_IF
    dd parse_while_statement    ; TOKEN_WHILE
    ; ... más entradas

; 2. Inline de funciones pequeñas frecuentes
%macro ALLOC_NODE 0
    mov eax, [ast_ptr]
    add dword [ast_ptr], 16
    mov dword [eax], 0
    mov dword [eax + 4], 0
    mov dword [eax + 8], 0
    mov dword [eax + 12], 0
%endmacro

; 3. Caché de tokens para reducir accesos a memoria
section .data
    token_cache     times 4 dd 0    ; Caché de 4 tokens
    cache_pos       dd 0

; 4. Eliminación de tail recursion
parse_expr_list:
    ; En lugar de recursión, usar loop
.loop:
    call parse_expression
    push eax
    
    call peek_token
    cmp eax, TOKEN_COMMA
    jne .done
    
    call consume_token
    jmp .loop
    
.done:
    ; Construir lista desde la pila
    ret
```

### Manejo de Errores Robusto

```asm
; Sistema de recuperación de errores

section .data
    error_count     dd 0
    error_buffer    times 1024 db 0
    sync_tokens     dd TOKEN_SEMICOLON, TOKEN_RBRACE, TOKEN_FN, 0

; recover_from_error: Intenta recuperarse de un error de sintaxis
recover_from_error:
    push ebp
    mov ebp, esp
    push ebx
    push edi
    
    ; Incrementar contador de errores
    inc dword [error_count]
    
    ; Buscar token de sincronización
.find_sync:
    call get_token
    cmp eax, TOKEN_EOF
    je .done
    
    ; Verificar si es token de sincronización
    mov ebx, sync_tokens
.check_sync:
    mov edx, [ebx]
    test edx, edx
    jz .continue_search
    
    cmp eax, edx
    je .found_sync
    
    add ebx, 4
    jmp .check_sync
    
.continue_search:
    call consume_token
    jmp .find_sync
    
.found_sync:
    ; Continuar parsing desde aquí
    mov eax, 1                  ; Indicar recuperación exitosa
    
.done:
    pop edi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; report_error: Reporta un error de sintaxis
; Entrada: EAX = código de error, EBX = información adicional
report_error:
    push ebp
    mov ebp, esp
    
    ; Guardar contexto del error
    push eax
    push ebx
    
    ; Obtener línea y columna actuales
    ; (asumiendo que el tokenizer las rastrea)
    mov ecx, [current_line]
    mov edx, [current_column]
    
    ; Formatear mensaje de error
    ; ... código de formateo ...
    
    ; Intentar recuperación
    call recover_from_error
    
    pop ebx
    pop eax
    mov esp, ebp
    pop ebp
    ret
```

## 3. Ejercicios (20%)

### Ejercicio 1: Expresiones Booleanas
Extiende el parser para soportar operadores de comparación y lógicos:
- Operadores: `==`, `!=`, `<`, `>`, `<=`, `>=`
- Operadores lógicos: `&&`, `||`, `!`

### Ejercicio 2: Arrays y Acceso
Implementa el parsing de:
- Declaraciones de arrays: `let arr: i32[10];`
- Acceso a arrays: `arr[i]`
- Expresiones de índice complejas: `arr[i + j * 2]`

### Ejercicio 3: Llamadas a Funciones
Añade soporte para:
- Llamadas sin argumentos: `foo()`
- Llamadas con argumentos: `bar(x, y + 2, z * 3)`
- Llamadas anidadas: `f(g(h(x)))`

### Ejercicio 4: Optimización de Parser
Implementa las siguientes optimizaciones:
1. **Constant folding durante parsing**: Si detectas `2 + 3`, crea directamente un nodo con valor `5`
2. **Strength reduction**: Convierte `x * 2` en `x << 1` durante el parsing
3. **Dead code detection**: Marca código después de `return` como inalcanzable

### Ejercicio 5: Parser de Dos Pasadas
Diseña un parser de dos pasadas que:
1. Primera pasada: Recolecta todas las declaraciones de funciones y tipos
2. Segunda pasada: Parsea los cuerpos de las funciones con información completa de tipos

Ventajas:
- Permite forward references
- Mejor detección de errores
- Preparación para type checking

## Proyecto Integrador

Implementa un parser completo para un subconjunto de Chronos que incluya:
- Funciones con parámetros y tipos
- Estructuras básicas
- Control de flujo (if/else, while)
- Expresiones aritméticas y booleanas
- Arrays unidimensionales

El parser debe:
1. Generar un AST correcto
2. Reportar errores con línea y columna
3. Recuperarse de errores para continuar parsing
4. Usar menos de 64KB de memoria
5. Parsear al menos 1000 líneas por segundo en un 486

## Recursos Adicionales

### Referencias
- "Crafting Interpreters" - Capítulo sobre Recursive Descent
- "Modern Compiler Implementation in C" - Andrew Appel
- Dragon Book - Sección 4.4: Top-Down Parsing

### Herramientas de Debugging
```asm
; print_ast: Imprime el AST para debugging
print_ast:
    ; Implementar traversal e impresión del árbol
    ret

; validate_ast: Valida la estructura del AST
validate_ast:
    ; Verificar invariantes del árbol
    ret
```

## Conclusión

En esta lección hemos construido un parser recursivo descendente en assembly, sentando las bases para nuestro compilador self-hosted. El parser es:

1. **Eficiente**: Sin overhead de tablas o frameworks
2. **Predecible**: Tiempo de parsing acotado
3. **Mínimo**: Menos de 2KB de código
4. **Robusto**: Manejo de errores y recuperación

En la siguiente lección, tomaremos este AST y generaremos código assembly ejecutable, completando nuestro primer compilador funcional.