╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 8: Generación de Código - From AST to Assembly

## Objetivos de la Lección
- Comprender el proceso de generación de código desde un AST
- Implementar un generador de código x86 eficiente
- Manejar registros y memoria de forma óptima
- Generar código determinista y predecible

## 1. Teoría (20%)

### El Proceso de Generación de Código

La generación de código es la fase final de un compilador donde transformamos la representación intermedia (AST) en código máquina ejecutable. Para Chronos, generamos directamente assembly x86 optimizado.

### Estrategias de Generación

1. **Generación Directa**: AST → Assembly
   - Ventaja: Simple y rápido
   - Desventaja: Menos oportunidades de optimización

2. **Generación con IR**: AST → IR → Assembly
   - Ventaja: Mejor optimización
   - Desventaja: Más complejo

Para nuestro compilador minimalista, usaremos generación directa con optimizaciones locales.

### Gestión de Registros

```
Convención de registros x86:
- EAX: Valor de retorno, operaciones aritméticas
- EBX: Registro preservado (callee-saved)
- ECX: Contador, cuarto argumento
- EDX: Datos, tercer argumento
- ESI: Source index, segundo argumento
- EDI: Destination index, primer argumento
- EBP: Frame pointer
- ESP: Stack pointer
```

### Stack Frame Layout

```
Alto
+---------------+
| Argumentos    |
+---------------+
| Return addr   |
+---------------+
| EBP anterior  | <- EBP
+---------------+
| Variables     |
| locales       |
+---------------+
| Chronosrales    | <- ESP
+---------------+
Bajo
```

## 2. Práctica (60%)

### Generador de Código Base

