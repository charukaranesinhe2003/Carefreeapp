import 'dart:math' as math;

enum PlaceKind { pharmacy, clinic, community }

enum SupplyPriority { routine, soon, urgent }

class StockLine {
  const StockLine(this.name, this.status, {this.cold = false});

  final String name;
  final String status;
  final bool cold;
}

class Place {
  const Place({
    required this.id,
    required this.name,
    required this.address,
    required this.open,
    required this.km,
    required this.tags,
    required this.kind,
    required this.free,
    required this.paid,
    required this.pinX,
    required this.pinY,
    required this.phone,
    required this.area,
    required this.lat,
    required this.lng,
    this.photo = 'assets/photos/city.jpg',
    this.note,
    this.closedNote = 'Opens tomorrow at 8:00 AM',
    this.localName,
    this.branchCode,
    this.queue,
    this.stock = const [],
    this.services = const [],
  });

  final int id;
  final String name;
  final String address;
  final String area;
  final bool open;
  final double km;
  final List<String> tags;
  final PlaceKind kind;
  final bool free;
  final bool paid;
  final double pinX;
  final double pinY;
  final String phone;
  final double lat;
  final double lng;
  final String photo;
  final String? note;
  final String closedNote;
  final String? localName;
  final String? branchCode;
  final String? queue;
  final List<StockLine> stock;
  final List<String> services;

  List<StockLine> get listedStock => stock.isNotEmpty
      ? stock
      : [for (final tag in tags) StockLine(tag, open ? 'Listed' : 'Ask on arrival')];

  String get distanceLabel => '${km.toStringAsFixed(1)} km';

  String get kindLabel => switch (kind) {
        PlaceKind.pharmacy => 'Pharmacy',
        PlaceKind.clinic => 'Clinic',
        PlaceKind.community => 'Community',
      };

  String get hoursLine {
    if (!open) return closedNote;
    if (note != null) return 'Open now · $note';
    return 'Open now · Until 6:00 PM';
  }
}

