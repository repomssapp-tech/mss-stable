import '../../../l10n/app_localizations.dart';
import '../../../services/recommendation/indian_states.dart';
import '../question_node.dart';

class AssessmentFlowResult {
  final Map<String, QuestionNode> flow;
  final String initialQuestionId;

  const AssessmentFlowResult({
    required this.flow,
    required this.initialQuestionId,
  });
}

/// Resolves the question flow and initial question ID based on card type and title.
AssessmentFlowResult resolveQuestionFlow({
  required String cardTitle,
  required String cardType,
  required AppLocalizations l10nEn,
  required AppLocalizations l10nTa,
}) {
  final title = cardTitle.toLowerCase().trim();

  if (cardType == 'category') {
    if (title.contains('educat') ||
        title.contains('scholar') ||
        title.contains('student')) {
      return AssessmentFlowResult(
        flow: getEducationFlow(l10nEn, l10nTa),
        initialQuestionId: 'edu_q1',
      );
    } else if (title.contains('women') ||
        title.contains('child') ||
        title.contains('matern')) {
      return AssessmentFlowResult(
        flow: getWomenFlow(l10nEn, l10nTa),
        initialQuestionId: 'women_q1',
      );
    } else if (title.contains('agri') ||
        title.contains('farm') ||
        title.contains('crop')) {
      return AssessmentFlowResult(
        flow: getAgricultureFlow(l10nEn, l10nTa),
        initialQuestionId: 'agri_q1',
      );
    } else if (title.contains('skill') ||
        title.contains('employ') ||
        title.contains('job')) {
      return AssessmentFlowResult(
        flow: getSkillFlow(l10nEn, l10nTa),
        initialQuestionId: 'skill_q1',
      );
    } else if (title.contains('tech') ||
        title.contains('export') ||
        title.contains('trade')) {
      return AssessmentFlowResult(
        flow: getTechExportFlow(l10nEn, l10nTa),
        initialQuestionId: 'te_q1',
      );
    } else if (title.contains('business') ||
        title.contains('msme') ||
        title.contains('start') ||
        title.contains('artisan') ||
        title.contains('loan') ||
        title.contains('credit')) {
      return AssessmentFlowResult(
        flow: getBusinessFlow(l10nEn, l10nTa),
        initialQuestionId: 'biz_q1',
      );
    } else {
      return AssessmentFlowResult(
        flow: getDefaultCategoryFlow(l10nEn, l10nTa),
        initialQuestionId: 'cat_q1',
      );
    }
  } else if (cardType == 'state') {
    return AssessmentFlowResult(
      flow: getStateFlow(cardTitle, l10nEn, l10nTa),
      initialQuestionId: 'state_q1',
    );
  } else {
    return AssessmentFlowResult(
      flow: getMinistryFlow(cardTitle, l10nEn, l10nTa),
      initialQuestionId: 'min_q1',
    );
  }
}

