# Dotbuntu Architectural Ledger

## 🔴 Critical Issues

### 1. DUPLICATE FUNCTIONS - Same Name, Different Implementations

| Function | Location 1 | Location 2 | Action |
|----------|-----------|-----------|--------|
| `log()` | `helper/logger.sh:152` | `scripts/core/logger.sh:35` | **CONFLICT** - Different implementations |
| `info()` | `helper/logger.sh:172` | `scripts/core/logger.sh:82` | **CONFLICT** |
| `debug()` | `helper/logger.sh:234` | `scripts/core/logger.sh:92` | **CONFLICT** |
| `detect_os()` | `helper/package_manager.sh:78` | `scripts/core/common.sh:37` | **CONFLICT** |
| `is_installed()` | `helper/checks.sh:218` | (vs `is_pkg_installed`) | **CONFUSION** |
| `logo()` | `scripts/core/ui.sh:34` | `helper/prompts.sh:57` (dotmarchy_logo) | RENAMED - OK |

### 2. INCONSISTENT NAMING

| Current Name | Location | Issue | Proposed Name |
|--------------|----------|-------|---------------|
| `is_installed()` | `checks.sh` | Unclear - package? command? | `is_package_installed()` |
| `is_pkg_installed()` | `package_manager.sh` | Similar to above | Keep (more explicit) |
| `warn()` vs `warning()` | `logger.sh` vs `core/logger.sh` | Inconsistent | Standardize to `warn()` |
| `dotmarchy_*` functions | `prompts.sh` | Legacy naming | Consider removing prefix |

### 3. ORPHANED/DEAD CODE

| Function | Location | Issue |
|----------|----------|-------|
| `has_pacman()` | `checks.sh:181` | Unused, replaced by `pkg_get_manager()` |
| `verify_arch_linux()` | `checks.sh:197` | Unused after multi-distro refactor |
| `dotmarchy_initial_checks()` | `checks.sh:251` | Unused, replaced by inline checks |

---

## 🟡 Inconsistencies

### Error Handling Patterns

| File | Pattern | Issue |
|------|---------|-------|
| `fupdate` | `return 1` | ✅ Correct |
| `fdeps` | Mixed `return 1` and `exit 1` | ⚠️ Inconsistent |
| `fzsh` | `return 1` | ✅ Correct |
| `fdotbare` | `return 1` | ✅ Correct |

### Color/Logging Systems

**TWO SEPARATE SYSTEMS:**

1. **helper/colors.sh + helper/logger.sh**
   - Colors: `$CGR`, `$CRE`, `$CYE`, etc.
   - Functions: `info()`, `warn()`, `log_error()`

2. **scripts/core/colors.sh + scripts/core/logger.sh**
   - Colors: `COLORS` associative array with `c()` and `cr()` functions
   - Functions: `log()`, `success()`, `error()`, `warning()`

**ACTION REQUIRED:** Unify into single system

---

## 🟢 Well-Designed Functions

| Function | Location | Notes |
|----------|----------|-------|
| `pkg_*` family | `package_manager.sh` | Clean abstraction, good naming |
| `validate_*` family | `validation.sh` | Consistent pattern |
| `execute_*_script()` | `utils.sh` | Good modular design |
| `ask_yes_no()` | `ui.sh` | Well-documented, handles edge cases |

---

## Function Directory

### helper/package_manager.sh (NEW - Clean)
- `detect_package_manager()` ✅
- `pkg_get_manager()` ✅
- `pkg_map_name()` ✅
- `is_pkg_installed()` ✅
- `pkg_update()` ✅
- `pkg_upgrade()` ✅
- `pkg_install()` ✅
- `pkg_install_silent()` ✅
- `is_arch_based()` ✅
- `is_debian_based()` ✅
- `pkg_get_manager_name()` ✅

### helper/checks.sh (NEEDS CLEANUP)
- `is_running_as_root()` ✅
- `verify_not_root()` ✅
- `has_internet_connection()` ✅
- `verify_internet_connection()` ✅
- `has_pacman()` 🗑️ OBSOLETE
- `verify_arch_linux()` 🗑️ OBSOLETE
- `is_installed()` ⚠️ RENAME
- `dotmarchy_initial_checks()` 🗑️ OBSOLETE

### helper/logger.sh (DUPLICATES EXIST)
- `log()` ⚠️ DUPLICATE
- `info()` ⚠️ DUPLICATE
- `warn()` ✅
- `debug()` ⚠️ DUPLICATE
- `log_error()` ✅
- `on_error()` ✅

### scripts/core/common.sh (DUPLICATES EXIST)
- `detect_os()` ⚠️ DUPLICATE with package_manager.sh
- `copy_to_clipboard()` ✅
- `initial_checks()` ✅ (for git phase)
- `setup_directories()` ✅
- `backup_existing_keys()` ✅

---

## Refactoring Priority

### P0 - Critical (Before Testing)
1. Resolve duplicate `log()`, `info()`, `debug()` functions
2. Remove obsolete Arch-only functions from `checks.sh`
3. Unify `detect_os()` implementations

### P1 - Important
4. Standardize color/logging system
5. Rename `is_installed()` to avoid confusion
6. Clean up legacy `dotmarchy_` prefixes

### P2 - Nice to Have
7. Add consistent documentation headers
8. Improve error handling consistency
