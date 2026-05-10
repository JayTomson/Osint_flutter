part of '../main.dart';

// ============================================================================
// MAP TAB — all coordinates for a single person
// ============================================================================

class _MapTab extends StatelessWidget {
  final Person person;
  const _MapTab({required this.person});

  List<({LatLng pt, String label})> _collectCoords() {
    final out = <({LatLng pt, String label})>[];
    for (final cat in person.categories) {
      for (final kv in cat.entries) {
        final pt = ValueDetector.extractCoord(kv.value);
        if (pt != null) {
          out.add((pt: pt, label: kv.key.isEmpty ? cat.name : kv.key));
        }
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final coords = _collectCoords();
    if (coords.isEmpty) {
      return Center(
        child: Text(tr('no_coords_yet'),
            style: const TextStyle(color: Colors.grey)),
      );
    }
    final center = coords.length == 1
        ? coords.first.pt
        : LatLng(
            coords.map((c) => c.pt.latitude).reduce((a, b) => a + b) /
                coords.length,
            coords.map((c) => c.pt.longitude).reduce((a, b) => a + b) /
                coords.length,
          );
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: coords.length == 1 ? 13 : 9,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'osint_v',
        ),
        MarkerLayer(
          markers: [
            for (final c in coords)
              Marker(
                point: c.pt,
                width: 180,
                height: 68,
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.red, size: 34),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        c.label,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
