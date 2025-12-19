# NIX Installation Specification

## ADDED Requirements

### Requirement: NIX Installation Detection
The system SHALL detect if NIX is already installed before attempting installation.

#### Scenario: NIX already installed
- **WHEN** `nix-env` command is available
- **THEN** system SHALL skip installation
- **AND** display NIX version information
- **AND** proceed to package installation

#### Scenario: NIX not installed
- **WHEN** `nix-env` command is not found
- **THEN** system SHALL offer to install NIX
- **AND** present installation method options
- **AND** require user confirmation before proceeding

### Requirement: Multiple Installation Methods
The system SHALL support three NIX installation methods with Determinate Systems as the recommended default.

#### Scenario: Determinate Systems installer (recommended)
- **WHEN** user selects Determinate Systems method
- **THEN** system SHALL download installer from `install.determinate.systems`
- **AND** execute installer with appropriate flags
- **AND** verify successful installation
- **AND** enable flakes by default

#### Scenario: Official NIX installer
- **WHEN** user selects official method
- **THEN** system SHALL download from `nixos.org/nix/install`
- **AND** install with `--daemon` flag for multi-user
- **AND** verify systemd service is running (Linux)
- **AND** configure NIX profile in user shell

#### Scenario: Distribution package manager
- **WHEN** user selects distro method
- **AND** on Arch Linux
- **THEN** system SHALL install via `pacman -S nix`
- **AND** enable and start `nix-daemon.service`
- **AND** configure user for NIX access

### Requirement: Interactive Installation Method Selection
The system SHALL provide an interactive menu for users to choose their preferred installation method.

#### Scenario: Display installation options
- **WHEN** installation method selection is triggered
- **THEN** menu SHALL display three options:
  1. Determinate Systems (recommended)
  2. Official NIX installer
  3. Distribution packages (if available)
- **AND** explain benefits of each method
- **AND** wait for user selection

#### Scenario: Non-interactive mode
- **WHEN** `--non-interactive` flag is set
- **THEN** Determinate Systems method SHALL be used by default
- **AND** no user input SHALL be required
- **AND** installation SHALL proceed automatically

### Requirement: Installation Verification
The system SHALL verify NIX installation completed successfully before proceeding.

#### Scenario: Successful installation
- **WHEN** NIX installation completes
- **THEN** `nix-env --version` SHALL execute successfully
- **AND** NIX store SHALL exist at `/nix/store`
- **AND** user SHALL have NIX in PATH
- **AND** success message SHALL be displayed

#### Scenario: Installation failure
- **WHEN** NIX installation fails
- **THEN** clear error message SHALL be displayed
- **AND** installation log SHALL be saved to ERROR_LOG
- **AND** troubleshooting steps SHALL be suggested
- **AND** script SHALL exit with non-zero status

### Requirement: NIX Configuration
The system SHALL configure NIX with sensible defaults for dotmarchy usage.

#### Scenario: Enable experimental features
- **WHEN** using Determinate Systems installer
- **THEN** flakes SHALL be enabled by default
- **AND** nix-command SHALL be enabled
- **AND** `~/.config/nix/nix.conf` SHALL reflect settings

#### Scenario: Configure binary cache
- **WHEN** NIX is installed
- **THEN** cache.nixos.org SHALL be configured as binary cache
- **AND** cache SHALL be trusted for substitutes
- **AND** binary cache SHALL be tested for connectivity

### Requirement: Shell Integration
The system SHALL integrate NIX into the user's shell environment automatically.

#### Scenario: Bash shell integration
- **WHEN** user's shell is bash
- **THEN** NIX profile script SHALL be sourced in `~/.bashrc`
- **AND** `/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh` SHALL be loaded
- **AND** NIX packages SHALL be available in PATH

#### Scenario: Zsh shell integration
- **WHEN** user's shell is zsh
- **THEN** NIX profile script SHALL be sourced in `~/.zshrc`
- **AND** NIX packages SHALL be available in PATH after shell restart

#### Scenario: Immediate PATH update
- **WHEN** installation completes within current session
- **THEN** system SHALL source NIX profile script immediately
- **AND** NIX commands SHALL be usable without shell restart

### Requirement: Installation Prerequisites Check
The system SHALL verify all prerequisites are met before attempting NIX installation.

#### Scenario: Check required tools
- **WHEN** installation is initiated
- **THEN** system SHALL verify `curl` is installed
- **AND** verify `sudo` access (for daemon installation)
- **AND** verify internet connectivity
- **AND** verify sufficient disk space (minimum 2GB)

#### Scenario: Missing prerequisites
- **WHEN** any prerequisite is missing
- **THEN** specific missing requirement SHALL be reported
- **AND** installation SHALL abort
- **AND** instructions to install prerequisites SHALL be provided

### Requirement: Uninstallation Support
The system SHALL provide guidance for uninstalling NIX if needed.

#### Scenario: Determinate Systems uninstall
- **WHEN** user installed via Determinate Systems
- **THEN** system SHALL document `nix-installer uninstall` command
- **AND** provide step-by-step uninstall instructions
- **AND** warn about data loss (NIX store deletion)

#### Scenario: Official installer uninstall
- **WHEN** user installed via official method
- **THEN** system SHALL provide manual uninstall steps
- **AND** document removal of NIX directories
- **AND** document shell configuration cleanup

### Requirement: Installation Logging
The system SHALL log all installation steps for debugging and troubleshooting.

#### Scenario: Successful installation logging
- **WHEN** installation succeeds
- **THEN** all steps SHALL be logged with timestamps
- **AND** NIX version SHALL be recorded
- **AND** installation method SHALL be recorded
- **AND** log SHALL be saved to standard log location

#### Scenario: Failed installation logging
- **WHEN** installation fails
- **THEN** error context SHALL be logged
- **AND** stderr output SHALL be captured
- **AND** system state SHALL be recorded
- **AND** log location SHALL be displayed to user

