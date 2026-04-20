import 'dart:io' if (dart.library.html) 'dart:html';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:main_ui/models/grievance_model.dart';
import 'package:main_ui/models/workproof_model.dart';
import 'package:main_ui/widgets/navigation_drawer.dart';
import 'package:main_ui/services/api_service.dart';
import 'package:main_ui/theme/app_theme.dart';
import 'package:intl/intl.dart';

// ────────────── Field staff may only move to: in_progress, on_hold, resolved ─
// Resolved requires at least one workproof uploaded.
List<String> _fieldTransitions(String current) {
  switch (current.toLowerCase()) {
    case 'new':         return ['in_progress'];
    case 'in_progress': return ['on_hold', 'resolved'];
    case 'on_hold':     return ['in_progress'];
    default:            return [];
  }
}

Color _sc(String s) {
  switch (s.toLowerCase()) {
    case 'new':         return const Color(0xFFFFB300);  // amber
    case 'in_progress': return const Color(0xFFFF6D00);  // orange
    case 'on_hold':     return const Color(0xFFD500F9);  // purple
    case 'resolved':    return const Color(0xFF00E676);  // green
    case 'closed':      return const Color(0xFF0097A7);  // cyan dim
    case 'rejected':    return const Color(0xFFFF1744);  // red
    default:            return dsTextSecondary;
  }
}
IconData _si(String s) {
  switch (s.toLowerCase()) {
    case 'new':         return Icons.fiber_new;
    case 'in_progress': return Icons.sync;
    case 'on_hold':     return Icons.pause_circle;
    case 'resolved':    return Icons.check_circle;
    case 'closed':      return Icons.lock;
    case 'rejected':    return Icons.cancel;
    default:            return Icons.help;
  }
}
String _sl(String s) => s == 'in_progress' ? 'IN PROGRESS' : s == 'on_hold' ? 'ON HOLD' : s.toUpperCase();

TextStyle _h(double s, {Color? c}) =>
    TextStyle(color: c ?? dsTextPrimary, fontSize: s, fontWeight: FontWeight.w700);
TextStyle _m(double s, {Color? c}) =>
    TextStyle(color: c ?? dsTextSecondary, fontSize: s, fontFamily: 'monospace');

// ─────────────────────────────────── Screen ──────────────────────────────────
class AssignedList extends ConsumerStatefulWidget {
  const AssignedList({super.key});
  @override
  ConsumerState<AssignedList> createState() => _AssignedListState();
}

