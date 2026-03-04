import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:forma1_tipp/l10n/app_localizations.dart';
import 'package:forma1_tipp/src/core/widgets/app_gradient_background.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';
import 'package:forma1_tipp/src/features/auth/presentation/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _autoLoginAttempted = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _email.text = 'birkusz20@gmail.com';
      _password.text = r'J@3cePcp$VbPGGe';
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isHu = Localizations.localeOf(context).languageCode == 'hu';

    ref.listen(authControllerProvider, (prev, next) {
      if (next.hasError) {
        final error = next.error;
        String message;
        if (error is FirebaseAuthException) {
          switch (error.code) {
            case 'user-not-found':
              message = isHu ? 'Felhasználó nem található' : 'User not found';
              break;
            case 'wrong-password':
            case 'invalid-credential':
              message = isHu ? 'Hibás jelszó' : 'Wrong password';
              break;
            case 'too-many-requests':
              message = isHu ? 'Túl sok próbálkozás, próbáld később' : 'Too many attempts, try later';
              break;
            case 'network-request-failed':
              message = isHu ? 'Hálózati hiba' : 'Network error';
              break;
            default:
              message = error.message ?? l10n.errorGeneric;
          }
        } else {
          message = '${l10n.errorGeneric}: $error';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      if (!next.isLoading && next.valueOrNull?.isAuthenticated == true) {
        context.go('/home');
      }
    });

    final auth = ref.watch(authControllerProvider);

    if (kDebugMode && !_autoLoginAttempted && !auth.isLoading) {
      _autoLoginAttempted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _submit());
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.login)),
      body: AppGradientBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: GlassCard(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ),
                      validator: (v) =>
                          (v == null || !v.contains('@'))
                              ? 'Enter a valid email'
                              : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6)
                              ? 'Min 6 characters'
                              : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: scheme.onPrimary,
                              ),
                            )
                          : Text(l10n.continueLabel),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: Text(
                        "Don't have an account? ${l10n.register}",
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(
                  begin: 0.1,
                  duration: 500.ms,
                  curve: Curves.easeOut,
                ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authControllerProvider.notifier).login(
      email: _email.text.trim(),
      password: _password.text,
    );
  }
}
