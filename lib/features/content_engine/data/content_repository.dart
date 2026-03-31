import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../settings/application/settings_controller.dart';
import '../../settings/data/settings_repository.dart';
import '../domain/content_catalog.dart';
import '../domain/content_item.dart';

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepository(
    settingsRepository: ref.read(settingsRepositoryProvider),
  ),
);

class ContentRepository {
  ContentRepository({
    required SettingsRepository settingsRepository,
  }) : _settingsRepository = settingsRepository;

  final SettingsRepository _settingsRepository;

  Future<ContentCatalog> loadCatalog() async {
    final localItems = <ContentItem>[
      ...await _loadAssetList('assets/json/hadith_general.json'),
      ...await _loadAssetList('assets/json/adhkar.json'),
      ...await _loadAssetList('assets/json/friday_content.json'),
      ...await _loadAssetList('assets/json/mosque_content.json'),
      ...await _loadAssetList('assets/json/sunnah.json'),
      ...await _loadAssetList('assets/json/nawawi.json'),
    ];

    final cachedBundle = _settingsRepository.loadRemoteContentBundle();
    if (cachedBundle == null || cachedBundle.isEmpty) {
      return ContentCatalog(localItems);
    }

    try {
      final remoteItems = _parseBundle(
        jsonDecode(cachedBundle) as Map<String, dynamic>,
      );

      final merged = <String, ContentItem>{
        for (final item in localItems) item.id: item,
        for (final item in remoteItems) item.id: item,
      };
      return ContentCatalog(merged.values.toList());
    } catch (_) {
      return ContentCatalog(localItems);
    }
  }

  Future<String> syncRemoteBundle() async {
    if (AppConfig.remoteContentBundleUrl.isEmpty) {
      return 'لا يوجد مسار مفعّل لمزامنة المحتوى البعيد.';
    }

    try {
      final response = await http.get(Uri.parse(AppConfig.remoteContentBundleUrl));
      if (response.statusCode != 200) {
        return 'تعذرت مزامنة المحتوى البعيد.';
      }

      final body = response.body;
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return 'بيانات المزامنة البعيدة غير صالحة.';
      }

      await _settingsRepository.saveRemoteContentBundle(body);
      return 'تم تحديث حزمة المحتوى البعيد.';
    } catch (_) {
      return 'التطبيق يعمل بالمحتوى المحلي حالياً.';
    }
  }

  Future<List<ContentItem>> _loadAssetList(String path) async {
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((entry) => ContentItem.fromJson(entry as Map<String, dynamic>))
        .toList();
  }

  List<ContentItem> _parseBundle(Map<String, dynamic> bundle) {
    if (bundle['items'] is List<dynamic>) {
      return (bundle['items'] as List<dynamic>)
          .map((entry) => ContentItem.fromJson(entry as Map<String, dynamic>))
          .toList();
    }

    final keys = <String>[
      'hadith_general',
      'adhkar',
      'friday_content',
      'mosque_content',
      'sunnah',
      'nawawi',
      'hadithGeneral',
      'fridayContent',
      'mosqueContent',
    ];

    final items = <ContentItem>[];
    for (final key in keys) {
      final value = bundle[key];
      if (value is List<dynamic>) {
        items.addAll(
          value.map(
            (entry) => ContentItem.fromJson(entry as Map<String, dynamic>),
          ),
        );
      }
    }
    return items;
  }
}