```asm
section .data
    ; Tabla de símbolos simple
    symbol_count    dd 0
    symbol_table    times 1024 db 0    ; nombre(32) + offset(4) + tipo(4)
    
    ; Control de stack frame
    local_offset    dd 0
    param_offset    dd 8               ; Después de EBP y return address
    
    ; Buffer de salida
    output_buffer   times 65536 db 0
    output_ptr      dd output_buffer
    
    ; Registros disponibles
    free_regs       db 0xFF            ; Bitmask: 1=libre, 0=ocupado

section .text

; generate_code: Genera código desde el AST
; Entrada: EAX = puntero al AST
generate_code:
    push ebp
    mov ebp, esp
    push ebx
    push edi
    push esi
    
    ; Emitir header del programa
    call emit_header
    
    ; Generar código para cada función
    mov ebx, eax                ; EBX = nodo programa
    mov esi, [ebx + 8]          ; Primer hijo (primera función)
    
.gen_functions:
    test esi, esi
    jz .done
    
    ; Generar función
    push esi
    call generate_function
    
    ; Siguiente función
    mov esi, [esi + 12]         ; Hermano derecho
    jmp .gen_functions
    
.done:
    ; Emitir footer
    call emit_footer
    
    mov eax, [output_ptr]
    sub eax, output_buffer      ; Tamaño del código generado
    
    pop esi
    pop edi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; generate_function: Genera código para una función
; Entrada: [ESP + 4] = nodo función
generate_function:
    push ebp
    mov ebp, esp
    push ebx
    push edi
    push esi
    
    mov ebx, [ebp + 8]          ; EBX = nodo función
    
    ; Reiniciar estado local
    mov dword [local_offset], 0
    
    ; Emitir label de función
    mov eax, [ebx + 4]          ; Nombre de función
    call emit_label
    
    ; Emitir prólogo
    call emit_string
    db "    push ebp", 10
    db "    mov ebp, esp", 10, 0
    
    ; Reservar espacio para variables locales
    ; (por ahora, reservamos un espacio fijo)
    call emit_string
    db "    sub esp, 64", 10, 0
    
    ; Generar código del cuerpo
    mov eax, [ebx + 8]          ; Bloque de función
    call generate_block
    
    ; Emitir epílogo
    call emit_string
    db "    mov esp, ebp", 10
    db "    pop ebp", 10
    db "    ret", 10, 10, 0
    
    pop esi
    pop edi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 4

; generate_block: Genera código para un bloque
; Entrada: EAX = nodo bloque
generate_block:
    push ebp
    mov ebp, esp
    push ebx
    push esi
    
    mov ebx, eax
    mov esi, [ebx + 8]          ; Primera sentencia
    
.gen_statements:
    test esi, esi
    jz .done
    
    ; Generar sentencia
    mov eax, esi
    call generate_statement
    
    ; Siguiente sentencia
    mov esi, [esi + 12]         ; Hermano derecho
    jmp .gen_statements
    
.done:
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; generate_statement: Genera código para una sentencia
; Entrada: EAX = nodo sentencia
generate_statement:
    push ebp
    mov ebp, esp
    push ebx
    
    mov ebx, eax
    mov eax, [ebx]              ; Tipo de nodo
    
    ; Tabla de saltos para tipos de sentencia
    cmp eax, NODE_RETURN
    je .gen_return
    
    cmp eax, NODE_IF
    je .gen_if
    
    cmp eax, NODE_WHILE
    je .gen_while
    
    cmp eax, NODE_ASSIGN
    je .gen_assign
    
    ; Por defecto, es una expresión
    mov eax, ebx
    call generate_expression
    
    jmp .done
    
.gen_return:
    ; Generar expresión de retorno en EAX
    mov eax, [ebx + 8]          ; Expresión
    test eax, eax
    jz .return_void
    
    call generate_expression
    
.return_void:
    ; Saltar al epílogo
    call emit_string
    db "    jmp .epilogue", 10, 0
    jmp .done
    
.gen_if:
    ; Generar código para if
    call generate_if_statement
    jmp .done
    
.gen_while:
    ; Generar código para while
    call generate_while_statement
    jmp .done
    
.gen_assign:
    ; Generar código para asignación
    call generate_assignment
    
.done:
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; generate_expression: Genera código para una expresión
; Entrada: EAX = nodo expresión
; Salida: El resultado queda en EAX
generate_expression:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx
    
    mov ebx, eax
    mov eax, [ebx]              ; Tipo de nodo
    
    cmp eax, NODE_NUMBER
    je .gen_number
    
    cmp eax, NODE_IDENT
    je .gen_ident
    
    cmp eax, NODE_BINARY_OP
    je .gen_binary_op
    
    cmp eax, NODE_CALL
    je .gen_call
    
    ; Error: tipo de nodo desconocido
    jmp .done
    
.gen_number:
    ; Cargar número inmediato
    mov eax, [ebx + 4]          ; Valor
    call emit_string
    db "    mov eax, ", 0
    call emit_number
    call emit_newline
    jmp .done
    
.gen_ident:
    ; Cargar variable
    mov eax, [ebx + 4]          ; Nombre
    call lookup_symbol
    test eax, eax
    js .undefined_var
    
    ; Cargar desde stack
    call emit_string
    db "    mov eax, [ebp", 0
    
    test eax, eax
    jns .positive_offset
    
    ; Offset negativo (variable local)
    call emit_string
    db "-", 0
    neg eax
    
.positive_offset:
    call emit_number
    call emit_string
    db "]", 10, 0
    jmp .done
    
.undefined_var:
    ; Error: variable no definida
    jmp .done
    
.gen_binary_op:
    ; Generar operación binaria
    push ebx
    
    ; Generar operando izquierdo
    mov eax, [ebx + 8]
    call generate_expression
    
    ; Guardar resultado
    call emit_string
    db "    push eax", 10, 0
    
    ; Generar operando derecho
    pop ebx
    push ebx
    mov eax, [ebx + 12]
    call generate_expression
    
    ; Recuperar operando izquierdo
    call emit_string
    db "    pop ecx", 10, 0
    
    ; Generar operación
    pop ebx
    mov eax, [ebx + 4]          ; Operador
    
    cmp eax, '+'
    je .add
    cmp eax, '-'
    je .sub
    cmp eax, '*'
    je .mul
    cmp eax, '/'
    je .div
    
.add:
    call emit_string
    db "    add eax, ecx", 10, 0
    jmp .done
    
.sub:
    call emit_string
    db "    sub ecx, eax", 10
    db "    mov eax, ecx", 10, 0
    jmp .done
    
.mul:
    call emit_string
    db "    imul eax, ecx", 10, 0
    jmp .done
    
.div:
    call emit_string
    db "    xchg eax, ecx", 10
    db "    cdq", 10
    db "    idiv ecx", 10, 0
    jmp .done
    
.gen_call:
    ; Generar llamada a función
    call generate_function_call
    
.done:
    pop edx
    pop ecx
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; generate_if_statement: Genera código para if/else
; Entrada: EBX = nodo if
generate_if_statement:
    push ebp
    mov ebp, esp
    push edi
    
    ; Generar etiquetas únicas
    call get_label_id
    mov edi, eax                ; ID para esta sentencia if
    
    ; Generar condición
    mov eax, [ebx + 8]          ; Condición
    call generate_expression
    
    ; Saltar si falso
    call emit_string
    db "    test eax, eax", 10
    db "    jz .L", 0
    mov eax, edi
    call emit_number
    call emit_string
    db "_else", 10, 0
    
    ; Generar bloque then
    mov eax, [ebx + 12]         ; Bloque then
    call generate_block
    
    ; Saltar sobre else
    call emit_string
    db "    jmp .L", 0
    mov eax, edi
    call emit_number
    call emit_string
    db "_end", 10, 0
    
    ; Etiqueta else
    call emit_string
    db ".L", 0
    mov eax, edi
    call emit_number
    call emit_string
    db "_else:", 10, 0
    
    ; Generar bloque else (si existe)
    mov eax, [ebx + 16]         ; Bloque else (opcional)
    test eax, eax
    jz .no_else
    call generate_block
    
.no_else:
    ; Etiqueta end
    call emit_string
    db ".L", 0
    mov eax, edi
    call emit_number
    call emit_string
    db "_end:", 10, 0
    
    pop edi
    mov esp, ebp
    pop ebp
    ret

; generate_while_statement: Genera código para while
; Entrada: EBX = nodo while
generate_while_statement:
    push ebp
    mov ebp, esp
    push edi
    
    ; Generar etiquetas únicas
    call get_label_id
    mov edi, eax
    
    ; Etiqueta inicio
    call emit_string
    db ".L", 0
    mov eax, edi
    call emit_number
    call emit_string
    db "_start:", 10, 0
    
    ; Generar condición
    mov eax, [ebx + 8]          ; Condición
    call generate_expression
    
    ; Saltar si falso
    call emit_string
    db "    test eax, eax", 10
    db "    jz .L", 0
    mov eax, edi
    call emit_number
    call emit_string
    db "_end", 10, 0
    
    ; Generar cuerpo
    mov eax, [ebx + 12]         ; Cuerpo
    call generate_block
    
    ; Saltar al inicio
    call emit_string
    db "    jmp .L", 0
    mov eax, edi
    call emit_number
    call emit_string
    db "_start", 10, 0
    
    ; Etiqueta fin
    call emit_string
    db ".L", 0
    mov eax, edi
    call emit_number
    call emit_string
    db "_end:", 10, 0
    
    pop edi
    mov esp, ebp
    pop ebp
    ret

; Funciones de emisión de código

; emit_string: Emite una cadena terminada en 0
; Entrada: Cadena después del call
emit_string:
    push esi
    push edi
    
    mov esi, [esp + 8]          ; Dirección de retorno = cadena
    mov edi, [output_ptr]
    
.copy:
    lodsb
    test al, al
    jz .done
    stosb
    jmp .copy
    
.done:
    mov [output_ptr], edi
    
    ; Ajustar dirección de retorno
    mov [esp + 8], esi
    
    pop edi
    pop esi
    ret

; emit_number: Emite un número en decimal
; Entrada: EAX = número
emit_number:
    push eax
    push ebx
    push ecx
    push edx
    push edi
    
    mov edi, [output_ptr]
    mov ebx, 10
    xor ecx, ecx                ; Contador de dígitos
    
    ; Manejar números negativos
    test eax, eax
    jns .positive
    neg eax
    mov byte [edi], '-'
    inc edi
    
.positive:
    ; Convertir a dígitos (orden inverso)
.convert:
    xor edx, edx
    div ebx
    push edx                    ; Guardar dígito
    inc ecx
    test eax, eax
    jnz .convert
    
    ; Emitir dígitos
.emit:
    pop eax
    add al, '0'
    stosb
    loop .emit
    
    mov [output_ptr], edi
    
    pop edi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret

; emit_newline: Emite un salto de línea
emit_newline:
    push edi
    mov edi, [output_ptr]
    mov byte [edi], 10
    inc edi
    mov [output_ptr], edi
    pop edi
    ret

; emit_label: Emite una etiqueta
; Entrada: EAX = puntero al nombre
emit_label:
    push esi
    push edi
    
    mov esi, eax
    mov edi, [output_ptr]
    
    ; Copiar nombre
.copy:
    lodsb
    test al, al
    jz .done
    stosb
    jmp .copy
    
.done:
    mov byte [edi], ':'
    inc edi
    mov byte [edi], 10
    inc edi
    mov [output_ptr], edi
    
    pop edi
    pop esi
    ret

; emit_header: Emite el header del programa
emit_header:
    call emit_string
    db "section .text", 10
    db "global _start", 10, 10
    db "_start:", 10
    db "    call main", 10
    db "    mov ebx, eax", 10
    db "    mov eax, 1", 10
    db "    int 0x80", 10, 10, 0
    ret

; emit_footer: Emite el footer del programa
emit_footer:
    call emit_string
    db 10, "section .data", 10
    db "    ; Datos del programa", 10, 0
    ret
```

