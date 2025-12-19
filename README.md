# 🛠️ dotbuntu v2.0

[![License](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)
[![ShellCheck](https://github.com/25ASAB015/dotbuntu/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/25ASAB015/dotbuntu/actions/workflows/shellcheck.yml)
[![Version](https://img.shields.io/badge/version-2.0.0-success)](https://github.com/25ASAB015/dotbuntu/releases)

**Reproducible development environment setup with NIX package management and dotbare dotfiles.**

Cross-platform, declarative, and version-controlled — works identically on Arch, Ubuntu, Debian, and macOS.

## ✨ Why dotbuntu v2?

**Before (v1.x):**
- 7+ package sources (apt, pacman, AUR, cargo, npm, pipx, gem...)
- Distribution-specific scripts
- Fragile, non-reproducible across machines

**After (v2.0):**
- ✅ **NIX packages** — 65,000+ packages, same on all platforms
- ✅ **dotbare dotfiles** — Git-based config management
- ✅ **Reproducible** — Same `packages.nix` = same packages everywhere
- ✅ **Atomic rollback** — Broke something? `nix-env --rollback`

## 🚀 Quick Start

```bash
git clone https://github.com/25ASAB015/dotbuntu.git
cd dotbuntu
./install.sh
```

**Interactive prompts will guide you:**
1. Install NIX package manager? (recommended)
2. Clone your dotfiles via dotbare?
3. Sync packages from `packages.nix`?

Done! Your environment is ready.

## 📦 Package Management (NIX)

### Add Packages

Edit `~/.config/dotmarchy/packages.nix`:

```nix
{ pkgs ? import <nixpkgs> {} }:
{
  myPackages = pkgs.buildEnv {
    name = "my-packages";
    paths = with pkgs; [
      neovim
      tmux
      fzf
      ripgrep
      # Add more packages here
    ];
  };
}
```

### Sync Changes

```bash
./scripts/sync-packages.sh
```

### Version in Dotfiles

```bash
dotbare add ~/.config/dotmarchy/packages.nix
dotbare commit -m "Add neovim and tmux"
dotbare push
```

On another machine:
```bash
dotbare pull
./scripts/sync-packages.sh  # Packages auto-sync!
```

## 🗂️ Dotfiles Management (dotbare)

**dotbare** uses a bare Git repository with `$HOME` as working tree.

### Track a new file

```bash
dotbare add ~/.zshrc
dotbare commit -m "Add zsh configuration"
dotbare push
```

### Pull updates

```bash
dotbare pull
```

Dotfiles automatically checked out to `$HOME`. If `packages.nix` changed, run sync-packages.sh to install new packages.

## 📖 Advanced Usage

### Manual Commands

```bash
# CLI entry point (advanced users)
./dotbuntu [OPTIONS]

# Install NIX only
./install.sh --nix --no-dotbare

# Legacy mode (DEPRECATED, removed 2026-03)
./dotbuntu --legacy
```

### CLI Options

| Option | Description |
| :--- | :--- |
| `--legacy` | Use old package managers (DEPRECATED) |
| `--extras` | Install extra packages (legacy mode) |
| `--setup-env` | Setup environment directories/repos |
| `--verify` | Run system diagnostics |
| `--non-interactive` | Automated mode (no prompts) |
| `--repo URL` | Override dotfiles repository URL |

## 🏗️ How It Works

```
┌─────────────────────────────────────────┐
│         install.sh (recommended)         │
└─────────────────────────────────────────┘
                  │
         ┌────────┴────────┐
         │                  │
         ▼                  ▼
  ┌──────────┐      ┌──────────────┐
  │   NIX    │      │   dotbare    │
  │ packages │      │  (dotfiles)  │
  └──────────┘      └──────────────┘
       │                    │
       ▼                    ▼
  packages.nix      ~/.zshrc, .vimrc, etc.
  (versioned)       (versioned in Git)
```

**Separation of concerns:**
- **NIX** = Software packages (neovim, tmux, git, etc.)
- **dotbare** = Configuration files (.zshrc, .vimrc, etc.)

Both versioned in your dotfiles repository → full environment reproducibility.

## 📚 Documentation

- **[NIX Setup Guide](docs/NIX_SETUP.md)** — Install, configure, and use NIX
- **[Migration Guide](docs/MIGRATION.md)** — Migrating from v1.x
- **[Architecture](docs/ARCHITECTURE.md)** — How dotbuntu works internally

## 🛡️ Why NIX?

1. **Cross-platform** — Same packages on Linux and macOS
2. **Reproducible** — Exact package versions, every time
3. **No conflicts** — Packages isolated in `/nix/store`
4. **Atomic rollback** — Revert to any previous state
5. **65,000+ packages** — Eliminates need for AUR, cargo, npm, pip, etc.

Traditional package managers (apt, pacman) are distribution-locked. NIX works everywhere.

## 🔄 Migrating from v1.x

**Option 1: Fresh install (recommended)**
```bash
./install.sh  # Guided setup with NIX
```

**Option 2: In-place migration**
```bash
./scripts/convert-setup-conf.sh  # Convert old setup.conf
./dotbuntu  # Now uses NIX by default
```

**Rollback safety:** Use `--legacy` flag to keep old method (until 2026-03-01).

See [docs/MIGRATION.md](docs/MIGRATION.md) for full guide.

## 🗂️ Project Structure

```
dotbuntu/
├── install.sh                 # Unified installer (NEW)
├── dotbuntu                   # CLI entry point
├── packages.nix               # Package template (NEW)
│
├── scripts/
│   ├── bootstrap-nix.sh       # NIX installer (NEW)
│   ├── sync-packages.sh       # Package sync (NEW)
│   ├── convert-setup-conf.sh  # Migration tool (NEW)
│   ├── core/fdotbare          # Dotbare setup
│   └── legacy/                # Old package installers (DEPRECATED)
│
├── docs/
│   ├── NIX_SETUP.md           # NIX guide (NEW)
│   ├── MIGRATION.md           # v1→v2 migration (NEW)
│   └── ARCHITECTURE.md        # System design (NEW)
│
└── config/, helper/           # Utilities and config
```

## 🧪 Testing

Manual testing required (no automated tests yet):
- Fresh Arch Linux install
- Fresh Ubuntu 22.04 install
- Verify NIX → dotbare → packages flow

## 🤝 Contributing

Contributions welcome! Open an issue or PR.

**Development setup:**
```bash
git clone https://github.com/25ASAB015/dotbuntu.git
cd dotbuntu
./dotbuntu --verify  # Check dependencies
```

## 📋 Roadmap

- [x] **v2.0** — NIX package management (current)
- [ ] **v2.1** — Auto-sync packages on `dotbare pull`
- [ ] **v2.2** — Home Manager integration
- [ ] **v3.0** — Remove legacy code (2026-03-01)

## 📄 License

**GPL-3.0** — See [LICENSE](LICENSE) for details.

---

**Questions?** Check [docs/NIX_SETUP.md](docs/NIX_SETUP.md) or open an issue.
