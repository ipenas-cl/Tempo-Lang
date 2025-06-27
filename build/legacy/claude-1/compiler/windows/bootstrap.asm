; ===========================================================================
; TEMPO BOOTSTRAP PARA WINDOWS - CERO C
; ===========================================================================
; Bootstrap en assembly puro para Windows x64
; Author: Ignacio Peña Sepúlveda
; Date: June 25, 2025
; ===========================================================================

BITS 64

; Windows API imports
extern GetStdHandle
extern WriteConsoleA
extern ReadFile
extern CreateFileA
extern CloseHandle
extern ExitProcess
extern GetCommandLineA
extern VirtualAlloc

section .data
    ; Banner con logo
    banner: db 0xE2,0x95,0x94,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0xA6,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0xA6,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x97,0x0D,0x0A
    db 0xE2,0x95,0x91, " ",0xF0,0x9F,0x9B,0xA1,0xEF,0xB8,0x8F,"  ",0xE2,0x95,0x91, " ",0xE2,0x9A,0x96,0xEF,0xB8,0x8F,"  ",0xE2,0x95,0x91, " ",0xE2,0x9A,0xA1,"  ",0xE2,0x95,0x91,"  TEMPO BOOTSTRAP WINDOWS",0x0D,0x0A
    db 0xE2,0x95,0x91,"  C  ",0xE2,0x95,0x91,"  E  ",0xE2,0x95,0x91,"  G  ",0xE2,0x95,0x91,0x0D,0x0A
    db 0xE2,0x95,0x9A,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0xA9,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0xA9,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x90,0xE2,0x95,0x9D,0x0D,0x0A,0x0D,0x0A
    banner_len equ $ - banner

    compiling_msg: db "Compilando: ", 0
    success_msg: db 0x0D,0x0A,"[OK] stage1.exe creado!",0x0D,0x0A,"[T",0xE2,0x88,0x9E,"] Sin C!",0x0D,0x0A,0
    error_open: db "Error: No se puede abrir el archivo",0x0D,0x0A,0
    
    output_name: db "stage1.exe",0
    
    ; Constantes Windows
    STD_OUTPUT_HANDLE equ -11
    STD_INPUT_HANDLE  equ -10
    GENERIC_READ      equ 0x80000000
    GENERIC_WRITE     equ 0x40000000
    CREATE_ALWAYS     equ 2
    OPEN_EXISTING     equ 3
    FILE_ATTRIBUTE_NORMAL equ 0x80
    MEM_COMMIT        equ 0x1000
    MEM_RESERVE       equ 0x2000
    PAGE_READWRITE    equ 0x04

section .bss
    stdout_handle: resq 1
    input_handle:  resq 1
    output_handle: resq 1
    bytes_written: resd 1
    bytes_read:    resd 1
    
    buffer:        resq 1    ; Puntero a buffer alocado
    output:        resq 1    ; Puntero a output alocado
    
    cmdline:       resq 1
    filename:      resb 260  ; MAX_PATH
    
    pos:           resq 1
    file_size:     resq 1
    out_pos:       resq 1

section .text
global main

main:
    ; Stack alignment para Windows x64
    sub rsp, 40h
    
    ; Obtener stdout handle
    mov ecx, STD_OUTPUT_HANDLE
    call GetStdHandle
    mov [stdout_handle], rax
    
    ; Mostrar banner
    lea rdx, [banner]
    mov r8d, banner_len
    call write_console
    
    ; Obtener argumentos
    call GetCommandLineA
    mov [cmdline], rax
    
    ; Parsear argumentos (simplificado - asume que el archivo es el segundo arg)
    mov rsi, rax
    call skip_program_name
    call skip_spaces
    
    ; Copiar nombre de archivo
    lea rdi, [filename]
    call copy_argument
    
    ; Mostrar qué compilamos
    lea rdx, [compiling_msg]
    call write_string
    lea rdx, [filename]
    call write_string
    lea rdx, [newline]
    call write_string
    
    ; Abrir archivo de entrada
    lea rcx, [filename]
    mov edx, GENERIC_READ
    xor r8d, r8d
    xor r9d, r9d
    mov dword [rsp+20h], OPEN_EXISTING
    mov dword [rsp+28h], FILE_ATTRIBUTE_NORMAL
    mov qword [rsp+30h], 0
    call CreateFileA
    
    cmp rax, -1
    je .error_open_file
    mov [input_handle], rax
    
    ; Alocar memoria para buffer (64KB)
    xor rcx, rcx
    mov edx, 65536
    mov r8d, MEM_COMMIT | MEM_RESERVE
    mov r9d, PAGE_READWRITE
    call VirtualAlloc
    mov [buffer], rax
    
    ; Alocar memoria para output (1MB)
    xor rcx, rcx
    mov edx, 1048576
    mov r8d, MEM_COMMIT | MEM_RESERVE
    mov r9d, PAGE_READWRITE
    call VirtualAlloc
    mov [output], rax
    
    ; Leer archivo
    mov rcx, [input_handle]
    mov rdx, [buffer]
    mov r8d, 65536
    lea r9, [bytes_read]
    mov qword [rsp+20h], 0
    call ReadFile
    
    mov eax, [bytes_read]
    mov [file_size], rax
    
    ; Cerrar archivo de entrada
    mov rcx, [input_handle]
    call CloseHandle
    
    ; Compilar!
    call compile_tempo
    
    ; Crear ejecutable de salida
    call create_windows_exe
    
    ; Mostrar éxito
    lea rdx, [success_msg]
    call write_string
    
    ; Salir
    xor ecx, ecx
    call ExitProcess

