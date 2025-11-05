# 🚨 URGENT: API Key Exposed - Action Required

**Date**: 2024-11-04  
**Severity**: HIGH

## ⚠️ CRITICAL: API Key Shared

A Supabase anon key was shared in conversation. This key needs to be **immediately rotated**.

## Exposed Key Details

- **Type**: Supabase Anon (Public) Key
- **Project**: `hkpkznslzkgnijoahgn` (from decoded JWT)
- **Issued**: 2024-10-24 (timestamp: 1761361824)
- **Expires**: 2025-10-24 (timestamp: 2076937824)

## ⚠️ IMMEDIATE ACTIONS REQUIRED

### Step 1: Rotate the Key (DO THIS NOW)

1. Go to your Supabase Dashboard:
   https://app.supabase.com/project/hkpkznslzkgnijoahgn

2. Navigate to: **Settings** → **API**

3. Find the **"anon public"** key section

4. Click **"Reset"** or **"Regenerate"** to create a new key

5. **Copy the new key** immediately

### Step 2: Update Local Environment

1. Update your `.env` file (or environment variables):
   ```bash
   SUPABASE_URL=https://hkpkznslzkgnijoahgn.supabase.co
   SUPABASE_ANON_KEY=<NEW_KEY_HERE>
   ```

2. If using `--dart-define` flags, update those as well

### Step 3: Verify No Key in Git

```bash
# Check if this key was ever committed
git log --all --full-history -p | grep "TbqbkOi5ZL0czgmc-a8X_OzqMMJzsXMFuzT9x5orHBc"

# Check current codebase
grep -r "TbqbkOi5ZL0czgmc-a8X_OzqMMJzsXMFuzT9x5orHBc" .
```

### Step 4: Check for Unauthorized Access

1. Go to Supabase Dashboard → **Logs** → **API Logs**
2. Check for any suspicious activity
3. Review recent API calls for anomalies

## Security Notes

### Anon Key Security

**Good news**: The anon key is designed to be "public" - it's meant to be used in client-side code. However:
- ✅ It's still protected by Row Level Security (RLS) policies
- ✅ It only has permissions you explicitly grant
- ⚠️ If exposed, it can be used to make API calls within RLS limits

**Important**: 
- The key is safe to use in client apps (Flutter, web, etc.)
- But you should still rotate it if exposed publicly
- Ensure RLS policies are properly configured

### Best Practices Going Forward

1. **Never share API keys in conversations**
2. **Never commit keys to git**
3. **Always use environment variables**
4. **Rotate keys if accidentally exposed**
5. **Use Supabase's key rotation feature regularly**

## Verification Commands

After rotating the key, verify:

```bash
# Check git history for the old key (should find nothing)
git log --all --full-history -p | grep "TbqbkOi5ZL0czgmc-a8X_OzqMMJzsXMFuzT9x5orHBc"

# Verify .env is not tracked
git ls-files | grep "\.env"

# Verify new key is not in code
grep -r "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9" lib/ --exclude-dir=config
```

## Status

- ✅ Key checked in git history: **NOT FOUND** (good - wasn't committed)
- ⚠️ Key exposed in conversation: **YES** (needs rotation)
- ✅ Current code uses environment variables: **YES**
- ✅ `.gitignore` configured: **YES**

## Next Steps

1. ✅ **Rotate the key in Supabase dashboard** (URGENT)
2. ✅ **Update local `.env` file**
3. ✅ **Test app with new key**
4. ✅ **Delete this file after rotation** (contains exposed key)

---

**Remember**: Anon keys are "public" by design, but you should still rotate them if exposed. Your RLS policies protect your data.


