╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝

Author: Ignacio Peña Sepúlveda
Date: June 25, 2025


# Lección 10: Sistema de Tipos - Type Checking and Inference Basics

## Objetivos de la Lección
- Implementar un sistema de tipos estático para Chronos
- Añadir type checking al compilador self-hosted
- Implementar inferencia de tipos básica
- Garantizar seguridad de tipos sin overhead en runtime

## 1. Teoría (20%)

### ¿Por qué un Sistema de Tipos?

Un sistema de tipos bien diseñado proporciona:

1. **Seguridad**: Detecta errores en tiempo de compilación
2. **Documentación**: Los tipos documentan el código
3. **Optimización**: Permite optimizaciones agresivas
4. **Abstracción**: Facilita el razonamiento sobre programas

### Tipos en Chronos

```tempo
// Tipos primitivos
i8, i16, i32, i64    // Enteros con signo
u8, u16, u32, u64    // Enteros sin signo
f32, f64             // Punto flotante
bool                 // Booleano
char                 // Carácter Unicode

// Tipos compuestos
[T; N]               // Array de tamaño fijo
*T                   // Puntero a T
fn(T1, T2) -> T3     // Tipo función
struct { ... }       // Estructura

// Tipos especiales
void                 // Sin valor de retorno
never                // Nunca retorna (panic, loop infinito)
```

### Reglas de Tipado

1. **Sound**: Si el type checker acepta un programa, no habrá errores de tipo en runtime
2. **Complete**: El type checker acepta todos los programas correctos (en la práctica, esto es imposible)
3. **Decidable**: El type checking siempre termina

### Inferencia de Tipos

Chronos usa inferencia de tipos bidireccional:
- **Síntesis**: Inferir el tipo de una expresión
- **Verificación**: Verificar que una expresión tiene un tipo esperado

## 2. Práctica (60%)

### Representación de Tipos

```tempo
// Representación interna de tipos en el compilador

enum TypeKind {
    TYPE_VOID = 0,
    TYPE_BOOL,
    TYPE_I8, TYPE_I16, TYPE_I32, TYPE_I64,
    TYPE_U8, TYPE_U16, TYPE_U32, TYPE_U64,
    TYPE_F32, TYPE_F64,
    TYPE_CHAR,
    TYPE_POINTER,
    TYPE_ARRAY,
    TYPE_FUNCTION,
    TYPE_STRUCT,
    TYPE_ENUM,
    TYPE_NEVER
}

struct Type {
    kind: TypeKind,
    size: i32,          // Tamaño en bytes
    align: i32,         // Alineación requerida
    
    // Datos específicos según el tipo
    union {
        // Para punteros
        pointer: struct {
            base: *Type
        },
        
        // Para arrays
        array: struct {
            element: *Type,
            size: i32
        },
        
        // Para funciones
        function: struct {
            params: *Type,
            param_count: i32,
            return_type: *Type,
            variadic: bool
        },
        
        // Para estructuras
        structure: struct {
            fields: *Field,
            field_count: i32,
            name: *char
        }
    }
}

struct Field {
    name: *char,
    type: *Type,
    offset: i32
}

// Cache de tipos para evitar duplicados
struct TypeCache {
    types: *Type,
    count: i32,
    capacity: i32
}

fn intern_type(cache: *TypeCache, type: *Type) -> *Type {
    // Buscar tipo existente
    let i = 0;
    while i < cache.count {
        if types_equal(cache.types[i], type) {
            return cache.types[i];
        }
        i = i + 1;
    }
    
    // Agregar nuevo tipo
    if cache.count >= cache.capacity {
        resize_cache(cache);
    }
    
    cache.types[cache.count] = copy_type(type);
    cache.count = cache.count + 1;
    return cache.types[cache.count - 1];
}
```

### Type Checker Base

