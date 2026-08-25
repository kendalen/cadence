import 'package:flutter/widgets.dart';

/// [base] grown to clear the system bars on the sides and bottom.
///
/// With edge-to-edge display the app draws behind Android's system bars. In
/// portrait that is the navigation bar along the bottom; rotated to landscape
/// the bar — and any display cutout — moves to a side edge. A scroll view that
/// padded only its bottom therefore let its content slide under a side bar: a
/// card's border, or a Save button, disappearing off the edge. Growing the
/// padding by the system inset on each of those edges keeps the content clear
/// while the view still scrolls edge-to-edge. The top is left to the app bar,
/// which already consumes it.
EdgeInsets withSystemInsets(BuildContext context, EdgeInsets base) {
  final system = MediaQuery.paddingOf(context);
  return base.copyWith(
    left: base.left + system.left,
    right: base.right + system.right,
    bottom: base.bottom + system.bottom,
  );
}
