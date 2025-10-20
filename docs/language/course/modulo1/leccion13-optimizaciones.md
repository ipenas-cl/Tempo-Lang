╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 13: Optimizaciones - SSA form, constant folding, dead code elimination

## Objetivos de la Lección
- Dominar la forma SSA (Static Single Assignment)
- Implementar optimizaciones clásicas de compiladores
- Desarrollar análisis de flujo de datos
- Crear un framework de optimización extensible para Chronos

## 1. Teoría (20%)

### Static Single Assignment (SSA)

SSA es una representación intermedia donde cada variable es asignada exactamente una vez. Esto simplifica muchas optimizaciones:

```tempo
// Código original
x = 1
y = 2
x = x + y
z = x * 2

// En forma SSA
x₁ = 1
y₁ = 2
x₂ = x₁ + y₁
z₁ = x₂ * 2
```

### Ventajas de SSA

1. **Use-def chains explícitas**: Fácil rastrear usos de variables
2. **Simplifica análisis**: Muchos algoritmos se vuelven lineales
3. **Optimizaciones poderosas**: GVN, PRE, SCCP
4. **Representación sparse**: Eficiente en memoria

### Funciones Phi (φ)

Para manejar merge points en el control flow:

```tempo
// Original
if (cond) { x = 1 } else { x = 2 }
y = x + 1

// SSA
if (cond) { x₁ = 1 } else { x₂ = 2 }
x₃ = φ(x₁, x₂)
y₁ = x₃ + 1
```

### Optimizaciones Clásicas

1. **Constant Folding**: Evaluar expresiones constantes
2. **Dead Code Elimination**: Remover código inalcanzable
3. **Common Subexpression Elimination**: Reutilizar cálculos
4. **Loop Invariant Code Motion**: Sacar código de loops
5. **Strength Reduction**: Reemplazar operaciones costosas

## 2. Práctica (60%)

### Construcción de SSA

