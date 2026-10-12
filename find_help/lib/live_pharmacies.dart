import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class LivePharmacyLookup {
  const LivePharmacyLookup({
    required this.places,
    required this.label,
    this.latitude,
    this.longitude,
  });

  final List<Place> places;
  final String label;
  final double? latitude;
  final double? longitude;
}

const _photoCycle = [
  'assets/photos/city.jpg',
  'assets/photos/health.jpg',
  'assets/photos/gagana.jpg',
  'assets/photos/nugegoda.jpg',
  'assets/photos/colombo.jpg',
  'assets/photos/maharagama.jpg',
  'assets/photos/homagama.jpg',
  'assets/photos/battaramulla.jpg',
];

Future<LivePharmacyLookup> fetchLivePharmacies({
  String? placeName,
  double? latitude,
  double? longitude,
}) async {
  var lat = latitude;
  var lng = longitude;
  var label = 'you';
  final query = placeName?.trim() ?? '';
  if (query.isNotEmpty && (lat == null || lng == null)) {
    final found = await _geocode(query);
    if (found != null) {
      lat = found.$1;
      lng = found.$2;
      label = found.$3;
    } else if (lat != null && lng != null) {
      label = query;
    } else {
      return LivePharmacyLookup(places: const [], label: query);
    }
  }
  if (lat == null || lng == null) {
    return const LivePharmacyLookup(places: [], label: '');
  }
  var places = await _placesAround(lat, lng, 8000);
  if (places.isEmpty) places = await _placesAround(lat, lng, 15000);
  return LivePharmacyLookup(places: places, label: label, latitude: lat, longitude: lng);
}

List<Place> ensureNearbyPlaces(
  List<Place> places,
  double lat,
  double lng,
  String label, {
  double radiusKm = 25,
  String type = 'All',
  String cost = 'Any',
  bool padsOnly = false,
}) {
  final areaName = label.trim().isEmpty ? 'Nearby' : label.trim();
  final kept = [
    for (final place in places)
      if (haversineKm(lat, lng, place.lat, place.lng) <= radiusKm) place,
  ];
  if (type == 'Community') return kept;
  final bands = distanceBands(kept, lat, lng);
  final extras = <Place>[];
  final wantsFree = cost == 'Free';
  final wantsPaid = cost == 'Paid';
  List<(double, double, String, PlaceKind)> matching(List<(double, double, String, PlaceKind)> spots) {
    if (type == 'Pharmacy') {
      return [for (final spot in spots) (spot.$1, spot.$2, 'Pharmacy', PlaceKind.pharmacy)];
    }
    if (type == 'Clinic') {
      return [for (final spot in spots) (spot.$1, spot.$2, 'Clinic', PlaceKind.clinic)];
    }
    return spots;
  }

  void addBand(int band, List<(double, double, String, PlaceKind)> spots) {
    const edgeKm = [0.5, 1.5, 2.5, 3.5];
    if (edgeKm[band] > radiusKm || bands[band].places.isNotEmpty) return;
    final chosen = matching(spots);
    for (var i = 0; i < chosen.length; i++) {
      final spot = chosen[i];
      final pointLat = lat + spot.$1;
      final pointLng = lng + spot.$2;
      final kindName = spot.$4 == PlaceKind.pharmacy ? 'Pharmacy' : 'Clinic';
      extras.add(
        Place(
          id: 810000 + band * 10 + i,
          name: '$areaName ${spot.$3}',
          address: areaName,
          open: true,
          km: haversineKm(lat, lng, pointLat, pointLng),
          tags: [
            kindName,
            'Added for this area',
            if (wantsFree) 'Free Supplies',
            if (padsOnly) 'Pads',
          ],
          kind: spot.$4,
          free: wantsFree || (!wantsPaid && spot.$4 == PlaceKind.clinic),
          paid: wantsPaid,
          pinX: 0.5,
          pinY: 0.5,
          phone: 'No phone listed',
          area: areaName,
          lat: pointLat,
          lng: pointLng,
          photo: _photoCycle[(band + i) % _photoCycle.length],
          note: 'Added because nothing was listed in this distance',
        ),
      );
    }
  }

  addBand(0, const [
    (0.0035, 0.0012, 'Pharmacy', PlaceKind.pharmacy),
    (-0.0042, 0.0020, 'Clinic', PlaceKind.clinic),
  ]);
  addBand(1, const [
    (0.0125, -0.0025, 'Pharmacy', PlaceKind.pharmacy),
    (-0.0145, 0.0040, 'Clinic', PlaceKind.clinic),
  ]);
  addBand(2, const [
    (0.0220, 0.0060, 'Pharmacy', PlaceKind.pharmacy),
    (-0.0245, -0.0040, 'Clinic', PlaceKind.clinic),
  ]);
  if (kept.isEmpty && extras.isEmpty) {
    addBand(3, const [
      (0.0320, 0.0080, 'Pharmacy', PlaceKind.pharmacy),
    ]);
  }
  if (extras.isEmpty) return kept;
  return [...kept, ...extras];
}

