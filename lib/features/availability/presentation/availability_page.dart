import 'package:flutter/material.dart';

import '../../../core/models/artisan.dart';
import '../../../core/models/availability.dart';
import '../../../core/state/app_scope.dart';
import '../../../core/widgets/request_status_widgets.dart';

class AvailabilityPage extends StatefulWidget {
  const AvailabilityPage({super.key});

  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  @override
  Widget build(BuildContext context) => StreamBuilder<Artisan?>(
    stream: AppScope.of(context).artisanProfile,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return ErrorStateView(
          message: 'Impossible de charger votre planning.',
          onRetry: () => setState(() {}),
        );
      }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      final artisan = snapshot.data;
      if (artisan == null) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Créez votre profil artisan avant de gérer le planning.',
            ),
          ),
        );
      }
      return AvailabilityEditor(
        key: ValueKey(artisan.id),
        artisan: artisan,
        onSave:
            ({
              required rules,
              required exceptions,
              required defaultDurationMinutes,
            }) => AppScope.of(context).updateArtisanAvailability(
              rules: rules,
              exceptions: exceptions,
              defaultDurationMinutes: defaultDurationMinutes,
            ),
      );
    },
  );
}

class AvailabilityEditor extends StatefulWidget {
  const AvailabilityEditor({
    super.key,
    required this.artisan,
    required this.onSave,
  });

  final Artisan artisan;
  final Future<void> Function({
    required List<AvailabilityRule> rules,
    required List<AvailabilityException> exceptions,
    required int defaultDurationMinutes,
  })
  onSave;

  @override
  State<AvailabilityEditor> createState() => _AvailabilityEditorState();
}

class _AvailabilityEditorState extends State<AvailabilityEditor> {
  late List<AvailabilityRule> _rules;
  late List<AvailabilityException> _exceptions;
  late int _durationMinutes;
  bool _saving = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _rules = widget.artisan.availabilityRules.isEmpty
        ? _legacyDefaultRules()
        : List.of(widget.artisan.availabilityRules);
    _exceptions = List.of(widget.artisan.availabilityExceptions);
    _durationMinutes = widget.artisan.defaultDurationMinutes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
          'Organisez vos disponibilités',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(
          'Les clients ne pourront réserver que dans les horaires publiés ici.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.event_available_outlined,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Modifiez vos horaires habituels, puis ajoutez vos congés ou absences ponctuelles.',
                    style: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text('Horaires habituels', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Ajoutez plusieurs plages si vous faites une pause dans la journée.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              for (
                var weekday = DateTime.monday;
                weekday <= DateTime.sunday;
                weekday++
              ) ...[
                _DayRow(
                  weekday: weekday,
                  rules: _rulesFor(weekday),
                  onEnabledChanged: (enabled) =>
                      _toggleDay(weekday, enabled: enabled),
                  onEdit: () => _editDay(weekday),
                ),
                if (weekday != DateTime.sunday)
                  Divider(height: 1, color: theme.colorScheme.outlineVariant),
              ],
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Durée d’un créneau', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Cette durée découpe automatiquement vos plages pour la réservation.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _durationMinutes,
          decoration: const InputDecoration(
            labelText: 'Durée proposée aux clients',
            prefixIcon: Icon(Icons.timelapse_outlined),
          ),
          items: const [30, 45, 60, 90, 120]
              .map(
                (minutes) => DropdownMenuItem(
                  value: minutes,
                  child: Text(_durationLabel(minutes)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _durationMinutes = value;
              _changed = true;
            });
          },
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: Text(
                'Congés et exceptions',
                style: theme.textTheme.titleLarge,
              ),
            ),
            TextButton.icon(
              onPressed: _addUnavailableDay,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
            ),
          ],
        ),
        Text(
          'Ces journées resteront fermées, même si vos horaires habituels les couvrent.',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (_exceptions.isEmpty)
          const _EmptyExceptions()
        else
          ..._sortedExceptions().map(
            (exception) => ListTile(
              key: ValueKey(exception.date),
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_busy_outlined),
              title: Text(_formatLongDate(exception.parsedDate!)),
              subtitle: const Text('Indisponible toute la journée'),
              trailing: IconButton(
                tooltip: 'Supprimer cette exception',
                onPressed: () => _removeException(exception),
                icon: const Icon(Icons.delete_outline),
              ),
            ),
          ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: !_changed || _saving ? null : _save,
          icon: _saving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(_saving ? 'Enregistrement…' : 'Enregistrer le planning'),
        ),
      ],
    );
  }

  List<AvailabilityRule> _rulesFor(int weekday) =>
      _rules.where((rule) => rule.weekday == weekday).toList()..sort(
        (left, right) => left.startMinutes.compareTo(right.startMinutes),
      );

  void _toggleDay(int weekday, {required bool enabled}) {
    setState(() {
      _rules.removeWhere((rule) => rule.weekday == weekday);
      if (enabled) {
        _rules.add(
          AvailabilityRule(
            weekday: weekday,
            startMinutes: 9 * 60,
            endMinutes: 17 * 60,
          ),
        );
      }
      _changed = true;
    });
  }

  Future<void> _editDay(int weekday) async {
    final result = await showModalBottomSheet<List<AvailabilityRule>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _DayScheduleSheet(weekday: weekday, initialRules: _rulesFor(weekday)),
    );
    if (result == null || !mounted) return;
    setState(() {
      _rules.removeWhere((rule) => rule.weekday == weekday);
      _rules.addAll(result);
      _changed = true;
    });
  }

  Future<void> _addUnavailableDay() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final date = await showDatePicker(
      context: context,
      firstDate: today,
      lastDate: DateTime(today.year + 1, today.month, today.day),
      initialDate: today,
    );
    if (date == null || !mounted) return;
    final key = _dateKey(date);
    if (_exceptions.any((item) => item.date == key)) return;
    setState(() {
      _exceptions.add(AvailabilityException(date: key, unavailable: true));
      _changed = true;
    });
  }

  void _removeException(AvailabilityException exception) {
    setState(() {
      _exceptions.removeWhere((item) => item.date == exception.date);
      _changed = true;
    });
  }

  List<AvailabilityException> _sortedExceptions() =>
      List.of(_exceptions)
        ..sort((left, right) => left.date.compareTo(right.date));

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(
        rules: _rules,
        exceptions: _exceptions,
        defaultDurationMinutes: _durationMinutes,
      );
      if (!mounted) return;
      setState(() => _changed = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Planning enregistré.')));
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le planning n’a pas pu être enregistré.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.weekday,
    required this.rules,
    required this.onEnabledChanged,
    required this.onEdit,
  });

  final int weekday;
  final List<AvailabilityRule> rules;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final enabled = rules.isNotEmpty;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Switch(value: enabled, onChanged: onEnabledChanged),
      title: Text(_weekdayName(weekday)),
      subtitle: Text(
        enabled
            ? rules
                  .map(
                    (rule) =>
                        '${_formatMinutes(rule.startMinutes)}–${_formatMinutes(rule.endMinutes)}',
                  )
                  .join('  ·  ')
            : 'Indisponible',
      ),
      trailing: IconButton(
        tooltip:
            'Modifier les horaires du ${_weekdayName(weekday).toLowerCase()}',
        onPressed: enabled ? onEdit : null,
        icon: const Icon(Icons.edit_outlined),
      ),
    );
  }
}

