# Git PR Merge Workflow

Automates the complete workflow for organizing commits, creating PR, merging, and cleanup.

## Command Name
`/git-pr-merge`

## Usage
```
/git-pr-merge <branch-name> [options]
```

## Options
- `--base <branch>` - Base branch for PR (default: master)
- `--skip-commits` - Skip commit organization, just create PR and merge
- `--draft` - Create draft PR

## Workflow Steps

1. **Organize Commits** (if not --skip-commits)
   - Analyze staged/unstaged changes
   - Group logically related changes
   - Create semantic commits with conventional commit messages
   - Push to remote branch

2. **Create Pull Request** (using GitHub CLI)
   - Generate comprehensive PR description
   - Include change summary, commit list, testing checklist
   - Create PR with `gh pr create`

3. **Merge PR**
   - Checkout base branch (master)
   - Merge with `--no-ff` for merge commit
   - Push merged changes

4. **Cleanup**
   - Delete local feature branch
   - Delete remote feature branch  
   - Pull latest from base branch

## Prerequisites

- GitHub CLI installed (`gh`)
- Authenticated with GitHub (`gh auth login`)
- Remote repository configured

## Example

```bash
# Full workflow
/git-pr-merge feat/my-feature

# Skip commit organization
/git-pr-merge feat/my-feature --skip-commits

# Target different base branch
/git-pr-merge feat/my-feature --base develop
```

## Implementation

When invoked, the AI assistant will:

1. Check prerequisites (gh, git status)
2. Execute workflow steps sequentially
3. Handle errors gracefully
4. Provide clear status updates
5. Verify completion

## Success Criteria

- ✓ All commits organized and pushed
- ✓ PR created and merged
- ✓ Branches cleaned up
- ✓ Local repo synchronized
- ✓ Working tree clean

