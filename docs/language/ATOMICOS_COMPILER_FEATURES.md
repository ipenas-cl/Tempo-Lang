# Características del Compilador Tempo para AtomicOS

## 🏗️ FUNDAMENTOS BÁSICOS

### 1. Control de Hardware de Bajo Nivel

```tempo
// Acceso directo a puertos I/O
@inline fn inb(port: u16) -> u8 wcet: 10_cycles {
    @asm("inb %dx, %al", in("dx") port, out("al") result)
}

@inline fn outb(port: u16, value: u8) wcet: 12_cycles {
    @asm("outb %al, %dx", in("al") value, in("dx") port)
}

@inline fn inw(port: u16) -> u16 wcet: 10_cycles {
    @asm("inw %dx, %ax", in("dx") port, out("ax") result)
}

@inline fn outw(port: u16, value: u16) wcet: 12_cycles {
    @asm("outw %ax, %dx", in("ax") value, in("dx") port)
}

@inline fn inl(port: u16) -> u32 wcet: 10_cycles {
    @asm("inl %dx, %eax", in("dx") port, out("eax") result)
}

@inline fn outl(port: u16, value: u32) wcet: 12_cycles {
    @asm("outl %eax, %dx", in("eax") value, in("dx") port)
}

// Registros de control del CPU
@inline fn read_cr0() -> u64 wcet: 5_cycles {
    @asm("movq %cr0, %rax", out("rax") result)
}

@inline fn write_cr0(value: u64) wcet: 8_cycles {
    @asm("movq %rax, %cr0", in("rax") value)
}

@inline fn read_cr2() -> u64 wcet: 5_cycles {
    @asm("movq %cr2, %rax", out("rax") result)
}

@inline fn read_cr3() -> u64 wcet: 5_cycles {
    @asm("movq %cr3, %rax", out("rax") result)
}

@inline fn write_cr3(pml4: u64) wcet: 15_cycles {
    @asm("movq %rax, %cr3", in("rax") pml4)
}

@inline fn read_cr4() -> u64 wcet: 5_cycles {
    @asm("movq %cr4, %rax", out("rax") result)
}

@inline fn write_cr4(value: u64) wcet: 8_cycles {
    @asm("movq %rax, %cr4", in("rax") value)
}

// Model Specific Registers
@inline fn read_msr(msr: u32) -> u64 wcet: 50_cycles {
    @asm("rdmsr", 
         in("ecx") msr, 
         out("eax") low, 
         out("edx") high)
    (high as u64) << 32 | (low as u64)
}

@inline fn write_msr(msr: u32, value: u64) wcet: 50_cycles {
    let low = value as u32;
    let high = (value >> 32) as u32;
    @asm("wrmsr", 
         in("ecx") msr, 
         in("eax") low, 
         in("edx") high)
}

// Control de interrupciones
@inline fn enable_interrupts() wcet: 3_cycles {
    @asm("sti")
}

@inline fn disable_interrupts() wcet: 3_cycles {
    @asm("cli")
}

@inline fn halt() wcet: 1_cycle {
    @asm("hlt")
}

@inline fn pause() wcet: 1_cycle {
    @asm("pause")
}

// Control de cache
@inline fn wbinvd() wcet: 1000_cycles {  // Cache writeback + invalidate
    @asm("wbinvd")
}

@inline fn invd() wcet: 500_cycles {     // Cache invalidate
    @asm("invd")
}

@inline fn clflush(addr: ptr<u8>) wcet: 100_cycles {
    @asm("clflush (%rax)", in("rax") addr)
}
```

### 2. Inline Assembly Completo

```tempo
// Assembly inline básico
fn get_rsp() -> u64 wcet: 2_cycles {
    @asm("movq %rsp, %rax", out("rax") result)
}

// Assembly con inputs/outputs múltiples
fn atomic_add(addr: ptr<u64>, value: u64) -> u64 wcet: 50_cycles {
    @asm("lock xaddq %rsi, (%rdi)",
         in("rdi") addr,
         in("rsi") value,
         out("rax") old_value)
}

// Assembly con memory constraints
fn copy_memory_optimized(dest: ptr<u8>, src: ptr<u8>, count: u64) wcet: count * 2_cycles {
    @asm("rep movsb",
         in("rdi") dest,
         in("rsi") src,
         in("rcx") count,
         memory_write)
}

// Assembly con side effects explícitos
fn set_page_table(pml4: u64) wcet: 50_cycles {
    @asm("movq %rax, %cr3
          movq %cr3, %rax",
         in("rax") pml4,
         clobber("memory"))  // Invalidates TLB
}

// Assembly naked functions (bootloader)
@naked fn boot_entry_16bit() -> never {
    @asm("
        cli
        xorw %ax, %ax
        movw %ax, %ds
        movw %ax, %es
        movw %ax, %ss
        movw $0x7C00, %sp
        
        # Load GDT
        lgdt gdt_descriptor
        
        # Enter protected mode
        movl %cr0, %eax
        orl $1, %eax
        movl %eax, %cr0
        
        ljmp $0x08, $protected_mode_entry
    ")
}
```

### 3. Control de Memory Layout

```tempo
// Secciones específicas para kernel
@section(".boot")      // Bootloader code (loaded at 0x7C00)
@align(512)           // Sector alignment
fn bootloader_main() -> never {
    // Boot code here
}

@section(".text")      // Normal kernel code  
@align(16)            // Cache line alignment
fn kernel_main() -> never {
    // Kernel entry point
}

@section(".data")      // Initialized global data
@align(8)
static mut KERNEL_HEAP_START: u64 = 0x200000;

@section(".bss")       // Uninitialized data (zeroed)
@align(4096)          // Page alignment
static mut PAGE_TABLES: [u64; 512 * 512] = [0; 512 * 512];

@section(".rodata")    // Read-only data
@align(16)
static INTERRUPT_VECTORS: [u64; 256] = generate_vectors!();

// Ubicación específica en memoria
@address(0x7C00)       // Real mode bootloader location
@section(".boot")
fn real_mode_entry() -> never {
    // Bootloader at fixed address
}

@address(0x100000)     // Kernel at 1MB
@section(".kernel")
fn kernel_entry() -> never {
    // Kernel at fixed address
}

// Control de linker layout
@link_section = ".kernel_stack"
@align(4096)
static mut KERNEL_STACK: [u8; 0x100000] = [0; 0x100000];  // 1MB stack

// Variables en segmentos específicos
@thread_local           // Thread-local storage
static mut CURRENT_TASK: ptr<Task> = null;

@percpu                // Per-CPU variable
static mut CPU_ID: u32 = 0;
```

## 🔄 BOOTLOADER

### 4. Cambios de Modo CPU

```tempo
// Estructuras para mode switching
#[repr(C)]
#[packed]
struct GDTDescriptor {
    limit: u16,
    base: u64,
}

#[repr(C)]
#[packed]
struct GDTEntry {
    limit_low: u16,
    base_low: u16,
    base_middle: u8,
    access: u8,
    granularity: u8,
    base_high: u8,
}

// Real mode (16-bit) -> Protected mode (32-bit)
@naked @section(".boot16")
fn real_mode_start() -> never wcet: 1000_cycles {
    @asm("
        cli
        
        # Setup segments
        xorw %ax, %ax
        movw %ax, %ds
        movw %ax, %es
        movw %ax, %ss
        movw $0x7C00, %sp
        
        # Enable A20 line
        inb $0x92, %al
        orb $2, %al
        outb %al, $0x92
        
        # Load GDT
        lgdt gdt_descriptor
        
        # Enter protected mode
        movl %cr0, %eax
        orl $1, %eax
        movl %eax, %cr0
        
        # Far jump to protected mode
        ljmp $0x08, $protected_mode
    ")
}

// Protected mode (32-bit) -> Long mode (64-bit)
@naked @section(".boot32")
fn protected_mode() -> never wcet: 2000_cycles {
    @asm("
        # Setup data segments
        movw $0x10, %ax
        movw %ax, %ds
        movw %ax, %es
        movw %ax, %fs
        movw %ax, %gs
        movw %ax, %ss
        
        # Setup page tables for long mode
        movl $pml4, %edi
        movl %edi, %cr3
        
        # Clear page tables
        xorl %eax, %eax
        movl $4096, %ecx
        rep stosl
        
        # Setup PML4[0] -> PDPT
        movl $pdpt, %eax
        orl $3, %eax          # Present + Writable
        movl %eax, pml4
        
        # Setup PDPT[0] -> PD  
        movl $pd, %eax
        orl $3, %eax
        movl %eax, pdpt
        
        # Setup PD[0] -> 2MB page
        movl $0x000083, %eax  # 2MB page, Present + Writable
        movl %eax, pd
        
        # Enable PAE
        movl %cr4, %eax
        orl $0x20, %eax
        movl %eax, %cr4
        
        # Enable long mode in EFER MSR
        movl $0xC0000080, %ecx
        rdmsr
        orl $0x100, %eax      # Set LME bit
        wrmsr
        
        # Enable paging (activates long mode)
        movl %cr0, %eax
        orl $0x80000000, %eax
        movl %eax, %cr0
        
        # Far jump to 64-bit code
        ljmp $0x08, $long_mode
    ")
}

@naked @section(".boot64")
fn long_mode() -> never wcet: 500_cycles {
    @asm("
        # Setup data segments for 64-bit
        movw $0x10, %ax
        movw %ax, %ds
        movw %ax, %es
        movw %ax, %fs
        movw %ax, %gs
        movw %ax, %ss
        
        # Setup stack
        movq $kernel_stack_top, %rsp
        
        # Jump to kernel main
        jmp kernel_main
    ")
}
```

