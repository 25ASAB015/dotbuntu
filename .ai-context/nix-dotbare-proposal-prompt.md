# Propuesta: Migración a Arquitectura NIX + dotbare

## Contexto del Proyecto

**dotmarchy** es un sistema de gestión de dotfiles y configuración de entorno de desarrollo que actualmente:

- Gestiona instalación de paquetes desde múltiples fuentes (apt/pacman, AUR, Chaotic-AUR, cargo, npm, pipx, gem)
- Usa dotbare (git bare repository) para gestión de dotfiles
- Intenta mantener compatibilidad entre Arch Linux y Ubuntu/Debian
- Tiene código complejo para detección de distribuciones y mapeo de nombres de paquetes

## Problema Actual

### Fragmentación de Gestión de Paquetes
El sistema actual instala paquetes desde ~7 fuentes diferentes:
- **Repositorios del sistema**: apt (Ubuntu) / pacman (Arch)
- **AUR**: Solo Arch Linux
- **Chaotic-AUR**: Solo Arch Linux  
- **cargo**: Herramientas de Rust
- **npm**: Paquetes globales de Node.js
- **pipx**: Aplicaciones Python
- **gem**: Gemas de Ruby
- **GitHub releases**: Instalaciones manuales

### Problemas Específicos
1. **Nombres de paquetes inconsistentes**: `ninja` (Arch) vs `ninja-build` (Ubuntu)
2. **Paquetes no disponibles**: Muchos paquetes fallan en Ubuntu porque solo existen en AUR
3. **Complejidad del código**: Cientos de líneas para detectar distribución y mapear paquetes
4. **Mantenimiento**: Cada nueva distro/paquete requiere actualizar múltiples archivos
5. **No reproducible**: Misma configuración da diferentes resultados en diferentes distros
6. **Dependencias**: Requiere instalar múltiples gestores de paquetes (cargo, npm, pipx, etc.)

### Ejemplo Real de Fallo (líneas 71-102 del log)
```
E: Unable to locate package vte3
E: Unable to locate package zed  
E: Unable to locate package pyright
E: Unable to locate package rust-analyzer
E: Unable to locate package vulkan-intel

Paquetes que no se pudieron instalar: 
mise clang ninja starship vte3 zed pyright rust-analyzer vulkan-intel
```

## Solución Propuesta: NIX + dotbare

### Arquitectura Nueva

**Separación Clara de Responsabilidades:**

```
NIX (gestión de paquetes)
├── Instala TODOS los paquetes
├── Multiplataforma (Arch, Ubuntu, Debian, Fedora, macOS)
├── 65,000+ paquetes disponibles
├── Reproducible y declarativo
└── Rollback nativo

dotbare (gestión de dotfiles)
├── Git bare repository (workflow nativo de Git)
├── HOME como working tree
├── Push/pull entre máquinas
├── Historial completo, branches, etc.
└── Ya implementado y funcionando bien
```

### Por Qué Esta Arquitectura

1. **Unix Philosophy**: Cada herramienta hace una cosa bien
   - NIX → Gestiona paquetes
   - dotbare → Gestiona archivos de configuración

2. **Multiplataforma Real**: Un `packages.nix` funciona en TODAS las distros

3. **Simplificación Masiva**: Elimina ~70% del código actual
   - No más detección de distros
   - No más mapeo de nombres de paquetes
   - No más instaladores múltiples

4. **Reproducibilidad**: Mismo resultado en cualquier máquina

5. **Menor Acoplamiento**: dotbare usa Git estándar (no depende de Nix ecosystem)

6. **Mantener lo que funciona**: dotbare ya gestiona dotfiles perfectamente

## Qué se Mantiene

✅ **dotbare para dotfiles**: Sistema actual funciona excelente  
✅ **Scripts de dotbare**: `fdotbare` y funcionalidad relacionada  
✅ **Configuración de Git**: Setup de GPG, SSH, credenciales  
✅ **Estructura de dotfiles**: El usuario sigue usando su repo actual  
✅ **Filosofía del proyecto**: Configuración profesional de desarrollo  

