import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'live_pharmacies.dart';
import 'models.dart';
import 'reminder_alerts.dart';

class AppController extends ChangeNotifier {
  static const _savedKey = 'pharmacy-finder-saved-places';
  static const _supplyKey = 'pharmacy-finder-supply-list';
  static const _historyKey = 'pharmacy-finder-history';
  static const _feedbackKey = 'pharmacy-finder-feedback';
  static const _recentKey = 'pharmacy-finder-recent-searches';
  static const _locationKey = 'pharmacy-finder-location-on';
  static const _areaKey = 'pharmacy-finder-area';
  static const _latKey = 'pharmacy-finder-lat';
  static const _lngKey = 'pharmacy-finder-lng';
  static const _searchKey = 'pharmacy-finder-search';
  static const _filtersKey = 'pharmacy-finder-filters';
  static const _notesKey = 'pharmacy-finder-notes';
  static const _remindersKey = 'pharmacy-finder-reminders';
  static const _geoKey = 'pharmacy-finder-geocode-cache';
  static const _managedKey = 'pharmacy-finder-managed';

  List<SavedPlace> saved = List.of(initialSaved);
  List<SupplyItem> supplies = List.of(initialSupplies);
  List<VisitNote> notes = List.of(initialNotes);
  List<Reminder> reminders = List.of(initialReminders);
  List<ManagedPharmacy> managed = [];
  List<Place> livePlaces = [];
  List<HistoryVisit> history = List.of(historySeed);
  List<VisitFeedback> feedback = [];
  List<SearchRecord> recentSearches = List.of(recentSearchSeed);

  String area = 'Kottawa';
  String searchQuery = '';
  double radiusKm = 5;
  String type = 'All';
  String cost = 'Any';
  bool openOnly = true;
  bool locationOn = false;
  bool locating = false;
  bool liveLoading = false;
  String liveMessage = '';
  double? latitude;
  double? longitude;
  double? searchLat;
  double? searchLng;
  Box<dynamic>? _box;
  Timer? _liveTimer;
  Timer? _gpsTimer;
  Timer? _reminderTimer;
  bool locationDenied = false;
  StreamSubscription<Position>? _positionSub;
  var _polling = false;
  DateTime? _lastPersistAt;
  var _fetchGen = 0;
  var _locationGen = 0;
  int tab = 0;
  final Set<String> chips = {'Open now'};
  final Map<String, (double, double, String)> _geoCache = {};
  Future<bool>? _locationTask;

  bool _disposed = false;

  String get areaLabel => area.trim().isEmpty ? 'your area' : area.trim();

  bool get inWesternProvince {
    final lat = latitude;
    final lng = longitude;
    if (!locationOn || lat == null || lng == null) return true;
    return lat >= 6.7 && lat <= 7.25 && lng >= 79.65 && lng <= 80.35;
  }

  String get provinceLine => inWesternProvince ? 'WESTERN PROVINCE · LIVE' : 'SRI LANKA · LIVE';

  String get townLabel {
    if (searchQuery.trim().isNotEmpty) {
      return nearestAreaName(originLat, originLng) ?? areaLabel;
    }
    if (!locationOn || latitude == null || longitude == null) return 'Kottawa';
    return nearestAreaName(latitude!, longitude!) ?? 'Near you';
  }

  String get gpsLine {
    if (!locationOn || latitude == null || longitude == null) return 'Kottawa, Sri Lanka';
    return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
  }

  double get originLat {
    if (searchLat != null) return searchLat!;
    if (locationOn && latitude != null) return latitude!;
    return 6.8412;
  }

  double get originLng {
    if (searchLng != null) return searchLng!;
    if (locationOn && longitude != null) return longitude!;
    return 79.9654;
  }

  String get queryArea {
    final search = searchQuery.trim();
    if (search.isNotEmpty) return search;
    return '';
  }

  bool get filtersNarrowed =>
      type != 'All' || cost != 'Any' || radiusKm != 5 || chips.any((chip) => chip != 'Open now');

  String distanceLabel(Place place) => formatKm(kilometersBetween(originLat, originLng, place));

  bool get showingNearest => livePlaces.isEmpty && searchQuery.trim().isEmpty && _filtered().isEmpty;

  bool get showingClosedInSearch =>
      livePlaces.isEmpty && searchQuery.trim().isNotEmpty && _filtered().isEmpty && _areaMatches.isNotEmpty;

  List<Place> _filtered() => filterPlaces(
        area: queryArea,
        radiusKm: radiusKm,
        type: type,
        cost: cost,
        openOnly: openOnly,
        chips: chips,
        latitude: originLat,
        longitude: originLng,
      );