Map<String, QuestionNode> getEducationFlow(
  AppLocalizations en,
  AppLocalizations ta,
) {
  return {
    'edu_q1': QuestionNode(
      id: 'edu_q1',
      questionText: en.assessEduQ1,
      questionTextTa: ta.assessEduQ1,
      options: [
        en.assessEduQ1Opt1,
        en.assessEduQ1Opt2,
        en.assessEduQ1Opt3,
        en.assessEduQ1Opt4,
      ],
      optionsTa: [
        ta.assessEduQ1Opt1,
        ta.assessEduQ1Opt2,
        ta.assessEduQ1Opt3,
        ta.assessEduQ1Opt4,
      ],
      nextId: (ans) => ans.contains("Schooling")
          ? "edu_q2_school"
          : ans.contains("Research")
          ? "edu_q2_research"
          : "edu_q2_college",
    ),
    'edu_q2_school': QuestionNode(
      id: 'edu_q2_school',
      questionText: en.assessEduQ2School,
      questionTextTa: ta.assessEduQ2School,
      options: [
        en.assessEduQ2SchoolOpt1,
        en.assessEduQ2SchoolOpt2,
        en.assessEduQ2SchoolOpt3,
      ],
      optionsTa: [
        ta.assessEduQ2SchoolOpt1,
        ta.assessEduQ2SchoolOpt2,
        ta.assessEduQ2SchoolOpt3,
      ],
      nextId: (_) => "edu_q3_school",
    ),
    'edu_q2_college': QuestionNode(
      id: 'edu_q2_college',
      questionText: en.assessEduQ2College,
      questionTextTa: ta.assessEduQ2College,
      options: [
        en.assessEduQ2CollegeOpt1,
        en.assessEduQ2CollegeOpt2,
        en.assessEduQ2CollegeOpt3,
        en.assessEduQ2CollegeOpt4,
      ],
      optionsTa: [
        ta.assessEduQ2CollegeOpt1,
        ta.assessEduQ2CollegeOpt2,
        ta.assessEduQ2CollegeOpt3,
        ta.assessEduQ2CollegeOpt4,
      ],
      nextId: (_) => "edu_q3_college",
    ),
    'edu_q2_research': QuestionNode(
      id: 'edu_q2_research',
      questionText: en.assessEduQ2Research,
      questionTextTa: ta.assessEduQ2Research,
      options: [
        en.assessEduQ2ResearchOpt1,
        en.assessEduQ2ResearchOpt2,
        en.assessEduQ2ResearchOpt3,
      ],
      optionsTa: [
        ta.assessEduQ2ResearchOpt1,
        ta.assessEduQ2ResearchOpt2,
        ta.assessEduQ2ResearchOpt3,
      ],
      nextId: (_) => "edu_q3_research",
    ),
    'edu_q3_school': QuestionNode(
      id: 'edu_q3_school',
      questionText: en.assessEduQ3School,
      questionTextTa: ta.assessEduQ3School,
      options: [
        en.assessEduQ3SchoolOpt1,
        en.assessEduQ3SchoolOpt2,
        en.assessEduQ3SchoolOpt3,
      ],
      optionsTa: [
        ta.assessEduQ3SchoolOpt1,
        ta.assessEduQ3SchoolOpt2,
        ta.assessEduQ3SchoolOpt3,
      ],
      nextId: (_) => "edu_q4_caste",
    ),
    'edu_q3_college': QuestionNode(
      id: 'edu_q3_college',
      questionText: en.assessEduQ3College,
      questionTextTa: ta.assessEduQ3College,
      options: [en.assessEduQ3CollegeOpt1, en.assessEduQ3CollegeOpt2],
      optionsTa: [ta.assessEduQ3CollegeOpt1, ta.assessEduQ3CollegeOpt2],
      nextId: (_) => "edu_q4_caste",
    ),
    'edu_q3_research': QuestionNode(
      id: 'edu_q3_research',
      questionText: en.assessEduQ3Research,
      questionTextTa: ta.assessEduQ3Research,
      options: [
        en.assessEduQ3ResearchOpt1,
        en.assessEduQ3ResearchOpt2,
        en.assessEduQ3ResearchOpt3,
      ],
      optionsTa: [
        ta.assessEduQ3ResearchOpt1,
        ta.assessEduQ3ResearchOpt2,
        ta.assessEduQ3ResearchOpt3,
      ],
      nextId: (_) => "edu_q4_caste",
    ),
    'edu_q4_caste': QuestionNode(
      id: 'edu_q4_caste',
      questionText: en.assessEduQ4Caste,
      questionTextTa: ta.assessEduQ4Caste,
      options: [
        en.assessEduQ4CasteOpt1,
        en.assessEduQ4CasteOpt2,
        en.assessEduQ4CasteOpt3,
        en.assessEduQ4CasteOpt4,
      ],
      optionsTa: [
        ta.assessEduQ4CasteOpt1,
        ta.assessEduQ4CasteOpt2,
        ta.assessEduQ4CasteOpt3,
        ta.assessEduQ4CasteOpt4,
      ],
      nextId: (_) => "edu_q5_income",
    ),
    'edu_q5_income': QuestionNode(
      id: 'edu_q5_income',
      questionText: en.assessEduQ5Income,
      questionTextTa: ta.assessEduQ5Income,
      options: [
        en.assessEduQ5IncomeOpt1,
        en.assessEduQ5IncomeOpt2,
        en.assessEduQ5IncomeOpt3,
      ],
      optionsTa: [
        ta.assessEduQ5IncomeOpt1,
        ta.assessEduQ5IncomeOpt2,
        ta.assessEduQ5IncomeOpt3,
      ],
      nextId: (_) => null,
    ),
  };
}