```tempo
// type_checker.ch - Sistema de type checking

struct TypeChecker {
    cache: *TypeCache,
    scope: *Scope,
    errors: *ErrorList,
    current_function: *Type
}

struct Scope {
    parent: *Scope,
    symbols: *Symbol,
    symbol_count: i32
}

struct Symbol {
    name: *char,
    type: *Type,
    kind: SymbolKind,  // Variable, Function, Type, etc.
    value: *ASTNode    // Para constantes
}

fn type_check_program(ast: *ASTNode) -> bool {
    let tc = create_type_checker();
    
    // Primera pasada: recolectar todas las declaraciones
    collect_declarations(tc, ast);
    
    // Segunda pasada: type check de implementaciones
    let node = ast.left;
    while node != 0 {
        type_check_declaration(tc, node);
        node = node.next;
    }
    
    return tc.errors.count == 0;
}

fn type_check_declaration(tc: *TypeChecker, node: *ASTNode) {
    if node.type == NODE_FUNCTION {
        type_check_function(tc, node);
    } else if node.type == NODE_STRUCT {
        type_check_struct(tc, node);
    } else if node.type == NODE_GLOBAL_VAR {
        type_check_global_var(tc, node);
    }
}

fn type_check_function(tc: *TypeChecker, func: *ASTNode) {
    // Crear nuevo scope para la función
    push_scope(tc);
    
    // Obtener tipo de la función
    let func_type = lookup_symbol(tc, func.name).type;
    tc.current_function = func_type;
    
    // Agregar parámetros al scope
    let params = func.params;
    let i = 0;
    while params != 0 {
        let param_type = func_type.function.params[i];
        add_symbol(tc, params.name, param_type, SYMBOL_PARAM);
        params = params.next;
        i = i + 1;
    }
    
    // Type check del cuerpo
    let body_type = type_check_block(tc, func.body);
    
    // Verificar tipo de retorno
    let expected_return = func_type.function.return_type;
    if !types_compatible(body_type, expected_return) {
        if expected_return.kind != TYPE_VOID {
            type_error(tc, func, "Function must return a value");
        }
    }
    
    tc.current_function = 0;
    pop_scope(tc);
}

fn type_check_block(tc: *TypeChecker, block: *ASTNode) -> *Type {
    push_scope(tc);
    
    let last_type = &type_void;
    let stmt = block.statements;
    
    while stmt != 0 {
        last_type = type_check_statement(tc, stmt);
        
        // Si encontramos un return o never, el resto es código muerto
        if last_type.kind == TYPE_NEVER {
            if stmt.next != 0 {
                warning(tc, stmt.next, "Unreachable code");
            }
            break;
        }
        
        stmt = stmt.next;
    }
    
    pop_scope(tc);
    return last_type;
}

fn type_check_statement(tc: *TypeChecker, stmt: *ASTNode) -> *Type {
    switch stmt.type {
        case NODE_LET:
            return type_check_let(tc, stmt);
            
        case NODE_ASSIGN:
            return type_check_assignment(tc, stmt);
            
        case NODE_RETURN:
            return type_check_return(tc, stmt);
            
        case NODE_IF:
            return type_check_if(tc, stmt);
            
        case NODE_WHILE:
            return type_check_while(tc, stmt);
            
        case NODE_EXPR_STMT:
            type_check_expression(tc, stmt.expr);
            return &type_void;
            
        default:
            type_error(tc, stmt, "Unknown statement type");
            return &type_void;
    }
}

fn type_check_expression(tc: *TypeChecker, expr: *ASTNode) -> *Type {
    switch expr.type {
        case NODE_NUMBER:
            return infer_number_type(expr);
            
        case NODE_IDENT:
            return type_check_identifier(tc, expr);
            
        case NODE_BINARY_OP:
            return type_check_binary_op(tc, expr);
            
        case NODE_UNARY_OP:
            return type_check_unary_op(tc, expr);
            
        case NODE_CALL:
            return type_check_call(tc, expr);
            
        case NODE_FIELD_ACCESS:
            return type_check_field_access(tc, expr);
            
        case NODE_ARRAY_ACCESS:
            return type_check_array_access(tc, expr);
            
        case NODE_CAST:
            return type_check_cast(tc, expr);
            
        default:
            type_error(tc, expr, "Unknown expression type");
            return &type_void;
    }
}

fn type_check_binary_op(tc: *TypeChecker, expr: *ASTNode) -> *Type {
    let left_type = type_check_expression(tc, expr.left);
    let right_type = type_check_expression(tc, expr.right);
    
    let op = expr.op;
    
    // Operadores aritméticos
    if op == '+' || op == '-' || op == '*' || op == '/' || op == '%' {
        if !is_numeric_type(left_type) || !is_numeric_type(right_type) {
            type_error(tc, expr, "Arithmetic operators require numeric types");
            return &type_void;
        }
        
        // Promoción de tipos
        return promote_types(left_type, right_type);
    }
    
    // Operadores de comparación
    if op == '<' || op == '>' || op == '<=' || op == '>=' {
        if !is_ordered_type(left_type) || !is_ordered_type(right_type) {
            type_error(tc, expr, "Comparison operators require ordered types");
            return &type_void;
        }
        
        if !types_compatible(left_type, right_type) {
            type_error(tc, expr, "Incompatible types for comparison");
        }
        
        return &type_bool;
    }
    
    // Operadores de igualdad
    if op == '==' || op == '!=' {
        if !types_compatible(left_type, right_type) {
            type_error(tc, expr, "Incompatible types for equality comparison");
        }
        return &type_bool;
    }
    
    // Operadores lógicos
    if op == '&&' || op == '||' {
        if left_type.kind != TYPE_BOOL || right_type.kind != TYPE_BOOL {
            type_error(tc, expr, "Logical operators require boolean types");
        }
        return &type_bool;
    }
    
    type_error(tc, expr, "Unknown binary operator");
    return &type_void;
}
```

