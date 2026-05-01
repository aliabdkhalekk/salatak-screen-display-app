import '../../prayer/domain/prayer_models.dart';

enum ContentType {
  hadith,
  adhkar,
  sunnah,
  nawawi,
  friday,
}

extension ContentTypeX on ContentType {
  String get labelArabic {
    switch (this) {
      case ContentType.hadith:
        return 'حديث';
      case ContentType.adhkar:
        return 'ذكر';
      case ContentType.sunnah:
        return 'سنة';
      case ContentType.nawawi:
        return 'نووي';
      case ContentType.friday:
        return 'الجمعة';
    }
  }

  static ContentType fromJson(String value) {
    return ContentType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ContentType.hadith,
    );
  }
}

enum DisplayContext {
  general,
  betweenPrayers,
  beforePrayerGeneral,
  beforePrayerSpecific,
  afterAdhan,
  afterPrayer,
  friday,
}

extension DisplayContextX on DisplayContext {
  String get storageKey {
    switch (this) {
      case DisplayContext.general:
        return 'general';
      case DisplayContext.betweenPrayers:
        return 'between_prayers';
      case DisplayContext.beforePrayerGeneral:
        return 'before_prayer_general';
      case DisplayContext.beforePrayerSpecific:
        return 'before_prayer_specific';
      case DisplayContext.afterAdhan:
        return 'after_adhan';
      case DisplayContext.afterPrayer:
        return 'after_prayer';
      case DisplayContext.friday:
        return 'friday';
    }
  }

  static DisplayContext fromJson(String value) {
    return DisplayContext.values.firstWhere(
      (context) => context.storageKey == value,
      orElse: () => DisplayContext.general,
    );
  }
}

class ContentItem {
  const ContentItem({
    required this.id,
    required this.title,
    required this.text,
    required this.source,
    required this.tags,
    required this.priority,
    required this.displayContexts,
    required this.type,
    this.order = 0,
    this.category,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id'].toString(),
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? (json['title'] as String).trim()
          : 'محتوى إيماني',
      text: (json['text'] as String? ?? '').trim(),
      source: (json['source'] as String? ?? 'مصدر محلي').trim(),
      tags: ((json['tags'] as List<dynamic>?) ?? const <dynamic>[])
          .map((tag) => tag.toString())
          .toList(),
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      displayContexts:
          ((json['displayContexts'] as List<dynamic>?) ?? const <dynamic>[])
              .map((context) => DisplayContextX.fromJson(context.toString()))
              .toList(),
      type: ContentTypeX.fromJson(
        (json['type'] as String?) ?? ContentType.hadith.name,
      ),
      order: (json['order'] as num?)?.toInt() ?? 0,
      category: (json['category'] as String?)?.trim(),
    );
  }

  final String id;
  final String title;
  final String text;
  final String source;
  final List<String> tags;
  final int priority;
  final List<DisplayContext> displayContexts;
  final ContentType type;
  final int order;
  final String? category;

  bool hasContext(DisplayContext context) => displayContexts.contains(context);

  ContentItem copyWith({
    String? id,
    String? title,
    String? text,
    String? source,
    List<String>? tags,
    int? priority,
    List<DisplayContext>? displayContexts,
    ContentType? type,
    int? order,
    String? category,
  }) {
    return ContentItem(
      id: id ?? this.id,
      title: title ?? this.title,
      text: text ?? this.text,
      source: source ?? this.source,
      tags: tags ?? this.tags,
      priority: priority ?? this.priority,
      displayContexts: displayContexts ?? this.displayContexts,
      type: type ?? this.type,
      order: order ?? this.order,
      category: category ?? this.category,
    );
  }

  int? get hadithNumber {
    if (type != ContentType.nawawi || order <= 0) {
      return null;
    }
    return order;
  }

  bool get isFridayContent {
    return type == ContentType.friday ||
        displayContexts.contains(DisplayContext.friday);
  }

  bool appliesToPrayer(PrayerName? prayer) {
    if (prayer == null) {
      return true;
    }

    final prayerTags = tags.where((tag) => tag.startsWith('prayer_')).toList();
    if (prayerTags.isEmpty) {
      return true;
    }
    return prayerTags.contains(prayer.tagKey);
  }

  String preview({int maxChars = 700}) {
    final normalized = text.replaceAll('\n\n', '\n').trim();
    if (normalized.length <= maxChars) {
      return normalized;
    }
    return '${normalized.substring(0, maxChars).trim()}...';
  }