### 5. Estructuras Hardware Packed

```tempo
// Descriptor tables - MUST be exact layout
#[repr(C)]
#[packed]
struct GDTEntry {
    limit_low: u16,      // Bits 0-15 of limit
    base_low: u16,       // Bits 0-15 of base
    base_middle: u8,     // Bits 16-23 of base
    access: u8,          // Access flags
    granularity: u8,     // Granularity + high limit
    base_high: u8,       // Bits 24-31 of base
}  // Total: exactly 8 bytes

#[repr(C)]
#[packed]
struct IDTEntry {
    offset_low: u16,     // Bits 0-15 of handler address
    selector: u16,       // Code segment selector
    ist: u8,             // Interrupt Stack Table index
    type_attr: u8,       // Type and attributes
    offset_mid: u16,     // Bits 16-31 of handler address
    offset_high: u32,    // Bits 32-63 of handler address
    zero: u32,           // Reserved, must be zero
}  // Total: exactly 16 bytes

#[repr(C)]
#[packed]
struct TSS {
    reserved1: u32,
    rsp0: u64,           // Stack pointer for ring 0
    rsp1: u64,           // Stack pointer for ring 1
    rsp2: u64,           // Stack pointer for ring 2
    reserved2: u64,
    ist1: u64,           // Interrupt Stack Table 1
    ist2: u64,           // Interrupt Stack Table 2
    ist3: u64,           // Interrupt Stack Table 3
    ist4: u64,           // Interrupt Stack Table 4
    ist5: u64,           // Interrupt Stack Table 5
    ist6: u64,           // Interrupt Stack Table 6
    ist7: u64,           // Interrupt Stack Table 7
    reserved3: u64,
    reserved4: u16,
    iomap_base: u16,     // I/O permission bitmap offset
}

// Page table entries con bit-level control
#[repr(transparent)]
struct PageTableEntry(u64);

impl PageTableEntry {
    @inline fn new() -> Self wcet: 2_cycles {
        PageTableEntry(0)
    }
    
    @inline fn set_present(&mut self, present: bool) wcet: 5_cycles {
        if present {
            self.0 |= 1;
        } else {
            self.0 &= !1;
        }
    }
    
    @inline fn set_writable(&mut self, writable: bool) wcet: 5_cycles {
        if writable {
            self.0 |= 2;
        } else {
            self.0 &= !2;
        }
    }
    
    @inline fn set_user(&mut self, user: bool) wcet: 5_cycles {
        if user {
            self.0 |= 4;
        } else {
            self.0 &= !4;
        }
    }
    
    @inline fn set_address(&mut self, addr: u64) wcet: 8_cycles {
        self.0 = (self.0 & 0xFFF) | (addr & 0xFFFFFFFFF000);
    }
    
    @inline fn address(&self) -> u64 wcet: 3_cycles {
        self.0 & 0xFFFFFFFFF000
    }
}
```

## 🧠 KERNEL CORE

### 6. Gestión de Interrupciones

```tempo
// Interrupt frame automaticamente preservada por hardware
#[repr(C)]
struct InterruptFrame {
    rip: u64,
    cs: u64,
    rflags: u64,
    rsp: u64,
    ss: u64,
}

// Handler de interrupción que preserva estado completo
@interrupt
fn keyboard_handler(frame: ptr<InterruptFrame>) wcet: 1000_cycles {
    // Automáticamente preserva todos los registros
    
    let scancode = inb(0x60);
    handle_key(scancode);
    
    // Send EOI to PIC
    outb(0x20, 0x20);
    
    // Registros automáticamente restaurados + iretq
}

// Exception handler con error code
@interrupt
fn page_fault_handler(frame: ptr<InterruptFrame>, error_code: u64) wcet: 5000_cycles {
    let fault_addr = read_cr2();
    
    // Analyze error code
    let present = (error_code & 1) == 0;
    let write = (error_code & 2) != 0;
    let user = (error_code & 4) != 0;
    let reserved = (error_code & 8) != 0;
    let instruction = (error_code & 16) != 0;
    
    if !present {
        handle_page_not_present(fault_addr, write, user);
    } else if write {
        handle_write_protection_violation(fault_addr, user);
    } else {
        kernel_panic("Unexpected page fault");
    }
}

// Double fault handler (critical)
@interrupt
fn double_fault_handler(frame: ptr<InterruptFrame>, error_code: u64) -> never {
    // Double fault = unrecoverable
    kernel_panic("Double fault occurred");
}

// Setup IDT en runtime
fn setup_idt() wcet: 10000_cycles {
    // IDT con 256 entradas
    static mut IDT: [IDTEntry; 256] = [IDTEntry::new(); 256];
    
    // Setup handlers
    IDT[0] = IDTEntry::new(divide_error_handler as u64, 0x08, 0, 0x8E);
    IDT[8] = IDTEntry::new(double_fault_handler as u64, 0x08, 0, 0x8E);
    IDT[13] = IDTEntry::new(general_protection_handler as u64, 0x08, 0, 0x8E);
    IDT[14] = IDTEntry::new(page_fault_handler as u64, 0x08, 0, 0x8E);
    IDT[33] = IDTEntry::new(keyboard_handler as u64, 0x08, 0, 0x8E);
    
    let idt_ptr = IDTDescriptor {
        limit: (256 * 16 - 1) as u16,
        base: IDT.as_ptr() as u64,
    };
    
    @asm("lidt (%rax)", in("rax") &idt_ptr);
}
```

### 7. Manejo de Memoria Virtual

```tempo
// Page table hierarchy
static mut PML4: [PageTableEntry; 512] = [PageTableEntry::new(); 512];
static mut PDPT: [[PageTableEntry; 512]; 4] = [[PageTableEntry::new(); 512]; 4];
static mut PD: [[[PageTableEntry; 512]; 512]; 4] = [[[PageTableEntry::new(); 512]; 512]; 4];

// Memory mapping functions
fn map_page(virt: u64, phys: u64, flags: u64) -> Result<(), MapError> wcet: 1000_cycles {
    let pml4_index = (virt >> 39) & 0x1FF;
    let pdpt_index = (virt >> 30) & 0x1FF;
    let pd_index = (virt >> 21) & 0x1FF;
    let pt_index = (virt >> 12) & 0x1FF;
    
    // Ensure PDPT exists
    if !PML4[pml4_index].present() {
        let pdpt_phys = allocate_page()?;
        PML4[pml4_index].set_address(pdpt_phys);
        PML4[pml4_index].set_present(true);
        PML4[pml4_index].set_writable(true);
    }
    
    // Map 2MB page in PD
    let mut pd_entry = &mut PD[pml4_index][pdpt_index][pd_index];
    pd_entry.set_address(phys);
    pd_entry.set_present(true);
    pd_entry.set_writable((flags & PAGE_WRITABLE) != 0);
    pd_entry.set_user((flags & PAGE_USER) != 0);
    pd_entry.0 |= PAGE_SIZE_2MB;  // 2MB page flag
    
    // Invalidate TLB
    @asm("invlpg (%rax)", in("rax") virt);
    
    Ok(())
}

// Memory allocator con pools fijos
const POOL_4K: usize = 0;
const POOL_64K: usize = 1;
const POOL_1M: usize = 2;
const POOL_16M: usize = 3;

struct MemoryPool {
    blocks: ptr<u8>,
    free_list: ptr<FreeBlock>,
    block_size: usize,
    block_count: usize,
}

struct FreeBlock {
    next: ptr<FreeBlock>,
}

static mut MEMORY_POOLS: [MemoryPool; 4] = [
    MemoryPool::new(0x200000, 4096, 1024),    // 4KB pool
    MemoryPool::new(0x600000, 65536, 64),     // 64KB pool  
    MemoryPool::new(0xA00000, 1048576, 16),   // 1MB pool
    MemoryPool::new(0x1A00000, 16777216, 4),  // 16MB pool
];

fn alloc_deterministic(size: usize) -> Result<ptr<u8>, AllocError> wcet: 100_cycles {
    let pool_index = if size <= 4096 { POOL_4K }
                    else if size <= 65536 { POOL_64K }
                    else if size <= 1048576 { POOL_1M }
                    else if size <= 16777216 { POOL_16M }
                    else { return Err(AllocError::TooLarge); };
    
    let pool = &mut MEMORY_POOLS[pool_index];
    
    if pool.free_list == null {
        return Err(AllocError::OutOfMemory);
    }
    
    let block = pool.free_list;
    pool.free_list = (*block).next;
    
    Ok(block as ptr<u8>)
}

fn free_deterministic(ptr: ptr<u8>, size: usize) wcet: 50_cycles {
    let pool_index = if size <= 4096 { POOL_4K }
                    else if size <= 65536 { POOL_64K }
                    else if size <= 1048576 { POOL_1M }
                    else if size <= 16777216 { POOL_16M }
                    else { return; };
    
    let pool = &mut MEMORY_POOLS[pool_index];
    let block = ptr as ptr<FreeBlock>;
    
    (*block).next = pool.free_list;
    pool.free_list = block;
}
```

### 8. Operaciones Atómicas para Concurrencia

