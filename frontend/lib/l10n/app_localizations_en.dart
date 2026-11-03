// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get goodMorning => 'Good Morning,';

  @override
  String get completeYourProfile => 'Complete Your Profile';

  @override
  String get unlockPersonalizedSchemeRecommendations =>
      'See the schemes that fit you';

  @override
  String get applicationsClosingSoon => 'Applications Closing Soon';

  @override
  String get featured => 'Featured';

  @override
  String get forWomenEntrepreneurs => 'For Women Entrepreneurs';

  @override
  String get exploreSpecialFundingSchemes => 'Explore special funding schemes';

  @override
  String get whatWouldYouLikeToDoToday => 'What would you like to do today?';

  @override
  String get exportSupport => 'Export Support';

  @override
  String get exportModuleDescription =>
      'Global Trade Readiness & Export Incentives';

  @override
  String get growBusiness => 'Grow Business';

  @override
  String get registerUdyam => 'Register UDYAM';

  @override
  String get udyamModuleDescription =>
      'Official MSME Registration Guide & Direct Portal Link';

  @override
  String get findFunding => 'Find Funding';

  @override
  String get startABusiness => 'Start a Business';

  @override
  String get exploreMsmeSupport => 'MSME support';

  @override
  String get schemes => 'Schemes';

  @override
  String get finance => 'Finance';

  @override
  String get taxGst => 'Tax & GST';

  @override
  String get export => 'Export';

  @override
  String get treds => 'TReDS';

  @override
  String get csrSupport => 'CSR Support';

  @override
  String get govtAuthorities => 'Govt. Authorities';

  @override
  String get institutions => 'Institutions';

  @override
  String get recommendedForYou => 'Recommended for you';

  @override
  String get homeRecommendationsEmptyMessage =>
      'Complete your profile to see recommendations';

  @override
  String get viewAll => 'View All';

  @override
  String get latestUpdates => 'Latest updates';

  @override
  String get tipOfTheDay => 'Tip of the day';

  @override
  String get askAi => 'Ask AI';

  @override
  String get searchPlaceholder => 'Search schemes, benefits or ask anything...';

  @override
  String get homeSearchHint => 'Search schemes';

  @override
  String get homeAskSaarthi => 'Ask Saarthi';

  @override
  String get filter => 'Filter';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navSaved => 'Saved';

  @override
  String get navProfile => 'Profile';

  @override
  String get quickPillPmegp => 'Search PMEGP';

  @override
  String get quickPillStartup => 'Search Startup India';

  @override
  String get quickPillLoans => 'Search MSME Loans';

  @override
  String get quickPillWomen => 'Search Women Entrepreneur Schemes';

  @override
  String get quickPillAscend => 'Search ASCEND Workshops';

  @override
  String get carouselTitleApplicationsClosingSoon =>
      'Applications Closing Soon';

  @override
  String get carouselSubPmegpDaysLeft => 'PMEGP · 2 days left';

  @override
  String get carouselTitlePmegpClosing => 'PMEGP (Closing in 5 Days)';

  @override
  String get carouselBadgeAlert => 'Alert';

  @override
  String get carouselTitleNewScheme => 'New Scheme';

  @override
  String get carouselSubTnExport => 'TN Export Promotion Scheme';

  @override
  String get carouselBadgeNewScheme => 'New Scheme';

  @override
  String get carouselTitleImportantUpdate => 'Important Update';

  @override
  String get carouselSubUdyamProcess => 'UDYAM registration process updated';

  @override
  String get carouselBadgeNotify => 'Notify';

  @override
  String get subsidiesGrantsGovtSchemes =>
      'Subsidies, grants & government schemes';

  @override
  String get loansCreditSupportFundingOptions =>
      'Loans, credit support & funding options';

  @override
  String get taxBenefitsGstSupportCompliance =>
      'Tax benefits, GST support & compliance';

  @override
  String get exportIncentivesFinanceMarketSupport =>
      'Export incentives, finance & market support';

  @override
  String get invoiceDiscountingWorkingCapital =>
      'Invoice discounting & working capital solutions';

  @override
  String get csrProgramsIncubatorsClusterSupport =>
      'CSR programs, incubators & cluster support';

  @override
  String get centralStateDistrictGovtStructure =>
      'Central, State & District government structure';

  @override
  String get sidbiNsicDicKvicMoreOrganizations =>
      'SIDBI, NSIC, DIC, KVIC & more organizations';

  @override
  String get tipOfTheDayContent =>
      'Women Entrepreneurs may receive additional subsidy under PMEGP.';

  @override
  String get tagNewScheme => 'New Scheme';

  @override
  String get tagUpdate => 'Update';

  @override
  String get tagReminder => 'Reminder';

  @override
  String get tagAlert => 'Alert';

  @override
  String get fallbackLatestUpdateTitle =>
      'Fisheries and Aquaculture Infra Development Fund Scheme Launched';

  @override
  String get time2DaysAgo => '2 days ago';

  @override
  String get searchTitle => 'Search';

  @override
  String get trySearchPrefix => 'Try:';

  @override
  String get quickFiltersHeader => 'Quick Filters';

  @override
  String get sortByPrefix => 'Sort by:';

  @override
  String get sortMatchPercent => 'Match %';

  @override
  String get sortNameAsc => 'Scheme Name (A-Z)';

  @override
  String get sortNameDesc => 'Scheme Name (Z-A)';

  @override
  String get browseCategories => 'Browse categories';

  @override
  String get forMe => 'For me';

  @override
  String get activeBadge => 'Active';

  @override
  String get calculatingMatches => 'Finding matches';

  @override
  String schemesMatchProfile(Object count) {
    return '$count schemes match your profile';
  }

  @override
  String noSchemesFound(Object query) {
    return 'No schemes found for \"$query\"';
  }

  @override
  String get tryDifferentKeyword =>
      'Try a different keyword or browse categories.';

  @override
  String searchDidYouMean(Object suggestion) {
    return 'Did you mean \"$suggestion\"?';
  }

  @override
  String resultsFor(Object count, Object query) {
    return '$count results for \"$query\"';
  }

  @override
  String matchScorePercent(Object percent) {
    return '$percent% Match';
  }

  @override
  String get filterAll => 'All';

  @override
  String get filterCentral => 'Central';

  @override
  String get filterState => 'State';

  @override
  String get filterLoan => 'Loan';

  @override
  String get filterUdyam => 'Udyam';

  @override
  String get filterStartup => 'Startup';

  @override
  String get filterSubsidy => 'Subsidy';

  @override
  String get filterCollateralFree => 'Collateral-Free';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get browseByCategories => 'Browse by Categories';

  @override
  String get featuredCollections => 'Featured Collections';

  @override
  String get browseByMinistry => 'Browse by Ministry';

  @override
  String get browseByState => 'Browse by State';

  @override
  String get smartAssessment => 'Smart Assessment';

  @override
  String get viewAllCategories => 'View All Categories';

  @override
  String schemeCountFormat(Object count) {
    return '$count Schemes';
  }

  @override
  String get exploreTopCuratedCollections => 'Explore top curated collections';

  @override
  String get schemesByGovernmentMinistries =>
      'Schemes by Government Ministries';

  @override
  String get schemesByStatesAndUnionTerritories =>
      'Schemes by States & Union Territories';

  @override
  String get personalizedRecommendationMatches =>
      'Personalized recommendation matches';

  @override
  String get savedTitle => 'Saved schemes';

  @override
  String allSavedTabFormat(Object count) {
    return 'All saved ($count)';
  }

  @override
  String get recentlyViewedTab => 'Recently viewed';

  @override
  String get loginChecklistTerms => 'Read the Terms of Use';

  @override
  String get loginChecklistPrivacy => 'Read the Privacy Policy';

  @override
  String get loginChecklistAgree => 'Agree to continue';

  @override
  String get loginOpeningGoogle => 'Opening Google…';

  @override
  String get loginCompletingSignIn => 'Signing you in…';

  @override
  String get betaGatePasswordLabel => 'Beta password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String notificationsUnreadCount(Object n) {
    return '$n unread';
  }

  @override
  String get quickPillPmegpQuery => 'PMEGP';

  @override
  String get quickPillStartupQuery => 'Startup';

  @override
  String get quickPillLoansQuery => 'Loans';

  @override
  String get quickPillWomenQuery => 'Women';

  @override
  String get quickPillAscendQuery => 'ASCEND';

  @override
  String get homeRecommendedEmptyTitle =>
      'Complete your profile to see schemes for you';

  @override
  String get homeRecommendedEmptyBody =>
      'Add a few details and we will show schemes you may be eligible for.';

  @override
  String get completeProfileCta => 'Complete profile';

  @override
  String get saveSchemeTooltip => 'Save scheme';

  @override
  String get removeSavedTooltip => 'Remove from saved';

  @override
  String get copyLinkTooltip => 'Copy link';

  @override
  String get shareSchemeTooltip => 'Copy scheme details';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get forMeTooltip =>
      'Show only schemes you are eligible for (uses your profile)';

  @override
  String get sortBestMatchNeedsProfile => 'Complete your profile to use this';

  @override
  String get recentlyViewedEmptyTitle => 'Nothing viewed yet';

  @override
  String get recentlyViewedEmptyDesc => 'Schemes you open will appear here.';

  @override
  String get browseSchemes => 'Browse schemes';

  @override
  String get schemeRemovedToast => 'Removed from saved';

  @override
  String get undo => 'Undo';

  @override
  String get moreOptions => 'More options';

  @override
  String get applyUnavailableHint => 'No official application link yet';

  @override
  String get assistedChooseOne => 'Choose one option to continue';

  @override
  String get ageIncrease => 'Increase age';

  @override
  String get ageDecrease => 'Decrease age';

  @override
  String get changeProfilePhoto => 'Change profile photo';

  @override
  String get notifEmptyBody =>
      'New scheme updates and reminders will show up here.';

  @override
  String get aboutTagline =>
      'Government Scheme Discovery & Eligibility Platform';

  @override
  String get aboutDescription =>
      'MSS is an intelligent digital platform designed to bridge the awareness gap and simplify the discovery, eligibility matching, and application process for Central and State Government schemes for Indian entrepreneurs, women, farmers, and students.';

  @override
  String get aboutCreatedBy => 'Developed in collaboration with:';

  @override
  String get sarvamPromptDocuments => 'Which documents do I need?';

  @override
  String get sarvamPromptEligibility => 'Am I eligible for a loan?';

  @override
  String get noStatesMatch => 'No states match your search';

  @override
  String get homeRecommendationsNoMatches =>
      'No matches yet — try Search or Discover';

  @override
  String get noSavedSchemes => 'No saved schemes yet';

  @override
  String get noSavedSchemesDesc =>
      'Save a scheme while browsing and it stays here, even offline';

  @override
  String savedSubtitleCountFormat(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count schemes saved',
      one: '1 scheme saved',
    );
    return '$_temp0';
  }

  @override
  String get savedRecentlyViewedEmptyTitle => 'No schemes viewed yet';

  @override
  String get savedRecentlyViewedEmptyDesc => 'Schemes you open appear here';

  @override
  String get manageSaved => 'Manage';

  @override
  String get doneManaging => 'Done';

  @override
  String get clearAllSaved => 'Clear All';

  @override
  String get schemeRemovedSnackbar => 'Scheme removed from saved list';

  @override
  String get confirmClearSavedTitle => 'Clear Saved Schemes';

  @override
  String get confirmClearSavedMsg =>
      'Are you sure you want to remove all saved schemes?';

  @override
  String get profileSettingsTitle => 'Settings';

  @override
  String get profileGroupHeader => 'Profile';

  @override
  String get completeProfileTitle => 'Complete Profile';

  @override
  String profileCompletionFormat(Object percent) {
    return '$percent% completed';
  }

  @override
  String get preferencesGroupHeader => 'Preferences';

  @override
  String get languageSetting => 'Language';

  @override
  String get navigationModeSetting => 'Navigation Mode';

  @override
  String get navigationModeRegular => 'Regular';

  @override
  String get navigationModeCompanion => 'Companion';

  @override
  String get notificationsGroupHeader => 'Notifications';

  @override
  String get pushNotificationsSetting => 'Push Notifications';

  @override
  String get notificationsEnabled => 'Notifications enabled';

  @override
  String get notificationsDisabled => 'Notifications disabled';

  @override
  String get securityPrivacyGroupHeader => 'Security & Privacy';

  @override
  String get privacyPolicySetting => 'Privacy Policy';

  @override
  String get privacyPolicyContent =>
      'Your privacy is important to us. All personal data is encrypted and saved locally on this device.';

  @override
  String get termsConditionsSetting => 'Terms & Conditions';

  @override
  String get termsConditionsContent =>
      'By using MSS, you agree to our terms of service. All scheme information is aggregated from official government portals.';

  @override
  String get deleteAccountSetting => 'Delete Account';

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountMsg =>
      'Your account will be deleted and you will be signed out. Your data is kept for 30 days, so you can sign in again within 30 days to reactivate it. After that, all your saved profiles, bookmarks and answers are permanently deleted.';

  @override
  String get deleteButton => 'Delete';

  @override
  String get accountDeletedTitle => 'Account deleted';

  @override
  String accountDeletedMsg(String date) {
    return 'Your account has been deleted and you have been signed out. Your data will not be deleted for 30 days (until $date). To reactivate your account, just sign in again before then.';
  }

  @override
  String get accountDeletedNowMsg =>
      'Your account has been permanently deleted.';

  @override
  String get accountRestoreTitle => 'Reactivate your account?';

  @override
  String accountRestoreMsg(String date) {
    return 'You deleted this account. Your data is kept until $date. Reactivate it to continue with your saved profile and schemes.';
  }

  @override
  String get accountRestoreConfirm => 'Reactivate';

  @override
  String get accountRestoreCancel => 'Not now';

  @override
  String get accountRestoredToast =>
      'Welcome back! Your account is active again.';

  @override
  String get accountRestoreFailed =>
      'Could not reactivate your account. Please sign in again.';

  @override
  String get supportGroupHeader => 'Support';

  @override
  String get helpFaqSetting => 'Help & FAQ';

  @override
  String get contactUsSetting => 'Contact Us';

  @override
  String get logoutButton => 'Logout';

  @override
  String get confirmLogoutTitle => 'Confirm Logout';

  @override
  String get confirmLogoutMsg => 'Are you sure you want to log out from MSS?';

  @override
  String get dialogDone => 'Done';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileVerified => 'Profile complete';

  @override
  String get profileIncomplete => 'Incomplete';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get userInformation => 'User Information';

  @override
  String get eligibilityProfessionalDetails =>
      'Eligibility & Professional Details';

  @override
  String get businessInformation => 'Business Information';

  @override
  String get labelFullName => 'Full Name';

  @override
  String get labelAge => 'Age';

  @override
  String get labelGender => 'Gender';

  @override
  String get labelLocation => 'Location';

  @override
  String get labelEducationLevel => 'Education Level';

  @override
  String get labelEmployment => 'Employment';

  @override
  String get labelCommunityCategory => 'Community Category';

  @override
  String get labelAnnualIncome => 'Annual Income';

  @override
  String get labelDifferentlyAbled => 'Differently Abled';

  @override
  String get labelExServiceman => 'Ex-Serviceman / Veteran';

  @override
  String get labelBusinessStage => 'Business Stage';

  @override
  String get labelIndustry => 'Industry';

  @override
  String get labelFundingRequired => 'Funding Required';

  @override
  String get labelRegNumbers => 'Reg. Numbers';

  @override
  String get subSavedSchemes => 'View your bookmarked schemes';

  @override
  String get subLanguage => 'Choose your preferred language';

  @override
  String get subSettings => 'Manage app preferences';

  @override
  String get subPrivacy => 'Privacy policy and data settings';

  @override
  String get subHelpSupport => 'Get help and contact support';

  @override
  String get aboutTitle => 'About';

  @override
  String get subAbout => 'About MSS app';

  @override
  String get subLogout => 'Logout from your account';

  @override
  String get aboutAppDescription =>
      'MSS is an intelligent digital platform to discover, verify eligibility, and access Central and State Government schemes across India.';

  @override
  String get profilePhotoTitle => 'Profile Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get empStudent => 'Student';

  @override
  String get empFarmer => 'Farmer';

  @override
  String get empSalaried => 'Salaried';

  @override
  String get empSelfEmployed => 'Self-Employed';

  @override
  String get empUnemployed => 'Unemployed';

  @override
  String get empRetired => 'Retired';

  @override
  String get commGeneral => 'General';

  @override
  String get commObc => 'OBC';

  @override
  String get commEws => 'EWS';

  @override
  String get commSc => 'SC';

  @override
  String get commSt => 'ST';

  @override
  String get commOthers => 'Others';

  @override
  String get incUnder1_5 => 'Under ₹1.5 Lakhs';

  @override
  String get inc1_5To3 => '₹1.5 Lakhs - ₹3 Lakhs';

  @override
  String get inc3To5 => '₹3 Lakhs - ₹5 Lakhs';

  @override
  String get inc5To8 => '₹5 Lakhs - ₹8 Lakhs';

  @override
  String get incAbove8 => 'Above ₹8 Lakhs';

  @override
  String get valYes => 'Yes';

  @override
  String get valNo => 'No';

  @override
  String get valNone => 'None';

  @override
  String get schemeDetailsTitle => 'Scheme details';

  @override
  String get tabOverview => 'Overview';

  @override
  String get tabBenefits => 'Benefits';

  @override
  String get tabEligibility => 'Eligibility';

  @override
  String get tabDocuments => 'Documents';

  @override
  String get tabServices => 'Services';

  @override
  String get tabProcess => 'Process';

  @override
  String get schemeAtAGlance => 'Scheme at a glance';

  @override
  String get benefitsDetails => 'Benefits';

  @override
  String get eligibilityCriteria => 'Who can apply';

  @override
  String get requiredDocuments => 'Documents you need';

  @override
  String get requiredServices => 'Services you need';

  @override
  String get applicationProcessHeader => 'How to apply';

  @override
  String get officialInformation => 'Official scheme information';

  @override
  String lastUpdatedFormat(Object date) {
    return 'Last updated: $date';
  }

  @override
  String get sourceButton => 'Source';

  @override
  String get applyNowButton => 'Apply now';

  @override
  String get saveSchemeButton => 'Save scheme';

  @override
  String get savedSchemeButton => 'Saved';

  @override
  String get noVerifiedLink => 'No verified official link is available.';

  @override
  String get couldNotOpenWebsite => 'Could not open the official website.';

  @override
  String get noDocumentsPublished =>
      'No document list is published for this scheme. Check the official source before applying.';

  @override
  String get noServicesRequiredMsg =>
      'No separate service requirement is listed for this scheme.';

  @override
  String get getDocumentOnline => 'Get it online';

  @override
  String issuedByFormat(Object authority) {
    return 'Issued by: $authority';
  }

  @override
  String estimatedCostFormat(Object cost) {
    return 'Estimated cost: $cost';
  }

  @override
  String get verificationNote => 'Verification note';

  @override
  String get benefitSubsidy => 'Subsidy';

  @override
  String get benefitAmount => 'Amount';

  @override
  String get benefitMaximum => 'Maximum';

  @override
  String get benefitSupport => 'Support';

  @override
  String matchPercentageFormat(Object percent) {
    return '$percent% Match';
  }

  @override
  String get schemeCopiedToast => 'Scheme details copied to clipboard';

  @override
  String get highlyRelevant => 'Highly relevant';

  @override
  String levelSchemeFormat(Object level) {
    return '$level Scheme';
  }

  @override
  String get processStepSubtitle => 'Complete this phase to progress further.';

  @override
  String get badgeRequired => 'Required';

  @override
  String get badgeConditional => 'Conditional';

  @override
  String get filterDistrict => 'District';

  @override
  String get filterMinistry => 'Ministry';

  @override
  String get filterDepartment => 'Department';

  @override
  String get filterCategory => 'Category';

  @override
  String get labelCommunity => 'Community';

  @override
  String get labelOccupation => 'Occupation';

  @override
  String get labelEducation => 'Education';

  @override
  String get labelFirstGenGraduate => 'First Generation Graduate';

  @override
  String get labelDisability => 'Disability';

  @override
  String get filterSchemeStatus => 'Scheme Status';

  @override
  String get filterOnlineOffline => 'Online / Offline';

  @override
  String get filterCentralStateScheme => 'Central / State Scheme';

  @override
  String get filterClearAll => 'Clear All';

  @override
  String get validationSelectDob => 'Please select your Date of Birth';

  @override
  String get notifTooltipMarkRead => 'Mark selected as read';

  @override
  String get notifTooltipDeleteSelected => 'Delete selected';

  @override
  String get notifNewSchemeAlertsTitle => 'New Scheme Alerts';

  @override
  String get notifNewSchemeAlertsSubtitle =>
      'Stay informed about newly launched schemes';

  @override
  String get notifDeadlineRemindersTitle => 'Deadline Reminders';

  @override
  String get notifDeadlineRemindersSubtitle =>
      'Don\'t miss important application deadlines';

  @override
  String get notifGovtUpdatesTitle => 'Government Updates';

  @override
  String get notifGovtUpdatesSubtitle => 'Important announcements and updates';

  @override
  String get notifProfileRemindersTitle => 'Profile Completion Reminders';

  @override
  String get notifProfileRemindersSubtitle =>
      'Complete your profile to get better recommendations';

  @override
  String get navChooseYourPrefix => 'Choose Your ';

  @override
  String get navExperienceSuffix => 'Experience';

  @override
  String get navRegularNavigationTitle => 'Regular Navigation';

  @override
  String get navModeRegularSubtitle =>
      'Browse and explore the app independently.';

  @override
  String get navAiCompanionTitle => 'AI Companion';

  @override
  String get navModeCompanionSubtitle => 'Let your AI guide you step by step.';

  @override
  String get navSwitchAnytimeTitle => 'Switch Anytime';

  @override
  String get navSelectStyleSubtitle =>
      'Select the navigation style that best suits you.';

  @override
  String get navContinueButton => 'Continue';

  @override
  String get navChipFastSimple => 'Fast & Simple';

  @override
  String get navChipTraditionalUi => 'Traditional UI';

  @override
  String get navChipSelfPaced => 'Self-paced browsing';

  @override
  String get navChipAiAnytime => 'AI available anytime';

  @override
  String get navChipVoiceFirst => 'Voice-first experience';

  @override
  String get navChipPersonalized => 'Personalized guidance';

  @override
  String get navChipSmartRecs => 'Smart recommendations';

  @override
  String get navChipExplainsScreens => 'Explains every screen';

  @override
  String get filterTitle => 'Filters';

  @override
  String get filterButton => 'Filter';

  @override
  String filterUseMyProfile(Object state) {
    return 'Use my profile ($state)';
  }

  @override
  String get filterGroupCoverage => 'Coverage';

  @override
  String get filterGroupOffers => 'What it offers';

  @override
  String get filterGroupFor => 'For';

  @override
  String get filterCoverageNationwide => 'Nationwide';

  @override
  String filterShowSchemes(Object count) {
    return 'Show $count schemes';
  }

  @override
  String get filterTypeLoans => 'Loans & credit';

  @override
  String get filterTypeSubsidies => 'Subsidies';

  @override
  String get filterTypeGrants => 'Grants & equity';

  @override
  String get filterTypeGuarantee => 'Guarantee';

  @override
  String get filterTypeTraining => 'Training';

  @override
  String get filterTypeMarket => 'Market & export';

  @override
  String get filterTypeInfra => 'Infrastructure';

  @override
  String get filterBenWomen => 'Women';

  @override
  String get filterBenSc => 'SC';

  @override
  String get filterBenSt => 'ST';

  @override
  String get filterBenDifferentlyAbled => 'Differently-abled';

  @override
  String get filterBenTransgender => 'Transgender';

  @override
  String get filterBenMinority => 'Minority';

  @override
  String get filterBenExServicemen => 'Ex-servicemen';

  @override
  String get sortRelevance => 'Relevance';

  @override
  String get sortBestMatch => 'Best match for me';

  @override
  String get sortSchemeNameAz => 'Scheme name (A-Z)';

  @override
  String get settingsRegularSubtitle =>
      'Traditional clean list and tab view layout';

  @override
  String get settingsCompanionTitle => 'AI Companion (Saarthi)';

  @override
  String get settingsCompanionSubtitle =>
      'Voice-first AI guided conversational view';

  @override
  String get navSwitchAnytimeDesc =>
      'You can change your navigation mode later from Settings.';

  @override
  String get helpContactEmailLabel => 'Contact Email Address';

  @override
  String get helpContactEmailHint => 'Enter your email for follow-up';

  @override
  String get helpDescriptionLabel => 'Description';

  @override
  String get helpDescriptionHint => 'Describe the issue in detail...';

  @override
  String get helpSuggestionsLabel => 'Your suggestions';

  @override
  String get helpSuggestionsHint => 'What can we do better?';

  @override
  String get companionVoiceUnavailableRetry =>
      'Voice service is unavailable. Tap retry.';

  @override
  String get companionSignInRetryVoice =>
      'Please sign in again, then retry voice.';

  @override
  String get companionCheckInternetRetryVoice =>
      'Check your internet, then retry voice.';

  @override
  String get companionVoiceConnectFailedRetry =>
      'Voice service could not connect. Tap retry.';

  @override
  String get companionGenericErrorRetry =>
      'An error occurred. Please try again.';

  @override
  String get companionConnectionNeedsAttention => 'Connection needs attention';

  @override
  String get companionConnectingShort => 'Connecting';

  @override
  String get companionListeningToYou => 'Listening to you';

  @override
  String get companionCheckingYourDetails => 'Checking your details';

  @override
  String get companionSpeakingNow => 'Speaking now';

  @override
  String get companionReadyToHelp => 'Ready to help';

  @override
  String get companionVoiceConnected => 'Voice connected';

  @override
  String get companionVoiceOffline => 'Voice offline';

  @override
  String get companionIntroPrefix => 'I\'m';

  @override
  String get companionIntroSuffix => ', your AI companion for\nMSME success.';

  @override
  String get companionEmptyStateHint =>
      'Tell me what support you need. I will ask one detail at a time.';

  @override
  String get companionScrollToLatest => 'Latest';

  @override
  String get companionSpeakingBadge => 'Speaking';

  @override
  String get companionRankedResultsCaption =>
      'Ranked from the details you shared. Final eligibility is confirmed by the department.';

  @override
  String get companionReviewMatch => 'Review match';

  @override
  String get companionOfficialSourceChecked => 'Official source checked';

  @override
  String companionOfficialSourceCheckedConfidence(Object confidence) {
    return 'Official source checked · $confidence confidence';
  }

  @override
  String get companionVerifyWithDepartment => 'Verify with the department';

  @override
  String get companionViewEligibility => 'View eligibility';

  @override
  String companionYouTimestampLabel(Object time) {
    return 'You  $time';
  }

  @override
  String companionAiTimestampLabel(Object time) {
    return 'MSS Saarthi  $time';
  }

  @override
  String get companionAskAnything => 'Ask Saarthi anything...';

  @override
  String get companionTapToSpeakHint => 'Tap below and speak your question';

  @override
  String get companionRetryVoice => 'Retry voice';

  @override
  String get companionSecureLiveSession => 'Secure live voice session';

  @override
  String get companionLiveConnectionRequired =>
      'Live voice connection required';

  @override
  String get companionStartSpeakingSemantic => 'Start speaking to Saarthi';

  @override
  String get companionTapToSpeak => 'Tap to speak';

  @override
  String get companionStop => 'Stop';

  @override
  String get companionInterrupt => 'Interrupt';

  @override
  String get companionSpeak => 'Speak';

  @override
  String get companionEnd => 'End';

  @override
  String get companionVoiceNotConnected => 'Voice is not connected';

  @override
  String get companionConnectingSecurely => 'Connecting securely';

  @override
  String get companionFindingBestMatch => 'Finding the best match';

  @override
  String get companionSaarthiIsSpeaking => 'Saarthi is speaking';

  @override
  String get companionReadyShort => 'Ready';

  @override
  String get welcomeMeetPrefix => 'Meet';

  @override
  String get welcomeIntroLine1 => 'I\'m Saarthi, your smart assistant.';

  @override
  String get welcomeIntroLine2 =>
      'I\'ll help you discover the right schemes, explain everything simply, and guide you at every step.';

  @override
  String get welcomeSectionHeader => 'Saarthi can help you with';

  @override
  String get welcomeFeatureTalkNaturally => 'Talk Naturally';

  @override
  String get welcomeFeatureFindSchemes => 'Find Right Schemes';

  @override
  String get welcomeFeatureBusinessRoadmap => 'Business Roadmap';

  @override
  String get welcomeFeatureApplicationSupport => 'Application Support';

  @override
  String get welcomeChooseLanguage => 'Choose Language';

  @override
  String get welcomeChooseLanguageSubtitle =>
      'Choose your preferred language so Saarthi can talk to you better.';

  @override
  String get welcomeVoiceLabel => 'Voice';

  @override
  String get welcomeVoiceNatural => 'Natural';

  @override
  String get welcomeVoiceClear => 'Clear';

  @override
  String get welcomePreviewVoiceTooltip => 'Preview in English and Tamil';

  @override
  String get welcomeChangeAnytimeNote =>
      'You can change this anytime in settings.';

  @override
  String get welcomeLetsBegin => 'Let\'s Begin';

  @override
  String get voiceLanguageAuto => 'Auto';

  @override
  String get voiceStatusSpeaking => 'Speaking...';

  @override
  String get voiceStatusListening => 'Listening...';

  @override
  String get voiceStatusProcessing => 'Processing...';

  @override
  String get voiceStatusUnderstanding => 'Understanding...';

  @override
  String get voiceStatusOneQuestion => 'One question';

  @override
  String get voiceStatusMatchesFound => 'Matches found';

  @override
  String get voiceStatusNeedsMoreDetail => 'Needs more detail';

  @override
  String get voiceStatusFinding => 'Finding...';

  @override
  String voiceStatusFoundCount(Object count) {
    return 'Found $count';
  }

  @override
  String get voiceRecommendedBySaarthiReason =>
      'Recommended by Saarthi from the verified catalog';

  @override
  String get voiceRecognitionUnavailable =>
      'Voice recognition is not available on this device.';

  @override
  String get voiceRecognitionStartFailed =>
      'Voice recognition could not start. Please try again.';

  @override
  String get voiceSearchFailed =>
      'I could not search right now. Please try again.';

  @override
  String get voiceUseValue => 'Use value';

  @override
  String get voiceReviewProfileUpdates => 'Review profile updates';

  @override
  String get voiceKeepSessionOnly => 'Keep session only';

  @override
  String get voiceSaveConfirmed => 'Save confirmed';

  @override
  String get voiceProfileSavedMessage =>
      'Confirmed details saved to your profile.';

  @override
  String get voiceCloudDisclosure =>
      'Record a request, review its transcription, then send it to the assistant. Audio is uploaded to Sarvam for transcription.';

  @override
  String get voiceNoConfidentMatch =>
      'No confident scheme match yet. Tell me a little more about your situation.';

  @override
  String get voiceHeaderTalkToSaarthi => 'Talk to Saarthi';

  @override
  String get voiceUnmute => 'Unmute';

  @override
  String get voiceMute => 'Mute';

  @override
  String get voiceCancelAssistantTooltip => 'Cancel assistant';

  @override
  String get voiceTellMeNaturally => 'Tell me your situation naturally...';

  @override
  String get voiceSuggestionBusinessLoans => 'Business loans';

  @override
  String get voiceSuggestionCollegeScholarship => 'College scholarship';

  @override
  String get voiceSuggestionFarmerSubsidy => 'Farmer subsidy';

  @override
  String get voiceStopListeningSemantic => 'Stop listening';

  @override
  String get voiceStartListeningSemantic => 'Start listening';

  @override
  String get voiceTypeToSaarthiHint => 'Type to Saarthi...';

  @override
  String get voiceSendMessageTooltip => 'Send message';

  @override
  String voiceLanguageSemantic(Object language) {
    return 'Voice language $language';
  }

  @override
  String get voiceWhatIUnderstood => 'What I understood';

  @override
  String get voiceRepeatQuestionTooltip => 'Repeat question';

  @override
  String get voiceSpeechOutputUnavailable =>
      'Speech output is unavailable; tap the microphone to answer.';

  @override
  String get voiceSchemesSuitedToSituation =>
      'Schemes suited to your situation';

  @override
  String get voiceViewAllResults => 'View all';

  @override
  String get voiceReviewAndSaveDetails => 'Review and save confirmed details';

  @override
  String get voiceOpenOfficialSource => 'Open official source';

  @override
  String get voiceGroundingChecking => 'Checking official sources…';

  @override
  String voiceGroundingFoundSources(Object count) {
    return 'Grounded online · $count official source(s)';
  }

  @override
  String get voiceGroundingUnavailable =>
      'Offline · using private on-device knowledge';

  @override
  String get voiceGroundingNoSources =>
      'Official page unavailable · using the verified local catalog';

  @override
  String get voiceGroundingPrivacyNote =>
      'Only the topic and official links are checked. Your statement and profile stay on this device.';

  @override
  String get voiceCouldNotOpenSource => 'Could not open the official source.';

  @override
  String get voiceMatchStrong => 'Strong match';

  @override
  String get voiceMatchLikely => 'Likely match';

  @override
  String get voiceMatchNeedsConfirmation => 'Needs confirmation';

  @override
  String get voiceMatchNotSuitable => 'Not suitable';

  @override
  String get voiceMatchNoConfident => 'No confident match';

  @override
  String voiceWhyThisFits(Object reasons) {
    return 'Why this fits: $reasons';
  }

  @override
  String voiceStillConfirm(Object requirements) {
    return 'Still confirm: $requirements';
  }

  @override
  String get voiceSourceVerified => 'Current official source verified';

  @override
  String get voiceSourceUnverified =>
      'Uncertain or historical — verify before applying';

  @override
  String get voiceBestMatchingSchemes => 'Best matching schemes';

  @override
  String get voiceFactLabelState => 'State';

  @override
  String get voiceFactLabelSituation => 'Situation';

  @override
  String get voiceFactLabelMaritalStatus => 'Marital status';

  @override
  String get voiceFactLabelSector => 'Sector';

  @override
  String get voiceFactLabelFundingNeed => 'Funding need';

  @override
  String get voiceFactLabelLandholding => 'Landholding';

  @override
  String voiceFactConflictFormat(Object conflictingValue, Object value) {
    return '$value (profile: $conflictingValue)';
  }

  @override
  String get calcUdyamClassifierTitle => 'Udyam MSME Classifier';

  @override
  String get calcUdyamClassifierSub =>
      'Classify your business under official government guidelines.';

  @override
  String get calcInvestmentLabel => 'Investment in Plant & Machinery';

  @override
  String get calcInvestmentHelper =>
      'Enter original purchase value of machinery in Crores';

  @override
  String get calcTurnoverLabel => 'Annual Turnover';

  @override
  String get calcTurnoverHelper =>
      'Enter total revenue/sales of last financial year in Crores';

  @override
  String get calcClassificationResult => 'Classification Result';

  @override
  String get calcBtnCalculate => 'Calculate Classification';

  @override
  String get calcGstTitle => 'GST / Tax Calculator';

  @override
  String get calcGstSub =>
      'Calculate CGST + SGST or IGST, and the total invoice amount.';

  @override
  String get calcGstWithinState => 'Within state (CGST + SGST)';

  @override
  String get calcGstInterState => 'Inter-state (IGST)';

  @override
  String get calcBaseAmountLabel => 'Base Amount';

  @override
  String get calcBaseAmountHelper =>
      'Enter net value of goods or services before GST';

  @override
  String get calcGstRateLabel => 'GST Rate (%)';

  @override
  String get calcBasePrice => 'Base Price';

  @override
  String get calcTotalInvoice => 'Total Invoice';

  @override
  String get calcBtnCalculateTax => 'Calculate Tax';

  @override
  String get calcErrValidBaseAmount => 'Please enter a valid base amount';

  @override
  String get calcEmiTitle => 'Business Loan EMI Calculator';

  @override
  String get calcEmiSub => 'Calculate monthly payments for your business loan.';

  @override
  String get calcLoanAmountLabel => 'Loan Amount';

  @override
  String get calcLoanAmountHelper => 'Enter total business loan sum required';

  @override
  String get calcInterestRateLabel => 'Interest Rate (% p.a.)';

  @override
  String get calcTenureLabel => 'Tenure (Months)';

  @override
  String get calcBtnCalculateEmi => 'Calculate EMI';

  @override
  String get calcDpiitTitle => 'DPIIT Recognition Checklist';

  @override
  String get calcDpiitSub =>
      'Evaluate if your business qualifies as a startup under DPIIT rules.';

  @override
  String get calcValuationTitle => 'Seed Valuation Estimator';

  @override
  String get calcValuationSub =>
      'Calculate estimated seed stage valuation ranges based on MRR and growth.';

  @override
  String get calcDocChecklistTitle => 'Business Setup Document Checklist';

  @override
  String get calcDocChecklistSub =>
      'Essential documents for registering and operating a business in India.';

  @override
  String get discoverUtilitiesTitle => 'Business Utilities & Tools';

  @override
  String get utilUdyamTitle => 'Udyam Classifier';

  @override
  String get utilUdyamDesc => 'Check MSME tier';

  @override
  String get utilSubsidyTitle => 'Subsidy Estimator';

  @override
  String get utilSubsidyDesc => 'Machinery subsidies';

  @override
  String get utilGstTitle => 'GST Calculator';

  @override
  String get utilGstDesc => 'Compute GST invoice';

  @override
  String get utilEmiTitle => 'EMI Calculator';

  @override
  String get utilEmiDesc => 'Calculate loan EMIs';

  @override
  String get utilDpiitTitle => 'DPIIT Eligibility';

  @override
  String get utilDpiitDesc => 'Check startup criteria';

  @override
  String get utilValuationTitle => 'Valuation Estimator';

  @override
  String get utilValuationDesc => 'Seed valuation ranges';

  @override
  String get utilDocChecklistTitle => 'Doc Checklist';

  @override
  String get utilDocChecklistDesc => 'Business setup docs';

  @override
  String get notifToastSelectedRead => 'Selected notifications marked as read';

  @override
  String get notifToastSelectedDeleted => 'Selected notifications deleted';

  @override
  String get notifToastAllRead => 'All notifications marked as read';

  @override
  String get notifToastAllDeleted => 'All notifications deleted';

  @override
  String get notifToastFilterOpened => 'Filter options opened';

  @override
  String get retryVoice => 'Retry voice';

  @override
  String get chooseYourLanguage => 'Choose Your Language';

  @override
  String get languageSubtitle =>
      'Select your preferred language to explore government schemes in your language.';

  @override
  String get yourLanguageExperience => 'Your Language, Your Experience';

  @override
  String get changeAnytime => 'Change it anytime from Settings.';

  @override
  String get welcome => 'Welcome!';

  @override
  String get loginSubtitle =>
      'Login or sign up to discover and explore government schemes that empower you.';

  @override
  String get loginReviewTermsNotice =>
      'Please review the Terms of Use and Privacy Policy before continuing.';

  @override
  String get continueSecurely => 'Continue securely';

  @override
  String get googleAccountContinue =>
      'Use your Google account to sign in or create your MSS account.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get secureBrowserAuth =>
      'A secure browser window will open for authentication.';

  @override
  String get privacyNote => 'By continuing, you agree to our';

  @override
  String get terms => 'Terms of Service';

  @override
  String get and => 'and';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get skipLogin => 'Skip & Explore';

  @override
  String get demoMode => 'Demo mode — all features available';

  @override
  String get verifiedPlatform => 'Government Verified Platform';

  @override
  String get forIndia => 'For every Indian entrepreneur & citizen';

  @override
  String get basicDetailsSubtitle => 'Let\'s start with your basic details.';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get dateOfBirth => 'Date of Birth (DOB)';

  @override
  String get profileInfoNote =>
      'We\'ll use this information to personalize your MSS experience and keep you updated.';

  @override
  String get step1Of4 => '1/4 Complete';

  @override
  String get step2Of4 => '2/4 Complete';

  @override
  String get step3Of4 => '3/4 Complete';

  @override
  String get step4Of4 => '4/4 Complete';

  @override
  String get step1Of3 => '1/3 Complete';

  @override
  String get step2Of3 => '2/3 Complete';

  @override
  String get step3Of3 => '3/3 Complete';

  @override
  String get whereLocated => 'Where Are You Located?';

  @override
  String get locationSubtitle =>
      'We use your location to recommend schemes available in your area.';

  @override
  String get useCurrentLocation => 'Use Current Location';

  @override
  String get fetchingCoordinates => 'Fetching coordinates...';

  @override
  String get getLocationAuto => 'Get your current location automatically';

  @override
  String get or => 'OR';

  @override
  String get doorNoStreet => 'Door No / Flat / House No / Street';

  @override
  String get areaLocality => 'Area / Locality';

  @override
  String get cityDistrict => 'City / District';

  @override
  String get state => 'State';

  @override
  String get pincode => 'Pincode';

  @override
  String get fullAddress => 'Full Address';

  @override
  String get cityTown => 'City / Town';

  @override
  String get district => 'District';

  @override
  String get profileErrEnterAge => 'Please enter your age';

  @override
  String get profileErrValidAge => 'Please enter a valid age (1-120)';

  @override
  String get dataProcessingConsent =>
      'I consent to MSS collecting and processing my information to create my profile and provide personalized Government scheme recommendations.';

  @override
  String get privacyAndData => 'Privacy & Data';

  @override
  String get readHowDataUsed => 'Read how your data is used →';

  @override
  String get pleaseConsentToContinue => 'Please consent to continue';

  @override
  String get tellUsAboutYou => 'Tell Us About You';

  @override
  String get aboutYouSubtitle => 'Choose the option that best describes you.';

  @override
  String get studentSubtitle =>
      'Looking for learning, innovation and startup opportunities.';

  @override
  String get aspiringEntrepreneur => 'Entrepreneur';

  @override
  String get aspiringEntrepreneurSubtitle =>
      'I have an idea and want to start a business.';

  @override
  String get existingBusiness => 'Business';

  @override
  String get existingBusinessSubtitle =>
      'I already run a registered or unregistered business.';

  @override
  String get msmeOwner => 'MSME Owner';

  @override
  String get msmeOwnerSubtitle => 'I own a micro, small or medium enterprise.';

  @override
  String get farmerSubtitle => 'I am involved in farming or agriculture.';

  @override
  String get artisanShg => 'Artisan / SHG Member';

  @override
  String get artisanShgSubtitle =>
      'I am an artisan or part of a Self Help Group.';

  @override
  String get overwriteDetails => 'Overwrite details?';

  @override
  String get overwriteMessage =>
      'You have already entered some address details. Do you want to overwrite them with your current location?';

  @override
  String get overwrite => 'Overwrite';

  @override
  String get profileSaved => 'Profile saved successfully!';

  @override
  String get failedFetchLocation => 'Failed to fetch location';

  @override
  String get usingDefaultLocation =>
      'Using default location (Chennai) due to GPS/permission constraints.';

  @override
  String get locationFetched => 'Location fetched and populated successfully!';

  @override
  String get saveProfile => 'Save Profile';

  @override
  String get updateProfile => 'Update Profile';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get locationInfo => 'Location Details';

  @override
  String get businessInfo => 'Business Information';

  @override
  String get income => 'Annual Income';

  @override
  String get community => 'Community / Category';

  @override
  String get employment => 'Employment Status';

  @override
  String get qualification => 'Qualification';

  @override
  String get veteran => 'Ex-Serviceman / Veteran';

  @override
  String get disability => 'Person with Disability';

  @override
  String get disabilityType => 'Disability Type';

  @override
  String get hasExistingBusiness => 'I have an existing business';

  @override
  String get businessStage => 'Business Stage';

  @override
  String get businessIndustry => 'Business Industry / Sector';

  @override
  String get fundingRequired => 'Funding Required';

  @override
  String get registrationNumbers => 'Registration Numbers (Udyam, GST, etc.)';

  @override
  String get checkEligibility => 'Check Eligibility';

  @override
  String get eligibilityDetails => 'Eligibility Details';

  @override
  String get eligibilitySubtitle =>
      'Helps us recommend 100% accurate schemes & subsidies for you.';

  @override
  String get firstGenGraduate => 'First-Generation Graduate';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get completeProfile => 'Complete Profile';

  @override
  String get profileSettingUp => 'Setting up your profile…';

  @override
  String get incomeNoIncome => 'No Income';

  @override
  String get incomeBelow15l => 'Below ₹1.5 Lakhs';

  @override
  String get income15l3l => '₹1.5L - ₹3 Lakhs';

  @override
  String get income3l6l => '₹3L - ₹6 Lakhs';

  @override
  String get income6l10l => '₹6L - ₹10 Lakhs';

  @override
  String get incomeAbove10l => 'Above ₹10 Lakhs';

  @override
  String get specialCategories => 'Special Status / Priority';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get retry => 'Retry';

  @override
  String get ok => 'OK';

  @override
  String get skip => 'Skip';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get select => 'Select';

  @override
  String get search => 'Search';

  @override
  String get close => 'Close';

  @override
  String get nameLabel => 'Name';

  @override
  String get dobLabel => 'Date of Birth';

  @override
  String get houseNo => 'House No.';

  @override
  String get street => 'Street';

  @override
  String get villageTown => 'Village / Town';

  @override
  String get useLocation => 'Use Location';

  @override
  String get locating => 'Locating...';

  @override
  String get salaried => 'Salaried';

  @override
  String get businessOwner => 'Business Owner';

  @override
  String get homemaker => 'Homemaker';

  @override
  String get retired => 'Retired';

  @override
  String get selfEmployed => 'Self-employed';

  @override
  String get undergraduate => 'Undergraduate';

  @override
  String get graduate => 'Graduate';

  @override
  String get postgraduate => 'Postgraduate';

  @override
  String get diploma => 'Diploma';

  @override
  String get higherSecondary => 'Higher Secondary';

  @override
  String get secondary => 'Secondary';

  @override
  String get primary => 'Primary';

  @override
  String get noFormal => 'No Formal Education';

  @override
  String get ideaStage => 'Idea Stage';

  @override
  String get earlyStage => 'Early Stage';

  @override
  String get growthStage => 'Growth Stage';

  @override
  String get established => 'Established';

  @override
  String get howCanIHelp => 'How can I help?';

  @override
  String get poweredBySarvamAi => 'Powered by Sarvam AI';

  @override
  String get sarvamPromptFindSchemes => 'Find schemes for me';

  @override
  String get sarvamPromptExplainMsmeLoans => 'Explain MSME loans';

  @override
  String get sarvamAskAboutSchemes =>
      'Ask about schemes, eligibility, or how to apply.';

  @override
  String get aiDisclaimerNotice =>
      'AI can make mistakes. Check details on the official scheme website.';

  @override
  String get sarvamInputHint => 'Ask Saarthi…';

  @override
  String get send => 'Send';

  @override
  String get sarvamCouldNotReach =>
      'Could not reach Saarthi. Please try again.';

  @override
  String get welcomePreviewVoice => 'Preview';

  @override
  String get welcomePreviewVoiceError =>
      'Unable to preview voice. Please check your audio settings.';

  @override
  String get welcomeSavePreferencesError =>
      'Unable to save preferences to the cloud. Please check your connection and try again.';

  @override
  String companionMatchPercent(Object percent) {
    return '$percent% match';
  }

  @override
  String get voiceNeedOneMoreDetail =>
      'I need one more detail to find a confident match.';

  @override
  String get voiceTellMeSituationFindSchemes =>
      'Tell me your situation. I’ll find relevant government schemes.';

  @override
  String get voiceSpeakerYou => 'You';

  @override
  String get voiceSpeakerAssistant => 'Assistant';

  @override
  String get voiceForYou => 'For you';

  @override
  String get voiceListenOrInterrupt => 'Listen, or tap below to interrupt';

  @override
  String get voiceSpeakNaturallyPause =>
      'Speak naturally, then pause when you are done';

  @override
  String get voiceReadyForNextQuestion => 'Ready for your next question';

  @override
  String get voiceDeviceNoiseControl => 'Device noise control';

  @override
  String get voiceConversation => 'Conversation';

  @override
  String get voiceRecommendedForYou => 'Recommended for you';

  @override
  String get updatingSoon => 'Updating Soon';

  @override
  String get updatingSoonCount => 'Updating Soon';

  @override
  String get gotIt => 'Got it';

  @override
  String comingSoonSchemesBody(Object name) {
    return 'Schemes under \"$name\" are currently being verified and will be updated soon. Stay tuned!';
  }

  @override
  String get allCategories => 'All Categories';

  @override
  String get allMinistries => 'All Ministries';

  @override
  String get allStatesAndUts => 'All States & UTs';

  @override
  String get searchCategoriesHint => 'Search categories...';

  @override
  String get catBusinessMsme => 'Business & MSME';

  @override
  String get catStartupIncubation => 'Startup & Incubation';

  @override
  String get catLoansCreditSupport => 'Loans & Credit Support';

  @override
  String get catWomenEntrepreneurship => 'Women Entrepreneurship';

  @override
  String get catFinanceBanking => 'Finance & Banking';

  @override
  String get catSkillDevelopment => 'Skill Development';

  @override
  String get catArtisanCraftsmen => 'Artisan & Craftsmen';

  @override
  String get catDigitalIndiaTech => 'Digital India & Tech';

  @override
  String get catStudentYouthStartups => 'Student & Youth Startups';

  @override
  String get catManufacturingIndustry => 'Manufacturing & Industry';

  @override
  String get catExportTradePromotion => 'Export & Trade Promotion';

  @override
  String get catAgricultureAllied => 'Agriculture & Allied';

  @override
  String get catRuralDevelopmentShg => 'Rural Development & SHG';

  @override
  String get catTechnologyInnovation => 'Technology & Innovation';

  @override
  String get catKhadiVillageIndustries => 'Khadi & Village Industries';

  @override
  String get catScStMinority => 'SC / ST & Minority';

  @override
  String get catGreenEnergyEnvironment => 'Green Energy & Environment';

  @override
  String get catHealthHealthcare => 'Health & Healthcare';

  @override
  String get catFoodProcessing => 'Food Processing';

  @override
  String get catEducationFellowship => 'Education & Fellowship';

  @override
  String get catInfrastructureLogistics => 'Infrastructure & Logistics';

  @override
  String get catSocialWelfareSupport => 'Social Welfare & Support';

  @override
  String get catRenewableEnergyEfficiency => 'Renewable & Energy Efficiency';

  @override
  String get msmeWhatTheUserGets => 'WHAT THE USER GETS';

  @override
  String get msmeInteractiveToolsActions => 'Interactive Tools & Actions';

  @override
  String get msmeInteractiveToolsDesc =>
      'Complete your profile or explore schemes with the search engine to get smart matching results.';

  @override
  String get msmeSearchSchemes => 'Search Schemes';

  @override
  String get msmeDelayedPaymentCalcTitle =>
      'Delayed Payment Interest Calculator';

  @override
  String get msmeDelayedPaymentCalcDesc =>
      'Under the MSMED Act Section 15/16, buyers must pay 3x the RBI Bank Rate as compound interest with monthly rests for delays exceeding 45 days.';

  @override
  String get msmeInvoiceAmountRupees => 'Invoice Amount (₹)';

  @override
  String get msmeDaysDelayedPost45 => 'Days Delayed (Post 45d)';

  @override
  String get msmeInterestRate3xBankRate => 'Interest Rate (3x Bank Rate):';

  @override
  String get msmeCalculatedInterestLabel => 'Calculated Interest:';

  @override
  String get msmeTotalClaimableAmountLabel => 'Total Claimable Amount:';

  @override
  String msmeStepNumber(Object number) {
    return 'Step $number';
  }

  @override
  String get msmeSearchSupportInstitutions => 'Search Support Institutions';

  @override
  String get msmeSearchInstitutionsHint => 'Search SIDBI, NSIC, DIC...';

  @override
  String get msmeRoleLabel => 'Role';

  @override
  String get msmeKeyServicesLabel => 'Key Services';

  @override
  String get msmeTopSchemesLabel => 'Top Schemes';

  @override
  String get msmeMainFeaturesInside => 'Main Features Inside';

  @override
  String get msmeFeatureSchemes1 =>
      'Personalized schemes matched to business profile';

  @override
  String get msmeFeatureSchemes2 => 'Central vs. State schemes filter';

  @override
  String get msmeFeatureSchemes3 => 'Comprehensive eligibility checker';

  @override
  String get msmeFeatureSchemes4 => 'Search by scheme categories';

  @override
  String get msmeFeatureSchemes5 =>
      'Capital subsidies, grants & interest subventions';

  @override
  String get msmeFeatureSchemes6 => 'Lists of required documents & checklists';

  @override
  String get msmeFeatureSchemes7 =>
      'Clear, step-by-step application guidelines';

  @override
  String get msmeFeatureSchemes8 => 'Save schemes for later';

  @override
  String get msmeFeatureFinance1 =>
      'Collateral-free business term loans & working capital';

  @override
  String get msmeFeatureFinance2 =>
      'SIDBI specialized credit schemes for machinery & tools';

  @override
  String get msmeFeatureFinance3 =>
      'Credit Guarantees (CGTMSE) for collateral-free bank options';

  @override
  String get msmeFeatureFinance4 => 'Equipment & machinery financing models';

  @override
  String get msmeFeatureFinance5 =>
      'Detailed comparisons of loan interest rates';

  @override
  String get msmeFeatureFinance6 =>
      'Direct contact pathways to SIDBI & partner commercial banks';

  @override
  String get msmeFeatureFinance7 =>
      'SME IPO listing requirements (BSE SME & NSE Emerge)';

  @override
  String get msmeFeatureTaxGst1 => 'MSME Corporate Income-Tax benefits';

  @override
  String get msmeFeatureTaxGst2 =>
      'GST registration threshold limits (₹40/₹20 Lakhs exemptions)';

  @override
  String get msmeFeatureTaxGst3 =>
      'GST Composition Scheme parameters (1% tax, easier filings)';

  @override
  String get msmeFeatureTaxGst4 =>
      'Section 43B(h) Income Tax protection (45-day payment rule)';

  @override
  String get msmeFeatureTaxGst5 =>
      'Late payment interest claim calculator (3x Bank Rate)';

  @override
  String get msmeFeatureTaxGst6 =>
      'Export tax refunds & LUT (Letter of Undertaking) rules';

  @override
  String get msmeFeatureTaxGst7 => 'MSME Samadhaan portal recovery guidelines';

  @override
  String get msmeFeatureExport1 =>
      'Duty refund schemes (RoDTEP, RoSCTL) & Drawbacks';

  @override
  String get msmeFeatureExport2 =>
      'Pre-shipment & Post-shipment export credit financing';

  @override
  String get msmeFeatureExport3 =>
      'Interest subvention on foreign currency loans';

  @override
  String get msmeFeatureExport4 =>
      'ECGC credit risk insurance coverage policies';

  @override
  String get msmeFeatureExport5 =>
      'MDA & MAI schemes for foreign exhibition participation';

  @override
  String get msmeFeatureExport6 =>
      'Directory of Export Councils & DGFT field offices';

  @override
  String get msmeFeatureExport7 =>
      'HS Code classifications & AD Code registration guide';

  @override
  String get msmeFeatureTreds1 =>
      'Invoice Discounting multi-party platforms explainer';

  @override
  String get msmeFeatureTreds2 => 'Onboarding guidelines for MSME Sellers';

  @override
  String get msmeFeatureTreds3 =>
      'RXIL, M1xchange & Invoicemart registration steps';

  @override
  String get msmeFeatureTreds4 => 'Acceptance guidelines for Corporate Buyers';

  @override
  String get msmeFeatureTreds5 =>
      'Financier bidding flow (anonymized auction for best rates)';

  @override
  String get msmeFeatureTreds6 =>
      'Payment settlement pathways (T+1 credit cycles)';

  @override
  String get msmeFeatureTreds7 =>
      'Recourse vs. Non-recourse factoring definitions';

  @override
  String get msmeFeatureCsr1 =>
      'Corporate CSR-backed cluster development funding';

  @override
  String get msmeFeatureCsr2 =>
      'Access to corporate incubation grants for prototype support';

  @override
  String get msmeFeatureCsr3 =>
      'Specialized green-energy & waste-management cluster programs';

  @override
  String get msmeFeatureCsr4 =>
      'Skill development & technology upgrade programs';

  @override
  String get msmeFeatureCsr5 => 'List of CSR implementing agencies & NGOs';

  @override
  String get msmeFeatureCsr6 => 'Eligibility checklists & application pathways';

  @override
  String get msmeFeatureGovt1 =>
      'Ministry of MSME (Central Govt) policies & initiatives';

  @override
  String get msmeFeatureGovt2 =>
      'State Directorate of Industries / Dept of Commerce role';

  @override
  String get msmeFeatureGovt3 =>
      'District Industries Centre (DIC) local assistance offices';

  @override
  String get msmeFeatureGovt4 =>
      'Clear hierarchies: Central -> State -> District levels';

  @override
  String get msmeFeatureGovt5 =>
      'Key contact directories & nodal officer lists';

  @override
  String get msmeFeatureGovt6 =>
      'Authority-specific schemes (PMEGP vs State subsidies)';

  @override
  String get msmeFeatureInstitutions1 =>
      'SIDBI (Small Industries Development Bank of India) credit portals';

  @override
  String get msmeFeatureInstitutions2 =>
      'NSIC (National Small Industries Corporation) raw material support';

  @override
  String get msmeFeatureInstitutions3 =>
      'DIC (District Industries Centre) single-window registrations';

  @override
  String get msmeFeatureInstitutions4 =>
      'KVIC (Khadi and Village Industries Commission) rural projects';

  @override
  String get msmeFeatureInstitutions5 =>
      'TIIC, StartupTN, FaMeTN, SIPCOT regional service descriptions';

  @override
  String get msmeFeatureInstitutions6 =>
      'Program services catalog & contact application routes';

  @override
  String get msmeFeatureUdyam1 =>
      '100% Free & Paperless Instant Portal Registration';

  @override
  String get msmeFeatureUdyam2 =>
      'Lifetime Validity with QR Code e-Certificate';

  @override
  String get msmeFeatureUdyam3 =>
      'Automatic CGTMSE Collateral-Free Credit & TReDS Eligibility';

  @override
  String get msmeFeatureUdyam4 =>
      'Exemption from Earnest Money Deposit (EMD) in Govt Tenders';

  @override
  String get msmeFeatureUdyam5 =>
      'Eligible for 15% CLCSS Technology & Capital Subsidies';

  @override
  String get msmeFeatureUdyam6 =>
      'Concessional Electricity & Patent Registration Fee Waiver';

  @override
  String get croreSuffix => 'Cr';

  @override
  String get assessEduQ1 => 'What is your current level of education?';

  @override
  String get assessEduQ1Opt1 => 'Schooling (Up to 12th)';

  @override
  String get assessEduQ1Opt2 => 'Undergraduate';

  @override
  String get assessEduQ1Opt3 => 'Postgraduate';

  @override
  String get assessEduQ1Opt4 => 'Ph.D. & Research';

  @override
  String get assessEduQ2School =>
      'What class/grade are you currently enrolled in?';

  @override
  String get assessEduQ2SchoolOpt1 => 'Class 1 - 8 (Primary)';

  @override
  String get assessEduQ2SchoolOpt2 => 'Class 9 - 10 (Secondary)';

  @override
  String get assessEduQ2SchoolOpt3 => 'Class 11 - 12 (Higher Secondary)';

  @override
  String get assessEduQ2College => 'What is your primary stream of study?';

  @override
  String get assessEduQ2CollegeOpt1 => 'STEM (Science/Engineering/IT)';

  @override
  String get assessEduQ2CollegeOpt2 => 'Arts, Commerce & Humanities';

  @override
  String get assessEduQ2CollegeOpt3 => 'Medical & Nursing';

  @override
  String get assessEduQ2CollegeOpt4 => 'Agricultural Studies';

  @override
  String get assessEduQ2Research =>
      'What is your research specialization domain?';

  @override
  String get assessEduQ2ResearchOpt1 => 'STEM Research & Patents';

  @override
  String get assessEduQ2ResearchOpt2 => 'Humanities & Social Sciences';

  @override
  String get assessEduQ2ResearchOpt3 => 'Agricultural/Biological Sciences';

  @override
  String get assessEduQ3School =>
      'What type of aid is most important right now?';

  @override
  String get assessEduQ3SchoolOpt1 => 'Pre-matric Scholarship';

  @override
  String get assessEduQ3SchoolOpt2 => 'Free textbooks & uniforms';

  @override
  String get assessEduQ3SchoolOpt3 => 'Hostel accommodation subsidy';

  @override
  String get assessEduQ3College =>
      'Are you interested in a low-interest student education loan?';

  @override
  String get assessEduQ3CollegeOpt1 => 'Yes, need education loan';

  @override
  String get assessEduQ3CollegeOpt2 => 'No, seeking tuition scholarships only';

  @override
  String get assessEduQ3Research =>
      'Are you seeking a research fellowship or international study grant?';

  @override
  String get assessEduQ3ResearchOpt1 => 'National Fellowship grant';

  @override
  String get assessEduQ3ResearchOpt2 => 'International study allowance';

  @override
  String get assessEduQ3ResearchOpt3 => 'Merit publication awards';

  @override
  String get assessEduQ4Caste =>
      'What is your caste/social reservation category?';

  @override
  String get assessEduQ4CasteOpt1 => 'General';

  @override
  String get assessEduQ4CasteOpt2 => 'OBC';

  @override
  String get assessEduQ4CasteOpt3 => 'SC / ST';

  @override
  String get assessEduQ4CasteOpt4 => 'EWS / Minority';

  @override
  String get assessEduQ5Income =>
      'What is your family\'s annual household income?';

  @override
  String get assessEduQ5IncomeOpt1 => 'Under ₹2.5 Lakhs';

  @override
  String get assessEduQ5IncomeOpt2 => '₹2.5 Lakhs - ₹8 Lakhs';

  @override
  String get assessEduQ5IncomeOpt3 => 'Over ₹8 Lakhs';

  @override
  String get assessWomenQ1 => 'Who is the primary beneficiary of the scheme?';

  @override
  String get assessWomenQ1Opt1 => 'Pregnant or Lactating Mother';

  @override
  String get assessWomenQ1Opt2 => 'Girl Child (Parent applying)';

  @override
  String get assessWomenQ1Opt3 => 'Woman Entrepreneur';

  @override
  String get assessWomenQ1Opt4 => 'Single Woman / Widow in distress';

  @override
  String get assessWomenQ2Maternal => 'Is this your first or second pregnancy?';

  @override
  String get assessWomenQ2MaternalOpt1 => 'First pregnancy';

  @override
  String get assessWomenQ2MaternalOpt2 => 'Second pregnancy';

  @override
  String get assessWomenQ2MaternalOpt3 => 'More than two';

  @override
  String get assessWomenQ2Girl => 'What is the age of the girl child?';

  @override
  String get assessWomenQ2GirlOpt1 => 'Newborn (0 - 1 Year)';

  @override
  String get assessWomenQ2GirlOpt2 => 'Child (2 - 10 Years)';

  @override
  String get assessWomenQ2GirlOpt3 => 'Adolescent (11 - 18 Years)';

  @override
  String get assessWomenQ2Biz =>
      'Do women hold at least a 51% ownership stake in the enterprise?';

  @override
  String get assessWomenQ2BizOpt1 => 'Yes, fully owned by women';

  @override
  String get assessWomenQ2BizOpt2 => 'No, minor/shared stake';

  @override
  String get assessWomenQ2Welfare =>
      'Do you possess a BPL (Below Poverty Line) Ration Card?';

  @override
  String get assessWomenQ2WelfareOpt1 => 'Yes, BPL Cardholder';

  @override
  String get assessWomenQ2WelfareOpt2 => 'No, APL / General';

  @override
  String get assessWomenQ3MaternReg =>
      'Are you registered at your local Anganwadi/Health center?';

  @override
  String get assessWomenQ3MaternRegOpt1 => 'Yes, registered';

  @override
  String get assessWomenQ3MaternRegOpt2 => 'No, not registered yet';

  @override
  String get assessWomenQ3GirlSave =>
      'Would you like to open a long-term savings account (Sukanya Samriddhi)?';

  @override
  String get assessWomenQ3GirlSaveOpt1 => 'Yes, open savings account';

  @override
  String get assessWomenQ3GirlSaveOpt2 =>
      'No, seeking educational scholarships';

  @override
  String get assessWomenQ3GirlEdu =>
      'Is the girl child currently enrolled in school/college?';

  @override
  String get assessWomenQ3GirlEduOpt1 => 'Yes, attending school/college';

  @override
  String get assessWomenQ3GirlEduOpt2 => 'No, discontinued education';

  @override
  String get assessWomenQ3BizCredit =>
      'What capital support size are you seeking for your business?';

  @override
  String get assessWomenQ3BizCreditOpt1 => 'Micro-credit (Under ₹1 Lakh)';

  @override
  String get assessWomenQ3BizCreditOpt2 => 'SME Loan (₹1 Lakh - ₹10 Lakhs)';

  @override
  String get assessWomenQ3BizCreditOpt3 =>
      'Stand-Up India loan (Over ₹10 Lakhs)';

  @override
  String get assessWomenQ3WelfarePension =>
      'Are you currently receiving any monthly social pension?';

  @override
  String get assessWomenQ3WelfarePensionOpt1 => 'Yes, receiving widow pension';

  @override
  String get assessWomenQ3WelfarePensionOpt2 => 'No pension received';

  @override
  String get assessWomenQ4Caste => 'What is your caste/social category?';

  @override
  String get assessWomenQ4CasteOpt1 => 'General';

  @override
  String get assessWomenQ4CasteOpt2 => 'OBC';

  @override
  String get assessWomenQ4CasteOpt3 => 'SC / ST';

  @override
  String get assessWomenQ4CasteOpt4 => 'Minority / EWS';

  @override
  String get assessWomenQ5Income => 'What is your family\'s annual income?';

  @override
  String get assessWomenQ5IncomeOpt1 => 'Under ₹1.5 Lakhs';

  @override
  String get assessWomenQ5IncomeOpt2 => '₹1.5 Lakhs - ₹5 Lakhs';

  @override
  String get assessWomenQ5IncomeOpt3 => 'Over ₹5 Lakhs';

  @override
  String get assessBizQ1 => 'Is your business legally registered?';

  @override
  String get assessBizQ1Opt1 => 'Yes, under MSME Udyam';

  @override
  String get assessBizQ1Opt2 => 'Yes, as a DPIIT Startup';

  @override
  String get assessBizQ1Opt3 => 'No, operating as individual trader/artisan';

  @override
  String get assessBizQ1Opt4 => 'No, it is in idea stage';

  @override
  String get assessBizQ2Msme =>
      'What is the total investment in machinery/equipment?';

  @override
  String get assessBizQ2MsmeOpt1 => 'Micro (up to ₹2.5 Crore investment)';

  @override
  String get assessBizQ2MsmeOpt2 => 'Small (₹2.5 Crore - ₹25 Crore)';

  @override
  String get assessBizQ2MsmeOpt3 => 'Medium (₹25 Crore - ₹125 Crore)';

  @override
  String get assessBizQ2Startup => 'What stage is your startup currently in?';

  @override
  String get assessBizQ2StartupOpt1 => 'Prototype / MVP development';

  @override
  String get assessBizQ2StartupOpt2 => 'Early Revenue / Validation';

  @override
  String get assessBizQ2StartupOpt3 => 'Scaling & expansion';

  @override
  String get assessBizQ2Artisan =>
      'Do you hold a valid PM Vishwakarma Card or Artisan ID?';

  @override
  String get assessBizQ2ArtisanOpt1 => 'Yes, active card';

  @override
  String get assessBizQ2ArtisanOpt2 => 'No, not registered';

  @override
  String get assessBizQ2Idea =>
      'Do you have a business project report prepared?';

  @override
  String get assessBizQ2IdeaOpt1 => 'Yes, report is ready';

  @override
  String get assessBizQ2IdeaOpt2 => 'No, need project guidance';

  @override
  String get assessBizQ3MsmeNeed =>
      'What primary credit/loan support do you need?';

  @override
  String get assessBizQ3MsmeNeedOpt1 => 'Collateral-free Mudra Loan';

  @override
  String get assessBizQ3MsmeNeedOpt2 => 'Working capital guarantee (CGTMSE)';

  @override
  String get assessBizQ3MsmeNeedOpt3 => 'Equipment purchase capital subsidy';

  @override
  String get assessBizQ3StartupNeed =>
      'Are you seeking equity funding or tax exemptions?';

  @override
  String get assessBizQ3StartupNeedOpt1 => 'Government Seed Funding';

  @override
  String get assessBizQ3StartupNeedOpt2 => 'Section 80-IAC Tax Exemption';

  @override
  String get assessBizQ3StartupNeedOpt3 => 'Incubator mentoring grant';

  @override
  String get assessBizQ3ArtisanNeed => 'What support does your craft require?';

  @override
  String get assessBizQ3ArtisanNeedOpt1 => 'Free toolkit upgrade voucher';

  @override
  String get assessBizQ3ArtisanNeedOpt2 => 'Exhibition & stall subsidies';

  @override
  String get assessBizQ3ArtisanNeedOpt3 => 'Individual craft micro-loan';

  @override
  String get assessBizQ4Demographics =>
      'Is the primary owner a Woman or SC/ST entrepreneur?';

  @override
  String get assessBizQ4DemographicsOpt1 => 'Yes, woman entrepreneur';

  @override
  String get assessBizQ4DemographicsOpt2 => 'Yes, SC/ST entrepreneur';

  @override
  String get assessBizQ4DemographicsOpt3 => 'Yes, both SC/ST & Woman';

  @override
  String get assessBizQ4DemographicsOpt4 => 'General category Male';

  @override
  String get assessBizQ5Turnover =>
      'What is the annual turnover or estimated revenue of the business?';

  @override
  String get assessBizQ5TurnoverOpt1 => 'Under ₹10 Lakhs';

  @override
  String get assessBizQ5TurnoverOpt2 => '₹10 Lakhs - ₹50 Lakhs';

  @override
  String get assessBizQ5TurnoverOpt3 => '₹50 Lakhs - ₹2 Crores';

  @override
  String get assessBizQ5TurnoverOpt4 => 'Over ₹2 Crores';

  @override
  String get assessAgriQ1 => 'What is your landholding size for farming?';

  @override
  String get assessAgriQ1Opt1 => 'Small / Marginal (Under 2 Hectares)';

  @override
  String get assessAgriQ1Opt2 => 'Medium (2 - 5 Hectares)';

  @override
  String get assessAgriQ1Opt3 => 'Large / Commercial (Over 5 Hectares)';

  @override
  String get assessAgriQ1Opt4 => 'Tenant / Landless Farmer';

  @override
  String get assessAgriQ2 => 'What agricultural support do you need urgently?';

  @override
  String get assessAgriQ2Opt1 => 'PM-KISAN Cash Transfer';

  @override
  String get assessAgriQ2Opt2 => 'Drip Irrigation / Equipment Subsidy';

  @override
  String get assessAgriQ2Opt3 => 'Crop Insurance & Disaster Relief';

  @override
  String get assessAgriQ2Opt4 => 'Kisan Credit Card (KCC) Loan';

  @override
  String get assessAgriQ3Caste => 'What is your social category?';

  @override
  String get assessAgriQ3CasteOpt1 => 'General';

  @override
  String get assessAgriQ3CasteOpt2 => 'OBC';

  @override
  String get assessAgriQ3CasteOpt3 => 'SC / ST';

  @override
  String get assessAgriQ3CasteOpt4 => 'Small Farmer Special';

  @override
  String get assessAgriQ4Income => 'What is your total family annual income?';

  @override
  String get assessAgriQ4IncomeOpt1 => 'Under ₹1.5 Lakhs';

  @override
  String get assessAgriQ4IncomeOpt2 => '₹1.5 Lakhs - ₹5 Lakhs';

  @override
  String get assessAgriQ4IncomeOpt3 => 'Over ₹5 Lakhs';

  @override
  String get assessSkillQ1 => 'What is your current employment or skill level?';

  @override
  String get assessSkillQ1Opt1 => 'Unemployed youth seeking job';

  @override
  String get assessSkillQ1Opt2 => 'School/College dropout';

  @override
  String get assessSkillQ1Opt3 => 'Traditional artisan / Worker';

  @override
  String get assessSkillQ1Opt4 => 'Employed seeking skill upgrade';

  @override
  String get assessSkillQ2 => 'Which skill training area interests you?';

  @override
  String get assessSkillQ2Opt1 => 'IT, Digital & Electronics';

  @override
  String get assessSkillQ2Opt2 => 'Apparel, Textile & Handicrafts';

  @override
  String get assessSkillQ2Opt3 => 'Automotive & Mechanical';

  @override
  String get assessSkillQ2Opt4 => 'Healthcare & Hospitality';

  @override
  String get assessSkillQ3 =>
      'Are you looking for government-certified PMKVY training?';

  @override
  String get assessSkillQ3Opt1 => 'Yes, need certified training';

  @override
  String get assessSkillQ3Opt2 => 'No, seeking self-employment stipend';

  @override
  String get assessSkillQ4Income => 'What is your annual family income?';

  @override
  String get assessSkillQ4IncomeOpt1 => 'Under ₹2.5 Lakhs';

  @override
  String get assessSkillQ4IncomeOpt2 => '₹2.5 Lakhs - ₹8 Lakhs';

  @override
  String get assessSkillQ4IncomeOpt3 => 'Over ₹8 Lakhs';

  @override
  String get assessTeQ1 => 'What is your primary enterprise focus?';

  @override
  String get assessTeQ1Opt1 => 'Technology / R&D Innovation';

  @override
  String get assessTeQ1Opt2 => 'Export & Trade Expansion';

  @override
  String get assessTeQ1Opt3 => 'Manufacturing Production Unit';

  @override
  String get assessTeQ1Opt4 => 'Digital Infrastructure';

  @override
  String get assessTeQ2 =>
      'What specific government scheme support do you require?';

  @override
  String get assessTeQ2Opt1 => 'Capital Investment Subsidy';

  @override
  String get assessTeQ2Opt2 => 'Patent & R&D Filing Reimbursement';

  @override
  String get assessTeQ2Opt3 => 'Market Access & International Fair Grant';

  @override
  String get assessTeQ2Opt4 => 'Software & Hardware Infrastructure Support';

  @override
  String get assessTeQ3Turnover => 'What is your enterprise annual turnover?';

  @override
  String get assessTeQ3TurnoverOpt1 => 'Under ₹50 Lakhs';

  @override
  String get assessTeQ3TurnoverOpt2 => '₹50 Lakhs - ₹5 Crores';

  @override
  String get assessTeQ3TurnoverOpt3 => 'Over ₹5 Crores';

  @override
  String get assessCatQ1 => 'What describes your current employment status?';

  @override
  String get assessCatQ1Opt1 => 'Student';

  @override
  String get assessCatQ1Opt2 => 'Farmer';

  @override
  String get assessCatQ1Opt3 => 'Business Owner / Self-employed';

  @override
  String get assessCatQ1Opt4 => 'Unemployed / Worker';

  @override
  String get assessCatQ2 =>
      'Are you seeking financial credit or direct subsidy grants?';

  @override
  String get assessCatQ2Opt1 => 'Business / Study Loans';

  @override
  String get assessCatQ2Opt2 => 'Subsidies & welfare grants';

  @override
  String get assessCatQ2Opt3 => 'Free skill training / services';

  @override
  String get assessCatQ3 => 'What is your gender?';

  @override
  String get assessCatQ3Opt1 => 'Female';

  @override
  String get assessCatQ3Opt2 => 'Male';

  @override
  String get assessCatQ3Opt3 => 'Other';

  @override
  String get assessCatQ4 => 'What is your social caste category?';

  @override
  String get assessCatQ4Opt1 => 'General';

  @override
  String get assessCatQ4Opt2 => 'OBC';

  @override
  String get assessCatQ4Opt3 => 'SC / ST';

  @override
  String get assessCatQ4Opt4 => 'EWS / Minority';

  @override
  String get assessCatQ5 => 'What is your annual family income?';

  @override
  String get assessCatQ5Opt1 => 'Under ₹2.5 Lakhs';

  @override
  String get assessCatQ5Opt2 => '₹2.5 Lakhs - ₹8 Lakhs';

  @override
  String get assessCatQ5Opt3 => 'Over ₹8 Lakhs';

  @override
  String assessStateQ1(Object stateName) {
    return 'Are you a permanent resident/domicile of $stateName?';
  }

  @override
  String get assessStateQ1Opt1 => 'Yes, I hold a domicile certificate';

  @override
  String get assessStateQ1Opt2 => 'No, I am a temporary resident';

  @override
  String assessStateQ2(Object stateName) {
    return 'What is your category in the $stateName state reservation list?';
  }

  @override
  String get assessStateQ2Opt1 => 'BC / SEBC / OBC';

  @override
  String get assessStateQ2Opt2 => 'SC / ST';

  @override
  String get assessStateQ2Opt3 => 'EWS / Minority';

  @override
  String get assessStateQ2Opt4 => 'General / Open';

  @override
  String assessStateQ3(Object stateName) {
    return 'What is your primary livelihood sector in $stateName?';
  }

  @override
  String get assessStateQ3Opt1 => 'Agriculture / Farmer';

  @override
  String get assessStateQ3Opt2 => 'MSME / Startup owner';

  @override
  String get assessStateQ3Opt3 => 'Weaving / Traditional Crafts';

  @override
  String get assessStateQ3Opt4 => 'Student / Higher studies';

  @override
  String get assessStateQ4 =>
      'What type of state assistance are you targeting?';

  @override
  String get assessStateQ4Opt1 => 'Monthly cash allowances';

  @override
  String get assessStateQ4Opt2 => 'Education fee waivers';

  @override
  String get assessStateQ4Opt3 => 'Business subsidies';

  @override
  String get assessStateQ4Opt4 => 'Agricultural input support';

  @override
  String get assessStateQ5 => 'What is your total family annual income?';

  @override
  String get assessStateQ5Opt1 => 'Under ₹1.5 Lakhs';

  @override
  String get assessStateQ5Opt2 => '₹1.5 Lakhs - ₹5 Lakhs';

  @override
  String get assessStateQ5Opt3 => 'Over ₹5 Lakhs';

  @override
  String get assessMinQ1 =>
      'What is your primary objective within this ministry\'s portal?';

  @override
  String get assessMinQ1Opt1 => 'Applying for business subsidy / credit';

  @override
  String get assessMinQ1Opt2 => 'Seeking educational scholarships';

  @override
  String get assessMinQ1Opt3 => 'Seeking farmer agricultural aid';

  @override
  String get assessMinQ1Opt4 => 'Seeking rural infrastructure / SHG help';

  @override
  String get assessMinQ2 => 'What is the applicant\'s current age?';

  @override
  String get assessMinQ2Opt1 => '18 - 35 Years';

  @override
  String get assessMinQ2Opt2 => '36 - 59 Years';

  @override
  String get assessMinQ2Opt3 => '60 Years and above';

  @override
  String get assessMinQ3 =>
      'Do you have any registered ID linked to this ministry?';

  @override
  String get assessMinQ3Opt1 => 'Yes, Udyam / PM-KISAN / Scholar ID';

  @override
  String get assessMinQ3Opt2 => 'No, not registered yet';

  @override
  String get assessMinQ4 => 'What is your social category?';

  @override
  String get assessMinQ4Opt1 => 'General';

  @override
  String get assessMinQ4Opt2 => 'OBC';

  @override
  String get assessMinQ4Opt3 => 'SC / ST';

  @override
  String get assessMinQ4Opt4 => 'Minority / PwD';

  @override
  String get assessMinQ5 => 'What is your annual household income?';

  @override
  String get assessMinQ5Opt1 => 'Under ₹2.5 Lakhs';

  @override
  String get assessMinQ5Opt2 => '₹2.5 Lakhs - ₹8 Lakhs';

  @override
  String get assessMinQ5Opt3 => 'Over ₹8 Lakhs';

  @override
  String assessStepLabel(Object currentStep, Object totalSteps) {
    return 'Step $currentStep of $totalSteps';
  }

  @override
  String get assessSkipToResults => 'Skip to Results';

  @override
  String get goodAfternoon => 'Good Afternoon,';

  @override
  String get goodEvening => 'Good Evening,';

  @override
  String get splashPreparingSubtitle =>
      'Please wait while we prepare\nsomething amazing for you';

  @override
  String get splashNoInternetTitle => 'No internet connection';

  @override
  String get splashNoInternetBody =>
      'Connect to the internet to sign in or restore this app.';

  @override
  String get openSaarthiAiChat => 'Open Saarthi AI chat';

  @override
  String get sortLabel => 'Sort';

  @override
  String get searchDiscoverSubtitle =>
      'Find government schemes you can apply for';

  @override
  String get searchCompleteProfileTitle =>
      'Complete your profile to see personalised matches';

  @override
  String get searchCompleteProfileSubtitle =>
      'Add your date of birth, gender and state so \"For Me\" can match schemes to you.';

  @override
  String get searchNoProfileMatchesTitle => 'No schemes match your profile yet';

  @override
  String get searchNoProfileMatchesSubtitle =>
      'Try adjusting the filters, or update your profile details.';

  @override
  String get schemeNotApplicable => 'Not applicable to you';

  @override
  String get searchNoFilterMatchesTitle =>
      'No schemes found matching your filters';

  @override
  String get searchNoFilterMatchesSubtitle =>
      'Try adjusting or clearing your filters to see more results.';

  @override
  String eligibleSchemesForYouCount(Object count) {
    return 'Eligible Schemes For You ($count)';
  }

  @override
  String matchingSchemesCount(Object count) {
    return 'Matching Schemes ($count)';
  }

  @override
  String get matchedStrictlyAgainstProfile =>
      'Matched strictly against your profile data';

  @override
  String schemesAvailableCount(Object count) {
    return '$count schemes available';
  }

  @override
  String get resultsCopiedToClipboard => 'Results copied to clipboard';

  @override
  String get clearFiltersAndExplore => 'Clear Filters & Explore Schemes';

  @override
  String get removeSaved => 'Remove from saved';

  @override
  String get viewDetails => 'View Details';

  @override
  String get eligibilityResultsTitle => 'Eligibility Results';

  @override
  String get eligibilityResultsCopiedToClipboard =>
      'Eligibility results copied to clipboard';

  @override
  String get faqEligibilityQ => 'How do I check my eligibility for a scheme?';

  @override
  String get faqEligibilityA =>
      'Fill in your profile details (age, gender, state, income, etc.) in the Profile tab, then browse the Search tab, where each scheme shows whether it matches your profile. For a quick check, you can also try the assessment under Discover.';

  @override
  String get faqApplyQ => 'How can I apply for a scheme?';

  @override
  String get faqApplyA =>
      'Select any scheme to see its detailed description, benefits, and required documents. Tap the \'Apply Now\' button to open the official government application portal in your browser.';

  @override
  String get faqTrackQ => 'Where can I track my application status?';

  @override
  String get faqTrackA =>
      'Since application submissions are processed directly on official government portals, you can track your status by logging into the respective portal using the application ID provided during submission.';

  @override
  String get faqFreeQ => 'Is MSS app free to use?';

  @override
  String get faqFreeA =>
      'Yes, MSS is completely free to use. Our goal is to make citizen benefits and government schemes accessible to everyone in India without any hidden fees.';

  @override
  String get faqDataFreshnessQ => 'How often is new data updated?';

  @override
  String get faqDataFreshnessA =>
      'Our database is updated daily to reflect the latest announcements, schemes, subsidies, and application guidelines from the central and state ministries.';

  @override
  String get faqScoringQ => 'How does the recommendation scoring work?';

  @override
  String get faqScoringA =>
      'We evaluate your profile (residency, age, gender, education, and community) against the criteria set by each scheme. A match score is calculated out of 100% depending on the percentage of conditions met.';

  @override
  String get faqDataSharingQ =>
      'Is my personal data shared with the government?';

  @override
  String get faqDataSharingA =>
      'No. MSS is a recommendation tool that runs fully on your device. We do not share your profile details with external departments. You apply directly on official portals.';

  @override
  String get faqMissingDocsQ => 'How do I obtain missing documents?';

  @override
  String get faqMissingDocsA =>
      'In the Scheme Details view, any document marked as \"Missing\" has a \"Get Document\" link that redirects you directly to the official portal (e.g., UIDAI for Aadhaar, NSDL for PAN).';

  @override
  String get helpCatGeneralInquiry => 'General Inquiry';

  @override
  String get helpFaqAnswerTitle => 'FAQ Answer';

  @override
  String get helpAllFaqsTitle => 'All FAQs';

  @override
  String get helpReportIssueTitle => 'Report an Issue';

  @override
  String get helpReportIssueBody =>
      'Facing a problem? Fill out the details below and our team will get back to you shortly.\n\nYour report will be sent directly to mssschemessearch@gmail.com. Please enter your email below so we can reply.';

  @override
  String get helpCatMatcherBug => 'Eligibility Matcher Bug';

  @override
  String get helpCatWrongDetails => 'Wrong Scheme Details';

  @override
  String get helpCatFeatureRequest => 'Feature Request';

  @override
  String get helpTicketSubmitted =>
      'Thank you! Your ticket has been submitted.';

  @override
  String get helpTicketSubmitFailed =>
      'Failed to submit ticket. Please check your connection and try again.';

  @override
  String get helpSubmitTicket => 'Submit Ticket';

  @override
  String get helpShareFeedbackTitle => 'Share Feedback';

  @override
  String get helpFeedbackBody =>
      'We value your feedback. Let us know how we can improve your experience!';

  @override
  String get helpRateExperience => 'Rate your experience';

  @override
  String helpRateStars(Object count) {
    return 'Rate $count stars';
  }

  @override
  String get helpFeedbackEmailHint =>
      'e.g. yourname@gmail.com for follow-up from mssschemessearch@gmail.com';

  @override
  String get helpFeedbackThanks => 'Thank you for your valuable feedback!';

  @override
  String get helpFeedbackSubmitFailed =>
      'Failed to submit feedback. Please check your connection.';

  @override
  String get helpTicketErrCategory => 'Please select an issue category.';

  @override
  String get helpTicketErrEmailMissing =>
      'Please enter your contact email address.';

  @override
  String get helpTicketErrEmailInvalid =>
      'Please enter a valid email address (e.g. name@example.com).';

  @override
  String get helpTicketErrDescriptionMissing =>
      'Please describe your issue or feedback.';

  @override
  String helpTicketErrDescriptionShort(int count) {
    return 'Please add a bit more detail (at least $count characters).';
  }

  @override
  String helpTicketErrWait(int seconds) {
    return 'Please wait $seconds seconds before submitting again.';
  }

  @override
  String get helpTicketErrTooMany =>
      'Too many submissions. Please try again later.';

  @override
  String get helpSubmitFeedback => 'Submit Feedback';

  @override
  String get helpHeaderContact => 'Contact Us';

  @override
  String get helpHeaderSupport => 'Help & Support';

  @override
  String get helpHeaderSubtitle => 'We\'re here to help you';

  @override
  String get helpFaqsGroupTitle => 'FAQs';

  @override
  String get helpFaqsGroupSubtitle => 'Find answers to common questions';

  @override
  String get helpViewAllFaqs => 'View all FAQs';

  @override
  String get helpContactGroupTitle => 'Contact Support';

  @override
  String get helpContactGroupSubtitle => 'Get in touch with our support team';

  @override
  String get helpEmailUs => 'Email Us';

  @override
  String get helpSupportEmailCopied => 'Support email copied to clipboard!';

  @override
  String get helpReplyWindow => 'We typically reply within 24 hours';

  @override
  String get helpReportIssueSubtitle => 'Facing a problem? Let us know.';

  @override
  String get helpFeedbackTileTitle => 'Feedback';

  @override
  String get helpFeedbackTileSubtitle =>
      'Share your suggestions to help us improve.';

  @override
  String get helpStillNeedHelp => 'Still need help?';

  @override
  String get helpStillNeedHelpBody =>
      'Our support team is always ready to assist you.';

  @override
  String get emiCalcTitle => 'Business Loan EMI Calculator';

  @override
  String get emiCalcSubtitle =>
      'Calculate monthly payments for your business loan.';

  @override
  String get emiLoanAmount => 'Loan Amount';

  @override
  String get emiLoanAmountHelper => 'Enter total business loan sum required';

  @override
  String get emiInterestRate => 'Interest Rate (% p.a.)';

  @override
  String get emiInterestRateHelper => 'Enter annual rate';

  @override
  String get emiTenureMonths => 'Tenure (Months)';

  @override
  String get emiTenureSuffixMo => 'Mo';

  @override
  String get emiTenureHelper => 'Enter term in months';

  @override
  String get emiMonthlyEmi => 'Monthly EMI';

  @override
  String get emiPrincipal => 'Principal Amount';

  @override
  String get emiTotalInterest => 'Total Interest Payable';

  @override
  String get emiTotalAmount => 'Total Amount (Principal + Int)';

  @override
  String get emiInvalidInputs => 'Please enter valid inputs';

  @override
  String get emiCalculate => 'Calculate EMI';

  @override
  String get dpiitTitle => 'DPIIT Recognition Checklist';

  @override
  String get dpiitSubtitle =>
      'Evaluate if your business qualifies as a startup under DPIIT rules.';

  @override
  String get dpiitCriteriaRegistered =>
      'Registered as Pvt Ltd / LLP / Partnership';

  @override
  String get dpiitCriteriaRegisteredSub =>
      'Must be registered in India. Sole proprietorships do not qualify.';

  @override
  String get dpiitCriteriaAge => 'Incorporation age is under 10 years';

  @override
  String get dpiitCriteriaAgeSub => 'From incorporation date';

  @override
  String get dpiitCriteriaNotSplit =>
      'Not formed by splitting up or rebuilding an existing business';

  @override
  String get dpiitCriteriaNotSplitSub => 'Must be a genuinely new entity';

  @override
  String get dpiitCriteriaTurnover =>
      'Annual turnover has never exceeded ₹100 Cr';

  @override
  String get dpiitCriteriaTurnoverSub => 'For any financial year';

  @override
  String get dpiitCriteriaInnovation => 'Working towards innovation/scaling';

  @override
  String get dpiitCriteriaInnovationSub => 'Developing new products/processes';

  @override
  String get dpiitResultEligible =>
      'You appear to meet all DPIIT criteria. Apply for recognition on the Startup India portal.';

  @override
  String get dpiitResultNotEligible =>
      'Not eligible yet. A startup must satisfy all 5 criteria.';

  @override
  String dpiitResultUnmet(String criteria) {
    return 'Not met: $criteria';
  }

  @override
  String get dpiitCheckEligibility => 'Check Eligibility';

  @override
  String get valuationTitle => 'Startup Valuation Estimator';

  @override
  String get valuationSubtitle =>
      'Get a ballpark pre-seed/seed valuation range based on MRR.';

  @override
  String get valuationMrrLabel => 'Monthly Recurring Revenue (MRR)';

  @override
  String get valuationMrrHelper => 'Enter monthly revenue in Rupees';

  @override
  String get valuationMomGrowth => 'MoM Growth (%)';

  @override
  String get valuationMomHelper => 'Enter month-on-month rate';

  @override
  String get valuationSector => 'Business Sector';

  @override
  String get valuationSectorSaasTech => 'SaaS / Tech';

  @override
  String get valuationSectorEcommerce => 'E-commerce';

  @override
  String get valuationSectorFintech => 'Fintech';

  @override
  String get valuationSectorAgritech => 'AgriTech';

  @override
  String get valuationRange => 'Valuation Range';

  @override
  String get valuationCalculatedArr => 'Calculated ARR';

  @override
  String get valuationAppliedMultiple => 'Applied ARR Multiple';

  @override
  String get valuationInvalidMrr => 'Please enter a valid MRR';

  @override
  String get valuationEstimate => 'Estimate Valuation';

  @override
  String valuationCroreFmt(Object value) {
    return '₹ $value Crores';
  }

  @override
  String valuationLakhFmt(Object value) {
    return '₹ $value Lakhs';
  }

  @override
  String get docChecklistTitle => 'Setup Document Checklist';

  @override
  String get docChecklistSubtitle =>
      'Checklist of documents needed to set up your business.';

  @override
  String get docEntityType => 'Business Entity Type';

  @override
  String get docRequiredDocuments => 'Required Documents';

  @override
  String get docCloseChecklist => 'Close Checklist';

  @override
  String get docEntityPrivateLimited => 'Private Limited';

  @override
  String get docEntitySoleProprietorship => 'Sole Proprietorship';

  @override
  String get docItemProprietorPanAadhaar => 'Owner\'s PAN card and Aadhaar';

  @override
  String get docItemUdyamRegistration =>
      'Udyam registration certificate (free, udyamregistration.gov.in)';

  @override
  String get docItemShopEstablishmentLicence =>
      'Shop & Establishment licence from your state / local body';

  @override
  String get docItemProprietorBankAccount =>
      'Current bank account in the business name';

  @override
  String get docEntityPartnership => 'Partnership';

  @override
  String get docEntityOpc => 'One Person Company (OPC)';

  @override
  String get docEntityLlp => 'LLP';

  @override
  String get docItemDsc => 'Digital Signature Certificate (DSC)';

  @override
  String get docItemDin => 'Director Identification Number (DIN)';

  @override
  String get docItemMoaAoa => 'MOA & AOA Drafting';

  @override
  String get docItemCoi => 'Certificate of Incorporation (COI)';

  @override
  String get docItemCompanyPanTan => 'Company PAN & TAN Cards';

  @override
  String get docItemCorporateBankAccount => 'Corporate Bank Account';

  @override
  String get docItemPartnershipDeed => 'Partnership Deed drafting';

  @override
  String get docItemDeedRegistration => 'Deed Registration with Registrar';

  @override
  String get docItemFirmPanTan => 'PAN & TAN cards of Firm';

  @override
  String get docItemFirmBankAccount => 'Firm Bank Account';

  @override
  String get docItemGstRegistrationOptional => 'GST Registration (Optional)';

  @override
  String get docItemLlpNameApproval => 'LLP Name Approval (RUN-LLP)';

  @override
  String get docItemFillipForm => 'FiLLiP Form (LLP Incorporation)';

  @override
  String get docItemLlpAgreement => 'LLP Agreement Drafting';

  @override
  String get docItemLlpPanTan => 'LLP PAN & TAN Cards';

  @override
  String get docItemLlpBankAccount => 'LLP Bank Account';

  @override
  String get subsidyTitle => 'Business Subsidy Estimator';

  @override
  String get subsidySubtitle =>
      'Estimate capital subsidies and net loan commitments for machinery.';

  @override
  String get subsidyProjectCost => 'Project / Machinery Cost (Lakhs)';

  @override
  String get subsidyProjectCostSuffix => 'Lakhs';

  @override
  String get subsidyProjectCostHelper =>
      'Enter machinery or project cost in Lakhs';

  @override
  String get subsidyPercentLabel => 'Expected Subsidy Percentage (%)';

  @override
  String get subsidyPercentHelper => 'Enter expected subsidy rate percentage';

  @override
  String get subsidyOriginalCost => 'Original Project Cost';

  @override
  String subsidyExpectedLabel(Object percent) {
    return 'Expected Subsidy ($percent%)';
  }

  @override
  String get subsidyNetCost => 'Net Cost to Business';

  @override
  String get subsidyInvalidValues =>
      'Please enter valid values (Subsidy % must be between 0 and 100)';

  @override
  String get subsidyCalculate => 'Calculate Subsidy';

  @override
  String subsidyLakhFmt(Object value) {
    return '₹ $value Lakhs';
  }

  @override
  String msmeRatePerAnnum(Object rate) {
    return '$rate% p.a.';
  }

  @override
  String get msmeUdyamFlowTitle => 'Udyam Registration Flow';

  @override
  String get msmeUdyamGoToPortal => 'Go to Official Udyam Portal';

  @override
  String get msmeUdyamStep1Title => '1. Aadhaar & PAN Validation';

  @override
  String get msmeUdyamStep1Desc =>
      'Enter entrepreneur Aadhaar Number & Name as per Aadhaar. Validate via OTP. Next, enter Organization Type & PAN details for automatic GSTIN verification.';

  @override
  String get msmeUdyamStep1Action =>
      'Aadhaar OTP authentication & PAN details entry.';

  @override
  String get msmeUdyamStep2Title => '2. Enterprise & Location Details';

  @override
  String get msmeUdyamStep2Desc =>
      'Provide Enterprise Name, Plant/Unit Addresses, Official Email, Mobile Number, Bank Account Number, and IFSC Code.';

  @override
  String get msmeUdyamStep2Action =>
      'Fill unit addresses, mobile, email & bank details.';

  @override
  String get msmeUdyamStep3Title => '3. NIC Code & Investment Details';

  @override
  String get msmeUdyamStep3Desc =>
      'Select Major Activity (Manufacturing / Service), search & select 2/4/5-digit NIC Codes, enter number of employees, and investment in Plant & Machinery.';

  @override
  String get msmeUdyamStep3Action =>
      'Select NIC classification code & enter investment/turnover.';

  @override
  String get msmeUdyamStep4Title => '4. Final Submit & e-Certificate';

  @override
  String get msmeUdyamStep4Desc =>
      'Review summary, submit final OTP. A unique 16-digit Udyam Registration Number (URN) and e-Certificate with QR code are issued instantly with zero registration fee.';

  @override
  String get msmeUdyamStep4Action =>
      'Final OTP submission; download instant e-Certificate.';

  @override
  String voiceRelevanceMatch(Object confidence) {
    return '$confidence% relevance match';
  }

  @override
  String voiceEditFact(Object label) {
    return 'Edit $label';
  }

  @override
  String get voiceNoiseControlSecure =>
      'Device noise control • Secure live voice';

  @override
  String voiceSeeUncertainSchemes(Object count) {
    return 'See $count uncertain or historical schemes';
  }

  @override
  String get voiceAiReady => 'AI voice ready';

  @override
  String get voiceConversationTranscript => 'Conversation transcript';

  @override
  String voiceFoundCount(Object count) {
    return '$count found';
  }

  @override
  String get voiceShowTop3 => 'Show top 3';

  @override
  String voiceShowAllMatches(Object count) {
    return 'Show all $count matches';
  }

  @override
  String get voiceReviewDetails => 'Review details';

  @override
  String get voiceConfirmEligibility =>
      'Confirm current eligibility before applying';

  @override
  String get voiceTapToInterrupt => 'Tap to interrupt';

  @override
  String get voiceSemInterrupt => 'Interrupt assistant';

  @override
  String get voiceSemMicHint => 'Double tap to control the microphone';

  @override
  String get voiceAiAssistant => 'AI assistant';

  @override
  String get voiceSemNoiseControlOn => 'Device echo and noise control is on';

  @override
  String get voiceTapWhenFinished => 'Tap when finished';

  @override
  String get voiceTypeInstead => 'Type instead...';

  @override
  String voiceFactCrore(Object value) {
    return '₹$value crore';
  }

  @override
  String voiceFactLakh(Object value) {
    return '₹$value lakh';
  }

  @override
  String get saarthiGreetingFriend => 'there';

  @override
  String get saarthiVoiceServiceUnavailable =>
      'Voice service is unavailable. Tap retry.';

  @override
  String get saarthiVoiceFallbackOnDevice =>
      'Cloud voice isn\'t available right now. Saarthi is listening on your phone instead.';

  @override
  String get saarthiCloudErrorSignIn =>
      'Please sign in again, then retry voice.';

  @override
  String get saarthiCloudErrorNetwork =>
      'Check your internet, then retry voice.';

  @override
  String get saarthiCloudErrorGeneric =>
      'Voice service could not connect. Tap retry.';

  @override
  String get saarthiGenericError => 'An error occurred. Please try again.';

  @override
  String get saarthiStatusConnectionAttention => 'Connection needs attention';

  @override
  String saarthiVoiceControlLabel(Object label) {
    return '$label voice control';
  }

  @override
  String get saarthiQAge => 'What is your age?';

  @override
  String get saarthiQState => 'Which state are you in?';

  @override
  String get saarthiQDistrict => 'Which district are you in?';

  @override
  String get saarthiQIncome => 'Roughly what is your family\'s annual income?';

  @override
  String get saarthiQGender => 'What is your gender?';

  @override
  String get saarthiQCommunity => 'Which community category do you belong to?';

  @override
  String get saarthiQOccupation => 'What do you do for a living right now?';

  @override
  String get saarthiQEducation => 'What is your education level?';

  @override
  String get saarthiQDisability => 'Does any disability category apply to you?';

  @override
  String get saarthiQMaritalStatus => 'What is your marital status?';

  @override
  String get saarthiQIsStudent => 'Are you currently a student?';

  @override
  String get saarthiQBusinessStage =>
      'Is this an idea, a new business, or an existing business?';

  @override
  String get saarthiQBusinessSector => 'Which business sector is it?';

  @override
  String get saarthiQFundingNeed => 'Roughly how much funding do you need?';

  @override
  String get saarthiQLandholding => 'How much land do you hold?';

  @override
  String get profileHintSelectDob => 'SELECT DATE OF BIRTH';

  @override
  String get profileErrEnterPhone => 'Please enter your phone number';

  @override
  String get profileErrPhone10Digits => 'Enter a 10-digit mobile number';

  @override
  String get profileErrPincode6Digits => 'Enter 6 digits';

  @override
  String get profileErrLocationFetchFailed =>
      'Could not fetch location. Please enter manually.';

  @override
  String get profileErrCompleteFieldsCorrectly =>
      'Please complete all required fields correctly.';

  @override
  String get profileErrLocationFieldsCorrectly =>
      'Please fill in all required location fields correctly.';

  @override
  String get profileErrCompleteFieldsToContinue =>
      'Please complete all required fields to continue.';

  @override
  String get profileErrUnableToSave =>
      'Unable to save profile. Please check connection and try again.';

  @override
  String get profileErrEnterFullName => 'Please enter your full name';

  @override
  String get profileErrValidEmail => 'Please enter a valid email address';

  @override
  String get profileHint10DigitMobile => '10-digit mobile number';

  @override
  String get profileErrSelectGender => 'Please select your gender';

  @override
  String get profileErrSelectDob => 'Please select your date of birth';

  @override
  String get profileHintDdmmyyyy => 'DD/MM/YYYY';

  @override
  String get profileHintDoorStreetExample => 'e.g. Flat 402, Royal Enclave';

  @override
  String get profileErrEnterHouseStreet =>
      'Please enter your house/street address';

  @override
  String get profileHintAreaExample => 'e.g. Anna Nagar West';

  @override
  String get profileErrEnterArea => 'Please enter your area or locality';

  @override
  String get profileHintCityExample => 'e.g. Chennai';

  @override
  String get profileErrValidCity => 'Please enter a valid city or district';

  @override
  String get profileHintStateExample => 'e.g. Tamil Nadu';

  @override
  String get profileErrValidState => 'Please select your state';

  @override
  String get profileSelectState => 'Select your state';

  @override
  String get profileSearchStateHint => 'Search state or union territory';

  @override
  String get profileNoStateMatch => 'No matching state';

  @override
  String get profileSelectDistrict => 'Select your district';

  @override
  String get profileSelectStateFirst => 'Select your state first';

  @override
  String get profileSearchDistrictHint => 'Search district';

  @override
  String get profileNoDistrictMatch => 'No matching district';

  @override
  String get profileErrValidDistrict => 'Please select your district';

  @override
  String get profileErrSelectOptionToContinue =>
      'Please select an option to continue.';

  @override
  String get profileErrSelectEducation => 'Please select your education level';

  @override
  String get profileErrSelectCommunity =>
      'Please select your community category';

  @override
  String get profileErrSelectIncome => 'Please select your annual income range';

  @override
  String get settingsNavModeDialogBody =>
      'Choose your preferred layout mode for navigating schemes and services.';

  @override
  String get settingsSwitchedToCompanion =>
      'Switched to AI Companion (Saarthi) Navigation';

  @override
  String get settingsSwitchedToRegular => 'Switched to Regular Navigation';

  @override
  String settingsAppVersion(Object version) {
    return 'App Version $version';
  }

  @override
  String get betaGateEnterPassword => 'Please enter the beta password.';

  @override
  String get betaGateInvalidPassword =>
      'Invalid beta password. Please try again.';

  @override
  String get betaGateVerifyFailed =>
      'Unable to verify password. Check your network.';

  @override
  String get betaGateAuthorizedTestersOnly => 'Authorized Beta Testers Only';

  @override
  String get betaGateAccess => 'Beta Access';

  @override
  String get betaGateEnterPasswordToContinue =>
      'Enter the beta tester password to continue.';

  @override
  String get betaGatePasswordHint => 'Enter password';

  @override
  String get betaGateVerifyAndEnter => 'Verify & Enter';

  @override
  String get loginGoogleSignInFailed =>
      'Unable to complete Google sign in. Please try again.';

  @override
  String get dialogConfirm => 'Confirm';

  @override
  String get monthAbbrList => 'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec';

  @override
  String get discoverEveryScheme => 'Discover every Government Scheme in India';

  @override
  String get shareResultsTooltip => 'Share results';

  @override
  String get clearSearchTooltip => 'Clear search';

  @override
  String get voiceSearchTooltip => 'Voice search';

  @override
  String get stopVoiceSearchTooltip => 'Stop voice search';

  @override
  String get voiceAssistantLabel => 'Voice assistant';

  @override
  String get eligResGreatNews => 'Great News! 🎉';

  @override
  String get eligResEligibleForPrefix => 'You are eligible for\n';

  @override
  String eligResGovernmentSchemesCount(Object count) {
    return '$count Government Schemes';
  }

  @override
  String get eligResBasedOnInfo => 'based on the information you provided';

  @override
  String get eligResRecommendedSchemes => 'Recommended Schemes';

  @override
  String get eligResNoMatches =>
      'No matching schemes found. Adjust your profile details to expand matching rules.';

  @override
  String get eligResSortedInfo =>
      'These schemes are sorted based on your profile match and eligibility criteria.';

  @override
  String get eligResSavedToast => 'Results saved to your eligibility profile!';

  @override
  String get eligResSaveResults => 'Save Results';

  @override
  String get eligResSecurePrivate => 'Your information is secure and private';

  @override
  String get eligResShareHeader => 'My Scheme Eligibility Results:';

  @override
  String eligResShareItem(Object name, Object percent) {
    return '• $name ($percent% Match)';
  }

  @override
  String get eligResEligibleSchemesTitle => 'Eligible Schemes';

  @override
  String get eligResExploreAll => 'Explore All Schemes';

  @override
  String get eligResSaving => 'Saving...';

  @override
  String get eligResSavedToProfile => 'Saved to Profile';

  @override
  String get eligResSaveFailed => 'Failed to save results. Please try again.';

  @override
  String get notifCatNewSchemes => 'New Schemes';

  @override
  String get notifCatReminders => 'Reminders';

  @override
  String get notifCatUpdates => 'Updates';

  @override
  String get notifCatProfile => 'Profile';

  @override
  String get notifBadgeNew => 'NEW';

  @override
  String get notifProfileCompletionLabel => 'Profile Completion';

  @override
  String get notifCancelSelectionTooltip => 'Cancel selection';

  @override
  String notifSelectedCount(Object count) {
    return '$count Selected';
  }

  @override
  String get notifMarkAllAsRead => 'Mark all as read';

  @override
  String get notifDeleteAll => 'Delete all';

  @override
  String get notifNoMatchingAlerts => 'No matching alerts';

  @override
  String get notifTagEducation => 'Education';

  @override
  String get notifTagSkillDevelopment => 'Skill Development';

  @override
  String timeAgoDays(Object count) {
    return '${count}d ago';
  }

  @override
  String timeAgoHours(Object count) {
    return '${count}h ago';
  }

  @override
  String timeAgoMinutes(Object count) {
    return '${count}m ago';
  }

  @override
  String get timeAgoJustNow => 'Just now';

  @override
  String daysLeftFmt(Object count) {
    return '$count days left';
  }

  @override
  String get notifSeed1Body =>
      'Government has launched the Fisheries and Aquaculture Infrastructure Development Fund to provide concessionary finance.';

  @override
  String get notifSeed2Title => 'PM Vidyalaxmi Education Loan Scheme';

  @override
  String get notifSeed2Body =>
      'A new scheme for students to provide collateral-free education loans for higher studies.';

  @override
  String get notifSeed3Title => 'PM Vishwakarma Yojana';

  @override
  String get notifSeed3Body =>
      'Financial support for traditional artisans and craftspeople to upgrade their skills and tools.';

  @override
  String get notifSeed4Title => 'Post Matric Scholarship Scheme';

  @override
  String get notifSeed4Body => 'Last date to apply is approaching';

  @override
  String get notifSeed5Title => 'PM Internship Scheme';

  @override
  String get notifSeed5Body => 'Application window will close soon';

  @override
  String get notifSeed6Title => 'New Update on Ayushman Bharat Yojana';

  @override
  String get notifSeed6Body =>
      'Changes in empanelment process for hospitals. Check full details.';

  @override
  String get notifSeed7Title => 'Income Limit Revised for Several Schemes';

  @override
  String get notifSeed7Body =>
      'Revised income criteria effective from 1st April 2024 for multiple schemes.';

  @override
  String get notifSeed8Body =>
      'Add your income details to find schemes you are eligible for.';

  @override
  String get commonUserFallback => 'User';

  @override
  String get searchHintFallback => 'Search PMEGP, Startup India, MSME loans...';

  @override
  String searchBestMatchesForQuery(Object query) {
    return 'Best matches for \"$query\"';
  }

  @override
  String get searchBestMatchesForCriteria =>
      'Best matches for your search criteria';

  @override
  String searchResultsShareHeader(Object title) {
    return 'Explore $title on MSME Scheme Sahayak:';
  }

  @override
  String get savedRemoveFromSavedTooltip => 'Remove from saved';

  @override
  String get savedRemoveFromRecentTooltip => 'Remove from recently viewed';

  @override
  String get savedInactiveBadge => 'Inactive';

  @override
  String get savedInactiveHint =>
      'This scheme is no longer active in the latest catalog.';

  @override
  String get savedKeepListUpdated => 'Keep your list updated!';

  @override
  String get savedRemoveNoLongerInterested =>
      'Remove schemes you\'re no longer interested in';

  @override
  String get eduSchool => 'School (10th / 12th)';

  @override
  String get eduDiploma => 'Diploma / ITI';

  @override
  String get eduUndergraduate => 'Undergraduate (Degree)';

  @override
  String get eduPostgraduate => 'Postgraduate (Master)';

  @override
  String get eduPhd => 'Ph.D. / Doctorate';

  @override
  String get commGeneralOc => 'General (OC)';

  @override
  String get commObcBcMbc => 'OBC / BC / MBC';

  @override
  String get commScCategory => 'SC';

  @override
  String get commStCategory => 'ST';

  @override
  String get commEwsCategory => 'EWS';

  @override
  String get commMinority => 'Minority';

  @override
  String get incomeNone => 'No Income';

  @override
  String get incomeUnder15L => 'Under ₹1.5 Lakhs';

  @override
  String get income15to3L => '₹1.5L - ₹3 Lakhs';

  @override
  String get income3to6L => '₹3L - ₹6 Lakhs';

  @override
  String get income6to10L => '₹6L - ₹10 Lakhs';

  @override
  String get incomeAbove10L => 'Above ₹10 Lakhs';

  @override
  String get profilePrivacyNoteDpdpa =>
      'DPDPA 2023: Used only to match you with welfare schemes. Never shared.';

  @override
  String get profileConsentSectionTitle => 'Privacy & Data';

  @override
  String get profileConsentCheckboxLabel =>
      'By completing your profile, you agree that MSS collects and processes your information to create your profile and provide personalized Government scheme recommendations.';

  @override
  String get profileConsentReadMore => 'Read how your data is used →';

  @override
  String get profileConsentPleaseConsent => 'Please consent to continue';

  @override
  String get profileConsentRequiredToast =>
      'Please consent to data processing to continue.';

  @override
  String get legalAccept => 'Accept';

  @override
  String get legalScrollToEndNotice =>
      'You must scroll to the end of this document before you can accept it.';

  @override
  String get legalScrollToEndHint => 'Scroll to the end to enable Accept';

  @override
  String get simpleProfileTitle => 'Quick Profile Setup';

  @override
  String get simpleProfileSubtitle =>
      'Answer 6 simple questions to discover your schemes';

  @override
  String get simpleProfileStepStateTitle => 'Where do you live?';

  @override
  String get simpleProfileStepStateSubtitle =>
      'Select your home state for local state schemes';

  @override
  String get simpleProfileStepGenderAgeTitle => 'About You';

  @override
  String get simpleProfileStepGenderAgeSubtitle => 'Select your gender and age';

  @override
  String get simpleProfileStepWorkTitle => 'What is your work or plan?';

  @override
  String get simpleProfileStepWorkSubtitle =>
      'Choose the option that describes you best';

  @override
  String get simpleProfileStepSectorTitle => 'Which sector or field?';

  @override
  String get simpleProfileStepSectorSubtitle =>
      'Select your primary trade or work area';

  @override
  String get simpleProfileStepCommunityTitle => 'Your Social Category';

  @override
  String get simpleProfileStepCommunitySubtitle =>
      'Government schemes provide special subsidies for specific categories';

  @override
  String get simpleProfileStepEducationTitle => 'Your Education Level';

  @override
  String get simpleProfileStepEducationSubtitle =>
      'Select your highest completed qualification';

  @override
  String get stateTamilNadu => 'Tamil Nadu';

  @override
  String get stateMaharashtra => 'Maharashtra';

  @override
  String get stateUttarPradesh => 'Uttar Pradesh';

  @override
  String get stateKarnataka => 'Karnataka';

  @override
  String get stateGujarat => 'Gujarat';

  @override
  String get stateOther => 'Other States';

  @override
  String get searchStateOrUtPlaceholder => 'Search state or UT';

  @override
  String get ageYearsLabel => 'years';

  @override
  String get workNewBusiness => 'Want to start a business';

  @override
  String get workNewBusinessDesc => 'Have an idea or starting a new venture';

  @override
  String get workExistingBusiness => 'Running a shop or business';

  @override
  String get workExistingBusinessDesc =>
      'Own an operational trade or enterprise';

  @override
  String get workFarmer => 'Farming & Agriculture';

  @override
  String get workFarmerDesc => 'Crops, dairy, poultry, or allied farming';

  @override
  String get workArtisan => 'Artisan, Handloom & Crafts';

  @override
  String get workArtisanDesc =>
      'Weaving, pottery, handicrafts, or trade crafts';

  @override
  String get workStudent => 'Student';

  @override
  String get workStudentDesc => 'Enrolled in school, college, or training';

  @override
  String get sectorAgri => 'Agriculture & Dairy';

  @override
  String get sectorManufacturing => 'Manufacturing & Workshop';

  @override
  String get sectorRetail => 'Retail, Shop & Trading';

  @override
  String get sectorTextiles => 'Textiles & Handloom';

  @override
  String get sectorFood => 'Food Processing & Eatery';

  @override
  String get sectorServices => 'Services & Digital Tech';

  @override
  String get sectorHandicrafts => 'Handicrafts & Art';

  @override
  String get sectorGeneral => 'General / Any Sector';

  @override
  String simpleProfileStepIndicator(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get actionNext => 'Next';

  @override
  String get actionBack => 'Back';

  @override
  String get actionFinish => 'Find My Schemes';

  @override
  String get actionSaving => 'Saving...';

  @override
  String get regionSouthIndia => 'South India';

  @override
  String get regionWestIndia => 'West India';

  @override
  String get regionNorthIndia => 'North India';

  @override
  String get regionAllIndia => 'All India';

  @override
  String get ageSelectLabel => 'Your Age';

  @override
  String get commDescObc => 'Backward / Most Backward Class';

  @override
  String get commDescSc => 'Scheduled Caste';

  @override
  String get commDescSt => 'Scheduled Tribe';

  @override
  String get commDescMinority =>
      'Muslim, Christian, Sikh, Jain, Buddhist, Parsi';

  @override
  String get commDescGeneral => 'Open Category';

  @override
  String get eduDescSchool => 'Up to 10th or 12th standard';

  @override
  String get eduDescDiploma => 'Polytechnic or vocational certificate';

  @override
  String get eduDescUndergraduate =>
      'Bachelor degree (BA, BSc, BCom, BE, etc.)';

  @override
  String get eduDescPostgraduate => 'Master degree, MPhil, or Ph.D.';

  @override
  String get hintAgeExample => 'e.g. 25';

  @override
  String get hintAddressExample => 'e.g. Door/Flat No, Street Name, Locality';

  @override
  String get hintCityExample => 'e.g. Chennai';

  @override
  String get legalPrivacyNoticeLink => 'Privacy Notice';

  @override
  String get legalTermsOfUseLink => 'Terms of Use';

  @override
  String get shareSchemeDetailsTooltip => 'Share scheme details';

  @override
  String get legalConsentPrefix => 'I have read and agree to the ';

  @override
  String get legalConsentMid => ' and acknowledge the ';

  @override
  String get legalConsentSuffix => '.';

  @override
  String get permLocationOffTitle => 'Location Services Off';

  @override
  String get permLocationOffBody =>
      'Location services are turned off. Please turn them on in your system settings to discover local state & district schemes tailored for you.';

  @override
  String get permLocationBenefitDetect =>
      'Auto-detect State & District eligibility';

  @override
  String get permLocationBenefitTailored =>
      'Tailored regional subsidies & benefits';

  @override
  String get permLocationTurnOn => 'Turn On Location';

  @override
  String get aboutAppSubtitle =>
      'Government Scheme Discovery & Eligibility Platform';

  @override
  String get aboutDevelopedWith => 'Developed in collaboration with:';

  @override
  String get splashDevelopedBy => 'App developed by';

  @override
  String aboutSupportLine(Object email) {
    return 'Support: $email';
  }

  @override
  String catalogFreshnessLabel(Object version) {
    return 'Local catalog $version';
  }

  @override
  String catalogFreshnessLabelUpdated(Object date, Object version) {
    return 'Local catalog $version • updated $date';
  }

  @override
  String get aboutAppDescriptionLong =>
      'MSS is an intelligent digital platform designed to bridge the awareness gap and simplify the discovery, eligibility matching, and application process for Central and State Government schemes for Indian entrepreneurs, women, farmers, and students.';

  @override
  String get schemeSectionContacts => 'Contact details';

  @override
  String get schemeSectionStatus => 'Status and updates';

  @override
  String get schemeSectionBenefitFacts => 'Benefit figures';

  @override
  String get schemeSectionApplyInfo => 'Fees and requirements';

  @override
  String get schemeSectionRelated => 'Related schemes';

  @override
  String get schemeSectionAltNames => 'Also known as';

  @override
  String get schemeSectionLinks => 'Official links';

  @override
  String get schemeContactPhone => 'Phone';

  @override
  String get schemeContactHelpline => 'Helpline';

  @override
  String get schemeContactEmail => 'Email';

  @override
  String get schemeContactWebsite => 'Website';

  @override
  String get schemeContactOffice => 'Office';

  @override
  String get schemeContactAddress => 'Address';

  @override
  String get schemeContactHours => 'Hours';

  @override
  String schemeStatusAsOf(String date) {
    return 'As of $date';
  }

  @override
  String schemeApplicationStatus(String status) {
    return 'Applications: $status';
  }

  @override
  String get schemeAppStatusOpen => 'Open';

  @override
  String get schemeAppStatusClosed => 'Closed';

  @override
  String get schemeAppStatusAnnounced => 'Announced';

  @override
  String get schemeAppStatusHistorical => 'Historical or superseded';

  @override
  String get schemeAppStatusUnavailable => 'Temporarily unavailable';

  @override
  String get schemeAppStatusUnknown => 'Not confirmed';

  @override
  String get officialInfoButton => 'Official information';

  @override
  String get schemeDeadline => 'Deadline';

  @override
  String get schemeFees => 'Fees';

  @override
  String get schemePrerequisite => 'Prerequisite';

  @override
  String get schemeProcedureOfficial => 'Procedure from official sources';

  @override
  String get schemeProcedurePolicy => 'Procedure inferred from policy text';

  @override
  String get schemeProcedureSecondary => 'Procedure from secondary web sources';

  @override
  String get schemeProcedureGeneric => 'General guidance only';

  @override
  String get schemeLinkApply => 'Apply';

  @override
  String get schemeLinkInfo => 'Scheme information';

  @override
  String get schemeLinkGuidelines => 'Guidelines';

  @override
  String schemeTranslationNotice(String language) {
    return 'This $language text is machine-translated and has not been reviewed yet.';
  }

  @override
  String get schemeFactMax => 'Maximum';

  @override
  String get schemeFactMin => 'Minimum';

  @override
  String get schemeFactAmount => 'Amount';

  @override
  String get schemeFactPercent => 'Percentage';

  @override
  String get schemeFactTenure => 'Tenure';

  @override
  String get schemeFactInterest => 'Interest rate';

  @override
  String get schemeFactCoverage => 'Coverage';

  @override
  String get schemeFactMaxCover => 'Maximum cover';

  @override
  String get schemeFactFee => 'Fee';

  @override
  String get schemeFactMoratorium => 'Moratorium';

  @override
  String get schemeFactDuration => 'Duration';

  @override
  String schemeMonthsValue(int count) {
    return '$count months';
  }

  @override
  String get schemeLinkPortal => 'Official portal';

  @override
  String get schemeLinkPortalLogin => 'Portal login';

  @override
  String get schemeLinkPortalServices => 'Portal services';

  @override
  String get passwordSetting => 'Password';

  @override
  String get activeSessionsSetting => 'Active Sessions';

  @override
  String get setPasswordTitle => 'Set Password';

  @override
  String get changePasswordTitle => 'Change Password';

  @override
  String get removePasswordTitle => 'Remove Password';

  @override
  String get currentPasswordLabel => 'Current Password';

  @override
  String get newPasswordLabel => 'New Password';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get passwordChangedNotice => 'Password updated. Please sign in again.';

  @override
  String get revokeSession => 'Revoke';

  @override
  String get logoutAllSessions => 'Log Out All Devices';

  @override
  String get sessionCurrent => 'Current Device';

  @override
  String get noActiveSessions => 'No active sessions found.';

  @override
  String get passwordRemovedNotice => 'Password removed. Please sign in again.';

  @override
  String get signInWithPassword => 'Sign in with password';

  @override
  String get pwInvalidEmail => 'Please enter a valid email address.';

  @override
  String get pwEnterPassword => 'Please enter your password.';

  @override
  String get pwLoginFailed =>
      'Sign-in failed. Please check your email and password.';

  @override
  String get pwInvalidCredentials => 'Invalid email or password.';

  @override
  String get pwTooManyAttempts =>
      'Too many attempts. Please wait and try again.';

  @override
  String get pwLoginUnexpected => 'Something went wrong while signing in.';

  @override
  String get pwSignInButton => 'Sign In';

  @override
  String get pwLengthRule => 'Password must be 15 to 128 characters long.';

  @override
  String get pwMismatch => 'New password and confirmation do not match.';

  @override
  String get pwEnterCurrent => 'Please enter your current password.';

  @override
  String get pwReauthRequired =>
      'For your security, please sign in again first.';

  @override
  String get pwPolicyFailed => 'Password does not meet the requirements.';

  @override
  String get pwCurrentIncorrect => 'Current password is incorrect.';

  @override
  String get pwUpdateFailed => 'Could not update the password.';

  @override
  String get pwRemoveNeedsCurrent =>
      'Enter your current password to remove it.';

  @override
  String get pwRemoveFailed => 'Could not remove the password.';

  @override
  String get pwMinHint => 'At least 15 characters';

  @override
  String pwLengthProgress(int count) {
    return '$count of 15 characters minimum';
  }

  @override
  String get pwLongTip =>
      'Long is strong: a few words you remember, like “mango tree near the temple”, work well.';

  @override
  String get sessionRevoked => 'Session revoked.';

  @override
  String get sessionRevokeFailed => 'Unable to revoke the session.';

  @override
  String get logoutAllFailed => 'Unable to log out all devices.';

  @override
  String get sessionOtherDevice => 'Signed-in device';

  @override
  String sessionSignedInAt(String time) {
    return 'Signed in: $time';
  }

  @override
  String get udyamMicro => 'MICRO Enterprise';

  @override
  String get udyamSmall => 'SMALL Enterprise';

  @override
  String get udyamMedium => 'MEDIUM Enterprise';

  @override
  String get udyamLarge => 'Large Enterprise (Beyond MSME Limits)';

  @override
  String get udyamInvalid => 'Invalid Input';

  @override
  String get udyamInvalidSub => 'Enter numbers of 0 or more.';

  @override
  String udyamLimitsSummary(
    String microInv,
    String microTurn,
    String smallInv,
    String smallTurn,
    String medInv,
    String medTurn,
  ) {
    return 'Limits (2025): Micro ≤$microInv / ≤$microTurn Cr · Small ≤$smallInv / ≤$smallTurn Cr · Medium ≤$medInv / ≤$medTurn Cr (investment / turnover)';
  }

  @override
  String get schemeNotMatchingFilters => 'Doesn\'t match your filters';

  @override
  String get greetingLateNight => 'Hello,';

  @override
  String get copyChecklistTooltip => 'Copy checklist';

  @override
  String get voiceClipError =>
      'Could not process your request. Check microphone permission or your connection. You can retry the same recording, change its language, or type your request.';

  @override
  String get voiceRecordTitle => 'Record your request';

  @override
  String get voiceRecordDisclosure =>
      'Choose the language you will speak. Record up to 60 seconds, then review the text before sending. Your recording is uploaded to Sarvam for transcription. It is kept in this screen only until you close it.';

  @override
  String get voiceSpokenLanguage => 'Spoken language';

  @override
  String get voiceTranscribingClip =>
      'Transcribing your recording. This may take a few minutes. You can cancel and type instead.';

  @override
  String get voiceRecordingClip =>
      'Recording — tap Stop when you finish (60-second limit).';

  @override
  String get voiceReviewTranscript => 'Review and edit your request';

  @override
  String get voiceStopAndTranscribe => 'Stop and transcribe';

  @override
  String get voiceRecordClip => 'Record a new request';

  @override
  String get voiceRetryClip => 'Transcribe this recording again';

  @override
  String get voiceSendReviewed => 'Send reviewed request';

  @override
  String get liveVoiceReady => 'Ready to talk';

  @override
  String get liveVoiceConnecting => 'Starting microphone…';

  @override
  String get liveVoiceListening => 'Listening';

  @override
  String get liveVoiceTranscribing => 'Finishing your request…';

  @override
  String get liveVoiceThinking => 'Finding an answer…';

  @override
  String get liveVoiceSpeaking => 'Saarthi is speaking';

  @override
  String get liveVoicePaused => 'Conversation paused';

  @override
  String get liveVoiceError => 'Voice needs attention';

  @override
  String get liveVoiceEnd => 'End';

  @override
  String get liveVoicePause => 'Pause conversation';

  @override
  String get liveVoiceResume => 'Resume listening';

  @override
  String get liveVoiceHeard => 'What I heard';

  @override
  String get liveVoiceFinish => 'Finish speaking';

  @override
  String get liveVoiceCorrect => 'Correct request';

  @override
  String get liveVoiceType => 'Type instead';

  @override
  String get liveVoiceRepeat => 'Hear reply again';

  @override
  String get liveVoiceEditRequest => 'Your request';

  @override
  String get liveVoiceEditingHint =>
      'The microphone is paused. Edit your words, then send.';

  @override
  String get liveVoiceOptions => 'Voice options';

  @override
  String get liveVoiceLongPauses => 'Allow longer pauses';

  @override
  String get liveVoiceLongPausesHint =>
      'Take more time between words before Saarthi replies.';

  @override
  String get liveVoiceReadAloud => 'Read replies aloud';

  @override
  String get liveVoiceReview => 'Review before sending';

  @override
  String get liveVoiceReviewHint =>
      'Check and correct each transcript before it is sent.';

  @override
  String get liveVoiceConversationHint =>
      'Speak, then pause. Saarthi replies and listens again. Pause whenever you need; correct or type your request below.';

  @override
  String get liveVoiceScreenReaderHint =>
      'The microphone stays paused after each reply so your screen reader can finish. Choose Resume listening when you are ready.';

  @override
  String get liveVoiceMicrophonePermission =>
      'Allow microphone access in your device settings, then resume. You can also type your request.';

  @override
  String get liveVoiceNoSpeech =>
      'No speech was heard. Resume to try again, or type your request.';

  @override
  String get liveVoiceConnectionError =>
      'Voice could not finish. Check your connection, then resume or type your request.';

  @override
  String get liveVoiceTitle => 'Saarthi';

  @override
  String get liveVoiceLatest => 'Latest reply';

  @override
  String get liveVoiceScreenReaderShort =>
      'Screen reader mode: resume after each reply.';

  @override
  String get liveVoiceFinalTimeout =>
      'The transcript did not finish. Correct the words we heard, or resume to try again.';

  @override
  String get liveVoiceSpeechUnavailable =>
      'I couldn’t play the audio. Your reply is below. Tap Hear reply again to retry, and check your media volume.';

  @override
  String get notifDetailTitle => 'Notification';

  @override
  String get notifDeleteThis => 'Delete this notification';

  @override
  String get notifDeletedToast => 'Notification deleted';

  @override
  String notifReceivedOn(String date) {
    return 'Received $date';
  }

  @override
  String get notifToday => 'Today';

  @override
  String get notifYesterday => 'Yesterday';

  @override
  String get notifEarlier => 'Earlier';

  @override
  String get settingsHapticsTitle => 'Haptic feedback';

  @override
  String get settingsHapticsSubtitle =>
      'Vibrate lightly on taps and when a notification arrives';

  @override
  String get homeFeaturedBestForYou => 'Best for you';

  @override
  String get homeFeaturedNewlyAdded => 'Newly added';

  @override
  String homeFeaturedAddedOn(String date) {
    return 'Added $date';
  }

  @override
  String get homeTip2 =>
      'Udyam registration is free. Most MSME schemes ask for your Udyam number.';

  @override
  String get homeTip3 =>
      'Keep your Aadhaar, PAN and bank details ready before you start an application.';

  @override
  String get homeTip4 =>
      'Under CGTMSE, micro and small enterprises can get loans without collateral.';

  @override
  String get homeTip5 =>
      'Complete your profile to get better scheme matches in MSS.';

  @override
  String get homeTip6 =>
      'Check a scheme\'s last date before applying. Some schemes stay open only for a few weeks.';

  @override
  String get homeTip7 =>
      'Tap the bookmark on a scheme to keep it in Saved for later.';

  @override
  String get homeTip8 =>
      'Buyers paying late? MSME Samadhaan lets micro and small enterprises file a delayed-payment case online.';

  @override
  String get homeTip9 =>
      'DPIIT-recognised startups can apply to the Startup India Seed Fund Scheme.';

  @override
  String get homeTip10 =>
      'Apply only through the official scheme link. Never pay an agent for a free government service.';

  @override
  String get homeTourFindTitle => 'Find a Scheme';

  @override
  String get homeTourFindBody =>
      'Search by scheme name, keyword, or benefit to find relevant government schemes and support.';

  @override
  String get homeTourAskTitle => 'Ask Saarthi';

  @override
  String get homeTourAskBody =>
      'Get quick answers to your questions about government schemes, eligibility, required documents, and application procedures.';

  @override
  String get homeTourDiscoverTitle => 'Discover';

  @override
  String get homeTourDiscoverBody =>
      'Explore schemes and support categories to find opportunities for financial assistance, business growth, registration, training, and more.';

  @override
  String get homeTourProfileTitle => 'Edit Your Profile';

  @override
  String get homeTourProfileBody =>
      'Update your personal and business details to help us provide more relevant scheme recommendations.';

  @override
  String homeTourProgress(int current, int total) {
    return '$current of $total';
  }

  @override
  String get homeTourSkip => 'Skip';

  @override
  String get homeTourNext => 'Next';

  @override
  String get homeTourFinish => 'Finish';

  @override
  String get verificationStatusVerified => 'Verified';

  @override
  String get verificationStatusNotIndependentlyVerified =>
      'Not independently verified';

  @override
  String get deleteAccountScreenTitle => 'Deleting your account';

  @override
  String get deleteAccountStepRemoving => 'Removing your account';

  @override
  String get deleteAccountStepVerifying => 'Checking that it is gone';

  @override
  String get deleteAccountStepClearing => 'Clearing this phone';

  @override
  String get deleteAccountDone => 'Your account was deleted';

  @override
  String get deleteAccountFailedTitle => 'Your account was not deleted';

  @override
  String get deleteAccountRetry => 'Try again';

  @override
  String get deleteAccountBack => 'Back to settings';

  @override
  String get deleteAccountSignOutAgain => 'Sign out and sign in again';

  @override
  String get deleteAccountKeepOpen => 'Please keep the app open.';

  @override
  String get deleteAccountErrReauth =>
      'For your security, sign in again and then delete your account within 5 minutes. Nothing was changed.';

  @override
  String get deleteAccountErrRateLimited =>
      'Too many attempts. Wait a minute and try again. Nothing was changed.';

  @override
  String get deleteAccountErrUnavailable =>
      'Account deletion is temporarily unavailable. Try again later. Nothing was changed.';

  @override
  String get deleteAccountErrOffline =>
      'Account deletion needs an internet connection. Nothing was changed.';

  @override
  String get deleteAccountErrNotVerified =>
      'The server still shows your account. Try again; if it keeps happening, contact support.';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String updateAvailableMessage(Object version) {
    return 'MSS version $version is ready. Download it to get the latest fixes and schemes.';
  }

  @override
  String get updateActionUpdate => 'Update';

  @override
  String get updateActionLater => 'Later';

  @override
  String get updateOpenFailed =>
      'Couldn\'t open the download page. Try again later.';

  @override
  String get settingsCheckUpdates => 'Check for updates';

  @override
  String settingsInstalledVersion(Object version) {
    return 'Installed: $version';
  }

  @override
  String get updateWhatsNew => 'What\'s new in this version';

  @override
  String get integrityTitle => 'MSS can\'t run on this phone right now';

  @override
  String get integritySubtitle =>
      'To keep your scheme details and account safe, fix the problem below. MSS opens by itself once it\'s fixed.';

  @override
  String get integrityDevTitle => 'Developer options are on';

  @override
  String get integrityDevBody =>
      'Turn off Developer options (and USB debugging) in your phone\'s Settings.';

  @override
  String get integrityVpnTitle => 'A VPN is connected';

  @override
  String get integrityVpnBody =>
      'Turn off your VPN to use MSS. Only Tailscale and AdGuard are allowed.';

  @override
  String get integrityWifiTitle => 'You\'re on public Wi-Fi';

  @override
  String get integrityWifiBody =>
      'This Wi-Fi has no password or needs a sign-in page. Switch to mobile data or a password-protected Wi-Fi.';

  @override
  String get integrityOpenDeveloper => 'Open developer settings';

  @override
  String get integrityOpenVpn => 'Open VPN settings';

  @override
  String get integrityOpenWifi => 'Open Wi-Fi settings';

  @override
  String get integrityCheckAgain => 'Check again';

  @override
  String get onbSkip => 'Skip';

  @override
  String onbStep(String step, String total) {
    return '$step / $total';
  }

  @override
  String get onbNext => 'Next';

  @override
  String get onbGetStarted => 'Get Started';

  @override
  String get onbP1Title => 'Government Schemes, Made [Simple]';

  @override
  String get onbP1Body =>
      'Discover government schemes for entrepreneurs, MSMEs, women and students — all in one place.';

  @override
  String onbP1Badge(int count) {
    return '$count+ Verified Schemes';
  }

  @override
  String get onbChipMsme => 'MSME';

  @override
  String get onbChipStartup => 'Startup';

  @override
  String get onbChipLoans => 'Loans';

  @override
  String get onbChipSubsidy => 'Subsidy';

  @override
  String get onbP2Title => 'Too Many Schemes.\n[One Simple Solution.]';

  @override
  String get onbP2Body =>
      'Government schemes can be difficult to find, understand and compare. MSS brings them together in one simple experience.';

  @override
  String get onbP2Badge => 'Find. Understand. Discover.';

  @override
  String get onbChipEligibility => 'Eligibility';

  @override
  String get onbChipIncome => 'Income';

  @override
  String get onbChipDocuments => 'Documents';

  @override
  String get onbChipSubsidies => 'Subsidies';

  @override
  String get onbP3Title => 'Know What You [Qualify] For';

  @override
  String get onbP3Body =>
      'Tell MSS about yourself and discover schemes that match your eligibility — with clear reasons why.';

  @override
  String get onbP3Matches => 'Your Matches';

  @override
  String onbP3Found(int count) {
    return '$count Schemes Found';
  }

  @override
  String get onbP3MayBeEligible => 'You may be eligible';

  @override
  String get onbP3Age => 'Age';

  @override
  String get onbP3Occupation => 'Occupation';

  @override
  String get onbP3Footer => 'No guessing. Just clear answers.';

  @override
  String get onbP4Title => 'Just Ask [Saarthi]';

  @override
  String get onbP4Body =>
      'Get step-by-step guidance through voice — in your language, your way.';

  @override
  String get onbP4SaarthiLabel => 'SAARTHI';

  @override
  String get onbP4Footer => 'Your Language. Your Voice. Your Schemes.';

  @override
  String get permTitle => 'Allow MSS to help you fully';

  @override
  String get permSubtitle =>
      'MSS works without these, but some features need them. You can change them later in your phone\'s Settings.';

  @override
  String get permNotificationsTitle => 'Notifications';

  @override
  String get permNotificationsBody =>
      'Hear about new schemes, deadlines and app updates.';

  @override
  String get permMicrophoneTitle => 'Microphone';

  @override
  String get permMicrophoneBody => 'Talk to Saarthi and search by voice.';

  @override
  String get permInstallTitle => 'Install updates';

  @override
  String get permInstallBody =>
      'Let MSS install its own new versions when you tap Update.';

  @override
  String get permFilesTitle => 'Photos and documents';

  @override
  String get permFilesBody =>
      'Attach or save documents such as your Aadhaar or project report.';

  @override
  String get permAllow => 'Allow';

  @override
  String get permAllowed => 'Allowed';

  @override
  String get permAllowAll => 'Allow all';

  @override
  String get permContinue => 'Continue';

  @override
  String get permNotNow => 'Not now';

  @override
  String get sv2Name => 'Saarthi';

  @override
  String get sv2PoweredBy => 'Powered by Sarvam AI';

  @override
  String get sv2ModeType => 'Type';

  @override
  String get sv2ModeVoice => 'Voice';

  @override
  String sv2TypeGreeting(String name) {
    return 'Hi, $name.\n[How can I help you?]';
  }

  @override
  String get sv2TypeIntro =>
      'Ask about any scheme, loan or subsidy — or start with one of these.';

  @override
  String get sv2ChipPmegp => 'Search PMEGP';

  @override
  String get sv2ChipWomen => 'Schemes for women';

  @override
  String get sv2TypeHint => 'Type here…';

  @override
  String get sv2You => 'You';

  @override
  String get sv2YouVoice => 'You · voice';

  @override
  String get sv2FollowEligible => 'Am I eligible?';

  @override
  String get sv2FollowDocuments => 'Documents needed';

  @override
  String get sv2BestMatch => 'BEST MATCH';

  @override
  String get sv2GoodMatch => 'GOOD MATCH';

  @override
  String get sv2ViewScheme => 'View scheme';

  @override
  String get sv2VoiceIntro => 'I\'m [Saarthi], your scheme companion.';

  @override
  String get sv2AskSaarthi => 'ASK SAARTHI';

  @override
  String get sv2StartTalking => 'Start talking to Saarthi';

  @override
  String sv2Listening(String language) {
    return 'Listening · $language';
  }

  @override
  String get sv2Connecting => 'Connecting…';

  @override
  String get sv2Transcribing => 'Getting your words…';

  @override
  String get sv2YourSpeech => 'YOUR SPEECH';

  @override
  String get sv2TapWhenDone => 'Tap the mic when you\'re done';

  @override
  String get sv2Speak => 'Speak';

  @override
  String get sv2TapToSpeak => 'Tap to speak';

  @override
  String get sv2Send => 'Send this';

  @override
  String get sv2Room => 'Conversation room';

  @override
  String sv2RoomHello(String name) {
    return 'Namaste $name! What would you like help with today?';
  }

  @override
  String get sv2Thinking => 'Saarthi is thinking…';

  @override
  String get sv2Speaking => 'Saarthi is speaking…';

  @override
  String get sv2HearAgain => 'Hear the reply again';

  @override
  String get sv2EndConversation => 'End conversation';

  @override
  String get sv2DocumentsNeeded => 'Documents needed';

  @override
  String sv2DocumentsReady(int ready, int total) {
    return '$ready of $total ready';
  }

  @override
  String get sv2OldSessions => 'Old sessions';

  @override
  String get sv2TypeMessage => 'Type a message to Saarthi';

  @override
  String get sv2HistoryTitle => 'Chat history';

  @override
  String get sv2HistoryOpen => 'Chat history';

  @override
  String get sv2HistorySearch => 'Search conversations';

  @override
  String get sv2HistoryEmpty =>
      'Your conversations with Saarthi will be saved here, on this phone.';

  @override
  String get sv2HistoryNoMatch => 'No conversation matches your search.';

  @override
  String sv2HistorySchemes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count schemes',
      one: '1 scheme',
    );
    return '$_temp0';
  }

  @override
  String sv2HistoryMessages(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messages',
      one: '1 message',
    );
    return '$_temp0';
  }

  @override
  String get sv2HistoryDelete => 'Delete this conversation';

  @override
  String get sv2HistoryDeleted => 'Conversation deleted';

  @override
  String get sv2HistoryClearAll => 'Delete all conversations';

  @override
  String get sv2HistoryClearConfirm =>
      'Delete every saved conversation from this phone?';

  @override
  String get sv2HistoryContinue => 'Continue this conversation';

  @override
  String get sv2VoiceSettings => 'Voice settings';

  @override
  String get sv2VoiceSettingsOpen => 'Voice settings';

  @override
  String get sv2VoiceLanguage => 'Language';

  @override
  String get sv2Autoplay => 'Auto-play replies';

  @override
  String get sv2AutoplayBody => 'Saarthi reads every answer aloud';

  @override
  String get sv2VoiceNote => 'Saarthi\'s voice is chosen for each language.';

  @override
  String get settingsSaarthiVoice => 'Saarthi voice settings';
}
