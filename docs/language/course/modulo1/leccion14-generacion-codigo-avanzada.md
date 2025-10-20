╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 14: Generación de Código Avanzada - Register allocation, instruction selection

## Objetivos de la Lección
- Dominar algoritmos de asignación de registros
- Implementar selección de instrucciones óptima
- Desarrollar scheduling de instrucciones
- Generar código máquina eficiente para múltiples arquitecturas

## 1. Teoría (20%)

### Register Allocation

La asignación de registros es uno de los problemas más importantes en generación de código. Debe mapear un número ilimitado de valores SSA a un conjunto finito de registros físicos.

### Graph Coloring

El problema se modela como coloreo de grafos:
- **Nodos**: Valores SSA (variables virtuales)
- **Aristas**: Interferencia (vivos simultáneamente)
- **Colores**: Registros físicos

### Instruction Selection

Elegir qué instrucciones máquina usar para implementar la IR:
- **Pattern Matching**: Cubrir el árbol IR con patterns
- **Cost Models**: Minimizar ciclos/tamaño
- **Peephole Optimization**: Mejoras locales

### Instruction Scheduling

Ordenar instrucciones para maximizar ILP:
- **Dependencias**: Respetar orden semántico
- **Latencias**: Ocultar delays
- **Recursos**: Evitar conflictos estructurales

## 2. Práctica (60%)

### Linear Scan Register Allocation

