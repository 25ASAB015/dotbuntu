# Implementation Tasks

## Phase 1: Foundation - NIX Support (Week 1)

### 1.1 Create packages.nix Template
- [ ] 1.1.1 Create `packages.nix` with current CORE_DEPENDENCIES equivalents
- [ ] 1.1.2 Add DEFAULT_EXTRA_DEPENDENCIES equivalents from setup.conf
- [ ] 1.1.3 Include language servers and dev tools
- [ ] 1.1.4 Test packages.nix syntax with `nix-instantiate --eval`
- [ ] 1.1.5 Verify all packages exist in nixpkgs with `nix search`

### 1.2 Implement NIX Installation Script
- [ ] 1.2.1 Create `scripts/bootstrap-nix.sh` with shebang and strict mode
- [ ] 1.2.2 Add detection for existing NIX installation
- [ ] 1.2.3 Implement Determinate Systems installer method
- [ ] 1.2.4 Implement official NIX installer method
- [ ] 1.2.5 Implement distro package method (pacman for Arch)
- [ ] 1.2.6 Add interactive menu for installation method selection
- [ ] 1.2.7 Test on Ubuntu (no NIX) and Arch (with/without NIX)

### 1.3 Create Package Sync Script
- [ ] 1.3.1 Create `scripts/sync-packages.sh` 
- [ ] 1.3.2 Implement `nix-env -iA` command construction
- [ ] 1.3.3 Add error handling and logging
- [ ] 1.3.4 Make script idempotent (safe to run multiple times)
- [ ] 1.3.5 Add success/failure reporting with package counts

### 1.4 Add NIX Helper Module
- [ ] 1.4.1 Create `helper/nix-helpers.sh`
- [ ] 1.4.2 Add function: `nix_is_installed()` - check if NIX available
- [ ] 1.4.3 Add function: `nix_get_version()` - get NIX version
- [ ] 1.4.4 Add function: `nix_package_installed()` - check package status
- [ ] 1.4.5 Add function: `nix_cleanup()` - garbage collection helper

### 1.5 Integrate with Main Entry Point
- [ ] 1.5.1 Add `--nix` flag to `dotbuntu` CLI argument parser
- [ ] 1.5.2 Conditional execution: if `--nix`, call bootstrap-nix → sync-packages
- [ ] 1.5.3 Keep default behavior unchanged (old package managers)
- [ ] 1.5.4 Add help text for `--nix` flag

### 1.6 Documentation - NIX Setup Guide
- [ ] 1.6.1 Create `docs/NIX_SETUP.md` with introduction
- [ ] 1.6.2 Document installation methods (Determinate, official, distro)
- [ ] 1.6.3 Add packages.nix format explanation with examples
- [ ] 1.6.4 Include troubleshooting section
- [ ] 1.6.5 Add FAQ (disk space, uninstall, package not found)

### 1.7 Testing Phase 1
- [ ] 1.7.1 Test `--nix` flag on clean Ubuntu 22.04
- [ ] 1.7.2 Test `--nix` flag on clean Arch Linux
- [ ] 1.7.3 Test with existing NIX installation
- [ ] 1.7.4 Verify packages.nix installs all expected packages
- [ ] 1.7.5 Confirm old method still works (no regression)

## Phase 2: Integration with dotbare (Week 2)

### 2.1 Update dotbare Integration
- [ ] 2.1.1 Modify `fdotbare` to suggest adding packages.nix to repo
- [ ] 2.1.2 Add template packages.nix to dotbare initialization
- [ ] 2.1.3 Update dotbare workflow docs to include packages.nix

### 2.2 Unified Install Script
- [ ] 2.2.1 Refactor `install.sh` to orchestrate NIX + dotbare
- [ ] 2.2.2 Add interactive prompts: install NIX? clone dotfiles? 
- [ ] 2.2.3 Handle first-time setup vs existing installation
- [ ] 2.2.4 Add progress indicators for each step
- [ ] 2.2.5 Implement error recovery (retry/skip/abort options)

