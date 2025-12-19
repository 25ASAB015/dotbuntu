# Specification: Helper Modules Quality Standards

## ADDED Requirements

### Requirement: Mandatory Function Documentation
Every function in helper modules MUST have a documentation block following the project standard.

The documentation block MUST include:
- One-line description
- Detailed explanation (optional for trivial functions)
- Globals section (if any globals are read or modified)
- Arguments section (with $1, $2, etc. descriptions)
- Returns section (with exit code meanings)
- Outputs section (STDOUT/STDERR descriptions)

#### Scenario: Function with complete documentation
- **GIVEN** a function `validate_email` in `helper/utils.sh`
- **WHEN** the function is reviewed
- **THEN** it MUST have a `#######################################` docblock
- **AND** the docblock MUST include all required sections

#### Scenario: Simple function documentation
- **GIVEN** a one-line utility function like `is_verbose_enabled`
- **WHEN** the function is reviewed
- **THEN** it MUST have at minimum a one-line description and Returns section

---

### Requirement: Idempotent Module Loading
All helper modules MUST support being sourced multiple times without side effects.

#### Scenario: Double-sourcing a helper
- **GIVEN** `helper/logger.sh` has been sourced
- **WHEN** it is sourced again
- **THEN** no functions are redefined
- **AND** no variables are reinitialized
- **AND** no errors are produced

#### Scenario: Load guard implementation
- **GIVEN** a helper module
- **WHEN** the module is loaded
- **THEN** it MUST check for a `_MODULE_LOADED` guard variable
- **AND** return immediately if already loaded

---

### Requirement: Dependency Declaration
Each helper module MUST explicitly declare and load its dependencies.

#### Scenario: Logger depends on colors
- **GIVEN** `helper/logger.sh` uses color variables
- **WHEN** the module is sourced without colors being loaded
- **THEN** it MUST automatically source `helper/colors.sh`
- **AND** it MUST NOT fail due to missing color variables

#### Scenario: Circular dependency prevention
- **GIVEN** module A depends on module B
- **AND** module B depends on module A
- **WHEN** either module is sourced
- **THEN** the load guards MUST prevent infinite recursion

---

### Requirement: Consistent Error Handling
All helper functions that can fail MUST handle errors explicitly.

#### Scenario: File operation failure
- **GIVEN** a function `write_to_error_log` attempts to write to a file
- **WHEN** the write operation fails
- **THEN** the function MUST NOT cause script termination
- **AND** it MUST log/report the failure to stderr
- **AND** it MUST return a non-zero exit code

#### Scenario: Command not found
- **GIVEN** a function `require_cmd` checks for a command
- **WHEN** the command is not found
- **THEN** the function MUST call `log_error` with a descriptive message
- **AND** it MUST exit with code 127 (command not found)

---

### Requirement: Exit Code Standardization
All helper functions MUST use standardized exit codes.

| Code | Meaning | Usage |
|------|---------|-------|
| 0 | Success | Normal completion |
| 1 | General failure | Unspecified error |
| 2 | Invalid input | Bad arguments or validation failure |
| 4 | Invalid environment | Missing dependencies or unsupported OS |
| 127 | Command not found | Required binary not in PATH |
| 130 | Interrupted | SIGINT received |

#### Scenario: Exit code consistency
- **GIVEN** a function fails due to missing command
- **WHEN** the function exits
- **THEN** it MUST use exit code 127
- **AND** the exit code MUST match the documented meaning

---

## ADDED Requirements

### Requirement: Color Variable Standardization
The canonical color system MUST use exported shell variables, not functions.

#### Scenario: Color variable availability
- **WHEN** `helper/colors.sh` is sourced
- **THEN** `$CRE`, `$CYE`, `$CGR`, `$CBL`, `$BLD`, `$CNC` MUST be exported
- **AND** each variable MUST contain ANSI escape codes or empty string (for non-tty)

#### Scenario: Non-tty fallback
- **GIVEN** the script runs in a non-tty environment (e.g., piped output)
- **WHEN** color variables are used
- **THEN** they MUST be empty strings to avoid escape codes in output

---

### Requirement: Logging System Unification
The `helper/logger.sh` module MUST be the canonical logging implementation.

Functions provided:
- `log()` - Plain output
- `info()` - Informational (blue)
- `warn()` - Warning (yellow)
- `log_error()` - Error to stderr and log file (red)
- `debug()` - Verbose-only output

#### Scenario: Error logging with timestamp
- **GIVEN** an error occurs
- **WHEN** `log_error "message"` is called
- **THEN** the message MUST be written to the ERROR_LOG file
- **AND** the file entry MUST include a timestamp in `YYYY-MM-DD HH:MM:SS` format
- **AND** the message MUST be displayed to stderr with red formatting

#### Scenario: Debug only in verbose mode
- **GIVEN** `VERBOSE=0`
- **WHEN** `debug "message"` is called
- **THEN** no output MUST be produced

- **GIVEN** `VERBOSE=1`
- **WHEN** `debug "message"` is called
- **THEN** the message MUST be displayed to stdout with bold formatting

