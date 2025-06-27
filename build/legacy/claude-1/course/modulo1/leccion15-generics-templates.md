╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 15: Generics y Templates - Parametric polymorphism implementation

## Objetivos de la Lección
- Comprender los fundamentos del polimorfismo paramétrico
- Implementar un sistema de generics eficiente
- Dominar técnicas de monomorphization y especialización
- Desarrollar optimizaciones específicas para código genérico

## 1. Teoría (20%)

### Polimorfismo Paramétrico

El polimorfismo paramétrico permite escribir código que funciona con múltiples tipos sin perder type safety:

```tempo
fn identity<T>(x: T) -> T {
    return x;
}

// Funciona con cualquier tipo
identity(42)      // T = i32
identity("hello") // T = *char
identity(3.14)    // T = f64
```

### Estrategias de Implementación

1. **Monomorphization**: Generar código especializado para cada tipo
2. **Boxing**: Usar representación uniforme con indirección
3. **Híbrido**: Combinar ambas estrategias
4. **Reified Generics**: Pasar información de tipos en runtime

### Trade-offs

- **Monomorphization**: Código rápido pero más binario
- **Boxing**: Código compacto pero overhead de indirección
- **Especialización**: Optimizaciones específicas por tipo

### Constraints y Bounds

Los generics útiles necesitan expresar relaciones entre tipos:

```tempo
fn sort<T: Ord>(array: &mut [T]) {
    // T debe implementar ordenamiento
}

fn hash<T: Hash + Eq>(value: &T) -> u64 {
    // T debe ser hasheable y comparable
}
```

## 2. Práctica (60%)

### Representación de Tipos Genéricos

```tempo
// generics.tempo - Sistema de generics para Tempo

struct GenericType {
    base_type: Type,
    params: **TypeParameter,
    param_count: i32,
    constraints: *ConstraintList,
    id: i32
}

struct TypeParameter {
    name: *char,
    id: i32,
    index: i32,  // Posición en lista de parámetros
    
    // Bounds
    constraints: *Constraint,
    variance: Variance,  // Covariant, Contravariant, Invariant
    
    // Default
    default_type: *Type
}

struct Constraint {
    kind: ConstraintKind,
    trait_ref: *TraitRef,
    next: *Constraint
}

enum ConstraintKind {
    TRAIT_BOUND,        // T: Trait
    LIFETIME_BOUND,     // T: 'a
    SIZED_BOUND,        // T: Sized
    PROJECTION,         // T::Item = U
}

struct GenericFunction {
    signature: *FunctionSignature,
    type_params: **TypeParameter,
    param_count: i32,
    where_clauses: *WhereClause,
    body: *ASTNode,
    
    // Cache de instancias monomorphizadas
    instances: *InstanceCache
}

struct GenericInstance {
    generic: *GenericFunction,
    type_args: **Type,
    arg_count: i32,
    
    // Función monomorphizada
    specialized: *Function,
    
    // Para deduplicación
    next: *GenericInstance
}

// Resolver genéricos durante type checking
fn resolve_generic_call(tc: *TypeChecker, call: *CallExpr, 
                       generic: *GenericFunction) -> *Type {
    
    // Inferir argumentos de tipo
    let type_args = infer_type_arguments(tc, call, generic);
    
    // Verificar constraints
    if !check_constraints(tc, generic, type_args) {
        type_error(tc, call, "Type constraints not satisfied");
        return &type_error;
    }
    
    // Sustituir tipos en signature
    let subst = create_substitution(generic.type_params, type_args);
    let result_type = substitute_type(generic.signature.return_type, subst);
    
    // Registrar para monomorphization
    queue_for_monomorphization(tc, generic, type_args);
    
    return result_type;
}

fn infer_type_arguments(tc: *TypeChecker, call: *CallExpr, 
                       generic: *GenericFunction) -> **Type {
    
    let n = generic.param_count;
    let inferred = alloc(n * sizeof(*Type));
    
    // Crear variables de tipo frescas
    let i = 0;
    while i < n {
        inferred[i] = create_type_variable(tc, generic.type_params[i].name);
        i = i + 1;
    }
    
    // Generar constraints basados en argumentos
    let param_types = generic.signature.param_types;
    let arg_count = min(call.arg_count, generic.signature.param_count);
    
    i = 0;
    while i < arg_count {
        let param_type = substitute_type(param_types[i], 
                                       create_substitution(generic.type_params, inferred));
        let arg_type = type_check_expr(tc, call.args[i]);
        
        unify(tc, param_type, arg_type);
        i = i + 1;
    }
    
    // Resolver variables de tipo
    i = 0;
    while i < n {
        inferred[i] = resolve_type_variable(tc, inferred[i]);
        
        // Si no se pudo inferir, usar default o error
        if is_type_variable(inferred[i]) {
            if generic.type_params[i].default_type != 0 {
                inferred[i] = generic.type_params[i].default_type;
            } else {
                type_error(tc, call, "Cannot infer type parameter");
            }
        }
        
        i = i + 1;
    }
    
    return inferred;
}
```