```tempo
// ssa_construction.tempo - Algoritmo de construcción SSA

struct SSABuilder {
    cfg: *ControlFlowGraph,
    dom_tree: *DominatorTree,
    dom_frontier: *DominanceFrontier,
    
    // Mapeo de variables originales a versiones SSA
    var_stacks: *VarStackMap,
    var_counter: *VarCounterMap,
    
    // Phi functions
    phi_functions: *PhiList
}

struct SSAValue {
    id: i32,
    name: *char,
    version: i32,
    def_block: *BasicBlock,
    def_inst: *Instruction,
    type: *Type
}

struct PhiFunction {
    result: *SSAValue,
    block: *BasicBlock,
    operands: **PhiOperand,
    operand_count: i32
}

struct PhiOperand {
    value: *SSAValue,
    pred_block: *BasicBlock
}

// Algoritmo de Cytron et al. para construcción SSA
fn build_ssa(cfg: *ControlFlowGraph) -> *SSAForm {
    let builder = create_ssa_builder(cfg);
    
    // Paso 1: Computar dominance frontier
    compute_dominance_frontier(builder);
    
    // Paso 2: Insertar phi functions
    insert_phi_functions(builder);
    
    // Paso 3: Renombrar variables
    rename_variables(builder);
    
    return finalize_ssa(builder);
}

// Computar dominance frontier eficientemente
fn compute_dominance_frontier(builder: *SSABuilder) {
    let cfg = builder.cfg;
    let dom_tree = builder.dom_tree;
    
    // DF(n) = {y | ∃x ∈ pred(y) : n dom x ∧ ¬(n sdom y)}
    let n = 0;
    while n < cfg.block_count {
        let block = cfg.blocks[n];
        builder.dom_frontier[n] = create_block_set();
        
        // DF_local
        let pred = 0;
        while pred < block.pred_count {
            let p = block.predecessors[pred];
            if !strictly_dominates(block, p) {
                add_to_set(builder.dom_frontier[n], block);
            }
            pred = pred + 1;
        }
        
        n = n + 1;
    }
    
    // DF_up
    compute_df_up(builder, dom_tree.root);
}

fn compute_df_up(builder: *SSABuilder, node: *DomTreeNode) {
    let child = node.first_child;
    while child != 0 {
        compute_df_up(builder, child);
        
        // Propagar DF del hijo
        let child_df = builder.dom_frontier[child.block.id];
        let block = child_df.first;
        
        while block != 0 {
            if !strictly_dominates(node.block, block) {
                add_to_set(builder.dom_frontier[node.block.id], block);
            }
            block = block.next;
        }
        
        child = child.next_sibling;
    }
}

// Insertar phi functions mínimas
fn insert_phi_functions(builder: *SSABuilder) {
    let cfg = builder.cfg;
    
    // Para cada variable
    let vars = collect_all_variables(cfg);
    let v = 0;
    while v < vars.count {
        let var = vars.items[v];
        let work_list = create_block_set();
        let has_phi = create_block_set();
        let ever_on_work = create_block_set();
        
        // Añadir bloques con definiciones a work list
        let defs = find_definitions(cfg, var);
        let d = 0;
        while d < defs.count {
            add_to_set(work_list, defs.blocks[d]);
            add_to_set(ever_on_work, defs.blocks[d]);
            d = d + 1;
        }
        
        // Iterar hasta punto fijo
        while !is_empty(work_list) {
            let block = remove_from_set(work_list);
            
            // Para cada bloque en DF(block)
            let df = builder.dom_frontier[block.id];
            let df_block = df.first;
            
            while df_block != 0 {
                if !is_in_set(has_phi, df_block) {
                    // Insertar phi function
                    insert_phi(builder, df_block, var);
                    add_to_set(has_phi, df_block);
                    
                    if !is_in_set(ever_on_work, df_block) {
                        add_to_set(work_list, df_block);
                        add_to_set(ever_on_work, df_block);
                    }
                }
                df_block = df_block.next;
            }
        }
        
        v = v + 1;
    }
}

// Renombrar variables a forma SSA
fn rename_variables(builder: *SSABuilder) {
    // Inicializar stacks para cada variable
    init_var_stacks(builder);
    
    // Renombrar recursivamente desde el entry block
    rename_block(builder, builder.cfg.entry);
}

fn rename_block(builder: *SSABuilder, block: *BasicBlock) {
    // Guardar estado de stacks
    let saved_tops = save_stack_tops(builder);
    
    // Renombrar phi functions
    let phi = block.phi_functions;
    while phi != 0 {
        let new_name = gen_ssa_name(builder, phi.var);
        phi.result = new_name;
        push_var_stack(builder, phi.var, new_name);
        phi = phi.next;
    }
    
    // Renombrar instrucciones
    let inst = block.instructions;
    while inst != 0 {
        // Renombrar usos
        rename_uses(builder, inst);
        
        // Renombrar definición si hay
        if defines_variable(inst) {
            let var = get_defined_var(inst);
            let new_name = gen_ssa_name(builder, var);
            set_ssa_def(inst, new_name);
            push_var_stack(builder, var, new_name);
        }
        
        inst = inst.next;
    }
    
    // Renombrar phi operands en sucesores
    let s = 0;
    while s < block.succ_count {
        let succ = block.successors[s];
        let phi = succ.phi_functions;
        
        while phi != 0 {
            let operand = find_phi_operand(phi, block);
            operand.value = top_of_stack(builder, phi.var);
            phi = phi.next;
        }
        
        s = s + 1;
    }
    
    // Renombrar hijos en dominator tree
    let child = get_dom_children(builder.dom_tree, block);
    while child != 0 {
        rename_block(builder, child);
        child = get_next_dom_sibling(child);
    }
    
    // Restaurar stacks
    restore_stack_tops(builder, saved_tops);
}
```

### Constant Folding y Propagation

