/// The DPIIT startup-recognition criteria (GSR 127(E), 2019). Recognition
/// needs all of them; the checklist is only a self-check, DPIIT decides.
enum DpiitCriterion {
  /// Private limited company, registered partnership firm or LLP in India.
  entityType,

  /// Not more than 10 years since incorporation or registration.
  age,

  /// Turnover has not exceeded 100 crore rupees in any financial year.
  turnover,

  /// Not formed by splitting up or reconstructing an existing business.
  notReconstruction,

  /// Working towards innovation or a scalable, job-creating model.
  innovation,
}

/// The criteria missing from [met], in checklist order. Empty means the
/// business meets every criterion.
List<DpiitCriterion> unmetDpiitCriteria(Set<DpiitCriterion> met) => [
  for (final c in DpiitCriterion.values)
    if (!met.contains(c)) c,
];
