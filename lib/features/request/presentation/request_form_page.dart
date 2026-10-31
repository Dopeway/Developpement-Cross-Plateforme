import 'package:flutter/material.dart';

import '../../../core/models/artisan.dart';
import '../../../core/state/app_scope.dart';

class RequestFormPage extends StatefulWidget {
  const RequestFormPage({super.key, required this.artisan});
  final Artisan artisan;
  @override
  State<RequestFormPage> createState() => _RequestFormPageState();
}

class _RequestFormPageState extends State<RequestFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  String _slot = 'Aujourd’hui · 16:00';
  bool _isSubmitting = false;
  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      await AppScope.of(context).createRequest(
        artisan: widget.artisan,
        description: _descriptionController.text,
        address: _addressController.text,
        slot: _slot,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande créée. Retrouvez-la dans Mes demandes.'),
        ),
      );
      Navigator.pop(context);
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La demande n’a pas pu être envoyée.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nouvelle demande')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Demande pour ${widget.artisan.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(widget.artisan.trade),
          const SizedBox(height: 24),
          TextFormField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Décrivez votre besoin',
              hintText: 'Ex. fuite sous l’évier de la cuisine',
              helperText: 'Ajoutez les détails utiles.',
            ),
            validator: (value) => value == null || value.trim().length < 10
                ? 'Décrivez le problème en au moins 10 caractères.'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            keyboardType: TextInputType.streetAddress,
            decoration: const InputDecoration(
              labelText: 'Adresse d’intervention',
              hintText: 'Ex. 12 rue des Jasmins, El Menzah',
            ),
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Indiquez une adresse.'
                : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _slot,
            decoration: const InputDecoration(labelText: 'Créneau souhaité'),
            items:
                const [
                      'Aujourd’hui · 16:00',
                      'Demain · 09:00',
                      'Demain · 14:30',
                    ]
                    .map(
                      (slot) =>
                          DropdownMenuItem(value: slot, child: Text(slot)),
                    )
                    .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _slot = value);
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Le prix final et la disponibilité sont confirmés par l’artisan.',
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Envoyer la demande'),
          ),
        ],
      ),
    ),
  );
}
