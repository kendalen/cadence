/// The store of the user's app-level preferences, as the rest of the app sees
/// it.
///
/// Separate from the diary itself ([SessionRepository]): this is small UI-facing
/// state (has the first-run notice been seen, later the discard-day-1 and
/// time-format choices), not measurements. Implementations return plain Dart
/// types only; no storage-engine type appears here (CLAUDE.md §3).
///
/// A failed read defaults to the safe answer (e.g. "not yet acknowledged"), and
/// a failed write is not fatal — the worst case is the one-time notice showing
/// once more — so these are plain futures, not `Result`s (CLAUDE.md §6: those
/// are for expected failures a caller must handle).
abstract interface class SettingsRepository {
  /// Whether the user has acknowledged the first-run "diary, not a device"
  /// notice (CLAUDE.md §1). Defaults to `false` when nothing has been stored.
  Future<bool> isDisclaimerAcknowledged();

  /// Records that the user has acknowledged the first-run notice. Idempotent:
  /// acknowledging again leaves the stored value unchanged.
  Future<void> acknowledgeDisclaimer();
}