Map<String, QuestionNode> getWomenFlow(
  AppLocalizations en,
  AppLocalizations ta,
) {
  return {
    'women_q1': QuestionNode(
      id: 'women_q1',
      questionText: en.assessWomenQ1,
      questionTextTa: ta.assessWomenQ1,
      options: [
        en.assessWomenQ1Opt1,
        en.assessWomenQ1Opt2,
        en.assessWomenQ1Opt3,
        en.assessWomenQ1Opt4,
      ],
      optionsTa: [
        ta.assessWomenQ1Opt1,
        ta.assessWomenQ1Opt2,
        ta.assessWomenQ1Opt3,
        ta.assessWomenQ1Opt4,
      ],
      nextId: (ans) => ans.contains("Mother")
          ? "women_q2_maternal"
          : ans.contains("Child")
          ? "women_q2_girl"
          : ans.contains("Entrepreneur")
          ? "women_q2_biz"
          : "women_q2_welfare",
    ),
    'women_q2_maternal': QuestionNode(
      id: 'women_q2_maternal',
      questionText: en.assessWomenQ2Maternal,
      questionTextTa: ta.assessWomenQ2Maternal,
      options: [
        en.assessWomenQ2MaternalOpt1,
        en.assessWomenQ2MaternalOpt2,
        en.assessWomenQ2MaternalOpt3,
      ],
      optionsTa: [
        ta.assessWomenQ2MaternalOpt1,
        ta.assessWomenQ2MaternalOpt2,
        ta.assessWomenQ2MaternalOpt3,
      ],
      nextId: (_) => "women_q3_matern_reg",
    ),
    'women_q2_girl': QuestionNode(
      id: 'women_q2_girl',
      questionText: en.assessWomenQ2Girl,
      questionTextTa: ta.assessWomenQ2Girl,
      options: [
        en.assessWomenQ2GirlOpt1,
        en.assessWomenQ2GirlOpt2,
        en.assessWomenQ2GirlOpt3,
      ],
      optionsTa: [
        ta.assessWomenQ2GirlOpt1,
        ta.assessWomenQ2GirlOpt2,
        ta.assessWomenQ2GirlOpt3,
      ],
      nextId: (ans) => ans.contains("Adolescent")
          ? "women_q3_girl_edu"
          : "women_q3_girl_save",
    ),
    'women_q2_biz': QuestionNode(
      id: 'women_q2_biz',
      questionText: en.assessWomenQ2Biz,
      questionTextTa: ta.assessWomenQ2Biz,
      options: [en.assessWomenQ2BizOpt1, en.assessWomenQ2BizOpt2],
      optionsTa: [ta.assessWomenQ2BizOpt1, ta.assessWomenQ2BizOpt2],
      nextId: (_) => "women_q3_biz_credit",
    ),
    'women_q2_welfare': QuestionNode(
      id: 'women_q2_welfare',
      questionText: en.assessWomenQ2Welfare,
      questionTextTa: ta.assessWomenQ2Welfare,
      options: [en.assessWomenQ2WelfareOpt1, en.assessWomenQ2WelfareOpt2],
      optionsTa: [ta.assessWomenQ2WelfareOpt1, ta.assessWomenQ2WelfareOpt2],
      nextId: (_) => "women_q3_welfare_pension",
    ),
    'women_q3_matern_reg': QuestionNode(
      id: 'women_q3_matern_reg',
      questionText: en.assessWomenQ3MaternReg,
      questionTextTa: ta.assessWomenQ3MaternReg,
      options: [en.assessWomenQ3MaternRegOpt1, en.assessWomenQ3MaternRegOpt2],
      optionsTa: [ta.assessWomenQ3MaternRegOpt1, ta.assessWomenQ3MaternRegOpt2],
      nextId: (_) => "women_q4_caste",
    ),
    'women_q3_girl_save': QuestionNode(
      id: 'women_q3_girl_save',
      questionText: en.assessWomenQ3GirlSave,
      questionTextTa: ta.assessWomenQ3GirlSave,
      options: [en.assessWomenQ3GirlSaveOpt1, en.assessWomenQ3GirlSaveOpt2],
      optionsTa: [ta.assessWomenQ3GirlSaveOpt1, ta.assessWomenQ3GirlSaveOpt2],
      nextId: (_) => "women_q4_caste",
    ),
    'women_q3_girl_edu': QuestionNode(
      id: 'women_q3_girl_edu',
      questionText: en.assessWomenQ3GirlEdu,
      questionTextTa: ta.assessWomenQ3GirlEdu,
      options: [en.assessWomenQ3GirlEduOpt1, en.assessWomenQ3GirlEduOpt2],
      optionsTa: [ta.assessWomenQ3GirlEduOpt1, ta.assessWomenQ3GirlEduOpt2],
      nextId: (_) => "women_q4_caste",
    ),
    'women_q3_biz_credit': QuestionNode(
      id: 'women_q3_biz_credit',
      questionText: en.assessWomenQ3BizCredit,
      questionTextTa: ta.assessWomenQ3BizCredit,
      options: [
        en.assessWomenQ3BizCreditOpt1,
        en.assessWomenQ3BizCreditOpt2,
        en.assessWomenQ3BizCreditOpt3,
      ],
      optionsTa: [
        ta.assessWomenQ3BizCreditOpt1,
        ta.assessWomenQ3BizCreditOpt2,
        ta.assessWomenQ3BizCreditOpt3,
      ],
      nextId: (_) => "women_q4_caste",
    ),
    'women_q3_welfare_pension': QuestionNode(
      id: 'women_q3_welfare_pension',
      questionText: en.assessWomenQ3WelfarePension,
      questionTextTa: ta.assessWomenQ3WelfarePension,
      options: [
        en.assessWomenQ3WelfarePensionOpt1,
        en.assessWomenQ3WelfarePensionOpt2,
      ],
      optionsTa: [
        ta.assessWomenQ3WelfarePensionOpt1,
        ta.assessWomenQ3WelfarePensionOpt2,
      ],
      nextId: (_) => "women_q4_caste",
    ),
    'women_q4_caste': QuestionNode(
      id: 'women_q4_caste',
      questionText: en.assessWomenQ4Caste,
      questionTextTa: ta.assessWomenQ4Caste,
      options: [
        en.assessWomenQ4CasteOpt1,
        en.assessWomenQ4CasteOpt2,
        en.assessWomenQ4CasteOpt3,
        en.assessWomenQ4CasteOpt4,
      ],
      optionsTa: [
        ta.assessWomenQ4CasteOpt1,
        ta.assessWomenQ4CasteOpt2,
        ta.assessWomenQ4CasteOpt3,
        ta.assessWomenQ4CasteOpt4,
      ],
      nextId: (_) => "women_q5_income",
    ),
    'women_q5_income': QuestionNode(
      id: 'women_q5_income',
      questionText: en.assessWomenQ5Income,
      questionTextTa: ta.assessWomenQ5Income,
      options: [
        en.assessWomenQ5IncomeOpt1,
        en.assessWomenQ5IncomeOpt2,
        en.assessWomenQ5IncomeOpt3,
      ],
      optionsTa: [
        ta.assessWomenQ5IncomeOpt1,
        ta.assessWomenQ5IncomeOpt2,
        ta.assessWomenQ5IncomeOpt3,
      ],
      nextId: (_) => null,
    ),
  };
}

