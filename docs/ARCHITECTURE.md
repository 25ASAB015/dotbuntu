# Architecture Documentation

## System Overview

```
┌──────────────────────────────────────────────────────────────┐
│                      Dotbuntu v2.0.0                          │
│         Reproducible Development Environment Setup            │
└──────────────────────────────────────────────────────────────┘
                              │
                              ▼
          ┌───────────────────────────────────┐
          │       Entry Points                │
          ├───────────────────────────────────┤
          │  • ./install.sh (recommended)     │
          │  • ./dotbuntu (advanced)          │
          └───────────────────────────────────┘
                              │
                              ▼
             ┌────────────────┴────────────────┐
             │                                  │
             ▼                                  ▼
    ┌──────────────────┐            ┌──────────────────┐
    │   NIX Packages   │            │     Dotfiles     │
    │   (packages.nix) │            │    (dotbare)     │
    └──────────────────┘            └──────────────────┘
```

## Core Components

### 1. Package Management (NIX)

**Purpose**: Install and manage all software packages

**Key Files**:
- `packages.nix` - Declarative package configuration
- `scripts/bootstrap-nix.sh` - NIX installer
- `scripts/sync-packages.sh` - Package synchronization
- `helper/nix-helpers.sh` - NIX utility functions

**Flow**:
```
1. Check if NIX installed
2. If not → run bootstrap-nix.sh
3. Locate packages.nix
4. Apply via: nix-env -iA myPackages -f packages.nix
5. Log results
```

**Package Configuration Location**:
```
~/.config/dotmarchy/packages.nix  (primary)
    OR
~/dotbuntu/packages.nix  (template)
```

### 2. Dotfiles Management (dotbare)

**Purpose**: Version control configuration files across machines

**Key Files**:
- `scripts/core/fdotbare` - Dotbare configuration script
- `~/.cfg/` - Bare git repository
- `$HOME` - Working tree

**Flow**:
```
1. Install dotbare (via NIX or manual)
2. Clone dotfiles repository to ~/.cfg
3. Checkout files to $HOME
4. Track changes: dotbare add/commit/push
```

**Integration with NIX**:
- `packages.nix` is versioned in dotbare repository
- Pulling dotfiles automatically syncs package list
- Cross-machine package reproducibility

### 3. Orchestration (install.sh)

**Purpose**: Coordinate NIX + dotbare setup

**Interactive Flow**:
```
┌─────────────────────────────────────┐
│  Welcome Screen                     │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  Install NIX? (Y/n)                 │
├─────────────────────────────────────┤
│  [Yes] → bootstrap-nix.sh           │
│  [No]  → Skip to dotbare            │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  Configure dotbare? (Y/n)           │
├─────────────────────────────────────┤
│  [Yes] → fdotbare                   │
│  [No]  → Skip to packages           │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  Sync packages? (Y/n)               │
├─────────────────────────────────────┤
│  [Yes] → sync-packages.sh           │
│  [No]  → Complete                   │
└─────────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│  Success Summary                    │
│  • Show installed components        │
│  • Display next steps               │
└─────────────────────────────────────┘
```

## Configuration Files

### Runtime Configuration

```
config/
├── defaults.sh          # Global variables (DOTBARE_*, REPO_URL)
└── ...

helper/
├── set_variable.sh      # Environment setup
├── nix-helpers.sh       # NIX utilities (new)
└── ...
```

**Environment Variables**:
```bash
# Dotbare
DOTBARE_DIR="$HOME/.cfg"
DOTBARE_TREE="$HOME"
DOTBARE_BACKUP="$HOME/.local/share/dotbare"

# Repository
REPO_URL="git@github.com:user/dotfiles.git"

# NIX
PACKAGES_NIX_PATH="$HOME/.config/dotmarchy/packages.nix"

# Logging
ERROR_LOG="$HOME/.local/share/dotmarchy/install_errors.log"
```

### User Configuration

```
~/.config/dotmarchy/
├── packages.nix         # NIX packages (versioned in dotbare)
└── setup.conf           # (DEPRECATED, use packages.nix)

~/.cfg/                  # Dotbare bare repository
└── ...

~/.local/share/dotmarchy/
└── install_errors.log   # Error logs
```

## Data Flow

### First-Time Setup

