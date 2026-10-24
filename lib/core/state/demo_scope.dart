import 'package:flutter/widgets.dart';

import 'demo_store.dart';

class DemoScope extends InheritedNotifier<DemoStore> {
  const DemoScope({super.key, required DemoStore store, required super.child})
    : super(notifier: store);

  static DemoStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DemoScope>();
    assert(scope != null, 'DemoScope is missing from the widget tree.');
    return scope!.notifier!;
  }
}
