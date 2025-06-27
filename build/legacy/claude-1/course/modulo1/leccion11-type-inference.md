╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 11: Type Inference - Hindley-Milner and beyond

## Objetivos de la Lección
- Comprender el algoritmo de inferencia de tipos Hindley-Milner
- Implementar inferencia de tipos completa para Tempo
- Extender el sistema con features más allá de HM clásico
- Optimizar el proceso de inferencia para compilación rápida

## 1. Teoría (20%)

### El Sistema Hindley-Milner

El sistema de tipos Hindley-Milner (HM) es la base de la inferencia de tipos en lenguajes funcionales modernos. Sus características principales:

1. **Principal Types**: Cada expresión tiene un tipo más general
2. **Decidible**: La inferencia siempre termina
3. **Complete**: No requiere anotaciones de tipo
4. **Sound**: Los programas bien tipados no fallan

### Conceptos Fundamentales

```tempo
// Variables de tipo
α, β, γ, ...

// Esquemas de tipo (type schemes)
∀α. α → α        // Función identidad
∀α β. (α → β) → [α] → [β]  // map

// Constraints
α = β            // Igualdad
α = τ₁ → τ₂      // Función
```

### Algoritmo W

El algoritmo W de Damas-Milner realiza inferencia en dos fases:
1. **Generación de constraints**: Recorre el AST generando ecuaciones
2. **Unificación**: Resuelve las ecuaciones encontrando sustituciones

### Extensiones Modernas

- **Row Polymorphism**: Para records extensibles
- **Rank-N Types**: Polimorfismo de alto orden
- **Type Classes**: Polimorfismo ad-hoc
- **Effect Systems**: Tracking de efectos secundarios

## 2. Práctica (60%)

### Representación de Tipos para Inferencia

```tempo
// type_inference.tempo - Sistema de inferencia de tipos HM

enum TypeExpr {
    TYPE_VAR,           // Variable de tipo
    TYPE_CONST,         // Tipo concreto (i32, bool, etc)
    TYPE_ARROW,         // Función
    TYPE_APP,           // Aplicación de tipo
    TYPE_FORALL         // Cuantificador universal
}

struct TypeVar {
    id: i32,
    name: *char,
    level: i32,         // Para generalización
    ref: *Type          // Para unificación
}

struct Type {
    kind: TypeExpr,
    
    union {
        var: *TypeVar,
        
        constant: struct {
            name: *char,
            arity: i32
        },
        
        arrow: struct {
            from: *Type,
            to: *Type
        },
        
        app: struct {
            ctor: *Type,
            args: **Type,
            arg_count: i32
        },
        
        forall: struct {
            vars: **TypeVar,
            var_count: i32,
            body: *Type
        }
    }
}

// Estado del inferenciador
struct InferenceState {
    next_var_id: i32,
    current_level: i32,
    subst: *Substitution,
    constraints: *ConstraintList
}

struct Substitution {
    entries: *SubstEntry,
    count: i32,
    capacity: i32
}

struct SubstEntry {
    var: *TypeVar,
    type: *Type
}

// Crear variable de tipo fresca
fn fresh_type_var(state: *InferenceState, name: *char) -> *Type {
    let var = alloc(sizeof(TypeVar));
    var.id = state.next_var_id;
    state.next_var_id = state.next_var_id + 1;
    var.name = name;
    var.level = state.current_level;
    var.ref = 0;
    
    let type = alloc(sizeof(Type));
    type.kind = TYPE_VAR;
    type.var = var;
    return type;
}

// Aplicar sustitución
fn apply_subst(subst: *Substitution, type: *Type) -> *Type {
    switch type.kind {
        case TYPE_VAR:
            // Buscar en sustitución
            let entry = lookup_subst(subst, type.var);
            if entry != 0 {
                return apply_subst(subst, entry.type);
            }
            return type;
            
        case TYPE_CONST:
            return type;
            
        case TYPE_ARROW:
            let from = apply_subst(subst, type.arrow.from);
            let to = apply_subst(subst, type.arrow.to);
            if from == type.arrow.from && to == type.arrow.to {
                return type;
            }
            return make_arrow_type(from, to);
            
        case TYPE_APP:
            let ctor = apply_subst(subst, type.app.ctor);
            let args = alloc(type.app.arg_count * sizeof(*Type));
            let changed = false;
            
            let i = 0;
            while i < type.app.arg_count {
                args[i] = apply_subst(subst, type.app.args[i]);
                if args[i] != type.app.args[i] {
                    changed = true;
                }
                i = i + 1;
            }
            
            if !changed && ctor == type.app.ctor {
                return type;
            }
            return make_app_type(ctor, args, type.app.arg_count);
            
        case TYPE_FORALL:
            // No sustituir variables cuantificadas
            let body = apply_subst_except(subst, type.forall.body, 
                                        type.forall.vars, type.forall.var_count);
            if body == type.forall.body {
                return type;
            }
            return make_forall_type(type.forall.vars, type.forall.var_count, body);
    }
}
```

