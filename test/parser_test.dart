import 'package:flutter_test/flutter_test.dart';
import 'package:previsao_tempo/models/conditions.dart';
import 'package:previsao_tempo/services/weather_service.dart';

void main() {
  test('parseCities lê nome, UF e id', () {
    const xml = '''
<cidades>
  <cidade><nome>São Paulo</nome><uf>SP</uf><id>244</id></cidade>
  <cidade><nome>São Paulo do Potengi</nome><uf>RN</uf><id>5300</id></cidade>
</cidades>''';
    final cities = parseCities(xml);
    expect(cities.length, 2);
    expect(cities.first.id, 244);
    expect(cities.first.label, 'São Paulo - SP');
  });

  test('parseCities sem resultados retorna lista vazia', () {
    expect(parseCities('<cidades></cidades>'), isEmpty);
  });

  test('parseForecast lê dias e tolera campos ausentes', () {
    const xml = '''
<cidade>
  <nome>São Paulo</nome><uf>SP</uf><atualizacao>2026-11-22</atualizacao>
  <previsao><dia>2026-11-23</dia><tempo>pn</tempo><maxima>28</maxima><minima>18</minima><iuv>11.0</iuv></previsao>
  <previsao><dia>2026-11-24</dia><maxima>30</maxima></previsao>
</cidade>''';
    final f = parseForecast(xml, 244);
    expect(f.days.length, 2);
    expect(f.days[0].max, 28);
    expect(f.days[0].uv, 11.0);
    expect(f.days[1].code, isNull);
    expect(f.days[1].min, isNull);
    expect(conditionDescription('pn'), 'Parcialmente nublado');
  });

  test('XML inválido gera WeatherException', () {
    expect(
      () => parseForecast('não é xml', 1),
      throwsA(isA<WeatherException>()),
    );
  });

  test('removeAccents', () {
    expect(removeAccents('são josé'), 'sao jose');
  });
}
