import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/core/router/app_router.dart';
import 'debug_error_collector.dart';

class DebugOverlay extends StatelessWidget {
  const DebugOverlay({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child;
    return Stack(children: [child, const _DebugFab()]);
  }
}

// ─── Floating button ────────────────────────────────────────────────────────

class _DebugFab extends StatefulWidget {
  const _DebugFab();

  @override
  State<_DebugFab> createState() => _DebugFabState();
}

class _DebugFabState extends State<_DebugFab> {
  final _c = DebugErrorCollector.instance;

  @override
  void initState() {
    super.initState();
    _c.addListener(_refresh);
  }

  @override
  void dispose() {
    _c.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _open() {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DebugPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final errors = _c.errorCount;
    final total = _c.entries.length;
    final hasError = errors > 0;

    return Positioned(
      bottom: 90,
      right: 16,
      child: GestureDetector(
        onTap: _open,
        child: Opacity(
          opacity: 0.88,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: hasError ? const Color(0xFFB71C1C) : const Color(0xFF1E1E1E),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
                ),
                child: Icon(
                  hasError ? Icons.bug_report : Icons.bug_report_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              if (total > 0)
                Positioned(
                  top: -5,
                  right: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: hasError ? Colors.amber : Colors.blueGrey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      total > 99 ? '99+' : '$total',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Panel ───────────────────────────────────────────────────────────────────

class _DebugPanel extends StatefulWidget {
  const _DebugPanel();

  @override
  State<_DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<_DebugPanel> {
  final _c = DebugErrorCollector.instance;
  String? _filter;

  @override
  void initState() {
    super.initState();
    _c.addListener(_refresh);
  }

  @override
  void dispose() {
    _c.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  List<DebugEntry> get _filtered {
    final all = List.of(_c.entries.reversed);
    return _filter == null ? all : all.where((e) => e.category == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF161616),
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          children: [
            _Handle(),
            _Header(
              total: _c.entries.length,
              errors: _c.errorCount,
              onClear: () {
                _c.clear();
                if (context.mounted) Navigator.pop(context);
              },
              onClose: () => Navigator.pop(context),
            ),
            _FilterBar(
              categories: _c.categories,
              selected: _filter,
              onSelect: (cat) => setState(() => _filter = _filter == cat ? null : cat),
            ),
            const Divider(height: 1, color: Colors.white12),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text(
                        'No entries',
                        style: TextStyle(color: Colors.white38),
                      ),
                    )
                  : ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _EntryTile(entry: filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 10, bottom: 4),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({
    required this.total,
    required this.errors,
    required this.onClear,
    required this.onClose,
  });
  final int total, errors;
  final VoidCallback onClear, onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 8),
      child: Row(
        children: [
          const Icon(Icons.bug_report, color: Color(0xFFEF5350), size: 18),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14),
              children: [
                const TextSpan(
                  text: 'Debug Log  ',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                if (errors > 0)
                  TextSpan(
                    text: '$errors err',
                    style: const TextStyle(color: Color(0xFFEF5350), fontSize: 12),
                  ),
                TextSpan(
                  text: errors > 0 ? '  ·  $total total' : '$total entries',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (total > 0)
            TextButton(
              onPressed: onClear,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Clear', style: TextStyle(color: Colors.amber, fontSize: 12)),
            ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white38, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onClose,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });
  final List<String> categories;
  final String? selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        children: categories.map((cat) {
          final color = DebugCategory.colorFor(cat);
          final active = selected == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: active ? color.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: active ? color : Colors.white24,
                    width: active ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(DebugCategory.iconFor(cat), size: 12, color: active ? color : Colors.white54),
                    const SizedBox(width: 4),
                    Text(
                      cat,
                      style: TextStyle(
                        color: active ? color : Colors.white54,
                        fontSize: 11,
                        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Entry tile ───────────────────────────────────────────────────────────────

class _EntryTile extends StatefulWidget {
  const _EntryTile({required this.entry});
  final DebugEntry entry;

  @override
  State<_EntryTile> createState() => _EntryTileState();
}

class _EntryTileState extends State<_EntryTile> {
  bool _expanded = false;
  bool _copied = false;

  DebugEntry get e => widget.entry;

  Color get _levelColor => switch (e.level) {
        LogLevel.error => const Color(0xFFEF5350),
        LogLevel.warning => const Color(0xFFFFCA28),
        LogLevel.info => const Color(0xFF42A5F5),
        LogLevel.success => const Color(0xFF66BB6A),
      };

  IconData get _levelIcon => switch (e.level) {
        LogLevel.error => Icons.error_rounded,
        LogLevel.warning => Icons.warning_amber_rounded,
        LogLevel.info => Icons.info_rounded,
        LogLevel.success => Icons.check_circle_rounded,
      };

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: e.copyText));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final catColor = DebugCategory.colorFor(e.category);
    final fmt = DateFormat('HH:mm:ss');
    final hasStack = e.stack != null;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF222222),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: catColor, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────────────────
          InkWell(
            onTap: hasStack ? () => setState(() => _expanded = !_expanded) : null,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Level icon
                  Icon(_levelIcon, color: _levelColor, size: 14),
                  const SizedBox(width: 6),
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(DebugCategory.iconFor(e.category), size: 10, color: catColor),
                        const SizedBox(width: 3),
                        Text(
                          e.category,
                          style: TextStyle(color: catColor, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Message
                  Expanded(
                    child: Text(
                      e.message,
                      style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      maxLines: _expanded ? null : 2,
                      overflow: _expanded ? null : TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Right actions column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        fmt.format(e.timestamp),
                        style: const TextStyle(color: Colors.white30, fontSize: 10),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Copy button
                          GestureDetector(
                            onTap: _copy,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _copied
                                  ? const Icon(Icons.check, color: Color(0xFF66BB6A), size: 14, key: ValueKey('check'))
                                  : const Icon(Icons.copy_rounded, color: Colors.white30, size: 14, key: ValueKey('copy')),
                            ),
                          ),
                          if (hasStack) ...[
                            const SizedBox(width: 4),
                            Icon(
                              _expanded ? Icons.expand_less : Icons.expand_more,
                              color: Colors.white30,
                              size: 14,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // ── Expanded stack trace ────────────────────────────────────────
          if (_expanded && hasStack)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  e.stack!,
                  style: const TextStyle(
                    color: Colors.white30,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
