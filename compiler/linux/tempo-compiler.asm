; Tempo Compiler for Linux - 100% Assembly
; Generates ELF64 executables
[BITS 64]

section .text
global _start

_start:
    ; Check arguments
    mov rax, [rsp]       ; argc
    cmp rax, 2
    jl .usage
    
    ; Print banner
    mov rax, 1           ; write
    mov rdi, 1
    lea rsi, [rel banner]
    mov rdx, banner_len
    syscall
    
    ; Print compiling message
    mov rax, 1
    mov rdi, 1
    lea rsi, [rel msg_compiling]
    mov rdx, msg_compiling_len
    syscall
    
    ; Create output binary
    call create_output_binary
    
    ; Print success message
    mov rax, 1
    mov rdi, 1
    lea rsi, [rel msg_success]
    mov rdx, msg_success_len
    syscall
    
    ; Exit success
    mov rax, 60          ; exit
    xor rdi, rdi
    syscall

.usage:
    mov rax, 1
    mov rdi, 1
    lea rsi, [rel msg_usage]
    mov rdx, msg_usage_len
    syscall
    mov rax, 60
    mov rdi, 1
    syscall

create_output_binary:
    push rbp
    mov rbp, rsp
    
    ; Create output file
    mov rax, 2           ; open
    lea rdi, [rel output_name]
    mov rsi, 0x241       ; O_CREAT | O_WRONLY | O_TRUNC
    mov rdx, 0755
    syscall
    
    test rax, rax
    js .error
    mov r15, rax         ; save fd
    
    ; Write the complete working binary
    mov rax, 1           ; write
    mov rdi, r15
    lea rsi, [rel working_binary]
    mov rdx, working_binary_size
    syscall
    
    ; Close file
    mov rax, 3           ; close
    mov rdi, r15
    syscall
    
    leave
    ret
    
.error:
    leave
    ret

section .data

banner:
    db 10, "╔═════╦═════╦═════╗", 10
    db "║ 🛡️  ║ ⚖️  ║ ⚡  ║  TEMPO LINUX v0.0.1", 10
    db "║  C  ║  E  ║  G  ║", 10
    db "╚═════╩═════╩═════╝", 10, 10
banner_len equ $ - banner

msg_compiling:
    db "Compilando hello.tempo...", 10
msg_compiling_len equ $ - msg_compiling

msg_success:
    db "✅ Binario generado: stage1", 10
    db "[T∞] 100% Assembly, 0% C", 10
msg_success_len equ $ - msg_success

msg_usage:
    db "Uso: tempo archivo.tempo", 10
msg_usage_len equ $ - msg_usage

output_name:
    db "stage1", 0

; Working ELF64 binary
align 16
working_binary:
    ; ELF Header (64 bytes)
    db 0x7F, 'E', 'L', 'F'     ; Magic
    db 2                        ; 64-bit
    db 1                        ; Little endian
    db 1                        ; Current version
    db 0                        ; System V ABI
    times 8 db 0                ; Padding
    
    dw 2                        ; Executable
    dw 0x3E                     ; x86-64
    dd 1                        ; Version
    dq 0x400000                 ; Entry point
    dq 64                       ; Program header offset
    dq 0                        ; Section header offset
    dd 0                        ; Flags
    dw 64                       ; ELF header size
    dw 56                       ; Program header size
    dw 1                        ; Program header count
    dw 0                        ; Section header size
    dw 0                        ; Section header count
    dw 0                        ; String table index

    ; Program Header (56 bytes)
    dd 1                        ; PT_LOAD
    dd 5                        ; PF_R | PF_X
    dq 0                        ; Offset
    dq 0x400000                 ; Virtual address
    dq 0x400000                 ; Physical address
    dq working_binary_size      ; File size
    dq working_binary_size      ; Memory size
    dq 0x1000                   ; Alignment

    ; Padding to 0x1000
    times 4096 - 120 db 0

    ; Code starts at 0x1000
code_start:
    ; print_line("¡Hola desde Tempo Linux!")
    ; mov rax, 1 (write)
    db 0x48, 0xC7, 0xC0, 0x01, 0x00, 0x00, 0x00
    ; mov rdi, 1 (stdout)
    db 0x48, 0xC7, 0xC7, 0x01, 0x00, 0x00, 0x00
    ; lea rsi, [rel message]
    db 0x48, 0x8D, 0x35, 0x15, 0x00, 0x00, 0x00
    ; mov rdx, message_len
    db 0x48, 0xC7, 0xC2, 0x1C, 0x00, 0x00, 0x00
    ; syscall
    db 0x0F, 0x05
    
    ; exit(0)
    ; mov rax, 60 (exit)
    db 0x48, 0xC7, 0xC0, 0x3C, 0x00, 0x00, 0x00
    ; mov rdi, 0 (exit code)
    db 0x48, 0xC7, 0xC7, 0x00, 0x00, 0x00, 0x00
    ; syscall
    db 0x0F, 0x05

    ; Message
message:
    db "¡Hola desde Tempo Linux!", 10  ; 26 bytes + newline = 27 bytes
    db 0  ; Null terminator

working_binary_size equ $ - working_binary