```tempo
// Operaciones lock-free con memory ordering
@inline fn atomic_load(addr: ptr<u64>, ordering: MemoryOrdering) -> u64 wcet: 10_cycles {
    match ordering {
        MemoryOrdering::Relaxed => @asm("movq (%rdi), %rax", in("rdi") addr, out("rax") result),
        MemoryOrdering::Acquire => {
            let result = @asm("movq (%rdi), %rax", in("rdi") addr, out("rax") result);
            @asm("lfence");  // Load fence
            result
        },
        MemoryOrdering::SeqCst => {
            @asm("mfence");  // Full fence before
            let result = @asm("movq (%rdi), %rax", in("rdi") addr, out("rax") result);
            @asm("mfence");  // Full fence after
            result
        },
    }
}

@inline fn atomic_store(addr: ptr<u64>, value: u64, ordering: MemoryOrdering) wcet: 15_cycles {
    match ordering {
        MemoryOrdering::Relaxed => @asm("movq %rsi, (%rdi)", in("rdi") addr, in("rsi") value),
        MemoryOrdering::Release => {
            @asm("sfence");  // Store fence
            @asm("movq %rsi, (%rdi)", in("rdi") addr, in("rsi") value);
        },
        MemoryOrdering::SeqCst => {
            @asm("mfence");  // Full fence before
            @asm("movq %rsi, (%rdi)", in("rdi") addr, in("rsi") value);
            @asm("mfence");  // Full fence after
        },
    }
}

@inline fn atomic_compare_exchange(addr: ptr<u64>, expected: u64, new: u64) -> (u64, bool) wcet: 50_cycles {
    @asm("lock cmpxchgq %rdx, (%rdi)",
         in("rdi") addr,
         in("rax") expected,
         in("rdx") new,
         out("rax") actual,
         clobber("cc"))
    (actual, actual == expected)
}

@inline fn atomic_fetch_add(addr: ptr<u64>, value: u64) -> u64 wcet: 50_cycles {
    @asm("lock xaddq %rsi, (%rdi)",
         in("rdi") addr,
         inout("rsi") value,
         memory_readwrite)
}

@inline fn atomic_fetch_and(addr: ptr<u64>, mask: u64) -> u64 wcet: 60_cycles {
    loop {
        let old = atomic_load(addr, MemoryOrdering::Relaxed);
        let new = old & mask;
        let (actual, success) = atomic_compare_exchange(addr, old, new);
        if success {
            return old;
        }
        pause();  // Reduce bus contention
    }
}

// Spinlock determinístico
struct SpinLock {
    locked: atomic<bool>,
}

impl SpinLock {
    @inline fn new() -> Self {
        SpinLock { locked: atomic::new(false) }
    }
    
    fn acquire(&mut self) wcet: 1000_cycles {  // Bounded by priority ceiling
        while !atomic_compare_exchange(&self.locked, false, true).1 {
            while atomic_load(&self.locked, MemoryOrdering::Relaxed) {
                pause();  // PAUSE instruction reduces bus traffic
            }
        }
        @fence(acquire);
    }
    
    @inline fn release(&mut self) wcet: 20_cycles {
        @fence(release);
        atomic_store(&self.locked, false, MemoryOrdering::Release);
    }
}

// RWLock para lectores múltiples
struct RWLock {
    readers: atomic<u32>,
    writer: atomic<bool>,
}

impl RWLock {
    @inline fn new() -> Self {
        RWLock { 
            readers: atomic::new(0),
            writer: atomic::new(false),
        }
    }
    
    fn read_lock(&mut self) wcet: 1500_cycles {
        loop {
            while atomic_load(&self.writer, MemoryOrdering::Acquire) {
                pause();
            }
            
            atomic_fetch_add(&self.readers, 1);
            
            if !atomic_load(&self.writer, MemoryOrdering::Acquire) {
                break;  // Successfully acquired read lock
            }
            
            atomic_fetch_add(&self.readers, -1);
        }
    }
    
    fn read_unlock(&mut self) wcet: 50_cycles {
        atomic_fetch_add(&self.readers, -1);
    }
    
    fn write_lock(&mut self) wcet: 2000_cycles {
        while !atomic_compare_exchange(&self.writer, false, true).1 {
            pause();
        }
        
        while atomic_load(&self.readers, MemoryOrdering::Acquire) > 0 {
            pause();
        }
    }
    
    fn write_unlock(&mut self) wcet: 20_cycles {
        atomic_store(&self.writer, false, MemoryOrdering::Release);
    }
}
```

## 🧵 MULTITHREADING

### 9. Context Switching Determinístico

```tempo
// CPU context que debe matchear exactamente el layout de stack
#[repr(C)]
struct CPUContext {
    // Preserved registers (callee-saved)
    r15: u64, r14: u64, r13: u64, r12: u64,
    rbp: u64, rbx: u64,
    
    // Interrupt frame (pushed by CPU during interrupt)
    rip: u64,
    cs: u64,
    rflags: u64,
    rsp: u64,
    ss: u64,
}

// Task Control Block
struct Task {
    id: TaskID,
    context: CPUContext,
    stack_base: ptr<u8>,
    stack_size: usize,
    priority: Priority,
    wcet: Duration,
    deadline: TimeStamp,
    budget: CpuBudget,
    state: TaskState,
    next: ptr<Task>,
}

enum TaskState {
    Ready,
    Running,
    Blocked,
    Terminated,
}

// Context switch determinístico
@naked
fn switch_context(old_context: ptr<CPUContext>, new_context: ptr<CPUContext>) wcet: 100_cycles {
    @asm("
        # Save callee-saved registers
        pushq %rbx
        pushq %rbp
        pushq %r12
        pushq %r13
        pushq %r14
        pushq %r15
        
        # Save current stack pointer
        movq %rsp, (%rdi)
        
        # Load new stack pointer
        movq (%rsi), %rsp
        
        # Restore callee-saved registers
        popq %r15
        popq %r14
        popq %r13
        popq %r12
        popq %rbp
        popq %rbx
        
        ret
    ")
}

// Task creation determinística
fn create_task(entry: fn(), stack_size: usize, priority: Priority) -> Result<ptr<Task>, TaskError> 
    wcet: 1000_cycles {
    
    let stack = alloc_deterministic(stack_size)?;
    let task = alloc_deterministic(sizeof::<Task>())? as ptr<Task>;
    
    // Setup initial context
    let stack_top = stack.offset(stack_size as isize);
    
    (*task).id = allocate_task_id();
    (*task).context = CPUContext {
        r15: 0, r14: 0, r13: 0, r12: 0,
        rbp: 0, rbx: 0,
        rip: entry as u64,
        cs: 0x08,  // Kernel code segment
        rflags: 0x202,  // Interrupts enabled
        rsp: stack_top as u64,
        ss: 0x10,  // Kernel data segment
    };
    (*task).stack_base = stack;
    (*task).stack_size = stack_size;
    (*task).priority = priority;
    (*task).state = TaskState::Ready;
    
    add_to_ready_queue(task);
    
    Ok(task)
}
```

### 10. Timer Management Determinístico

```tempo
// High precision timer setup
fn setup_apic_timer(frequency_hz: u32) wcet: 2000_cycles {
    let apic_base = read_msr(0x1B) & 0xFFFFF000;
    
    // Disable APIC timer
    write_apic_register(apic_base + APIC_LVT_TIMER, APIC_DISABLE);
    
    // Set divide configuration (divide by 1)
    write_apic_register(apic_base + APIC_TIMER_DIV, 0x0B);
    
    // Set LVT timer entry
    write_apic_register(apic_base + APIC_LVT_TIMER, TIMER_VECTOR | APIC_TIMER_PERIODIC);
    
    // Calculate initial count
    let cpu_freq = get_cpu_frequency();
    let initial_count = cpu_freq / frequency_hz;
    write_apic_register(apic_base + APIC_TIMER_INIT, initial_count);
}

// HPET (High Precision Event Timer) setup
fn setup_hpet() -> Result<(), TimerError> wcet: 5000_cycles {
    let hpet_base = find_hpet_in_acpi()?;
    
    // Read capabilities
    let caps = read_hpet_register(hpet_base + HPET_CAPS);
    let period_fs = caps >> 32;  // Period in femtoseconds
    
    // Disable HPET
    write_hpet_register(hpet_base + HPET_CONFIG, 0);
    
    // Reset main counter
    write_hpet_register(hpet_base + HPET_MAIN_COUNTER, 0);
    
    // Configure comparator 0 for periodic interrupts
    let config = HPET_INT_ENABLE | HPET_TYPE_PERIODIC | HPET_VAL_SET;
    write_hpet_register(hpet_base + HPET_TIMER0_CONFIG, config);
    
    // Set period (1000 Hz = 1ms)
    let period_ticks = 1_000_000_000_000 / period_fs;  // 1ms in HPET ticks
    write_hpet_register(hpet_base + HPET_TIMER0_COMPARE, period_ticks);
    
    // Enable HPET
    write_hpet_register(hpet_base + HPET_CONFIG, HPET_ENABLE);
    
    Ok(())
}

// Time tracking determinístico
static mut SYSTEM_TICKS: atomic<u64> = atomic::new(0);
static mut TIME_SLICE_REMAINING: atomic<u32> = atomic::new(0);

@interrupt
fn timer_interrupt_handler(frame: ptr<InterruptFrame>) wcet: 500_cycles {
    atomic_fetch_add(&SYSTEM_TICKS, 1);
    
    let remaining = atomic_fetch_add(&TIME_SLICE_REMAINING, -1);
    if remaining == 1 {
        // Time slice expired, schedule next task
        schedule_next_task();
    }
    
    // Send EOI
    let apic_base = read_msr(0x1B) & 0xFFFFF000;
    write_apic_register(apic_base + APIC_EOI, 0);
}
```

## 💾 DRIVERS Y HARDWARE

