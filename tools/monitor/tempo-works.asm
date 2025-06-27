; Tempo Works - Minimal Valid Mach-O
[BITS 64]
org 0

; Mach-O header (32 bytes)
mach_header:
    dd 0xFEEDFACF      ; magic
    dd 0x01000007      ; cputype x86_64
    dd 0x00000003      ; cpusubtype
    dd 0x00000002      ; filetype EXECUTE
    dd 3               ; ncmds
    dd lcend - lcstart ; sizeofcmds
    dd 0x00200085      ; flags
    dd 0               ; reserved

lcstart:
; LC_SEGMENT_64 __PAGEZERO (72 bytes)
    dd 0x19            ; LC_SEGMENT_64
    dd 72              ; cmdsize
    db "__PAGEZERO", 0, 0, 0, 0, 0, 0 ; segname
    dq 0               ; vmaddr
    dq 0x100000000     ; vmsize
    dq 0               ; fileoff
    dq 0               ; filesize
    dd 0               ; maxprot
    dd 0               ; initprot
    dd 0               ; nsects
    dd 0               ; flags

; LC_SEGMENT_64 __TEXT (152 bytes)
    dd 0x19            ; LC_SEGMENT_64
    dd 152             ; cmdsize
    db "__TEXT", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; segname
    dq 0x100000000     ; vmaddr
    dq 0x1000          ; vmsize
    dq 0               ; fileoff
    dq filesize        ; filesize
    dd 7               ; maxprot RWX
    dd 5               ; initprot RX
    dd 1               ; nsects
    dd 0               ; flags

; Section __text (80 bytes)
    db "__text", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; sectname
    db "__TEXT", 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ; segname
    dq 0x100000000 + codestart ; addr
    dq codeend - codestart     ; size
    dd codestart               ; offset
    dd 4                       ; align (2^4)
    dd 0                       ; reloff
    dd 0                       ; nreloc
    dd 0x80000400             ; flags
    dd 0                       ; reserved1
    dd 0                       ; reserved2

; LC_UNIXTHREAD (184 bytes)
    dd 0x5             ; LC_UNIXTHREAD
    dd 184             ; cmdsize
    dd 4               ; flavor x86_THREAD_STATE64
    dd 42              ; count
    ; x86_thread_state64_t
    dq 0, 0, 0, 0      ; rax, rbx, rcx, rdx
    dq 0, 0, 0, 0      ; rdi, rsi, rbp, rsp
    dq 0, 0, 0, 0      ; r8-r11
    dq 0, 0, 0, 0      ; r12-r15
    dq 0x100000000 + codestart ; rip
    dq 0, 0, 0, 0, 0   ; rflags, cs, fs, gs, padding

lcend:

; Padding to page boundary
times 0x1000 - ($ - $$) db 0

codestart:
    ; write(1, "Tempo Works!\n", 13)
    mov rax, 0x2000004  ; write
    mov rdi, 1          ; stdout
    lea rsi, [rel msg]  ; message
    mov rdx, 13         ; length
    syscall
    
    ; exit(0)
    mov rax, 0x2000001  ; exit
    xor rdi, rdi        ; status 0
    syscall

msg: db "Tempo Works!", 10
codeend:

; Padding to end
times 0x2000 - ($ - $$) db 0

filesize equ $ - $$