import 'package:flutter/material.dart';

import '../../../domain/sessions/home_reference.dart';
import '../../../domain/sessions/session_average.dart';
import '../../../domain/sessions/weekly_coverage.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/cadence_extra_colors.dart';
import '../pressure_text.dart';

/// A summary of how well the last seven days keep to the 7-2-2 protocol,
/// pinned above the readings list (CLAUDE.md §4).
///
/// Shows occasions logged against occasions expected and days logged against
/// the seven the protocol spans, and — when at least one occasion falls in the
/// window — the period average. It states completeness; it never judges the
/// numbers or shows a threshold (CLAUDE.md §1).
///
/// When the average is reliable enough to read (≥ [minReliableMonitoringDays]
/// logged days), a small info button offers the ESH reference-range comparison.
/// It starts hidden and only expands on the user's tap — the interpretation is
/// never pushed, and the card stays compact (which matters most in the short
/// landscape layout).
///
/// Portrait stacks the pieces over two or three lines. Landscape is wide but
/// short, so the same pieces flow onto a single line — leaving the scarce height
/// for the readings — and fall back to more lines only under very large font
/// scales, so nothing is clipped.
class WeeklyCoverageCard extends StatefulWidget {
  /// Shows [coverage], computed by the caller from the current sessions.
  const WeeklyCoverageCard(this.coverage, {super.key});

  /// The coverage to display.
  final MonitoringCoverage coverage;

  @override
  State<WeeklyCoverageCard> createState() => _WeeklyCoverageCardState();
}

class _WeeklyCoverageCardState extends State<WeeklyCoverageCard> {
  /// Whether the user has tapped the info button to reveal the reference-range
  /// comparison. Ephemeral and starts hidden: the interpretation is opt-in per
  /// view, never remembered or shown by default (CLAUDE.md §1).
  bool _revealed = false;

  MonitoringCoverage get coverage => widget.coverage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    // A reference comparison is offered only against a reliable average (§4):
    // the average must rest on enough days and there must be one to compare.
    final canCompare =
        coverage.hasSufficientDays && coverage.periodAverage != null;
    final showReference = canCompare && _revealed;

