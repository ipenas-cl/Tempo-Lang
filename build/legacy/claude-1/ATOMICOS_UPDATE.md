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

# ✅ Actualización: TempoOS → AtomicOS

## 📝 Resumen de Cambios

Se han actualizado todas las referencias de **TempoOS** a **AtomicOS** en el repositorio.

## 📊 Archivos Actualizados (14 archivos)

### Bootloader
- `/bootloader/build.sh`
- `/bootloader/bios/boot.s`
- `/bootloader/bios/stage2.tempo`
- `/bootloader/uefi/boot.tempo`
- `/bootloader/README.md`
- `/bootloader/Makefile`

### Kernel
- `/src/kernel/kernel.tempo`
- `/src/kernel/memory.tempo`
- `/src/kernel/scheduler.tempo`
- `/src/kernel/syscalls.tempo`
- `/src/kernel/vga.tempo`
- `/src/kernel/interrupts.tempo`

### Documentación
- `/course/README.md`
- `/docs/philosophy/TEMPO_BIBLE.md`

## 🔍 Cambios Realizados

- `TempoOS` → `AtomicOS`
- `Tempo OS` → `AtomicOS`
- `tempo-os` → `AtomicOS`

## ✅ Verificación

Se verificó que el kernel ahora muestra correctamente:
```tempo
vga_print("AtomicOS Kernel v0.1.0\n")
```

## 📌 Nota Importante

**AtomicOS** es el sistema operativo determinístico escrito en Tempo:
- **Atomic** = Operaciones atómicas garantizadas
- **Determinístico** = WCET garantizado en todas las operaciones
- **100% Tempo** = Sin C, puro Tempo

---

**[T∞]** *"AtomicOS: El sistema operativo con tiempo de ejecución garantizado"*