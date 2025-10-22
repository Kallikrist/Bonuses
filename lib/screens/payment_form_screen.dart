import 'package:flutter/material.dart';
import 'dart:io';
import '../services/stripe_service.dart';
import '../services/storage_service.dart';
import '../models/financial_transaction.dart';
import '../models/payment_card.dart';
import '../models/company_subscription.dart';

class PaymentFormScreen extends StatefulWidget {
  final String companyId;
  final double amount;
  final String description;

  const PaymentFormScreen({
    Key? key,
    required this.companyId,
    required this.amount,
    required this.description,
  }) : super(key: key);

  @override
  State<PaymentFormScreen> createState() => _PaymentFormScreenState();
}

class _PaymentFormScreenState extends State<PaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryMonthController = TextEditingController();
  final _expiryYearController = TextEditingController();
  final _cvcController = TextEditingController();
  final _cardholderNameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isApplePayAvailable = false;
  bool _isApplePayLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeStripe();
    _checkApplePayAvailability();
  }

  Future<void> _initializeStripe() async {
    try {
      await StripeService.initialize();
      print('Payment system initialized (mock mode)');
    } catch (e) {
      print('Payment system initialization failed: $e');
      // Continue with mock mode - no error shown to user
    }
  }

  Future<void> _checkApplePayAvailability() async {
    if (Platform.isIOS || Platform.isMacOS) {
      try {
        final isAvailable = await StripeService.isApplePayAvailable();
        setState(() {
          _isApplePayAvailable = isAvailable;
        });
      } catch (e) {
        print('Apple Pay availability check failed: $e');
      }
    }
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryMonthController.dispose();
    _expiryYearController.dispose();
    _cvcController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Create payment intent
      final paymentIntent = await StripeService.createPaymentIntent(
        companyId: widget.companyId,
        amount: widget.amount,
        currency: 'USD',
        description: widget.description,
      );

      // Process payment
      final result = await StripeService.processPayment(
        paymentIntentId: paymentIntent['id'],
        cardNumber: _cardNumberController.text.replaceAll(' ', ''),
        expiryMonth: _expiryMonthController.text,
        expiryYear: _expiryYearController.text,
        cvc: _cvcController.text,
        cardholderName: _cardholderNameController.text,
      );

      if (result['success']) {
        // Save payment card
        final cardNumber = _cardNumberController.text.replaceAll(' ', '');
        final paymentCard = PaymentCard(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          companyId: widget.companyId,
          userId:
              'current_user', // You might want to get this from your auth system
          lastFourDigits: cardNumber.substring(cardNumber.length - 4),
          brand: _getCardBrand(cardNumber),
          cardType: _getCardType(cardNumber),
          expiryMonth: int.parse(_expiryMonthController.text),
          expiryYear: int.parse(_expiryYearController.text),
          cardholderName: _cardholderNameController.text,
          status: CardStatus.active,
          createdAt: DateTime.now(),
          isDefault: true,
        );

        await StorageService.addPaymentCard(paymentCard);

        // Create financial transaction record
        final transaction = FinancialTransaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          companyId: widget.companyId,
          userId: 'current_user',
          paymentCardId: paymentCard.id,
          amount: widget.amount,
          currency: 'USD',
          status: TransactionStatus.completed,
          type: TransactionType.subscription,
          category: TransactionCategory.subscription,
          description: widget.description,
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
        );

        await StorageService.addFinancialTransaction(transaction);

        // Update subscription status to active
        final subscriptions = await StorageService.getSubscriptions();
        print('DEBUG: Payment - Found ${subscriptions.length} subscriptions');
        print('DEBUG: Payment - Looking for companyId: ${widget.companyId}');

        final companySubscription = subscriptions.firstWhere(
          (sub) => sub.companyId == widget.companyId,
          orElse: () => subscriptions.first,
        );

        print(
            'DEBUG: Payment - Found subscription: status=${companySubscription.status}, price=\$${companySubscription.currentPrice}');

        final updatedSubscription = companySubscription.copyWith(
          status: SubscriptionStatus.active,
          updatedAt: DateTime.now(),
        );

        print(
            'DEBUG: Payment - Updating subscription to: status=${updatedSubscription.status}');

        await StorageService.updateSubscription(updatedSubscription);

        print('DEBUG: Payment - Subscription update completed');

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful! Subscription activated.'),
              backgroundColor: Colors.green,
            ),
          );
          // Add a small delay to ensure the subscription is saved
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Payment failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processApplePayPayment() async {
    setState(() {
      _isApplePayLoading = true;
      _errorMessage = null;
    });

    try {
      // Create Apple Pay payment intent
      final paymentIntent = await StripeService.createApplePayPaymentIntent(
        amount: widget.amount,
        currency: 'USD',
        description: widget.description,
      );

      if (!paymentIntent['success']) {
        setState(() {
          _errorMessage = paymentIntent['error'];
        });
        return;
      }

      // Process Apple Pay payment
      final result = await StripeService.processApplePayPayment(
        paymentIntentId: paymentIntent['client_secret'],
        amount: widget.amount,
        currency: 'USD',
        description: widget.description,
      );

      if (result['success']) {
        // Save Apple Pay as payment method
        final paymentCard = PaymentCard(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          companyId: widget.companyId,
          userId: 'current_user',
          lastFourDigits: '****',
          brand: 'apple_pay',
          cardType: CardType.applePay,
          expiryMonth: 0,
          expiryYear: 0,
          cardholderName: 'Apple Pay',
          status: CardStatus.active,
          createdAt: DateTime.now(),
          isDefault: true,
        );

        await StorageService.addPaymentCard(paymentCard);

        // Create financial transaction
        final transaction = FinancialTransaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          companyId: widget.companyId,
          userId: 'current_user',
          type: TransactionType.payment,
          status: TransactionStatus.completed,
          category: TransactionCategory.subscription,
          amount: widget.amount,
          currency: 'USD',
          description: widget.description,
          createdAt: DateTime.now(),
          completedAt: DateTime.now(),
          paymentCardId: paymentCard.id,
          receiptUrl:
              'apple_pay_receipt_${DateTime.now().millisecondsSinceEpoch}',
        );

        await StorageService.addFinancialTransaction(transaction);

        // Update subscription status to active
        final subscriptions = await StorageService.getSubscriptions();
        print('DEBUG: Payment - Found ${subscriptions.length} subscriptions');
        print('DEBUG: Payment - Looking for companyId: ${widget.companyId}');

        final companySubscription = subscriptions.firstWhere(
          (sub) => sub.companyId == widget.companyId,
          orElse: () => subscriptions.first,
        );

        print('DEBUG: Payment - Found subscription: ${companySubscription.id}');
        print('DEBUG: Payment - Current status: ${companySubscription.status}');

        final updatedSubscription = companySubscription.copyWith(
          status: SubscriptionStatus.active,
          updatedAt: DateTime.now(),
        );

        await StorageService.updateSubscription(updatedSubscription);
        print(
            'DEBUG: Payment - Updated subscription status to: ${updatedSubscription.status}');

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Apple Pay payment successful! Subscription activated.'),
              backgroundColor: Colors.green,
            ),
          );
          // Add a small delay to ensure the subscription is saved
          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _errorMessage = result['error'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Apple Pay payment failed: $e';
      });
    } finally {
      setState(() {
        _isApplePayLoading = false;
      });
    }
  }

  CardType _getCardType(String cardNumber) {
    if (cardNumber.startsWith('4')) return CardType.visa;
    if (cardNumber.startsWith('5')) return CardType.mastercard;
    if (cardNumber.startsWith('3')) return CardType.americanExpress;
    return CardType.unknown;
  }

  String _getCardBrand(String cardNumber) {
    if (cardNumber.startsWith('4')) return 'visa';
    if (cardNumber.startsWith('5')) return 'mastercard';
    if (cardNumber.startsWith('3')) return 'amex';
    return 'unknown';
  }

  String _formatCardNumber(String value) {
    // Remove all non-digits
    String digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    // Add spaces every 4 digits
    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += digitsOnly[i];
    }

    return formatted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Payment amount
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Column(
                  children: [
                    Text(
                      'Payment Amount',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.purple[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${widget.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.purple[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.purple[600],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Card number
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Card Number',
                  hintText: '1234 5678 9012 3456',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _cardNumberController.value = TextEditingValue(
                    text: _formatCardNumber(value),
                    selection: TextSelection.collapsed(
                        offset: _formatCardNumber(value).length),
                  );
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter card number';
                  }
                  final digitsOnly = value.replaceAll(' ', '');
                  if (digitsOnly.length < 13 || digitsOnly.length > 19) {
                    return 'Please enter a valid card number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Cardholder name
              TextFormField(
                controller: _cardholderNameController,
                decoration: const InputDecoration(
                  labelText: 'Cardholder Name',
                  hintText: 'John Doe',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter cardholder name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Expiry and CVC
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryMonthController,
                      decoration: const InputDecoration(
                        labelText: 'Month',
                        hintText: 'MM',
                        prefixIcon: Icon(Icons.calendar_month),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'MM';
                        }
                        final month = int.tryParse(value);
                        if (month == null || month < 1 || month > 12) {
                          return 'Invalid month';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _expiryYearController,
                      decoration: const InputDecoration(
                        labelText: 'Year',
                        hintText: 'YYYY',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'YYYY';
                        }
                        final year = int.tryParse(value);
                        if (year == null || year < DateTime.now().year) {
                          return 'Invalid year';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _cvcController,
                      decoration: const InputDecoration(
                        labelText: 'CVC',
                        hintText: '123',
                        prefixIcon: Icon(Icons.security),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'CVC';
                        }
                        if (value.length < 3 || value.length > 4) {
                          return 'Invalid CVC';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Error message
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red[700]),
                  ),
                ),

              const SizedBox(height: 24),

              // Apple Pay button (iOS only)
              if (_isApplePayAvailable) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed:
                        _isApplePayLoading ? null : _processApplePayPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isApplePayLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.apple,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Pay with Apple Pay',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Pay button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Pay \$${widget.amount}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Test card info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Cards (Development Only)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Visa Success: 4242424242424242\nVisa Declined: 4000000000000002\nMastercard: 5555555555554444',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                      ),
                    ),
                    Text(
                      'Use any future expiry date and any 3-digit CVC',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
