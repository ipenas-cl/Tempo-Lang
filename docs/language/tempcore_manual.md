<div align="center">

╔═════╦═════╦═════╗  
║ 🛡️  ║ ⚖️  ║ ⚡  ║  
║  C  ║  E  ║  G  ║  
╚═════╩═════╩═════╝  
╔═════════════════╗  
║ wcet [T∞] bound ║  
╚═════════════════╝  

**Author:** Ignacio Peña Sepúlveda  
**Date:** June 25, 2025

</div>

---

# ChronosCore Technical Reference Manual

## Table of Contents
1. [Introduction](#introduction)
2. [Architecture Overview](#architecture-overview)
3. [Instruction Set Architecture](#instruction-set-architecture)
4. [Pipeline Design](#pipeline-design)
5. [Memory System](#memory-system)
6. [Custom Extensions](#custom-extensions)
7. [Programming Model](#programming-model)
8. [Timing Analysis](#timing-analysis)
9. [Assembly Examples](#assembly-examples)

## Introduction

ChronosCore is a deterministic processor architecture specifically designed for the Chronos programming language and AtomicOS. The primary design goal is to provide predictable, deterministic execution timing while maintaining reasonable performance for real-time and safety-critical applications.

### Key Features
- **Deterministic Execution**: Every instruction has a fixed, known cycle count
- **No Speculation**: In-order pipeline with no branch prediction or speculative execution
- **Scratchpad Memory**: Fast, deterministic memory access
- **Custom Instructions**: Specialized operations for Chronos patterns
- **Timing Guarantees**: Hardware support for deadline monitoring and WCET enforcement

## Architecture Overview

### Register Architecture
- **32 General Purpose Registers** (R0-R31), 64-bit width
  - R0 is hardwired to zero
  - R1 (SP) - Stack Pointer
  - R2 (FP) - Frame Pointer
  - R3 (LR) - Link Register
- **Special Purpose Registers**:
  - PC - Program Counter
  - SR - Status Register
  - TCR - Timing Control Register
  - DCR - Deadline Control Register
  - ECR - Error Control Register
  - CYCLE_LOW/HIGH - 64-bit cycle counter
  - WCET - Worst-Case Execution Time register
  - DEADLINE - Current deadline register
  - ATOMIC_CTX - Atomic context register
  - TEMPO_FLAGS - Chronos-specific flags

### Instruction Format
All instructions are 32-bit fixed width:

```
Standard Format:
[31:24] [23:19] [18:14] [13:9] [8:6] [5:0]
OPCODE    RD      RS1     RS2   FUNC  IMM6

Immediate Format:
[31:24] [23:19] [18:14] [13:0]
OPCODE    RD      RS1     IMM14
```

## Instruction Set Architecture

### Arithmetic/Logic Instructions (1 cycle)
| Mnemonic | Opcode | Operation | Description |
|----------|---------|-----------|-------------|
| ADD      | 0x01    | rd = rs1 + rs2 | Add registers |
| SUB      | 0x02    | rd = rs1 - rs2 | Subtract registers |
| AND      | 0x03    | rd = rs1 & rs2 | Bitwise AND |
| OR       | 0x04    | rd = rs1 \| rs2 | Bitwise OR |
| XOR      | 0x05    | rd = rs1 ^ rs2 | Bitwise XOR |
| SHL      | 0x06    | rd = rs1 << rs2 | Shift left |
| SHR      | 0x07    | rd = rs1 >> rs2 | Shift right |
| NOT      | 0x08    | rd = ~rs1 | Bitwise NOT |

### Immediate Instructions (1 cycle)
| Mnemonic | Opcode | Operation | Description |
|----------|---------|-----------|-------------|
| ADDI     | 0x11    | rd = rs1 + imm | Add immediate |
| SUBI     | 0x12    | rd = rs1 - imm | Subtract immediate |
| ANDI     | 0x13    | rd = rs1 & imm | AND immediate |
| ORI      | 0x14    | rd = rs1 \| imm | OR immediate |
| XORI     | 0x15    | rd = rs1 ^ imm | XOR immediate |
| LDI      | 0x16    | rd = imm | Load immediate |

### Memory Instructions
| Mnemonic | Opcode | Cycles | Operation | Description |
|----------|---------|---------|-----------|-------------|
| LD       | 0x20    | 2 | rd = mem[rs1 + imm] | Load from memory |
| ST       | 0x21    | 2 | mem[rs1 + imm] = rs2 | Store to memory |
| LDX      | 0x22    | 2 | rd = mem[rs1 + rs2] | Indexed load |
| STX      | 0x23    | 2 | mem[rs1 + rs2] = rd | Indexed store |
| LDSP     | 0x24    | 1 | rd = sp_mem[rs1 + imm] | Load from scratchpad |
| STSP     | 0x25    | 1 | sp_mem[rs1 + imm] = rs2 | Store to scratchpad |

### Control Flow Instructions (2 cycles)
| Mnemonic | Opcode | Operation | Description |
|----------|---------|-----------|-------------|
| JMP      | 0x30    | PC = rs1 | Jump to register |
| JMPI     | 0x31    | PC = PC + imm | Jump immediate |
| BEQ      | 0x32    | if (rs1 == rs2) PC += imm | Branch if equal |
| BNE      | 0x33    | if (rs1 != rs2) PC += imm | Branch if not equal |
| BLT      | 0x34    | if (rs1 < rs2) PC += imm | Branch if less than |
| BGE      | 0x35    | if (rs1 >= rs2) PC += imm | Branch if greater/equal |
| CALL     | 0x36    | LR = PC + 4; PC = rs1 | Function call |
| RET      | 0x37    | PC = LR | Return from function |

### Chronos-Specific Instructions (1 cycle)
| Mnemonic | Opcode | Description |
|----------|---------|-------------|
| ATOMIC_BEGIN | 0x40 | Begin atomic block |
| ATOMIC_END | 0x41 | End atomic block |
| SET_DEADLINE | 0x42 | Set deadline register |
| CHECK_TIME | 0x43 | Check if within deadline |
| GET_CYCLE | 0x44 | Get cycle counter |
| SYNC_POINT | 0x45 | Synchronization barrier |

## Pipeline Design

ChronosCore uses a classic 5-stage in-order pipeline:

1. **IF (Instruction Fetch)**: Fetch instruction from memory (2 cycles)
2. **ID (Instruction Decode)**: Decode instruction and read registers
3. **EX (Execute)**: Perform ALU operation or address calculation
4. **MEM (Memory Access)**: Access memory if needed
5. **WB (Write Back)**: Write result to register file

### Pipeline Characteristics
- **No Branch Prediction**: All branches take 2 cycles
- **No Speculation**: Pipeline stalls on hazards
- **Deterministic Forwarding**: Data forwarding paths are fixed
- **In-Order Execution**: Instructions complete in program order

### Hazard Handling
- **RAW (Read-After-Write)**: Handled by forwarding or stalling
- **WAW (Write-After-Write)**: Not possible in in-order pipeline
- **WAR (Write-After-Read)**: Not possible in in-order pipeline

## Memory System

### Memory Map
```
0x00000000 - 0x0000FFFF : Scratchpad Memory (64KB, 1-cycle access)
0x00010000 - 0x00FFFFFF : Code Region (16MB - 64KB)
0x01000000 - 0x3FFFFFFF : Data Region (1GB - 16MB)
0x40000000 - 0x7FFFFFFF : Memory-Mapped I/O (1GB)
0x80000000 - 0xFFFFFFFF : Invalid/Reserved
```

### Scratchpad Memory
- 64KB of fast, single-cycle access memory
- Ideal for stack, frequently accessed data, and real-time buffers
- No cache coherency issues
- Predictable access timing

### Main Memory
- Always 2-cycle access in deterministic mode
- Optional direct-mapped cache (disabled by default)
- Write-through policy when cache is enabled
- No prefetching or speculative accesses

## Custom Extensions

### Atomic Operations (1 cycle)
- **ATOMIC_SWAP**: Atomic register-memory swap
- **ATOMIC_ADD**: Atomic add to memory
- **ATOMIC_CAS**: Compare-and-swap
- **ATOMIC_FENCE**: Memory fence

### Channel Operations (2 cycles)
- **CHAN_SEND**: Send data on channel
- **CHAN_RECV**: Receive data from channel
- **CHAN_SELECT**: Select on multiple channels
- **CHAN_READY**: Check channel readiness

### Task Management (1 cycle)
- **TASK_YIELD**: Yield to scheduler
- **TASK_SPAWN**: Create new task
- **TASK_JOIN**: Wait for task completion
- **TASK_ID**: Get current task ID

### Vector Operations (2 cycles)
- Operate on 4x64-bit values simultaneously
- **VEC_ADD**: Vector addition
- **VEC_MUL**: Vector multiplication
- **VEC_DOT**: Dot product
- **VEC_LOAD/STORE**: Vector memory operations

## Programming Model

### Calling Convention
- **Arguments**: R4-R11 (first 8 arguments)
- **Return Values**: R4-R5 (up to 2 return values)
- **Callee-Saved**: R16-R27
- **Caller-Saved**: R4-R15
- **Stack Growth**: Downward (decreasing addresses)

### Atomic Blocks
```assembly
    ATOMIC_BEGIN
    ; Critical section code
    ; No interrupts or context switches
    ATOMIC_END
```

### Deadline Management
```assembly
    LDI r1, 1000        ; 1000 cycle deadline
    SET_DEADLINE r1     ; Set deadline
    ; Time-critical code
    CHECK_TIME r2       ; r2 = 1 if within deadline
    BEQ r2, r0, timeout ; Branch if deadline missed
```

## Timing Analysis

### Instruction Timing
- Arithmetic/Logic: 1 cycle
- Memory (Main): 2 cycles
- Memory (Scratchpad): 1 cycle
- Branches: 2 cycles (always)
- Extensions: 1-4 cycles (documented per instruction)

### WCET Calculation
```
WCET = Σ(instruction_count[i] × cycle_count[i])
```

### Pipeline Stalls
- Load-use hazard: 1 cycle stall
- Branch: 1 cycle penalty (included in 2-cycle cost)
- No other stall conditions

## Assembly Examples

### Basic Arithmetic
```assembly
    ; Calculate (a + b) * c
    LD r1, 0(sp)      ; Load a (2 cycles)
    LD r2, 8(sp)      ; Load b (2 cycles)
    LD r3, 16(sp)     ; Load c (2 cycles)
    ADD r4, r1, r2    ; r4 = a + b (1 cycle)
    MUL r5, r4, r3    ; r5 = (a + b) * c (1 cycle)
    ST r5, 24(sp)     ; Store result (2 cycles)
    ; Total: 10 cycles (guaranteed)
```

### Scratchpad Usage
```assembly
    ; Fast buffer access
    LDI r1, 0x100     ; Buffer offset (1 cycle)
    LDSP r2, 0(r1)    ; Load from scratchpad (1 cycle)
    ADDI r2, r2, 1    ; Increment (1 cycle)
    STSP r2, 0(r1)    ; Store to scratchpad (1 cycle)
    ; Total: 4 cycles (guaranteed)
```

### Channel Communication
```assembly
    ; Send on channel
    LDI r1, 1         ; Channel ID (1 cycle)
    LDI r2, 42        ; Data to send (1 cycle)
    CHAN_SEND r1, r2  ; Send data (2 cycles)
    ; Total: 4 cycles
    
    ; Receive from channel
    LDI r1, 1         ; Channel ID (1 cycle)
    CHAN_RECV r2, r1  ; Receive data (2 cycles)
    ; Total: 3 cycles
```

### Atomic Operations
```assembly
    ; Atomic increment
    LDI r1, counter   ; Address (1 cycle)
    LDI r2, 1         ; Increment value (1 cycle)
    ATOMIC_ADD r3, r1, r2 ; r3 = old value (1 cycle)
    ; Total: 3 cycles
```

## Hardware Implementation Notes

### Critical Path
- ALU operations: Single cycle at up to 1 GHz
- Memory access: Pipelined for 2-cycle latency
- No complex operations (divide, floating-point)

### Area Estimates
- Core logic: ~50K gates
- Register file: 32 × 64 bits
- Scratchpad: 64KB SRAM
- Pipeline registers: ~500 flip-flops

### Power Characteristics
- No speculative execution reduces power waste
- Deterministic behavior enables precise power management
- Clock gating for unused pipeline stages

## Conclusion

ChronosCore provides a deterministic, predictable execution environment ideal for real-time systems and the Chronos programming language. By eliminating sources of non-determinism and providing hardware support for common patterns, it enables both safety and performance for critical applications.