```tempo
// linear_scan.tempo - Algoritmo de asignación lineal

struct LinearScanAllocator {
    intervals: **LiveInterval,
    interval_count: i32,
    
    registers: *PhysicalRegister,
    reg_count: i32,
    
    active: *IntervalList,      // Intervalos activos
    inactive: *IntervalList,    // Intervalos inactivos
    handled: *IntervalList,     // Intervalos procesados
    
    spill_slots: *SpillSlotMap,
    reg_classes: *RegisterClassInfo
}

struct LiveInterval {
    value: *SSAValue,
    ranges: *LiveRange,
    reg: PhysicalRegister,
    spill_slot: i32,
    weight: f64,                // Para decisiones de spill
    
    // Split children
    parent: *LiveInterval,
    children: **LiveInterval,
    child_count: i32
}

struct LiveRange {
    start: i32,                 // Program point
    end: i32,
    next: *LiveRange
}

fn allocate_registers_linear_scan(func: *Function) -> *AllocationResult {
    let allocator = create_linear_scan_allocator(func);
    
    // Paso 1: Computar live intervals
    compute_live_intervals(allocator, func);
    
    // Paso 2: Ordenar por start point
    sort_intervals_by_start(allocator.intervals, allocator.interval_count);
    
    // Paso 3: Linear scan
    let i = 0;
    while i < allocator.interval_count {
        let current = allocator.intervals[i];
        let position = current.ranges.start;
        
        // Expirar intervalos viejos
        expire_old_intervals(allocator, position);
        
        // Encontrar registro disponible
        let reg = find_available_register(allocator, current);
        
        if reg != NO_REGISTER {
            // Asignar registro
            current.reg = reg;
            add_to_active(allocator, current);
        } else {
            // Necesita spill
            allocate_blocked_register(allocator, current);
        }
        
        i = i + 1;
    }
    
    // Paso 4: Resolver y reescribir código
    return finalize_allocation(allocator, func);
}

fn compute_live_intervals(allocator: *LinearScanAllocator, func: *Function) {
    // Numeración de program points
    let numbering = number_instructions(func);
    
    // Análisis de liveness
    let liveness = compute_liveness(func);
    
    // Construir intervalos
    let values = collect_ssa_values(func);
    let v = 0;
    while v < values.count {
        let value = values.items[v];
        let interval = create_interval(value);
        
        // Encontrar todos los puntos donde está vivo
        let uses = get_uses(value);
        let def_point = get_def_point(value, numbering);
        
        // Añadir rango desde definición hasta último uso
        let last_use = def_point;
        let u = 0;
        while u < uses.count {
            let use_point = get_use_point(uses.items[u], numbering);
            last_use = max(last_use, use_point);
            u = u + 1;
        }
        
        add_range(interval, def_point, last_use);
        
        // Extender a través de bloques donde está vivo
        extend_through_blocks(interval, value, liveness, numbering);
        
        allocator.intervals[v] = interval;
        v = v + 1;
    }
}

fn find_available_register(allocator: *LinearScanAllocator, 
                          interval: *LiveInterval) -> PhysicalRegister {
    // Obtener clase de registro requerida
    let reg_class = get_register_class(interval.value.type);
    let available = get_registers_in_class(allocator.registers, reg_class);
    
    // Marcar registros usados por intervalos activos
    let used = create_register_set();
    let active = allocator.active.first;
    while active != 0 {
        if intervals_overlap(interval, active.interval) {
            mark_used(used, active.interval.reg);
        }
        active = active.next;
    }
    
    // Verificar inactivos que podrían interferir
    let inactive = allocator.inactive.first;
    while inactive != 0 {
        if intervals_overlap(interval, inactive.interval) {
            mark_used(used, inactive.interval.reg);
        }
        inactive = inactive.next;
    }
    
    // Encontrar primer registro disponible
    let r = 0;
    while r < available.count {
        if !is_used(used, available.regs[r]) {
            return available.regs[r];
        }
        r = r + 1;
    }
    
    return NO_REGISTER;
}

fn allocate_blocked_register(allocator: *LinearScanAllocator, 
                            current: *LiveInterval) {
    // Encontrar registro con próximo uso más lejano
    let next_use = alloc(allocator.reg_count * sizeof(i32));
    
    // Inicializar con infinito
    let r = 0;
    while r < allocator.reg_count {
        next_use[r] = INFINITY;
        r = r + 1;
    }
    
    // Calcular próximo uso para activos
    compute_next_uses_active(allocator, current.ranges.start, next_use);
    
    // Calcular próximo uso para inactivos
    compute_next_uses_inactive(allocator, current.ranges.start, next_use);
    
    // Encontrar registro con uso más lejano
    let best_reg = NO_REGISTER;
    let best_next_use = -1;
    
    r = 0;
    while r < allocator.reg_count {
        if can_use_register(current, allocator.registers[r]) {
            if next_use[r] > best_next_use {
                best_reg = r;
                best_next_use = next_use[r];
            }
        }
        r = r + 1;
    }
    
    // Si el próximo uso del mejor registro es después del current
    if best_next_use > get_next_use(current, current.ranges.start) {
        // Spill otro intervalo
        spill_at_interval(allocator, best_reg, current);
        current.reg = best_reg;
        add_to_active(allocator, current);
    } else {
        // Spill current
        assign_spill_slot(allocator, current);
    }
}

// Splitting de intervalos para reducir spills
fn try_split_interval(allocator: *LinearScanAllocator, 
                     interval: *LiveInterval, 
                     position: i32) -> bool {
    
    // Buscar buen punto de split (e.g., boundary de loop)
    let split_pos = find_optimal_split_position(interval, position);
    
    if split_pos == -1 {
        return false;
    }
    
    // Crear hijo para segunda parte
    let child = create_interval(interval.value);
    child.parent = interval;
    
    // Dividir rangos
    split_ranges_at(interval, child, split_pos);
    
    // El padre mantiene la primera parte
    add_child(interval, child);
    
    // Añadir hijo para procesamiento futuro
    insert_unhandled(allocator, child);
    
    return true;
}
```

### Graph Coloring Register Allocation

