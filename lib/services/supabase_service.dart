import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as models;
import '../models/company.dart';
import '../models/sales_target.dart';
import '../models/points_transaction.dart';
import '../models/bonus.dart';
import '../models/workplace.dart';
import '../models/message.dart';
import '../models/approval_request.dart';
import '../config/app_config.dart';

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase using environment variables
  static Future<void> initialize() async {
    final url = AppConfig.supabaseUrl;
    final anonKey = AppConfig.supabaseAnonKey;

    // Validate that environment variables are set (not using defaults)
    if (url.isEmpty || anonKey.isEmpty) {
      throw Exception(
        'Supabase credentials not configured. Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables.',
      );
    }

    // Warn if using default/placeholder values (in debug mode)
    assert(
      url != 'https://your-project.supabase.co' &&
          anonKey != 'your_supabase_anon_key_here',
      '⚠️ WARNING: Using placeholder Supabase credentials. Set SUPABASE_URL and SUPABASE_ANON_KEY environment variables.',
    );

    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
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

  static models.User? getCurrentUser() {
    final authUser = client.auth.currentUser;
    if (authUser != null) {
      // Return a basic user object - you might want to fetch full user data
      return models.User(
        id: authUser.id,
        name: authUser.userMetadata?['name'] ?? 'Unknown',
        email: authUser.email ?? '',
        role: models.UserRole.employee, // Default role
        createdAt: DateTime.now(),
      );
    }
    return null;
  }

  // Users
  static Future<List<models.User>> getUsers() async {
    final response = await client
        .from('users')
        .select()
        .order('created_at', ascending: false);

    return response.map((json) => models.User.fromJson(json)).toList();
  }

  static Future<models.User?> getUserById(String id) async {
    try {
      final response =
          await client.from('users').select().eq('id', id).single();

      return models.User.fromJson(response);
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  static Future<void> createUser(models.User user) async {
    await client.from('users').insert(user.toJson());
  }

  static Future<void> updateUser(models.User user) async {
    await client.from('users').update(user.toJson()).eq('id', user.id);
  }

  static Future<List<models.User>> getUsersByCompany(String companyId) async {
    final response = await client
        .from('users')
        .select()
        .contains('company_ids', [companyId]);

    return response.map((json) => models.User.fromJson(json)).toList();
  }

  // Companies
  static Future<List<Company>> getCompanies() async {
    final response = await client
        .from('companies')
        .select()
        .order('created_at', ascending: false);

    return response.map((json) => Company.fromJson(json)).toList();
  }

  static Future<Company?> getCompanyById(String id) async {
    try {
      final response =
          await client.from('companies').select().eq('id', id).single();

      return Company.fromJson(response);
    } catch (e) {
      print('Error getting company by ID: $e');
      return null;
    }
  }

  static Future<void> createCompany(Company company) async {
    final companyData = company.toJson();
    companyData['owner_id'] =
        company.adminUserId; // Map adminUserId to owner_id
    await client.from('companies').insert(companyData);
  }

  static Future<void> updateCompany(Company company) async {
    await client
        .from('companies')
        .update(company.toJson())
        .eq('id', company.id);
  }

  // Workplaces
  static Future<List<Workplace>> getWorkplaces() async {
    final response = await client
        .from('workplaces')
        .select()
        .order('created_at', ascending: false);

    return response.map((json) => Workplace.fromJson(json)).toList();
  }

  static Future<List<Workplace>> getWorkplacesByCompany(
      String companyId) async {
    final response = await client
        .from('workplaces')
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    return response.map((json) => Workplace.fromJson(json)).toList();
  }

  static Future<void> createWorkplace(Workplace workplace) async {
    await client.from('workplaces').insert(workplace.toJson());
  }

  // Sales Targets
  static Future<List<SalesTarget>> getSalesTargets() async {
    final response = await client
        .from('sales_targets')
        .select()
        .order('date', ascending: false);

    // Filter out deleted targets in Dart (PostgREST null check syntax varies)
    final targets = response.map((json) => SalesTarget.fromJson(json)).toList();
    return targets.where((target) => target.deletedAt == null).toList();
  }

  static Future<List<SalesTarget>> getSalesTargetsByCompany(
      String companyId) async {
    final response = await client
        .from('sales_targets')
        .select()
        .eq('company_id', companyId)
        .order('date', ascending: false);

    // Filter out deleted targets in Dart
    final targets = response.map((json) => SalesTarget.fromJson(json)).toList();
    return targets.where((target) => target.deletedAt == null).toList();
  }

  static Future<List<SalesTarget>> getSalesTargetsByUser(String userId) async {
    final response = await client
        .from('sales_targets')
        .select()
        .or('assigned_employee_id.eq.$userId,collaborative_employee_ids.cs.{$userId}')
        .order('date', ascending: false);

    // Filter out deleted targets in Dart
    final targets = response.map((json) => SalesTarget.fromJson(json)).toList();
    return targets.where((target) => target.deletedAt == null).toList();
  }

  static Future<void> createSalesTarget(SalesTarget target) async {
    final payload = _salesTargetPayload(target, forUpdate: false);
    print('DEBUG: SupabaseService.createSalesTarget final payload:');
    print(payload);
    await client.from('sales_targets').insert(payload);
  }

  static Map<String, dynamic> _salesTargetPayload(SalesTarget target,
      {required bool forUpdate}) {
    final String dateOnly = target.date.toIso8601String().split('T').first;
    return {
      'id': target.id,
      'company_id': target.companyId,
      'assigned_employee_id': target.assignedEmployeeId,
      'assigned_employee_name': target.assignedEmployeeName,
      'assigned_workplace_id': target.assignedWorkplaceId,
      'assigned_workplace_name': target.assignedWorkplaceName,
      'collaborative_employee_ids': target.collaborativeEmployeeIds,
      'collaborative_employee_names': target.collaborativeEmployeeNames,
      'title': target.assignedWorkplaceName != null &&
              target.assignedEmployeeName != null
          ? '${target.assignedEmployeeName} - ${target.assignedWorkplaceName}'
          : 'Sales Target',
      'description': null,
      'target_amount': target.targetAmount,
      'points': (target.pointsAwarded).toDouble(),
      'date': dateOnly,
      'status': target.status.name,
      'created_at': target.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'actual_amount': target.actualAmount,
      'is_met': target.isMet,
      'percentage_above_target': target.percentageAboveTarget,
      'points_awarded': target.pointsAwarded,
      'created_by': target.createdBy,
      'is_submitted': target.isSubmitted,
      'is_approved': target.isApproved,
      'approved_by': target.approvedBy,
      'approved_at': target.approvedAt?.toIso8601String(),
    }..removeWhere((_, v) => v == null);
  }

  static Future<void> updateSalesTarget(SalesTarget target) async {
    final payload = _salesTargetPayload(target, forUpdate: true);
    print('DEBUG: SupabaseService.updateSalesTarget payload:');
    print(payload);
    print(
        'DEBUG: Updating target ${target.id} with is_submitted=${target.isSubmitted}, status=${target.status.name}');
    try {
      // Try to get the updated row back (might fail due to RLS, but update will still work)
      final response = await client
          .from('sales_targets')
          .update(payload)
          .eq('id', target.id)
          .select();
      if (response.isNotEmpty) {
        print('DEBUG: Supabase update response: ${response.first}');
      } else {
        print(
            '⚠️ DEBUG: Update succeeded but could not read row back (RLS may block SELECT)');
      }
    } catch (e) {
      // Update might still have succeeded, but we can't read it back due to RLS
      print(
          '⚠️ DEBUG: Update call completed but could not verify response: $e');
      // Don't throw - the update likely succeeded (we got 204), just can't read it back
    }
  }

  static Future<void> deleteSalesTarget(
      String targetId, String deletedBy) async {
    print(
        'DEBUG: SupabaseService.deleteSalesTarget id=$targetId, deletedBy=$deletedBy');
    try {
      final now = DateTime.now();
      final deletedAt = now.toIso8601String();
      print(
          'DEBUG: Deleting target with deleted_at=$deletedAt, deleted_by=$deletedBy');

      // Soft delete: update deleted_at and deleted_by instead of hard deleting
      final response = await client
          .from('sales_targets')
          .update({
            'deleted_at': deletedAt,
            'deleted_by': deletedBy,
          })
          .eq('id', targetId)
          .select();

      if (response.isEmpty) {
        print(
            '⚠️ WARNING: Target update returned empty response (target may not exist or RLS blocked)');
      } else {
        print('✅ Sales target soft deleted in Supabase: $targetId');
        print('DEBUG: Deleted target response: ${response.first}');
      }
    } catch (e) {
      print('❌ ERROR: Failed to soft delete target in Supabase: $e');
      rethrow; // Re-throw so calling code knows it failed
    }
  }

  // Points Transactions
  static Future<List<PointsTransaction>> getPointsTransactions() async {
    final response = await client
        .from('points_transactions')
        .select()
        .order('date', ascending: false);

    return response.map((json) => PointsTransaction.fromJson(json)).toList();
  }

  static Future<List<PointsTransaction>> getPointsTransactionsByUser(
      String userId) async {
    final response = await client
        .from('points_transactions')
        .select()
        .eq('user_id', userId)
        .order('date', ascending: false);

    return response.map((json) => PointsTransaction.fromJson(json)).toList();
  }

  static Future<void> createPointsTransaction(
      PointsTransaction transaction) async {
    final payload = {
      'id': transaction.id,
      'user_id': transaction.userId,
      'company_id': transaction.companyId,
      'type': transaction.type.name,
      'points': transaction.points,
      'amount': (transaction.points).toDouble(),
      'description': transaction.description,
      'date': transaction.date.toIso8601String(),
      'related_target_id': transaction.relatedTargetId,
    }..removeWhere((_, v) => v == null);
    print('DEBUG: SupabaseService.createPointsTransaction payload:');
    print(payload);
    await client.from('points_transactions').insert(payload);
  }

  // Bonuses
  static Future<List<Bonus>> getBonuses() async {
    final response = await client
        .from('bonuses')
        .select()
        .order('created_at', ascending: false);

    return response.map((json) => Bonus.fromJson(json)).toList();
  }

  static Future<List<Bonus>> getBonusesByCompany(String companyId) async {
    final response = await client
        .from('bonuses')
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false);

    return response.map((json) => Bonus.fromJson(json)).toList();
  }

  static Future<void> createBonus(Bonus bonus) async {
    await client.from('bonuses').insert(bonus.toJson());
  }

  // Test method to create bonus with raw JSON
  static Future<void> createBonusRaw(Map<String, dynamic> data) async {
    await client.from('bonuses').insert(data);
  }

  // Messages
  static Future<List<Message>> getMessages() async {
    final response = await client
        .from('messages')
        .select()
        .order('created_at', ascending: false);

    return response.map((json) => Message.fromJson(json)).toList();
  }

  static Future<List<Message>> getMessagesByUser(String userId) async {
    final response = await client
        .from('messages')
        .select()
        .or('sender_id.eq.$userId,receiver_id.eq.$userId')
        .order('created_at', ascending: false);

    return response.map((json) => Message.fromJson(json)).toList();
  }

  static Future<void> createMessage(Message message) async {
    await client.from('messages').insert(message.toJson());
  }

  static Future<void> markMessageAsRead(String messageId) async {
    await client.from('messages').update({'is_read': true}).eq('id', messageId);
  }

  // Approval Requests
  static Future<List<ApprovalRequest>> getApprovalRequests() async {
    final response = await client
        .from('approval_requests')
        .select()
        .order('submitted_at', ascending: false);

    return response.map((json) => ApprovalRequest.fromJson(json)).toList();
  }

  static Future<void> createApprovalRequest(ApprovalRequest request) async {
    await client.from('approval_requests').insert(request.toJson());
  }

  static Future<void> updateApprovalRequest(ApprovalRequest request) async {
    await client
        .from('approval_requests')
        .update(request.toJson())
        .eq('id', request.id);
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
            print('Sales target updated: ${payload.newRecord}');
            // You can emit events or update state here
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
            print('Message received: ${payload.newRecord}');
            // You can emit events or update state here
          },
        )
        .subscribe();
  }

  static RealtimeChannel subscribeToPointsTransactions() {
    return client
        .channel('points_transactions')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'points_transactions',
          callback: (payload) {
            print('Points transaction updated: ${payload.newRecord}');
            // You can emit events or update state here
          },
        )
        .subscribe();
  }

  // Utility methods
  static Future<void> disconnect() async {
    await client.realtime.disconnect();
  }

  static bool get isConnected => client.realtime.isConnected;
}