### Algoritmo de Unificación

```tempo
// Unificación de Robinson con occurs check

struct UnificationError {
    kind: ErrorKind,
    type1: *Type,
    type2: *Type,
    message: *char
}

enum ErrorKind {
    ERROR_OCCURS_CHECK,
    ERROR_TYPE_MISMATCH,
    ERROR_ARITY_MISMATCH
}

fn unify(state: *InferenceState, t1: *Type, t2: *Type) -> *UnificationError {
    // Derreferenciar variables
    t1 = deref_type(t1);
    t2 = deref_type(t2);
    
    // Mismo tipo
    if types_equal(t1, t2) {
        return 0;
    }
    
    // Variable en t1
    if t1.kind == TYPE_VAR {
        return unify_var(state, t1.var, t2);
    }
    
    // Variable en t2
    if t2.kind == TYPE_VAR {
        return unify_var(state, t2.var, t1);
    }
    
    // Funciones
    if t1.kind == TYPE_ARROW && t2.kind == TYPE_ARROW {
        let err = unify(state, t1.arrow.from, t2.arrow.from);
        if err != 0 return err;
        return unify(state, t1.arrow.to, t2.arrow.to);
    }
    
    // Aplicaciones de tipo
    if t1.kind == TYPE_APP && t2.kind == TYPE_APP {
        if t1.app.arg_count != t2.app.arg_count {
            return make_error(ERROR_ARITY_MISMATCH, t1, t2, "Arity mismatch");
        }
        
        let err = unify(state, t1.app.ctor, t2.app.ctor);
        if err != 0 return err;
        
        let i = 0;
        while i < t1.app.arg_count {
            err = unify(state, t1.app.args[i], t2.app.args[i]);
            if err != 0 return err;
            i = i + 1;
        }
        return 0;
    }
    
    // Constantes
    if t1.kind == TYPE_CONST && t2.kind == TYPE_CONST {
        if string_equal(t1.constant.name, t2.constant.name) {
            return 0;
        }
    }
    
    return make_error(ERROR_TYPE_MISMATCH, t1, t2, "Cannot unify types");
}

fn unify_var(state: *InferenceState, var: *TypeVar, type: *Type) -> *UnificationError {
    // Occurs check
    if occurs_check(var, type) {
        return make_error(ERROR_OCCURS_CHECK, var_to_type(var), type, 
                         "Infinite type");
    }
    
    // Actualizar nivel para generalización correcta
    update_level(type, var.level);
    
    // Añadir a sustitución
    add_subst(state.subst, var, type);
    
    // Union-find optimization
    var.ref = type;
    
    return 0;
}

fn occurs_check(var: *TypeVar, type: *Type) -> bool {
    type = deref_type(type);
    
    switch type.kind {
        case TYPE_VAR:
            return var.id == type.var.id;
            
        case TYPE_CONST:
            return false;
            
        case TYPE_ARROW:
            return occurs_check(var, type.arrow.from) || 
                   occurs_check(var, type.arrow.to);
                   
        case TYPE_APP:
            if occurs_check(var, type.app.ctor) {
                return true;
            }
            let i = 0;
            while i < type.app.arg_count {
                if occurs_check(var, type.app.args[i]) {
                    return true;
                }
                i = i + 1;
            }
            return false;
            
        case TYPE_FORALL:
            return occurs_check(var, type.forall.body);
    }
}
```

