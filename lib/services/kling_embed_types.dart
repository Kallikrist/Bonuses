/// Result of opening Kling checkout (embedded overlay, hosted URL, or demo).
class KlingEmbedResult {
  final String sessionId;
  final String? paymentStatus;
  final bool canceled;
  final bool hostedRedirect;
  final bool demo;

  const KlingEmbedResult({
    required this.sessionId,
    this.paymentStatus,
    this.canceled = false,
    this.hostedRedirect = false,
    this.demo = false,
  });

  bool get paid => !canceled && paymentStatus == 'paid';
}
