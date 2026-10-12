import 'package:find_help/live_pharmacies.dart';
import 'package:find_help/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('kottawa search keeps nearby open places', () {
    final results = filterPlaces(
      area: 'Kottawa',
      radiusKm: 5,
      type: 'All',
      cost: 'Any',
      openOnly: true,
      chips: {'Open now'},
    );
    expect(results.every((place) => place.open), isTrue);
    expect(results.map((place) => place.name), contains('Rajya Osu Sala'));
    expect(results.map((place) => place.name), isNot(contains('Prasanna Pharmacy')));
    expect(results.map((place) => place.name), isNot(contains('Campus Clinic')));
  });

  test('searching a town by name finds that place', () {
    final results = filterPlaces(
      area: 'Mahiyanganaya',
      radiusKm: 5,
      type: 'All',
      cost: 'Any',
      openOnly: false,
      chips: {},
    );
    expect(results, isNotEmpty);
    expect(results.first.name, 'Prasanna Pharmacy');
  });

  test('university search returns the campus clinic', () {
    final results = filterPlaces(
      area: 'University of Moratuwa',
      radiusKm: 5,
      type: 'All',
      cost: 'Any',
      openOnly: false,
      chips: {},
    );
    expect(results.map((place) => place.name), contains('Campus Clinic'));
  });

  test('searching Kandy shows pharmacies in that area', () {
    final results = filterPlaces(
      area: 'Kandy',
      radiusKm: 5,
      type: 'All',
      cost: 'Any',
      openOnly: false,
      chips: {},
    );
    expect(results.map((place) => place.area), everyElement('Kandy'));
    expect(results.map((place) => place.name), contains('Kandy Osu Sala'));
  });

  test('a typed area resolves to coordinates', () {
    final pin = resolveTown('Nugegoda');
    expect(pin, isNotNull);
    expect(pin!.name, 'Nugegoda');
    expect(resolveTown('colo')?.name, 'Colombo');
    expect(resolveTown('Ella')?.name, 'Ella');
    expect(resolveTown('nuwaraeliya')?.name, 'Nuwara Eliya');
  });

  test('free chip keeps only free places', () {
    final results = filterPlaces(
      area: 'Kottawa',
      radiusKm: 5,
      type: 'All',
      cost: 'Any',
      openOnly: false,
      chips: {'Free'},
    );
    expect(results, isNotEmpty);
    expect(results.every((place) => place.free), isTrue);
    expect(results.map((place) => place.name), contains('Health Guard Pharmacy'));
  });

  test('places are grouped into distance bands', () {
    Place sample(int id, double lat) {
      return Place(
        id: id,
        name: 'Place $id',
        address: 'Road',
        open: true,
        km: 0,
        tags: const ['Pharmacy'],
        kind: id.isEven ? PlaceKind.clinic : PlaceKind.pharmacy,
        free: false,
        paid: false,
        pinX: 0.5,
        pinY: 0.5,
        phone: '011',
        area: 'Test',
        lat: lat,
        lng: 79.96,
      );
    }

    final bands = distanceBands(
      [
        sample(1, 6.844),
        sample(2, 6.854),
        sample(3, 6.863),
        sample(4, 6.880),
      ],
      6.84,
      79.96,
    );
    expect(bands.map((band) => band.title), ['Under 1 km', '1–2 km', '2–3 km', '3 km and further']);
    expect(bands[0].places.single.kind, PlaceKind.pharmacy);
    expect(bands[1].places.single.kind, PlaceKind.clinic);
    expect(bands[2].places.single.id, 3);
    expect(bands[3].places.single.id, 4);
  });

  test('missing pharmacies are created around the searched point', () {
    final created = createdPlacesNear(7.0, 80.0, 'Ella');
    expect(created, isNotEmpty);
    expect(created.every((place) => place.area == 'Ella'), isTrue);
    expect(created.every((place) => place.photo.startsWith('assets/photos/')), isTrue);
    expect(created.any((place) => place.kind == PlaceKind.pharmacy), isTrue);
    expect(created.any((place) => place.kind == PlaceKind.clinic), isTrue);
    final bands = distanceBands(created, 7.0, 80.0);
    expect(bands.any((band) => band.places.isNotEmpty), isTrue);
  });

  test('empty close ranges get pharmacies and clinics', () {
    final far = Place(
      id: 50,
      name: 'Far Pharmacy',
      address: 'Road',
      open: true,
      km: 6,
      tags: const ['Pharmacy'],
      kind: PlaceKind.pharmacy,
      free: false,
      paid: false,
      pinX: 0.5,
      pinY: 0.5,
      phone: '011',
      area: 'Far',
      lat: 7.05,
      lng: 80.0,
    );
    final filled = ensureNearbyPlaces([far], 7.0, 80.0, 'Ella');
    final bands = distanceBands(filled, 7.0, 80.0);
    expect(bands[0].places, isNotEmpty);
    expect(bands[1].places, isNotEmpty);
    expect(bands[2].places, isNotEmpty);
    expect(bands[3].places.single.name, 'Far Pharmacy');
  });

  test('distance and pharmacy filters change which places are added', () {
    final far = Place(
      id: 50,
      name: 'Far Pharmacy',
      address: 'Road',
      open: true,
      km: 6,
      tags: const ['Pharmacy'],
      kind: PlaceKind.pharmacy,
      free: false,
      paid: false,
      pinX: 0.5,
      pinY: 0.5,
      phone: '011',
      area: 'Far',
      lat: 7.05,
      lng: 80.0,
    );
    final closeOnly = ensureNearbyPlaces([far], 7.0, 80.0, 'Ella', radiusKm: 1);
    final bands = distanceBands(closeOnly, 7.0, 80.0);
    expect(bands[0].places, isNotEmpty);
    expect(bands[1].places, isEmpty);
    expect(bands[3].places, isEmpty);
    final pharmacies = ensureNearbyPlaces(const [], 7.0, 80.0, 'Ella', type: 'Pharmacy', padsOnly: true);
    expect(pharmacies, isNotEmpty);
    expect(pharmacies.every((place) => place.kind == PlaceKind.pharmacy), isTrue);
    expect(pharmacies.every((place) => place.tags.any((tag) => tag.toLowerCase().contains('pad'))), isTrue);
  });

  test('a visit keeps its pharmacy photo', () {
    final visit = HistoryVisit(
      placeId: 800004,
      name: 'Ella Pharmacy',
      visitedAt: DateTime(2026, 10, 6),
      badge: 'OPEN',
      tags: const ['Pharmacy'],
      km: 0.4,
      photo: 'assets/photos/gagana.jpg',
    );
    expect(placeForHistory(visit).photo, 'assets/photos/gagana.jpg');
    final older = HistoryVisit(
      placeId: 800004,
      name: 'Ella Pharmacy',
      visitedAt: DateTime(2026, 10, 6),
      badge: 'OPEN',
      tags: const ['Pharmacy'],
      km: 0.4,
    );
    expect(historyPhoto(older), historyPhotos[800004 % historyPhotos.length]);
  });
}
