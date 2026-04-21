import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/providers/auth_provider.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/theme/app_theme.dart';

/// Handles OAuth / token redirect callbacks.
/// Shown briefly while the app processes the token and navigates.
class LoginCallbackScreen extends ConsumerStatefulWidget {
  const LoginCallbackScreen({super.key});

  @override
  ConsumerState<LoginCallbackScreen> createState() => _LoginCallbackScreenState();
}

class _LoginCallbackScreenState extends ConsumerState<LoginCallbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleCallback());
  }

  Future<void> _handleCallback() async {
    try {
      final uri   = Uri.base;
      final token = uri.queryParameters['access_token'];

      if (token == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await ref.read(authProvider.notifier).processNewToken(token);
      final user = ref.read(authProvider);

      if (!mounted) return;

      if (user != null && user.role != null) {
        Navigator.pushReplacementNamed(context, '/${user.role!.toLowerCase()}/home');
      } else {
        await ref.read(authProvider.notifier).logout();
        Navigator.pushReplacementNamed(context, '/login');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)?.authenticationFailed ?? 'Login failed'),
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (_) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: theme.colorScheme.primary),
              const SizedBox(height: AppSpacing.xl),
              Text(
                AppLocalizations.of(context)?.loading ?? 'Processing login…',
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
