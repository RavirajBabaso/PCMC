import 'package:flutter/material.dart';
import 'package:main_ui/layouts/app_shell.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppShell(
      title: l10n.privacyPolicy,
      currentRoute: '/privacy-policy',
      bottomNavCurrentRoute: '/profile',
      backgroundColor: dsBackground,
      appBarBackgroundColor: dsSurface,
      appBarForegroundColor: dsTextPrimary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          color: dsSurfaceAlt,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.privacyPolicyCommitmentTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: dsTextPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.privacyPolicyCommitmentBody,
                  style: const TextStyle(fontSize: 16, color: dsTextPrimary, height: 1.5),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.privacyPolicyDataCollectionTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: dsTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.privacyPolicyDataCollectionBody,
                  style: const TextStyle(fontSize: 15, color: dsTextSecondary, height: 1.4),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.privacyPolicyDataUsageTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: dsTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.privacyPolicyDataUsageBody,
                  style: const TextStyle(fontSize: 15, color: dsTextSecondary, height: 1.4),
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.privacyPolicySecurityTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: dsTextPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.privacyPolicySecurityBody,
                  style: const TextStyle(fontSize: 15, color: dsTextSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
