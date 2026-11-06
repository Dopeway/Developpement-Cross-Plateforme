import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/models/artisan.dart';
import '../../../core/models/artisan_catalog.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/widgets/request_status_widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _query = '';
  ArtisanTrade? _trade;
  bool _availableOnly = false;

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
    final artisans = allArtisans.where((artisan) {
      final query = _query.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          artisan.name.toLowerCase().contains(query) ||
          artisan.trade.label.toLowerCase().contains(query) ||
          artisan.area.label.toLowerCase().contains(query);
      return matchesQuery &&
          (_trade == null || artisan.trade == _trade) &&
          (!_availableOnly || artisan.availableToday);
    }).toList();
    final trades = allArtisans.map((artisan) => artisan.trade).toSet().toList();
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
          'Services populaires',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterChip(
              label: const Text('Tous'),
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
            FilterChip(
              avatar: const Icon(Icons.schedule_outlined),
              label: const Text('Disponible aujourd’hui'),
              selected: _availableOnly,
              onSelected: (selected) =>
                  setState(() => _availableOnly = selected),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Disponibles près de vous',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextButton(
              onPressed: () => setState(() {
                _query = '';
                _trade = null;
                _availableOnly = false;
              }),
              child: const Text('Voir tout'),
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
                    onPressed: () => setState(() {
                      _query = '';
                      _trade = null;
                      _availableOnly = false;
                    }),
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
