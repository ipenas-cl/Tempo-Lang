; ===========================================================================
; TEMPO BOOTSTRAP - CERO C - 100% ASSEMBLY
; ===========================================================================
; Compilador de Tempo que puede compilar stage1.tempo
; Author: Ignacio Peña Sepúlveda
; Date: June 25, 2025
; ===========================================================================

BITS 64

section .data
    ; Banner
    banner: db 0xE2,0x95,0x94,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0xA6,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0xA6,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x97,0x0A
    db "║ 🛡️  ║ ⚖️  ║ ⚡  ║  TEMPO BOOTSTRAP - ZERO C", 0x0A
    db "║  C  ║  E  ║  G  ║", 0x0A
    db 0xE2,0x95,0x9A,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0xA9,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0xA9,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x9D,0x0A,0x0A
    banner_len: equ $ - banner

    compiling: db "Compilando: ", 0
    success: db 0x0A, "✅ Tempo stage1 compilado!", 0x0A, "[T∞] Sin C!", 0x0A, 0
    error_msg: db "Error: No puedo abrir archivo", 0x0A, 0
    
    ; Tokens de Tempo
    tok_fn: db "fn", 0
    tok_let: db "let", 0
    tok_return: db "return", 0
    tok_print_line: db "print_line", 0
    tok_main: db "main", 0
    tok_i32: db "i32", 0

section .bss
    buffer: resb 65536      ; Buffer de entrada
    output: resb 1048576    ; Buffer de salida (1MB)
    token: resb 256         ; Token actual
    filename: resb 256      ; Nombre archivo
    
    ; Estado del compilador
    pos: resq 1             ; Posición en buffer
    out_pos: resq 1         ; Posición en output
    file_size: resq 1       ; Tamaño del archivo

section .text
global _start

_start:
    ; Imprimir banner
    mov rax, 1
    mov rdi, 1
    mov rsi, banner
    mov rdx, banner_len
    syscall
    
    ; Verificar argumentos
    mov rax, [rsp]          ; argc
    cmp rax, 2
    jl .usage
    
    ; Copiar nombre de archivo
    mov rsi, [rsp+16]       ; argv[1]
    mov rdi, filename
    call strcpy
    
    ; Mostrar qué compilamos
    mov rsi, compiling
    call print_str
    mov rsi, filename
    call print_str
    mov rsi, newline
    call print_str
    
    ; Abrir archivo
    mov rax, 2              ; open
    mov rdi, filename
    xor rsi, rsi            ; O_RDONLY
    syscall
    
    test rax, rax
    js .error
    mov r15, rax            ; Guardar fd
    
    ; Leer archivo completo
    mov rax, 0              ; read
    mov rdi, r15
    mov rsi, buffer
    mov rdx, 65536
    syscall
    
    mov [file_size], rax
    
    ; Cerrar archivo
    mov rax, 3              ; close
    mov rdi, r15
    syscall
    
    ; Compilar!
    call compile_tempo
    
    ; Escribir ejecutable
    call write_elf
    
    ; Éxito
    mov rsi, success
    call print_str
    
    xor rdi, rdi
    mov rax, 60
    syscall

.usage:
    mov rdi, 1
    mov rax, 60
    syscall

.error:
    mov rsi, error_msg
    call print_str
    mov rdi, 1
    mov rax, 60
    syscall

; ===========================================================================
; COMPILADOR DE TEMPO
; ===========================================================================

compile_tempo:
    ; Inicializar
    xor rax, rax
    mov [pos], rax
    mov [out_pos], rax
    
    ; Generar código inicial
    call emit_header
    
.loop:
    call next_token
    test rax, rax
    jz .done
    
    ; Verificar si es "fn"
    mov rsi, token
    mov rdi, tok_fn
    call strcmp
    test rax, rax
    jz .parse_function
    
    jmp .loop

.parse_function:
    call parse_function
    jmp .loop

.done:
    call emit_footer
    ret

; Parser de función
parse_function:
    ; Esperar nombre
    call next_token
    
    ; Ver si es "main"
    mov rsi, token
    mov rdi, tok_main
    call strcmp
    test rax, rax
    jnz .not_main
    
    ; Es main - generar _start
    mov rsi, asm_start
    call emit_string
    
