# Supabase Setup for Bonuses App

## Why Supabase?

- ✅ **PostgreSQL** - Industry standard database
- ✅ **Real-time** - Live updates between users  
- ✅ **Authentication** - Built-in user management
- ✅ **Simple setup** - Much easier than Firebase
- ✅ **Flutter support** - Excellent packages
- ✅ **Free tier** - Generous limits (500MB database, 50,000 monthly active users)

## Step 1: Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign up with GitHub/Google
3. Click "New Project"
4. Choose organization
5. Project name: `bonuses-app`
6. Database password: `your-secure-password`
7. Region: `Europe West (London)` (closest to Iceland)
8. Click "Create new project"

## Step 2: Database Schema

Run this SQL in the Supabase SQL Editor:

```sql
-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(50),
    role VARCHAR(20) NOT NULL CHECK (role IN ('employee', 'admin', 'superAdmin')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    workplace_ids TEXT[] DEFAULT '{}',
    workplace_names TEXT[] DEFAULT '{}',
    company_ids TEXT[] DEFAULT '{}',
    company_names TEXT[] DEFAULT '{}',
    primary_company_id UUID,
    total_points INTEGER DEFAULT 0,
    company_points JSONB DEFAULT '{}',
    company_roles JSONB DEFAULT '{}'
);

-- Companies table
CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    admin_user_id UUID REFERENCES users(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    subscription_status VARCHAR(20) DEFAULT 'active',
    subscription_tier VARCHAR(20) DEFAULT 'free'
);

-- Workplaces table
CREATE TABLE workplaces (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Sales targets table
CREATE TABLE sales_targets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    date DATE NOT NULL,
    target_amount DECIMAL(10,2) NOT NULL,
    actual_amount DECIMAL(10,2) DEFAULT 0,
    is_met BOOLEAN DEFAULT false,
    status VARCHAR(20) DEFAULT 'pending',
    percentage_above_target DECIMAL(5,2) DEFAULT 0,
    points_awarded INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users(id),
    assigned_employee_id UUID REFERENCES users(id),
    assigned_employee_name VARCHAR(255),
    assigned_workplace_id UUID REFERENCES workplaces(id),
    assigned_workplace_name VARCHAR(255),
    collaborative_employee_ids TEXT[] DEFAULT '{}',
    collaborative_employee_names TEXT[] DEFAULT '{}',
    is_submitted BOOLEAN DEFAULT false,
    is_approved BOOLEAN DEFAULT false,
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    company_id UUID REFERENCES companies(id)
);

-- Points transactions table
CREATE TABLE points_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    type VARCHAR(20) NOT NULL CHECK (type IN ('earned', 'redeemed', 'bonus', 'adjustment')),
    points INTEGER NOT NULL,
    description TEXT NOT NULL,
    date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    related_target_id UUID REFERENCES sales_targets(id),
    company_id UUID REFERENCES companies(id)
);

-- Bonuses table
CREATE TABLE bonuses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    points_required INTEGER NOT NULL,
    company_id UUID REFERENCES companies(id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Messages table
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID REFERENCES users(id),
    receiver_id UUID REFERENCES users(id),
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    company_id UUID REFERENCES companies(id)
);

-- Approval requests table
CREATE TABLE approval_requests (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    target_id UUID REFERENCES sales_targets(id),
    submitted_by UUID REFERENCES users(id),
    submitted_by_name VARCHAR(255),
    type VARCHAR(20) NOT NULL CHECK (type IN ('salesSubmission', 'teamChange')),
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    submitted_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID REFERENCES users(id),
    reviewed_by_name VARCHAR(255),
    rejection_reason TEXT,
    new_actual_amount DECIMAL(10,2),
    previous_actual_amount DECIMAL(10,2),
    new_team_member_ids TEXT[],
    new_team_member_names TEXT[],
    previous_team_member_ids TEXT[],
    previous_team_member_names TEXT[]
);

-- Create indexes for better performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_company ON users(primary_company_id);
CREATE INDEX idx_sales_targets_date ON sales_targets(date);
CREATE INDEX idx_sales_targets_company ON sales_targets(company_id);
CREATE INDEX idx_points_transactions_user ON points_transactions(user_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_receiver ON messages(receiver_id);
```

## Step 3: Row Level Security (RLS)

Enable RLS and create policies:

