; Tempo Alert System - Intelligent SRE Notifications
; Send smart alerts to SRE team with context and recommendations
[BITS 64]

section .text
global start

start:
    ; Check arguments
    mov rax, [rsp]       ; argc
    cmp rax, 2
    jl .usage
    
    ; Get alert message
    mov rax, [rsp + 16]  ; argv
    mov rax, [rax + 8]   ; argv[1]
    mov [alert_message], rax
    
    ; Initialize alert system
    call init_alert_system
    
    ; Collect system context
    call collect_system_context
    
    ; Analyze alert severity
    call analyze_alert_severity
    
    ; Generate intelligent alert
    call generate_intelligent_alert
    
    ; Send alert through multiple channels
    call send_multi_channel_alert
    
    ; Log alert for audit trail
    call log_alert_audit
    
    ; Show confirmation
    call show_alert_confirmation
    
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
    mov rax, 0x2000001
    syscall

; Initialize alert system
init_alert_system:
    push rbp
    mov rbp, rsp
    
    ; Load alert configuration
    call load_alert_config
    
    ; Initialize alert channels
    call init_alert_channels
    
    ; Get current timestamp
    call get_current_timestamp
    mov [alert_timestamp], rax
    
    ; Generate alert ID
    call generate_alert_id
    
    leave
    ret

; Collect system context for intelligent alerting
collect_system_context:
    push rbp
    mov rbp, rsp
    
    ; Get system load
    call get_system_load
    
    ; Get running Tempo processes
    call get_tempo_processes_status
    
    ; Get memory usage
    call get_memory_status
    
    ; Get network status
    call get_network_status
    
    ; Get WCET violations if any
    call get_wcet_violations
    
    ; Get error logs
    call get_recent_errors
    
    leave
    ret

; Analyze alert severity based on context
analyze_alert_severity:
    push rbp
    mov rbp, rsp
    
    ; Default to INFO level
    mov qword [alert_severity], SEVERITY_INFO
    
    ; Check for critical keywords
    call check_critical_keywords
    test rax, rax
    jz .check_warning
    mov qword [alert_severity], SEVERITY_CRITICAL
    jmp .severity_done
    
.check_warning:
    call check_warning_keywords
    test rax, rax
    jz .check_wcet
    mov qword [alert_severity], SEVERITY_WARNING
    jmp .severity_done
    
.check_wcet:
    ; Check for WCET violations
    cmp qword [wcet_violation_count], 0
    je .check_load
    mov qword [alert_severity], SEVERITY_HIGH
    jmp .severity_done
    
.check_load:
    ; Check system load
    mov rax, [system_load]
    cmp rax, 80              ; 80% load threshold
    jb .severity_done
    mov qword [alert_severity], SEVERITY_WARNING
    
.severity_done:
    leave
    ret

; Check for critical keywords in alert message
check_critical_keywords:
    push rbp
    mov rbp, rsp
    
    lea rdi, [alert_message]
    lea rsi, [rel critical_keywords]
    call check_keywords_in_message
    
    leave
    ret

; Generate intelligent alert with context and recommendations
generate_intelligent_alert:
    push rbp
    mov rbp, rsp
    
    ; Start building alert
    lea rdi, [rel alert_buffer]
    
    ; Add alert header
    call build_alert_header
    
    ; Add original message
    call add_original_message
    
    ; Add system context
    call add_system_context
    
    ; Add severity assessment
    call add_severity_assessment
    
    ; Add recommendations
    call add_intelligent_recommendations
    
    ; Add related alerts
    call add_related_alerts
    
    ; Add troubleshooting links
    call add_troubleshooting_links
    
    leave
    ret

; Build alert header with metadata
build_alert_header:
    push rbp
    mov rbp, rsp
    
    ; Add severity emoji and level
    mov rax, [alert_severity]
    cmp rax, SEVERITY_CRITICAL
    je .critical_header
    cmp rax, SEVERITY_HIGH
    je .high_header
    cmp rax, SEVERITY_WARNING
    je .warning_header
    jmp .info_header
    
.critical_header:
    lea rsi, [rel critical_emoji]
    call append_to_alert
    jmp .add_timestamp
    
.high_header:
    lea rsi, [rel high_emoji]
    call append_to_alert
    jmp .add_timestamp
    