### Inferencia de Tipos

```tempo
// Inferencia de tipos bidireccional

fn infer_type(tc: *TypeChecker, expr: *ASTNode, expected: *Type) -> *Type {
    // Si tenemos un tipo esperado, intentar verificar
    if expected != 0 && expected.kind != TYPE_VOID {
        if check_type(tc, expr, expected) {
            return expected;
        }
    }
    
    // Si no, sintetizar el tipo
    return synthesize_type(tc, expr);
}

fn synthesize_type(tc: *TypeChecker, expr: *ASTNode) -> *Type {
    switch expr.type {
        case NODE_NUMBER:
            // Inferir el tipo más pequeño que pueda contener el valor
            let value = expr.value;
            if value >= -128 && value <= 127 {
                return &type_i8;
            } else if value >= -32768 && value <= 32767 {
                return &type_i16;
            } else if value >= -2147483648 && value <= 2147483647 {
                return &type_i32;
            } else {
                return &type_i64;
            }
            
        case NODE_STRING:
            return create_pointer_type(&type_u8);
            
        case NODE_ARRAY_LITERAL:
            return infer_array_literal_type(tc, expr);
            
        case NODE_STRUCT_LITERAL:
            return infer_struct_literal_type(tc, expr);
            
        default:
            return type_check_expression(tc, expr);
    }
}

fn check_type(tc: *TypeChecker, expr: *ASTNode, expected: *Type) -> bool {
    let actual = synthesize_type(tc, expr);
    
    // Verificar compatibilidad
    if types_equal(actual, expected) {
        return true;
    }
    
    // Permitir coerciones seguras
    if can_coerce(actual, expected) {
        // Insertar nodo de coerción en el AST
        insert_coercion(expr, actual, expected);
        return true;
    }
    
    return false;
}

fn can_coerce(from: *Type, to: *Type) -> bool {
    // Coerción de enteros
    if is_integer_type(from) && is_integer_type(to) {
        // Permitir si no hay pérdida de información
        if from.size <= to.size {
            // Mismo signo o expansión de signo segura
            if is_signed(from) == is_signed(to) {
                return true;
            }
            // unsigned -> signed si hay espacio
            if !is_signed(from) && is_signed(to) && from.size < to.size {
                return true;
            }
        }
    }
    
    // Coerción de arrays a punteros
    if from.kind == TYPE_ARRAY && to.kind == TYPE_POINTER {
        return types_equal(from.array.element, to.pointer.base);
    }
    
    // Literal 0 puede ser puntero nulo
    if is_zero_literal(from) && to.kind == TYPE_POINTER {
        return true;
    }
    
    return false;
}

// Inferencia para let con tipo parcial
fn type_check_let_with_inference(tc: *TypeChecker, stmt: *ASTNode) -> *Type {
    let var_name = stmt.name;
    let var_type = stmt.type_annotation;
    let init_expr = stmt.initializer;
    
    if var_type != 0 && init_expr != 0 {
        // Tipo explícito con inicializador: verificar compatibilidad
        let init_type = check_type(tc, init_expr, var_type);
        if !init_type {
            type_error(tc, stmt, "Type mismatch in variable initialization");
            return &type_void;
        }
        add_symbol(tc, var_name, var_type, SYMBOL_VAR);
    } else if var_type != 0 {
        // Solo tipo explícito
        add_symbol(tc, var_name, var_type, SYMBOL_VAR);
    } else if init_expr != 0 {
        // Solo inicializador: inferir tipo
        let inferred = synthesize_type(tc, init_expr);
        add_symbol(tc, var_name, inferred, SYMBOL_VAR);
    } else {
        type_error(tc, stmt, "Variable needs type annotation or initializer");
    }
    
    return &type_void;
}
```

