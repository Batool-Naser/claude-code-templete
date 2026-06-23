import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:todo_app/core/router/app_router.dart';
import 'debug_error_collector.dart';

class DebugOverlay extends StatelessWidget {
  const DebugOverlay({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child;
    return Stack(
      children: [
        child,
        const _DebugButton(),
      ],
    );
  }
}

class _DebugButton extends StatefulWidget {
  const _DebugButton();

  @override
  State<_DebugButton> createState() => _DebugButtonState();
}

class _DebugButtonState extends State<_DebugButton> {
  final _collector = DebugErrorCollector.instance;

  @override
  void initState() {
    super.initState();
    _collector.addListener(_refresh);
  }

  @override
  void dispose() {
    _collector.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _showPanel() {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return;
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ErrorPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = _collector.errors.length;
    return Positioned(
      bottom: 90,
      right: 16,
      child: GestureDetector(
        onTap: _showPanel,
        child: Opacity(
          opacity: 0.85,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: count > 0 ? const Color(0xFFB71C1C) : const Color(0xFF212121),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                  boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 8)],
                ),
                child: Icon(
                  count > 0 ? Icons.bug_report : Icons.bug_report_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              if (count > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
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

class _ErrorPanel extends StatefulWidget {
  const _ErrorPanel();

  @override
  State<_ErrorPanel> createState() => _ErrorPanelState();
}

class _ErrorPanelState extends State<_ErrorPanel> {
  final _collector = DebugErrorCollector.instance;

  @override
  void initState() {
    super.initState();
    _collector.addListener(_refresh);
  }

  @override
  void dispose() {
    _collector.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final errors = List.of(_collector.errors.reversed);
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            _PanelHeader(
              count: errors.length,
              onClear: () {
                _collector.clear();
                if (context.mounted) Navigator.pop(context);
              },
            ),
            Expanded(
              child: errors.isEmpty
                  ? const Center(
                      child: Text(
                        'No errors recorded',
                        style: TextStyle(color: Colors.white54),
                      ),
                    )
                  : ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.all(12),
                      itemCount: errors.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _ErrorTile(error: errors[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.count, required this.onClear});
  final int count;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bug_report, color: Color(0xFFEF5350), size: 20),
          const SizedBox(width: 8),
          Text(
            'Debug Errors ($count)',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          if (count > 0)
            TextButton(
              onPressed: onClear,
              child: const Text('Clear all', style: TextStyle(color: Colors.amber, fontSize: 12)),
            ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _ErrorTile extends StatefulWidget {
  const _ErrorTile({required this.error});
  final AppError error;

  @override
  State<_ErrorTile> createState() => _ErrorTileState();
}

class _ErrorTileState extends State<_ErrorTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm:ss');
    final e = widget.error;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEF5350).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF5350).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      e.type,
                      style: const TextStyle(color: Color(0xFFEF5350), fontSize: 10),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.message,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      maxLines: _expanded ? null : 2,
                      overflow: _expanded ? null : TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        fmt.format(e.timestamp),
                        style: const TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                      if (e.stack != null)
                        Icon(
                          _expanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.white38,
                          size: 16,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded && e.stack != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  e.stack!,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
