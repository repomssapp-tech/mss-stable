import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';

/// Round avatar showing the first letter of the MSS profile name, used when
/// the user has not picked a photo in the app (issue #145: the Google
/// account picture showed Google's own generated letter, e.g. an old "J").
/// Falls back to a person icon when there is no name yet.
class NameInitialAvatar extends StatelessWidget {
  const NameInitialAvatar({super.key, required this.name, required this.size});

  final String name;
  final double size;

  // Tokens that keep white text above 4.5:1.
  static const List<Color> _palette = [
    AppColors.primary,
    AppColors.success,
    AppColors.primaryStrong,
    AppColors.warningText,
    AppColors.dangerStrong,
  ];

  /// First user-visible character of [name] (works for Tamil and Devanagari
  /// too), upper-cased; empty when there is no name.
  static String initialOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initial = initialOf(name);
    final color = initial.isEmpty
        ? AppColors.textMuted
        : _palette[initial.codeUnitAt(0) % _palette.length];
    return Semantics(
      label: name.trim().isEmpty ? null : name.trim(),
      image: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: initial.isEmpty
            ? Icon(
                Icons.person_rounded,
                color: AppColors.textOnPrimary,
                size: size * 0.55,
              )
            : Text(
                initial,
                style: TextStyle(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: size * 0.45,
                  height: 1,
                ),
              ),
      ),
    );
  }
}
