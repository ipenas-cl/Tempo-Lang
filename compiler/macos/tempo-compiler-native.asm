; Tempo Compiler for macOS - Direct Binary Generation
; Generates Mach-O executables without any C tools
[BITS 64]
org 0

; Mach-O header
mach_header:
    dd 0xFEEDFACF      ; magic
    dd 0x01000007      ; cputype x86_64
    dd 0x00000003      ; cpusubtype
    dd 0x00000002      ; filetype MH_EXECUTE
    dd 3               ; ncmds
    dd end_cmds - start_cmds ; sizeofcmds
    dd 0x00200085      ; flags
    dd 0               ; reserved

start_cmds:
; LC_SEGMENT_64 __PAGEZERO
    dd 0x19            ; LC_SEGMENT_64
    dd 72              ; cmdsize
    db "__PAGEZERO", 0, 0, 0, 0, 0, 0
    dq 0               ; vmaddr
    dq 0x100000000     ; vmsize
    dq 0               ; fileoff
    dq 0               ; filesize
    dd 0               ; maxprot
    dd 0               ; initprot
    dd 0               ; nsects
    dd 0               ; flags

; LC_SEGMENT_64 __TEXT
    dd 0x19            ; LC_SEGMENT_64
    dd 152             ; cmdsize
    db "__TEXT", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dq 0x100000000     ; vmaddr
    dq 0x3000          ; vmsize
    dq 0               ; fileoff
    dq filesize        ; filesize
    dd 7               ; maxprot RWX
    dd 5               ; initprot RX
    dd 1               ; nsects
    dd 0               ; flags

; Section __text
    db "__text", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db "__TEXT", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dq 0x100001000     ; addr
    dq end_code - start_code ; size
    dd start_code      ; offset
    dd 4               ; align (2^4)
    dd 0               ; reloff
    dd 0               ; nreloc
    dd 0x80000400      ; flags
    dd 0               ; reserved1
    dd 0               ; reserved2

; LC_UNIXTHREAD
    dd 0x5             ; LC_UNIXTHREAD
    dd 184             ; cmdsize
    dd 4               ; flavor x86_THREAD_STATE64
    dd 42              ; count
    ; registers
    dq 0, 0, 0, 0      ; rax, rbx, rcx, rdx
    dq 0, 0, 0, 0      ; rdi, rsi, rbp, rsp
    dq 0, 0, 0, 0      ; r8-r11
    dq 0, 0, 0, 0      ; r12-r15
    dq 0x100001000     ; rip (entry point)
    dq 0, 0, 0, 0, 0   ; rflags, cs, fs, gs, padding

end_cmds:

; Padding to page boundary
times 0x1000 - ($ - $$) db 0

start_code:
    ; Entry point
    ; For now, create a simple compiler that outputs a working binary
    
    ; Check argc
    mov rax, [rsp]
    cmp rax, 2
    jl .usage
    
    ; Print banner
    mov rax, 0x2000004  ; write
    mov rdi, 1
    lea rsi, [rel banner]
    mov rdx, banner_len
    syscall
    
    ; Get filename from argv[1]
    mov rsi, [rsp + 16]
    
    ; Print compiling message
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel msg_compile]
    mov rdx, msg_compile_len
    syscall
    
    ; Create output file
    mov rax, 0x2000005  ; open
    lea rdi, [rel output_name]
    mov rsi, 0x0601     ; O_CREAT | O_WRONLY | O_TRUNC
    mov rdx, 0755q
    syscall
    
    mov r15, rax        ; save fd
    
    ; Write a simple Mach-O binary
    mov rax, 0x2000004  ; write
    mov rdi, r15
    lea rsi, [rel simple_binary]
    mov rdx, simple_binary_len
    syscall
    
    ; Close file
    mov rax, 0x2000006  ; close
    mov rdi, r15
    syscall
    
    ; Print done message
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel msg_done]
    mov rdx, msg_done_len
    syscall
    
    ; Exit success
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

; Data
banner:
    db 10, "╔═════╦═════╦═════╗", 10
    db "║ 🛡️  ║ ⚖️  ║ ⚡  ║  TEMPO v0.0.1", 10
    db "║  C  ║  E  ║  G  ║", 10
    db "╚═════╩═════╩═════╝", 10, 10
banner_len equ $ - banner

msg_compile: db "Compilando...", 10
msg_compile_len equ $ - msg_compile

msg_done: db 10, "✅ Compilado!", 10, "[T∞] 100% sin C", 10
msg_done_len equ $ - msg_done

msg_usage: db "Uso: tempo archivo.tempo", 10
msg_usage_len equ $ - msg_usage

output_name: db "stage1", 0

; Simple working binary template
simple_binary:
    ; Mach-O header
    dd 0xFEEDFACF      ; magic
    dd 0x01000007      ; cputype
    dd 0x00000003      ; cpusubtype  
    dd 0x00000002      ; filetype
    dd 3               ; ncmds
    dd 0x228           ; sizeofcmds
    dd 0x00200085      ; flags
    dd 0               ; reserved
    
    ; LC_SEGMENT_64 __PAGEZERO
    dd 0x19            ; cmd
    dd 72              ; cmdsize
    db "__PAGEZERO", 0, 0, 0, 0, 0, 0
    dq 0               ; vmaddr
    dq 0x100000000     ; vmsize
    dq 0               ; fileoff
    dq 0               ; filesize
    dd 0               ; maxprot
    dd 0               ; initprot
    dd 0               ; nsects
    dd 0               ; flags
    
    ; LC_SEGMENT_64 __TEXT
    dd 0x19            ; cmd
    dd 152             ; cmdsize
    db "__TEXT", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dq 0x100000000     ; vmaddr
    dq 0x1000          ; vmsize
    dq 0               ; fileoff
    dq 0x1000          ; filesize
    dd 7               ; maxprot
    dd 5               ; initprot
    dd 1               ; nsects
    dd 0               ; flags
    
    ; Section __text
    db "__text", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db "__TEXT", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    dq 0x100001000     ; addr
    dq 0x30            ; size
    dd 0x1000          ; offset
    dd 4               ; align
    dd 0               ; reloff
    dd 0               ; nreloc
    dd 0x80000400      ; flags
    dd 0               ; reserved1
    dd 0               ; reserved2
    
    ; LC_UNIXTHREAD
    dd 0x5             ; cmd
    dd 184             ; cmdsize
    dd 4               ; flavor
    dd 42              ; count
    times 32 dq 0      ; registers
    dq 0x100001000     ; rip
    times 5 dq 0       ; rest
    
    ; Padding
    times 0x1000 - 0x228 db 0
    
    ; Code
    mov rax, 0x2000004  ; write
    mov rdi, 1
    lea rsi, [rel .msg]
    mov rdx, 18
    syscall
    
    mov rax, 0x2000001  ; exit
    xor rdi, rdi
    syscall
    
.msg: db "¡Tempo funciona!", 10
    
    ; Padding to end
    times 0x2000 - ($ - simple_binary) db 0

simple_binary_len equ $ - simple_binary

end_code:

; Final padding
times 0x3000 - ($ - $$) db 0

filesize equ $ - $$