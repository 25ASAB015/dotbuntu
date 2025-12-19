# Change: Comprehensive Code Quality Audit and Refactor

## Why

The dotbuntu codebase has grown organically from two merged repositories (gitconfig and dotmarchy). While functional, it has accumulated inconsistencies in documentation style, function signatures, error handling patterns, and code organization that deviate from the strict standards defined in `docs/prompt.md`. This proposal systematically audits every function, applies the mandatory documentation template, eliminates duplication, and ensures robustness before manual testing.

## What Changes

### Phase 1: Function Inventory and Ledger Creation
- Create a complete **Function Refactor Ledger** documenting every function in both `helper/` and `scripts/core/` modules
- Classify each function using the ledger status system (MERGED, KEPT, REWRITTEN, RENAMED, DELETED, DEFERRED)
- Identify duplicate or overlapping implementations across the two logging/color systems

### Phase 2: Documentation Standard Enforcement
- Apply the mandatory docblock template to ALL functions:
  ```
  #######################################
  # One-line description
  #
  # Detailed explanation of purpose and rationale.
  #
  # Globals:
  #   VAR_NAME - Description
  #
  # Arguments:
  #   $1 - Description
  #
  # Returns:
  #   0 - Success
  #   1 - Failure
  #
  # Outputs:
  #   STDOUT - Normal output
  #   STDERR - Error messages
  #######################################
  ```
- Ensure 4-space indentation throughout
- Verify all functions have explicit error handling on critical paths

### Phase 3: Consolidate Duplicate Systems
- **Logging**: Unify `helper/logger.sh` and `scripts/core/logger.sh` into a single canonical implementation
- **Colors**: Resolve the dual-color systems (`$CGR/$CRE/$CYE` vs `c()/cr()` functions) with a compatibility bridge
- **Prompts**: Merge `helper/prompts.sh` functions with `scripts/core/ui.sh` equivalents
- **Checks**: Consolidate `helper/checks.sh` with `scripts/core/common.sh` (initial_checks, root checks, etc.)

### Phase 4: Centralize Global Variables
- Audit all globals scattered across `config/defaults.sh`, `helper/set_variable.sh`
- Create a single source of truth for configuration with clear documentation
- Remove redundant declarations and ensure idempotent loading

### Phase 5: Error Handling Hardening
- Ensure all critical paths have explicit error handling
- Standardize exit codes across the codebase
- Review `on_error` trap handler and ensure consistent behavior

### Phase 6: Code Organization
- Ensure clean separation of concerns per `docs/prompt.md` architecture
- Remove dead code, legacy functions, and unused backward-compatibility aliases
- Validate all module load guards work correctly

## Impact

- **Affected specs**: helper-modules, entrypoint, documentation (new capabilities)
- **Affected code**:
  - `dotbuntu` (main entrypoint)
  - `helper/*.sh` (all 8 helper modules)
  - `scripts/core/*.sh` (6 core modules)
  - `config/defaults.sh`
- **Risk**: Changes to shared functions could break existing behavior
- **Mitigation**: Function-by-function refactor with ledger tracking, no batch changes

