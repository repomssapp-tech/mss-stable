import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/design_v2/saarthi/scheme_mentions.dart';
import 'package:frontend/models/scheme_model.dart';
import 'package:frontend/services/voice/cloud_voice_protocol.dart';

void main() {
  const pmegp = Scheme(
    id: 'A',
    name: 'Prime Minister Employment Generation Programme (PMEGP)',
    shortName: 'PMEGP',
    nativeNames: {
      'name': {
        'ta': 'பிரதமர் வேலைவாய்ப்பு உருவாக்கும் திட்டம்',
        'hi': 'प्रधानमंत्री रोजगार सृजन कार्यक्रम',
      },
    },
  );
  const grant = Scheme(id: 'B', name: 'Test Grant');
  const plus = Scheme(id: 'C', name: 'Test Grant Plus');
  const catalog = [pmegp, grant, plus];
  List<String> ids(String reply, {List<String>? selected}) => schemesForReply(
    reply,
    catalog,
    schemeIds: selected,
  ).map((s) => s.id).toList();

  test(
    'authoritative IDs survive alternate spellings, preserve order and cap at two',
    () {
      expect(
        ids(
          'An alternate translation.',
          selected: ['C', 'unknown', 'A', 'C', 'B'],
        ),
        ['C', 'A'],
      );
      expect(ids('PMEGP can help.', selected: []), isEmpty);
      expect(ids('PMEGP can help.', selected: ['unknown']), isEmpty);
      expect(schemesForReply('PMEGP', catalog, limit: 0), isEmpty);
    },
  );
  test(
    'missing IDs use only named schemes, with longest overlapping name winning',
    () {
      expect(ids('Test Grant Plus and PMEGP can help.'), ['C', 'A']);
      expect(ids('An unrelated reply.'), isEmpty);
      expect(ids('XPMEGPX is unrelated.'), isEmpty);
    },
  );
  test('Tamil, Hindi, spaced and punctuated acronyms match catalog names', () {
    for (final reply in [
      'P.M.E.G.P can help.',
      'P M E G P can help.',
      'पीएमईजीपी आपकी मदद कर सकता है।',
      'पी एम ई जी पी आपकी मदद कर सकता है।',
      'பிஎம்இஜிபி உதவலாம்.',
      'பிரதமர் வேலைவாய்ப்பு உருவாக்கும் திட்டத்தில் உதவி கிடைக்கலாம்.',
      'प्रधानमंत्री रोजगार सृजन कार्यक्रम आपकी मदद कर सकता है।',
    ]) {
      expect(ids(reply), ['A'], reason: reply);
    }
  });
  test(
    'unverified details get no fallback card in each supported language',
    () {
      for (final reply in [
        'No verified details for PMEGP.',
        'PMEGP விவரங்கள் இல்லை.',
        'प्रधानमंत्री रोजगार सृजन कार्यक्रम की जानकारी नहीं है।',
      ]) {
        expect(ids(reply), isEmpty, reason: reply);
      }
      expect(ids('No verified details for PMEGP. Test Grant can help.'), ['B']);
    },
  );
  test(
    'lookup titles may match, but the result list alone never supplies a card',
    () {
      const results = [
        CloudSchemeResult(id: 'B', code: 'B', name: 'சோதனை மானியம்'),
      ];
      expect(
        schemesForReply(
          'சோதனை மானியம் உதவலாம்.',
          catalog,
          results: results,
        ).map((s) => s.id),
        ['B'],
      );
      expect(
        schemesForReply('How can I help?', catalog, results: results),
        isEmpty,
      );
    },
  );
  test('metadata distinguishes absent, empty and malformed IDs', () {
    expect(replySchemeIds({}), isNull);
    expect(replySchemeIds({'scheme_ids': []}), isEmpty);
    expect(replySchemeIds({'scheme_ids': 'A'}), isEmpty);
    expect(
      replySchemeIds({
        'scheme_ids': ['A', 3],
      }),
      isEmpty,
    );
    expect(
      replySchemeIds({
        'scheme_ids': ['A', 'A', 'B'],
      }),
      ['A', 'B'],
    );
  });
}