### 11. DMA (Direct Memory Access)

```tempo
// DMA descriptor para hardware
#[repr(C)]
#[packed]
struct DMADescriptor {
    buffer_addr: u64,     // Physical address
    length: u32,          // Transfer length
    flags: u32,           // Control flags
    next: u64,            // Next descriptor (for chaining)
}

const DMA_FLAG_INTERRUPT: u32 = 1 << 0;
const DMA_FLAG_END_OF_CHAIN: u32 = 1 << 1;

// DMA controller programming
fn setup_dma_transfer(channel: u8, desc: ptr<DMADescriptor>) -> Result<(), DMAError> 
    wcet: 1000_cycles {
    
    let dma_base = get_dma_controller_base(channel)?;
    
    // Ensure cache coherency before DMA
    @fence(full);
    wbinvd();  // Writeback and invalidate cache
    
    // Program DMA controller
    write_mmio(dma_base + DMA_DESC_ADDR_LOW, desc as u64 & 0xFFFFFFFF);
    write_mmio(dma_base + DMA_DESC_ADDR_HIGH, (desc as u64) >> 32);
    
    // Enable DMA channel
    write_mmio(dma_base + DMA_CONTROL, DMA_ENABLE | DMA_INTERRUPT_ENABLE);
    
    @fence(full);
    
    Ok(())
}

// Zero-copy network DMA
struct NetworkDMADescriptor {
    desc: DMADescriptor,
    packet: ptr<NetworkPacket>,
    completion_callback: fn(Result<(), DMAError>),
}

fn send_packet_zerocopy(nic: ptr<NetworkInterface>, packet: ptr<NetworkPacket>) 
    wcet: 2000_cycles {
    
    // Map packet buffer for DMA
    let phys_addr = virtual_to_physical(packet.data);
    
    // Setup DMA descriptor
    let desc = DMADescriptor {
        buffer_addr: phys_addr,
        length: packet.length,
        flags: DMA_FLAG_INTERRUPT | DMA_FLAG_END_OF_CHAIN,
        next: 0,
    };
    
    // Add to TX ring
    let tx_head = nic.tx_head;
    nic.tx_ring[tx_head] = desc;
    nic.tx_head = (tx_head + 1) % TX_RING_SIZE;
    
    // Kick the NIC
    write_mmio(nic.mmio_base + NIC_TX_TAIL, nic.tx_head as u32);
}
```

### 12. PCI Configuration y MSI

```tempo
// PCI configuration space access
fn read_pci_config(bus: u8, device: u8, function: u8, offset: u8) -> u32 
    wcet: 100_cycles {
    
    let address = 0x80000000u32 |
                  ((bus as u32) << 16) |
                  ((device as u32) << 11) |
                  ((function as u32) << 8) |
                  ((offset as u32) & 0xFC);
    
    outl(PCI_CONFIG_ADDRESS, address);
    inl(PCI_CONFIG_DATA)
}

fn write_pci_config(bus: u8, device: u8, function: u8, offset: u8, value: u32) 
    wcet: 120_cycles {
    
    let address = 0x80000000u32 |
                  ((bus as u32) << 16) |
                  ((device as u32) << 11) |
                  ((function as u32) << 8) |
                  ((offset as u32) & 0xFC);
    
    outl(PCI_CONFIG_ADDRESS, address);
    outl(PCI_CONFIG_DATA, value);
}

// MSI (Message Signaled Interrupts) setup
struct MSICapability {
    cap_id: u8,       // 0x05 for MSI
    next_cap: u8,
    control: u16,
    msg_addr_low: u32,
    msg_addr_high: u32,  // Only if 64-bit capable
    msg_data: u16,
    mask: u32,           // Only if per-vector masking capable
    pending: u32,        // Only if per-vector masking capable
}

fn setup_msi(device: PCIDevice, vector: u8) -> Result<(), PCIError> wcet: 1500_cycles {
    let msi_cap_offset = find_pci_capability(device, PCI_CAP_MSI)?;
    
    // MSI message address (local APIC)
    let cpu_id = get_current_cpu_id();
    let msg_addr = 0xFEE00000u32 | ((cpu_id & 0xFF) << 12);
    
    // MSI message data
    let msg_data = vector as u16;
    
    // Write MSI configuration
    write_pci_config(device.bus, device.device, device.function,
                     msi_cap_offset + 4, msg_addr);
    
    // Check if 64-bit capable
    let control = read_pci_config(device.bus, device.device, device.function,
                                  msi_cap_offset + 2) as u16;
    
    if (control & MSI_64BIT_CAPABLE) != 0 {
        write_pci_config(device.bus, device.device, device.function,
                         msi_cap_offset + 8, 0);  // High 32 bits = 0
        write_pci_config(device.bus, device.device, device.function,
                         msi_cap_offset + 12, msg_data as u32);
    } else {
        write_pci_config(device.bus, device.device, device.function,
                         msi_cap_offset + 8, msg_data as u32);
    }
    
    // Enable MSI
    let new_control = control | MSI_ENABLE;
    write_pci_config(device.bus, device.device, device.function,
                     msi_cap_offset + 2, new_control as u32);
    
    Ok(())
}
```

## 🖥️ INTERFAZ DE USUARIO

### 13. Graphics y Framebuffer

```tempo
// Framebuffer linear para graphics
struct Framebuffer {
    addr: ptr<u32>,       // Physical address mapped
    width: u32,
    height: u32,
    pitch: u32,           // Bytes per scanline
    bpp: u32,             // Bits per pixel
    format: PixelFormat,
}

enum PixelFormat {
    RGB888,               // 24-bit RGB
    RGBA8888,             // 32-bit RGBA
    BGR888,               // 24-bit BGR (common on x86)
    BGRA8888,             // 32-bit BGRA
}

// Pixel operations optimizadas
@inline fn put_pixel(fb: ptr<Framebuffer>, x: u32, y: u32, color: u32) wcet: 20_cycles {
    if x < (*fb).width && y < (*fb).height {
        let offset = y * ((*fb).pitch / 4) + x;
        (*fb).addr[offset] = color;
    }
}

@inline fn get_pixel(fb: ptr<Framebuffer>, x: u32, y: u32) -> u32 wcet: 15_cycles {
    if x < (*fb).width && y < (*fb).height {
        let offset = y * ((*fb).pitch / 4) + x;
        (*fb).addr[offset]
    } else {
        0
    }
}

// Operaciones de bloque para performance
fn fill_rect(fb: ptr<Framebuffer>, x: u32, y: u32, w: u32, h: u32, color: u32) 
    wcet: w * h * 10_cycles {
    
    for row in y..(y + h) {
        if row >= (*fb).height { break; }
        
        let start_offset = row * ((*fb).pitch / 4) + x;
        let end_x = min(x + w, (*fb).width);
        let count = end_x - x;
        
        // Use rep stosl for fast fill
        @asm("rep stosl",
             in("edi") &(*fb).addr[start_offset],
             in("eax") color,
             in("ecx") count,
             memory_write);
    }
}

fn copy_rect(src_fb: ptr<Framebuffer>, dst_fb: ptr<Framebuffer>,
             src_x: u32, src_y: u32, dst_x: u32, dst_y: u32, w: u32, h: u32)
    wcet: w * h * 15_cycles {
    
    for row in 0..h {
        let src_row = src_y + row;
        let dst_row = dst_y + row;
        
        if src_row >= (*src_fb).height || dst_row >= (*dst_fb).height {
            continue;
        }
        
        let src_offset = src_row * ((*src_fb).pitch / 4) + src_x;
        let dst_offset = dst_row * ((*dst_fb).pitch / 4) + dst_x;
        
        let copy_width = min(w, min((*src_fb).width - src_x, (*dst_fb).width - dst_x));
        
        // Use rep movsl for fast copy
        @asm("rep movsl",
             in("esi") &(*src_fb).addr[src_offset],
             in("edi") &(*dst_fb).addr[dst_offset],
             in("ecx") copy_width,
             memory_readwrite);
    }
}

// GPU command buffer para hardware acceleration
struct GPUCommand {
    cmd_type: u32,
    src_addr: u64,
    dst_addr: u64,
    width: u32,
    height: u32,
    color: u32,
    flags: u32,
}

const GPU_CMD_FILL: u32 = 1;
const GPU_CMD_COPY: u32 = 2;
const GPU_CMD_BLIT: u32 = 3;

fn submit_gpu_command(cmd: GPUCommand) wcet: 500_cycles {
    let gpu_mmio = get_gpu_mmio_base();
    
    // Wait for command buffer space
    while (read_mmio(gpu_mmio + GPU_STATUS) & GPU_CMD_BUFFER_FULL) != 0 {
        pause();
    }
    
    // Write command to GPU
    write_mmio(gpu_mmio + GPU_CMD_TYPE, cmd.cmd_type);
    write_mmio(gpu_mmio + GPU_CMD_SRC_ADDR, cmd.src_addr);
    write_mmio(gpu_mmio + GPU_CMD_DST_ADDR, cmd.dst_addr);
    write_mmio(gpu_mmio + GPU_CMD_WIDTH, cmd.width);
    write_mmio(gpu_mmio + GPU_CMD_HEIGHT, cmd.height);
    write_mmio(gpu_mmio + GPU_CMD_COLOR, cmd.color);
    write_mmio(gpu_mmio + GPU_CMD_FLAGS, cmd.flags);
    
    // Trigger execution
    write_mmio(gpu_mmio + GPU_EXECUTE, 1);
}
```

### 14. Input Processing Determinístico