### Monomorphization

```tempo
// monomorphization.tempo - Generación de código especializado

struct Monomorphizer {
    module: *Module,
    work_queue: *GenericInstanceQueue,
    instances: *InstanceMap,
    
    // Para evitar recursión infinita
    in_progress: *InstanceSet,
    recursion_limit: i32
}

fn monomorphize_module(module: *Module) {
    let mono = create_monomorphizer(module);
    
    // Fase 1: Encontrar todos los usos de genéricos
    collect_generic_uses(mono, module);
    
    // Fase 2: Generar instancias especializadas
    while !is_empty(mono.work_queue) {
        let instance = dequeue(mono.work_queue);
        
        if !needs_codegen(instance) {
            continue;
        }
        
        monomorphize_function(mono, instance);
    }
    
    // Fase 3: Optimizar código especializado
    optimize_monomorphized_code(mono);
}

fn monomorphize_function(mono: *Monomorphizer, instance: *GenericInstance) {
    // Verificar recursión
    if is_in_progress(mono, instance) {
        if get_depth(mono, instance) > mono.recursion_limit {
            error("Recursion limit exceeded in generics");
            return;
        }
    }
    
    mark_in_progress(mono, instance);
    
    // Crear función especializada
    let specialized = create_function(make_mangled_name(instance));
    instance.specialized = specialized;
    
    // Copiar y sustituir signature
    let subst = create_substitution(instance.generic.type_params, 
                                   instance.type_args);
    specialized.signature = substitute_signature(instance.generic.signature, subst);
    
    // Copiar y sustituir body
    let body_copy = deep_copy_ast(instance.generic.body);
    let specialized_body = substitute_ast(body_copy, subst);
    
    // Type check especializado
    type_check_specialized(specialized, specialized_body);
    
    // Generar IR
    specialized.body = lower_to_ir(specialized_body);
    
    // Registrar nuevas instancias encontradas
    collect_new_instances(mono, specialized);
    
    mark_complete(mono, instance);
}

// Sustitución de tipos en AST
fn substitute_ast(node: *ASTNode, subst: *Substitution) -> *ASTNode {
    switch node.kind {
        case AST_TYPE:
            node.type = substitute_type(node.type, subst);
            break;
            
        case AST_CALL:
            // Si es llamada a genérico, especializar
            if is_generic_function(node.callee) {
                let gen_func = get_generic_function(node.callee);
                let type_args = alloc(node.type_arg_count * sizeof(*Type));
                
                let i = 0;
                while i < node.type_arg_count {
                    type_args[i] = substitute_type(node.type_args[i], subst);
                    i = i + 1;
                }
                
                // Buscar o crear instancia
                let instance = get_or_create_instance(gen_func, type_args);
                node.callee = instance.specialized;
                node.type_args = 0;  // Ya no es genérico
                node.type_arg_count = 0;
            }
            break;
    }
    
    // Recursión en hijos
    let child = node.first_child;
    while child != 0 {
        substitute_ast(child, subst);
        child = child.next_sibling;
    }
    
    return node;
}

// Mangling de nombres para evitar colisiones
fn make_mangled_name(instance: *GenericInstance) -> *char {
    let name = string_builder_create();
    
    // Nombre base
    string_builder_append(name, instance.generic.name);
    string_builder_append(name, "$$");
    
    // Argumentos de tipo
    let i = 0;
    while i < instance.arg_count {
        append_type_mangled(name, instance.type_args[i]);
        if i < instance.arg_count - 1 {
            string_builder_append(name, "$");
        }
        i = i + 1;
    }
    
    return string_builder_finish(name);
}

fn append_type_mangled(name: *StringBuilder, type: *Type) {
    switch type.kind {
        case TYPE_I32:
            string_builder_append(name, "i32");
            break;
            
        case TYPE_POINTER:
            string_builder_append(name, "P");
            append_type_mangled(name, type.pointer.base);
            break;
            
        case TYPE_ARRAY:
            string_builder_append(name, "A");
            string_builder_append_int(name, type.array.size);
            append_type_mangled(name, type.array.element);
            break;
            
        case TYPE_STRUCT:
            string_builder_append(name, "S");
            string_builder_append(name, type.struct.name);
            break;
            
        case TYPE_GENERIC:
            string_builder_append(name, "G");
            string_builder_append(name, type.generic.name);
            let i = 0;
            while i < type.generic.arg_count {
                append_type_mangled(name, type.generic.args[i]);
                i = i + 1;
            }
            break;
    }
}
```

