# Legacy Scripts - Deprecated

This directory contains scripts that have been replaced by modern implementations.

## Status: DEPRECATED

These scripts are no longer used in the main dotmarchy installation process and will be removed in a future release.

## Replaced By

All functionality from these scripts has been integrated into:

- **`fmise`** - MISE package manager integration
- **`fmise-extras`** - Complementary tools and configurations

## Scripts List

| Script | Replaced By | Notes |
|--------|-------------|--------|
| `fnpm` | `fmise` | NPM packages now managed via MISE |
| `fcargo` | `fmise` + `fmise-extras` | Rust tools via MISE, setup via fmise-extras |
| `fpython` | `fmise` + `fmise-extras` | Python packages via MISE, PEP 668 via fmise-extras |
| `fruby` | `fmise` | Ruby gems now managed via MISE |
| `fgithub` | `fmise` + `fmise-extras` | GitHub tools via MISE, releases via fmise-extras |
| `fpath` | `fmise-extras` | PATH configuration now handled by fmise-extras |

## Development Scripts

| Script | Purpose | Notes |
|--------|---------|--------|
| `fmise.backup` | Backup of fmise | Historical reference |
| `fmise_improved.sh` | Development version | Superseded by current fmise |
| `fmise_master.sh` | Master development version | Used for feature integration |
| `fmise_master2.sh` | Alternative master version | Superseded by fmise_master.sh |

## Migration

If you were using any of these scripts directly, update your workflows to use:

```bash
# Instead of individual scripts:
./fnpm --force
./fcargo --force
./fgithub --force
# etc.

# Use the unified approach:
./fmise --force          # Core MISE packages
./fmise-extras --force   # Complementary tools
```

## Removal

These scripts will be completely removed in the next major release. Please migrate any custom usage before then.
