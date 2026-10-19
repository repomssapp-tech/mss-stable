import 'package:flutter/widgets.dart';

/// Spell-check configuration for a text field, or null where the platform has
/// no spell checker.
///
/// Flutter's own signal is used rather than a list of platforms: it is true
/// only when the engine provides a native checker (the system spell checker on
/// Android and iOS). Enabling spell check anywhere else makes Flutter assert in
/// debug builds and tests, so it must be left off there.
SpellCheckConfiguration? platformSpellCheck() =>
    WidgetsBinding.instance.platformDispatcher.nativeSpellCheckServiceDefined
    ? const SpellCheckConfiguration()
    : null;
