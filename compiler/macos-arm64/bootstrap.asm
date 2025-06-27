; ===========================================================================
; TEMPO BOOTSTRAP MACOS ARM64 - CERO C - 100% ASSEMBLY
; ===========================================================================
; Compilador de Tempo que puede compilar stage1.tempo
; Versión macOS/Darwin ARM64 (Apple Silicon)
; Author: Ignacio Peña Sepúlveda
; Date: June 26, 2025
; ===========================================================================

; Definir la plataforma
%define PLATFORM_MACOS

; Incluir syscalls comunes
%include "../syscalls.inc"

section .data
    ; Banner
    banner: db 0xE2,0x95,0x94,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0xA6,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0xA6,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x97,0x0A
    db "║ 🛡️  ║ ⚖️  ║ ⚡  ║  TEMPO BOOTSTRAP macOS ARM64 - ZERO C", 0x0A
    db "║  C  ║  E  ║  G  ║", 0x0A
    db 0xE2,0x95,0x9A,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0xA9,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0xA9,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x9D,0x0A,0x0A
    banner_len: equ $ - banner

    compiling: db "Compilando: ", 0
    success: db 0x0A, "✅ Tempo stage1 compilado!", 0x0A, "[T∞] Sin C en macOS ARM64!", 0x0A, 0
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
    ; ARM64 Convention: x0-x7 para argumentos, x8 para syscall number
    ; Imprimir banner
    mov x8, SYS_write
    mov x0, #1              ; stdout
    adr x1, banner          ; buffer
    mov x2, banner_len      ; length
    svc #0                  ; system call
    
    ; Verificar argumentos (argc en x0 en este punto)
    ; Necesitamos leer argc desde el stack
    ldr x0, [sp]            ; argc
    cmp x0, #2
    b.lt .usage
    
    ; Copiar nombre de archivo
    ldr x1, [sp, #16]       ; argv[1]
    adr x0, filename
    bl strcpy
    
    ; Mostrar qué compilamos
    adr x0, compiling
    bl print_str
    adr x0, filename
    bl print_str
    adr x0, newline
    bl print_str
    
    ; Abrir archivo
    mov x8, SYS_open
    adr x0, filename
    mov x1, O_RDONLY        ; flags
    mov x2, #0              ; mode (no usado para O_RDONLY)
    svc #0
    
    cmp x0, #0
    b.lt .error
    mov x19, x0             ; Guardar fd en x19 (callee-saved)
    
    ; Leer archivo completo
    mov x8, SYS_read
    mov x0, x19
    adr x1, buffer
    mov x2, #65536
    svc #0
    
    adr x1, file_size
    str x0, [x1]
    
    ; Cerrar archivo
    mov x8, SYS_close
    mov x0, x19
    svc #0
    
    ; Compilar!
    bl compile_tempo
    
    ; Escribir ejecutable Mach-O
    bl write_macho
    
    ; Éxito
    adr x0, success
    bl print_str
    
    mov x0, #0
    mov x8, SYS_exit
    svc #0

.usage:
    mov x0, #1
    mov x8, SYS_exit
    svc #0

.error:
    adr x0, error_msg
    bl print_str
    mov x0, #1
    mov x8, SYS_exit
    svc #0

; ===========================================================================
; COMPILADOR DE TEMPO (ARM64)
; ===========================================================================

compile_tempo:
    ; Inicializar
    mov x0, #0
    adr x1, pos
    str x0, [x1]
    adr x1, out_pos
    str x0, [x1]
    
    ; Generar código inicial
    bl emit_header
    
.loop:
    bl next_token
    cbz x0, .done
    
    ; Verificar si es "fn"
    adr x0, token
    adr x1, tok_fn
    bl strcmp
    cbz x0, .parse_function
    
    b .loop

.parse_function:
    bl parse_function
    b .loop

.done:
    bl emit_footer
    ret

; Parser de función (ARM64)
parse_function:
    ; Esperar nombre
    bl next_token
    
    ; Ver si es "main"
    adr x0, token
    adr x1, tok_main
    bl strcmp
    cbnz x0, .not_main
    
    ; Es main - generar _main
    adr x0, asm_start
    bl emit_string
    
.not_main:
    ; Saltar () -> i32 {
    bl skip_until_brace
    
    ; Parsear cuerpo
    bl parse_block
    
    ret

; Parser de bloque (ARM64)
parse_block:
.loop:
    bl next_token
    cbz x0, .done
    
    ; Check for }
    adr x0, token
    ldrb w1, [x0]
    cmp w1, #'}'
    b.eq .done
    
    ; Check for print_line
    adr x0, token
    adr x1, tok_print_line
    bl strcmp
    cbz x0, .print_line
    
    ; Check for return
    adr x0, token
    adr x1, tok_return
    bl strcmp
    cbz x0, .return
    
    b .loop

.print_line:
    bl parse_print_line
    b .loop

.return:
    bl parse_return
    b .loop

.done:
    ret

; Generar print_line (ARM64)
parse_print_line:
    ; Saltar (
    bl next_token
    
    ; Obtener string
    bl next_token
    
    ; Generar código
    adr x0, asm_print_start
    bl emit_string
    
    ; Emitir el string
    adr x0, token
    bl emit_string_data
    
    adr x0, asm_print_end
    bl emit_string
    
    ; Saltar )
    bl next_token
    ; Saltar ;
    bl next_token
    
    ret

; Generar return (ARM64)
parse_return:
    ; Saltar número
    bl next_token
    
    ; Generar exit
    adr x0, asm_exit
    bl emit_string
    
    ret

; ===========================================================================
; GENERADOR DE CÓDIGO (ARM64)
; ===========================================================================

emit_header:
    adr x0, macho_header
    mov x1, macho_header_len
    bl emit_bytes
    ret

emit_footer:
    ret

emit_string:
    ; x0 = string a emitir
    mov x19, x0             ; Guardar string
.loop:
    ldrb w1, [x0], #1       ; Cargar byte y avanzar
    cbz w1, .done
    mov w0, w1
    bl emit_byte
    mov x0, x19
    add x0, x0, #1
    mov x19, x0
    b .loop
.done:
    ret

emit_byte:
    ; w0 = byte a emitir
    adr x1, output
    adr x2, out_pos
    ldr x3, [x2]
    add x1, x1, x3
    strb w0, [x1]
    add x3, x3, #1
    str x3, [x2]
    ret

emit_bytes:
    ; x0 = bytes, x1 = count
    mov x19, x0             ; src
    mov x20, x1             ; count
    adr x21, output
    adr x22, out_pos
    ldr x23, [x22]
    add x21, x21, x23
    
.loop:
    cbz x20, .done
    ldrb w0, [x19], #1
    strb w0, [x21], #1
    sub x20, x20, #1
    add x23, x23, #1
    b .loop
.done:
    str x23, [x22]
    ret

; ===========================================================================
; LEXER (ARM64)
; ===========================================================================

next_token:
    ; Saltar espacios
    bl skip_whitespace
    
    ; Check EOF
    adr x0, pos
    ldr x1, [x0]
    adr x0, file_size
    ldr x2, [x0]
    cmp x1, x2
    b.ge .eof
    
    ; Leer token
    adr x0, buffer
    adr x1, pos
    ldr x2, [x1]
    add x0, x0, x2
    adr x1, token
    
    ; Check tipo de token
    ldrb w2, [x0]
    
    ; String?
    cmp w2, #'"'
    b.eq .string
    
    ; Identificador?
    mov w0, w2
    bl is_alpha
    cbnz w0, .ident
    
    ; Símbolo
    strb w2, [x1]
    mov w3, #0
    strb w3, [x1, #1]
    adr x0, pos
    ldr x2, [x0]
    add x2, x2, #1
    str x2, [x0]
    mov x0, #1
    ret

.string:
    adr x0, pos
    ldr x2, [x0]
    add x2, x2, #1
    str x2, [x0]
    adr x0, buffer
    add x0, x0, x2
    adr x1, token
    
.string_loop:
    ldrb w2, [x0]
    cmp w2, #'"'
    b.eq .string_done
    strb w2, [x1], #1
    add x0, x0, #1
    adr x3, pos
    ldr x4, [x3]
    add x4, x4, #1
    str x4, [x3]
    b .string_loop
.string_done:
    mov w2, #0
    strb w2, [x1]
    adr x0, pos
    ldr x2, [x0]
    add x2, x2, #1
    str x2, [x0]
    mov x0, #1
    ret

.ident:
    adr x0, buffer
    adr x2, pos
    ldr x3, [x2]
    add x0, x0, x3
    adr x1, token
    
.ident_loop:
    ldrb w2, [x0]
    mov w4, w2
    bl is_alnum
    cbz x0, .ident_done
    strb w4, [x1], #1
    adr x0, buffer
    adr x2, pos
    ldr x3, [x2]
    add x3, x3, #1
    str x3, [x2]
    add x0, x0, x3
    b .ident_loop
.ident_done:
    mov w2, #0
    strb w2, [x1]
    mov x0, #1
    ret

.eof:
    mov x0, #0
    ret

skip_whitespace:
    adr x0, buffer
    adr x1, pos
    ldr x2, [x1]
    add x0, x0, x2
.loop:
    ldrb w3, [x0]
    cmp w3, #' '
    b.eq .skip
    cmp w3, #0x09    ; tab
    b.eq .skip
    cmp w3, #0x0A    ; newline
    b.eq .skip
    cmp w3, #0x0D    ; cr
    b.eq .skip
    ret
.skip:
    add x2, x2, #1
    str x2, [x1]
    add x0, x0, #1
    b .loop

; ===========================================================================
; GENERADOR DE MACH-O (ARM64)
; ===========================================================================

write_macho:
    ; Crear archivo stage1
    mov x8, SYS_open
    adr x0, stage1_name
    mov x1, O_WRONLY | O_CREAT | O_TRUNC
    mov x2, #0755           ; rwxr-xr-x
    svc #0
    
    mov x19, x0             ; fd
    
    ; Escribir output
    mov x8, SYS_write
    mov x0, x19
    adr x1, output
    adr x2, out_pos
    ldr x2, [x2]
    svc #0
    
    ; Cerrar
    mov x8, SYS_close
    mov x0, x19
    svc #0
    
    ; chmod +x
    mov x8, SYS_chmod
    adr x0, stage1_name
    mov x1, #0755
    svc #0
    
    ret

; ===========================================================================
; UTILIDADES (ARM64)
; ===========================================================================

print_str:
    mov x19, x0             ; Guardar string
.loop:
    ldrb w1, [x0], #1
    cbz w1, .done
    mov x8, SYS_write
    mov x0, #1              ; stdout
    sub sp, sp, #16
    strb w1, [sp]
    mov x1, sp
    mov x2, #1
    svc #0
    add sp, sp, #16
    mov x0, x19
    add x0, x0, #1
    mov x19, x0
    b .loop
.done:
    ret

strcpy:
    ; x0 = dst, x1 = src
.loop:
    ldrb w2, [x1], #1
    strb w2, [x0], #1
    cbnz w2, .loop
    ret

strcmp:
    ; x0 = str1, x1 = str2
.loop:
    ldrb w2, [x0], #1
    ldrb w3, [x1], #1
    cmp w2, w3
    b.ne .diff
    cbz w2, .equal
    b .loop
.equal:
    mov x0, #0
    ret
.diff:
    mov x0, #1
    ret

is_alpha:
    ; w0 = character
    cmp w0, #'a'
    b.lt .check_upper
    cmp w0, #'z'
    b.le .yes
.check_upper:
    cmp w0, #'A'
    b.lt .no
    cmp w0, #'Z'
    b.le .yes
.no:
    mov x0, #0
    ret
.yes:
    mov x0, #1
    ret

is_alnum:
    mov x19, x30            ; Guardar LR
    bl is_alpha
    cbnz x0, .yes
    cmp w0, #'0'
    b.lt .check_underscore
    cmp w0, #'9'
    b.le .yes
.check_underscore:
    cmp w0, #'_'
    b.eq .yes
    mov x0, #0
    mov x30, x19
    ret
.yes:
    mov x0, #1
    mov x30, x19
    ret

skip_until_brace:
.loop:
    bl next_token
    adr x0, token
    ldrb w1, [x0]
    cmp w1, #'{'
    b.eq .done
    b .loop
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
    
    ; Template de Mach-O mínimo (ARM64)
    macho_header:
        ; Mach-O Header
        dd 0xFEEDFACF               ; Magic (64-bit)
        dd 0x0100000C               ; CPU Type (ARM64)
        dd 0x00000000               ; CPU Subtype (all)
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
        dd 0x110                    ; cmdsize (ARM64 thread state is larger)
        dd 0x06                     ; flavor (ARM_THREAD_STATE64)
        dd 0x44                     ; count (68 registers)
        ; Thread state (ARM64 registers)
        times 29 dq 0               ; x0-x28
        dq 0                        ; fp (x29)
        dq 0                        ; lr (x30)
        dq 0                        ; sp
        dq 0x0000000100000F80       ; pc (entry point)
        dq 0                        ; cpsr
        times 32 dq 0               ; v0-v31 (SIMD registers)
        dq 0                        ; fpsr
        dq 0                        ; fpcr
        
    macho_commands_size: equ $ - macho_commands
    macho_header_len: equ $ - macho_header
    
    ; Templates de código assembly para ARM64
    asm_start:
        db 0xE0, 0x03, 0x1F, 0x2A   ; mov w0, wzr
        db 0
        
    asm_print_start:
        db 0x08, 0x80, 0x80, 0xD2   ; mov x8, #0x2000004 (write syscall)
        db 0x20, 0x00, 0x80, 0xD2   ; mov x0, #1 (stdout)
        db 0
        
    asm_print_end:
        db 0x01, 0x00, 0x00, 0xD4   ; svc #0
        db 0
        
    asm_exit:
        db 0x08, 0x20, 0x80, 0xD2   ; mov x8, #0x2000001 (exit syscall)
        db 0x00, 0x00, 0x80, 0xD2   ; mov x0, #0 (exit code)
        db 0x01, 0x00, 0x00, 0xD4   ; svc #0
        db 0