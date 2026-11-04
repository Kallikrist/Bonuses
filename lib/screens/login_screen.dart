import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../utils/error_handler.dart';
import '../utils/app_semantics.dart';
import '../providers/app_provider.dart';
import 'onboarding_screen.dart';
import '../services/auth_service.dart';
import '../services/validation_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await context.read<AppProvider>().login(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (!success && mounted) {
        _showLoginMessage(
          'Invalid email or password',
          Theme.of(context).colorScheme.error,
          Theme.of(context).colorScheme.onError,
        );
      }
    } on RateLimitException catch (e) {
      if (mounted) {
        _showLoginMessage(
          e.message,
          Theme.of(context).colorScheme.tertiary,
          Theme.of(context).colorScheme.onTertiary,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      if (mounted && e is! RateLimitException) {
        if (kDebugMode) {
          print('DEBUG: Login error: $e');
        }
        _showLoginMessage(
          ErrorHandler.getSanitizedMessage(e,
              defaultMessage: 'Login failed. Please try again.'),
          Theme.of(context).colorScheme.error,
          Theme.of(context).colorScheme.onError,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showLoginMessage(
    String message,
    Color background,
    Color foreground, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: foreground)),
        backgroundColor: background,
        duration: duration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = context.watch<AppProvider>().isDarkMode;

    final loginCard = Card(
      elevation: 8,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: AutofillGroup(
          child: Semantics(
            identifier: AppSemantics.loginForm,
            container: true,
            explicitChildNodes: true,
            label: AppSemantics.loginForm,
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 64,
                    color: colorScheme.primary,
                    semanticLabel: 'Bonuses App',
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    label: 'Bonuses App',
                    child: Text(
                      'Bonuses App',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track sales targets and earn points!',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Semantics(
                    identifier: AppSemantics.emailField,
                    textField: true,
                    label: AppSemantics.emailField,
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.none,
                      maxLength: ValidationService.maxEmailLength,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(
                          Icons.email,
                          semanticLabel: AppSemantics.emailField,
                        ),
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      validator: ValidationService.validateEmail,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    identifier: AppSemantics.passwordField,
                    textField: true,
                    obscured: true,
                    label: AppSemantics.passwordField,
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) {
                        if (!_isLoading) _login();
                      },
                      maxLength: ValidationService.maxPasswordLength,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(
                          Icons.lock,
                          semanticLabel: AppSemantics.passwordField,
                        ),
                        border: const OutlineInputBorder(),
                        counterText: '',
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? AppSemantics.showPassword
                              : AppSemantics.hidePassword,
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            semanticLabel: _obscurePassword
                                ? AppSemantics.showPassword
                                : AppSemantics.hidePassword,
                          ),
                        ),
                      ),
                      validator: (value) => ValidationService.validatePassword(
                          value,
                          isNewPassword: false),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Semantics(
                      identifier: AppSemantics.loginButton,
                      button: true,
                      enabled: !_isLoading,
                      label: _isLoading
                          ? AppSemantics.signingIn
                          : AppSemantics.loginButton,
                      excludeSemantics: true,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : const Text('Login'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      Text(
                        'Don\'t have an account?',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Semantics(
                        identifier: AppSemantics.createCompany,
                        button: true,
                        label: AppSemantics.createCompany,
                        excludeSemantics: true,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const OnboardingScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.primary,
                          ),
                          child: const Text('Create Company'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Semantics(
      identifier: AppSemantics.loginScreen,
      container: true,
      explicitChildNodes: true,
      namesRoute: true,
      label: AppSemantics.loginScreen,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primary,
                colorScheme.primaryContainer,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip:
                        isDark ? AppSemantics.lightMode : AppSemantics.darkMode,
                    onPressed: () =>
                        context.read<AppProvider>().toggleDarkMode(),
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      color: colorScheme.onPrimary,
                      semanticLabel: isDark
                          ? AppSemantics.lightMode
                          : AppSemantics.darkMode,
                    ),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: (constraints.maxHeight - 24)
                                .clamp(0.0, double.infinity),
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: loginCard,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
