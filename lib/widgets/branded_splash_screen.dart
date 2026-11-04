import 'package:flutter/material.dart';

class BrandedSplashScreen extends StatelessWidget {
  final String companyName;
  final bool showProgress;

  const BrandedSplashScreen({
    super.key,
    required this.companyName,
    this.showProgress = true,
  });

  bool get _isAppBrand => companyName == 'Bonuses';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    scheme.surface,
                    scheme.primaryContainer.withValues(alpha: 0.45),
                    scheme.surface,
                  ]
                : [
                    scheme.primaryContainer.withValues(alpha: 0.55),
                    scheme.secondaryContainer.withValues(alpha: 0.4),
                    scheme.surface,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.shadow
                              .withValues(alpha: isDark ? 0.35 : 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isAppBrand ? Icons.emoji_events : Icons.business,
                      size: 60,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Semantics(
                    header: true,
                    label: companyName,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Text(
                        companyName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: companyName.length > 18 ? 32 : 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: companyName.length > 18 ? 0.5 : 1.2,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bonuses & Rewards',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 60),
                  if (showProgress) ...[
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
