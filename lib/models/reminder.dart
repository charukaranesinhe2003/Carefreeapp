class Reminder {
  final String id;
  final String title;
  final int hour;
  final int minute;
  final bool isActive;

  Reminder({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'hour': hour,
      'minute': minute,
      'isActive': isActive,
    };
  }

  factory Reminder.fromMap(Map<dynamic, dynamic> map) {
    return Reminder(
      id: map['id'] as String,
      title: map['title'] as String,
      hour: map['hour'] as int,
      minute: map['minute'] as int,
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}
