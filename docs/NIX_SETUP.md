# NIX Setup Guide

This guide explains how to use NIX package manager with dotbuntu for reproducible, cross-platform package management.

## What is NIX?

NIX is a powerful package manager that works on Linux and macOS with:
- **65,000+ packages** available across all platforms
- **Reproducible environments** - same `packages.nix` = same setup everywhere
- **Atomic upgrades/rollbacks** - no broken states
- **No conflicts** - packages installed in isolation

## Why NIX for dotbuntu?

The traditional multi-source approach (apt/pacman + AUR + npm + cargo + pip) causes:
- Package name inconsistencies between distributions (`ninja` vs `ninja-build`)
- Frequent "package not found" errors on Ubuntu for Arch-only packages
- Complex maintenance with 7+ different installation methods

NIX solves all of this with a single, universal package source.

## Installation

### Option 1: Automatic Installation (Recommended)

Run dotbuntu with the `--nix` flag:

```bash
./dotbuntu --nix
```

This will:
1. Detect if NIX is already installed
2. If not, show an interactive menu to choose installation method
3. Install NIX using your selected method
4. Sync packages from `packages.nix`

### Option 2: Manual Installation

#### Determinate Systems Installer (Recommended)

Best for most users. Clean uninstallation and modern features.

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

**Uninstall**: `nix-installer uninstall`

#### Official NIX Installer

Standard installation method.

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

**Uninstall**: Follow [official guide](https://nixos.org/manual/nix/stable/installation/uninstall.html)

#### Arch Linux (pacman)

```bash
sudo pacman -S nix
sudo systemctl enable --now nix-daemon
sudo usermod -aG nix-users $USER
```

Log out and back in to apply group changes.

## Using packages.nix

### File Location

The `packages.nix` file defines your system packages. Place it in one of:
- `~/.config/dotmarchy/packages.nix` (recommended, versioned with dotfiles)
- Repository root: `~/dotfiles/packages.nix`

### Basic Format

```nix
{ pkgs ? import <nixpkgs> {} }:

{
  myPackages = pkgs.buildEnv {
    name = "my-environment";
    paths = with pkgs; [
      # Your packages here
      neovim
      tmux
      fzf
      ripgrep
    ];
  };
}
```

### Adding Packages

1. **Find package name**: `nix search nixpkgs <term>`
   ```bash
   nix search nixpkgs neovim
   ```

2. **Add to packages.nix**:
   ```nix
   paths = with pkgs; [
     neovim
     tmux
     fzf
     ripgrep
     bat         # <-- add new package here
   ];
   ```

3. **Sync changes**:
   ```bash
   ./scripts/sync-packages.sh
   ```

### Removing Packages

1. Remove line from `packages.nix`
2. Run sync: `./scripts/sync-packages.sh`
3. (Optional) Clean up: `nix-collect-garbage -d`

## Common Operations

### List Installed Packages

```bash
nix-env -q
```

### Search for Packages

```bash
nix search nixpkgs <search-term>
```

Examples:
```bash
nix search nixpkgs python
nix search nixpkgs 'rust.*analyzer'
```

### Update Packages

```bash
nix-channel --update
./scripts/sync-packages.sh
```

### Rollback Changes

If an update breaks something:

```bash
nix-env --rollback
```

### Clean Up Old Versions

```bash
nix-collect-garbage -d
```

This removes old package versions and generations.

## Troubleshooting

### NIX not in PATH

After installation, source the NIX profile:

```bash
# Multi-user installation (most common)
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh

# Single-user installation
source ~/.nix-profile/etc/profile.d/nix.sh
```

Add this to your shell's RC file (`~/.bashrc`, `~/.zshrc`).

### Package Not Found

1. **Update channels**:
   ```bash
   nix-channel --update
   ```

2. **Search with exact name**:
   ```bash
   nix search nixpkgs --exact <package>
   ```

3. **Check package availability**: Some packages may be in unstable channel only.

### Permission Denied

The NIX daemon may not be running:

```bash
sudo systemctl start nix-daemon
```

Enable for automatic startup:
```bash
sudo systemctl enable nix-daemon
```

### Build Failures

Check the error log:
```bash
tail -n 50 ~/.local/share/dotmarchy/install_errors.log
```

Common issues:
- Network connectivity (downloads failed)
- Disk space (NIX store full)
- Missing dependencies (build tool not available)

## FAQ

### How much disk space does NIX use?

Typical usage: **1-2 GB** for the NIX store + installed packages.

Use `nix-collect-garbage -d` regularly to clean up.

### Does NIX replace apt/pacm?

**No**. NIX installs user packages. Your system package manager (apt, pacman) is still used for:
- System libraries
- Kernel updates
- System services

Think of NIX as a supplement, not a replacement.

### Can I use both old and new package methods?

**Not simultaneously**. Choose one:
- Traditional: `./dotbuntu` (uses apt/pacman/AUR)
- NIX: `./dotbuntu --nix` (uses NIX only)

We recommend NIX for better reproducibility.

### Will my dotfiles still work?

**Yes**. dotbare (Git-based dotfiles) is completely separate from package management.

Workflow:
1. `./dotbuntu --nix` - Install packages via NIX
2. `fdotbare` or dotbare commands - Manage dotfiles as usual

### How do I uninstall NIX?

**Determinate Systems**:
```bash
nix-installer uninstall
```

**Official installer**: Follow the [official guide](https://nixos.org/manual/nix/stable/installation/uninstall.html)

Steps (summary):
1. Remove users/groups: `nix-users`, `nixbld*`
2. Delete `/nix` directory
3. Remove daemon service
4. Clean shell profiles

## Learning More

- [NIX Official Manual](https://nixos.org/manual/nix/stable/)
- [Nixpkgs Search](https://search.nixpkgs.org/)
- [Zero to Nix](https://zero-to-nix.com/) - Beginner tutorial

## Support

Issues or questions:
1. Check this guide's troubleshooting section
2. Check `~/.local/share/dotmarchy/install_errors.log`
3. Open an issue on GitHub with log excerpts
