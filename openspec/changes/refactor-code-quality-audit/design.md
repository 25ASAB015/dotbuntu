# Design: Code Quality Audit and Refactor

## Context

The dotbuntu project merges two Bash repositories with different conventions:

1. **gitconfig** (Crixus): Uses `c()/cr()` color functions, `COLORS` associative array, `@description` style docblocks
2. **dotmarchy**: Uses `$CGR/$CRE/$CYE` color variables, `#######################################` docblock style, Spanish user messages

Both systems are currently loaded simultaneously via `compat.sh`, creating function name conflicts and inconsistent UX. The `docs/prompt.md` mandate requires a unified, professional standard.

## Goals / Non-Goals

### Goals
- Single, canonical implementation for each responsibility (logging, colors, prompts, checks)
- 100% docblock coverage using the mandatory template
- Elimination of duplicate globals and redundant code
- Clear, documented function ledger tracking all decisions
- Code that passes shellcheck without suppressions (where possible)

### Non-Goals
- Rewrite from scratch (this is surgical refactoring)
- Change user-facing Spanish messages
- Add new features beyond quality improvements
- Change CLI interface or flags

## Decisions

### Decision 1: Color System Unification
**Decision**: Keep both systems but make `helper/colors.sh` the canonical source; `compat.sh` provides `c()/cr()` wrappers that delegate to the color variables.

**Rationale**: The `c()/cr()` pattern is more readable in complex printf statements but requires a function call per color. The variable approach (`$CGR`) is faster and sufficient for most cases. Providing both via delegation avoids breaking existing code.

**Alternatives considered**:
- Replace all `$CGR` with `c(success)` calls → Too invasive, slower
- Remove `c()/cr()` entirely → Breaks `scripts/core/*.sh` files

### Decision 2: Logging Unification
**Decision**: Use `helper/logger.sh` as the canonical implementation; deprecate `scripts/core/logger.sh` and redirect its functions.

**Rationale**: `helper/logger.sh` has proper error log file support, timestamp formatting, and the `on_error` trap handler. The core logger is simpler but lacks these features.

**Implementation**:
- `scripts/core/logger.sh` becomes a thin shim that sources `helper/logger.sh` and adds any missing functions
- Functions like `success()`, `error()`, `warning()` are provided by `compat.sh`

### Decision 3: Docblock Standard
**Decision**: All functions MUST use the `#######################################` block format from `docs/prompt.md`.

**Template**:
```bash
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
function_name() {
    # Implementation
}
```

**Rationale**: The `@description` style in gitconfig is less structured and harder to parse consistently. The block format is explicit and self-documenting.

### Decision 4: Global Variable Centralization
**Decision**: `config/defaults.sh` becomes the single source for all configuration; `helper/set_variable.sh` is deprecated and merged.

**Rationale**: Currently both files define the same variables (DOTBARE_DIR, REPO_URL, etc.) with slightly different defaults. This creates confusion about which value is used.

**Migration**:
1. Merge all unique variables from `set_variable.sh` into `defaults.sh`
2. Make `set_variable.sh` a thin shim that sources `defaults.sh` (for backward compat)
3. Update load order so `defaults.sh` is always sourced first

### Decision 5: Function Naming Convention
**Decision**: Use `snake_case` for all functions; remove `dotmarchy_` prefixes except for backward-compat aliases.

**Rationale**: The `dotmarchy_` prefix was needed during merge but creates unnecessary verbosity. The project is now unified as dotbuntu.

**Migration**:
- `dotmarchy_usage()` → `dotbuntu_usage()` (with alias)
- `dotmarchy_parse_arguments()` → `parse_arguments()` (alias exists)
- `dotmarchy_logo()` → `show_logo()` (alias exists)

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Breaking existing scripts that source helpers | Keep all backward-compat aliases for at least one release |
| Function ledger becomes stale | Update ledger BEFORE each function change, not after |
| Shellcheck violations | Run `shellcheck --severity=warning` on all files in CI |
| Merge conflicts during refactor | Work function-by-function, commit after each module |

## Migration Plan

### Phase 1: Inventory (No code changes)
1. Create `docs/function-refactor-ledger.md` with complete function list
2. Classify each function (MERGED/KEPT/REWRITTEN/etc.)
3. Document dependencies between functions

### Phase 2: Documentation (Non-breaking)
1. Add/fix docblocks for all functions
2. Fix indentation (4 spaces)
3. Run shellcheck and fix warnings

### Phase 3: Consolidation (Breaking within modules)
1. Unify logging (helper/logger.sh canonical)
2. Unify colors (helper/colors.sh canonical + compat bridge)
3. Unify prompts (helper/prompts.sh absorbs ui.sh equivalents)
4. Unify checks (helper/checks.sh canonical)

### Phase 4: Globals (Potentially breaking)
1. Merge set_variable.sh into defaults.sh
2. Update all source statements
3. Remove duplicate declarations

### Phase 5: Cleanup
1. Remove deprecated functions
2. Remove dead code
3. Final shellcheck pass
4. Update README

## Open Questions

1. **Should we keep the dual-entrypoint pattern?** Currently `dotbuntu` is the main script. Should there be a `gitconfig` symlink for backward compatibility?

2. **Spanish vs English messages**: User-facing messages are in Spanish, but code/comments are in English. Should we add i18n support or continue with Spanish as the sole user language?

3. **Test strategy**: Beyond `--verify` mode, do we need a proper test suite? ShellSpec, Bats, or just shellcheck?