Map<String, QuestionNode> getBusinessFlow(
  AppLocalizations en,
  AppLocalizations ta,
) {
  return {
    'biz_q1': QuestionNode(
      id: 'biz_q1',
      questionText: en.assessBizQ1,
      questionTextTa: ta.assessBizQ1,
      options: [
        en.assessBizQ1Opt1,
        en.assessBizQ1Opt2,
        en.assessBizQ1Opt3,
        en.assessBizQ1Opt4,
      ],
      optionsTa: [
        ta.assessBizQ1Opt1,
        ta.assessBizQ1Opt2,
        ta.assessBizQ1Opt3,
        ta.assessBizQ1Opt4,
      ],
      nextId: (ans) => ans.contains("MSME")
          ? "biz_q2_msme"
          : ans.contains("Startup")
          ? "biz_q2_startup"
          : ans.contains("trader")
          ? "biz_q2_artisan"
          : "biz_q2_idea",
    ),
    'biz_q2_msme': QuestionNode(
      id: 'biz_q2_msme',
      questionText: en.assessBizQ2Msme,
      questionTextTa: ta.assessBizQ2Msme,
      options: [
        en.assessBizQ2MsmeOpt1,
        en.assessBizQ2MsmeOpt2,
        en.assessBizQ2MsmeOpt3,
      ],
      optionsTa: [
        ta.assessBizQ2MsmeOpt1,
        ta.assessBizQ2MsmeOpt2,
        ta.assessBizQ2MsmeOpt3,
      ],
      nextId: (_) => "biz_q3_msme_need",
    ),
    'biz_q2_startup': QuestionNode(
      id: 'biz_q2_startup',
      questionText: en.assessBizQ2Startup,
      questionTextTa: ta.assessBizQ2Startup,
      options: [
        en.assessBizQ2StartupOpt1,
        en.assessBizQ2StartupOpt2,
        en.assessBizQ2StartupOpt3,
      ],
      optionsTa: [
        ta.assessBizQ2StartupOpt1,
        ta.assessBizQ2StartupOpt2,
        ta.assessBizQ2StartupOpt3,
      ],
      nextId: (_) => "biz_q3_startup_need",
    ),
    'biz_q2_artisan': QuestionNode(
      id: 'biz_q2_artisan',
      questionText: en.assessBizQ2Artisan,
      questionTextTa: ta.assessBizQ2Artisan,
      options: [en.assessBizQ2ArtisanOpt1, en.assessBizQ2ArtisanOpt2],
      optionsTa: [ta.assessBizQ2ArtisanOpt1, ta.assessBizQ2ArtisanOpt2],
      nextId: (_) => "biz_q3_artisan_need",
    ),
    'biz_q2_idea': QuestionNode(
      id: 'biz_q2_idea',
      questionText: en.assessBizQ2Idea,
      questionTextTa: ta.assessBizQ2Idea,
      options: [en.assessBizQ2IdeaOpt1, en.assessBizQ2IdeaOpt2],
      optionsTa: [ta.assessBizQ2IdeaOpt1, ta.assessBizQ2IdeaOpt2],
      nextId: (_) => "biz_q3_msme_need",
    ),
    'biz_q3_msme_need': QuestionNode(
      id: 'biz_q3_msme_need',
      questionText: en.assessBizQ3MsmeNeed,
      questionTextTa: ta.assessBizQ3MsmeNeed,
      options: [
        en.assessBizQ3MsmeNeedOpt1,
        en.assessBizQ3MsmeNeedOpt2,
        en.assessBizQ3MsmeNeedOpt3,
      ],
      optionsTa: [
        ta.assessBizQ3MsmeNeedOpt1,
        ta.assessBizQ3MsmeNeedOpt2,
        ta.assessBizQ3MsmeNeedOpt3,
      ],
      nextId: (_) => "biz_q4_demographics",
    ),
    'biz_q3_startup_need': QuestionNode(
      id: 'biz_q3_startup_need',
      questionText: en.assessBizQ3StartupNeed,
      questionTextTa: ta.assessBizQ3StartupNeed,
      options: [
        en.assessBizQ3StartupNeedOpt1,
        en.assessBizQ3StartupNeedOpt2,
        en.assessBizQ3StartupNeedOpt3,
      ],
      optionsTa: [
        ta.assessBizQ3StartupNeedOpt1,
        ta.assessBizQ3StartupNeedOpt2,
        ta.assessBizQ3StartupNeedOpt3,
      ],
      nextId: (_) => "biz_q4_demographics",
    ),
    'biz_q3_artisan_need': QuestionNode(
      id: 'biz_q3_artisan_need',
      questionText: en.assessBizQ3ArtisanNeed,
      questionTextTa: ta.assessBizQ3ArtisanNeed,
      options: [
        en.assessBizQ3ArtisanNeedOpt1,
        en.assessBizQ3ArtisanNeedOpt2,
        en.assessBizQ3ArtisanNeedOpt3,
      ],
      optionsTa: [
        ta.assessBizQ3ArtisanNeedOpt1,
        ta.assessBizQ3ArtisanNeedOpt2,
        ta.assessBizQ3ArtisanNeedOpt3,
      ],
      nextId: (_) => "biz_q4_demographics",
    ),
    'biz_q4_demographics': QuestionNode(
      id: 'biz_q4_demographics',
      questionText: en.assessBizQ4Demographics,
      questionTextTa: ta.assessBizQ4Demographics,
      options: [
        en.assessBizQ4DemographicsOpt1,
        en.assessBizQ4DemographicsOpt2,
        en.assessBizQ4DemographicsOpt3,
        en.assessBizQ4DemographicsOpt4,
      ],
      optionsTa: [
        ta.assessBizQ4DemographicsOpt1,
        ta.assessBizQ4DemographicsOpt2,
        ta.assessBizQ4DemographicsOpt3,
        ta.assessBizQ4DemographicsOpt4,
      ],
      nextId: (_) => "biz_q5_turnover",
    ),
    'biz_q5_turnover': QuestionNode(
      id: 'biz_q5_turnover',
      questionText: en.assessBizQ5Turnover,
      questionTextTa: ta.assessBizQ5Turnover,
      options: [
        en.assessBizQ5TurnoverOpt1,
        en.assessBizQ5TurnoverOpt2,
        en.assessBizQ5TurnoverOpt3,
        en.assessBizQ5TurnoverOpt4,
      ],
      optionsTa: [
        ta.assessBizQ5TurnoverOpt1,
        ta.assessBizQ5TurnoverOpt2,
        ta.assessBizQ5TurnoverOpt3,
        ta.assessBizQ5TurnoverOpt4,
      ],
      nextId: (_) => null,
    ),
  };
}

