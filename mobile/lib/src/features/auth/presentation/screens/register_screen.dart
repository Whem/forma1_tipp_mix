import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:forma1_tipp/l10n/app_localizations.dart';
import 'package:forma1_tipp/src/core/widgets/app_gradient_background.dart';
import 'package:forma1_tipp/src/core/widgets/glass_card.dart';
import 'package:forma1_tipp/src/features/auth/presentation/auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _displayName = TextEditingController();
  String? _language;
  bool _isAIAssisted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _language ??= _detectLanguage();
  }

  String _detectLanguage() {
    final locale = Localizations.localeOf(context).languageCode;
    return locale == 'hu' ? 'hu' : 'en';
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _displayName.dispose();
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
        final message = error is FirebaseAuthException
            ? (error.message ?? l10n.errorGeneric)
            : l10n.errorGeneric;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
      if (!next.isLoading && next.valueOrNull?.isAuthenticated == true) {
        context.go('/home');
      }
    });

    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.register)),
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
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.length < 6)
                              ? 'Min 6 characters'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _displayName,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: l10n.nickname,
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Enter a display name'
                              : null,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: _language ?? 'en',
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'hu', child: Text('Magyar')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _language = v);
                      },
                      decoration: InputDecoration(
                        labelText: l10n.language,
                        prefixIcon: const Icon(Icons.language),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      value: _isAIAssisted,
                      onChanged: (v) => setState(() => _isAIAssisted = v),
                      title: Text(
                        isHu
                            ? 'AI segítséget használok'
                            : 'I use AI assistance',
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        isHu
                            ? 'Jelöld be, ha AI eszközöket használsz a tippjeidhez. Külön ranglistán versenyzel.'
                            : 'Check if you use AI tools for your predictions. You\'ll compete in a separate leaderboard.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                      secondary: const Icon(Icons.smart_toy_outlined),
                      contentPadding: EdgeInsets.zero,
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
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'Already have an account? ${l10n.login}',
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
    ref.read(authControllerProvider.notifier).register(
      email: _email.text.trim(),
      password: _password.text,
      displayName: _displayName.text.trim(),
      language: _language ?? 'en',
      isAIAssisted: _isAIAssisted,
    );
  }
}
