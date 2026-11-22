import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/storage_service.dart';
import '../services/weather_service.dart';
import 'forecast_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.service, required this.storage});

  final WeatherService service;
  final StorageService storage;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();

  List<City> _recents = [];
  List<City>? _results;
  String? _lastQuery;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecents() async {
    final list = await widget.storage.recentCities();
    if (mounted) setState(() => _recents = list);
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
      _lastQuery = query;
    });
    try {
      final results = await widget.service.searchCities(query);
      if (!mounted) return;
      setState(() => _results = results);
    } on WeatherException catch (e) {
      if (!mounted) return;
      setState(() {
        _results = null;
        _error = e.message;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(City city) async {
    await widget.storage.addRecent(city);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForecastScreen(
          city: city,
          service: widget.service,
          storage: widget.storage,
        ),
      ),
    );
    _loadRecents();
  }

  Future<void> _removeRecent(City city) async {
    await widget.storage.removeRecent(city.id);
    _loadRecents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Previsão do Tempo')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                labelText: 'Nome da cidade',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  tooltip: 'Pesquisar',
                  icon: const Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(context)),
          const Padding(
            padding: EdgeInsets.all(8),
            child: Text('Fonte dos dados: CPTEC/INPE',
                style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return _Message(
        icon: Icons.cloud_off,
        text: _error!,
        action: FilledButton(onPressed: _search, child: const Text('Tentar de novo')),
      );
    }

    final results = _results;
    if (results != null) {
      if (results.isEmpty) {
        return _Message(
          icon: Icons.search_off,
          text: 'Nenhuma cidade encontrada para “$_lastQuery”.',
        );
      }
      return ListView.separated(
        itemCount: results.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.location_city),
          title: Text(results[i].name),
          subtitle: Text(results[i].uf),
          onTap: () => _open(results[i]),
        ),
      );
    }

    if (_recents.isEmpty) {
      return const _Message(
        icon: Icons.wb_sunny_outlined,
        text: 'Pesquise uma cidade para ver a previsão dos próximos dias.',
      );
    }

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text('Cidades recentes',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final city in _recents)
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(city.name),
            subtitle: Text(city.uf),
            trailing: IconButton(
              tooltip: 'Remover',
              icon: const Icon(Icons.close),
              onPressed: () => _removeRecent(city),
            ),
            onTap: () => _open(city),
          ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.action});

  final IconData icon;
  final String text;
  final Widget? action;

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
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