.warning_header:
    lea rsi, [rel warning_emoji]
    call append_to_alert
    jmp .add_timestamp
    
.info_header:
    lea rsi, [rel info_emoji]
    call append_to_alert
    
.add_timestamp:
    ; Add timestamp
    lea rsi, [rel timestamp_prefix]
    call append_to_alert
    call format_timestamp
    call append_to_alert
    
    ; Add alert ID
    lea rsi, [rel alert_id_prefix]
    call append_to_alert
    lea rsi, [rel alert_id]
    call append_to_alert
    
    leave
    ret

; Add intelligent recommendations based on context
add_intelligent_recommendations:
    push rbp
    mov rbp, rsp
    
    lea rsi, [rel recommendations_header]
    call append_to_alert
    
    ; Check if WCET violations exist
    cmp qword [wcet_violation_count], 0
    je .check_memory
    lea rsi, [rel wcet_recommendation]
    call append_to_alert
    
.check_memory:
    ; Check memory usage
    mov rax, [memory_usage_percent]
    cmp rax, 85
    jb .check_load
    lea rsi, [rel memory_recommendation]
    call append_to_alert
    
.check_load:
    ; Check system load
    mov rax, [system_load]
    cmp rax, 80
    jb .check_processes
    lea rsi, [rel load_recommendation]
    call append_to_alert
    
.check_processes:
    ; Check if any processes are failing
    cmp qword [failing_processes], 0
    je .add_general
    lea rsi, [rel process_recommendation]
    call append_to_alert
    
.add_general:
    ; Add general troubleshooting
    lea rsi, [rel general_recommendation]
    call append_to_alert
    
    leave
    ret

; Send alert through multiple channels
send_multi_channel_alert:
    push rbp
    mov rbp, rsp
    
    ; Send to console (always)
    call send_console_alert
    
    ; Send to syslog
    call send_syslog_alert
    
    ; Send to webhook if configured
    call send_webhook_alert
    
    ; Send to email if configured
    call send_email_alert
    
    ; Send to Slack if configured
    call send_slack_alert
    
    ; Send to PagerDuty if critical
    mov rax, [alert_severity]
    cmp rax, SEVERITY_CRITICAL
    jne .no_pagerduty
    call send_pagerduty_alert
    
.no_pagerduty:
    leave
    ret

; Send alert to console
send_console_alert:
    push rbp
    mov rbp, rsp
    
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel alert_buffer]
    mov rdx, [alert_buffer_len]
    syscall
    
    leave
    ret

; Send alert to syslog
send_syslog_alert:
    push rbp
    mov rbp, rsp
    
    ; Open syslog connection
    mov rax, 0x2000005   ; open
    lea rdi, [rel syslog_path]
    mov rsi, 1           ; O_WRONLY
    syscall
    test rax, rax
    js .syslog_error
    mov [syslog_fd], rax
    
    ; Format syslog message
    call format_syslog_message
    
    ; Write to syslog
    mov rax, 0x2000004   ; write
    mov rdi, [syslog_fd]
    lea rsi, [rel syslog_buffer]
    mov rdx, [syslog_buffer_len]
    syscall
    
    ; Close syslog
    mov rax, 0x2000006   ; close
    mov rdi, [syslog_fd]
    syscall
    
.syslog_error:
    leave
    ret

; Send webhook alert
send_webhook_alert:
    push rbp
    mov rbp, rsp
    
    ; Check if webhook URL is configured
    cmp qword [webhook_url], 0
    je .no_webhook
    
    ; Create HTTP POST request
    call create_webhook_request
    
    ; Send HTTP request
    call send_http_request
    
.no_webhook:
    leave
    ret

; Send Slack alert
send_slack_alert:
    push rbp
    mov rbp, rsp
    
    ; Check if Slack webhook is configured
    cmp qword [slack_webhook], 0
    je .no_slack
    
    ; Format Slack message
    call format_slack_message
    
    ; Send to Slack
    call send_slack_webhook
    
.no_slack:
    leave
    ret

; Send PagerDuty alert for critical issues
send_pagerduty_alert:
    push rbp
    mov rbp, rsp
    
    ; Check if PagerDuty is configured
    cmp qword [pagerduty_key], 0
    je .no_pagerduty
    
    ; Create PagerDuty incident
    call create_pagerduty_incident
    
