# How to Identify the Correct Key to Rotate

## 🎯 Quick Answer

**YES, you're looking for the "anon public" key** - this is the one that was exposed.

## What to Look For in Supabase Dashboard

### Step 1: Navigate to API Settings
1. Go to: https://app.supabase.com/project/hkpkznslzkgnijoahgn
2. Click **Settings** (gear icon in left sidebar)
3. Click **API** (under "Project Settings")

### Step 2: Find the Anon Public Key

You'll see **two main keys** in the API section:

#### 🔵 **anon public** (THIS IS THE ONE TO ROTATE)
- **Label**: "anon public" or "public anon key"
- **Description**: "This key is safe to use in a browser if you have Row Level Security enabled"
- **Starts with**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`
- **This is the exposed key** ✅

#### 🔴 **service_role** (DO NOT ROTATE THIS)
- **Label**: "service_role" or "service_role secret"
- **Description**: "This key has admin privileges and can bypass Row Level Security"
- **Starts with**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...` (but different content)
- **Keep this secret** - never expose this one

## How to Verify It's the Right Key

The exposed key ends with: `...TbqbkOi5ZL0czgmc-a8X_OzqMMJzsXMFuzT9x5orHBc`

1. Look at the "anon public" key in your dashboard
2. Check if it ends with `TbqbkOi5ZL0czgmc-a8X_OzqMMJzsXMFuzT9x5orHBc`
3. If it matches → **This is the one to rotate** ✅

## Visual Guide

```
┌─────────────────────────────────────────────────┐
│  Supabase Dashboard → Settings → API            │
├─────────────────────────────────────────────────┤
│                                                  │
│  📍 API URL                                      │
│  https://hkpkznslzkgnijoahgn.supabase.co        │
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │ 🔵 anon public                            │  │
│  │ eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...  │  │
│  │ ✅ THIS IS THE ONE TO ROTATE              │  │
│  │ [Reset] [Copy] [Eye icon to show/hide]    │  │
│  └──────────────────────────────────────────┘  │
│                                                  │
│  ┌──────────────────────────────────────────┐  │
│  │ 🔴 service_role secret                    │  │
│  │ eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...  │  │
│  │ ⚠️ DO NOT ROTATE (unless compromised)     │  │
│  │ [Reset] [Copy] [Eye icon to show/hide]    │  │
│  └──────────────────────────────────────────┘  │
│                                                  │
└─────────────────────────────────────────────────┘
```

## What to Do When You Find It

1. ✅ Click the **"Reset"** or **"Regenerate"** button next to "anon public"
2. ✅ **Copy the new key** immediately (Supabase will show it once)
3. ✅ Update your `.env` file with the new key:
   ```bash
   SUPABASE_ANON_KEY=<paste_new_key_here>
   ```
4. ✅ Test your app to make sure it still works

## Important Notes

- ✅ **anon public** is safe to use in client apps (Flutter, web, mobile)
- ✅ It's protected by Row Level Security (RLS) policies
- ✅ Rotating it is good practice after exposure
- ⚠️ **service_role** should NEVER be exposed or used in client apps
- ⚠️ **service_role** has full admin access - keep it secret!

## Still Not Sure?

If you're unsure which key you're looking at, you can:

1. **Check the label**: Should say "anon public" or "public anon key"
2. **Check the description**: Should mention "safe to use in browser" or "RLS enabled"
3. **Compare the ending**: Your exposed key ends with `TbqbkOi5ZL0czgmc-a8X_OzqMMJzsXMFuzT9x5orHBc`

---

**TL;DR**: Look for "anon public" key, not "service_role". Click "Reset" on the anon public key.

