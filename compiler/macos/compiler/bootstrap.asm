; ===========================================================================
; TEMPO BOOTSTRAP COMPILER FOR macOS
; ===========================================================================
; Genera binarios Mach-O válidos sin usar herramientas de C
; 100% determinista, 100% Tempo
; ===========================================================================

[BITS 64]
[DEFAULT REL]

section .data
    ; Banner
    banner: db 10, "╔═════╦═════╦═════╗", 10
            db "║ 🛡️  ║ ⚖️  ║ ⚡  ║  TEMPO COMPILER v0.0.1", 10
            db "║  C  ║  E  ║  G  ║", 10
            db "╚═════╩═════╩═════╝", 10, 10, 0

    msg_compile: db "Compilando: ", 0
    msg_done: db 10, "✅ Compilado!", 10, 0
    msg_error: db "❌ Error: ", 0
    msg_usage: db "Uso: tempo archivo.tempo", 10, 0
    
    output_name: db "stage1", 0

    ; Tokens
    tok_fn: db "fn", 0
    tok_main: db "main", 0
    tok_print_line: db "print_line", 0
    tok_return: db "return", 0
    tok_i32: db "i32", 0

    ; macOS syscalls
    SYS_exit    equ 0x2000001
    SYS_read    equ 0x2000003
    SYS_write   equ 0x2000004
    SYS_open    equ 0x2000005
    SYS_close   equ 0x2000006
    SYS_unlink  equ 0x200000A
    SYS_chmod   equ 0x200000F

    O_RDONLY    equ 0x0000
    O_WRONLY    equ 0x0001
    O_CREAT     equ 0x0200
    O_TRUNC     equ 0x0400

section .bss
    input_buffer:   resb 65536
    output_buffer:  resb 65536
    token_buffer:   resb 256
    string_buffer:  resb 4096
    
    input_pos:      resq 1
    output_pos:     resq 1
    token_pos:      resq 1
    string_count:   resq 1
    code_size:      resq 1

section .text
global _main

_main:
    ; Show banner
    lea rsi, [banner]
    call print_string
    
    ; Check arguments
    pop rax             ; argc
    cmp rax, 2
    jl .usage
    
    pop rax             ; skip argv[0]
    pop rdi             ; argv[1] - filename
    
    ; Show compiling message
    push rdi
    lea rsi, [msg_compile]
    call print_string
    pop rsi
    push rsi
    call print_string
    
    ; Open input file
    pop rdi
    mov rax, SYS_open
    mov rsi, O_RDONLY
    xor rdx, rdx
    syscall
    
    test rax, rax
    js .error
    mov r15, rax        ; save fd
    
    ; Read file
    mov rax, SYS_read
    mov rdi, r15
    lea rsi, [input_buffer]
    mov rdx, 65536
    syscall
    
    mov r14, rax        ; save size
    
    ; Close file
    mov rax, SYS_close
    mov rdi, r15
    syscall
    
    ; Initialize
    mov qword [input_pos], 0
    mov qword [output_pos], 0
    mov qword [string_count], 0
    
    ; Compile
    call compile_program
    
    ; Write output
    call write_macho_binary
    
    ; Success message
    lea rsi, [msg_done]
    call print_string
    
    ; Exit
    xor rdi, rdi
    mov rax, SYS_exit
    syscall

.usage:
    lea rsi, [msg_usage]
    call print_string
    mov rdi, 1
    mov rax, SYS_exit
    syscall

.error:
    lea rsi, [msg_error]
    call print_string
    mov rdi, 1
    mov rax, SYS_exit
    syscall

; ===========================================================================
; COMPILER
; ===========================================================================

compile_program:
    push rbp
    mov rbp, rsp
    
.next_token:
    call get_next_token
    test rax, rax
    jz .done
    
    ; Check for "fn"
    lea rdi, [token_buffer]
    lea rsi, [tok_fn]
    call string_compare
    test rax, rax
    jz .compile_function
    
    jmp .next_token
    
.compile_function:
    call compile_function
    jmp .next_token
    
.done:
    leave
    ret

compile_function:
    push rbp
    mov rbp, rsp
    
    ; Get function name
    call get_next_token
    
    ; For now, only support "main"
    lea rdi, [token_buffer]
    lea rsi, [tok_main]
    call string_compare
    test rax, rax
    jnz .done
    
    ; Skip to opening brace
