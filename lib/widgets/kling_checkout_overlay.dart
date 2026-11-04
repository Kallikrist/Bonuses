import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../services/kling_embed.dart';
import '../services/kling_service.dart';
import '../utils/app_semantics.dart';

/// Opens Kling embedded checkout: demo dialog while [AppConfig.useMockKling]
/// is true, `kling.js` overlay on web when live, hosted session URL otherwise.
class KlingCheckoutOverlay {
  KlingCheckoutOverlay._();

  static Future<KlingEmbedResult?> show(
    BuildContext context, {
    required Map<String, dynamic> session,
    bool? demoMode,
  }) async {
    final sessionId = session['id']?.toString() ?? '';
    final inDemo = demoMode ?? AppConfig.useMockKling;
    if (inDemo) {
      return showDialog<KlingEmbedResult>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const KlingDemoCheckoutDialog(),
      );
    }

    if (isKlingOverlaySupported) {
      return openKlingEmbeddedCheckout(
        sessionId: sessionId,
        locale: KlingService.locale,
      );
    }

    final url = session['url']?.toString();
    if (url == null || url.isEmpty) {
      throw Exception('Kling checkout session is missing a url');
    }
    final uri = Uri.parse(url);
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw Exception('Could not open Kling checkout');
    }
    return KlingEmbedResult(
      sessionId: sessionId,
      hostedRedirect: true,
    );
  }
}

class KlingDemoCheckoutDialog extends StatelessWidget {
  const KlingDemoCheckoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final amount = KlingService.formatIsk(KlingService.mockStoreAmountIsk);
    return Semantics(
      identifier: AppSemantics.klingCheckoutOverlay,
      container: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: AppSemantics.klingCheckoutOverlay,
      child: AlertDialog(
        title: const Text('Kling checkout'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                identifier: AppSemantics.klingDemoNotice,
                liveRegion: true,
                label: AppSemantics.klingDemoNotice,
                child: Text(
                  'Demo mode — card only, no live charges. Recurring store '
                  'subscription $amount (ISK integer, not multiplied by 100).',
                ),
              ),
            ],
          ),
        ),
        actions: [
          Semantics(
            identifier: AppSemantics.klingCheckoutCancel,
            button: true,
            label: AppSemantics.klingCheckoutCancel,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop(
                  const KlingEmbedResult(
                    sessionId: 'demo',
                    canceled: true,
                    demo: true,
                  ),
                );
              },
              child: const Text('Cancel'),
            ),
          ),
          Semantics(
            identifier: AppSemantics.klingCheckoutPay,
            button: true,
            label: AppSemantics.klingCheckoutPay,
            child: FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  const KlingEmbedResult(
                    sessionId: 'demo',
                    paymentStatus: 'paid',
                    demo: true,
                  ),
                );
              },
              child: const Text('Pay with card'),
            ),
          ),
        ],
      ),
    );
  }
}

class KlingDemoPortalDialog extends StatelessWidget {
  const KlingDemoPortalDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: AppSemantics.klingPortal,
      container: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: AppSemantics.klingPortal,
      child: AlertDialog(
        title: const Text('Kling billing portal'),
        content: Semantics(
          identifier: AppSemantics.klingDemoNotice,
          liveRegion: true,
          label: AppSemantics.klingDemoNotice,
          child: const Text(
            'Demo mode — manage card and subscription here after launch. '
            'No live Kling portal and no live charges.',
          ),
        ),
        actions: [
          Semantics(
            identifier: AppSemantics.klingPortalClose,
            button: true,
            label: AppSemantics.klingPortalClose,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the Kling billing portal URL, or a demo stand-in.
Future<void> openKlingBillingPortal(
  BuildContext context, {
  required Map<String, dynamic> session,
  bool? demoMode,
}) async {
  final inDemo = demoMode ?? AppConfig.useMockKling;
  if (inDemo) {
    await showDialog<void>(
      context: context,
      builder: (context) => const KlingDemoPortalDialog(),
    );
    return;
  }

  final url = session['url']?.toString();
  if (url == null || url.isEmpty) {
    throw Exception('Kling billing portal session is missing a url');
  }
  final launched = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!launched) {
    throw Exception('Could not open Kling billing portal');
  }
}