```tempo
// graph_coloring.tempo - Asignación por coloreo de grafos (Chaitin-Briggs)

struct GraphColoringAllocator {
    interference_graph: *InterferenceGraph,
    worklists: struct {
        precolored: *NodeSet,     // Nodos con color fijo
        initial: *NodeSet,        // Nodos sin procesar
        simplify: *NodeSet,       // Nodos de bajo grado
        freeze: *NodeSet,         // Nodos de bajo grado con moves
        spill: *NodeSet,          // Nodos de alto grado
        spilled: *NodeSet,        // Nodos para spill
        coalesced: *NodeSet,      // Nodos coalescidos
        colored: *NodeSet,        // Nodos coloreados exitosamente
        select_stack: *NodeStack  // Stack para fase select
    },
    
    move_list: *MoveList,         // Lista de moves para coalescing
    alias: *AliasMap,             // Para nodos coalescidos
    color: *ColorMap,             // Asignación final
    
    K: i32                        // Número de colores (registros)
}

struct InterferenceGraph {
    nodes: **IGraphNode,
    node_count: i32,
    edges: *EdgeSet
}

struct IGraphNode {
    value: *SSAValue,
    degree: i32,
    neighbors: *NodeList,
    move_list: *MoveList,
    spill_cost: f64,
    color: i32
}

fn allocate_registers_graph_coloring(func: *Function) -> *AllocationResult {
    let allocator = create_graph_coloring_allocator(func);
    
    // Loop principal hasta convergencia
    loop {
        // Construir grafo de interferencia
        build_interference_graph(allocator, func);
        
        // Intentar colorear
        if color_graph(allocator) {
            break;  // Éxito
        }
        
        // Reescribir código para spills
        rewrite_spills(allocator, func);
    }
    
    return finalize_coloring(allocator, func);
}

fn build_interference_graph(allocator: *GraphColoringAllocator, func: *Function) {
    let liveness = compute_liveness(func);
    
    // Crear nodo para cada valor SSA
    let values = collect_ssa_values(func);
    create_nodes(allocator, values);
    
    // Añadir aristas de interferencia
    let block = func.entry;
    while block != 0 {
        let live_out = get_live_out(liveness, block);
        let live = copy_set(live_out);
        
        // Procesar instrucciones en reversa
        let inst = get_last_instruction(block);
        while inst != 0 {
            // Para definiciones
            if defines_value(inst) {
                let def = get_defined_value(inst);
                
                // Interferencia con todo lo vivo
                let v = get_first(live);
                while v != 0 {
                    if v != def {
                        add_edge(allocator.interference_graph, def, v);
                    }
                    v = get_next(live, v);
                }
                
                // Remover def de live
                remove_from_set(live, def);
            }
            
            // Para moves, registrar para coalescing
            if is_move(inst) {
                let src = get_move_src(inst);
                let dst = get_move_dst(inst);
                add_move(allocator.move_list, src, dst);
                
                // No crear interferencia entre src y dst
                remove_from_set(live, src);
            }
            
            // Añadir uses a live
            add_uses_to_set(live, inst);
            
            inst = get_prev_instruction(inst);
        }
        
        block = get_next_block(block);
    }
}

fn color_graph(allocator: *GraphColoringAllocator) -> bool {
    // Algoritmo iterativo de Chaitin-Briggs
    
    // Inicializar worklists
    make_worklist(allocator);
    
    // Loop principal
    while !all_worklists_empty(allocator) {
        if !is_empty(allocator.worklists.simplify) {
            simplify(allocator);
        } else if !is_empty(allocator.worklists.freeze) {
            freeze(allocator);
        } else if !is_empty(allocator.worklists.spill) {
            select_spill(allocator);
        }
    }
    
    // Asignar colores
    assign_colors(allocator);
    
    // Verificar si hubo spills
    return is_empty(allocator.worklists.spilled);
}

fn simplify(allocator: *GraphColoringAllocator) {
    let node = remove_from_worklist(allocator.worklists.simplify);
    push(allocator.worklists.select_stack, node);
    
    // Decrementar grado de vecinos
    let neighbor = node.neighbors.first;
    while neighbor != 0 {
        decrement_degree(allocator, neighbor);
        neighbor = neighbor.next;
    }
}

fn coalesce(allocator: *GraphColoringAllocator) {
    let move = remove_from_worklist(allocator.move_list);
    let src = get_alias(allocator, move.src);
    let dst = get_alias(allocator, move.dst);
    
    if src == dst {
        add_to_worklist(allocator.worklists.coalesced, move);
        return;
    }
    
    // Verificar si es seguro coalescer
    if can_coalesce_conservative(allocator, src, dst) {
        // Coalescer
        if is_precolored(dst) {
            combine(allocator, dst, src);
        } else {
            combine(allocator, src, dst);
        }
        add_to_worklist(allocator.worklists.coalesced, move);
    } else {
        // No se puede coalescer
        add_to_worklist(allocator.move_list.active, move);
    }
}

fn select_spill(allocator: *GraphColoringAllocator) {
    // Heurística: spill el nodo con menor (costo / grado)
    let best = 0;
    let best_cost = INFINITY;
    
    let node = allocator.worklists.spill.first;
    while node != 0 {
        let cost = compute_spill_cost(node) / node.degree;
        if cost < best_cost {
            best = node;
            best_cost = cost;
        }
        node = node.next;
    }
    
    remove_from_worklist(allocator.worklists.spill, best);
    simplify_node(allocator, best);
}

fn assign_colors(allocator: *GraphColoringAllocator) {
    // Pop del stack y asignar colores
    while !is_empty(allocator.worklists.select_stack) {
        let node = pop(allocator.worklists.select_stack);
        
        // Colores disponibles
        let ok_colors = create_color_set(allocator.K);
        
        // Remover colores de vecinos coloreados
        let neighbor = node.neighbors.first;
        while neighbor != 0 {
            let n = get_alias(allocator, neighbor);
            if is_colored(n) || is_precolored(n) {
                remove_color(ok_colors, get_color(allocator, n));
            }
            neighbor = neighbor.next;
        }
        
        if is_empty(ok_colors) {
            // Spill necesario
            add_to_worklist(allocator.worklists.spilled, node);
        } else {
            // Asignar color
            node.color = get_first_color(ok_colors);
            add_to_worklist(allocator.worklists.colored, node);
        }
    }
}

// Spill cost estimation
fn compute_spill_cost(node: *IGraphNode) -> f64 {
    let cost = 0.0;
    let uses = get_uses(node.value);
    
    let u = 0;
    while u < uses.count {
        let use = uses.items[u];
        let freq = get_block_frequency(get_block(use));
        let depth = get_loop_depth(get_block(use));
        
        // Penalizar más en loops internos
        cost = cost + freq * pow(10.0, depth);
        
        u = u + 1;
    }
    
    // Considerar si es rematerializable
    if is_rematerializable(node.value) {
        cost = cost * 0.1;
    }
    
    return cost;
}
```

