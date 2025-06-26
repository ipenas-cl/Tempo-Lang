; ===========================================================================
; TEMPO BOOTSTRAP MACOS - CERO C - 100% ASSEMBLY
; ===========================================================================
; Compilador de Tempo que puede compilar stage1.tempo
; Versión macOS/Darwin x86-64
; Author: Ignacio Peña Sepúlveda
; Date: June 26, 2025
; ===========================================================================

BITS 64

; Definir la plataforma
%define PLATFORM_MACOS

; Incluir syscalls comunes
%include "../syscalls.inc"

section .data
    ; Banner
    banner: db 0xE2,0x95,0x94,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0xA6,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0xA6,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x97,0x0A
    db "║ 🛡️  ║ ⚖️  ║ ⚡  ║  TEMPO BOOTSTRAP macOS - ZERO C", 0x0A
    db "║  C  ║  E  ║  G  ║", 0x0A
    db 0xE2,0x95,0x9A,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0xA9,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0xA9,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x9D,0x0A,0x0A
    banner_len: equ $ - banner

    compiling: db "Compilando: ", 0
    success: db 0x0A, "✅ Tempo stage1 compilado!", 0x0A, "[T∞] Sin C en macOS!", 0x0A, 0
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
    mov rax, SYS_write
    mov rdi, 1              ; stdout
    lea rsi, [rel banner]
    mov rdx, banner_len
    syscall
    
    ; Verificar argumentos
    mov rax, [rsp]          ; argc
    cmp rax, 2
    jl .usage
    
    ; Copiar nombre de archivo
    mov rsi, [rsp+16]       ; argv[1]
    lea rdi, [rel filename]
    call strcpy
    
    ; Mostrar qué compilamos
    lea rsi, [rel compiling]
    call print_str
    lea rsi, [rel filename]
    call print_str
    lea rsi, [rel newline]
    call print_str
    
    ; Abrir archivo
    mov rax, SYS_open
    lea rdi, [rel filename]
    mov rsi, O_RDONLY       ; flags
    xor rdx, rdx            ; mode (no usado para O_RDONLY)
    syscall
    
    test rax, rax
    js .error
    mov r15, rax            ; Guardar fd
    
    ; Leer archivo completo
    mov rax, SYS_read
    mov rdi, r15
    lea rsi, [rel buffer]
    mov rdx, 65536
    syscall
    
    mov [rel file_size], rax
    
    ; Cerrar archivo
    mov rax, SYS_close
    mov rdi, r15
    syscall
    
    ; Compilar!
    call compile_tempo
    
    ; Escribir ejecutable Mach-O
    call write_macho
    
    ; Éxito
    lea rsi, [rel success]
    call print_str
    
    xor rdi, rdi
    mov rax, SYS_exit
    syscall

.usage:
    mov rdi, 1
    mov rax, SYS_exit
    syscall

.error:
    lea rsi, [rel error_msg]
    call print_str
    mov rdi, 1
    mov rax, SYS_exit
    syscall

; ===========================================================================
; COMPILADOR DE TEMPO
; ===========================================================================

compile_tempo:
    ; Inicializar
    xor rax, rax
    mov [rel pos], rax
    mov [rel out_pos], rax
    
    ; Generar código inicial
    call emit_header
    
.loop:
    call next_token
    test rax, rax
    jz .done
    
    ; Verificar si es "fn"
    lea rsi, [rel token]
    lea rdi, [rel tok_fn]
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
    lea rsi, [rel token]
    lea rdi, [rel tok_main]
    call strcmp
    test rax, rax
    jnz .not_main
    
    ; Es main - generar _main (macOS usa _main en lugar de _start)
    lea rsi, [rel asm_start]
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
    mov al, [rel token]
    cmp al, '}'
    je .done
    
    ; Check for print_line
    lea rsi, [rel token]
    lea rdi, [rel tok_print_line]
    call strcmp
    test rax, rax
    jz .print_line
    
    ; Check for return
    lea rsi, [rel token]
    lea rdi, [rel tok_return]
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
    lea rsi, [rel asm_print_start]
    call emit_string
    
    ; Emitir el string
    lea rsi, [rel token]
    call emit_string_data
    
    lea rsi, [rel asm_print_end]
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
    lea rsi, [rel asm_exit]
    call emit_string
    
    ret

; ===========================================================================
; GENERADOR DE CÓDIGO
; ===========================================================================

emit_header:
    lea rsi, [rel macho_header]
    mov rcx, macho_header_len
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
    lea rdi, [rel output]
    add rdi, [rel out_pos]
    mov [rdi], al
    inc qword [rel out_pos]
    pop rdi
    ret

emit_bytes:
    ; rsi = bytes, rcx = count
    push rdi
    push rcx
    lea rdi, [rel output]
    add rdi, [rel out_pos]
    rep movsb
    pop rcx
    add [rel out_pos], rcx
    pop rdi
    ret

; ===========================================================================
; LEXER
; ===========================================================================

next_token:
    ; Saltar espacios
    call skip_whitespace
    
    ; Check EOF
    mov rax, [rel pos]
    cmp rax, [rel file_size]
    jge .eof
    
    ; Leer token
    lea rsi, [rel buffer]
    add rsi, [rel pos]
    lea rdi, [rel token]
    
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
    inc qword [rel pos]
    mov rax, 1
    ret

