# Design: NIX + dotbare Architecture

## Context

**Problem**: Current system manages packages from 7+ sources (apt/pacman, AUR, Chaotic-AUR, cargo, npm, pipx, gem, GitHub) with distribution-specific logic causing maintainability issues and installation failures.

**Stakeholders**:
- Users: Need reliable, reproducible development environments
- Maintainers: Need simpler codebase with fewer edge cases
- Contributors: Need clear architecture to extend

**Constraints**:
- Must remain Linux-focused (Arch, Ubuntu, Debian primary targets)
- Must preserve existing dotbare workflow (users love it)
- Must provide migration path for existing users
- Bash-only implementation (no new language dependencies)

## Goals / Non-Goals

### Goals
1. **Single package source**: All packages via NIX (reproducible)
2. **Cross-distro consistency**: Same packages.nix works everywhere
3. **Code simplification**: Remove 60-70% of package management code
4. **Preserve dotbare**: Keep Git-based dotfiles workflow
5. **User-friendly**: Automated NIX installation, clear docs

### Non-Goals
- Supporting Windows (NIX support experimental)
- Replacing system package managers (apt/pacman remain for OS updates)
- Using Home Manager (adds complexity, dotbare sufficient)
- Migrating to NixOS (dotfiles tool, not distro)
- GUI package management

## Decisions

### Decision 1: NIX for Packages, dotbare for Dotfiles

**Rationale**: 
- NIX: 65,000+ packages, declarative, reproducible, cross-platform
- dotbare: Git-native workflow, already implemented, users familiar
- Clear separation of concerns (Unix Philosophy)

**Alternatives considered**:
- **Home Manager**: Rejected - adds complexity, mixes packages and configs, harder to learn
- **Keep current system**: Rejected - unsustainable maintenance burden
- **Docker containers**: Rejected - too heavyweight, doesn't fit dotfiles use case

**Implications**:
- Two tools to learn vs one (Home Manager) - acceptable trade-off for simplicity
- Package changes versioned in dotbare repo (bonus: full history)

### Decision 2: Determinate Systems Installer as Default

**Rationale**:
- Clean uninstallation (`nix-installer uninstall`)
- Better UX (clear messages, error handling)
- Flakes enabled by default (modern NIX)
- Professionally maintained

**Alternatives considered**:
- **Official installer**: Rejected as default - harder to uninstall, intimidates new users
- **Distro packages**: Rejected - outdated versions, additional config needed

**Implications**:
- Dependency on third-party installer (mitigated: still offer official as fallback)
- Users can uninstall easily if NIX doesn't fit their needs

### Decision 3: Gradual Migration (4-Phase Plan)

**Rationale**:
- Minimize disruption for existing users
- Allow testing and iteration
- Build confidence before full switchover

**Phases**:
1. **Week 1**: Add `--nix` flag (opt-in), old method still default
2. **Week 2**: Integrate NIX with dotbare (version packages.nix)
3. **Week 3**: Make NIX default, deprecate old method
4. **Week 4**: Polish, test, release v2.0.0

**Alternatives considered**:
- **Immediate switch**: Rejected - too risky, breaks existing users
- **Permanent dual support**: Rejected - doubles maintenance burden

**Implications**:
- Longer timeline (1 month vs 1 week)
- Need to maintain both systems temporarily
- Clear deprecation warnings needed

### Decision 4: packages.nix Location and Versioning

**Rationale**:
- Store in `~/.config/dotmarchy/packages.nix`
- Version in dotbare repository (part of dotfiles)
- Push/pull syncs packages AND configs

**Alternatives considered**:
- **Separate repo for packages**: Rejected - two repos to manage
- **In dotmarchy source**: Rejected - not user-customizable per machine

**Implications**:
- Users must commit packages.nix to their dotfiles repo
- Changes to package list show in Git history (good for debugging)

## Architecture

### Old System (Current)
```
User → dotbuntu → [fdeps, faur, fchaotic, fnpm, fcargo, fpipx, fgem, fgithub]
                   ↓         ↓        ↓       ↓       ↓      ↓     ↓       ↓
                  apt/    paru/   pacman   npm   cargo  pipx  gem   curl
                 pacman    AUR   Chaotic
```

### New System (Proposed)
```
User → dotbuntu → bootstrap-nix.sh → [Determinate/Official/Distro]
                   ↓
                   nix-env -iA nixpkgs.myPackages -f ~/.config/dotmarchy/packages.nix
                   ↓
                   65,000+ packages (cross-platform)
```

### Component Responsibilities