```tempo
// constant_folding.tempo - Evaluación de constantes en compile time

struct ConstantFolder {
    ssa: *SSAForm,
    constants: *ConstantMap,
    worklist: *InstructionList
}

struct Constant {
    type: *Type,
    value: union {
        i64_val: i64,
        f64_val: f64,
        bool_val: bool,
        ptr_val: *void
    }
}

fn fold_constants(ssa: *SSAForm) -> bool {
    let folder = create_constant_folder(ssa);
    let changed = false;
    
    // Inicializar worklist con todas las instrucciones
    add_all_instructions(folder.worklist, ssa);
    
    while !is_empty(folder.worklist) {
        let inst = remove_from_worklist(folder.worklist);
        
        if try_fold_instruction(folder, inst) {
            changed = true;
            // Añadir usuarios a worklist
            add_users_to_worklist(folder.worklist, inst.result);
        }
    }
    
    return changed;
}

fn try_fold_instruction(folder: *ConstantFolder, inst: *Instruction) -> bool {
    switch inst.opcode {
        case OP_ADD:
        case OP_SUB:
        case OP_MUL:
        case OP_DIV:
        case OP_MOD:
            return fold_binary_op(folder, inst);
            
        case OP_NEG:
        case OP_NOT:
            return fold_unary_op(folder, inst);
            
        case OP_CMP:
            return fold_comparison(folder, inst);
            
        case OP_PHI:
            return fold_phi(folder, inst);
            
        case OP_SELECT:
            return fold_select(folder, inst);
            
        case OP_CAST:
            return fold_cast(folder, inst);
            
        case OP_GEP:
            return fold_gep(folder, inst);
            
        default:
            return false;
    }
}

fn fold_binary_op(folder: *ConstantFolder, inst: *Instruction) -> bool {
    let left = get_constant(folder, inst.operands[0]);
    let right = get_constant(folder, inst.operands[1]);
    
    if left == 0 || right == 0 {
        return false;
    }
    
    // Evaluar operación
    let result = alloc(sizeof(Constant));
    result.type = inst.type;
    
    switch inst.opcode {
        case OP_ADD:
            if is_integer_type(inst.type) {
                result.value.i64_val = left.value.i64_val + right.value.i64_val;
            } else {
                result.value.f64_val = left.value.f64_val + right.value.f64_val;
            }
            break;
            
        case OP_MUL:
            if is_integer_type(inst.type) {
                result.value.i64_val = left.value.i64_val * right.value.i64_val;
            } else {
                result.value.f64_val = left.value.f64_val * right.value.f64_val;
            }
            break;
            
        case OP_DIV:
            // Verificar división por cero
            if (is_integer_type(inst.type) && right.value.i64_val == 0) ||
               (is_float_type(inst.type) && right.value.f64_val == 0.0) {
                return false;  // No folding si hay UB
            }
            
            if is_integer_type(inst.type) {
                result.value.i64_val = left.value.i64_val / right.value.i64_val;
            } else {
                result.value.f64_val = left.value.f64_val / right.value.f64_val;
            }
            break;
    }
    
    // Reemplazar instrucción con constante
    replace_with_constant(folder, inst, result);
    return true;
}

// Sparse Conditional Constant Propagation
fn sccp(ssa: *SSAForm) {
    let lattice = create_lattice();
    let cfg_worklist = create_block_worklist();
    let ssa_worklist = create_value_worklist();
    
    // Inicializar lattice
    init_lattice(lattice, ssa);
    
    // Añadir entry block
    mark_executable(cfg_worklist, ssa.entry);
    
    while !is_empty(cfg_worklist) || !is_empty(ssa_worklist) {
        // Procesar bloques ejecutables
        while !is_empty(cfg_worklist) {
            let block = remove_from_worklist(cfg_worklist);
            visit_block(lattice, block, ssa_worklist);
        }
        
        // Procesar valores
        while !is_empty(ssa_worklist) {
            let value = remove_from_worklist(ssa_worklist);
            
            let users = get_users(value);
            let u = 0;
            while u < users.count {
                let user = users.items[u];
                
                if is_phi(user) {
                    visit_phi(lattice, user, ssa_worklist);
                } else if is_executable(get_block(user)) {
                    visit_instruction(lattice, user, ssa_worklist, cfg_worklist);
                }
                
                u = u + 1;
            }
        }
    }
    
    // Reemplazar con constantes descubiertas
    apply_sccp_results(ssa, lattice);
}
```

### Dead Code Elimination