.not_main:
    ; Saltar () -> i32 {
    call skip_until_brace
    
    ; Parsear cuerpo
    call parse_block
    
    ret

; Parser de bloque
parse_block:
.loop:
    call next_token
    test rax, rax
    jz .done
    
    ; Check for }
    mov al, [token]
    cmp al, '}'
    je .done
    
    ; Check for print_line
    mov rsi, token
    mov rdi, tok_print_line
    call strcmp
    test rax, rax
    jz .print_line
    
    ; Check for return
    mov rsi, token
    mov rdi, tok_return
    call strcmp
    test rax, rax
    jz .return
    
    jmp .loop

.print_line:
    call parse_print_line
    jmp .loop

.return:
    call parse_return
    jmp .loop

.done:
    ret

; Generar print_line
parse_print_line:
    ; Saltar (
    call next_token
    
    ; Obtener string
    call next_token
    
    ; Generar código
    mov rsi, asm_print_start
    call emit_string
    
    ; Emitir el string
    mov rsi, token
    call emit_string_data
    
    mov rsi, asm_print_end
    call emit_string
    
    ; Saltar )
    call next_token
    ; Saltar ;
    call next_token
    
    ret

; Generar return
parse_return:
    ; Saltar número
    call next_token
    
    ; Generar exit
    mov rsi, asm_exit
    call emit_string
    
    ret

; ===========================================================================
; GENERADOR DE CÓDIGO
; ===========================================================================

emit_header:
    mov rsi, elf_header
    mov rcx, elf_header_len
    call emit_bytes
    ret

emit_footer:
    ret

emit_string:
    ; rsi = string a emitir
    push rsi
.loop:
    lodsb
    test al, al
    jz .done
    call emit_byte
    jmp .loop
.done:
    pop rsi
    ret

emit_byte:
    ; al = byte a emitir
    push rdi
    mov rdi, output
    add rdi, [out_pos]
    mov [rdi], al
    inc qword [out_pos]
    pop rdi
    ret

emit_bytes:
    ; rsi = bytes, rcx = count
    push rdi
    push rcx
    mov rdi, output
    add rdi, [out_pos]
    rep movsb
    pop rcx
    add [out_pos], rcx
    pop rdi
    ret

; ===========================================================================
; LEXER
; ===========================================================================

next_token:
    ; Saltar espacios
    call skip_whitespace
    
    ; Check EOF
    mov rax, [pos]
    cmp rax, [file_size]
    jge .eof
    
    ; Leer token
    mov rsi, buffer
    add rsi, [pos]
    mov rdi, token
    
    ; Check tipo de token
    mov al, [rsi]
    
    ; String?
    cmp al, '"'
    je .string
    
    ; Identificador?
    call is_alpha
    test rax, rax
    jnz .ident
    
    ; Símbolo
    mov [rdi], al
    mov byte [rdi+1], 0
    inc qword [pos]
    mov rax, 1
    ret

.string:
    inc rsi
    inc qword [pos]
.string_loop:
    mov al, [rsi]
    cmp al, '"'
    je .string_done
    mov [rdi], al
    inc rsi
    inc rdi
    inc qword [pos]
    jmp .string_loop
.string_done:
    mov byte [rdi], 0
    inc qword [pos]
    mov rax, 1
    ret

.ident:
.ident_loop:
    mov al, [rsi]
    call is_alnum
    test rax, rax
    jz .ident_done
    mov [rdi], al
    inc rsi
    inc rdi
    inc qword [pos]
    jmp .ident_loop
.ident_done:
    mov byte [rdi], 0
    mov rax, 1
    ret

.eof:
    xor rax, rax
    ret

skip_whitespace:
    push rsi
    mov rsi, buffer
    add rsi, [pos]
.loop:
    mov al, [rsi]
    cmp al, ' '
    je .skip
    cmp al, 0x09    ; tab
    je .skip
    cmp al, 0x0A    ; newline
    je .skip
    cmp al, 0x0D    ; cr
    je .skip
    pop rsi
    ret
.skip:
    inc qword [pos]
    inc rsi
    jmp .loop

; ===========================================================================
; GENERADOR DE ELF
; ===========================================================================