### Traits y Type Classes

```tempo
// traits.tempo - Sistema de traits para polimorfismo con constraints

struct Trait {
    name: *char,
    id: i32,
    
    // Métodos requeridos
    methods: **TraitMethod,
    method_count: i32,
    
    // Associated types
    assoc_types: **AssociatedType,
    assoc_count: i32,
    
    // Supertraits
    supertraits: **TraitRef,
    supertrait_count: i32
}

struct TraitMethod {
    name: *char,
    signature: *FunctionSignature,
    has_default: bool,
    default_impl: *Function
}

struct TraitImpl {
    trait: *Trait,
    for_type: *Type,
    
    // Type parameters del impl
    type_params: **TypeParameter,
    param_count: i32,
    
    // Métodos implementados
    methods: **Function,
    method_count: i32,
    
    // Associated types
    assoc_bindings: **TypeBinding,
    binding_count: i32
}

// Resolver método de trait
fn resolve_trait_method(tc: *TypeChecker, receiver_type: *Type, 
                       method_name: *char) -> *Function {
    
    // Buscar impls aplicables
    let impls = find_trait_impls_for_type(tc, receiver_type);
    
    let i = 0;
    while i < impls.count {
        let impl = impls.items[i];
        let method = find_method_in_impl(impl, method_name);
        
        if method != 0 {
            // Verificar que el impl es aplicable
            if matches_impl(tc, impl, receiver_type) {
                return instantiate_method(tc, method, impl, receiver_type);
            }
        }
        
        i = i + 1;
    }
    
    return 0;  // No encontrado
}

// Witness tables para dynamic dispatch
struct WitnessTable {
    trait: *Trait,
    impl_type: *Type,
    methods: **Function,
    
    // Para traits con associated types
    assoc_types: **Type
}

fn build_witness_table(impl: *TraitImpl) -> *WitnessTable {
    let table = alloc(sizeof(WitnessTable));
    table.trait = impl.trait;
    table.impl_type = impl.for_type;
    
    // Mapear métodos del trait a implementaciones
    table.methods = alloc(impl.trait.method_count * sizeof(*Function));
    
    let i = 0;
    while i < impl.trait.method_count {
        let trait_method = impl.trait.methods[i];
        let impl_method = find_impl_method(impl, trait_method.name);
        
        if impl_method != 0 {
            table.methods[i] = impl_method;
        } else if trait_method.has_default {
            table.methods[i] = trait_method.default_impl;
        } else {
            error("Missing implementation for trait method");
        }
        
        i = i + 1;
    }
    
    return table;
}

// Trait objects para polimorfismo dinámico
struct TraitObject {
    data: *void,
    vtable: *WitnessTable
}

fn make_trait_object(value: *T, impl: *TraitImpl) -> TraitObject {
    let obj: TraitObject;
    obj.data = value;
    obj.vtable = get_witness_table(impl);
    return obj;
}

fn call_trait_method(obj: *TraitObject, method_index: i32, args: **void) -> *void {
    let method = obj.vtable.methods[method_index];
    
    // Insertar receiver como primer argumento
    let full_args = alloc((get_arg_count(method) + 1) * sizeof(*void));
    full_args[0] = obj.data;
    
    let i = 0;
    while i < get_arg_count(method) {
        full_args[i + 1] = args[i];
        i = i + 1;
    }
    
    return call_function(method, full_args);
}
```

