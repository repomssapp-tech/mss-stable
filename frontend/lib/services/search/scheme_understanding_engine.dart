import 'dart:async';

import '../../models/scheme_model.dart';
import 'intelligent_scheme_search.dart';
import 'private_ai_knowledge_base.dart';
import 'scheme_eligibility_evaluator.dart';
import 'scheme_fact_extractor.dart';
import 'scheme_understanding_models.dart';
import 'scheme_understanding_rules.dart';

export 'scheme_eligibility_evaluator.dart';
export 'scheme_fact_extractor.dart';
export 'scheme_understanding_models.dart';
export 'scheme_understanding_rules.dart';

/// Offline English/Tamil statement understanding and scheme ranking.
///
/// The engine deliberately uses only bundled catalog data. It never performs a
/// network request or persists the user's statement.
class LocalSchemeUnderstandingEngine implements SchemeUnderstandingEngine {
  const LocalSchemeUnderstandingEngine();

  static const int maxFollowUpQuestions = 5;
  static final Expando<bool> _trustedSchemeCache = Expando<bool>(
    'trustedScheme',
  );
  static final Expando<String> _conceptTextCache = Expando<String>(
    'schemeConceptText',
  );

  static const Map<String, List<String>> _needAliases = schemeNeedAliases;
  static const Map<EligibilityFactKey, FollowUpQuestion> _questions =
      schemeFollowUpQuestions;