### 2.3 Package Sync on Pull
- [ ] 2.3.1 Create hook suggestion: sync-packages after `dotbare pull`
- [ ] 2.3.2 Add `--auto-sync` option to apply packages.nix changes automatically
- [ ] 2.3.3 Document manual sync workflow

### 2.4 Migration Guide
- [ ] 2.4.1 Create `docs/MIGRATION.md`
- [ ] 2.4.2 Document step-by-step migration from v1.x
- [ ] 2.4.3 Add setup.conf → packages.nix conversion examples
- [ ] 2.4.4 Include rollback instructions (how to return to v1.x)
- [ ] 2.4.5 Add troubleshooting for common migration issues

### 2.5 Conversion Helper Script
- [ ] 2.5.1 Create `scripts/convert-setup-conf.sh`
- [ ] 2.5.2 Parse setup.conf arrays (EXTRA_DEPENDENCIES, etc.)
- [ ] 2.5.3 Map known packages to nixpkgs equivalents
- [ ] 2.5.4 Output packages.nix format
- [ ] 2.5.5 Add warnings for unmapped packages

### 2.6 Testing Phase 2
- [ ] 2.6.1 Test full workflow: install NIX → clone dotfiles → apply packages
- [ ] 2.6.2 Test packages.nix versioning in dotbare repo
- [ ] 2.6.3 Test sync after modifying packages.nix
- [ ] 2.6.4 Test conversion script with real setup.conf files
- [ ] 2.6.5 Beta test with 2-3 external users

## Phase 3: Transition to NIX Default (Week 3)

### 3.1 Make NIX Default Method
- [ ] 3.1.1 Swap default: NIX is default, add `--legacy` flag for old method
- [ ] 3.1.2 Add deprecation warnings to legacy package installers
- [ ] 3.1.3 Update `--help` output to promote NIX method
- [ ] 3.1.4 Show migration guide link when using `--legacy`

### 3.2 Move Legacy Code
- [ ] 3.2.1 Create `scripts/legacy/` directory
- [ ] 3.2.2 Move `fdeps`, `faur`, `fchaotic`, `fchaotic-deps` to legacy/
- [ ] 3.2.3 Move language-specific installers (fnpm, fcargo, etc.) to legacy/
- [ ] 3.2.4 Keep scripts executable but mark as deprecated in headers
- [ ] 3.2.5 Update any imports/references to legacy scripts

### 3.3 Simplify Configuration
- [ ] 3.3.1 Update `config/defaults.sh` - remove package-related vars
- [ ] 3.3.2 Keep only: DOTBARE_*, REPO_URL, ERROR_LOG, SETUP_CONFIG
- [ ] 3.3.3 Update `helper/set_variable.sh` similarly
- [ ] 3.3.4 Add PACKAGES_NIX_PATH variable

### 3.4 Remove Distribution Detection
- [ ] 3.4.1 Archive `helper/package_manager.sh` (no longer needed)
- [ ] 3.4.2 Remove distro detection from checks.sh if present
- [ ] 3.4.3 Update any code that called package_manager functions
- [ ] 3.4.4 Verify no broken imports

### 3.5 Update Main Documentation
- [ ] 3.5.1 Rewrite README.md with NIX-first approach
- [ ] 3.5.2 Update installation instructions
- [ ] 3.5.3 Update usage examples (show packages.nix workflow)
- [ ] 3.5.4 Add "Why NIX?" section explaining benefits
- [ ] 3.5.5 Link to NIX_SETUP.md and MIGRATION.md

### 3.6 Architecture Documentation
- [ ] 3.6.1 Create `docs/ARCHITECTURE.md`
- [ ] 3.6.2 Document NIX + dotbare separation of concerns
- [ ] 3.6.3 Explain package installation flow
- [ ] 3.6.4 Document configuration file locations
- [ ] 3.6.5 Add diagrams (ASCII art or mermaid)

### 3.7 Testing Phase 3
- [ ] 3.7.1 Full integration test on Arch (NIX default)
- [ ] 3.7.2 Full integration test on Ubuntu (NIX default)
- [ ] 3.7.3 Test `--legacy` flag still works
- [ ] 3.7.4 Verify no code references to removed files
- [ ] 3.7.5 Run shellcheck on all modified scripts