### Tipos Genéricos Básicos

```tempo
// Soporte básico para tipos genéricos

struct TypeParam {
    name: *char,
    id: i32,
    constraints: *Type  // Lista de tipos que debe satisfacer
}

struct GenericType {
    base: Type,
    params: *TypeParam,
    param_count: i32
}

// Ejemplo: Option<T>
fn create_option_type(tc: *TypeChecker) -> *GenericType {
    let option = alloc(sizeof(GenericType));
    option.base.kind = TYPE_ENUM;
    option.param_count = 1;
    
    let T = create_type_param("T");
    option.params = T;
    
    // Variantes: None | Some(T)
    let variants = alloc(2 * sizeof(EnumVariant));
    variants[0].name = "None";
    variants[0].has_data = false;
    
    variants[1].name = "Some";
    variants[1].has_data = true;
    variants[1].data_type = T;
    
    return option;
}

// Instanciación de tipos genéricos
fn instantiate_generic(tc: *TypeChecker, generic: *GenericType, args: **Type) -> *Type {
    // Crear mapa de sustitución
    let subst = create_substitution();
    
    let i = 0;
    while i < generic.param_count {
        add_substitution(subst, generic.params[i], args[i]);
        i = i + 1;
    }
    
    // Aplicar sustitución
    return substitute_type(generic.base, subst);
}

// Inferencia con genéricos
fn infer_generic_call(tc: *TypeChecker, func: *GenericType, args: **ASTNode) -> *Type {
    // Crear variables de tipo frescas para cada parámetro genérico
    let type_vars = alloc(func.param_count * sizeof(*Type));
    let i = 0;
    while i < func.param_count {
        type_vars[i] = create_type_variable(tc);
        i = i + 1;
    }
    
    // Instanciar tipo de función con variables
    let instantiated = instantiate_generic(tc, func, type_vars);
    
    // Generar constraints basados en los argumentos
    let constraints = generate_constraints(tc, instantiated, args);
    
    // Resolver constraints (unificación)
    let solution = unify_constraints(tc, constraints);
    
    // Aplicar solución para obtener tipos concretos
    return apply_solution(instantiated, solution);
}
```

### Verificación de Seguridad de Memoria