### Especialización y Optimización

```tempo
// specialization.tempo - Optimizaciones específicas para tipos concretos

struct SpecializationPass {
    module: *Module,
    specializations: *SpecializationMap,
    cost_model: *CostModel
}

// Especialización de containers
fn specialize_containers(pass: *SpecializationPass) {
    let functions = collect_generic_functions(pass.module);
    
    let f = 0;
    while f < functions.count {
        let func = functions.items[f];
        
        if is_container_operation(func) {
            specialize_container_ops(pass, func);
        }
        
        f = f + 1;
    }
}

fn specialize_container_ops(pass: *SpecializationPass, func: *GenericFunction) {
    // Para Vec<T>
    if is_vec_type(func.signature.self_type) {
        let element_type = get_element_type(func.signature.self_type);
        
        // Especializar para tipos pequeños
        if is_primitive_type(element_type) && get_size(element_type) <= 8 {
            create_vectorized_version(pass, func, element_type);
        }
        
        // Especializar para tipos con layout especial
        if has_special_layout(element_type) {
            create_layout_optimized_version(pass, func, element_type);
        }
    }
}

// Especialización para tipos numéricos con SIMD
fn create_vectorized_version(pass: *SpecializationPass, 
                            func: *GenericFunction, 
                            element_type: *Type) {
    
    let vector_width = get_simd_width(pass.module.target, element_type);
    if vector_width <= 1 {
        return;  // No hay beneficio
    }
    
    // Crear versión vectorizada
    let vec_func = clone_function(func);
    vec_func.name = make_name(func.name, "_vec", vector_width);
    
    // Transformar operaciones a SIMD
    let transformer = create_simd_transformer(vector_width, element_type);
    transform_to_simd(vec_func.body, transformer);
    
    // Registrar especialización
    register_specialization(pass, func, element_type, vec_func);
}

// Inline de operaciones genéricas pequeñas
fn inline_generic_ops(module: *Module) {
    let changed = true;
    
    while changed {
        changed = false;
        
        let calls = collect_generic_calls(module);
        let c = 0;
        while c < calls.count {
            let call = calls.items[c];
            let instance = get_instance(call);
            
            if should_inline_generic(instance) {
                inline_call(call, instance.specialized);
                changed = true;
            }
            
            c = c + 1;
        }
    }
}

fn should_inline_generic(instance: *GenericInstance) -> bool {
    // Heurísticas para inlining de genéricos
    
    // 1. Funciones triviales siempre
    if is_trivial_function(instance.specialized) {
        return true;
    }
    
    // 2. Operaciones en tipos primitivos
    if all_primitive_types(instance.type_args, instance.arg_count) {
        let size = get_function_size(instance.specialized);
        return size < GENERIC_INLINE_THRESHOLD;
    }
    
    // 3. Hot paths
    if get_call_frequency(instance) > HOT_THRESHOLD {
        return true;
    }
    
    return false;
}

// Desvirtualización de trait calls
fn devirtualize_trait_calls(module: *Module) {
    let trait_calls = collect_trait_calls(module);
    
    let c = 0;
    while c < trait_calls.count {
        let call = trait_calls.items[c];
        
        // Analizar tipo concreto del receiver
        let receiver_type = analyze_receiver_type(call);
        
        if is_concrete_type(receiver_type) {
            // Buscar implementación concreta
            let impl = find_trait_impl(call.trait, receiver_type);
            if impl != 0 {
                let method = get_method(impl, call.method_index);
                
                // Reemplazar con llamada directa
                replace_trait_call_with_direct(call, method);
            }
        }
        
        c = c + 1;
    }
}
```

### Variance y Lifetimes

