import 'package:flutter/material.dart';

import '../../../app/app_routes.dart';
import '../../../core/models/artisan.dart';

class ArtisanDetailPage extends StatelessWidget {
  const ArtisanDetailPage({super.key, required this.artisan});
  final Artisan artisan;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Profil artisan')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        CircleAvatar(
          radius: 38,
          child: Text(
            artisan.name.substring(0, 1),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 16),
        Text(artisan.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text('${artisan.trade} · ${artisan.area}'),
        const SizedBox(height: 12),
        if (artisan.verified)
          const Chip(
            avatar: Icon(Icons.verified, color: Color(0xFF0B6B58)),
            label: Text('Identité vérifiée'),
          ),
        const Divider(height: 36),
        Text('À propos', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          '${artisan.name} intervient pour les dépannages et installations. Prix indicatif à partir de ${artisan.startingPrice} DT, à confirmer avant l’intervention.',
        ),
        const SizedBox(height: 20),
        ListTile(
          leading: const Icon(Icons.star_outline),
          title: Text('${artisan.rating} / 5'),
          subtitle: Text('${artisan.reviewCount} avis contrôlés'),
        ),
        ListTile(
          leading: const Icon(Icons.schedule_outlined),
          title: Text(
            artisan.availableToday
                ? 'Disponible aujourd’hui'
                : 'Prochain créneau demain',
          ),
          subtitle: const Text('Créneau à confirmer avec l’artisan'),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(
            context,
            AppRoutes.requestForm,
            arguments: artisan,
          ),
          icon: const Icon(Icons.add_task),
          label: const Text('Créer une demande'),
        ),
      ],
    ),
  );
}