.no_pagerduty:
    leave
    ret

; Log alert for audit trail
log_alert_audit:
    push rbp
    mov rbp, rsp
    
    ; Open alert log file
    mov rax, 0x2000005   ; open
    lea rdi, [rel alert_log_path]
    mov rsi, 0x601       ; O_CREAT | O_WRONLY | O_APPEND
    mov rdx, 0644
    syscall
    test rax, rax
    js .log_error
    mov [log_fd], rax
    
    ; Write audit entry
    call format_audit_entry
    mov rax, 0x2000004   ; write
    mov rdi, [log_fd]
    lea rsi, [rel audit_buffer]
    mov rdx, [audit_buffer_len]
    syscall
    
    ; Close log file
    mov rax, 0x2000006   ; close
    mov rdi, [log_fd]
    syscall
    
.log_error:
    leave
    ret

; Show alert confirmation
show_alert_confirmation:
    push rbp
    mov rbp, rsp
    
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel confirmation_msg]
    mov rdx, confirmation_len
    syscall
    
    ; Show alert ID
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel alert_id]
    mov rdx, 16
    syscall
    
    mov rax, 0x2000004
    mov rdi, 1
    lea rsi, [rel newline]
    mov rdx, 1
    syscall
    
    leave
    ret

section .data

usage_msg: db "Usage: tempo alert <message>", 10
           db "Send intelligent alert to SRE team", 10
           db "", 10
           db "Examples:", 10
           db "  tempo alert 'WCET violation in payment service'", 10
           db "  tempo alert 'High memory usage detected'", 10
           db "  tempo alert 'Critical: Database connection failed'", 10
usage_len equ $ - usage_msg

; Alert severity levels
SEVERITY_INFO equ 0
SEVERITY_WARNING equ 1
SEVERITY_HIGH equ 2
SEVERITY_CRITICAL equ 3

; Severity emojis and labels
critical_emoji: db "🚨 CRITICAL", 0
high_emoji: db "⚠️  HIGH", 0
warning_emoji: db "⚠️  WARNING", 0
info_emoji: db "ℹ️  INFO", 0

; Alert components
timestamp_prefix: db " | Time: ", 0
alert_id_prefix: db " | ID: ", 0
newline: db 10

; Keywords for severity detection
critical_keywords: db "critical,fatal,emergency,down,failed,crash,panic,dead", 0
warning_keywords: db "warning,high,slow,timeout,retry,degraded", 0

; Recommendations
recommendations_header: db 10, "🔧 INTELLIGENT RECOMMENDATIONS:", 10, 0

wcet_recommendation: db "• WCET violations detected - Check @wcet annotations and optimize critical paths", 10, 0

memory_recommendation: db "• High memory usage - Consider garbage collection or memory leak investigation", 10, 0

load_recommendation: db "• High system load - Scale horizontally or optimize resource usage", 10, 0

process_recommendation: db "• Process failures detected - Check logs and restart failed services", 10, 0

general_recommendation: db "• Run 'tempo monitor' for detailed system analysis", 10
                       db "• Check recent logs with 'tempo logs <app>'", 10
                       db "• Use 'tempo debug <app>' for detailed debugging", 10, 0

; Paths and configurations
syslog_path: db "/dev/log", 0
alert_log_path: db "/var/log/tempo-alerts.log", 0

confirmation_msg: db "✅ Alert sent successfully! Alert ID: ", 0

section .bss

; Alert data
alert_message: resq 1
alert_timestamp: resq 1
alert_severity: resq 1
alert_id: resb 17        ; 16 chars + null

; System context
system_load: resq 1
memory_usage_percent: resq 1
wcet_violation_count: resq 1
failing_processes: resq 1

; Configuration
webhook_url: resq 1
slack_webhook: resq 1
pagerduty_key: resq 1

; File descriptors
syslog_fd: resq 1
log_fd: resq 1

; Buffers
alert_buffer: resb 4096
alert_buffer_len: resq 1
syslog_buffer: resb 2048
syslog_buffer_len: resq 1
audit_buffer: resb 1024
audit_buffer_len: resq 1