```tempo
// dead_code_elimination.tempo - Eliminar código muerto

struct DCEPass {
    ssa: *SSAForm,
    live: *BitVector,
    worklist: *InstructionList
}

fn eliminate_dead_code(ssa: *SSAForm) -> bool {
    let dce = create_dce_pass(ssa);
    
    // Marcar instrucciones con side effects como vivas
    mark_essential_instructions(dce);
    
    // Propagar liveness
    while !is_empty(dce.worklist) {
        let inst = remove_from_worklist(dce.worklist);
        
        // Marcar operandos como vivos
        let op = 0;
        while op < get_operand_count(inst) {
            let operand = inst.operands[op];
            if is_instruction(operand) {
                mark_live(dce, operand);
            }
            op = op + 1;
        }
        
        // Para phi functions, solo marcar operandos de bloques ejecutables
        if is_phi(inst) {
            mark_phi_operands(dce, inst);
        }
    }
    
    // Eliminar instrucciones muertas
    let changed = false;
    let block = ssa.entry;
    while block != 0 {
        let inst = block.instructions;
        let prev = 0;
        
        while inst != 0 {
            let next = inst.next;
            
            if !is_live(dce, inst) && !has_side_effects(inst) {
                remove_instruction(block, inst, prev);
                changed = true;
            } else {
                prev = inst;
            }
            
            inst = next;
        }
        
        block = get_next_block(block);
    }
    
    return changed;
}

fn mark_essential_instructions(dce: *DCEPass) {
    let block = dce.ssa.entry;
    
    while block != 0 {
        let inst = block.instructions;
        
        while inst != 0 {
            if is_essential(inst) {
                mark_live(dce, inst);
            }
            inst = inst.next;
        }
        
        block = get_next_block(block);
    }
}

fn is_essential(inst: *Instruction) -> bool {
    // Instrucciones con side effects son esenciales
    switch inst.opcode {
        case OP_STORE:
        case OP_CALL:  // A menos que sea marked pure
        case OP_RETURN:
        case OP_BRANCH:
        case OP_INVOKE:
        case OP_ATOMIC:
            return true;
            
        default:
            // Verificar si tiene flag volatile o atomic
            return inst.flags & (FLAG_VOLATILE | FLAG_ATOMIC) != 0;
    }
}

// Aggressive Dead Code Elimination
fn adce(ssa: *SSAForm) -> bool {
    // ADCE puede eliminar loops completos si no tienen efectos
    let cdg = build_control_dependence_graph(ssa);
    let pdg = build_program_dependence_graph(ssa, cdg);
    
    // Marcar como vivo solo lo verdaderamente necesario
    let live = create_instruction_set();
    mark_truly_live(live, ssa);
    
    // Propagar a través de dependencias
    let worklist = create_from_set(live);
    
    while !is_empty(worklist) {
        let inst = remove_from_worklist(worklist);
        
        // Dependencias de datos
        mark_data_dependencies(live, worklist, inst);
        
        // Dependencias de control
        mark_control_dependencies(live, worklist, inst, cdg);
    }
    
    // Eliminar todo lo no marcado
    return remove_unmarked_code(ssa, live);
}
```

### Common Subexpression Elimination (CSE)

```tempo
// cse.tempo - Eliminar subexpresiones comunes

struct CSEPass {
    ssa: *SSAForm,
    value_table: *ValueNumberTable,
    expr_map: *ExpressionMap
}

struct Expression {
    opcode: Opcode,
    type: *Type,
    operands: [3]*SSAValue,
    hash: u64
}

fn eliminate_common_subexpressions(ssa: *SSAForm) -> bool {
    let cse = create_cse_pass(ssa);
    let changed = false;
    
    // Procesar en orden dominador para encontrar más oportunidades
    let dom_tree = build_dominator_tree(ssa.cfg);
    changed = cse_dom_tree(cse, dom_tree.root);
    
    return changed;
}

fn cse_dom_tree(cse: *CSEPass, node: *DomTreeNode) -> bool {
    let changed = false;
    let saved_exprs = get_expr_count(cse.expr_map);
    
    // Procesar instrucciones del bloque
    let inst = node.block.instructions;
    while inst != 0 {
        if is_pure(inst) && !has_memory_effects(inst) {
            let expr = instruction_to_expression(inst);
            
            // Buscar expresión existente
            let existing = lookup_expression(cse.expr_map, expr);
            if existing != 0 {
                // Reemplazar con valor existente
                replace_all_uses(inst.result, existing);
                mark_for_deletion(inst);
                changed = true;
            } else {
                // Añadir nueva expresión
                add_expression(cse.expr_map, expr, inst.result);
            }
        }
        inst = inst.next;
    }
    
    // Procesar hijos recursivamente
    let child = node.first_child;
    while child != 0 {
        changed = changed || cse_dom_tree(cse, child);
        child = child.next_sibling;
    }
    
    // Restaurar estado de expresiones
    restore_expr_count(cse.expr_map, saved_exprs);
    
    return changed;
}

// Global Value Numbering
fn gvn(ssa: *SSAForm) -> bool {
    let gvn = create_gvn_pass(ssa);
    let changed = true;
    let iteration = 0;
    
    while changed && iteration < MAX_GVN_ITERATIONS {
        changed = false;
        
        // Construir tabla de value numbers
        build_value_number_table(gvn);
        
        // Procesar en RPO
        let rpo = compute_rpo(ssa.cfg);
        let i = 0;
        while i < rpo.count {
            changed = changed || process_block_gvn(gvn, rpo.blocks[i]);
            i = i + 1;
        }
        
        iteration = iteration + 1;
    }
    
    return iteration > 0;
}

fn process_block_gvn(gvn: *GVNPass, block: *BasicBlock) -> bool {
    let changed = false;
    
    // Procesar phi nodes
    let phi = block.phi_functions;
    while phi != 0 {
        if simplify_phi(gvn, phi) {
            changed = true;
        }
        phi = phi.next;
    }
    
    // Procesar instrucciones
    let inst = block.instructions;
    while inst != 0 {
        let vn = compute_value_number(gvn, inst);
        
        // Buscar líder con mismo value number
        let leader = find_leader(gvn, vn);
        if leader != 0 && leader != inst.result {
            replace_all_uses(inst.result, leader);
            mark_for_deletion(inst);
            changed = true;
        } else {
            set_leader(gvn, vn, inst.result);
        }
        
        inst = inst.next;
    }
    
    return changed;
}
```

