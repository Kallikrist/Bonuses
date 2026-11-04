import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../config/app_config.dart';
import 'supabase_service.dart';

/// Stripe client helpers.
///
/// The app may hold the **publishable** key only. Secret-key Stripe API calls
/// go through the `stripe-secret` Supabase Edge Function. DEMO_MODE (default)
/// and missing Supabase config keep the existing mock payment path.
class StripeService {
  static const String _publishableKey = AppConfig.stripePublishableKey;
  static const String _functionName = 'stripe-secret';

  // Initialize Stripe (Mock for demo)
  static Future<void> initialize() async {
    try {
      Stripe.publishableKey = _publishableKey;
      await Stripe.instance.applySettings();
    } catch (e) {
      print('Stripe initialization failed (using mock mode): $e');
      // Continue with mock mode for demo
    }
  }

  // Check if Apple Pay is available
  static Future<bool> isApplePayAvailable() async {
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        // Mock implementation for demo - in real app, use Stripe.instance.isApplePaySupported()
        return true; // Always return true for demo
      }
      return false;
    } catch (e) {
      print('Apple Pay availability check failed: $e');
      return false;
    }
  }

  // Create Apple Pay payment intent
  static Future<Map<String, dynamic>> createApplePayPaymentIntent({
    required double amount,
    required String currency,
    required String description,
  }) async {
    try {
      // Mock implementation for demo
      await Future.delayed(const Duration(seconds: 1));

      return {
        'success': true,
        'client_secret': 'pi_mock_${DateTime.now().millisecondsSinceEpoch}',
        'amount': (amount * 100).round(), // Convert to cents
        'currency': currency,
        'description': description,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to create Apple Pay payment intent: $e',
      };
    }
  }

  // Process Apple Pay payment
  static Future<Map<String, dynamic>> processApplePayPayment({
    required String paymentIntentId,
    required double amount,
    required String currency,
    required String description,
  }) async {
    try {
      // Simulate Apple Pay processing
      await Future.delayed(const Duration(seconds: 2));

      // Mock successful Apple Pay payment
      return {
        'success': true,
        'payment_intent': {
          'id': paymentIntentId,
          'status': 'succeeded',
          'amount': (amount * 100).round(),
          'currency': currency,
        },
        'payment_method': {
          'id': 'pm_apple_pay_${DateTime.now().millisecondsSinceEpoch}',
          'type': 'apple_pay',
          'apple_pay': {
            'brand': 'apple_pay',
            'last4': '****',
          },
        },
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Apple Pay payment failed: $e',
      };
    }
  }

  // Create payment intent for $1 subscription (mock unless live path is on)
  static Future<Map<String, dynamic>> createPaymentIntent({
    required String companyId,
    required double amount,
    required String currency,
    required String description,
  }) async {
    if (AppConfig.useMockStripe) {
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

      return {
        'id': 'pi_mock_${DateTime.now().millisecondsSinceEpoch}',
        'client_secret':
            'pi_mock_${DateTime.now().millisecondsSinceEpoch}_secret_mock',
        'amount': (amount * 100).toInt(),
        'currency': currency.toLowerCase(),
        'status': 'requires_payment_method',
        'description': description,
        'metadata': {
          'company_id': companyId,
          'subscription_type': 'monthly',
        },
      };
    }

    return _invokeSecretAction('createPaymentIntent', {
      'companyId': companyId,
      'amount': amount,
      'currency': currency,
      'description': description,
    });
  }

  // Process payment with card (Mock for demo)
  static Future<Map<String, dynamic>> processPayment({
    required String paymentIntentId,
    required String cardNumber,
    required String expiryMonth,
    required String expiryYear,
    required String cvc,
    required String cardholderName,
  }) async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Mock card validation
      final cleanCardNumber = cardNumber.replaceAll(' ', '');

      // Simulate different test card scenarios
      if (cleanCardNumber == '4000000000000002') {
        return {
          'success': false,
          'error': 'Your card was declined. Please try a different card.',
        };
      }

      if (cleanCardNumber == '4000000000009995') {
        return {
          'success': false,
          'error': 'Your card has insufficient funds.',
        };
      }

      // Simulate successful payment for valid test cards
      if (cleanCardNumber.startsWith('4') ||
          cleanCardNumber.startsWith('5') ||
          cleanCardNumber.startsWith('3')) {
        return {
          'success': true,
          'payment_intent': {
            'id': paymentIntentId,
            'status': 'succeeded',
            'amount': 100, // $1.00 in cents
            'currency': 'usd',
          },
          'payment_method': {
            'id': 'pm_mock_${DateTime.now().millisecondsSinceEpoch}',
            'type': 'card',
            'card': {
              'brand': cleanCardNumber.startsWith('4')
                  ? 'visa'
                  : cleanCardNumber.startsWith('5')
                      ? 'mastercard'
                      : 'amex',
              'last4': cleanCardNumber.substring(cleanCardNumber.length - 4),
              'exp_month': int.parse(expiryMonth),
              'exp_year': int.parse(expiryYear),
            },
          },
        };
      }

      return {
        'success': false,
        'error': 'Invalid card number. Please use a valid test card.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Payment processing failed: $e',
      };
    }
  }

  // Create customer for recurring payments
  static Future<Map<String, dynamic>> createCustomer({
    required String email,
    required String name,
    String? phone,
  }) async {
    if (AppConfig.useMockStripe) {
      return {
        'id': 'cus_mock_${DateTime.now().millisecondsSinceEpoch}',
        'email': email,
        'name': name,
        if (phone != null) 'phone': phone,
      };
    }

    return _invokeSecretAction('createCustomer', {
      'email': email,
      'name': name,
      if (phone != null) 'phone': phone,
    });
  }

  // Create subscription for recurring billing
  static Future<Map<String, dynamic>> createSubscription({
    required String customerId,
    required String priceId,
    required String paymentMethodId,
  }) async {
    if (AppConfig.useMockStripe) {
      return {
        'id': 'sub_mock_${DateTime.now().millisecondsSinceEpoch}',
        'customer': customerId,
        'status': 'active',
      };
    }

    return _invokeSecretAction('createSubscription', {
      'customerId': customerId,
      'priceId': priceId,
      'paymentMethodId': paymentMethodId,
    });
  }

  // Get payment methods for a customer
  static Future<List<Map<String, dynamic>>> getPaymentMethods({
    required String customerId,
  }) async {
    if (AppConfig.useMockStripe) {
      return const [];
    }

    final result = await _invokeSecretAction('getPaymentMethods', {
      'customerId': customerId,
    });
    final data = result['data'];
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [];
  }

  // Cancel subscription
  static Future<Map<String, dynamic>> cancelSubscription({
    required String subscriptionId,
  }) async {
    if (AppConfig.useMockStripe) {
      return {
        'id': subscriptionId,
        'status': 'canceled',
      };
    }

    return _invokeSecretAction('cancelSubscription', {
      'subscriptionId': subscriptionId,
    });
  }

  /// Calls the `stripe-secret` Edge Function. Never sends a Stripe secret.
  /// Requires a Supabase Auth session (`verify_jwt=true`). Not used while
  /// [AppConfig.useMockStripe] is true (default until launch).
  static Future<Map<String, dynamic>> _invokeSecretAction(
    String action,
    Map<String, dynamic> payload,
  ) async {
    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session == null) {
        throw Exception(
          'stripe-secret requires a Supabase Auth session',
        );
      }
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
          throw Exception('Stripe function error: ${map['error']}');
        }
        return map;
      }
      throw Exception('Unexpected stripe-secret response');
    } on FunctionException catch (e) {
      throw Exception(
        'Stripe function failed (${e.status}): ${e.details ?? e.reasonPhrase}',
      );
    }
  }

  // Test card numbers for development
  static const Map<String, String> testCards = {
    'visa_success': '4242424242424242',
    'visa_declined': '4000000000000002',
    'visa_insufficient_funds': '4000000000009995',
    'mastercard_success': '5555555555554444',
    'amex_success': '378282246310005',
  };
}