### Optimizaciones en la Generación

```asm
; Optimizaciones locales durante la generación

; 1. Constant folding en tiempo de generación
generate_optimized_binary_op:
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    
    mov ebx, [ebp + 8]          ; Nodo operación
    
    ; Verificar si ambos operandos son constantes
    mov eax, [ebx + 8]          ; Operando izquierdo
    cmp dword [eax], NODE_NUMBER
    jne .generate_normal
    
    mov ecx, [ebx + 12]         ; Operando derecho
    cmp dword [ecx], NODE_NUMBER
    jne .generate_normal
    
    ; Ambos son constantes, evaluar en tiempo de compilación
    mov eax, [eax + 4]          ; Valor izquierdo
    mov ecx, [ecx + 4]          ; Valor derecho
    mov edx, [ebx + 4]          ; Operador
    
    cmp edx, '+'
    je .const_add
    cmp edx, '-'
    je .const_sub
    cmp edx, '*'
    je .const_mul
    cmp edx, '/'
    je .const_div
    
.const_add:
    add eax, ecx
    jmp .emit_constant
    
.const_sub:
    sub eax, ecx
    jmp .emit_constant
    
.const_mul:
    imul eax, ecx
    jmp .emit_constant
    
.const_div:
    cdq
    idiv ecx
    
.emit_constant:
    ; Emitir resultado como constante
    call emit_string
    db "    mov eax, ", 0
    call emit_number
    call emit_newline
    jmp .done
    
.generate_normal:
    ; Generar código normal
    mov eax, ebx
    call generate_expression
    
.done:
    pop ecx
    pop ebx
    mov esp, ebp
    pop ebp
    ret

; 2. Strength reduction
generate_optimized_mul:
    ; Si multiplicamos por potencia de 2, usar shift
    mov ecx, [ebx + 12]         ; Operando derecho
    cmp dword [ecx], NODE_NUMBER
    jne .normal_mul
    
    mov ecx, [ecx + 4]          ; Valor
    
    ; Verificar si es potencia de 2
    mov edx, ecx
    dec edx
    test ecx, edx               ; n & (n-1) == 0 si es potencia de 2
    jnz .normal_mul
    
    ; Calcular shift count
    bsf edx, ecx                ; Encontrar primer bit
    
    ; Generar shift en lugar de multiplicación
    call emit_string
    db "    shl eax, ", 0
    mov eax, edx
    call emit_number
    call emit_newline
    ret
    
.normal_mul:
    ; Multiplicación normal
    call emit_string
    db "    imul eax, ecx", 10, 0
    ret

; 3. Peephole optimizations
peephole_optimize:
    ; Eliminar instrucciones redundantes
    ; mov eax, eax -> nop
    ; add eax, 0   -> nop
    ; push eax; pop eax -> nop
    
    ; Implementación simplificada
    ret

; 4. Register allocation mejorado
allocate_register:
    ; Buscar registro libre
    movzx ecx, byte [free_regs]
    bsf eax, ecx                ; Encontrar primer bit libre
    jz .no_free_reg
    
    ; Marcar como usado
    btr [free_regs], eax
    ret
    
.no_free_reg:
    ; Spill a memoria
    mov eax, -1
    ret

free_register:
    ; Entrada: EAX = registro a liberar
    bts [free_regs], eax
    ret
```

