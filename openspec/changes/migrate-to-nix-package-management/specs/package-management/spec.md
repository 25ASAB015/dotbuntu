# Package Management Specification

## ADDED Requirements

### Requirement: NIX Package Installation
The system SHALL install all packages exclusively through the NIX package manager using a declarative `packages.nix` configuration file.

#### Scenario: Fresh installation with packages.nix
- **WHEN** user runs install with NIX enabled
- **AND** `packages.nix` exists at `~/.config/dotmarchy/packages.nix`
- **THEN** all packages listed in `packages.nix` SHALL be installed via `nix-env`
- **AND** installation status SHALL be logged

#### Scenario: Update existing packages
- **WHEN** user modifies `packages.nix` and runs sync
- **THEN** new packages SHALL be installed
- **AND** removed packages SHALL remain available (NIX doesn't auto-remove)
- **AND** system SHALL be idempotent (safe to rerun)

#### Scenario: Package not in nixpkgs
- **WHEN** packages.nix references non-existent package
- **THEN** clear error message SHALL be displayed
- **AND** installation SHALL continue with remaining packages
- **AND** failed packages SHALL be logged to ERROR_LOG

### Requirement: Declarative Package Configuration
The system SHALL use a `packages.nix` file in Nix expression language to declare all packages.

#### Scenario: Valid packages.nix format
- **WHEN** packages.nix uses correct Nix syntax
- **THEN** `nix-instantiate --eval` SHALL succeed
- **AND** all package references SHALL resolve to nixpkgs attributes

#### Scenario: Syntax error in packages.nix
- **WHEN** packages.nix contains syntax errors
- **THEN** validation SHALL fail with clear error message
- **AND** specific line number SHALL be reported
- **AND** installation SHALL abort before making changes

### Requirement: Package Versioning in Dotfiles
The system SHALL support versioning `packages.nix` in the dotbare repository alongside other dotfiles.

#### Scenario: Commit package changes
- **WHEN** user modifies `packages.nix`
- **THEN** changes SHALL be committable via `dotbare add/commit`
- **AND** package list SHALL be synced across machines via `dotbare push/pull`

#### Scenario: Pull triggers package sync
- **WHEN** user runs `dotbare pull` and `packages.nix` changes
- **THEN** system SHOULD offer to run package sync
- **AND** user SHALL be able to review changes before applying

### Requirement: Cross-Platform Package Names
The system SHALL use consistent package names from nixpkgs that work identically on all supported distributions (Arch, Ubuntu, Debian, Fedora).

#### Scenario: Same packages.nix on different distros
- **WHEN** same `packages.nix` is used on Arch and Ubuntu
- **THEN** identical set of packages SHALL be installed
- **AND** package versions SHALL match (same nixpkgs revision)
- **AND** no distribution-specific logic SHALL be required

#### Scenario: Distribution-specific package does not exist
- **WHEN** user requests Arch-only package (e.g., AUR package)
- **THEN** system SHALL provide guidance on alternatives
- **AND** documentation SHALL explain nixpkgs availability

### Requirement: Package Rollback
The system SHALL support rolling back package installations using NIX's built-in generation management.

#### Scenario: Rollback to previous generation
- **WHEN** user runs `nix-env --rollback`
- **THEN** previous package set SHALL be restored
- **AND** system state SHALL return to before last package operation

#### Scenario: List available generations
- **WHEN** user runs `nix-env --list-generations`
- **THEN** all package generations SHALL be displayed with timestamps
- **AND** user SHALL be able to switch to any previous generation

### Requirement: Package Installation Performance
The system SHALL provide fast package installations by leveraging NIX's binary cache.

#### Scenario: Package available in cache
- **WHEN** package exists in cache.nixos.org
- **THEN** package SHALL be downloaded as binary (not built)
- **AND** installation SHALL complete in seconds to minutes

#### Scenario: Package requires building
- **WHEN** package not in binary cache
- **THEN** system SHALL build from source
- **AND** user SHALL be warned about build time
- **AND** build progress SHALL be displayed

### Requirement: Cleanup and Garbage Collection
The system SHALL provide mechanisms to clean up unused packages and free disk space.

#### Scenario: Remove old generations
- **WHEN** user runs garbage collection
- **THEN** unreferenced packages SHALL be removed
- **AND** current generation SHALL remain intact
- **AND** disk space freed SHALL be reported

#### Scenario: Automatic cleanup suggestion
- **WHEN** NIX store exceeds 10GB
- **THEN** system SHOULD suggest running garbage collection
- **AND** provide command to execute cleanup

## REMOVED Requirements

### Requirement: Distribution-Specific Package Installation
**Reason**: NIX provides uniform package management across all distributions, eliminating the need for distro-specific installers (apt/pacman).

**Migration**: Users SHALL use `packages.nix` instead of `setup.conf` arrays. Conversion script SHALL map old package names to nixpkgs equivalents.

### Requirement: AUR Package Installation
**Reason**: NIX provides comprehensive package repository (65,000+ packages) making AUR unnecessary. Most AUR packages have nixpkgs equivalents.

**Migration**: Users SHALL search nixpkgs for equivalent packages. For missing packages, documentation SHALL explain overlay creation or GitHub releases fallback.

### Requirement: Multiple Package Manager Support
**Reason**: Maintaining 7+ package sources (cargo, npm, pipx, gem, etc.) creates complexity. NIX unifies all package management.

**Migration**: All language-specific tools (cargo, npm, etc.) SHALL be installed via NIX. Language runtimes (node, python, ruby) remain available in PATH for project-specific usage.

### Requirement: Package Name Mapping Between Distributions
**Reason**: NIX uses consistent package names across distributions, eliminating need for mapping logic (e.g., `ninja` vs `ninja-build`).

**Migration**: Package manager detection code SHALL be removed. All package references SHALL use nixpkgs attribute names.