## Qué se Cambia

🔄 **Gestión de paquetes**: De múltiples fuentes → NIX exclusivamente  
🔄 **Archivo de configuración**: `setup.conf` → `packages.nix`  
🔄 **Scripts de instalación**: Nuevos scripts para NIX  
🔄 **Documentación**: Enfoque en NIX + dotbare  

## Qué se Elimina

❌ Scripts específicos de distro: `fdeps`, `fchaotic`, `fchaotic-deps`, `faur`  
❌ Código de detección de distros en `helper/package_manager.sh`  
❌ Instaladores específicos: cargo, npm, pipx, gem helpers  
❌ Mapeo de nombres de paquetes entre distros  
❌ `setup.conf` con arrays separados por distro  

## Estructura Propuesta del Proyecto

```
dotmarchy/
├── README.md                          # Documentación principal actualizada
├── install.sh                         # Nuevo: Setup inicial (Nix + dotbare)
├── packages.nix                       # Nuevo: Definición de paquetes Nix
├── shell.nix                          # Nuevo: Para nix-shell
│
├── scripts/
│   ├── bootstrap-nix.sh              # Nuevo: Instalar Nix
│   ├── sync-packages.sh              # Nuevo: Aplicar packages.nix
│   ├── core/
│   │   ├── fdotbare                  # Mantener: Configurar dotbare
│   │   └── fgit                      # Mantener: Configurar Git
│   └── legacy/                       # Mover scripts viejos aquí
│       ├── fdeps
│       ├── fchaotic
│       └── ...
│
├── helper/
│   ├── colors.sh                     # Mantener
│   ├── logger.sh                     # Mantener
│   ├── prompts.sh                    # Mantener
│   └── nix-helpers.sh                # Nuevo: Funciones para Nix
│
├── config/
│   └── defaults.sh                   # Simplificar: Solo vars de dotbare/git
│
└── docs/
    ├── NIX_SETUP.md                  # Nuevo: Guía de Nix
    ├── MIGRATION.md                  # Nuevo: Migración desde versión anterior
    └── ARCHITECTURE.md               # Nuevo: Explicar arquitectura
```

## Ejemplo de `packages.nix`

```nix
# ~/.config/dotmarchy/packages.nix
{ pkgs ? import <nixpkgs> {} }:

with pkgs; [
  # Shells & Terminal
  zsh starship zoxide fzf
  
  # Editors & IDE
  neovim tmux geany
  
  # Git ecosystem
  git gh lazygit git-delta diff-so-fancy
  
  # CLI utilities (nombres consistentes en todas las distros)
  ripgrep fd bat eza tree htop
  
  # Dev tools & version managers
  mise nodejs python3 rustup
  
  # Language servers (todos disponibles en Nix)
  rust-analyzer pyright 
  nodePackages.typescript-language-server
  nodePackages.yaml-language-server
  nodePackages.bash-language-server
  
  # Build tools (nombres consistentes)
  cmake meson ninja pkg-config clang
  
  # Multiplayer code editor
  zed-editor
]
```

## Workflow del Usuario

### Setup Inicial (Nueva Máquina)
```bash
# 1. Instalar Nix (funciona en cualquier distro)
curl -L https://nixos.org/nix/install | sh -s -- --daemon

# 2. Clonar y ejecutar dotmarchy
git clone https://github.com/25ASAB015/dotmarchy.git
cd dotmarchy
./install.sh

# Interactivo pregunta:
# - URL de tu repo de dotfiles
# - Configuración de Git (nombre, email, GPG)
# - Paquetes a instalar (usa packages.nix por defecto o permite personalizar)
```

### Uso Diario