### Generación de Código para Características Avanzadas

```asm
; generate_struct_access: Genera código para acceso a campos de estructura
; Entrada: EBX = nodo acceso (struct.field)
generate_struct_access:
    push ebp
    mov ebp, esp
    push edi
    
    ; Generar dirección base de la estructura
    mov eax, [ebx + 8]          ; Expresión base
    call generate_expression
    
    ; EAX contiene puntero a estructura
    push eax
    
    ; Buscar offset del campo
    mov eax, [ebx + 12]         ; Nombre del campo
    call lookup_field_offset
    mov edi, eax                ; EDI = offset
    
    pop eax
    
    ; Generar acceso
    call emit_string
    db "    mov eax, [eax + ", 0
    mov eax, edi
    call emit_number
    call emit_string
    db "]", 10, 0
    
    pop edi
    mov esp, ebp
    pop ebp
    ret

; generate_array_access: Genera código para acceso a arrays
; Entrada: EBX = nodo acceso (array[index])
generate_array_access:
    push ebp
    mov ebp, esp
    push edi
    
    ; Generar índice
    mov eax, [ebx + 12]         ; Expresión índice
    call generate_expression
    push eax                    ; Guardar índice
    
    ; Generar dirección base del array
    mov eax, [ebx + 8]          ; Array
    call generate_expression
    
    ; Calcular dirección: base + index * size
    pop ecx                     ; Recuperar índice
    
    ; Obtener tamaño del elemento
    mov edi, 4                  ; Por ahora, asumir i32
    
    call emit_string
    db "    lea eax, [eax + ecx * ", 0
    mov eax, edi
    call emit_number
    call emit_string
    db "]", 10
    db "    mov eax, [eax]", 10, 0
    
    pop edi
    mov esp, ebp
    pop ebp
    ret

; generate_function_call: Genera código para llamada a función
; Entrada: EBX = nodo llamada
generate_function_call:
    push ebp
    mov ebp, esp
    push edi
    push esi
    
    ; Guardar registros caller-saved
    call emit_string
    db "    push ecx", 10
    db "    push edx", 10, 0
    
    ; Evaluar y push argumentos (derecha a izquierda)
    mov esi, [ebx + 12]         ; Lista de argumentos
    call count_arguments
    mov edi, eax                ; Número de argumentos
    
    ; Push argumentos en orden inverso
    call push_arguments_reverse
    
    ; Llamar función
    call emit_string
    db "    call ", 0
    mov eax, [ebx + 4]          ; Nombre de función
    call emit_identifier
    call emit_newline
    
    ; Limpiar stack
    test edi, edi
    jz .no_cleanup
    
    call emit_string
    db "    add esp, ", 0
    mov eax, edi
    shl eax, 2                  ; argumentos * 4
    call emit_number
    call emit_newline
    
.no_cleanup:
    ; Restaurar registros
    call emit_string
    db "    pop edx", 10
    db "    pop ecx", 10, 0
    
    pop esi
    pop edi
    mov esp, ebp
    pop ebp
    ret
```

