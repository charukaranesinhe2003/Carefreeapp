import 'package:hive/hive.dart';

part 'cycle_entry.g.dart';

@HiveType(typeId: 0)
class CycleEntry extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  String flow;

  @HiveField(2)
  String symptoms;

  @HiveField(3)
  String mood;

  @HiveField(4)
  String note;

  @HiveField(5)
  bool isPeriodDay;

  CycleEntry({
    required this.date,
    this.flow = '',
    this.symptoms = '',
    this.mood = '',
    this.note = '',
    this.isPeriodDay = false,
  });
}