  @override
  Future<SchemeUnderstandingResult> understand(
    SchemeUnderstandingRequest request,
  ) async {
    final stopwatch = Stopwatch()..start();
    final knowledgeMatch = PrivateAiKnowledgeBase.lookup(request.statement);
    final intent = IntelligentSchemeSearch.interpret(request.statement);
    final concepts = <String>{...intent.concepts};
    final normalizedStatement = SchemeFactExtractor.normalize(request.statement);
    for (final entry in _needAliases.entries) {
      if (entry.value.any(
        (alias) => SchemeFactExtractor.contains(normalizedStatement, alias),
      )) {
        concepts.add(entry.key);
      }
    }

    final facts = <EligibilityFactKey, EligibilityFact>{...request.knownFacts};
    SchemeFactExtractor.mergeExtractedFacts(
      facts,
      SchemeFactExtractor.extractFacts(
        request.statement,
        EligibilityFactSource.statement,
      ),
    );
    final answer = request.latestAnswer?.trim();
    if (answer != null && answer.isNotEmpty) {
      SchemeFactExtractor.mergeExtractedFacts(
        facts,
        SchemeFactExtractor.extractFacts(
          answer,
          EligibilityFactSource.followUp,
          requestedFact: request.requestedFact,
        ),
      );
    }

    final trusted = request.schemes.where(_isTrusted).toList(growable: false);
    final uncertain = request.schemes
        .where((scheme) => scheme.isActive && !_isTrusted(scheme))
        .toList(growable: false);
    final searchable = request.includeUncertain
        ? [...trusted, ...uncertain]
        : trusted;
    final expandedQuery = [
      request.statement,
      ...concepts.expand((concept) => _needAliases[concept] ?? [concept]),
    ].join(' ');
    final requiredConcepts = _requiredConcepts(concepts);
    final matchesByCode = <String, SchemeSearchMatch>{};

    // Curated answers own their recommendation set. Mixing a factual answer
    // with broad semantic hits caused generic MSME schemes to appear beside
    // unrelated answers such as tax definitions and investor guidance.
    if (knowledgeMatch == null) {
      for (final match
          in IntelligentSchemeSearch.rank(
            expandedQuery,
            searchable,
            limit: 40,
          ).where(
            (match) => _matchesRequiredConcepts(match.scheme, requiredConcepts),
          )) {
        matchesByCode[match.scheme.schemeCode.toUpperCase()] = match;
      }
    }
    if (knowledgeMatch != null) {
      final schemesByCode = <String, Scheme>{};
      for (final scheme in searchable) {
        schemesByCode[scheme.schemeCode.toUpperCase()] = scheme;
        schemesByCode[scheme.id.toUpperCase()] = scheme;
        if (scheme.schemeCode.toUpperCase().startsWith('TN')) {
          schemesByCode[scheme.schemeCode.toUpperCase().replaceFirst(
                'TN',
                'IN',
              )] =
              scheme;
        }
        for (final token in scheme.searchKeywords.split(RegExp(r'\s+'))) {
          final t = token.toUpperCase().trim();
          if (t.startsWith('IN') || t.startsWith('TN') || t.startsWith('SCH')) {
            schemesByCode[t] = scheme;
          }
        }
      }
      for (
        var index = 0;
        index < knowledgeMatch.relatedSchemeCodes.length;
        index++
      ) {
        final code = knowledgeMatch.relatedSchemeCodes[index].toUpperCase();
        final scheme = schemesByCode[code];
        if (scheme == null) continue;
        final preferredScore = 0.98 - index * 0.025;
        final existing = matchesByCode[code];
        if (existing == null || existing.score < preferredScore) {
          matchesByCode[code] = SchemeSearchMatch(
            scheme: scheme,
            score: preferredScore,
            reasons: const ['Directly relevant to your question'],
          );
        }
      }
    }
    if (knowledgeMatch != null &&
        knowledgeMatch.relatedSchemeCodes.isNotEmpty &&
        matchesByCode.isEmpty) {
      for (final match
          in IntelligentSchemeSearch.rank(
            expandedQuery,
            searchable,
            limit: 40,
          ).where(
            (match) => _matchesRequiredConcepts(match.scheme, requiredConcepts),
          )) {
        matchesByCode[match.scheme.schemeCode.toUpperCase()] = match;
      }
    }

    final ranked =
        matchesByCode.values
            .map(
              (match) => SchemeEligibilityEvaluator.evaluate(
                match,
                facts,
                isTrusted: _isTrusted(match.scheme),
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => b.score.compareTo(a.score));
    final usable = ranked
        .where(
          (recommendation) =>
              recommendation.state != SchemeMatchState.notSuitable &&
              recommendation.score >= 0.32,
        )
        .take(12)
        .toList(growable: false);

    FollowUpQuestion? followUp;
    if (usable.isNotEmpty &&
        request.questionsAsked < maxFollowUpQuestions &&
        usable.take(3).where(_isStableRecommendation).length < 3) {
      followUp = SchemeEligibilityEvaluator.chooseQuestion(
        usable,
        facts,
        _questions,
      );
    }

    final reply =
        knowledgeMatch?.reply() ??
        _recommendationReply(
          statement: request.statement,
          isTamil: intent.isTamil,
          recommendations: usable,
          followUp: followUp,
        );

    stopwatch.stop();
    return SchemeUnderstandingResult(
      isTamil: intent.isTamil,
      concepts: Set.unmodifiable(concepts),
      facts: Map.unmodifiable(facts),
      recommendations: List.unmodifiable(usable),
      excludedUncertainCount: request.includeUncertain ? 0 : uncertain.length,
      elapsed: stopwatch.elapsed,
      reply: reply,
      followUpQuestion: followUp,
      noConfidentMatch: usable.isEmpty && knowledgeMatch == null,
    );
  }

  static GroundedAssistantReply _recommendationReply({
    required String statement,
    required bool isTamil,
    required List<SchemeRecommendation> recommendations,
    required FollowUpQuestion? followUp,
  }) {
    final tamilScript = RegExp(r'[\u0B80-\u0BFF]').hasMatch(statement);
    final language = tamilScript || isTamil
        ? PrivateAiLanguage.tamil
        : PrivateAiLanguage.english;
    if (recommendations.isEmpty) {
      final text = switch (language) {
        PrivateAiLanguage.english =>
          'I could not find a verified catalog match for that yet. Tell me the type of help, your work or study situation, location, and approximate funding need; I will try again without guessing.',
        PrivateAiLanguage.tamil =>
          'இதற்கு நம்பகமாக சரிபார்க்கப்பட்ட திட்டம் இன்னும் கிடைக்கவில்லை. தேவையான உதவி வகை, வேலை அல்லது படிப்பு நிலை, இருப்பிடம் மற்றும் சுமார் நிதித் தேவையைச் சொல்லுங்கள்; ஊகிக்காமல் மீண்டும் தேடுகிறேன்.',
      };
      return GroundedAssistantReply(
        topic: 'no_verified_match',
        displayText: text,
        spokenText: text,
        languageTag: language == PrivateAiLanguage.tamil ? 'ta-IN' : 'en-IN',
        sourceLabel: 'Verified scheme catalog',
        sourceUrl: '',
      );
    }

    final top = recommendations.first;
    final count = recommendations.length;
    final needsMore = followUp != null || top.unknownRequirements.isNotEmpty;
    final text = switch (language) {
      PrivateAiLanguage.english =>
        'I found $count verified ${count == 1 ? 'possibility' : 'possibilities'}. The closest match is ${top.scheme.name}. ${needsMore ? 'I still need one eligibility detail before treating it as a strong match.' : 'The published details align with what you told me, but confirm final eligibility on the official source.'}',
      PrivateAiLanguage.tamil =>
        'சரிபார்க்கப்பட்ட $count வாய்ப்புகள் கிடைத்துள்ளன. மிக நெருக்கமான பொருத்தம் ${top.scheme.name}. ${needsMore ? 'வலுவான பொருத்தமாகக் கூற இன்னும் ஒரு தகுதி விவரம் தேவை.' : 'நீங்கள் கூறிய தகவலுடன் வெளியிடப்பட்ட விவரங்கள் பொருந்துகின்றன; இறுதி தகுதியை அதிகாரப்பூர்வ தளத்தில் உறுதி செய்யுங்கள்.'}',
    };
    return GroundedAssistantReply(
      topic: 'scheme_recommendation',
      displayText: text,
      spokenText: text,
      languageTag: language == PrivateAiLanguage.tamil ? 'ta-IN' : 'en-IN',
      sourceLabel: 'Official scheme source',
      sourceUrl: top.scheme.sourceUrl,
      relatedSchemeCodes: recommendations
          .map((item) => item.scheme.schemeCode)
          .toList(growable: false),
    );
  }

  static bool _isStableRecommendation(SchemeRecommendation recommendation) =>
      recommendation.state == SchemeMatchState.strongMatch ||
      recommendation.state == SchemeMatchState.likelyMatch;

  static Set<String> _requiredConcepts(Set<String> concepts) {
    final required = concepts.where(_needAliases.containsKey).toSet();
    // Sector-specific requests must not degrade into generic startup results.
    // "Start a dairy farm", for example, still requires a livestock match.
    for (final specific in const ['livestock', 'fisheries', 'food']) {
      if (required.contains(specific)) return {specific};
    }
    if (required.length > 1) required.remove('business');
    return required;
  }

  static bool _isTrusted(Scheme scheme) {
    final cached = _trustedSchemeCache[scheme];
    if (cached != null) return cached;
    final trusted = _computeTrust(scheme);
    _trustedSchemeCache[scheme] = trusted;
    return trusted;
  }

  static bool _computeTrust(Scheme scheme) {
    if (!scheme.isActive) return false;
    final status = SchemeFactExtractor.normalize(
      '${scheme.status} ${scheme.verificationStatus}',
    );
    if (SchemeFactExtractor.containsAny(status, [
      'historical',
      'closed',
      'withdrawn',
      'discontinued',
      'expired',
      'needs final',
      'needs further',
      'pending verification',
      'not verified',
    ])) {
      return false;
    }
    return scheme.sourceUrl.isNotEmpty &&
        SchemeFactExtractor.containsAny(status, [
          'verified',
          'official',
          'current',
          'active',
          'yes',
        ]);
  }

  static bool _matchesRequiredConcepts(
    Scheme scheme,
    Set<String> requiredConcepts,
  ) {
    if (requiredConcepts.isEmpty) return true;
    final searchable =
        _conceptTextCache[scheme] ??
        SchemeFactExtractor.normalize(
          '${scheme.name} ${scheme.sector} ${scheme.targetBeneficiary} '
          '${scheme.category} ${scheme.overview} ${scheme.searchKeywords}',
        );
    _conceptTextCache[scheme] = searchable;
    // A statement may contain independent needs (for example, a widow asking
    // about pension and general financial help). A scheme only needs to serve
    // one explicit need; relevance scoring decides which candidates lead.
    return requiredConcepts.any(
      (concept) => (_needAliases[concept] ?? [concept]).any(
        (alias) => _containsCatalogAlias(searchable, alias),
      ),
    );
  }

  static bool _containsCatalogAlias(String text, String alias) {
    final normalizedAlias = SchemeFactExtractor.normalize(alias);
    if (normalizedAlias.isEmpty) return false;
    if (' $text '.contains(' $normalizedAlias ')) return true;
    if (normalizedAlias.contains(' ') || normalizedAlias.length < 4) {
      return false;
    }
    return text
        .split(' ')
        .any(
          (token) =>
              token.startsWith(normalizedAlias) ||
              (token.length >= 4 && normalizedAlias.startsWith(token)),
        );
  }
}