```
./install.sh
    │
    ├─→ bootstrap-nix.sh
    │       │
    │       ├─→ Detect existing NIX
    │       ├─→ Offer installation methods
    │       ├─→ Install NIX (Determinate Systems default)
    │       └─→ Enable flakes
    │
    ├─→ fdotbare
    │       │
    │       ├─→ Install dotbare (from NIX)
    │       ├─→ Clone dotfiles → ~/.cfg
    │       ├─→ Checkout files → $HOME
    │       └─→ Suggest tracking packages.nix
    │
    └─→ sync-packages.sh
            │
            ├─→ Find packages.nix
            ├─→ Apply with nix-env
            └─→ Report results
```

### Daily Workflow

```
# Update packages
vim ~/.config/dotmarchy/packages.nix
dotbare add ~/.config/dotmarchy/packages.nix
dotbare commit -m "Add neovim"
dotbare push

# On another machine
dotbare pull
./scripts/sync-packages.sh  # Install new packages

# Rollback if needed
nix-env --rollback
```

## Directory Structure

```
dotbuntu/
├── dotbuntu                 # Main CLI entry point
├── install.sh               # Unified installer (new)
│
├── config/
│   └── defaults.sh          # Simplified config
│
├── helper/
│   ├── nix-helpers.sh       # NIX utilities (new)
│   └── ...
│
├── scripts/
│   ├── bootstrap-nix.sh     # NIX installer (new)
│   ├── sync-packages.sh     # Package sync (new)
│   ├── convert-setup-conf.sh # Migration tool (new)
│   │
│   ├── core/
│   │   ├── fdotbare         # Dotbare setup
│   │   └── ...
│   │
│   └── legacy/              # Deprecated (new)
│       ├── fdeps            # apt/pacman installer
│       ├── faur             # AUR installer
│       └── fchaotic*        # Chaotic-AUR
│
├── docs/
│   ├── NIX_SETUP.md         # NIX user guide (new)
│   ├── MIGRATION.md         # v1 → v2 migration (new)
│   ├── ARCHITECTURE.md      # This file (new)
│   └── README.md            # Main documentation (updated)
│
└── packages.nix             # Package template (new)
```

## Design Decisions

### 1. NIX as Default (Phase 3)

**Why**: 
- Cross-platform reproducibility (Linux + macOS)
- 65,000+ packages (eliminates need for AUR, npm, cargo, pip, gem)
- Atomic upgrades/rollbacks
- No distribution-specific logic needed

**Trade-offs**:
- Learning curve for NIX expression language
- /nix/store disk usage (~5-10GB typical)
- Legacy method available via `--legacy` flag (deprecated 2026-03)

### 2. Dotbare for Dotfiles

**Why**:
- Git-based (familiar workflow)
- Bare repository model (HOME as working tree)
- No symlink complexity
- Easy to sync across machines

**Integration with NIX**:
- `packages.nix` versioned alongside dotfiles
- Pull dotfiles → pull new packages
- Single source of truth for environment

### 3. Separation of Concerns

**Packages (NIX)**:
- System software (neovim, tmux, fzf, etc.)
- Language runtimes (node, python, ruby)
- Development tools (git-delta, ripgrep, etc.)

**Dotfiles (dotbare)**:
- Configuration files (.zshrc, .vimrc, .gitconfig)
- Application settings
- Shell customizations

**Clear boundary**: NIX = software, dotbare = configuration

## Error Handling & Logging

All scripts log to: `$HOME/.local/share/dotmarchy/install_errors.log`

**Log Format**:
```
[TIMESTAMP] [LEVEL] [SCRIPT] Message
[2024-01-15 10:30:45] [ERROR] [bootstrap-nix.sh] Failed to download installer
```

**Recovery**:
- Non-fatal errors: warn + continue
- Fatal errors: log + exit with code 1
- User visibility: errors shown in terminal + saved to log

## Security Considerations

- SSH keys handled by Git/GPG configuration (separate concern)
- NIX installations verify signatures from cache.nixos.org
- Dotbare clones use SSH authentication (keys must exist)
- No sudo required for NIX user-level package management

## Performance

**First install**: ~10-20 minutes
- NIX installation: 2-5 min
- Dotbare clone: 1-2 min
- Package sync: 5-15 min (depends on cache)

**Subsequent sync**: ~1-5 minutes
- Most packages from binary cache
- Only build if not cached

## Testing

**Manual testing required** (no automated test infrastructure):
- Fresh Arch Linux install
- Fresh Ubuntu 22.04 install
- Existing NIX installation
- Migration from v1.x

## Future Enhancements

Planned for v2.1+:
- Auto-sync packages on `dotbare pull` (hook)
- NixOS configuration integration
- Home Manager support
- Flake-based package management