const places = <Place>[
  Place(
    id: 1,
    name: 'Rajya Osu Sala',
    address: '452 High Level Rd, Kottawa Junction',
    open: true,
    km: 1.2,
    tags: ['Pads', 'Tampons', 'Cups', 'Free Supplies'],
    kind: PlaceKind.pharmacy,
    free: false,
    paid: false,
    pinX: 0.52,
    pinY: 0.42,
    phone: '+94 11 222 1100',
    area: 'Kottawa',
    lat: 6.8480,
    lng: 79.9580,
    photo: 'assets/photos/city.jpg',
    localName: 'රාජ්‍ය ඔසු සාලා',
    branchCode: 'DS-452',
    queue: '~2 min',
    note: 'Until 10:00 PM',
    services: ['Blood glucose check', 'BP monitoring', 'Discreet counter'],
    stock: [
      StockLine('Sanitary napkins / pads', 'In stock'),
      StockLine('Pain relief (paracetamol)', 'In stock'),
      StockLine('Iron tablets', 'In stock'),
      StockLine('Sanitary pads (eco pack)', 'In stock'),
      StockLine('Cold-chain items', 'Cold chain safe', cold: true),
    ],
  ),
  Place(
    id: 2,
    name: 'Health Guard Pharmacy',
    address: 'University Health Block C, Kottawa',
    open: true,
    km: 0.9,
    tags: ['Pads', 'Condoms', 'Free Supplies', 'Testing'],
    kind: PlaceKind.pharmacy,
    free: true,
    paid: false,
    pinX: 0.68,
    pinY: 0.62,
    phone: '+94 11 234 5678',
    area: 'Kottawa',
    lat: 6.8355,
    lng: 79.9720,
    photo: 'assets/photos/health.jpg',
    note: 'Until 10:00 PM',
    queue: 'Short',
  ),
  Place(
    id: 3,
    name: 'Prasanna Pharmacy',
    address: 'Near Bus Stand, Mahiyanganaya',
    open: false,
    km: 140,
    tags: ['Emergency Kit', 'Pads', 'OTC Meds'],
    kind: PlaceKind.pharmacy,
    free: false,
    paid: false,
    pinX: 0.22,
    pinY: 0.30,
    phone: '+94 55 222 0190',
    area: 'Mahiyanganaya',
    lat: 7.3317,
    lng: 80.9926,
    photo: 'assets/photos/prasanna.jpg',
  ),
  Place(
    id: 4,
    name: 'Gagana Pharmacy',
    address: 'Station Road, Kottawa',
    open: true,
    km: 2.1,
    tags: ['Tampons', 'Pads', 'OTC Meds'],
    kind: PlaceKind.pharmacy,
    free: false,
    paid: true,
    pinX: 0.36,
    pinY: 0.74,
    phone: '+94 11 289 4410',
    area: 'Kottawa',
    lat: 6.8280,
    lng: 79.9550,
    photo: 'assets/photos/gagana.jpg',
  ),
  Place(
    id: 5,
    name: 'Nugegoda Pharmacy',
    address: 'High Level Road, Nugegoda',
    open: true,
    km: 7.6,
    tags: ['Pads', 'Tampons', 'OTC Meds'],
    kind: PlaceKind.pharmacy,
    free: false,
    paid: false,
    pinX: 0.18,
    pinY: 0.58,
    phone: '+94 11 281 2200',
    area: 'Nugegoda',
    lat: 6.8644,
    lng: 79.8996,
    photo: 'assets/photos/nugegoda.jpg',
  ),
  Place(
    id: 6,
    name: 'Colombo Pharmacy',
    address: 'Reid Avenue, Colombo 07',
    open: true,
    km: 13.2,
    tags: ['Pads', 'Condoms', 'Free Supplies'],
    kind: PlaceKind.pharmacy,
    free: true,
    paid: false,
    pinX: 0.78,
    pinY: 0.36,
    phone: '+94 11 258 4400',
    area: 'Colombo',
    lat: 6.9022,
    lng: 79.8612,
    photo: 'assets/photos/colombo.jpg',
  ),
  Place(
    id: 7,
    name: 'Campus Clinic',
    address: 'University of Moratuwa, Katubedda',
    open: true,
    km: 8.8,
    tags: ['Pads', 'Testing', 'Free Supplies'],
    kind: PlaceKind.clinic,
    free: true,
    paid: false,
    pinX: 0.62,
    pinY: 0.22,
    phone: '+94 11 265 0300',
    area: 'Moratuwa',
    lat: 6.7951,
    lng: 79.9009,
    photo: 'assets/photos/campus.jpg',
    note: 'Until 4:00 PM',
  ),
  Place(
    id: 8,
    name: 'Family Health Bureau & MOH Centre',
    address: 'Maternal & child health, Kottawa',
    open: true,
    km: 2.3,
    tags: ['Pads', 'Help', 'Free Supplies'],
    kind: PlaceKind.community,
    free: true,
    paid: false,
    pinX: 0.84,
    pinY: 0.7,
    phone: '+94 11 278 0900',
    area: 'Kottawa',
    lat: 6.8445,
    lng: 79.9605,
    photo: 'assets/photos/community.jpg',
  ),
  Place(
    id: 9,
    name: 'Maharagama Osu Sala',
    address: 'High Level Road, Maharagama',
    open: true,
    km: 4.4,
    tags: ['Pads', 'OTC Meds', 'Free Supplies'],
    kind: PlaceKind.pharmacy,
    free: true,
    paid: false,
    pinX: 0.4,
    pinY: 0.5,
    phone: '+94 11 284 5500',
    area: 'Maharagama',
    lat: 6.8482,
    lng: 79.9267,
    photo: 'assets/photos/maharagama.jpg',
    note: 'Until 8:00 PM',
  ),
  Place(
    id: 10,
    name: 'Pannipitiya Pharmacy',
    address: 'High Level Road, Pannipitiya',
    open: true,
    km: 2.2,
    tags: ['Pads', 'Tampons'],
    kind: PlaceKind.pharmacy,
    free: false,
    paid: false,
    pinX: 0.46,
    pinY: 0.48,
    phone: '+94 11 285 2201',
    area: 'Pannipitiya',
    lat: 6.8464,
    lng: 79.9468,
    photo: 'assets/photos/pannipitiya.jpg',
    note: 'Until 9:00 PM',
  ),
  Place(
    id: 11,
    name: 'Homagama Pharmacy',
    address: 'Homagama Town, Homagama',
    open: true,
    km: 4.8,
    tags: ['Pads', 'OTC Meds'],
    kind: PlaceKind.pharmacy,
    free: false,
    paid: true,
    pinX: 0.7,
    pinY: 0.55,
    phone: '+94 11 289 7700',
    area: 'Homagama',
    lat: 6.8431,
    lng: 80.0024,
    photo: 'assets/photos/homagama.jpg',
  ),
  Place(
    id: 12,
    name: 'Dehiwala Pharmacy',
    address: 'Galle Road, Dehiwala',
    open: true,
    km: 11.2,
    tags: ['Pads', 'Condoms', 'OTC Meds'],
    kind: PlaceKind.pharmacy,
    free: false,
    paid: false,
    pinX: 0.2,
    pinY: 0.4,
    phone: '+94 11 271 4400',
    area: 'Dehiwala',
    lat: 6.8569,
    lng: 79.8653,
    photo: 'assets/photos/dehiwala.jpg',
    note: 'Until 10:00 PM',
  ),
  Place(
    id: 13,
    name: 'Battaramulla Pharmacy',
    address: 'Kaduwela Road, Battaramulla',
    open: true,
    km: 8.1,
    tags: ['Pads', 'Free Supplies'],
    kind: PlaceKind.pharmacy,
    free: true,
    paid: false,
    pinX: 0.55,
    pinY: 0.25,
    phone: '+94 11 287 3300',
    area: 'Battaramulla',
    lat: 6.8986,
    lng: 79.9223,
    photo: 'assets/photos/battaramulla.jpg',
  ),
  Place(
    id: 14,
    name: 'Kaduwela Pharmacy',
    address: 'Kaduwela Town, Kaduwela',
    open: false,
    km: 12.4,
    tags: ['Pads', 'OTC Meds'],
    kind: PlaceKind.pharmacy,
    free: false,
    paid: false,
    pinX: 0.72,
    pinY: 0.2,
    phone: '+94 11 257 1180',
    area: 'Kaduwela',
    lat: 6.9354,
    lng: 79.9836,
    photo: 'assets/photos/kaduwela.jpg',
    closedNote: 'Opens tomorrow at 8:00 AM',
  ),
  Place(
    id: 15,
    name: 'Kandy Osu Sala',
    address: 'Dalada Veediya, Kandy',
    open: true,
    km: 115,
    tags: ['Pads', 'OTC Meds', 'Free Supplies'],
    kind: PlaceKind.pharmacy,
    free: true,
    paid: false,
    pinX: 0.5,
    pinY: 0.4,
    phone: '+94 81 223 4400',
    area: 'Kandy',
    lat: 7.2936,
    lng: 80.6413,
    photo: 'assets/photos/city.jpg',
    note: 'Until 8:00 PM',
  ),
  Place(
    id: 16,
    name: 'Peradeniya Road Pharmacy',
    address: 'Peradeniya Road, Kandy',
    open: true,
    km: 116,
    tags: ['Pads', 'Tampons', 'OTC Meds'],
    kind: PlaceKind.pharmacy,
    free: false,
    paid: true,
    pinX: 0.48,
    pinY: 0.46,
    phone: '+94 81 222 1188',
    area: 'Kandy',
    lat: 7.2765,
    lng: 80.6210,
    photo: 'assets/photos/health.jpg',
  ),
  Place(
    id: 17,
    name: 'Galle Fort Pharmacy',
    address: 'Church Street, Galle Fort',
    open: true,
    km: 128,
    tags: ['Pads', 'OTC Meds'],
    kind: PlaceKind.pharmacy,
    free: false,
    paid: false,
    pinX: 0.4,
    pinY: 0.6,
    phone: '+94 91 223 5500',
    area: 'Galle',
    lat: 6.0269,
    lng: 80.2170,
    photo: 'assets/photos/gagana.jpg',
    note: 'Until 9:00 PM',
  ),
  Place(
    id: 18,
    name: 'Jaffna Osu Sala',
    address: 'Hospital Road, Jaffna',
    open: true,
    km: 360,
    tags: ['Pads', 'Free Supplies', 'OTC Meds'],
    kind: PlaceKind.pharmacy,
    free: true,
    paid: false,
    pinX: 0.55,
    pinY: 0.3,
    phone: '+94 21 222 3300',
    area: 'Jaffna',
    lat: 9.6645,
    lng: 80.0205,
    photo: 'assets/photos/colombo.jpg',
  ),
  Place(
    id: 19,
    name: 'Negombo Pharmacy',
    address: 'Main Street, Negombo',
    open: true,
    km: 42,
    tags: ['Pads', 'Condoms', 'OTC Meds'],
    kind: PlaceKind.pharmacy,
    free: false,
    paid: false,
    pinX: 0.3,
    pinY: 0.35,
    phone: '+94 31 222 4410',
    area: 'Negombo',
    lat: 7.2088,
    lng: 79.8358,
    photo: 'assets/photos/dehiwala.jpg',
    note: 'Until 10:00 PM',
  ),
  Place(
    id: 20,
    name: 'Gampaha Pharmacy',
    address: 'Colombo Road, Gampaha',
    open: true,
    km: 32,
    tags: ['Pads', 'OTC Meds'],
    kind: PlaceKind.pharmacy,
    free: false,
    paid: true,
    pinX: 0.6,
    pinY: 0.28,
    phone: '+94 33 222 1900',
    area: 'Gampaha',
    lat: 7.0912,
    lng: 79.9940,
    photo: 'assets/photos/homagama.jpg',
  ),
  Place(
    id: 21,
    name: 'Kurunegala Osu Sala',
    address: 'Colombo Road, Kurunegala',
    open: true,
    km: 94,
    tags: ['Pads', 'Free Supplies'],
    kind: PlaceKind.pharmacy,
    free: true,
    paid: false,
    pinX: 0.42,
    pinY: 0.22,
    phone: '+94 37 222 4500',
    area: 'Kurunegala',
    lat: 7.4863,
    lng: 80.3620,
    photo: 'assets/photos/maharagama.jpg',
  ),
  Place(
    id: 22,
    name: 'Matara Pharmacy',
    address: 'Station Road, Matara',
    open: true,
    km: 155,
    tags: ['Pads', 'OTC Meds'],
    kind: PlaceKind.pharmacy,
    free: false,
    paid: false,
    pinX: 0.38,
    pinY: 0.7,
    phone: '+94 41 222 6700',
    area: 'Matara',
    lat: 5.9496,
    lng: 80.5490,
    photo: 'assets/photos/nugegoda.jpg',
  ),
  Place(
    id: 23,
    name: 'Anuradhapura Pharmacy',
    address: 'Main Street, Anuradhapura',
    open: false,
    km: 200,
    tags: ['Pads', 'OTC Meds'],
    kind: PlaceKind.pharmacy,
    free: false,
    paid: false,
    pinX: 0.5,
    pinY: 0.18,
    phone: '+94 25 222 3100',
    area: 'Anuradhapura',
    lat: 8.3114,
    lng: 80.4037,
    photo: 'assets/photos/battaramulla.jpg',
    closedNote: 'Opens tomorrow at 8:00 AM',
  ),
];