```tempo
// Unified input event system
enum InputEvent {
    KeyPress { key: KeyCode, modifiers: KeyModifiers },
    KeyRelease { key: KeyCode, modifiers: KeyModifiers },
    MouseMove { x: i32, y: i32, dx: i32, dy: i32 },
    MousePress { button: MouseButton, x: i32, y: i32 },
    MouseRelease { button: MouseButton, x: i32, y: i32 },
    MouseWheel { dx: i32, dy: i32 },
    TouchDown { id: u32, x: i32, y: i32, pressure: u16 },
    TouchMove { id: u32, x: i32, y: i32, pressure: u16 },
    TouchUp { id: u32, x: i32, y: i32 },
}

// Ring buffer lock-free para events
struct InputQueue {
    events: [InputEvent; INPUT_QUEUE_SIZE],
    head: atomic<u32>,
    tail: atomic<u32>,
}

const INPUT_QUEUE_SIZE: usize = 1024;

impl InputQueue {
    fn new() -> Self {
        InputQueue {
            events: [InputEvent::default(); INPUT_QUEUE_SIZE],
            head: atomic::new(0),
            tail: atomic::new(0),
        }
    }
    
    fn push(&mut self, event: InputEvent) -> bool wcet: 100_cycles {
        let head = atomic_load(&self.head, MemoryOrdering::Acquire);
        let next_head = (head + 1) % INPUT_QUEUE_SIZE as u32;
        let tail = atomic_load(&self.tail, MemoryOrdering::Acquire);
        
        if next_head == tail {
            return false;  // Queue full
        }
        
        self.events[head as usize] = event;
        atomic_store(&self.head, next_head, MemoryOrdering::Release);
        true
    }
    
    fn pop(&mut self) -> Option<InputEvent> wcet: 80_cycles {
        let tail = atomic_load(&self.tail, MemoryOrdering::Acquire);
        let head = atomic_load(&self.head, MemoryOrdering::Acquire);
        
        if tail == head {
            return None;  // Queue empty
        }
        
        let event = self.events[tail as usize];
        atomic_store(&self.tail, (tail + 1) % INPUT_QUEUE_SIZE as u32, 
                    MemoryOrdering::Release);
        Some(event)
    }
}

// Keyboard driver con scancode translation
static SCANCODE_TO_KEYCODE: [KeyCode; 256] = generate_scancode_table!();

@interrupt  
fn keyboard_interrupt(frame: ptr<InterruptFrame>) wcet: 200_cycles {
    let scancode = inb(0x60);
    let released = (scancode & 0x80) != 0;
    let code = scancode & 0x7F;
    
    let keycode = SCANCODE_TO_KEYCODE[code as usize];
    let modifiers = get_current_modifiers();
    
    let event = if released {
        InputEvent::KeyRelease { key: keycode, modifiers }
    } else {
        InputEvent::KeyPress { key: keycode, modifiers }
    };
    
    push_input_event(event);
    
    // Send EOI
    outb(0x20, 0x20);
}

// Mouse driver PS/2
static mut MOUSE_PACKET: [u8; 3] = [0; 3];
static mut MOUSE_CYCLE: u8 = 0;
static mut MOUSE_X: i32 = 0;
static mut MOUSE_Y: i32 = 0;

@interrupt
fn mouse_interrupt(frame: ptr<InterruptFrame>) wcet: 300_cycles {
    let data = inb(0x60);
    
    MOUSE_PACKET[MOUSE_CYCLE as usize] = data;
    MOUSE_CYCLE += 1;
    
    if MOUSE_CYCLE == 3 {
        MOUSE_CYCLE = 0;
        
        let flags = MOUSE_PACKET[0];
        let dx = MOUSE_PACKET[1] as i8 as i32;
        let dy = -(MOUSE_PACKET[2] as i8 as i32);  // Invert Y
        
        MOUSE_X += dx;
        MOUSE_Y += dy;
        
        // Clamp to screen bounds
        MOUSE_X = max(0, min(MOUSE_X, SCREEN_WIDTH as i32 - 1));
        MOUSE_Y = max(0, min(MOUSE_Y, SCREEN_HEIGHT as i32 - 1));
        
        // Generate move event
        let move_event = InputEvent::MouseMove {
            x: MOUSE_X,
            y: MOUSE_Y, 
            dx, dy
        };
        push_input_event(move_event);
        
        // Check button states
        if (flags & 1) != 0 {  // Left button
            let press_event = InputEvent::MousePress {
                button: MouseButton::Left,
                x: MOUSE_X,
                y: MOUSE_Y,
            };
            push_input_event(press_event);
        }
        
        if (flags & 2) != 0 {  // Right button
            let press_event = InputEvent::MousePress {
                button: MouseButton::Right,
                x: MOUSE_X,
                y: MOUSE_Y,
            };
            push_input_event(press_event);
        }
    }
    
    // Send EOI
    outb(0x20, 0x20);
}
```

## 📁 FILESYSTEM

### 15. Block Device Interface Determinístico

```tempo
// Block device trait para storage
trait BlockDevice {
    fn read_block(&self, block: u64, buffer: ptr<u8>) -> Result<(), IOError> 
        wcet: 10000_cycles;
        
    fn write_block(&self, block: u64, buffer: ptr<u8>) -> Result<(), IOError>
        wcet: 15000_cycles;
        
    fn flush(&self) -> Result<(), IOError>
        wcet: 50000_cycles;
        
    fn block_size(&self) -> u32 wcet: 5_cycles;
    fn block_count(&self) -> u64 wcet: 5_cycles;
    fn is_read_only(&self) -> bool wcet: 5_cycles;
}

// ATA/SATA driver implementation
struct ATADevice {
    base_port: u16,
    control_port: u16,
    drive: u8,           // 0 for master, 1 for slave
    sectors: u64,
    is_lba48: bool,
}

impl BlockDevice for ATADevice {
    fn read_block(&self, block: u64, buffer: ptr<u8>) -> Result<(), IOError> 
        wcet: 10000_cycles {
        
        if self.is_lba48 && block > 0xFFFFFFF {
            self.read_lba48(block, buffer)
        } else {
            self.read_lba28(block as u32, buffer)
        }
    }
    
    fn write_block(&self, block: u64, buffer: ptr<u8>) -> Result<(), IOError>
        wcet: 15000_cycles {
        
        if self.is_lba48 && block > 0xFFFFFFF {
            self.write_lba48(block, buffer)
        } else {
            self.write_lba28(block as u32, buffer)
        }
    }
    
    fn block_size(&self) -> u32 wcet: 5_cycles { 512 }
    fn block_count(&self) -> u64 wcet: 5_cycles { self.sectors }
    fn is_read_only(&self) -> bool wcet: 5_cycles { false }
}

impl ATADevice {
    fn read_lba28(&self, lba: u32, buffer: ptr<u8>) -> Result<(), IOError> 
        wcet: 8000_cycles {
        
        // Select drive and set LBA mode
        outb(self.base_port + ATA_REG_DRIVE, 
             0xE0 | (self.drive << 4) | ((lba >> 24) & 0x0F) as u8);
        
        // Set sector count (1 sector)
        outb(self.base_port + ATA_REG_SECCOUNT, 1);
        
        // Set LBA
        outb(self.base_port + ATA_REG_LBA0, (lba & 0xFF) as u8);
        outb(self.base_port + ATA_REG_LBA1, ((lba >> 8) & 0xFF) as u8);
        outb(self.base_port + ATA_REG_LBA2, ((lba >> 16) & 0xFF) as u8);
        
        // Issue READ SECTORS command
        outb(self.base_port + ATA_REG_COMMAND, ATA_CMD_READ_SECTORS);
        
        // Wait for BSY to clear and DRQ to set
        self.wait_for_ready()?;
        
        // Read data
        for i in 0..256 {
            let word = inw(self.base_port + ATA_REG_DATA);
            buffer[i * 2] = (word & 0xFF) as u8;
            buffer[i * 2 + 1] = (word >> 8) as u8;
        }
        
        Ok(())
    }
    
    fn wait_for_ready(&self) -> Result<(), IOError> wcet: 5000_cycles {
        let mut timeout = 5000;
        
        while timeout > 0 {
            let status = inb(self.base_port + ATA_REG_STATUS);
            
            if (status & ATA_STATUS_ERR) != 0 {
                return Err(IOError::DeviceError);
            }
            
            if (status & ATA_STATUS_BSY) == 0 && (status & ATA_STATUS_DRQ) != 0 {
                return Ok(());
            }
            
            timeout -= 1;
            pause();
        }
        
        Err(IOError::Timeout)
    }
}

// NVMe driver para SSDs modernos  
struct NVMeDevice {
    mmio_base: ptr<u8>,
    admin_queue: NVMeQueue,
    io_queues: [NVMeQueue; 16],
    nsid: u32,
    block_size: u32,
    block_count: u64,
}

struct NVMeQueue {
    submission_queue: ptr<NVMeCommand>,
    completion_queue: ptr<NVMeCompletion>,
    sq_tail: atomic<u16>,
    cq_head: atomic<u16>,
    queue_size: u16,
}

#[repr(C)]
struct NVMeCommand {
    opcode: u8,
    flags: u8,
    command_id: u16,
    nsid: u32,
    cdw2: u32,
    cdw3: u32,
    metadata: u64,
    prp1: u64,           // Physical Region Page 1
    prp2: u64,           // Physical Region Page 2
    cdw10: u32,
    cdw11: u32,
    cdw12: u32,
    cdw13: u32,
    cdw14: u32,
    cdw15: u32,
}

impl BlockDevice for NVMeDevice {
    fn read_block(&self, block: u64, buffer: ptr<u8>) -> Result<(), IOError>
        wcet: 5000_cycles {  // NVMe is much faster than ATA
        
        let queue_id = get_current_cpu_id() % 16;
        let queue = &self.io_queues[queue_id];
        
        let cmd = NVMeCommand {
            opcode: NVME_CMD_READ,
            flags: 0,
            command_id: allocate_command_id(),
            nsid: self.nsid,
            prp1: virtual_to_physical(buffer),
            prp2: 0,
            cdw10: (block & 0xFFFFFFFF) as u32,
            cdw11: (block >> 32) as u32,
            cdw12: 0,  // Number of blocks - 1 (0 = 1 block)
            ..NVMeCommand::default()
        };
        
        self.submit_command(queue_id, cmd)?;
        self.wait_for_completion(queue_id, cmd.command_id)?;
        
        Ok(())
    }
}
```

