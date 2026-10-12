import 'package:hive/hive.dart';

part 'starred_tip.g.dart';

/// A health tip starred/bookmarked by the user. Keyed by [tipId] in the box.
@HiveType(typeId: 3)
class StarredTip extends HiveObject {
  @HiveField(0)
  String tipId;

  @HiveField(1)
  String contentEn;

  @HiveField(2)
  String contentSi;

  @HiveField(3)
  String category;

  @HiveField(4)
  DateTime starredAt;

  StarredTip({
    required this.tipId,
    required this.contentEn,
    required this.contentSi,
    required this.category,
    required this.starredAt,
  });
}
