# Change: Migrate from Multi-Source Package Management to NIX

## Why

The current multi-source package management system (apt/pacman, AUR, Chaotic-AUR, cargo, npm, pipx, gem, GitHub releases) causes:
- Package name inconsistencies between distributions (`ninja` vs `ninja-build`)
- Frequent installation failures in Ubuntu for Arch-only packages
- Complex codebase with ~7 different package installation methods
- Non-reproducible configurations across different Linux distributions

This migration replaces all package management with NIX while keeping dotbare for dotfiles management, achieving true multi-platform reproducibility.

## What Changes

**Added:**
- NIX package manager as sole package installation method
- `packages.nix` declarative configuration file
- `bootstrap-nix.sh` script with multiple installation options (Determinate Systems, official, distro packages)
- `sync-packages.sh` script to apply `packages.nix`
- New helper module `nix-helpers.sh`
- Documentation: `NIX_SETUP.md`, `MIGRATION.md`, `ARCHITECTURE.md`

**Modified:**
- `install.sh` to orchestrate NIX + dotbare setup
- `config/defaults.sh` simplified to only dotbare/git variables
- Main entry point to support `--nix` flag (transitional phase)
- User workflow to version `packages.nix` in dotbare repository

**Removed (moved to legacy/):**
- `scripts/core/fdeps` - System package installer (apt/pacman)
- `scripts/core/fchaotic` - Chaotic-AUR setup
- `scripts/core/fchaotic-deps` - Chaotic-AUR package installer  
- `scripts/core/faur` - AUR package installer
- `helper/package_manager.sh` - Distribution detection logic
- Language-specific installers for cargo, npm, pipx, gem
- `setup.conf` arrays (replaced by `packages.nix`)

**Kept:**
- `scripts/core/fdotbare` - dotbare configuration (unchanged)
- `scripts/core/fgit` - Git/GPG/SSH setup (unchanged)
- All helper modules (colors, logger, prompts, utils, checks)
- Philosophy: Professional development environment configuration

## Impact

**BREAKING CHANGES:**
- **Installation method**: Users must install NIX before running dotmarchy
- **Configuration format**: `setup.conf` replaced by `packages.nix`
- **Command compatibility**: Package management flags may change
- **Platform support**: Requires NIX-compatible systems (Linux, macOS)

**Affected capabilities:**
- `package-management` (NEW) - NIX-based package installation
- `dotfile-management` (NEW) - dotbare workflow (preserved)
- `nix-installation` (NEW) - NIX bootstrapping with multiple methods

**Affected code:**
- All `scripts/core/f*` package installers (~1000 LOC removed)
- `helper/package_manager.sh` (~357 lines removed)
- `config/defaults.sh` and `helper/set_variable.sh` (simplified)
- Main `dotbuntu` entry point (add --nix flag)
- Documentation (complete rewrite)

**Migration path:**
- Phase 1: Add NIX support with `--nix` flag (no breaking changes)
- Phase 2: Make NIX default, mark old method as deprecated
- Phase 3: Remove old package management code after 3-month transition

**Benefits:**
- **65,000+ packages** available cross-platform
- **Zero "package not found" errors** between distros
- **~70% code reduction** in package management
- **Reproducible builds** - same packages.nix = same environment
- **Rollback capability** - `nix-env --rollback` + Git for configs

**Risks:**
- Learning curve for users unfamiliar with NIX
- Disk space requirements for NIX store
- Initial resistance to architectural change

**Mitigation:**
- Excellent documentation with examples
- Automated `bootstrap-nix.sh` script
- Gradual migration with transition period
- Support for multiple NIX installation methods (Determinate Systems recommended)

