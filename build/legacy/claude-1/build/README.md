# Build - Ejecutables de Tempo

╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝

## Estructura

```
build/
├── README.md           # Este archivo
│
├── linux/              # Ejecutables para Linux
│   └── tempo           # Compilador Tempo para Linux
│
└── windows/            # Ejecutables para Windows
    ├── tempo.exe       # Compilador Tempo para Windows
    ├── examples/       # Programas de ejemplo
    ├── output/         # Ejecutables compilados
    └── stage*/         # Etapas del compilador
```

## Uso

### En Linux/WSL
```bash
# El script principal detecta la plataforma
./tempo programa.tempo

# O directamente
./build/linux/tempo programa.tempo
```

### En Windows
```cmd
REM Desde CMD o PowerShell
build\windows\tempo.exe programa.tempo

REM Genera programa.exe automáticamente
```

## Primera compilación

Si no existen los ejecutables:

### Linux
```bash
cd compiler/linux
./build.sh
# Copia el resultado a build/linux/tempo
```

### Windows
```cmd
cd compiler\windows
build.bat
REM Copia el resultado a build\windows\tempo.exe
```

## Cross-Compilation

Desde Linux puedes compilar para Windows:
```bash
./tempo --target windows programa.tempo
# Genera programa.exe (PE64)
```

Desde Windows puedes compilar para Linux:
```cmd
tempo.exe --target linux programa.tempo
REM Genera programa (ELF64)
```

[T∞] Un compilador, todas las plataformas.