# 🔧 Testing Tools

This directory contains standalone testing tools for the `gitconfig.sh` script. These tools allow you to test and verify individual components and functions without running the full installation process.

## 📋 Available Tools

### `test_verification.sh`

A flexible testing tool that allows you to test **any function** from the project by loading all necessary modules and executing the specified function.

#### Features

- **Test any function**: Execute any function from the project
- **Automatic module loading**: All project modules are loaded automatically
- **Function validation**: Verifies that the function exists before execution
- **Default function**: Runs `run_verification_suite` by default if no function is specified
- **Standalone execution**: No need to run the full installation script

#### Usage

```bash
# Show help
./tools/test_verification.sh --help

# Test default function (run_verification_suite)
./tools/test_verification.sh

# Test with auto mode (no confirmation)
./tools/test_verification.sh --auto

# Test specific function
./tools/test_verification.sh check_dependencies
./tools/test_verification.sh --auto check_optional_dependencies
./tools/test_verification.sh --auto test_github_connection

# List all available functions
./tools/test_verification.sh --list
```

#### Options

| Option | Description |
|--------|-------------|
| `--auto` | Execute without waiting for confirmation |
| `--help`, `-h` | Show help message |
| `--list`, `-l` | List all available functions |
| `function_name` | Name of the function to test |

**Note:** If no function is specified, `run_verification_suite` is executed by default.

#### Environment Variables

You can set these environment variables to customize the testing:

```bash
export USER_NAME="Your Name"
export USER_EMAIL="your.email@example.com"
export GPG_KEY_ID="YOUR_GPG_KEY_ID"
export LOG_FILE="/path/to/log/file.log"

./tools/test_verification.sh check_dependencies
```

#### Examples

**Test default verification suite:**
```bash
./tools/test_verification.sh
# or with auto mode:
./tools/test_verification.sh --auto
```

**Test dependency checking:**
```bash
./tools/test_verification.sh --auto check_dependencies
./tools/test_verification.sh --auto check_optional_dependencies
```

**Test GitHub connectivity:**
```bash
./tools/test_verification.sh --auto test_github_connection
```

**Test Git configuration:**
```bash
./tools/test_verification.sh --auto configure_git
```

**List all available functions:**
```bash
./tools/test_verification.sh --list
```

## 🎯 Use Cases

### Development

When developing new features or fixing bugs, use this tool to quickly test specific functions:

```bash
# After modifying dependency checking
./tools/test_verification.sh --auto check_dependencies

# After modifying Git configuration
./tools/test_verification.sh --auto configure_git

# After modifying SSH key generation
./tools/test_verification.sh --auto generate_ssh_key
```

### Debugging

When troubleshooting issues, test functions individually:

```bash
# Check dependencies
./tools/test_verification.sh --auto check_dependencies

# Check GitHub connectivity
./tools/test_verification.sh --auto test_github_connection

# Check SSH agent
./tools/test_verification.sh --auto start_ssh_agent
```

### CI/CD

Use in automated testing pipelines:

```bash
# Non-interactive verification
./tools/test_verification.sh --auto run_verification_suite
```

### Function Discovery

Explore available functions:

```bash
# List all functions
./tools/test_verification.sh --list

# Test a function you found
./tools/test_verification.sh --auto function_name
```

## 📝 Output Format

The tool provides color-coded output:

- ✅ **Green (✓)**: Function executed successfully
- ⚠️ **Yellow (⚠)**: Function returned non-zero exit code (may be normal)
- ❌ **Red (✗)**: Error occurred

The output includes:
- Configuration information (USER_NAME, USER_EMAIL, etc.)
- Function execution results
- Exit code information

## 🔍 Available Functions

### Verification Functions
- `run_verification_suite` - Full post-installation verification
- `check_dependencies` - Check required dependencies
- `check_optional_dependencies` - Check optional dependencies
- `test_github_connection` - Test GitHub SSH connectivity

### Configuration Functions
- `collect_user_info` - Collect user information
- `configure_git` - Configure Git settings
- `generate_gitconfig` - Generate .gitconfig file

### SSH Functions
- `generate_ssh_key` - Generate SSH key pair
- `start_ssh_agent` - Start SSH agent
- `create_ssh_agent_script` - Create SSH agent script

### GPG Functions
- `generate_gpg_key` - Generate GPG key
- `setup_gpg_environment` - Setup GPG environment
- `cleanup_gpg_processes` - Cleanup GPG processes

### GitHub Functions
- `ensure_github_cli_ready` - Ensure GitHub CLI is ready
- `upload_ssh_key_to_github` - Upload SSH key to GitHub
- `upload_gpg_key_to_github` - Upload GPG key to GitHub
- `maybe_upload_keys` - Conditionally upload keys

### UI Functions
- `logo` - Display ASCII logo
- `welcome` - Display welcome message
- `show_help` - Show help information
- `display_keys` - Display key information
- `show_final_instructions` - Show final instructions

**Note:** Use `--list` to see all available functions.

## 🚀 Quick Start

1. **Test default verification suite:**
   ```bash
   ./tools/test_verification.sh --auto
   ```

2. **Test a specific function:**
   ```bash
   ./tools/test_verification.sh --auto check_dependencies
   ```

3. **Discover available functions:**
   ```bash
   ./tools/test_verification.sh --list
   ```

4. **Get help:**
   ```bash
   ./tools/test_verification.sh --help
   ```

## 💡 Tips

- Use `--auto` flag for non-interactive testing
- Set environment variables to test with specific configurations
- Use `--list` to discover all available functions
- Check the log file for detailed information
- Some functions may return non-zero exit codes in normal operation (e.g., `run_verification_suite`)

## 📚 Related Documentation

- Main script: `./gitconfig.sh --help`
- Project README: `./README.md`
- OpenSpec: `./openspec/`