/// Pharmacies the user creates, edits, and deletes. Stored in Hive.
List<Place> userPlaces = [];

List<Place> get allPlaces => <Place>[...places, ...userPlaces];

class SavedPlace {
  const SavedPlace({
    required this.id,
    required this.name,
    required this.area,
    required this.kind,
    required this.note,
  });

  final int id;
  final String name;
  final String area;
  final String kind;
  final String note;

  SavedPlace copyWith({String? name, String? area, String? kind, String? note}) {
    return SavedPlace(
      id: id,
      name: name ?? this.name,
      area: area ?? this.area,
      kind: kind ?? this.kind,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'area': area,
        'kind': kind,
        'note': note,
      };

  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    return SavedPlace(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      area: json['area'] as String,
      kind: json['kind'] as String? ?? 'Pharmacy',
      note: json['note'] as String? ?? '',
    );
  }
}

class SupplyItem {
  const SupplyItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.priority,
    required this.found,
  });

  final int id;
  final String name;
  final String quantity;
  final SupplyPriority priority;
  final bool found;

  SupplyItem copyWith({
    String? name,
    String? quantity,
    SupplyPriority? priority,
    bool? found,
  }) {
    return SupplyItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      priority: priority ?? this.priority,
      found: found ?? this.found,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'priority': priority.name,
        'found': found,
      };

  factory SupplyItem.fromJson(Map<String, dynamic> json) {
    return SupplyItem(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      quantity: json['quantity'] as String,
      priority: SupplyPriority.values.byName(json['priority'] as String? ?? 'routine'),
      found: json['found'] as bool? ?? false,
    );
  }
}