  List<Place> _directoryNear(
    double lat,
    double lng, {
    required String placeType,
    required bool onlyOpen,
  }) {
    final ranked = [...allPlaces]..sort(
          (a, b) => haversineKm(lat, lng, a.lat, a.lng).compareTo(haversineKm(lat, lng, b.lat, b.lng)),
        );
    bool wanted(Place place, {required bool honorOpen}) {
      if (placeType == 'Pharmacy' && place.kind != PlaceKind.pharmacy) return false;
      if (placeType == 'Clinic' && place.kind != PlaceKind.clinic) return false;
      if (placeType == 'Community' && place.kind != PlaceKind.community) return false;
      if (honorOpen && !place.open) return false;
      return haversineKm(lat, lng, place.lat, place.lng) <= 22;
    }

    final openMatches = [for (final place in ranked) if (wanted(place, honorOpen: onlyOpen)) place];
    if (openMatches.isNotEmpty) return openMatches.take(12).toList();
    return [for (final place in ranked) if (wanted(place, honorOpen: false)) place].take(12).toList();
  }

  List<Place> get _areaMatches => filterPlaces(
        area: searchQuery,
        radiusKm: 500,
        type: type,
        cost: cost,
        openOnly: false,
        chips: chips.where((chip) => chip != 'Open now').toSet(),
        latitude: originLat,
        longitude: originLng,
      );

  bool _listingOk(
    Place place, {
    required bool honorOpen,
    required String placeType,
    required String placeCost,
    required bool onlyOpen,
    required Set<String> selected,
  }) {
    if (placeType == 'Pharmacy' && place.kind != PlaceKind.pharmacy) return false;
    if (placeType == 'Clinic' && place.kind != PlaceKind.clinic) return false;
    if (placeType == 'Community' && place.kind != PlaceKind.community) return false;
    if (honorOpen && (onlyOpen || selected.contains('Open now')) && !place.open) return false;
    if ((placeCost == 'Free' || selected.contains('Free')) && !place.free) return false;
    if (placeCost == 'Paid' && !place.paid) return false;
    if (placeCost == 'Low Cost' && place.paid) return false;
    if (selected.contains('Pads') && !place.tags.any((tag) => tag.toLowerCase().contains('pad'))) return false;
    if (selected.contains('Help') &&
        !place.tags.any((tag) {
          final value = tag.toLowerCase();
          return value.contains('free') || value.contains('test') || value.contains('help');
        })) {
      return false;
    }
    return true;
  }

  List<Place> _uniqueByName(Iterable<Place> source) {
    final seen = <String>{};
    final list = <Place>[];
    for (final place in source) {
      if (seen.add(place.name.toLowerCase())) list.add(place);
    }
    return list;
  }

  List<Place> get results => placesFor(
        radiusKm: radiusKm,
        type: type,
        cost: cost,
        openOnly: openOnly,
        chips: chips,
      );

  List<Place> placesFor({
    required double radiusKm,
    required String type,
    required String cost,
    required bool openOnly,
    required Set<String> chips,
  }) {
    final query = searchQuery.trim();
    final lat = originLat;
    final lng = originLng;
    int byDistance(Place a, Place b) =>
        kilometersBetween(lat, lng, a).compareTo(kilometersBetween(lat, lng, b));
    bool inRange(Place place) => kilometersBetween(lat, lng, place) <= radiusKm;

    List<Place> apply(Iterable<Place> pool) {
      var visible = _uniqueByName(
        pool.where(
          (place) =>
              inRange(place) &&
              _listingOk(
                place,
                honorOpen: true,
                placeType: type,
                placeCost: cost,
                onlyOpen: openOnly,
                selected: chips,
              ),
        ),
      );
      if (visible.isEmpty) {
        visible = _uniqueByName(
          pool.where(
            (place) =>
                inRange(place) &&
                _listingOk(
                  place,
                  honorOpen: false,
                  placeType: type,
                  placeCost: cost,
                  onlyOpen: openOnly,
                  selected: chips,
                ),
          ),
        );
      }
      visible.sort(byDistance);
      return _withNearby(visible, byDistance, radiusKm: radiusKm, type: type, cost: cost, chips: chips);
    }

    if (query.isNotEmpty) {
      final town = resolveTown(query);
      final pool = <Place>[
        ...livePlaces,
        ...filterPlaces(
          area: query,
          radiusKm: radiusKm,
          type: type,
          cost: cost,
          openOnly: openOnly,
          chips: chips,
          latitude: lat,
          longitude: lng,
        ),
        if (town != null) ..._directoryNear(town.lat, town.lng, placeType: type, onlyOpen: openOnly),
        if (town == null && searchLat != null && searchLng != null)
          ..._directoryNear(searchLat!, searchLng!, placeType: type, onlyOpen: openOnly),
      ];
      return apply(pool);
    }

    if (livePlaces.isNotEmpty) {
      return apply([
        ...livePlaces,
        ...filterPlaces(
          area: '',
          radiusKm: radiusKm,
          type: type,
          cost: cost,
          openOnly: false,
          chips: chips.where((chip) => chip != 'Open now').toSet(),
          latitude: lat,
          longitude: lng,
        ),
      ]);
    }

    final matched = filterPlaces(
      area: queryArea,
      radiusKm: radiusKm,
      type: type,
      cost: cost,
      openOnly: openOnly,
      chips: chips,
      latitude: lat,
      longitude: lng,
    ).where(inRange).toList();
    if (matched.isNotEmpty) return _withNearby(matched, byDistance, radiusKm: radiusKm, type: type, cost: cost, chips: chips);
    return _withNearby(
      nearestPlaces(
        latitude: lat,
        longitude: lng,
        type: type,
        cost: cost,
        openOnly: openOnly,
        chips: chips,
        limit: 6,
      ).where(inRange).toList(),
      byDistance,
      radiusKm: radiusKm,
      type: type,
      cost: cost,
      chips: chips,
    );
  }

