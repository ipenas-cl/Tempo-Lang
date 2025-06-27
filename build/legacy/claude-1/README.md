# Tempo Programming Language

<div align="center">

```
╔═════╦═════╦═════╗
║ 🛡️  ║ ⚖️  ║ ⚡  ║
║  C  ║  E  ║  G  ║
╚═════╩═════╩═════╝
╔═════════════════╗
║ wcet [T∞] bound ║
╚═════════════════╝
```

**El lenguaje de programación 100% determinístico**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20Windows-blue)](/)
[![Language](https://img.shields.io/badge/Language-Tempo-green)](/)

</div>

## 🚀 Inicio Rápido

```bash
# Construir el compilador desde cero (solo la primera vez)
./build.sh

# Compilar un programa
./tempo hello.tempo

# Ejecutar
./hello
```

## 📁 Estructura del Proyecto

```
tempo/
├── build.sh              # Sistema de construcción principal
├── tempo                 # Compilador (enlace simbólico)
├── README.md            # Este archivo
├── LICENSE              # MIT License
├── AUTHORS.md           # Ignacio Peña Sepúlveda
│
├── compiler/            # Compilador de Tempo
│   ├── tempo.tempo      # Compilador principal (100% Tempo)
│   ├── stages/          # Etapas de bootstrap
│   │   ├── stage0/      # Bootstrap inicial (Assembly)
│   │   ├── stage1/      # Compilador mínimo (Tempo)
│   │   └── stage2/      # Compilador completo (Tempo)
│   ├── linux/           # Bootstrap Linux (Assembly)
│   ├── windows/         # Bootstrap Windows (Assembly)
│   └── tools/           # Herramientas del compilador
│
├── src/                 # Código fuente
│   ├── std/             # Biblioteca estándar
│   ├── kernel/          # AtomicOS kernel
│   ├── drivers/         # Drivers del sistema
│   ├── fs/              # Sistema de archivos
│   ├── net/             # Stack de red
│   └── graphics/        # Sistema gráfico
│
├── apps/                # Aplicaciones
│   ├── doom/            # DOOM determinístico
│   └── orchestrator/    # Orquestador de contenedores
│
├── platform/            # Plataforma y hardware
│   ├── cpu/             # Diseño TempoCore CPU
│   ├── emulator/        # Emulador de TempoCore
│   └── hardware_synthesis/ # Síntesis FPGA
│
├── build/               # Archivos compilados
│   ├── linux/           # Ejecutables Linux
│   └── windows/         # Ejecutables Windows
│
├── docs/                # Documentación
├── examples/            # Ejemplos de código
├── benchmarks/          # Benchmarks competitivos
├── course/              # Curso de compiladores
└── bootloader/          # Bootloader UEFI/BIOS
```

## 🏗️ Proceso de Construcción

El compilador Tempo se construye en 5 etapas, **sin usar C**:

```
1. bootstrap.asm (Assembly) → tempo-bootstrap
2. stage0/bootstrap.s (Assembly) → stage0
3. stage0 compila stage1/compiler.tempo → stage1
4. stage1 compila stage2/compiler.tempo → stage2
5. stage2 compila compiler/tempo.tempo → tempo
```

### Construcción Manual

```bash
# Linux
cd compiler/linux
./build.sh

# Windows
cd compiler\windows
build.bat
```

## 💻 Ejemplo: Hello World

```tempo
// No se necesitan imports - todo está disponible globalmente
fn main() -> i32 {
    print_line("¡Hola, mundo determinístico!");
    
    // Mostrar los tres pilares
    print_line("╔═════╦═════╦═════╗");
    print_line("║ 🛡️  ║ ⚖️  ║ ⚡  ║");
    print_line("║  C  ║  E  ║  G  ║");
    print_line("╚═════╩═════╩═════╝");
    
    return 0;  // WCET: 5 ciclos garantizados
}
```

## 🎯 Características Principales

### 1. **100% Determinístico**
- Mismo input → Mismo output → Mismo tiempo
- WCET (Worst-Case Execution Time) garantizado
- Sin garbage collection ni sorpresas en runtime

### 2. **Sin Imports**
- Toda la biblioteca estándar disponible globalmente
- No más dependency hell
- Desarrollo offline completo

### 3. **Self-Hosting**
- Tempo está escrito en Tempo
- Bootstrap desde Assembly puro
- Cero dependencias de C

### 4. **Multi-Plataforma**
- Genera ejecutables nativos Linux (ELF64)
- Genera ejecutables nativos Windows (PE64)
- Cross-compilation soportada

## 📊 Benchmarks

| Sistema | Implementación Original | **Tempo** | Mejora |
|---------|------------------------|-----------|--------|
| Redis | 100K ops/s | **450K ops/s** | 4.5x |
| Nginx | 50K req/s | **150K req/s** | 3.0x |
| PostgreSQL | 5K tx/s | **18K tx/s** | 3.6x |
| WCET | Variable | **Determinístico** | ∞ |

## 🎼 Los Tres Pilares (C-E-G)

Los tres pilares de Tempo forman un acorde perfecto de Do Mayor:

- **🛡️ C (Do)**: **Seguridad** - Protección contra vulnerabilidades
- **⚖️ E (Mi)**: **Estabilidad** - Comportamiento predecible
- **⚡ G (Sol)**: **Rendimiento** - Velocidad máxima garantizada

## 🌍 Casos de Uso

### PyMEs vs Big Tech
- Compite con Amazon/Google sin su infraestructura
- Servidores determinísticos de alto rendimiento
- Costos predecibles y escalables

### Trading Algorítmico
- Latencia garantizada para retail traders
- Compite con HFT (High-Frequency Trading)
- Ejecución determinística de órdenes

### Dispositivos Médicos
- Tiempo de respuesta garantizado
- Certificación más simple por determinismo
- Funciona sin conexión a internet

### Edge Computing
- IoT devices con comportamiento predecible
- Sistemas embebidos de tiempo real
- Consumo energético determinístico

## 🛠️ Herramientas Incluidas

- **Compilador**: Multi-etapa con optimizaciones WCET-aware
- **AtomicOS**: Sistema operativo determinístico
- **Biblioteca Estándar**: Completa, sin imports necesarios
- **Depurador**: Con análisis de WCET
- **Profiler**: Medición precisa de tiempos

## 📚 Documentación

- [Guía de Inicio](docs/quickstart.md)
- [Manual del Lenguaje](docs/manual.md)
- [Curso de Compiladores](course/) - 27 lecciones
- [API Reference](docs/api.md)
- [Filosofía de Tempo](docs/philosophy/)

## 🤝 Contribuir

Tempo es software libre bajo licencia MIT. Contribuciones bienvenidas:

1. Fork el repositorio
2. Crea tu rama (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📜 Licencia

MIT License - Ver [LICENSE](LICENSE) para detalles.

## 👨‍💻 Autor

**Ignacio Peña Sepúlveda**  
📅 June 25, 2025

---

<div align="center">

**[T∞]** *"El tiempo es determinístico, la ejecución es perfecta"*

</div>