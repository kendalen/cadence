import 'package:flutter/widgets.dart';

/// [base] grown at the bottom to clear the system navigation bar.
///
/// A scroll view fills the screen behind Android's navigation bar, so without
/// this its last child — a Save or Delete button — can sit underneath the bar
/// and be hard or impossible to tap. Wrap a scroll view's own padding with this
/// so the final item always comes to rest above the bar.
EdgeInsets withSystemBottomInset(BuildContext context, EdgeInsets base) =>
    base.copyWith(bottom: base.bottom + MediaQuery.paddingOf(context).bottom);