### Algoritmo W - Inferencia Completa

```tempo
// Implementación del algoritmo W

struct TypeEnv {
    bindings: *Binding,
    count: i32,
    parent: *TypeEnv
}

struct Binding {
    name: *char,
    scheme: *TypeScheme
}

struct TypeScheme {
    vars: **TypeVar,
    var_count: i32,
    type: *Type
}

// Inferir tipo de expresión
fn infer_expr(state: *InferenceState, env: *TypeEnv, expr: *ASTNode) 
    -> Result<*Type, *InferenceError> {
    
    switch expr.type {
        case NODE_VAR:
            return infer_var(state, env, expr.name);
            
        case NODE_LAMBDA:
            return infer_lambda(state, env, expr);
            
        case NODE_APP:
            return infer_app(state, env, expr);
            
        case NODE_LET:
            return infer_let(state, env, expr);
            
        case NODE_LITERAL:
            return infer_literal(state, expr);
            
        case NODE_IF:
            return infer_if(state, env, expr);
            
        default:
            return Err(make_inference_error("Unknown expression type"));
    }
}

fn infer_var(state: *InferenceState, env: *TypeEnv, name: *char) 
    -> Result<*Type, *InferenceError> {
    
    let binding = lookup_env(env, name);
    if binding == 0 {
        return Err(make_inference_error("Unbound variable"));
    }
    
    // Instanciar esquema de tipo
    return Ok(instantiate(state, binding.scheme));
}

fn infer_lambda(state: *InferenceState, env: *TypeEnv, lambda: *ASTNode) 
    -> Result<*Type, *InferenceError> {
    
    // Crear tipo fresco para parámetro
    let param_type = fresh_type_var(state, lambda.param);
    
    // Extender environment
    let param_scheme = make_monotype(param_type);
    let new_env = extend_env(env, lambda.param, param_scheme);
    
    // Inferir tipo del cuerpo
    let body_type = infer_expr(state, new_env, lambda.body)?;
    
    // Retornar tipo función
    return Ok(make_arrow_type(param_type, body_type));
}

fn infer_app(state: *InferenceState, env: *TypeEnv, app: *ASTNode) 
    -> Result<*Type, *InferenceError> {
    
    // Inferir tipos de función y argumento
    let fun_type = infer_expr(state, env, app.function)?;
    let arg_type = infer_expr(state, env, app.argument)?;
    
    // Crear tipo fresco para resultado
    let result_type = fresh_type_var(state, "result");
    
    // Unificar con tipo función esperado
    let expected = make_arrow_type(arg_type, result_type);
    let err = unify(state, fun_type, expected);
    if err != 0 {
        return Err(unify_error_to_inference_error(err));
    }
    
    return Ok(result_type);
}

fn infer_let(state: *InferenceState, env: *TypeEnv, let_expr: *ASTNode) 
    -> Result<*Type, *InferenceError> {
    
    // Inferir tipo del valor
    let value_type = infer_expr(state, env, let_expr.value)?;
    
    // Generalizar
    enter_level(state);
    let gen_type = generalize(state, env, value_type);
    leave_level(state);
    
    // Extender environment
    let new_env = extend_env(env, let_expr.name, gen_type);
    
    // Inferir tipo del cuerpo
    return infer_expr(state, new_env, let_expr.body);
}

// Generalización
fn generalize(state: *InferenceState, env: *TypeEnv, type: *Type) -> *TypeScheme {
    // Aplicar sustitución actual
    type = apply_subst(state.subst, type);
    
    // Encontrar variables libres que se pueden generalizar
    let free_vars = collect_generalizable_vars(type, state.current_level);
    
    if free_vars.count == 0 {
        return make_monotype(type);
    }
    
    // Crear esquema polimórfico
    return make_polytype(free_vars.vars, free_vars.count, type);
}

// Instanciación
fn instantiate(state: *InferenceState, scheme: *TypeScheme) -> *Type {
    if scheme.var_count == 0 {
        return scheme.type;
    }
    
    // Crear sustitución con variables frescas
    let fresh_subst = create_substitution();
    
    let i = 0;
    while i < scheme.var_count {
        let fresh = fresh_type_var(state, scheme.vars[i].name);
        add_subst(fresh_subst, scheme.vars[i], fresh);
        i = i + 1;
    }
    
    // Aplicar sustitución
    return apply_subst(fresh_subst, scheme.type);
}
```

