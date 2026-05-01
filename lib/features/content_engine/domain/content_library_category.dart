import 'content_item.dart';

class ContentLibraryCategory {
  const ContentLibraryCategory({
    required this.id,
    required this.name,
    required this.items,
    required this.sortOrder,
    required this.sourceNames,
    this.subtitle,
    this.isAllItems = false,
  });

  final String id;
  final String name;
  final String? subtitle;
  final List<ContentItem> items;
  final int sortOrder;
  final List<String> sourceNames;
  final bool isAllItems;

  int get itemCount => items.length;

  String? get sourceSummary {
    if (sourceNames.isEmpty) {
      return null;
    }
    if (sourceNames.length == 1) {
      return sourceNames.first;
    }
    return '${sourceNames.first} ومصادر أخرى';
  }

  static List<ContentLibraryCategory> build(List<ContentItem> items) {
    final availableItems =
        items.where((item) => item.text.trim().isNotEmpty).toList()
          ..sort((a, b) {
            final orderSort = a.libraryCollectionSortOrder
                .compareTo(b.libraryCollectionSortOrder);
            if (orderSort != 0) {
              return orderSort;
            }

            final titleSort = a.title.compareTo(b.title);
            if (titleSort != 0) {
              return titleSort;
            }

            return a.id.compareTo(b.id);
          });

    final grouped = <String, List<ContentItem>>{};
    for (final item in availableItems) {
      grouped.putIfAbsent(item.categoryId, () => <ContentItem>[]).add(item);
    }

    final categories = grouped.entries.map((entry) {
      final representative = entry.value.first;
      final sourceNames = entry.value
          .map((item) => item.sourceName.trim())
          .where((source) => source.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      return ContentLibraryCategory(
        id: entry.key,
        name: representative.categoryName,
        subtitle: representative.collectionSubtitle,
        items: entry.value,
        sortOrder: representative.libraryCollectionSortOrder,
        sourceNames: sourceNames,
      );
    }).toList()
      ..sort((a, b) {
        final sortOrderCompare = a.sortOrder.compareTo(b.sortOrder);
        if (sortOrderCompare != 0) {
          return sortOrderCompare;
        }
        return a.name.compareTo(b.name);
      });

    return <ContentLibraryCategory>[
      ContentLibraryCategory(
        id: 'all_items',
        name: 'كل المحتوى',
        subtitle: 'عرض جميع الأحاديث والأذكار المتاحة',
        items: availableItems,
        sortOrder: 0,
        sourceNames: availableItems
            .map((item) => item.sourceName.trim())
            .where((source) => source.isNotEmpty)
            .toSet()
            .toList()
          ..sort(),
        isAllItems: true,
      ),
      ...categories,
    ];
  }
}
