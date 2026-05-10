part of '../main.dart';

// ============================================================================
// SINGLE MARKER MAP SCREEN
// ============================================================================

class SingleMarkerMapScreen extends StatelessWidget {
  final LatLng point;
  final String label;
  const SingleMarkerMapScreen(
      {super.key, required this.point, required this.label});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(label),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(
                  text: '${point.latitude}, ${point.longitude}'));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(tr('copied'))),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: () async {
              final url = Uri.parse(
                  'https://www.openstreetmap.org/?mlat=${point.latitude}&mlon=${point.longitude}#map=15/${point.latitude}/${point.longitude}');
              await launchUrl(url, mode: LaunchMode.externalApplication);
            },
          ),
        ],
      ),
      body: FlutterMap(
        options: MapOptions(initialCenter: point, initialZoom: 14),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'osint_v',
          ),
          MarkerLayer(markers: [
            Marker(
              point: point,
              width: 60,
              height: 60,
              child: const Icon(Icons.location_on,
                  color: Colors.red, size: 48),
            ),
          ]),
        ],
      ),
    );
  }
}

// ============================================================================
// GLOBAL MAP SCREEN — all targets' coordinates in a case
// ============================================================================

class GlobalMapScreen extends StatefulWidget {
  final String caseId;
  const GlobalMapScreen({super.key, required this.caseId});
  @override
  State<GlobalMapScreen> createState() => _GlobalMapScreenState();
}

class _GlobalMapScreenState extends State<GlobalMapScreen> {
  final _mapController = MapController();
  final _repaintKey = GlobalKey();

  List<({LatLng pt, String label, String personName})> _collectAll() {
    final c = AppState.instance.findCase(widget.caseId);
    if (c == null) return [];
    final out = <({LatLng pt, String label, String personName})>[];
    for (final person in c.people) {
      for (final cat in person.categories) {
        for (final kv in cat.entries) {
          final pt = ValueDetector.extractCoord(kv.value);
          if (pt != null) {
            final label = kv.key.isEmpty ? cat.name : kv.key;
            out.add((
              pt: pt,
              label: label,
              personName: person.fullName,
            ));
          }
        }
      }
    }
    return out;
  }

  void _fitAll(List<({LatLng pt, String label, String personName})> markers) {
    if (markers.isEmpty) return;
    if (markers.length == 1) {
      _mapController.move(markers.first.pt, 13);
      return;
    }
    double minLat = markers.first.pt.latitude;
    double maxLat = markers.first.pt.latitude;
    double minLng = markers.first.pt.longitude;
    double maxLng = markers.first.pt.longitude;
    for (final m in markers) {
      if (m.pt.latitude < minLat) minLat = m.pt.latitude;
      if (m.pt.latitude > maxLat) maxLat = m.pt.latitude;
      if (m.pt.longitude < minLng) minLng = m.pt.longitude;
      if (m.pt.longitude > maxLng) maxLng = m.pt.longitude;
    }
    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    _mapController.move(center, 9);
  }

  Future<void> _exportPng() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      final f = File(
          '${AppState.instance.docsDir.path}/case_map_${DateTime.now().millisecondsSinceEpoch}.png');
      await f.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(f.path)], text: 'OSINT V Case Map');
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
    final markers = _collectAll();
    final exp = AppState.instance.settings.experimental;
    return Scaffold(
      appBar: AppBar(
        title: Text('${tr("global_case_map")} — ${c?.name ?? ""}'),
        actions: [
          if (exp.exportMapPng && markers.isNotEmpty)
            IconButton(
              tooltip: tr('export_map_png'),
              icon: const Icon(Icons.image_outlined),
              onPressed: _exportPng,
            ),
        ],
      ),
      body: markers.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  tr('no_coords_in_case'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          : RepaintBoundary(
              key: _repaintKey,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: markers.first.pt,
                  initialZoom: markers.length == 1 ? 13 : 7,
                  onMapReady: () => _fitAll(markers),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'osint_v',
                  ),
                  MarkerLayer(
                    markers: [
                      for (final m in markers)
                        Marker(
                          point: m.pt,
                          width: 180,
                          height: 70,
                          alignment: Alignment.topCenter,
                          child: _GlobalMarker(
                            label: m.label,
                            personName: m.personName,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}

class _GlobalMarker extends StatelessWidget {
  final String label;
  final String personName;
  const _GlobalMarker({required this.label, required this.personName});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.location_on, color: Colors.deepOrange, size: 34),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                personName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 9),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