```tempo
// variance.tempo - Análisis de varianza para type safety

enum Variance {
    COVARIANT,      // T<A> -> T<B> si A -> B
    CONTRAVARIANT,  // T<B> -> T<A> si A -> B
    INVARIANT,      // No hay relación
    BIVARIANT       // Ambas direcciones (raro)
}

struct VarianceAnalysis {
    types: *TypeMap,
    constraints: *VarianceConstraints
}

fn compute_variance(type: *GenericType) -> *VarianceInfo {
    let analysis = create_variance_analysis();
    
    // Analizar cada parámetro
    let info = alloc(sizeof(VarianceInfo));
    info.variances = alloc(type.param_count * sizeof(Variance));
    
    let i = 0;
    while i < type.param_count {
        let param = type.params[i];
        info.variances[i] = analyze_parameter_variance(analysis, type, param);
        i = i + 1;
    }
    
    return info;
}

fn analyze_parameter_variance(analysis: *VarianceAnalysis, 
                             generic: *GenericType, 
                             param: *TypeParameter) -> Variance {
    
    // Comenzar con bivariant
    let variance = BIVARIANT;
    
    // Analizar usos del parámetro
    let uses = find_parameter_uses(generic, param);
    
    let u = 0;
    while u < uses.count {
        let use = uses.items[u];
        let use_variance = compute_use_variance(use);
        
        // Combinar variancias
        variance = combine_variance(variance, use_variance);
        
        u = u + 1;
    }
    
    return variance;
}

fn compute_use_variance(use: *ParameterUse) -> Variance {
    switch use.context {
        case USE_RETURN:
            return COVARIANT;
            
        case USE_PARAMETER:
            return CONTRAVARIANT;
            
        case USE_MUTABLE_REF:
            return INVARIANT;
            
        case USE_FIELD:
            if use.field_mutable {
                return INVARIANT;
            } else {
                return COVARIANT;
            }
    }
}

// Higher-ranked types
struct HigherRankedType {
    binder: Binder,
    bound_vars: **TypeParameter,
    var_count: i32,
    inner_type: *Type
}

fn type_check_higher_ranked(tc: *TypeChecker, hrt: *HigherRankedType, 
                           concrete: *Type) -> bool {
    
    // Skolemization: reemplazar variables bound con tipos frescos
    let skolem_types = alloc(hrt.var_count * sizeof(*Type));
    let i = 0;
    while i < hrt.var_count {
        skolem_types[i] = create_skolem_type(tc, hrt.bound_vars[i]);
        i = i + 1;
    }
    
    // Sustituir y verificar
    let subst = create_substitution(hrt.bound_vars, skolem_types);
    let instantiated = substitute_type(hrt.inner_type, subst);
    
    return subtype_check(tc, concrete, instantiated);
}
```

### Optimizaciones Avanzadas para Generics

```tempo
// generic_optimizations.tempo - Optimizaciones específicas para código genérico

// Shape analysis para eliminar boxing
struct ShapeAnalysis {
    shapes: *ShapeMap,
    equivalences: *ShapeEquivalence
}

struct Shape {
    size: i32,
    align: i32,
    has_drop: bool,
    fields: *FieldLayout
}

fn analyze_generic_shapes(module: *Module) -> *ShapeAnalysis {
    let analysis = create_shape_analysis();
    
    // Analizar todas las instancias
    let instances = collect_all_instances(module);
    
    let i = 0;
    while i < instances.count {
        let inst = instances.items[i];
        analyze_instance_shape(analysis, inst);
        i = i + 1;
    }
    
    // Encontrar shapes equivalentes
    compute_shape_equivalences(analysis);
    
    return analysis;
}

// Compartir código entre instancias con mismo shape
fn share_generic_code(module: *Module, shapes: *ShapeAnalysis) {
    let groups = group_by_shape(module, shapes);
    
    let g = 0;
    while g < groups.count {
        let group = groups.items[g];
        
        if group.instance_count > 1 {
            merge_equivalent_instances(group);
        }
        
        g = g + 1;
    }
}

// Partial evaluation para generics
fn partial_evaluate_generics(module: *Module) {
    let instances = collect_generic_instances(module);
    
    let i = 0;
    while i < instances.count {
        let inst = instances.items[i];
        
        // Si algunos type parameters son conocidos
        if has_concrete_type_args(inst) {
            let evaluator = create_partial_evaluator();
            
            // Evaluar parcialmente con tipos conocidos
            let optimized = partial_eval_function(evaluator, 
                                                inst.specialized, 
                                                inst.type_args);
            
            // Reemplazar con versión optimizada
            inst.specialized.body = optimized;
        }
        
        i = i + 1;
    }
}

// Fusion de operaciones genéricas
fn fuse_generic_operations(module: *Module) {
    // Buscar patrones como map().filter().collect()
    let chains = find_generic_method_chains(module);
    
    let c = 0;
    while c < chains.count {
        let chain = chains.items[c];
        
        if can_fuse_chain(chain) {
            let fused = create_fused_operation(chain);
            replace_chain_with_fused(chain, fused);
        }
        
        c = c + 1;
    }
}

// Loop fusion para iteradores genéricos
fn fuse_generic_loops(func: *Function) {
    let loops = find_iterator_loops(func);
    
    let i = 0;
    while i < loops.count - 1 {
        let loop1 = loops.items[i];
        let loop2 = loops.items[i + 1];
        
        if can_fuse_iterator_loops(loop1, loop2) {
            let fused = fuse_loops(loop1, loop2);
            replace_loops(loop1, loop2, fused);
        }
        
        i = i + 1;
    }
}
```

