import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/app_localizations.dart';

/// The one-time "diary, not a device" notice (CLAUDE.md §1) and the always-
/// reachable About dialog. Both show the same [AppLocalizations.disclaimerBody],
/// held in one place so the boundary statement never drifts between them.

/// Shows the first-run notice and completes once the user acknowledges it.
///
/// Modal and not dismissible by tapping away or the back button: the user must
/// press "I understand", so the acknowledgement the caller then records reflects
/// a deliberate action. The caller stores that acknowledgement.
Future<void> showFirstRunNotice(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(l10n.disclaimerTitle),
        content: SingleChildScrollView(child: Text(l10n.disclaimerBody)),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.disclaimerAcknowledge),
          ),
        ],
      ),
    ),
  );
}

/// Opens the standard About dialog: the app version, the diary-not-a-device
/// statement, plus the built-in licences page (which lists the bundled Hanken
/// font's OFL, registered in `main.dart`).
///
/// The version is read from the built app at runtime (never hardcoded, §2), so
/// this awaits before showing; a failed read falls back to no version line
/// rather than an error (the About dialog is informational, §6).
Future<void> showAppAbout(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final appName = l10n.appTitle;
  final disclaimer = l10n.disclaimerBody;

  String? version;
  try {
    version = (await PackageInfo.fromPlatform()).version;
  } on Exception {
    version = null;
  }

  if (!context.mounted) {
    return;
  }
  showAboutDialog(
    context: context,
    applicationName: appName,
    applicationVersion: version,
    children: [Text(disclaimer)],
  );
}
