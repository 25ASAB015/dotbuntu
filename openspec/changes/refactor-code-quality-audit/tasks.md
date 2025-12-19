# Tasks: Code Quality Audit and Refactor

## 1. Function Inventory and Ledger
- [ ] 1.1 Create `docs/function-refactor-ledger.md` with all functions from `helper/*.sh`
- [ ] 1.2 Add all functions from `scripts/core/*.sh` to the ledger
- [ ] 1.3 Add functions from `dotbuntu` main entrypoint to the ledger
- [ ] 1.4 Classify each function with ledger status (MERGED/KEPT/REWRITTEN/RENAMED/DELETED/DEFERRED)
- [ ] 1.5 Document cross-dependencies between functions

## 2. Documentation Standardization

### 2.1 Helper Modules
- [ ] 2.1.1 `helper/colors.sh` - Apply mandatory docblock template
- [ ] 2.1.2 `helper/logger.sh` - Apply mandatory docblock template (already mostly compliant)
- [ ] 2.1.3 `helper/utils.sh` - Apply mandatory docblock template to all 20+ functions
- [ ] 2.1.4 `helper/checks.sh` - Apply mandatory docblock template (mostly compliant)
- [ ] 2.1.5 `helper/prompts.sh` - Apply mandatory docblock template to all render functions
- [ ] 2.1.6 `helper/set_variable.sh` - Document all exported variables
- [ ] 2.1.7 `helper/load_helpers.sh` - Apply mandatory docblock template
- [ ] 2.1.8 `helper/compat.sh` - Apply mandatory docblock template
- [ ] 2.1.9 `helper/package_manager.sh` - Apply mandatory docblock template

### 2.2 Core Scripts
- [ ] 2.2.1 `scripts/core/colors.sh` - Apply mandatory docblock template
- [ ] 2.2.2 `scripts/core/logger.sh` - Apply mandatory docblock template
- [ ] 2.2.3 `scripts/core/ui.sh` - Apply mandatory docblock template (mostly compliant)
- [ ] 2.2.4 `scripts/core/common.sh` - Apply mandatory docblock template (mostly compliant)
- [ ] 2.2.5 `scripts/core/validation.sh` - Apply mandatory docblock template (mostly compliant)

### 2.3 Configuration
- [ ] 2.3.1 `config/defaults.sh` - Document all variables with inline comments
- [ ] 2.3.2 `dotbuntu` - Apply mandatory docblock template to main/parse_arguments/cleanup

## 3. Code Consolidation

### 3.1 Logging Unification
- [ ] 3.1.1 Inventory functions in both logger.sh files
- [ ] 3.1.2 Decide canonical implementation for each function
- [ ] 3.1.3 Update `scripts/core/logger.sh` to delegate to `helper/logger.sh`
- [ ] 3.1.4 Verify no functionality lost
- [ ] 3.1.5 Update ledger with decisions

### 3.2 Color System Unification
- [ ] 3.2.1 Verify `helper/colors.sh` exports all needed variables
- [ ] 3.2.2 Ensure `compat.sh` provides working `c()/cr()` wrappers
- [ ] 3.2.3 Update ledger with color function decisions

### 3.3 Prompt/UI Consolidation
- [ ] 3.3.1 Compare `helper/prompts.sh` with `scripts/core/ui.sh` functions
- [ ] 3.3.2 Identify duplicates: `show_logo`, `welcome`, `ask_yes_no`, etc.
- [ ] 3.3.3 Decide canonical implementation for each
- [ ] 3.3.4 Ensure backward-compat aliases exist
- [ ] 3.3.5 Update ledger

### 3.4 Checks Consolidation
- [ ] 3.4.1 Compare `helper/checks.sh` with `scripts/core/common.sh`
- [ ] 3.4.2 Identify duplicates: `initial_checks`, root checks, etc.
- [ ] 3.4.3 Decide canonical implementation
- [ ] 3.4.4 Update ledger

## 4. Global Variable Centralization
- [ ] 4.1 List all variables in `config/defaults.sh`
- [ ] 4.2 List all variables in `helper/set_variable.sh`
- [ ] 4.3 Identify overlaps and conflicts
- [ ] 4.4 Merge unique variables into `config/defaults.sh`
- [ ] 4.5 Convert `helper/set_variable.sh` to a shim
- [ ] 4.6 Update source order in `dotbuntu`

## 5. Error Handling Hardening
- [ ] 5.1 Audit all `exit` statements for proper codes
- [ ] 5.2 Ensure `on_error` trap is registered in all scripts
- [ ] 5.3 Verify all critical paths have explicit error handling
- [ ] 5.4 Standardize exit codes across modules

## 6. Code Cleanup
- [ ] 6.1 Remove deprecated backward-compat aliases (after one release)
- [ ] 6.2 Remove dead code identified during inventory
- [ ] 6.3 Fix all shellcheck warnings (severity=warning)
- [ ] 6.4 Verify 4-space indentation throughout

## 7. Validation
- [ ] 7.1 Run shellcheck on all `.sh` files
- [ ] 7.2 Test on Arch Linux (interactive mode)
- [ ] 7.3 Test on Arch Linux (non-interactive mode)
- [ ] 7.4 Test on Ubuntu 22.04 (interactive mode)
- [ ] 7.5 Test on Ubuntu 24.04 (non-interactive mode)
- [ ] 7.6 Test signal handling (Ctrl+C during execution)
- [ ] 7.7 Verify `--verify` mode works correctly
- [ ] 7.8 Update README with any changed behaviors