.string:
    inc rsi
    inc qword [rel pos]
.string_loop:
    mov al, [rsi]
    cmp al, '"'
    je .string_done
    mov [rdi], al
    inc rsi
    inc rdi
    inc qword [rel pos]
    jmp .string_loop
.string_done:
    mov byte [rdi], 0
    inc qword [rel pos]
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
    inc qword [rel pos]
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
    lea rsi, [rel buffer]
    add rsi, [rel pos]
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
    inc qword [rel pos]
    inc rsi
    jmp .loop

; ===========================================================================
; GENERADOR DE MACH-O
; ===========================================================================

write_macho:
    ; Crear archivo stage1
    mov rax, SYS_open
    lea rdi, [rel stage1_name]
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, 0755q          ; rwxr-xr-x
    syscall
    
    mov r15, rax            ; fd
    
    ; Escribir output
    mov rax, SYS_write
    mov rdi, r15
    lea rsi, [rel output]
    mov rdx, [rel out_pos]
    syscall
    
    ; Cerrar
    mov rax, SYS_close
    mov rdi, r15
    syscall
    
    ; chmod +x
    mov rax, SYS_chmod
    lea rdi, [rel stage1_name]
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
    mov rax, SYS_write
    mov rdi, 1              ; stdout
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
    mov al, [rel token]
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
    
    ; Template de Mach-O mínimo (64-bit)
    macho_header:
        ; Mach-O Header
        dd 0xFEEDFACF               ; Magic (64-bit)
        dd 0x01000007               ; CPU Type (x86_64)
        dd 0x00000003               ; CPU Subtype (all)
        dd 0x00000002               ; File Type (executable)
        dd 0x00000003               ; Number of Load Commands
        dd macho_commands_size      ; Size of Load Commands
        dd 0x00000085               ; Flags
        dd 0x00000000               ; Reserved
        
    macho_commands:
        ; LC_SEGMENT_64 (__PAGEZERO)
        dd 0x19                     ; cmd (LC_SEGMENT_64)
        dd 0x48                     ; cmdsize
        db '__PAGEZERO',0,0,0,0,0,0 ; segname
        dq 0x0000000000000000       ; vmaddr
        dq 0x0000000100000000       ; vmsize
        dq 0x0000000000000000       ; fileoff
        dq 0x0000000000000000       ; filesize
        dd 0x00000000               ; maxprot
        dd 0x00000000               ; initprot
        dd 0x00000000               ; nsects
        dd 0x00000000               ; flags
        
        ; LC_SEGMENT_64 (__TEXT)
        dd 0x19                     ; cmd (LC_SEGMENT_64)
        dd 0x98                     ; cmdsize
        db '__TEXT',0,0,0,0,0,0,0,0,0,0 ; segname
        dq 0x0000000100000000       ; vmaddr
        dq 0x0000000000001000       ; vmsize
        dq 0x0000000000000000       ; fileoff
        dq 0x0000000000001000       ; filesize
        dd 0x00000007               ; maxprot (RWX)
        dd 0x00000005               ; initprot (RX)
        dd 0x00000001               ; nsects
        dd 0x00000000               ; flags
        
        ; Section (__text)
        db '__text',0,0,0,0,0,0,0,0,0,0 ; sectname
        db '__TEXT',0,0,0,0,0,0,0,0,0,0 ; segname
        dq 0x0000000100000F80       ; addr
        dq 0x0000000000000080       ; size
        dd 0x00000F80               ; offset
        dd 0x00000004               ; align
        dd 0x00000000               ; reloff
        dd 0x00000000               ; nreloc
        dd 0x80000400               ; flags
        dd 0x00000000               ; reserved1
        dd 0x00000000               ; reserved2
        dd 0x00000000               ; reserved3
        
        ; LC_UNIXTHREAD
        dd 0x05                     ; cmd (LC_UNIXTHREAD)
        dd 0xB8                     ; cmdsize
        dd 0x04                     ; flavor (x86_THREAD_STATE64)
        dd 0x2A                     ; count
        ; Thread state (registers)
        times 16 dq 0               ; rax, rbx, rcx, rdx, rdi, rsi, rbp, rsp
        dq 0x0000000100000F80       ; rip (entry point)
        times 5 dq 0                ; rflags, cs, fs, gs, (padding)
        
    macho_commands_size: equ $ - macho_commands
    macho_header_len: equ $ - macho_header
    
    ; Templates de código assembly para macOS
    asm_start:
        db 0x48, 0x31, 0xC0         ; xor rax, rax
        db 0
        
    asm_print_start:
        db 0x48, 0xC7, 0xC0, 0x04, 0x00, 0x00, 0x02  ; mov rax, 0x2000004 (write)
        db 0x48, 0xC7, 0xC7, 0x01, 0x00, 0x00, 0x00  ; mov rdi, 1 (stdout)
        db 0
        
    asm_print_end:
        db 0x0F, 0x05                ; syscall
        db 0
        
    asm_exit:
        db 0x48, 0xC7, 0xC0, 0x01, 0x00, 0x00, 0x02  ; mov rax, 0x2000001 (exit)
        db 0x48, 0x31, 0xFF                           ; xor rdi, rdi
        db 0x0F, 0x05                                 ; syscall
        db 0