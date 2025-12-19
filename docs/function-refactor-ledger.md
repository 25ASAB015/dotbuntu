# Dotbuntu Function Refactor Ledger

> **Purpose**: This ledger is the single source of truth for tracking all functions from both source repositories (gitconfig and dotmarchy). Every function must be registered and classified before implementation or modification.

## Legend
- 🟢 MERGED      → Unified implementation in final codebase
- 🔵 KEPT        → Preserved as-is (no equivalent found)
- 🟡 REWRITTEN   → Logic preserved, implementation improved
- 🟠 RENAMED     → Function renamed for clarity/consistency
- 🔴 DELETED     → Redundant or obsolete
- ⚫ IGNORED     → Intentionally not migrated (with reason)
- 🟣 DEFERRED    → To be addressed in a later phase

---

## 🔴 Critical Issues (Blocking Quality Standards)

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

---

## Complete Function Inventory

### Entrypoint: dotbuntu

| Function Name | Status | Notes |
|---------------|--------|-------|
| `main` | 🟡 REWRITTEN | Merged from gitconfig + dotmarchy; needs docblock |
| `parse_arguments` | 🔵 KEPT | Handles all merged CLI flags |
| `show_help` | 🔵 KEPT | Displays unified help |
| `cleanup` | 🔵 KEPT | Signal handler for SIGINT/SIGTERM |

### Module: helper/colors.sh

| Function Name | Status | Final Name | Notes |
|---------------|--------|------------|-------|
| (exports only) | 🔵 KEPT | — | Exports $CRE, $CYE, $CGR, $CBL, $BLD, $CNC |

### Module: helper/logger.sh

| Function Name | Repository | Status | Final Name | Notes |
|---------------|------------|--------|------------|-------|
| `get_timestamp` | helper | 🔵 KEPT | `get_timestamp` | ISO 8601 format |
| `get_error_log_path` | helper | 🔵 KEPT | `get_error_log_path` | Returns ERROR_LOG path |
| `is_verbose_enabled` | helper | 🔵 KEPT | `is_verbose_enabled` | Checks VERBOSE flag |
| `log` | helper | 🟢 MERGED | `log` | Plain output; CONFLICT with core/logger.sh |
| `info` | helper | 🟢 MERGED | `info` | Blue formatted; CONFLICT with core/logger.sh |
| `print_info` | helper | 🔴 DELETED | — | Alias for info(); redundant |
| `warn` | helper | 🔵 KEPT | `warn` | Yellow formatted warning |
| `debug` | helper | 🟢 MERGED | `debug` | Verbose-only output; CONFLICT |
| `write_to_error_log` | helper | 🔵 KEPT | `write_to_error_log` | Internal function |
| `display_error_to_user` | helper | 🔵 KEPT | `display_error_to_user` | Internal function |
| `log_error` | helper | 🔵 KEPT | `log_error` | Red error to file + stderr |
| `get_error_context` | helper | 🔵 KEPT | `get_error_context` | For on_error trap |
| `on_error` | helper | 🔵 KEPT | `on_error` | ERR trap handler |

### Module: helper/utils.sh

| Function Name | Status | Notes |
|---------------|--------|-------|
| `run` | 🔵 KEPT | Execute with timing and dry-run support |
| `require_cmd` | 🔵 KEPT | Verify command exists |
| `normalize_repo_url` | 🔵 KEPT | URL normalization |
| `ssh_to_https` | 🔵 KEPT | Convert SSH URL to HTTPS |
| `check_ssh_auth` | 🔵 KEPT | Test GitHub SSH auth |
| `get_nvm_dir` | 🔵 KEPT | NVM directory location |
| `preflight_utils` | 🔵 KEPT | Check required utilities |
| `ensure_node_available` | 🔵 KEPT | Install/verify Node.js >= 18 |
| `dotbuntu_usage` | 🟠 RENAMED | From dotmarchy_usage; needs docblock |
| `parse_arguments` | 🔵 KEPT | CLI argument parsing |
| `dotmarchy_parse_arguments` | 🔴 DELETED | Backward-compat alias; use parse_arguments |
| `initialize_error_log` | 🔵 KEPT | Reset error log file |
| `execute_core_script` | 🔵 KEPT | Run core script with error handling |
| `execute_extras_script` | 🔵 KEPT | Run extras script |
| `execute_setup_script` | 🔵 KEPT | Run setup script |
| `configure_dotbare` | 🔵 KEPT | Critical dotbare setup |
| `execute_core_operations` | 🔵 KEPT | Core installation flow |
| `execute_extras_operations` | 🔵 KEPT | Extras installation |
| `execute_setup_operations` | 🔵 KEPT | Environment setup |
| `run_verification_mode` | 🔵 KEPT | Verification mode handler |

