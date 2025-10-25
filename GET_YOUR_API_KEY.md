# 🔑 Get Your Supabase API Key

## Step 1: In Your Supabase Dashboard
1. You already have the dashboard open
2. Click **"Settings"** in the left sidebar
3. Click **"API"** under Settings

## Step 2: Copy the API Key
1. Find the **"anon public"** key
2. It's a long string starting with `eyJ`
3. Click the copy button next to it

## Step 3: Where to Put It
Once you have the key, I'll update this line in `lib/services/supabase_service.dart`:

```dart
anonKey: 'YOUR_ANON_KEY_HERE', // Replace this with your actual key
```

## Your Project Details (Already Set)
✅ **Project URL**: `https://hkpkznslzkgnijoahgn.supabase.co` (already added)
❌ **API Key**: Need to add this

**Just get the API key and I'll show you exactly where to put it!**
