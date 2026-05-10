part of '../main.dart';

// ============================================================================
// GRAPH SCREEN
// ============================================================================

class GraphScreen extends StatefulWidget {
  final String caseId;
  const GraphScreen({super.key, required this.caseId});
  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  String? _reasonFilter;
  final _graphKey = GlobalKey<_ForceDirectedGraphViewState>();

  Set<String> _allReasons(CaseFile c) {
    final set = <String>{};
    for (final p in c.people) {
      for (final link in p.connections) {
        set.addAll(link.reasons);
      }
    }
    return set;
  }

  Future<void> _exportPng() async {
    try {
      final state = _graphKey.currentState;
      if (state == null) return;
      final bytes = await state.exportToPng();
      if (bytes == null) return;
      final f = File(
          '${AppState.instance.docsDir.path}/graph_${DateTime.now().millisecondsSinceEpoch}.png');
      await f.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(f.path)], text: 'OSINT V Graph');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppState.instance.findCase(widget.caseId);
    final exp = AppState.instance.settings.experimental;
    if (c == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('graph'))),
        body: const Center(child: Text('—')),
      );
    }

    final nodes = <_GraphNode>[
      for (final p in c.people) _GraphNode(id: p.id, label: p.fullName),
    ];
    final edgeKeys = <String>{};
    final edges = <_GraphEdge>[];
    for (final p in c.people) {
      for (final link in p.connections) {
        if (_reasonFilter != null &&
            !link.reasons.contains(_reasonFilter)) continue;
        if (c.findPerson(link.targetPersonId) == null) continue;
        final ids = [p.id, link.targetPersonId]..sort();
        final key = ids.join('|');
        if (edgeKeys.contains(key)) continue;
        edgeKeys.add(key);
        edges.add(_GraphEdge(fromId: p.id, toId: link.targetPersonId));
      }
    }

    final reasons = _allReasons(c).toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('graph')),
        actions: [
          if (exp.exportGraphPng)
            IconButton(
              tooltip: tr('export_graph_png'),
              icon: const Icon(Icons.image_outlined),
              onPressed: _exportPng,
            ),
          PopupMenuButton<String?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _reasonFilter = v),
            itemBuilder: (_) => [
              PopupMenuItem<String?>(
                  value: null, child: Text(tr('all_reasons'))),
              for (final r in reasons)
                PopupMenuItem<String?>(value: r, child: Text(r)),
            ],
          ),
        ],
      ),
      body: nodes.isEmpty
          ? Center(
              child: Text(tr('no_targets'),
                  style: const TextStyle(color: Colors.grey)),
            )
          : _ForceDirectedGraphView(
              key: _graphKey,
              nodes: nodes,
              edges: edges,
              onTapNode: (id) {
                final p = c.findPerson(id);
                if (p == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PersonScreen(caseId: c.id, personId: p.id),
                  ),
                );
              },
            ),
    );
  }
}

// ============================================================================
// CUSTOM FORCE-DIRECTED GRAPH (no overlap)
// ============================================================================

class _GraphNode {
  final String id;
  final String label;
  Offset position = Offset.zero;
  Size size = const Size(120, 44);
  _GraphNode({required this.id, required this.label});
}

class _GraphEdge {
  final String fromId;
  final String toId;
  _GraphEdge({required this.fromId, required this.toId});
}

class _ForceDirectedGraphView extends StatefulWidget {
  final List<_GraphNode> nodes;
  final List<_GraphEdge> edges;
  final void Function(String id) onTapNode;
  const _ForceDirectedGraphView({
    super.key,
    required this.nodes,
    required this.edges,
    required this.onTapNode,
  });

  @override
  State<_ForceDirectedGraphView> createState() =>
      _ForceDirectedGraphViewState();
}

class _ForceDirectedGraphViewState extends State<_ForceDirectedGraphView> {
  bool _laidOut = false;
  late Size _canvasSize;
  final TransformationController _transformController =
      TransformationController();
  final _repaintKey = GlobalKey();