### Instruction Selection

```tempo
// instruction_selection.tempo - Selección de instrucciones con pattern matching

struct InstructionSelector {
    target: *TargetMachine,
    patterns: *PatternDatabase,
    dag: *SelectionDAG,
    schedule: *InstructionSchedule
}

struct Pattern {
    // Pattern para matchear
    root: *PatternNode,
    cost: i32,
    
    // Código a generar
    emit: fn(*MatchContext) -> *MachineInstr
}

struct SelectionDAG {
    root: *DAGNode,
    nodes: **DAGNode,
    node_count: i32
}

struct DAGNode {
    opcode: IROp,
    type: *Type,
    operands: **DAGNode,
    operand_count: i32,
    uses: *UseList,
    
    // Para scheduling
    latency: i32,
    earliest: i32,
    latest: i32
}

fn select_instructions(func: *Function, target: *TargetMachine) -> *MachineFunction {
    let selector = create_instruction_selector(target);
    let mfunc = create_machine_function();
    
    let block = func.entry;
    while block != 0 {
        let mbb = create_machine_basic_block();
        
        // Construir DAG para el bloque
        let dag = build_selection_dag(block);
        
        // Seleccionar instrucciones
        let selected = select_for_dag(selector, dag);
        
        // Schedule instrucciones
        let scheduled = schedule_instructions(selector, selected);
        
        // Emitir a MachineBasicBlock
        emit_instructions(mbb, scheduled);
        
        add_basic_block(mfunc, mbb);
        block = get_next_block(block);
    }
    
    return mfunc;
}

fn select_for_dag(selector: *InstructionSelector, dag: *SelectionDAG) -> *InstrList {
    let selected = create_instruction_list();
    
    // Bottom-up pattern matching
    let worklist = create_dag_worklist();
    add_roots(worklist, dag);
    
    while !is_empty(worklist) {
        let node = remove_from_worklist(worklist);
        
        if is_selected(node) {
            continue;
        }
        
        // Encontrar mejor pattern
        let matches = find_matching_patterns(selector.patterns, node);
        let best = select_best_match(matches);
        
        if best != 0 {
            // Aplicar pattern
            let instrs = apply_pattern(best, node);
            append_instructions(selected, instrs);
            mark_covered(node, best);
            
            // Añadir nodos descubiertos
            add_uncovered_operands(worklist, node);
        } else {
            // Pattern por defecto
            let default = generate_default(selector.target, node);
            append_instruction(selected, default);
        }
    }
    
    return selected;
}

// Pattern matching con costs
fn find_matching_patterns(db: *PatternDatabase, node: *DAGNode) -> *MatchList {
    let matches = create_match_list();
    
    let p = 0;
    while p < db.pattern_count {
        let pattern = db.patterns[p];
        let match = try_match_pattern(pattern, node);
        
        if match != 0 {
            match.cost = compute_match_cost(pattern, match);
            add_match(matches, match);
        }
        
        p = p + 1;
    }
    
    return matches;
}

fn try_match_pattern(pattern: *Pattern, node: *DAGNode) -> *Match {
    let ctx = create_match_context();
    
    if match_node(pattern.root, node, ctx) {
        return create_match(pattern, ctx);
    }
    
    return 0;
}

fn match_node(pnode: *PatternNode, dnode: *DAGNode, ctx: *MatchContext) -> bool {
    // Verificar opcode
    if pnode.opcode != WILDCARD && pnode.opcode != dnode.opcode {
        return false;
    }
    
    // Verificar tipo
    if pnode.type != 0 && !types_compatible(pnode.type, dnode.type) {
        return false;
    }
    
    // Verificar predicado
    if pnode.predicate != 0 && !pnode.predicate(dnode) {
        return false;
    }
    
    // Capturar si es necesario
    if pnode.capture_id != -1 {
        capture_node(ctx, pnode.capture_id, dnode);
    }
    
    // Match recursivo de operandos
    if pnode.operand_count != dnode.operand_count {
        return false;
    }
    
    let i = 0;
    while i < pnode.operand_count {
        if !match_node(pnode.operands[i], dnode.operands[i], ctx) {
            return false;
        }
        i = i + 1;
    }
    
    return true;
}

// Ejemplo de patterns para x86
fn create_x86_patterns() -> *PatternDatabase {
    let db = create_pattern_database();
    
    // Pattern: (add reg, imm) -> ADD reg, imm
    add_pattern(db, 
        pattern(OP_ADD, [capture(0), immediate()]),
        1,  // cost
        fn(ctx: *MatchContext) -> *MachineInstr {
            return create_add_ri(
                get_capture_reg(ctx, 0),
                get_immediate_value(ctx, 1)
            );
        }
    );
    
    // Pattern: (add (mul x, 2), y) -> LEA [y + x*2]
    add_pattern(db,
        pattern(OP_ADD, [
            pattern(OP_MUL, [capture(0), const_int(2)]),
            capture(1)
        ]),
        1,  // LEA es barato
        fn(ctx: *MatchContext) -> *MachineInstr {
            return create_lea(
                create_address(
                    get_capture_reg(ctx, 1),  // base
                    get_capture_reg(ctx, 0),  // index
                    2,                        // scale
                    0                         // disp
                )
            );
        }
    );
    
    // Pattern: (load (add base, offset)) -> MOV reg, [base + offset]
    add_pattern(db,
        pattern(OP_LOAD, [
            pattern(OP_ADD, [capture(0), capture(1)])
        ]),
        1,
        fn(ctx: *MatchContext) -> *MachineInstr {
            return create_load(
                create_address_offset(
                    get_capture_reg(ctx, 0),
                    get_capture_value(ctx, 1)
                )
            );
        }
    );
    
    return db;
}
```

