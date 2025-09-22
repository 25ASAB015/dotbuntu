# Changelog

All notable changes to this project will be documented in this file.

The format is based on Keep a Changelog and this project adheres to Semantic Versioning.

## [Unreleased]
- Flags CLI potenciales: `--no-clear`, `--no-pause`, `--fail-on-apt-errors`.
- Salida con código ≠ 0 cuando persisten fallos APT (opcional configurable).

## [0.1.0] - 2025-09-22
### Added
- Resumen APT: listar paquetes presentes, instalados y fallidos.
- Instalación por paquete con captura de errores y reintentos interactivos.
- Manejo de `bat`/`batcat` y `gem coderay` incluido en el resumen.
- Pausa tras resumen APT (omitible con `NO_PAUSE=1`).
- `NO_CLEAR=1` para no limpiar pantalla; limpieza condicional con `maybe_clear`.
- Modo de prueba `TEST_FAIL_APT` para simular fallos APT y validar flujo.
- Resumen final: APT + dotbare con remoto y próximo paso.
- Opción de relanzar si hay fallos APT: borra `~/.cfg` y `~/.dotbare` y reejecuta.
- Logging de errores a `~/.local/share/dotbuntu/install_errors.log`.
- Wrapper `~/.local/bin/dotbare` para resolver helpers correctamente.

### Changed
- README reescrito para ser más amigable (TL;DR, variables, troubleshooting, ejemplos).

### Fixed
- Error de helpers de dotbare al usar symlink; se reemplaza por wrapper.

[Unreleased]: https://github.com/25ASAB015/dotbuntu/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/25ASAB015/dotbuntu/releases/tag/v0.1.0
