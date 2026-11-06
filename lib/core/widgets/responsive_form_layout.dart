import 'package:flutter/material.dart';

/// Keeps focused tasks comfortable to read on wide windows without reducing
/// the usable space on a phone.
class ResponsiveFormLayout extends StatelessWidget {
  const ResponsiveFormLayout({
    super.key,
    required this.child,
    this.maxWidth = 680,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final content = Padding(
          padding: EdgeInsets.all(isWide ? 32 : 20),
          child: child,
        );

        return ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 40 : 0,
            vertical: isWide ? 32 : 16,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: isWide ? Card(child: content) : content,
              ),
            ),
          ],
        );
      },
    ),
  );
}
