import 'package:hive/hive.dart';

part 'daily_log.g.dart';

@HiveType(typeId: 2)
class DailyLog extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  String flowIntensity;

  @HiveField(2)
  String symptoms;

  @HiveField(3)
  String mood;

  @HiveField(4)
  String note;

  DailyLog({
    required this.date,
    required this.flowIntensity,
    required this.symptoms,
    required this.mood,
    required this.note,
  });
}
