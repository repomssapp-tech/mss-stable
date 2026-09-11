import 'package:flutter/material.dart';

/// Business-role selector data model (Step 3 of the profile-completion
/// wizard's role picker cards).
///
/// Extracted verbatim from `basic_profile_screen.dart` (frontend refactor C4,
/// safe slice) — a plain data class with zero coupling to
/// `_BasicProfileScreenState`, used only inside that file.
class RoleModel {
  final String id;
  final String title;
  final String subtitle;
  final String imagePath;
  final IconData icon;
  final Color color;

  RoleModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.icon,
    required this.color,
  });
}