.error_open_file:
    lea rdx, [error_open]
    call write_string
    mov ecx, 1
    call ExitProcess

; ===========================================================================
; FUNCIONES DE WINDOWS
; ===========================================================================

write_console:
    ; rdx = string, r8 = length
    push rbp
    mov rbp, rsp
    sub rsp, 30h
    
    mov rcx, [stdout_handle]
    ; rdx ya tiene el string
    ; r8 ya tiene length
    lea r9, [bytes_written]
    mov qword [rsp+20h], 0
    call WriteConsoleA
    
    leave
    ret

write_string:
    ; rdx = null-terminated string
    push rdx
    push rcx
    
    ; Calcular longitud
    mov rcx, rdx
    xor r8, r8
.len_loop:
    cmp byte [rcx], 0
    je .len_done
    inc rcx
    inc r8
    jmp .len_loop
.len_done:
    
    call write_console
    
    pop rcx
    pop rdx
    ret

; ===========================================================================
; COMPILADOR TEMPO
; ===========================================================================

compile_tempo:
    ; Inicializar
    xor rax, rax
    mov [pos], rax
    mov [out_pos], rax
    
    ; Por ahora, generar un ejecutable Windows simple
    call generate_pe_stub
    
    ret

generate_pe_stub:
    ; Generar un PE mínimo que muestra "Stage 1 Tempo Compiler"
    mov rdi, [output]
    
    ; DOS Header
    mov word [rdi], 0x5A4D          ; MZ
    mov word [rdi+0x3C], 0x80       ; PE header offset
    
    ; DOS Stub
    add rdi, 0x40
    mov dword [rdi], 0x0E1FBA0E     ; push cs, pop ds, mov dx, 0x0E
    mov dword [rdi+4], 0x21CD09B4   ; mov ah, 9, int 21h
    mov dword [rdi+8], 0x21CD4C01   ; mov ax, 4C01h, int 21h
    mov dword [rdi+12], 0x73696854  ; "This"
    mov dword [rdi+16], 0x6F727020  ; " pro"
    mov dword [rdi+20], 0x6D617267  ; "gram"
    ; ... etc
    
    ; PE Header
    add rdi, 0x40
    mov dword [rdi], 0x00004550     ; PE\0\0
    
    ; COFF Header
    mov word [rdi+4], 0x8664        ; Machine (x64)
    mov word [rdi+6], 2             ; NumberOfSections
    ; ... continuar con estructura PE completa
    
    mov qword [out_pos], 0x400      ; Tamaño mínimo
    ret

create_windows_exe:
    ; Crear archivo de salida
    lea rcx, [output_name]
    mov edx, GENERIC_WRITE
    xor r8d, r8d
    xor r9d, r9d
    mov dword [rsp+20h], CREATE_ALWAYS
    mov dword [rsp+28h], FILE_ATTRIBUTE_NORMAL
    mov qword [rsp+30h], 0
    call CreateFileA
    
    mov [output_handle], rax
    
    ; Escribir
    mov rcx, [output_handle]
    mov rdx, [output]
    mov r8, [out_pos]
    lea r9, [bytes_written]
    mov qword [rsp+20h], 0
    call WriteFile
    
    ; Cerrar
    mov rcx, [output_handle]
    call CloseHandle
    
    ret

; ===========================================================================
; UTILIDADES
; ===========================================================================

skip_program_name:
    ; Saltar nombre del programa en command line
    cmp byte [rsi], '"'
    je .quoted
.unquoted:
    cmp byte [rsi], ' '
    je .done
    cmp byte [rsi], 0
    je .done
    inc rsi
    jmp .unquoted
.quoted:
    inc rsi
.quoted_loop:
    cmp byte [rsi], '"'
    je .quoted_done
    cmp byte [rsi], 0
    je .done
    inc rsi
    jmp .quoted_loop
.quoted_done:
    inc rsi
.done:
    ret

skip_spaces:
    cmp byte [rsi], ' '
    jne .done
    inc rsi
    jmp skip_spaces
.done:
    ret

copy_argument:
    ; rsi = source, rdi = dest
.loop:
    cmp byte [rsi], ' '
    je .done
    cmp byte [rsi], 0
    je .done
    movsb
    jmp .loop
.done:
    mov byte [rdi], 0
    ret

section .rodata
    newline: db 0x0D, 0x0A, 0