### Loop Optimizations

```tempo
// loop_optimizations.tempo - Optimizaciones específicas de loops

struct LoopOptimizer {
    ssa: *SSAForm,
    loop_info: *LoopInfo,
    scev: *ScalarEvolution
}

// Loop Invariant Code Motion (LICM)
fn hoist_loop_invariants(optimizer: *LoopOptimizer, loop: *Loop) -> bool {
    let changed = false;
    let preheader = get_or_create_preheader(loop);
    
    // Identificar instrucciones invariantes
    let worklist = create_instruction_list();
    let invariant = create_instruction_set();
    
    // Semilla: operandos definidos fuera del loop
    let block = loop.header;
    while block != 0 && is_in_loop(block, loop) {
        let inst = block.instructions;
        while inst != 0 {
            if all_operands_loop_invariant(inst, loop, invariant) {
                add_to_worklist(worklist, inst);
            }
            inst = inst.next;
        }
        block = get_next_in_loop(block, loop);
    }
    
    // Propagar invariancia
    while !is_empty(worklist) {
        let inst = remove_from_worklist(worklist);
        
        if can_hoist(inst, loop) {
            add_to_set(invariant, inst);
            
            // Añadir usuarios que podrían volverse invariantes
            let users = get_users(inst.result);
            let u = 0;
            while u < users.count {
                if is_in_loop(get_block(users.items[u]), loop) &&
                   !is_in_set(invariant, users.items[u]) {
                    add_to_worklist(worklist, users.items[u]);
                }
                u = u + 1;
            }
        }
    }
    
    // Mover instrucciones invariantes al preheader
    let iter = create_set_iterator(invariant);
    while has_next(iter) {
        let inst = next_instruction(iter);
        move_to_block(inst, preheader);
        changed = true;
    }
    
    return changed;
}

fn can_hoist(inst: *Instruction, loop: *Loop) -> bool {
    // No hoist si:
    // 1. Tiene side effects
    // 2. Puede throw
    // 3. Es una operación de memoria que podría alias
    
    if has_side_effects(inst) || may_throw(inst) {
        return false;
    }
    
    if is_memory_op(inst) {
        // Verificar que no hay stores en el loop que puedan alias
        return !may_alias_with_loop_stores(inst, loop);
    }
    
    return true;
}

// Loop Unrolling
fn unroll_loop(optimizer: *LoopOptimizer, loop: *Loop, factor: i32) -> bool {
    // Verificar que es seguro unroll
    if !is_simple_loop(loop) || !has_constant_trip_count(loop) {
        return false;
    }
    
    let trip_count = get_trip_count(loop);
    if trip_count % factor != 0 && trip_count != -1 {
        // Necesitaríamos remainder loop
        if trip_count < factor * 2 {
            return false;  // No vale la pena
        }
    }
    
    // Clonar cuerpo del loop factor-1 veces
    let original_blocks = collect_loop_blocks(loop);
    let clones = alloc((factor - 1) * sizeof(*BasicBlock));
    
    let i = 1;
    while i < factor {
        clones[i-1] = clone_blocks(original_blocks);
        i = i + 1;
    }
    
    // Reconectar control flow
    reconnect_unrolled_loop(loop, original_blocks, clones, factor);
    
    // Actualizar induction variables
    update_induction_variables(loop, factor);
    
    // Simplificar el resultado
    simplify_unrolled_loop(optimizer, loop);
    
    return true;
}

// Loop Strength Reduction
fn reduce_loop_strength(optimizer: *LoopOptimizer, loop: *Loop) -> bool {
    let changed = false;
    
    // Buscar multiplicaciones/divisiones por induction variables
    let ivs = find_induction_variables(loop);
    
    let block = loop.header;
    while block != 0 && is_in_loop(block, loop) {
        let inst = block.instructions;
        while inst != 0 {
            if inst.opcode == OP_MUL {
                let iv = get_induction_var(inst.operands[0], ivs);
                let constant = get_constant_operand(inst.operands[1]);
                
                if iv != 0 && constant != 0 {
                    // Reemplazar i * c con suma acumulativa
                    replace_with_accumulator(inst, iv, constant);
                    changed = true;
                }
            }
            inst = inst.next;
        }
        block = get_next_in_loop(block, loop);
    }
    
    return changed;
}

// Loop Fusion
fn fuse_loops(optimizer: *LoopOptimizer, loop1: *Loop, loop2: *Loop) -> bool {
    // Verificar que es legal fusionar
    if !have_same_bounds(loop1, loop2) ||
       !are_adjacent(loop1, loop2) ||
       have_dependencies(loop1, loop2) {
        return false;
    }
    
    // Fusionar bodies
    let exit1 = get_loop_exit(loop1);
    let header2 = loop2.header;
    
    // Redirigir salida de loop1 al body de loop2
    redirect_branch(exit1, header2, get_loop_body(loop2));
    
    // Combinar exits
    merge_loop_exits(loop1, loop2);
    
    // Actualizar metadatos
    update_loop_info(optimizer.loop_info, loop1);
    remove_loop(optimizer.loop_info, loop2);
    
    return true;
}
```