.find_brace:
    call get_next_token
    lea rdi, [token_buffer]
    cmp byte [rdi], '{'
    jne .find_brace
    
    ; Generate function prologue
    call emit_function_prologue
    
    ; Parse function body
.parse_body:
    call get_next_token
    test rax, rax
    jz .done
    
    lea rdi, [token_buffer]
    cmp byte [rdi], '}'
    je .end_function
    
    ; Check for print_line
    lea rsi, [tok_print_line]
    call string_compare
    test rax, rax
    jz .handle_print_line
    
    ; Check for return
    lea rdi, [token_buffer]
    lea rsi, [tok_return]
    call string_compare
    test rax, rax
    jz .handle_return
    
    jmp .parse_body
    
.handle_print_line:
    call compile_print_line
    jmp .parse_body
    
.handle_return:
    call compile_return
    jmp .parse_body
    
.end_function:
    call emit_function_epilogue
    
.done:
    leave
    ret

; ===========================================================================
; CODE GENERATION
; ===========================================================================

emit_function_prologue:
    ; Nothing needed for main
    ret

emit_function_epilogue:
    ; Nothing needed - return handles it
    ret

compile_print_line:
    push rbp
    mov rbp, rsp
    
    ; Skip opening paren
    call get_next_token
    
    ; Get string literal
    call get_next_token
    
    ; Store string in string section
    mov rax, [string_count]
    lea rdi, [string_buffer + rax]
    lea rsi, [token_buffer]
    call copy_string
    
    ; Remember string offset
    mov rbx, [string_count]
    add [string_count], rax
    inc qword [string_count]    ; for null terminator
    
    ; Skip closing paren and semicolon
    call get_next_token
    call get_next_token
    
    ; Generate code for print_line
    mov rdi, [output_pos]
    lea rsi, [output_buffer + rdi]
    
    ; mov rax, SYS_write
    mov byte [rsi], 0x48
    mov byte [rsi+1], 0xC7
    mov byte [rsi+2], 0xC0
    mov dword [rsi+3], SYS_write
    add rsi, 7
    
    ; mov rdi, 1 (stdout)
    mov byte [rsi], 0x48
    mov byte [rsi+1], 0xC7
    mov byte [rsi+2], 0xC7
    mov dword [rsi+3], 1
    add rsi, 7
    
    ; lea rsi, [rel string_addr]
    mov byte [rsi], 0x48
    mov byte [rsi+1], 0x8D
    mov byte [rsi+2], 0x35
    ; Calculate relative offset to string
    mov eax, 0x1000         ; strings start at 0x1000 after code
    sub eax, esi
    add eax, ebx
    add eax, 3              ; adjust for instruction length
    mov dword [rsi+3], eax
    add rsi, 7
    
    ; mov rdx, string_length
    mov byte [rsi], 0x48
    mov byte [rsi+1], 0xC7
    mov byte [rsi+2], 0xC2
    ; Calculate string length
    push rsi
    lea rdi, [token_buffer]
    call string_length
    pop rsi
    mov dword [rsi+3], eax
    add rsi, 7
    
    ; syscall
    mov byte [rsi], 0x0F
    mov byte [rsi+1], 0x05
    add rsi, 2
    
    ; Update output position
    sub rsi, output_buffer
    mov [output_pos], rsi
    
    leave
    ret

compile_return:
    push rbp
    mov rbp, rsp
    
    ; Skip return value (for now always 0)
    call get_next_token
    call get_next_token     ; skip semicolon
    
    mov rdi, [output_pos]
    lea rsi, [output_buffer + rdi]
    
    ; mov rax, SYS_exit
    mov byte [rsi], 0x48
    mov byte [rsi+1], 0xC7
    mov byte [rsi+2], 0xC0
    mov dword [rsi+3], SYS_exit
    add rsi, 7
    
    ; xor rdi, rdi (exit code 0)
    mov byte [rsi], 0x48
    mov byte [rsi+1], 0x31
    mov byte [rsi+2], 0xFF
    add rsi, 3
    
    ; syscall
    mov byte [rsi], 0x0F
    mov byte [rsi+1], 0x05
    add rsi, 2
    
    ; Update output position
    sub rsi, output_buffer
    mov [output_pos], rsi
    
    leave
    ret

