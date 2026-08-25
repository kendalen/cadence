import 'package:flutter/material.dart';

/// A card wrapping one section of a screen with consistent inner padding.
///
/// One place for the "content in a bordered card" look the detail and form
/// screens share, so every section is padded the same way (CLAUDE.md §8 — one
/// way to do a thing). Colour, border and radius come from the theme's
/// `cardTheme`; [margin] defaults to the theme's card margin and is set to
/// `EdgeInsets.zero` where the surrounding list already provides the inset.
class SectionCard extends StatelessWidget {
  /// Wraps [child] in a padded card.
  const SectionCard({required this.child, this.margin, super.key});

  /// The section's content.
  final Widget child;

  /// The card's outer margin, or `null` to use the theme's card margin.
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) => Card(
    margin: margin,
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
}