### Inferencia con Row Polymorphism

```tempo
// Extensión para records polimórficos

struct RowType {
    fields: *Field,
    field_count: i32,
    rest: *Type  // Variable de row o RowEmpty
}

struct Field {
    label: *char,
    type: *Type
}

// Inferir acceso a campo
fn infer_field_access(state: *InferenceState, env: *TypeEnv, 
                      record: *ASTNode, field: *char) 
    -> Result<*Type, *InferenceError> {
    
    // Inferir tipo del record
    let record_type = infer_expr(state, env, record)?;
    
    // Crear variables frescas
    let field_type = fresh_type_var(state, "field");
    let rest_row = fresh_row_var(state, "row");
    
    // Crear tipo record esperado
    let expected = make_record_type_with_field(field, field_type, rest_row);
    
    // Unificar
    let err = unify(state, record_type, expected);
    if err != 0 {
        return Err(unify_error_to_inference_error(err));
    }
    
    return Ok(field_type);
}

// Unificación de rows
fn unify_rows(state: *InferenceState, row1: *RowType, row2: *RowType) 
    -> *UnificationError {
    
    // Algoritmo de unificación para rows de Rémy
    // 1. Encontrar campos comunes
    // 2. Unificar tipos de campos comunes
    // 3. Construir row restante con campos no comunes
    
    let common = find_common_fields(row1, row2);
    let i = 0;
    while i < common.count {
        let f1 = find_field(row1, common.fields[i].label);
        let f2 = find_field(row2, common.fields[i].label);
        
        let err = unify(state, f1.type, f2.type);
        if err != 0 return err;
        
        i = i + 1;
    }
    
    // Construir rows restantes
    let rest1 = remove_fields(row1, common);
    let rest2 = remove_fields(row2, common);
    
    return unify_row_rests(state, rest1, row1.rest, rest2, row2.rest);
}
```

### Type Classes y Constraints

```tempo
// Sistema de type classes estilo Haskell

struct TypeClass {
    name: *char,
    params: **TypeVar,
    param_count: i32,
    methods: *Method,
    method_count: i32,
    superclasses: **TypeClass,
    superclass_count: i32
}

struct Method {
    name: *char,
    type: *TypeScheme
}

struct Instance {
    class: *TypeClass,
    types: **Type,
    type_count: i32,
    methods: *MethodImpl,
    constraints: *Constraint
}

struct Constraint {
    class: *TypeClass,
    type: *Type,
    next: *Constraint
}

// Inferencia con constraints
fn infer_with_constraints(state: *InferenceState, env: *TypeEnv, 
                         expr: *ASTNode) 
    -> Result<QualifiedType, *InferenceError> {
    
    // Inferir tipo principal
    let type = infer_expr(state, env, expr)?;
    
    // Recolectar constraints generados
    let constraints = collect_constraints(state);
    
    // Simplificar constraints
    let simplified = simplify_constraints(state, env, constraints);
    
    // Verificar satisfacibilidad
    if !all_satisfiable(state, env, simplified) {
        return Err(make_inference_error("Unsatisfiable constraints"));
    }
    
    return Ok(QualifiedType {
        constraints: simplified,
        type: type
    });
}

// Resolución de constraints
fn resolve_constraint(state: *InferenceState, env: *TypeEnv, 
                     constraint: *Constraint) -> *Instance {
    
    // Buscar instancia exacta
    let instance = lookup_instance(env, constraint.class, constraint.type);
    if instance != 0 {
        return instance;
    }
    
    // Intentar con superclases
    let i = 0;
    while i < constraint.class.superclass_count {
        let super = constraint.class.superclasses[i];
        let super_constraint = make_constraint(super, constraint.type);
        instance = resolve_constraint(state, env, super_constraint);
        if instance != 0 {
            return derive_instance(instance, constraint.class);
        }
        i = i + 1;
    }
    
    return 0;
}
```

### Optimizaciones de Inferencia