## 3. Ejercicios (20%)

### Ejercicio 1: Generic Associated Types (GATs)
Implementa soporte para tipos asociados genéricos:
```tempo
trait Iterator {
    type Item<'a>;
    fn next<'a>(&'a mut self) -> Option<Self::Item<'a>>;
}
```

### Ejercicio 2: Const Generics
Añade soporte para parámetros de valor constante:
```tempo
fn create_array<T, const N: usize>() -> [T; N] {
    // Array con tamaño conocido en compile time
}
```

### Ejercicio 3: Specialization con Precedencia
Implementa especialización con reglas de precedencia:
```tempo
impl<T> Display for T {
    default fn fmt(&self) -> String { "generic" }
}

impl Display for i32 {
    fn fmt(&self) -> String { self.to_string() }
}
```

### Ejercicio 4: Monomorphization Compartida
Optimiza para compartir código entre instancias similares:
```tempo
// Vec<&T> y Vec<*T> pueden compartir implementación
fn optimize_pointer_containers<T>(vec: Vec<*T>) {
    // Compartir código con Vec<&T>
}
```

### Ejercicio 5: Effect Polymorphism
Implementa polimorfismo sobre efectos:
```tempo
fn map<T, U, effect E>(x: T, f: fn(T) -> U with E) -> U with E {
    return f(x);
}
```

## Proyecto Final: Sistema de Generics Completo

Implementa un sistema de generics production-ready:

1. **Core Features**:
   - Type parameters con bounds
   - Associated types
   - Higher-kinded types
   - Const generics

2. **Implementación**:
   - Monomorphization eficiente
   - Code sharing inteligente
   - Especialización
   - Inline agresivo

3. **Optimizaciones**:
   - Shape analysis
   - Devirtualization
   - Loop fusion
   - SIMD automático

4. **Herramientas**:
   - Error messages claros
   - Debugger support
   - Profiling de bloat
   - Visualización de instancias

## Recursos Adicionales

### Papers Fundamentales
- "Parametricity" - Reynolds
- "Fast Type-Safe Generic Programming" - Kennedy & Syme
- "Generics of a Higher Kind" - Moors et al.
- "Specialization in Generic Programming" - Siek & Lumsdaine

### Implementaciones de Referencia
- Rust: Monomorphization con MIR
- C++: Templates con SFINAE
- Swift: Witness tables y specialization
- Haskell: Type classes y higher-kinded types

## Conclusión

Los generics son fundamentales para escribir código reusable y type-safe. La implementación presentada demuestra:

1. **Expresividad**: Polimorfismo poderoso y flexible
2. **Performance**: Zero-cost abstractions via monomorphization
3. **Seguridad**: Type checking fuerte sin overhead
4. **Optimización**: Especialización para casos comunes

El sistema de generics de Tempo combina las mejores ideas de múltiples lenguajes, proporcionando abstracciones poderosas sin sacrificar performance. Con estas técnicas, los programadores pueden escribir código genérico que es tan eficiente como el código especializado manualmente.