## 3. Ejercicios (20%)

### Ejercicio 1: Optimización de Tail Calls
Implementa la optimización de tail calls:
```tempo
fn factorial(n: i32, acc: i32) -> i32 {
    if n <= 1 {
        return acc;
    }
    return factorial(n - 1, n * acc);  // Tail call
}
```
Debe generar un jump en lugar de call/ret.

### Ejercicio 2: Inline de Funciones Pequeñas
Implementa inlining automático para funciones que:
- Tienen menos de 5 instrucciones
- No tienen loops
- Son llamadas frecuentemente

### Ejercicio 3: Allocation de Registros
Implementa un allocator de registros simple que:
- Asigne variables a registros cuando sea posible
- Haga spill a memoria cuando se agoten los registros
- Priorice variables más usadas

### Ejercicio 4: Generación de Código SIMD
Para arrays, genera código que use instrucciones SSE cuando sea posible:
```tempo
// Suma de arrays
for i in 0..n {
    c[i] = a[i] + b[i];
}
```

### Ejercicio 5: Análisis de Liveness
Implementa análisis de liveness para:
- Reusar registros de variables muertas
- Eliminar stores innecesarios
- Optimizar el uso del stack

## Proyecto Integrador

Completa el generador de código con las siguientes características:

1. **Soporte completo de tipos**:
   - Enteros de diferentes tamaños (i8, i16, i32, i64)
   - Booleanos con representación eficiente
   - Arrays y estructuras

