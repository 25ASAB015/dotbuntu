# Project Context

## Purpose

**dotbuntu** is a unified system configuration and dotfiles management tool for Arch Linux and Ubuntu-based systems. It consolidates two previously separate tools:

1. **gitconfig** (Crixus) - Professional Git & GitHub configuration tool
2. **dotmarchy** - Modular dotfiles installation and system setup tool

The goal is to create a single, comprehensive tool that handles:
- Complete Git/GitHub professional setup (SSH keys, GPG keys, Git configuration)
- Automated dotfiles installation and management via dotbare
- Multi-source package installation (pacman, AUR, Chaotic-AUR, npm, cargo, pip, ruby, GitHub releases)
- Environment setup and shell configuration
- System-wide developer onboarding automation

## Tech Stack

### Core Technologies
- **Bash 4.0+** - Primary scripting language with strict mode (`set -Eeuo pipefail`)
- **Git** - Version control and dotfiles management
- **dotbare** - Git bare repository manager for dotfiles

### Package Managers & Sources
- **pacman** - Arch Linux official package manager
- **paru** - AUR helper (installed from Chaotic-AUR)
- **Chaotic-AUR** - Pre-compiled AUR packages repository
- **npm** - Node.js package manager (global packages)
- **cargo** - Rust package manager (crates.io)
- **pip/pipx** - Python package manager (isolated environments)
- **gem** - Ruby package manager (RubyGems)
- **curl** - Direct binary downloads from GitHub Releases

### Development Tools
- **shellcheck** - Static analysis for Bash scripts
- **shfmt** - Shell script formatter
- **GitHub CLI (gh)** - GitHub integration for key uploads
- **OpenSpec** - Spec-driven development framework

## Project Conventions

### Code Style

- **Language**: Bash scripts with Spanish comments for clarity
- **Strict Mode**: All scripts use `set -Eeuo pipefail` for robust error handling
- **Formatting**: Code formatted with `shfmt -ln=bash`
- **Linting**: All scripts pass `shellcheck` validation
- **Naming Conventions**:
  - Executable scripts: Prefix with `f` (e.g., `fdeps`, `faur`, `fupdate`)
  - Helper modules: Suffix with `.sh` (e.g., `colors.sh`, `logger.sh`)
  - Constants: `UPPER_SNAKE_CASE` with `readonly` declaration
  - Functions: `snake_case` with descriptive names
  - Local variables: `snake_case` with `local` declaration

### Architecture Patterns

**Modular Architecture** (inspired by [dotbare](https://github.com/kazhala/dotbare)):

```
dotbuntu/
├── gitconfig.sh              # Main entry point (orchestrator)
├── config/
│   ├── defaults.sh           # Global variables and configuration
│   └── templates/            # Configuration templates
├── helper/                   # Shared utility libraries
│   ├── colors.sh            # Color definitions and helpers
│   ├── logger.sh            # Logging system
│   ├── utils.sh             # Common utilities
│   ├── checks.sh            # System validations
│   └── prompts.sh           # User interaction
└── scripts/
    ├── core/                # Always executed (Git, SSH, GPG, dotfiles)
    ├── extras/              # Optional packages (--extras flag)
    └── setup/               # Environment setup (--setup-env flag)
```

**Design Principles**:
1. **Single Responsibility**: Each module has one clear purpose
2. **Separation of Concerns**: Helpers, core, extras, setup are distinct
3. **Idempotency**: Safe to run multiple times without side effects
4. **Fail-Fast**: Errors halt execution immediately with clear messages
5. **Dependency Order**: Modules loaded in correct dependency sequence

### Testing Strategy

- **Static Analysis**: All scripts validated with `shellcheck`
- **Manual Testing**: Each module executable independently for testing
- **Verification Mode**: `--verify` flag runs post-installation checks
- **Logging**: All errors logged to `~/.local/share/dotbuntu/install_errors.log`
- **Dry-Run Mode**: `DRY_RUN=1` environment variable for testing without changes

### Git Workflow

- **Branch Strategy**: `master` branch for stable releases
- **Commit Conventions**: Conventional commits format
- **Documentation**: README.md updated with all changes
- **OpenSpec Integration**: All major changes tracked via OpenSpec proposals

## Domain Context

### Dotfiles Management
- Uses **dotbare** pattern: Git bare repository with separate working tree
- Default locations: `~/.cfg` (bare repo), `~` (working tree)
- Supports custom repository URLs via `--repo` flag

### Package Installation Strategy
1. **Official repos first** (fastest, most stable)
2. **Chaotic-AUR** for pre-compiled AUR packages (faster than building)
3. **AUR via paru** for packages requiring compilation
4. **Language-specific managers** (npm, cargo, pip, gem) for dev tools
5. **GitHub Releases** for binaries without package manager support

### System Requirements
- **OS**: Arch Linux, Omarchy Linux, or Ubuntu-based distributions
- **Permissions**: Must NOT run as root (safety check enforced)
- **Network**: Active internet connection required
- **Shell**: Bash 4.0+ with standard utilities

## Important Constraints

### Technical Constraints
- **No root execution**: Script refuses to run as root for safety
- **Bash only**: No dependencies on other shells (zsh, fish)
- **Linux only**: Not compatible with macOS or Windows
- **Internet required**: Cannot work offline (downloads packages)

### Compatibility Constraints
- **Arch-based systems**: Primary target (pacman required)
- **Ubuntu support**: Secondary target (apt-based systems)
- **No Artix support**: Requires systemd (not compatible with Artix Linux)

### Safety Constraints
- **Backup before overwrite**: Existing configurations backed up automatically
- **Verification checks**: Pre-flight checks before any system modifications
- **Error logging**: All failures recorded for debugging
- **Rollback capability**: Backups allow manual restoration

## External Dependencies

### Required System Commands
- `git` - Version control
- `curl` - Downloads and API calls
- `ssh-keygen` - SSH key generation
- `gpg` - GPG key generation for commit signing
- `pacman` - Package manager (Arch-based systems)

### Optional Dependencies
- `gh` (GitHub CLI) - Automatic key upload to GitHub
- `paru` - AUR helper (auto-installed from Chaotic-AUR)
- `dotbare` - Dotfiles manager (auto-installed from AUR)

### External Services
- **GitHub** - Repository hosting and key management
- **Chaotic-AUR** - Pre-compiled AUR packages repository
- **AUR** - Arch User Repository for community packages
- **npm Registry** - Node.js packages
- **crates.io** - Rust packages
- **PyPI** - Python packages
- **RubyGems** - Ruby packages
