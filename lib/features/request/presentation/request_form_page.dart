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
    DateUtils.dateOnly(DateTime.now().add(const Duration(days: 1))),
  );
  String? _addressId;
  String? _slotStart;
  Future<_BookingCalendar>? _calendarFuture;
  bool _showSlotError = false;
  bool _submitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _calendarFuture ??= _loadCalendar();
  }

  @override
  void dispose() {
    _description.dispose();
    _day.dispose();
    super.dispose();
  }

  Future<_BookingCalendar> _loadCalendar() async {
    final requestedDay = DateUtils.dateOnly(_day.value);
    final app = AppScope.of(context);
    final availableDays = await app.availableBookingDays(
      artisanId: widget.artisan.id,
      startDay: DateUtils.dateOnly(DateTime.now()),
      days: 60,
    );
    final selectedDay = availableDays.contains(_dateKey(requestedDay))
        ? requestedDay
        : _firstAvailableDay(availableDays) ?? requestedDay;
    final slots = availableDays.contains(_dateKey(selectedDay))
        ? await app.availableSlots(
            artisanId: widget.artisan.id,
            day: selectedDay,
          )
        : const <BookingSlot>[];
    return _BookingCalendar(
      selectedDay: selectedDay,
      availableDays: availableDays,
      slots: slots,
    );
  }

  DateTime? _firstAvailableDay(Set<String> days) {
    if (days.isEmpty) return null;
    final sortedDays = days.toList()..sort();
    return DateTime.tryParse(sortedDays.first);
  }

  void _reloadCalendar(DateTime day) => setState(() {
    _day.value = DateUtils.dateOnly(day);
    _slotStart = null;
    _showSlotError = false;
    _calendarFuture = _loadCalendar();
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
                  Text(
                    'Choisissez une date',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text('Seuls les créneaux encore libres sont proposés.'),
                  const SizedBox(height: 12),
                  FutureBuilder<_BookingCalendar>(
                    future: _calendarFuture,
                    builder: (context, calendarSnapshot) {
                      if (calendarSnapshot.hasError) {
                        return _SlotError(
                          onRetry: () => _reloadCalendar(_day.value),
                        );
                      }
                      if (!calendarSnapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(12),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final calendar = calendarSnapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BookingDayPicker(
                            selectedDay: calendar.selectedDay,
                            availableDayKeys: calendar.availableDays,
                            onSelected: _reloadCalendar,
                            onOpenCalendar: () => _chooseDay(calendar),
                          ),
                          const SizedBox(height: 20),
                          if (calendar.slots.isEmpty)
                            const Text('Aucun créneau libre ce jour-là.')
                          else
                            _SlotSelector(
                              day: calendar.selectedDay,
                              slots: calendar.slots,
                              selectedSlotStart: _slotStart,
                              showError: _showSlotError,
                              onSelected: (slot) => setState(() {
                                _slotStart = slot.start.toIso8601String();
                                _showSlotError = false;
                              }),
                            ),
                        ],
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
                            calendarFuture: _calendarFuture!,
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

  Future<void> _chooseDay(_BookingCalendar calendar) async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      initialDate: calendar.selectedDay,
      selectableDayPredicate: (day) =>
          calendar.availableDays.contains(_dateKey(day)),
    );
    if (date == null || !mounted) return;
    _reloadCalendar(date);
  }

  Future<void> _submit({
    required String? addressId,
    required Future<_BookingCalendar> calendarFuture,
  }) async {
    final formValid = _formKey.currentState!.validate();
    if (_slotStart == null) setState(() => _showSlotError = true);
    if (!formValid || addressId == null || _slotStart == null) return;
    final calendar = await calendarFuture;
    if (!mounted) return;
    final slot = calendar.slots
        .where((item) => item.start.toIso8601String() == _slotStart)
        .firstOrNull;
    if (slot == null) {
      _reloadCalendar(calendar.selectedDay);
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

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class BookingDayPicker extends StatelessWidget {
  const BookingDayPicker({
    super.key,
    required this.selectedDay,
    required this.availableDayKeys,
    required this.onSelected,
    required this.onOpenCalendar,
  });

  final DateTime selectedDay;
  final Set<String> availableDayKeys;
  final ValueChanged<DateTime> onSelected;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    final today = DateUtils.dateOnly(DateTime.now());
    final start = selectedDay.isAfter(today.add(const Duration(days: 6)))
        ? selectedDay
        : today;
    final days = List.generate(7, (index) => start.add(Duration(days: index)));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final day in days) ...[
            ChoiceChip(
              key: Key('booking-day-${_dateKey(day)}'),
              label: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_shortWeekday(day.weekday)),
                  Text('${day.day}/${day.month}'),
                ],
              ),
              selected: DateUtils.isSameDay(day, selectedDay),
              onSelected: availableDayKeys.contains(_dateKey(day))
                  ? (_) => onSelected(day)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          IconButton.outlined(
            tooltip: 'Choisir une autre date',
            onPressed: onOpenCalendar,
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ],
      ),
    );
  }

  String _shortWeekday(int weekday) => const [
    'Lun.',
    'Mar.',
    'Mer.',
    'Jeu.',
    'Ven.',
    'Sam.',
    'Dim.',
  ][weekday - 1];

  String _dateKey(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _BookingCalendar {
  const _BookingCalendar({
    required this.selectedDay,
    required this.availableDays,
    required this.slots,
  });

  final DateTime selectedDay;
  final Set<String> availableDays;
  final List<BookingSlot> slots;
}

class _SlotSelector extends StatelessWidget {
  const _SlotSelector({
    required this.day,
    required this.slots,
    required this.selectedSlotStart,
    required this.showError,
    required this.onSelected,
  });

  final DateTime day;
  final List<BookingSlot> slots;
  final String? selectedSlotStart;
  final bool showError;
  final ValueChanged<BookingSlot> onSelected;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Créneaux du ${_formatDay(day)}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 10),
      Wrap(
        key: const Key('request-slot-selector'),
        spacing: 8,
        runSpacing: 8,
        children: slots
            .map(
              (slot) => ChoiceChip(
                label: Text(
                  '${_formatTime(slot.start)}–${_formatTime(slot.end)}',
                ),
                selected: selectedSlotStart == slot.start.toIso8601String(),
                onSelected: (_) => onSelected(slot),
              ),
            )
            .toList(),
      ),
      if (showError)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Choisissez un créneau libre.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
    ],
  );

  String _formatTime(DateTime value) {
    final local = value.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

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
