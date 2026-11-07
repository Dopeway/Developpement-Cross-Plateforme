import 'package:flutter/material.dart';

/// Keeps desktop content easy to scan while preserving the full width on mobile.
class ResponsivePageLayout extends StatelessWidget {
  const ResponsivePageLayout({
    super.key,
    required this.child,
    this.maxWidth = 920,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}