    // A soft warm tint (not a status colour) sets the pinned summary apart from
    // the white reading cards below it, so it reads as "the overview" rather
    // than another entry. Sand is neutral on purpose — colouring it teal/green
    // would read as a good/bad verdict on the numbers, which §1 forbids.
    return Card(
      color: theme.extension<CadenceExtraColors>()!.sand,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: landscape
            ? _flowing(theme, l10n, canCompare, showReference)
            : _stacked(theme, l10n, canCompare, showReference),
      ),
    );
  }

  /// The tall portrait layout: title, then the two counts, then the average.
  Widget _stacked(
    ThemeData theme,
    AppLocalizations l10n,
    bool canCompare,
    bool showReference,
  ) {
    final average = coverage.periodAverage;
    // Portrait is left-aligned (the maintainer's call — only landscape centres).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title on the left, the info button (when a comparison is available)
        // at the far right of the same line.
        Row(
          children: [
            _title(theme, l10n),
            if (canCompare) ...[const Spacer(), _infoButton(l10n)],
          ],
        ),
        const SizedBox(height: 4),
        // Two dimensions of coverage side by side — how many occasions, and over
        // how many days — wrapping to separate lines under large font scales.
        Wrap(
          spacing: 8,
          children: [_occasions(theme, l10n), _dot(theme), _days(theme, l10n)],
        ),
        if (average != null) ...[
          const SizedBox(height: 12),
          _average(theme, l10n, average, expand: true),
          if (!coverage.hasSufficientDays) ...[
            const SizedBox(height: 2),
            _partialTag(theme, l10n),
          ],
        ],
        if (showReference) ...[
          const SizedBox(height: 12),
          _referenceBlock(theme, l10n),
        ],
      ],
    );
  }

  /// The short landscape layout: every piece on one line, wrapping only if a
  /// large font scale forces it.
  Widget _flowing(
    ThemeData theme,
    AppLocalizations l10n,
    bool canCompare,
    bool showReference,
  ) {
    final average = coverage.periodAverage;
    // Force the card to full width so revealing the reference block grows only
    // its height, not its width. Without this the Wrap shrink-wraps to the
    // summary line, and the full-width reference block would widen the whole
    // card on reveal (portrait is already full width via the expanding average).
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _title(theme, l10n),
          _occasions(theme, l10n),
          _dot(theme),
          _days(theme, l10n),
          if (average != null) _average(theme, l10n, average, expand: false),
          if (average != null && !coverage.hasSufficientDays)
            _partialTag(theme, l10n),
          if (canCompare) _infoButton(l10n),
          // A full-width child drops the revealed reference block onto its own
          // line below the centred summary, its sentences left-aligned.
          if (showReference)
            SizedBox(
              width: double.infinity,
              child: _referenceBlock(theme, l10n),
            ),
        ],
      ),
    );
  }

  /// The button that reveals/hides the reference-range comparison. A comfortable
  /// tap target for the older audience; its tooltip and semantic label name what
  /// it does. The icon fills in once revealed, so its state is visible.
  Widget _infoButton(AppLocalizations l10n) => IconButton(
    icon: Icon(_revealed ? Icons.info : Icons.info_outline),
    tooltip: l10n.referenceInfoLabel,
    onPressed: () => setState(() => _revealed = !_revealed),
  );

  /// A small, muted, italic note that the average rests on fewer than
  /// [minReliableMonitoringDays] logged days — a completeness caveat, never a
  /// verdict on the numbers (CLAUDE.md §1, §4). Kept tiny so it does not crowd
  /// the short landscape card.
  Widget _partialTag(ThemeData theme, AppLocalizations l10n) => Text(
    l10n.coveragePartialData,
    style: theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontStyle: FontStyle.italic,
    ),
  );

  /// The reference-range comparison: where the period average sits relative to
  /// the ESH 135/85 home reference, plus the reused "not a diagnosis" clause.
  ///
  /// Muted text only — no colour or icon, since a good/bad tint would be the
  /// verdict §1 forbids. Shown only when the average is reliable and the user
  /// has revealed it (CLAUDE.md §4). The comparison names its source (ESH) and
  /// travels with the consult-your-doctor line, reusing
  /// [AppLocalizations.exportDisclaimer] (§8).
  Widget _referenceBlock(ThemeData theme, AppLocalizations l10n) {
    final comparison = compareToHomeReference(coverage.periodAverage!);
    final sentence = comparison == ReferenceComparison.atOrAbove
        ? l10n.referenceAtOrAbove
        : l10n.referenceBelow;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(sentence, style: muted),
        const SizedBox(height: 2),
        Text(l10n.exportDisclaimer, style: muted),
      ],
    );
  }

  Widget _title(ThemeData theme, AppLocalizations l10n) =>
      Text(l10n.coverageLast7Days, style: theme.textTheme.titleMedium);

  Widget _occasions(ThemeData theme, AppLocalizations l10n) => Text(
    l10n.coverageOccasions(
      coverage.occasionsLogged,
      coverage.occasionsExpected,
    ),
    style: theme.textTheme.bodyLarge,
  );

  Widget _days(ThemeData theme, AppLocalizations l10n) => Text(
    l10n.coverageDays(coverage.daysLogged, coverage.daysExpected),
    style: theme.textTheme.bodyLarge,
  );

  Widget _dot(ThemeData theme) => Text(
    '·',
    style: theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    ),
  );

  /// The period average: its label, the pressure, and any pulse.
  ///
  /// [expand] fills the width and pushes the pulse to the far edge (portrait,
  /// where the row owns a full line and the summary is left-aligned); otherwise
  /// the group is only as wide as its content, so it centres as a group inside
  /// the landscape [Wrap].
  Widget _average(
    ThemeData theme,
    AppLocalizations l10n,
    SessionAverage average, {
    required bool expand,
  }) {
    final textTheme = theme.textTheme;
    return Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Text(l10n.sessionAverageTitle, style: textTheme.labelLarge),
        const SizedBox(width: 8),
        PressureText(
          average.systolic,
          average.diastolic,
          style: textTheme.titleMedium,
        ),
        if (average.pulse != null) ...[
          if (expand) const Spacer() else const SizedBox(width: 8),
          Text(l10n.readingPulse(average.pulse!)),
        ],
      ],
    );
  }
}
