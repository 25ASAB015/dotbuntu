# Specification: Main Entrypoint Quality Standards

## ADDED Requirements

### Requirement: Entrypoint Guard Pattern
The main script MUST use the Bash source/execute guard pattern.

```bash
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

#### Scenario: Script executed directly
- **GIVEN** `./dotbuntu` is executed from command line
- **WHEN** the script runs
- **THEN** the `main` function MUST be called with all CLI arguments

#### Scenario: Script sourced by another
- **GIVEN** another script sources `dotbuntu`
- **WHEN** the source completes
- **THEN** the `main` function MUST NOT be called automatically
- **AND** all functions and variables MUST be available to the sourcing script

---

### Requirement: Argument Parsing Robustness
The `parse_arguments` function MUST handle all CLI flags correctly.

Required flags:
- `-h, --help` - Display help and exit
- `--non-interactive` - Disable user prompts
- `--auto-upload` - Auto-upload keys to GitHub
- `--extras` - Install extra packages
- `--setup-env` - Setup environment
- `--verify` - Run verification mode
- `--repo URL` - Override repository URL
- `-v, --verbose` - Enable verbose output
- `-f, --force` - Force operations

#### Scenario: Unknown flag handling
- **GIVEN** the user runs `./dotbuntu --unknown-flag`
- **WHEN** arguments are parsed
- **THEN** an error message MUST be displayed to stderr
- **AND** the script MUST exit with code 1
- **AND** the help text MUST be suggested

#### Scenario: Missing required argument
- **GIVEN** the user runs `./dotbuntu --repo` without a URL
- **WHEN** arguments are parsed
- **THEN** an error message "Option --repo requires an argument" MUST be displayed
- **AND** the script MUST exit with code 2

#### Scenario: Positional argument as repo URL
- **GIVEN** the user runs `./dotbuntu git@github.com:user/dots.git`
- **WHEN** arguments are parsed
- **THEN** `REPO_URL` MUST be set to the provided URL

---

### Requirement: Signal Handling
The entrypoint MUST handle interruption signals gracefully.

#### Scenario: SIGINT during execution
- **GIVEN** the script is running
- **WHEN** the user presses Ctrl+C (SIGINT)
- **THEN** the `cleanup` function MUST be called
- **AND** a warning message MUST be displayed
- **AND** the script MUST exit with code 130

#### Scenario: SIGTERM during execution
- **GIVEN** the script is running
- **WHEN** SIGTERM is received
- **THEN** the `cleanup` function MUST be called
- **AND** the script MUST exit with code 130

---

### Requirement: Module Loading Order
The entrypoint MUST source modules in a specific order to satisfy dependencies.

Load order:
1. `config/defaults.sh` - Global configuration
2. `scripts/core/colors.sh` - Color functions (c, cr)
3. `scripts/core/logger.sh` - Logging functions
4. `scripts/core/validation.sh` - Input validation
5. `scripts/core/ui.sh` - UI functions
6. `scripts/core/common.sh` - Common utilities
7. `helper/load_helpers.sh` - Dynamic loader
8. Load helpers: `utils`, `checks`, `prompts`
9. Feature modules: `dependencies.sh`, `ssh.sh`, `gpg.sh`, etc.

#### Scenario: Colors available to logger
- **GIVEN** `scripts/core/logger.sh` is sourced
- **WHEN** a logging function is called
- **THEN** color functions `c()` and `cr()` MUST be available

#### Scenario: Missing module
- **GIVEN** a required module file does not exist
- **WHEN** the entrypoint sources modules
- **THEN** the script MUST fail with a clear error message
- **AND** the missing file path MUST be included in the error

---

### Requirement: Two-Phase Execution
The main function MUST support two distinct execution phases.

Phase 1 (Dotfiles & System): Controlled by flags `--extras`, `--setup-env`
Phase 2 (Git Configuration): Controlled by interactive prompt or `--non-interactive`

#### Scenario: Full execution in interactive mode
- **GIVEN** the user runs `./dotbuntu` without flags
- **WHEN** prompted about dotfiles installation
- **AND** the user responds "yes"
- **AND** prompted about Git configuration
- **AND** the user responds "yes"
- **THEN** both Phase 1 and Phase 2 MUST execute

#### Scenario: Skip Phase 1 in non-interactive without flags
- **GIVEN** the user runs `./dotbuntu --non-interactive`
- **WHEN** no `--extras` or `--setup-env` flags are provided
- **THEN** Phase 1 MUST be skipped (no INSTALL_EXTRAS or SETUP_ENVIRONMENT)

---

### Requirement: Verification Mode
The `--verify` flag MUST trigger diagnostic mode and exit.

#### Scenario: Verification mode execution
- **GIVEN** the user runs `./dotbuntu --verify`
- **WHEN** arguments are parsed
- **THEN** the verification script MUST be executed via `exec`
- **AND** no other phases MUST run
- **AND** the exit code MUST be from the verification script

---

## ADDED Requirements

### Requirement: Progress Reporting
The entrypoint MUST display progress during Git configuration.

#### Scenario: Progress bar display
- **GIVEN** Git configuration is running
- **WHEN** each step completes
- **THEN** a progress bar MUST be displayed
- **AND** the bar MUST show current step out of total
- **AND** a description of the current step MUST be shown

#### Scenario: Progress in non-interactive mode
- **GIVEN** `--non-interactive` flag is set
- **WHEN** progress is reported
- **THEN** progress bars MUST still be displayed
- **AND** no prompts MUST appear