## 🌐 NETWORKING

### 16. Network Stack Determinístico

```tempo
// Network packet structure
struct NetworkPacket {
    data: ptr<u8>,
    len: u32,
    capacity: u32,
    protocol: Protocol,
    source: NetworkAddress,
    dest: NetworkAddress,
    timestamp: TimeStamp,
}

enum Protocol {
    Ethernet,
    IPv4,
    IPv6,
    TCP,
    UDP,
    ICMP,
}

struct NetworkAddress {
    addr_type: AddressType,
    addr: [u8; 16],     // Large enough for IPv6
}

enum AddressType {
    MAC,
    IPv4,
    IPv6,
}

// Zero-copy networking con DMA
struct NetworkInterface {
    mmio_base: ptr<u8>,
    tx_ring: [TXDescriptor; TX_RING_SIZE],
    rx_ring: [RXDescriptor; RX_RING_SIZE],
    tx_head: atomic<u16>,
    tx_tail: atomic<u16>,
    rx_head: atomic<u16>,
    rx_tail: atomic<u16>,
    mac_addr: [u8; 6],
}

#[repr(C)]
struct TXDescriptor {
    addr: u64,           // Physical address of buffer
    len: u16,
    flags: u16,
    vlan: u16,
    css: u8,
    cmd: u8,
    status: u8,
    reserved: u8,
}

#[repr(C)]  
struct RXDescriptor {
    addr: u64,           // Physical address of buffer
    len: u16,
    checksum: u16,
    status: u8,
    errors: u8,
    vlan: u16,
}

const TX_RING_SIZE: usize = 256;
const RX_RING_SIZE: usize = 256;

// Packet transmission zero-copy
fn send_packet_zerocopy(nic: ptr<NetworkInterface>, packet: NetworkPacket) 
    wcet: 1000_cycles {
    
    let tx_head = atomic_load(&(*nic).tx_head, MemoryOrdering::Acquire);
    let next_head = (tx_head + 1) % TX_RING_SIZE as u16;
    let tx_tail = atomic_load(&(*nic).tx_tail, MemoryOrdering::Acquire);
    
    // Check if ring buffer is full
    if next_head == tx_tail {
        return;  // Drop packet - deterministic behavior
    }
    
    // Map packet buffer for DMA
    let phys_addr = virtual_to_physical(packet.data);
    
    // Setup TX descriptor
    let desc = &mut (*nic).tx_ring[tx_head as usize];
    desc.addr = phys_addr;
    desc.len = packet.len as u16;
    desc.flags = TX_FLAG_END_OF_PACKET | TX_FLAG_INTERRUPT;
    desc.cmd = TX_CMD_SEND;
    
    // Memory barrier before updating hardware
    @fence(release);
    
    // Update head pointer
    atomic_store(&(*nic).tx_head, next_head, MemoryOrdering::Release);
    
    // Notify hardware
    write_mmio((*nic).mmio_base + NIC_TX_TAIL, next_head as u32);
}

// Packet reception processing
@interrupt
fn network_rx_interrupt(frame: ptr<InterruptFrame>) wcet: 2000_cycles {
    let nic = get_primary_nic();
    
    let rx_tail = atomic_load(&nic.rx_tail, MemoryOrdering::Acquire);
    let rx_head = atomic_load(&nic.rx_head, MemoryOrdering::Acquire);
    
    while rx_tail != rx_head {
        let desc = &nic.rx_ring[rx_tail as usize];
        
        if (desc.status & RX_STATUS_DONE) == 0 {
            break;
        }
        
        // Process received packet
        let packet_data = physical_to_virtual(desc.addr) as ptr<u8>;
        let packet_len = desc.len;
        
        process_received_packet(packet_data, packet_len);
        
        // Clear descriptor for reuse
        desc.status = 0;
        
        // Update tail
        let new_tail = (rx_tail + 1) % RX_RING_SIZE as u16;
        atomic_store(&nic.rx_tail, new_tail, MemoryOrdering::Release);
        write_mmio(nic.mmio_base + NIC_RX_TAIL, new_tail as u32);
    }
    
    // Send EOI
    let apic_base = read_msr(0x1B) & 0xFFFFF000;
    write_apic_register(apic_base + APIC_EOI, 0);
}

// Protocol stack processing
fn process_received_packet(data: ptr<u8>, len: u16) wcet: 1500_cycles {
    // Parse Ethernet header
    let eth_header = data as ptr<EthernetHeader>;
    let eth_type = be16_to_cpu((*eth_header).ethertype);
    
    let payload = data.offset(sizeof::<EthernetHeader>() as isize);
    let payload_len = len - sizeof::<EthernetHeader>() as u16;
    
    match eth_type {
        ETHERTYPE_IPV4 => process_ipv4_packet(payload, payload_len),
        ETHERTYPE_IPV6 => process_ipv6_packet(payload, payload_len),
        ETHERTYPE_ARP => process_arp_packet(payload, payload_len),
        _ => {
            // Unknown protocol, drop packet
        }
    }
}

fn process_ipv4_packet(data: ptr<u8>, len: u16) wcet: 1000_cycles {
    let ip_header = data as ptr<IPv4Header>;
    
    // Verify checksum
    if !verify_ipv4_checksum(ip_header) {
        return;  // Drop invalid packet
    }
    
    let protocol = (*ip_header).protocol;
    let header_len = ((*ip_header).version_ihl & 0x0F) * 4;
    let payload = data.offset(header_len as isize);
    let payload_len = be16_to_cpu((*ip_header).total_length) - header_len as u16;
    
    match protocol {
        IP_PROTO_TCP => process_tcp_packet(payload, payload_len),
        IP_PROTO_UDP => process_udp_packet(payload, payload_len),
        IP_PROTO_ICMP => process_icmp_packet(payload, payload_len),
        _ => {
            // Unknown protocol
        }
    }
}
```

## 🛡️ SECURITY

### 17. Protection Rings y Privileges

```tempo
// User mode transition
@naked
fn enter_usermode(entry: fn(), stack: ptr<u8>) -> never wcet: 200_cycles {
    @asm("
        # Setup user data segments
        movw $0x23, %ax      # User data segment (GDT entry 4, RPL=3)
        movw %ax, %ds
        movw %ax, %es
        movw %ax, %fs
        movw %ax, %gs
        
        # Push IRET frame for user mode
        pushq $0x23          # SS (user stack segment)
        pushq {stack}        # RSP (user stack pointer)
        pushfq               # RFLAGS (current flags)
        orq $0x200, (%rsp)   # Enable interrupts in user mode
        pushq $0x1B          # CS (user code segment, GDT entry 3, RPL=3)
        pushq {entry}        # RIP (entry point)
        
        # Zero out registers for security
        xorq %rax, %rax
        xorq %rbx, %rbx
        xorq %rcx, %rcx
        xorq %rdx, %rdx
        xorq %rsi, %rsi
        xorq %rdi, %rdi
        xorq %r8, %r8
        xorq %r9, %r9
        xorq %r10, %r10
        xorq %r11, %r11
        xorq %r12, %r12
        xorq %r13, %r13
        xorq %r14, %r14
        xorq %r15, %r15
        
        iretq
    ", stack = in(stack), entry = in(entry))
}

// System call interface
#[repr(C)]
struct SyscallFrame {
    rax: u64,    // System call number
    rdi: u64,    // Argument 1
    rsi: u64,    // Argument 2  
    rdx: u64,    // Argument 3
    r10: u64,    // Argument 4 (rcx is used by syscall instruction)
    r8: u64,     // Argument 5
    r9: u64,     // Argument 6
}

// System call handler
@interrupt
fn syscall_handler(frame: ptr<InterruptFrame>) wcet: 1000_cycles {
    let syscall_frame = frame as ptr<SyscallFrame>;
    
    let syscall_num = (*syscall_frame).rax;
    let arg1 = (*syscall_frame).rdi;
    let arg2 = (*syscall_frame).rsi;
    let arg3 = (*syscall_frame).rdx;
    let arg4 = (*syscall_frame).r10;
    let arg5 = (*syscall_frame).r8;
    let arg6 = (*syscall_frame).r9;
    
    let result = match syscall_num {
        SYS_READ => sys_read(arg1 as i32, arg2 as ptr<u8>, arg3 as usize),
        SYS_WRITE => sys_write(arg1 as i32, arg2 as ptr<u8>, arg3 as usize),
        SYS_OPEN => sys_open(arg1 as ptr<char>, arg2 as i32, arg3 as i32),
        SYS_CLOSE => sys_close(arg1 as i32),
        SYS_EXIT => sys_exit(arg1 as i32),
        _ => Err(ENOSYS),
    };
    
    // Return result in RAX
    (*syscall_frame).rax = match result {
        Ok(val) => val as u64,
        Err(errno) => (-errno as i64) as u64,
    };
}

// Capability-based security
struct Capability {
    object_id: u64,      // ID of the object this capability grants access to
    permissions: u64,    // Bitmask of allowed operations
    valid_until: u64,    // Expiration timestamp
    signature: [u8; 64], // HMAC-SHA256 signature
}

const CAP_READ: u64 = 1 << 0;
const CAP_WRITE: u64 = 1 << 1;
const CAP_EXECUTE: u64 = 1 << 2;
const CAP_DELETE: u64 = 1 << 3;
const CAP_ADMIN: u64 = 1 << 63;

// Verify capability authenticity and permissions
fn verify_capability(cap: ptr<Capability>, operation: u64) -> bool wcet: 5000_cycles {
    // Check expiration
    if (*cap).valid_until < get_system_time() {
        return false;
    }
    
    // Check permissions
    if ((*cap).permissions & operation) == 0 {
        return false;
    }
    
    // Verify HMAC signature
    let message = [
        (*cap).object_id.to_bytes(),
        (*cap).permissions.to_bytes(), 
        (*cap).valid_until.to_bytes(),
    ].concat();
    
    let expected_sig = hmac_sha256(&get_capability_key(), &message);
    
    constant_time_compare(&(*cap).signature, &expected_sig)
}

// Constant-time comparison para prevenir timing attacks
@inline fn constant_time_compare(a: &[u8; 64], b: &[u8; 64]) -> bool wcet: 64_cycles {
    let mut diff: u8 = 0;
    
    for i in 0..64 {
        diff |= a[i] ^ b[i];
    }
    
    diff == 0
}
```

