import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/layouts/app_shell.dart';
import 'package:main_ui/models/kpi_model.dart';
import 'package:main_ui/providers/admin_provider.dart';
import 'package:main_ui/services/admin_service.dart';
import 'package:main_ui/theme/app_theme.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedPeriod = 'all';
  Map<String, dynamic>? _dashboard;
  bool _loading = false;
  String? _error;

  final List<_Period> _periods = const [
    _Period('All Time', 'all'),
    _Period('This Week', 'week'),
    _Period('This Month', 'month'),
    _Period('This Year', 'year'),
  ];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Future.wait([
        ref
            .read(adminProvider.notifier)
            .fetchAdvancedKPIs(timePeriod: _selectedPeriod),
        _loadDashboard(),
      ]);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await AdminService().getDashboard();
      if (mounted) setState(() => _dashboard = data);
    } catch (_) {
      // Dashboard panel is supplemental — don't block the screen on error
    }
  }

  String _fmt(dynamic val) {
    if (val == null) return '—';
    if (val is double) return val.toStringAsFixed(1);
    return val.toString();
  }

  @override
  Widget build(BuildContext context) {
    final kpi = ref.watch(adminProvider).kpiData;

    return AppShell(
      title: 'Reports & Analytics',
      currentRoute: '/admin/reports',
      child: RefreshIndicator(
        onRefresh: _fetchData,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorPanel(error: _error!, onRetry: _fetchData)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Period selector
                      _PeriodSelector(
                        periods: _periods,
                        selected: _selectedPeriod,
                        onSelect: (v) {
                          setState(() => _selectedPeriod = v);
                          _fetchData();
                        },
                      ),
                      const SizedBox(height: 16),

                      // Live dashboard KPIs from /admins/dashboard
                      if (_dashboard != null) ...[
                        const _SectionHeader('Live Dashboard'),
                        _KpiTile('Resolution Rate',
                            _fmt(_dashboard!['resolution_rate']),
                            Icons.check_circle_outline, Colors.green),
                        _KpiTile('SLA Compliance',
                            _fmt(_dashboard!['sla_compliance']),
                            Icons.timer_outlined, Colors.blue),
                        _KpiTile('Avg Pending Age',
                            _fmt(_dashboard!['pending_aging']),
                            Icons.hourglass_empty, Colors.orange),
                        const SizedBox(height: 16),
                      ],

                      // Advanced KPIs from /admins/reports/kpis/advanced
                      if (kpi != null) ...[
                        _SectionHeader(
                          'Metrics — ${_selectedPeriod == "all" ? "All Time" : _selectedPeriod}',
                        ),
                        _KpiTile('Total Grievances',
                            '${kpi.totalGrievances}',
                            Icons.list_alt, dsAccent),
                        _KpiTile('Resolved',
                            '${kpi.resolvedCount}',
                            Icons.done_all, Colors.green),
                        _KpiTile('In Progress',
                            '${kpi.inProgressCount}',
                            Icons.autorenew, Colors.blueAccent),
                        _KpiTile('Pending / On Hold',
                            '${kpi.newCount + kpi.onHoldCount}',
                            Icons.pending_actions, Colors.orange),
                        _KpiTile('Rejected',
                            '${kpi.rejectedCount}',
                            Icons.cancel_outlined, Colors.red),
                        _KpiTile('SLA Compliance',
                            '${kpi.slaCompliance.toStringAsFixed(1)}%',
                            Icons.verified_outlined, Colors.teal),
                        _KpiTile('Avg Resolution Time',
                            kpi.avgResolutionTime > 0
                                ? '${kpi.avgResolutionTime.toStringAsFixed(1)} days'
                                : '—',
                            Icons.schedule, Colors.purple),
                      ],

                      if (kpi == null && _dashboard == null)
                        const Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(
                            child: Text(
                              'No data available for the selected period.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}

// ── Data class ───────────────────────────────────────────────────────────────

class _Period {
  const _Period(this.label, this.value);
  final String label;
  final String value;
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4)),
      );
}

class _KpiTile extends StatelessWidget {
  const _KpiTile(this.label, this.value, this.icon, this.color);
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha:0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          trailing: Text(value,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ),
      );
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.periods,
    required this.selected,
    required this.onSelect,
  });
  final List<_Period> periods;
  final String selected;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 4,
        children: periods
            .map((p) => ChoiceChip(
                  label: Text(p.label),
                  selected: selected == p.value,
                  onSelected: (_) => onSelect(p.value),
                ))
            .toList(),
      );
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 12),
              Text(error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
}

