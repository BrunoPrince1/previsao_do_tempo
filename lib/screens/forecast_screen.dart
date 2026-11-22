import 'package:flutter/material.dart';

import '../models/conditions.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/weather_service.dart';
import '../utils/format.dart';
import 'temperature_chart.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({
    super.key,
    required this.city,
    required this.service,
    required this.storage,
  });

  final City city;
  final WeatherService service;
  final StorageService storage;

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  Forecast? _forecast;
  bool _loading = true;
  bool _fromCache = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final forecast = await widget.service.fetchForecast(widget.city.id);
      await widget.storage.saveForecast(forecast);
      if (!mounted) return;
      setState(() {
        _forecast = forecast;
        _fromCache = false;
      });
    } on WeatherException catch (e) {
      final cached = _forecast ?? await widget.storage.cachedForecast(widget.city.id);
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _forecast = cached;
        _fromCache = cached != null;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.city.label),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final forecast = _forecast;

    if (forecast == null) {
      if (_loading) return const Center(child: CircularProgressIndicator());
      return _StateMessage(
        icon: Icons.cloud_off,
        text: _error ?? 'Não foi possível obter a previsão.',
        onRetry: _load,
      );
    }

    if (forecast.days.isEmpty) {
      return _StateMessage(
        icon: Icons.event_busy,
        text: 'Não há previsão disponível para esta cidade no momento.',
        onRetry: _load,
      );
    }

    return Column(
      children: [
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null && _fromCache)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: ListTile(
                      leading: const Icon(Icons.wifi_off),
                      title: const Text('Exibindo dados salvos'),
                      subtitle: Text(_error!),
                    ),
                  ),
                Text(
                  forecast.cityName.isEmpty ? widget.city.name : forecast.cityName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if (forecast.updatedAt != null)
                  Text('Atualizado em ${fullDateFmt.format(forecast.updatedAt!)}'),
                const SizedBox(height: 12),
                for (final day in forecast.days) _DayCard(day: day),
                TemperatureChart(days: forecast.days),
                const SizedBox(height: 8),
                const Center(
                  child: Text('Fonte dos dados: CPTEC/INPE',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final DayForecast day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = conditionIconUrl(day.code);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: url == null
                  ? const Icon(Icons.help_outline, size: 40)
                  : Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.cloud, size: 40),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(weekdayDateFmt.format(day.date),
                      style: theme.textTheme.titleMedium),
                  Text(conditionDescription(day.code)),
                  if (day.uv != null)
                    Text(
                      'Índice UV: ${uvFmt.format(day.uv)} (${uvLevel(day.uv!)})',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  day.max == null ? '—' : '${day.max!.round()}°C',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(color: Colors.deepOrange),
                ),
                Text(
                  day.min == null ? '—' : '${day.min!.round()}°C',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.text,
    required this.onRetry,
  });

  final IconData icon;
  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}