```tempo
// Análisis de préstamos simplificado para Chronos

enum BorrowKind {
    BORROW_SHARED,      // Lectura
    BORROW_EXCLUSIVE    // Lectura/escritura
}

struct Borrow {
    var: *Symbol,
    kind: BorrowKind,
    lifetime: *Lifetime
}

struct BorrowChecker {
    tc: *TypeChecker,
    active_borrows: *Borrow,
    borrow_count: i32
}

fn check_borrow_safety(bc: *BorrowChecker, expr: *ASTNode) -> bool {
    switch expr.type {
        case NODE_ADDR_OF:
            return check_borrow_creation(bc, expr);
            
        case NODE_DEREF:
            return check_borrow_use(bc, expr);
            
        case NODE_ASSIGN:
            return check_borrow_assignment(bc, expr);
            
        default:
            // Recursivamente verificar sub-expresiones
            return check_children_borrows(bc, expr);
    }
}

fn check_borrow_creation(bc: *BorrowChecker, expr: *ASTNode) -> bool {
    let target = expr.operand;
    let is_mutable = expr.is_mutable;
    
    // Encontrar variable siendo prestada
    let var = resolve_to_variable(bc.tc, target);
    if var == 0 {
        type_error(bc.tc, expr, "Cannot borrow temporary value");
        return false;
    }
    
    // Verificar conflictos con préstamos existentes
    let i = 0;
    while i < bc.borrow_count {
        let existing = bc.active_borrows[i];
        if existing.var == var {
            if is_mutable || existing.kind == BORROW_EXCLUSIVE {
                type_error(bc.tc, expr, "Cannot borrow while another borrow exists");
                return false;
            }
        }
        i = i + 1;
    }
    
    // Crear nuevo préstamo
    let borrow: Borrow;
    borrow.var = var;
    borrow.kind = is_mutable ? BORROW_EXCLUSIVE : BORROW_SHARED;
    borrow.lifetime = infer_lifetime(bc, expr);
    
    add_borrow(bc, borrow);
    return true;
}

fn check_move_semantics(tc: *TypeChecker, expr: *ASTNode) -> bool {
    // Tipos que implementan Copy se pueden usar múltiples veces
    let type = get_expression_type(tc, expr);
    if implements_copy(type) {
        return true;
    }
    
    // Para tipos no-Copy, verificar que no se use después de mover
    if is_moved(tc, expr) {
        type_error(tc, expr, "Use of moved value");
        return false;
    }
    
    // Marcar como movido
    mark_as_moved(tc, expr);
    return true;
}
```

### Optimizaciones Basadas en Tipos

```tempo
// El sistema de tipos permite optimizaciones agresivas

fn optimize_based_on_types(func: *Function) {
    let bb = func.entry_block;
    
    while bb != 0 {
        let inst = bb.instructions;
        while inst != 0 {
            optimize_instruction(inst);
            inst = inst.next;
        }
        bb = bb.next;
    }
}

fn optimize_instruction(inst: *Instruction) {
    switch inst.opcode {
        case OP_ADD:
            // Si sabemos que los operandos nunca overflowean,
            // podemos usar add sin checks
            if guaranteed_no_overflow(inst.type, inst.left, inst.right) {
                inst.opcode = OP_ADD_UNCHECKED;
            }
            break;
            
        case OP_ARRAY_ACCESS:
            // Si el índice está garantizado en rango,
            // eliminar bounds check
            if index_in_bounds(inst.array_type, inst.index) {
                inst.opcode = OP_ARRAY_ACCESS_UNCHECKED;
            }
            break;
            
        case OP_DIV:
            // Si el divisor nunca es cero, usar división sin check
            if never_zero(inst.right) {
                inst.opcode = OP_DIV_UNCHECKED;
            }
            break;
    }
}

fn guaranteed_no_overflow(type: *Type, left: *Value, right: *Value) -> bool {
    // Para tipos pequeños promovidos, no hay overflow
    if type.size > max(left.type.size, right.type.size) {
        return true;
    }
    
    // Análisis de rangos
    let left_range = compute_value_range(left);
    let right_range = compute_value_range(right);
    
    return !can_overflow(type, left_range, right_range);
}
```

## 3. Ejercicios (20%)

### Ejercicio 1: Tipos Algebraicos
Implementa soporte para tipos suma (enums) con pattern matching:
```tempo
enum Result<T, E> {
    Ok(T),
    Err(E)
}

fn divide(a: i32, b: i32) -> Result<i32, String> {
    if b == 0 {
        return Err("Division by zero");
    }
    return Ok(a / b);
}
```

