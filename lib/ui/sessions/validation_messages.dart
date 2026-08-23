import '../../domain/sessions/validation_failure.dart';
import '../../l10n/app_localizations.dart';

/// Turns a [ValidationFailure] into the sentence shown under its field.
///
/// Wording lives here rather than in the domain so that the domain stays free
/// of presentation, and every string comes from the ARB (CLAUDE.md §9).
String messageFor(ValidationFailure failure, AppLocalizations l10n) =>
    switch (failure) {
      ValueMissing() => l10n.errorValueRequired,
      ValueNotAnInteger() => l10n.errorWholeNumber,
      ValueOutOfRange(:final min, :final max) => l10n.errorOutOfRange(min, max),
      TakenAtInFuture() => l10n.errorFutureTime,
    };

/// Returns the message for the first failure reported against [field], or
/// `null` when [failures] holds none for it.
String? messageForField(
  ReadingField field,
  List<ValidationFailure> failures,
  AppLocalizations l10n,
) {
  for (final failure in failures) {
    if (failure.field == field) {
      return messageFor(failure, l10n);
    }
  }
  return null;
}
