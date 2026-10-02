/// Tap-target, icon-size, control-height and border-width tokens
/// (spec_design_system.md §4.2).
abstract final class AppSize {
  static const tapTarget = 48.0; // min hit area, everywhere
  static const controlHeight = 48.0; // buttons, text fields (visual); grows with text scale
  static const iconSm = 16.0; // inline-with-text only
  static const icon = 20.0; // default in chips/fields
  static const iconLg = 24.0; // toolbar, nav
  static const avatarSm = 40.0;
  static const avatar = 56.0;
  static const avatarLg = 72.0;
  static const borderWidth = 1.0; // replaces 1.0/1.2/1.5
  static const borderWidthSelected = 1.5; // selected chip/card; (2.0 only for focus ring)
}
