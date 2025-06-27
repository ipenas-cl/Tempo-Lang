; Tempo Logs - Intelligent Log Analysis
; Advanced log viewing with filtering, analysis, and insights
[BITS 64]

section .text
global start

start:
    ; Check arguments
    mov rax, [rsp]       ; argc
    cmp rax, 2
    jl .usage
    
    ; Get target application name
    mov rax, [rsp + 16]  ; argv
    mov rax, [rax + 8]   ; argv[1]
    mov [target_app], rax
    
    ; Initialize log system
    call init_log_system
    
    ; Find application logs
    call find_app_logs
    test rax, rax
    jz .no_logs_found
    
    ; Analyze log patterns
    call analyze_log_patterns
    
    ; Display intelligent log viewer
    call display_log_viewer
    
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

.no_logs_found:
    mov rax, 0x2000004
    mov rdi, 2
    lea rsi, [rel no_logs_msg]
    mov rdx, no_logs_len
    syscall
    mov rdi, 1

.exit:
    mov rax, 0x2000001
    syscall

; Initialize log analysis system
init_log_system:
    push rbp
    mov rbp, rsp
    
    ; Clear log statistics
    call clear_log_stats
    
    ; Initialize filters
    call init_log_filters
    
    ; Setup terminal for interactive mode
    call setup_terminal
    
    leave
    ret

; Find logs for target application
find_app_logs:
    push rbp
    mov rbp, rsp
    
    ; Build log file paths
    call build_log_paths
    
    ; Check system logs
    call check_system_logs
    
    ; Check application-specific logs
    call check_app_logs
    
    ; Check syslog
    call check_syslog
    
    ; Check tempo-specific logs
    call check_tempo_logs
    
    ; Return number of log sources found
    mov rax, [log_sources_count]
    leave
    ret

; Analyze log patterns and extract insights
analyze_log_patterns:
    push rbp
    mov rbp, rsp
    
    ; Scan for error patterns
    call scan_error_patterns
    
    ; Analyze performance metrics
    call analyze_performance_logs
    
    ; Detect anomalies
    call detect_log_anomalies
    
    ; Extract WCET information
    call extract_wcet_info
    
    ; Build timeline
    call build_log_timeline
    
    ; Generate insights
    call generate_log_insights
    
    leave
    ret

; Display interactive log viewer
display_log_viewer:
    push rbp
    mov rbp, rsp
    
    ; Clear screen and show header
    call clear_screen
    call show_log_header
    
.viewer_loop:
    ; Display current view
    call display_current_view
    
    ; Show status bar
    call show_status_bar
    
    ; Handle user input
    call handle_log_input
    test rax, rax
    jz .viewer_loop
    
    ; Cleanup
    call cleanup_log_viewer
    
    leave
    ret

; Show log viewer header
show_log_header:
    push rbp
    mov rbp, rsp
    
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel log_header]
    mov rdx, log_header_len
    syscall
    
    ; Show application name
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel app_name_prefix]
    mov rdx, app_name_prefix_len
    syscall
    
    mov rax, 0x2000004
    mov rdi, 1
    mov rsi, [target_app]
    mov rdx, 32              ; Max app name length
    syscall
    
    ; Show log statistics
    call show_log_statistics
    
    leave
    ret

; Display current log view
display_current_view:
    push rbp
    mov rbp, rsp
    
    ; Check current view mode
    mov rax, [view_mode]
    cmp rax, VIEW_RECENT
    je .show_recent
    cmp rax, VIEW_ERRORS
    je .show_errors
    cmp rax, VIEW_PERFORMANCE
    je .show_performance
    cmp rax, VIEW_TIMELINE
    je .show_timeline
    cmp rax, VIEW_INSIGHTS
    je .show_insights
    
    ; Default to recent logs
.show_recent:
    call display_recent_logs
    jmp .view_done
    
.show_errors:
    call display_error_logs
    jmp .view_done
    
.show_performance:
    call display_performance_logs
    jmp .view_done
    
.show_timeline:
    call display_timeline_view
    jmp .view_done
    
.show_insights:
    call display_insights_view
    
.view_done:
    leave
    ret