; ===========================================================================
; MACH-O WRITER
; ===========================================================================

write_macho_binary:
    push rbp
    mov rbp, rsp
    sub rsp, 0x1000     ; buffer for headers
    
    ; Open output file
    mov rax, SYS_open
    lea rdi, [output_name]
    mov rsi, O_WRONLY | O_CREAT | O_TRUNC
    mov rdx, 0755q
    syscall
    
    mov r15, rax        ; save fd
    
    ; Write Mach-O headers
    lea rdi, [rsp]
    call build_macho_headers
    
    ; Write headers
    mov rax, SYS_write
    mov rdi, r15
    lea rsi, [rsp]
    mov rdx, 0x1000
    syscall
    
    ; Write code
    mov rax, SYS_write
    mov rdi, r15
    lea rsi, [output_buffer]
    mov rdx, [output_pos]
    syscall
    
    ; Pad to page boundary
    mov rcx, 0x1000
    mov rax, [output_pos]
    sub rcx, rax
    jz .no_code_padding
    
.pad_code:
    push rcx
    push rax
    xor rax, rax
    push rax
    mov rax, SYS_write
    mov rdi, r15
    mov rsi, rsp
    mov rdx, 1
    syscall
    add rsp, 8
    pop rax
    pop rcx
    loop .pad_code
    
.no_code_padding:
    ; Write strings
    mov rax, SYS_write
    mov rdi, r15
    lea rsi, [string_buffer]
    mov rdx, [string_count]
    syscall
    
    ; Close file
    mov rax, SYS_close
    mov rdi, r15
    syscall
    
    leave
    ret

build_macho_headers:
    push rbp
    mov rbp, rsp
    
    ; Clear buffer
    push rdi
    xor rax, rax
    mov rcx, 0x200
    rep stosq
    pop rdi
    
    ; Mach-O header
    mov dword [rdi], 0xFEEDFACF         ; magic
    mov dword [rdi+4], 0x01000007       ; cputype (x86_64)
    mov dword [rdi+8], 0x00000003       ; cpusubtype
    mov dword [rdi+12], 0x00000002      ; filetype (MH_EXECUTE)
    mov dword [rdi+16], 3               ; ncmds
    mov dword [rdi+20], 0x228           ; sizeofcmds
    mov dword [rdi+24], 0x00200085      ; flags
    mov dword [rdi+28], 0               ; reserved
    
    add rdi, 32
    
    ; LC_SEGMENT_64 __PAGEZERO
    mov dword [rdi], 0x19               ; LC_SEGMENT_64
    mov dword [rdi+4], 72               ; cmdsize
    mov rax, '__PAGEZE'
    mov [rdi+8], rax
    mov rax, 'RO'
    mov [rdi+16], rax
    ; Rest is zeros (vmaddr=0, vmsize=0x100000000, etc)
    mov qword [rdi+32], 0x100000000     ; vmsize
    
    add rdi, 72
    
    ; LC_SEGMENT_64 __TEXT
    mov dword [rdi], 0x19               ; LC_SEGMENT_64
    mov dword [rdi+4], 152              ; cmdsize
    mov rax, '__TEXT'
    mov [rdi+8], rax
    mov qword [rdi+24], 0x100000000     ; vmaddr
    mov qword [rdi+32], 0x2000          ; vmsize
    mov qword [rdi+40], 0               ; fileoff
    mov qword [rdi+48], 0x2000          ; filesize
    mov dword [rdi+56], 7               ; maxprot
    mov dword [rdi+60], 5               ; initprot
    mov dword [rdi+64], 1               ; nsects
    
    add rdi, 72
    
    ; Section __text
    mov rax, '__text'
    mov [rdi], rax
    mov rax, '__TEXT'
    mov [rdi+16], rax
    mov qword [rdi+32], 0x100001000     ; addr
    mov rax, [output_pos]
    mov qword [rdi+40], rax             ; size
    mov dword [rdi+48], 0x1000          ; offset
    mov dword [rdi+52], 4               ; align
    mov dword [rdi+64], 0x80000400      ; flags
    
    add rdi, 80
    
    ; LC_UNIXTHREAD
    mov dword [rdi], 0x5                ; LC_UNIXTHREAD
    mov dword [rdi+4], 184              ; cmdsize
    mov dword [rdi+8], 4                ; flavor
    mov dword [rdi+12], 42              ; count
    
    ; Set RIP to entry point
    mov qword [rdi+16+16*8], 0x100001000
    
    leave
    ret

