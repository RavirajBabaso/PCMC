import 'package:flutter/material.dart';
import 'package:main_ui/layouts/app_shell.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/theme/app_theme.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionScreen extends StatefulWidget {
  const AppVersionScreen({super.key});

  @override
  State<AppVersionScreen> createState() => _AppVersionScreenState();
}

class _AppVersionScreenState extends State<AppVersionScreen> {
  String version = '';
  String appName = '';
  String packageName = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    if (version.isEmpty) {
      version = AppLocalizations.of(context)?.loadingData ?? 'Loading...';
    }
    setState(() {
      version = '${info.version} (Build ${info.buildNumber})';
      appName = info.appName;
      packageName = info.packageName;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppShell(
      title: l10n.appVersion,
      currentRoute: '/app-version',
      bottomNavCurrentRoute: '/profile',
      backgroundColor: dsBackground,
      appBarBackgroundColor: dsSurface,
      appBarForegroundColor: dsTextPrimary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: dsPanelDecoration(color: dsSurface, radius: 24),
              child: Column(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [dsAccentSoft, dsAccentDim],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: dsAccent.withOpacity(0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.apps_rounded,
                      size: 46,
                      color: dsBackground,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    appName.isNotEmpty ? appName : l10n.appNameFallback,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: dsTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    packageName.isNotEmpty ? packageName : l10n.packageNameFallback,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: dsTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: dsAccent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: dsAccent.withOpacity(0.34)),
                    ),
                    child: Text(
                      version.isEmpty ? l10n.loadingData : version,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: dsAccentSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = constraints.maxWidth > 540
                    ? (constraints.maxWidth - 12) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _buildInfoItem(
                        icon: Icons.update_rounded,
                        title: l10n.lastUpdated,
                        value: 'October 2023',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildInfoItem(
                        icon: Icons.system_security_update_rounded,
                        title: l10n.minimumOS,
                        value: 'Android 8.0+',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: dsPanelDecoration(color: dsSurfaceAlt, radius: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: dsAccentSoft),
                      SizedBox(width: 10),
                    ],
                  ),
                  Text(
                    l10n.versionInformation,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: dsTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Keep your app current for the latest fixes, stability improvements, and public service updates.',
                    style: TextStyle(
                      fontSize: 14,
                      color: dsTextSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildVersionInfoItem(
                    l10n.currentVersion,
                    version.isEmpty ? l10n.loadingData : version,
                    dsAccentSoft,
                  ),
                  const SizedBox(height: 10),
                  _buildVersionInfoItem(l10n.status, l10n.upToDate, AppTheme.success),
                  const SizedBox(height: 10),
                  _buildVersionInfoItem(l10n.releaseType, 'Stable', dsAccentSoft),
                  const SizedBox(height: 10),
                  _buildVersionInfoItem(l10n.size, '28.5 MB', dsTextSecondary),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Add update functionality here.
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dsAccent,
                        foregroundColor: dsTextPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.system_update_alt_rounded),
                      label: Text(
                        l10n.checkForUpdates,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: dsPanelDecoration(color: dsSurface, radius: 16),
              child: Text(
                l10n.thankYouMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: dsTextSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: dsPanelDecoration(color: dsSurfaceAlt, radius: 18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: dsAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 22, color: dsAccentSoft),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: dsTextSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: dsTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionInfoItem(String title, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: dsTextSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