### Instruction Scheduling

```tempo
// instruction_scheduling.tempo - Scheduling para maximizar ILP

struct InstructionScheduler {
    target: *TargetMachine,
    hazard_rec: *HazardRecognizer,
    scoreboard: *Scoreboard,
    ready_queue: *PriorityQueue
}

struct ScheduleDAG {
    nodes: **ScheduleNode,
    node_count: i32
}

struct ScheduleNode {
    instr: *MachineInstr,
    preds: **ScheduleDep,
    pred_count: i32,
    succs: **ScheduleDep,
    succ_count: i32,
    
    // Scheduling info
    earliest: i32,
    latest: i32,
    height: i32,    // Distancia crítica al final
    depth: i32,     // Distancia crítica desde inicio
    scheduled: bool,
    cycle: i32
}

struct ScheduleDep {
    node: *ScheduleNode,
    latency: i32,
    kind: DepKind  // Data, Anti, Output, Control
}

fn schedule_instructions(scheduler: *InstructionScheduler, 
                        instrs: *InstrList) -> *InstrList {
    // Construir DAG de dependencias
    let dag = build_schedule_dag(instrs);
    
    // Calcular alturas y profundidades
    compute_heights(dag);
    compute_depths(dag);
    
    // List scheduling
    let scheduled = list_schedule(scheduler, dag);
    
    return scheduled;
}

fn build_schedule_dag(instrs: *InstrList) -> *ScheduleDAG {
    let dag = create_schedule_dag();
    
    // Crear nodos
    let instr = instrs.first;
    while instr != 0 {
        let node = create_schedule_node(instr);
        add_node(dag, node);
        instr = instr.next;
    }
    
    // Añadir dependencias de datos
    add_data_dependencies(dag);
    
    // Añadir dependencias de memoria
    add_memory_dependencies(dag);
    
    // Añadir dependencias de control
    add_control_dependencies(dag);
    
    return dag;
}

fn add_data_dependencies(dag: *ScheduleDAG) {
    // Map de def a nodo
    let def_map = create_def_map();
    
    let i = 0;
    while i < dag.node_count {
        let node = dag.nodes[i];
        
        // Para cada operando
        let op = 0;
        while op < get_operand_count(node.instr) {
            if is_use(node.instr, op) {
                let reg = get_operand_reg(node.instr, op);
                let def_node = lookup_def(def_map, reg);
                
                if def_node != 0 {
                    let latency = get_latency(def_node.instr);
                    add_dependency(def_node, node, latency, DEP_DATA);
                }
            }
            op = op + 1;
        }
        
        // Actualizar defs
        if defines_register(node.instr) {
            let reg = get_defined_reg(node.instr);
            update_def(def_map, reg, node);
        }
        
        i = i + 1;
    }
}

fn list_schedule(scheduler: *InstructionScheduler, dag: *ScheduleDAG) -> *InstrList {
    let scheduled = create_instruction_list();
    let cycle = 0;
    
    // Inicializar ready queue con nodos sin predecesores
    init_ready_queue(scheduler, dag);
    
    while has_unscheduled_nodes(dag) {
        // Avanzar scoreboard
        advance_cycle(scheduler.scoreboard, cycle);
        
        // Añadir nodos que se volvieron ready
        update_ready_queue(scheduler, dag, cycle);
        
        // Elegir siguiente instrucción
        let best = 0;
        while !is_empty(scheduler.ready_queue) && best == 0 {
            let candidate = peek_ready_queue(scheduler.ready_queue);
            
            // Verificar hazards
            if !has_hazard(scheduler.hazard_rec, candidate.instr, cycle) &&
               has_available_unit(scheduler.scoreboard, candidate.instr) {
                best = remove_from_queue(scheduler.ready_queue);
            } else {
                // Intentar con siguiente
                rotate_ready_queue(scheduler.ready_queue);
            }
        }
        
        if best != 0 {
            // Schedule instrucción
            best.cycle = cycle;
            best.scheduled = true;
            append_instruction(scheduled, best.instr);
            
            // Actualizar scoreboard
            reserve_units(scheduler.scoreboard, best.instr, cycle);
            
            // Decrementar contadores de sucesores
            let s = 0;
            while s < best.succ_count {
                let succ = best.succs[s];
                decrement_pred_count(succ.node);
                s = s + 1;
            }
        }
        
        cycle = cycle + 1;
    }
    
    return scheduled;
}

// Heurísticas para selección
fn compare_ready_nodes(a: *ScheduleNode, b: *ScheduleNode) -> i32 {
    // 1. Priorizar critical path
    if a.height != b.height {
        return b.height - a.height;
    }
    
    // 2. Priorizar menos sucesores (reduce presión)
    if a.succ_count != b.succ_count {
        return a.succ_count - b.succ_count;
    }
    
    // 3. Priorizar tipo de instrucción
    let a_lat = get_latency(a.instr);
    let b_lat = get_latency(b.instr);
    if a_lat != b_lat {
        return b_lat - a_lat;
    }
    
    // 4. Orden original
    return get_original_order(a) - get_original_order(b);
}

// Modular scheduling para loops
fn modulo_schedule_loop(loop: *MachineLoop) -> *ModuloSchedule {
    // Calcular MII (Minimum Initiation Interval)
    let res_mii = compute_resource_mii(loop);
    let rec_mii = compute_recurrence_mii(loop);
    let mii = max(res_mii, rec_mii);
    
    // Intentar schedule con II creciente
    let ii = mii;
    while ii <= max_ii {
        let schedule = try_modulo_schedule(loop, ii);
        if schedule != 0 {
            return schedule;
        }
        ii = ii + 1;
    }
    
    return 0;  // Fallo
}
```

