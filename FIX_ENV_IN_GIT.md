# 🔒 How to Remove .env Files from Git History

## ⚠️ CRITICAL: If .env files were ever committed to git

If you accidentally committed `.env` files with real API keys before, they are **permanently in git history** even if you delete them now. Here's how to fix it:

## Step 1: Check if .env files are tracked

```bash
# Check if .env files are currently tracked
git ls-files | grep -E "\.env"

# Check if they exist in git history
git log --all --full-history --oneline -- ".env"
```

## Step 2: Remove from git tracking (if found)

If `.env` files are found, you have two options:

### Option A: Remove from tracking but keep locally (RECOMMENDED)

```bash
# Remove from git tracking but keep the file locally
git rm --cached .env
git rm --cached .env.local
git rm --cached .env.production

# Commit the removal
git commit -m "Remove .env files from git tracking"

# Push the changes
git push origin main
```

**⚠️ IMPORTANT**: After this, if the `.env` file was already pushed to GitHub:
1. The file will still exist in git history
2. Anyone with access to the repo can see old commits
3. You should **rotate/regenerate all API keys** that were exposed

### Option B: Remove from git history (Advanced - requires force push)

**⚠️ WARNING**: This rewrites git history. Only do this if:
- You're the only one working on the repo, OR
- You coordinate with your team first
- You understand the implications

```bash
# Use git filter-branch or BFG Repo-Cleaner
# This removes the file from ALL commits in history

# Method 1: Using git filter-branch (built-in)
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env .env.local .env.production" \
  --prune-empty --tag-name-filter cat -- --all

# Method 2: Using BFG Repo-Cleaner (easier, faster)
# Download BFG from: https://rtyley.github.io/bfg-repo-cleaner/
# Then run:
# bfg --delete-files .env
# bfg --delete-files .env.local
# bfg --delete-files .env.production
# git reflog expire --expire=now --all
# git gc --prune=now --aggressive

# After either method, force push (DANGEROUS - coordinate with team!)
# git push origin --force --all
```

## Step 3: Verify .gitignore is working

```bash
# Verify .env is ignored
git check-ignore .env
# Should output: .env

# Try to add it (should be ignored)
git add .env
git status
# .env should NOT appear in "Changes to be committed"
```

## Step 4: Rotate compromised credentials

If `.env` files with real keys were ever pushed:

1. **Supabase**: 
   - Go to your Supabase project settings
   - Regenerate the anon key
   - Update your local `.env` with the new key

2. **Stripe**:
   - Go to Stripe dashboard
   - Rotate API keys
   - Update your local `.env`

3. **Any other services**:
   - Rotate all API keys/secrets that were in the `.env` file

## Step 5: Verify current status

```bash
# Check what's tracked
git ls-files | grep -E "\.env|secret|key"

# Verify .gitignore patterns
cat .gitignore | grep -E "\.env"

# Check for any hardcoded secrets in code
grep -r "AIzaSy\|eyJhbGci\|sk_" lib/ --exclude-dir=config
```

## Current Status (as of 2024-11-04)

✅ **No `.env` files are currently tracked by git**
✅ **`.gitignore` properly configured**
✅ **All API keys use environment variables via `AppConfig`**
✅ **No hardcoded secrets in code**

## Prevention for the future

1. Always check `.gitignore` before first commit
2. Use `git status` to review before committing
3. Consider using `git-secrets` or `truffleHog` to scan commits
4. Use a pre-commit hook to prevent committing secrets:

```bash
# Create .git/hooks/pre-commit
#!/bin/sh
if git diff --cached --name-only | grep -E "\.env"; then
  echo "ERROR: .env files cannot be committed!"
  exit 1
fi
```

## Resources

- [GitHub's guide on removing sensitive data](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository)
- [BFG Repo-Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)
- [git-secrets](https://github.com/awslabs/git-secrets)