### Framework de Optimización

```tempo
// optimization_framework.tempo - Framework extensible para optimizaciones

struct OptimizationPass {
    name: *char,
    run: fn(*Module) -> bool,
    requires: **AnalysisID,
    preserves: **AnalysisID,
    invalidates: **AnalysisID
}

struct PassManager {
    passes: **OptimizationPass,
    pass_count: i32,
    analyses: *AnalysisManager,
    module: *Module
}

fn create_optimization_pipeline() -> *PassManager {
    let pm = create_pass_manager();
    
    // Early optimizations
    add_pass(pm, create_instcombine_pass());
    add_pass(pm, create_simplifycfg_pass());
    add_pass(pm, create_sroa_pass());
    
    // Main optimization loop
    add_pass(pm, create_function_pass_manager([
        create_gvn_pass(),
        create_sccp_pass(),
        create_dce_pass(),
        create_licm_pass(),
        create_loop_unroll_pass(),
        create_strength_reduce_pass()
    ]));
    
    // Late optimizations
    add_pass(pm, create_instcombine_pass());
    add_pass(pm, create_branch_folding_pass());
    add_pass(pm, create_merge_blocks_pass());
    
    return pm;
}

fn run_optimization_pipeline(pm: *PassManager) -> bool {
    let changed = true;
    let iteration = 0;
    
    while changed && iteration < MAX_OPT_ITERATIONS {
        changed = false;
        
        let p = 0;
        while p < pm.pass_count {
            let pass = pm.passes[p];
            
            // Verificar análisis requeridos
            ensure_analyses(pm.analyses, pass.requires);
            
            // Ejecutar pass
            if pass.run(pm.module) {
                changed = true;
                
                // Invalidar análisis
                invalidate_analyses(pm.analyses, pass.invalidates);
            }
            
            // Verificación opcional
            if DEBUG_VERIFY {
                verify_module(pm.module);
            }
            
            p = p + 1;
        }
        
        iteration = iteration + 1;
    }
    
    return iteration > 0;
}

// Pattern-based instruction combining
fn instcombine(inst: *Instruction) -> bool {
    // Catálogo de patterns
    switch inst.opcode {
        case OP_ADD:
            // x + 0 => x
            if is_zero(inst.operands[1]) {
                replace_with(inst, inst.operands[0]);
                return true;
            }
            // x + x => x * 2
            if inst.operands[0] == inst.operands[1] {
                replace_with_mul(inst, inst.operands[0], 2);
                return true;
            }
            break;
            
        case OP_MUL:
            // x * 0 => 0
            if is_zero(inst.operands[1]) {
                replace_with_constant(inst, 0);
                return true;
            }
            // x * 1 => x
            if is_one(inst.operands[1]) {
                replace_with(inst, inst.operands[0]);
                return true;
            }
            // x * 2^n => x << n
            if is_power_of_two(inst.operands[1]) {
                let shift = log2(get_constant_value(inst.operands[1]));
                replace_with_shift(inst, inst.operands[0], shift);
                return true;
            }
            break;
            
        case OP_AND:
            // x & x => x
            if inst.operands[0] == inst.operands[1] {
                replace_with(inst, inst.operands[0]);
                return true;
            }
            // x & 0 => 0
            if is_zero(inst.operands[1]) {
                replace_with_constant(inst, 0);
                return true;
            }
            // x & -1 => x
            if is_all_ones(inst.operands[1]) {
                replace_with(inst, inst.operands[0]);
                return true;
            }
            break;
    }
    
    return false;
}
```

