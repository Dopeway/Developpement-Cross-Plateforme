import 'package:flutter/material.dart';

import '../../../core/models/artisan_catalog.dart';
import '../../../core/state/app_scope.dart';

class MissingArtisanProfile extends StatefulWidget {
  const MissingArtisanProfile({super.key});

  @override
  State<MissingArtisanProfile> createState() => _MissingArtisanProfileState();
}

class _MissingArtisanProfileState extends State<MissingArtisanProfile> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  ArtisanTrade? _trade;
  InterventionArea? _area;
  bool _isSaving = false;

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = AppScope.of(context).currentUser!;
    return SafeArea(
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(Icons.work_outline, size: 40),
                      const SizedBox(height: 16),
                      Text(
                        'Complétez votre profil professionnel',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Votre compte est créé, mais les informations de votre activité sont manquantes.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        initialValue: user.name,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Nom affiché',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ArtisanTrade>(
                        decoration: const InputDecoration(labelText: 'Métier'),
                        items: ArtisanTrade.values
                            .map(
                              (trade) => DropdownMenuItem(
                                value: trade,
                                child: Text(trade.label),
                              ),
                            )
                            .toList(),
                        onChanged: _isSaving
                            ? null
                            : (trade) => setState(() => _trade = trade),
                        validator: (value) =>
                            value == null ? 'Choisissez votre métier.' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<InterventionArea>(
                        decoration: const InputDecoration(
                          labelText: 'Zone d’intervention',
                        ),
                        items: InterventionArea.values
                            .map(
                              (area) => DropdownMenuItem(
                                value: area,
                                child: Text(area.label),
                              ),
                            )
                            .toList(),
                        onChanged: _isSaving
                            ? null
                            : (area) => setState(() => _area = area),
                        validator: (value) => value == null
                            ? 'Choisissez votre zone d’intervention.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _priceController,
                        enabled: !_isSaving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tarif de départ (DT)',
                        ),
                        validator: (value) {
                          final price = int.tryParse(value ?? '');
                          return price == null || price < 0
                              ? 'Indiquez un tarif valide.'
                              : null;
                        },
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _isSaving ? null : _save,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Créer mon profil'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await AppScope.of(context).createArtisanProfile(
        name: AppScope.of(context).currentUser!.name,
        trade: _trade!,
        area: _area!,
        startingPrice: int.parse(_priceController.text),
        availableToday: true,
      );
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le profil n’a pas pu être créé.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