Map<String, QuestionNode> getAgricultureFlow(
  AppLocalizations en,
  AppLocalizations ta,
) {
  return {
    'agri_q1': QuestionNode(
      id: 'agri_q1',
      questionText: en.assessAgriQ1,
      questionTextTa: ta.assessAgriQ1,
      options: [
        en.assessAgriQ1Opt1,
        en.assessAgriQ1Opt2,
        en.assessAgriQ1Opt3,
        en.assessAgriQ1Opt4,
      ],
      optionsTa: [
        ta.assessAgriQ1Opt1,
        ta.assessAgriQ1Opt2,
        ta.assessAgriQ1Opt3,
        ta.assessAgriQ1Opt4,
      ],
      nextId: (_) => "agri_q2",
    ),
    'agri_q2': QuestionNode(
      id: 'agri_q2',
      questionText: en.assessAgriQ2,
      questionTextTa: ta.assessAgriQ2,
      options: [
        en.assessAgriQ2Opt1,
        en.assessAgriQ2Opt2,
        en.assessAgriQ2Opt3,
        en.assessAgriQ2Opt4,
      ],
      optionsTa: [
        ta.assessAgriQ2Opt1,
        ta.assessAgriQ2Opt2,
        ta.assessAgriQ2Opt3,
        ta.assessAgriQ2Opt4,
      ],
      nextId: (_) => "agri_q3_caste",
    ),
    'agri_q3_caste': QuestionNode(
      id: 'agri_q3_caste',
      questionText: en.assessAgriQ3Caste,
      questionTextTa: ta.assessAgriQ3Caste,
      options: [
        en.assessAgriQ3CasteOpt1,
        en.assessAgriQ3CasteOpt2,
        en.assessAgriQ3CasteOpt3,
        en.assessAgriQ3CasteOpt4,
      ],
      optionsTa: [
        ta.assessAgriQ3CasteOpt1,
        ta.assessAgriQ3CasteOpt2,
        ta.assessAgriQ3CasteOpt3,
        ta.assessAgriQ3CasteOpt4,
      ],
      nextId: (_) => "agri_q4_income",
    ),
    'agri_q4_income': QuestionNode(
      id: 'agri_q4_income',
      questionText: en.assessAgriQ4Income,
      questionTextTa: ta.assessAgriQ4Income,
      options: [
        en.assessAgriQ4IncomeOpt1,
        en.assessAgriQ4IncomeOpt2,
        en.assessAgriQ4IncomeOpt3,
      ],
      optionsTa: [
        ta.assessAgriQ4IncomeOpt1,
        ta.assessAgriQ4IncomeOpt2,
        ta.assessAgriQ4IncomeOpt3,
      ],
      nextId: (_) => null,
    ),
  };
}