## 🔧 CARACTERÍSTICAS DEL LENGUAJE

### 18. Manejo de Errores Sin Heap

```tempo
// Result types que no requieren allocación
type Result<T, E> = union {
    Ok(T),
    Err(E),
}

// Error codes específicos del kernel
enum KernelError {
    OutOfMemory = 1,
    InvalidParameter = 2,
    DeviceNotFound = 3,
    PermissionDenied = 4,
    Timeout = 5,
    InvalidState = 6,
    BufferTooSmall = 7,
    NotSupported = 8,
}

// Conversión de errores POSIX
impl From<KernelError> for i32 {
    fn from(err: KernelError) -> i32 wcet: 5_cycles {
        match err {
            KernelError::OutOfMemory => ENOMEM,
            KernelError::InvalidParameter => EINVAL,
            KernelError::DeviceNotFound => ENODEV,
            KernelError::PermissionDenied => EACCES,
            KernelError::Timeout => ETIMEDOUT,
            KernelError::InvalidState => EBUSY,
            KernelError::BufferTooSmall => ENOBUFS,
            KernelError::NotSupported => ENOSYS,
        }
    }
}

// Macro para propagación de errores
macro_rules! try_kernel {
    ($expr:expr) => {
        match $expr {
            Ok(val) => val,
            Err(err) => return Err(err),
        }
    };
}

// Ejemplo de uso
fn allocate_and_map_page(virt_addr: u64) -> Result<u64, KernelError> wcet: 2000_cycles {
    let phys_addr = try_kernel!(allocate_physical_page());
    try_kernel!(map_page(virt_addr, phys_addr, PAGE_PRESENT | PAGE_WRITABLE));
    Ok(phys_addr)
}
```

### 19. Compile-Time Computation

```tempo
// Generate lookup tables at compile time
const SINE_TABLE: [f32; 1024] = generate_sine_table!();
const CRC32_TABLE: [u32; 256] = generate_crc32_table!();
const INTERRUPT_VECTORS: [u64; 256] = generate_interrupt_table!();

// Compile-time task scheduling
const TASK_SCHEDULE: [TaskID; 86400000] = compute_optimal_schedule!(TASKS);

// Compile-time memory layout
const MEMORY_LAYOUT: MemoryMap = compute_memory_layout!();

macro_rules! generate_sine_table {
    () => {{
        let mut table = [0.0f32; 1024];
        let mut i = 0;
        while i < 1024 {
            table[i] = libm::sinf(i as f32 * 2.0 * PI / 1024.0);
            i += 1;
        }
        table
    }};
}

macro_rules! generate_crc32_table {
    () => {{
        let mut table = [0u32; 256];
        let mut i = 0;
        while i < 256 {
            let mut crc = i as u32;
            let mut j = 0;
            while j < 8 {
                if (crc & 1) != 0 {
                    crc = (crc >> 1) ^ 0xEDB88320;
                } else {
                    crc >>= 1;
                }
                j += 1;
            }
            table[i] = crc;
            i += 1;
        }
        table
    }};
}

// Compile-time verification
const_assert!(sizeof::<Task>() <= 256);
const_assert!(TASK_COUNT <= MAX_TASKS);
const_assert!(STACK_SIZE >= MIN_STACK_SIZE);
```

### 20. Zero Runtime

```tempo
// No standard library, no runtime
#![no_std]
#![no_main]
#![no_builtins]

// Everything statically allocated
@section(".bss")
@align(4096)
static mut KERNEL_HEAP: [u8; 16777216] = [0; 16777216];  // 16MB static heap

@section(".bss") 
@align(4096)
static mut TASK_STACKS: [[u8; 65536]; 64] = [[0; 65536]; 64];  // 64 task stacks

@section(".bss")
@align(8)
static mut TASKS: [Task; 64] = [Task::new(); 64];

// Global allocator basado en pools estáticos
struct StaticAllocator {
    heap_start: ptr<u8>,
    heap_size: usize,
    next_free: atomic<ptr<u8>>,
}

static ALLOCATOR: StaticAllocator = StaticAllocator {
    heap_start: KERNEL_HEAP.as_ptr(),
    heap_size: 16777216,
    next_free: atomic::new(KERNEL_HEAP.as_ptr()),
};

impl StaticAllocator {
    fn alloc(&self, size: usize, align: usize) -> Result<ptr<u8>, AllocError> 
        wcet: 100_cycles {
        
        let current = atomic_load(&self.next_free, MemoryOrdering::Acquire);
        let aligned = align_up(current as usize, align) as ptr<u8>;
        let new_ptr = aligned.offset(size as isize);
        
        let heap_end = self.heap_start.offset(self.heap_size as isize);
        if new_ptr >= heap_end {
            return Err(AllocError::OutOfMemory);
        }
        
        // Try to atomically update the pointer
        let success = atomic_compare_exchange(&self.next_free, current, new_ptr).1;
        if success {
            Ok(aligned)
        } else {
            Err(AllocError::Contention)
        }
    }
}

// No dynamic allocation functions
fn alloc_static<T>() -> Result<ptr<T>, AllocError> wcet: 100_cycles {
    ALLOCATOR.alloc(sizeof::<T>(), alignof::<T>()).map(|p| p as ptr<T>)
}

// Panic handler para kernel
#[panic_handler]
fn panic(info: &PanicInfo) -> ! {
    disable_interrupts();
    
    if let Some(location) = info.location() {
        kernel_log!("PANIC at {}:{}: {}", 
                   location.file(), location.line(), info.message());
    } else {
        kernel_log!("PANIC: {}", info.message());
    }
    
    // Halt all CPUs
    halt_all_cpus();
    loop { halt(); }
}

// Entry point del kernel
#[no_mangle]
extern "C" fn kernel_main() -> ! {
    // Initialize kernel subsystems
    init_memory_management();
    init_interrupt_handlers();
    init_scheduler();
    init_drivers();
    
    // Start first user process
    let init_task = create_task(init_process, 65536, Priority::Normal)
        .expect("Failed to create init task");
    
    schedule_task(init_task);
    
    // Enable interrupts and start scheduling
    enable_interrupts();
    scheduler_loop();
}
```

## 🎯 CARACTERÍSTICAS ESPECÍFICAS PARA ATOMICOS

### 21. WCET (Worst-Case Execution Time) Obligatorio

```tempo
// TODAS las funciones deben tener WCET declarado
@wcet(1000)  // Máximo 1000 ciclos, verificado por el compilador
fn handle_interrupt() {
    // El compilador analiza todos los paths y verifica que
    // ninguno exceda 1000 ciclos
}

@wcet(50)    // 50 ciclos máximo
fn context_switch() {
    // Cambio de contexto ultra-rápido
}

// El compilador RECHAZA código sin WCET verificable
fn bad_function() {  // ERROR: No WCET bound provable
    while unknown_condition() { }  // Loop potentially unbounded
}

// Loops deben tener bounds explícitos
@wcet(1000)
fn bounded_loop() {
    for i in 0..100 {  // OK: bound is 100
        do_work(i);    // do_work must have its own WCET
    }
}

// WCET puede depender de parámetros
@wcet(n * 10 + 50)
fn process_array(arr: &[u32; n]) {
    for item in arr {
        process_item(item);  // Must be @wcet(10)
    }
}
```

### 22. No Allocación Dinámica - TODO Pre-Asignado

