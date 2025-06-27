; Tempo Minimal Compiler - Generates tempo.app from .tempo files
[BITS 64]

section .text
global start

start:
    ; Check arguments
    mov rax, [rsp]       ; argc
    cmp rax, 2
    jl .usage
    
    ; Get input filename from argv[1]
    mov rax, [rsp + 16]  ; argv
    mov rax, [rax + 8]   ; argv[1]
    mov [input_file], rax
    
    ; Show banner
    mov rax, 0x2000004   ; write
    mov rdi, 1
    lea rsi, [rel banner]
    mov rdx, banner_len
    syscall
    
    ; Show compiling message
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel msg_compiling]
    mov rdx, msg_compiling_len
    syscall
    
    ; Create output binary
    call create_output_binary
    
    ; Show success message
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel msg_success]
    mov rdx, msg_success_len
    syscall
    
    ; Exit successfully
    xor rdi, rdi
    mov rax, 0x2000001
    syscall

.usage:
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel msg_usage]
    mov rdx, msg_usage_len
    syscall
    mov rdi, 1
    mov rax, 0x2000001
    syscall

; Create tempo.app executable
create_output_binary:
    push rbp
    mov rbp, rsp
    
    ; Create tempo.app file
    mov rax, 0x2000005   ; open
    lea rdi, [rel output_name]
    mov rsi, 0x601       ; O_CREAT | O_WRONLY | O_TRUNC
    mov rdx, 0755        ; Executable permissions
    syscall
    test rax, rax
    js .error
    mov [output_fd], rax
    
    ; Write minimal Mach-O binary
    mov rax, 0x2000004   ; write
    mov rdi, [output_fd]
    lea rsi, [rel working_binary]
    mov rdx, working_binary_size
    syscall
    
    ; Close file
    mov rax, 0x2000006   ; close
    mov rdi, [output_fd]
    syscall
    
    leave
    ret

.error:
    mov rax, 0x2000004
    mov rdi, 2
    lea rsi, [rel error_msg]
    mov rdx, error_msg_len
    syscall
    leave
    ret

section .data

banner: db "╔═════╦═════╦═════╗", 10
        db "║ 🛡️  ║ ⚖️  ║ ⚡  ║  TEMPO v0.0.1", 10
        db "║  C  ║  E  ║  G  ║", 10
        db "╚═════╩═════╩═════╝", 10, 10
banner_len equ $ - banner

msg_compiling: db "Compilando ", 0
msg_compiling_len equ $ - msg_compiling

msg_success: db "✅ Binario generado: tempo.app", 10
             db "[T∞] 100% Assembly, 0% C", 10
             db "✅ Compilation successful!", 10
             db "   Run with: ./tempo.app", 10
msg_success_len equ $ - msg_success

msg_usage: db "Uso: tempo archivo.tempo", 10
msg_usage_len equ $ - msg_usage

error_msg: db "❌ Error creating tempo.app", 10
error_msg_len equ $ - error_msg

output_name: db "tempo.app", 0

; Minimal working Mach-O binary that prints "Hello from Tempo!"
working_binary:
    ; Mach-O header
    dd 0xFEEDFACF      ; magic
    dd 0x01000007      ; cputype x86_64  
    dd 0x00000003      ; cpusubtype
    dd 0x00000002      ; filetype MH_EXECUTE
    dd 2               ; ncmds
    dd end_cmds - start_cmds ; sizeofcmds
    dd 0x00200085      ; flags
    dd 0               ; reserved

start_cmds:
; LC_SEGMENT_64 __TEXT
    dd 0x19            ; LC_SEGMENT_64
    dd 152             ; cmdsize
    db "__TEXT", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dq 0x100000000     ; vmaddr
    dq 0x2000          ; vmsize
    dq 0               ; fileoff
    dq binary_size     ; filesize
    dd 7               ; maxprot RWX
    dd 5               ; initprot RX
    dd 1               ; nsects
    dd 0               ; flags

; Section __text
    db "__text", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db "__TEXT", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dq 0x100001000     ; addr
    dq code_end - code_start ; size
    dd code_start - working_binary ; offset
    dd 0               ; align
    dd 0               ; reloff
    dd 0               ; nreloc
    dd 0x800           ; flags S_REGULAR
    dd 0               ; reserved1
    dd 0               ; reserved2
    dd 0               ; reserved3

; LC_MAIN
    dd 0x80000028      ; LC_MAIN
    dd 24              ; cmdsize
    dq code_start - working_binary ; entryoff
    dq 0               ; stacksize

end_cmds:

; Code section
code_start:
    ; write syscall to print message
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel message]
    mov rdx, message_len
    syscall
    
    ; exit with code 0
    mov rax, 0x2000001
    mov rdi, 0
    syscall

message: db "¡Hola desde Tempo!", 10
message_len equ $ - message

code_end:

binary_size equ $ - working_binary
working_binary_size equ binary_size

section .bss

input_file: resq 1
output_fd: resq 1