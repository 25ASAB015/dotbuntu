# Git PR Merge Command - Usage Guide

## Quick Start

Simply invoke the command in Cursor chat:

```
/git-pr-merge feat/my-feature
```

## What It Does

Automates the entire Git workflow:

1. **Organizes your changes** into logical commits
2. **Creates a PR** using GitHub CLI (`gh`)
3. **Merges the PR** to master
4. **Cleans up** both local and remote branches
5. **Syncs** your local repository

## Installation

### 1. Install GitHub CLI

**macOS:**
```bash
brew install gh
```

**Linux:**
```bash
# Debian/Ubuntu
sudo apt install gh

# Arch Linux
sudo pacman -S github-cli
```

**Verify:**
```bash
gh --version
```

### 2. Authenticate with GitHub

```bash
gh auth login
```

Follow the prompts to authenticate.

### 3. Add to Cursor Rules

The command is already configured in `.cursorrules-git-workflow`.

To use it, either:

**Option A: Include in your main `.cursorrules`**
Add this line to your `.cursorrules`:
```
@import .cursorrules-git-workflow
```

**Option B: Cursor will read it automatically**
Cursor reads all `.cursorrules*` files in the project root.

## Examples

### Basic Usage

```
User: /git-pr-merge feat/add-authentication

AI: [Analyzes changes, creates commits, creates PR, merges, cleans up]
```

### Skip Commit Organization

If you've already organized your commits:

```
User: /git-pr-merge feat/my-feature --skip-commits
```

### Create Draft PR

```
User: /git-pr-merge feat/work-in-progress --draft
```

### Different Base Branch

```
User: /git-pr-merge feat/new-feature --base develop
```

### Keep Branches After Merge

```
User: /git-pr-merge feat/experimental --no-cleanup
```

### Dry Run

See what would happen without executing:

```
User: /git-pr-merge feat/test --dry-run
```

## What to Expect

### Step 1: Commit Organization

AI will:
- Analyze your changes
- Group related files
- Create semantic commits
- Push to remote

Example output:
```
✓ Analyzing 15 modified files...
✓ Creating 3 logical commits:
  1. feat(auth): implement JWT authentication (8 files)
  2. test(auth): add authentication tests (4 files)
  3. docs: update API documentation (3 files)
✓ Pushed to origin/feat/add-authentication
```

### Step 2: PR Creation

AI will:
- Generate comprehensive PR description
- Use GitHub CLI to create PR
- Report PR number and URL

Example output:
```
✓ Creating PR with GitHub CLI...
✓ PR #42 created: https://github.com/yourorg/yourrepo/pull/42

PR Details:
  Title: feat: Implement JWT Authentication
  Base: master
  Head: feat/add-authentication
  Status: Open
```

### Step 3: Merge

AI will:
- Checkout master
- Merge with --no-ff
- Push merged changes

Example output:
```
✓ Checked out master
✓ Merged feat/add-authentication
✓ Pushed to origin/master
```

### Step 4: Cleanup

AI will:
- Delete local branch
- Delete remote branch
- Sync with remote

Example output:
```
✓ Deleted local branch: feat/add-authentication
✓ Deleted remote branch: origin/feat/add-authentication
✓ Pulled latest from origin/master
```

### Step 5: Summary

```
✅ Git PR Merge Workflow Complete!

📊 Summary:
   - Commits created: 3
   - PR created: #42
   - Base branch: master
   - Merged: ✓
   - Cleanup: ✓

📁 Repository Status:
   - Branch: master
   - Status: Clean (working tree clean)
   - Sync: Up to date with origin/master

🚀 Next Steps:
   - Review PR: https://github.com/yourorg/yourrepo/pull/42
   - Deploy if needed
   - Notify team
```

## Troubleshooting

### "gh: command not found"

Install GitHub CLI:
```bash
# macOS
brew install gh

# Linux
sudo apt install gh  # or sudo pacman -S github-cli
```

### "gh: not authenticated"

Authenticate:
```bash
gh auth login
```

### "Working tree not clean"

Commit or stash your changes first:
```bash
git status
git add .
git commit -m "temp"
# Then retry /git-pr-merge
```

### "Branch doesn't exist"

Make sure you're on the correct branch:
```bash
git checkout feat/your-feature
# Then retry /git-pr-merge
```

## Tips

### Commit Message Quality

The AI will create semantic commits following Conventional Commits:

**Format:**
```
type(scope): subject

- Detail 1
- Detail 2
- Detail 3
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `refactor`: Code refactoring
- `test`: Tests
- `chore`: Maintenance
- `style`: Formatting

### PR Description Quality

The AI generates comprehensive PR descriptions including:
- Summary with emoji
- What's changed
- Commit list
- Testing checklist
- Breaking changes
- Documentation links

### Best Practices

1. **Work on feature branches**: Always create a branch for your work
2. **Keep PRs focused**: One feature/fix per PR
3. **Write clear commits**: AI helps, but review generated messages
4. **Test before merging**: Verify everything works
5. **Review PR description**: Make sure it's accurate

## Advanced Usage

### Custom Workflow

You can customize the workflow by modifying `.cursorrules-git-workflow`.

### Integration with CI/CD

The command creates PRs that trigger your CI/CD pipelines.

### Integration with OpenSpec

If you have OpenSpec changes, the AI will:
- Reference them in PR description
- Link to proposal/design/tasks
- Include implementation status

## Commit Organization Examples

For detailed examples of how the AI organizes commits, see:

**[COMMIT-EXAMPLES.md](./COMMIT-EXAMPLES.md)**

This document shows:
- Real examples from NIX migration (5 commits)
- Feature + Tests + Docs (4 commits)
- Bug fix + Improvements (3 commits)
- Large refactors (6+ commits)
- What to do and what NOT to do

**Key principle:** Always multiple logical commits, never one giant commit.

## Support

For issues or questions:
1. Check this guide
2. See `COMMIT-EXAMPLES.md` for commit organization patterns
3. Read `.cursorrules-git-workflow` for implementation details
4. Verify GitHub CLI is working: `gh pr list`
5. Ask in Cursor chat: "Help with /git-pr-merge"

---

**Happy merging! 🚀**