```sql
-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE workplaces ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales_targets ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bonuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE approval_requests ENABLE ROW LEVEL SECURITY;

-- Users can read their own data and company data
CREATE POLICY "Users can read own data" ON users FOR SELECT USING (auth.uid()::text = id::text);
CREATE POLICY "Users can read company users" ON users FOR SELECT USING (
    primary_company_id IN (
        SELECT primary_company_id FROM users WHERE auth.uid()::text = id::text
    )
);

-- Companies policies
CREATE POLICY "Users can read own company" ON companies FOR SELECT USING (
    id IN (
        SELECT primary_company_id FROM users WHERE auth.uid()::text = id::text
    )
);

-- Sales targets policies
CREATE POLICY "Users can read company targets" ON sales_targets FOR SELECT USING (
    company_id IN (
        SELECT primary_company_id FROM users WHERE auth.uid()::text = id::text
    )
);

-- Points transactions policies
CREATE POLICY "Users can read own transactions" ON points_transactions FOR SELECT USING (
    user_id = auth.uid()::text OR
    company_id IN (
        SELECT primary_company_id FROM users WHERE auth.uid()::text = id::text
    )
);

-- Messages policies
CREATE POLICY "Users can read own messages" ON messages FOR SELECT USING (
    sender_id = auth.uid()::text OR receiver_id = auth.uid()::text
);
```

## Step 4: Flutter Dependencies

Add to `pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: ^2.0.0
  postgrest: ^2.0.0
```

## Step 5: Supabase Service

Create `lib/services/supabase_service.dart`:

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../models/company.dart';
import '../models/sales_target.dart';
import '../models/points_transaction.dart';
import '../models/bonus.dart';
import '../models/workplace.dart';
import '../models/message.dart';
import '../models/approval_request.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'YOUR_SUPABASE_URL',
      anonKey: 'YOUR_SUPABASE_ANON_KEY',
    );
  }

  // Authentication
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Users
  static Future<List<User>> getUsers() async {
    final response = await client
        .from('users')
        .select()
        .order('created_at', ascending: false);
    
    return response.map((json) => User.fromJson(json)).toList();
  }

  static Future<User?> getUserById(String id) async {
    final response = await client
        .from('users')
        .select()
        .eq('id', id)
        .single();
    
    return response != null ? User.fromJson(response) : null;
  }

  static Future<void> createUser(User user) async {
    await client.from('users').insert(user.toJson());
  }

  static Future<void> updateUser(User user) async {
    await client
        .from('users')
        .update(user.toJson())
        .eq('id', user.id);
  }

  // Companies
  static Future<List<Company>> getCompanies() async {
    final response = await client
        .from('companies')
        .select()
        .order('created_at', ascending: false);
    
    return response.map((json) => Company.fromJson(json)).toList();
  }

  static Future<void> createCompany(Company company) async {
    await client.from('companies').insert(company.toJson());
  }

  // Sales Targets
  static Future<List<SalesTarget>> getSalesTargets() async {
    final response = await client
        .from('sales_targets')
        .select()
        .order('date', ascending: false);
    
    return response.map((json) => SalesTarget.fromJson(json)).toList();
  }

  static Future<void> createSalesTarget(SalesTarget target) async {
    await client.from('sales_targets').insert(target.toJson());
  }

  static Future<void> updateSalesTarget(SalesTarget target) async {
    await client
        .from('sales_targets')
        .update(target.toJson())
        .eq('id', target.id);
  }

  // Points Transactions
  static Future<List<PointsTransaction>> getPointsTransactions() async {
    final response = await client
        .from('points_transactions')
        .select()
        .order('date', ascending: false);
    
    return response.map((json) => PointsTransaction.fromJson(json)).toList();
  }

  static Future<void> createPointsTransaction(PointsTransaction transaction) async {
    await client.from('points_transactions').insert(transaction.toJson());
  }

  // Real-time subscriptions
  static RealtimeChannel subscribeToSalesTargets() {
    return client
        .channel('sales_targets')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'sales_targets',
          callback: (payload) {
            // Handle real-time updates
            print('Sales target updated: ${payload.newRecord}');
          },
        )
        .subscribe();
  }

  static RealtimeChannel subscribeToMessages() {
    return client
        .channel('messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            // Handle real-time updates
            print('Message received: ${payload.newRecord}');
          },
        )
        .subscribe();
  }
}
```

## Step 6: Update main.dart

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await SupabaseService.initialize();
  
  runApp(MyApp());
}
```

## Step 7: Update AuthService

```dart
import 'services/supabase_service.dart';

class AuthService {
  static Future<bool> login(String email, String password) async {
    try {
      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Get user data from database
        final user = await SupabaseService.getUserById(response.user!.id);
        if (user != null) {
          // Set current user in app state
          // Update UI
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }
}
```

## Benefits of This Setup:

1. **Real-time updates** - Users see changes instantly
2. **Scalable** - Handles thousands of users
3. **Secure** - Row Level Security protects data
4. **Reliable** - PostgreSQL is battle-tested
5. **Cost-effective** - Free tier covers most use cases
6. **Easy deployment** - No server management needed

## Next Steps:

1. Create Supabase project
2. Run the SQL schema
3. Add Flutter dependencies
4. Update your services
5. Test with real users!

This gives you a **production-ready database** that can handle multiple companies, users, and real-time collaboration! 🚀
