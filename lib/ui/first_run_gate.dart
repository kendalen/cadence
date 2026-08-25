import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/settings/settings_repository.dart';
import 'about/app_about.dart';
import 'sessions/list/session_list_screen.dart';

/// The app's home: the readings list, with the first-run notice shown over it
/// once (CLAUDE.md §1).
///
/// A thin wrapper so the notice is a launch concern, not something the list
/// screen has to know about. After the first frame it checks whether the notice
/// has been acknowledged; if not, it shows it and records the acknowledgement.
/// A failed record is not fatal — the notice simply shows again next launch
/// (see [SettingsRepository]).
class FirstRunGate extends StatefulWidget {
  /// Creates the gate.
  const FirstRunGate({super.key});

  @override
  State<FirstRunGate> createState() => _FirstRunGateState();
}

class _FirstRunGateState extends State<FirstRunGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowNotice());
  }

  Future<void> _maybeShowNotice() async {
    final settings = context.read<SettingsRepository>();
    if (await settings.isDisclaimerAcknowledged()) {
      return;
    }
    if (!mounted) {
      return;
    }
    await showFirstRunNotice(context);
    await settings.acknowledgeDisclaimer();
  }

  @override
  Widget build(BuildContext context) => const SessionListScreen();
}