; ===========================================================================
; LEXER
; ===========================================================================

get_next_token:
    push rbp
    mov rbp, rsp
    
    ; Skip whitespace
    call skip_whitespace
    
    ; Check EOF
    mov rax, [input_pos]
    cmp rax, r14
    jae .eof
    
    ; Clear token buffer
    lea rdi, [token_buffer]
    xor rax, rax
    mov rcx, 32
    rep stosq
    
    ; Get character
    lea rsi, [input_buffer]
    add rsi, [input_pos]
    lea rdi, [token_buffer]
    
    mov al, [rsi]
    
    ; Check for string literal
    cmp al, '"'
    je .string_literal
    
    ; Check for single character tokens
    cmp al, '('
    je .single_char
    cmp al, ')'
    je .single_char
    cmp al, '{'
    je .single_char
    cmp al, '}'
    je .single_char
    cmp al, ';'
    je .single_char
    
    ; Regular token
.regular_token:
    lodsb
    inc qword [input_pos]
    
    ; Check for end of token
    cmp al, ' '
    jbe .done
    cmp al, '('
    je .back_one
    cmp al, ')'
    je .back_one
    cmp al, '{'
    je .back_one
    cmp al, '}'
    je .back_one
    cmp al, ';'
    je .back_one
    
    stosb
    jmp .regular_token
    
.single_char:
    movsb
    inc qword [input_pos]
    jmp .done
    
.string_literal:
    inc rsi
    inc qword [input_pos]
    
.string_loop:
    lodsb
    inc qword [input_pos]
    
    cmp al, '"'
    je .done
    cmp al, 0
    je .done
    
    cmp al, '\'
    je .escape
    
    stosb
    jmp .string_loop
    
.escape:
    lodsb
    inc qword [input_pos]
    
    cmp al, 'n'
    jne .store_escape
    mov al, 10
    
.store_escape:
    stosb
    jmp .string_loop
    
.back_one:
    dec qword [input_pos]
    
.done:
    mov byte [rdi], 0
    mov rax, 1
    leave
    ret
    
.eof:
    xor rax, rax
    leave
    ret

skip_whitespace:
    push rbp
    mov rbp, rsp
    
.loop:
    mov rax, [input_pos]
    cmp rax, r14
    jae .done
    
    lea rsi, [input_buffer]
    add rsi, rax
    mov al, [rsi]
    
    cmp al, ' '
    je .skip
    cmp al, 9       ; tab
    je .skip
    cmp al, 10      ; newline
    je .skip
    cmp al, 13      ; carriage return
    je .skip
    
.done:
    leave
    ret
    
.skip:
    inc qword [input_pos]
    jmp .loop

; ===========================================================================
; UTILITIES
; ===========================================================================

print_string:
    push rbp
    mov rbp, rsp
    push rsi
    
    ; Get length
    mov rdi, rsi
    call string_length
    mov rdx, rax
    
    ; Write
    mov rax, SYS_write
    mov rdi, 1          ; stdout
    pop rsi
    syscall
    
    leave
    ret

string_length:
    push rbp
    mov rbp, rsp
    
    xor rax, rax
.loop:
    cmp byte [rdi + rax], 0
    je .done
    inc rax
    jmp .loop
.done:
    leave
    ret

string_compare:
    push rbp
    mov rbp, rsp
    
.loop:
    mov al, [rdi]
    mov bl, [rsi]
    
    cmp al, bl
    jne .not_equal
    
    test al, al
    jz .equal
    
    inc rdi
    inc rsi
    jmp .loop
    
.equal:
    xor rax, rax
    leave
    ret
    
.not_equal:
    mov rax, 1
    leave
    ret

copy_string:
    push rbp
    mov rbp, rsp
    
    xor rax, rax
.loop:
    mov bl, [rsi + rax]
    mov [rdi + rax], bl
    test bl, bl
    jz .done
    inc rax
    jmp .loop
.done:
    leave
    ret