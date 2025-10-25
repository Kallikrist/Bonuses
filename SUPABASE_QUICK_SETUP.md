# Quick Supabase Setup Guide

## Step 1: Get Your Supabase Credentials

1. Go to your Supabase dashboard: [app.supabase.com](https://app.supabase.com)
2. Click on your project
3. Go to **Settings** → **API**
4. Copy these two values:
   - **Project URL**: `https://your-project-id.supabase.co`
   - **Anon public key**: `eyJ...` (long string starting with eyJ)

## Step 2: Update Your App

1. Open `lib/services/supabase_service.dart`
2. Replace these lines:
   ```dart
   url: 'https://your-project-id.supabase.co', // Replace with your actual URL
   anonKey: 'your-anon-key-here', // Replace with your actual anon key
   ```

## Step 3: Create Database Tables

1. In your Supabase dashboard, go to **SQL Editor**
2. Click **New Query**
3. Copy and paste the content from `supabase_test_setup.sql`
4. Click **Run**

## Step 4: Test the Connection

1. Run your Flutter app
2. Navigate to: `http://localhost:8080/#/supabase-test` (or your app URL + `/supabase-test`)
3. Click "Test Connection"
4. If successful, click "Test Write"

## Step 5: If It Works

If the test succeeds, you can:
1. Go to Admin Dashboard → Demo Settings
2. Click "Migrate to Supabase"
3. All your local data will move to the cloud!

## What This Gives You

✅ **Real multi-user system** - Multiple companies can use the app
✅ **Real-time updates** - Changes sync instantly between users
✅ **Production ready** - Handles thousands of users
✅ **Secure** - Row Level Security protects data
✅ **Scalable** - Grows with your business

## If It Doesn't Work

If you get errors, we can:
1. Keep using local storage (it works perfectly)
2. Try a different database solution
3. Debug the specific Supabase issues

**The key is testing it first before committing to a full migration!**