**Gestionar paquetes (Nix):**
```bash
# Editar lista de paquetes
nvim ~/.config/dotmarchy/packages.nix

# Aplicar cambios
nix-env -iA nixpkgs.myPackages -f ~/.config/dotmarchy/packages.nix

# Versionar cambios de paquetes
dotbare add .config/dotmarchy/packages.nix
dotbare commit -m "add ripgrep and fd"
dotbare push
```

**Gestionar configuraciones (dotbare):**
```bash
# Workflow Git normal
dotbare status
dotbare add .zshrc .config/nvim/init.lua
dotbare commit -m "update zsh and nvim config"
dotbare push origin main

# En otra máquina
dotbare pull
```

### Sincronizar con Nueva Máquina
```bash
# 1. Instalar Nix
curl -L https://nixos.org/nix/install | sh

# 2. Clonar dotfiles con dotbare
dotbare finit -u git@github.com:tuuser/dotfiles.git

# 3. Aplicar paquetes (packages.nix está en el repo de dotbare)
nix-env -iA nixpkgs.myPackages -f ~/.config/dotmarchy/packages.nix
```

## Plan de Implementación

### Fase 1: Fundación NIX (Semana 1)
**Objetivo**: Soporte básico de Nix sin romper funcionalidad existente

- [ ] Crear `packages.nix` con equivalentes de paquetes actuales
- [ ] Crear `shell.nix` para nix-shell
- [ ] Script `bootstrap-nix.sh` para instalar Nix
- [ ] Script `sync-packages.sh` para aplicar packages.nix
- [ ] Agregar flag `--nix` a dotbuntu para usar nuevo método
- [ ] Documentación básica en `docs/NIX_SETUP.md`
- [ ] Probar en Ubuntu y Arch

**Criterios de Éxito**:
- ✅ `./dotbuntu --nix` instala todos los paquetes vía Nix en Ubuntu
- ✅ `./dotbuntu --nix` instala todos los paquetes vía Nix en Arch
- ✅ dotbare sigue funcionando sin cambios
- ✅ Método antiguo sigue funcionando (flag por defecto)

### Fase 2: Integración dotbare (Semana 2)
**Objetivo**: Integración seamless entre Nix y dotbare

- [ ] `packages.nix` versionado en dotbare repo por defecto
- [ ] `install.sh` unificado que configura Nix + dotbare
- [ ] Script interactivo para primera configuración
- [ ] Sincronización automática de paquetes al hacer pull
- [ ] Documentación completa de workflow
- [ ] Guía de migración para usuarios existentes

**Criterios de Éxito**:
- ✅ Setup de máquina nueva en 3 comandos
- ✅ Cambios de paquetes versionados en Git
- ✅ Push/pull sincroniza paquetes y configs
- ✅ Documentación clara para usuarios nuevos

### Fase 3: Limpieza y Deprecación (Semana 3)
**Objetivo**: Limpiar código antiguo y hacer Nix el método principal

- [ ] Mover scripts viejos a `scripts/legacy/`
- [ ] Marcar método antiguo como deprecated
- [ ] Simplificar `config/defaults.sh`
- [ ] Remover código de detección de distros
- [ ] Actualizar README con enfoque Nix
- [ ] Crear `docs/ARCHITECTURE.md`
- [ ] Agregar tests básicos

**Criterios de Éxito**:
- ✅ Código base reducido en ~60-70%
- ✅ NIX es el método recomendado en docs
- ✅ Warning al usar método antiguo
- ✅ Todo funciona en Arch, Ubuntu, Debian

### Fase 4: Pulido y Release (Semana 4)
**Objetivo**: Release v2.0.0 con arquitectura nueva

- [ ] Testing exhaustivo en múltiples distros
- [ ] Video demo / GIF animado
- [ ] Actualizar todas las docs
- [ ] Crear release notes completas
- [ ] Merge a master
- [ ] Tag v2.0.0
- [ ] Anuncio en GitHub

## Objetivos del Proyecto