### Ejercicio 2: Traits Básicos
Implementa un sistema simple de traits:
```tempo
trait Display {
    fn display(self) -> String;
}

impl Display for i32 {
    fn display(self) -> String {
        return int_to_string(self);
    }
}
```

### Ejercicio 3: Inferencia de Tipos Completa
Extiende la inferencia para soportar:
- Inferencia en closures
- Inferencia en genéricos
- Inferencia bidireccional completa

### Ejercicio 4: Linear Types
Implementa tipos lineales que deben ser usados exactamente una vez:
```tempo
linear struct File {
    fd: i32
}

fn use_file() {
    let f = open_file("data.txt");
    read_from(f);
    // Error: f debe ser cerrado explícitamente
}
```

### Ejercicio 5: Dependent Types Simples
Implementa tipos que dependen de valores:
```tempo
fn create_array<const N: i32>() -> [i32; N] {
    let arr: [i32; N];
    return arr;
}
```

## Proyecto Final: Sistema de Tipos Completo

Implementa un sistema de tipos production-ready que incluya:

1. **Tipos avanzados**:
   - Genéricos con constraints
   - Associated types
   - Higher-kinded types básicos
   - Existential types

2. **Análisis de efectos**:
   - Tracking de efectos secundarios
   - Funciones puras vs impuras
   - Análisis de excepciones

3. **Optimizaciones**:
   - Especialización de genéricos
   - Devirtualización
   - Layout optimization
   - Zero-cost abstractions

4. **Herramientas**:
   - Type-driven development
   - Holes y tipo parciales
   - Error messages claros
   - Quick fixes automáticos

## Recursos Adicionales

### Papers Fundamentales
- "Types and Programming Languages" - Benjamin Pierce
- "Advanced Topics in Types and Programming Languages"
- "Bidirectional Type Checking" - Various papers
- "The Essence of ML Type Inference"

### Implementación de Referencia

```tempo
// Ejemplo completo: Type checker para lambda calculus

enum Term {
    Var(String),
    Abs(String, *Type, *Term),
    App(*Term, *Term)
}

enum Type {
    Base(String),
    Arrow(*Type, *Type)
}

fn type_check(ctx: *Context, term: *Term) -> Result<*Type, String> {
    match term {
        Var(x) => {
            match lookup(ctx, x) {
                Some(t) => Ok(t),
                None => Err("Unbound variable")
            }
        },
        
        Abs(x, t, body) => {
            let new_ctx = extend(ctx, x, t);
            let body_type = type_check(new_ctx, body)?;
            Ok(Arrow(t, body_type))
        },
        
        App(f, arg) => {
            let f_type = type_check(ctx, f)?;
            let arg_type = type_check(ctx, arg)?;
            
            match f_type {
                Arrow(param_type, return_type) => {
                    if types_equal(param_type, arg_type) {
                        Ok(return_type)
                    } else {
                        Err("Type mismatch in application")
                    }
                },
                _ => Err("Applied non-function")
            }
        }
    }
}
```

## Conclusión

Con esta lección hemos completado nuestro compilador añadiendo un sistema de tipos robusto. El sistema de tipos:

1. **Garantiza seguridad**: Sin errores de tipo en runtime
2. **Permite optimizaciones**: El compilador puede hacer asunciones fuertes
3. **Mejora la experiencia**: Errores claros y documentación implícita
4. **Es eficiente**: Type checking en tiempo lineal para la mayoría de programas

Has construido un compilador completo desde cero:
- **Lección 5**: Fundamentos de assembly
- **Lección 6**: Tokenizer eficiente
- **Lección 7**: Parser recursivo descendente
- **Lección 8**: Generación de código
- **Lección 9**: Self-hosting
- **Lección 10**: Sistema de tipos

¡Felicitaciones! Ahora tienes las herramientas y conocimientos para crear lenguajes de programación eficientes y seguros. El compilador de Chronos que has construido es comparable a compiladores de producción, demostrando que es posible crear herramientas de alta calidad con diseño minimalista y enfoque en la eficiencia.