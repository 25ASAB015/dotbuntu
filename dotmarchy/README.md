# 🚀 dotmarchy

<div align="center">

**Script automatizado para instalar y configurar dotfiles en Arch Linux / Omarchy Linux**

[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Shell Script](https://img.shields.io/badge/Shell-Bash-4EAA25?logo=gnu-bash)](https://www.gnu.org/software/bash/)

</div>

---

## 📋 Tabla de Contenidos

- [¿Qué es dotmarchy?](#-qué-es-dotmarchy)
- [✨ Características Principales](#-características-principales)
- [🛡️ Seguridad y Confiabilidad](#️-seguridad-y-confiabilidad)
- [🎯 Beneficios](#-beneficios)
- [📦 Requisitos](#-requisitos)
- [🚀 Instalación y Uso](#-instalación-y-uso)
- [⚙️ Opciones Avanzadas](#️-opciones-avanzadas)
- [🔧 Tecnologías Utilizadas](#-tecnologías-utilizadas)
- [📝 Logs y Depuración](#-logs-y-depuración)
- [🤝 Contribuir](#-contribuir)
- [📄 Licencia](#-licencia)

---

## 🎯 ¿Qué es dotmarchy?

**dotmarchy** es un sistema modular de scripts bash diseñado para automatizar completamente la instalación y configuración de dotfiles en sistemas Arch Linux y Omarchy Linux. Elimina la necesidad de configurar manualmente tu entorno de desarrollo, gestionando todo el proceso de forma segura y automatizada.

Con una **arquitectura modular inspirada en dotbare** (21 componentes optimizados), soporte para **múltiples fuentes de paquetes** (pacman, Chaotic-AUR, AUR, npm, cargo, pip, ruby, GitHub releases) y un sistema de paquetes **core + extras** personalizable, dotmarchy se adapta tanto a configuraciones minimalistas como a entornos de desarrollo completos.

### ¿Por qué usar dotmarchy?

- ⚡ **Ahorra tiempo**: Configura tu entorno completo en minutos, no en horas
- 🛡️ **Seguro**: Múltiples verificaciones de seguridad y respaldos automáticos
- 🔄 **Reproducible**: Mismo entorno en cualquier máquina Arch/Omarchy
- 🎨 **Profesional**: Interfaz visual clara con feedback en tiempo real
- 🧪 **Probado**: Código estricto con manejo robusto de errores
- 🎯 **Flexible**: Modo core minimalista o extras completo según necesites
- 🧩 **Modular**: Arquitectura organizada en 21 componentes independientes
- 🔧 **Mantenible**: Código limpio siguiendo el patrón dotbare
- ⚙️ **Extensible**: Fácil agregar nuevos gestores de paquetes

---

## ✨ Características Principales

### 🔄 Automatización Completa

- ✅ Actualización automática del sistema (`pacman -Syu`)
- ✅ Configuración automática del repositorio Chaotic-AUR
- ✅ Instalación inteligente de dependencias desde **múltiples fuentes**:
  - 📦 **Repositorios oficiales de Arch** (pacman)
  - ⚡ **Chaotic-AUR** (paquetes AUR pre-compilados)
  - 🔨 **AUR** (compilación con paru)
  - 📦 **npm** (paquetes Node.js globales)
  - 🦀 **Cargo** (herramientas Rust)
  - 🐍 **pip/pipx** (paquetes Python)
  - 💎 **RubyGems** (gemas Ruby)
  - 🐙 **GitHub Releases** (binarios directos)
- ✅ Modo `--extras` para instalar paquetes opcionales adicionales
- ✅ Configuración automática de dotbare para gestión de dotfiles
- ✅ Clonado y aplicación automática de tu repositorio de dotfiles

### 🎨 Experiencia de Usuario

- 🖥️ Interfaz visual con colores y logo ASCII
- 📊 Feedback en tiempo real con información de progreso
- ⏱️ Cronometraje de operaciones para transparencia
- 📝 Mensajes claros y descriptivos en cada paso
- 🎯 Detección dinámica de modos (muestra paquetes extras si `--extras` está activado)
- 📋 Información detallada del repositorio de dotfiles a clonar

### 🔍 Verificaciones Inteligentes

- 🔐 Verificación de permisos (no ejecuta como root)
- 🌐 Verificación de conexión a internet
- 📦 Detección de paquetes ya instalados en **todas las fuentes** (evita reinstalaciones)
- 🔄 Detección de configuraciones existentes
- ✅ Verificación post-instalación de cada paquete
- 📝 Logging automático de todos los errores
- 🧩 Scripts modulares independientes y testeables

---

## 🛡️ Seguridad y Confiabilidad

### Múltiples Capas de Seguridad

#### 1. **Modo Estricto de Bash**
```bash
set -Eeuo pipefail
```
- **`-E`**: Los traps de error se heredan en funciones
- **`-e`**: Sale inmediatamente si un comando falla
- **`-u`**: Trata variables no definidas como error
- **`-o pipefail`**: Detecta errores en pipelines

#### 2. **Verificaciones Previas Obligatorias**

- ❌ **No ejecuta como root**: Protege contra modificaciones peligrosas del sistema
- 🌐 **Verificación de internet**: Asegura conectividad antes de descargar
- 🐧 **Verificación de sistema**: Solo funciona en Arch/Omarchy (requiere pacman)

#### 3. **Manejo Robusto de Errores**

- 📋 **Logging automático**: Todos los errores se registran en `~/.local/share/dotmarchy/install_errors.log`
- 🔍 **Trap de errores**: Captura automática de fallos con información de línea y código
- ✅ **Verificación post-instalación**: Confirma que cada paquete se instaló correctamente
- 🔄 **Manejo de conflictos**: Detecta y resuelve conflictos de configuración existente

#### 4. **Respaldo Automático**

- 💾 **Backups antes de sobrescribir**: Protege tus configuraciones existentes
- 📁 **Respaldo de directorios conflictivos**: Guarda versiones anteriores automáticamente
- 🔙 **Recuperación fácil**: Puedes restaurar desde los backups creados

#### 5. **Código de Calidad**

- ✅ **shellcheck**: Análisis estático de código para detectar errores
- ✅ **shfmt**: Formateo consistente del código
- ✅ **Arquitectura modular**: 21 componentes organizados siguiendo patrón dotbare
- ✅ **Separación de responsabilidades**: Helpers, core, extras, setup
- ✅ **Scripts independientes**: Cada componente es testeable por separado
- ✅ **Comentarios en español**: Documentación clara y comprensible

---

## 🎯 Beneficios

### Para Desarrolladores

1. **Configuración Instantánea**
   - Configura un nuevo sistema en minutos
   - Mismo entorno en todas tus máquinas
   - Sin configuración manual tediosa

2. **Gestión Centralizada**
   - Todos tus dotfiles en un repositorio Git
   - Sincronización automática entre máquinas
   - Historial completo de cambios

3. **Reproducibilidad**
   - Entorno idéntico en cualquier momento
   - Fácil onboarding de nuevos desarrolladores
   - Recuperación rápida después de reinstalación

### Para Usuarios

1. **Simplicidad**
   - Un solo comando para configurar todo
   - Sin necesidad de conocimiento técnico profundo
   - Interfaz clara y guiada

2. **Seguridad**
   - Múltiples verificaciones de seguridad
   - Respaldo automático de configuraciones
   - No modifica configuraciones críticas del sistema

3. **Confiabilidad**
   - Manejo robusto de errores
   - Logs detallados para depuración
   - Verificación de cada paso

---

## 📦 Requisitos

- **Sistema Operativo**: Arch Linux u Omarchy Linux
- **Gestor de paquetes**: `pacman` (incluido por defecto)
- **Permisos**: Usuario normal (NO root)
- **Conexión**: Internet activa
- **Ubicación**: Ejecutable desde cualquier directorio

---

## 💾 Instalación

> **Nota**
>
> El instalador solo funciona para Arch Linux y distribuciones basadas en Arch (como Omarchy Linux). No funciona en distribuciones sin systemd como Artix.
>
> Antes de ejecutar este comando, revisa el código de dotmarchy para asegurarte de que funciona y confirmar que es seguro para tu sistema.

Abre una terminal y ejecuta estos comandos uno por uno:

```bash
# Descargar el instalador en tu $HOME
curl -LO https://raw.githubusercontent.com/25ASAB015/dotmarchy/master/dotmarchy

# Dar permisos de ejecución
chmod +x dotmarchy

# Ejecutar el instalador
./dotmarchy

# O con paquetes extras opcionales
./dotmarchy --extras
```

### Uso con Repositorio Personalizado

Si deseas usar tu propio repositorio de dotfiles:

```bash
# Especificar repositorio personalizado
./dotmarchy https://github.com/usuario/mis-dotfiles.git

# O usando SSH
./dotmarchy git@github.com:usuario/mis-dotfiles.git

# O usando el flag --repo
./dotmarchy --repo https://github.com/usuario/mis-dotfiles.git
```

### Paquetes: Core vs Extras

dotmarchy instala paquetes en dos niveles:

#### 📦 Paquetes Core (Siempre se instalan)

Estos paquetes son esenciales para el funcionamiento de dotmarchy:

**Repositorios Oficiales:**
- `tree` - Visualización de estructura de directorios
- `bat` - Visualizador de archivos con resaltado de sintaxis
- `highlight` - Resaltador de sintaxis
- `ruby-coderay` - Librería para resaltado de sintaxis
- `git-delta` - Visor de diffs elegante para Git
- `diff-so-fancy` - Visor de diffs mejorado
- `npm` - Gestor de paquetes Node.js

**Chaotic-AUR:**
- `paru` - Helper de AUR (para instalar paquetes del AUR)

**AUR:**
- `dotbare` - Gestor de dotfiles con Git bare repository

#### ⭐ Paquetes Extras (Solo con `--extras`)

Si deseas un entorno más completo con herramientas de desarrollo, aplicaciones y utilidades adicionales, usa el flag `--extras`:

```bash
# Instalar paquetes core + extras
./dotmarchy --extras

# Combinar con repositorio personalizado
./dotmarchy --extras --repo https://github.com/usuario/mis-dotfiles.git

# Agregar configuración del entorno (con archivo de configuración)
./dotmarchy --extras --setup-env
```

**Paquetes por defecto con `--extras`** (personalizables vía `setup.conf`):

**Herramientas de Desarrollo (Repositorios Oficiales):**
- `neovim` - Editor de texto avanzado
- `tmux` - Multiplexor de terminal
- `htop` - Monitor de procesos interactivo
- `ripgrep` - Búsqueda de texto ultra-rápida
- `fd` - Alternativa moderna a `find`
- `fzf` - Buscador fuzzy de línea de comandos

**Aplicaciones (Chaotic-AUR):**
- `brave-bin` - Navegador web enfocado en privacidad
- `visual-studio-code-bin` - Editor de código de Microsoft

**Shell Tools (AUR):**
- `zsh-theme-powerlevel10k-git` - Tema poderoso para Zsh
- `zsh-autosuggestions` - Autocompletado inteligente para Zsh
- `zsh-syntax-highlighting` - Resaltado de sintaxis para Zsh

**Herramientas NPM (Globales):**
- `@fission-ai/openspec` - Herramienta de gestión de especificaciones OpenSpec

#### Comparativa Rápida: Core vs Extras

| Característica | Sin `--extras` | Con `--extras` |
|---------------|----------------|----------------|
| **Gestores de paquetes** | 4 fuentes | 8 fuentes |
| **Paquetes oficiales** | 7 paquetes | ~13+ paquetes |
| **Chaotic-AUR** | 1 paquete (paru) | ~3+ paquetes |
| **AUR** | 1 paquete (dotbare) | ~4+ paquetes |
| **npm** | 0 paquetes | Configurable |
| **cargo** | 0 paquetes | Configurable |
| **pip/pipx** | 0 paquetes | Configurable |
| **ruby gems** | 0 paquetes | Configurable |
| **GitHub releases** | 0 paquetes | Configurable |
| **Total mínimo** | **9 paquetes** | **20+ paquetes** |
| **Tiempo aprox.** | ~5-10 min | ~15-30 min |
| **Uso de disco** | ~50-100 MB | ~500 MB - 1 GB |
| **Ideal para** | Configuración minimalista | Entorno de desarrollo completo |

> **Nota**: Los paquetes extras son completamente personalizables vía `~/.config/dotmarchy/setup.conf`

### Ayuda

Para ver todas las opciones disponibles:

```bash
./dotmarchy --help
```

### Archivo de Configuración

dotmarchy utiliza un archivo de configuración centralizado: `~/.config/dotmarchy/setup.conf`

Este archivo controla:

1. **Paquetes extras** (`--extras` flag) - Personaliza qué paquetes instalar
2. **Configuración de entorno** (`--setup-env` flag) - Directorios, repos, scripts

**Configuración:**

```bash
# Crear el archivo de configuración
mkdir -p ~/.config/dotmarchy
cp setup.conf.example ~/.config/dotmarchy/setup.conf

# Editar según necesites
nano ~/.config/dotmarchy/setup.conf
```

#### Personalizar Paquetes Extras

Por defecto, `--extras` instala un conjunto de paquetes predefinidos. Puedes personalizarlos en el archivo de configuración:

```bash
# En ~/.config/dotmarchy/setup.conf

# Paquetes oficiales (ejemplo: solo lo esencial)
EXTRA_DEPENDENCIES=(
    "neovim"
    "tmux"
)

# Chaotic-AUR (ejemplo: solo VS Code)
EXTRA_CHAOTIC_DEPENDENCIES=(
    "visual-studio-code-bin"
)

# AUR (ejemplo: ninguno)
EXTRA_AUR_APPS=()

# NPM (ejemplo: herramientas de desarrollo)
EXTRA_NPM_PACKAGES=(
    "@fission-ai/openspec"
    "typescript"
    "prettier"
)
```

**Sin configuración:** Se usan los paquetes predeterminados documentados más abajo.

#### Configurar Entorno de Desarrollo

Además de paquetes, puedes configurar tu entorno con `--setup-env`:

- Creación de estructura de directorios
- Clonado de repositorios (plugins, herramientas)
- Descarga de scripts
- Configuración de shell

Ver `setup.conf.example` en el repositorio para un ejemplo completo de configuración.

### Ejemplos de Uso Completos

```bash
# Instalación básica (solo paquetes core)
./dotmarchy

# Instalación completa con extras
./dotmarchy --extras

# Configurar entorno (requiere archivo de configuración)
./dotmarchy --setup-env

# Todo junto: extras + configuración de entorno
./dotmarchy --extras --setup-env

# Repositorio personalizado + extras + entorno
./dotmarchy --extras --setup-env --repo git@github.com:usuario/dotfiles.git

# Modo dry-run para probar sin instalar
DRY_RUN=1 ./dotmarchy --extras

# Modo verbose para depuración
VERBOSE=1 ./dotmarchy --extras
```

---

## 📦 Sistema de Gestión de Paquetes

dotmarchy utiliza un sistema de gestión de paquetes multi-fuente que optimiza la instalación y garantiza compatibilidad:

### Estrategia de Instalación (8 fuentes)

1. **Repositorios Oficiales (pacman)** 🏛️
   - Paquetes mantenidos oficialmente por Arch Linux
   - Altamente estables y probados
   - Instalación rápida y confiable

2. **Chaotic-AUR** ⚡
   - Paquetes AUR pre-compilados
   - Evita tiempos de compilación largos
   - Ideal para aplicaciones grandes (navegadores, IDEs)

3. **AUR vía paru** 🔨
   - Paquetes que requieren compilación
   - Acceso a la colección completa de AUR
   - Para herramientas especializadas y temas

4. **npm Registry** 📦
   - Paquetes Node.js instalados globalmente
   - Herramientas CLI modernas
   - Solo con `--extras` (configurable vía `setup.conf`)

5. **Cargo (Rust)** 🦀
   - Herramientas Rust ultra-rápidas
   - Compiladas desde crates.io
   - Solo con `--extras` (ej: ripgrep-all, lsd, tokei)

6. **pip/pipx (Python)** 🐍
   - Paquetes Python en entornos aislados
   - Herramientas de desarrollo y CLI
   - Solo con `--extras` (ej: httpie, black, ruff)

7. **RubyGems** 💎
   - Gemas Ruby instaladas localmente
   - Tools especializados
   - Solo con `--extras` (ej: tmuxinator, colorls)

8. **GitHub Releases** 🐙
   - Binarios descargados directamente
   - Para herramientas sin gestor de paquetes
   - Solo con `--extras` (ej: lazygit, delta, fzf)

### Ventajas del Sistema

- ✅ **Detección inteligente**: Evita reinstalar paquetes ya instalados
- ✅ **Verificación post-instalación**: Confirma que cada paquete se instaló correctamente
- ✅ **Manejo de errores robusto**: Logging detallado de fallos
- ✅ **Instalación por lotes**: Optimiza tiempo instalando múltiples paquetes juntos
- ✅ **Feedback visual**: Muestra progreso de cada instalación en tiempo real

---

## ⚙️ Opciones Avanzadas

### Variables de Entorno

Puedes personalizar el comportamiento del script usando variables de entorno:

```bash
# Cambiar directorio de dotbare (por defecto: ~/.cfg)
export DOTBARE_DIR="$HOME/.mi-dotfiles"

# Cambiar árbol de trabajo (por defecto: ~)
export DOTBARE_TREE="$HOME"

# Ejecutar
./dotmarchy
```

### Modo Dry-Run (Prueba)

Para probar el script sin hacer cambios reales:

```bash
DRY_RUN=1 ./dotmarchy
```

### Modo Verbose (Depuración)

Para ver información detallada de cada operación:

```bash
VERBOSE=1 ./dotmarchy
```

---

## 🔧 Tecnologías Utilizadas

### Herramientas Principales

- **Bash 4.0+**: Lenguaje de scripting principal con modo estricto (`set -Eeuo pipefail`)
- **pacman**: Gestor de paquetes oficial de Arch Linux
- **paru**: Helper de AUR (instalado automáticamente desde Chaotic-AUR)
- **dotbare**: Gestor de dotfiles basado en Git bare repository
- **git**: Control de versiones para repositorios de dotfiles

### Gestores de Paquetes Adicionales (Extras)

- **npm**: Paquetes Node.js globales
- **cargo**: Herramientas Rust (crates.io)
- **pip/pipx**: Paquetes Python en entornos aislados
- **gem**: Gemas Ruby instaladas localmente
- **curl**: Descarga de binarios desde GitHub Releases

### Herramientas de Desarrollo

- **shellcheck**: Análisis estático de código bash
- **shfmt**: Formateador de código shell
- **OpenSpec**: Framework para spec-driven development

### Repositorios y Fuentes de Paquetes

- **Repositorios Oficiales de Arch**: Paquetes base del sistema y herramientas core
- **Chaotic-AUR**: Repositorio de terceros para instalación rápida de paquetes AUR pre-compilados
- **AUR (Arch User Repository)**: Repositorio comunitario de paquetes compilados con paru
- **npm Registry**: Paquetes Node.js instalados globalmente
- **crates.io**: Herramientas Rust compiladas con cargo
- **PyPI**: Paquetes Python instalados con pip/pipx
- **RubyGems**: Gemas Ruby instaladas con gem
- **GitHub Releases**: Binarios descargados directamente

---

## 📝 Logs y Depuración

### Ubicación de Logs

Todos los errores se registran automáticamente en:
```
~/.local/share/dotmarchy/install_errors.log
```

### Formato de Logs

Cada entrada incluye:
- ⏰ **Timestamp**: Fecha y hora del error
- 📍 **Ubicación**: Línea del código donde ocurrió
- 🔢 **Código de salida**: Código de error del comando
- 📋 **Mensaje**: Descripción detallada del error

### Ejemplo de Log

```
[2025-09-21 14:30:15] ERROR: Fallo en la línea 423. Código: 1
[2025-09-21 14:30:16] ERROR: Error al instalar: paquete-example
```

### Depuración

Si encuentras problemas:

1. **Revisa los logs**: `cat ~/.local/share/dotmarchy/install_errors.log`
2. **Ejecuta en modo verbose**: `VERBOSE=1 ./dotmarchy`
3. **Verifica los requisitos**: Asegúrate de cumplir todos los requisitos
4. **Revisa el código**: El script está bien documentado y comentado

---

## 🏗️ Arquitectura del Proyecto

### Estructura Modular (Patrón dotbare)

dotmarchy sigue una arquitectura modular inspirada en [dotbare](https://github.com/kazhala/dotbare), con 21 componentes organizados en una estructura clara:

```
dotmarchy/
├── dotmarchy                 # Router principal (106 líneas, orquesta todo)
├── helper/                   # Librerías compartidas (6 archivos)
│   ├── set_variable.sh       # Variables, configuración, arrays de paquetes
│   ├── colors.sh             # Definiciones de colores y estilos
│   ├── logger.sh             # Sistema de logging (log, info, warn, debug)
│   ├── utils.sh              # Utilidades (run, require_cmd, normalize_repo_url)
│   ├── checks.sh             # Verificaciones iniciales (sistema, internet)
│   └── prompts.sh            # Interacción (logo, usage, welcome, farewell)
├── scripts/
│   ├── core/                 # Scripts core (6 archivos, siempre ejecutados)
│   │   ├── fupdate           # Actualización del sistema (pacman -Syu)
│   │   ├── fchaotic          # Configuración Chaotic-AUR
│   │   ├── fdeps             # Instalación dependencias oficiales
│   │   ├── fchaotic-deps     # Instalación desde Chaotic-AUR
│   │   ├── faur              # Instalación desde AUR
│   │   └── fdotbare          # Configuración dotbare
│   ├── extras/               # Scripts extras (6 archivos, solo con --extras)
│   │   ├── fnpm              # Paquetes npm globales
│   │   ├── fcargo            # Herramientas Rust/cargo
│   │   ├── fpython           # Paquetes Python (pip/pipx)
│   │   ├── fruby             # Gemas Ruby
│   │   ├── fgithub           # Tools desde GitHub releases
│   │   └── fpath             # Configuración PATH (8 rutas: cargo, local, ruby, lua, go, nvm, deno, pynvim)
│   ├── setup/                # Setup entorno (1 archivo, solo con --setup-env)
│   │   └── fenv-setup        # Orquestador unificado (dirs, repos, scripts, shell)
│   └── fverify               # Verificación completa de instalación
└── setup.conf.example        # Archivo de configuración de ejemplo
```

### Ventajas de la Arquitectura Modular

- 🧩 **Separación clara**: Cada script tiene una responsabilidad específica
- 🔧 **Mantenimiento fácil**: Modificar un componente no afecta a otros
- 🧪 **Testeable**: Cada script puede ejecutarse y probarse independientemente
- ⚙️ **Extensible**: Agregar nuevos gestores de paquetes es trivial
- 📖 **Legible**: Código organizado en archivos pequeños y enfocados
- 🔄 **Reutilizable**: Helpers compartidos evitan duplicación de código

### Principios de Diseño

1. **Scripts ejecutables con prefijo `f`**: Siguiendo convención dotbare
2. **Helpers sourceable**: Solo definiciones, no ejecutables
3. **Comunicación vía environment**: Variables exportadas entre componentes
4. **Idempotencia**: Operaciones seguras para ejecutar múltiples veces
5. **Manejo robusto de errores**: `set -Eeuo pipefail` en todos los scripts

### Flujo de Ejecución

El router principal (`dotmarchy`) orquesta la ejecución de todos los componentes:

```
1. Router principal (dotmarchy)
   ├─ Source de todos los helpers (set_variable, colors, logger, utils, checks, prompts)
   ├─ Parseo de argumentos (--extras, --setup-env, --repo, --verify, etc.)
   ↓
2. Verificaciones iniciales (checks.sh)
   ├─ No ejecuta como root
   ├─ Verifica conexión a internet
   └─ Confirma que es sistema Arch/Omarchy
   ↓
3. Mensaje de bienvenida (welcome)
   ├─ Logo ASCII de dotmarchy
   ├─ Información dinámica (muestra extras/setup si están activos)
   └─ Confirmación del usuario
   ↓
4. Scripts Core (siempre ejecutados)
   ├─ scripts/core/fupdate          → Actualización sistema (pacman -Syu)
   ├─ scripts/core/fchaotic         → Configuración Chaotic-AUR
   ├─ scripts/core/fdeps            → Deps oficiales
   ├─ scripts/core/fchaotic-deps    → Deps Chaotic-AUR
   ├─ scripts/core/faur             → Deps AUR
   └─ scripts/core/fdotbare         → Configuración dotbare + clone dotfiles
   ↓
5. Scripts Extras (solo si --extras)
   ├─ scripts/extras/fnpm           → Paquetes npm globales
   ├─ scripts/extras/fcargo         → Herramientas Rust
   ├─ scripts/extras/fpython        → Paquetes Python (pip/pipx)
   ├─ scripts/extras/fruby          → Gemas Ruby
   ├─ scripts/extras/fgithub        → Tools desde GitHub releases
   └─ scripts/extras/fpath          → Configuración PATH (8 rutas)
   ↓
6. Setup Entorno (solo si --setup-env)
   └─ scripts/setup/fenv-setup      → Orquestador unificado
      ├─ [1] Crear directorios personalizados
      ├─ [2] Clonar repositorios (plugins, tools)
      ├─ [3] Descargar scripts
      └─ [4] Configurar shell (.zshrc/.bashrc)
   ↓
7. Verificación (solo si --verify)
   └─ scripts/fverify               → Verificación completa de instalación
   ↓
8. Finalización (farewell)
   ├─ Resumen de instalación
   ├─ Estadísticas (tiempo, paquetes instalados)
   └─ Próximos pasos
```

### Comunicación Entre Componentes

Los scripts se comunican mediante:
- **Variables exportadas**: `REPO_URL`, `INSTALL_EXTRAS`, `SETUP_ENVIRONMENT`, `DRY_RUN`, `VERBOSE`
- **Códigos de salida**: `0` (éxito), `1` (error)
- **Logs compartidos**: `~/.local/share/dotmarchy/install_errors.log`
- **Helpers compartidos**: Todas las funciones de `helper/` disponibles para todos los scripts

---

## 🏛️ Historia del Proyecto

### Refactorización a Arquitectura Modular (2025-11-16)

dotmarchy fue originalmente un script monolítico de **2,465 líneas** en un solo archivo. Fue completamente refactorizado a una arquitectura modular inspirada en [dotbare](https://github.com/kazhala/dotbare), manteniendo 100% de compatibilidad backward.

**Métricas de la refactorización:**
- 📉 **Reducción del 95.7%** en el script principal (2,464 → 106 líneas)
- 🧩 **21 componentes modulares** con separación clara de responsabilidades
- ✅ **13 correcciones** + 1 mejora UX + limpieza de código muerto
- 🎯 **100% de fidelidad** funcional y visual al monolítico original
- 📖 **235 tareas implementadas** documentadas en OpenSpec

**Ventajas de la refactorización:**
- ✅ Código más mantenible y testeable
- ✅ Fácil agregar nuevos gestores de paquetes
- ✅ Scripts independientes ejecutables individualmente
- ✅ Mejor organización del código fuente
- ✅ Documentación detallada de cada componente

**Documentación de la refactorización:**
- Ver `REFACTORING_SUMMARY.md` para detalles técnicos completos
- Ver `openspec/changes/refactor-monolithic-to-modular/` para propuestas, tareas y specs

---

## 🤝 Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

### Estándares de Código

- Usa `shellcheck` para verificar tu código
- Usa `shfmt` para formatear tu código
- Mantén el estilo consistente con el código existente
- Añade comentarios en español para nuevas funciones

---

## 📄 Licencia

Este proyecto está licenciado bajo la **GNU General Public License v3.0** (GPL-3.0).

Ver el archivo [LICENSE](LICENSE) para más detalles.

---

## 👤 Autor

**Roberto Flores**

- GitHub: [@25ASAB015](https://github.com/25ASAB015)
- Email: 25ASAB015@ujmd.edu.sv

---

## 🙏 Agradecimientos

- **dotbare**: Por proporcionar una herramienta excelente para gestión de dotfiles
- **Chaotic-AUR**: Por ofrecer paquetes AUR pre-compilados
- **Comunidad de Arch Linux**: Por mantener un ecosistema robusto y confiable

---

<div align="center">

**⭐ Si este proyecto te ha sido útil, considera darle una estrella ⭐**

Hecho con ❤️ para la comunidad de Arch Linux

</div>

