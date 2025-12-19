# Migration Guide: v1.x → v2.0.0 (NIX Package Management)

This guide helps you migrate from the multi-source package management system to NIX-based package management.

## Overview

**What's Changing:**
- **Old**: apt/pacman + AUR + Chaotic-AUR + cargo + npm + pipx + gem
- **New**: NIX package manager only (65,000+ packages, cross-platform)

**What's Preserved:**
- dotbare dotfiles management (unchanged)
- Git/GPG/SSH configuration (unchanged)
- Your existing dotfiles repository

## Migration Paths

### Path 1: Fresh Install (Recommended)

Best for new machines or if you want a clean start.

```bash
# 1. Clone the new dotmarchy
git clone https://github.com/25ASAB015/dotbuntu.git
cd dotbuntu

# 2. Run unified installer
./install.sh

# 3. Follow interactive prompts
# - Install NIX? Yes
# - Configure dotbare? Yes  
# - Sync packages? Yes

# 4. Your dotfiles will be cloned automatically
# 5. Packages from packages.nix will install
```

### Path 2: In-Place Migration

Migrate existing installation to NIX.

```bash
# 1. Pull latest dotbuntu changes
cd ~/dotbuntu  # or wherever you cloned it
git pull origin master

# 2. Convert your setup.conf to packages.nix (if you have one)
./scripts/convert-setup-conf.sh

# 3. Run NIX installation
./dotbuntu --nix

# 4. Verify packages installed
nix-env -q

# 5. Add packages.nix to dotfiles
dotbare add ~/.config/dotmarchy/packages.nix
dotbare commit -m "Add NIX package configuration"
dotbare push
```

### Path 3: Keep Old System (Deprecated)

Continue using apt/pacman/AUR for 3 months.

```bash
# Run with --legacy flag (available until v3.0.0)
./dotbuntu --legacy

# Note: This will be removed in 3 months
# Plan your migration before then
```

## Step-by-Step Migration

### Step 1: Backup Current System

```bash
# List currently installed packages
dpkg --get-selections > ~/packages-backup-apt.txt  # Ubuntu/Debian
pacman -Qqe > ~/packages-backup-pacman.txt         # Arch

# Backup dotfiles (if not using dotbare yet)
cp -r ~/.config ~/config-backup
```

### Step 2: Install NIX

```bash
# Option A: Use install.sh
./install.sh --nix --no-dotbare

# Option B: Manual bootstrap
./scripts/bootstrap-nix.sh
```

###Step 3: Convert Package Configuration

**If you have setup.conf** (old config format):

```bash
./scripts/convert-setup-conf.sh

# Review generated packages.nix
vim ~/.config/dotmarchy/packages.nix

# Apply packages
./scripts/sync-packages.sh
```

**If starting fresh**:

```bash
# Copy template
mkdir -p ~/.config/dotmarchy
cp packages.nix ~/.config/dotmarchy/

# Edit to your needs
vim ~/.config/dotmarchy/packages.nix

# Apply packages
./scripts/sync-packages.sh
```

### Step 4: Version packages.nix in Dotfiles

```bash
# Add to dotbare (if using dotbare)
dotbare add ~/.config/dotmarchy/packages.nix
dotbare commit -m "Add NIX package configuration"
dotbare push

# Or commit manually (if using regular git)
cd ~/dotfiles
git add .config/dotmarchy/packages.nix
git commit -m "Add NIX package configuration"
git push
```

### Step 5: Test on Another Machine

```bash
# On second machine
git clone https://github.com/25ASAB015/dotbuntu.git
cd dotbuntu
./install.sh

# Your packages.nix should sync automatically via dotbare
# Packages will be installed from packages.nix
```

## Package Name Mapping

Common packages and their NIX equivalents:

