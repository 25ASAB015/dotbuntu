# Dotfile Management Specification

## ADDED Requirements

### Requirement: Dotbare-Based Dotfiles Management
The system SHALL use dotbare (git bare repository) for managing user dotfiles with HOME as the working tree.

#### Scenario: Initialize dotbare repository
- **WHEN** user runs initial setup
- **THEN** bare repository SHALL be created at `~/.cfg`
- **AND** HOME directory SHALL be set as working tree
- **AND** dotbare command SHALL be available for git operations

#### Scenario: Clone existing dotfiles
- **WHEN** user provides dotfiles repository URL
- **THEN** dotbare SHALL clone repository to `~/.cfg`
- **AND** dotfiles SHALL be checked out to HOME
- **AND** existing files SHALL be backed up before overwrite

### Requirement: Git Workflow for Dotfiles
The system SHALL provide standard git commands via dotbare for dotfile version control.

#### Scenario: Track new dotfile
- **WHEN** user runs `dotbare add <file>`
- **THEN** file SHALL be staged in bare repository
- **AND** file location SHALL remain in HOME directory
- **AND** `dotbare status` SHALL reflect staged change

#### Scenario: Commit dotfile changes
- **WHEN** user runs `dotbare commit`
- **THEN** changes SHALL be committed to bare repository
- **AND** commit history SHALL be preserved
- **AND** commit message SHALL be required

#### Scenario: Push dotfiles to remote
- **WHEN** user runs `dotbare push`
- **THEN** commits SHALL be pushed to configured remote
- **AND** remote repository SHALL be updated
- **AND** other machines SHALL be able to pull changes

#### Scenario: Pull dotfile updates
- **WHEN** user runs `dotbare pull`
- **THEN** remote changes SHALL be fetched and merged
- **AND** dotfiles in HOME SHALL be updated
- **AND** merge conflicts SHALL be reported if any

### Requirement: Package Configuration Versioning
The system SHALL support versioning the NIX packages.nix file alongside other dotfiles.

#### Scenario: Track packages.nix changes
- **WHEN** user modifies `~/.config/dotmarchy/packages.nix`
- **THEN** file SHALL be committable via dotbare
- **AND** changes SHALL be visible in `dotbare diff`
- **AND** package history SHALL be viewable via `dotbare log`

#### Scenario: Sync packages across machines
- **WHEN** packages.nix is pushed from machine A
- **AND** pulled on machine B
- **THEN** package list SHALL be identical
- **AND** system SHOULD offer to sync packages
- **AND** user SHALL review differences before applying

### Requirement: Dotfiles Backup
The system SHALL backup existing dotfiles before overwriting with repository versions.

#### Scenario: Backup conflicting files
- **WHEN** cloning dotfiles would overwrite existing files
- **THEN** existing files SHALL be moved to backup location
- **AND** backup location SHALL be `~/.local/share/dotbare/backup-TIMESTAMP/`
- **AND** backup location SHALL be displayed to user
- **AND** user SHALL be able to restore from backup

#### Scenario: No backup needed
- **WHEN** no conflicting files exist
- **THEN** dotfiles SHALL be cloned without backup
- **AND** no backup directory SHALL be created

### Requirement: Dotbare Repository Configuration
The system SHALL configure dotbare with sensible defaults for dotfiles management.

#### Scenario: Configure repository locations
- **WHEN** dotbare is initialized
- **THEN** `DOTBARE_DIR` SHALL be set to `~/.cfg`
- **AND** `DOTBARE_TREE` SHALL be set to `$HOME`
- **AND** `DOTBARE_BACKUP` SHALL be set to `~/.local/share/dotbare`
- **AND** environment variables SHALL persist in shell config

#### Scenario: Ignore unnecessary files
- **WHEN** dotbare repository is created
- **THEN** `.cfg` directory SHALL be ignored
- **AND** system SHALL NOT track all HOME directory files by default
- **AND** only explicitly added files SHALL be tracked

### Requirement: Dotbare Integration with NIX Workflow
The system SHALL integrate dotbare workflow with NIX package management for unified user experience.

#### Scenario: First-time setup workflow
- **WHEN** user runs install script
- **THEN** NIX SHALL be installed first
- **AND** dotbare SHALL be configured second
- **AND** dotfiles repository SHALL be cloned third
- **AND** packages.nix SHALL be applied last

#### Scenario: Update workflow
- **WHEN** user updates dotfiles and packages
- **THEN** user SHALL commit both types of changes to dotbare repo
- **AND** single push SHALL sync both dotfiles and package list
- **AND** pull on another machine SHALL receive both updates

### Requirement: Remote Repository Support
The system SHALL support both SSH and HTTPS remote repository URLs for dotfiles.

#### Scenario: SSH repository URL
- **WHEN** user provides git@github.com:user/repo.git
- **THEN** SSH key SHALL be used for authentication
- **AND** SSH key SHALL be tested before cloning
- **AND** failed authentication SHALL be reported clearly

#### Scenario: HTTPS repository URL
- **WHEN** user provides https://github.com/user/repo.git
- **THEN** HTTPS SHALL be used for cloning
- **AND** credentials MAY be cached via git credential helper
- **AND** authentication prompts SHALL be handled interactively

### Requirement: Dotbare Command Availability
The system SHALL ensure dotbare command is available and properly configured for use.

#### Scenario: Dotbare installed from nixpkgs
- **WHEN** dotbare is installed via packages.nix
- **THEN** `dotbare` command SHALL be in PATH
- **AND** command SHALL execute git operations correctly
- **AND** dotbare version SHALL be logged

#### Scenario: Dotbare not in PATH
- **WHEN** dotbare command is not found
- **THEN** clear error message SHALL be displayed
- **AND** installation instructions SHALL be provided
- **AND** script SHALL exit with error status

### Requirement: Dotfiles Template Support
The system SHALL provide a template packages.nix when initializing a new dotfiles repository.

#### Scenario: New dotfiles repository
- **WHEN** user initializes new repository (not cloning existing)
- **THEN** template packages.nix SHALL be created
- **AND** template SHALL include common packages
- **AND** template SHALL have comments explaining usage
- **AND** user SHALL be prompted to customize

#### Scenario: Existing dotfiles repository
- **WHEN** user clones existing repository
- **THEN** existing packages.nix SHALL be used if present
- **AND** no template SHALL be created
- **AND** packages SHALL be applied from repository version

