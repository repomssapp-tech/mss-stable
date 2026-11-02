# Saarathi Voice: Matching Scheme Suggestions

Oct 31, 2026

The app now shows a scheme card only when Saarathi's reply names that scheme, but a proper match needs the Sarvam agent and backend to report which schemes the reply used. Until then, a correct reply can appear with no card.

## The problem

Saarathi could speak about one scheme while the screen suggested another. The spoken words come from the model, while the cards come from the search results of its lookup, so the two can differ.

## What the app does now

The change is in `frontend/lib/design_v2/saarthi/scheme_mentions.dart`, in `schemesForReply`. It is uncommitted on `feat/saarthi-redesign`.

1. It looks for schemes named in the reply: acronyms, including split or spelled forms (P.M.E.G.P, पीएमईजीपी, பிஎம்இஜிபி), plus short and full names in the catalog's languages. It ignores punctuation and Hindi and Tamil word endings.
2. A scheme from the lookup results also counts if the reply says its title, or a word of its name that no other scheme has.
3. If two names overlap, the longest wins, then the lookup result, so one mention gives one card. If nothing matches, it shows no card. It shows at most 2 cards.

A wrong card can no longer appear this way, but this is text matching, so these gaps remain:

- **Missing card:** a scheme named in a spelling or translation the catalog doesn't have may not match, so no card appears.
- **Scheme outside the catalog:** if the model names a scheme that isn't in the catalog, no card appears and the app cannot flag it.

## What we need on the Sarvam and backend side

- [ ] **Agent instructions:** speak only about schemes the lookup returned, and always say each scheme's official name or acronym exactly as returned.
- [ ] **Scheme IDs with each reply:** have the agent or backend report the catalog IDs the reply actually used, so that the app can show cards by ID. Check whether the agent can do this.
- [ ] **Scheme titles by language:** make sure lookup results include the title in the language being spoken, starting with Tamil, Hindi and English.

The app can then use those IDs and keep text matching as the fallback.

## Done when

Test on a real Android phone with real speech, because the emulator's mic did not pick up speech.

- [ ] In Tamil, Hindi and English, every scheme Saarathi names gets a card, up to the limit of 2.
- [ ] No card appears for a scheme Saarathi did not name.
- [ ] When Saarathi says it has no verified details, no card appears for that scheme.

So far, one typed chat on the emulator showed only the scheme named in the reply, and automated tests cover the voice rule. Real speech has not been checked since this change.
