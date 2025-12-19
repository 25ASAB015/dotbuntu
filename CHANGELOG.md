# Changelog

All notable changes to dotbuntu will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-12-19

### 🎉 Major Release: NIX Package Management

**Breaking Changes:**
- NIX is now the default package manager (use `--legacy` flag for old behavior)
- `setup.conf` replaced by `packages.nix` (use `convert-setup-conf.sh` to migrate)
- Legacy package installers moved to `scripts/legacy/` (deprecated, removed 2026-03-01)

### Added

#### NIX Package Management (Phase 1)
- `packages.nix` — Declarative NIX package configuration template
- `scripts/bootstrap-nix.sh` — Automated NIX installer with 3 methods:
  - Determinate Systems (recommended, easy uninstall)
  - Official NIX installer
  - Distribution packages (Arch pacman)
- `scripts/sync-packages.sh` — Idempotent package synchronization from packages.nix
- `helper/nix-helpers.sh` — NIX utility functions (is_installed, get_version, cleanup, etc.)
- `docs/NIX_SETUP.md` — Comprehensive NIX setup and usage guide

#### Dotbare Integration (Phase 2)
- `install.sh` — Unified installer orchestrating NIX + dotbare setup
  - Interactive prompts for each component
  - Progress indicators (Step 1/3, 2/3, 3/3)
  - Error recovery and completion summary
- Modified `scripts/core/fdotbare` — Suggests tracking packages.nix in dotbare
- `docs/MIGRATION.md` — Complete v1.x → v2.0 migration guide with 3 paths:
  - Fresh install
  - In-place migration
  - Keep old method (--legacy)
- `scripts/convert-setup-conf.sh` — Converts old setup.conf to packages.nix format

#### NIX as Default (Phase 3)
- `--legacy` flag — Use old package managers (deprecated, removed 2026-03-01)
- Deprecation warnings when using `--legacy` flag
- `scripts/legacy/` directory — Moved fdeps, faur, fchaotic, fchaotic-deps
- `docs/ARCHITECTURE.md` — System architecture documentation:
  - NIX + dotbare separation of concerns
  - Data flow diagrams (ASCII art)
  - Configuration file locations
  - Design decisions and trade-offs
- Simplified `config/defaults.sh` — Removed package arrays, added PACKAGES_NIX_PATH

#### Documentation
- Completely rewritten `README.md` — NIX-first approach with:
  - "Why NIX?" section
  - Quick start with install.sh
  - Package management examples
  - dotbare workflow examples
- All docs link to each other (NIX_SETUP.md ↔ MIGRATION.md ↔ ARCHITECTURE.md)

### Changed

- **Default behavior**: NIX is now default package manager (was apt/pacman/AUR)
- `dotbuntu` help text updated to promote NIX method
- `--nix` flag removed (now default behavior)
- `packages.nix` versioned in dotbare repository for cross-machine sync
- Error messages improved with helpful suggestions
- Version updated to 2.0.0 across all files

### Deprecated

**Legacy package management** (removed 2026-03-01):
- `scripts/legacy/fdeps` (apt/pacman installer)
- `scripts/legacy/faur` (AUR installer)  
- `scripts/legacy/fchaotic*` (Chaotic-AUR)
- Language-specific installers (npm, cargo, pipx, gem, etc.)
- `setup.conf` configuration format
- Multi-source package approach

Use `--legacy` flag to access deprecated functionality until v3.0.0.

### Migration Path

**From v1.x:**
```bash
# Option 1: Fresh install (recommended)
./install.sh

# Option 2: Convert configuration
./scripts/convert-setup-conf.sh
./dotbuntu  # Now uses NIX

# Option 3: Keep old method temporarily
./dotbuntu --legacy  # Available until 2026-03-01
```

See [docs/MIGRATION.md](docs/MIGRATION.md) for complete guide.

### Technical Details

**New files** (14):
- `packages.nix` (3.4KB)
- `scripts/bootstrap-nix.sh` (7.6KB)
- `scripts/sync-packages.sh` (3.6KB)  
- `helper/nix-helpers.sh` (3.9KB)
- `docs/NIX_SETUP.md` (5.9KB)
- `install.sh` (9.2KB)
- `docs/MIGRATION.md` (10.4KB)
- `scripts/convert-setup-conf.sh` (5.3KB)
- `docs/ARCHITECTURE.md` (16KB)
- `scripts/legacy/*` (4 files moved)

**Modified files** (3):
- `dotbuntu` (+85 lines)
- `scripts/core/fdotbare` (+37 lines)
- `config/defaults.sh` (simplified, +NIX vars)
- `README.md` (rewritten)

**Total**: ~49KB new code + comprehensive documentation

### Benefits

✅ **Reproducibility** — Same packages.nix works on Arch, Ubuntu, Debian, macOS  
✅ **Simplicity** — One package source instead of 7+  
✅ **Version control** — packages.nix versioned with dotfiles  
✅ **Atomic rollback** — `nix-env --rollback` reverts changes  
✅ **Binary cache** — Fast installs (cache.nixos.org)  
✅ **No conflicts** — Isolated packages in /nix/store

### Known Limitations

- Manual testing required (no automated test suite)
- `dotbare` itself not in nixpkgs (manual install from GitHub)
- NIX store disk usage (~5-10GB typical)
- Learning curve for NIX expression language

### Upgrade Notes

**Non-breaking for existing users:**
- Default behavior now uses NIX (prompts on first run)
- Use `--legacy` flag to keep old package managers
- 3-month transition period (until 2026-03-01)

**Recommended actions:**
1. Review [docs/MIGRATION.md](docs/MIGRATION.md)
2. Test NIX on a VM or secondary machine first
3. Convert setup.conf: `./scripts/convert-setup-conf.sh`
4. Track packages.nix in dotbare: `dotbare add ~/.config/dotmarchy/packages.nix`

## [1.9.0] - 2024-12 (Last v1.x release)

Final release before NIX migration. Includes distribution-agnostic improvements.

### Added
- Distribution-agnostic dotbar e and environment setup
- Clear warnings when package installation unavailable
- Welcome screen streamlined

### Changed
- Arch Linux check made conditional
- dotbare works on non-Arch systems
- Error messages improved

## [1.0.0] - 2024-11

Initial stable release.

### Added
- Git configuration automation
- GPG and SSH key management
- dotbare integration for dotfiles
- Multi-source package installation (apt, pacman, AUR, cargo, npm, pipx, gem)
- Interactive and non-interactive modes

---

## Timeline & Roadmap

- **Now** — v2.0.0 released (NIX default, --legacy available)
- **Month 1-3** — Transition period, both methods supported
- **2026-03-01** — v3.0.0 released (legacy code removed, NIX required)

## Support

- **Documentation**: [docs/NIX_SETUP.md](docs/NIX_SETUP.md), [docs/MIGRATION.md](docs/MIGRATION.md)
- **Issues**: https://github.com/25ASAB015/dotbuntu/issues
- **Questions**: Open a GitHub Discussion
