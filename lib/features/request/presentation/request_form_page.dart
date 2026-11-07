import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../core/models/artisan.dart';
import '../../../core/models/booking_slot.dart';
import '../../../core/models/saved_address.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/widgets/responsive_form_layout.dart';

class RequestFormPage extends StatefulWidget {
  const RequestFormPage({super.key, required this.artisan});

  final Artisan artisan;

  @override
  State<RequestFormPage> createState() => _RequestFormPageState();
}

class _RequestFormPageState extends State<RequestFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _day = ValueNotifier<DateTime>(
    DateTime.now().add(const Duration(days: 1)),
  );
  String? _addressId;
  String? _slotStart;
  Future<List<BookingSlot>>? _slotsFuture;

  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _slotsFuture ??= _loadSlots();
  }

  @override
  void dispose() {
    _description.dispose();
    _day.dispose();
    super.dispose();
  }

  Future<List<BookingSlot>> _loadSlots() =>
      AppScope.of(context)
          .availableSlots(artisanId: widget.artisan.id, day: _day.value);

  void _reloadSlots() => setState(() {
    _slotStart = null;
    _slotsFuture = _loadSlots();
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Réserver une intervention')),
    body: StreamBuilder<List<SavedAddress>>(
      stream: AppScope.of(context).savedAddresses,
      builder: (context, snapshot) {
        final addresses = snapshot.data ?? const <SavedAddress>[];
        final selectedAddressId = pickSavedAddressId(addresses, _addressId);
        return Form(
          key: _formKey,
          child: ResponsiveFormLayout(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Réserver avec ${widget.artisan.name}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.artisan.trade.label} · dès ${widget.artisan.startingPrice} DT',
                ),
                const SizedBox(height: 24),
                if (addresses.isEmpty)
                  const _NoAddressState()
                else ...[
                  DropdownButtonFormField<String>(
                    key: const Key('request-address-selector'),
                    initialValue: selectedAddressId,
                    decoration: const InputDecoration(
                      labelText: 'Adresse d’intervention',
                    ),
                    items: addresses
                        .map(
                          (address) => DropdownMenuItem(
                            value: address.id,
                            child: Text(
                              '${address.label} · ${address.fullAddress}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _addressId = value),
                    validator: (value) =>
                        value == null ? 'Choisissez une adresse.' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.schedule_outlined),
                    title: Text('Choisir le ${_formatDay(_day.value)}'),
                    subtitle: const Text(
                      'Seuls les créneaux encore libres sont proposés.',
                    ),
                    trailing: const Icon(Icons.edit_calendar_outlined),
                    onTap: _chooseDay,
                  ),
                  FutureBuilder<List<BookingSlot>>(
                    future: _slotsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return _SlotError(onRetry: _reloadSlots);
                      }
                      if (!snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final slots = snapshot.data!;
                      if (slots.isEmpty) {
                        return const Text('Aucun créneau libre ce jour-là.');
                      }
                      final availableStartTimes = slots
                          .map((slot) => slot.start.toIso8601String())
                          .toSet();
                      final selectedStart =
                          availableStartTimes.contains(_slotStart)
                          ? _slotStart
                          : null;
                      return DropdownButtonFormField<String>(
                        key: const Key('request-slot-selector'),
                        initialValue: selectedStart,
                        decoration: const InputDecoration(
                          labelText: 'Créneau disponible',
                        ),
                        items: slots
                            .map(
                              (slot) => DropdownMenuItem(
                                value: slot.start.toIso8601String(),
                                child: Text(_formatSlot(slot.start)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => _slotStart = value),
                        validator: (value) => value == null
                            ? 'Choisissez un créneau libre.'
                            : null,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _description,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'Décrivez votre besoin',
                      hintText: 'Ex. fuite sous l’évier de la cuisine',
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 10
                        ? 'Décrivez le problème en au moins 10 caractères.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Le prix final sera proposé par devis avant le début de l’intervention.',
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _submitting
                        ? null
                        : () => _submit(
                            addressId: selectedAddressId,
                            slotsFuture: _slotsFuture!,
                          ),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Bloquer ce créneau'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );

  Future<void> _chooseDay() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      initialDate: _day.value,
    );
    if (date == null || !mounted) {
      return;
    }
    _day.value = date;
    _reloadSlots();
  }

  Future<void> _submit({
    required String? addressId,
    required Future<List<BookingSlot>> slotsFuture,
  }) async {
    if (!_formKey.currentState!.validate() ||
        addressId == null ||
        _slotStart == null) {
      return;
    }
    final slots = await slotsFuture;
    if (!mounted) {
      return;
    }
    final slot = slots
        .where((item) => item.start.toIso8601String() == _slotStart)
        .firstOrNull;
    if (slot == null) {
      _reloadSlots();
      return;
    }
    setState(() => _submitting = true);
    try {
      await AppScope.of(context).createRequest(
        artisan: widget.artisan,
        description: _description.text,
        addressId: addressId,
        start: slot.start,
        end: slot.end,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Créneau bloqué pendant une heure.')),
      );
      Navigator.pop(context);
    } on FirebaseFunctionsException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Ce créneau n’est plus disponible.'),
          ),
        );
      }
      _reloadSlots();
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La réservation n’a pas pu être envoyée.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatSlot(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  String _formatDay(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class _NoAddressState extends StatelessWidget {
  const _NoAddressState();
  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Ajoutez une adresse dans votre compte avant de réserver.'),
      SizedBox(height: 12),
    ],
  );
}

class _SlotError extends StatelessWidget {
  const _SlotError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Text('Impossible de charger les créneaux.')),
      TextButton(onPressed: onRetry, child: const Text('Réessayer')),
    ],
  );
}
