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
import '../validation_messages.dart';
import 'number_stepper.dart';
import 'reading_context_details.dart';

/// Corrects one already-recorded [Reading].
///
/// A focused form over the same steppers, context pickers and validation as the
/// entry screen — but for an existing reading, so there is no banking, no
/// history seed, and no "add another". Saving validates the values and pops the
/// corrected reading back to the caller (`null` if the user backs out); the
/// caller writes it to the store. The reading keeps its identity and its
/// original time — only its values and context are edited here (editing the
/// time is not part of this slice).
class EditReadingScreen extends StatefulWidget {
  /// Edits [reading].
  const EditReadingScreen(this.reading, {super.key});

  /// The reading to correct.
  final Reading reading;

  @override
  State<EditReadingScreen> createState() => _EditReadingScreenState();
}

class _EditReadingScreenState extends State<EditReadingScreen> {
  late final _systolic = TextEditingController(
    text: '${widget.reading.systolic}',
  );
  late final _diastolic = TextEditingController(
    text: '${widget.reading.diastolic}',
  );
  late final _pulse = TextEditingController(
    text: widget.reading.pulse?.toString() ?? '',
  );
  late final _notes = TextEditingController(text: widget.reading.notes ?? '');

  late MeasurementSite? _site = widget.reading.site;
  late Posture? _posture = widget.reading.posture;
  late MedicationTiming? _medicationTiming = widget.reading.medicationTiming;

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
      appBar: AppBar(title: Text(l10n.editReading)),
      body: ListView(
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
          TextField(
            controller: _notes,
            decoration: InputDecoration(labelText: l10n.notesLabel),
            maxLines: 2,
          ),
          ReadingContextDetails(
            site: _site,
            posture: _posture,
            medicationTiming: _medicationTiming,
            onSite: (value) => setState(() => _site = value),
            onPosture: (value) => setState(() => _posture = value),
            onMedication: (value) => setState(() => _medicationTiming = value),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: Text(l10n.saveReading)),
        ],
      ),
    );
  }

  /// Validates the edited values and, if they hold, pops the corrected reading.
  ///
  /// The reading keeps its identity: [ReadingInput.validate] mints a fresh id,
  /// which is immediately re-stamped with the original via [Reading.withId] so
  /// the store updates the same reading rather than adding a new one.
  void _save() {
    final input = ReadingInput(
      systolic: _systolic.text,
      diastolic: _diastolic.text,
      pulse: _pulse.text,
      notes: _notes.text,
      takenAt: widget.reading.takenAt,
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
        Navigator.of(context).pop(value.withId(widget.reading.id));
    }
  }
}
