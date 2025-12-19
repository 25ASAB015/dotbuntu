# Crixus - Professional Git & GitHub Configuration Tool

Crixus is an interactive Bash script that automates the professional configuration of Git and GitHub on Linux systems. It streamlines the developer onboarding process by generating SSH keys, GPG keys, configuring Git settings, and integrating with GitHub CLI.

## 🏗️ Architecture

Crixus follows the **dotbare-style modular architecture** pattern, inspired by the [dotbare](https://github.com/kazhala/dotbare) repository. This modular structure provides:

- **Improved maintainability**: Single-responsibility modules are easier to understand and modify
- **Better testability**: Isolated modules can be unit tested independently
- **Cleaner organization**: Clear separation of concerns with consistent documentation
- **Industry standard**: Well-established, community-vetted pattern for organizing Bash scripts
- **Easier onboarding**: Developers familiar with dotbare will immediately understand the codebase

## 📁 Directory Structure

```
.
├── gitconfig.sh                 # Main entry point (orchestrator)
├── config/
│   ├── defaults.sh              # Global variables and default configuration
│   └── templates/
│       ├── gitconfig.template   # Template for .gitconfig generation
│       └── gitmessage.template  # Template for .gitmessage generation
└── scripts/
    ├── core/                     # Core utilities (foundational)
    │   ├── colors.sh            # Color system and helpers (c, cr)
    │   ├── logger.sh            # Logging system
    │   ├── validation.sh        # Validations (email, etc.)
    │   ├── ui.sh                # Interface functions (spinner, progress, logo)
    │   └── common.sh            # Common auxiliary functions
    ├── dependencies.sh          # Dependency checking and installation
    ├── ssh.sh                   # SSH key generation and configuration
    ├── gpg.sh                   # GPG key generation and configuration
    ├── git-config.sh            # Git configuration and .gitconfig generation
    ├── github.sh                # GitHub CLI integration (upload keys)
    └── finalize.sh              # Final summary, instructions, connectivity test
```

## 🔄 Module Loading Order

Modules are loaded in a specific order to respect dependencies:

1. **Configuration** (`config/defaults.sh`) - Loaded first, defines all global state
2. **Core utilities** (in order):
   - `colors.sh` - No dependencies
   - `logger.sh` - Uses colors
   - `validation.sh` - Uses colors, logger
   - `ui.sh` - Uses colors, logger
   - `common.sh` - Uses colors, ui
3. **Feature modules** (any order, all depend on core):
   - `dependencies.sh`
   - `ssh.sh`
   - `gpg.sh`
   - `git-config.sh`
   - `github.sh`
   - `finalize.sh`

## 📦 Module Descriptions

### Configuration Layer

#### `config/defaults.sh`
Centralized configuration file that defines all global variables:
- Script directories (`SCRIPT_DIR`, `BACKUP_DIR`, `LOG_FILE`)
- Behavior flags (`DEBUG`, `INTERACTIVE_MODE`, `AUTO_UPLOAD_KEYS`)
- State variables (`SSH_KEY_UPLOADED`, `GPG_KEY_UPLOADED`, `GH_INSTALL_ATTEMPTED`)
- User data (`USER_EMAIL`, `USER_NAME`, `GPG_KEY_ID`, `GENERATE_GPG`)
- Progress tracking (`TOTAL_STEPS`, `CURRENT_STEP`, `WORKFLOW_STEPS`)
- Color definitions (`COLORS` associative array)

### Core Utilities (`scripts/core/`)

#### `colors.sh`
Color output utilities for terminal display:
- `c(color_name)` - Get color escape code by name
- `cr()` - Get reset escape code
- `check_unicode_support()` - Check if terminal supports Unicode
- `get_symbol(unicode, ascii)` - Get appropriate symbol based on Unicode support

**Dependencies:** None (loaded first)

#### `logger.sh`
Logging system for script operations:
- `log(message)` - Write message to log file with timestamp

**Dependencies:** `colors.sh`

#### `validation.sh`
Input validation functions:
- `validate_email(email)` - Validate email format
- `initial_checks()` - Perform initial system checks (root user, etc.)

**Dependencies:** `colors.sh`, `logger.sh`

#### `ui.sh`
User interface utilities:
- `logo()` - Display ASCII art logo
- `welcome()` - Display welcome message
- `show_separator()` - Display separator line
- `success(message)`, `error(message)`, `warning(message)`, `info(message)` - Message helpers
- `show_spinner(pid, message)` - Display spinner animation
- `show_progress_bar(current, total, message)` - Display progress bar
- `ask_yes_no(prompt, default, exit_on_no)` - Yes/No prompt
- `read_input(prompt, default, var_name)` - Read user input

**Dependencies:** `colors.sh`, `logger.sh`

#### `common.sh`
Common auxiliary functions:
- `detect_os()` - Detect operating system (Linux, Darwin, etc.)
- `copy_to_clipboard(file)` - Copy file contents to clipboard
- `setup_directories()` - Create necessary directories

**Dependencies:** `colors.sh`, `ui.sh`

### Feature Modules (`scripts/`)

#### `dependencies.sh`
Dependency checking and installation:
- `check_dependencies()` - Check for required commands (git, ssh-keygen, gpg, etc.)
- `auto_install_dependencies()` - Automatically install missing dependencies (if supported)

**Dependencies:** Core utilities

#### `ssh.sh`
SSH key generation and configuration:
- `backup_existing_keys()` - Backup existing SSH keys before generation
- `generate_ssh_key()` - Generate Ed25519 SSH key pair
- `create_ssh_agent_script()` - Create ssh-agent configuration script

**Dependencies:** Core utilities

#### `gpg.sh`
GPG key generation and configuration:
- `generate_gpg_key()` - Generate GPG key for commit signing
- `generate_gpg_key_alternative()` - Fallback GPG key generation method
- `setup_gpg_environment()` - Setup GPG environment variables
- `cleanup_gpg_processes()` - Clean up blocked GPG processes

**Dependencies:** Core utilities

#### `git-config.sh`
Git configuration and .gitconfig generation:
- `collect_user_info()` - Collect user name and email
- `configure_git()` - Main Git configuration function
- `generate_gitconfig()` - Generate .gitconfig file
- `create_commit_template()` - Create .gitmessage template
- `show_changes_summary()` - Preview changes before applying
- `cleanup_credential_duplicates()` - Remove duplicate credential helper entries

**Dependencies:** Core utilities

#### `github.sh`
GitHub CLI integration:
- `ensure_github_cli_ready()` - Verify GitHub CLI is installed and authenticated
- `show_manual_gh_install_instructions()` - Display manual installation instructions
- `upload_ssh_key_to_github()` - Upload SSH key to GitHub
- `upload_gpg_key_to_github()` - Upload GPG key to GitHub
- `maybe_upload_keys()` - Orchestrate key upload process

**Dependencies:** Core utilities

#### `finalize.sh`
Final summary, instructions, and connectivity test:
- `display_keys()` - Display generated SSH and GPG keys
- `save_keys_to_files()` - Export keys to files for manual upload
- `test_github_connection()` - Test SSH connectivity with GitHub
- `show_final_instructions()` - Display final setup instructions
- `run_verification_suite()` - Comprehensive post-installation verification of all configured components

**Dependencies:** Core utilities

## 🚀 Usage

### Basic Usage

```bash
# Interactive mode (default)
./gitconfig.sh

# Non-interactive mode (requires USER_EMAIL and USER_NAME)
USER_EMAIL="user@example.com" USER_NAME="John Doe" ./gitconfig.sh --non-interactive

# Auto-upload keys to GitHub (requires GitHub CLI authentication)
./gitconfig.sh --auto-upload

# Show help
./gitconfig.sh --help
```

### Command-Line Options

- `--non-interactive`: Run without user prompts (requires `USER_EMAIL` and `USER_NAME` environment variables)
- `--auto-upload`: Automatically upload keys to GitHub using GitHub CLI (requires prior authentication)
- `--help`, `-h`: Show help information

### Environment Variables

- `INTERACTIVE_MODE`: Control interactive mode (`true`/`false`, default: `true`)
- `USER_EMAIL`: Git user email (required in non-interactive mode)
- `USER_NAME`: Git user name (required in non-interactive mode)
- `DEBUG`: Enable debug logging (`true`/`false`, default: `false`)

## 📝 Documentation Standard

All modules follow the **dotbare documentation standard**:

### File Header Format

```bash
#!/usr/bin/env bash
#==============================================================================
#                              MODULE_NAME
#==============================================================================
# @file module.sh
# @brief Brief description of the module
# @description
#   Detailed description of what the module provides.
#
# Globals:
#   ${VARIABLE1}: description of global variable it uses/modifies
#   ${VARIABLE2}: description of another global variable
#
# Arguments:
#   None (or list of command-line arguments if applicable)
#
# Returns:
#   0 - Always succeeds (or success condition)
#   1 - Failure condition (if applicable)
#==============================================================================
```

### Function Documentation Format

Each function includes inline documentation:

```bash
# @description Brief description of what the function does
# @param $1 param_name - Description of first parameter
# @param $2 param_name - Description of second parameter
# @return 0 on success, 1 on failure
# @example
#   function_name "arg1" "arg2"
function_name() {
    local param1="$1"
    local param2="$2"
    # implementation
}
```

## 🔧 Development

### Adding a New Module

1. Create the module file in the appropriate directory (`scripts/core/` or `scripts/`)
2. Add the dotbare-style header with complete documentation
3. Document all functions with inline comments
4. Add the module to the sourcing order in `gitconfig.sh`
5. Ensure all global variables are declared in `config/defaults.sh`

### Testing

Run ShellCheck on all modules:

```bash
shellcheck gitconfig.sh
shellcheck scripts/**/*.sh
```

### Module Dependencies

When creating a new module, ensure:
- All global variables are declared in `config/defaults.sh`
- Core utilities are loaded before feature modules
- Dependencies are clearly documented in the module header

## 📚 References

- [dotbare repository](https://github.com/kazhala/dotbare) - Pattern inspiration
- [Git Documentation](https://git-scm.com/doc)
- [GitHub CLI Documentation](https://cli.github.com/manual/)

## 📄 License

GPL-3.0

## 👤 Author

25asab015 <25asab015@ujmd.edu.sv>