class _DayScheduleSheet extends StatefulWidget {
  const _DayScheduleSheet({required this.weekday, required this.initialRules});

  final int weekday;
  final List<AvailabilityRule> initialRules;

  @override
  State<_DayScheduleSheet> createState() => _DayScheduleSheetState();
}

class _DayScheduleSheetState extends State<_DayScheduleSheet> {
  late final List<AvailabilityRule> _rules = List.of(widget.initialRules);
  String? _error;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _weekdayName(widget.weekday),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          const Text(
            'Définissez les heures pendant lesquelles vous acceptez des réservations.',
          ),
          const SizedBox(height: 16),
          for (var index = 0; index < _rules.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(index, isStart: true),
                      child: Text(_formatMinutes(_rules[index].startMinutes)),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('à'),
                  ),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _pickTime(index, isStart: false),
                      child: Text(_formatMinutes(_rules[index].endMinutes)),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Supprimer la plage',
                    onPressed: () => setState(() {
                      _rules.removeAt(index);
                      _error = null;
                    }),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addRange,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une plage'),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _apply, child: const Text('Appliquer')),
        ],
      ),
    ),
  );

  Future<void> _pickTime(int index, {required bool isStart}) async {
    final rule = _rules[index];
    final minutes = isStart ? rule.startMinutes : rule.endMinutes;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
    );
    if (selected == null || !mounted) return;
    final value = selected.hour * 60 + selected.minute;
    setState(() {
      _rules[index] = AvailabilityRule(
        weekday: rule.weekday,
        startMinutes: isStart ? value : rule.startMinutes,
        endMinutes: isStart ? rule.endMinutes : value,
      );
      _error = null;
    });
  }

  void _addRange() {
    final sorted = List.of(_rules)
      ..sort((left, right) => left.endMinutes.compareTo(right.endMinutes));
    final start = sorted.isEmpty ? 9 * 60 : sorted.last.endMinutes;
    final end = (start + 60).clamp(0, Duration.minutesPerDay);
    if (start >= end) {
      setState(
        () => _error = 'La journée ne peut pas contenir une autre plage.',
      );
      return;
    }
    setState(() {
      _rules.add(
        AvailabilityRule(
          weekday: widget.weekday,
          startMinutes: start,
          endMinutes: end,
        ),
      );
      _error = null;
    });
  }

  void _apply() {
    if (_rules.any((rule) => !rule.isValid)) {
      setState(
        () => _error = 'L’heure de fin doit être après l’heure de début.',
      );
      return;
    }
    for (final rule in _rules) {
      if (_rules.any(
        (other) => !identical(rule, other) && rule.overlaps(other),
      )) {
        setState(() => _error = 'Deux plages horaires se chevauchent.');
        return;
      }
    }
    _rules.sort(
      (left, right) => left.startMinutes.compareTo(right.startMinutes),
    );
    Navigator.pop(context, _rules);
  }
}

class _EmptyExceptions extends StatelessWidget {
  const _EmptyExceptions();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Padding(
      padding: EdgeInsets.all(16),
      child: Text('Aucune indisponibilité ponctuelle ajoutée.'),
    ),
  );
}

List<AvailabilityRule> _legacyDefaultRules() => [
  for (var weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
    AvailabilityRule(
      weekday: weekday,
      startMinutes: 9 * 60,
      endMinutes: 17 * 60,
    ),
];

String _formatMinutes(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

String _dateKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _formatLongDate(DateTime date) =>
    '${_weekdayName(date.weekday)} ${date.day} ${_monthName(date.month)} ${date.year}';

String _durationLabel(int minutes) => switch (minutes) {
  60 => '1 heure',
  120 => '2 heures',
  _ => '$minutes minutes',
};

String _weekdayName(int weekday) => const [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
][weekday - 1];

String _monthName(int month) => const [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
][month - 1];