; Display recent logs with intelligent highlighting
display_recent_logs:
    push rbp
    mov rbp, rsp
    
    ; Move to log display area
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel cursor_logs]
    mov rdx, cursor_logs_len
    syscall
    
    ; Read recent log entries
    call read_recent_entries
    
    ; Display with intelligent highlighting
    call display_highlighted_logs
    
    leave
    ret

; Display error logs with context
display_error_logs:
    push rbp
    mov rbp, rsp
    
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel error_logs_header]
    mov rdx, error_logs_header_len
    syscall
    
    ; Show error summary
    call show_error_summary
    
    ; Display detailed errors
    call display_detailed_errors
    
    leave
    ret

; Display performance-related logs
display_performance_logs:
    push rbp
    mov rbp, rsp
    
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel perf_logs_header]
    mov rdx, perf_logs_header_len
    syscall
    
    ; Show WCET analysis
    call show_wcet_analysis
    
    ; Show timing information
    call show_timing_info
    
    ; Show resource usage
    call show_resource_usage
    
    leave
    ret

; Display timeline view
display_timeline_view:
    push rbp
    mov rbp, rsp
    
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel timeline_header]
    mov rdx, timeline_header_len
    syscall
    
    ; Draw timeline graph
    call draw_timeline_graph
    
    ; Show event markers
    call show_event_markers
    
    leave
    ret

; Display insights and recommendations
display_insights_view:
    push rbp
    mov rbp, rsp
    
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel insights_header]
    mov rdx, insights_header_len
    syscall
    
    ; Show automated insights
    call show_automated_insights
    
    ; Show recommendations
    call show_log_recommendations
    
    ; Show patterns detected
    call show_detected_patterns
    
    leave
    ret

; Scan for error patterns in logs
scan_error_patterns:
    push rbp
    mov rbp, rsp
    
    ; Reset error counters
    mov qword [error_count], 0
    mov qword [warning_count], 0
    mov qword [critical_count], 0
    
    ; Open each log source
    mov rcx, [log_sources_count]
    test rcx, rcx
    jz .no_sources
    
    lea rdi, [rel log_sources]
    
.scan_loop:
    push rcx
    push rdi
    
    ; Open log file
    call open_log_file
    test rax, rax
    js .next_source
    mov [current_log_fd], rax
    
    ; Scan for patterns
    call scan_file_patterns
    
    ; Close file
    mov rax, 0x2000006   ; close
    mov rdi, [current_log_fd]
    syscall
    
.next_source:
    pop rdi
    pop rcx
    add rdi, LOG_SOURCE_SIZE
    loop .scan_loop
    
.no_sources:
    leave
    ret

; Extract WCET information from logs
extract_wcet_info:
    push rbp
    mov rbp, rsp
    
    ; Look for WCET-related log entries
    call scan_wcet_entries
    
    ; Parse timing information
    call parse_timing_data
    
    ; Calculate statistics
    call calculate_wcet_stats
    
    ; Detect violations
    call detect_wcet_violations
    
    leave
    ret

; Generate intelligent insights
generate_log_insights:
    push rbp
    mov rbp, rsp
    
    ; Analyze error frequency
    call analyze_error_frequency
    
    ; Detect performance trends
    call detect_performance_trends
    
    ; Find correlations
    call find_log_correlations
    
    ; Generate recommendations
    call generate_recommendations
    
    leave
    ret

; Handle user input in log viewer
handle_log_input:
    push rbp
    mov rbp, rsp
    
    ; Read key press
    mov rax, 0x2000003   ; read
    mov rdi, 0           ; stdin
    lea rsi, [rel input_key]
    mov rdx, 1
    syscall
    
    test rax, rax
    jz .no_input
    
    movzx rax, byte [input_key]
    
    ; Process key commands
    cmp al, 'q'
    je .quit
    cmp al, 'Q'
    je .quit
    cmp al, 'r'
    je .view_recent
    cmp al, 'e'
    je .view_errors
    cmp al, 'p'
    je .view_performance
    cmp al, 't'
    je .view_timeline
    cmp al, 'i'
    je .view_insights
    cmp al, 'f'
    je .toggle_filter
    cmp al, '/'
    je .search_logs
    cmp al, 27           ; ESC
    je .quit
    
.no_input:
    xor rax, rax         ; Continue
    leave
    ret
    