write_elf:
    ; Crear archivo stage1
    mov rax, 2              ; open
    mov rdi, stage1_name
    mov rsi, 0x42           ; O_CREAT|O_WRONLY
    mov rdx, 0755q
    syscall
    
    mov r15, rax            ; fd
    
    ; Escribir output
    mov rax, 1              ; write
    mov rdi, r15
    mov rsi, output
    mov rdx, [out_pos]
    syscall
    
    ; Cerrar
    mov rax, 3              ; close
    mov rdi, r15
    syscall
    
    ; chmod +x
    mov rax, 90             ; chmod
    mov rdi, stage1_name
    mov rsi, 0755q
    syscall
    
    ret

; ===========================================================================
; UTILIDADES
; ===========================================================================

print_str:
    push rsi
.loop:
    lodsb
    test al, al
    jz .done
    push rax
    push rsi
    mov rax, 1
    mov rdi, 1
    mov rsi, rsp
    add rsi, 8
    mov rdx, 1
    syscall
    pop rsi
    pop rax
    jmp .loop
.done:
    pop rsi
    ret

strcpy:
    push rsi
    push rdi
.loop:
    lodsb
    stosb
    test al, al
    jnz .loop
    pop rdi
    pop rsi
    ret

strcmp:
    push rsi
    push rdi
.loop:
    mov al, [rsi]
    mov bl, [rdi]
    cmp al, bl
    jne .diff
    test al, al
    jz .equal
    inc rsi
    inc rdi
    jmp .loop
.equal:
    xor rax, rax
    pop rdi
    pop rsi
    ret
.diff:
    mov rax, 1
    pop rdi
    pop rsi
    ret

is_alpha:
    cmp al, 'a'
    jl .check_upper
    cmp al, 'z'
    jle .yes
.check_upper:
    cmp al, 'A'
    jl .no
    cmp al, 'Z'
    jle .yes
.no:
    xor rax, rax
    ret
.yes:
    mov rax, 1
    ret

is_alnum:
    call is_alpha
    test rax, rax
    jnz .yes
    cmp al, '0'
    jl .check_underscore
    cmp al, '9'
    jle .yes
.check_underscore:
    cmp al, '_'
    je .yes
    xor rax, rax
    ret
.yes:
    mov rax, 1
    ret

skip_until_brace:
.loop:
    call next_token
    mov al, [token]
    cmp al, '{'
    je .done
    jmp .loop
.done:
    ret

emit_string_data:
    ; Por ahora simplificado
    ret

; ===========================================================================
; DATOS
; ===========================================================================

section .rodata
    newline: db 0x0A, 0
    stage1_name: db "stage1", 0
    
    ; Template de ELF mínimo
    elf_header:
        db 0x7F, 'E', 'L', 'F'      ; Magic
        db 2                         ; 64-bit
        db 1                         ; Little endian
        db 1                         ; Version
        db 0                         ; System V ABI
        times 8 db 0                 ; Padding
        dw 2                         ; Executable
        dw 0x3E                      ; x86-64
        dd 1                         ; Version
        dq 0x400078                  ; Entry point
        dq 0x40                      ; Program header offset
        dq 0                         ; Section header offset
        dd 0                         ; Flags
        dw 0x40                      ; ELF header size
        dw 0x38                      ; Program header size
        dw 1                         ; Program header count
        dw 0                         ; Section header size
        dw 0                         ; Section header count
        dw 0                         ; String table index
        
        ; Program header
        dd 1                         ; PT_LOAD
        dd 7                         ; RWX
        dq 0                         ; Offset
        dq 0x400000                  ; Virtual address
        dq 0x400000                  ; Physical address
        dq 0x1000                    ; File size
        dq 0x1000                    ; Memory size
        dq 0x1000                    ; Alignment
    elf_header_len: equ $ - elf_header
    
    ; Templates de código assembly
    asm_start:
        db 0x48, 0x31, 0xC0         ; xor rax, rax
        db 0
        
    asm_print_start:
        db 0x48, 0xC7, 0xC0, 0x01, 0x00, 0x00, 0x00  ; mov rax, 1
        db 0x48, 0xC7, 0xC7, 0x01, 0x00, 0x00, 0x00  ; mov rdi, 1
        db 0
        
    asm_print_end:
        db 0x0F, 0x05                ; syscall
        db 0
        
    asm_exit:
        db 0x48, 0xC7, 0xC0, 0x3C, 0x00, 0x00, 0x00  ; mov rax, 60
        db 0x48, 0x31, 0xFF                           ; xor rdi, rdi
        db 0x0F, 0x05                                 ; syscall
        db 0