Map<String, QuestionNode> getSkillFlow(
  AppLocalizations en,
  AppLocalizations ta,
) {
  return {
    'skill_q1': QuestionNode(
      id: 'skill_q1',
      questionText: en.assessSkillQ1,
      questionTextTa: ta.assessSkillQ1,
      options: [
        en.assessSkillQ1Opt1,
        en.assessSkillQ1Opt2,
        en.assessSkillQ1Opt3,
        en.assessSkillQ1Opt4,
      ],
      optionsTa: [
        ta.assessSkillQ1Opt1,
        ta.assessSkillQ1Opt2,
        ta.assessSkillQ1Opt3,
        ta.assessSkillQ1Opt4,
      ],
      nextId: (_) => "skill_q2",
    ),
    'skill_q2': QuestionNode(
      id: 'skill_q2',
      questionText: en.assessSkillQ2,
      questionTextTa: ta.assessSkillQ2,
      options: [
        en.assessSkillQ2Opt1,
        en.assessSkillQ2Opt2,
        en.assessSkillQ2Opt3,
        en.assessSkillQ2Opt4,
      ],
      optionsTa: [
        ta.assessSkillQ2Opt1,
        ta.assessSkillQ2Opt2,
        ta.assessSkillQ2Opt3,
        ta.assessSkillQ2Opt4,
      ],
      nextId: (_) => "skill_q3",
    ),
    'skill_q3': QuestionNode(
      id: 'skill_q3',
      questionText: en.assessSkillQ3,
      questionTextTa: ta.assessSkillQ3,
      options: [en.assessSkillQ3Opt1, en.assessSkillQ3Opt2],
      optionsTa: [ta.assessSkillQ3Opt1, ta.assessSkillQ3Opt2],
      nextId: (_) => "skill_q4_income",
    ),
    'skill_q4_income': QuestionNode(
      id: 'skill_q4_income',
      questionText: en.assessSkillQ4Income,
      questionTextTa: ta.assessSkillQ4Income,
      options: [
        en.assessSkillQ4IncomeOpt1,
        en.assessSkillQ4IncomeOpt2,
        en.assessSkillQ4IncomeOpt3,
      ],
      optionsTa: [
        ta.assessSkillQ4IncomeOpt1,
        ta.assessSkillQ4IncomeOpt2,
        ta.assessSkillQ4IncomeOpt3,
      ],
      nextId: (_) => null,
    ),
  };
}