## 3. Ejercicios (20%)

### Ejercicio 1: Construcción SSA Minimal
Implementa el algoritmo de Braun et al. para construcción SSA sin precomputar dominance frontier:
```tempo
fn minimal_ssa_construction(cfg: *ControlFlowGraph) -> *SSAForm {
    // Construir SSA on-the-fly durante un recorrido del CFG
}
```

### Ejercicio 2: Alias Analysis
Implementa análisis de alias para mejorar optimizaciones de memoria:
```tempo
fn may_alias(ptr1: *Value, ptr2: *Value) -> bool {
    // Determinar si dos punteros pueden apuntar a la misma memoria
}
```

### Ejercicio 3: Partial Redundancy Elimination
Implementa PRE para eliminar cálculos parcialmente redundantes:
```tempo
fn pre_optimization(ssa: *SSAForm) -> bool {
    // Mover cálculos para eliminar redundancia parcial
}
```

### Ejercicio 4: Auto-vectorización
Implementa vectorización automática de loops:
```tempo
fn vectorize_loop(loop: *Loop, vector_width: i32) -> bool {
    // Transformar operaciones escalares en vectoriales
}
```

### Ejercicio 5: Profile-Guided Optimization
Usa información de profiling para optimizaciones dirigidas:
```tempo
fn pgo_optimize(ssa: *SSAForm, profile: *ProfileData) -> bool {
    // Optimizar basándose en frecuencias de ejecución reales
}
```

## Proyecto Final: Optimizador Completo

Implementa un optimizador de producción que incluya:

1. **Infraestructura SSA**:
   - Construcción y destrucción eficiente
   - Verificación de propiedades SSA
   - Utilidades de manipulación
   - Pretty printing

2. **Suite de optimizaciones**:
   - Todas las optimizaciones clásicas
   - Optimizaciones inter-procedurales
   - Optimizaciones específicas de arquitectura
   - Machine learning para decisiones

3. **Análisis avanzados**:
   - Alias analysis preciso
   - Escape analysis
   - Value range analysis
   - Dependence analysis

4. **Herramientas**:
   - Visualización de transformaciones
   - Benchmarking automático
   - A/B testing de optimizaciones
   - Reporte de mejoras

## Recursos Adicionales

### Papers Fundamentales
- "Efficiently Computing Static Single Assignment Form" - Cytron et al.
- "A Simple, Fast Dominance Algorithm" - Cooper et al.
- "Global Value Numbers and Redundant Computations" - Rosen et al.
- "LLVM: A Compilation Framework for Lifelong Program Analysis" - Lattner

### Implementaciones de Referencia
- LLVM: Framework moderno y extensible
- GCC: Décadas de optimizaciones probadas
- V8 TurboFan: Optimizaciones JIT agresivas
- Cranelift: Diseño moderno en Rust

## Conclusión

Las optimizaciones basadas en SSA forman el corazón de los compiladores modernos. Las técnicas presentadas permiten:

1. **Código eficiente**: Eliminar redundancia y overhead
2. **Análisis preciso**: SSA simplifica muchos análisis
3. **Optimizaciones poderosas**: Transformaciones complejas se vuelven tractables
4. **Extensibilidad**: Framework permite añadir nuevas optimizaciones

La implementación en Chronos demuestra que es posible construir un optimizador sofisticado con diseño limpio y eficiente.