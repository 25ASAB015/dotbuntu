# Specification: Documentation Standards

## ADDED Requirements

### Requirement: Function Docblock Template
Every function MUST be documented using the following template:

```bash
#######################################
# One-line description
#
# Detailed explanation of purpose and rationale.
# This section is optional for trivial functions.
#
# Globals:
#   VAR_NAME - Description of how it is used (read/modified)
#
# Arguments:
#   $1 - Description of first argument
#   $2 - Description of second argument (optional)
#
# Returns:
#   0 - Success condition
#   1 - Failure condition
#
# Outputs:
#   STDOUT - What is written to stdout
#   STDERR - What is written to stderr
#######################################
function_name() {
    # Implementation
}
```

#### Scenario: Complete function documentation
- **GIVEN** a function `generate_ssh_key` in `scripts/ssh.sh`
- **WHEN** the function is reviewed
- **THEN** it MUST have the `#######################################` header
- **AND** it MUST have a one-line description
- **AND** it MUST document all globals it reads or modifies
- **AND** it MUST document all arguments
- **AND** it MUST document all return codes
- **AND** it MUST document STDOUT/STDERR outputs

#### Scenario: Minimal function documentation
- **GIVEN** a trivial function `is_running_as_root`
- **WHEN** the function is reviewed
- **THEN** it MUST have at minimum:
  - One-line description
  - Returns section
- **AND** the Globals/Arguments/Outputs sections MAY be omitted if empty

---

### Requirement: File Header Documentation
Every script file MUST have a header block describing its purpose.

```bash
#!/usr/bin/env bash
# shellcheck shell=bash
#
# filename.sh - One-line description
#
# Detailed description of what this module provides and when to use it.
#
# @author: dotbuntu
# @version: X.Y.Z
```

#### Scenario: Module file header
- **GIVEN** the file `helper/logger.sh`
- **WHEN** the file is opened
- **THEN** the first line MUST be the shebang `#!/usr/bin/env bash`
- **AND** line 2 SHOULD be `# shellcheck shell=bash`
- **AND** a description block MUST follow within the first 30 lines

---

### Requirement: Inline Comment Standards
Code comments MUST follow these conventions:

1. Comments in English (code-level)
2. User-facing strings in Spanish
3. TODO comments MUST include context: `# TODO(username): description`
4. Avoid redundant comments that repeat the code

#### Scenario: Appropriate comment
- **GIVEN** complex logic in a function
- **WHEN** a comment is added
- **THEN** the comment MUST explain WHY, not WHAT
- **AND** the comment MUST be on its own line (not trailing)

#### Scenario: Redundant comment
- **GIVEN** code like `# Increment counter` above `counter=$((counter + 1))`
- **WHEN** the code is reviewed
- **THEN** the comment SHOULD be removed as redundant

---

### Requirement: Function Refactor Ledger
A markdown document MUST track all functions from both source repositories.

Location: `docs/function-refactor-ledger.md`

Format:
```markdown
# Function Refactor Ledger

## Legend
- 🟢 MERGED      → Unified implementation in final codebase
- 🔵 KEPT        → Preserved as-is (no equivalent found)
- 🟡 REWRITTEN   → Logic preserved, implementation improved
- 🟠 RENAMED     → Function renamed for clarity/consistency
- 🔴 DELETED     → Redundant or obsolete
- ⚫ IGNORED     → Intentionally not migrated (with reason)
- 🟣 DEFERRED    → To be addressed in a later phase

---

## Module: helper/logger.sh

| Function Name | Repository | Status | Final Name | Notes |
|---------------|------------|--------|------------|-------|
| log           | helper     | 🔵 KEPT | log        | Plain output |
| info          | helper     | 🟢 MERGED | info       | Blue formatted |
| ...           | ...        | ...    | ...        | ...   |
```

#### Scenario: New function added
- **GIVEN** a new function `pkg_install` is being added
- **WHEN** the function is implemented
- **THEN** it MUST first be added to the ledger with status 🔵 KEPT
- **AND** the ledger MUST be updated BEFORE the code is written

#### Scenario: Function merged from two sources
- **GIVEN** both repositories have a `log_error` function
- **WHEN** they are unified
- **THEN** both entries MUST appear in the ledger
- **AND** both MUST have status 🟢 MERGED
- **AND** the Notes column MUST explain the merge decision

---

### Requirement: Variable Documentation
All exported global variables MUST be documented inline.

```bash
# Path to the Git bare repository for dotfiles
# Used by dotbare for dotfile management
# Default: $HOME/.cfg
export DOTBARE_DIR="${DOTBARE_DIR:-$HOME/.cfg}"
```

#### Scenario: Variable with default value
- **GIVEN** a variable `REPO_URL` with a default
- **WHEN** the variable is declared
- **THEN** a comment MUST describe what the variable controls
- **AND** the default value MUST be mentioned in the comment

---

### Requirement: Indentation Standard
All code MUST use 4-space indentation, never tabs.

#### Scenario: Function body indentation
- **GIVEN** a function with nested logic
- **WHEN** the code is reviewed
- **THEN** each nesting level MUST be indented by exactly 4 spaces
- **AND** no tab characters MUST be present

#### Scenario: Continuation lines
- **GIVEN** a long command spanning multiple lines
- **WHEN** the command is broken with `\`
- **THEN** continuation lines MUST be indented to align logically

---

## ADDED Requirements

### Requirement: Deprecation Comments
Deprecated functions MUST be clearly marked.

```bash
#######################################
# DEPRECATED: Use show_logo() instead
#
# This function is maintained for backward compatibility only.
# It will be removed in version 3.0.0.
#######################################
dotmarchy_logo() {
    show_logo "$@"
}
```

#### Scenario: Deprecated function
- **GIVEN** a function `dotmarchy_usage` is deprecated
- **WHEN** the function is reviewed
- **THEN** the docblock MUST include `DEPRECATED:` on the first line
- **AND** it MUST specify which function to use instead
- **AND** it MUST indicate the planned removal version