Map<String, QuestionNode> getTechExportFlow(
  AppLocalizations en,
  AppLocalizations ta,
) {
  return {
    'te_q1': QuestionNode(
      id: 'te_q1',
      questionText: en.assessTeQ1,
      questionTextTa: ta.assessTeQ1,
      options: [
        en.assessTeQ1Opt1,
        en.assessTeQ1Opt2,
        en.assessTeQ1Opt3,
        en.assessTeQ1Opt4,
      ],
      optionsTa: [
        ta.assessTeQ1Opt1,
        ta.assessTeQ1Opt2,
        ta.assessTeQ1Opt3,
        ta.assessTeQ1Opt4,
      ],
      nextId: (_) => "te_q2",
    ),
    'te_q2': QuestionNode(
      id: 'te_q2',
      questionText: en.assessTeQ2,
      questionTextTa: ta.assessTeQ2,
      options: [
        en.assessTeQ2Opt1,
        en.assessTeQ2Opt2,
        en.assessTeQ2Opt3,
        en.assessTeQ2Opt4,
      ],
      optionsTa: [
        ta.assessTeQ2Opt1,
        ta.assessTeQ2Opt2,
        ta.assessTeQ2Opt3,
        ta.assessTeQ2Opt4,
      ],
      nextId: (_) => "te_q3_turnover",
    ),
    'te_q3_turnover': QuestionNode(
      id: 'te_q3_turnover',
      questionText: en.assessTeQ3Turnover,
      questionTextTa: ta.assessTeQ3Turnover,
      options: [
        en.assessTeQ3TurnoverOpt1,
        en.assessTeQ3TurnoverOpt2,
        en.assessTeQ3TurnoverOpt3,
      ],
      optionsTa: [
        ta.assessTeQ3TurnoverOpt1,
        ta.assessTeQ3TurnoverOpt2,
        ta.assessTeQ3TurnoverOpt3,
      ],
      nextId: (_) => null,
    ),
  };
}

Map<String, QuestionNode> getDefaultCategoryFlow(
  AppLocalizations en,
  AppLocalizations ta,
) {
  return {
    'cat_q1': QuestionNode(
      id: 'cat_q1',
      questionText: en.assessCatQ1,
      questionTextTa: ta.assessCatQ1,
      options: [
        en.assessCatQ1Opt1,
        en.assessCatQ1Opt2,
        en.assessCatQ1Opt3,
        en.assessCatQ1Opt4,
      ],
      optionsTa: [
        ta.assessCatQ1Opt1,
        ta.assessCatQ1Opt2,
        ta.assessCatQ1Opt3,
        ta.assessCatQ1Opt4,
      ],
      nextId: (_) => "cat_q2",
    ),
    'cat_q2': QuestionNode(
      id: 'cat_q2',
      questionText: en.assessCatQ2,
      questionTextTa: ta.assessCatQ2,
      options: [en.assessCatQ2Opt1, en.assessCatQ2Opt2, en.assessCatQ2Opt3],
      optionsTa: [ta.assessCatQ2Opt1, ta.assessCatQ2Opt2, ta.assessCatQ2Opt3],
      nextId: (_) => "cat_q3",
    ),
    'cat_q3': QuestionNode(
      id: 'cat_q3',
      questionText: en.assessCatQ3,
      questionTextTa: ta.assessCatQ3,
      options: [en.assessCatQ3Opt1, en.assessCatQ3Opt2, en.assessCatQ3Opt3],
      optionsTa: [ta.assessCatQ3Opt1, ta.assessCatQ3Opt2, ta.assessCatQ3Opt3],
      nextId: (_) => "cat_q4",
    ),
    'cat_q4': QuestionNode(
      id: 'cat_q4',
      questionText: en.assessCatQ4,
      questionTextTa: ta.assessCatQ4,
      options: [
        en.assessCatQ4Opt1,
        en.assessCatQ4Opt2,
        en.assessCatQ4Opt3,
        en.assessCatQ4Opt4,
      ],
      optionsTa: [
        ta.assessCatQ4Opt1,
        ta.assessCatQ4Opt2,
        ta.assessCatQ4Opt3,
        ta.assessCatQ4Opt4,
      ],
      nextId: (_) => "cat_q5",
    ),
    'cat_q5': QuestionNode(
      id: 'cat_q5',
      questionText: en.assessCatQ5,
      questionTextTa: ta.assessCatQ5,
      options: [en.assessCatQ5Opt1, en.assessCatQ5Opt2, en.assessCatQ5Opt3],
      optionsTa: [ta.assessCatQ5Opt1, ta.assessCatQ5Opt2, ta.assessCatQ5Opt3],
      nextId: (_) => null,
    ),
  };
}

