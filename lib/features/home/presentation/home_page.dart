import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/models/artisan.dart';
import '../../../core/state/app_scope.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _query = '';
  String? _trade;
  bool _availableOnly = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Artisan>>(
      stream: AppScope.of(context).artisans,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Impossible de charger les artisans.'),
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
          artisan.trade.toLowerCase().contains(query) ||
          artisan.area.toLowerCase().contains(query);
      return matchesQuery &&
          (_trade == null || artisan.trade == _trade) &&
          (!_availableOnly || artisan.availableToday);
    }).toList();
    final trades = allArtisans.map((artisan) => artisan.trade).toSet().toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Text(
          'Un souci à la maison ?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 6),
        const Text('Trouvez un professionnel vérifié près de chez vous.'),
        const SizedBox(height: 20),
        SearchBar(
          hintText: 'Quel service recherchez-vous ?',
          leading: const Icon(Icons.search),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16),
          ),
          onChanged: (value) => setState(() => _query = value),
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
                label: Text(trade),
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text('Aucun artisan ne correspond à votre recherche.'),
            ),
          ),
        ...artisans.map(
          (artisan) => Card(
            child: ListTile(
              key: ValueKey(artisan.name),
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(child: Text(artisan.name.substring(0, 1))),
              title: Row(
                children: [
                  Expanded(child: Text(artisan.name)),
                  if (artisan.verified)
                    const Icon(
                      Icons.verified,
                      color: Color(0xFF0B6B58),
                      semanticLabel: 'Profil vérifié',
                    ),
                ],
              ),
              subtitle: Text(
                '${artisan.trade} · ${artisan.area}\n★ ${artisan.rating} (${artisan.reviewCount} avis) · dès ${artisan.startingPrice} DT',
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