class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.place,
    required this.when,
    this.atMillis,
    this.done = false,
  });

  final int id;
  final String title;
  final String place;
  final String when;
  final int? atMillis;
  final bool done;

  DateTime? get at => atMillis == null ? null : DateTime.fromMillisecondsSinceEpoch(atMillis!);

  bool get isDue {
    final time = at;
    if (done || time == null) return false;
    return !time.isAfter(DateTime.now());
  }

  String get status {
    if (done) return 'Done';
    if (at == null) return 'Needs a time';
    if (isDue) return 'Due now';
    return 'Upcoming';
  }

  Reminder copyWith({
    String? title,
    String? place,
    String? when,
    int? atMillis,
    bool? done,
  }) {
    return Reminder(
      id: id,
      title: title ?? this.title,
      place: place ?? this.place,
      when: when ?? this.when,
      atMillis: atMillis ?? this.atMillis,
      done: done ?? this.done,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'place': place,
        'when': when,
        'atMillis': atMillis,
        'done': done,
      };

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      place: json['place'] as String? ?? '',
      when: json['when'] as String? ?? '',
      atMillis: (json['atMillis'] as num?)?.toInt(),
      done: json['done'] as bool? ?? false,
    );
  }
}

String formatReminderWhen(DateTime at) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final hour = at.hour % 12 == 0 ? 12 : at.hour % 12;
  final minute = at.minute.toString().padLeft(2, '0');
  final suffix = at.hour >= 12 ? 'PM' : 'AM';
  return '${months[at.month - 1]} ${at.day}, ${at.year} · $hour:$minute $suffix';
}

const initialReminders = <Reminder>[
  Reminder(
    id: 1,
    title: 'Pick up pads',
    place: 'Health Guard Pharmacy',
    when: 'Today, 4:00 PM',
  ),
];

const historyPhotos = [
  'assets/photos/city.jpg',
  'assets/photos/health.jpg',
  'assets/photos/gagana.jpg',
  'assets/photos/nugegoda.jpg',
  'assets/photos/colombo.jpg',
  'assets/photos/maharagama.jpg',
  'assets/photos/homagama.jpg',
  'assets/photos/battaramulla.jpg',
];

class HistoryVisit {
  const HistoryVisit({
    required this.placeId,
    required this.name,
    required this.visitedAt,
    required this.badge,
    required this.tags,
    required this.km,
    this.note = '',
    this.photo = '',
  });

  final int placeId;
  final String name;
  final DateTime visitedAt;
  final String badge;
  final List<String> tags;
  final double km;
  final String note;
  final String photo;

  HistoryVisit copyWith({
    String? name,
    String? badge,
    String? note,
    double? km,
  }) {
    return HistoryVisit(
      placeId: placeId,
      name: name ?? this.name,
      visitedAt: visitedAt,
      badge: badge ?? this.badge,
      tags: tags,
      km: km ?? this.km,
      note: note ?? this.note,
      photo: photo,
    );
  }

  String get subtitle => '${km.toStringAsFixed(1)} km · Visited $visitedOn';

  String get visitedOn {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[visitedAt.month - 1]} ${visitedAt.day}, ${visitedAt.year}';
  }

  Map<String, dynamic> toJson() => {
        'placeId': placeId,
        'name': name,
        'visitedAt': visitedAt.toIso8601String(),
        'badge': badge,
        'tags': tags,
        'km': km,
        'note': note,
        'photo': photo,
      };

  factory HistoryVisit.fromJson(Map<String, dynamic> json) {
    return HistoryVisit(
      placeId: (json['placeId'] as num).toInt(),
      name: json['name'] as String,
      visitedAt: DateTime.parse(json['visitedAt'] as String),
      badge: json['badge'] as String? ?? 'OPEN',
      tags: (json['tags'] as List<dynamic>).map((tag) => tag as String).toList(),
      km: (json['km'] as num).toDouble(),
      note: json['note'] as String? ?? '',
      photo: json['photo'] as String? ?? '',
    );
  }
}

class VisitFeedback {
  const VisitFeedback({
    required this.placeId,
    required this.experience,
    required this.note,
    required this.at,
  });

  final int placeId;
  final String experience;
  final String note;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'placeId': placeId,
        'experience': experience,
        'note': note,
        'at': at.toIso8601String(),
      };

  factory VisitFeedback.fromJson(Map<String, dynamic> json) {
    return VisitFeedback(
      placeId: (json['placeId'] as num).toInt(),
      experience: json['experience'] as String,
      note: json['note'] as String? ?? '',
      at: DateTime.parse(json['at'] as String),
    );
  }
}

const initialSaved = <SavedPlace>[
  SavedPlace(
    id: 1,
    name: 'Health Guard Pharmacy',
    area: 'University Health Block C',
    kind: 'Pharmacy',
    note: 'Free supplies available',
  ),
  SavedPlace(
    id: 2,
    name: 'City Community Clinic',
    area: 'Kottawa town centre',
    kind: 'Clinic',
    note: 'Open weekdays until 6 PM',
  ),
];

