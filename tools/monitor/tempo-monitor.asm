; Tempo Monitor - Observabilidad Inteligente
; Similar a htop pero específico para aplicaciones Tempo
[BITS 64]

section .text
global start

start:
    ; Clear screen and setup monitoring
    call clear_screen
    call init_monitor
    call draw_header
    
main_loop:
    ; Refresh system information
    call scan_tempo_processes
    call collect_metrics
    call check_wcet_violations
    call draw_interface
    
    ; Handle user input
    call handle_input
    test rax, rax
    jz main_loop
    
    ; Cleanup and exit
    call cleanup_monitor
    xor rdi, rdi
    mov rax, 0x2000001
    syscall

; Initialize monitoring system
init_monitor:
    push rbp
    mov rbp, rsp
    
    ; Setup terminal for interactive mode
    mov rax, 0x2000054   ; ioctl
    mov rdi, 0           ; stdin
    mov rsi, 0x8004741A  ; TIOCGETA
    lea rdx, [rel term_orig]
    syscall
    
    ; Set raw mode
    mov rax, 0x2000054   ; ioctl
    mov rdi, 0           ; stdin
    mov rsi, 0x8004741B  ; TIOCSETA
    lea rdx, [rel term_raw]
    syscall
    
    ; Initialize process table
    mov qword [process_count], 0
    
    leave
    ret

; Clear screen and reset cursor
clear_screen:
    push rbp
    mov rbp, rsp
    
    mov rax, 0x2000004   ; write
    mov rdi, 1
    lea rsi, [rel clear_seq]
    mov rdx, clear_seq_len
    syscall
    
    leave
    ret

; Draw monitor header
draw_header:
    push rbp
    mov rbp, rsp
    
    ; Print header with system info
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel header]
    mov rdx, header_len
    syscall
    
    ; Print current time
    call print_current_time
    
    ; Print system load
    call print_system_load
    
    leave
    ret

; Scan for running Tempo processes
scan_tempo_processes:
    push rbp
    mov rbp, rsp
    
    ; Reset process count
    mov qword [process_count], 0
    
    ; Open /proc directory to scan processes
    mov rax, 0x2000005   ; open
    lea rdi, [rel proc_dir]
    mov rsi, 0           ; O_RDONLY
    syscall
    test rax, rax
    js .scan_error
    mov [proc_fd], rax
    
    ; Read directory entries
.read_loop:
    mov rax, 0x2000003   ; read
    mov rdi, [proc_fd]
    lea rsi, [rel dir_buffer]
    mov rdx, 4096
    syscall
    test rax, rax
    jz .scan_done
    
    ; Parse directory entries for Tempo processes
    call parse_proc_entries
    jmp .read_loop
    
.scan_done:
    mov rax, 0x2000006   ; close
    mov rdi, [proc_fd]
    syscall
    
.scan_error:
    leave
    ret

; Parse /proc entries to find Tempo applications
parse_proc_entries:
    push rbp
    mov rbp, rsp
    
    lea rdi, [rel dir_buffer]
    mov rsi, rax         ; bytes read
    
.parse_loop:
    test rsi, rsi
    jz .parse_done
    
    ; Check if entry is a PID directory
    call is_numeric_dir
    test rax, rax
    jz .next_entry
    
    ; Check if process is a Tempo app
    call check_tempo_process
    test rax, rax
    jz .next_entry
    
    ; Add to process list
    call add_tempo_process
    
.next_entry:
    ; Move to next directory entry
    add rdi, 19          ; Fixed size for simplicity
    sub rsi, 19
    jmp .parse_loop
    
.parse_done:
    leave
    ret

