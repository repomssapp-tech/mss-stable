import '../../../models/scheme_filter.dart';
import '../../../models/scheme_model.dart';
import '../../../services/recommendation/indian_states.dart';

/// The state a guest's home is built around: the state they entered on this
/// phone, else the one their app language belongs to (Marathi is used for
/// Maharashtra schemes, Tamil for Tamil Nadu). Empty when neither says.
///
/// A guest has no account and so no profile match, so home shows the top
/// schemes for this state instead of "Recommended for you".
String guestStateFor({required String profileState, required String language}) {
  final entered = profileState.trim();
  if (entered.isNotEmpty) {
    final code = IndianStates.code(entered);
    return (code == null ? null : IndianStates.nameForCode(code)) ?? entered;
  }
  return switch (language) {
    'mr' => 'Maharashtra',
    'ta' => 'Tamil Nadu',
    _ => '',
  };
}

/// Up to [limit] schemes for a guest in [state]: the state's own schemes
/// first, newest first, then national schemes to fill the row. Without a
/// state, the newest national schemes.
List<Scheme> pickGuestStateSchemes({
  required List<Scheme> all,
  required String state,
  int limit = 5,
}) {
  int newestFirst(Scheme a, Scheme b) => b.addedOn.compareTo(a.addedOn);
  final national = all.where(schemeAppliesNationally).toList()
    ..sort(newestFirst);
  if (state.isEmpty) return national.take(limit).toList();

  final own =
      all
          .where(
            (s) => !schemeAppliesNationally(s) && schemeAppliesInState(s, state),
          )
          .toList()
        ..sort(newestFirst);
  return [...own, ...national].take(limit).toList();
}