class _AssignedListState extends ConsumerState<AssignedList>
    with TickerProviderStateMixin {
  late Future<List<Grievance>> _future;
  late AnimationController _pulseCtrl;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _reload();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _future = _fetch();
    });
  }

  Future<List<Grievance>> _fetch() async {
    final r = await ApiService.get('/grievances/assigned');
    return (r.data as List).whereType<Map<String, dynamic>>()
        .map((j) => Grievance.fromJson(j)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dsBackground,
      appBar: _appBar(),
      drawer: const CustomNavigationDrawer(),
      body: Column(children: [
        _filterBar(),
        Expanded(child: FutureBuilder<List<Grievance>>(
          future: _future,
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) return _loadingState();
            if (snap.hasError) return _errorState(snap.error.toString());
            final raw = snap.data ?? [];
            final items = _filter == 'all' ? raw
                : raw.where((g) => (g.status ?? 'new').toLowerCase() == _filter).toList();
            if (items.isEmpty) return _emptyState();
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              color: dsAccent, backgroundColor: dsSurface,
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 30),
                itemCount: items.length,
                itemBuilder: (_, i) => _card(items[i]),
              ),
            );
          },
        )),
      ]),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: dsSurface, elevation: 0,
    iconTheme: IconThemeData(color: dsAccent),
    bottom: PreferredSize(preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: const Color(0xFFFF6D00).withOpacity(0.4))),
    title: Row(children: [
      AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (_, __) => Container(width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFF6D00),
            boxShadow: [BoxShadow(color: const Color(0xFFFF6D00).withOpacity(0.3 + _pulseCtrl.value * 0.7), blurRadius: 10)])),
      ),
      const SizedBox(width: 10),
      Text('FIELD OPS', style: TextStyle(color: dsTextPrimary, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 2)),
    ]),
    actions: [
      IconButton(icon: Icon(Icons.refresh, color: dsAccent), onPressed: _reload),
    ],
  );

  Widget _filterBar() {
    return Container(
      color: dsSurface,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final s in ['all', 'new', 'in_progress', 'on_hold'])
            _filterChip(s),
        ]),
      ),
    );
  }

  Widget _filterChip(String val) {
    final sel = _filter == val;
    final color = val == 'all' ? dsAccent : _sc(val);
    final label = val == 'all' ? 'ALL' : _sl(val);
    return GestureDetector(
      onTap: () => setState(() => _filter = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: sel ? color : dsBorder),
        ),
        child: Text(label, style: TextStyle(color: sel ? color : dsTextSecondary,
            fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      ),
    );
  }

  Widget _card(Grievance g) {
    final color = _sc(g.status ?? 'new');
    final transitions = _fieldTransitions(g.status ?? 'new');
    final hasWorkproof = (g.workproofs?.isNotEmpty ?? false);
    final fmt = DateFormat('dd MMM, HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: dsSurfaceAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 18)],
      ),
      child: Column(children: [

        // ── Header ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            border: Border(bottom: BorderSide(color: color.withOpacity(0.15))),
          ),
          child: Row(children: [
            Icon(_si(g.status ?? 'new'), color: color, size: 16),
            const SizedBox(width: 8),
            _badge(_sl(g.status ?? 'new'), color),
            const Spacer(),
            Text(g.complaintId, style: _m(10, c: dsAccentDim)),
          ]),
        ),

        // ── Body ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            Text(g.title, style: _h(15)),
            const SizedBox(height: 4),
            Text(g.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: _m(12)),
            const SizedBox(height: 10),

            // Meta
            Wrap(spacing: 12, runSpacing: 6, children: [
              if (g.area != null) _meta(Icons.location_on, g.area!.name ?? '', dsAccentDim),
              if (g.subject != null) _meta(Icons.category, g.subject!.name ?? '', const Color(0xFFD500F9)),
              _meta(Icons.calendar_today, fmt.format(g.createdAt), dsTextSecondary),
            ]),

            // ── Workproof section ─────────────────────────────────
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (hasWorkproof ? const Color(0xFF00E676) : const Color(0xFFFF6D00)).withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: (hasWorkproof ? const Color(0xFF00E676) : const Color(0xFFFF6D00)).withOpacity(0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(hasWorkproof ? Icons.verified : Icons.upload_file,
                      color: hasWorkproof ? const Color(0xFF00E676) : const Color(0xFFFF6D00), size: 16),
                  const SizedBox(width: 8),
                  Text('WORK PROOF', style: _m(11, c: hasWorkproof ? const Color(0xFF00E676) : const Color(0xFFFF6D00))),
                  const Spacer(),
                  if (hasWorkproof)
                    Text('${g.workproofs!.length} FILE${g.workproofs!.length > 1 ? 'S' : ''}',
                        style: _m(10, c: const Color(0xFF00E676)))
                  else
                    Text('REQUIRED TO RESOLVE', style: _m(10, c: const Color(0xFFFF6D00))),
                ]),
                if (hasWorkproof) ...[
                  const SizedBox(height: 8),
                  ...g.workproofs!.map((wp) => _workproofChip(wp)),
                ],
                if (!hasWorkproof) ...[
                  const SizedBox(height: 6),
                  Text('Upload image or video evidence before marking resolved',
                      style: _m(10, c: const Color(0xFFFF6D00).withOpacity(0.7))),
                ],
                const SizedBox(height: 10),
                SizedBox(width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _uploadWorkproofDialog(g),
                      icon: const Icon(Icons.add_photo_alternate, size: 16),
                      label: const Text('ADD PROOF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dsAccent.withOpacity(0.12),
                        foregroundColor: dsAccent,
                        side: BorderSide(color: dsAccentDim),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    )),
              ]),
            ),

            // ── Status transitions ────────────────────────────────
            if (transitions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(height: 1, color: dsBorder),
              const SizedBox(height: 12),
              Row(children: [
                Icon(Icons.alt_route, color: dsAccent, size: 14),
                const SizedBox(width: 6),
                Text('UPDATE STATUS', style: _m(10, c: dsAccent)),
                const Spacer(),
                ...transitions.map((next) => Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _transitionBtn(g, next, hasWorkproof),
                )),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }

  Widget _workproofChip(Workproof wp) {
    final isVideo = (wp.fileType ?? '').contains('video') ||
        (wp.filePath ?? '').contains('.mp4') || (wp.filePath ?? '').contains('.mov');
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: dsSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(isVideo ? Icons.videocam : Icons.image, color: const Color(0xFF00E676), size: 14),
        const SizedBox(width: 8),
        Expanded(child: Text(wp.filePath?.split('/').last ?? 'file',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: _m(11, c: dsTextPrimary))),
        if (wp.notes?.isNotEmpty ?? false)
          Text(wp.notes!, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: _m(10, c: dsTextSecondary)),
      ]),
    );
  }

  Widget _transitionBtn(Grievance g, String next, bool hasWorkproof) {
    final nc = _sc(next);
    final needsProof = next == 'resolved' && !hasWorkproof;
    return Tooltip(
      message: needsProof ? 'Upload work proof first' : '',
      child: GestureDetector(
        onTap: needsProof ? () => _showToast('Upload work proof before marking resolved', const Color(0xFFFF6D00)) : () => _doTransition(g, next),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: needsProof ? 0.4 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: nc.withOpacity(needsProof ? 0.05 : 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: nc.withOpacity(needsProof ? 0.2 : 0.5)),
              boxShadow: needsProof ? [] : [BoxShadow(color: nc.withOpacity(0.2), blurRadius: 8)],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(_si(next), color: nc, size: 12),
              const SizedBox(width: 4),
              Text(_sl(next), style: TextStyle(color: nc, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
              if (needsProof) ...[
                const SizedBox(width: 4),
                Icon(Icons.lock, color: nc, size: 10),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5))),
    child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
  );

  Widget _meta(IconData icon, String label, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: color, size: 11), const SizedBox(width: 4),
    Text(label, style: _m(10, c: color)),
  ]);

  // ── Upload workproof dialog ──────────────────────────────────────────────────
  Future<void> _uploadWorkproofDialog(Grievance g) async {
    final notesCtrl = TextEditingController();
    List<PlatformFile> pickedFiles = [];

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: dsSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: dsAccentDim)),
        child: StatefulBuilder(
          builder: (ctx2, setDlg) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Title
              Row(children: [
                Icon(Icons.upload_file, color: dsAccent, size: 20),
                const SizedBox(width: 10),
                Text('UPLOAD WORK PROOF', style: _h(13, c: dsAccent)),
              ]),
              const SizedBox(height: 6),
              Text('Attach images or video evidence of the completed work',
                  style: _m(11)),
              const SizedBox(height: 18),

              // File picker button
              GestureDetector(
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    allowMultiple: true,
                    type: FileType.custom,
                    allowedExtensions: ['jpg', 'jpeg', 'png', 'mp4', 'mov', 'pdf'],
                    withData: kIsWeb,
                  );
                  if (result != null) {
                    setDlg(() => pickedFiles = result.files);
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: dsAccent.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: dsAccent.withOpacity(0.3), width: 1.5,
                        style: BorderStyle.solid),
                  ),
                  child: Column(children: [
                    Icon(Icons.cloud_upload, color: dsAccent, size: 32),
                    const SizedBox(height: 8),
                    Text('TAP TO SELECT FILES', style: _m(12, c: dsAccent)),
                    const SizedBox(height: 4),
                    Text('Images (JPG/PNG) or Video (MP4/MOV)', style: _m(10)),
                  ]),
                ),
              ),

              // Picked files list
              if (pickedFiles.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...pickedFiles.map((f) {
                  final isVid = ['mp4', 'mov'].contains(f.extension?.toLowerCase());
                  return Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Icon(isVid ? Icons.videocam : Icons.image, color: const Color(0xFF00E676), size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: _h(12)),
                        Text('${(f.size / 1024).toStringAsFixed(1)} KB', style: _m(10)),
                      ])),
                      Icon(Icons.check_circle, color: const Color(0xFF00E676), size: 16),
                    ]),
                  );
                }),
              ],

              const SizedBox(height: 14),
              // Notes
              Container(
                decoration: BoxDecoration(color: dsSurfaceAlt, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: dsBorder)),
                child: TextField(
                  controller: notesCtrl,
                  maxLines: 3,
                  style: TextStyle(color: dsTextPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Work notes / description…',
                    hintStyle: TextStyle(color: dsTextSecondary, fontSize: 12),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('CANCEL', style: TextStyle(color: dsTextSecondary, letterSpacing: 1, fontSize: 12)),
                )),
                const SizedBox(width: 10),
                Expanded(child: ElevatedButton(
                  onPressed: pickedFiles.isEmpty ? null : () async {
                    Navigator.pop(ctx);
                    await _uploadWorkproof(g.id, pickedFiles, notesCtrl.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dsAccent.withOpacity(0.2),
                    foregroundColor: dsAccent,
                    side: BorderSide(color: dsAccentDim),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('UPLOAD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _uploadWorkproof(int id, List<PlatformFile> files, String notes) async {
    try {
      for (final f in files) {
        await ApiService.postMultipart('/grievances/$id/workproof',
            files: [f], fieldName: 'file', data: {'notes': notes});
      }
      _showToast('Work proof uploaded (${files.length} file${files.length > 1 ? 's' : ''})', const Color(0xFF00E676));
      _reload();
    } catch (e) {
      _showToast('Upload failed: $e', const Color(0xFFFF1744));
    }
  }

  Future<void> _doTransition(Grievance g, String next) async {
    try {
      await ApiService.put('/grievances/${g.id}/status', {'status': next});
      _showToast('Status → ${_sl(next)}', _sc(next));
      _reload();
    } catch (e) {
      _showToast('Update failed: $e', const Color(0xFFFF1744));
    }
  }

  void _showToast(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Container(width: 4, height: 28,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: TextStyle(color: dsTextPrimary, fontSize: 13))),
      ]),
      backgroundColor: dsSurfaceAlt,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withOpacity(0.4))),
    ));
  }

  Widget _loadingState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    SizedBox(width: 48, height: 48,
        child: CircularProgressIndicator(strokeWidth: 3, color: dsAccent, backgroundColor: dsBorder)),
    const SizedBox(height: 16),
    Text('LOADING ASSIGNMENTS…', style: _m(12)),
  ]));

  Widget _errorState(String err) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline, color: const Color(0xFFFF1744), size: 48),
      const SizedBox(height: 12),
      Text(err, style: _m(12, c: const Color(0xFFFF1744)), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: _reload,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF1744).withOpacity(0.2),
              foregroundColor: const Color(0xFFFF1744), side: const BorderSide(color: const Color(0xFFFF1744))),
          child: const Text('RETRY')),
    ]),
  ));

  Widget _emptyState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.assignment_outlined, color: dsTextSecondary.withOpacity(0.3), size: 64),
    const SizedBox(height: 12),
    Text('NO ASSIGNMENTS', style: _m(13)),
    const SizedBox(height: 4),
    Text('Nothing assigned to you right now', style: _m(11)),
  ]));
}
