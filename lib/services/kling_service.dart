import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'supabase_service.dart';

/// Kling client helpers (second provider next to `StripeService`).
///
/// The app never holds `KLING_SECRET_KEY` or `KLING_WEBHOOK_SECRET`.
/// Secret-key calls go through the `kling-secret` Edge Function.
/// DEMO_MODE (default) and missing Supabase config keep the mock path —
/// no live Kling charges. Overlay JS (`kling.js`) is public, not a secret.
class KlingService {
  static const String _functionName = 'kling-secret';
  static const String paymentMethodType = 'card';
  static const String currency = 'ISK';
  static const String locale = 'is';

  /// Public overlay script from Kling docs. Not a secret key.
  static const String publicEmbedScriptUrl =
      'https://api.kling.is/v1/kling.js';

  /// Recurring store plan price used only on the mock path. ISK has no
  /// decimals: `4990` means 4.990 kr. Never multiply by 100.
  static const int mockStoreAmountIsk = 4990;

  static const _customerPrefix = 'kling_customer_';
  static const _subscriptionPrefix = 'kling_subscription_';

  static bool get useMock => AppConfig.useMockKling;

  /// Icelandic thousands grouping for whole krónur. [amount] is already ISK.
  static String formatIsk(int amount) {
    final digits = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buffer.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }
    buffer.write(' kr');
    return buffer.toString();
  }

  static String defaultReturnUrl({String? webOrigin}) {
    if (webOrigin != null && webOrigin.isNotEmpty) {
      return webOrigin;
    }
    return 'https://bonuses.app/account';
  }

  static Future<Map<String, dynamic>> createCheckoutSession({
    required String companyId,
    required String customerEmail,
    required String customerName,
    String? customerPhone,
    String? productId,
  }) async {
    if (AppConfig.useMockKling) {
      return {
        'id': _mockUuid(),
        'url': 'https://pay.kling.is/demo',
        'status': 'open',
        'payment_status': 'unpaid',
        'amount': mockStoreAmountIsk,
        'currency': currency,
        'payment_method_type': paymentMethodType,
        'demo': true,
      };
    }

    final resolvedProductId =
        (productId ?? AppConfig.klingStoreProductId).trim();
    if (resolvedProductId.isEmpty) {
      throw Exception(
        'KLING_STORE_PRODUCT_ID is required for live Kling checkout',
      );
    }

    return _invokeSecretAction('createCheckoutSession', {
      'productId': resolvedProductId,
      'companyId': companyId,
      'customerEmail': customerEmail,
      'customerName': customerName,
      if (customerPhone != null && customerPhone.isNotEmpty)
        'customerPhone': customerPhone,
      'locale': locale,
      'paymentMethodType': paymentMethodType,
    });
  }

  static Future<Map<String, dynamic>> getCheckoutSession({
    required String sessionId,
  }) async {
    if (AppConfig.useMockKling) {
      return {
        'id': sessionId,
        'status': 'complete',
        'payment_status': 'paid',
        'amount': mockStoreAmountIsk,
        'currency': currency,
        'payment_method_type': paymentMethodType,
        'demo': true,
      };
    }

    return _invokeSecretAction('getCheckoutSession', {
      'sessionId': sessionId,
    });
  }

  static Future<Map<String, dynamic>> createBillingPortalSession({
    required String customerId,
    required String returnUrl,
    String? subscriptionId,
  }) async {
    if (AppConfig.useMockKling) {
      return {
        'id': _mockUuid(),
        'url': 'https://pay.kling.is/demo-portal',
        'customer': customerId,
        'demo': true,
      };
    }

    return _invokeSecretAction('createBillingPortalSession', {
      'customerId': customerId,
      'returnUrl': returnUrl,
      if (subscriptionId != null && subscriptionId.isNotEmpty)
        'subscriptionId': subscriptionId,
    });
  }

  static Future<String?> storedCustomerId(String companyId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_customerPrefix$companyId');
  }

  static Future<String?> storedSubscriptionId(String companyId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_subscriptionPrefix$companyId');
  }

  static Future<void> rememberCustomer({
    required String companyId,
    required String customerId,
    String? subscriptionId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_customerPrefix$companyId', customerId);
    if (subscriptionId != null && subscriptionId.isNotEmpty) {
      await prefs.setString('$_subscriptionPrefix$companyId', subscriptionId);
    }
  }

  /// After a paid overlay, keep the Kling customer id so the billing portal
  /// can open. Live fulfilment still comes from the Kling webhook function.
  static Future<void> rememberFromCheckoutSession({
    required String companyId,
    required Map<String, dynamic> session,
  }) async {
    final customerId = session['customer_id'] ??
        session['customerId'] ??
        session['customer'];
    if (customerId is String && customerId.isNotEmpty) {
      String? subscriptionId;
      final ids = session['subscription_ids'] ?? session['subscriptionIds'];
      if (ids is List && ids.isNotEmpty) {
        subscriptionId = ids.first.toString();
      } else {
        final single =
            session['subscription_id'] ?? session['subscriptionId'];
        if (single is String && single.isNotEmpty) {
          subscriptionId = single;
        }
      }
      await rememberCustomer(
        companyId: companyId,
        customerId: customerId,
        subscriptionId: subscriptionId,
      );
    }
  }

  static Future<void> rememberMockCustomer(String companyId) async {
    final existing = await storedCustomerId(companyId);
    if (existing != null) return;
    await rememberCustomer(
      companyId: companyId,
      customerId: _mockUuid(),
      subscriptionId: _mockUuid(),
    );
  }

  /// Calls the `kling-secret` Edge Function. Never sends a Kling secret.
  static Future<Map<String, dynamic>> _invokeSecretAction(
    String action,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await SupabaseService.client.functions.invoke(
        _functionName,
        body: {
          'action': action,
          'payload': payload,
        },
      );
      final data = response.data;
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        if (map['error'] != null) {
          throw Exception('Kling function error: ${map['error']}');
        }
        return map;
      }
      throw Exception('Unexpected kling-secret response');
    } on FunctionException catch (e) {
      throw Exception(
        'Kling function failed (${e.status}): ${e.details ?? e.reasonPhrase}',
      );
    }
  }

  static String _mockUuid() {
    final n = DateTime.now().microsecondsSinceEpoch.remainder(0xffffffffffff);
    final tail = n.toRadixString(16).padLeft(12, '0');
    return '00000000-0000-4000-8000-$tail';
  }
}
