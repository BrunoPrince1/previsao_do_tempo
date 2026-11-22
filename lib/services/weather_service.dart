import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

import '../models/models.dart';

enum WeatherErrorKind { network, unavailable, invalidResponse }

class WeatherException implements Exception {
  final WeatherErrorKind kind;
  final String message;
  const WeatherException(this.kind, this.message);

  @override
  String toString() => message;
}

/// Cliente do webservice XML do CPTEC/INPE.
class WeatherService {
  static const _hosts = [
    'https://servicos.cptec.inpe.br',
    'http://servicos.cptec.inpe.br',
  ];

  final http.Client _client;
  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<City>> searchCities(String query) async {
    final term = Uri.encodeComponent(removeAccents(query.trim().toLowerCase()));
    final body = await _get('/XML/listaCidades?city=$term');
    return parseCities(body);
  }

  Future<Forecast> fetchForecast(int cityId) async {
    final body = await _get('/XML/cidade/$cityId/previsao.xml');
    return parseForecast(body, cityId);
  }

  Future<String> _get(String path) async {
    WeatherException? failure;
    for (final host in _hosts) {
      try {
        final response = await _client
            .get(Uri.parse('$host$path'))
            .timeout(const Duration(seconds: 15));
        if (response.statusCode != 200) {
          failure = WeatherException(
            WeatherErrorKind.unavailable,
            'O serviço do CPTEC/INPE está indisponível no momento '
            '(erro ${response.statusCode}).',
          );
          continue;
        }
        return _decode(response.bodyBytes);
      } on TimeoutException {
        failure = const WeatherException(
          WeatherErrorKind.network,
          'Tempo esgotado ao acessar o serviço. Verifique sua conexão.',
        );
      } catch (_) {
        failure = const WeatherException(
          WeatherErrorKind.network,
          'Falha de conexão. Verifique sua internet e tente novamente.',
        );
      }
    }
    throw failure!;
  }

  String _decode(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }
}

List<City> parseCities(String xml) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xml);
  } on XmlException {
    throw const WeatherException(
      WeatherErrorKind.invalidResponse,
      'O serviço retornou uma resposta inválida.',
    );
  }

  final cities = <City>[];
  for (final node in doc.findAllElements('cidade')) {
    final id = int.tryParse(_text(node, 'id') ?? '');
    final name = _text(node, 'nome');
    if (id == null || name == null || name.toLowerCase() == 'undefined') {
      continue;
    }
    cities.add(City(id: id, name: name, uf: _text(node, 'uf') ?? ''));
  }
  return cities;
}

Forecast parseForecast(String xml, int cityId) {
  final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xml);
  } on XmlException {
    throw const WeatherException(
      WeatherErrorKind.invalidResponse,
      'O serviço retornou uma resposta inválida.',
    );
  }

  final root = doc.rootElement;
  if (root.name.local != 'cidade') {
    throw const WeatherException(
      WeatherErrorKind.invalidResponse,
      'O serviço retornou uma resposta inválida.',
    );
  }

  final days = <DayForecast>[];
  for (final node in root.findElements('previsao')) {
    final date = DateTime.tryParse(_text(node, 'dia') ?? '');
    if (date == null) continue;
    days.add(DayForecast(
      date: date,
      code: _text(node, 'tempo'),
      min: _number(node, 'minima'),
      max: _number(node, 'maxima'),
      uv: _number(node, 'iuv'),
    ));
  }
  days.sort((a, b) => a.date.compareTo(b.date));

  String clean(String? v, String fallback) =>
      (v == null || v.toLowerCase() == 'undefined') ? fallback : v;

  return Forecast(
    cityId: cityId,
    cityName: clean(_text(root, 'nome'), ''),
    uf: clean(_text(root, 'uf'), ''),
    updatedAt: DateTime.tryParse(_text(root, 'atualizacao') ?? ''),
    days: days,
  );
}

String? _text(XmlElement parent, String name) {
  final value = parent.getElement(name)?.innerText.trim();
  return (value == null || value.isEmpty) ? null : value;
}

double? _number(XmlElement parent, String name) =>
    double.tryParse((_text(parent, name) ?? '').replaceAll(',', '.'));

String removeAccents(String input) {
  const from = 'áàâãäéèêëíìîïóòôõöúùûüçñ';
  const to = 'aaaaaeeeeiiiiooooouuuucn';
  final buffer = StringBuffer();
  for (final ch in input.split('')) {
    final i = from.indexOf(ch);
    buffer.write(i >= 0 ? to[i] : ch);
  }
  return buffer.toString();
}
