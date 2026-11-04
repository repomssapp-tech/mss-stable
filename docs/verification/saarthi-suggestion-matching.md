# Saarthi suggestion matching

Typed and voice replies now share `schemesForReply`. When the backend supplies
`scheme_ids`, only those IDs resolve to cards in the local catalog. An explicit
empty list suppresses cards; missing metadata on older servers permits name
matching. Unknown IDs are ignored and every reply is limited to two cards.

The fallback handles official names, lookup titles, Hindi and Tamil names,
spelled acronyms, punctuation and Tamil case endings. Longer overlapping names
win. Unavailable-details statements do not get fallback cards. Voice metadata is
consumed once and cleared before the next turn or session.

The coordinated backend change is [backend PR #5](https://github.com/mssschemes/backend/pull/5).
It supplies localized lookup titles, validates selections against published
owner-scoped evidence, and documents the Sarvam agent instructions and selection
tool. Hosted agent configuration and backend activation remain operational work;
an app update does not perform either step.

Automated coverage is in `scheme_reply_selection_test.dart`,
`http_voice_agent_controller_test.dart`, `saarthi_voice_v2_test.dart`,
`saarthi_type_screen_test.dart` and `native_saarthi_conversation_test.dart`.
The full analyzer and test suite are also run before merging.

Real Android speech is still unverified: no device was connected during this
change. On a phone, speak in Tamil, Hindi and English and check one scheme, two
schemes, a follow-up, a greeting after a lookup and unavailable details. Each
named scheme should have its own card, up to two; no unrelated card should appear.