; Check if a process is a Tempo application
check_tempo_process:
    push rbp
    mov rbp, rsp
    
    ; Build path to /proc/PID/cmdline
    lea rax, [rel proc_cmdline_path]
    call build_proc_path
    
    ; Open cmdline file
    mov rax, 0x2000005   ; open
    lea rdi, [rel proc_cmdline_path]
    mov rsi, 0           ; O_RDONLY
    syscall
    test rax, rax
    js .not_tempo
    mov [cmdline_fd], rax
    
    ; Read command line
    mov rax, 0x2000003   ; read
    mov rdi, [cmdline_fd]
    lea rsi, [rel cmdline_buffer]
    mov rdx, 1024
    syscall
    
    ; Close file
    mov rdx, rax         ; save bytes read
    mov rax, 0x2000006   ; close
    mov rdi, [cmdline_fd]
    syscall
    
    ; Check if contains "tempo.app"
    lea rdi, [rel cmdline_buffer]
    lea rsi, [rel tempo_app_signature]
    call string_contains
    
    leave
    ret
    
.not_tempo:
    xor rax, rax
    leave
    ret

; Add Tempo process to monitoring list
add_tempo_process:
    push rbp
    mov rbp, rsp
    
    ; Get current process count
    mov rax, [process_count]
    cmp rax, MAX_PROCESSES
    jge .list_full
    
    ; Calculate offset in process table
    mov rdx, PROCESS_ENTRY_SIZE
    mul rdx
    lea rdi, [rel process_table + rax]
    
    ; Store process information
    call store_process_info
    
    ; Increment process count
    inc qword [process_count]
    
.list_full:
    leave
    ret

; Collect performance metrics for Tempo processes
collect_metrics:
    push rbp
    mov rbp, rsp
    
    mov rcx, [process_count]
    test rcx, rcx
    jz .no_processes
    
    lea rdi, [rel process_table]
    
.metric_loop:
    push rcx
    push rdi
    
    ; Collect CPU usage
    call collect_cpu_usage
    
    ; Collect memory usage
    call collect_memory_usage
    
    ; Collect WCET metrics
    call collect_wcet_metrics
    
    ; Collect I/O metrics
    call collect_io_metrics
    
    pop rdi
    pop rcx
    add rdi, PROCESS_ENTRY_SIZE
    loop .metric_loop
    
.no_processes:
    leave
    ret

; Check for WCET violations
check_wcet_violations:
    push rbp
    mov rbp, rsp
    
    mov rcx, [process_count]
    test rcx, rcx
    jz .no_violations
    
    lea rdi, [rel process_table]
    
.check_loop:
    push rcx
    push rdi
    
    ; Get process WCET bound
    mov rax, [rdi + PROCESS_WCET_BOUND]
    test rax, rax
    jz .no_bound
    
    ; Get actual execution time
    mov rdx, [rdi + PROCESS_ACTUAL_TIME]
    
    ; Check for violation
    cmp rdx, rax
    jle .no_violation
    
    ; WCET violation detected
    call handle_wcet_violation
    
.no_violation:
.no_bound:
    pop rdi
    pop rcx
    add rdi, PROCESS_ENTRY_SIZE
    loop .check_loop
    
.no_violations:
    leave
    ret

; Handle WCET violation
handle_wcet_violation:
    push rbp
    mov rbp, rsp
    
    ; Log violation
    call log_wcet_violation
    
    ; Send alert to SRE if configured
    call send_sre_alert
    
    ; Optionally terminate violating process
    call handle_violation_policy
    
    leave
    ret

; Draw the main monitoring interface
draw_interface:
    push rbp
    mov rbp, rsp
    
    ; Move cursor to process table area
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel cursor_pos_table]
    mov rdx, cursor_pos_table_len
    syscall
    
    ; Draw process table header
    call draw_table_header
    
    ; Draw process entries
    call draw_process_entries
    
    ; Draw bottom status bar
    call draw_status_bar
    
    ; Draw real-time metrics
    call draw_metrics_panel
    
    leave
    ret

; Draw process table header
draw_table_header:
    push rbp
    mov rbp, rsp
    
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel table_header]
    mov rdx, table_header_len
    syscall
    
    leave
    ret