  Future<Uint8List?> exportToPng() async {
    final boundary = _repaintKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  void initState() {
    super.initState();
    _measureLabels();
  }

  void _measureLabels() {
    for (final n in widget.nodes) {
      final tp = TextPainter(
        text: TextSpan(
          text: n.label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: 220);
      final w = (tp.width + 24).clamp(80.0, 240.0);
      n.size = Size(w, 44);
    }
  }

  void _layout(Size canvas) {
    final n = widget.nodes.length;
    if (n == 0) return;

    final rng = math.Random(42);
    final cx = canvas.width / 2;
    final cy = canvas.height / 2;
    final r0 = math.min(canvas.width, canvas.height) * 0.32;
    for (var i = 0; i < n; i++) {
      final angle = (i / n) * 2 * math.pi + rng.nextDouble() * 0.2;
      widget.nodes[i].position =
          Offset(cx + r0 * math.cos(angle), cy + r0 * math.sin(angle));
    }

    if (n == 1) {
      widget.nodes[0].position = Offset(cx, cy);
      return;
    }

    final area = canvas.width * canvas.height;
    final k = math.sqrt(area / n) * 0.85;
    final minSpacing = _maxNodeRadius() * 2 + 30;

    final idToIndex = <String, int>{};
    for (var i = 0; i < n; i++) {
      idToIndex[widget.nodes[i].id] = i;
    }
    final edgePairs = <List<int>>[];
    for (final e in widget.edges) {
      final a = idToIndex[e.fromId];
      final b = idToIndex[e.toId];
      if (a == null || b == null || a == b) continue;
      edgePairs.add([a, b]);
    }

    final disp = List<Offset>.filled(n, Offset.zero);
    var temperature = math.min(canvas.width, canvas.height) / 8;
    const iterations = 500;

    for (var it = 0; it < iterations; it++) {
      for (var i = 0; i < n; i++) {
        disp[i] = Offset.zero;
      }

      for (var i = 0; i < n; i++) {
        for (var j = i + 1; j < n; j++) {
          var delta = widget.nodes[i].position - widget.nodes[j].position;
          var d = delta.distance;
          if (d < 0.01) {
            final a = rng.nextDouble() * 2 * math.pi;
            delta = Offset(math.cos(a), math.sin(a)) * 0.5;
            d = 0.5;
          }
          double force = (k * k) / d;
          if (d < minSpacing) {
            final overlap = (minSpacing - d);
            force += overlap * overlap * 0.6;
          }
          final dir = delta / d;
          disp[i] = disp[i] + dir * force;
          disp[j] = disp[j] - dir * force;
        }
      }

      for (final pair in edgePairs) {
        final a = pair[0];
        final b = pair[1];
        var delta = widget.nodes[a].position - widget.nodes[b].position;
        var d = delta.distance;
        if (d < 0.01) d = 0.01;
        final force = (d * d) / k;
        final dir = delta / d;
        disp[a] = disp[a] - dir * force;
        disp[b] = disp[b] + dir * force;
      }

      for (var i = 0; i < n; i++) {
        final d = disp[i].distance;
        if (d > 0) {
          final capped = math.min(d, temperature);
          final move = disp[i] / d * capped;
          var pos = widget.nodes[i].position + move;
          final r = math.max(
                  widget.nodes[i].size.width, widget.nodes[i].size.height) /
              2;
          final x = pos.dx.clamp(r, canvas.width - r);
          final y = pos.dy.clamp(r, canvas.height - r);
          widget.nodes[i].position = Offset(x, y);
        }
      }

      temperature *= 0.985;
      if (temperature < 0.5) break;
    }

    for (var pass = 0; pass < 60; pass++) {
      var moved = false;
      for (var i = 0; i < n; i++) {
        for (var j = i + 1; j < n; j++) {
          final a = widget.nodes[i];
          final b = widget.nodes[j];
          var delta = a.position - b.position;
          var d = delta.distance;
          final ra = math.sqrt(
                  a.size.width * a.size.width +
                      a.size.height * a.size.height) /
              2;
          final rb = math.sqrt(
                  b.size.width * b.size.width +
                      b.size.height * b.size.height) /
              2;
          final required = ra + rb + 14;
          if (d < required) {
            if (d < 0.01) {
              final ang = rng.nextDouble() * 2 * math.pi;
              delta = Offset(math.cos(ang), math.sin(ang));
              d = 1;
            }
            final shift = (required - d) / 2;
            final dir = delta / d;
            a.position = a.position + dir * shift;
            b.position = b.position - dir * shift;
            moved = true;
          }
        }
      }
      if (!moved) break;
    }

    for (final node in widget.nodes) {
      final r = math.max(node.size.width, node.size.height) / 2;
      final x = node.position.dx.clamp(r, canvas.width - r);
      final y = node.position.dy.clamp(r, canvas.height - r);
      node.position = Offset(x, y);
    }
  }

  double _maxNodeRadius() {
    double r = 0;
    for (final n in widget.nodes) {
      final cur = math.max(n.size.width, n.size.height) / 2;
      if (cur > r) r = cur;
    }
    return r;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final n = widget.nodes.length;
        final base = math.max(900.0, math.sqrt(n) * 260);
        final w = math.max(constraints.maxWidth, base);
        final h = math.max(constraints.maxHeight, base * 0.75);
        final canvas = Size(w, h);

        if (!_laidOut || _canvasSize != canvas) {
          _canvasSize = canvas;
          _layout(canvas);
          _laidOut = true;
        }

        return InteractiveViewer(
          transformationController: _transformController,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(400),
          minScale: 0.2,
          maxScale: 4,
          child: RepaintBoundary(
            key: _repaintKey,
            child: SizedBox(
              width: canvas.width,
              height: canvas.height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _EdgePainter(
                        nodes: widget.nodes,
                        edges: widget.edges,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  for (final node in widget.nodes)
                    Positioned(
                      left: node.position.dx - node.size.width / 2,
                      top: node.position.dy - node.size.height / 2,
                      width: node.size.width,
                      height: node.size.height,
                      child: _GraphNodeChip(
                        label: node.label,
                        onTap: () => widget.onTapNode(node.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EdgePainter extends CustomPainter {
  final List<_GraphNode> nodes;
  final List<_GraphEdge> edges;
  final Color color;
  _EdgePainter(
      {required this.nodes, required this.edges, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final byId = {for (final n in nodes) n.id: n};
    for (final e in edges) {
      final a = byId[e.fromId];
      final b = byId[e.toId];
      if (a == null || b == null) continue;
      canvas.drawLine(a.position, b.position, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _EdgePainter oldDelegate) =>
      oldDelegate.nodes != nodes || oldDelegate.edges != edges;
}

class _GraphNodeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _GraphNodeChip({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.colorScheme.primary, width: 1.4),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
