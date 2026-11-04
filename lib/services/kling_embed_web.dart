// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:js' as js;

import 'kling_embed_types.dart';

export 'kling_embed_types.dart';

/// True when `Kling.init` from https://api.kling.is/v1/kling.js can run.
bool get isKlingOverlaySupported => true;

/// Opens Kling's embedded checkout overlay. [sessionId] is a UUID from
/// `kling-secret` `createCheckoutSession`. No secret key is used here.
Future<KlingEmbedResult> openKlingEmbeddedCheckout({
  required String sessionId,
  String locale = 'is',
}) async {
  final klingNs = js.context['Kling'];
  if (klingNs == null || klingNs is! js.JsObject) {
    throw StateError(
      'Kling overlay script is not loaded (https://api.kling.is/v1/kling.js)',
    );
  }

  final completer = Completer<KlingEmbedResult>();
  final instance = klingNs.callMethod('init', [
    js.JsObject.jsify({'locale': locale}),
  ]);
  if (instance is! js.JsObject) {
    throw StateError('Kling.init did not return an overlay instance');
  }

  instance.callMethod('checkout', [
    js.JsObject.jsify({
      'sessionId': sessionId,
      'onSuccess': js.allowInterop((dynamic res) {
        if (completer.isCompleted) return;
        var id = sessionId;
        var status = 'paid';
        if (res is js.JsObject) {
          id = res['sessionId']?.toString() ?? id;
          status = res['paymentStatus']?.toString() ?? status;
        }
        completer.complete(
          KlingEmbedResult(
            sessionId: id,
            paymentStatus: status,
          ),
        );
      }),
      'onCancel': js.allowInterop(() {
        if (completer.isCompleted) return;
        completer.complete(
          KlingEmbedResult(sessionId: sessionId, canceled: true),
        );
      }),
    }),
  ]);

  return completer.future;
}