; Draw individual process entries
draw_process_entries:
    push rbp
    mov rbp, rsp
    
    mov rcx, [process_count]
    test rcx, rcx
    jz .no_processes
    
    lea rdi, [rel process_table]
    mov rbx, 1           ; Line number
    
.draw_loop:
    push rcx
    push rdi
    push rbx
    
    ; Format and draw process line
    call format_process_line
    call draw_process_line
    
    pop rbx
    pop rdi
    pop rcx
    
    inc rbx
    add rdi, PROCESS_ENTRY_SIZE
    loop .draw_loop
    
.no_processes:
    ; Show "No Tempo processes running"
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel no_processes_msg]
    mov rdx, no_processes_msg_len
    syscall
    
    leave
    ret

; Draw status bar with system information
draw_status_bar:
    push rbp
    mov rbp, rsp
    
    ; Move to bottom of screen
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel cursor_pos_bottom]
    mov rdx, cursor_pos_bottom_len
    syscall
    
    ; Draw status information
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel status_bar]
    mov rdx, status_bar_len
    syscall
    
    leave
    ret

; Draw real-time metrics panel
draw_metrics_panel:
    push rbp
    mov rbp, rsp
    
    ; Draw system load average
    call draw_load_average
    
    ; Draw memory usage
    call draw_memory_usage
    
    ; Draw network I/O
    call draw_network_io
    
    ; Draw WCET compliance status
    call draw_wcet_status
    
    leave
    ret

; Handle keyboard input
handle_input:
    push rbp
    mov rbp, rsp
    
    ; Read one character (non-blocking)
    mov rax, 0x2000003   ; read
    mov rdi, 0           ; stdin
    lea rsi, [rel input_char]
    mov rdx, 1
    syscall
    
    ; Check if any input available
    test rax, rax
    jz .no_input
    
    ; Process the key
    movzx rax, byte [input_char]
    
    cmp al, 'q'
    je .quit
    cmp al, 'Q'
    je .quit
    cmp al, 'r'
    je .restart_selected
    cmp al, 's'
    je .stop_selected
    cmp al, 'd'
    je .debug_selected
    cmp al, 'a'
    je .send_alert
    cmp al, 27           ; ESC key
    je .quit
    
.no_input:
    xor rax, rax         ; Continue monitoring
    leave
    ret
    
.quit:
    mov rax, 1           ; Exit flag
    leave
    ret
    
.restart_selected:
    call restart_selected_process
    xor rax, rax
    leave
    ret
    
.stop_selected:
    call stop_selected_process
    xor rax, rax
    leave
    ret
    
.debug_selected:
    call debug_selected_process
    xor rax, rax
    leave
    ret
    
.send_alert:
    call prompt_send_alert
    xor rax, rax
    leave
    ret

; Restart selected Tempo process
restart_selected_process:
    push rbp
    mov rbp, rsp
    
    ; Get selected process PID
    mov rdi, [selected_process]
    test rdi, rdi
    jz .no_selection
    
    ; Send SIGTERM first
    mov rax, 0x2000025   ; kill
    mov rsi, 15          ; SIGTERM
    syscall
    
    ; Wait a moment
    call short_sleep
    
    ; Restart the process
    call restart_tempo_app
    
.no_selection:
    leave
    ret

; Stop selected Tempo process
stop_selected_process:
    push rbp
    mov rbp, rsp
    
    ; Get selected process PID
    mov rdi, [selected_process]
    test rdi, rdi
    jz .no_selection
    
    ; Send SIGTERM
    mov rax, 0x2000025   ; kill
    mov rsi, 15          ; SIGTERM
    syscall
    
.no_selection:
    leave
    ret

; Debug selected Tempo process
debug_selected_process:
    push rbp
    mov rbp, rsp
    
    ; Launch debugger for selected process
    call launch_tempo_debugger
    
    leave
    ret

