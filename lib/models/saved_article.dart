import 'package:hive/hive.dart';

part 'saved_article.g.dart';

/// An article saved to the Offline Library. Keyed by [articleId] in the box.
@HiveType(typeId: 1)
class SavedArticle extends HiveObject {
  @HiveField(0)
  String articleId;

  @HiveField(1)
  DateTime savedAt;

  SavedArticle({required this.articleId, required this.savedAt});
}