### Generación de Código Máquina

```tempo
// code_emission.tempo - Emisión final de código máquina

struct CodeEmitter {
    target: *TargetMachine,
    buffer: *CodeBuffer,
    relocations: *RelocationList,
    debug_info: *DebugInfoBuilder
}

struct CodeBuffer {
    data: *u8,
    size: i32,
    capacity: i32,
    labels: *LabelMap
}

fn emit_machine_code(mfunc: *MachineFunction, target: *TargetMachine) -> *CodeBuffer {
    let emitter = create_code_emitter(target);
    
    // Emitir prólogo de función
    emit_function_prologue(emitter, mfunc);
    
    // Emitir cada bloque
    let mbb = mfunc.entry;
    while mbb != 0 {
        // Registrar label del bloque
        let label = register_label(emitter.buffer, mbb);
        
        // Emitir instrucciones
        let mi = mbb.first;
        while mi != 0 {
            emit_instruction(emitter, mi);
            mi = mi.next;
        }
        
        mbb = mbb.next;
    }
    
    // Emitir epílogo
    emit_function_epilogue(emitter, mfunc);
    
    // Resolver referencias
    resolve_labels(emitter.buffer);
    apply_relocations(emitter);
    
    return emitter.buffer;
}

fn emit_instruction(emitter: *CodeEmitter, mi: *MachineInstr) {
    let desc = get_instruction_desc(emitter.target, mi.opcode);
    
    // Emitir prefijos si necesario
    emit_prefixes(emitter, mi, desc);
    
    // Emitir opcode
    emit_opcode(emitter, desc.opcode, desc.opcode_size);
    
    // Emitir ModR/M y SIB si necesario
    if desc.has_modrm {
        emit_modrm(emitter, mi);
        if needs_sib(mi) {
            emit_sib(emitter, mi);
        }
    }
    
    // Emitir displacement
    if has_displacement(mi) {
        emit_displacement(emitter, mi);
    }
    
    // Emitir immediate
    if has_immediate(mi) {
        emit_immediate(emitter, mi);
    }
    
    // Debug info
    if emitter.debug_info != 0 {
        record_instruction_location(emitter.debug_info, mi, 
                                  get_current_offset(emitter.buffer));
    }
}

// Ejemplo: emitir para x86-64
fn emit_x86_64_instruction(emitter: *CodeEmitter, mi: *MachineInstr) {
    switch mi.opcode {
        case X86_ADD_RR:
            // ADD reg, reg
            if needs_rex(mi) {
                emit_rex(emitter, mi);
            }
            emit_u8(emitter, 0x01);  // ADD r/m64, r64
            emit_modrm(emitter, 
                      MOD_REG,
                      get_reg_encoding(mi.operands[1]),
                      get_reg_encoding(mi.operands[0]));
            break;
            
        case X86_MOV_RM:
            // MOV reg, [mem]
            if needs_rex(mi) {
                emit_rex(emitter, mi);
            }
            emit_u8(emitter, 0x8B);  // MOV r64, r/m64
            emit_memory_operand(emitter, mi.operands[0], mi.operands[1]);
            break;
            
        case X86_CALL:
            // CALL target
            emit_u8(emitter, 0xE8);  // CALL rel32
            emit_call_target(emitter, mi.operands[0]);
            break;
            
        case X86_JCC:
            // Conditional jump
            let cond = get_condition(mi);
            emit_u8(emitter, 0x0F);
            emit_u8(emitter, 0x80 + cond);  // Jcc rel32
            emit_branch_target(emitter, mi.operands[0]);
            break;
    }
}

// Optimización de código máquina
fn optimize_machine_code(buffer: *CodeBuffer) {
    // Peephole optimizations
    peephole_optimize(buffer);
    
    // Alineación de branches
    align_branch_targets(buffer);
    
    // Padding para evitar stalls
    insert_nop_padding(buffer);
}

fn peephole_optimize(buffer: *CodeBuffer) {
    let patterns = create_peephole_patterns();
    let offset = 0;
    
    while offset < buffer.size {
        let matched = false;
        
        // Intentar cada pattern
        let p = 0;
        while p < patterns.count && !matched {
            let pattern = patterns.items[p];
            
            if match_at_offset(buffer, offset, pattern) {
                apply_peephole(buffer, offset, pattern);
                matched = true;
            }
            
            p = p + 1;
        }
        
        if !matched {
            offset = offset + get_instruction_size(buffer, offset);
        }
    }
}
```

