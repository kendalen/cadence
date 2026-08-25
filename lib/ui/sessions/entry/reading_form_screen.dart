import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/core/result.dart';
import '../../../domain/sessions/id_generator.dart';
import '../../../domain/sessions/reading.dart';
import '../../../domain/sessions/reading_context.dart';
import '../../../domain/sessions/reading_input.dart';
import '../../../domain/sessions/validation_failure.dart';
import '../../../l10n/app_localizations.dart';
import '../../system_insets.dart';
import '../section_card.dart';
import '../validation_messages.dart';
import 'number_stepper.dart';
import 'reading_context_details.dart';
import 'taken_at_field.dart';

/// A form for one reading — used both to correct an existing reading and to add
/// another reading to an occasion after it was first saved.
///
/// The same steppers, context pickers, time picker and validation as the entry
/// screen, but for a single reading: no banking, no history seed, no "add
/// another". It seeds its fields from [initial] and, on save, pops the
/// validated [Reading]. The popped reading carries a **fresh** id: the caller
/// decides identity — keeping [initial]'s id (via [Reading.withId]) to replace
/// it, or using the fresh one to add a new reading. `null` is popped if the
/// user backs out.
class ReadingFormScreen extends StatefulWidget {
  /// Edits or adds a reading, seeded from [initial], under the app-bar [title].
  const ReadingFormScreen({
    required this.initial,
    required this.title,
    super.key,
  });

  /// The values the form opens on.
  final Reading initial;

  /// The app-bar title (e.g. "Edit reading" or "Add a reading").
  final String title;

  @override
  State<ReadingFormScreen> createState() => _ReadingFormScreenState();
}

class _ReadingFormScreenState extends State<ReadingFormScreen> {
  late final _systolic = TextEditingController(
    text: '${widget.initial.systolic}',
  );
  late final _diastolic = TextEditingController(
    text: '${widget.initial.diastolic}',
  );
  late final _pulse = TextEditingController(
    text: widget.initial.pulse?.toString() ?? '',
  );
  late final _notes = TextEditingController(text: widget.initial.notes ?? '');

  late MeasurementSite? _site = widget.initial.site;
  late Posture? _posture = widget.initial.posture;
  late MedicationTiming? _medicationTiming = widget.initial.medicationTiming;

  /// The chosen moment, in local time for the picker and display; converted to
  /// UTC by [ReadingInput.validate] on save.
  late DateTime _takenAt = widget.initial.takenAt.toLocal();

  List<ValidationFailure> _failures = const [];

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

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        key: const Key('readingFormList'),
        padding: withSystemInsets(context, const EdgeInsets.all(16)),
        children: [
          NumberStepper(
            key: const Key('systolicStepper'),
            controller: _systolic,
            label: l10n.systolicLabel,
            min: ReadingInput.minPressure,
            max: ReadingInput.maxPressure,
            decrementLabel: l10n.stepperDecrease(l10n.fieldSystolic),
            incrementLabel: l10n.stepperIncrease(l10n.fieldSystolic),
            errorText: messageForField(ReadingField.systolic, _failures, l10n),
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
            errorText: messageForField(ReadingField.diastolic, _failures, l10n),
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
            decrementLabel: l10n.stepperDecrease(l10n.fieldPulse),
            incrementLabel: l10n.stepperIncrease(l10n.fieldPulse),
            errorText: messageForField(ReadingField.pulse, _failures, l10n),
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
              takenAt: _takenAt,
              error: messageForField(ReadingField.takenAt, _failures, l10n),
              onChange: _pickTakenAt,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: Text(l10n.saveReading)),
        ],
      ),
    );
  }

  Future<void> _pickTakenAt() async {
    final picked = await pickTakenAt(context, _takenAt);
    if (picked == null || !mounted) {
      return;
    }
    setState(() => _takenAt = picked);
  }

  /// Validates the values and, if they hold, pops the reading with a fresh id.
  ///
  /// The fresh id is deliberate: the caller re-stamps it (for an edit) or keeps
  /// it (for an add). See [ReadingFormScreen].
  void _save() {
    final input = ReadingInput(
      systolic: _systolic.text,
      diastolic: _diastolic.text,
      pulse: _pulse.text,
      notes: _notes.text,
      takenAt: _takenAt,
      site: _site,
      posture: _posture,
      medicationTiming: _medicationTiming,
    );

    final validated = input.validate(
      context.read<IdGenerator>(),
      now: DateTime.now(),
    );
    switch (validated) {
      case Err(:final error):
        setState(() => _failures = error);
      case Ok(:final value):
        Navigator.of(context).pop(value);
    }
  }
}