```tempo
// Técnicas para hacer la inferencia más eficiente

// 1. Memoización de tipos inferidos
struct TypeCache {
    entries: *CacheEntry,
    count: i32,
    capacity: i32
}

struct CacheEntry {
    expr: *ASTNode,
    env_hash: u64,
    type: *Type
}

fn infer_with_cache(state: *InferenceState, env: *TypeEnv, 
                   expr: *ASTNode) -> Result<*Type, *InferenceError> {
    
    // Buscar en cache
    let hash = hash_env(env);
    let cached = lookup_cache(state.cache, expr, hash);
    if cached != 0 {
        return Ok(instantiate(state, cached));
    }
    
    // Inferir normalmente
    let type = infer_expr(state, env, expr)?;
    
    // Guardar en cache
    add_to_cache(state.cache, expr, hash, generalize(state, env, type));
    
    return Ok(type);
}

// 2. Inferencia incremental
struct IncrementalInferencer {
    base_state: *InferenceState,
    change_set: *ChangeSet,
    affected: *AffectedSet
}

fn incremental_infer(inc: *IncrementalInferencer, change: *Change) 
    -> Result<*TypeDiff, *InferenceError> {
    
    // Identificar nodos afectados
    compute_affected_nodes(inc, change);
    
    // Re-inferir solo nodos afectados
    let diff = create_type_diff();
    
    let node = inc.affected.nodes;
    while node != 0 {
        let old_type = get_cached_type(node);
        let new_type = infer_expr(inc.base_state, node.env, node)?;
        
        if !types_equal(old_type, new_type) {
            add_diff(diff, node, old_type, new_type);
        }
        
        node = node.next;
    }
    
    return Ok(diff);
}

// 3. Inferencia paralela
fn parallel_infer(state: *InferenceState, modules: **Module, count: i32) 
    -> Result<*TypeInfo, *InferenceError> {
    
    // Fase 1: Inferir signatures en paralelo
    let signatures = alloc(count * sizeof(*ModuleSignature));
    
    parallel_for(0, count, fn(i: i32) {
        signatures[i] = infer_module_signature(state, modules[i]);
    });
    
    // Fase 2: Resolver dependencias
    let deps = resolve_dependencies(modules, signatures, count);
    
    // Fase 3: Inferir implementaciones en orden topológico
    let sorted = topological_sort(deps);
    
    let i = 0;
    while i < count {
        let module = sorted[i];
        infer_module_body(state, module, signatures);
        i = i + 1;
    }
    
    return Ok(collect_type_info(signatures, count));
}

// 4. Compartir estructura con hash-consing
struct TypeTable {
    types: **Type,
    count: i32,
    capacity: i32,
    hash_table: *HashEntry
}

fn intern_type(table: *TypeTable, type: *Type) -> *Type {
    let hash = hash_type(type);
    let entry = lookup_hash(table.hash_table, hash);
    
    while entry != 0 {
        if types_equal(entry.type, type) {
            return entry.type;
        }
        entry = entry.next;
    }
    
    // Añadir nuevo tipo
    let interned = copy_type(type);
    add_to_table(table, interned, hash);
    return interned;
}
```

### Inferencia Bidireccional Completa

```tempo
// Sistema bidireccional más expresivo

enum Mode {
    MODE_INFER,    // Inferir tipo
    MODE_CHECK     // Verificar contra tipo esperado
}

fn bidirectional_infer(state: *InferenceState, env: *TypeEnv, 
                      expr: *ASTNode, mode: Mode, expected: *Type) 
    -> Result<*Type, *InferenceError> {
    
    switch expr.type {
        case NODE_LAMBDA:
            if mode == MODE_CHECK && expected.kind == TYPE_ARROW {
                // Modo check: usar tipo esperado para parámetro
                return check_lambda(state, env, expr, expected);
            } else {
                // Modo infer: crear variable fresca
                return infer_lambda(state, env, expr);
            }
            
        case NODE_IF:
            // If siempre necesita check para las ramas
            return check_if(state, env, expr, mode, expected);
            
        case NODE_APP:
            // Aplicación siempre infiere
            let type = infer_app(state, env, expr);
            if mode == MODE_CHECK {
                unify(state, type, expected)?;
            }
            return Ok(type);
            
        case NODE_ANN:
            // Anotación de tipo
            let ann_type = expr.annotation;
            check_expr(state, env, expr.expr, ann_type)?;
            if mode == MODE_CHECK {
                unify(state, ann_type, expected)?;
            }
            return Ok(ann_type);
    }
}

fn check_lambda(state: *InferenceState, env: *TypeEnv, 
               lambda: *ASTNode, expected: *Type) 
    -> Result<*Type, *InferenceError> {
    
    // Descomponer tipo esperado
    if expected.kind != TYPE_ARROW {
        return Err(make_inference_error("Expected function type"));
    }
    
    let param_type = expected.arrow.from;
    let return_type = expected.arrow.to;
    
    // Extender environment con tipo conocido
    let param_scheme = make_monotype(param_type);
    let new_env = extend_env(env, lambda.param, param_scheme);
    
    // Check del cuerpo con tipo esperado
    check_expr(state, new_env, lambda.body, return_type)?;
    
    return Ok(expected);
}
```

