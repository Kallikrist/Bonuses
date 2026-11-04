import 'kling_embed_types.dart';

export 'kling_embed_types.dart';

/// Browser overlay (`@klingis/embed` / kling.js) is web-only.
bool get isKlingOverlaySupported => false;

/// Non-web platforms fall back to the hosted checkout `url` from the session.
Future<KlingEmbedResult> openKlingEmbeddedCheckout({
  required String sessionId,
  String locale = 'is',
}) async {
  throw UnsupportedError(
    'Kling embedded overlay requires the browser script '
    'https://api.kling.is/v1/kling.js',
  );
}