  static ContentItem fallback({
    required String id,
    required String title,
    required String text,
    required String source,
    required ContentType type,
    required List<DisplayContext> displayContexts,
    String? category,
  }) {
    return ContentItem(
      id: id,
      title: title,
      text: text,
      source: source,
      tags: const <String>[],
      priority: 1,
      displayContexts: displayContexts,
      type: type,
      category: category,
    );
  }
}

extension ContentItemLibraryMetadataX on ContentItem {
  String get sourceName => source;

  String get categoryName {
    final trimmedCategory = category?.trim();
    if (trimmedCategory != null && trimmedCategory.isNotEmpty) {
      return trimmedCategory;
    }

    if (type == ContentType.hadith && _isPrayerRelatedHadith) {
      return 'أحاديث عن الصلاة';
    }

    if (type == ContentType.hadith && _isEthicsRelatedHadith) {
      return 'أحاديث عن الأخلاق';
    }

    if (type == ContentType.adhkar) {
      return _isDuaLike ? 'أدعية' : 'أذكار';
    }

    return collectionName;
  }

  String get categoryId {
    switch (categoryName) {
      case 'الأربعون النووية':
        return 'collection_nawawi';
      case 'ركن الجمعة':
        return 'collection_friday';
      case 'أذكار':
        return 'category_adhkar';
      case 'أدعية':
        return 'category_dua';
      case 'أحاديث عن الصلاة':
        return 'category_prayer_hadith';
      case 'أحاديث عن الأخلاق':
        return 'category_ethics_hadith';
      case 'سنن الصلاة':
        return 'category_sunnah';
      case 'أحاديث قصيرة':
        return 'category_short_hadith';
      default:
        return _libraryKeyFrom(categoryName);
    }
  }

  String get collectionName {
    switch (type) {
      case ContentType.nawawi:
        return 'الأربعون النووية';
      case ContentType.friday:
        return 'ركن الجمعة';
      case ContentType.adhkar:
        return _isDuaLike ? 'أدعية' : 'أذكار';
      case ContentType.sunnah:
        return 'سنن الصلاة';
      case ContentType.hadith:
        if (_isPrayerRelatedHadith) {
          return 'أحاديث عن الصلاة';
        }
        if (_isEthicsRelatedHadith) {
          return 'أحاديث عن الأخلاق';
        }
        return 'أحاديث قصيرة';
    }
  }

  String? get collectionSubtitle {
    switch (collectionName) {
      case 'الأربعون النووية':
        return 'الأحاديث الجامعة للإمام النووي';
      case 'ركن الجمعة':
        return 'فضائل وآداب وتذكيرات يوم الجمعة';
      case 'أذكار':
        return 'أذكار يومية ومأثورة';
      case 'أدعية':
        return 'أدعية مأثورة صالحة للعرض';
      case 'سنن الصلاة':
        return 'رواتب وآداب وسنن متعلقة بالصلاة';
      case 'أحاديث عن الصلاة':
        return 'أحاديث مختارة عن الصلاة والجماعة والمسجد';
      case 'أحاديث عن الأخلاق':
        return 'تذكيرات نبوية في السلوك والآداب';
      case 'أحاديث قصيرة':
        return 'أحاديث مختصرة جامعة للعرض العام';
    }

    return null;
  }

  int get libraryCollectionSortOrder {
    switch (collectionName) {
      case 'الأربعون النووية':
        return 10;
      case 'أحاديث عن الصلاة':
        return 20;
      case 'سنن الصلاة':
        return 30;
      case 'أذكار':
        return 40;
      case 'أدعية':
        return 50;
      case 'ركن الجمعة':
        return 60;
      case 'أحاديث عن الأخلاق':
        return 70;
      case 'أحاديث قصيرة':
        return 80;
      default:
        return 100;
    }
  }

  bool get _isPrayerRelatedHadith {
    return tags.any((tag) => tag.startsWith('prayer_')) ||
        tags.contains('before_prayer') ||
        tags.contains('congregation') ||
        tags.contains('masjid');
  }

  bool get _isEthicsRelatedHadith {
    return tags.contains('akhlaq') ||
        title.contains('الأخلاق') ||
        title.contains('الخلق');
  }

  bool get _isDuaLike {
    return title.contains('دعاء') || tags.contains('dua');
  }
}

String _libraryKeyFrom(String value) {
  final normalized = value
      .trim()
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'[^\w\u0600-\u06FF_]+'), '')
      .toLowerCase();
  return normalized.isEmpty ? 'category_misc' : 'category_$normalized';
}
