import 'package:flutter/material.dart';

/// Shadow tokens (spec_design_system.md §4.3), replacing ~40 ad-hoc
/// `Colors.black.withValues(alpha: .01-.05)` shadows.
abstract final class AppShadows {
  static const none = <BoxShadow>[];
  static const card = [
    BoxShadow(color: Color(0x0A0F172A), blurRadius: 12, offset: Offset(0, 4)),
  ];
  static const raised = [
    BoxShadow(color: Color(0x140F172A), blurRadius: 16, offset: Offset(0, 6)),
  ]; // dialogs, popovers
  static const topBar = [
    BoxShadow(color: Color(0x0D0F172A), blurRadius: 16, offset: Offset(0, -4)),
  ]; // bottom action bars
}
