import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../domain/sessions/id_generator.dart';
import '../../../domain/sessions/ids.dart';
import '../../../domain/sessions/reading.dart';
import '../../../domain/sessions/session_repository.dart';
import '../../../domain/sessions/validation_failure.dart';
import '../../../l10n/app_localizations.dart';
import '../validation_messages.dart';
import 'session_entry_cubit.dart';
import 'session_entry_state.dart';

/// The form for recording one reading.
class SessionEntryScreen extends StatelessWidget {
  /// Builds the form over the repository provided above this widget.
  const SessionEntryScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => SessionEntryCubit(
      context.read<SessionRepository>(),
      context.read<IdGenerator>(),
    ),
    child: const _SessionEntryForm(),
  );
}

class _SessionEntryForm extends StatefulWidget {
  const _SessionEntryForm();

  @override
  State<_SessionEntryForm> createState() => _SessionEntryFormState();
}

class _SessionEntryFormState extends State<_SessionEntryForm> {
  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  final _pulse = TextEditingController();
  final _notes = TextEditingController();

  /// How many readings were banked at the last state we reacted to, so growth
  /// (a reading was just banked) can be told from any other state change.
  int _bankedCount = 0;

  @override
  void dispose() {
    _systolic.dispose();
    _diastolic.dispose();
    _pulse.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<SessionEntryCubit, SessionEntryState>(
      listener: _onStateChanged,
      builder: (context, state) {
        final failures = state is SessionEntryEditing
            ? state.failures
            : const <ValidationFailure>[];
        final submitting = state is SessionEntrySubmitting;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.addReading)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _numberField(
                controller: _systolic,
                label: l10n.systolicLabel,
                error: messageForField(ReadingField.systolic, failures, l10n),
              ),
              _numberField(
                controller: _diastolic,
                label: l10n.diastolicLabel,
                error: messageForField(ReadingField.diastolic, failures, l10n),
              ),
              _numberField(
                controller: _pulse,
                label: l10n.pulseLabel,
                error: messageForField(ReadingField.pulse, failures, l10n),
              ),
              TextField(
                controller: _notes,
                decoration: InputDecoration(labelText: l10n.notesLabel),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              _TakenAtField(
                takenAt: state.takenAt,
                error: messageForField(ReadingField.takenAt, failures, l10n),
                onChange: () => _pickTakenAt(state.takenAt),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: submitting ? null : _addReading,
                icon: const Icon(Icons.add),
                label: Text(l10n.addAnotherReading),
              ),
              _BankedReadings(
                readings: state.bankedReadings,
                onRemove: (id) =>
                    context.read<SessionEntryCubit>().removeBankedReading(id),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: submitting ? null : _save,
                child: Text(l10n.saveReading),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String? error,
  }) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label, errorText: error),
  );

  void _onStateChanged(BuildContext context, SessionEntryState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state.bankedReadings.length > _bankedCount) {
      _clearInputs();
    }
    _bankedCount = state.bankedReadings.length;

    switch (state) {
      case SessionEntrySaved():
        Navigator.of(context).pop();
      case SessionEntrySaveFailed():
        // The typed values stay in place, so the user can simply try again.
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.errorSaveFailed)));
      case SessionEntryEditing():
      case SessionEntrySubmitting():
        break;
    }
  }

  void _clearInputs() {
    _systolic.clear();
    _diastolic.clear();
    _pulse.clear();
    _notes.clear();
  }

  void _addReading() => context.read<SessionEntryCubit>().addReading(
    systolic: _systolic.text,
    diastolic: _diastolic.text,
    pulse: _pulse.text,
    notes: _notes.text,
  );

  void _save() => unawaited(
    context.read<SessionEntryCubit>().save(
      systolic: _systolic.text,
      diastolic: _diastolic.text,
      pulse: _pulse.text,
      notes: _notes.text,
    ),
  );

  /// Asks for a date, then a time, and reports the result to the cubit.
  ///
  /// The date picker cannot go past today; a time later today is still
  /// selectable, which `ReadingInput.validate` rejects.
  Future<void> _pickTakenAt(DateTime current) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) {
      return;
    }

    context.read<SessionEntryCubit>().takenAtChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }
}

/// The chosen date and time, with a button to change it.
class _TakenAtField extends StatelessWidget {
  const _TakenAtField({
    required this.takenAt,
    required this.error,
    required this.onChange,
  });

  final DateTime takenAt;
  final String? error;
  final VoidCallback onChange;

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

/// The readings already banked for this occasion, each removable.
class _BankedReadings extends StatelessWidget {
  const _BankedReadings({required this.readings, required this.onRemove});

  final List<Reading> readings;
  final void Function(ReadingId id) onRemove;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final time = DateFormat.jm(locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(l10n.readingsSoFar, style: Theme.of(context).textTheme.titleSmall),
        for (final reading in readings)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              l10n.readingPressure(reading.systolic, reading.diastolic),
            ),
            subtitle: Text(time.format(reading.takenAt.toLocal())),
            trailing: IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.removeReading,
              onPressed: () => onRemove(reading.id),
            ),
          ),
      ],
    );
  }
}