  List<Place> _withNearby(
    List<Place> places,
    int Function(Place, Place) byDistance, {
    required double radiusKm,
    required String type,
    required String cost,
    required Set<String> chips,
  }) {
    final query = searchQuery.trim();
    final located = searchLat != null && searchLng != null;
    if (query.isNotEmpty && !located && resolveTown(query) == null) return places;
    final label = query.isNotEmpty
        ? (resolveTown(query)?.name ?? query)
        : (area.trim().isEmpty ? 'Nearby' : area.trim());
    final filled = ensureNearbyPlaces(
      places,
      originLat,
      originLng,
      label,
      radiusKm: radiusKm,
      type: type,
      cost: cost == 'Free' || chips.contains('Free') ? 'Free' : cost,
      padsOnly: chips.contains('Pads'),
    );
    filled.sort(byDistance);
    return filled;
  }

  int get foundSupplies => supplies.where((item) => item.found).length;

  double get supplyProgress =>
      supplies.isEmpty ? 0 : foundSupplies / supplies.length;

  int get openVisits => history.where((item) => item.badge == 'OPEN' || item.badge == 'FREE').length;

  int get freeVisits => history.where((item) => item.badge == 'FREE').length;

  int get closedVisits => history.where((item) => item.badge == 'CLOSED').length;

  VisitFeedback? feedbackFor(int placeId) {
    for (final item in feedback) {
      if (item.placeId == placeId) return item;
    }
    return null;
  }

  List<Place> get closedNearby {
    return filterPlaces(
      area: queryArea,
      radiusKm: radiusKm,
      type: type,
      cost: cost,
      openOnly: false,
      chips: chips.where((chip) => chip != 'Open now').toSet(),
      latitude: originLat,
      longitude: originLng,
    ).where((place) => !place.open).toList();
  }

