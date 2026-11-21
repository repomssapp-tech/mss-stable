import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../models/questionnaire.dart';
import '../../../screens/regular_mode/basic_profile/state_picker_field.dart';
import '../../../utils/app_spacing.dart';

class QuestionnaireFieldControl extends StatefulWidget {
  const QuestionnaireFieldControl({
    super.key,
    required this.field,
    required this.language,
    required this.answer,
    required this.onChanged,
  });

  final QuestionnaireField field;
  final String language;
  final Object? answer;
  final ValueChanged<Object?> onChanged;

  @override
  State<QuestionnaireFieldControl> createState() =>
      _QuestionnaireFieldControlState();
}

class _QuestionnaireFieldControlState extends State<QuestionnaireFieldControl> {
  late final TextEditingController _stateController;

  @override
  void initState() {
    super.initState();
    _stateController = TextEditingController(
      text: widget.answer as String? ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant QuestionnaireFieldControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.answer != widget.answer && widget.field.type == 'state') {
      _stateController.text = widget.answer as String? ?? '';
    }
  }

  @override
  void dispose() {
    _stateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.field.type) {
      'single_select' => _singleSelect(),
      'multi_select' => _multiSelect(),
      'boolean' => _boolean(),
      'boolean_with_district' => _booleanWithDistrict(),
      'location' => _location(),
      'number' => _number(),
      'number_pair' => _numberPair(),
      'text_tags' => _textTags(),
      'state' => StatePickerField(
        controller: _stateController,
        errorText: null,
        onChanged: () => widget.onChanged(_stateController.text),
      ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _singleSelect() {
    final selected = widget.answer as String?;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final option in widget.field.options)
          ChoiceChip(
            label: Text(option.labelFor(widget.language)),
            selected: selected == option.value,
            onSelected: (_) => widget.onChanged(option.value),
          ),
      ],
    );
  }

  Widget _multiSelect() {
    final selected = widget.answer is List
        ? (widget.answer as List).whereType<String>().toSet()
        : <String>{};
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final option in widget.field.options)
          FilterChip(
            label: Text(option.labelFor(widget.language)),
            selected: selected.contains(option.value),
            onSelected: (isSelected) {
              final next = {...selected};
              if (isSelected) {
                next.add(option.value);
              } else {
                next.remove(option.value);
              }
              widget.onChanged(next.toList(growable: false));
            },
          ),
      ],
    );
  }

  Widget _boolean() {
    final selected = widget.answer as bool?;
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        for (final option in widget.field.options)
          ChoiceChip(
            label: Text(option.labelFor(widget.language)),
            selected:
                selected == (option.booleanAnswer ?? option.value == 'yes'),
            onSelected: (_) =>
                widget.onChanged(option.booleanAnswer ?? option.value == 'yes'),
          ),
      ],
    );
  }

  Widget _booleanWithDistrict() {
    final answer = _answerMap();
    final resident = answer['resident'] as bool?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            for (final option in widget.field.options)
              ChoiceChip(
                label: Text(option.labelFor(widget.language)),
                selected:
                    resident == (option.booleanAnswer ?? option.value == 'yes'),
                onSelected: (_) => widget.onChanged({
                  ...answer,
                  'resident': option.booleanAnswer ?? option.value == 'yes',
                  'district': answer['district'] ?? '',
                }),
              ),
          ],
        ),
        if (resident == false) ...[
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            key: ValueKey('${widget.field.id}-district'),
            initialValue: answer['district'] as String? ?? '',
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: widget.field.subInputLabelFor(widget.language),
            ),
            onChanged: (district) => widget.onChanged({
              ...answer,
              'resident': false,
              'district': district,
            }),
          ),
        ],
      ],
    );
  }

  Widget _location() {
    final answer = _answerMap();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _areaOptions(answer),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          key: ValueKey('${widget.field.id}-district'),
          initialValue: answer['district'] as String? ?? '',
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(labelText: context.l10n.district),
          onChanged: (district) =>
              widget.onChanged({...answer, 'district': district}),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          key: ValueKey('${widget.field.id}-taluka'),
          initialValue: answer['taluka'] as String? ?? '',
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: context.l10n.questionnaireTaluka,
          ),
          onChanged: (taluka) =>
              widget.onChanged({...answer, 'taluka': taluka}),
        ),
      ],
    );
  }

  Widget _areaOptions(Map<String, Object?> answer) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final option in widget.field.options)
          ChoiceChip(
            label: Text(option.labelFor(widget.language)),
            selected: answer['area'] == option.value,
            onSelected: (_) =>
                widget.onChanged({...answer, 'area': option.value}),
          ),
      ],
    );
  }

  Widget _number() {
    return TextFormField(
      key: ValueKey(widget.field.id),
      initialValue: widget.answer?.toString() ?? '',
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText:
            widget.field.hints[widget.language] ?? widget.field.hints['en'],
      ),
      onChanged: (value) => widget.onChanged(int.tryParse(value)),
    );
  }

  Widget _numberPair() {
    final answer = _answerMap();
    return Column(
      children: [
        for (final part in widget.field.parts) ...[
          if (widget.field.parts.indexOf(part) > 0)
            const SizedBox(height: AppSpacing.sm),
          TextFormField(
            key: ValueKey('${widget.field.id}-${part.key}'),
            initialValue: answer[part.key]?.toString() ?? '',
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: part.labelFor(widget.language),
            ),
            onChanged: (value) =>
                widget.onChanged({...answer, part.key: int.tryParse(value)}),
          ),
        ],
      ],
    );
  }

  Widget _textTags() {
    final tags = widget.answer is List
        ? (widget.answer as List).whereType<String>().join(', ')
        : '';
    return TextFormField(
      key: ValueKey(widget.field.id),
      initialValue: tags,
      textCapitalization: TextCapitalization.sentences,
      decoration: InputDecoration(
        hintText:
            widget.field.hints[widget.language] ?? widget.field.hints['en'],
      ),
      onChanged: (value) => widget.onChanged(
        value.trim().isEmpty
            ? null
            : value
                  .split(',')
                  .map((tag) => tag.trim())
                  .where((tag) => tag.isNotEmpty)
                  .toList(),
      ),
    );
  }

  Map<String, Object?> _answerMap() => widget.answer is Map
      ? Map<String, Object?>.from(widget.answer as Map)
      : <String, Object?>{};
}
