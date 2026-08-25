import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';

/// The chosen date and time of a reading, with a button to change it.
///
/// Shared by the entry form and the single-reading form so a reading's time is
/// picked one way everywhere (CLAUDE.md §8). [takenAt] is shown in local time;
/// [error] is the validation message to show beneath it, or `null` when valid.
class TakenAtField extends StatelessWidget {
  /// Shows [takenAt] and calls [onChange] when the change button is tapped.
  const TakenAtField({
    required this.takenAt,
    required this.onChange,
    this.error,
    super.key,
  });

  /// The moment to show, in local time.
  final DateTime takenAt;

  /// Called when the user asks to change the moment.
  final VoidCallback onChange;

  /// Validation message shown beneath the field, or `null` when there is none.
  final String? error;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final formatted = DateFormat.yMMMd(locale).add_jm().format(takenAt);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.takenAtLabel),
      subtitle: Text(
        error == null ? formatted : '$formatted\n${error!}',
        style: error == null
            ? null
            : TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      trailing: TextButton(
        onPressed: onChange,
        child: Text(l10n.changeTakenAt),
      ),
    );
  }
}

/// Asks for a date, then a time, and returns the combined local moment.
///
/// Returns `null` if the user cancels either step. The date picker cannot go
/// past today; a time later today is still selectable, which
/// `ReadingInput.validate` rejects — so the one future-time guard stays in the
/// domain rather than being duplicated in the picker.
Future<DateTime?> pickTakenAt(BuildContext context, DateTime current) async {
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: current,
    firstDate: DateTime(now.year - 5),
    lastDate: now,
  );
  if (date == null || !context.mounted) {
    return null;
  }

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(current),
  );
  if (time == null) {
    return null;
  }

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
