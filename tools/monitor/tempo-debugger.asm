; Tempo Debugger - Debug running Tempo applications
; Advanced debugging with WCET analysis and real-time inspection
[BITS 64]

section .text
global start

start:
    ; Check arguments
    mov rax, [rsp]       ; argc
    cmp rax, 2
    jl .usage
    
    ; Get target process name/PID
    mov rax, [rsp + 16]  ; argv
    mov rax, [rax + 8]   ; argv[1]
    mov [target_app], rax
    
    ; Initialize debugger
    call init_debugger
    call attach_to_process
    test rax, rax
    jz .attach_failed
    
    ; Main debugging loop
    call debug_main_loop
    
    ; Cleanup
    call detach_from_process
    xor rdi, rdi
    mov rax, 0x2000001
    syscall

.usage:
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel usage_msg]
    mov rdx, usage_len
    syscall
    mov rdi, 1
    jmp .exit

.attach_failed:
    mov rax, 0x2000004
    mov rdi, 2
    lea rsi, [rel attach_error]
    mov rdx, attach_error_len
    syscall
    mov rdi, 1

.exit:
    mov rax, 0x2000001
    syscall

; Initialize debugging environment
init_debugger:
    push rbp
    mov rbp, rsp
    
    ; Setup signal handlers for debugging
    call setup_debug_signals
    
    ; Initialize debugging state
    mov qword [debug_state], DEBUG_INIT
    mov qword [breakpoint_count], 0
    
    ; Clear breakpoint table
    lea rdi, [rel breakpoint_table]
    mov rcx, MAX_BREAKPOINTS * BREAKPOINT_SIZE
    xor al, al
    rep stosb
    
    leave
    ret

; Attach to target Tempo process
attach_to_process:
    push rbp
    mov rbp, rsp
    
    ; Find process by name/PID
    call find_target_process
    test rax, rax
    jz .not_found
    mov [target_pid], rax
    
    ; Attach using ptrace
    mov rax, 0x200001A   ; ptrace
    mov rdi, 16          ; PTRACE_ATTACH
    mov rsi, [target_pid]
    xor rdx, rdx
    xor rcx, rcx
    syscall
    test rax, rax
    js .attach_failed
    
    ; Wait for process to stop
    call wait_for_stop
    
    ; Read process information
    call read_process_info
    
    ; Setup debugging context
    call setup_debug_context
    
    mov rax, 1           ; Success
    leave
    ret

.not_found:
.attach_failed:
    xor rax, rax         ; Failure
    leave
    ret

; Main debugging loop
debug_main_loop:
    push rbp
    mov rbp, rsp
    
    ; Print debugging banner
    call print_debug_banner
    
.main_loop:
    ; Show current state
    call show_debug_state
    
    ; Show prompt
    call show_debug_prompt
    
    ; Read command
    call read_debug_command
    
    ; Process command
    call process_debug_command
    test rax, rax
    jz .main_loop
    
    leave
    ret

; Print debugging banner
print_debug_banner:
    push rbp
    mov rbp, rsp
    
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel debug_banner]
    mov rdx, debug_banner_len
    syscall
    
    ; Show target process info
    call show_target_info
    
    leave
    ret

; Show current debugging state
show_debug_state:
    push rbp
    mov rbp, rsp
    
    ; Show current instruction
    call show_current_instruction
    
    ; Show registers
    call show_registers
    
    ; Show stack
    call show_stack
    
    ; Show WCET status
    call show_wcet_status
    
    ; Show memory regions
    call show_memory_regions
    
    leave
    ret

; Show current instruction being executed
show_current_instruction:
    push rbp
    mov rbp, rsp
    
    ; Get current instruction pointer
    call get_instruction_pointer
    mov [current_ip], rax
    
    ; Read instruction at IP
    call read_instruction_at_ip
    
    ; Disassemble and display
    call disassemble_instruction
    call display_instruction
    
    leave
    ret

; Show processor registers
show_registers:
    push rbp
    mov rbp, rsp
    
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel registers_header]
    mov rdx, registers_header_len
    syscall
    
    ; Read all registers using ptrace
    call read_all_registers
    
    ; Display registers in formatted way
    call display_registers
    
    leave
    ret

