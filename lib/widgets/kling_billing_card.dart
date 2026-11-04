import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../services/kling_service.dart';
import '../utils/app_semantics.dart';
import '../utils/error_handler.dart';
import 'kling_checkout_overlay.dart';

/// Store-manager Kling subscribe + billing portal. Demo-gated until launch.
class KlingBillingCard extends StatefulWidget {
  final String companyId;
  final String customerEmail;
  final String customerName;
  final String? customerPhone;

  const KlingBillingCard({
    super.key,
    required this.companyId,
    required this.customerEmail,
    required this.customerName,
    this.customerPhone,
  });

  @override
  State<KlingBillingCard> createState() => _KlingBillingCardState();
}

class _KlingBillingCardState extends State<KlingBillingCard> {
  bool _busy = false;

  Future<void> _subscribe() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final session = await KlingService.createCheckoutSession(
        companyId: widget.companyId,
        customerEmail: widget.customerEmail,
        customerName: widget.customerName,
        customerPhone: widget.customerPhone,
      );
      if (!mounted) return;
      setState(() => _busy = false);
      final result = await KlingCheckoutOverlay.show(
        context,
        session: session,
      );
      if (!mounted || result == null || result.canceled) return;

      if (AppConfig.useMockKling) {
        await KlingService.rememberMockCustomer(widget.companyId);
      } else if (result.paid) {
        final paid = await KlingService.getCheckoutSession(
          sessionId: result.sessionId,
        );
        await KlingService.rememberFromCheckoutSession(
          companyId: widget.companyId,
          session: paid,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppConfig.useMockKling
                ? 'Demo Kling checkout complete. No live charge.'
                : 'Kling checkout submitted. Access updates when the payment is confirmed.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorHandler.getSanitizedMessage(
              e,
              defaultMessage: 'Kling checkout failed. Please try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openPortal() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final customerId = await KlingService.storedCustomerId(widget.companyId);
      if (customerId == null || customerId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscribe with Kling before opening the billing portal.'),
          ),
        );
        return;
      }

      final session = await KlingService.createBillingPortalSession(
        customerId: customerId,
        returnUrl: KlingService.defaultReturnUrl(
          webOrigin: kIsWeb ? Uri.base.toString() : null,
        ),
        subscriptionId:
            await KlingService.storedSubscriptionId(widget.companyId),
      );
      if (!mounted) return;
      setState(() => _busy = false);
      await openKlingBillingPortal(context, session: session);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ErrorHandler.getSanitizedMessage(
              e,
              defaultMessage: 'Kling billing portal failed. Please try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final demo = AppConfig.useMockKling;
    return Semantics(
      identifier: AppSemantics.klingBilling,
      container: true,
      explicitChildNodes: true,
      label: AppSemantics.klingBilling,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.credit_card, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Kling (Iceland)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Card-only recurring store subscription. Amounts are whole '
                'krónur (ISK).',
              ),
              if (demo) ...[
                const SizedBox(height: 8),
                Semantics(
                  identifier: AppSemantics.klingDemoNotice,
                  liveRegion: true,
                  label: AppSemantics.klingDemoNotice,
                  child: Text(
                    'Demo mode — no live Kling charges.',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      identifier: AppSemantics.klingSubscribe,
                      button: true,
                      enabled: !_busy,
                      label: AppSemantics.klingSubscribe,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _subscribe,
                        icon: _busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.payment),
                        label: const Text('Subscribe with Kling'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      identifier: AppSemantics.klingManageBilling,
                      button: true,
                      enabled: !_busy,
                      label: AppSemantics.klingManageBilling,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _openPortal,
                        icon: const Icon(Icons.manage_accounts),
                        label: const Text('Manage billing'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
