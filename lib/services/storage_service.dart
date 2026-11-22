import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class StorageService {
  static const _recentKey = 'recent_cities';
  static const _cacheKey = 'forecast_cache';
  static const _maxRecent = 8;

  Future<List<City>> recentCities() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_recentKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .map((c) => City.fromJson(c as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addRecent(City city) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await recentCities();
    list.removeWhere((c) => c.id == city.id);
    list.insert(0, city);
    await prefs.setString(
      _recentKey,
      jsonEncode(list.take(_maxRecent).map((c) => c.toJson()).toList()),
    );
  }

  Future<void> removeRecent(int cityId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await recentCities()..removeWhere((c) => c.id == cityId);
    await prefs.setString(
      _recentKey,
      jsonEncode(list.map((c) => c.toJson()).toList()),
    );
  }

  Future<Forecast?> cachedForecast(int cityId) async {
    final cache = await _readCache();
    final entry = cache['$cityId'];
    if (entry == null) return null;
    try {
      return Forecast.fromJson(entry as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveForecast(Forecast forecast) async {
    final prefs = await SharedPreferences.getInstance();
    final cache = await _readCache();
    cache['${forecast.cityId}'] = forecast.toJson();
    await prefs.setString(_cacheKey, jsonEncode(cache));
  }

  Future<Map<String, dynamic>> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }
}