### Objetivos Técnicos
1. ✅ **Multiplataforma Real**: Un comando, funciona en Arch, Ubuntu, Debian, Fedora, macOS
2. ✅ **Reproducible**: Mismo `packages.nix` = mismos paquetes en cualquier máquina
3. ✅ **Simplificación**: Reducir código base en 60-70%
4. ✅ **Mantenibilidad**: Un solo método de instalación de paquetes
5. ✅ **Rollback**: Soporte nativo de rollback (Nix y Git)

### Objetivos de Usuario
1. ✅ **Setup rápido**: Nueva máquina lista en minutos
2. ✅ **Workflow Git**: Gestión de configs como cualquier repo
3. ✅ **Sincronización fácil**: Push/pull entre máquinas
4. ✅ **Extensible**: Fácil agregar nuevos paquetes
5. ✅ **Sin surpresas**: Mismo resultado en todas las distros

### No-Objetivos
❌ Soportar Windows (Nix en Windows es experimental)  
❌ Gestión de paquetes del sistema (Nix no reemplaza apt/pacman)  
❌ Home Manager (optamos por dotbare + Nix simple)  
❌ NixOS (proyecto sigue siendo dotfiles, no distro completa)  

## Beneficios Esperados

### Para Usuarios
- ⏱️ **Setup 10x más rápido**: 3 comandos vs ~20 minutos de scripts
- 🔄 **Sincronización perfecta**: Paquetes + configs versionados juntos
- 🎯 **Sin frustración**: No más "paquete no encontrado"
- 📦 **Más paquetes**: Acceso a 65,000+ paquetes de nixpkgs
- 🔙 **Rollback fácil**: `nix-env --rollback` + `git revert`

### Para Mantenedores
- 🧹 **Código más limpio**: -70% de líneas de código
- 🐛 **Menos bugs**: Un método de instalación vs 7
- 📝 **Documentación simple**: Una forma de hacer las cosas
- 🚀 **Más features**: Tiempo para features reales vs mantenimiento
- 🌍 **Más distros**: Cualquier distro con Nix automáticamente soportada

## Riesgos y Mitigaciones

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|--------------|---------|------------|
| Usuarios no conocen Nix | Alta | Medio | Docs excelentes, install.sh automatizado |
| Nix no instalado por defecto | Alta | Bajo | Script de bootstrap automatizado |
| Espacio en disco (Nix store) | Media | Bajo | Documentar, permitir cleanup fácil |
| Resistencia al cambio | Media | Medio | Mantener método viejo temporalmente, guía de migración |
| Bugs en fase de transición | Media | Alto | Testing exhaustivo, rollback plan |

## Métricas de Éxito

1. **Reducción de código**: Eliminar mínimo 60% de LOC en scripts de instalación
2. **Cobertura de distros**: Funcionar en mínimo 3 distros (Arch, Ubuntu, Debian)
3. **Tiempo de setup**: Reducir de ~20min a <5min en máquina nueva
4. **Tasa de error**: 0 errores de "paquete no encontrado" entre distros
5. **Adopción**: 100% de usuarios del proyecto migrados en 3 meses

## Preguntas para la Propuesta

1. ¿Cómo manejamos la transición de usuarios existentes?
2. ¿Cuánto tiempo mantenemos soporte del método antiguo?
3. ¿Necesitamos CI/CD para testear en múltiples distros?
4. ¿Documentamos en inglés, español, o ambos?
5. ¿Creamos packages.nix mínimo y otro completo como ejemplos?

## Referencias

- [Nix Package Manager](https://nixos.org/manual/nix/stable/)
- [nixpkgs Search](https://search.nixos.org/packages)
- [dotbare GitHub](https://github.com/kazhala/dotbare)
- [Git Bare Repository Workflow](https://www.atlassian.com/git/tutorials/dotfiles)

---

**Nota**: Este prompt está diseñado para ser usado con `openspec-proposal` para generar una propuesta formal estructurada según el proceso de OpenSpec del proyecto.

