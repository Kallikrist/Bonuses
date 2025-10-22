import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class StripeService {
  // Stripe configuration
  static const String _publishableKey =
      'pk_test_51234567890abcdef'; // Replace with your test key
  static const String _secretKey =
      'sk_test_51234567890abcdef'; // Replace with your secret key
  static const String _baseUrl = 'https://api.stripe.com/v1';

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

  // Create payment intent for $1 subscription (Mock for demo)
  static Future<Map<String, dynamic>> createPaymentIntent({
    required String companyId,
    required double amount,
    required String currency,
    required String description,
  }) async {
    // Mock payment intent for demo purposes
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
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/customers'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'email': email,
          'name': name,
          if (phone != null) 'phone': phone,
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create customer: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating customer: $e');
    }
  }

  // Create subscription for recurring billing
  static Future<Map<String, dynamic>> createSubscription({
    required String customerId,
    required String priceId,
    required String paymentMethodId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/subscriptions'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'customer': customerId,
          'items[0][price]': priceId,
          'default_payment_method': paymentMethodId,
          'expand[]': 'latest_invoice.payment_intent',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create subscription: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating subscription: $e');
    }
  }

  // Get payment methods for a customer
  static Future<List<Map<String, dynamic>>> getPaymentMethods({
    required String customerId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payment_methods?customer=$customerId&type=card'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['data']);
      } else {
        throw Exception('Failed to get payment methods: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting payment methods: $e');
    }
  }

  // Cancel subscription
  static Future<Map<String, dynamic>> cancelSubscription({
    required String subscriptionId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/subscriptions/$subscriptionId'),
        headers: {
          'Authorization': 'Bearer $_secretKey',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to cancel subscription: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error canceling subscription: $e');
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
