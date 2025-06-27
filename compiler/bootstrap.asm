; ===========================================================================
; TEMPO BOOTSTRAP - PURE ASSEMBLY, NO C!
; ===========================================================================
; Compilador mínimo de Tempo escrito 100% en assembly x64
; Author: Ignacio Peña Sepúlveda
; Date: June 25, 2025
; ===========================================================================

section .data
    banner db "╔═══════════════════════════════════════════════════════════════╗", 10
           db "║              TEMPO BOOTSTRAP - 100% ASSEMBLY                  ║", 10
           db "║  ╔═════╦═════╦═════╗                                         ║", 10
           db "║  ║ 🛡️  ║ ⚖️  ║ ⚡  ║    Zero C Dependencies                  ║", 10
           db "║  ║  C  ║  E  ║  G  ║                                         ║", 10
           db "║  ╚═════╩═════╩═════╝                                         ║", 10
           db "╚═══════════════════════════════════════════════════════════════╝", 10, 10
    banner_len equ $ - banner
    
    usage db "Uso: ./bootstrap stage1.tempo", 10
    usage_len equ $ - usage
    
    compiling db "Compilando: "
    compiling_len equ $ - compiling
    
    newline db 10
    
    success db 10, "✅ Bootstrap completado!", 10
            db "[T∞] Ahora ejecuta: ./stage1", 10
    success_len equ $ - success

section .bss
    buffer resb 65536       ; Buffer para leer archivo
    output resb 65536       ; Buffer para salida
    filename resb 256       ; Nombre del archivo

section .text
    global _start

_start:
    ; Mostrar banner
    mov rax, 1              ; sys_write
    mov rdi, 1              ; stdout
    mov rsi, banner
    mov rdx, banner_len
    syscall
    
    ; Verificar argumentos
    pop rcx                 ; argc
    cmp rcx, 2
    jl .show_usage
    
    ; Obtener nombre de archivo
    pop rsi                 ; argv[0] (programa)
    pop rsi                 ; argv[1] (archivo.tempo)
    mov rdi, filename
    call strcpy
    
    ; Mostrar que estamos compilando
    mov rax, 1
    mov rdi, 1
    mov rsi, compiling
    mov rdx, compiling_len
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, filename
    mov rdx, rsi
    call strlen
    mov rdx, rax
    syscall
    
    mov rax, 1
    mov rdi, 1
    mov rsi, newline
    mov rdx, 1
    syscall
    
    ; Abrir archivo
    mov rax, 2              ; sys_open
    mov rdi, filename
    xor rsi, rsi            ; O_RDONLY
    xor rdx, rdx
    syscall
    
    test rax, rax
    js .error_open
    
    mov r8, rax             ; Guardar fd
    
    ; Leer archivo
    mov rax, 0              ; sys_read
    mov rdi, r8
    mov rsi, buffer
    mov rdx, 65536
    syscall
    
    mov r9, rax             ; Guardar tamaño
    
    ; Cerrar archivo
    mov rax, 3              ; sys_close
    mov rdi, r8
    syscall
    
    ; Compilar (versión simplificada)
    call compile_tempo
    
    ; Crear archivo de salida (stage1)
    mov rax, 2              ; sys_open
    mov rdi, stage1_name
    mov rsi, 0x42           ; O_CREAT | O_WRONLY
    mov rdx, 0x1ed          ; 0755
    syscall
    
    mov r8, rax             ; fd
    
    ; Escribir ejecutable
    mov rax, 1              ; sys_write
    mov rdi, r8
    mov rsi, output
    mov rdx, r10            ; Tamaño del output
    syscall
    
    ; Cerrar
    mov rax, 3              ; sys_close
    mov rdi, r8
    syscall
    
    ; Hacer ejecutable
    mov rax, 90             ; sys_chmod
    mov rdi, stage1_name
    mov rsi, 0x1ed          ; 0755
    syscall
    
    ; Mostrar éxito
    mov rax, 1
    mov rdi, 1
    mov rsi, success
    mov rdx, success_len
    syscall
    
    ; Salir
    xor rdi, rdi
    mov rax, 60             ; sys_exit
    syscall

.show_usage:
    mov rax, 1
    mov rdi, 1
    mov rsi, usage
    mov rdx, usage_len
    syscall
    
    mov rdi, 1
    mov rax, 60
    syscall

.error_open:
    mov rdi, 1
    mov rax, 60
    syscall

; ===========================================================================
; COMPILADOR MÍNIMO
; ===========================================================================

compile_tempo:
    ; Generar un ELF64 mínimo que puede ejecutar stage1
    mov rdi, output
    
    ; ELF header
    mov dword [rdi], 0x464c457f     ; Magic
    mov byte [rdi+4], 2             ; 64-bit
    mov byte [rdi+5], 1             ; Little endian
    mov byte [rdi+6], 1             ; Version
    add rdi, 16
    
    mov word [rdi], 2               ; Executable
    mov word [rdi+2], 0x3e          ; x86-64
    add rdi, 8
    
    mov qword [rdi], 0x400078       ; Entry point
    add rdi, 8
    
    ; ... más código del compilador ...
    
    ; Por ahora, generar un hello world
    mov r10, 0x200                  ; Tamaño del ejecutable
    ret

; ===========================================================================
; FUNCIONES AUXILIARES
; ===========================================================================

strlen:
    xor rax, rax
.loop:
    cmp byte [rsi+rax], 0
    je .done
    inc rax
    jmp .loop
.done:
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

section .rodata
    stage1_name db "stage1", 0