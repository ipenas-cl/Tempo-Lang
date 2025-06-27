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

# Estado Actual del Build de Tempo

## ✅ Lo que existe:
1. **Estructura de carpetas** - Completamente organizada
2. **Bootstrap en Assembly** - `compiler/linux/bootstrap.asm` (lexer/parser)
3. **Stage 0** - `compiler/stages/stage0/bootstrap.s` 
4. **Stage 1** - `compiler/stages/stage1/compiler.tempo`
5. **Stage 2** - `compiler/stages/stage2/` (múltiples archivos)
6. **Compilador final** - `compiler/tempo.tempo`

## ❌ Lo que falta:
1. **NASM** - Necesitas instalarlo: `sudo apt-get install nasm`
2. **Bootstrap binario** - Los archivos assembly necesitan ser compilados
3. **Conexión entre etapas** - Stage0 debe poder compilar Stage1

## 🚀 Para hacer funcionar Tempo:

### Opción 1: Bootstrap completo (requiere NASM)
```bash
sudo apt-get install nasm
./build.sh
```

### Opción 2: Bootstrap manual paso a paso
```bash
# 1. Compilar bootstrap assembly
cd compiler/linux
nasm -f elf64 bootstrap.asm -o bootstrap.o
ld bootstrap.o -o tempo-bootstrap

# 2. Usar bootstrap para compilar stage1
./tempo-bootstrap ../stages/stage1/compiler.tempo stage1

# 3. Usar stage1 para compilar stage2
./stage1 ../stages/stage2/compiler.tempo stage2

# 4. Usar stage2 para compilar el compilador final
./stage2 ../tempo.tempo tempo
```

## 📝 Nota importante:
El sistema está diseñado para ser 100% self-hosting sin C, pero necesita un bootstrap inicial en assembly. Los archivos `.tempo` son reales y contienen el compilador completo, pero necesitan ser compilados por la cadena de bootstrapping.

---
**[T∞]** *Sin C, puro determinismo*