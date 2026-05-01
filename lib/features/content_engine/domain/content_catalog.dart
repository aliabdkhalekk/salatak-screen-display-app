import '../../prayer/domain/prayer_models.dart';
import 'content_item.dart';

class ContentCatalog {
  const ContentCatalog(this.items);

  final List<ContentItem> items;

  List<ContentItem> filter({
    required Set<DisplayContext> contexts,
    PrayerName? prayer,
    Set<ContentType>? types,
    Set<String>? tags,
  }) {
    final filtered = items.where((item) {
      final contextMatch = item.displayContexts.any(contexts.contains);
      final typeMatch = types == null || types.contains(item.type);
      final tagMatch = tags == null || item.tags.any(tags.contains);
      return contextMatch &&
          typeMatch &&
          tagMatch &&
          item.appliesToPrayer(prayer);
    }).toList();

    filtered.sort((a, b) {
      final prioritySort = b.priority.compareTo(a.priority);
      if (prioritySort != 0) {
        return prioritySort;
      }

      final orderSort = a.order.compareTo(b.order);
      if (orderSort != 0) {
        return orderSort;
      }

      return a.id.compareTo(b.id);
    });

    return filtered;
  }

  List<ContentItem> get nawawiItems {
    final list =
        items.where((item) => item.type == ContentType.nawawi).toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  List<ContentItem> get libraryItems {
    final list = items.where((item) {
      return item.text.trim().isNotEmpty &&
          !item.tags.contains('prayer_window');
    }).toList();

    list.sort((a, b) {
      final typeSort = a.type.index.compareTo(b.type.index);
      if (typeSort != 0) {
        return typeSort;
      }

      final orderSort = a.order.compareTo(b.order);
      if (orderSort != 0) {
        return orderSort;
      }

      return a.title.compareTo(b.title);
    });

    return list;
  }

  ContentItem? itemById(String id) {
    for (final item in items) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }
}