; Cleanup monitor before exit
cleanup_monitor:
    push rbp
    mov rbp, rsp
    
    ; Restore terminal settings
    mov rax, 0x2000054   ; ioctl
    mov rdi, 0           ; stdin
    mov rsi, 0x8004741B  ; TIOCSETA
    lea rdx, [rel term_orig]
    syscall
    
    ; Clear screen
    call clear_screen
    
    leave
    ret

; Helper functions
is_numeric_dir:
    ; Check if directory name is all digits (PID)
    push rbp
    mov rbp, rsp
    ; Implementation would check each character
    mov rax, 1  ; Assume yes for now
    leave
    ret

string_contains:
    ; Check if string contains substring
    push rbp
    mov rbp, rsp
    ; Implementation would do proper string search
    mov rax, 1  ; Assume found for now
    leave
    ret

short_sleep:
    ; Sleep for short duration
    push rbp
    mov rbp, rsp
    
    mov rax, 0x200001D   ; nanosleep
    lea rdi, [rel short_delay]
    xor rsi, rsi
    syscall
    
    leave
    ret

section .data

; Screen control sequences
clear_seq: db 27, "[2J", 27, "[H"  ; Clear screen and home cursor
clear_seq_len equ $ - clear_seq

cursor_pos_table: db 27, "[6;1H"   ; Position for process table
cursor_pos_table_len equ $ - cursor_pos_table

cursor_pos_bottom: db 27, "[24;1H" ; Bottom of screen
cursor_pos_bottom_len equ $ - cursor_pos_bottom

; Monitor header
header: db "╔══════════════════════════════════════════════════════════════════════════════╗", 10
        db "║                     🚀 TEMPO MONITOR - Observabilidad Inteligente           ║", 10
        db "║                           AtomicOS Process Monitor                           ║", 10
        db "╠══════════════════════════════════════════════════════════════════════════════╣", 10
header_len equ $ - header

; Process table header
table_header: db "╠════╦════════════════╦═══════╦═══════╦══════════╦══════════╦═══════════════╣", 10
              db "║PID ║ NAME           ║  CPU% ║  MEM% ║   WCET   ║  STATUS  ║    ALERTS     ║", 10
              db "╠════╬════════════════╬═══════╬═══════╬══════════╬══════════╬═══════════════╣", 10
table_header_len equ $ - table_header

; Status bar
status_bar: db "╚══════════════════════════════════════════════════════════════════════════════╝", 10
           db " [q]uit  [r]estart  [s]top  [d]ebug  [a]lert  ↑↓ select process", 10
status_bar_len equ $ - status_bar

; Messages
no_processes_msg: db "║              No Tempo applications currently running                        ║", 10
no_processes_msg_len equ $ - no_processes_msg

; File paths and signatures
proc_dir: db "/proc", 0
tempo_app_signature: db "tempo.app", 0
proc_cmdline_path: times 256 db 0

; Terminal settings
term_orig: times 64 db 0
term_raw: times 64 db 0

; Timing
short_delay: dq 0, 100000000  ; 0.1 seconds

section .bss

; Process monitoring
MAX_PROCESSES equ 64
PROCESS_ENTRY_SIZE equ 256

process_table: resb MAX_PROCESSES * PROCESS_ENTRY_SIZE
process_count: resq 1
selected_process: resq 1

; Process entry offsets
PROCESS_PID equ 0
PROCESS_NAME equ 8
PROCESS_CPU_USAGE equ 64
PROCESS_MEM_USAGE equ 72
PROCESS_WCET_BOUND equ 80
PROCESS_ACTUAL_TIME equ 88
PROCESS_STATUS equ 96

; File descriptors
proc_fd: resq 1
cmdline_fd: resq 1

; Buffers
dir_buffer: resb 4096
cmdline_buffer: resb 1024
input_char: resb 1