| Old (apt/pacman) | NIX Package | Notes |
|------------------|-------------|-------|
| `ninja-build` (Ubuntu) / `ninja` (Arch) | `ninja` | Consistent across distros |
| `git-delta` (AUR) | `delta` | In nixpkgs |
| `brave-bin` (Chaotic-AUR) | `brave` | In nixpkgs |
| `visual-studio-code-bin` | `vscode` | In nixpkgs |
| `zsh-theme-powerlevel10k-git` | `zsh-powerlevel10k` | In nixpkgs |
| `dotbare` (AUR) | Manual install | Not in nixpkgs yet |
| `diff-so-fancy` (npm) | `diff-so-fancy` | In nixpkgs |

**Search for packages**:
```bash
nix search nixpkgs neovim
nix search nixpkgs 'python.*3.11'
```

## Troubleshooting

### Package Not Found in nixpkgs

**Solution 1: Use unstable channel**
```bash
nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs-unstable
nix-channel --update
```

**Solution 2: Check online**
- https://search.nixpkgs.org/
- Search by name or description

**Solution 3: Manual installation**
- Some packages may need manual git clone (e.g., dotbare)
- Document in packages.nix comments for reference

### Dotbare Not Working After Migration

```bash
# Reinstall dotbare manually
git clone https://github.com/kazhala/dotbare.git ~/.dotbare

# Source plugin in shell config
echo 'source ~/.dotbare/dotbare.plugin.zsh' >> ~/.zshrc  # or ~/.bashrc
```

### packages.nix Syntax Error

```bash
# Validate syntax
nix-instantiate --eval ~/.config/dotmarchy/packages.nix

# Common errors:
# - Missing semicolon
# - Incorrect attribute name
# - Missing closing brace
```

### NIX Takes Too Much Disk Space

```bash
# Clean up old generations
nix-collect-garbage -d

# Check disk usage
du -sh /nix/store/
```

### Rollback to Old Package Set

```bash
# List generations
nix-env --list-generations

# Rollback to previous
nix-env --rollback

# Rollback to specific generation
nix-env --switch-generation 42
```

## Breaking Changes Summary

1. **Configuration Format**
   - Old: `setup.conf` bash arrays
   - New: `packages.nix` Nix expressions

2. **Installation Method**
   - Old: `./dotbuntu --extras`
   - New: `./dotbuntu --nix` or `./install.sh`

3. **Package Commands**
   - Old: `sudo pacman -S <pkg>` or `sudo apt install <pkg>`
   - New: Edit `packages.nix`, run `./scripts/sync-packages.sh`

4. **Removed Scripts**
   - `fdeps` (apt/pacman installer)
   - `faur` (AUR installer)
   - `fchaotic*` (Chaotic-AUR)
   - Language installers (cargo, npm, pipx, gem)
   - Moved to `scripts/legacy/` (available via `--legacy` flag until v3.0.0)

## Rollback to v1.x

If you need to revert:

```bash
# 1. Checkout v1.x tag
cd ~/dotbuntu
git checkout v1.9.0  # or latest v1.x

# 2. Remove NIX (optional)
nix-installer uninstall  # if using Determinate Systems
# OR follow: https://nixos.org/manual/nix/stable/installation/uninstall.html

# 3. Resume old workflow
./dotbuntu
```

## Timeline

- **Now - Month 1**: v2.0.0 released, opt-in via `--nix` flag
- **Month 1 - Month 3**: Transition period, both methods supported
- **Month 3+**: v3.0.0 released, legacy code removed, NIX required

## Getting Help

- **Documentation**: `docs/NIX_SETUP.md`
- **Issues**: https://github.com/25ASAB015/dotbuntu/issues
- **Questions**: Create a discussion on GitHub

## FAQ

**Q: Will my dotfiles break?**  
A: No. Dotbare workflow is unchanged. Only package installation method changes.

**Q: Can I use both old and new methods?**  
A: Not recommended. Choose one to avoid conflicts.

**Q: What if NIX package doesn't exist?**  
A: Search nixpkgs, use unstable channel, or install manually and document in packages.nix comments.

**Q: How do I sync packages across machines?**  
A: Version `packages.nix` in dotbare repo. Pull on other machine, run `./scripts/sync-packages.sh`.

**Q: Does this work on macOS?**  
A: Yes! NIX works on macOS. Same `packages.nix` works on Linux and macOS.
