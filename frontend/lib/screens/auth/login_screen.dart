import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/providers/auth_provider.dart';
import 'package:main_ui/utils/validators.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/widgets/app/app_button.dart';
import 'package:main_ui/exceptions/auth_exception.dart';
import 'package:main_ui/services/api_service.dart';
import 'package:main_ui/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  String _name = '';
  String _email = '';
  String _password = '';
  String _address = '';
  String _phone = '';
  String _voterId = '';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await ref.read(authProvider.notifier).loginWithEmail(_email, _password);
      } else {
        await ref.read(authProvider.notifier).register(
          _name, _email, _password,
          address: _address, phoneNumber: _phone, voterId: _voterId,
        );
      }

      final user = ref.read(authProvider);
      if (!mounted) return;
      if (user != null) {
        Navigator.pushReplacementNamed(context, '/${user.role}/home');
      } else {
        _showError(AppLocalizations.of(context)!.authenticationFailed);
      }
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final message = e is AuthException ? e.message : l10n.authenticationFailed;
      _showErrorDialog(
        _isLogin ? l10n.loginFailed : l10n.registrationFailed,
        message,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _showErrorDialog(String title, String message) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPasswordReset(String email) async {
    try {
      final response = await ApiService.post('/auth/forgot-password', {'email': email});
      if (!mounted) return;
      Navigator.of(context).pop();
      final data = response.data;
      final message = data['message'] ?? (data['error'] ?? 'Unknown response');
      final isSuccess = !message.toLowerCase().contains('error') &&
          !message.toLowerCase().contains('failed');
      _showError(isSuccess
          ? 'Reset link sent! Check your email at https://www.nivaran.co.in.'
          : message);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showError('Error sending reset email: $e');
      }
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _ForgotPasswordDialog(onSubmit: _requestPasswordReset),
    );
  }

  String? _validatePhone(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) return l10n.phoneNumberRequired;
    if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(value)) return l10n.invalidMobileNumber;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n  = AppLocalizations.of(context)!;
    final primary = theme.colorScheme.primary;

    return Scaffold(
      // No AppBar — full immersive auth experience
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.xxl),

              // ── App identity ─────────────────────────────────────────────
              Icon(Icons.gavel_rounded, size: 56, color: primary),
              const SizedBox(height: AppSpacing.base),
              Text(
                'NIVARAN',
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _isLogin ? l10n.welcomeBack : l10n.createAccountPrompt,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Toggle chip ──────────────────────────────────────────────
              _AuthToggle(
                isLogin: _isLogin,
                loginLabel: l10n.login,
                registerLabel: l10n.register,
                onToggle: (v) => setState(() {
                  _isLogin = v;
                  _formKey.currentState?.reset();
                }),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Form ─────────────────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Register-only fields
                    if (!_isLogin) ...[
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: validateRequired,
                        onSaved: (v) => _name = v!.trim(),
                      ),
                      const SizedBox(height: AppSpacing.base),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          prefixIcon: Icon(Icons.home_outlined),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: validateRequired,
                        onSaved: (v) => _address = v!.trim(),
                      ),
                      const SizedBox(height: AppSpacing.base),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: (v) => _validatePhone(v, l10n),
                        onSaved: (v) => _phone = v!.trim(),
                      ),
                      const SizedBox(height: AppSpacing.base),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Voter ID',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: validateRequired,
                        onSaved: (v) => _voterId = v!.trim(),
                      ),
                      const SizedBox(height: AppSpacing.base),
                    ],

                    // Common fields
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: validateEmail,
                      onSaved: (v) => _email = v!.trim(),
                    ),
                    const SizedBox(height: AppSpacing.base),

                    TextFormField(
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: _isLogin
                          ? TextInputAction.done
                          : TextInputAction.next,
                      autofillHints: const [AutofillHints.password],
                      validator: validateRequired,
                      onSaved: (v) => _password = v!,
                      onFieldSubmitted: (_) => _submit(),
                    ),

                    // Forgot password
                    if (_isLogin) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          child: Text(
                            l10n.forgotPassword ?? 'Forgot Password?',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),

                    // Submit button
                    AppButton(
                      text: _isLogin ? l10n.login : l10n.register,
                      onPressed: _isLoading ? null : _submit,
                      isLoading: _isLoading,
                      fullWidth: true,
                      size: AppButtonSize.large,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Switch mode row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLogin ? l10n.registerPrompt : l10n.loginPrompt,
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () => setState(() {
                            _isLogin = !_isLogin;
                            _formKey.currentState?.reset();
                          }),
                          child: Text(
                            _isLogin ? l10n.register : l10n.login,
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth Toggle (Login / Register segmented switch)
// ─────────────────────────────────────────────────────────────────────────────
class _AuthToggle extends StatelessWidget {
  const _AuthToggle({
    required this.isLogin,
    required this.loginLabel,
    required this.registerLabel,
    required this.onToggle,
  });

  final bool isLogin;
  final String loginLabel;
  final String registerLabel;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          _tab(context, loginLabel, isLogin, () => onToggle(true), primary),
          _tab(context, registerLabel, !isLogin, () => onToggle(false), primary),
        ],
      ),
    );
  }

  Widget _tab(BuildContext ctx, String label, bool selected, VoidCallback onTap, Color primary) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Theme.of(ctx).colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Forgot Password Dialog
// ─────────────────────────────────────────────────────────────────────────────
class _ForgotPasswordDialog extends StatefulWidget {
  const _ForgotPasswordDialog({required this.onSubmit});
  final Future<void> Function(String) onSubmit;

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _emailCtrl = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool _sending    = false;

  bool get _valid =>
      _emailCtrl.text.isNotEmpty &&
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(_emailCtrl.text);

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending || !_valid) return;
    setState(() => _sending = true);
    try {
      await widget.onSubmit(_emailCtrl.text.trim());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Password'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter your email address. We'll send you a reset link.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.base),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _submit(),
              validator: validateEmail,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _sending || !_valid ? null : _submit,
          child: _sending
              ? const SizedBox(
                  width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Link'),
        ),
      ],
    );
  }
}