## 3. Ejercicios (20%)

### Ejercicio 1: PBQP Register Allocation
Implementa asignación de registros usando Partitioned Boolean Quadratic Programming:
```tempo
fn pbqp_register_allocation(func: *Function) -> *AllocationResult {
    // Formular como problema PBQP y resolver
}
```

### Ejercicio 2: Instruction Selection con BURS
Implementa selección usando Bottom-Up Rewrite System:
```tempo
fn burs_instruction_selection(tree: *IRTree) -> *MachineCode {
    // Usar programación dinámica para selección óptima
}
```

### Ejercicio 3: Trace Scheduling
Implementa scheduling de traces para código con branches:
```tempo
fn trace_schedule(traces: **Trace, count: i32) -> *ScheduledCode {
    // Optimizar traces frecuentes
}
```

### Ejercicio 4: Rematerialization
Implementa rematerialización para reducir spills:
```tempo
fn rematerialize_values(allocator: *RegisterAllocator) -> bool {
    // Recalcular valores baratos en lugar de spill/reload
}
```

### Ejercicio 5: Post-RA Scheduling
Implementa scheduling después de register allocation:
```tempo
fn post_ra_schedule(mfunc: *MachineFunction) -> bool {
    // Re-ordenar sin cambiar asignación de registros
}
```

