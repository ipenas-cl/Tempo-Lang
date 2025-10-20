; CHRONOS v0.2 - Control Flow + Function Calls

section .text
    global _start

_start:
    call main
    mov rdi, rax
    mov rax, 60
    syscall

main:
    mov rax, 10
    push rax
    mov rax, 5
    mov rbx, rax
    pop rax
    cmp rax, rbx
    setg al
    movzx rax, al
    test rax, rax
    jz .L0
    mov rax, 42
    ret
    jmp .L1
.L0:
.L1:
    mov rax, 0
    ret