; Show stack contents
show_stack:
    push rbp
    mov rbp, rsp
    
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel stack_header]
    mov rdx, stack_header_len
    syscall
    
    ; Read stack memory
    call read_stack_memory
    
    ; Display stack contents
    call display_stack
    
    leave
    ret

; Show WCET analysis status
show_wcet_status:
    push rbp
    mov rbp, rsp
    
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel wcet_header]
    mov rdx, wcet_header_len
    syscall
    
    ; Analyze current WCET status
    call analyze_wcet_status
    
    ; Display WCET information
    call display_wcet_info
    
    leave
    ret

; Process debugging commands
process_debug_command:
    push rbp
    mov rbp, rsp
    
    ; Parse command
    lea rdi, [rel command_buffer]
    call parse_command
    
    ; Execute based on command type
    cmp rax, CMD_CONTINUE
    je .cmd_continue
    cmp rax, CMD_STEP
    je .cmd_step
    cmp rax, CMD_BREAK
    je .cmd_break
    cmp rax, CMD_WATCH
    je .cmd_watch
    cmp rax, CMD_WCET
    je .cmd_wcet
    cmp rax, CMD_MEMORY
    je .cmd_memory
    cmp rax, CMD_QUIT
    je .cmd_quit
    cmp rax, CMD_HELP
    je .cmd_help
    
    ; Unknown command
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel unknown_cmd_msg]
    mov rdx, unknown_cmd_len
    syscall
    jmp .continue_debug

.cmd_continue:
    call debug_continue
    jmp .continue_debug

.cmd_step:
    call debug_step
    jmp .continue_debug

.cmd_break:
    call debug_set_breakpoint
    jmp .continue_debug

.cmd_watch:
    call debug_set_watchpoint
    jmp .continue_debug

.cmd_wcet:
    call debug_wcet_analysis
    jmp .continue_debug

.cmd_memory:
    call debug_memory_dump
    jmp .continue_debug

.cmd_help:
    call show_debug_help
    jmp .continue_debug

.cmd_quit:
    mov rax, 1           ; Exit debugging
    leave
    ret

.continue_debug:
    xor rax, rax         ; Continue debugging
    leave
    ret

; Continue execution
debug_continue:
    push rbp
    mov rbp, rsp
    
    ; Resume process execution
    mov rax, 0x200001A   ; ptrace
    mov rdi, 7           ; PTRACE_CONT
    mov rsi, [target_pid]
    xor rdx, rdx
    xor rcx, rcx
    syscall
    
    ; Wait for next stop
    call wait_for_stop
    
    leave
    ret

; Single step execution
debug_step:
    push rbp
    mov rbp, rsp
    
    ; Single step
    mov rax, 0x200001A   ; ptrace
    mov rdi, 9           ; PTRACE_SINGLESTEP
    mov rsi, [target_pid]
    xor rdx, rdx
    xor rcx, rcx
    syscall
    
    ; Wait for step completion
    call wait_for_stop
    
    leave
    ret

; Set breakpoint
debug_set_breakpoint:
    push rbp
    mov rbp, rsp
    
    ; Parse breakpoint address from command
    call parse_breakpoint_address
    test rax, rax
    jz .invalid_address
    
    ; Add breakpoint
    call add_breakpoint
    
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel breakpoint_set_msg]
    mov rdx, breakpoint_set_len
    syscall
    
.invalid_address:
    leave
    ret

; WCET analysis command
debug_wcet_analysis:
    push rbp
    mov rbp, rsp
    
    ; Perform real-time WCET analysis
    call perform_wcet_analysis
    
    ; Display results
    call display_wcet_analysis
    
    leave
    ret

; Memory dump command
debug_memory_dump:
    push rbp
    mov rbp, rsp
    
    ; Parse memory range
    call parse_memory_range
    
    ; Dump memory contents
    call dump_memory_range
    
    leave
    ret

; Show debugging help
show_debug_help:
    push rbp
    mov rbp, rsp
    
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel debug_help]
    mov rdx, debug_help_len
    syscall
    
    leave
    ret