### Module: helper/checks.sh

| Function Name | Status | Final Name | Notes |
|---------------|--------|------------|-------|
| `is_running_as_root` | 🔵 KEPT | `is_running_as_root` | Returns 0 if root |
| `verify_not_root` | 🔵 KEPT | `verify_not_root` | Exits if root |
| `has_internet_connection` | 🔵 KEPT | `has_internet_connection` | Ping check |
| `verify_internet_connection` | 🔵 KEPT | `verify_internet_connection` | Exits if no internet |
| `is_package_installed` | 🔵 KEPT | `is_package_installed` | Multi-distro package check |
| `is_installed` | 🔴 DELETED | — | Deprecated alias; use is_package_installed |

### Module: helper/prompts.sh

| Function Name | Status | Final Name | Notes |
|---------------|--------|------------|-------|
| `show_logo` | 🔵 KEPT | `show_logo` | ASCII art with message |
| `show_welcome` | 🔵 KEPT | `show_welcome` | Welcome screen |
| `show_farewell` | 🔵 KEPT | `show_farewell` | Final summary |
| `load_setup_configuration_once` | 🔵 KEPT | — | Internal |
| `count_words` | 🔵 KEPT | — | Internal |
| `calculate_core_count` | 🔵 KEPT | — | Internal |
| `calculate_extra_totals` | 🔵 KEPT | — | Internal |
| `calculate_setup_counts` | 🔵 KEPT | — | Internal |
| `clear_screen` | 🔵 KEPT | — | Internal |
| `show_welcome_intro` | 🔵 KEPT | — | Internal |
| `show_basic_operations` | 🔵 KEPT | — | Internal |
| `show_extras_section` | 🔵 KEPT | — | Internal |
| `show_setup_section` | 🔵 KEPT | — | Internal |
| `show_safety_section` | 🔵 KEPT | — | Internal |
| `prompt_user_confirmation` | 🔵 KEPT | — | Internal |
| `format_repo_name` | 🔵 KEPT | — | Internal |
| `print_farewell_banner` | 🔵 KEPT | — | Internal |
| `print_completion_header` | 🔵 KEPT | — | Internal |
| `print_operation_summary` | 🔵 KEPT | — | Internal |
| `print_next_steps` | 🔵 KEPT | — | Internal |
| `print_resources` | 🔵 KEPT | — | Internal |
| `dotmarchy_logo` | 🔴 DELETED | — | Deprecated alias; use show_logo |
| `dotmarchy_welcome` | 🔴 DELETED | — | Deprecated alias; use show_welcome |
| `dotmarchy_farewell` | 🔴 DELETED | — | Deprecated alias; use show_farewell |

### Module: helper/set_variable.sh

| Variable/Function | Status | Notes |
|-------------------|--------|-------|
| (exports only) | 🟣 DEFERRED | Merge with config/defaults.sh; currently duplicates |

### Module: helper/load_helpers.sh

| Function Name | Status | Notes |
|---------------|--------|-------|
| `_loader_error` | 🔵 KEPT | Internal error function |
| `load_helpers` | 🔵 KEPT | Dynamic helper loader |
| `load_core_helpers` | 🔵 KEPT | Load core helper set |
| `load_extras_helpers` | 🔵 KEPT | Load extras helper set |

### Module: helper/compat.sh

| Function Name | Status | Notes |
|---------------|--------|-------|
| `success` | 🔵 KEPT | Bridge function from core/logger |
| `error` | 🔵 KEPT | Bridge function from core/logger |
| `warning` | 🔵 KEPT | Bridge function; aliases warn |
| `warn` | 🔵 KEPT | Bridge if not defined |
| `c` | 🔵 KEPT | Color function wrapper |
| `cr` | 🔵 KEPT | Color reset wrapper |
| `show_separator` | 🔵 KEPT | Horizontal line |

### Module: helper/package_manager.sh

