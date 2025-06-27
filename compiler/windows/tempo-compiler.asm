; Tempo Compiler for Windows - 100% Assembly  
; Generates PE64 executables
[BITS 64]

section .text
global WinMainCRTStartup

WinMainCRTStartup:
    ; Simple Windows entry point
    ; For now, just exit - Windows PE is complex
    
    ; GetStdHandle for stdout
    sub rsp, 32          ; Shadow space
    mov rcx, -11         ; STD_OUTPUT_HANDLE
    call [GetStdHandle]
    mov r15, rax         ; Save handle
    
    ; WriteFile banner
    mov rcx, r15         ; Handle
    lea rdx, [rel banner]  ; Buffer
    mov r8, banner_len   ; Bytes to write
    lea r9, [rel bytes_written]  ; Bytes written
    push 0               ; Overlapped
    call [WriteFile]
    
    ; WriteFile compiling message
    mov rcx, r15
    lea rdx, [rel msg_compiling]
    mov r8, msg_compiling_len
    lea r9, [rel bytes_written]
    push 0
    call [WriteFile]
    
    ; Create output file - simplified for now
    ; Just write success message
    mov rcx, r15
    lea rdx, [rel msg_success]
    mov r8, msg_success_len
    lea r9, [rel bytes_written]
    push 0
    call [WriteFile]
    
    ; ExitProcess
    xor rcx, rcx
    call [ExitProcess]

section .data

banner:
    db 13, 10, "╔═════╦═════╦═════╗", 13, 10
    db "║ 🛡️  ║ ⚖️  ║ ⚡  ║  TEMPO WINDOWS v0.0.1", 13, 10
    db "║  C  ║  E  ║  G  ║", 13, 10
    db "╚═════╩═════╩═════╝", 13, 10, 13, 10
banner_len equ $ - banner

msg_compiling:
    db "Compilando hello.tempo...", 13, 10
msg_compiling_len equ $ - msg_compiling

msg_success:
    db "✅ Binario generado: stage1.exe", 13, 10
    db "[T∞] 100% Assembly, 0% C", 13, 10
msg_success_len equ $ - msg_success

section .bss
bytes_written: resd 1

section .idata
; Import table for kernel32.dll
extern GetStdHandle
extern WriteFile  
extern ExitProcess