## Proyecto Final: Backend Completo

Implementa un backend de producción que incluya:

1. **Register Allocation**:
   - Linear scan con splitting
   - Graph coloring con coalescing
   - PBQP para arquitecturas irregulares
   - Rematerialization

2. **Instruction Selection**:
   - Pattern matching óptimo
   - Soporte para múltiples ISAs
   - Intrinsics y builtins
   - Vector instructions

3. **Scheduling**:
   - List scheduling
   - Modulo scheduling para loops
   - Trace scheduling
   - Post-RA scheduling

4. **Code Generation**:
   - Emisión eficiente
   - Relocations y linking
   - Debug information
   - Profile-guided layout

## Recursos Adicionales

### Papers Fundamentales
- "Linear Scan Register Allocation" - Poletto & Sarkar
- "Improvements to Graph Coloring Register Allocation" - Briggs et al.
- "Optimal Instruction Selection" - Aho et al.
- "Software Pipelining" - Lam

### Implementaciones de Referencia
- LLVM: Backend modular y retargetable
- GCC: Décadas de optimizaciones de backend
- V8: JIT con fast register allocation
- HotSpot: Técnicas avanzadas de JIT

## Conclusión

La generación de código avanzada es donde la teoría encuentra la práctica. Las técnicas presentadas permiten:

1. **Código eficiente**: Uso óptimo de recursos de hardware
2. **Portabilidad**: Soporte para múltiples arquitecturas
3. **Performance**: Explotar ILP y microarquitectura
4. **Practicidad**: Balance entre compile time y code quality

El backend de Chronos demuestra que es posible generar código competitivo con diseño limpio y modular.