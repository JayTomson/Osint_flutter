import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app_state.dart';
import '../detection.dart';
import '../l10n.dart';
import '../models.dart';

class MapTab extends StatefulWidget {
  final String caseId;
  final String personId;
  const MapTab(
      {super.key, required this.caseId, required this.personId});
  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();

  List<({LatLng coord, String label})> _extractCoords(Person p) {
    final result = <({LatLng coord, String label})>[];
    for (final cat in p.categories) {
      for (final kv in cat.entries) {
        final coord = ValueDetector.extractCoord(kv.value);
        if (coord != null) {
          result.add((
            coord: coord,
            label: kv.key.isNotEmpty
                ? '${cat.name} — ${kv.key}'
                : cat.name,
          ));
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final c = AppState.instance.findCase(widget.caseId);
        final p = c?.findPerson(widget.personId);
        if (c == null || p == null) return const SizedBox();
        final coords = _extractCoords(p);
        if (coords.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                tr('no_coordinates_found'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          );
        }
        final center = coords.length == 1
            ? coords.first.coord
            : LatLng(
                coords.map((e) => e.coord.latitude).reduce((a, b) => a + b) /
                    coords.length,
                coords
                        .map((e) => e.coord.longitude)
                        .reduce((a, b) => a + b) /
                    coords.length,
              );
        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: coords.length == 1 ? 14.0 : 10.0,
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.osint_v',
            ),
            MarkerLayer(
              markers: [
                for (final item in coords)
                  Marker(
                    point: item.coord,
                    width: 200,
                    height: 60,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () => _showLabel(context, item.label),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.label,
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.location_pin,
                              color: Colors.red, size: 28),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showLabel(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label), duration: const Duration(seconds: 2)),
    );
  }
}

class SingleMarkerMapScreen extends StatelessWidget {
  final LatLng coord;
  final String label;
  const SingleMarkerMapScreen(
      {super.key, required this.coord, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('map'))),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: coord,
          initialZoom: 14.0,
        ),
        children: [
          TileLayer(
            urlTemplate:
                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.osint_v',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: coord,
                width: 200,
                height: 60,
                alignment: Alignment.topCenter,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        label,
                        style: const TextStyle(fontSize: 10),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.location_pin,
                        color: Colors.red, size: 28),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GlobalMapScreen extends StatefulWidget {
  final String caseId;
  const GlobalMapScreen({super.key, required this.caseId});
  @override
  State<GlobalMapScreen> createState() => _GlobalMapScreenState();
}

class _GlobalMapScreenState extends State<GlobalMapScreen> {
  final MapController _mapController = MapController();

  List<_GlobalMarker> _buildMarkers(CaseFile c) {
    final result = <_GlobalMarker>[];
    for (final p in c.people) {
      for (final cat in p.categories) {
        for (final kv in cat.entries) {
          final coord = ValueDetector.extractCoord(kv.value);
          if (coord != null) {
            result.add(_GlobalMarker(
              coord: coord,
              personName: p.fullName,
              label: kv.key.isNotEmpty
                  ? '${cat.name} — ${kv.key}'
                  : cat.name,
            ));
          }
        }
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final c = AppState.instance.findCase(widget.caseId);
        if (c == null) return const SizedBox();
        final markers = _buildMarkers(c);
        final center = markers.isEmpty
            ? const LatLng(55.75, 37.62)
            : LatLng(
                markers
                        .map((m) => m.coord.latitude)
                        .reduce((a, b) => a + b) /
                    markers.length,
                markers
                        .map((m) => m.coord.longitude)
                        .reduce((a, b) => a + b) /
                    markers.length,
              );
        return Scaffold(
          appBar: AppBar(title: Text(tr('global_case_map'))),
          body: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: markers.length == 1 ? 14.0 : 8.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.osint_v',
              ),
              MarkerLayer(
                markers: [
                  for (final m in markers)
                    Marker(
                      point: m.coord,
                      width: 220,
                      height: 70,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        onTap: () => _showInfo(context, m),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius:
                                    BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${m.personName}: ${m.label}',
                                style: const TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                            const Icon(Icons.location_pin,
                                color: Colors.deepOrange, size: 28),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInfo(BuildContext context, _GlobalMarker m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(m.personName),
        content: Text(m.label),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(tr('close'))),
        ],
      ),
    );
  }
}

class _GlobalMarker {
  final LatLng coord;
  final String personName;
  final String label;
  const _GlobalMarker(
      {required this.coord,
      required this.personName,
      required this.label});
}
