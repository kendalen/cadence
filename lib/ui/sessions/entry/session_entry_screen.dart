import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/sessions/id_generator.dart';
import '../../../domain/sessions/reading.dart';
import '../../../domain/sessions/reading_context.dart';
import '../../../domain/sessions/reading_input.dart';
import '../../../domain/sessions/session_repository.dart';
import '../../../domain/sessions/validation_failure.dart';
import '../../../l10n/app_localizations.dart';
import '../../system_insets.dart';
import '../section_card.dart';
import '../validation_messages.dart';
import 'banked_readings.dart';
import 'number_stepper.dart';
import 'reading_context_details.dart';
import 'session_entry_cubit.dart';
import 'session_entry_state.dart';
import 'taken_at_field.dart';

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
  /// The value pulse jumps to when the field is empty and + is first tapped — a
  /// neutral starting point, not a norm.
  static const _pulseStartWhenEmpty = 60;

  final _systolic = TextEditingController();
  final _diastolic = TextEditingController();
  final _pulse = TextEditingController();
  final _notes = TextEditingController();

  /// False until the history-based seed has been read and applied. The form
  /// waits for it rather than opening on a placeholder and swapping the numbers
  /// under the user (CLAUDE.md §4: the audience skews older — nothing the user
  /// is looking at should change on its own).
  bool _seeded = false;

  /// How many readings were banked at the last state we reacted to, so growth
  /// (a reading was just banked) can be told from any other state change.
  int _bankedCount = 0;

  MeasurementSite? _site;
  Posture? _posture;
  MedicationTiming? _medicationTiming;

  @override
  void initState() {
    super.initState();
    _applyInitialSeed();
  }

  /// Waits for the first reading's opening values and fills the fields with
  /// them. Numbers come from the user's own history, pulse and context too when
  /// there is any; all of it stays editable before it is saved.
  Future<void> _applyInitialSeed() async {
    final seed = await context.read<SessionEntryCubit>().initialSeed;
    if (!mounted) {
      return;
    }
    _systolic.text = '${seed.systolic}';
    _diastolic.text = '${seed.diastolic}';
    _pulse.text = seed.pulse?.toString() ?? '';
    setState(() {
      _seeded = true;
      _site = seed.site;
      _posture = seed.posture;
      _medicationTiming = seed.medicationTiming;
    });
  }

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

    if (!_seeded) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.addReading)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
            key: const Key('entryFormList'),
            padding: withSystemBottomInset(context, const EdgeInsets.all(16)),
            children: [
              NumberStepper(
                key: const Key('systolicStepper'),
                controller: _systolic,
                label: l10n.systolicLabel,
                min: ReadingInput.minPressure,
                max: ReadingInput.maxPressure,
                decrementLabel: l10n.stepperDecrease(l10n.fieldSystolic),
                incrementLabel: l10n.stepperIncrease(l10n.fieldSystolic),
                errorText: messageForField(
                  ReadingField.systolic,
                  failures,
                  l10n,
                ),
              ),
              const SizedBox(height: 16),
              NumberStepper(
                key: const Key('diastolicStepper'),
                controller: _diastolic,
                label: l10n.diastolicLabel,
                min: ReadingInput.minPressure,
                max: ReadingInput.maxPressure,
                decrementLabel: l10n.stepperDecrease(l10n.fieldDiastolic),
                incrementLabel: l10n.stepperIncrease(l10n.fieldDiastolic),
                errorText: messageForField(
                  ReadingField.diastolic,
                  failures,
                  l10n,
                ),
              ),
              const SizedBox(height: 16),
              NumberStepper(
                key: const Key('pulseStepper'),
                controller: _pulse,
                label: l10n.pulseLabel,
                min: ReadingInput.minPulse,
                max: ReadingInput.maxPulse,
                clearable: true,
                clearLabel: l10n.clearPulse,
                startWhenEmpty: _pulseStartWhenEmpty,
                decrementLabel: l10n.stepperDecrease(l10n.fieldPulse),
                incrementLabel: l10n.stepperIncrease(l10n.fieldPulse),
                errorText: messageForField(ReadingField.pulse, failures, l10n),
              ),
              const SizedBox(height: 16),
              SectionCard(
                margin: EdgeInsets.zero,
                child: TextField(
                  controller: _notes,
                  decoration: InputDecoration(labelText: l10n.notesLabel),
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                margin: EdgeInsets.zero,
                child: ReadingContextDetails(
                  site: _site,
                  posture: _posture,
                  medicationTiming: _medicationTiming,
                  onSite: (value) => setState(() => _site = value),
                  onPosture: (value) => setState(() => _posture = value),
                  onMedication: (value) =>
                      setState(() => _medicationTiming = value),
                ),
              ),
              const SizedBox(height: 12),
              SectionCard(
                margin: EdgeInsets.zero,
                child: TakenAtField(
                  takenAt: state.takenAt,
                  error: messageForField(ReadingField.takenAt, failures, l10n),
                  onChange: () => _pickTakenAt(state.takenAt),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: submitting ? null : _addReading,
                icon: const Icon(Icons.add),
                label: Text(l10n.addAnotherReading),
              ),
              BankedReadings(
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

  void _onStateChanged(BuildContext context, SessionEntryState state) {
    final l10n = AppLocalizations.of(context)!;
    if (state.bankedReadings.length > _bankedCount) {
      _prefillFromLastBanked(state.bankedReadings.last);
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

  /// Fills the form with the values just banked, so the next reading in the
  /// occasion starts where the last one landed (readings a minute apart cluster
  /// — see the roadmap's ease-of-use principle). Numbers and context carry
  /// over; the note is cleared because a note belongs to the reading it was
  /// written for, not the next one.
  void _prefillFromLastBanked(Reading reading) {
    _systolic.text = '${reading.systolic}';
    _diastolic.text = '${reading.diastolic}';
    _pulse.text = reading.pulse?.toString() ?? '';
    _notes.clear();
    setState(() {
      _site = reading.site;
      _posture = reading.posture;
      _medicationTiming = reading.medicationTiming;
    });
  }

  void _addReading() => context.read<SessionEntryCubit>().addReading(
    systolic: _systolic.text,
    diastolic: _diastolic.text,
    pulse: _pulse.text,
    notes: _notes.text,
    site: _site,
    posture: _posture,
    medicationTiming: _medicationTiming,
  );

  void _save() => unawaited(
    context.read<SessionEntryCubit>().save(
      systolic: _systolic.text,
      diastolic: _diastolic.text,
      pulse: _pulse.text,
      notes: _notes.text,
      site: _site,
      posture: _posture,
      medicationTiming: _medicationTiming,
    ),
  );

  /// Asks for a moment via the shared picker and reports it to the cubit.
  Future<void> _pickTakenAt(DateTime current) async {
    final picked = await pickTakenAt(context, current);
    if (picked == null || !mounted) {
      return;
    }
    context.read<SessionEntryCubit>().takenAtChanged(picked);
  }
}
