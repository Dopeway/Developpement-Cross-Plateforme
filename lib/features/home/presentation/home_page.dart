import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/models/artisan.dart';
import '../../../core/models/artisan_catalog.dart';
import '../../../core/services/availability_calculator.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/widgets/request_status_widgets.dart';

List<Artisan> filterArtisans({
  required List<Artisan> artisans,
  required String query,
  ArtisanTrade? trade,
  InterventionArea? area,
  required bool availableOnly,
  DateTime? now,
}) {
  final normalizedQuery = query.toLowerCase();
  final referenceTime = now ?? DateTime.now();
  return artisans.where((artisan) {
    final matchesQuery =
        normalizedQuery.isEmpty ||
        artisan.name.toLowerCase().contains(normalizedQuery) ||
        artisan.trade.label.toLowerCase().contains(normalizedQuery) ||
        artisan.area.label.toLowerCase().contains(normalizedQuery);
    return matchesQuery &&
        (trade == null || artisan.trade == trade) &&
        (area == null || artisan.area == area) &&
        (!availableOnly ||
            hasAvailableSlotOn(
              artisan: artisan,
              day: referenceTime,
              now: referenceTime,
            ));
  }).toList();
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _query = '';
  ArtisanTrade? _trade;
  InterventionArea? _area;
  bool _availableOnly = false;

  bool get _hasActiveFilters =>
      _query.isNotEmpty || _trade != null || _area != null || _availableOnly;

  void _clearFilters() {
    setState(() {
      _query = '';
      _trade = null;
      _area = null;
      _availableOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Artisan>>(
      stream: AppScope.of(context).artisans,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return ErrorStateView(
            message: 'Impossible de charger les artisans.',
            onRetry: () => setState(() {}),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildContent(context, snapshot.data!);
      },
    );
  }

  Widget _buildContent(BuildContext context, List<Artisan> allArtisans) {
    final artisans = filterArtisans(
      artisans: allArtisans,
      query: _query,
      trade: _trade,
      area: _area,
      availableOnly: _availableOnly,
    );
    final trades = allArtisans.map((artisan) => artisan.trade).toSet().toList();
    final areas = allArtisans.map((artisan) => artisan.area).toSet().toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Un souci à la maison ?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Trouvez un professionnel vérifié près de chez vous.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              SearchBar(
                hintText: 'Quel service recherchez-vous ?',
                leading: const Icon(Icons.search),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 16),
                ),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.surface,
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Affiner la recherche',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Choisissez un métier, une zone ou une disponibilité.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        Text('Métier', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Tous les métiers'),
              selected: _trade == null,
              onSelected: (_) => setState(() => _trade = null),
            ),
            ...trades.map(
              (trade) => FilterChip(
                label: Text(trade.label),
                selected: _trade == trade,
                onSelected: (selected) =>
                    setState(() => _trade = selected ? trade : null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Zone d’intervention',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Toutes les zones'),
              selected: _area == null,
              onSelected: (_) => setState(() => _area = null),
            ),
            ...areas.map(
              (area) => FilterChip(
                label: Text(area.label),
                selected: _area == area,
                onSelected: (selected) =>
                    setState(() => _area = selected ? area : null),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilterChip(
          avatar: const Icon(Icons.schedule_outlined),
          showCheckmark: false,
          label: const Text('Disponible aujourd’hui'),
          selected: _availableOnly,
          onSelected: (selected) => setState(() => _availableOnly = selected),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${artisans.length} artisan${artisans.length > 1 ? 's' : ''} trouvé${artisans.length > 1 ? 's' : ''}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_hasActiveFilters)
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Réinitialiser'),
              ),
          ],
        ),
        if (artisans.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Aucun artisan ne correspond à votre recherche.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _clearFilters,
                    child: const Text('Réinitialiser les filtres'),
                  ),
                ],
              ),
            ),
          ),
        ...artisans.map(
          (artisan) => Card(
            child: ListTile(
              key: ValueKey(artisan.name),
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .secondaryContainer,
                foregroundColor: Theme.of(context)
                    .colorScheme
                    .onSecondaryContainer,
                child: Text(artisan.name.substring(0, 1)),
              ),
              title: Row(
                children: [
                  Expanded(child: Text(artisan.name)),
                  if (artisan.verified)
                    Icon(
                      Icons.verified,
                      color: Theme.of(context).colorScheme.primary,
                      semanticLabel: 'Profil vérifié',
                    ),
                ],
              ),
              subtitle: Text(
                '${artisan.trade.label} · ${artisan.area.label}\n★ ${artisan.rating} (${artisan.reviewCount} avis) · dès ${artisan.startingPrice} DT',
              ),
              isThreeLine: true,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.artisanDetail,
                arguments: artisan,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