| Component | Responsibility | 
|-----------|----------------|
| `install.sh` | Main orchestrator - calls bootstrap-nix + fdotbare |
| `bootstrap-nix.sh` | Detect/install NIX (interactive method selection) |
| `sync-packages.sh` | Apply packages.nix (idempotent) |
| `packages.nix` | Declarative package list |
| `fdotbare` | dotbare setup (unchanged) |
| `fgit` | Git/GPG/SSH (unchanged) |
| `nix-helpers.sh` | NIX utility functions |

## Risks / Trade-offs

### Risk: Users Don't Know NIX
**Impact**: Medium  
**Mitigation**:
- Comprehensive `NIX_SETUP.md` documentation
- Automated `bootstrap-nix.sh` (minimal user input)
- Clear examples in packages.nix
- Link to official NIX learning resources

### Risk: Disk Space (NIX Store)
**Impact**: Low  
**Mitigation**:
- Document expected space usage (~1-2GB typical)
- Provide `nix-collect-garbage` cleanup script
- Explain benefits outweigh cost

### Risk: Resistance to Change
**Impact**: Medium  
**Mitigation**:
- Keep old method working for 3 months (deprecation period)
- Provide `MIGRATION.md` guide
- Show clear benefits (reproducibility, 65k packages)
- Support users during transition

### Risk: NIX Installation Failures
**Impact**: Medium  
**Mitigation**:
- Offer 3 installation methods (Determinate, official, distro)
- Fallback logic in bootstrap-nix.sh
- Clear error messages with troubleshooting steps

### Trade-off: Simplicity vs Immediate Benefit
**Trade-off**: NIX has learning curve but provides long-term maintainability  
**Decision**: Accept short-term complexity for long-term gain  
**Justification**: Current system unsustainable; technical debt must be addressed

## Migration Plan

### Phase 1: Foundation (Week 1)
1. Create packages.nix with current package equivalents
2. Implement bootstrap-nix.sh with method selection
3. Add --nix flag to dotbuntu
4. Write NIX_SETUP.md basic docs
5. Test on Ubuntu and Arch

**Rollback**: Remove --nix flag, delete new files

### Phase 2: Integration (Week 2)
1. Version packages.nix in dotbare repo by default
2. Update install.sh to orchestrate NIX + dotbare
3. Add sync-packages.sh for package updates
4. Write MIGRATION.md guide
5. Internal testing with real dotfiles repos

**Rollback**: Revert install.sh changes, docs remain

### Phase 3: Transition (Week 3)
1. Make --nix default, old method requires --legacy flag
2. Add deprecation warnings to legacy code
3. Update README with new workflow
4. Create ARCHITECTURE.md
5. Move old installers to scripts/legacy/

**Rollback**: Switch default back to legacy

### Phase 4: Release (Week 4)
1. Comprehensive testing on Arch, Ubuntu, Debian
2. Create release video/GIF demo
3. Finalize all documentation
4. Tag v2.0.0
5. Announce on GitHub

**Rollback**: If critical bugs, revert to v1.x branch

### Data Migration

**User actions required**:
1. Install NIX (automated by bootstrap-nix.sh)
2. Convert setup.conf packages to packages.nix (we provide conversion script)
3. Commit packages.nix to dotfiles repo
4. Test new setup on secondary machine before primary

**Backward compatibility**:
- v1.x configs work with --legacy flag for 3 months
- After 3 months, remove legacy code (v3.0.0)

## Open Questions

1. **Should we provide a setup.conf → packages.nix conversion script?**  
   - **Answer**: Yes, include in bootstrap-nix.sh as optional step

2. **How do we handle packages not available in nixpkgs?**  
   - **Answer**: Document GitHub releases fallback, create nixpkgs overlay guide

3. **Do we need CI/CD to test on multiple distros?**  
   - **Answer**: Nice-to-have but not blocker for v2.0.0; add in v2.1.0

4. **Should documentation be bilingual (English + Spanish)?**  
   - **Answer**: Start with English (wider audience), add Spanish in v2.1.0

5. **How do we handle users who refuse to use NIX?**  
   - **Answer**: Support legacy mode for 3 months, then recommend they stay on v1.x

## Success Criteria

**Technical**:
- [ ] 60%+ reduction in package management code
- [ ] Zero "package not found" errors between Arch/Ubuntu
- [ ] `packages.nix` works identically on Arch and Ubuntu
- [ ] Setup time < 5 minutes on clean machine

**User Experience**:
- [ ] Documentation rated "clear" by 3+ external users
- [ ] Migration guide successfully followed by beta testers
- [ ] No critical bugs reported in first 2 weeks

**Adoption**:
- [ ] 50%+ of active users migrated within 1 month
- [ ] 100% migrated within 3 months (legacy code removal)

