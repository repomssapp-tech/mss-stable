import 'package:flutter/material.dart';

import '../../../l10n/l10n.dart';
import '../../../models/eligibility_questionnaire.dart';
import '../../../models/places_data.dart';
import '../../../utils/app_colors.dart';
import '../../../utils/app_radius.dart';
import '../../../utils/app_spacing.dart';
import '../../../utils/app_text.dart';

/// One questionnaire question, drawn from its field definition. The caller owns
/// the answer: this reports every change through [onChanged] (null = cleared).
class QuestionView extends StatelessWidget {
  const QuestionView({
    super.key,
    required this.field,
    required this.lang,
    required this.value,
    required this.onChanged,
    this.places = PlacesData.empty,
    this.answers = const {},
    this.mandatory = false,
  });

  final QuestionField field;
  final String lang;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  /// Districts, talukas and cities for `place` questions.
  final PlacesData places;

  /// All answers so far (a place question reads its state and district from here).
  final QuestionnaireAnswers answers;

  /// Every question is needed (Google sign-in): all of them carry the * mark.
  final bool mandatory;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (field.required || mandatory)
                ? '${field.questionText(lang)} *'
                : field.questionText(lang),
            style: text.cardTitle.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          _answer(context),
        ],
      ),
    );
  }

  Widget _answer(BuildContext context) {
    switch (field.type) {
      case QuestionType.single:
        return _options(
          multi: false,
          selected: {if (value is String) value as String},
        );
      case QuestionType.multi:
        return _options(
          multi: true,
          selected: {if (value is List) ...(value as List).cast<String>()},
        );
      case QuestionType.select:
        return DropdownButtonFormField<String>(
          key: ValueKey('${field.id}.${value ?? ''}'),
          initialValue: value is String ? value as String : null,
          isExpanded: true,
          hint: Text(context.l10n.eligCheckSelect),
          items: [
            for (final o in field.options)
              DropdownMenuItem(value: o.value, child: Text(o.label(lang))),
          ],
          onChanged: (v) => onChanged(v),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: AppRadius.mdAll,
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        );
      case QuestionType.pair:
        final m = value is Map ? value as Map : const {};
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (id, label) in field.parts)
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: AppSpacing.md),
                  child: TextAnswer(
                    key: ValueKey('${field.id}.$id'),
                    label: label[lang] ?? label['en'] ?? id,
                    initial: m[id] == null ? '' : '${m[id]}',
                    numeric: true,
                    onChanged: (v) {
                      final n = int.tryParse(v.trim());
                      final out = {...m.cast<String, Object?>()};
                      if (n == null) {
                        out.remove(id);
                      } else {
                        out[id] = n;
                      }
                      onChanged(out);
                    },
                  ),
                ),
              ),
          ],
        );
      case QuestionType.place:
        final state = answers[field.stateField] as String?;
        if (field.place == 'city') {
          return CityAnswer(
            key: ValueKey('${field.id}.$state.${value ?? ''}'),
            cities: places.cities(state),
            initial: value is String ? value as String : '',
            hint: field.placeholder[lang] ?? field.placeholder['en'],
            onChanged: (v) => onChanged(v.trim()),
          );
        }
        final list = field.place == 'district'
            ? places.districts(state)
            : places.talukas(state, answers[field.districtField] as String?);
        if (list.isEmpty) {
          return TextAnswer(
            key: ValueKey('${field.id}.$state'),
            hint: field.placeholder[lang] ?? field.placeholder['en'],
            initial: value is String ? value as String : '',
            onChanged: (v) => onChanged(v.trim()),
          );
        }
        return PlaceAnswer(
          key: ValueKey('${field.id}.$state.${answers[field.districtField]}'),
          list: list,
          initial: value is String ? value as String : '',
          onChanged: onChanged,
        );
      case QuestionType.text:
        return TextAnswer(
          key: ValueKey('${field.id}.${value ?? ''}'),
          hint: field.placeholder[lang] ?? field.placeholder['en'],
          initial: value is String ? value as String : '',
          onChanged: (v) => onChanged(v.trim()),
        );
    }
  }

  Widget _options({
    required bool multi,
    required Set<String> selected,
    ValueChanged<String>? onPick,
  }) {
    return Column(
      children: [
        for (final o in field.options)
          OptionTile(
            label: o.label(lang),
            selected: selected.contains(o.value),
            multi: multi,
            onTap: () {
              if (onPick != null) return onPick(o.value);
              if (!multi) return onChanged(o.value);
              final next = {...selected};
              if (!next.remove(o.value)) {
                if (field.exclusive.contains(o.value)) {
                  next.clear();
                } else {
                  next.removeAll(field.exclusive);
                }
                next.add(o.value);
              }
              onChanged(next.toList());
            },
          ),
      ],
    );
  }
}

