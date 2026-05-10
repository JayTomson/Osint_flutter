import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../models.dart';

class GraphScreen extends StatefulWidget {
  final String caseId;
  const GraphScreen({super.key, required this.caseId});
  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ticker;
  final List<_Node> _nodes = [];
  final List<_Edge> _edges = [];
  bool _initialized = false;
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  String? _selectedNodeId;

  static const double _kRepulsion = 8000;
  static const double _kAttraction = 0.015;
  static const double _kDamping = 0.85;
  static const double _kMinEnergy = 0.5;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(hours: 1),
    )..addListener(_step);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _init() {
    final c = AppState.instance.findCase(widget.caseId);
    if (c == null) return;
    final size = MediaQuery.of(context).size;
    final rng = math.Random();
    _nodes.clear();
    _edges.clear();
    for (final p in c.people) {
      _nodes.add(_Node(
        id: p.id,
        label: p.fullName,
        x: (rng.nextDouble() - 0.5) * size.width * 0.6,
        y: (rng.nextDouble() - 0.5) * size.height * 0.6,
      ));
    }
    final seen = <String>{};
    for (final p in c.people) {
      for (final link in p.connections) {
        final key = [p.id, link.targetPersonId]..sort();
        final edgeKey = key.join('|');
        if (!seen.contains(edgeKey)) {
          seen.add(edgeKey);
          _edges.add(_Edge(
            fromId: p.id,
            toId: link.targetPersonId,
            reasons: link.reasons,
          ));
        }
      }
    }
    _initialized = true;
    _ticker.repeat();
  }

  void _step() {
    if (!_initialized || _nodes.isEmpty) return;
    double totalEnergy = 0;
    for (final n in _nodes) {
      n.fx = 0;
      n.fy = 0;
    }
    for (var i = 0; i < _nodes.length; i++) {
      for (var j = i + 1; j < _nodes.length; j++) {
        final a = _nodes[i];
        final b = _nodes[j];
        final dx = b.x - a.x;
        final dy = b.y - a.y;
        final distSq = dx * dx + dy * dy + 0.1;
        final dist = math.sqrt(distSq);
        final force = _kRepulsion / distSq;
        final fx = force * dx / dist;
        final fy = force * dy / dist;
        a.fx -= fx;
        a.fy -= fy;
        b.fx += fx;
        b.fy += fy;
      }
    }
    final nodeMap = {for (final n in _nodes) n.id: n};
    for (final e in _edges) {
      final a = nodeMap[e.fromId];
      final b = nodeMap[e.toId];
      if (a == null || b == null) continue;
      final dx = b.x - a.x;
      final dy = b.y - a.y;
      final dist = math.sqrt(dx * dx + dy * dy + 0.1);
      final targetDist = 150.0;
      final stretch = dist - targetDist;
      final force = _kAttraction * stretch;
      final fx = force * dx / dist;
      final fy = force * dy / dist;
      a.fx += fx;
      a.fy += fy;
      b.fx -= fx;
      b.fy -= fy;
    }
    for (final n in _nodes) {
      if (n.pinned) continue;
      n.vx = (n.vx + n.fx) * _kDamping;
      n.vy = (n.vy + n.fy) * _kDamping;
      n.x += n.vx;
      n.y += n.vy;
      totalEnergy += n.vx.abs() + n.vy.abs();
    }
    if (totalEnergy < _kMinEnergy) {
      _ticker.stop();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = AppState.instance.findCase(widget.caseId);
    final nodeMap = {for (final n in _nodes) n.id: n};
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('graph')),
        actions: [
          IconButton(
            tooltip: tr('reset_layout'),
            icon: const Icon(Icons.refresh),
            onPressed: () {
              for (final n in _nodes) {
                n.pinned = false;
                n.vx = 0;
                n.vy = 0;
              }
              _ticker.repeat();
            },
          ),
        ],
      ),
      body: GestureDetector(
        onScaleStart: (d) {},
        onScaleUpdate: (d) {
          setState(() {
            _scale = (_scale * d.scale).clamp(0.3, 4.0);
            _offset += d.focalPointDelta;
          });
        },
        child: CustomPaint(
          painter: _GraphPainter(
            nodes: _nodes,
            edges: _edges,
            nodeMap: nodeMap,
            scale: _scale,
            offset: _offset,
            selectedId: _selectedNodeId,
            context: context,
          ),
          child: Stack(
            children: [
              for (final n in _nodes)
                Positioned(
                  left: n.x * _scale +
                      MediaQuery.of(context).size.width / 2 +
                      _offset.dx -
                      36,
                  top: n.y * _scale +
                      MediaQuery.of(context).size.height / 2 +
                      _offset.dy -
                      60,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedNodeId =
                            _selectedNodeId == n.id ? null : n.id;
                      });
                    },
                    onPanUpdate: (d) {
                      setState(() {
                        n.x += d.delta.dx / _scale;
                        n.y += d.delta.dy / _scale;
                        n.vx = 0;
                        n.vy = 0;
                        n.pinned = true;
                      });
                    },
                    child: _NodeWidget(
                      node: n,
                      selected: _selectedNodeId == n.id,
                    ),
                  ),
                ),
              if (_selectedNodeId != null && c != null)
                _buildInfoPanel(context, c, nodeMap[_selectedNodeId]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoPanel(
      BuildContext context, CaseFile c, _Node? node) {
    if (node == null) return const SizedBox();
    final person = c.findPerson(node.id);
    if (person == null) return const SizedBox();
    final theme = Theme.of(context);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: const Offset(0, -4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(person.fullName,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            if (person.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: person.tags
                    .map((t) => Chip(
                          label: Text(t),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            ],
            if (person.connections.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${tr("connections")}: ${person.connections.length}',
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Node {
  final String id;
  final String label;
  double x, y, vx = 0, vy = 0, fx = 0, fy = 0;
  bool pinned = false;
  _Node(
      {required this.id,
      required this.label,
      required this.x,
      required this.y});
}

class _Edge {
  final String fromId;
  final String toId;
  final List<String> reasons;
  const _Edge(
      {required this.fromId,
      required this.toId,
      this.reasons = const []});
}

class _NodeWidget extends StatelessWidget {
  final _Node node;
  final bool selected;
  const _NodeWidget({required this.node, required this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: selected ? 56 : 48,
          height: selected ? 56 : 48,
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 2)
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            _initials(node.label),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color:
                theme.colorScheme.surface.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(6),
          ),
          constraints: const BoxConstraints(maxWidth: 110),
          child: Text(
            node.label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600),
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isEmpty ? '?' : name[0].toUpperCase();
  }
}

class _GraphPainter extends CustomPainter {
  final List<_Node> nodes;
  final List<_Edge> edges;
  final Map<String, _Node> nodeMap;
  final double scale;
  final Offset offset;
  final String? selectedId;
  final BuildContext context;

  const _GraphPainter({
    required this.nodes,
    required this.edges,
    required this.nodeMap,
    required this.scale,
    required this.offset,
    required this.selectedId,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final theme = Theme.of(context);
    final cx = size.width / 2 + offset.dx;
    final cy = size.height / 2 + offset.dy;
    final linePaint = Paint()
      ..color = theme.colorScheme.primary.withValues(alpha: 0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final selectedLinePaint = Paint()
      ..color = theme.colorScheme.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    for (final e in edges) {
      final a = nodeMap[e.fromId];
      final b = nodeMap[e.toId];
      if (a == null || b == null) continue;
      final ax = a.x * scale + cx;
      final ay = a.y * scale + cy;
      final bx = b.x * scale + cx;
      final by = b.y * scale + cy;
      final isSelected =
          selectedId == a.id || selectedId == b.id;
      canvas.drawLine(
          Offset(ax, ay), Offset(bx, by), isSelected ? selectedLinePaint : linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GraphPainter old) => true;
}