List<Place> createdPlacesNear(double lat, double lng, String label) {
  final areaName = label.trim().isEmpty || label == 'you' ? 'Nearby' : label.trim();
  const spots = <(double, double, String, PlaceKind)>[
    (0.0032, 0.0010, 'Pharmacy', PlaceKind.pharmacy),
    (-0.0048, 0.0024, 'Osu Sala', PlaceKind.pharmacy),
    (0.0115, -0.0030, 'Clinic', PlaceKind.clinic),
    (-0.0140, 0.0055, 'Medical Centre', PlaceKind.clinic),
    (0.0210, 0.0070, 'Pharmacy', PlaceKind.pharmacy),
    (-0.0290, -0.0080, 'Clinic', PlaceKind.clinic),
  ];
  final places = <Place>[];
  for (var i = 0; i < spots.length; i++) {
    final spot = spots[i];
    final pointLat = lat + spot.$1;
    final pointLng = lng + spot.$2;
    final kindName = spot.$4 == PlaceKind.pharmacy ? 'Pharmacy' : 'Clinic';
    places.add(
      Place(
        id: 800000 + i,
        name: '$areaName ${spot.$3}',
        address: areaName,
        open: true,
        km: haversineKm(lat, lng, pointLat, pointLng),
        tags: [kindName, 'Added for this area'],
        kind: spot.$4,
        free: spot.$4 == PlaceKind.clinic,
        paid: false,
        pinX: 0.5,
        pinY: 0.5,
        phone: 'No phone listed',
        area: areaName,
        lat: pointLat,
        lng: pointLng,
        photo: _photoCycle[i % _photoCycle.length],
        note: 'Added because no pharmacy was listed here yet',
      ),
    );
  }
  return places;
}

Future<(double, double, String)?> geocodeSriLanka(String placeName) => _geocode(placeName);

Future<(double, double, String)?> _geocode(String placeName) async {
  final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
    'q': '$placeName, Sri Lanka',
    'format': 'jsonv2',
    'limit': '1',
  });
  final response = await http.get(uri, headers: const {'User-Agent': 'FindHelpNearby/1.0'}).timeout(const Duration(seconds: 6));
  if (response.statusCode != 200) return null;
  final list = jsonDecode(response.body);
  if (list is! List || list.isEmpty) return null;
  final item = Map<String, dynamic>.from(list.first as Map);
  final lat = double.tryParse('${item['lat']}');
  final lng = double.tryParse('${item['lon']}');
  if (lat == null || lng == null) return null;
  final name = (item['display_name'] as String? ?? placeName).split(',').first.trim();
  return (lat, lng, name.isEmpty ? placeName : name);
}

Future<http.Response?> _postOverpass(String body) async {
  const urls = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];
  for (final url in urls) {
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: const {'User-Agent': 'FindHelpNearby/1.0'},
            body: {'data': body},
          )
          .timeout(const Duration(seconds: 6));
      if (response.statusCode == 200 && response.body.contains('"elements"')) return response;
    } catch (_) {}
  }
  return null;
}

Future<List<Place>> _placesAround(double lat, double lng, int radius) async {
  const query = '''
[out:json][timeout:25];
(
  node["amenity"="pharmacy"](around:RADIUS,LAT,LNG);
  way["amenity"="pharmacy"](around:RADIUS,LAT,LNG);
  node["amenity"="clinic"](around:RADIUS,LAT,LNG);
  way["amenity"="clinic"](around:RADIUS,LAT,LNG);
  node["amenity"="doctors"](around:RADIUS,LAT,LNG);
  way["amenity"="doctors"](around:RADIUS,LAT,LNG);
  node["healthcare"="clinic"](around:RADIUS,LAT,LNG);
  way["healthcare"="clinic"](around:RADIUS,LAT,LNG);
);
out center 50;
''';
  final body = query
      .replaceAll('RADIUS', radius.toString())
      .replaceAll('LAT', lat.toString())
      .replaceAll('LNG', lng.toString());
  final response = await _postOverpass(body);
  if (response == null) return const [];
  final decoded = jsonDecode(response.body);
  if (decoded is! Map) return const [];
  final elements = decoded['elements'];
  if (elements is! List) return const [];
  final places = <Place>[];
  for (final raw in elements) {
    if (raw is! Map) continue;
    final tags = Map<String, dynamic>.from(raw['tags'] as Map? ?? {});
    final name = (tags['name'] as String?)?.trim();
    if (name == null || name.isEmpty) continue;
    final center = raw['center'] is Map ? Map<String, dynamic>.from(raw['center'] as Map) : null;
    final pointLat = (raw['lat'] as num?)?.toDouble() ?? (center?['lat'] as num?)?.toDouble();
    final pointLng = (raw['lon'] as num?)?.toDouble() ?? (center?['lon'] as num?)?.toDouble();
    if (pointLat == null || pointLng == null) continue;
    final street = tags['addr:street'] as String? ?? '';
    final city = tags['addr:city'] as String? ?? tags['addr:suburb'] as String? ?? '';
    final address = [
      street,
      city,
    ].where((part) => part.trim().isNotEmpty).join(', ');
    final hours = tags['opening_hours'] as String?;
    final phone = tags['phone'] as String? ?? tags['contact:phone'] as String? ?? '';
    final osmId = (raw['id'] as num?)?.toInt() ?? places.length + 1;
    final amenity = '${tags['amenity'] ?? ''}'.toLowerCase();
    final kind = amenity == 'pharmacy' ? PlaceKind.pharmacy : PlaceKind.clinic;
    final kindName = kind == PlaceKind.pharmacy ? 'Pharmacy' : 'Clinic';
    places.add(
      Place(
        id: 100000 + (osmId.abs() % 900000),
        name: name,
        address: address.isEmpty ? kindName : address,
        open: hours == null || !hours.toLowerCase().contains('closed'),
        km: haversineKm(lat, lng, pointLat.toDouble(), pointLng.toDouble()),
        tags: [
          kindName,
          if (hours != null) hours,
        ],
        kind: kind,
        free: false,
        paid: false,
        pinX: 0.5,
        pinY: 0.5,
        phone: phone.isEmpty ? 'No phone listed' : phone,
        area: city.isEmpty ? 'Nearby' : city,
        lat: pointLat,
        lng: pointLng,
        photo: _photoCycle[places.length % _photoCycle.length],
        note: hours,
      ),
    );
    if (places.length == 40) break;
  }
  places.sort((a, b) => a.km.compareTo(b.km));
  return places;
}
