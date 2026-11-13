import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quickfix_tunisia/features/request/presentation/request_form_page.dart';

void main() {
  testWidgets('grise les jours sans créneau et laisse choisir un jour ouvert', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final closed = today;
    final open = today.add(const Duration(days: 1));
    DateTime? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookingDayPicker(
            selectedDay: open,
            availableDayKeys: {_key(open)},
            onSelected: (value) => selected = value,
            onOpenCalendar: () {},
          ),
        ),
      ),
    );

    final closedChip = tester.widget<ChoiceChip>(
      find.byKey(Key('booking-day-${_key(closed)}')),
    );
    expect(closedChip.onSelected, isNull);

    await tester.tap(find.byKey(Key('booking-day-${_key(open)}')));
    expect(selected, open);
  });
}

String _key(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