class VisitNote {
  const VisitNote({
    required this.id,
    required this.title,
    required this.place,
    required this.body,
  });

  final int id;
  final String title;
  final String place;
  final String body;

  VisitNote copyWith({String? title, String? place, String? body}) {
    return VisitNote(
      id: id,
      title: title ?? this.title,
      place: place ?? this.place,
      body: body ?? this.body,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'place': place,
        'body': body,
      };

  factory VisitNote.fromJson(Map<String, dynamic> json) {
    return VisitNote(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      place: json['place'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}

const initialNotes = <VisitNote>[
  VisitNote(
    id: 1,
    title: 'Ask for free pads',
    place: 'Health Guard Pharmacy',
    body: 'Counter keeps free supplies until 4 PM',
  ),
];

const initialSupplies = <SupplyItem>[
  SupplyItem(
    id: 1,
    name: 'Pain relief',
    quantity: '1 pack',
    priority: SupplyPriority.soon,
    found: false,
  ),
  SupplyItem(
    id: 2,
    name: 'Hygiene supplies',
    quantity: '2 packs',
    priority: SupplyPriority.urgent,
    found: true,
  ),
  SupplyItem(
    id: 3,
    name: 'Oral rehydration salts',
    quantity: '5 sachets',
    priority: SupplyPriority.routine,
    found: false,
  ),
];

final historySeed = <HistoryVisit>[
  HistoryVisit(
    placeId: 1,
    name: 'Rajya Osu Sala',
    visitedAt: DateTime(2024, 5, 18),
    badge: 'OPEN',
    tags: ['Pads', 'Tampons', 'Free Supplies'],
    km: 1.2,
  ),
  HistoryVisit(
    placeId: 2,
    name: 'Health Guard Pharmacy',
    visitedAt: DateTime(2024, 6, 1),
    badge: 'FREE',
    tags: ['Pads', 'Condoms', 'Free Supplies', 'Testing'],
    km: 0.9,
  ),
  HistoryVisit(
    placeId: 4,
    name: 'Gagana Pharmacy',
    visitedAt: DateTime(2025, 8, 23),
    badge: 'OPEN',
    tags: ['Tampons', 'Pads', 'OTC Meds'],
    km: 2.1,
  ),
];

class SearchRecord {
  const SearchRecord({required this.query, required this.at});

  final String query;
  final DateTime at;

  String get when {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[at.month - 1]} ${at.day}';
  }

  Map<String, dynamic> toJson() => {
        'query': query,
        'at': at.toIso8601String(),
      };

  factory SearchRecord.fromJson(dynamic raw) {
    if (raw is String) {
      return SearchRecord(query: raw, at: DateTime.now());
    }
    final json = raw as Map<String, dynamic>;
    return SearchRecord(
      query: json['query'] as String? ?? '',
      at: DateTime.tryParse(json['at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

final recentSearchSeed = <SearchRecord>[
  SearchRecord(query: 'Colombo 07', at: DateTime(2026, 9, 28, 14, 10)),
  SearchRecord(query: 'University of Moratuwa', at: DateTime(2026, 9, 26, 9, 40)),
  SearchRecord(query: 'Nugegoda', at: DateTime(2026, 9, 21, 18, 5)),
];

String weekdayName(int weekday) {
  const names = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return names[weekday - 1];
}

Place? placeById(int id) {
  for (final place in allPlaces) {
    if (place.id == id) return place;
  }
  return null;
}

Place? placeByName(String name) {
  final key = name.toLowerCase().replaceAll(' ', '');
  for (final place in allPlaces) {
    if (place.name.toLowerCase().replaceAll(' ', '') == key) return place;
  }
  return null;
}

String historyPhoto(HistoryVisit visit) {
  if (visit.photo.isNotEmpty) return visit.photo;
  final known = placeById(visit.placeId) ?? placeByName(visit.name);
  if (known != null) return known.photo;
  return historyPhotos[visit.placeId.abs() % historyPhotos.length];
}

Place placeForHistory(HistoryVisit visit) {
  final known = placeById(visit.placeId) ?? placeByName(visit.name);
  if (known != null) return known;
  return Place(
    id: visit.placeId,
    name: visit.name,
    address: visit.subtitle,
    area: visit.name,
    open: visit.badge != 'CLOSED',
    km: visit.km,
    tags: visit.tags,
    kind: PlaceKind.pharmacy,
    free: visit.badge == 'FREE',
    paid: false,
    pinX: 0.5,
    pinY: 0.5,
    phone: '+94 11 200 1100',
    lat: 6.8412,
    lng: 79.9654,
    photo: historyPhoto(visit),
  );
}

Place placeForSaved(SavedPlace saved) {
  final known = placeByName(saved.name);
  if (known != null) return known;
  return Place(
    id: saved.id,
    name: saved.name,
    address: saved.area,
    area: saved.area,
    open: true,
    km: 1.1,
    tags: [
      saved.kind,
      if (saved.note.isNotEmpty) saved.note,
    ],
    kind: switch (saved.kind) {
      'Clinic' => PlaceKind.clinic,
      'Community' => PlaceKind.community,
      _ => PlaceKind.pharmacy,
    },
    free: saved.note.toLowerCase().contains('free'),
    paid: false,
    pinX: 0.5,
    pinY: 0.46,
    phone: '+94 11 234 5600',
    lat: 6.8412,
    lng: 79.9654,
    note: saved.note.isEmpty ? null : saved.note,
  );
}

const _searchStopWords = {
  'area',
  'areas',
  'near',
  'nearby',
  'town',
  'the',
  'and',
  'for',
  'around',
  'from',
  'with',
  'pharmacy',
  'pharmacies',
  'clinic',
  'clinics',
  'search',
  'find',
};

List<String> _queryWords(String query) {
  return query
      .trim()
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((word) => word.length > 2 && !_searchStopWords.contains(word))
      .toList();
}

bool _textMatch(Place place, List<String> words) {
  if (words.isEmpty) return true;
  final haystack = '${place.name} ${place.address} ${place.area} ${place.kindLabel} ${place.tags.join(' ')}'
      .toLowerCase();
  return words.every(haystack.contains);
}

bool _namedDirectly(Place place, List<String> words) {
  if (words.isEmpty) return false;
  final identity = '${place.name} ${place.address} ${place.area}'.toLowerCase();
  return words.every(identity.contains);
}

double kilometersBetween(double? latitude, double? longitude, Place place) {
  if (latitude == null || longitude == null) return place.km;
  return haversineKm(latitude, longitude, place.lat, place.lng);
}

double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const earth = 6371.0;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
  return earth * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

String formatKm(double km) {
  if (km >= 100) return '${km.toStringAsFixed(0)} km';
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1)} km';
}

class DistanceBand {
  const DistanceBand({required this.title, required this.detail, required this.places});

  final String title;
  final String detail;
  final List<Place> places;
}

List<DistanceBand> distanceBands(List<Place> places, double latitude, double longitude) {
  final underOne = <Place>[];
  final oneToTwo = <Place>[];
  final twoToThree = <Place>[];
  final further = <Place>[];
  for (final place in places) {
    final km = kilometersBetween(latitude, longitude, place);
    if (km < 1) {
      underOne.add(place);
    } else if (km < 2) {
      oneToTwo.add(place);
    } else if (km < 3) {
      twoToThree.add(place);
    } else {
      further.add(place);
    }
  }
  return [
    DistanceBand(title: 'Under 1 km', detail: 'Less than 1 km', places: underOne),
    DistanceBand(title: '1–2 km', detail: 'Between 1 and 2 km', places: oneToTwo),
    DistanceBand(title: '2–3 km', detail: 'Between 2 and 3 km', places: twoToThree),
    DistanceBand(title: '3 km and further', detail: '3 km and further', places: further),
  ];
}

List<Place> filterPlaces({
  required String area,
  required double radiusKm,
  required String type,
  required String cost,
  required bool openOnly,
  required Set<String> chips,
  double? latitude,
  double? longitude,
}) {
  final words = _queryWords(area);
  final matched = allPlaces.where((place) {
    if (!_textMatch(place, words)) return false;
    final distance = kilometersBetween(latitude, longitude, place);
    final outsideRadius = distance > radiusKm && !_namedDirectly(place, words);
    if (outsideRadius) return false;
    if ((openOnly || chips.contains('Open now')) && !place.open) return false;
    if (type == 'Pharmacy' && place.kind != PlaceKind.pharmacy) return false;
    if (type == 'Clinic' && place.kind != PlaceKind.clinic) return false;
    if (type == 'Community' && place.kind != PlaceKind.community) return false;
    if ((cost == 'Free' || chips.contains('Free')) && !place.free) return false;
    if (cost == 'Paid' && !place.paid) return false;
    if (cost == 'Low Cost' && place.paid) return false;
    if (chips.contains('Pads') &&
        !place.tags.any((tag) => tag.toLowerCase().contains('pad'))) {
      return false;
    }
    if (chips.contains('Help') &&
        !place.tags.any((tag) {
          final value = tag.toLowerCase();
          return value.contains('free') || value.contains('test') || value.contains('help');
        })) {
      return false;
    }
    return true;
  }).toList();
  matched.sort(
    (a, b) => kilometersBetween(latitude, longitude, a).compareTo(kilometersBetween(latitude, longitude, b)),
  );
  return matched;
}

List<Place> nearestPlaces({
  required double latitude,
  required double longitude,
  required String type,
  required String cost,
  required bool openOnly,
  required Set<String> chips,
  int limit = 4,
}) {
  final matched = filterPlaces(
    area: '',
    radiusKm: 20000,
    type: type,
    cost: cost,
    openOnly: openOnly,
    chips: chips,
    latitude: latitude,
    longitude: longitude,
  );
  return matched.take(limit).toList();
}

List<String> searchSuggestions(String query) {
  final words = _queryWords(query);
  if (words.isEmpty) return const [];
  final suggestions = <String>{};
  for (final place in allPlaces) {
    if (_textMatch(place, words)) {
      suggestions.add(place.name);
      suggestions.add(place.area);
    }
  }
  return suggestions.take(6).toList();
}

class AreaPin {
  const AreaPin(this.name, this.lat, this.lng);

  final String name;
  final double lat;
  final double lng;
}

const areaPins = <AreaPin>[
  AreaPin('Kottawa', 6.8412, 79.9654),
  AreaPin('Nugegoda', 6.8644, 79.8996),
  AreaPin('Maharagama', 6.8482, 79.9267),
  AreaPin('Pannipitiya', 6.8464, 79.9468),
  AreaPin('Homagama', 6.8431, 80.0024),
  AreaPin('Dehiwala', 6.8569, 79.8653),
  AreaPin('Battaramulla', 6.8986, 79.9223),
  AreaPin('Kaduwela', 6.9354, 79.9836),
  AreaPin('Colombo', 6.9271, 79.8612),
  AreaPin('Moratuwa', 6.7951, 79.9009),
  AreaPin('Mahiyanganaya', 7.3317, 80.9926),
  AreaPin('Kandy', 7.2906, 80.6337),
  AreaPin('Galle', 6.0320, 80.2168),
  AreaPin('Jaffna', 9.6615, 80.0255),
  AreaPin('Negombo', 7.2083, 79.8358),
  AreaPin('Gampaha', 7.0917, 79.9994),
  AreaPin('Kurunegala', 7.4863, 80.3647),
  AreaPin('Matara', 5.9549, 80.5550),
  AreaPin('Anuradhapura', 8.3114, 80.4037),
  AreaPin('Ratnapura', 6.6828, 80.3992),
  AreaPin('Badulla', 6.9934, 81.0550),
  AreaPin('Trincomalee', 8.5874, 81.2152),
  AreaPin('Batticaloa', 7.7102, 81.6924),
  AreaPin('Kalutara', 6.5854, 79.9607),
  AreaPin('Panadura', 6.7133, 79.9026),
  AreaPin('Malabe', 6.9061, 79.9696),
  AreaPin('Kiribathgoda', 6.9806, 79.9297),
  AreaPin('Ella', 6.8667, 81.0466),
  AreaPin('Nuwara Eliya', 6.9497, 80.7891),
  AreaPin('Hatton', 6.8916, 80.5959),
  AreaPin('Bandarawela', 6.8259, 80.9982),
  AreaPin('Haputale', 6.7667, 80.9500),
  AreaPin('Badulla', 6.9934, 81.0550),
  AreaPin('Monaragala', 6.8728, 81.3508),
  AreaPin('Wellawaya', 6.7369, 81.1028),
  AreaPin('Kataragama', 6.4135, 81.3326),
  AreaPin('Tissamaharama', 6.2792, 81.2870),
  AreaPin('Hambantota', 6.1246, 81.1185),
  AreaPin('Tangalle', 6.0240, 80.7941),
  AreaPin('Matara', 5.9549, 80.5550),
  AreaPin('Weligama', 5.9750, 80.4297),
  AreaPin('Unawatuna', 6.0174, 80.2489),
  AreaPin('Hikkaduwa', 6.1407, 80.1010),
  AreaPin('Ambalangoda', 6.2355, 80.0538),
  AreaPin('Elpitiya', 6.2886, 80.1615),
  AreaPin('Bentota', 6.4259, 79.9956),
  AreaPin('Aluthgama', 6.4347, 79.9975),
  AreaPin('Beruwala', 6.4788, 79.9828),
  AreaPin('Kalutara', 6.5854, 79.9607),
  AreaPin('Horana', 6.7159, 80.0626),
  AreaPin('Bandaragama', 6.7133, 79.9886),
  AreaPin('Panadura', 6.7133, 79.9026),
  AreaPin('Moratuwa', 6.7951, 79.9009),
  AreaPin('Piliyandala', 6.8018, 79.9227),
  AreaPin('Kesbewa', 6.7969, 79.9403),
  AreaPin('Mount Lavinia', 6.8381, 79.8630),
  AreaPin('Ratmalana', 6.8217, 79.8686),
  AreaPin('Dehiwala', 6.8569, 79.8653),
  AreaPin('Wellawatte', 6.8747, 79.8604),
  AreaPin('Bambalapitiya', 6.8933, 79.8564),
  AreaPin('Kollupitiya', 6.9106, 79.8492),
  AreaPin('Borella', 6.9147, 79.8778),
  AreaPin('Rajagiriya', 6.9092, 79.8943),
  AreaPin('Nawala', 6.8964, 79.8876),
  AreaPin('Kotte', 6.8905, 79.9036),
  AreaPin('Thalawathugoda', 6.8746, 79.9390),
  AreaPin('Athurugiriya', 6.8780, 79.9980),
  AreaPin('Padukka', 6.8440, 80.0910),
  AreaPin('Avissawella', 6.9543, 80.2114),
  AreaPin('Hanwella', 6.9010, 80.0850),
  AreaPin('Kaduwela', 6.9354, 79.9836),
  AreaPin('Kelaniya', 6.9559, 79.9220),
  AreaPin('Wattala', 6.9892, 79.8914),
  AreaPin('Ja-Ela', 7.0742, 79.8919),
  AreaPin('Katunayake', 7.1697, 79.8846),
  AreaPin('Negombo', 7.2083, 79.8358),
  AreaPin('Chilaw', 7.5758, 79.7953),
  AreaPin('Puttalam', 8.0362, 79.8283),
  AreaPin('Wennappuwa', 7.3414, 79.8362),
  AreaPin('Gampaha', 7.0917, 79.9994),
  AreaPin('Minuwangoda', 7.1664, 79.9533),
  AreaPin('Veyangoda', 7.1569, 80.0566),
  AreaPin('Nittambuwa', 7.1421, 80.0950),
  AreaPin('Mirigama', 7.2417, 80.1281),
  AreaPin('Warakapola', 7.2267, 80.1953),
  AreaPin('Kegalle', 7.2513, 80.3464),
  AreaPin('Mawanella', 7.2517, 80.4467),
  AreaPin('Peradeniya', 7.2699, 80.5938),
  AreaPin('Gampola', 7.1643, 80.5696),
  AreaPin('Nawalapitiya', 7.0444, 80.5347),
  AreaPin('Matale', 7.4675, 80.6234),
  AreaPin('Dambulla', 7.8600, 80.6517),
  AreaPin('Sigiriya', 7.9570, 80.7603),
  AreaPin('Kurunegala', 7.4863, 80.3647),
  AreaPin('Kuliyapitiya', 7.4688, 80.0447),
  AreaPin('Wariyapola', 7.6278, 80.2431),
  AreaPin('Nikaweratiya', 7.7480, 80.1167),
  AreaPin('Polonnaruwa', 7.9403, 81.0188),
  AreaPin('Anuradhapura', 8.3114, 80.4037),
  AreaPin('Vavuniya', 8.7514, 80.4971),
  AreaPin('Mannar', 8.9779, 79.9044),
  AreaPin('Kilinochchi', 9.3803, 80.3770),
  AreaPin('Jaffna', 9.6615, 80.0255),
  AreaPin('Point Pedro', 9.8167, 80.2333),
  AreaPin('Trincomalee', 8.5874, 81.2152),
  AreaPin('Kantale', 8.3594, 80.9936),
  AreaPin('Batticaloa', 7.7102, 81.6924),
  AreaPin('Kalmunai', 7.4090, 81.8347),
  AreaPin('Ampara', 7.2914, 81.6747),
  AreaPin('Akkaraipattu', 7.2186, 81.8497),
  AreaPin('Ratnapura', 6.6828, 80.3992),
  AreaPin('Balangoda', 6.6569, 80.6994),
  AreaPin('Embilipitiya', 6.3434, 80.8497),
  AreaPin('Eheliyagoda', 6.8489, 80.2614),
  AreaPin('Kuruwita', 6.7792, 80.3681),
];

String _foldPlace(String value) => value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

AreaPin? resolveTown(String query) {
  final raw = query.trim().toLowerCase();
  if (raw.length < 2) return null;
  final foldedQuery = _foldPlace(raw);
  final words = raw.split(RegExp(r'[^a-z0-9]+')).where((word) => word.length > 2).toSet();
  AreaPin? best;
  var bestScore = 0;
  for (final pin in areaPins) {
    final name = pin.name.toLowerCase();
    final foldedName = _foldPlace(name);
    var score = 0;
    if (foldedQuery.isNotEmpty && foldedQuery == foldedName) {
      score = 100;
    } else if (raw == name) {
      score = 100;
    } else if (words.contains(name)) {
      score = 80;
    } else if (name.startsWith(raw) || (foldedQuery.length >= 4 && foldedName.startsWith(foldedQuery))) {
      score = 70;
    } else if (name.length >= 5 && raw.contains(name)) {
      score = 60;
    } else if (raw.length >= 3 && name.contains(raw)) {
      score = 40;
    }
    if (score > bestScore) {
      bestScore = score;
      best = pin;
    }
  }
  return bestScore >= 40 ? best : null;
}

String? nearestAreaName(double lat, double lng) {
  AreaPin? best;
  var bestKm = double.infinity;
  for (final pin in areaPins) {
    final distance = haversineKm(lat, lng, pin.lat, pin.lng);
    if (distance < bestKm) {
      bestKm = distance;
      best = pin;
    }
  }
  if (best == null || bestKm > 25) return null;
  return best.name;
}

class ManagedPharmacy {
  const ManagedPharmacy({
    required this.id,
    required this.name,
    required this.address,
    required this.area,
    required this.phone,
    required this.open,
    required this.free,
    required this.kind,
    required this.tags,
    this.note = '',
    this.lat,
    this.lng,
  });

  final int id;
  final String name;
  final String address;
  final String area;
  final String phone;
  final bool open;
  final bool free;
  final String kind;
  final List<String> tags;
  final String note;
  final double? lat;
  final double? lng;

  Place toPlace() {
    final pin = resolveTown(area) ?? resolveTown(address);
    final pointLat = lat ?? pin?.lat ?? 6.8412;
    final pointLng = lng ?? pin?.lng ?? 79.9654;
    return Place(
      id: id,
      name: name,
      address: address.isEmpty ? area : address,
      area: area,
      open: open,
      km: haversineKm(6.8412, 79.9654, pointLat, pointLng),
      tags: tags.isEmpty ? [kind] : tags,
      kind: switch (kind) {
        'Clinic' => PlaceKind.clinic,
        'Community' => PlaceKind.community,
        _ => PlaceKind.pharmacy,
      },
      free: free,
      paid: !free,
      pinX: 0.5,
      pinY: 0.5,
      phone: phone.isEmpty ? 'No phone listed' : phone,
      lat: pointLat,
      lng: pointLng,
      note: note.isEmpty ? null : note,
      photo: 'assets/photos/health.jpg',
    );
  }

  ManagedPharmacy copyWith({
    String? name,
    String? address,
    String? area,
    String? phone,
    bool? open,
    bool? free,
    String? kind,
    List<String>? tags,
    String? note,
    double? lat,
    double? lng,
  }) {
    return ManagedPharmacy(
      id: id,
      name: name ?? this.name,
      address: address ?? this.address,
      area: area ?? this.area,
      phone: phone ?? this.phone,
      open: open ?? this.open,
      free: free ?? this.free,
      kind: kind ?? this.kind,
      tags: tags ?? this.tags,
      note: note ?? this.note,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'area': area,
        'phone': phone,
        'open': open,
        'free': free,
        'kind': kind,
        'tags': tags,
        'note': note,
        'lat': lat,
        'lng': lng,
      };

  factory ManagedPharmacy.fromJson(Map<String, dynamic> json) {
    return ManagedPharmacy(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      area: json['area'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      open: json['open'] as bool? ?? true,
      free: json['free'] as bool? ?? false,
      kind: json['kind'] as String? ?? 'Pharmacy',
      tags: (json['tags'] as List<dynamic>? ?? const []).map((tag) => tag.toString()).toList(),
      note: json['note'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
    );
  }
}