Map<String, QuestionNode> getStateFlow(
  String stateName,
  AppLocalizations en,
  AppLocalizations ta,
) {
  // The translated sentences carry the state name in that same language.
  final taState = IndianStates.displayName(stateName, ta.localeName);
  return {
    'state_q1': QuestionNode(
      id: 'state_q1',
      questionText: en.assessStateQ1(stateName),
      questionTextTa: ta.assessStateQ1(taState),
      options: [en.assessStateQ1Opt1, en.assessStateQ1Opt2],
      optionsTa: [ta.assessStateQ1Opt1, ta.assessStateQ1Opt2],
      nextId: (_) => "state_q2",
    ),
    'state_q2': QuestionNode(
      id: 'state_q2',
      questionText: en.assessStateQ2(stateName),
      questionTextTa: ta.assessStateQ2(taState),
      options: [
        en.assessStateQ2Opt1,
        en.assessStateQ2Opt2,
        en.assessStateQ2Opt3,
        en.assessStateQ2Opt4,
      ],
      optionsTa: [
        ta.assessStateQ2Opt1,
        ta.assessStateQ2Opt2,
        ta.assessStateQ2Opt3,
        ta.assessStateQ2Opt4,
      ],
      nextId: (_) => "state_q3",
    ),
    'state_q3': QuestionNode(
      id: 'state_q3',
      questionText: en.assessStateQ3(stateName),
      questionTextTa: ta.assessStateQ3(taState),
      options: [
        en.assessStateQ3Opt1,
        en.assessStateQ3Opt2,
        en.assessStateQ3Opt3,
        en.assessStateQ3Opt4,
      ],
      optionsTa: [
        ta.assessStateQ3Opt1,
        ta.assessStateQ3Opt2,
        ta.assessStateQ3Opt3,
        ta.assessStateQ3Opt4,
      ],
      nextId: (_) => "state_q4",
    ),
    'state_q4': QuestionNode(
      id: 'state_q4',
      questionText: en.assessStateQ4,
      questionTextTa: ta.assessStateQ4,
      options: [
        en.assessStateQ4Opt1,
        en.assessStateQ4Opt2,
        en.assessStateQ4Opt3,
        en.assessStateQ4Opt4,
      ],
      optionsTa: [
        ta.assessStateQ4Opt1,
        ta.assessStateQ4Opt2,
        ta.assessStateQ4Opt3,
        ta.assessStateQ4Opt4,
      ],
      nextId: (_) => "state_q5",
    ),
    'state_q5': QuestionNode(
      id: 'state_q5',
      questionText: en.assessStateQ5,
      questionTextTa: ta.assessStateQ5,
      options: [
        en.assessStateQ5Opt1,
        en.assessStateQ5Opt2,
        en.assessStateQ5Opt3,
      ],
      optionsTa: [
        ta.assessStateQ5Opt1,
        ta.assessStateQ5Opt2,
        ta.assessStateQ5Opt3,
      ],
      nextId: (_) => null,
    ),
  };
}

Map<String, QuestionNode> getMinistryFlow(
  String ministryName,
  AppLocalizations en,
  AppLocalizations ta,
) {
  return {
    'min_q1': QuestionNode(
      id: 'min_q1',
      questionText: en.assessMinQ1,
      questionTextTa: ta.assessMinQ1,
      options: [
        en.assessMinQ1Opt1,
        en.assessMinQ1Opt2,
        en.assessMinQ1Opt3,
        en.assessMinQ1Opt4,
      ],
      optionsTa: [
        ta.assessMinQ1Opt1,
        ta.assessMinQ1Opt2,
        ta.assessMinQ1Opt3,
        ta.assessMinQ1Opt4,
      ],
      nextId: (_) => "min_q2",
    ),
    'min_q2': QuestionNode(
      id: 'min_q2',
      questionText: en.assessMinQ2,
      questionTextTa: ta.assessMinQ2,
      options: [en.assessMinQ2Opt1, en.assessMinQ2Opt2, en.assessMinQ2Opt3],
      optionsTa: [ta.assessMinQ2Opt1, ta.assessMinQ2Opt2, ta.assessMinQ2Opt3],
      nextId: (_) => "min_q3",
    ),
    'min_q3': QuestionNode(
      id: 'min_q3',
      questionText: en.assessMinQ3,
      questionTextTa: ta.assessMinQ3,
      options: [en.assessMinQ3Opt1, en.assessMinQ3Opt2],
      optionsTa: [ta.assessMinQ3Opt1, ta.assessMinQ3Opt2],
      nextId: (_) => "min_q4",
    ),
    'min_q4': QuestionNode(
      id: 'min_q4',
      questionText: en.assessMinQ4,
      questionTextTa: ta.assessMinQ4,
      options: [
        en.assessMinQ4Opt1,
        en.assessMinQ4Opt2,
        en.assessMinQ4Opt3,
        en.assessMinQ4Opt4,
      ],
      optionsTa: [
        ta.assessMinQ4Opt1,
        ta.assessMinQ4Opt2,
        ta.assessMinQ4Opt3,
        ta.assessMinQ4Opt4,
      ],
      nextId: (_) => "min_q5",
    ),
    'min_q5': QuestionNode(
      id: 'min_q5',
      questionText: en.assessMinQ5,
      questionTextTa: ta.assessMinQ5,
      options: [en.assessMinQ5Opt1, en.assessMinQ5Opt2, en.assessMinQ5Opt3],
      optionsTa: [ta.assessMinQ5Opt1, ta.assessMinQ5Opt2, ta.assessMinQ5Opt3],
      nextId: (_) => null,
    ),
  };
}
