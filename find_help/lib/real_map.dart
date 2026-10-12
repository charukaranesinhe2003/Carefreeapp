import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'app_state.dart';
import 'models.dart';
import 'theme.dart';

class PlacePhoto extends StatelessWidget {
  const PlacePhoto({
    super.key,
    required this.place,
    this.height = 140,
    this.hero = false,
    this.radius = 0,
  });

  final Place place;
  final double height;
  final bool hero;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      place.photo,
      package: 'find_help',
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        color: AppColors.blushDeep,
        alignment: Alignment.center,
        child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.primary, size: 36),
      ),
    );
    final clipped = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: image,
    );
    if (!hero) return clipped;
    return Hero(tag: 'photo-${place.id}', child: clipped);
  }
}

class AnimatedFinderMap extends StatefulWidget {
  const AnimatedFinderMap({
    super.key,
    required this.pins,
    this.height,
    this.selectedId,
    this.onSelect,
    this.wander = true,
    this.showLock = true,
  });

  final List<Place> pins;
  final double? height;
  final int? selectedId;
  final ValueChanged<Place>? onSelect;
  final bool wander;
  final bool showLock;

  @override
  State<AnimatedFinderMap> createState() => _AnimatedFinderMapState();
}

class _AnimatedFinderMapState extends State<AnimatedFinderMap> {
  final _controller = MapController();
  var _ready = false;

  @override
  void didUpdateWidget(covariant AnimatedFinderMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fit();
  }

  void _fit() {
    if (!_ready) return;
    final app = AppScope.of(context);
    final here = LatLng(app.originLat, app.originLng);
    final closeToResults = widget.pins.any(
      (place) => haversineKm(here.latitude, here.longitude, place.lat, place.lng) < 40,
    );
    final points = <LatLng>[
      for (final place in widget.pins) LatLng(place.lat, place.lng),
      if (closeToResults) here,
    ];
    if (points.isEmpty) {
      _controller.move(const LatLng(6.8412, 79.9654), 13);
      return;
    }
    if (points.length == 1) {
      _controller.move(points.first, 15);
      return;
    }
    _controller.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(42),
        maxZoom: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    Place? selected;
    for (final place in widget.pins) {
      if (place.id == widget.selectedId) {
        selected = place;
        break;
      }
    }
    final user = LatLng(app.originLat, app.originLng);

    final map = ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: user,
              initialZoom: 13,
              onMapReady: () {
                _ready = true;
                _fit();
              },
            ),
            children: [
              ColorFiltered(
                colorFilter: const ColorFilter.mode(Color(0xFFFFD0E6), BlendMode.modulate),
                child: TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.findhelp.find_help',
                ),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                      point: user,
                      width: 28,
                      height: 28,
                      child: const _UserDot(),
                    ),
                  for (final place in widget.pins)
                    Marker(
                      point: LatLng(place.lat, place.lng),
                      width: 118,
                      height: 54,
                      alignment: Alignment.bottomCenter,
                      child: GestureDetector(
                        onTap: () => widget.onSelect?.call(place),
                        child: _PinkPin(
                          label: place.name.split(' ').first,
                          selected: place.id == widget.selectedId,
                        ),
                      ),
                    ),
                ],
              ),
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution('OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          if (widget.showLock && selected != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 28,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    '${selected.name} · ${app.distanceLabel(selected)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.height != null) return SizedBox(height: widget.height, child: map);
    return map;
  }
}

class _UserDot extends StatelessWidget {
  const _UserDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x66E21886), blurRadius: 8)],
      ),
    );
  }
}

class _PinkPin extends StatelessWidget {
  const _PinkPin({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: Colors.white, width: selected ? 2 : 1),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
        Icon(
          Icons.location_on_rounded,
          color: selected ? AppColors.primaryDark : AppColors.primary,
          size: selected ? 26 : 22,
        ),
      ],
    );
  }
}