; Real-time WCET analysis
perform_wcet_analysis:
    push rbp
    mov rbp, rsp
    
    ; Get current execution metrics
    call get_execution_metrics
    
    ; Compare with WCET bounds
    call compare_wcet_bounds
    
    ; Predict future execution time
    call predict_execution_time
    
    ; Check for potential violations
    call check_potential_violations
    
    leave
    ret

; Advanced memory analysis
analyze_memory_usage:
    push rbp
    mov rbp, rsp
    
    ; Scan memory regions
    call scan_memory_regions
    
    ; Detect memory leaks
    call detect_memory_leaks
    
    ; Check for buffer overflows
    call check_buffer_overflows
    
    ; Validate memory access patterns
    call validate_memory_patterns
    
    leave
    ret

; Detach from process
detach_from_process:
    push rbp
    mov rbp, rsp
    
    ; Remove all breakpoints
    call remove_all_breakpoints
    
    ; Detach using ptrace
    mov rax, 0x200001A   ; ptrace
    mov rdi, 17          ; PTRACE_DETACH
    mov rsi, [target_pid]
    xor rdx, rdx
    xor rcx, rcx
    syscall
    
    leave
    ret

section .data

usage_msg: db "Usage: tempo-debugger <process_name_or_pid>", 10
           db "Debug a running Tempo application", 10
usage_len equ $ - usage_msg

attach_error: db "❌ Failed to attach to process", 10
attach_error_len equ $ - attach_error

debug_banner: db "╔══════════════════════════════════════════════════════════════════════════════╗", 10
              db "║                        🐛 TEMPO DEBUGGER v1.0                               ║", 10
              db "║                    Advanced AtomicOS Process Debugging                       ║", 10
              db "╠══════════════════════════════════════════════════════════════════════════════╣", 10
debug_banner_len equ $ - debug_banner

registers_header: db "╔═══ REGISTERS ═══════════════════════════════════════════════════════════════╗", 10
registers_header_len equ $ - registers_header

stack_header: db "╔═══ STACK ═══════════════════════════════════════════════════════════════════╗", 10
stack_header_len equ $ - stack_header

wcet_header: db "╔═══ WCET ANALYSIS ═══════════════════════════════════════════════════════════╗", 10
wcet_header_len equ $ - wcet_header

debug_help: db "Tempo Debugger Commands:", 10
           db "  c, continue    - Continue execution", 10
           db "  s, step        - Single step", 10
           db "  b <addr>       - Set breakpoint at address", 10
           db "  w <addr>       - Set watchpoint on memory", 10
           db "  wcet           - Show WCET analysis", 10
           db "  mem <addr>     - Dump memory at address", 10
           db "  regs           - Show all registers", 10
           db "  stack          - Show stack contents", 10
           db "  help, h        - Show this help", 10
           db "  quit, q        - Quit debugger", 10
debug_help_len equ $ - debug_help

unknown_cmd_msg: db "Unknown command. Type 'help' for available commands.", 10
unknown_cmd_len equ $ - unknown_cmd_msg

breakpoint_set_msg: db "✅ Breakpoint set", 10
breakpoint_set_len equ $ - breakpoint_set_msg

; Command constants
CMD_CONTINUE equ 1
CMD_STEP equ 2
CMD_BREAK equ 3
CMD_WATCH equ 4
CMD_WCET equ 5
CMD_MEMORY equ 6
CMD_QUIT equ 7
CMD_HELP equ 8

; Debug state constants
DEBUG_INIT equ 0
DEBUG_RUNNING equ 1
DEBUG_STOPPED equ 2
DEBUG_BREAKPOINT equ 3

section .bss

; Target process information
target_app: resq 1
target_pid: resq 1
debug_state: resq 1

; Current execution state
current_ip: resq 1
current_sp: resq 1

; Breakpoints
MAX_BREAKPOINTS equ 32
BREAKPOINT_SIZE equ 16
breakpoint_table: resb MAX_BREAKPOINTS * BREAKPOINT_SIZE
breakpoint_count: resq 1

; Command processing
command_buffer: resb 256

; Memory buffers
instruction_buffer: resb 64
register_buffer: resb 1024
stack_buffer: resb 2048
memory_dump_buffer: resb 4096