| Function Name | Status | Notes |
|---------------|--------|-------|
| `detect_package_manager` | 🟢 MERGED | CONFLICT with scripts/core/common.sh:detect_os |
| `pkg_get_manager` | 🔵 KEPT | Cached manager detection |
| `pkg_map_name` | 🔵 KEPT | Cross-distro package mapping |
| `is_pkg_installed` | 🔵 KEPT | Check package installation |
| `pkg_update` | 🔵 KEPT | Update package database |
| `pkg_upgrade` | 🔵 KEPT | Upgrade all packages |
| `pkg_install` | 🔵 KEPT | Install packages |
| `pkg_install_silent` | 🔵 KEPT | Silent install |
| `is_arch_based` | 🔵 KEPT | Distribution check |
| `is_debian_based` | 🔵 KEPT | Distribution check |
| `pkg_get_manager_name` | 🔵 KEPT | Human-readable name |

### Module: scripts/core/colors.sh

| Function Name | Status | Notes |
|---------------|--------|-------|
| `c` | 🟢 MERGED | Color code function; now in compat.sh bridge |
| `cr` | 🟢 MERGED | Color reset; now in compat.sh bridge |

### Module: scripts/core/logger.sh

| Function Name | Repository | Status | Final Name | Notes |
|---------------|------------|--------|------------|-------|
| `log` | core | 🟢 MERGED | — | CONFLICT: Delegate to helper/logger.sh |
| `success` | core | 🔵 KEPT | `success` | Green checkmark |
| `error` | core | 🔵 KEPT | `error` | Red error display |
| `warning` | core | 🟢 MERGED | — | Delegate to warn() |
| `info` | core | 🟢 MERGED | — | CONFLICT: Delegate to helper/logger.sh |
| `debug` | core | 🟢 MERGED | — | CONFLICT: Delegate to helper/logger.sh |

### Module: scripts/core/ui.sh

| Function Name | Status | Notes |
|---------------|--------|-------|
| `logo` | 🔵 KEPT | Crixus ASCII art |
| `show_spinner` | 🔵 KEPT | Animated spinner |
| `show_progress_bar` | 🔵 KEPT | Progress bar display |
| `ask_yes_no` | 🔵 KEPT | Y/N prompt with default |
| `read_input` | 🔵 KEPT | User input with prompt |
| `show_help` | 🟢 MERGED | Combined with dotbuntu show_help |
| `welcome` | 🔵 KEPT | Git phase welcome |

### Module: scripts/core/common.sh

| Function Name | Status | Notes |
|---------------|--------|-------|
| `detect_os` | 🟢 MERGED | CONFLICT with package_manager.sh |
| `copy_to_clipboard` | 🔵 KEPT | Cross-platform clipboard |
| `initial_checks` | 🔵 KEPT | Git phase checks |
| `setup_directories` | 🔵 KEPT | Create SSH/GPG dirs |
| `backup_existing_keys` | 🔵 KEPT | Backup SSH keys |

### Module: scripts/core/validation.sh

| Function Name | Status | Notes |
|---------------|--------|-------|
| `validate_email` | 🔵 KEPT | Email format validation |
| `validate_not_empty` | 🔵 KEPT | String not empty |
| `validate_file_exists` | 🔵 KEPT | File existence check |
| `validate_dir_exists` | 🔵 KEPT | Directory existence check |
| `validate_command_exists` | 🔵 KEPT | Command in PATH check |

---

## Summary Statistics

| Status | Count | Description |
|--------|-------|-------------|
| 🟢 MERGED | 12 | Unified implementations |
| 🔵 KEPT | 65+ | Preserved as-is |
| 🟡 REWRITTEN | 1 | Logic improved |
| 🟠 RENAMED | 1 | Name changed |
| 🔴 DELETED | 6 | Redundant/obsolete |
| 🟣 DEFERRED | 1 | Set variable merge |

---

## Conflict Resolution Required

| Functions | Locations | Resolution |
|-----------|-----------|------------|
| `log()`, `info()`, `debug()` | helper/logger.sh vs scripts/core/logger.sh | Make core/logger.sh delegate to helper/logger.sh |
| `detect_os()` vs `detect_package_manager()` | common.sh vs package_manager.sh | Keep both; different purposes (detect_os is more detailed) |
| `warn()` vs `warning()` | helper vs core | Standardize to `warn()`; warning() bridges to it |
