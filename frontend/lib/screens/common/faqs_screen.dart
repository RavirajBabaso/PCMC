import 'package:flutter/material.dart';
import 'package:main_ui/layouts/app_shell.dart';
import 'package:main_ui/l10n/app_localizations.dart';
import 'package:main_ui/theme/app_theme.dart';

class FaqsScreen extends StatelessWidget {
  const FaqsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final faqs = [
      {
        'q': l10n.faq1_q,
        'a': l10n.faq1_a,
        'icon': Icons.report_problem_outlined,
      },
      {
        'q': l10n.faq2_q,
        'a': l10n.faq2_a,
        'icon': Icons.track_changes_outlined,
      },
      {
        'q': l10n.faq3_q,
        'a': l10n.faq3_a,
        'icon': Icons.attach_file_outlined,
      },
      {
        'q': l10n.faq4_q,
        'a': l10n.faq4_a,
        'icon': Icons.schedule_outlined,
      },
      {
        'q': l10n.faq5_q,
        'a': l10n.faq5_a,
        'icon': Icons.list_alt_outlined,
      },
      {
        'q': l10n.faq6_q,
        'a': l10n.faq6_a,
        'icon': Icons.edit_outlined,
      },
      {
        'q': l10n.faq7_q,
        'a': l10n.faq7_a,
        'icon': Icons.notifications_outlined,
      },
    ];

    return AppShell(
      title: l10n.faqs,
      currentRoute: '/faqs',
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
              padding: const EdgeInsets.all(24),
              decoration: dsPanelDecoration(color: dsSurface, radius: 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: dsAccent.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: dsAccent.withOpacity(0.35)),
                    ),
                    child: const Icon(
                      Icons.help_outline_rounded,
                      size: 30,
                      color: dsAccentSoft,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.needHelp,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: dsTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.faqsHeaderSubtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            color: dsTextSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.faqsCommonQuestions,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: dsTextPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: faqs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final faq = faqs[index];
                return Container(
                  decoration: dsPanelDecoration(color: dsSurfaceAlt, radius: 16),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      dividerColor: Colors.transparent,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      iconColor: dsAccentSoft,
                      collapsedIconColor: dsAccentSoft,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                      childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      shape: const RoundedRectangleBorder(side: BorderSide.none),
                      collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: dsAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          faq['icon']! as IconData,
                          color: dsAccentSoft,
                        ),
                      ),
                      title: Text(
                        faq['q']! as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: dsTextPrimary,
                        ),
                      ),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: dsSurface.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: dsBorder),
                          ),
                          child: Text(
                            faq['a']! as String,
                            style: const TextStyle(
                              fontSize: 15,
                              color: dsTextSecondary,
                              height: 1.55,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Container(
              decoration: dsPanelDecoration(color: dsSurface, radius: 16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.support_agent_rounded, color: dsAccentSoft),
                        SizedBox(width: 10),
                      ],
                    ),
                    Text(
                      l10n.faqsStillNeedHelp,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: dsTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.faqsContactSupportMessage,
                      style: const TextStyle(
                        fontSize: 14,
                        color: dsTextSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pushNamed(context, '/contact-support'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dsAccent,
                          foregroundColor: dsTextPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.support_agent, size: 20),
                        label: Text(l10n.contactSupport),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
