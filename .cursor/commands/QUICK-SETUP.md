# Quick Setup: /git-pr-merge Command

## Option 1: Add to Existing .cursorrules (Recommended)

Add this to your `.cursorrules` file:

```markdown
## Git PR Merge Workflow Automation

### Command: /git-pr-merge

When user invokes `/git-pr-merge <branch-name> [options]`, execute the following workflow:

1. **Organize Commits** (unless --skip-commits flag)
   - Analyze staged/unstaged changes
   - Group related files logically
   - Create semantic commits using Conventional Commits format
   - Push commits to remote branch

2. **Create Pull Request** (ALWAYS use GitHub CLI)
   ```bash
   gh pr create --title "..." --body "..." --base master --head <branch>
   ```
   - Generate comprehensive PR description
   - Include: summary, commits, testing checklist, breaking changes
   - Capture PR number for merge step

3. **Merge Pull Request**
   ```bash
   git checkout master
   git merge <branch> --no-ff -m "Merge pull request #<num> from ..."
   git push origin master
   ```

4. **Cleanup**
   ```bash
   git branch -d <branch>
   git push origin --delete <branch>
   git pull origin master
   ```

5. **Report Summary**
   - Show: commits created, PR number, merge status, cleanup status
   - Verify: working tree clean, branch deleted, sync complete

**Options:**
- `--base <branch>`: Target branch (default: master)
- `--skip-commits`: Skip commit organization
- `--draft`: Create draft PR
- `--no-cleanup`: Keep branches after merge
- `--dry-run`: Show what would happen

**Prerequisites:**
- GitHub CLI installed: `gh --version`
- Authenticated: `gh auth status`

**Example:**
```
User: /git-pr-merge feat/new-feature
AI: [Executes full workflow with detailed progress reporting]
```

See `.cursor/commands/USAGE.md` for detailed documentation.
```

## Option 2: Cursor Will Read Automatically

Cursor automatically reads `.cursorrules-git-workflow` file from the project root.

No additional setup needed! Just make sure the file exists.

## Option 3: Create .cursor/rules.md

If you prefer Cursor's native rules format:

```bash
mkdir -p .cursor
```

Then create `.cursor/rules.md` with the content from Option 1.

## Verify Installation

Test the command:

```
/git-pr-merge --help
```

AI should respond with usage information.

## Quick Test

Create a test branch and try it:

```bash
git checkout -b test/cursor-command
echo "test" >> test.txt
git add test.txt
```

Then in Cursor chat:
```
/git-pr-merge test/cursor-command --dry-run
```

AI should show what it would do without executing.

## Installation Complete! 🎉

You can now use:
```
/git-pr-merge <branch-name>
```

For more examples and options, see `USAGE.md`.