## Phase 4: Polish and Release (Week 4)

### 4.1 Comprehensive Testing
- [ ] 4.1.1 Test on fresh Ubuntu 20.04, 22.04, 24.04
- [ ] 4.1.2 Test on fresh Arch Linux
- [ ] 4.1.3 Test on Debian 11, 12
- [ ] 4.1.4 Test with different shells (bash, zsh)
- [ ] 4.1.5 Test uninstall and reinstall flow

### 4.2 Error Handling and UX
- [ ] 4.2.1 Review all error messages for clarity
- [ ] 4.2.2 Add helpful suggestions to error messages
- [ ] 4.2.3 Ensure progress indicators work correctly
- [ ] 4.2.4 Test interruption handling (Ctrl+C)
- [ ] 4.2.5 Verify logging to ERROR_LOG is complete

### 4.3 Documentation Polish
- [ ] 4.3.1 Proofread all documentation (spelling, grammar)
- [ ] 4.3.2 Add code examples to every doc section
- [ ] 4.3.3 Create quick start guide (1-page, 5 minutes)
- [ ] 4.3.4 Update CHANGELOG with all changes
- [ ] 4.3.5 Create upgrade guide (v1.x → v2.0.0)

### 4.4 Demo Materials
- [ ] 4.4.1 Create animated GIF: fresh install flow
- [ ] 4.4.2 Create animated GIF: sync packages workflow
- [ ] 4.4.3 Add GIFs to README.md
- [ ] 4.4.4 Optional: Create 2-minute demo video
- [ ] 4.4.5 Take screenshots for documentation

### 4.5 Release Preparation
- [ ] 4.5.1 Update version to 2.0.0 in all files
- [ ] 4.5.2 Create comprehensive release notes
- [ ] 4.5.3 Tag v2.0.0-rc1 for release candidate testing
- [ ] 4.5.4 Beta test release candidate for 3-5 days
- [ ] 4.5.5 Address any critical bugs from RC

### 4.6 Release
- [ ] 4.6.1 Merge `feat/nix-dotbare` to `master`
- [ ] 4.6.2 Create GitHub release v2.0.0
- [ ] 4.6.3 Attach any binary artifacts (if applicable)
- [ ] 4.6.4 Announce on GitHub discussions
- [ ] 4.6.5 Update social media / project website

### 4.7 Post-Release Monitoring
- [ ] 4.7.1 Monitor GitHub issues for bug reports (first 2 weeks)
- [ ] 4.7.2 Collect user feedback on NIX transition
- [ ] 4.7.3 Update FAQ based on common questions
- [ ] 4.7.4 Plan v2.1.0 improvements based on feedback
- [ ] 4.7.5 Schedule legacy code removal for v3.0.0 (3 months)

## Validation Tasks (Ongoing)

### Continuous Validation
- [ ] Run `shellcheck` on all modified shell scripts
- [ ] Run `shfmt -d` to check formatting
- [ ] Test on both Arch and Ubuntu after each phase
- [ ] Update documentation as implementation evolves
- [ ] Keep CHANGELOG.md updated with each task completion

## Dependencies

**Sequential dependencies:**
- 1.1-1.5 must complete before 1.7 (testing)
- Phase 1 must complete before Phase 2
- Phase 2 must complete before Phase 3
- 2.4 (Migration guide) needed before 3.1 (making NIX default)

**Parallel work opportunities:**
- Documentation tasks (1.6, 2.4, 3.5, 3.6) can be done in parallel with implementation
- Testing can start as soon as related implementation completes
- Demo materials (4.4) can be created alongside Phase 3 work

## Estimated Effort

- Phase 1: 8-12 hours (foundational work)
- Phase 2: 6-8 hours (integration)
- Phase 3: 4-6 hours (cleanup, mostly deletion)
- Phase 4: 6-8 hours (testing, polish, release)

**Total**: ~24-34 hours over 4 weeks (1 week per phase)

