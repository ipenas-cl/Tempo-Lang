# Compilador Tempo - Estructura Multi-Plataforma

╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝

## Estructura

```
compiler/
├── README.md           # Este archivo
├── tempo.tempo         # Compilador principal en Tempo
├── stage1.tempo        # Compilador mínimo
├── bootstrap.c         # ELIMINADO - Ya no usamos C!
│
├── linux/              # Bootstrap para Linux
│   ├── bootstrap.asm   # Assembly puro para Linux
│   └── build.sh        # Script de compilación
│
└── windows/            # Bootstrap para Windows
    ├── bootstrap.asm   # Assembly puro para Windows
    ├── build.bat       # Script de compilación
    └── tempo-windows.c # Generador PE (a migrar a Tempo)
```

## Compilación

### Linux
```bash
cd compiler/linux
./build.sh
```

Genera:
- `tempo-bootstrap` - Bootstrap en assembly
- `stage1` - Compilador Tempo
- Se copia a `build/linux/tempo`

### Windows
```cmd
cd compiler\windows
build.bat
```

Genera:
- `tempo-bootstrap.exe` - Bootstrap en assembly
- `stage1.exe` - Compilador Tempo  
- Se copia a `build\windows\tempo.exe`

## Proceso de Bootstrap

1. **Assembly Bootstrap** (0% C)
   - Linux: `linux/bootstrap.asm` → ELF64
   - Windows: `windows/bootstrap.asm` → PE64

2. **Stage 1** (100% Tempo)
   - `stage1.tempo` - Compilador mínimo

3. **Compilador Final** (100% Tempo)
   - `tempo.tempo` - Compilador completo

## Sin C

NO hay C en el proceso. Los únicos archivos externos son:
- Linux: syscalls del kernel
- Windows: kernel32.dll (API de Windows)

Ambos son interfaces del OS, no bibliotecas de C.

## Verificación

Para verificar que no hay C:

```bash
# Linux
ldd tempo-bootstrap
# No debe mostrar libc

# Windows  
dumpbin /dependents tempo-bootstrap.exe
# Solo debe mostrar kernel32.dll
```

[T∞] Tempo puro en todas las plataformas.