## 3. Ejercicios (20%)

### Ejercicio 1: Inferencia para Pattern Matching
Implementa inferencia de tipos para pattern matching con exhaustividad:
```tempo
fn match_option<T>(opt: Option<T>) -> i32 {
    match opt {
        None => 0,
        Some(x) => 1
    }
}
```

### Ejercicio 2: Tipos de Rango Superior
Extiende el sistema para soportar rank-2 types:
```tempo
fn apply_to_pair<A, B>(f: forall<T>. T -> T, pair: (A, B)) -> (A, B) {
    return (f(pair.0), f(pair.1));
}
```

### Ejercicio 3: Inferencia de Efectos
Implementa un sistema de efectos simple:
```tempo
effect IO;
effect State<S>;

fn pure_function(x: i32) -> i32 { x + 1 }
fn io_function() -> i32 with IO { read_int() }
```

### Ejercicio 4: Tipos Dependientes Ligeros
Añade soporte para tipos indexados por valores:
```tempo
fn safe_index<T, const N: usize>(arr: [T; N], idx: BoundedInt<0, N>) -> T {
    return arr[idx];
}
```

### Ejercicio 5: Inferencia de Lifetimes
Implementa inferencia básica de lifetimes para memoria segura:
```tempo
fn longest<'a>(x: &'a str, y: &'a str) -> &'a str {
    if x.len() > y.len() { x } else { y }
}
```

## Proyecto Final: Sistema de Inferencia Avanzado

Implementa un sistema de inferencia completo que incluya:

1. **Características Core**:
   - Hindley-Milner completo
   - Let-polymorphism
   - Mutually recursive definitions
   - Pattern matching exhaustivo

2. **Extensiones**:
   - Type classes con functional dependencies
   - Higher-rank types
   - Existential types
   - GADTs básicos

3. **Optimizaciones**:
   - Compartir tipos con hash-consing
   - Inferencia incremental
   - Paralelización
   - Caching agresivo

4. **Diagnósticos**:
   - Mensajes de error precisos
   - Sugerencias de fixes
   - Explicación del proceso de inferencia
   - Debugging interactivo

## Recursos Adicionales

### Papers Fundamentales
- "Principal type-schemes for functional programs" - Damas & Milner
- "Complete and Easy Bidirectional Typechecking" - Dunfield & Krishnaswami  
- "Extensible records with scoped labels" - Leijen
- "OutsideIn(X): Modular type inference with local assumptions" - SPJ et al.

### Implementaciones de Referencia
- OCaml: Implementación clásica de HM
- Haskell: Type classes y extensiones
- Rust: Inferencia con lifetimes
- Scala: Higher-kinded types

## Conclusión

La inferencia de tipos Hindley-Milner y sus extensiones permiten escribir código seguro y expresivo sin annotaciones excesivas. Las técnicas presentadas en esta lección forman la base de los sistemas de tipos modernos y permiten:

1. **Verificación automática**: Sin burden de anotaciones
2. **Expresividad**: Polimorfismo y abstracción
3. **Performance**: Inferencia eficiente
4. **Extensibilidad**: Base para features avanzados

El sistema implementado para Tempo combina la elegancia teórica de HM con optimizaciones prácticas necesarias para un compilador de producción.