```tempo
// NO malloc/free - todo estático y determinístico
static mut TASK_POOL: [Task; 1024] = [Task::new(); 1024];
static mut MEMORY_REGIONS: [MemoryRegion; 65536] = [MemoryRegion::new(); 65536];
static mut FILE_DESCRIPTORS: [FileDescriptor; 4096] = [FileDescriptor::new(); 4096];

// Asignación determinística en compile-time
const TASK_MEMORY_MAP: [MemoryAssignment; 1024] = compute_memory_layout!(TASKS);

// Allocator que usa pools pre-asignados
struct DeterministicAllocator;

impl DeterministicAllocator {
    @wcet(10)
    fn alloc_task(&mut self) -> Option<ptr<Task>> {
        for i in 0..1024 {
            if TASK_POOL[i].is_free() {
                TASK_POOL[i].mark_used();
                return Some(&mut TASK_POOL[i]);
            }
        }
        None
    }
    
    @wcet(5)
    fn free_task(&mut self, task: ptr<Task>) {
        task.mark_free();
    }
}

// Memory regions con tamaño fijo
struct MemoryRegion {
    start: u64,
    size: u64,
    used: bool,
    owner: TaskID,
}

const MEMORY_REGION_4K: usize = 0;
const MEMORY_REGION_64K: usize = 1;
const MEMORY_REGION_1M: usize = 2;

@wcet(100)
fn alloc_memory_region(size_class: usize) -> Option<MemoryRegion> {
    let pool = match size_class {
        MEMORY_REGION_4K => &mut MEMORY_POOLS_4K,
        MEMORY_REGION_64K => &mut MEMORY_POOLS_64K,
        MEMORY_REGION_1M => &mut MEMORY_POOLS_1M,
        _ => return None,
    };
    
    for region in pool {
        if !region.used {
            region.used = true;
            return Some(*region);
        }
    }
    None
}
```

### 23. Scheduling Determinístico por Tablas

```tempo
// Schedule pre-computado para 24 horas (1ms ticks)
const SCHEDULE_TABLE: [TaskID; 86_400_000] = generate_schedule!();

// No hay "decisiones" en runtime - todo está pre-computado
@wcet(10)
fn get_next_task() -> TaskID {
    let current_tick = get_system_tick();
    SCHEDULE_TABLE[current_tick % 86_400_000]
}

// Generación de schedule en compile-time
macro_rules! generate_schedule {
    () => {{
        // Rate Monotonic Scheduling para tasks periódicos
        let mut schedule = [TaskID::IDLE; 86_400_000];
        
        // Task definitions con períodos exactos
        const TASKS: &[(TaskID, u32)] = &[  // (ID, period_ms)
            (TaskID::HEARTBEAT, 1),         // 1ms
            (TaskID::NETWORK_RX, 2),        // 2ms  
            (TaskID::DISK_IO, 5),           // 5ms
            (TaskID::USER_INPUT, 10),       // 10ms
            (TaskID::GRAPHICS, 16),         // 16ms (60 FPS)
            (TaskID::BACKGROUND, 100),      // 100ms
        ];
        
        // Fill schedule table
        let mut tick = 0;
        while tick < 86_400_000 {
            let mut assigned = false;
            
            // Check each task in priority order (shorter period = higher priority)
            for &(task_id, period) in TASKS {
                if tick % period == 0 {
                    schedule[tick] = task_id;
                    assigned = true;
                    break;
                }
            }
            
            if !assigned {
                schedule[tick] = TaskID::IDLE;
            }
            
            tick += 1;
        }
        
        schedule
    }};
}

// Scheduler simplísimo - solo consulta tabla
@wcet(20)
fn schedule() {
    let next_task = get_next_task();
    
    if next_task != get_current_task() {
        switch_to_task(next_task);
    }
}
```

### 24. Hardware Determinístico Forzado

```tempo
// Deshabilitar TODO lo no-determinístico
@wcet(10000)
fn enforce_determinism() {
    // CPU configuration
    disable_turbo_boost();
    disable_hyperthreading();
    disable_speculative_execution();
    set_fixed_cpu_frequency(2_000_000_000);  // 2GHz fijo
    
    // Cache configuration
    enable_cache_partitioning();
    disable_cache_prefetching();
    disable_cache_line_speculation();
    
    // Memory configuration  
    disable_memory_compression();
    disable_swap();  // No paging to disk
    set_memory_frequency(1600);  // DDR3-1600 fijo
    
    // Interrupt configuration
    set_fixed_interrupt_latency();
    disable_interrupt_coalescing();
}

@wcet(1000)
fn disable_turbo_boost() {
    // Intel: Disable turbo boost via MSR
    let turbo_disable = read_msr(MSR_IA32_MISC_ENABLE);
    write_msr(MSR_IA32_MISC_ENABLE, turbo_disable | (1 << 38));
    
    // AMD: Disable Core Performance Boost
    let boost_disable = read_msr(MSR_AMD_HWCR);
    write_msr(MSR_AMD_HWCR, boost_disable | (1 << 25));
}

@wcet(500)
fn disable_speculative_execution() {
    // Disable speculative execution features
    let spec_ctrl = read_msr(MSR_IA32_SPEC_CTRL);
    write_msr(MSR_IA32_SPEC_CTRL, spec_ctrl | SPEC_CTRL_IBRS | SPEC_CTRL_STIBP);
    
    // Disable indirect branch prediction
    write_msr(MSR_IA32_PRED_CMD, PRED_CMD_IBPB);
}

@wcet(2000)
fn setup_cache_partitioning() {
    // Intel CAT (Cache Allocation Technology)
    let cat_mask = 0x00FF;  // Use only lower 8 ways of LLC
    
    for cpu in 0..get_cpu_count() {
        write_msr(MSR_IA32_L3_QOS_MASK(cpu), cat_mask);
    }
    
    // Enable CAT
    let qos_cfg = read_msr(MSR_IA32_QM_EVTSEL);
    write_msr(MSR_IA32_QM_EVTSEL, qos_cfg | QOS_ENABLE_CAT);
}
```

### 25. Operaciones Constant-Time

```tempo
// Comparaciones constant-time para security y determinismo
@wcet(32)  // Exactamente 32 ciclos SIEMPRE, independiente del contenido
fn constant_time_compare(a: &[u8; 32], b: &[u8; 32]) -> bool {
    let mut diff: u8 = 0;
    
    // Loop unrolled para garantizar timing constante
    diff |= a[0] ^ b[0];   diff |= a[1] ^ b[1];   diff |= a[2] ^ b[2];   diff |= a[3] ^ b[3];
    diff |= a[4] ^ b[4];   diff |= a[5] ^ b[5];   diff |= a[6] ^ b[6];   diff |= a[7] ^ b[7];
    diff |= a[8] ^ b[8];   diff |= a[9] ^ b[9];   diff |= a[10] ^ b[10]; diff |= a[11] ^ b[11];
    diff |= a[12] ^ b[12]; diff |= a[13] ^ b[13]; diff |= a[14] ^ b[14]; diff |= a[15] ^ b[15];
    diff |= a[16] ^ b[16]; diff |= a[17] ^ b[17]; diff |= a[18] ^ b[18]; diff |= a[19] ^ b[19];
    diff |= a[20] ^ b[20]; diff |= a[21] ^ b[21]; diff |= a[22] ^ b[22]; diff |= a[23] ^ b[23];
    diff |= a[24] ^ b[24]; diff |= a[25] ^ b[25]; diff |= a[26] ^ b[26]; diff |= a[27] ^ b[27];
    diff |= a[28] ^ b[28]; diff |= a[29] ^ b[29]; diff |= a[30] ^ b[30]; diff |= a[31] ^ b[31];
    
    diff == 0
}

// Selección constant-time (sin branches)
@wcet(10)
fn constant_time_select(condition: bool, a: u64, b: u64) -> u64 {
    let mask = -(condition as i64) as u64;  // All 1s if true, all 0s if false
    (a & mask) | (b & !mask)
}

// Copy constant-time
@wcet(len * 2)
fn constant_time_copy(dest: ptr<u8>, src: ptr<u8>, len: usize) {
    for i in 0..len {
        dest[i] = src[i];  // No early termination, always copy full length
    }
}

// Crypto operations con timing constante
@wcet(64 * 8)  // 64 bytes * 8 cycles per byte
fn aes_encrypt_block(plaintext: &[u8; 16], key: &[u8; 16]) -> [u8; 16] {
    // AES implementation que siempre toma el mismo tiempo
    // Sin lookup tables (para evitar cache timing attacks)
    // Solo operaciones aritméticas y XOR
}
```

## 📊 RESUMEN PARA ATOMICOS

Para AtomicOS necesitas TODAS estas características del compilador:

### ✅ Control Hardware Completo
- Inline assembly sin restricciones
- Acceso directo a registros de control
- Memory-mapped I/O
- Interrupt handling determinístico

### ✅ WCET en TODO
- Cada función con tiempo máximo garantizado
- Análisis estático de timing
- Rechazo de código sin bounds

### ✅ Zero Allocación Dinámica  
- Todo pre-asignado estáticamente
- Pools de memoria fijos
- Sin malloc/free

### ✅ Scheduling por Tablas
- Sin decisiones en runtime
- Schedule pre-computado
- Rate Monotonic Scheduling

### ✅ Hardware Determinístico
- Control de CPU/Cache/Memory
- Deshabilitación de features no-determinísticos
- Configuración fija de frecuencias

### ✅ Constant-Time Operations
- Para seguridad y predictibilidad
- Sin timing side-channels
- Crypto determinístico

### ✅ Lock-Free Determinístico
- Canales con tiempo acotado
- Estructuras sin locks
- Atomic operations

### ✅ Zero Runtime
- Sin standard library
- Sin heap allocator
- Todo compile-time

**AtomicOS no es solo un OS, es una sinfonía matemática donde cada instrucción toca en el momento exacto predeterminado. 🎼**

Esta especificación completa permite al otro Claude implementar AtomicOS con todas las garantías determinísticas necesarias.