.quit:
    mov rax, 1           ; Exit
    leave
    ret
    
.view_recent:
    mov qword [view_mode], VIEW_RECENT
    xor rax, rax
    leave
    ret
    
.view_errors:
    mov qword [view_mode], VIEW_ERRORS
    xor rax, rax
    leave
    ret
    
.view_performance:
    mov qword [view_mode], VIEW_PERFORMANCE
    xor rax, rax
    leave
    ret
    
.view_timeline:
    mov qword [view_mode], VIEW_TIMELINE
    xor rax, rax
    leave
    ret
    
.view_insights:
    mov qword [view_mode], VIEW_INSIGHTS
    xor rax, rax
    leave
    ret
    
.toggle_filter:
    call toggle_log_filter
    xor rax, rax
    leave
    ret
    
.search_logs:
    call start_log_search
    xor rax, rax
    leave
    ret

; Show status bar with navigation help
show_status_bar:
    push rbp
    mov rbp, rsp
    
    ; Move to bottom of screen
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel cursor_bottom]
    mov rdx, cursor_bottom_len
    syscall
    
    ; Show navigation help
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel status_bar]
    mov rdx, status_bar_len
    syscall
    
    leave
    ret

section .data

usage_msg: db "Usage: tempo logs <application_name>", 10
           db "Intelligent log analysis for Tempo applications", 10
           db "", 10
           db "Examples:", 10
           db "  tempo logs tempo.app       # View logs for tempo.app", 10
           db "  tempo logs payment-service # View logs for payment-service", 10
usage_len equ $ - usage_msg

no_logs_msg: db "❌ No logs found for the specified application", 10
no_logs_len equ $ - no_logs_msg

log_header: db "╔══════════════════════════════════════════════════════════════════════════════╗", 10
           db "║                        📋 TEMPO LOGS - Intelligent Analysis                 ║", 10
           db "╠══════════════════════════════════════════════════════════════════════════════╣", 10
log_header_len equ $ - log_header

app_name_prefix: db "║ Application: "
app_name_prefix_len equ $ - app_name_prefix

error_logs_header: db "╔═══ ERROR ANALYSIS ═══════════════════════════════════════════════════════════╗", 10
error_logs_header_len equ $ - error_logs_header

perf_logs_header: db "╔═══ PERFORMANCE ANALYSIS ═════════════════════════════════════════════════════╗", 10
perf_logs_header_len equ $ - perf_logs_header

timeline_header: db "╔═══ TIMELINE VIEW ═══════════════════════════════════════════════════════════╗", 10
timeline_header_len equ $ - timeline_header

insights_header: db "╔═══ INTELLIGENT INSIGHTS ═══════════════════════════════════════════════════╗", 10
insights_header_len equ $ - insights_header

status_bar: db "╚══════════════════════════════════════════════════════════════════════════════╝", 10
           db " [r]ecent [e]rrors [p]erformance [t]imeline [i]nsights [f]ilter [/]search [q]uit", 10
status_bar_len equ $ - status_bar

; Screen positioning
cursor_logs: db 27, "[7;1H"      ; Position for log content
cursor_logs_len equ $ - cursor_logs

cursor_bottom: db 27, "[23;1H"   ; Bottom status bar
cursor_bottom_len equ $ - cursor_bottom

clear_seq: db 27, "[2J", 27, "[H"  ; Clear screen
clear_seq_len equ $ - clear_seq

; View modes
VIEW_RECENT equ 0
VIEW_ERRORS equ 1
VIEW_PERFORMANCE equ 2
VIEW_TIMELINE equ 3
VIEW_INSIGHTS equ 4

section .bss

; Application data
target_app: resq 1
view_mode: resq 1

; Log sources
MAX_LOG_SOURCES equ 16
LOG_SOURCE_SIZE equ 256
log_sources: resb MAX_LOG_SOURCES * LOG_SOURCE_SIZE
log_sources_count: resq 1

; Statistics
error_count: resq 1
warning_count: resq 1
critical_count: resq 1
total_entries: resq 1

; Current state
current_log_fd: resq 1
input_key: resb 1

; Buffers
log_buffer: resb 8192
search_buffer: resb 256
insights_buffer: resb 4096