/// A tappable radio / checkbox row, at least 48dp tall.
class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.multi,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = multi
        ? (selected ? Icons.check_box : Icons.check_box_outline_blank)
        : (selected ? Icons.radio_button_checked : Icons.radio_button_off);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: selected ? AppColors.primarySoft : AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdAll,
            side: BorderSide(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: InkWell(
            borderRadius: AppRadius.mdAll,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      color: selected ? AppColors.primary : AppColors.iconMuted,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        label,
                        style: context.text.body.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A text / number input that keeps its own controller.
class TextAnswer extends StatefulWidget {
  const TextAnswer({
    super.key,
    required this.initial,
    required this.onChanged,
    this.label,
    this.hint,
    this.numeric = false,
  });

  final String initial;
  final ValueChanged<String> onChanged;
  final String? label;
  final String? hint;
  final bool numeric;

  @override
  State<TextAnswer> createState() => _TextAnswerState();
}

class _TextAnswerState extends State<TextAnswer> {
  late final TextEditingController _c = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      keyboardType: widget.numeric ? TextInputType.number : TextInputType.text,
      onChanged: widget.onChanged,
      style: context.text.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}


/// A district or taluka picked from the government list, or typed under "Other".
class PlaceAnswer extends StatefulWidget {
  const PlaceAnswer({
    super.key,
    required this.list,
    required this.initial,
    required this.onChanged,
  });

  final List<String> list;
  final String initial;
  final ValueChanged<Object?> onChanged;

  @override
  State<PlaceAnswer> createState() => _PlaceAnswerState();
}

class _PlaceAnswerState extends State<PlaceAnswer> {
  static const _other = '__other';
  late String? _picked;
  late String _typed;

  @override
  void initState() {
    super.initState();
    final match = PlacesData.match(widget.list, widget.initial);
    if (match != null) {
      _picked = match;
      _typed = '';
    } else if (widget.initial.isNotEmpty) {
      _picked = _other;
      _typed = widget.initial;
    } else {
      _picked = null;
      _typed = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _picked,
          isExpanded: true,
          hint: Text(context.l10n.eligCheckSelect),
          items: [
            for (final n in widget.list)
              DropdownMenuItem(value: n, child: Text(n)),
            DropdownMenuItem(
              value: _other,
              child: Text(context.l10n.eligCheckOther),
            ),
          ],
          onChanged: (v) {
            setState(() => _picked = v);
            widget.onChanged(v == _other ? _typed : v);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: AppRadius.mdAll,
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
        if (_picked == _other) ...[
          const SizedBox(height: AppSpacing.sm),
          TextAnswer(
            hint: context.l10n.eligCheckTypeHere,
            initial: _typed,
            onChanged: (v) {
              _typed = v.trim();
              widget.onChanged(_typed);
            },
          ),
        ],
      ],
    );
  }
}

/// A city or town: type it, with the state's cities offered as suggestions.
class CityAnswer extends StatelessWidget {
  const CityAnswer({
    super.key,
    required this.cities,
    required this.initial,
    required this.onChanged,
    this.hint,
  });

  final List<String> cities;
  final String initial;
  final String? hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: initial),
      optionsBuilder: (v) {
        final q = v.text.trim().toLowerCase();
        if (q.isEmpty) return const Iterable<String>.empty();
        return cities.where((c) => c.toLowerCase().startsWith(q)).take(8);
      },
      onSelected: onChanged,
      fieldViewBuilder: (context, controller, focus, onSubmit) => TextField(
        controller: controller,
        focusNode: focus,
        onChanged: onChanged,
        style: context.text.body.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: AppRadius.mdAll,
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}
