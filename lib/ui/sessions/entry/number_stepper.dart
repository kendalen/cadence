import 'package:flutter/material.dart';

/// A large, legible number with a − and a + button on either side, used for the
/// systolic, diastolic and pulse values on the entry form.
///
/// The [controller] is the single source of truth. − and + step its value by
/// one within [min]..[max]; typing straight into the field is deliberately left
/// unclamped so `ReadingInput.validate` — not this widget — stays the one place
/// that judges an out-of-range typo (CLAUDE.md §4). Built big, with tap targets
/// well over the 48dp minimum, for the older audience the app targets (see the
/// roadmap's ease-of-use principle).
class NumberStepper extends StatefulWidget {
  /// Creates a stepper bound to [controller].
  ///
  /// [decrementLabel] and [incrementLabel] are the accessible labels of the −
  /// and + buttons. When [clearable] is true a clear button empties the field
  /// back to "not recorded" — used for the optional pulse (CLAUDE.md §4) — and
  /// [clearLabel] is its accessible label. [startWhenEmpty], if given, is the
  /// value + jumps to when the field is empty; otherwise + starts from [min].
  const NumberStepper({
    required this.controller,
    required this.label,
    required this.min,
    required this.max,
    required this.decrementLabel,
    required this.incrementLabel,
    this.errorText,
    this.clearable = false,
    this.clearLabel,
    this.startWhenEmpty,
    super.key,
  }) : assert(
         !clearable || clearLabel != null,
         'a clearable stepper needs a clearLabel',
       );

  /// Holds the value shown, as text; the single source of truth.
  final TextEditingController controller;

  /// The field label shown above the number (e.g. "Systolic (mmHg)").
  final String label;

  /// Lowest value − and + will step to.
  final int min;

  /// Highest value − and + will step to.
  final int max;

  /// Accessible label of the − button.
  final String decrementLabel;

  /// Accessible label of the + button.
  final String incrementLabel;

  /// The field error to show below the number, or `null` when valid.
  final String? errorText;

  /// Whether the field can be emptied back to "not recorded".
  final bool clearable;

  /// Accessible label of the clear button; required when [clearable].
  final String? clearLabel;

  /// The value + jumps to from empty; when `null`, + starts from [min].
  final int? startWhenEmpty;

  @override
  State<NumberStepper> createState() => _NumberStepperState();
}

class _NumberStepperState extends State<NumberStepper> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(NumberStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onControllerChanged);
      widget.controller.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  /// Rebuilds so the buttons' enabled state and the clear button's visibility
  /// track the value as it is stepped, typed or cleared.
  void _onControllerChanged() => setState(() {});

  int? get _value => int.tryParse(widget.controller.text.trim());

  void _step(int delta) {
    final current = _value;
    // An empty field means + starts it off (− is disabled and never gets here).
    final next = current == null
        ? (widget.startWhenEmpty ?? widget.min)
        : current + delta;
    _setValue(next.clamp(widget.min, widget.max));
  }

  void _setValue(int value) {
    final text = value.toString();
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final value = _value;
    final hasValue = widget.controller.text.trim().isNotEmpty;
    final canDecrement = value != null && value > widget.min;
    final canIncrement = value == null || value < widget.max;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: theme.textTheme.titleMedium),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: canDecrement ? () => _step(-1) : null,
              iconSize: 32,
              tooltip: widget.decrementLabel,
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: TextField(
                controller: widget.controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: theme.textTheme.displaySmall,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  errorText: widget.errorText,
                  hintText: widget.clearable ? '—' : null,
                  suffixIcon: widget.clearable && hasValue
                      ? IconButton(
                          onPressed: widget.controller.clear,
                          tooltip: widget.clearLabel,
                          icon: const Icon(Icons.close),
                        )
                      : null,
                ),
              ),
            ),
            IconButton.filledTonal(
              onPressed: canIncrement ? () => _step(1) : null,
              iconSize: 32,
              tooltip: widget.incrementLabel,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}