  Future<void> load() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox('find_help');
      if (_box!.isEmpty) await _migrateFromPrefs();
      saved = _readList(_savedKey, SavedPlace.fromJson) ?? List.of(initialSaved);
      supplies = _readList(_supplyKey, SupplyItem.fromJson) ?? List.of(initialSupplies);
      history = _readList(_historyKey, HistoryVisit.fromJson) ?? List.of(historySeed);
      feedback = _readList(_feedbackKey, VisitFeedback.fromJson) ?? [];
      notes = _readList(_notesKey, VisitNote.fromJson) ?? List.of(initialNotes);
      reminders = _readList(_remindersKey, Reminder.fromJson) ?? List.of(initialReminders);
      _readGeoCache();
      managed = _readList(_managedKey, ManagedPharmacy.fromJson) ?? [];
      _syncManaged();
      final recentRaw = _box!.get(_recentKey);
      if (recentRaw is String) {
        recentSearches = (jsonDecode(recentRaw) as List<dynamic>).map(SearchRecord.fromJson).toList();
      }
      locationOn = _box!.get(_locationKey) as bool? ?? false;
      area = _box!.get(_areaKey) as String? ?? 'Kottawa';
      latitude = (_box!.get(_latKey) as num?)?.toDouble();
      longitude = (_box!.get(_lngKey) as num?)?.toDouble();
      searchQuery = _box!.get(_searchKey) as String? ?? '';
      final filtersRaw = _box!.get(_filtersKey);
      if (filtersRaw is String) {
        final filters = jsonDecode(filtersRaw) as Map<String, dynamic>;
        radiusKm = (filters['radius'] as num?)?.toDouble() ?? radiusKm;
        type = filters['type'] as String? ?? type;
        cost = filters['cost'] as String? ?? cost;
        openOnly = filters['openOnly'] as bool? ?? openOnly;
        final savedChips = filters['chips'];
        if (savedChips is List) {
          chips
            ..clear()
            ..addAll(savedChips.map((chip) => chip.toString()));
        }
      }
    } catch (_) {
      saved = List.of(initialSaved);
      supplies = List.of(initialSupplies);
      history = List.of(historySeed);
      notes = List.of(initialNotes);
      reminders = List.of(initialReminders);
      managed = [];
      _syncManaged();
    }
    if (latitude != null && longitude != null && livePlaces.isEmpty) {
      final label = area.trim().isEmpty ? (nearestAreaName(latitude!, longitude!) ?? 'Nearby') : area.trim();
      livePlaces = createdPlacesNear(latitude!, longitude!, label);
    }
    _watchReminders();
    ReminderAlerts.sync(reminders);
    _notify();
    if (locationOn) {
      final ok = await refreshLocation(requestPermission: false);
      if (ok) await loadLivePharmacies();
    }
  }

  Future<void> _migrateFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    Future<void> copyString(String key) async {
      final value = prefs.getString(key);
      if (value != null) await _box!.put(key, value);
    }

    await copyString(_savedKey);
    await copyString(_supplyKey);
    await copyString(_historyKey);
    await copyString(_feedbackKey);
    await copyString(_recentKey);
    await copyString(_areaKey);
    await copyString(_searchKey);
    await copyString(_notesKey);
    await copyString(_filtersKey);
    final on = prefs.getBool(_locationKey);
    if (on != null) await _box!.put(_locationKey, on);
    final lat = prefs.getDouble(_latKey);
    final lng = prefs.getDouble(_lngKey);
    if (lat != null) await _box!.put(_latKey, lat);
    if (lng != null) await _box!.put(_lngKey, lng);
  }

  List<T>? _readList<T>(String key, T Function(Map<String, dynamic>) decode) {
    final raw = _box?.get(key);
    if (raw is! String) return null;
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((item) => decode(Map<String, dynamic>.from(item as Map))).toList();
  }

  void setArea(String value) {
    area = value;
    _notify();
    _persist();
  }

  void setSearch(String value) {
    searchQuery = value;
    final query = value.trim();
    _liveTimer?.cancel();
    if (query.length < 2) {
      livePlaces = [];
      searchLat = null;
      searchLng = null;
      liveMessage = '';
      _notify();
      _persist();
      return;
    }
    final town = resolveTown(query);
    if (town != null) {
      searchLat = town.lat;
      searchLng = town.lng;
      area = town.name;
      livePlaces = createdPlacesNear(town.lat, town.lng, town.name);
      liveMessage = 'Pharmacies near ${town.name}';
    } else {
      searchLat = null;
      searchLng = null;
      liveMessage = 'Searching $query';
    }
    _notify();
    _persist();
    _liveTimer = Timer(const Duration(milliseconds: 280), () {
      loadLivePharmacies(placeName: query);
    });
  }

  void denyLocation() {
    _locationGen++;
    locationOn = false;
    locationDenied = true;
    locating = false;
    _positionSub?.cancel();
    _positionSub = null;
    _gpsTimer?.cancel();
    _gpsTimer = null;
    _notify();
    _persist();
  }

  void clearFilters() {
    radiusKm = 10;
    type = 'All';
    cost = 'Any';
    openOnly = false;
    chips
      ..remove('Open now')
      ..remove('Free')
      ..remove('Pads')
      ..remove('Help');
    _notify();
    _persist();
  }

  Future<void> loadLivePharmacies({String? placeName}) async {
    final gen = ++_fetchGen;
    liveLoading = true;
    final place = placeName?.trim() ?? '';
    final town = place.isEmpty ? null : resolveTown(place);
    liveMessage = place.isEmpty ? 'Finding pharmacies and clinics near you' : 'Finding pharmacies and clinics in $place';
    _notify();
    try {
      var pointLat = town?.lat ?? (place.isEmpty ? latitude : searchLat);
      var pointLng = town?.lng ?? (place.isEmpty ? longitude : searchLng);
      var label = town?.name ?? (place.isEmpty ? 'you' : place);
      if (place.isNotEmpty && town == null) {
        final found = await _locateOffline(place);
        if (_disposed || gen != _fetchGen) return;
        if (found != null) {
          pointLat = found.$1;
          pointLng = found.$2;
          label = found.$3;
        }
      }
      if (pointLat != null && pointLng != null) {
        if (place.isNotEmpty) {
          searchLat = pointLat;
          searchLng = pointLng;
          area = label;
          _rememberPlace(place, pointLat, pointLng, label);
        }
        livePlaces = createdPlacesNear(pointLat, pointLng, label);
        liveLoading = false;
        liveMessage = 'Pharmacies near $label, saved on this phone.';
        _notify();
      }
      final result = await fetchLivePharmacies(
        placeName: place.isEmpty ? null : place,
        latitude: pointLat,
        longitude: pointLng,
      );
      if (_disposed || gen != _fetchGen) return;
      pointLat = result.latitude ?? pointLat;
      pointLng = result.longitude ?? pointLng;
      if (result.label.isNotEmpty) label = result.label;
      if (place.isNotEmpty && result.places.isEmpty && pointLat == null && town == null) {
        livePlaces = [];
        searchLat = null;
        searchLng = null;
        liveMessage = 'No live listing for $place. Showing saved pharmacies and clinics that match.';
      } else if (pointLat != null && pointLng != null) {
        final places = result.places.isEmpty
            ? createdPlacesNear(pointLat, pointLng, label)
            : ensureNearbyPlaces(result.places, pointLat, pointLng, label);
        livePlaces = places;
        if (place.isNotEmpty) {
          searchLat = pointLat;
          searchLng = pointLng;
          area = label;
        }
        liveMessage = result.places.isEmpty
            ? 'Added pharmacies with photos near $label.'
            : '${result.places.length} live pharmacies and clinics near $label';
      }
    } catch (_) {
      if (_disposed || gen != _fetchGen) return;
      final fallbackTown = place.isEmpty ? null : resolveTown(place);
      final pointLat = fallbackTown?.lat ?? (place.isEmpty ? latitude : searchLat);
      final pointLng = fallbackTown?.lng ?? (place.isEmpty ? longitude : searchLng);
      final label = fallbackTown?.name ?? (place.isEmpty ? 'you' : place);
      if (pointLat != null && pointLng != null) {
        livePlaces = createdPlacesNear(pointLat, pointLng, label);
        if (place.isNotEmpty) {
          searchLat = pointLat;
          searchLng = pointLng;
        }
        liveMessage = 'Added pharmacies with photos near $label.';
      } else if (livePlaces.isEmpty) {
        liveMessage = 'No saved map point for $place. Try a town such as Kandy, Galle, or Jaffna.';
      } else {
        liveMessage = 'Pharmacies near ${area.trim().isEmpty ? 'you' : area.trim()}, saved on this phone.';
      }
    } finally {
      if (!_disposed && gen == _fetchGen) {
        liveLoading = false;
        _notify();
      }
    }
  }

  void goToTab(int index) {
    tab = index;
    _notify();
  }

  Future<bool> enableLocation() {
    return _locationTask ??= refreshLocation(requestPermission: true).whenComplete(() {
      _locationTask = null;
    });
  }

  Future<bool> refreshLocation({bool requestPermission = true}) {
    final gen = _locationGen;
    locating = true;
    _notify();
    return _readFreshPosition(requestPermission, gen);
  }

  Future<bool> _readFreshPosition(bool requestPermission, int gen) async {
    try {
      final serviceOn = await Geolocator.isLocationServiceEnabled();
      if (_disposed || gen != _locationGen) return false;
      if (!serviceOn) {
        locationOn = false;
        liveMessage = 'Turn on location on your phone, then tap Allow again.';
        if (requestPermission) await Geolocator.openLocationSettings();
        return false;
      }
      var permission = await Geolocator.checkPermission();
      if (_disposed || gen != _locationGen) return false;
      if (permission == LocationPermission.denied && requestPermission) {
        permission = await Geolocator.requestPermission();
      }
      if (_disposed || gen != _locationGen) return false;
      if (permission == LocationPermission.deniedForever) {
        locationOn = false;
        liveMessage = 'Allow location for Find Help in your phone settings.';
        if (requestPermission) await Geolocator.openAppSettings();
        return false;
      }
      final allowed = permission == LocationPermission.always || permission == LocationPermission.whileInUse;
      if (!allowed) {
        locationOn = false;
        return false;
      }
      Position? position;
      try {
        final settings = defaultTargetPlatform == TargetPlatform.android
            ? AndroidSettings(
                accuracy: LocationAccuracy.high,
                forceLocationManager: true,
                timeLimit: const Duration(seconds: 12),
              )
            : const LocationSettings(accuracy: LocationAccuracy.high);
        position = await Geolocator.getCurrentPosition(locationSettings: settings);
      } catch (_) {
        try {
          position = await Geolocator.getLastKnownPosition();
        } catch (_) {
          position = null;
        }
      }
      if (_disposed || gen != _locationGen) return false;
      if (position == null && latitude != null && longitude != null) {
        locationOn = true;
        locationDenied = false;
        final label = nearestAreaName(latitude!, longitude!) ?? area;
        if (searchQuery.trim().isEmpty) area = label;
        livePlaces = createdPlacesNear(latitude!, longitude!, area.trim().isEmpty ? 'Nearby' : area.trim());
        liveMessage = 'Using your last location. Pharmacies are saved on this phone.';
        return true;
      }
      if (position == null) {
        locationOn = false;
        liveMessage = 'Could not read your location. Allow location and try again.';
        return false;
      }
      if (_disposed || gen != _locationGen) return false;
      latitude = position.latitude;
      longitude = position.longitude;
      locationOn = true;
      locationDenied = false;
      if (searchQuery.trim().isEmpty) {
        area = nearestAreaName(position.latitude, position.longitude) ?? 'Near you';
      }
      _watchLocation();
      return true;
    } catch (_) {
      if (_disposed || gen != _locationGen) return false;
      if (latitude != null && longitude != null) {
        locationOn = true;
        livePlaces = createdPlacesNear(latitude!, longitude!, area.trim().isEmpty ? 'Nearby' : area.trim());
        liveMessage = 'Using your last location. Pharmacies are saved on this phone.';
        return true;
      }
      locationOn = false;
      liveMessage = 'Could not read your location. Allow location and try again.';
      return false;
    } finally {
      if (!_disposed && gen == _locationGen) {
        locating = false;
        _notify();
        _persist();
      }
    }
  }

  void _watchLocation() {
    _positionSub?.cancel();
    _gpsTimer?.cancel();
    final settings = defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.high,
            forceLocationManager: true,
            distanceFilter: 5,
            intervalDuration: const Duration(seconds: 2),
          )
        : const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 5,
          );
    _positionSub = Geolocator.getPositionStream(locationSettings: settings).listen(
      _onPosition,
      onError: (_) {},
    );
    _gpsTimer = Timer.periodic(const Duration(seconds: 3), (_) => _pollLocation());
  }

  Future<void> _pollLocation() async {
    if (_disposed || _polling || !locationOn) return;
    _polling = true;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 6));
      _onPosition(position);
    } catch (_) {
    } finally {
      _polling = false;
    }
  }

  void _onPosition(Position position) {
    if (_disposed) return;
    final previousLat = latitude;
    final previousLng = longitude;
    latitude = position.latitude;
    longitude = position.longitude;
    locationOn = true;
    if (searchQuery.trim().isEmpty) {
      area = nearestAreaName(position.latitude, position.longitude) ?? 'Near you';
    }
    _notify();
    final now = DateTime.now();
    if (_lastPersistAt == null || now.difference(_lastPersistAt!) > const Duration(seconds: 6)) {
      _lastPersistAt = now;
      _persist();
    }
    if (previousLat == null || previousLng == null || searchQuery.trim().isNotEmpty || liveLoading) return;
    final moved = haversineKm(previousLat, previousLng, position.latitude, position.longitude);
    if (moved >= 0.05) loadLivePharmacies();
  }

  void rememberSearch(String value) {
    final query = value.trim();
    if (query.length < 2) return;
    recentSearches = [
      SearchRecord(query: query, at: DateTime.now()),
      ...recentSearches.where((item) => item.query.toLowerCase() != query.toLowerCase()),
    ].take(8).toList();
    _notify();
    _persist();
  }

  void deleteSearch(String query) {
    recentSearches = recentSearches.where((item) => item.query.toLowerCase() != query.toLowerCase()).toList();
    _notify();
    _persist();
  }

  void clearSearches() {
    recentSearches = [];
    _notify();
    _persist();
  }

  void removeHistory(int placeId) {
    history = history.where((item) => item.placeId != placeId).toList();
    _notify();
    _persist();
  }

  void updateHistory(HistoryVisit visit) {
    history = [
      for (final item in history)
        if (item.placeId == visit.placeId) visit else item,
    ];
    _notify();
    _persist();
  }

  void recordVisit(Place place) {
    final badge = !place.open
        ? 'CLOSED'
        : place.free
            ? 'FREE'
            : 'OPEN';
    history = [
      HistoryVisit(
        placeId: place.id,
        name: place.name,
        visitedAt: DateTime.now(),
        badge: badge,
        tags: place.tags,
        km: kilometersBetween(originLat, originLng, place),
        photo: place.photo,
      ),
      ...history.where((item) => item.placeId != place.id),
    ];
    _notify();
    _persist();
  }

  void saveFeedback({
    required int placeId,
    required String experience,
    required String note,
  }) {
    feedback = [
      VisitFeedback(
        placeId: placeId,
        experience: experience,
        note: note.trim(),
        at: DateTime.now(),
      ),
      ...feedback.where((item) => item.placeId != placeId),
    ];
    _notify();
    _persist();
  }

  void toggleChip(String chip) {
    if (chips.contains(chip)) {
      chips.remove(chip);
    } else {
      chips.add(chip);
    }
    if (chip == 'Open now') openOnly = chips.contains(chip);
    _notify();
    _persist();
  }

  void applyFilters({
    required double radiusKm,
    required String type,
    required String cost,
    required bool openOnly,
  }) {
    this.radiusKm = radiusKm;
    this.type = type;
    this.cost = cost;
    this.openOnly = openOnly;
    if (openOnly) {
      chips.add('Open now');
    } else {
      chips.remove('Open now');
    }
    _notify();
    _persist();
  }

  void setServiceChips({required bool free, required bool pads}) {
    if (free) {
      chips.add('Free');
    } else {
      chips.remove('Free');
    }
    if (pads) {
      chips.add('Pads');
    } else {
      chips.remove('Pads');
    }
    _notify();
    _persist();
  }

  void addNote(VisitNote note) {
    notes = [note, ...notes];
    _notify();
    _persist();
  }

  void updateNote(VisitNote note) {
    notes = [
      for (final item in notes)
        if (item.id == note.id) note else item,
    ];
    _notify();
    _persist();
  }

  void removeNote(int id) {
    notes = notes.where((item) => item.id != id).toList();
    _notify();
    _persist();
  }

  Future<bool> addReminder(Reminder reminder) async {
    reminders = [reminder, ...reminders];
    _notify();
    _persist();
    return _armReminders(ask: true);
  }

  Future<bool> updateReminder(Reminder reminder) async {
    reminders = [
      for (final item in reminders)
        if (item.id == reminder.id) reminder else item,
    ];
    _notify();
    _persist();
    return _armReminders(ask: true);
  }

  void removeReminder(int id) {
    reminders = reminders.where((item) => item.id != id).toList();
    _notify();
    _persist();
    ReminderAlerts.sync(reminders);
  }

  List<Reminder> get dueReminders => [for (final reminder in reminders) if (reminder.isDue) reminder];

  void completeReminder(int id) {
    reminders = [
      for (final item in reminders)
        if (item.id == id) item.copyWith(done: true) else item,
    ];
    _notify();
    _persist();
    ReminderAlerts.sync(reminders);
  }

  void snoozeReminder(int id) {
    final next = DateTime.now().add(const Duration(minutes: 10));
    reminders = [
      for (final item in reminders)
        if (item.id == id)
          item.copyWith(
            atMillis: next.millisecondsSinceEpoch,
            when: formatReminderWhen(next),
            done: false,
          )
        else item,
    ];
    _notify();
    _persist();
    ReminderAlerts.sync(reminders);
  }

  Future<bool> _armReminders({required bool ask}) async {
    final ready = ask ? await ReminderAlerts.prepare() : true;
    await ReminderAlerts.sync(reminders);
    return ready;
  }

  Future<(double, double, String)?> _locateOffline(String place) async {
    final key = place.trim().toLowerCase();
    final cached = _geoCache[key];
    if (cached != null) return cached;
    try {
      final found = await geocodeSriLanka(place).timeout(const Duration(seconds: 6));
      if (found != null) _rememberPlace(place, found.$1, found.$2, found.$3);
      return found;
    } catch (_) {
      return null;
    }
  }

  void _rememberPlace(String place, double lat, double lng, String name) {
    final key = place.trim().toLowerCase();
    if (key.isEmpty) return;
    _geoCache[key] = (lat, lng, name);
    final box = _box;
    if (box == null) return;
    box.put(
      _geoKey,
      jsonEncode({
        for (final entry in _geoCache.entries)
          entry.key: {'lat': entry.value.$1, 'lng': entry.value.$2, 'name': entry.value.$3},
      }),
    );
  }

  void _readGeoCache() {
    final raw = _box?.get(_geoKey);
    if (raw is! String) return;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return;
    decoded.forEach((key, value) {
      if (value is! Map) return;
      final lat = (value['lat'] as num?)?.toDouble();
      final lng = (value['lng'] as num?)?.toDouble();
      final name = value['name'] as String? ?? key.toString();
      if (lat == null || lng == null) return;
      _geoCache[key.toString()] = (lat, lng, name);
    });
  }

  void _watchReminders() {
    _reminderTimer?.cancel();
    if (_disposed) return;
    _reminderTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!_disposed) _notify();
    });
  }

  void removeFeedback(int placeId) {
    feedback = feedback.where((item) => item.placeId != placeId).toList();
    _notify();
    _persist();
  }

  void addSaved(SavedPlace place) {
    saved = [place, ...saved];
    _notify();
    _persist();
  }

  void updateSaved(SavedPlace place) {
    saved = [
      for (final item in saved)
        if (item.id == place.id) place else item,
    ];
    _notify();
    _persist();
  }

  void removeSaved(int id) {
    saved = saved.where((item) => item.id != id).toList();
    _notify();
    _persist();
  }

  void addSupply(SupplyItem item) {
    supplies = [...supplies, item];
    _notify();
    _persist();
  }

  void updateSupply(SupplyItem item) {
    supplies = [
      for (final current in supplies)
        if (current.id == item.id) item else current,
    ];
    _notify();
    _persist();
  }

  void removeSupply(int id) {
    supplies = supplies.where((item) => item.id != id).toList();
    _notify();
    _persist();
  }

  void _syncManaged() {
    userPlaces = managed.map((item) => item.toPlace()).toList();
  }

  void addManaged(ManagedPharmacy pharmacy) {
    managed = [pharmacy, ...managed];
    _syncManaged();
    _notify();
    _persist();
  }

  void updateManaged(ManagedPharmacy pharmacy) {
    managed = [
      for (final item in managed)
        if (item.id == pharmacy.id) pharmacy else item,
    ];
    _syncManaged();
    _notify();
    _persist();
  }

  void removeManaged(int id) {
    managed = managed.where((item) => item.id != id).toList();
    _syncManaged();
    _notify();
    _persist();
  }

  void toggleFound(int id) {
    supplies = [
      for (final item in supplies)
        if (item.id == id) item.copyWith(found: !item.found) else item,
    ];
    _notify();
    _persist();
  }

  void clearHistory() {
    history = [];
    _notify();
    _persist();
  }

  bool isSaved(String name) =>
      saved.any((item) => item.name.toLowerCase() == name.toLowerCase());

  Future<void> _persist() async {
    final box = _box;
    if (box == null) return;
    try {
      await box.put(_savedKey, jsonEncode(saved.map((item) => item.toJson()).toList()));
      await box.put(_supplyKey, jsonEncode(supplies.map((item) => item.toJson()).toList()));
      await box.put(_historyKey, jsonEncode(history.map((item) => item.toJson()).toList()));
      await box.put(_feedbackKey, jsonEncode(feedback.map((item) => item.toJson()).toList()));
      await box.put(_recentKey, jsonEncode(recentSearches.map((item) => item.toJson()).toList()));
      await box.put(_notesKey, jsonEncode(notes.map((item) => item.toJson()).toList()));
      await box.put(_remindersKey, jsonEncode(reminders.map((item) => item.toJson()).toList()));
      await box.put(_managedKey, jsonEncode(managed.map((item) => item.toJson()).toList()));
      await box.put(_locationKey, locationOn);
      await box.put(_areaKey, area);
      await box.put(_searchKey, searchQuery);
      await box.put(
        _filtersKey,
        jsonEncode({
          'radius': radiusKm,
          'type': type,
          'cost': cost,
          'openOnly': openOnly,
          'chips': chips.toList(),
        }),
      );
      if (latitude != null) await box.put(_latKey, latitude);
      if (longitude != null) await box.put(_lngKey, longitude);
    } catch (_) {}
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _liveTimer?.cancel();
    _gpsTimer?.cancel();
    _reminderTimer?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({
    super.key,
    required AppController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope was not found');
    return scope!.notifier!;
  }
}
