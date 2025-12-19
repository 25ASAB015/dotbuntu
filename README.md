# 🛠️ dotbuntu

[![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)
[![ShellCheck](https://github.com/25ASAB015/dotbuntu/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/25ASAB015/dotbuntu/actions/workflows/shellcheck.yml)
[![Version](https://img.shields.io/badge/version-1.0.0-success)](https://github.com/25ASAB015/dotbuntu/releases)

**dotbuntu** es una herramienta unificada para la configuración profesional de Git y la gestión automatizada de dotfiles en sistemas Arch Linux. Consolida la potencia de `gitconfig` y `dotmarchy` en una única interfaz cohesiva.

## ✨ Características

-   **Configuración Profesional de Git:** SSH, GPG, y `.gitconfig` optimizado.
-   **Gestión de Dotfiles:** Integración con `dotbare` para rastrear configuraciones.
-   **Instalación Modular:** Soporte para paquetes Core, Extras (AUR, npm, cargo, pipx) y configuración de entorno.
-   **Seguridad Primero:** Backups automáticos de llaves existentes y archivos de configuración.
-   **No-Root:** Diseñado para ejecutarse 100% como usuario normal.

## 🚀 Instalación Rápida

```bash
git clone https://github.com/25ASAB015/dotbuntu.git
cd dotbuntu
chmod +x dotbuntu
./dotbuntu
```

## 📖 Uso

```bash
./dotbuntu [OPCIONES] [REPO_URL]
```

### Opciones Disponibles

| Opción | Descripción |
| :--- | :--- |
| `--extras` | Instala paquetes adicionales (npm, cargo, pipx, etc.) |
| `--setup-env` | Configura directorios, repositorios y shell |
| `--verify` | Ejecuta un diagnóstico del sistema y las herramientas |
| `--auto-upload` | Sube llaves automáticamente a GitHub (requiere `gh` auth) |
| `--non-interactive` | Ejecuta la fase de Git sin solicitar entradas |
| `--repo URL` | Especifica un repositorio de dotfiles alternativo |
| `-v, --verbose` | Habilita salida detallada |
| `-f, --force` | Fuerza operaciones sin confirmación |

## 🏗️ Estructura del Proyecto

```text
.
├── dotbuntu           # Orquestador principal
├── config/            # Configuraciones por defecto
├── helper/            # Funciones de utilidad y prompts
├── scripts/           # Módulos de funcionalidad
│   ├── core/          # Lógica fundamental de Git
│   ├── extras/        # scripts de instalación de paquetes
│   └── setup/         # scripts de configuración de entorno
└── tools/             # Herramientas auxiliares
```

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor, abre un issue o un PR para discutir cambios.

## 📄 Licencia

Este proyecto está bajo la licencia **GPL-3.0**.