2. **Optimizaciones esenciales**:
   - Constant folding
   - Dead code elimination
   - Strength reduction
   - Peephole optimizations

3. **Gestión de memoria**:
   - Stack allocation automático
   - Alineación correcta
   - Overflow detection

4. **Debugging support**:
   - Comentarios en el assembly generado
   - Mapeo línea fuente → assembly
   - Símbolos para debugger

El generador debe producir código que:
- Sea correcto y eficiente
- Use menos de 32 registros x86
- Minimice accesos a memoria
- Sea determinista (mismo input → mismo output)

## Recursos Adicionales

### Patrones de Generación Comunes

```asm
; Patrón: Comparación y branch
;   if (a < b) { ... }
    mov eax, [ebp-4]    ; a
    cmp eax, [ebp-8]    ; b
    jge .else_label
    ; código del then
    jmp .end_label
.else_label:
    ; código del else
.end_label:

; Patrón: Loop con contador
;   for i in 0..n { ... }
    xor ecx, ecx        ; i = 0
.loop_start:
    cmp ecx, [ebp-4]    ; i < n
    jge .loop_end
    ; cuerpo del loop
    inc ecx
    jmp .loop_start
.loop_end:

; Patrón: Switch/case
;   switch (x) { ... }
    mov eax, [ebp-4]    ; x
    cmp eax, 0
    je .case_0
    cmp eax, 1
    je .case_1
    ; más casos...
    jmp .default
```

### Debugging del Código Generado

```asm
; Macro para debugging
%macro DEBUG_PRINT 1
    pushad
    push %1
    call debug_print_value
    add esp, 4
    popad
%endmacro

; Verificación de invariantes
%macro ASSERT_ALIGNED 1
    test %1, 3
    jnz .alignment_error
%endmacro
```

## Conclusión

En esta lección hemos implementado un generador de código que transforma nuestro AST en assembly x86 ejecutable. El generador:

1. **Es eficiente**: Genera código optimizado localmente
2. **Es correcto**: Maneja todos los casos del lenguaje
3. **Es predecible**: Produce código determinista
4. **Es minimal**: Sin dependencias externas

Con el tokenizer (Lección 6), parser (Lección 7) y generador de código (Lección 8), tenemos todos los componentes para nuestro compilador. En la próxima lección, realizaremos el momento mágico: hacer que nuestro compilador se compile a sí mismo.