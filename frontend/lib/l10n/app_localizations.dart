import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('ta'),
  ];

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning,'**
  String get goodMorning;

  /// No description provided for @completeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Your Profile'**
  String get completeYourProfile;

  /// No description provided for @unlockPersonalizedSchemeRecommendations.
  ///
  /// In en, this message translates to:
  /// **'Unlock personalized scheme recommendations.'**
  String get unlockPersonalizedSchemeRecommendations;

  /// No description provided for @applicationsClosingSoon.
  ///
  /// In en, this message translates to:
  /// **'Applications Closing Soon'**
  String get applicationsClosingSoon;

  /// No description provided for @featured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get featured;

  /// No description provided for @forWomenEntrepreneurs.
  ///
  /// In en, this message translates to:
  /// **'For Women Entrepreneurs'**
  String get forWomenEntrepreneurs;

  /// No description provided for @exploreSpecialFundingSchemes.
  ///
  /// In en, this message translates to:
  /// **'Explore special funding schemes'**
  String get exploreSpecialFundingSchemes;

  /// No description provided for @whatWouldYouLikeToDoToday.
  ///
  /// In en, this message translates to:
  /// **'What would you like to do today?'**
  String get whatWouldYouLikeToDoToday;

  /// No description provided for @exportSupport.
  ///
  /// In en, this message translates to:
  /// **'Export Support'**
  String get exportSupport;

  /// No description provided for @exportModuleDescription.
  ///
  /// In en, this message translates to:
  /// **'Global Trade Readiness & Export Incentives'**
  String get exportModuleDescription;

  /// No description provided for @growBusiness.
  ///
  /// In en, this message translates to:
  /// **'Grow Business'**
  String get growBusiness;

  /// No description provided for @registerUdyam.
  ///
  /// In en, this message translates to:
  /// **'Register UDYAM'**
  String get registerUdyam;

  /// No description provided for @udyamModuleDescription.
  ///
  /// In en, this message translates to:
  /// **'Official MSME Registration Guide & Direct Portal Link'**
  String get udyamModuleDescription;

  /// No description provided for @findFunding.
  ///
  /// In en, this message translates to:
  /// **'Find Funding'**
  String get findFunding;

  /// No description provided for @startABusiness.
  ///
  /// In en, this message translates to:
  /// **'Start a Business'**
  String get startABusiness;

  /// No description provided for @exploreMsmeSupport.
  ///
  /// In en, this message translates to:
  /// **'Explore MSME Support'**
  String get exploreMsmeSupport;

  /// No description provided for @schemes.
  ///
  /// In en, this message translates to:
  /// **'Schemes'**
  String get schemes;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @taxGst.
  ///
  /// In en, this message translates to:
  /// **'Tax & GST'**
  String get taxGst;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @treds.
  ///
  /// In en, this message translates to:
  /// **'TReDS'**
  String get treds;

  /// No description provided for @csrSupport.
  ///
  /// In en, this message translates to:
  /// **'CSR Support'**
  String get csrSupport;

  /// No description provided for @govtAuthorities.
  ///
  /// In en, this message translates to:
  /// **'Govt. Authorities'**
  String get govtAuthorities;

  /// No description provided for @institutions.
  ///
  /// In en, this message translates to:
  /// **'Institutions'**
  String get institutions;

  /// No description provided for @recommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended For You'**
  String get recommendedForYou;

  /// No description provided for @homeRecommendationsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to see recommendations'**
  String get homeRecommendationsEmptyMessage;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @latestUpdates.
  ///
  /// In en, this message translates to:
  /// **'Latest Updates'**
  String get latestUpdates;

  /// No description provided for @tipOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Tip of the Day'**
  String get tipOfTheDay;

  /// No description provided for @askAi.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get askAi;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search schemes, benefits or ask anything...'**
  String get searchPlaceholder;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// No description provided for @navSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get navSaved;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @quickPillPmegp.
  ///
  /// In en, this message translates to:
  /// **'Search PMEGP'**
  String get quickPillPmegp;

  /// No description provided for @quickPillStartup.
  ///
  /// In en, this message translates to:
  /// **'Search Startup India'**
  String get quickPillStartup;

  /// No description provided for @quickPillLoans.
  ///
  /// In en, this message translates to:
  /// **'Search MSME Loans'**
  String get quickPillLoans;

  /// No description provided for @quickPillWomen.
  ///
  /// In en, this message translates to:
  /// **'Search Women Entrepreneur Schemes'**
  String get quickPillWomen;

  /// No description provided for @quickPillAscend.
  ///
  /// In en, this message translates to:
  /// **'Search ASCEND Workshops'**
  String get quickPillAscend;

  /// No description provided for @carouselTitleApplicationsClosingSoon.
  ///
  /// In en, this message translates to:
  /// **'Applications Closing Soon'**
  String get carouselTitleApplicationsClosingSoon;

  /// No description provided for @carouselSubPmegpDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'PMEGP · 2 days left'**
  String get carouselSubPmegpDaysLeft;

  /// No description provided for @carouselTitlePmegpClosing.
  ///
  /// In en, this message translates to:
  /// **'PMEGP (Closing in 5 Days)'**
  String get carouselTitlePmegpClosing;

  /// No description provided for @carouselBadgeAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get carouselBadgeAlert;

  /// No description provided for @carouselTitleNewScheme.
  ///
  /// In en, this message translates to:
  /// **'New Scheme'**
  String get carouselTitleNewScheme;

  /// No description provided for @carouselSubTnExport.
  ///
  /// In en, this message translates to:
  /// **'TN Export Promotion Scheme'**
  String get carouselSubTnExport;

  /// No description provided for @carouselBadgeNewScheme.
  ///
  /// In en, this message translates to:
  /// **'New Scheme'**
  String get carouselBadgeNewScheme;

  /// No description provided for @carouselTitleImportantUpdate.
  ///
  /// In en, this message translates to:
  /// **'Important Update'**
  String get carouselTitleImportantUpdate;

  /// No description provided for @carouselSubUdyamProcess.
  ///
  /// In en, this message translates to:
  /// **'UDYAM registration process updated'**
  String get carouselSubUdyamProcess;

  /// No description provided for @carouselBadgeNotify.
  ///
  /// In en, this message translates to:
  /// **'Notify'**
  String get carouselBadgeNotify;

  /// No description provided for @subsidiesGrantsGovtSchemes.
  ///
  /// In en, this message translates to:
  /// **'Subsidies, grants & government schemes'**
  String get subsidiesGrantsGovtSchemes;

  /// No description provided for @loansCreditSupportFundingOptions.
  ///
  /// In en, this message translates to:
  /// **'Loans, credit support & funding options'**
  String get loansCreditSupportFundingOptions;

  /// No description provided for @taxBenefitsGstSupportCompliance.
  ///
  /// In en, this message translates to:
  /// **'Tax benefits, GST support & compliance'**
  String get taxBenefitsGstSupportCompliance;

  /// No description provided for @exportIncentivesFinanceMarketSupport.
  ///
  /// In en, this message translates to:
  /// **'Export incentives, finance & market support'**
  String get exportIncentivesFinanceMarketSupport;

  /// No description provided for @invoiceDiscountingWorkingCapital.
  ///
  /// In en, this message translates to:
  /// **'Invoice discounting & working capital solutions'**
  String get invoiceDiscountingWorkingCapital;

  /// No description provided for @csrProgramsIncubatorsClusterSupport.
  ///
  /// In en, this message translates to:
  /// **'CSR programs, incubators & cluster support'**
  String get csrProgramsIncubatorsClusterSupport;

  /// No description provided for @centralStateDistrictGovtStructure.
  ///
  /// In en, this message translates to:
  /// **'Central, State & District government structure'**
  String get centralStateDistrictGovtStructure;

  /// No description provided for @sidbiNsicDicKvicMoreOrganizations.
  ///
  /// In en, this message translates to:
  /// **'SIDBI, NSIC, DIC, KVIC & more organizations'**
  String get sidbiNsicDicKvicMoreOrganizations;

  /// No description provided for @tipOfTheDayContent.
  ///
  /// In en, this message translates to:
  /// **'Women Entrepreneurs may receive additional subsidy under PMEGP.'**
  String get tipOfTheDayContent;

  /// No description provided for @tagNewScheme.
  ///
  /// In en, this message translates to:
  /// **'New Scheme'**
  String get tagNewScheme;

  /// No description provided for @tagUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get tagUpdate;

  /// No description provided for @tagReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get tagReminder;

  /// No description provided for @tagAlert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get tagAlert;

  /// No description provided for @fallbackLatestUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Fisheries and Aquaculture Infra Development Fund Scheme Launched'**
  String get fallbackLatestUpdateTitle;

  /// No description provided for @time2DaysAgo.
  ///
  /// In en, this message translates to:
  /// **'2 days ago'**
  String get time2DaysAgo;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @trySearchPrefix.
  ///
  /// In en, this message translates to:
  /// **'Try:'**
  String get trySearchPrefix;

  /// No description provided for @quickFiltersHeader.
  ///
  /// In en, this message translates to:
  /// **'Quick Filters'**
  String get quickFiltersHeader;

  /// No description provided for @sortByPrefix.
  ///
  /// In en, this message translates to:
  /// **'Sort by:'**
  String get sortByPrefix;

  /// No description provided for @sortMatchPercent.
  ///
  /// In en, this message translates to:
  /// **'Match %'**
  String get sortMatchPercent;

  /// No description provided for @sortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Scheme Name (A-Z)'**
  String get sortNameAsc;

  /// No description provided for @sortNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Scheme Name (Z-A)'**
  String get sortNameDesc;

  /// No description provided for @browseCategories.
  ///
  /// In en, this message translates to:
  /// **'Browse Categories'**
  String get browseCategories;

  /// No description provided for @forMe.
  ///
  /// In en, this message translates to:
  /// **'For Me'**
  String get forMe;

  /// No description provided for @activeBadge.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeBadge;

  /// No description provided for @calculatingMatches.
  ///
  /// In en, this message translates to:
  /// **'Calculating matches...'**
  String get calculatingMatches;

  /// No description provided for @schemesMatchProfile.
  ///
  /// In en, this message translates to:
  /// **'{count} schemes match your profile.'**
  String schemesMatchProfile(Object count);

  /// No description provided for @noSchemesFound.
  ///
  /// In en, this message translates to:
  /// **'No schemes found for \"{query}\"'**
  String noSchemesFound(Object query);

  /// No description provided for @tryDifferentKeyword.
  ///
  /// In en, this message translates to:
  /// **'Try a different keyword or browse categories.'**
  String get tryDifferentKeyword;

  /// No description provided for @searchDidYouMean.
  ///
  /// In en, this message translates to:
  /// **'Did you mean \"{suggestion}\"?'**
  String searchDidYouMean(Object suggestion);

  /// No description provided for @resultsFor.
  ///
  /// In en, this message translates to:
  /// **'{count} results for \"{query}\"'**
  String resultsFor(Object count, Object query);

  /// No description provided for @matchScorePercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Match'**
  String matchScorePercent(Object percent);

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterCentral.
  ///
  /// In en, this message translates to:
  /// **'Central'**
  String get filterCentral;

  /// No description provided for @filterState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get filterState;

  /// No description provided for @filterLoan.
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get filterLoan;

  /// No description provided for @filterUdyam.
  ///
  /// In en, this message translates to:
  /// **'Udyam'**
  String get filterUdyam;

  /// No description provided for @filterStartup.
  ///
  /// In en, this message translates to:
  /// **'Startup'**
  String get filterStartup;

  /// No description provided for @filterSubsidy.
  ///
  /// In en, this message translates to:
  /// **'Subsidy'**
  String get filterSubsidy;

  /// No description provided for @filterCollateralFree.
  ///
  /// In en, this message translates to:
  /// **'Collateral-Free'**
  String get filterCollateralFree;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @browseByCategories.
  ///
  /// In en, this message translates to:
  /// **'Browse by Categories'**
  String get browseByCategories;

  /// No description provided for @featuredCollections.
  ///
  /// In en, this message translates to:
  /// **'Featured Collections'**
  String get featuredCollections;

  /// No description provided for @browseByMinistry.
  ///
  /// In en, this message translates to:
  /// **'Browse by Ministry'**
  String get browseByMinistry;

  /// No description provided for @browseByState.
  ///
  /// In en, this message translates to:
  /// **'Browse by State'**
  String get browseByState;

  /// No description provided for @smartAssessment.
  ///
  /// In en, this message translates to:
  /// **'Smart Assessment'**
  String get smartAssessment;

  /// No description provided for @viewAllCategories.
  ///
  /// In en, this message translates to:
  /// **'View All Categories'**
  String get viewAllCategories;

  /// No description provided for @schemeCountFormat.
  ///
  /// In en, this message translates to:
  /// **'{count} Schemes'**
  String schemeCountFormat(Object count);

  /// No description provided for @exploreTopCuratedCollections.
  ///
  /// In en, this message translates to:
  /// **'Explore top curated collections'**
  String get exploreTopCuratedCollections;

  /// No description provided for @schemesByGovernmentMinistries.
  ///
  /// In en, this message translates to:
  /// **'Schemes by Government Ministries'**
  String get schemesByGovernmentMinistries;

  /// No description provided for @schemesByStatesAndUnionTerritories.
  ///
  /// In en, this message translates to:
  /// **'Schemes by States & Union Territories'**
  String get schemesByStatesAndUnionTerritories;

  /// No description provided for @personalizedRecommendationMatches.
  ///
  /// In en, this message translates to:
  /// **'Personalized recommendation matches'**
  String get personalizedRecommendationMatches;

  /// No description provided for @savedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Schemes'**
  String get savedTitle;

  /// No description provided for @allSavedTabFormat.
  ///
  /// In en, this message translates to:
  /// **'All Saved ({count})'**
  String allSavedTabFormat(Object count);

  /// No description provided for @recentlyViewedTab.
  ///
  /// In en, this message translates to:
  /// **'Recently viewed'**
  String get recentlyViewedTab;

  /// No description provided for @loginChecklistTerms.
  ///
  /// In en, this message translates to:
  /// **'Read the Terms of Use'**
  String get loginChecklistTerms;

  /// No description provided for @loginChecklistPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Read the Privacy Policy'**
  String get loginChecklistPrivacy;

  /// No description provided for @loginChecklistAgree.
  ///
  /// In en, this message translates to:
  /// **'Agree to continue'**
  String get loginChecklistAgree;

  /// No description provided for @loginOpeningGoogle.
  ///
  /// In en, this message translates to:
  /// **'Opening Google…'**
  String get loginOpeningGoogle;

  /// No description provided for @loginCompletingSignIn.
  ///
  /// In en, this message translates to:
  /// **'Signing you in…'**
  String get loginCompletingSignIn;

  /// No description provided for @betaGatePasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Beta password'**
  String get betaGatePasswordLabel;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @notificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTooltip;

  /// No description provided for @notificationsUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{n} unread'**
  String notificationsUnreadCount(Object n);

  /// No description provided for @quickPillPmegpQuery.
  ///
  /// In en, this message translates to:
  /// **'PMEGP'**
  String get quickPillPmegpQuery;

  /// No description provided for @quickPillStartupQuery.
  ///
  /// In en, this message translates to:
  /// **'Startup'**
  String get quickPillStartupQuery;

  /// No description provided for @quickPillLoansQuery.
  ///
  /// In en, this message translates to:
  /// **'Loans'**
  String get quickPillLoansQuery;

  /// No description provided for @quickPillWomenQuery.
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get quickPillWomenQuery;

  /// No description provided for @quickPillAscendQuery.
  ///
  /// In en, this message translates to:
  /// **'ASCEND'**
  String get quickPillAscendQuery;

  /// No description provided for @homeRecommendedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to see schemes for you'**
  String get homeRecommendedEmptyTitle;

  /// No description provided for @homeRecommendedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add a few details and we will show schemes you may be eligible for.'**
  String get homeRecommendedEmptyBody;

  /// No description provided for @completeProfileCta.
  ///
  /// In en, this message translates to:
  /// **'Complete profile'**
  String get completeProfileCta;

  /// No description provided for @saveSchemeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Save scheme'**
  String get saveSchemeTooltip;

  /// No description provided for @removeSavedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get removeSavedTooltip;

  /// No description provided for @copyLinkTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy link'**
  String get copyLinkTooltip;

  /// No description provided for @shareSchemeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy scheme details'**
  String get shareSchemeTooltip;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @forMeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show only schemes you are eligible for (uses your profile)'**
  String get forMeTooltip;

  /// No description provided for @sortBestMatchNeedsProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to use this'**
  String get sortBestMatchNeedsProfile;

  /// No description provided for @recentlyViewedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing viewed yet'**
  String get recentlyViewedEmptyTitle;

  /// No description provided for @recentlyViewedEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Schemes you open will appear here.'**
  String get recentlyViewedEmptyDesc;

  /// No description provided for @browseSchemes.
  ///
  /// In en, this message translates to:
  /// **'Browse schemes'**
  String get browseSchemes;

  /// No description provided for @schemeRemovedToast.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved'**
  String get schemeRemovedToast;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @applyUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'No official application link yet'**
  String get applyUnavailableHint;

  /// No description provided for @assistedChooseOne.
  ///
  /// In en, this message translates to:
  /// **'Choose one option to continue'**
  String get assistedChooseOne;

  /// No description provided for @ageIncrease.
  ///
  /// In en, this message translates to:
  /// **'Increase age'**
  String get ageIncrease;

  /// No description provided for @ageDecrease.
  ///
  /// In en, this message translates to:
  /// **'Decrease age'**
  String get ageDecrease;

  /// No description provided for @changeProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get changeProfilePhoto;

  /// No description provided for @notifEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'New scheme updates and reminders will show up here.'**
  String get notifEmptyBody;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'Government Scheme Discovery & Eligibility Platform'**
  String get aboutTagline;

  /// No description provided for @aboutDescription.
  ///
  /// In en, this message translates to:
  /// **'MSS is an intelligent digital platform designed to bridge the awareness gap and simplify the discovery, eligibility matching, and application process for Central and State Government schemes for Indian entrepreneurs, women, farmers, and students.'**
  String get aboutDescription;

  /// No description provided for @aboutCreatedBy.
  ///
  /// In en, this message translates to:
  /// **'Developed in collaboration with:'**
  String get aboutCreatedBy;

  /// No description provided for @sarvamPromptDocuments.
  ///
  /// In en, this message translates to:
  /// **'Which documents do I need?'**
  String get sarvamPromptDocuments;

  /// No description provided for @sarvamPromptEligibility.
  ///
  /// In en, this message translates to:
  /// **'Am I eligible for a loan?'**
  String get sarvamPromptEligibility;

  /// No description provided for @noStatesMatch.
  ///
  /// In en, this message translates to:
  /// **'No states match your search'**
  String get noStatesMatch;

  /// No description provided for @homeRecommendationsNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches yet — try Search or Discover'**
  String get homeRecommendationsNoMatches;

  /// No description provided for @noSavedSchemes.
  ///
  /// In en, this message translates to:
  /// **'No Saved Schemes Yet'**
  String get noSavedSchemes;

  /// No description provided for @noSavedSchemesDesc.
  ///
  /// In en, this message translates to:
  /// **'Bookmark schemes while browsing to view them offline anytime.'**
  String get noSavedSchemesDesc;

  /// No description provided for @savedSubtitleCountFormat.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 scheme saved} other{{count} schemes saved}}'**
  String savedSubtitleCountFormat(int count);

  /// No description provided for @savedRecentlyViewedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No Schemes Viewed Yet'**
  String get savedRecentlyViewedEmptyTitle;

  /// No description provided for @savedRecentlyViewedEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Schemes you open appear here'**
  String get savedRecentlyViewedEmptyDesc;

  /// No description provided for @manageSaved.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manageSaved;

  /// No description provided for @doneManaging.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneManaging;

  /// No description provided for @clearAllSaved.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAllSaved;

  /// No description provided for @schemeRemovedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Scheme removed from saved list'**
  String get schemeRemovedSnackbar;

  /// No description provided for @confirmClearSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Saved Schemes'**
  String get confirmClearSavedTitle;

  /// No description provided for @confirmClearSavedMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove all saved schemes?'**
  String get confirmClearSavedMsg;

  /// No description provided for @profileSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileSettingsTitle;

  /// No description provided for @profileGroupHeader.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileGroupHeader;

  /// No description provided for @completeProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfileTitle;

  /// No description provided for @profileCompletionFormat.
  ///
  /// In en, this message translates to:
  /// **'{percent}% completed'**
  String profileCompletionFormat(Object percent);

  /// No description provided for @preferencesGroupHeader.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesGroupHeader;

  /// No description provided for @languageSetting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSetting;

  /// No description provided for @navigationModeSetting.
  ///
  /// In en, this message translates to:
  /// **'Navigation Mode'**
  String get navigationModeSetting;

  /// No description provided for @navigationModeRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get navigationModeRegular;

  /// No description provided for @navigationModeCompanion.
  ///
  /// In en, this message translates to:
  /// **'Companion'**
  String get navigationModeCompanion;

  /// No description provided for @notificationsGroupHeader.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsGroupHeader;

  /// No description provided for @pushNotificationsSetting.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotificationsSetting;

  /// No description provided for @notificationsEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications enabled'**
  String get notificationsEnabled;

  /// No description provided for @notificationsDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notifications disabled'**
  String get notificationsDisabled;

  /// No description provided for @securityPrivacyGroupHeader.
  ///
  /// In en, this message translates to:
  /// **'Security & Privacy'**
  String get securityPrivacyGroupHeader;

  /// No description provided for @privacyPolicySetting.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicySetting;

  /// No description provided for @privacyPolicyContent.
  ///
  /// In en, this message translates to:
  /// **'Your privacy is important to us. All personal data is encrypted and saved locally on this device.'**
  String get privacyPolicyContent;

  /// No description provided for @termsConditionsSetting.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get termsConditionsSetting;

  /// No description provided for @termsConditionsContent.
  ///
  /// In en, this message translates to:
  /// **'By using MSS, you agree to our terms of service. All scheme information is aggregated from official government portals.'**
  String get termsConditionsContent;

  /// No description provided for @deleteAccountSetting.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountSetting;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountMsg.
  ///
  /// In en, this message translates to:
  /// **'Your account will be deleted and you will be signed out. Your data is kept for 30 days, so you can sign in again within 30 days to reactivate it. After that, all your saved profiles, bookmarks and answers are permanently deleted.'**
  String get deleteAccountMsg;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @accountDeletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Account deleted'**
  String get accountDeletedTitle;

  /// No description provided for @accountDeletedMsg.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted and you have been signed out. Your data will not be deleted for 30 days (until {date}). To reactivate your account, just sign in again before then.'**
  String accountDeletedMsg(String date);

  /// No description provided for @accountDeletedNowMsg.
  ///
  /// In en, this message translates to:
  /// **'Your account has been permanently deleted.'**
  String get accountDeletedNowMsg;

  /// No description provided for @accountRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Reactivate your account?'**
  String get accountRestoreTitle;

  /// No description provided for @accountRestoreMsg.
  ///
  /// In en, this message translates to:
  /// **'You deleted this account. Your data is kept until {date}. Reactivate it to continue with your saved profile and schemes.'**
  String accountRestoreMsg(String date);

  /// No description provided for @accountRestoreConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get accountRestoreConfirm;

  /// No description provided for @accountRestoreCancel.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get accountRestoreCancel;

  /// No description provided for @accountRestoredToast.
  ///
  /// In en, this message translates to:
  /// **'Welcome back! Your account is active again.'**
  String get accountRestoredToast;

  /// No description provided for @accountRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not reactivate your account. Please sign in again.'**
  String get accountRestoreFailed;

  /// No description provided for @supportGroupHeader.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get supportGroupHeader;

  /// No description provided for @helpFaqSetting.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get helpFaqSetting;

  /// No description provided for @contactUsSetting.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUsSetting;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButton;

  /// No description provided for @confirmLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogoutTitle;

  /// No description provided for @confirmLogoutMsg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out from MSS?'**
  String get confirmLogoutMsg;

  /// No description provided for @dialogDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get dialogDone;

  /// No description provided for @dialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileVerified.
  ///
  /// In en, this message translates to:
  /// **'Profile complete'**
  String get profileVerified;

  /// No description provided for @profileIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Incomplete'**
  String get profileIncomplete;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @userInformation.
  ///
  /// In en, this message translates to:
  /// **'User Information'**
  String get userInformation;

  /// No description provided for @eligibilityProfessionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Eligibility & Professional Details'**
  String get eligibilityProfessionalDetails;

  /// No description provided for @businessInformation.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get businessInformation;

  /// No description provided for @labelFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get labelFullName;

  /// No description provided for @labelAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get labelAge;

  /// No description provided for @labelGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get labelGender;

  /// No description provided for @labelLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get labelLocation;

  /// No description provided for @labelEducationLevel.
  ///
  /// In en, this message translates to:
  /// **'Education Level'**
  String get labelEducationLevel;

  /// No description provided for @labelEmployment.
  ///
  /// In en, this message translates to:
  /// **'Employment'**
  String get labelEmployment;

  /// No description provided for @labelCommunityCategory.
  ///
  /// In en, this message translates to:
  /// **'Community Category'**
  String get labelCommunityCategory;

  /// No description provided for @labelAnnualIncome.
  ///
  /// In en, this message translates to:
  /// **'Annual Income'**
  String get labelAnnualIncome;

  /// No description provided for @labelDifferentlyAbled.
  ///
  /// In en, this message translates to:
  /// **'Differently Abled'**
  String get labelDifferentlyAbled;

  /// No description provided for @labelExServiceman.
  ///
  /// In en, this message translates to:
  /// **'Ex-Serviceman / Veteran'**
  String get labelExServiceman;

  /// No description provided for @labelBusinessStage.
  ///
  /// In en, this message translates to:
  /// **'Business Stage'**
  String get labelBusinessStage;

  /// No description provided for @labelIndustry.
  ///
  /// In en, this message translates to:
  /// **'Industry'**
  String get labelIndustry;

  /// No description provided for @labelFundingRequired.
  ///
  /// In en, this message translates to:
  /// **'Funding Required'**
  String get labelFundingRequired;

  /// No description provided for @labelRegNumbers.
  ///
  /// In en, this message translates to:
  /// **'Reg. Numbers'**
  String get labelRegNumbers;

  /// No description provided for @subSavedSchemes.
  ///
  /// In en, this message translates to:
  /// **'View your bookmarked schemes'**
  String get subSavedSchemes;

  /// No description provided for @subLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language'**
  String get subLanguage;

  /// No description provided for @subSettings.
  ///
  /// In en, this message translates to:
  /// **'Manage app preferences'**
  String get subSettings;

  /// No description provided for @subPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy and data settings'**
  String get subPrivacy;

  /// No description provided for @subHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Get help and contact support'**
  String get subHelpSupport;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @subAbout.
  ///
  /// In en, this message translates to:
  /// **'About MSS app'**
  String get subAbout;

  /// No description provided for @subLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout from your account'**
  String get subLogout;

  /// No description provided for @aboutAppDescription.
  ///
  /// In en, this message translates to:
  /// **'MSS is an intelligent digital platform to discover, verify eligibility, and access Central and State Government schemes across India.'**
  String get aboutAppDescription;

  /// No description provided for @profilePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Photo'**
  String get profilePhotoTitle;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @empStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get empStudent;

  /// No description provided for @empFarmer.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get empFarmer;

  /// No description provided for @empSalaried.
  ///
  /// In en, this message translates to:
  /// **'Salaried'**
  String get empSalaried;

  /// No description provided for @empSelfEmployed.
  ///
  /// In en, this message translates to:
  /// **'Self-Employed'**
  String get empSelfEmployed;

  /// No description provided for @empUnemployed.
  ///
  /// In en, this message translates to:
  /// **'Unemployed'**
  String get empUnemployed;

  /// No description provided for @empRetired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get empRetired;

  /// No description provided for @commGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get commGeneral;

  /// No description provided for @commObc.
  ///
  /// In en, this message translates to:
  /// **'OBC'**
  String get commObc;

  /// No description provided for @commEws.
  ///
  /// In en, this message translates to:
  /// **'EWS'**
  String get commEws;

  /// No description provided for @commSc.
  ///
  /// In en, this message translates to:
  /// **'SC'**
  String get commSc;

  /// No description provided for @commSt.
  ///
  /// In en, this message translates to:
  /// **'ST'**
  String get commSt;

  /// No description provided for @commOthers.
  ///
  /// In en, this message translates to:
  /// **'Others'**
  String get commOthers;

  /// No description provided for @incUnder1_5.
  ///
  /// In en, this message translates to:
  /// **'Under ₹1.5 Lakhs'**
  String get incUnder1_5;

  /// No description provided for @inc1_5To3.
  ///
  /// In en, this message translates to:
  /// **'₹1.5 Lakhs - ₹3 Lakhs'**
  String get inc1_5To3;

  /// No description provided for @inc3To5.
  ///
  /// In en, this message translates to:
  /// **'₹3 Lakhs - ₹5 Lakhs'**
  String get inc3To5;

  /// No description provided for @inc5To8.
  ///
  /// In en, this message translates to:
  /// **'₹5 Lakhs - ₹8 Lakhs'**
  String get inc5To8;

  /// No description provided for @incAbove8.
  ///
  /// In en, this message translates to:
  /// **'Above ₹8 Lakhs'**
  String get incAbove8;

  /// No description provided for @valYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get valYes;

  /// No description provided for @valNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get valNo;

  /// No description provided for @valNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get valNone;

  /// No description provided for @schemeDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Scheme Details'**
  String get schemeDetailsTitle;

  /// No description provided for @tabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tabOverview;

  /// No description provided for @tabBenefits.
  ///
  /// In en, this message translates to:
  /// **'Benefits'**
  String get tabBenefits;

  /// No description provided for @tabEligibility.
  ///
  /// In en, this message translates to:
  /// **'Eligibility'**
  String get tabEligibility;

  /// No description provided for @tabDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get tabDocuments;

  /// No description provided for @tabServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get tabServices;

  /// No description provided for @tabProcess.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get tabProcess;

  /// No description provided for @schemeAtAGlance.
  ///
  /// In en, this message translates to:
  /// **'Scheme at a glance'**
  String get schemeAtAGlance;

  /// No description provided for @benefitsDetails.
  ///
  /// In en, this message translates to:
  /// **'Benefits Details'**
  String get benefitsDetails;

  /// No description provided for @eligibilityCriteria.
  ///
  /// In en, this message translates to:
  /// **'Eligibility Criteria'**
  String get eligibilityCriteria;

  /// No description provided for @requiredDocuments.
  ///
  /// In en, this message translates to:
  /// **'Required Documents'**
  String get requiredDocuments;

  /// No description provided for @requiredServices.
  ///
  /// In en, this message translates to:
  /// **'Required Services'**
  String get requiredServices;

  /// No description provided for @applicationProcessHeader.
  ///
  /// In en, this message translates to:
  /// **'Application Process'**
  String get applicationProcessHeader;

  /// No description provided for @officialInformation.
  ///
  /// In en, this message translates to:
  /// **'Official scheme information'**
  String get officialInformation;

  /// No description provided for @lastUpdatedFormat.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String lastUpdatedFormat(Object date);

  /// No description provided for @sourceButton.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sourceButton;

  /// No description provided for @applyNowButton.
  ///
  /// In en, this message translates to:
  /// **'Apply Now'**
  String get applyNowButton;

  /// No description provided for @saveSchemeButton.
  ///
  /// In en, this message translates to:
  /// **'Save Scheme'**
  String get saveSchemeButton;

  /// No description provided for @savedSchemeButton.
  ///
  /// In en, this message translates to:
  /// **'Saved Scheme'**
  String get savedSchemeButton;

  /// No description provided for @noVerifiedLink.
  ///
  /// In en, this message translates to:
  /// **'No verified official link is available.'**
  String get noVerifiedLink;

  /// No description provided for @couldNotOpenWebsite.
  ///
  /// In en, this message translates to:
  /// **'Could not open the official website.'**
  String get couldNotOpenWebsite;

  /// No description provided for @noDocumentsPublished.
  ///
  /// In en, this message translates to:
  /// **'No document list is published for this scheme. Check the official source before applying.'**
  String get noDocumentsPublished;

  /// No description provided for @noServicesRequiredMsg.
  ///
  /// In en, this message translates to:
  /// **'No separate service requirement is listed for this scheme.'**
  String get noServicesRequiredMsg;

  /// No description provided for @getDocumentOnline.
  ///
  /// In en, this message translates to:
  /// **'Get Document Online'**
  String get getDocumentOnline;

  /// No description provided for @issuedByFormat.
  ///
  /// In en, this message translates to:
  /// **'Issued by: {authority}'**
  String issuedByFormat(Object authority);

  /// No description provided for @estimatedCostFormat.
  ///
  /// In en, this message translates to:
  /// **'Estimated cost: {cost}'**
  String estimatedCostFormat(Object cost);

  /// No description provided for @verificationNote.
  ///
  /// In en, this message translates to:
  /// **'Verification note'**
  String get verificationNote;

  /// No description provided for @benefitSubsidy.
  ///
  /// In en, this message translates to:
  /// **'Subsidy'**
  String get benefitSubsidy;

  /// No description provided for @benefitAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get benefitAmount;

  /// No description provided for @benefitMaximum.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get benefitMaximum;

  /// No description provided for @benefitSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get benefitSupport;

  /// No description provided for @matchPercentageFormat.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Match'**
  String matchPercentageFormat(Object percent);

  /// No description provided for @schemeCopiedToast.
  ///
  /// In en, this message translates to:
  /// **'Scheme details copied to clipboard'**
  String get schemeCopiedToast;

  /// No description provided for @highlyRelevant.
  ///
  /// In en, this message translates to:
  /// **'Highly relevant'**
  String get highlyRelevant;

  /// No description provided for @levelSchemeFormat.
  ///
  /// In en, this message translates to:
  /// **'{level} Scheme'**
  String levelSchemeFormat(Object level);

  /// No description provided for @processStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete this phase to progress further.'**
  String get processStepSubtitle;

  /// No description provided for @badgeRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get badgeRequired;

  /// No description provided for @badgeConditional.
  ///
  /// In en, this message translates to:
  /// **'Conditional'**
  String get badgeConditional;

  /// No description provided for @filterDistrict.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get filterDistrict;

  /// No description provided for @filterMinistry.
  ///
  /// In en, this message translates to:
  /// **'Ministry'**
  String get filterMinistry;

  /// No description provided for @filterDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get filterDepartment;

  /// No description provided for @filterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get filterCategory;

  /// No description provided for @labelCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get labelCommunity;

  /// No description provided for @labelOccupation.
  ///
  /// In en, this message translates to:
  /// **'Occupation'**
  String get labelOccupation;

  /// No description provided for @labelEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get labelEducation;

  /// No description provided for @labelFirstGenGraduate.
  ///
  /// In en, this message translates to:
  /// **'First Generation Graduate'**
  String get labelFirstGenGraduate;

  /// No description provided for @labelDisability.
  ///
  /// In en, this message translates to:
  /// **'Disability'**
  String get labelDisability;

  /// No description provided for @filterSchemeStatus.
  ///
  /// In en, this message translates to:
  /// **'Scheme Status'**
  String get filterSchemeStatus;

  /// No description provided for @filterOnlineOffline.
  ///
  /// In en, this message translates to:
  /// **'Online / Offline'**
  String get filterOnlineOffline;

  /// No description provided for @filterCentralStateScheme.
  ///
  /// In en, this message translates to:
  /// **'Central / State Scheme'**
  String get filterCentralStateScheme;

  /// No description provided for @filterClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get filterClearAll;

  /// No description provided for @validationSelectDob.
  ///
  /// In en, this message translates to:
  /// **'Please select your Date of Birth'**
  String get validationSelectDob;

  /// No description provided for @notifTooltipMarkRead.
  ///
  /// In en, this message translates to:
  /// **'Mark selected as read'**
  String get notifTooltipMarkRead;

  /// No description provided for @notifTooltipDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get notifTooltipDeleteSelected;

  /// No description provided for @notifNewSchemeAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'New Scheme Alerts'**
  String get notifNewSchemeAlertsTitle;

  /// No description provided for @notifNewSchemeAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay informed about newly launched schemes'**
  String get notifNewSchemeAlertsSubtitle;

  /// No description provided for @notifDeadlineRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Deadline Reminders'**
  String get notifDeadlineRemindersTitle;

  /// No description provided for @notifDeadlineRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t miss important application deadlines'**
  String get notifDeadlineRemindersSubtitle;

  /// No description provided for @notifGovtUpdatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Government Updates'**
  String get notifGovtUpdatesTitle;

  /// No description provided for @notifGovtUpdatesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Important announcements and updates'**
  String get notifGovtUpdatesSubtitle;

  /// No description provided for @notifProfileRemindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile Completion Reminders'**
  String get notifProfileRemindersTitle;

  /// No description provided for @notifProfileRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to get better recommendations'**
  String get notifProfileRemindersSubtitle;

  /// No description provided for @navChooseYourPrefix.
  ///
  /// In en, this message translates to:
  /// **'Choose Your '**
  String get navChooseYourPrefix;

  /// No description provided for @navExperienceSuffix.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get navExperienceSuffix;

  /// No description provided for @navRegularNavigationTitle.
  ///
  /// In en, this message translates to:
  /// **'Regular Navigation'**
  String get navRegularNavigationTitle;

  /// No description provided for @navModeRegularSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse and explore the app independently.'**
  String get navModeRegularSubtitle;

  /// No description provided for @navAiCompanionTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Companion'**
  String get navAiCompanionTitle;

  /// No description provided for @navModeCompanionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let your AI guide you step by step.'**
  String get navModeCompanionSubtitle;

  /// No description provided for @navSwitchAnytimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch Anytime'**
  String get navSwitchAnytimeTitle;

  /// No description provided for @navSelectStyleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the navigation style that best suits you.'**
  String get navSelectStyleSubtitle;

  /// No description provided for @navContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get navContinueButton;

  /// No description provided for @navChipFastSimple.
  ///
  /// In en, this message translates to:
  /// **'Fast & Simple'**
  String get navChipFastSimple;

  /// No description provided for @navChipTraditionalUi.
  ///
  /// In en, this message translates to:
  /// **'Traditional UI'**
  String get navChipTraditionalUi;

  /// No description provided for @navChipSelfPaced.
  ///
  /// In en, this message translates to:
  /// **'Self-paced browsing'**
  String get navChipSelfPaced;

  /// No description provided for @navChipAiAnytime.
  ///
  /// In en, this message translates to:
  /// **'AI available anytime'**
  String get navChipAiAnytime;

  /// No description provided for @navChipVoiceFirst.
  ///
  /// In en, this message translates to:
  /// **'Voice-first experience'**
  String get navChipVoiceFirst;

  /// No description provided for @navChipPersonalized.
  ///
  /// In en, this message translates to:
  /// **'Personalized guidance'**
  String get navChipPersonalized;

  /// No description provided for @navChipSmartRecs.
  ///
  /// In en, this message translates to:
  /// **'Smart recommendations'**
  String get navChipSmartRecs;

  /// No description provided for @navChipExplainsScreens.
  ///
  /// In en, this message translates to:
  /// **'Explains every screen'**
  String get navChipExplainsScreens;

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filterTitle;

  /// No description provided for @filterButton.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterButton;

  /// No description provided for @filterUseMyProfile.
  ///
  /// In en, this message translates to:
  /// **'Use my profile ({state})'**
  String filterUseMyProfile(Object state);

  /// No description provided for @filterGroupCoverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get filterGroupCoverage;

  /// No description provided for @filterGroupOffers.
  ///
  /// In en, this message translates to:
  /// **'What it offers'**
  String get filterGroupOffers;

  /// No description provided for @filterGroupFor.
  ///
  /// In en, this message translates to:
  /// **'For'**
  String get filterGroupFor;

  /// No description provided for @filterCoverageNationwide.
  ///
  /// In en, this message translates to:
  /// **'Nationwide'**
  String get filterCoverageNationwide;

  /// No description provided for @filterShowSchemes.
  ///
  /// In en, this message translates to:
  /// **'Show {count} schemes'**
  String filterShowSchemes(Object count);

  /// No description provided for @filterTypeLoans.
  ///
  /// In en, this message translates to:
  /// **'Loans & credit'**
  String get filterTypeLoans;

  /// No description provided for @filterTypeSubsidies.
  ///
  /// In en, this message translates to:
  /// **'Subsidies'**
  String get filterTypeSubsidies;

  /// No description provided for @filterTypeGrants.
  ///
  /// In en, this message translates to:
  /// **'Grants & equity'**
  String get filterTypeGrants;

  /// No description provided for @filterTypeGuarantee.
  ///
  /// In en, this message translates to:
  /// **'Guarantee'**
  String get filterTypeGuarantee;

  /// No description provided for @filterTypeTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get filterTypeTraining;

  /// No description provided for @filterTypeMarket.
  ///
  /// In en, this message translates to:
  /// **'Market & export'**
  String get filterTypeMarket;

  /// No description provided for @filterTypeInfra.
  ///
  /// In en, this message translates to:
  /// **'Infrastructure'**
  String get filterTypeInfra;

  /// No description provided for @filterBenWomen.
  ///
  /// In en, this message translates to:
  /// **'Women'**
  String get filterBenWomen;

  /// No description provided for @filterBenSc.
  ///
  /// In en, this message translates to:
  /// **'SC'**
  String get filterBenSc;

  /// No description provided for @filterBenSt.
  ///
  /// In en, this message translates to:
  /// **'ST'**
  String get filterBenSt;

  /// No description provided for @filterBenDifferentlyAbled.
  ///
  /// In en, this message translates to:
  /// **'Differently-abled'**
  String get filterBenDifferentlyAbled;

  /// No description provided for @filterBenTransgender.
  ///
  /// In en, this message translates to:
  /// **'Transgender'**
  String get filterBenTransgender;

  /// No description provided for @filterBenMinority.
  ///
  /// In en, this message translates to:
  /// **'Minority'**
  String get filterBenMinority;

  /// No description provided for @filterBenExServicemen.
  ///
  /// In en, this message translates to:
  /// **'Ex-servicemen'**
  String get filterBenExServicemen;

  /// No description provided for @sortRelevance.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get sortRelevance;

  /// No description provided for @sortBestMatch.
  ///
  /// In en, this message translates to:
  /// **'Best match for me'**
  String get sortBestMatch;

  /// No description provided for @sortSchemeNameAz.
  ///
  /// In en, this message translates to:
  /// **'Scheme name (A-Z)'**
  String get sortSchemeNameAz;

  /// No description provided for @settingsRegularSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Traditional clean list and tab view layout'**
  String get settingsRegularSubtitle;

  /// No description provided for @settingsCompanionTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Companion (Saarthi)'**
  String get settingsCompanionTitle;

  /// No description provided for @settingsCompanionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Voice-first AI guided conversational view'**
  String get settingsCompanionSubtitle;

  /// No description provided for @navSwitchAnytimeDesc.
  ///
  /// In en, this message translates to:
  /// **'You can change your navigation mode later from Settings.'**
  String get navSwitchAnytimeDesc;

  /// No description provided for @helpContactEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Email Address'**
  String get helpContactEmailLabel;

  /// No description provided for @helpContactEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email for follow-up'**
  String get helpContactEmailHint;

  /// No description provided for @helpDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get helpDescriptionLabel;

  /// No description provided for @helpDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue in detail...'**
  String get helpDescriptionHint;

  /// No description provided for @helpSuggestionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Your suggestions'**
  String get helpSuggestionsLabel;

  /// No description provided for @helpSuggestionsHint.
  ///
  /// In en, this message translates to:
  /// **'What can we do better?'**
  String get helpSuggestionsHint;

  /// No description provided for @companionVoiceUnavailableRetry.
  ///
  /// In en, this message translates to:
  /// **'Voice service is unavailable. Tap retry.'**
  String get companionVoiceUnavailableRetry;

  /// No description provided for @companionSignInRetryVoice.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again, then retry voice.'**
  String get companionSignInRetryVoice;

  /// No description provided for @companionCheckInternetRetryVoice.
  ///
  /// In en, this message translates to:
  /// **'Check your internet, then retry voice.'**
  String get companionCheckInternetRetryVoice;

  /// No description provided for @companionVoiceConnectFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Voice service could not connect. Tap retry.'**
  String get companionVoiceConnectFailedRetry;

  /// No description provided for @companionGenericErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get companionGenericErrorRetry;

  /// No description provided for @companionConnectionNeedsAttention.
  ///
  /// In en, this message translates to:
  /// **'Connection needs attention'**
  String get companionConnectionNeedsAttention;

  /// No description provided for @companionConnectingShort.
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get companionConnectingShort;

  /// No description provided for @companionListeningToYou.
  ///
  /// In en, this message translates to:
  /// **'Listening to you'**
  String get companionListeningToYou;

  /// No description provided for @companionCheckingYourDetails.
  ///
  /// In en, this message translates to:
  /// **'Checking your details'**
  String get companionCheckingYourDetails;

  /// No description provided for @companionSpeakingNow.
  ///
  /// In en, this message translates to:
  /// **'Speaking now'**
  String get companionSpeakingNow;

  /// No description provided for @companionReadyToHelp.
  ///
  /// In en, this message translates to:
  /// **'Ready to help'**
  String get companionReadyToHelp;

  /// No description provided for @companionVoiceConnected.
  ///
  /// In en, this message translates to:
  /// **'Voice connected'**
  String get companionVoiceConnected;

  /// No description provided for @companionVoiceOffline.
  ///
  /// In en, this message translates to:
  /// **'Voice offline'**
  String get companionVoiceOffline;

  /// No description provided for @companionIntroPrefix.
  ///
  /// In en, this message translates to:
  /// **'I\'m'**
  String get companionIntroPrefix;

  /// No description provided for @companionIntroSuffix.
  ///
  /// In en, this message translates to:
  /// **', your AI companion for\nMSME success.'**
  String get companionIntroSuffix;

  /// No description provided for @companionEmptyStateHint.
  ///
  /// In en, this message translates to:
  /// **'Tell me what support you need. I will ask one detail at a time.'**
  String get companionEmptyStateHint;

  /// No description provided for @companionScrollToLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get companionScrollToLatest;

  /// No description provided for @companionSpeakingBadge.
  ///
  /// In en, this message translates to:
  /// **'Speaking'**
  String get companionSpeakingBadge;

  /// No description provided for @companionRankedResultsCaption.
  ///
  /// In en, this message translates to:
  /// **'Ranked from the details you shared. Final eligibility is confirmed by the department.'**
  String get companionRankedResultsCaption;

  /// No description provided for @companionReviewMatch.
  ///
  /// In en, this message translates to:
  /// **'Review match'**
  String get companionReviewMatch;

  /// No description provided for @companionOfficialSourceChecked.
  ///
  /// In en, this message translates to:
  /// **'Official source checked'**
  String get companionOfficialSourceChecked;

  /// No description provided for @companionOfficialSourceCheckedConfidence.
  ///
  /// In en, this message translates to:
  /// **'Official source checked · {confidence} confidence'**
  String companionOfficialSourceCheckedConfidence(Object confidence);

  /// No description provided for @companionVerifyWithDepartment.
  ///
  /// In en, this message translates to:
  /// **'Verify with the department'**
  String get companionVerifyWithDepartment;

  /// No description provided for @companionViewEligibility.
  ///
  /// In en, this message translates to:
  /// **'View eligibility'**
  String get companionViewEligibility;

  /// No description provided for @companionYouTimestampLabel.
  ///
  /// In en, this message translates to:
  /// **'You  {time}'**
  String companionYouTimestampLabel(Object time);

  /// No description provided for @companionAiTimestampLabel.
  ///
  /// In en, this message translates to:
  /// **'MSS Saarthi  {time}'**
  String companionAiTimestampLabel(Object time);

  /// No description provided for @companionAskAnything.
  ///
  /// In en, this message translates to:
  /// **'Ask Saarthi anything...'**
  String get companionAskAnything;

  /// No description provided for @companionTapToSpeakHint.
  ///
  /// In en, this message translates to:
  /// **'Tap below and speak your question'**
  String get companionTapToSpeakHint;

  /// No description provided for @companionRetryVoice.
  ///
  /// In en, this message translates to:
  /// **'Retry voice'**
  String get companionRetryVoice;

  /// No description provided for @companionSecureLiveSession.
  ///
  /// In en, this message translates to:
  /// **'Secure live voice session'**
  String get companionSecureLiveSession;

  /// No description provided for @companionLiveConnectionRequired.
  ///
  /// In en, this message translates to:
  /// **'Live voice connection required'**
  String get companionLiveConnectionRequired;

  /// No description provided for @companionStartSpeakingSemantic.
  ///
  /// In en, this message translates to:
  /// **'Start speaking to Saarthi'**
  String get companionStartSpeakingSemantic;

  /// No description provided for @companionTapToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Tap to speak'**
  String get companionTapToSpeak;

  /// No description provided for @companionStop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get companionStop;

  /// No description provided for @companionInterrupt.
  ///
  /// In en, this message translates to:
  /// **'Interrupt'**
  String get companionInterrupt;

  /// No description provided for @companionSpeak.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get companionSpeak;

  /// No description provided for @companionEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get companionEnd;

  /// No description provided for @companionVoiceNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Voice is not connected'**
  String get companionVoiceNotConnected;

  /// No description provided for @companionConnectingSecurely.
  ///
  /// In en, this message translates to:
  /// **'Connecting securely'**
  String get companionConnectingSecurely;

  /// No description provided for @companionFindingBestMatch.
  ///
  /// In en, this message translates to:
  /// **'Finding the best match'**
  String get companionFindingBestMatch;

  /// No description provided for @companionSaarthiIsSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Saarthi is speaking'**
  String get companionSaarthiIsSpeaking;

  /// No description provided for @companionReadyShort.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get companionReadyShort;

  /// No description provided for @welcomeMeetPrefix.
  ///
  /// In en, this message translates to:
  /// **'Meet'**
  String get welcomeMeetPrefix;

  /// No description provided for @welcomeIntroLine1.
  ///
  /// In en, this message translates to:
  /// **'I\'m Saarthi, your smart assistant.'**
  String get welcomeIntroLine1;

  /// No description provided for @welcomeIntroLine2.
  ///
  /// In en, this message translates to:
  /// **'I\'ll help you discover the right schemes, explain everything simply, and guide you at every step.'**
  String get welcomeIntroLine2;

  /// No description provided for @welcomeSectionHeader.
  ///
  /// In en, this message translates to:
  /// **'Saarthi can help you with'**
  String get welcomeSectionHeader;

  /// No description provided for @welcomeFeatureTalkNaturally.
  ///
  /// In en, this message translates to:
  /// **'Talk Naturally'**
  String get welcomeFeatureTalkNaturally;

  /// No description provided for @welcomeFeatureFindSchemes.
  ///
  /// In en, this message translates to:
  /// **'Find Right Schemes'**
  String get welcomeFeatureFindSchemes;

  /// No description provided for @welcomeFeatureBusinessRoadmap.
  ///
  /// In en, this message translates to:
  /// **'Business Roadmap'**
  String get welcomeFeatureBusinessRoadmap;

  /// No description provided for @welcomeFeatureApplicationSupport.
  ///
  /// In en, this message translates to:
  /// **'Application Support'**
  String get welcomeFeatureApplicationSupport;

  /// No description provided for @welcomeChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get welcomeChooseLanguage;

  /// No description provided for @welcomeChooseLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred language so Saarthi can talk to you better.'**
  String get welcomeChooseLanguageSubtitle;

  /// No description provided for @welcomeVoiceLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get welcomeVoiceLabel;

  /// No description provided for @welcomeVoiceNatural.
  ///
  /// In en, this message translates to:
  /// **'Natural'**
  String get welcomeVoiceNatural;

  /// No description provided for @welcomeVoiceClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get welcomeVoiceClear;

  /// No description provided for @welcomePreviewVoiceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Preview in English and Tamil'**
  String get welcomePreviewVoiceTooltip;

  /// No description provided for @welcomeChangeAnytimeNote.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in settings.'**
  String get welcomeChangeAnytimeNote;

  /// No description provided for @welcomeLetsBegin.
  ///
  /// In en, this message translates to:
  /// **'Let\'s Begin'**
  String get welcomeLetsBegin;

  /// No description provided for @voiceLanguageAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get voiceLanguageAuto;

  /// No description provided for @voiceStatusSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Speaking...'**
  String get voiceStatusSpeaking;

  /// No description provided for @voiceStatusListening.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get voiceStatusListening;

  /// No description provided for @voiceStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get voiceStatusProcessing;

  /// No description provided for @voiceStatusUnderstanding.
  ///
  /// In en, this message translates to:
  /// **'Understanding...'**
  String get voiceStatusUnderstanding;

  /// No description provided for @voiceStatusOneQuestion.
  ///
  /// In en, this message translates to:
  /// **'One question'**
  String get voiceStatusOneQuestion;

  /// No description provided for @voiceStatusMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'Matches found'**
  String get voiceStatusMatchesFound;

  /// No description provided for @voiceStatusNeedsMoreDetail.
  ///
  /// In en, this message translates to:
  /// **'Needs more detail'**
  String get voiceStatusNeedsMoreDetail;

  /// No description provided for @voiceStatusFinding.
  ///
  /// In en, this message translates to:
  /// **'Finding...'**
  String get voiceStatusFinding;

  /// No description provided for @voiceStatusFoundCount.
  ///
  /// In en, this message translates to:
  /// **'Found {count}'**
  String voiceStatusFoundCount(Object count);

  /// No description provided for @voiceRecommendedBySaarthiReason.
  ///
  /// In en, this message translates to:
  /// **'Recommended by Saarthi from the verified catalog'**
  String get voiceRecommendedBySaarthiReason;

  /// No description provided for @voiceRecognitionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice recognition is not available on this device.'**
  String get voiceRecognitionUnavailable;

  /// No description provided for @voiceRecognitionStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Voice recognition could not start. Please try again.'**
  String get voiceRecognitionStartFailed;

  /// No description provided for @voiceSearchFailed.
  ///
  /// In en, this message translates to:
  /// **'I could not search right now. Please try again.'**
  String get voiceSearchFailed;

  /// No description provided for @voiceUseValue.
  ///
  /// In en, this message translates to:
  /// **'Use value'**
  String get voiceUseValue;

  /// No description provided for @voiceReviewProfileUpdates.
  ///
  /// In en, this message translates to:
  /// **'Review profile updates'**
  String get voiceReviewProfileUpdates;

  /// No description provided for @voiceKeepSessionOnly.
  ///
  /// In en, this message translates to:
  /// **'Keep session only'**
  String get voiceKeepSessionOnly;

  /// No description provided for @voiceSaveConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Save confirmed'**
  String get voiceSaveConfirmed;

  /// No description provided for @voiceProfileSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Confirmed details saved to your profile.'**
  String get voiceProfileSavedMessage;

  /// No description provided for @voiceCloudDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Record a request, review its transcription, then send it to the assistant. Audio is uploaded to Sarvam for transcription.'**
  String get voiceCloudDisclosure;

  /// No description provided for @voiceNoConfidentMatch.
  ///
  /// In en, this message translates to:
  /// **'No confident scheme match yet. Tell me a little more about your situation.'**
  String get voiceNoConfidentMatch;

  /// No description provided for @voiceHeaderTalkToSaarthi.
  ///
  /// In en, this message translates to:
  /// **'Talk to Saarthi'**
  String get voiceHeaderTalkToSaarthi;

  /// No description provided for @voiceUnmute.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get voiceUnmute;

  /// No description provided for @voiceMute.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get voiceMute;

  /// No description provided for @voiceCancelAssistantTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel assistant'**
  String get voiceCancelAssistantTooltip;

  /// No description provided for @voiceTellMeNaturally.
  ///
  /// In en, this message translates to:
  /// **'Tell me your situation naturally...'**
  String get voiceTellMeNaturally;

  /// No description provided for @voiceSuggestionBusinessLoans.
  ///
  /// In en, this message translates to:
  /// **'Business loans'**
  String get voiceSuggestionBusinessLoans;

  /// No description provided for @voiceSuggestionCollegeScholarship.
  ///
  /// In en, this message translates to:
  /// **'College scholarship'**
  String get voiceSuggestionCollegeScholarship;

  /// No description provided for @voiceSuggestionFarmerSubsidy.
  ///
  /// In en, this message translates to:
  /// **'Farmer subsidy'**
  String get voiceSuggestionFarmerSubsidy;

  /// No description provided for @voiceStopListeningSemantic.
  ///
  /// In en, this message translates to:
  /// **'Stop listening'**
  String get voiceStopListeningSemantic;

  /// No description provided for @voiceStartListeningSemantic.
  ///
  /// In en, this message translates to:
  /// **'Start listening'**
  String get voiceStartListeningSemantic;

  /// No description provided for @voiceTypeToSaarthiHint.
  ///
  /// In en, this message translates to:
  /// **'Type to Saarthi...'**
  String get voiceTypeToSaarthiHint;

  /// No description provided for @voiceSendMessageTooltip.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get voiceSendMessageTooltip;

  /// No description provided for @voiceLanguageSemantic.
  ///
  /// In en, this message translates to:
  /// **'Voice language {language}'**
  String voiceLanguageSemantic(Object language);

  /// No description provided for @voiceWhatIUnderstood.
  ///
  /// In en, this message translates to:
  /// **'What I understood'**
  String get voiceWhatIUnderstood;

  /// No description provided for @voiceRepeatQuestionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Repeat question'**
  String get voiceRepeatQuestionTooltip;

  /// No description provided for @voiceSpeechOutputUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Speech output is unavailable; tap the microphone to answer.'**
  String get voiceSpeechOutputUnavailable;

  /// No description provided for @voiceSchemesSuitedToSituation.
  ///
  /// In en, this message translates to:
  /// **'Schemes suited to your situation'**
  String get voiceSchemesSuitedToSituation;

  /// No description provided for @voiceViewAllResults.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get voiceViewAllResults;

  /// No description provided for @voiceReviewAndSaveDetails.
  ///
  /// In en, this message translates to:
  /// **'Review and save confirmed details'**
  String get voiceReviewAndSaveDetails;

  /// No description provided for @voiceOpenOfficialSource.
  ///
  /// In en, this message translates to:
  /// **'Open official source'**
  String get voiceOpenOfficialSource;

  /// No description provided for @voiceGroundingChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking official sources…'**
  String get voiceGroundingChecking;

  /// No description provided for @voiceGroundingFoundSources.
  ///
  /// In en, this message translates to:
  /// **'Grounded online · {count} official source(s)'**
  String voiceGroundingFoundSources(Object count);

  /// No description provided for @voiceGroundingUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Offline · using private on-device knowledge'**
  String get voiceGroundingUnavailable;

  /// No description provided for @voiceGroundingNoSources.
  ///
  /// In en, this message translates to:
  /// **'Official page unavailable · using the verified local catalog'**
  String get voiceGroundingNoSources;

  /// No description provided for @voiceGroundingPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Only the topic and official links are checked. Your statement and profile stay on this device.'**
  String get voiceGroundingPrivacyNote;

  /// No description provided for @voiceCouldNotOpenSource.
  ///
  /// In en, this message translates to:
  /// **'Could not open the official source.'**
  String get voiceCouldNotOpenSource;

  /// No description provided for @voiceMatchStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong match'**
  String get voiceMatchStrong;

  /// No description provided for @voiceMatchLikely.
  ///
  /// In en, this message translates to:
  /// **'Likely match'**
  String get voiceMatchLikely;

  /// No description provided for @voiceMatchNeedsConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Needs confirmation'**
  String get voiceMatchNeedsConfirmation;

  /// No description provided for @voiceMatchNotSuitable.
  ///
  /// In en, this message translates to:
  /// **'Not suitable'**
  String get voiceMatchNotSuitable;

  /// No description provided for @voiceMatchNoConfident.
  ///
  /// In en, this message translates to:
  /// **'No confident match'**
  String get voiceMatchNoConfident;

  /// No description provided for @voiceWhyThisFits.
  ///
  /// In en, this message translates to:
  /// **'Why this fits: {reasons}'**
  String voiceWhyThisFits(Object reasons);

  /// No description provided for @voiceStillConfirm.
  ///
  /// In en, this message translates to:
  /// **'Still confirm: {requirements}'**
  String voiceStillConfirm(Object requirements);

  /// No description provided for @voiceSourceVerified.
  ///
  /// In en, this message translates to:
  /// **'Current official source verified'**
  String get voiceSourceVerified;

  /// No description provided for @voiceSourceUnverified.
  ///
  /// In en, this message translates to:
  /// **'Uncertain or historical — verify before applying'**
  String get voiceSourceUnverified;

  /// No description provided for @voiceBestMatchingSchemes.
  ///
  /// In en, this message translates to:
  /// **'Best matching schemes'**
  String get voiceBestMatchingSchemes;

  /// No description provided for @voiceFactLabelState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get voiceFactLabelState;

  /// No description provided for @voiceFactLabelSituation.
  ///
  /// In en, this message translates to:
  /// **'Situation'**
  String get voiceFactLabelSituation;

  /// No description provided for @voiceFactLabelMaritalStatus.
  ///
  /// In en, this message translates to:
  /// **'Marital status'**
  String get voiceFactLabelMaritalStatus;

  /// No description provided for @voiceFactLabelSector.
  ///
  /// In en, this message translates to:
  /// **'Sector'**
  String get voiceFactLabelSector;

  /// No description provided for @voiceFactLabelFundingNeed.
  ///
  /// In en, this message translates to:
  /// **'Funding need'**
  String get voiceFactLabelFundingNeed;

  /// No description provided for @voiceFactLabelLandholding.
  ///
  /// In en, this message translates to:
  /// **'Landholding'**
  String get voiceFactLabelLandholding;

  /// No description provided for @voiceFactConflictFormat.
  ///
  /// In en, this message translates to:
  /// **'{value} (profile: {conflictingValue})'**
  String voiceFactConflictFormat(Object conflictingValue, Object value);

  /// No description provided for @calcUdyamClassifierTitle.
  ///
  /// In en, this message translates to:
  /// **'Udyam MSME Classifier'**
  String get calcUdyamClassifierTitle;

  /// No description provided for @calcUdyamClassifierSub.
  ///
  /// In en, this message translates to:
  /// **'Classify your business under official government guidelines.'**
  String get calcUdyamClassifierSub;

  /// No description provided for @calcInvestmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Investment in Plant & Machinery'**
  String get calcInvestmentLabel;

  /// No description provided for @calcInvestmentHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter original purchase value of machinery in Crores'**
  String get calcInvestmentHelper;

  /// No description provided for @calcTurnoverLabel.
  ///
  /// In en, this message translates to:
  /// **'Annual Turnover'**
  String get calcTurnoverLabel;

  /// No description provided for @calcTurnoverHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter total revenue/sales of last financial year in Crores'**
  String get calcTurnoverHelper;

  /// No description provided for @calcClassificationResult.
  ///
  /// In en, this message translates to:
  /// **'Classification Result'**
  String get calcClassificationResult;

  /// No description provided for @calcBtnCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate Classification'**
  String get calcBtnCalculate;

  /// No description provided for @calcGstTitle.
  ///
  /// In en, this message translates to:
  /// **'GST / Tax Calculator'**
  String get calcGstTitle;

  /// No description provided for @calcGstSub.
  ///
  /// In en, this message translates to:
  /// **'Calculate CGST + SGST or IGST, and the total invoice amount.'**
  String get calcGstSub;

  /// No description provided for @calcGstWithinState.
  ///
  /// In en, this message translates to:
  /// **'Within state (CGST + SGST)'**
  String get calcGstWithinState;

  /// No description provided for @calcGstInterState.
  ///
  /// In en, this message translates to:
  /// **'Inter-state (IGST)'**
  String get calcGstInterState;

  /// No description provided for @calcBaseAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Base Amount'**
  String get calcBaseAmountLabel;

  /// No description provided for @calcBaseAmountHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter net value of goods or services before GST'**
  String get calcBaseAmountHelper;

  /// No description provided for @calcGstRateLabel.
  ///
  /// In en, this message translates to:
  /// **'GST Rate (%)'**
  String get calcGstRateLabel;

  /// No description provided for @calcBasePrice.
  ///
  /// In en, this message translates to:
  /// **'Base Price'**
  String get calcBasePrice;

  /// No description provided for @calcTotalInvoice.
  ///
  /// In en, this message translates to:
  /// **'Total Invoice'**
  String get calcTotalInvoice;

  /// No description provided for @calcBtnCalculateTax.
  ///
  /// In en, this message translates to:
  /// **'Calculate Tax'**
  String get calcBtnCalculateTax;

  /// No description provided for @calcErrValidBaseAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid base amount'**
  String get calcErrValidBaseAmount;

  /// No description provided for @calcEmiTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Loan EMI Calculator'**
  String get calcEmiTitle;

  /// No description provided for @calcEmiSub.
  ///
  /// In en, this message translates to:
  /// **'Calculate monthly payments for your business loan.'**
  String get calcEmiSub;

  /// No description provided for @calcLoanAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Loan Amount'**
  String get calcLoanAmountLabel;

  /// No description provided for @calcLoanAmountHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter total business loan sum required'**
  String get calcLoanAmountHelper;

  /// No description provided for @calcInterestRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Interest Rate (% p.a.)'**
  String get calcInterestRateLabel;

  /// No description provided for @calcTenureLabel.
  ///
  /// In en, this message translates to:
  /// **'Tenure (Months)'**
  String get calcTenureLabel;

  /// No description provided for @calcBtnCalculateEmi.
  ///
  /// In en, this message translates to:
  /// **'Calculate EMI'**
  String get calcBtnCalculateEmi;

  /// No description provided for @calcDpiitTitle.
  ///
  /// In en, this message translates to:
  /// **'DPIIT Recognition Checklist'**
  String get calcDpiitTitle;

  /// No description provided for @calcDpiitSub.
  ///
  /// In en, this message translates to:
  /// **'Evaluate if your business qualifies as a startup under DPIIT rules.'**
  String get calcDpiitSub;

  /// No description provided for @calcValuationTitle.
  ///
  /// In en, this message translates to:
  /// **'Seed Valuation Estimator'**
  String get calcValuationTitle;

  /// No description provided for @calcValuationSub.
  ///
  /// In en, this message translates to:
  /// **'Calculate estimated seed stage valuation ranges based on MRR and growth.'**
  String get calcValuationSub;

  /// No description provided for @calcDocChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Setup Document Checklist'**
  String get calcDocChecklistTitle;

  /// No description provided for @calcDocChecklistSub.
  ///
  /// In en, this message translates to:
  /// **'Essential documents for registering and operating a business in India.'**
  String get calcDocChecklistSub;

  /// No description provided for @discoverUtilitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Utilities & Tools'**
  String get discoverUtilitiesTitle;

  /// No description provided for @utilUdyamTitle.
  ///
  /// In en, this message translates to:
  /// **'Udyam Classifier'**
  String get utilUdyamTitle;

  /// No description provided for @utilUdyamDesc.
  ///
  /// In en, this message translates to:
  /// **'Check MSME tier'**
  String get utilUdyamDesc;

  /// No description provided for @utilSubsidyTitle.
  ///
  /// In en, this message translates to:
  /// **'Subsidy Estimator'**
  String get utilSubsidyTitle;

  /// No description provided for @utilSubsidyDesc.
  ///
  /// In en, this message translates to:
  /// **'Machinery subsidies'**
  String get utilSubsidyDesc;

  /// No description provided for @utilGstTitle.
  ///
  /// In en, this message translates to:
  /// **'GST Calculator'**
  String get utilGstTitle;

  /// No description provided for @utilGstDesc.
  ///
  /// In en, this message translates to:
  /// **'Compute GST invoice'**
  String get utilGstDesc;

  /// No description provided for @utilEmiTitle.
  ///
  /// In en, this message translates to:
  /// **'EMI Calculator'**
  String get utilEmiTitle;

  /// No description provided for @utilEmiDesc.
  ///
  /// In en, this message translates to:
  /// **'Calculate loan EMIs'**
  String get utilEmiDesc;

  /// No description provided for @utilDpiitTitle.
  ///
  /// In en, this message translates to:
  /// **'DPIIT Eligibility'**
  String get utilDpiitTitle;

  /// No description provided for @utilDpiitDesc.
  ///
  /// In en, this message translates to:
  /// **'Check startup criteria'**
  String get utilDpiitDesc;

  /// No description provided for @utilValuationTitle.
  ///
  /// In en, this message translates to:
  /// **'Valuation Estimator'**
  String get utilValuationTitle;

  /// No description provided for @utilValuationDesc.
  ///
  /// In en, this message translates to:
  /// **'Seed valuation ranges'**
  String get utilValuationDesc;

  /// No description provided for @utilDocChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Doc Checklist'**
  String get utilDocChecklistTitle;

  /// No description provided for @utilDocChecklistDesc.
  ///
  /// In en, this message translates to:
  /// **'Business setup docs'**
  String get utilDocChecklistDesc;

  /// No description provided for @notifToastSelectedRead.
  ///
  /// In en, this message translates to:
  /// **'Selected notifications marked as read'**
  String get notifToastSelectedRead;

  /// No description provided for @notifToastSelectedDeleted.
  ///
  /// In en, this message translates to:
  /// **'Selected notifications deleted'**
  String get notifToastSelectedDeleted;

  /// No description provided for @notifToastAllRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read'**
  String get notifToastAllRead;

  /// No description provided for @notifToastAllDeleted.
  ///
  /// In en, this message translates to:
  /// **'All notifications deleted'**
  String get notifToastAllDeleted;

  /// No description provided for @notifToastFilterOpened.
  ///
  /// In en, this message translates to:
  /// **'Filter options opened'**
  String get notifToastFilterOpened;

  /// No description provided for @retryVoice.
  ///
  /// In en, this message translates to:
  /// **'Retry voice'**
  String get retryVoice;

  /// No description provided for @chooseYourLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Language'**
  String get chooseYourLanguage;

  /// No description provided for @languageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language to explore government schemes in your language.'**
  String get languageSubtitle;

  /// No description provided for @yourLanguageExperience.
  ///
  /// In en, this message translates to:
  /// **'Your Language, Your Experience'**
  String get yourLanguageExperience;

  /// No description provided for @changeAnytime.
  ///
  /// In en, this message translates to:
  /// **'Change it anytime from Settings.'**
  String get changeAnytime;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login or sign up to discover and explore government schemes that empower you.'**
  String get loginSubtitle;

  /// No description provided for @loginReviewTermsNotice.
  ///
  /// In en, this message translates to:
  /// **'Please review the Terms of Use and Privacy Policy before continuing.'**
  String get loginReviewTermsNotice;

  /// No description provided for @continueSecurely.
  ///
  /// In en, this message translates to:
  /// **'Continue securely'**
  String get continueSecurely;

  /// No description provided for @googleAccountContinue.
  ///
  /// In en, this message translates to:
  /// **'Use your Google account to sign in or create your MSS account.'**
  String get googleAccountContinue;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @secureBrowserAuth.
  ///
  /// In en, this message translates to:
  /// **'A secure browser window will open for authentication.'**
  String get secureBrowserAuth;

  /// No description provided for @privacyNote.
  ///
  /// In en, this message translates to:
  /// **'By continuing, you agree to our'**
  String get privacyNote;

  /// No description provided for @terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get terms;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @skipLogin.
  ///
  /// In en, this message translates to:
  /// **'Skip & Explore'**
  String get skipLogin;

  /// No description provided for @demoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo mode — all features available'**
  String get demoMode;

  /// No description provided for @verifiedPlatform.
  ///
  /// In en, this message translates to:
  /// **'Government Verified Platform'**
  String get verifiedPlatform;

  /// No description provided for @forIndia.
  ///
  /// In en, this message translates to:
  /// **'For every Indian entrepreneur & citizen'**
  String get forIndia;

  /// No description provided for @basicDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s start with your basic details.'**
  String get basicDetailsSubtitle;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth (DOB)'**
  String get dateOfBirth;

  /// No description provided for @profileInfoNote.
  ///
  /// In en, this message translates to:
  /// **'We\'ll use this information to personalize your MSS experience and keep you updated.'**
  String get profileInfoNote;

  /// No description provided for @step1Of4.
  ///
  /// In en, this message translates to:
  /// **'1/4 Complete'**
  String get step1Of4;

  /// No description provided for @step2Of4.
  ///
  /// In en, this message translates to:
  /// **'2/4 Complete'**
  String get step2Of4;

  /// No description provided for @step3Of4.
  ///
  /// In en, this message translates to:
  /// **'3/4 Complete'**
  String get step3Of4;

  /// No description provided for @step4Of4.
  ///
  /// In en, this message translates to:
  /// **'4/4 Complete'**
  String get step4Of4;

  /// No description provided for @step1Of3.
  ///
  /// In en, this message translates to:
  /// **'1/3 Complete'**
  String get step1Of3;

  /// No description provided for @step2Of3.
  ///
  /// In en, this message translates to:
  /// **'2/3 Complete'**
  String get step2Of3;

  /// No description provided for @step3Of3.
  ///
  /// In en, this message translates to:
  /// **'3/3 Complete'**
  String get step3Of3;

  /// No description provided for @whereLocated.
  ///
  /// In en, this message translates to:
  /// **'Where Are You Located?'**
  String get whereLocated;

  /// No description provided for @locationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We use your location to recommend schemes available in your area.'**
  String get locationSubtitle;

  /// No description provided for @useCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// No description provided for @fetchingCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Fetching coordinates...'**
  String get fetchingCoordinates;

  /// No description provided for @getLocationAuto.
  ///
  /// In en, this message translates to:
  /// **'Get your current location automatically'**
  String get getLocationAuto;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get or;

  /// No description provided for @doorNoStreet.
  ///
  /// In en, this message translates to:
  /// **'Door No / Flat / House No / Street'**
  String get doorNoStreet;

  /// No description provided for @areaLocality.
  ///
  /// In en, this message translates to:
  /// **'Area / Locality'**
  String get areaLocality;

  /// No description provided for @cityDistrict.
  ///
  /// In en, this message translates to:
  /// **'City / District'**
  String get cityDistrict;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @pincode.
  ///
  /// In en, this message translates to:
  /// **'Pincode'**
  String get pincode;

  /// No description provided for @fullAddress.
  ///
  /// In en, this message translates to:
  /// **'Full Address'**
  String get fullAddress;

  /// No description provided for @cityTown.
  ///
  /// In en, this message translates to:
  /// **'City / Town'**
  String get cityTown;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @profileErrEnterAge.
  ///
  /// In en, this message translates to:
  /// **'Please enter your age'**
  String get profileErrEnterAge;

  /// No description provided for @profileErrValidAge.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid age (1-120)'**
  String get profileErrValidAge;

  /// No description provided for @dataProcessingConsent.
  ///
  /// In en, this message translates to:
  /// **'I consent to MSS collecting and processing my information to create my profile and provide personalized Government scheme recommendations.'**
  String get dataProcessingConsent;

  /// No description provided for @privacyAndData.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data'**
  String get privacyAndData;

  /// No description provided for @readHowDataUsed.
  ///
  /// In en, this message translates to:
  /// **'Read how your data is used →'**
  String get readHowDataUsed;

  /// No description provided for @pleaseConsentToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please consent to continue'**
  String get pleaseConsentToContinue;

  /// No description provided for @tellUsAboutYou.
  ///
  /// In en, this message translates to:
  /// **'Tell Us About You'**
  String get tellUsAboutYou;

  /// No description provided for @aboutYouSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the option that best describes you.'**
  String get aboutYouSubtitle;

  /// No description provided for @studentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Looking for learning, innovation and startup opportunities.'**
  String get studentSubtitle;

  /// No description provided for @aspiringEntrepreneur.
  ///
  /// In en, this message translates to:
  /// **'Entrepreneur'**
  String get aspiringEntrepreneur;

  /// No description provided for @aspiringEntrepreneurSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I have an idea and want to start a business.'**
  String get aspiringEntrepreneurSubtitle;

  /// No description provided for @existingBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get existingBusiness;

  /// No description provided for @existingBusinessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I already run a registered or unregistered business.'**
  String get existingBusinessSubtitle;

  /// No description provided for @msmeOwner.
  ///
  /// In en, this message translates to:
  /// **'MSME Owner'**
  String get msmeOwner;

  /// No description provided for @msmeOwnerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I own a micro, small or medium enterprise.'**
  String get msmeOwnerSubtitle;

  /// No description provided for @farmerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I am involved in farming or agriculture.'**
  String get farmerSubtitle;

  /// No description provided for @artisanShg.
  ///
  /// In en, this message translates to:
  /// **'Artisan / SHG Member'**
  String get artisanShg;

  /// No description provided for @artisanShgSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I am an artisan or part of a Self Help Group.'**
  String get artisanShgSubtitle;

  /// No description provided for @overwriteDetails.
  ///
  /// In en, this message translates to:
  /// **'Overwrite details?'**
  String get overwriteDetails;

  /// No description provided for @overwriteMessage.
  ///
  /// In en, this message translates to:
  /// **'You have already entered some address details. Do you want to overwrite them with your current location?'**
  String get overwriteMessage;

  /// No description provided for @overwrite.
  ///
  /// In en, this message translates to:
  /// **'Overwrite'**
  String get overwrite;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved successfully!'**
  String get profileSaved;

  /// No description provided for @failedFetchLocation.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch location'**
  String get failedFetchLocation;

  /// No description provided for @usingDefaultLocation.
  ///
  /// In en, this message translates to:
  /// **'Using default location (Chennai) due to GPS/permission constraints.'**
  String get usingDefaultLocation;

  /// No description provided for @locationFetched.
  ///
  /// In en, this message translates to:
  /// **'Location fetched and populated successfully!'**
  String get locationFetched;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;

  /// No description provided for @updateProfile.
  ///
  /// In en, this message translates to:
  /// **'Update Profile'**
  String get updateProfile;

  /// No description provided for @personalInfo.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfo;

  /// No description provided for @locationInfo.
  ///
  /// In en, this message translates to:
  /// **'Location Details'**
  String get locationInfo;

  /// No description provided for @businessInfo.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get businessInfo;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Annual Income'**
  String get income;

  /// No description provided for @community.
  ///
  /// In en, this message translates to:
  /// **'Community / Category'**
  String get community;

  /// No description provided for @employment.
  ///
  /// In en, this message translates to:
  /// **'Employment Status'**
  String get employment;

  /// No description provided for @qualification.
  ///
  /// In en, this message translates to:
  /// **'Qualification'**
  String get qualification;

  /// No description provided for @veteran.
  ///
  /// In en, this message translates to:
  /// **'Ex-Serviceman / Veteran'**
  String get veteran;

  /// No description provided for @disability.
  ///
  /// In en, this message translates to:
  /// **'Person with Disability'**
  String get disability;

  /// No description provided for @disabilityType.
  ///
  /// In en, this message translates to:
  /// **'Disability Type'**
  String get disabilityType;

  /// No description provided for @hasExistingBusiness.
  ///
  /// In en, this message translates to:
  /// **'I have an existing business'**
  String get hasExistingBusiness;

  /// No description provided for @businessStage.
  ///
  /// In en, this message translates to:
  /// **'Business Stage'**
  String get businessStage;

  /// No description provided for @businessIndustry.
  ///
  /// In en, this message translates to:
  /// **'Business Industry / Sector'**
  String get businessIndustry;

  /// No description provided for @fundingRequired.
  ///
  /// In en, this message translates to:
  /// **'Funding Required'**
  String get fundingRequired;

  /// No description provided for @registrationNumbers.
  ///
  /// In en, this message translates to:
  /// **'Registration Numbers (Udyam, GST, etc.)'**
  String get registrationNumbers;

  /// No description provided for @checkEligibility.
  ///
  /// In en, this message translates to:
  /// **'Check Eligibility'**
  String get checkEligibility;

  /// No description provided for @eligibilityDetails.
  ///
  /// In en, this message translates to:
  /// **'Eligibility Details'**
  String get eligibilityDetails;

  /// No description provided for @eligibilitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Helps us recommend 100% accurate schemes & subsidies for you.'**
  String get eligibilitySubtitle;

  /// No description provided for @firstGenGraduate.
  ///
  /// In en, this message translates to:
  /// **'First-Generation Graduate'**
  String get firstGenGraduate;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @completeProfile.
  ///
  /// In en, this message translates to:
  /// **'Complete Profile'**
  String get completeProfile;

  /// No description provided for @profileSettingUp.
  ///
  /// In en, this message translates to:
  /// **'Setting up your profile…'**
  String get profileSettingUp;

  /// No description provided for @incomeNoIncome.
  ///
  /// In en, this message translates to:
  /// **'No Income'**
  String get incomeNoIncome;

  /// No description provided for @incomeBelow15l.
  ///
  /// In en, this message translates to:
  /// **'Below ₹1.5 Lakhs'**
  String get incomeBelow15l;

  /// No description provided for @income15l3l.
  ///
  /// In en, this message translates to:
  /// **'₹1.5L - ₹3 Lakhs'**
  String get income15l3l;

  /// No description provided for @income3l6l.
  ///
  /// In en, this message translates to:
  /// **'₹3L - ₹6 Lakhs'**
  String get income3l6l;

  /// No description provided for @income6l10l.
  ///
  /// In en, this message translates to:
  /// **'₹6L - ₹10 Lakhs'**
  String get income6l10l;

  /// No description provided for @incomeAbove10l.
  ///
  /// In en, this message translates to:
  /// **'Above ₹10 Lakhs'**
  String get incomeAbove10l;

  /// No description provided for @specialCategories.
  ///
  /// In en, this message translates to:
  /// **'Special Status / Priority'**
  String get specialCategories;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @dobLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dobLabel;

  /// No description provided for @houseNo.
  ///
  /// In en, this message translates to:
  /// **'House No.'**
  String get houseNo;

  /// No description provided for @street.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get street;

  /// No description provided for @villageTown.
  ///
  /// In en, this message translates to:
  /// **'Village / Town'**
  String get villageTown;

  /// No description provided for @useLocation.
  ///
  /// In en, this message translates to:
  /// **'Use Location'**
  String get useLocation;

  /// No description provided for @locating.
  ///
  /// In en, this message translates to:
  /// **'Locating...'**
  String get locating;

  /// No description provided for @salaried.
  ///
  /// In en, this message translates to:
  /// **'Salaried'**
  String get salaried;

  /// No description provided for @businessOwner.
  ///
  /// In en, this message translates to:
  /// **'Business Owner'**
  String get businessOwner;

  /// No description provided for @homemaker.
  ///
  /// In en, this message translates to:
  /// **'Homemaker'**
  String get homemaker;

  /// No description provided for @retired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get retired;

  /// No description provided for @selfEmployed.
  ///
  /// In en, this message translates to:
  /// **'Self-employed'**
  String get selfEmployed;

  /// No description provided for @undergraduate.
  ///
  /// In en, this message translates to:
  /// **'Undergraduate'**
  String get undergraduate;

  /// No description provided for @graduate.
  ///
  /// In en, this message translates to:
  /// **'Graduate'**
  String get graduate;

  /// No description provided for @postgraduate.
  ///
  /// In en, this message translates to:
  /// **'Postgraduate'**
  String get postgraduate;

  /// No description provided for @diploma.
  ///
  /// In en, this message translates to:
  /// **'Diploma'**
  String get diploma;

  /// No description provided for @higherSecondary.
  ///
  /// In en, this message translates to:
  /// **'Higher Secondary'**
  String get higherSecondary;

  /// No description provided for @secondary.
  ///
  /// In en, this message translates to:
  /// **'Secondary'**
  String get secondary;

  /// No description provided for @primary.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get primary;

  /// No description provided for @noFormal.
  ///
  /// In en, this message translates to:
  /// **'No Formal Education'**
  String get noFormal;

  /// No description provided for @ideaStage.
  ///
  /// In en, this message translates to:
  /// **'Idea Stage'**
  String get ideaStage;

  /// No description provided for @earlyStage.
  ///
  /// In en, this message translates to:
  /// **'Early Stage'**
  String get earlyStage;

  /// No description provided for @growthStage.
  ///
  /// In en, this message translates to:
  /// **'Growth Stage'**
  String get growthStage;

  /// No description provided for @established.
  ///
  /// In en, this message translates to:
  /// **'Established'**
  String get established;

  /// No description provided for @howCanIHelp.
  ///
  /// In en, this message translates to:
  /// **'How can I help?'**
  String get howCanIHelp;

  /// No description provided for @poweredBySarvamAi.
  ///
  /// In en, this message translates to:
  /// **'Powered by Sarvam AI'**
  String get poweredBySarvamAi;

  /// No description provided for @sarvamPromptFindSchemes.
  ///
  /// In en, this message translates to:
  /// **'Find schemes for me'**
  String get sarvamPromptFindSchemes;

  /// No description provided for @sarvamPromptExplainMsmeLoans.
  ///
  /// In en, this message translates to:
  /// **'Explain MSME loans'**
  String get sarvamPromptExplainMsmeLoans;

  /// No description provided for @sarvamAskAboutSchemes.
  ///
  /// In en, this message translates to:
  /// **'Ask about schemes, eligibility, or how to apply.'**
  String get sarvamAskAboutSchemes;

  /// No description provided for @aiDisclaimerNotice.
  ///
  /// In en, this message translates to:
  /// **'AI can make mistakes. Check details on the official scheme website.'**
  String get aiDisclaimerNotice;

  /// No description provided for @sarvamInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask Saarthi…'**
  String get sarvamInputHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @sarvamCouldNotReach.
  ///
  /// In en, this message translates to:
  /// **'Could not reach Saarthi. Please try again.'**
  String get sarvamCouldNotReach;

  /// No description provided for @welcomePreviewVoice.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get welcomePreviewVoice;

  /// No description provided for @welcomePreviewVoiceError.
  ///
  /// In en, this message translates to:
  /// **'Unable to preview voice. Please check your audio settings.'**
  String get welcomePreviewVoiceError;

  /// No description provided for @welcomeSavePreferencesError.
  ///
  /// In en, this message translates to:
  /// **'Unable to save preferences to the cloud. Please check your connection and try again.'**
  String get welcomeSavePreferencesError;

  /// No description provided for @companionMatchPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% match'**
  String companionMatchPercent(Object percent);

  /// No description provided for @voiceNeedOneMoreDetail.
  ///
  /// In en, this message translates to:
  /// **'I need one more detail to find a confident match.'**
  String get voiceNeedOneMoreDetail;

  /// No description provided for @voiceTellMeSituationFindSchemes.
  ///
  /// In en, this message translates to:
  /// **'Tell me your situation. I’ll find relevant government schemes.'**
  String get voiceTellMeSituationFindSchemes;

  /// No description provided for @voiceSpeakerYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get voiceSpeakerYou;

  /// No description provided for @voiceSpeakerAssistant.
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get voiceSpeakerAssistant;

  /// No description provided for @voiceForYou.
  ///
  /// In en, this message translates to:
  /// **'For you'**
  String get voiceForYou;

  /// No description provided for @voiceListenOrInterrupt.
  ///
  /// In en, this message translates to:
  /// **'Listen, or tap below to interrupt'**
  String get voiceListenOrInterrupt;

  /// No description provided for @voiceSpeakNaturallyPause.
  ///
  /// In en, this message translates to:
  /// **'Speak naturally, then pause when you are done'**
  String get voiceSpeakNaturallyPause;

  /// No description provided for @voiceReadyForNextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ready for your next question'**
  String get voiceReadyForNextQuestion;

  /// No description provided for @voiceDeviceNoiseControl.
  ///
  /// In en, this message translates to:
  /// **'Device noise control'**
  String get voiceDeviceNoiseControl;

  /// No description provided for @voiceConversation.
  ///
  /// In en, this message translates to:
  /// **'Conversation'**
  String get voiceConversation;

  /// No description provided for @voiceRecommendedForYou.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get voiceRecommendedForYou;

  /// No description provided for @updatingSoon.
  ///
  /// In en, this message translates to:
  /// **'Updating Soon'**
  String get updatingSoon;

  /// No description provided for @updatingSoonCount.
  ///
  /// In en, this message translates to:
  /// **'Updating Soon'**
  String get updatingSoonCount;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @comingSoonSchemesBody.
  ///
  /// In en, this message translates to:
  /// **'Schemes under \"{name}\" are currently being verified and will be updated soon. Stay tuned!'**
  String comingSoonSchemesBody(Object name);

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// No description provided for @allMinistries.
  ///
  /// In en, this message translates to:
  /// **'All Ministries'**
  String get allMinistries;

  /// No description provided for @allStatesAndUts.
  ///
  /// In en, this message translates to:
  /// **'All States & UTs'**
  String get allStatesAndUts;

  /// No description provided for @searchCategoriesHint.
  ///
  /// In en, this message translates to:
  /// **'Search categories...'**
  String get searchCategoriesHint;

  /// No description provided for @catBusinessMsme.
  ///
  /// In en, this message translates to:
  /// **'Business & MSME'**
  String get catBusinessMsme;

  /// No description provided for @catStartupIncubation.
  ///
  /// In en, this message translates to:
  /// **'Startup & Incubation'**
  String get catStartupIncubation;

  /// No description provided for @catLoansCreditSupport.
  ///
  /// In en, this message translates to:
  /// **'Loans & Credit Support'**
  String get catLoansCreditSupport;

  /// No description provided for @catWomenEntrepreneurship.
  ///
  /// In en, this message translates to:
  /// **'Women Entrepreneurship'**
  String get catWomenEntrepreneurship;

  /// No description provided for @catFinanceBanking.
  ///
  /// In en, this message translates to:
  /// **'Finance & Banking'**
  String get catFinanceBanking;

  /// No description provided for @catSkillDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Skill Development'**
  String get catSkillDevelopment;

  /// No description provided for @catArtisanCraftsmen.
  ///
  /// In en, this message translates to:
  /// **'Artisan & Craftsmen'**
  String get catArtisanCraftsmen;

  /// No description provided for @catDigitalIndiaTech.
  ///
  /// In en, this message translates to:
  /// **'Digital India & Tech'**
  String get catDigitalIndiaTech;

  /// No description provided for @catStudentYouthStartups.
  ///
  /// In en, this message translates to:
  /// **'Student & Youth Startups'**
  String get catStudentYouthStartups;

  /// No description provided for @catManufacturingIndustry.
  ///
  /// In en, this message translates to:
  /// **'Manufacturing & Industry'**
  String get catManufacturingIndustry;

  /// No description provided for @catExportTradePromotion.
  ///
  /// In en, this message translates to:
  /// **'Export & Trade Promotion'**
  String get catExportTradePromotion;

  /// No description provided for @catAgricultureAllied.
  ///
  /// In en, this message translates to:
  /// **'Agriculture & Allied'**
  String get catAgricultureAllied;

  /// No description provided for @catRuralDevelopmentShg.
  ///
  /// In en, this message translates to:
  /// **'Rural Development & SHG'**
  String get catRuralDevelopmentShg;

  /// No description provided for @catTechnologyInnovation.
  ///
  /// In en, this message translates to:
  /// **'Technology & Innovation'**
  String get catTechnologyInnovation;

  /// No description provided for @catKhadiVillageIndustries.
  ///
  /// In en, this message translates to:
  /// **'Khadi & Village Industries'**
  String get catKhadiVillageIndustries;

  /// No description provided for @catScStMinority.
  ///
  /// In en, this message translates to:
  /// **'SC / ST & Minority'**
  String get catScStMinority;

  /// No description provided for @catGreenEnergyEnvironment.
  ///
  /// In en, this message translates to:
  /// **'Green Energy & Environment'**
  String get catGreenEnergyEnvironment;

  /// No description provided for @catHealthHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Health & Healthcare'**
  String get catHealthHealthcare;

  /// No description provided for @catFoodProcessing.
  ///
  /// In en, this message translates to:
  /// **'Food Processing'**
  String get catFoodProcessing;

  /// No description provided for @catEducationFellowship.
  ///
  /// In en, this message translates to:
  /// **'Education & Fellowship'**
  String get catEducationFellowship;

  /// No description provided for @catInfrastructureLogistics.
  ///
  /// In en, this message translates to:
  /// **'Infrastructure & Logistics'**
  String get catInfrastructureLogistics;

  /// No description provided for @catSocialWelfareSupport.
  ///
  /// In en, this message translates to:
  /// **'Social Welfare & Support'**
  String get catSocialWelfareSupport;

  /// No description provided for @catRenewableEnergyEfficiency.
  ///
  /// In en, this message translates to:
  /// **'Renewable & Energy Efficiency'**
  String get catRenewableEnergyEfficiency;

  /// No description provided for @msmeWhatTheUserGets.
  ///
  /// In en, this message translates to:
  /// **'WHAT THE USER GETS'**
  String get msmeWhatTheUserGets;

  /// No description provided for @msmeInteractiveToolsActions.
  ///
  /// In en, this message translates to:
  /// **'Interactive Tools & Actions'**
  String get msmeInteractiveToolsActions;

  /// No description provided for @msmeInteractiveToolsDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile or explore schemes with the search engine to get smart matching results.'**
  String get msmeInteractiveToolsDesc;

  /// No description provided for @msmeSearchSchemes.
  ///
  /// In en, this message translates to:
  /// **'Search Schemes'**
  String get msmeSearchSchemes;

  /// No description provided for @msmeDelayedPaymentCalcTitle.
  ///
  /// In en, this message translates to:
  /// **'Delayed Payment Interest Calculator'**
  String get msmeDelayedPaymentCalcTitle;

  /// No description provided for @msmeDelayedPaymentCalcDesc.
  ///
  /// In en, this message translates to:
  /// **'Under the MSMED Act Section 15/16, buyers must pay 3x the RBI Bank Rate as compound interest with monthly rests for delays exceeding 45 days.'**
  String get msmeDelayedPaymentCalcDesc;

  /// No description provided for @msmeInvoiceAmountRupees.
  ///
  /// In en, this message translates to:
  /// **'Invoice Amount (₹)'**
  String get msmeInvoiceAmountRupees;

  /// No description provided for @msmeDaysDelayedPost45.
  ///
  /// In en, this message translates to:
  /// **'Days Delayed (Post 45d)'**
  String get msmeDaysDelayedPost45;

  /// No description provided for @msmeInterestRate3xBankRate.
  ///
  /// In en, this message translates to:
  /// **'Interest Rate (3x Bank Rate):'**
  String get msmeInterestRate3xBankRate;

  /// No description provided for @msmeCalculatedInterestLabel.
  ///
  /// In en, this message translates to:
  /// **'Calculated Interest:'**
  String get msmeCalculatedInterestLabel;

  /// No description provided for @msmeTotalClaimableAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Claimable Amount:'**
  String get msmeTotalClaimableAmountLabel;

  /// No description provided for @msmeStepNumber.
  ///
  /// In en, this message translates to:
  /// **'Step {number}'**
  String msmeStepNumber(Object number);

  /// No description provided for @msmeSearchSupportInstitutions.
  ///
  /// In en, this message translates to:
  /// **'Search Support Institutions'**
  String get msmeSearchSupportInstitutions;

  /// No description provided for @msmeSearchInstitutionsHint.
  ///
  /// In en, this message translates to:
  /// **'Search SIDBI, NSIC, DIC...'**
  String get msmeSearchInstitutionsHint;

  /// No description provided for @msmeRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get msmeRoleLabel;

  /// No description provided for @msmeKeyServicesLabel.
  ///
  /// In en, this message translates to:
  /// **'Key Services'**
  String get msmeKeyServicesLabel;

  /// No description provided for @msmeTopSchemesLabel.
  ///
  /// In en, this message translates to:
  /// **'Top Schemes'**
  String get msmeTopSchemesLabel;

  /// No description provided for @msmeMainFeaturesInside.
  ///
  /// In en, this message translates to:
  /// **'Main Features Inside'**
  String get msmeMainFeaturesInside;

  /// No description provided for @msmeFeatureSchemes1.
  ///
  /// In en, this message translates to:
  /// **'Personalized schemes matched to business profile'**
  String get msmeFeatureSchemes1;

  /// No description provided for @msmeFeatureSchemes2.
  ///
  /// In en, this message translates to:
  /// **'Central vs. State schemes filter'**
  String get msmeFeatureSchemes2;

  /// No description provided for @msmeFeatureSchemes3.
  ///
  /// In en, this message translates to:
  /// **'Comprehensive eligibility checker'**
  String get msmeFeatureSchemes3;

  /// No description provided for @msmeFeatureSchemes4.
  ///
  /// In en, this message translates to:
  /// **'Search by scheme categories'**
  String get msmeFeatureSchemes4;

  /// No description provided for @msmeFeatureSchemes5.
  ///
  /// In en, this message translates to:
  /// **'Capital subsidies, grants & interest subventions'**
  String get msmeFeatureSchemes5;

  /// No description provided for @msmeFeatureSchemes6.
  ///
  /// In en, this message translates to:
  /// **'Lists of required documents & checklists'**
  String get msmeFeatureSchemes6;

  /// No description provided for @msmeFeatureSchemes7.
  ///
  /// In en, this message translates to:
  /// **'Clear, step-by-step application guidelines'**
  String get msmeFeatureSchemes7;

  /// No description provided for @msmeFeatureSchemes8.
  ///
  /// In en, this message translates to:
  /// **'Save schemes for later'**
  String get msmeFeatureSchemes8;

  /// No description provided for @msmeFeatureFinance1.
  ///
  /// In en, this message translates to:
  /// **'Collateral-free business term loans & working capital'**
  String get msmeFeatureFinance1;

  /// No description provided for @msmeFeatureFinance2.
  ///
  /// In en, this message translates to:
  /// **'SIDBI specialized credit schemes for machinery & tools'**
  String get msmeFeatureFinance2;

  /// No description provided for @msmeFeatureFinance3.
  ///
  /// In en, this message translates to:
  /// **'Credit Guarantees (CGTMSE) for collateral-free bank options'**
  String get msmeFeatureFinance3;

  /// No description provided for @msmeFeatureFinance4.
  ///
  /// In en, this message translates to:
  /// **'Equipment & machinery financing models'**
  String get msmeFeatureFinance4;

  /// No description provided for @msmeFeatureFinance5.
  ///
  /// In en, this message translates to:
  /// **'Detailed comparisons of loan interest rates'**
  String get msmeFeatureFinance5;

  /// No description provided for @msmeFeatureFinance6.
  ///
  /// In en, this message translates to:
  /// **'Direct contact pathways to SIDBI & partner commercial banks'**
  String get msmeFeatureFinance6;

  /// No description provided for @msmeFeatureFinance7.
  ///
  /// In en, this message translates to:
  /// **'SME IPO listing requirements (BSE SME & NSE Emerge)'**
  String get msmeFeatureFinance7;

  /// No description provided for @msmeFeatureTaxGst1.
  ///
  /// In en, this message translates to:
  /// **'MSME Corporate Income-Tax benefits'**
  String get msmeFeatureTaxGst1;

  /// No description provided for @msmeFeatureTaxGst2.
  ///
  /// In en, this message translates to:
  /// **'GST registration threshold limits (₹40/₹20 Lakhs exemptions)'**
  String get msmeFeatureTaxGst2;

  /// No description provided for @msmeFeatureTaxGst3.
  ///
  /// In en, this message translates to:
  /// **'GST Composition Scheme parameters (1% tax, easier filings)'**
  String get msmeFeatureTaxGst3;

  /// No description provided for @msmeFeatureTaxGst4.
  ///
  /// In en, this message translates to:
  /// **'Section 43B(h) Income Tax protection (45-day payment rule)'**
  String get msmeFeatureTaxGst4;

  /// No description provided for @msmeFeatureTaxGst5.
  ///
  /// In en, this message translates to:
  /// **'Late payment interest claim calculator (3x Bank Rate)'**
  String get msmeFeatureTaxGst5;

  /// No description provided for @msmeFeatureTaxGst6.
  ///
  /// In en, this message translates to:
  /// **'Export tax refunds & LUT (Letter of Undertaking) rules'**
  String get msmeFeatureTaxGst6;

  /// No description provided for @msmeFeatureTaxGst7.
  ///
  /// In en, this message translates to:
  /// **'MSME Samadhaan portal recovery guidelines'**
  String get msmeFeatureTaxGst7;

  /// No description provided for @msmeFeatureExport1.
  ///
  /// In en, this message translates to:
  /// **'Duty refund schemes (RoDTEP, RoSCTL) & Drawbacks'**
  String get msmeFeatureExport1;

  /// No description provided for @msmeFeatureExport2.
  ///
  /// In en, this message translates to:
  /// **'Pre-shipment & Post-shipment export credit financing'**
  String get msmeFeatureExport2;

  /// No description provided for @msmeFeatureExport3.
  ///
  /// In en, this message translates to:
  /// **'Interest subvention on foreign currency loans'**
  String get msmeFeatureExport3;

  /// No description provided for @msmeFeatureExport4.
  ///
  /// In en, this message translates to:
  /// **'ECGC credit risk insurance coverage policies'**
  String get msmeFeatureExport4;

  /// No description provided for @msmeFeatureExport5.
  ///
  /// In en, this message translates to:
  /// **'MDA & MAI schemes for foreign exhibition participation'**
  String get msmeFeatureExport5;

  /// No description provided for @msmeFeatureExport6.
  ///
  /// In en, this message translates to:
  /// **'Directory of Export Councils & DGFT field offices'**
  String get msmeFeatureExport6;

  /// No description provided for @msmeFeatureExport7.
  ///
  /// In en, this message translates to:
  /// **'HS Code classifications & AD Code registration guide'**
  String get msmeFeatureExport7;

  /// No description provided for @msmeFeatureTreds1.
  ///
  /// In en, this message translates to:
  /// **'Invoice Discounting multi-party platforms explainer'**
  String get msmeFeatureTreds1;

  /// No description provided for @msmeFeatureTreds2.
  ///
  /// In en, this message translates to:
  /// **'Onboarding guidelines for MSME Sellers'**
  String get msmeFeatureTreds2;

  /// No description provided for @msmeFeatureTreds3.
  ///
  /// In en, this message translates to:
  /// **'RXIL, M1xchange & Invoicemart registration steps'**
  String get msmeFeatureTreds3;

  /// No description provided for @msmeFeatureTreds4.
  ///
  /// In en, this message translates to:
  /// **'Acceptance guidelines for Corporate Buyers'**
  String get msmeFeatureTreds4;

  /// No description provided for @msmeFeatureTreds5.
  ///
  /// In en, this message translates to:
  /// **'Financier bidding flow (anonymized auction for best rates)'**
  String get msmeFeatureTreds5;

  /// No description provided for @msmeFeatureTreds6.
  ///
  /// In en, this message translates to:
  /// **'Payment settlement pathways (T+1 credit cycles)'**
  String get msmeFeatureTreds6;

  /// No description provided for @msmeFeatureTreds7.
  ///
  /// In en, this message translates to:
  /// **'Recourse vs. Non-recourse factoring definitions'**
  String get msmeFeatureTreds7;

  /// No description provided for @msmeFeatureCsr1.
  ///
  /// In en, this message translates to:
  /// **'Corporate CSR-backed cluster development funding'**
  String get msmeFeatureCsr1;

  /// No description provided for @msmeFeatureCsr2.
  ///
  /// In en, this message translates to:
  /// **'Access to corporate incubation grants for prototype support'**
  String get msmeFeatureCsr2;

  /// No description provided for @msmeFeatureCsr3.
  ///
  /// In en, this message translates to:
  /// **'Specialized green-energy & waste-management cluster programs'**
  String get msmeFeatureCsr3;

  /// No description provided for @msmeFeatureCsr4.
  ///
  /// In en, this message translates to:
  /// **'Skill development & technology upgrade programs'**
  String get msmeFeatureCsr4;

  /// No description provided for @msmeFeatureCsr5.
  ///
  /// In en, this message translates to:
  /// **'List of CSR implementing agencies & NGOs'**
  String get msmeFeatureCsr5;

  /// No description provided for @msmeFeatureCsr6.
  ///
  /// In en, this message translates to:
  /// **'Eligibility checklists & application pathways'**
  String get msmeFeatureCsr6;

  /// No description provided for @msmeFeatureGovt1.
  ///
  /// In en, this message translates to:
  /// **'Ministry of MSME (Central Govt) policies & initiatives'**
  String get msmeFeatureGovt1;

  /// No description provided for @msmeFeatureGovt2.
  ///
  /// In en, this message translates to:
  /// **'State Directorate of Industries / Dept of Commerce role'**
  String get msmeFeatureGovt2;

  /// No description provided for @msmeFeatureGovt3.
  ///
  /// In en, this message translates to:
  /// **'District Industries Centre (DIC) local assistance offices'**
  String get msmeFeatureGovt3;

  /// No description provided for @msmeFeatureGovt4.
  ///
  /// In en, this message translates to:
  /// **'Clear hierarchies: Central -> State -> District levels'**
  String get msmeFeatureGovt4;

  /// No description provided for @msmeFeatureGovt5.
  ///
  /// In en, this message translates to:
  /// **'Key contact directories & nodal officer lists'**
  String get msmeFeatureGovt5;

  /// No description provided for @msmeFeatureGovt6.
  ///
  /// In en, this message translates to:
  /// **'Authority-specific schemes (PMEGP vs State subsidies)'**
  String get msmeFeatureGovt6;

  /// No description provided for @msmeFeatureInstitutions1.
  ///
  /// In en, this message translates to:
  /// **'SIDBI (Small Industries Development Bank of India) credit portals'**
  String get msmeFeatureInstitutions1;

  /// No description provided for @msmeFeatureInstitutions2.
  ///
  /// In en, this message translates to:
  /// **'NSIC (National Small Industries Corporation) raw material support'**
  String get msmeFeatureInstitutions2;

  /// No description provided for @msmeFeatureInstitutions3.
  ///
  /// In en, this message translates to:
  /// **'DIC (District Industries Centre) single-window registrations'**
  String get msmeFeatureInstitutions3;

  /// No description provided for @msmeFeatureInstitutions4.
  ///
  /// In en, this message translates to:
  /// **'KVIC (Khadi and Village Industries Commission) rural projects'**
  String get msmeFeatureInstitutions4;

  /// No description provided for @msmeFeatureInstitutions5.
  ///
  /// In en, this message translates to:
  /// **'TIIC, StartupTN, FaMeTN, SIPCOT regional service descriptions'**
  String get msmeFeatureInstitutions5;

  /// No description provided for @msmeFeatureInstitutions6.
  ///
  /// In en, this message translates to:
  /// **'Program services catalog & contact application routes'**
  String get msmeFeatureInstitutions6;

  /// No description provided for @msmeFeatureUdyam1.
  ///
  /// In en, this message translates to:
  /// **'100% Free & Paperless Instant Portal Registration'**
  String get msmeFeatureUdyam1;

  /// No description provided for @msmeFeatureUdyam2.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Validity with QR Code e-Certificate'**
  String get msmeFeatureUdyam2;

  /// No description provided for @msmeFeatureUdyam3.
  ///
  /// In en, this message translates to:
  /// **'Automatic CGTMSE Collateral-Free Credit & TReDS Eligibility'**
  String get msmeFeatureUdyam3;

  /// No description provided for @msmeFeatureUdyam4.
  ///
  /// In en, this message translates to:
  /// **'Exemption from Earnest Money Deposit (EMD) in Govt Tenders'**
  String get msmeFeatureUdyam4;

  /// No description provided for @msmeFeatureUdyam5.
  ///
  /// In en, this message translates to:
  /// **'Eligible for 15% CLCSS Technology & Capital Subsidies'**
  String get msmeFeatureUdyam5;

  /// No description provided for @msmeFeatureUdyam6.
  ///
  /// In en, this message translates to:
  /// **'Concessional Electricity & Patent Registration Fee Waiver'**
  String get msmeFeatureUdyam6;

  /// No description provided for @croreSuffix.
  ///
  /// In en, this message translates to:
  /// **'Cr'**
  String get croreSuffix;

  /// No description provided for @assessEduQ1.
  ///
  /// In en, this message translates to:
  /// **'What is your current level of education?'**
  String get assessEduQ1;

  /// No description provided for @assessEduQ1Opt1.
  ///
  /// In en, this message translates to:
  /// **'Schooling (Up to 12th)'**
  String get assessEduQ1Opt1;

  /// No description provided for @assessEduQ1Opt2.
  ///
  /// In en, this message translates to:
  /// **'Undergraduate'**
  String get assessEduQ1Opt2;

  /// No description provided for @assessEduQ1Opt3.
  ///
  /// In en, this message translates to:
  /// **'Postgraduate'**
  String get assessEduQ1Opt3;

  /// No description provided for @assessEduQ1Opt4.
  ///
  /// In en, this message translates to:
  /// **'Ph.D. & Research'**
  String get assessEduQ1Opt4;

  /// No description provided for @assessEduQ2School.
  ///
  /// In en, this message translates to:
  /// **'What class/grade are you currently enrolled in?'**
  String get assessEduQ2School;

  /// No description provided for @assessEduQ2SchoolOpt1.
  ///
  /// In en, this message translates to:
  /// **'Class 1 - 8 (Primary)'**
  String get assessEduQ2SchoolOpt1;

  /// No description provided for @assessEduQ2SchoolOpt2.
  ///
  /// In en, this message translates to:
  /// **'Class 9 - 10 (Secondary)'**
  String get assessEduQ2SchoolOpt2;

  /// No description provided for @assessEduQ2SchoolOpt3.
  ///
  /// In en, this message translates to:
  /// **'Class 11 - 12 (Higher Secondary)'**
  String get assessEduQ2SchoolOpt3;

  /// No description provided for @assessEduQ2College.
  ///
  /// In en, this message translates to:
  /// **'What is your primary stream of study?'**
  String get assessEduQ2College;

  /// No description provided for @assessEduQ2CollegeOpt1.
  ///
  /// In en, this message translates to:
  /// **'STEM (Science/Engineering/IT)'**
  String get assessEduQ2CollegeOpt1;

  /// No description provided for @assessEduQ2CollegeOpt2.
  ///
  /// In en, this message translates to:
  /// **'Arts, Commerce & Humanities'**
  String get assessEduQ2CollegeOpt2;

  /// No description provided for @assessEduQ2CollegeOpt3.
  ///
  /// In en, this message translates to:
  /// **'Medical & Nursing'**
  String get assessEduQ2CollegeOpt3;

  /// No description provided for @assessEduQ2CollegeOpt4.
  ///
  /// In en, this message translates to:
  /// **'Agricultural Studies'**
  String get assessEduQ2CollegeOpt4;

  /// No description provided for @assessEduQ2Research.
  ///
  /// In en, this message translates to:
  /// **'What is your research specialization domain?'**
  String get assessEduQ2Research;

  /// No description provided for @assessEduQ2ResearchOpt1.
  ///
  /// In en, this message translates to:
  /// **'STEM Research & Patents'**
  String get assessEduQ2ResearchOpt1;

  /// No description provided for @assessEduQ2ResearchOpt2.
  ///
  /// In en, this message translates to:
  /// **'Humanities & Social Sciences'**
  String get assessEduQ2ResearchOpt2;

  /// No description provided for @assessEduQ2ResearchOpt3.
  ///
  /// In en, this message translates to:
  /// **'Agricultural/Biological Sciences'**
  String get assessEduQ2ResearchOpt3;

  /// No description provided for @assessEduQ3School.
  ///
  /// In en, this message translates to:
  /// **'What type of aid is most important right now?'**
  String get assessEduQ3School;

  /// No description provided for @assessEduQ3SchoolOpt1.
  ///
  /// In en, this message translates to:
  /// **'Pre-matric Scholarship'**
  String get assessEduQ3SchoolOpt1;

  /// No description provided for @assessEduQ3SchoolOpt2.
  ///
  /// In en, this message translates to:
  /// **'Free textbooks & uniforms'**
  String get assessEduQ3SchoolOpt2;

  /// No description provided for @assessEduQ3SchoolOpt3.
  ///
  /// In en, this message translates to:
  /// **'Hostel accommodation subsidy'**
  String get assessEduQ3SchoolOpt3;

  /// No description provided for @assessEduQ3College.
  ///
  /// In en, this message translates to:
  /// **'Are you interested in a low-interest student education loan?'**
  String get assessEduQ3College;

  /// No description provided for @assessEduQ3CollegeOpt1.
  ///
  /// In en, this message translates to:
  /// **'Yes, need education loan'**
  String get assessEduQ3CollegeOpt1;

  /// No description provided for @assessEduQ3CollegeOpt2.
  ///
  /// In en, this message translates to:
  /// **'No, seeking tuition scholarships only'**
  String get assessEduQ3CollegeOpt2;

  /// No description provided for @assessEduQ3Research.
  ///
  /// In en, this message translates to:
  /// **'Are you seeking a research fellowship or international study grant?'**
  String get assessEduQ3Research;

  /// No description provided for @assessEduQ3ResearchOpt1.
  ///
  /// In en, this message translates to:
  /// **'National Fellowship grant'**
  String get assessEduQ3ResearchOpt1;

  /// No description provided for @assessEduQ3ResearchOpt2.
  ///
  /// In en, this message translates to:
  /// **'International study allowance'**
  String get assessEduQ3ResearchOpt2;

  /// No description provided for @assessEduQ3ResearchOpt3.
  ///
  /// In en, this message translates to:
  /// **'Merit publication awards'**
  String get assessEduQ3ResearchOpt3;

  /// No description provided for @assessEduQ4Caste.
  ///
  /// In en, this message translates to:
  /// **'What is your caste/social reservation category?'**
  String get assessEduQ4Caste;

  /// No description provided for @assessEduQ4CasteOpt1.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get assessEduQ4CasteOpt1;

  /// No description provided for @assessEduQ4CasteOpt2.
  ///
  /// In en, this message translates to:
  /// **'OBC'**
  String get assessEduQ4CasteOpt2;

  /// No description provided for @assessEduQ4CasteOpt3.
  ///
  /// In en, this message translates to:
  /// **'SC / ST'**
  String get assessEduQ4CasteOpt3;

  /// No description provided for @assessEduQ4CasteOpt4.
  ///
  /// In en, this message translates to:
  /// **'EWS / Minority'**
  String get assessEduQ4CasteOpt4;

  /// No description provided for @assessEduQ5Income.
  ///
  /// In en, this message translates to:
  /// **'What is your family\'s annual household income?'**
  String get assessEduQ5Income;

  /// No description provided for @assessEduQ5IncomeOpt1.
  ///
  /// In en, this message translates to:
  /// **'Under ₹2.5 Lakhs'**
  String get assessEduQ5IncomeOpt1;

  /// No description provided for @assessEduQ5IncomeOpt2.
  ///
  /// In en, this message translates to:
  /// **'₹2.5 Lakhs - ₹8 Lakhs'**
  String get assessEduQ5IncomeOpt2;

  /// No description provided for @assessEduQ5IncomeOpt3.
  ///
  /// In en, this message translates to:
  /// **'Over ₹8 Lakhs'**
  String get assessEduQ5IncomeOpt3;

  /// No description provided for @assessWomenQ1.
  ///
  /// In en, this message translates to:
  /// **'Who is the primary beneficiary of the scheme?'**
  String get assessWomenQ1;

  /// No description provided for @assessWomenQ1Opt1.
  ///
  /// In en, this message translates to:
  /// **'Pregnant or Lactating Mother'**
  String get assessWomenQ1Opt1;

  /// No description provided for @assessWomenQ1Opt2.
  ///
  /// In en, this message translates to:
  /// **'Girl Child (Parent applying)'**
  String get assessWomenQ1Opt2;

  /// No description provided for @assessWomenQ1Opt3.
  ///
  /// In en, this message translates to:
  /// **'Woman Entrepreneur'**
  String get assessWomenQ1Opt3;

  /// No description provided for @assessWomenQ1Opt4.
  ///
  /// In en, this message translates to:
  /// **'Single Woman / Widow in distress'**
  String get assessWomenQ1Opt4;

  /// No description provided for @assessWomenQ2Maternal.
  ///
  /// In en, this message translates to:
  /// **'Is this your first or second pregnancy?'**
  String get assessWomenQ2Maternal;

  /// No description provided for @assessWomenQ2MaternalOpt1.
  ///
  /// In en, this message translates to:
  /// **'First pregnancy'**
  String get assessWomenQ2MaternalOpt1;

  /// No description provided for @assessWomenQ2MaternalOpt2.
  ///
  /// In en, this message translates to:
  /// **'Second pregnancy'**
  String get assessWomenQ2MaternalOpt2;

  /// No description provided for @assessWomenQ2MaternalOpt3.
  ///
  /// In en, this message translates to:
  /// **'More than two'**
  String get assessWomenQ2MaternalOpt3;

  /// No description provided for @assessWomenQ2Girl.
  ///
  /// In en, this message translates to:
  /// **'What is the age of the girl child?'**
  String get assessWomenQ2Girl;

  /// No description provided for @assessWomenQ2GirlOpt1.
  ///
  /// In en, this message translates to:
  /// **'Newborn (0 - 1 Year)'**
  String get assessWomenQ2GirlOpt1;

  /// No description provided for @assessWomenQ2GirlOpt2.
  ///
  /// In en, this message translates to:
  /// **'Child (2 - 10 Years)'**
  String get assessWomenQ2GirlOpt2;

  /// No description provided for @assessWomenQ2GirlOpt3.
  ///
  /// In en, this message translates to:
  /// **'Adolescent (11 - 18 Years)'**
  String get assessWomenQ2GirlOpt3;

  /// No description provided for @assessWomenQ2Biz.
  ///
  /// In en, this message translates to:
  /// **'Do women hold at least a 51% ownership stake in the enterprise?'**
  String get assessWomenQ2Biz;

  /// No description provided for @assessWomenQ2BizOpt1.
  ///
  /// In en, this message translates to:
  /// **'Yes, fully owned by women'**
  String get assessWomenQ2BizOpt1;

  /// No description provided for @assessWomenQ2BizOpt2.
  ///
  /// In en, this message translates to:
  /// **'No, minor/shared stake'**
  String get assessWomenQ2BizOpt2;

  /// No description provided for @assessWomenQ2Welfare.
  ///
  /// In en, this message translates to:
  /// **'Do you possess a BPL (Below Poverty Line) Ration Card?'**
  String get assessWomenQ2Welfare;

  /// No description provided for @assessWomenQ2WelfareOpt1.
  ///
  /// In en, this message translates to:
  /// **'Yes, BPL Cardholder'**
  String get assessWomenQ2WelfareOpt1;

  /// No description provided for @assessWomenQ2WelfareOpt2.
  ///
  /// In en, this message translates to:
  /// **'No, APL / General'**
  String get assessWomenQ2WelfareOpt2;

  /// No description provided for @assessWomenQ3MaternReg.
  ///
  /// In en, this message translates to:
  /// **'Are you registered at your local Anganwadi/Health center?'**
  String get assessWomenQ3MaternReg;

  /// No description provided for @assessWomenQ3MaternRegOpt1.
  ///
  /// In en, this message translates to:
  /// **'Yes, registered'**
  String get assessWomenQ3MaternRegOpt1;

  /// No description provided for @assessWomenQ3MaternRegOpt2.
  ///
  /// In en, this message translates to:
  /// **'No, not registered yet'**
  String get assessWomenQ3MaternRegOpt2;

  /// No description provided for @assessWomenQ3GirlSave.
  ///
  /// In en, this message translates to:
  /// **'Would you like to open a long-term savings account (Sukanya Samriddhi)?'**
  String get assessWomenQ3GirlSave;

  /// No description provided for @assessWomenQ3GirlSaveOpt1.
  ///
  /// In en, this message translates to:
  /// **'Yes, open savings account'**
  String get assessWomenQ3GirlSaveOpt1;

  /// No description provided for @assessWomenQ3GirlSaveOpt2.
  ///
  /// In en, this message translates to:
  /// **'No, seeking educational scholarships'**
  String get assessWomenQ3GirlSaveOpt2;

  /// No description provided for @assessWomenQ3GirlEdu.
  ///
  /// In en, this message translates to:
  /// **'Is the girl child currently enrolled in school/college?'**
  String get assessWomenQ3GirlEdu;

  /// No description provided for @assessWomenQ3GirlEduOpt1.
  ///
  /// In en, this message translates to:
  /// **'Yes, attending school/college'**
  String get assessWomenQ3GirlEduOpt1;

  /// No description provided for @assessWomenQ3GirlEduOpt2.
  ///
  /// In en, this message translates to:
  /// **'No, discontinued education'**
  String get assessWomenQ3GirlEduOpt2;

  /// No description provided for @assessWomenQ3BizCredit.
  ///
  /// In en, this message translates to:
  /// **'What capital support size are you seeking for your business?'**
  String get assessWomenQ3BizCredit;

  /// No description provided for @assessWomenQ3BizCreditOpt1.
  ///
  /// In en, this message translates to:
  /// **'Micro-credit (Under ₹1 Lakh)'**
  String get assessWomenQ3BizCreditOpt1;

  /// No description provided for @assessWomenQ3BizCreditOpt2.
  ///
  /// In en, this message translates to:
  /// **'SME Loan (₹1 Lakh - ₹10 Lakhs)'**
  String get assessWomenQ3BizCreditOpt2;

  /// No description provided for @assessWomenQ3BizCreditOpt3.
  ///
  /// In en, this message translates to:
  /// **'Stand-Up India loan (Over ₹10 Lakhs)'**
  String get assessWomenQ3BizCreditOpt3;

  /// No description provided for @assessWomenQ3WelfarePension.
  ///
  /// In en, this message translates to:
  /// **'Are you currently receiving any monthly social pension?'**
  String get assessWomenQ3WelfarePension;

  /// No description provided for @assessWomenQ3WelfarePensionOpt1.
  ///
  /// In en, this message translates to:
  /// **'Yes, receiving widow pension'**
  String get assessWomenQ3WelfarePensionOpt1;

  /// No description provided for @assessWomenQ3WelfarePensionOpt2.
  ///
  /// In en, this message translates to:
  /// **'No pension received'**
  String get assessWomenQ3WelfarePensionOpt2;

  /// No description provided for @assessWomenQ4Caste.
  ///
  /// In en, this message translates to:
  /// **'What is your caste/social category?'**
  String get assessWomenQ4Caste;

  /// No description provided for @assessWomenQ4CasteOpt1.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get assessWomenQ4CasteOpt1;

  /// No description provided for @assessWomenQ4CasteOpt2.
  ///
  /// In en, this message translates to:
  /// **'OBC'**
  String get assessWomenQ4CasteOpt2;

  /// No description provided for @assessWomenQ4CasteOpt3.
  ///
  /// In en, this message translates to:
  /// **'SC / ST'**
  String get assessWomenQ4CasteOpt3;

  /// No description provided for @assessWomenQ4CasteOpt4.
  ///
  /// In en, this message translates to:
  /// **'Minority / EWS'**
  String get assessWomenQ4CasteOpt4;

  /// No description provided for @assessWomenQ5Income.
  ///
  /// In en, this message translates to:
  /// **'What is your family\'s annual income?'**
  String get assessWomenQ5Income;

  /// No description provided for @assessWomenQ5IncomeOpt1.
  ///
  /// In en, this message translates to:
  /// **'Under ₹1.5 Lakhs'**
  String get assessWomenQ5IncomeOpt1;

  /// No description provided for @assessWomenQ5IncomeOpt2.
  ///
  /// In en, this message translates to:
  /// **'₹1.5 Lakhs - ₹5 Lakhs'**
  String get assessWomenQ5IncomeOpt2;

  /// No description provided for @assessWomenQ5IncomeOpt3.
  ///
  /// In en, this message translates to:
  /// **'Over ₹5 Lakhs'**
  String get assessWomenQ5IncomeOpt3;

  /// No description provided for @assessBizQ1.
  ///
  /// In en, this message translates to:
  /// **'Is your business legally registered?'**
  String get assessBizQ1;

  /// No description provided for @assessBizQ1Opt1.
  ///
  /// In en, this message translates to:
  /// **'Yes, under MSME Udyam'**
  String get assessBizQ1Opt1;

  /// No description provided for @assessBizQ1Opt2.
  ///
  /// In en, this message translates to:
  /// **'Yes, as a DPIIT Startup'**
  String get assessBizQ1Opt2;

  /// No description provided for @assessBizQ1Opt3.
  ///
  /// In en, this message translates to:
  /// **'No, operating as individual trader/artisan'**
  String get assessBizQ1Opt3;

  /// No description provided for @assessBizQ1Opt4.
  ///
  /// In en, this message translates to:
  /// **'No, it is in idea stage'**
  String get assessBizQ1Opt4;

  /// No description provided for @assessBizQ2Msme.
  ///
  /// In en, this message translates to:
  /// **'What is the total investment in machinery/equipment?'**
  String get assessBizQ2Msme;

  /// No description provided for @assessBizQ2MsmeOpt1.
  ///
  /// In en, this message translates to:
  /// **'Micro (up to ₹2.5 Crore investment)'**
  String get assessBizQ2MsmeOpt1;

  /// No description provided for @assessBizQ2MsmeOpt2.
  ///
  /// In en, this message translates to:
  /// **'Small (₹2.5 Crore - ₹25 Crore)'**
  String get assessBizQ2MsmeOpt2;

  /// No description provided for @assessBizQ2MsmeOpt3.
  ///
  /// In en, this message translates to:
  /// **'Medium (₹25 Crore - ₹125 Crore)'**
  String get assessBizQ2MsmeOpt3;

  /// No description provided for @assessBizQ2Startup.
  ///
  /// In en, this message translates to:
  /// **'What stage is your startup currently in?'**
  String get assessBizQ2Startup;

  /// No description provided for @assessBizQ2StartupOpt1.
  ///
  /// In en, this message translates to:
  /// **'Prototype / MVP development'**
  String get assessBizQ2StartupOpt1;

  /// No description provided for @assessBizQ2StartupOpt2.
  ///
  /// In en, this message translates to:
  /// **'Early Revenue / Validation'**
  String get assessBizQ2StartupOpt2;

  /// No description provided for @assessBizQ2StartupOpt3.
  ///
  /// In en, this message translates to:
  /// **'Scaling & expansion'**
  String get assessBizQ2StartupOpt3;

  /// No description provided for @assessBizQ2Artisan.
  ///
  /// In en, this message translates to:
  /// **'Do you hold a valid PM Vishwakarma Card or Artisan ID?'**
  String get assessBizQ2Artisan;

  /// No description provided for @assessBizQ2ArtisanOpt1.
  ///
  /// In en, this message translates to:
  /// **'Yes, active card'**
  String get assessBizQ2ArtisanOpt1;

  /// No description provided for @assessBizQ2ArtisanOpt2.
  ///
  /// In en, this message translates to:
  /// **'No, not registered'**
  String get assessBizQ2ArtisanOpt2;

  /// No description provided for @assessBizQ2Idea.
  ///
  /// In en, this message translates to:
  /// **'Do you have a business project report prepared?'**
  String get assessBizQ2Idea;

  /// No description provided for @assessBizQ2IdeaOpt1.
  ///
  /// In en, this message translates to:
  /// **'Yes, report is ready'**
  String get assessBizQ2IdeaOpt1;

  /// No description provided for @assessBizQ2IdeaOpt2.
  ///
  /// In en, this message translates to:
  /// **'No, need project guidance'**
  String get assessBizQ2IdeaOpt2;

  /// No description provided for @assessBizQ3MsmeNeed.
  ///
  /// In en, this message translates to:
  /// **'What primary credit/loan support do you need?'**
  String get assessBizQ3MsmeNeed;

  /// No description provided for @assessBizQ3MsmeNeedOpt1.
  ///
  /// In en, this message translates to:
  /// **'Collateral-free Mudra Loan'**
  String get assessBizQ3MsmeNeedOpt1;

  /// No description provided for @assessBizQ3MsmeNeedOpt2.
  ///
  /// In en, this message translates to:
  /// **'Working capital guarantee (CGTMSE)'**
  String get assessBizQ3MsmeNeedOpt2;

  /// No description provided for @assessBizQ3MsmeNeedOpt3.
  ///
  /// In en, this message translates to:
  /// **'Equipment purchase capital subsidy'**
  String get assessBizQ3MsmeNeedOpt3;

  /// No description provided for @assessBizQ3StartupNeed.
  ///
  /// In en, this message translates to:
  /// **'Are you seeking equity funding or tax exemptions?'**
  String get assessBizQ3StartupNeed;

  /// No description provided for @assessBizQ3StartupNeedOpt1.
  ///
  /// In en, this message translates to:
  /// **'Government Seed Funding'**
  String get assessBizQ3StartupNeedOpt1;

  /// No description provided for @assessBizQ3StartupNeedOpt2.
  ///
  /// In en, this message translates to:
  /// **'Section 80-IAC Tax Exemption'**
  String get assessBizQ3StartupNeedOpt2;

  /// No description provided for @assessBizQ3StartupNeedOpt3.
  ///
  /// In en, this message translates to:
  /// **'Incubator mentoring grant'**
  String get assessBizQ3StartupNeedOpt3;

  /// No description provided for @assessBizQ3ArtisanNeed.
  ///
  /// In en, this message translates to:
  /// **'What support does your craft require?'**
  String get assessBizQ3ArtisanNeed;

  /// No description provided for @assessBizQ3ArtisanNeedOpt1.
  ///
  /// In en, this message translates to:
  /// **'Free toolkit upgrade voucher'**
  String get assessBizQ3ArtisanNeedOpt1;

  /// No description provided for @assessBizQ3ArtisanNeedOpt2.
  ///
  /// In en, this message translates to:
  /// **'Exhibition & stall subsidies'**
  String get assessBizQ3ArtisanNeedOpt2;

  /// No description provided for @assessBizQ3ArtisanNeedOpt3.
  ///
  /// In en, this message translates to:
  /// **'Individual craft micro-loan'**
  String get assessBizQ3ArtisanNeedOpt3;

  /// No description provided for @assessBizQ4Demographics.
  ///
  /// In en, this message translates to:
  /// **'Is the primary owner a Woman or SC/ST entrepreneur?'**
  String get assessBizQ4Demographics;

  /// No description provided for @assessBizQ4DemographicsOpt1.
  ///
  /// In en, this message translates to:
  /// **'Yes, woman entrepreneur'**
  String get assessBizQ4DemographicsOpt1;

  /// No description provided for @assessBizQ4DemographicsOpt2.
  ///
  /// In en, this message translates to:
  /// **'Yes, SC/ST entrepreneur'**
  String get assessBizQ4DemographicsOpt2;

  /// No description provided for @assessBizQ4DemographicsOpt3.
  ///
  /// In en, this message translates to:
  /// **'Yes, both SC/ST & Woman'**
  String get assessBizQ4DemographicsOpt3;

  /// No description provided for @assessBizQ4DemographicsOpt4.
  ///
  /// In en, this message translates to:
  /// **'General category Male'**
  String get assessBizQ4DemographicsOpt4;

  /// No description provided for @assessBizQ5Turnover.
  ///
  /// In en, this message translates to:
  /// **'What is the annual turnover or estimated revenue of the business?'**
  String get assessBizQ5Turnover;

  /// No description provided for @assessBizQ5TurnoverOpt1.
  ///
  /// In en, this message translates to:
  /// **'Under ₹10 Lakhs'**
  String get assessBizQ5TurnoverOpt1;

  /// No description provided for @assessBizQ5TurnoverOpt2.
  ///
  /// In en, this message translates to:
  /// **'₹10 Lakhs - ₹50 Lakhs'**
  String get assessBizQ5TurnoverOpt2;

  /// No description provided for @assessBizQ5TurnoverOpt3.
  ///
  /// In en, this message translates to:
  /// **'₹50 Lakhs - ₹2 Crores'**
  String get assessBizQ5TurnoverOpt3;

  /// No description provided for @assessBizQ5TurnoverOpt4.
  ///
  /// In en, this message translates to:
  /// **'Over ₹2 Crores'**
  String get assessBizQ5TurnoverOpt4;

  /// No description provided for @assessAgriQ1.
  ///
  /// In en, this message translates to:
  /// **'What is your landholding size for farming?'**
  String get assessAgriQ1;

  /// No description provided for @assessAgriQ1Opt1.
  ///
  /// In en, this message translates to:
  /// **'Small / Marginal (Under 2 Hectares)'**
  String get assessAgriQ1Opt1;

  /// No description provided for @assessAgriQ1Opt2.
  ///
  /// In en, this message translates to:
  /// **'Medium (2 - 5 Hectares)'**
  String get assessAgriQ1Opt2;

  /// No description provided for @assessAgriQ1Opt3.
  ///
  /// In en, this message translates to:
  /// **'Large / Commercial (Over 5 Hectares)'**
  String get assessAgriQ1Opt3;

  /// No description provided for @assessAgriQ1Opt4.
  ///
  /// In en, this message translates to:
  /// **'Tenant / Landless Farmer'**
  String get assessAgriQ1Opt4;

  /// No description provided for @assessAgriQ2.
  ///
  /// In en, this message translates to:
  /// **'What agricultural support do you need urgently?'**
  String get assessAgriQ2;

  /// No description provided for @assessAgriQ2Opt1.
  ///
  /// In en, this message translates to:
  /// **'PM-KISAN Cash Transfer'**
  String get assessAgriQ2Opt1;

  /// No description provided for @assessAgriQ2Opt2.
  ///
  /// In en, this message translates to:
  /// **'Drip Irrigation / Equipment Subsidy'**
  String get assessAgriQ2Opt2;

  /// No description provided for @assessAgriQ2Opt3.
  ///
  /// In en, this message translates to:
  /// **'Crop Insurance & Disaster Relief'**
  String get assessAgriQ2Opt3;

  /// No description provided for @assessAgriQ2Opt4.
  ///
  /// In en, this message translates to:
  /// **'Kisan Credit Card (KCC) Loan'**
  String get assessAgriQ2Opt4;

  /// No description provided for @assessAgriQ3Caste.
  ///
  /// In en, this message translates to:
  /// **'What is your social category?'**
  String get assessAgriQ3Caste;

  /// No description provided for @assessAgriQ3CasteOpt1.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get assessAgriQ3CasteOpt1;

  /// No description provided for @assessAgriQ3CasteOpt2.
  ///
  /// In en, this message translates to:
  /// **'OBC'**
  String get assessAgriQ3CasteOpt2;

  /// No description provided for @assessAgriQ3CasteOpt3.
  ///
  /// In en, this message translates to:
  /// **'SC / ST'**
  String get assessAgriQ3CasteOpt3;

  /// No description provided for @assessAgriQ3CasteOpt4.
  ///
  /// In en, this message translates to:
  /// **'Small Farmer Special'**
  String get assessAgriQ3CasteOpt4;

  /// No description provided for @assessAgriQ4Income.
  ///
  /// In en, this message translates to:
  /// **'What is your total family annual income?'**
  String get assessAgriQ4Income;

  /// No description provided for @assessAgriQ4IncomeOpt1.
  ///
  /// In en, this message translates to:
  /// **'Under ₹1.5 Lakhs'**
  String get assessAgriQ4IncomeOpt1;

  /// No description provided for @assessAgriQ4IncomeOpt2.
  ///
  /// In en, this message translates to:
  /// **'₹1.5 Lakhs - ₹5 Lakhs'**
  String get assessAgriQ4IncomeOpt2;

  /// No description provided for @assessAgriQ4IncomeOpt3.
  ///
  /// In en, this message translates to:
  /// **'Over ₹5 Lakhs'**
  String get assessAgriQ4IncomeOpt3;

  /// No description provided for @assessSkillQ1.
  ///
  /// In en, this message translates to:
  /// **'What is your current employment or skill level?'**
  String get assessSkillQ1;

  /// No description provided for @assessSkillQ1Opt1.
  ///
  /// In en, this message translates to:
  /// **'Unemployed youth seeking job'**
  String get assessSkillQ1Opt1;

  /// No description provided for @assessSkillQ1Opt2.
  ///
  /// In en, this message translates to:
  /// **'School/College dropout'**
  String get assessSkillQ1Opt2;

  /// No description provided for @assessSkillQ1Opt3.
  ///
  /// In en, this message translates to:
  /// **'Traditional artisan / Worker'**
  String get assessSkillQ1Opt3;

  /// No description provided for @assessSkillQ1Opt4.
  ///
  /// In en, this message translates to:
  /// **'Employed seeking skill upgrade'**
  String get assessSkillQ1Opt4;

  /// No description provided for @assessSkillQ2.
  ///
  /// In en, this message translates to:
  /// **'Which skill training area interests you?'**
  String get assessSkillQ2;

  /// No description provided for @assessSkillQ2Opt1.
  ///
  /// In en, this message translates to:
  /// **'IT, Digital & Electronics'**
  String get assessSkillQ2Opt1;

  /// No description provided for @assessSkillQ2Opt2.
  ///
  /// In en, this message translates to:
  /// **'Apparel, Textile & Handicrafts'**
  String get assessSkillQ2Opt2;

  /// No description provided for @assessSkillQ2Opt3.
  ///
  /// In en, this message translates to:
  /// **'Automotive & Mechanical'**
  String get assessSkillQ2Opt3;

  /// No description provided for @assessSkillQ2Opt4.
  ///
  /// In en, this message translates to:
  /// **'Healthcare & Hospitality'**
  String get assessSkillQ2Opt4;

  /// No description provided for @assessSkillQ3.
  ///
  /// In en, this message translates to:
  /// **'Are you looking for government-certified PMKVY training?'**
  String get assessSkillQ3;

  /// No description provided for @assessSkillQ3Opt1.
  ///
  /// In en, this message translates to:
  /// **'Yes, need certified training'**
  String get assessSkillQ3Opt1;

  /// No description provided for @assessSkillQ3Opt2.
  ///
  /// In en, this message translates to:
  /// **'No, seeking self-employment stipend'**
  String get assessSkillQ3Opt2;

  /// No description provided for @assessSkillQ4Income.
  ///
  /// In en, this message translates to:
  /// **'What is your annual family income?'**
  String get assessSkillQ4Income;

  /// No description provided for @assessSkillQ4IncomeOpt1.
  ///
  /// In en, this message translates to:
  /// **'Under ₹2.5 Lakhs'**
  String get assessSkillQ4IncomeOpt1;

  /// No description provided for @assessSkillQ4IncomeOpt2.
  ///
  /// In en, this message translates to:
  /// **'₹2.5 Lakhs - ₹8 Lakhs'**
  String get assessSkillQ4IncomeOpt2;

  /// No description provided for @assessSkillQ4IncomeOpt3.
  ///
  /// In en, this message translates to:
  /// **'Over ₹8 Lakhs'**
  String get assessSkillQ4IncomeOpt3;

  /// No description provided for @assessTeQ1.
  ///
  /// In en, this message translates to:
  /// **'What is your primary enterprise focus?'**
  String get assessTeQ1;

  /// No description provided for @assessTeQ1Opt1.
  ///
  /// In en, this message translates to:
  /// **'Technology / R&D Innovation'**
  String get assessTeQ1Opt1;

  /// No description provided for @assessTeQ1Opt2.
  ///
  /// In en, this message translates to:
  /// **'Export & Trade Expansion'**
  String get assessTeQ1Opt2;

  /// No description provided for @assessTeQ1Opt3.
  ///
  /// In en, this message translates to:
  /// **'Manufacturing Production Unit'**
  String get assessTeQ1Opt3;

  /// No description provided for @assessTeQ1Opt4.
  ///
  /// In en, this message translates to:
  /// **'Digital Infrastructure'**
  String get assessTeQ1Opt4;

  /// No description provided for @assessTeQ2.
  ///
  /// In en, this message translates to:
  /// **'What specific government scheme support do you require?'**
  String get assessTeQ2;

  /// No description provided for @assessTeQ2Opt1.
  ///
  /// In en, this message translates to:
  /// **'Capital Investment Subsidy'**
  String get assessTeQ2Opt1;

  /// No description provided for @assessTeQ2Opt2.
  ///
  /// In en, this message translates to:
  /// **'Patent & R&D Filing Reimbursement'**
  String get assessTeQ2Opt2;

  /// No description provided for @assessTeQ2Opt3.
  ///
  /// In en, this message translates to:
  /// **'Market Access & International Fair Grant'**
  String get assessTeQ2Opt3;

  /// No description provided for @assessTeQ2Opt4.
  ///
  /// In en, this message translates to:
  /// **'Software & Hardware Infrastructure Support'**
  String get assessTeQ2Opt4;

  /// No description provided for @assessTeQ3Turnover.
  ///
  /// In en, this message translates to:
  /// **'What is your enterprise annual turnover?'**
  String get assessTeQ3Turnover;

  /// No description provided for @assessTeQ3TurnoverOpt1.
  ///
  /// In en, this message translates to:
  /// **'Under ₹50 Lakhs'**
  String get assessTeQ3TurnoverOpt1;

  /// No description provided for @assessTeQ3TurnoverOpt2.
  ///
  /// In en, this message translates to:
  /// **'₹50 Lakhs - ₹5 Crores'**
  String get assessTeQ3TurnoverOpt2;

  /// No description provided for @assessTeQ3TurnoverOpt3.
  ///
  /// In en, this message translates to:
  /// **'Over ₹5 Crores'**
  String get assessTeQ3TurnoverOpt3;

  /// No description provided for @assessCatQ1.
  ///
  /// In en, this message translates to:
  /// **'What describes your current employment status?'**
  String get assessCatQ1;

  /// No description provided for @assessCatQ1Opt1.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get assessCatQ1Opt1;

  /// No description provided for @assessCatQ1Opt2.
  ///
  /// In en, this message translates to:
  /// **'Farmer'**
  String get assessCatQ1Opt2;

  /// No description provided for @assessCatQ1Opt3.
  ///
  /// In en, this message translates to:
  /// **'Business Owner / Self-employed'**
  String get assessCatQ1Opt3;

  /// No description provided for @assessCatQ1Opt4.
  ///
  /// In en, this message translates to:
  /// **'Unemployed / Worker'**
  String get assessCatQ1Opt4;

  /// No description provided for @assessCatQ2.
  ///
  /// In en, this message translates to:
  /// **'Are you seeking financial credit or direct subsidy grants?'**
  String get assessCatQ2;

  /// No description provided for @assessCatQ2Opt1.
  ///
  /// In en, this message translates to:
  /// **'Business / Study Loans'**
  String get assessCatQ2Opt1;

  /// No description provided for @assessCatQ2Opt2.
  ///
  /// In en, this message translates to:
  /// **'Subsidies & welfare grants'**
  String get assessCatQ2Opt2;

  /// No description provided for @assessCatQ2Opt3.
  ///
  /// In en, this message translates to:
  /// **'Free skill training / services'**
  String get assessCatQ2Opt3;

  /// No description provided for @assessCatQ3.
  ///
  /// In en, this message translates to:
  /// **'What is your gender?'**
  String get assessCatQ3;

  /// No description provided for @assessCatQ3Opt1.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get assessCatQ3Opt1;

  /// No description provided for @assessCatQ3Opt2.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get assessCatQ3Opt2;

  /// No description provided for @assessCatQ3Opt3.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get assessCatQ3Opt3;

  /// No description provided for @assessCatQ4.
  ///
  /// In en, this message translates to:
  /// **'What is your social caste category?'**
  String get assessCatQ4;

  /// No description provided for @assessCatQ4Opt1.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get assessCatQ4Opt1;

  /// No description provided for @assessCatQ4Opt2.
  ///
  /// In en, this message translates to:
  /// **'OBC'**
  String get assessCatQ4Opt2;

  /// No description provided for @assessCatQ4Opt3.
  ///
  /// In en, this message translates to:
  /// **'SC / ST'**
  String get assessCatQ4Opt3;

  /// No description provided for @assessCatQ4Opt4.
  ///
  /// In en, this message translates to:
  /// **'EWS / Minority'**
  String get assessCatQ4Opt4;

  /// No description provided for @assessCatQ5.
  ///
  /// In en, this message translates to:
  /// **'What is your annual family income?'**
  String get assessCatQ5;

  /// No description provided for @assessCatQ5Opt1.
  ///
  /// In en, this message translates to:
  /// **'Under ₹2.5 Lakhs'**
  String get assessCatQ5Opt1;

  /// No description provided for @assessCatQ5Opt2.
  ///
  /// In en, this message translates to:
  /// **'₹2.5 Lakhs - ₹8 Lakhs'**
  String get assessCatQ5Opt2;

  /// No description provided for @assessCatQ5Opt3.
  ///
  /// In en, this message translates to:
  /// **'Over ₹8 Lakhs'**
  String get assessCatQ5Opt3;

  /// No description provided for @assessStateQ1.
  ///
  /// In en, this message translates to:
  /// **'Are you a permanent resident/domicile of {stateName}?'**
  String assessStateQ1(Object stateName);

  /// No description provided for @assessStateQ1Opt1.
  ///
  /// In en, this message translates to:
  /// **'Yes, I hold a domicile certificate'**
  String get assessStateQ1Opt1;

  /// No description provided for @assessStateQ1Opt2.
  ///
  /// In en, this message translates to:
  /// **'No, I am a temporary resident'**
  String get assessStateQ1Opt2;

  /// No description provided for @assessStateQ2.
  ///
  /// In en, this message translates to:
  /// **'What is your category in the {stateName} state reservation list?'**
  String assessStateQ2(Object stateName);

  /// No description provided for @assessStateQ2Opt1.
  ///
  /// In en, this message translates to:
  /// **'BC / SEBC / OBC'**
  String get assessStateQ2Opt1;

  /// No description provided for @assessStateQ2Opt2.
  ///
  /// In en, this message translates to:
  /// **'SC / ST'**
  String get assessStateQ2Opt2;

  /// No description provided for @assessStateQ2Opt3.
  ///
  /// In en, this message translates to:
  /// **'EWS / Minority'**
  String get assessStateQ2Opt3;

  /// No description provided for @assessStateQ2Opt4.
  ///
  /// In en, this message translates to:
  /// **'General / Open'**
  String get assessStateQ2Opt4;

  /// No description provided for @assessStateQ3.
  ///
  /// In en, this message translates to:
  /// **'What is your primary livelihood sector in {stateName}?'**
  String assessStateQ3(Object stateName);

  /// No description provided for @assessStateQ3Opt1.
  ///
  /// In en, this message translates to:
  /// **'Agriculture / Farmer'**
  String get assessStateQ3Opt1;

  /// No description provided for @assessStateQ3Opt2.
  ///
  /// In en, this message translates to:
  /// **'MSME / Startup owner'**
  String get assessStateQ3Opt2;

  /// No description provided for @assessStateQ3Opt3.
  ///
  /// In en, this message translates to:
  /// **'Weaving / Traditional Crafts'**
  String get assessStateQ3Opt3;

  /// No description provided for @assessStateQ3Opt4.
  ///
  /// In en, this message translates to:
  /// **'Student / Higher studies'**
  String get assessStateQ3Opt4;

  /// No description provided for @assessStateQ4.
  ///
  /// In en, this message translates to:
  /// **'What type of state assistance are you targeting?'**
  String get assessStateQ4;

  /// No description provided for @assessStateQ4Opt1.
  ///
  /// In en, this message translates to:
  /// **'Monthly cash allowances'**
  String get assessStateQ4Opt1;

  /// No description provided for @assessStateQ4Opt2.
  ///
  /// In en, this message translates to:
  /// **'Education fee waivers'**
  String get assessStateQ4Opt2;

  /// No description provided for @assessStateQ4Opt3.
  ///
  /// In en, this message translates to:
  /// **'Business subsidies'**
  String get assessStateQ4Opt3;

  /// No description provided for @assessStateQ4Opt4.
  ///
  /// In en, this message translates to:
  /// **'Agricultural input support'**
  String get assessStateQ4Opt4;

  /// No description provided for @assessStateQ5.
  ///
  /// In en, this message translates to:
  /// **'What is your total family annual income?'**
  String get assessStateQ5;

  /// No description provided for @assessStateQ5Opt1.
  ///
  /// In en, this message translates to:
  /// **'Under ₹1.5 Lakhs'**
  String get assessStateQ5Opt1;

  /// No description provided for @assessStateQ5Opt2.
  ///
  /// In en, this message translates to:
  /// **'₹1.5 Lakhs - ₹5 Lakhs'**
  String get assessStateQ5Opt2;

  /// No description provided for @assessStateQ5Opt3.
  ///
  /// In en, this message translates to:
  /// **'Over ₹5 Lakhs'**
  String get assessStateQ5Opt3;

  /// No description provided for @assessMinQ1.
  ///
  /// In en, this message translates to:
  /// **'What is your primary objective within this ministry\'s portal?'**
  String get assessMinQ1;

  /// No description provided for @assessMinQ1Opt1.
  ///
  /// In en, this message translates to:
  /// **'Applying for business subsidy / credit'**
  String get assessMinQ1Opt1;

  /// No description provided for @assessMinQ1Opt2.
  ///
  /// In en, this message translates to:
  /// **'Seeking educational scholarships'**
  String get assessMinQ1Opt2;

  /// No description provided for @assessMinQ1Opt3.
  ///
  /// In en, this message translates to:
  /// **'Seeking farmer agricultural aid'**
  String get assessMinQ1Opt3;

  /// No description provided for @assessMinQ1Opt4.
  ///
  /// In en, this message translates to:
  /// **'Seeking rural infrastructure / SHG help'**
  String get assessMinQ1Opt4;

  /// No description provided for @assessMinQ2.
  ///
  /// In en, this message translates to:
  /// **'What is the applicant\'s current age?'**
  String get assessMinQ2;

  /// No description provided for @assessMinQ2Opt1.
  ///
  /// In en, this message translates to:
  /// **'18 - 35 Years'**
  String get assessMinQ2Opt1;

  /// No description provided for @assessMinQ2Opt2.
  ///
  /// In en, this message translates to:
  /// **'36 - 59 Years'**
  String get assessMinQ2Opt2;

  /// No description provided for @assessMinQ2Opt3.
  ///
  /// In en, this message translates to:
  /// **'60 Years and above'**
  String get assessMinQ2Opt3;

  /// No description provided for @assessMinQ3.
  ///
  /// In en, this message translates to:
  /// **'Do you have any registered ID linked to this ministry?'**
  String get assessMinQ3;

  /// No description provided for @assessMinQ3Opt1.
  ///
  /// In en, this message translates to:
  /// **'Yes, Udyam / PM-KISAN / Scholar ID'**
  String get assessMinQ3Opt1;

  /// No description provided for @assessMinQ3Opt2.
  ///
  /// In en, this message translates to:
  /// **'No, not registered yet'**
  String get assessMinQ3Opt2;

  /// No description provided for @assessMinQ4.
  ///
  /// In en, this message translates to:
  /// **'What is your social category?'**
  String get assessMinQ4;

  /// No description provided for @assessMinQ4Opt1.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get assessMinQ4Opt1;

  /// No description provided for @assessMinQ4Opt2.
  ///
  /// In en, this message translates to:
  /// **'OBC'**
  String get assessMinQ4Opt2;

  /// No description provided for @assessMinQ4Opt3.
  ///
  /// In en, this message translates to:
  /// **'SC / ST'**
  String get assessMinQ4Opt3;

  /// No description provided for @assessMinQ4Opt4.
  ///
  /// In en, this message translates to:
  /// **'Minority / PwD'**
  String get assessMinQ4Opt4;

  /// No description provided for @assessMinQ5.
  ///
  /// In en, this message translates to:
  /// **'What is your annual household income?'**
  String get assessMinQ5;

  /// No description provided for @assessMinQ5Opt1.
  ///
  /// In en, this message translates to:
  /// **'Under ₹2.5 Lakhs'**
  String get assessMinQ5Opt1;

  /// No description provided for @assessMinQ5Opt2.
  ///
  /// In en, this message translates to:
  /// **'₹2.5 Lakhs - ₹8 Lakhs'**
  String get assessMinQ5Opt2;

  /// No description provided for @assessMinQ5Opt3.
  ///
  /// In en, this message translates to:
  /// **'Over ₹8 Lakhs'**
  String get assessMinQ5Opt3;

  /// No description provided for @assessStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {currentStep} of {totalSteps}'**
  String assessStepLabel(Object currentStep, Object totalSteps);

  /// No description provided for @assessSkipToResults.
  ///
  /// In en, this message translates to:
  /// **'Skip to Results'**
  String get assessSkipToResults;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon,'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening,'**
  String get goodEvening;

  /// No description provided for @splashPreparingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Please wait while we prepare\nsomething amazing for you'**
  String get splashPreparingSubtitle;

  /// No description provided for @splashNoInternetTitle.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get splashNoInternetTitle;

  /// No description provided for @splashNoInternetBody.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to sign in or restore this app.'**
  String get splashNoInternetBody;

  /// No description provided for @openSaarthiAiChat.
  ///
  /// In en, this message translates to:
  /// **'Open Saarthi AI chat'**
  String get openSaarthiAiChat;

  /// No description provided for @sortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortLabel;

  /// No description provided for @searchDiscoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find and explore all eligible government schemes'**
  String get searchDiscoverSubtitle;

  /// No description provided for @searchCompleteProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to see personalised matches'**
  String get searchCompleteProfileTitle;

  /// No description provided for @searchCompleteProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add your date of birth, gender and state so \"For Me\" can match schemes to you.'**
  String get searchCompleteProfileSubtitle;

  /// No description provided for @searchNoProfileMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No schemes match your profile yet'**
  String get searchNoProfileMatchesTitle;

  /// No description provided for @searchNoProfileMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting the filters, or update your profile details.'**
  String get searchNoProfileMatchesSubtitle;

  /// No description provided for @schemeNotApplicable.
  ///
  /// In en, this message translates to:
  /// **'Not applicable to you'**
  String get schemeNotApplicable;

  /// No description provided for @searchNoFilterMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No schemes found matching your filters'**
  String get searchNoFilterMatchesTitle;

  /// No description provided for @searchNoFilterMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting or clearing your filters to see more results.'**
  String get searchNoFilterMatchesSubtitle;

  /// No description provided for @eligibleSchemesForYouCount.
  ///
  /// In en, this message translates to:
  /// **'Eligible Schemes For You ({count})'**
  String eligibleSchemesForYouCount(Object count);

  /// No description provided for @matchingSchemesCount.
  ///
  /// In en, this message translates to:
  /// **'Matching Schemes ({count})'**
  String matchingSchemesCount(Object count);

  /// No description provided for @matchedStrictlyAgainstProfile.
  ///
  /// In en, this message translates to:
  /// **'Matched strictly against your profile data'**
  String get matchedStrictlyAgainstProfile;

  /// No description provided for @schemesAvailableCount.
  ///
  /// In en, this message translates to:
  /// **'{count} schemes available'**
  String schemesAvailableCount(Object count);

  /// No description provided for @resultsCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Results copied to clipboard'**
  String get resultsCopiedToClipboard;

  /// No description provided for @clearFiltersAndExplore.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters & Explore Schemes'**
  String get clearFiltersAndExplore;

  /// No description provided for @removeSaved.
  ///
  /// In en, this message translates to:
  /// **'Remove Saved'**
  String get removeSaved;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @eligibilityResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Eligibility Results'**
  String get eligibilityResultsTitle;

  /// No description provided for @eligibilityResultsCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Eligibility results copied to clipboard'**
  String get eligibilityResultsCopiedToClipboard;

  /// No description provided for @faqEligibilityQ.
  ///
  /// In en, this message translates to:
  /// **'How do I check my eligibility for a scheme?'**
  String get faqEligibilityQ;

  /// No description provided for @faqEligibilityA.
  ///
  /// In en, this message translates to:
  /// **'Fill in your profile details (age, gender, state, income, etc.) in the Profile tab, then browse the Search tab, where each scheme shows whether it matches your profile. For a quick check, you can also try the assessment under Discover.'**
  String get faqEligibilityA;

  /// No description provided for @faqApplyQ.
  ///
  /// In en, this message translates to:
  /// **'How can I apply for a scheme?'**
  String get faqApplyQ;

  /// No description provided for @faqApplyA.
  ///
  /// In en, this message translates to:
  /// **'Select any scheme to see its detailed description, benefits, and required documents. Tap the \'Apply Now\' button to open the official government application portal in your browser.'**
  String get faqApplyA;

  /// No description provided for @faqTrackQ.
  ///
  /// In en, this message translates to:
  /// **'Where can I track my application status?'**
  String get faqTrackQ;

  /// No description provided for @faqTrackA.
  ///
  /// In en, this message translates to:
  /// **'Since application submissions are processed directly on official government portals, you can track your status by logging into the respective portal using the application ID provided during submission.'**
  String get faqTrackA;

  /// No description provided for @faqFreeQ.
  ///
  /// In en, this message translates to:
  /// **'Is MSS app free to use?'**
  String get faqFreeQ;

  /// No description provided for @faqFreeA.
  ///
  /// In en, this message translates to:
  /// **'Yes, MSS is completely free to use. Our goal is to make citizen benefits and government schemes accessible to everyone in India without any hidden fees.'**
  String get faqFreeA;

  /// No description provided for @faqDataFreshnessQ.
  ///
  /// In en, this message translates to:
  /// **'How often is new data updated?'**
  String get faqDataFreshnessQ;

  /// No description provided for @faqDataFreshnessA.
  ///
  /// In en, this message translates to:
  /// **'Our database is updated daily to reflect the latest announcements, schemes, subsidies, and application guidelines from the central and state ministries.'**
  String get faqDataFreshnessA;

  /// No description provided for @faqScoringQ.
  ///
  /// In en, this message translates to:
  /// **'How does the recommendation scoring work?'**
  String get faqScoringQ;

  /// No description provided for @faqScoringA.
  ///
  /// In en, this message translates to:
  /// **'We evaluate your profile (residency, age, gender, education, and community) against the criteria set by each scheme. A match score is calculated out of 100% depending on the percentage of conditions met.'**
  String get faqScoringA;

  /// No description provided for @faqDataSharingQ.
  ///
  /// In en, this message translates to:
  /// **'Is my personal data shared with the government?'**
  String get faqDataSharingQ;

  /// No description provided for @faqDataSharingA.
  ///
  /// In en, this message translates to:
  /// **'No. MSS is a recommendation tool that runs fully on your device. We do not share your profile details with external departments. You apply directly on official portals.'**
  String get faqDataSharingA;

  /// No description provided for @faqMissingDocsQ.
  ///
  /// In en, this message translates to:
  /// **'How do I obtain missing documents?'**
  String get faqMissingDocsQ;

  /// No description provided for @faqMissingDocsA.
  ///
  /// In en, this message translates to:
  /// **'In the Scheme Details view, any document marked as \"Missing\" has a \"Get Document\" link that redirects you directly to the official portal (e.g., UIDAI for Aadhaar, NSDL for PAN).'**
  String get faqMissingDocsA;

  /// No description provided for @helpCatGeneralInquiry.
  ///
  /// In en, this message translates to:
  /// **'General Inquiry'**
  String get helpCatGeneralInquiry;

  /// No description provided for @helpFaqAnswerTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ Answer'**
  String get helpFaqAnswerTitle;

  /// No description provided for @helpAllFaqsTitle.
  ///
  /// In en, this message translates to:
  /// **'All FAQs'**
  String get helpAllFaqsTitle;

  /// No description provided for @helpReportIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Report an Issue'**
  String get helpReportIssueTitle;

  /// No description provided for @helpReportIssueBody.
  ///
  /// In en, this message translates to:
  /// **'Facing a problem? Fill out the details below and our team will get back to you shortly.\n\nYour report will be sent directly to mssschemessearch@gmail.com. Please enter your email below so we can reply.'**
  String get helpReportIssueBody;

  /// No description provided for @helpCatMatcherBug.
  ///
  /// In en, this message translates to:
  /// **'Eligibility Matcher Bug'**
  String get helpCatMatcherBug;

  /// No description provided for @helpCatWrongDetails.
  ///
  /// In en, this message translates to:
  /// **'Wrong Scheme Details'**
  String get helpCatWrongDetails;

  /// No description provided for @helpCatFeatureRequest.
  ///
  /// In en, this message translates to:
  /// **'Feature Request'**
  String get helpCatFeatureRequest;

  /// No description provided for @helpTicketSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Thank you! Your ticket has been submitted.'**
  String get helpTicketSubmitted;

  /// No description provided for @helpTicketSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit ticket. Please check your connection and try again.'**
  String get helpTicketSubmitFailed;

  /// No description provided for @helpSubmitTicket.
  ///
  /// In en, this message translates to:
  /// **'Submit Ticket'**
  String get helpSubmitTicket;

  /// No description provided for @helpShareFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Share Feedback'**
  String get helpShareFeedbackTitle;

  /// No description provided for @helpFeedbackBody.
  ///
  /// In en, this message translates to:
  /// **'We value your feedback. Let us know how we can improve your experience!'**
  String get helpFeedbackBody;

  /// No description provided for @helpRateExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate your experience'**
  String get helpRateExperience;

  /// No description provided for @helpRateStars.
  ///
  /// In en, this message translates to:
  /// **'Rate {count} stars'**
  String helpRateStars(Object count);

  /// No description provided for @helpFeedbackEmailHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. yourname@gmail.com for follow-up from mssschemessearch@gmail.com'**
  String get helpFeedbackEmailHint;

  /// No description provided for @helpFeedbackThanks.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your valuable feedback!'**
  String get helpFeedbackThanks;

  /// No description provided for @helpFeedbackSubmitFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit feedback. Please check your connection.'**
  String get helpFeedbackSubmitFailed;

  /// No description provided for @helpTicketErrCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select an issue category.'**
  String get helpTicketErrCategory;

  /// No description provided for @helpTicketErrEmailMissing.
  ///
  /// In en, this message translates to:
  /// **'Please enter your contact email address.'**
  String get helpTicketErrEmailMissing;

  /// No description provided for @helpTicketErrEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address (e.g. name@example.com).'**
  String get helpTicketErrEmailInvalid;

  /// No description provided for @helpTicketErrDescriptionMissing.
  ///
  /// In en, this message translates to:
  /// **'Please describe your issue or feedback.'**
  String get helpTicketErrDescriptionMissing;

  /// No description provided for @helpTicketErrDescriptionShort.
  ///
  /// In en, this message translates to:
  /// **'Please add a bit more detail (at least {count} characters).'**
  String helpTicketErrDescriptionShort(int count);

  /// No description provided for @helpTicketErrWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait {seconds} seconds before submitting again.'**
  String helpTicketErrWait(int seconds);

  /// No description provided for @helpTicketErrTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many submissions. Please try again later.'**
  String get helpTicketErrTooMany;

  /// No description provided for @helpSubmitFeedback.
  ///
  /// In en, this message translates to:
  /// **'Submit Feedback'**
  String get helpSubmitFeedback;

  /// No description provided for @helpHeaderContact.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get helpHeaderContact;

  /// No description provided for @helpHeaderSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get helpHeaderSupport;

  /// No description provided for @helpHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'re here to help you'**
  String get helpHeaderSubtitle;

  /// No description provided for @helpFaqsGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'FAQs'**
  String get helpFaqsGroupTitle;

  /// No description provided for @helpFaqsGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find answers to common questions'**
  String get helpFaqsGroupSubtitle;

  /// No description provided for @helpViewAllFaqs.
  ///
  /// In en, this message translates to:
  /// **'View all FAQs'**
  String get helpViewAllFaqs;

  /// No description provided for @helpContactGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get helpContactGroupTitle;

  /// No description provided for @helpContactGroupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get in touch with our support team'**
  String get helpContactGroupSubtitle;

  /// No description provided for @helpEmailUs.
  ///
  /// In en, this message translates to:
  /// **'Email Us'**
  String get helpEmailUs;

  /// No description provided for @helpSupportEmailCopied.
  ///
  /// In en, this message translates to:
  /// **'Support email copied to clipboard!'**
  String get helpSupportEmailCopied;

  /// No description provided for @helpReplyWindow.
  ///
  /// In en, this message translates to:
  /// **'We typically reply within 24 hours'**
  String get helpReplyWindow;

  /// No description provided for @helpReportIssueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Facing a problem? Let us know.'**
  String get helpReportIssueSubtitle;

  /// No description provided for @helpFeedbackTileTitle.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get helpFeedbackTileTitle;

  /// No description provided for @helpFeedbackTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share your suggestions to help us improve.'**
  String get helpFeedbackTileSubtitle;

  /// No description provided for @helpStillNeedHelp.
  ///
  /// In en, this message translates to:
  /// **'Still need help?'**
  String get helpStillNeedHelp;

  /// No description provided for @helpStillNeedHelpBody.
  ///
  /// In en, this message translates to:
  /// **'Our support team is always ready to assist you.'**
  String get helpStillNeedHelpBody;

  /// No description provided for @emiCalcTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Loan EMI Calculator'**
  String get emiCalcTitle;

  /// No description provided for @emiCalcSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Calculate monthly payments for your business loan.'**
  String get emiCalcSubtitle;

  /// No description provided for @emiLoanAmount.
  ///
  /// In en, this message translates to:
  /// **'Loan Amount'**
  String get emiLoanAmount;

  /// No description provided for @emiLoanAmountHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter total business loan sum required'**
  String get emiLoanAmountHelper;

  /// No description provided for @emiInterestRate.
  ///
  /// In en, this message translates to:
  /// **'Interest Rate (% p.a.)'**
  String get emiInterestRate;

  /// No description provided for @emiInterestRateHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter annual rate'**
  String get emiInterestRateHelper;

  /// No description provided for @emiTenureMonths.
  ///
  /// In en, this message translates to:
  /// **'Tenure (Months)'**
  String get emiTenureMonths;

  /// No description provided for @emiTenureSuffixMo.
  ///
  /// In en, this message translates to:
  /// **'Mo'**
  String get emiTenureSuffixMo;

  /// No description provided for @emiTenureHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter term in months'**
  String get emiTenureHelper;

  /// No description provided for @emiMonthlyEmi.
  ///
  /// In en, this message translates to:
  /// **'Monthly EMI'**
  String get emiMonthlyEmi;

  /// No description provided for @emiPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Principal Amount'**
  String get emiPrincipal;

  /// No description provided for @emiTotalInterest.
  ///
  /// In en, this message translates to:
  /// **'Total Interest Payable'**
  String get emiTotalInterest;

  /// No description provided for @emiTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount (Principal + Int)'**
  String get emiTotalAmount;

  /// No description provided for @emiInvalidInputs.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid inputs'**
  String get emiInvalidInputs;

  /// No description provided for @emiCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate EMI'**
  String get emiCalculate;

  /// No description provided for @dpiitTitle.
  ///
  /// In en, this message translates to:
  /// **'DPIIT Recognition Checklist'**
  String get dpiitTitle;

  /// No description provided for @dpiitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Evaluate if your business qualifies as a startup under DPIIT rules.'**
  String get dpiitSubtitle;

  /// No description provided for @dpiitCriteriaRegistered.
  ///
  /// In en, this message translates to:
  /// **'Registered as Pvt Ltd / LLP / Partnership'**
  String get dpiitCriteriaRegistered;

  /// No description provided for @dpiitCriteriaRegisteredSub.
  ///
  /// In en, this message translates to:
  /// **'Must be registered in India. Sole proprietorships do not qualify.'**
  String get dpiitCriteriaRegisteredSub;

  /// No description provided for @dpiitCriteriaAge.
  ///
  /// In en, this message translates to:
  /// **'Incorporation age is under 10 years'**
  String get dpiitCriteriaAge;

  /// No description provided for @dpiitCriteriaAgeSub.
  ///
  /// In en, this message translates to:
  /// **'From incorporation date'**
  String get dpiitCriteriaAgeSub;

  /// No description provided for @dpiitCriteriaNotSplit.
  ///
  /// In en, this message translates to:
  /// **'Not formed by splitting up or rebuilding an existing business'**
  String get dpiitCriteriaNotSplit;

  /// No description provided for @dpiitCriteriaNotSplitSub.
  ///
  /// In en, this message translates to:
  /// **'Must be a genuinely new entity'**
  String get dpiitCriteriaNotSplitSub;

  /// No description provided for @dpiitCriteriaTurnover.
  ///
  /// In en, this message translates to:
  /// **'Annual turnover has never exceeded ₹100 Cr'**
  String get dpiitCriteriaTurnover;

  /// No description provided for @dpiitCriteriaTurnoverSub.
  ///
  /// In en, this message translates to:
  /// **'For any financial year'**
  String get dpiitCriteriaTurnoverSub;

  /// No description provided for @dpiitCriteriaInnovation.
  ///
  /// In en, this message translates to:
  /// **'Working towards innovation/scaling'**
  String get dpiitCriteriaInnovation;

  /// No description provided for @dpiitCriteriaInnovationSub.
  ///
  /// In en, this message translates to:
  /// **'Developing new products/processes'**
  String get dpiitCriteriaInnovationSub;

  /// No description provided for @dpiitResultEligible.
  ///
  /// In en, this message translates to:
  /// **'You appear to meet all DPIIT criteria. Apply for recognition on the Startup India portal.'**
  String get dpiitResultEligible;

  /// No description provided for @dpiitResultNotEligible.
  ///
  /// In en, this message translates to:
  /// **'Not eligible yet. A startup must satisfy all 5 criteria.'**
  String get dpiitResultNotEligible;

  /// No description provided for @dpiitResultUnmet.
  ///
  /// In en, this message translates to:
  /// **'Not met: {criteria}'**
  String dpiitResultUnmet(String criteria);

  /// No description provided for @dpiitCheckEligibility.
  ///
  /// In en, this message translates to:
  /// **'Check Eligibility'**
  String get dpiitCheckEligibility;

  /// No description provided for @valuationTitle.
  ///
  /// In en, this message translates to:
  /// **'Startup Valuation Estimator'**
  String get valuationTitle;

  /// No description provided for @valuationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get a ballpark pre-seed/seed valuation range based on MRR.'**
  String get valuationSubtitle;

  /// No description provided for @valuationMrrLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly Recurring Revenue (MRR)'**
  String get valuationMrrLabel;

  /// No description provided for @valuationMrrHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter monthly revenue in Rupees'**
  String get valuationMrrHelper;

  /// No description provided for @valuationMomGrowth.
  ///
  /// In en, this message translates to:
  /// **'MoM Growth (%)'**
  String get valuationMomGrowth;

  /// No description provided for @valuationMomHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter month-on-month rate'**
  String get valuationMomHelper;

  /// No description provided for @valuationSector.
  ///
  /// In en, this message translates to:
  /// **'Business Sector'**
  String get valuationSector;

  /// No description provided for @valuationSectorSaasTech.
  ///
  /// In en, this message translates to:
  /// **'SaaS / Tech'**
  String get valuationSectorSaasTech;

  /// No description provided for @valuationSectorEcommerce.
  ///
  /// In en, this message translates to:
  /// **'E-commerce'**
  String get valuationSectorEcommerce;

  /// No description provided for @valuationSectorFintech.
  ///
  /// In en, this message translates to:
  /// **'Fintech'**
  String get valuationSectorFintech;

  /// No description provided for @valuationSectorAgritech.
  ///
  /// In en, this message translates to:
  /// **'AgriTech'**
  String get valuationSectorAgritech;

  /// No description provided for @valuationRange.
  ///
  /// In en, this message translates to:
  /// **'Valuation Range'**
  String get valuationRange;

  /// No description provided for @valuationCalculatedArr.
  ///
  /// In en, this message translates to:
  /// **'Calculated ARR'**
  String get valuationCalculatedArr;

  /// No description provided for @valuationAppliedMultiple.
  ///
  /// In en, this message translates to:
  /// **'Applied ARR Multiple'**
  String get valuationAppliedMultiple;

  /// No description provided for @valuationInvalidMrr.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid MRR'**
  String get valuationInvalidMrr;

  /// No description provided for @valuationEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimate Valuation'**
  String get valuationEstimate;

  /// No description provided for @valuationCroreFmt.
  ///
  /// In en, this message translates to:
  /// **'₹ {value} Crores'**
  String valuationCroreFmt(Object value);

  /// No description provided for @valuationLakhFmt.
  ///
  /// In en, this message translates to:
  /// **'₹ {value} Lakhs'**
  String valuationLakhFmt(Object value);

  /// No description provided for @docChecklistTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup Document Checklist'**
  String get docChecklistTitle;

  /// No description provided for @docChecklistSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Checklist of documents needed to set up your business.'**
  String get docChecklistSubtitle;

  /// No description provided for @docEntityType.
  ///
  /// In en, this message translates to:
  /// **'Business Entity Type'**
  String get docEntityType;

  /// No description provided for @docRequiredDocuments.
  ///
  /// In en, this message translates to:
  /// **'Required Documents'**
  String get docRequiredDocuments;

  /// No description provided for @docCloseChecklist.
  ///
  /// In en, this message translates to:
  /// **'Close Checklist'**
  String get docCloseChecklist;

  /// No description provided for @docEntityPrivateLimited.
  ///
  /// In en, this message translates to:
  /// **'Private Limited'**
  String get docEntityPrivateLimited;

  /// No description provided for @docEntitySoleProprietorship.
  ///
  /// In en, this message translates to:
  /// **'Sole Proprietorship'**
  String get docEntitySoleProprietorship;

  /// No description provided for @docItemProprietorPanAadhaar.
  ///
  /// In en, this message translates to:
  /// **'Owner\'s PAN card and Aadhaar'**
  String get docItemProprietorPanAadhaar;

  /// No description provided for @docItemUdyamRegistration.
  ///
  /// In en, this message translates to:
  /// **'Udyam registration certificate (free, udyamregistration.gov.in)'**
  String get docItemUdyamRegistration;

  /// No description provided for @docItemShopEstablishmentLicence.
  ///
  /// In en, this message translates to:
  /// **'Shop & Establishment licence from your state / local body'**
  String get docItemShopEstablishmentLicence;

  /// No description provided for @docItemProprietorBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Current bank account in the business name'**
  String get docItemProprietorBankAccount;

  /// No description provided for @docEntityPartnership.
  ///
  /// In en, this message translates to:
  /// **'Partnership'**
  String get docEntityPartnership;

  /// No description provided for @docEntityOpc.
  ///
  /// In en, this message translates to:
  /// **'One Person Company (OPC)'**
  String get docEntityOpc;

  /// No description provided for @docEntityLlp.
  ///
  /// In en, this message translates to:
  /// **'LLP'**
  String get docEntityLlp;

  /// No description provided for @docItemDsc.
  ///
  /// In en, this message translates to:
  /// **'Digital Signature Certificate (DSC)'**
  String get docItemDsc;

  /// No description provided for @docItemDin.
  ///
  /// In en, this message translates to:
  /// **'Director Identification Number (DIN)'**
  String get docItemDin;

  /// No description provided for @docItemMoaAoa.
  ///
  /// In en, this message translates to:
  /// **'MOA & AOA Drafting'**
  String get docItemMoaAoa;

  /// No description provided for @docItemCoi.
  ///
  /// In en, this message translates to:
  /// **'Certificate of Incorporation (COI)'**
  String get docItemCoi;

  /// No description provided for @docItemCompanyPanTan.
  ///
  /// In en, this message translates to:
  /// **'Company PAN & TAN Cards'**
  String get docItemCompanyPanTan;

  /// No description provided for @docItemCorporateBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Corporate Bank Account'**
  String get docItemCorporateBankAccount;

  /// No description provided for @docItemPartnershipDeed.
  ///
  /// In en, this message translates to:
  /// **'Partnership Deed drafting'**
  String get docItemPartnershipDeed;

  /// No description provided for @docItemDeedRegistration.
  ///
  /// In en, this message translates to:
  /// **'Deed Registration with Registrar'**
  String get docItemDeedRegistration;

  /// No description provided for @docItemFirmPanTan.
  ///
  /// In en, this message translates to:
  /// **'PAN & TAN cards of Firm'**
  String get docItemFirmPanTan;

  /// No description provided for @docItemFirmBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Firm Bank Account'**
  String get docItemFirmBankAccount;

  /// No description provided for @docItemGstRegistrationOptional.
  ///
  /// In en, this message translates to:
  /// **'GST Registration (Optional)'**
  String get docItemGstRegistrationOptional;

  /// No description provided for @docItemLlpNameApproval.
  ///
  /// In en, this message translates to:
  /// **'LLP Name Approval (RUN-LLP)'**
  String get docItemLlpNameApproval;

  /// No description provided for @docItemFillipForm.
  ///
  /// In en, this message translates to:
  /// **'FiLLiP Form (LLP Incorporation)'**
  String get docItemFillipForm;

  /// No description provided for @docItemLlpAgreement.
  ///
  /// In en, this message translates to:
  /// **'LLP Agreement Drafting'**
  String get docItemLlpAgreement;

  /// No description provided for @docItemLlpPanTan.
  ///
  /// In en, this message translates to:
  /// **'LLP PAN & TAN Cards'**
  String get docItemLlpPanTan;

  /// No description provided for @docItemLlpBankAccount.
  ///
  /// In en, this message translates to:
  /// **'LLP Bank Account'**
  String get docItemLlpBankAccount;

  /// No description provided for @subsidyTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Subsidy Estimator'**
  String get subsidyTitle;

  /// No description provided for @subsidySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Estimate capital subsidies and net loan commitments for machinery.'**
  String get subsidySubtitle;

  /// No description provided for @subsidyProjectCost.
  ///
  /// In en, this message translates to:
  /// **'Project / Machinery Cost (Lakhs)'**
  String get subsidyProjectCost;

  /// No description provided for @subsidyProjectCostSuffix.
  ///
  /// In en, this message translates to:
  /// **'Lakhs'**
  String get subsidyProjectCostSuffix;

  /// No description provided for @subsidyProjectCostHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter machinery or project cost in Lakhs'**
  String get subsidyProjectCostHelper;

  /// No description provided for @subsidyPercentLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected Subsidy Percentage (%)'**
  String get subsidyPercentLabel;

  /// No description provided for @subsidyPercentHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter expected subsidy rate percentage'**
  String get subsidyPercentHelper;

  /// No description provided for @subsidyOriginalCost.
  ///
  /// In en, this message translates to:
  /// **'Original Project Cost'**
  String get subsidyOriginalCost;

  /// No description provided for @subsidyExpectedLabel.
  ///
  /// In en, this message translates to:
  /// **'Expected Subsidy ({percent}%)'**
  String subsidyExpectedLabel(Object percent);

  /// No description provided for @subsidyNetCost.
  ///
  /// In en, this message translates to:
  /// **'Net Cost to Business'**
  String get subsidyNetCost;

  /// No description provided for @subsidyInvalidValues.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid values (Subsidy % must be between 0 and 100)'**
  String get subsidyInvalidValues;

  /// No description provided for @subsidyCalculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate Subsidy'**
  String get subsidyCalculate;

  /// No description provided for @subsidyLakhFmt.
  ///
  /// In en, this message translates to:
  /// **'₹ {value} Lakhs'**
  String subsidyLakhFmt(Object value);

  /// No description provided for @msmeRatePerAnnum.
  ///
  /// In en, this message translates to:
  /// **'{rate}% p.a.'**
  String msmeRatePerAnnum(Object rate);

  /// No description provided for @msmeUdyamFlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Udyam Registration Flow'**
  String get msmeUdyamFlowTitle;

  /// No description provided for @msmeUdyamGoToPortal.
  ///
  /// In en, this message translates to:
  /// **'Go to Official Udyam Portal'**
  String get msmeUdyamGoToPortal;

  /// No description provided for @msmeUdyamStep1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Aadhaar & PAN Validation'**
  String get msmeUdyamStep1Title;

  /// No description provided for @msmeUdyamStep1Desc.
  ///
  /// In en, this message translates to:
  /// **'Enter entrepreneur Aadhaar Number & Name as per Aadhaar. Validate via OTP. Next, enter Organization Type & PAN details for automatic GSTIN verification.'**
  String get msmeUdyamStep1Desc;

  /// No description provided for @msmeUdyamStep1Action.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar OTP authentication & PAN details entry.'**
  String get msmeUdyamStep1Action;

  /// No description provided for @msmeUdyamStep2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Enterprise & Location Details'**
  String get msmeUdyamStep2Title;

  /// No description provided for @msmeUdyamStep2Desc.
  ///
  /// In en, this message translates to:
  /// **'Provide Enterprise Name, Plant/Unit Addresses, Official Email, Mobile Number, Bank Account Number, and IFSC Code.'**
  String get msmeUdyamStep2Desc;

  /// No description provided for @msmeUdyamStep2Action.
  ///
  /// In en, this message translates to:
  /// **'Fill unit addresses, mobile, email & bank details.'**
  String get msmeUdyamStep2Action;

  /// No description provided for @msmeUdyamStep3Title.
  ///
  /// In en, this message translates to:
  /// **'3. NIC Code & Investment Details'**
  String get msmeUdyamStep3Title;

  /// No description provided for @msmeUdyamStep3Desc.
  ///
  /// In en, this message translates to:
  /// **'Select Major Activity (Manufacturing / Service), search & select 2/4/5-digit NIC Codes, enter number of employees, and investment in Plant & Machinery.'**
  String get msmeUdyamStep3Desc;

  /// No description provided for @msmeUdyamStep3Action.
  ///
  /// In en, this message translates to:
  /// **'Select NIC classification code & enter investment/turnover.'**
  String get msmeUdyamStep3Action;

  /// No description provided for @msmeUdyamStep4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Final Submit & e-Certificate'**
  String get msmeUdyamStep4Title;

  /// No description provided for @msmeUdyamStep4Desc.
  ///
  /// In en, this message translates to:
  /// **'Review summary, submit final OTP. A unique 16-digit Udyam Registration Number (URN) and e-Certificate with QR code are issued instantly with zero registration fee.'**
  String get msmeUdyamStep4Desc;

  /// No description provided for @msmeUdyamStep4Action.
  ///
  /// In en, this message translates to:
  /// **'Final OTP submission; download instant e-Certificate.'**
  String get msmeUdyamStep4Action;

  /// No description provided for @voiceRelevanceMatch.
  ///
  /// In en, this message translates to:
  /// **'{confidence}% relevance match'**
  String voiceRelevanceMatch(Object confidence);

  /// No description provided for @voiceEditFact.
  ///
  /// In en, this message translates to:
  /// **'Edit {label}'**
  String voiceEditFact(Object label);

  /// No description provided for @voiceNoiseControlSecure.
  ///
  /// In en, this message translates to:
  /// **'Device noise control • Secure live voice'**
  String get voiceNoiseControlSecure;

  /// No description provided for @voiceSeeUncertainSchemes.
  ///
  /// In en, this message translates to:
  /// **'See {count} uncertain or historical schemes'**
  String voiceSeeUncertainSchemes(Object count);

  /// No description provided for @voiceAiReady.
  ///
  /// In en, this message translates to:
  /// **'AI voice ready'**
  String get voiceAiReady;

  /// No description provided for @voiceConversationTranscript.
  ///
  /// In en, this message translates to:
  /// **'Conversation transcript'**
  String get voiceConversationTranscript;

  /// No description provided for @voiceFoundCount.
  ///
  /// In en, this message translates to:
  /// **'{count} found'**
  String voiceFoundCount(Object count);

  /// No description provided for @voiceShowTop3.
  ///
  /// In en, this message translates to:
  /// **'Show top 3'**
  String get voiceShowTop3;

  /// No description provided for @voiceShowAllMatches.
  ///
  /// In en, this message translates to:
  /// **'Show all {count} matches'**
  String voiceShowAllMatches(Object count);

  /// No description provided for @voiceReviewDetails.
  ///
  /// In en, this message translates to:
  /// **'Review details'**
  String get voiceReviewDetails;

  /// No description provided for @voiceConfirmEligibility.
  ///
  /// In en, this message translates to:
  /// **'Confirm current eligibility before applying'**
  String get voiceConfirmEligibility;

  /// No description provided for @voiceTapToInterrupt.
  ///
  /// In en, this message translates to:
  /// **'Tap to interrupt'**
  String get voiceTapToInterrupt;

  /// No description provided for @voiceSemInterrupt.
  ///
  /// In en, this message translates to:
  /// **'Interrupt assistant'**
  String get voiceSemInterrupt;

  /// No description provided for @voiceSemMicHint.
  ///
  /// In en, this message translates to:
  /// **'Double tap to control the microphone'**
  String get voiceSemMicHint;

  /// No description provided for @voiceAiAssistant.
  ///
  /// In en, this message translates to:
  /// **'AI assistant'**
  String get voiceAiAssistant;

  /// No description provided for @voiceSemNoiseControlOn.
  ///
  /// In en, this message translates to:
  /// **'Device echo and noise control is on'**
  String get voiceSemNoiseControlOn;

  /// No description provided for @voiceTapWhenFinished.
  ///
  /// In en, this message translates to:
  /// **'Tap when finished'**
  String get voiceTapWhenFinished;

  /// No description provided for @voiceTypeInstead.
  ///
  /// In en, this message translates to:
  /// **'Type instead...'**
  String get voiceTypeInstead;

  /// No description provided for @voiceFactCrore.
  ///
  /// In en, this message translates to:
  /// **'₹{value} crore'**
  String voiceFactCrore(Object value);

  /// No description provided for @voiceFactLakh.
  ///
  /// In en, this message translates to:
  /// **'₹{value} lakh'**
  String voiceFactLakh(Object value);

  /// No description provided for @saarthiGreetingFriend.
  ///
  /// In en, this message translates to:
  /// **'there'**
  String get saarthiGreetingFriend;

  /// No description provided for @saarthiVoiceServiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice service is unavailable. Tap retry.'**
  String get saarthiVoiceServiceUnavailable;

  /// No description provided for @saarthiVoiceFallbackOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Cloud voice isn\'t available right now. Saarthi is listening on your phone instead.'**
  String get saarthiVoiceFallbackOnDevice;

  /// No description provided for @saarthiCloudErrorSignIn.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again, then retry voice.'**
  String get saarthiCloudErrorSignIn;

  /// No description provided for @saarthiCloudErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Check your internet, then retry voice.'**
  String get saarthiCloudErrorNetwork;

  /// No description provided for @saarthiCloudErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Voice service could not connect. Tap retry.'**
  String get saarthiCloudErrorGeneric;

  /// No description provided for @saarthiGenericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get saarthiGenericError;

  /// No description provided for @saarthiStatusConnectionAttention.
  ///
  /// In en, this message translates to:
  /// **'Connection needs attention'**
  String get saarthiStatusConnectionAttention;

  /// No description provided for @saarthiVoiceControlLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} voice control'**
  String saarthiVoiceControlLabel(Object label);

  /// No description provided for @saarthiQAge.
  ///
  /// In en, this message translates to:
  /// **'What is your age?'**
  String get saarthiQAge;

  /// No description provided for @saarthiQState.
  ///
  /// In en, this message translates to:
  /// **'Which state are you in?'**
  String get saarthiQState;

  /// No description provided for @saarthiQDistrict.
  ///
  /// In en, this message translates to:
  /// **'Which district are you in?'**
  String get saarthiQDistrict;

  /// No description provided for @saarthiQIncome.
  ///
  /// In en, this message translates to:
  /// **'Roughly what is your family\'s annual income?'**
  String get saarthiQIncome;

  /// No description provided for @saarthiQGender.
  ///
  /// In en, this message translates to:
  /// **'What is your gender?'**
  String get saarthiQGender;

  /// No description provided for @saarthiQCommunity.
  ///
  /// In en, this message translates to:
  /// **'Which community category do you belong to?'**
  String get saarthiQCommunity;

  /// No description provided for @saarthiQOccupation.
  ///
  /// In en, this message translates to:
  /// **'What do you do for a living right now?'**
  String get saarthiQOccupation;

  /// No description provided for @saarthiQEducation.
  ///
  /// In en, this message translates to:
  /// **'What is your education level?'**
  String get saarthiQEducation;

  /// No description provided for @saarthiQDisability.
  ///
  /// In en, this message translates to:
  /// **'Does any disability category apply to you?'**
  String get saarthiQDisability;

  /// No description provided for @saarthiQMaritalStatus.
  ///
  /// In en, this message translates to:
  /// **'What is your marital status?'**
  String get saarthiQMaritalStatus;

  /// No description provided for @saarthiQIsStudent.
  ///
  /// In en, this message translates to:
  /// **'Are you currently a student?'**
  String get saarthiQIsStudent;

  /// No description provided for @saarthiQBusinessStage.
  ///
  /// In en, this message translates to:
  /// **'Is this an idea, a new business, or an existing business?'**
  String get saarthiQBusinessStage;

  /// No description provided for @saarthiQBusinessSector.
  ///
  /// In en, this message translates to:
  /// **'Which business sector is it?'**
  String get saarthiQBusinessSector;

  /// No description provided for @saarthiQFundingNeed.
  ///
  /// In en, this message translates to:
  /// **'Roughly how much funding do you need?'**
  String get saarthiQFundingNeed;

  /// No description provided for @saarthiQLandholding.
  ///
  /// In en, this message translates to:
  /// **'How much land do you hold?'**
  String get saarthiQLandholding;

  /// No description provided for @profileHintSelectDob.
  ///
  /// In en, this message translates to:
  /// **'SELECT DATE OF BIRTH'**
  String get profileHintSelectDob;

  /// No description provided for @profileErrEnterPhone.
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get profileErrEnterPhone;

  /// No description provided for @profileErrPhone10Digits.
  ///
  /// In en, this message translates to:
  /// **'Enter a 10-digit mobile number'**
  String get profileErrPhone10Digits;

  /// No description provided for @profileErrPincode6Digits.
  ///
  /// In en, this message translates to:
  /// **'Enter 6 digits'**
  String get profileErrPincode6Digits;

  /// No description provided for @profileErrLocationFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch location. Please enter manually.'**
  String get profileErrLocationFetchFailed;

  /// No description provided for @profileErrCompleteFieldsCorrectly.
  ///
  /// In en, this message translates to:
  /// **'Please complete all required fields correctly.'**
  String get profileErrCompleteFieldsCorrectly;

  /// No description provided for @profileErrLocationFieldsCorrectly.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required location fields correctly.'**
  String get profileErrLocationFieldsCorrectly;

  /// No description provided for @profileErrCompleteFieldsToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please complete all required fields to continue.'**
  String get profileErrCompleteFieldsToContinue;

  /// No description provided for @profileErrUnableToSave.
  ///
  /// In en, this message translates to:
  /// **'Unable to save profile. Please check connection and try again.'**
  String get profileErrUnableToSave;

  /// No description provided for @profileErrEnterFullName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get profileErrEnterFullName;

  /// No description provided for @profileErrValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get profileErrValidEmail;

  /// No description provided for @profileHint10DigitMobile.
  ///
  /// In en, this message translates to:
  /// **'10-digit mobile number'**
  String get profileHint10DigitMobile;

  /// No description provided for @profileErrSelectGender.
  ///
  /// In en, this message translates to:
  /// **'Please select your gender'**
  String get profileErrSelectGender;

  /// No description provided for @profileErrSelectDob.
  ///
  /// In en, this message translates to:
  /// **'Please select your date of birth'**
  String get profileErrSelectDob;

  /// No description provided for @profileHintDdmmyyyy.
  ///
  /// In en, this message translates to:
  /// **'DD/MM/YYYY'**
  String get profileHintDdmmyyyy;

  /// No description provided for @profileHintDoorStreetExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Flat 402, Royal Enclave'**
  String get profileHintDoorStreetExample;

  /// No description provided for @profileErrEnterHouseStreet.
  ///
  /// In en, this message translates to:
  /// **'Please enter your house/street address'**
  String get profileErrEnterHouseStreet;

  /// No description provided for @profileHintAreaExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Anna Nagar West'**
  String get profileHintAreaExample;

  /// No description provided for @profileErrEnterArea.
  ///
  /// In en, this message translates to:
  /// **'Please enter your area or locality'**
  String get profileErrEnterArea;

  /// No description provided for @profileHintCityExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Chennai'**
  String get profileHintCityExample;

  /// No description provided for @profileErrValidCity.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid city or district'**
  String get profileErrValidCity;

  /// No description provided for @profileHintStateExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Tamil Nadu'**
  String get profileHintStateExample;

  /// No description provided for @profileErrValidState.
  ///
  /// In en, this message translates to:
  /// **'Please select your state'**
  String get profileErrValidState;

  /// No description provided for @profileSelectState.
  ///
  /// In en, this message translates to:
  /// **'Select your state'**
  String get profileSelectState;

  /// No description provided for @profileSearchStateHint.
  ///
  /// In en, this message translates to:
  /// **'Search state or union territory'**
  String get profileSearchStateHint;

  /// No description provided for @profileNoStateMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching state'**
  String get profileNoStateMatch;

  /// No description provided for @profileSelectDistrict.
  ///
  /// In en, this message translates to:
  /// **'Select your district'**
  String get profileSelectDistrict;

  /// No description provided for @profileSelectStateFirst.
  ///
  /// In en, this message translates to:
  /// **'Select your state first'**
  String get profileSelectStateFirst;

  /// No description provided for @profileSearchDistrictHint.
  ///
  /// In en, this message translates to:
  /// **'Search district'**
  String get profileSearchDistrictHint;

  /// No description provided for @profileNoDistrictMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching district'**
  String get profileNoDistrictMatch;

  /// No description provided for @profileErrValidDistrict.
  ///
  /// In en, this message translates to:
  /// **'Please select your district'**
  String get profileErrValidDistrict;

  /// No description provided for @profileErrSelectOptionToContinue.
  ///
  /// In en, this message translates to:
  /// **'Please select an option to continue.'**
  String get profileErrSelectOptionToContinue;

  /// No description provided for @profileErrSelectEducation.
  ///
  /// In en, this message translates to:
  /// **'Please select your education level'**
  String get profileErrSelectEducation;

  /// No description provided for @profileErrSelectCommunity.
  ///
  /// In en, this message translates to:
  /// **'Please select your community category'**
  String get profileErrSelectCommunity;

  /// No description provided for @profileErrSelectIncome.
  ///
  /// In en, this message translates to:
  /// **'Please select your annual income range'**
  String get profileErrSelectIncome;

  /// No description provided for @settingsNavModeDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred layout mode for navigating schemes and services.'**
  String get settingsNavModeDialogBody;

  /// No description provided for @settingsSwitchedToCompanion.
  ///
  /// In en, this message translates to:
  /// **'Switched to AI Companion (Saarthi) Navigation'**
  String get settingsSwitchedToCompanion;

  /// No description provided for @settingsSwitchedToRegular.
  ///
  /// In en, this message translates to:
  /// **'Switched to Regular Navigation'**
  String get settingsSwitchedToRegular;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version {version}'**
  String settingsAppVersion(Object version);

  /// No description provided for @betaGateEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter the beta password.'**
  String get betaGateEnterPassword;

  /// No description provided for @betaGateInvalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Invalid beta password. Please try again.'**
  String get betaGateInvalidPassword;

  /// No description provided for @betaGateVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify password. Check your network.'**
  String get betaGateVerifyFailed;

  /// No description provided for @betaGateAuthorizedTestersOnly.
  ///
  /// In en, this message translates to:
  /// **'Authorized Beta Testers Only'**
  String get betaGateAuthorizedTestersOnly;

  /// No description provided for @betaGateAccess.
  ///
  /// In en, this message translates to:
  /// **'Beta Access'**
  String get betaGateAccess;

  /// No description provided for @betaGateEnterPasswordToContinue.
  ///
  /// In en, this message translates to:
  /// **'Enter the beta tester password to continue.'**
  String get betaGateEnterPasswordToContinue;

  /// No description provided for @betaGatePasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get betaGatePasswordHint;

  /// No description provided for @betaGateVerifyAndEnter.
  ///
  /// In en, this message translates to:
  /// **'Verify & Enter'**
  String get betaGateVerifyAndEnter;

  /// No description provided for @loginGoogleSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to complete Google sign in. Please try again.'**
  String get loginGoogleSignInFailed;

  /// No description provided for @dialogConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get dialogConfirm;

  /// No description provided for @monthAbbrList.
  ///
  /// In en, this message translates to:
  /// **'Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec'**
  String get monthAbbrList;

  /// No description provided for @discoverEveryScheme.
  ///
  /// In en, this message translates to:
  /// **'Discover every Government Scheme in India'**
  String get discoverEveryScheme;

  /// No description provided for @shareResultsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share results'**
  String get shareResultsTooltip;

  /// No description provided for @clearSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearchTooltip;

  /// No description provided for @voiceSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Voice search'**
  String get voiceSearchTooltip;

  /// No description provided for @stopVoiceSearchTooltip.
  ///
  /// In en, this message translates to:
  /// **'Stop voice search'**
  String get stopVoiceSearchTooltip;

  /// No description provided for @voiceAssistantLabel.
  ///
  /// In en, this message translates to:
  /// **'Voice assistant'**
  String get voiceAssistantLabel;

  /// No description provided for @eligResGreatNews.
  ///
  /// In en, this message translates to:
  /// **'Great News! 🎉'**
  String get eligResGreatNews;

  /// No description provided for @eligResEligibleForPrefix.
  ///
  /// In en, this message translates to:
  /// **'You are eligible for\n'**
  String get eligResEligibleForPrefix;

  /// No description provided for @eligResGovernmentSchemesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Government Schemes'**
  String eligResGovernmentSchemesCount(Object count);

  /// No description provided for @eligResBasedOnInfo.
  ///
  /// In en, this message translates to:
  /// **'based on the information you provided'**
  String get eligResBasedOnInfo;

  /// No description provided for @eligResRecommendedSchemes.
  ///
  /// In en, this message translates to:
  /// **'Recommended Schemes'**
  String get eligResRecommendedSchemes;

  /// No description provided for @eligResNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching schemes found. Adjust your profile details to expand matching rules.'**
  String get eligResNoMatches;

  /// No description provided for @eligResSortedInfo.
  ///
  /// In en, this message translates to:
  /// **'These schemes are sorted based on your profile match and eligibility criteria.'**
  String get eligResSortedInfo;

  /// No description provided for @eligResSavedToast.
  ///
  /// In en, this message translates to:
  /// **'Results saved to your eligibility profile!'**
  String get eligResSavedToast;

  /// No description provided for @eligResSaveResults.
  ///
  /// In en, this message translates to:
  /// **'Save Results'**
  String get eligResSaveResults;

  /// No description provided for @eligResSecurePrivate.
  ///
  /// In en, this message translates to:
  /// **'Your information is secure and private'**
  String get eligResSecurePrivate;

  /// No description provided for @eligResShareHeader.
  ///
  /// In en, this message translates to:
  /// **'My Scheme Eligibility Results:'**
  String get eligResShareHeader;

  /// No description provided for @eligResShareItem.
  ///
  /// In en, this message translates to:
  /// **'• {name} ({percent}% Match)'**
  String eligResShareItem(Object name, Object percent);

  /// No description provided for @eligResEligibleSchemesTitle.
  ///
  /// In en, this message translates to:
  /// **'Eligible Schemes'**
  String get eligResEligibleSchemesTitle;

  /// No description provided for @eligResExploreAll.
  ///
  /// In en, this message translates to:
  /// **'Explore All Schemes'**
  String get eligResExploreAll;

  /// No description provided for @eligResSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get eligResSaving;

  /// No description provided for @eligResSavedToProfile.
  ///
  /// In en, this message translates to:
  /// **'Saved to Profile'**
  String get eligResSavedToProfile;

  /// No description provided for @eligResSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save results. Please try again.'**
  String get eligResSaveFailed;

  /// No description provided for @notifCatNewSchemes.
  ///
  /// In en, this message translates to:
  /// **'New Schemes'**
  String get notifCatNewSchemes;

  /// No description provided for @notifCatReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get notifCatReminders;

  /// No description provided for @notifCatUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get notifCatUpdates;

  /// No description provided for @notifCatProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get notifCatProfile;

  /// No description provided for @notifBadgeNew.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get notifBadgeNew;

  /// No description provided for @notifProfileCompletionLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile Completion'**
  String get notifProfileCompletionLabel;

  /// No description provided for @notifCancelSelectionTooltip.
  ///
  /// In en, this message translates to:
  /// **'Cancel selection'**
  String get notifCancelSelectionTooltip;

  /// No description provided for @notifSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Selected'**
  String notifSelectedCount(Object count);

  /// No description provided for @notifMarkAllAsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notifMarkAllAsRead;

  /// No description provided for @notifDeleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get notifDeleteAll;

  /// No description provided for @notifNoMatchingAlerts.
  ///
  /// In en, this message translates to:
  /// **'No matching alerts'**
  String get notifNoMatchingAlerts;

  /// No description provided for @notifTagEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get notifTagEducation;

  /// No description provided for @notifTagSkillDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Skill Development'**
  String get notifTagSkillDevelopment;

  /// No description provided for @timeAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeAgoDays(Object count);

  /// No description provided for @timeAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeAgoHours(Object count);

  /// No description provided for @timeAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeAgoMinutes(Object count);

  /// No description provided for @timeAgoJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeAgoJustNow;

  /// No description provided for @daysLeftFmt.
  ///
  /// In en, this message translates to:
  /// **'{count} days left'**
  String daysLeftFmt(Object count);

  /// No description provided for @notifSeed1Body.
  ///
  /// In en, this message translates to:
  /// **'Government has launched the Fisheries and Aquaculture Infrastructure Development Fund to provide concessionary finance.'**
  String get notifSeed1Body;

  /// No description provided for @notifSeed2Title.
  ///
  /// In en, this message translates to:
  /// **'PM Vidyalaxmi Education Loan Scheme'**
  String get notifSeed2Title;

  /// No description provided for @notifSeed2Body.
  ///
  /// In en, this message translates to:
  /// **'A new scheme for students to provide collateral-free education loans for higher studies.'**
  String get notifSeed2Body;

  /// No description provided for @notifSeed3Title.
  ///
  /// In en, this message translates to:
  /// **'PM Vishwakarma Yojana'**
  String get notifSeed3Title;

  /// No description provided for @notifSeed3Body.
  ///
  /// In en, this message translates to:
  /// **'Financial support for traditional artisans and craftspeople to upgrade their skills and tools.'**
  String get notifSeed3Body;

  /// No description provided for @notifSeed4Title.
  ///
  /// In en, this message translates to:
  /// **'Post Matric Scholarship Scheme'**
  String get notifSeed4Title;

  /// No description provided for @notifSeed4Body.
  ///
  /// In en, this message translates to:
  /// **'Last date to apply is approaching'**
  String get notifSeed4Body;

  /// No description provided for @notifSeed5Title.
  ///
  /// In en, this message translates to:
  /// **'PM Internship Scheme'**
  String get notifSeed5Title;

  /// No description provided for @notifSeed5Body.
  ///
  /// In en, this message translates to:
  /// **'Application window will close soon'**
  String get notifSeed5Body;

  /// No description provided for @notifSeed6Title.
  ///
  /// In en, this message translates to:
  /// **'New Update on Ayushman Bharat Yojana'**
  String get notifSeed6Title;

  /// No description provided for @notifSeed6Body.
  ///
  /// In en, this message translates to:
  /// **'Changes in empanelment process for hospitals. Check full details.'**
  String get notifSeed6Body;

  /// No description provided for @notifSeed7Title.
  ///
  /// In en, this message translates to:
  /// **'Income Limit Revised for Several Schemes'**
  String get notifSeed7Title;

  /// No description provided for @notifSeed7Body.
  ///
  /// In en, this message translates to:
  /// **'Revised income criteria effective from 1st April 2024 for multiple schemes.'**
  String get notifSeed7Body;

  /// No description provided for @notifSeed8Body.
  ///
  /// In en, this message translates to:
  /// **'Add your income details to find schemes you are eligible for.'**
  String get notifSeed8Body;

  /// No description provided for @commonUserFallback.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get commonUserFallback;

  /// No description provided for @searchHintFallback.
  ///
  /// In en, this message translates to:
  /// **'Search PMEGP, Startup India, MSME loans...'**
  String get searchHintFallback;

  /// No description provided for @searchBestMatchesForQuery.
  ///
  /// In en, this message translates to:
  /// **'Best matches for \"{query}\"'**
  String searchBestMatchesForQuery(Object query);

  /// No description provided for @searchBestMatchesForCriteria.
  ///
  /// In en, this message translates to:
  /// **'Best matches for your search criteria'**
  String get searchBestMatchesForCriteria;

  /// No description provided for @searchResultsShareHeader.
  ///
  /// In en, this message translates to:
  /// **'Explore {title} on MSME Scheme Sahayak:'**
  String searchResultsShareHeader(Object title);

  /// No description provided for @savedRemoveFromSavedTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get savedRemoveFromSavedTooltip;

  /// No description provided for @savedRemoveFromRecentTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from recently viewed'**
  String get savedRemoveFromRecentTooltip;

  /// No description provided for @savedInactiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get savedInactiveBadge;

  /// No description provided for @savedInactiveHint.
  ///
  /// In en, this message translates to:
  /// **'This scheme is no longer active in the latest catalog.'**
  String get savedInactiveHint;

  /// No description provided for @savedKeepListUpdated.
  ///
  /// In en, this message translates to:
  /// **'Keep your list updated!'**
  String get savedKeepListUpdated;

  /// No description provided for @savedRemoveNoLongerInterested.
  ///
  /// In en, this message translates to:
  /// **'Remove schemes you\'re no longer interested in.'**
  String get savedRemoveNoLongerInterested;

  /// No description provided for @eduSchool.
  ///
  /// In en, this message translates to:
  /// **'School (10th / 12th)'**
  String get eduSchool;

  /// No description provided for @eduDiploma.
  ///
  /// In en, this message translates to:
  /// **'Diploma / ITI'**
  String get eduDiploma;

  /// No description provided for @eduUndergraduate.
  ///
  /// In en, this message translates to:
  /// **'Undergraduate (Degree)'**
  String get eduUndergraduate;

  /// No description provided for @eduPostgraduate.
  ///
  /// In en, this message translates to:
  /// **'Postgraduate (Master)'**
  String get eduPostgraduate;

  /// No description provided for @eduPhd.
  ///
  /// In en, this message translates to:
  /// **'Ph.D. / Doctorate'**
  String get eduPhd;

  /// No description provided for @commGeneralOc.
  ///
  /// In en, this message translates to:
  /// **'General (OC)'**
  String get commGeneralOc;

  /// No description provided for @commObcBcMbc.
  ///
  /// In en, this message translates to:
  /// **'OBC / BC / MBC'**
  String get commObcBcMbc;

  /// No description provided for @commScCategory.
  ///
  /// In en, this message translates to:
  /// **'SC'**
  String get commScCategory;

  /// No description provided for @commStCategory.
  ///
  /// In en, this message translates to:
  /// **'ST'**
  String get commStCategory;

  /// No description provided for @commEwsCategory.
  ///
  /// In en, this message translates to:
  /// **'EWS'**
  String get commEwsCategory;

  /// No description provided for @commMinority.
  ///
  /// In en, this message translates to:
  /// **'Minority'**
  String get commMinority;

  /// No description provided for @incomeNone.
  ///
  /// In en, this message translates to:
  /// **'No Income'**
  String get incomeNone;

  /// No description provided for @incomeUnder15L.
  ///
  /// In en, this message translates to:
  /// **'Under ₹1.5 Lakhs'**
  String get incomeUnder15L;

  /// No description provided for @income15to3L.
  ///
  /// In en, this message translates to:
  /// **'₹1.5L - ₹3 Lakhs'**
  String get income15to3L;

  /// No description provided for @income3to6L.
  ///
  /// In en, this message translates to:
  /// **'₹3L - ₹6 Lakhs'**
  String get income3to6L;

  /// No description provided for @income6to10L.
  ///
  /// In en, this message translates to:
  /// **'₹6L - ₹10 Lakhs'**
  String get income6to10L;

  /// No description provided for @incomeAbove10L.
  ///
  /// In en, this message translates to:
  /// **'Above ₹10 Lakhs'**
  String get incomeAbove10L;

  /// No description provided for @profilePrivacyNoteDpdpa.
  ///
  /// In en, this message translates to:
  /// **'DPDPA 2023: Used only to match you with welfare schemes. Never shared.'**
  String get profilePrivacyNoteDpdpa;

  /// No description provided for @profileConsentSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data'**
  String get profileConsentSectionTitle;

  /// No description provided for @profileConsentCheckboxLabel.
  ///
  /// In en, this message translates to:
  /// **'By completing your profile, you agree that MSS collects and processes your information to create your profile and provide personalized Government scheme recommendations.'**
  String get profileConsentCheckboxLabel;

  /// No description provided for @profileConsentReadMore.
  ///
  /// In en, this message translates to:
  /// **'Read how your data is used →'**
  String get profileConsentReadMore;

  /// No description provided for @profileConsentPleaseConsent.
  ///
  /// In en, this message translates to:
  /// **'Please consent to continue'**
  String get profileConsentPleaseConsent;

  /// No description provided for @profileConsentRequiredToast.
  ///
  /// In en, this message translates to:
  /// **'Please consent to data processing to continue.'**
  String get profileConsentRequiredToast;

  /// No description provided for @legalAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get legalAccept;

  /// No description provided for @legalScrollToEndNotice.
  ///
  /// In en, this message translates to:
  /// **'You must scroll to the end of this document before you can accept it.'**
  String get legalScrollToEndNotice;

  /// No description provided for @legalScrollToEndHint.
  ///
  /// In en, this message translates to:
  /// **'Scroll to the end to enable Accept'**
  String get legalScrollToEndHint;

  /// No description provided for @simpleProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Profile Setup'**
  String get simpleProfileTitle;

  /// No description provided for @simpleProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Answer 6 simple questions to discover your schemes'**
  String get simpleProfileSubtitle;

  /// No description provided for @simpleProfileStepStateTitle.
  ///
  /// In en, this message translates to:
  /// **'Where do you live?'**
  String get simpleProfileStepStateTitle;

  /// No description provided for @simpleProfileStepStateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your home state for local state schemes'**
  String get simpleProfileStepStateSubtitle;

  /// No description provided for @simpleProfileStepGenderAgeTitle.
  ///
  /// In en, this message translates to:
  /// **'About You'**
  String get simpleProfileStepGenderAgeTitle;

  /// No description provided for @simpleProfileStepGenderAgeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your gender and age'**
  String get simpleProfileStepGenderAgeSubtitle;

  /// No description provided for @simpleProfileStepWorkTitle.
  ///
  /// In en, this message translates to:
  /// **'What is your work or plan?'**
  String get simpleProfileStepWorkTitle;

  /// No description provided for @simpleProfileStepWorkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the option that describes you best'**
  String get simpleProfileStepWorkSubtitle;

  /// No description provided for @simpleProfileStepSectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Which sector or field?'**
  String get simpleProfileStepSectorTitle;

  /// No description provided for @simpleProfileStepSectorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your primary trade or work area'**
  String get simpleProfileStepSectorSubtitle;

  /// No description provided for @simpleProfileStepCommunityTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Social Category'**
  String get simpleProfileStepCommunityTitle;

  /// No description provided for @simpleProfileStepCommunitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Government schemes provide special subsidies for specific categories'**
  String get simpleProfileStepCommunitySubtitle;

  /// No description provided for @simpleProfileStepEducationTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Education Level'**
  String get simpleProfileStepEducationTitle;

  /// No description provided for @simpleProfileStepEducationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select your highest completed qualification'**
  String get simpleProfileStepEducationSubtitle;

  /// No description provided for @stateTamilNadu.
  ///
  /// In en, this message translates to:
  /// **'Tamil Nadu'**
  String get stateTamilNadu;

  /// No description provided for @stateMaharashtra.
  ///
  /// In en, this message translates to:
  /// **'Maharashtra'**
  String get stateMaharashtra;

  /// No description provided for @stateUttarPradesh.
  ///
  /// In en, this message translates to:
  /// **'Uttar Pradesh'**
  String get stateUttarPradesh;

  /// No description provided for @stateKarnataka.
  ///
  /// In en, this message translates to:
  /// **'Karnataka'**
  String get stateKarnataka;

  /// No description provided for @stateGujarat.
  ///
  /// In en, this message translates to:
  /// **'Gujarat'**
  String get stateGujarat;

  /// No description provided for @stateOther.
  ///
  /// In en, this message translates to:
  /// **'Other States'**
  String get stateOther;

  /// No description provided for @searchStateOrUtPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search state or UT'**
  String get searchStateOrUtPlaceholder;

  /// No description provided for @ageYearsLabel.
  ///
  /// In en, this message translates to:
  /// **'years'**
  String get ageYearsLabel;

  /// No description provided for @workNewBusiness.
  ///
  /// In en, this message translates to:
  /// **'Want to start a business'**
  String get workNewBusiness;

  /// No description provided for @workNewBusinessDesc.
  ///
  /// In en, this message translates to:
  /// **'Have an idea or starting a new venture'**
  String get workNewBusinessDesc;

  /// No description provided for @workExistingBusiness.
  ///
  /// In en, this message translates to:
  /// **'Running a shop or business'**
  String get workExistingBusiness;

  /// No description provided for @workExistingBusinessDesc.
  ///
  /// In en, this message translates to:
  /// **'Own an operational trade or enterprise'**
  String get workExistingBusinessDesc;

  /// No description provided for @workFarmer.
  ///
  /// In en, this message translates to:
  /// **'Farming & Agriculture'**
  String get workFarmer;

  /// No description provided for @workFarmerDesc.
  ///
  /// In en, this message translates to:
  /// **'Crops, dairy, poultry, or allied farming'**
  String get workFarmerDesc;

  /// No description provided for @workArtisan.
  ///
  /// In en, this message translates to:
  /// **'Artisan, Handloom & Crafts'**
  String get workArtisan;

  /// No description provided for @workArtisanDesc.
  ///
  /// In en, this message translates to:
  /// **'Weaving, pottery, handicrafts, or trade crafts'**
  String get workArtisanDesc;

  /// No description provided for @workStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get workStudent;

  /// No description provided for @workStudentDesc.
  ///
  /// In en, this message translates to:
  /// **'Enrolled in school, college, or training'**
  String get workStudentDesc;

  /// No description provided for @sectorAgri.
  ///
  /// In en, this message translates to:
  /// **'Agriculture & Dairy'**
  String get sectorAgri;

  /// No description provided for @sectorManufacturing.
  ///
  /// In en, this message translates to:
  /// **'Manufacturing & Workshop'**
  String get sectorManufacturing;

  /// No description provided for @sectorRetail.
  ///
  /// In en, this message translates to:
  /// **'Retail, Shop & Trading'**
  String get sectorRetail;

  /// No description provided for @sectorTextiles.
  ///
  /// In en, this message translates to:
  /// **'Textiles & Handloom'**
  String get sectorTextiles;

  /// No description provided for @sectorFood.
  ///
  /// In en, this message translates to:
  /// **'Food Processing & Eatery'**
  String get sectorFood;

  /// No description provided for @sectorServices.
  ///
  /// In en, this message translates to:
  /// **'Services & Digital Tech'**
  String get sectorServices;

  /// No description provided for @sectorHandicrafts.
  ///
  /// In en, this message translates to:
  /// **'Handicrafts & Art'**
  String get sectorHandicrafts;

  /// No description provided for @sectorGeneral.
  ///
  /// In en, this message translates to:
  /// **'General / Any Sector'**
  String get sectorGeneral;

  /// No description provided for @simpleProfileStepIndicator.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String simpleProfileStepIndicator(int current, int total);

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionFinish.
  ///
  /// In en, this message translates to:
  /// **'Find My Schemes'**
  String get actionFinish;

  /// No description provided for @actionSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get actionSaving;

  /// No description provided for @regionSouthIndia.
  ///
  /// In en, this message translates to:
  /// **'South India'**
  String get regionSouthIndia;

  /// No description provided for @regionWestIndia.
  ///
  /// In en, this message translates to:
  /// **'West India'**
  String get regionWestIndia;

  /// No description provided for @regionNorthIndia.
  ///
  /// In en, this message translates to:
  /// **'North India'**
  String get regionNorthIndia;

  /// No description provided for @regionAllIndia.
  ///
  /// In en, this message translates to:
  /// **'All India'**
  String get regionAllIndia;

  /// No description provided for @ageSelectLabel.
  ///
  /// In en, this message translates to:
  /// **'Your Age'**
  String get ageSelectLabel;

  /// No description provided for @commDescObc.
  ///
  /// In en, this message translates to:
  /// **'Backward / Most Backward Class'**
  String get commDescObc;

  /// No description provided for @commDescSc.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Caste'**
  String get commDescSc;

  /// No description provided for @commDescSt.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Tribe'**
  String get commDescSt;

  /// No description provided for @commDescMinority.
  ///
  /// In en, this message translates to:
  /// **'Muslim, Christian, Sikh, Jain, Buddhist, Parsi'**
  String get commDescMinority;

  /// No description provided for @commDescGeneral.
  ///
  /// In en, this message translates to:
  /// **'Open Category'**
  String get commDescGeneral;

  /// No description provided for @eduDescSchool.
  ///
  /// In en, this message translates to:
  /// **'Up to 10th or 12th standard'**
  String get eduDescSchool;

  /// No description provided for @eduDescDiploma.
  ///
  /// In en, this message translates to:
  /// **'Polytechnic or vocational certificate'**
  String get eduDescDiploma;

  /// No description provided for @eduDescUndergraduate.
  ///
  /// In en, this message translates to:
  /// **'Bachelor degree (BA, BSc, BCom, BE, etc.)'**
  String get eduDescUndergraduate;

  /// No description provided for @eduDescPostgraduate.
  ///
  /// In en, this message translates to:
  /// **'Master degree, MPhil, or Ph.D.'**
  String get eduDescPostgraduate;

  /// No description provided for @hintAgeExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. 25'**
  String get hintAgeExample;

  /// No description provided for @hintAddressExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Door/Flat No, Street Name, Locality'**
  String get hintAddressExample;

  /// No description provided for @hintCityExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Chennai'**
  String get hintCityExample;

  /// No description provided for @legalPrivacyNoticeLink.
  ///
  /// In en, this message translates to:
  /// **'Privacy Notice'**
  String get legalPrivacyNoticeLink;

  /// No description provided for @legalTermsOfUseLink.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get legalTermsOfUseLink;

  /// No description provided for @shareSchemeDetailsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share scheme details'**
  String get shareSchemeDetailsTooltip;

  /// No description provided for @legalConsentPrefix.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the '**
  String get legalConsentPrefix;

  /// No description provided for @legalConsentMid.
  ///
  /// In en, this message translates to:
  /// **' and acknowledge the '**
  String get legalConsentMid;

  /// No description provided for @legalConsentSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get legalConsentSuffix;

  /// No description provided for @permLocationOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Services Off'**
  String get permLocationOffTitle;

  /// No description provided for @permLocationOffBody.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off. Please turn them on in your system settings to discover local state & district schemes tailored for you.'**
  String get permLocationOffBody;

  /// No description provided for @permLocationBenefitDetect.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect State & District eligibility'**
  String get permLocationBenefitDetect;

  /// No description provided for @permLocationBenefitTailored.
  ///
  /// In en, this message translates to:
  /// **'Tailored regional subsidies & benefits'**
  String get permLocationBenefitTailored;

  /// No description provided for @permLocationTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn On Location'**
  String get permLocationTurnOn;

  /// No description provided for @aboutAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Government Scheme Discovery & Eligibility Platform'**
  String get aboutAppSubtitle;

  /// No description provided for @aboutDevelopedWith.
  ///
  /// In en, this message translates to:
  /// **'Developed in collaboration with:'**
  String get aboutDevelopedWith;

  /// No description provided for @splashDevelopedBy.
  ///
  /// In en, this message translates to:
  /// **'App developed by'**
  String get splashDevelopedBy;

  /// No description provided for @aboutSupportLine.
  ///
  /// In en, this message translates to:
  /// **'Support: {email}'**
  String aboutSupportLine(Object email);

  /// No description provided for @catalogFreshnessLabel.
  ///
  /// In en, this message translates to:
  /// **'Local catalog {version}'**
  String catalogFreshnessLabel(Object version);

  /// No description provided for @catalogFreshnessLabelUpdated.
  ///
  /// In en, this message translates to:
  /// **'Local catalog {version} • updated {date}'**
  String catalogFreshnessLabelUpdated(Object date, Object version);

  /// No description provided for @aboutAppDescriptionLong.
  ///
  /// In en, this message translates to:
  /// **'MSS is an intelligent digital platform designed to bridge the awareness gap and simplify the discovery, eligibility matching, and application process for Central and State Government schemes for Indian entrepreneurs, women, farmers, and students.'**
  String get aboutAppDescriptionLong;

  /// No description provided for @schemeSectionContacts.
  ///
  /// In en, this message translates to:
  /// **'Contact details'**
  String get schemeSectionContacts;

  /// No description provided for @schemeSectionStatus.
  ///
  /// In en, this message translates to:
  /// **'Status and updates'**
  String get schemeSectionStatus;

  /// No description provided for @schemeSectionBenefitFacts.
  ///
  /// In en, this message translates to:
  /// **'Benefit figures'**
  String get schemeSectionBenefitFacts;

  /// No description provided for @schemeSectionApplyInfo.
  ///
  /// In en, this message translates to:
  /// **'Fees and requirements'**
  String get schemeSectionApplyInfo;

  /// No description provided for @schemeSectionRelated.
  ///
  /// In en, this message translates to:
  /// **'Related schemes'**
  String get schemeSectionRelated;

  /// No description provided for @schemeSectionAltNames.
  ///
  /// In en, this message translates to:
  /// **'Also known as'**
  String get schemeSectionAltNames;

  /// No description provided for @schemeSectionLinks.
  ///
  /// In en, this message translates to:
  /// **'Official links'**
  String get schemeSectionLinks;

  /// No description provided for @schemeContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get schemeContactPhone;

  /// No description provided for @schemeContactHelpline.
  ///
  /// In en, this message translates to:
  /// **'Helpline'**
  String get schemeContactHelpline;

  /// No description provided for @schemeContactEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get schemeContactEmail;

  /// No description provided for @schemeContactWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get schemeContactWebsite;

  /// No description provided for @schemeContactOffice.
  ///
  /// In en, this message translates to:
  /// **'Office'**
  String get schemeContactOffice;

  /// No description provided for @schemeContactAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get schemeContactAddress;

  /// No description provided for @schemeContactHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get schemeContactHours;

  /// No description provided for @schemeStatusAsOf.
  ///
  /// In en, this message translates to:
  /// **'As of {date}'**
  String schemeStatusAsOf(String date);

  /// No description provided for @schemeApplicationStatus.
  ///
  /// In en, this message translates to:
  /// **'Applications: {status}'**
  String schemeApplicationStatus(String status);

  /// No description provided for @schemeAppStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get schemeAppStatusOpen;

  /// No description provided for @schemeAppStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get schemeAppStatusClosed;

  /// No description provided for @schemeAppStatusAnnounced.
  ///
  /// In en, this message translates to:
  /// **'Announced'**
  String get schemeAppStatusAnnounced;

  /// No description provided for @schemeAppStatusHistorical.
  ///
  /// In en, this message translates to:
  /// **'Historical or superseded'**
  String get schemeAppStatusHistorical;

  /// No description provided for @schemeAppStatusUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Temporarily unavailable'**
  String get schemeAppStatusUnavailable;

  /// No description provided for @schemeAppStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed'**
  String get schemeAppStatusUnknown;

  /// No description provided for @officialInfoButton.
  ///
  /// In en, this message translates to:
  /// **'Official information'**
  String get officialInfoButton;

  /// No description provided for @schemeDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get schemeDeadline;

  /// No description provided for @schemeFees.
  ///
  /// In en, this message translates to:
  /// **'Fees'**
  String get schemeFees;

  /// No description provided for @schemePrerequisite.
  ///
  /// In en, this message translates to:
  /// **'Prerequisite'**
  String get schemePrerequisite;

  /// No description provided for @schemeProcedureOfficial.
  ///
  /// In en, this message translates to:
  /// **'Procedure from official sources'**
  String get schemeProcedureOfficial;

  /// No description provided for @schemeProcedurePolicy.
  ///
  /// In en, this message translates to:
  /// **'Procedure inferred from policy text'**
  String get schemeProcedurePolicy;

  /// No description provided for @schemeProcedureSecondary.
  ///
  /// In en, this message translates to:
  /// **'Procedure from secondary web sources'**
  String get schemeProcedureSecondary;

  /// No description provided for @schemeProcedureGeneric.
  ///
  /// In en, this message translates to:
  /// **'General guidance only'**
  String get schemeProcedureGeneric;

  /// No description provided for @schemeLinkApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get schemeLinkApply;

  /// No description provided for @schemeLinkInfo.
  ///
  /// In en, this message translates to:
  /// **'Scheme information'**
  String get schemeLinkInfo;

  /// No description provided for @schemeLinkGuidelines.
  ///
  /// In en, this message translates to:
  /// **'Guidelines'**
  String get schemeLinkGuidelines;

  /// No description provided for @schemeTranslationNotice.
  ///
  /// In en, this message translates to:
  /// **'This {language} text is machine-translated and has not been reviewed yet.'**
  String schemeTranslationNotice(String language);

  /// No description provided for @schemeFactMax.
  ///
  /// In en, this message translates to:
  /// **'Maximum'**
  String get schemeFactMax;

  /// No description provided for @schemeFactMin.
  ///
  /// In en, this message translates to:
  /// **'Minimum'**
  String get schemeFactMin;

  /// No description provided for @schemeFactAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get schemeFactAmount;

  /// No description provided for @schemeFactPercent.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get schemeFactPercent;

  /// No description provided for @schemeFactTenure.
  ///
  /// In en, this message translates to:
  /// **'Tenure'**
  String get schemeFactTenure;

  /// No description provided for @schemeFactInterest.
  ///
  /// In en, this message translates to:
  /// **'Interest rate'**
  String get schemeFactInterest;

  /// No description provided for @schemeFactCoverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get schemeFactCoverage;

  /// No description provided for @schemeFactMaxCover.
  ///
  /// In en, this message translates to:
  /// **'Maximum cover'**
  String get schemeFactMaxCover;

  /// No description provided for @schemeFactFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get schemeFactFee;

  /// No description provided for @schemeFactMoratorium.
  ///
  /// In en, this message translates to:
  /// **'Moratorium'**
  String get schemeFactMoratorium;

  /// No description provided for @schemeFactDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get schemeFactDuration;

  /// No description provided for @schemeMonthsValue.
  ///
  /// In en, this message translates to:
  /// **'{count} months'**
  String schemeMonthsValue(int count);

  /// No description provided for @schemeLinkPortal.
  ///
  /// In en, this message translates to:
  /// **'Official portal'**
  String get schemeLinkPortal;

  /// No description provided for @schemeLinkPortalLogin.
  ///
  /// In en, this message translates to:
  /// **'Portal login'**
  String get schemeLinkPortalLogin;

  /// No description provided for @schemeLinkPortalServices.
  ///
  /// In en, this message translates to:
  /// **'Portal services'**
  String get schemeLinkPortalServices;

  /// No description provided for @passwordSetting.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordSetting;

  /// No description provided for @activeSessionsSetting.
  ///
  /// In en, this message translates to:
  /// **'Active Sessions'**
  String get activeSessionsSetting;

  /// No description provided for @setPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Password'**
  String get setPasswordTitle;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordTitle;

  /// No description provided for @removePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Password'**
  String get removePasswordTitle;

  /// No description provided for @currentPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPasswordLabel;

  /// No description provided for @newPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPasswordLabel;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @passwordChangedNotice.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Please sign in again.'**
  String get passwordChangedNotice;

  /// No description provided for @revokeSession.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revokeSession;

  /// No description provided for @logoutAllSessions.
  ///
  /// In en, this message translates to:
  /// **'Log Out All Devices'**
  String get logoutAllSessions;

  /// No description provided for @sessionCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current Device'**
  String get sessionCurrent;

  /// No description provided for @noActiveSessions.
  ///
  /// In en, this message translates to:
  /// **'No active sessions found.'**
  String get noActiveSessions;

  /// No description provided for @passwordRemovedNotice.
  ///
  /// In en, this message translates to:
  /// **'Password removed. Please sign in again.'**
  String get passwordRemovedNotice;

  /// No description provided for @signInWithPassword.
  ///
  /// In en, this message translates to:
  /// **'Sign in with password'**
  String get signInWithPassword;

  /// No description provided for @pwInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get pwInvalidEmail;

  /// No description provided for @pwEnterPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password.'**
  String get pwEnterPassword;

  /// No description provided for @pwLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed. Please check your email and password.'**
  String get pwLoginFailed;

  /// No description provided for @pwInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password.'**
  String get pwInvalidCredentials;

  /// No description provided for @pwTooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait and try again.'**
  String get pwTooManyAttempts;

  /// No description provided for @pwLoginUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong while signing in.'**
  String get pwLoginUnexpected;

  /// No description provided for @pwSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get pwSignInButton;

  /// No description provided for @pwLengthRule.
  ///
  /// In en, this message translates to:
  /// **'Password must be 15 to 128 characters long.'**
  String get pwLengthRule;

  /// No description provided for @pwMismatch.
  ///
  /// In en, this message translates to:
  /// **'New password and confirmation do not match.'**
  String get pwMismatch;

  /// No description provided for @pwEnterCurrent.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password.'**
  String get pwEnterCurrent;

  /// No description provided for @pwReauthRequired.
  ///
  /// In en, this message translates to:
  /// **'For your security, please sign in again first.'**
  String get pwReauthRequired;

  /// No description provided for @pwPolicyFailed.
  ///
  /// In en, this message translates to:
  /// **'Password does not meet the requirements.'**
  String get pwPolicyFailed;

  /// No description provided for @pwCurrentIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect.'**
  String get pwCurrentIncorrect;

  /// No description provided for @pwUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not update the password.'**
  String get pwUpdateFailed;

  /// No description provided for @pwRemoveNeedsCurrent.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password to remove it.'**
  String get pwRemoveNeedsCurrent;

  /// No description provided for @pwRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove the password.'**
  String get pwRemoveFailed;

  /// No description provided for @pwMinHint.
  ///
  /// In en, this message translates to:
  /// **'At least 15 characters'**
  String get pwMinHint;

  /// No description provided for @pwLengthProgress.
  ///
  /// In en, this message translates to:
  /// **'{count} of 15 characters minimum'**
  String pwLengthProgress(int count);

  /// No description provided for @pwLongTip.
  ///
  /// In en, this message translates to:
  /// **'Long is strong: a few words you remember, like “mango tree near the temple”, work well.'**
  String get pwLongTip;

  /// No description provided for @sessionRevoked.
  ///
  /// In en, this message translates to:
  /// **'Session revoked.'**
  String get sessionRevoked;

  /// No description provided for @sessionRevokeFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to revoke the session.'**
  String get sessionRevokeFailed;

  /// No description provided for @logoutAllFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to log out all devices.'**
  String get logoutAllFailed;

  /// No description provided for @sessionOtherDevice.
  ///
  /// In en, this message translates to:
  /// **'Signed-in device'**
  String get sessionOtherDevice;

  /// No description provided for @sessionSignedInAt.
  ///
  /// In en, this message translates to:
  /// **'Signed in: {time}'**
  String sessionSignedInAt(String time);

  /// No description provided for @udyamMicro.
  ///
  /// In en, this message translates to:
  /// **'MICRO Enterprise'**
  String get udyamMicro;

  /// No description provided for @udyamSmall.
  ///
  /// In en, this message translates to:
  /// **'SMALL Enterprise'**
  String get udyamSmall;

  /// No description provided for @udyamMedium.
  ///
  /// In en, this message translates to:
  /// **'MEDIUM Enterprise'**
  String get udyamMedium;

  /// No description provided for @udyamLarge.
  ///
  /// In en, this message translates to:
  /// **'Large Enterprise (Beyond MSME Limits)'**
  String get udyamLarge;

  /// No description provided for @udyamInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid Input'**
  String get udyamInvalid;

  /// No description provided for @udyamInvalidSub.
  ///
  /// In en, this message translates to:
  /// **'Enter numbers of 0 or more.'**
  String get udyamInvalidSub;

  /// No description provided for @udyamLimitsSummary.
  ///
  /// In en, this message translates to:
  /// **'Limits (2025): Micro ≤{microInv} / ≤{microTurn} Cr · Small ≤{smallInv} / ≤{smallTurn} Cr · Medium ≤{medInv} / ≤{medTurn} Cr (investment / turnover)'**
  String udyamLimitsSummary(
    String microInv,
    String microTurn,
    String smallInv,
    String smallTurn,
    String medInv,
    String medTurn,
  );

  /// No description provided for @schemeNotMatchingFilters.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t match your filters'**
  String get schemeNotMatchingFilters;

  /// No description provided for @greetingLateNight.
  ///
  /// In en, this message translates to:
  /// **'Hello,'**
  String get greetingLateNight;

  /// No description provided for @copyChecklistTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy checklist'**
  String get copyChecklistTooltip;

  /// No description provided for @voiceClipError.
  ///
  /// In en, this message translates to:
  /// **'Could not process your request. Check microphone permission or your connection. You can retry the same recording, change its language, or type your request.'**
  String get voiceClipError;

  /// No description provided for @voiceRecordTitle.
  ///
  /// In en, this message translates to:
  /// **'Record your request'**
  String get voiceRecordTitle;

  /// No description provided for @voiceRecordDisclosure.
  ///
  /// In en, this message translates to:
  /// **'Choose the language you will speak. Record up to 60 seconds, then review the text before sending. Your recording is uploaded to Sarvam for transcription. It is kept in this screen only until you close it.'**
  String get voiceRecordDisclosure;

  /// No description provided for @voiceSpokenLanguage.
  ///
  /// In en, this message translates to:
  /// **'Spoken language'**
  String get voiceSpokenLanguage;

  /// No description provided for @voiceTranscribingClip.
  ///
  /// In en, this message translates to:
  /// **'Transcribing your recording. This may take a few minutes. You can cancel and type instead.'**
  String get voiceTranscribingClip;

  /// No description provided for @voiceRecordingClip.
  ///
  /// In en, this message translates to:
  /// **'Recording — tap Stop when you finish (60-second limit).'**
  String get voiceRecordingClip;

  /// No description provided for @voiceReviewTranscript.
  ///
  /// In en, this message translates to:
  /// **'Review and edit your request'**
  String get voiceReviewTranscript;

  /// No description provided for @voiceStopAndTranscribe.
  ///
  /// In en, this message translates to:
  /// **'Stop and transcribe'**
  String get voiceStopAndTranscribe;

  /// No description provided for @voiceRecordClip.
  ///
  /// In en, this message translates to:
  /// **'Record a new request'**
  String get voiceRecordClip;

  /// No description provided for @voiceRetryClip.
  ///
  /// In en, this message translates to:
  /// **'Transcribe this recording again'**
  String get voiceRetryClip;

  /// No description provided for @voiceSendReviewed.
  ///
  /// In en, this message translates to:
  /// **'Send reviewed request'**
  String get voiceSendReviewed;

  /// No description provided for @liveVoiceReady.
  ///
  /// In en, this message translates to:
  /// **'Ready to talk'**
  String get liveVoiceReady;

  /// No description provided for @liveVoiceConnecting.
  ///
  /// In en, this message translates to:
  /// **'Starting microphone…'**
  String get liveVoiceConnecting;

  /// No description provided for @liveVoiceListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get liveVoiceListening;

  /// No description provided for @liveVoiceTranscribing.
  ///
  /// In en, this message translates to:
  /// **'Finishing your request…'**
  String get liveVoiceTranscribing;

  /// No description provided for @liveVoiceThinking.
  ///
  /// In en, this message translates to:
  /// **'Finding an answer…'**
  String get liveVoiceThinking;

  /// No description provided for @liveVoiceSpeaking.
  ///
  /// In en, this message translates to:
  /// **'Saarthi is speaking'**
  String get liveVoiceSpeaking;

  /// No description provided for @liveVoicePaused.
  ///
  /// In en, this message translates to:
  /// **'Conversation paused'**
  String get liveVoicePaused;

  /// No description provided for @liveVoiceError.
  ///
  /// In en, this message translates to:
  /// **'Voice needs attention'**
  String get liveVoiceError;

  /// No description provided for @liveVoiceEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get liveVoiceEnd;

  /// No description provided for @liveVoicePause.
  ///
  /// In en, this message translates to:
  /// **'Pause conversation'**
  String get liveVoicePause;

  /// No description provided for @liveVoiceResume.
  ///
  /// In en, this message translates to:
  /// **'Resume listening'**
  String get liveVoiceResume;

  /// No description provided for @liveVoiceHeard.
  ///
  /// In en, this message translates to:
  /// **'What I heard'**
  String get liveVoiceHeard;

  /// No description provided for @liveVoiceFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish speaking'**
  String get liveVoiceFinish;

  /// No description provided for @liveVoiceCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct request'**
  String get liveVoiceCorrect;

  /// No description provided for @liveVoiceType.
  ///
  /// In en, this message translates to:
  /// **'Type instead'**
  String get liveVoiceType;

  /// No description provided for @liveVoiceRepeat.
  ///
  /// In en, this message translates to:
  /// **'Hear reply again'**
  String get liveVoiceRepeat;

  /// No description provided for @liveVoiceEditRequest.
  ///
  /// In en, this message translates to:
  /// **'Your request'**
  String get liveVoiceEditRequest;

  /// No description provided for @liveVoiceEditingHint.
  ///
  /// In en, this message translates to:
  /// **'The microphone is paused. Edit your words, then send.'**
  String get liveVoiceEditingHint;

  /// No description provided for @liveVoiceOptions.
  ///
  /// In en, this message translates to:
  /// **'Voice options'**
  String get liveVoiceOptions;

  /// No description provided for @liveVoiceLongPauses.
  ///
  /// In en, this message translates to:
  /// **'Allow longer pauses'**
  String get liveVoiceLongPauses;

  /// No description provided for @liveVoiceLongPausesHint.
  ///
  /// In en, this message translates to:
  /// **'Take more time between words before Saarthi replies.'**
  String get liveVoiceLongPausesHint;

  /// No description provided for @liveVoiceReadAloud.
  ///
  /// In en, this message translates to:
  /// **'Read replies aloud'**
  String get liveVoiceReadAloud;

  /// No description provided for @liveVoiceReview.
  ///
  /// In en, this message translates to:
  /// **'Review before sending'**
  String get liveVoiceReview;

  /// No description provided for @liveVoiceReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Check and correct each transcript before it is sent.'**
  String get liveVoiceReviewHint;

  /// No description provided for @liveVoiceConversationHint.
  ///
  /// In en, this message translates to:
  /// **'Speak, then pause. Saarthi replies and listens again. Pause whenever you need; correct or type your request below.'**
  String get liveVoiceConversationHint;

  /// No description provided for @liveVoiceScreenReaderHint.
  ///
  /// In en, this message translates to:
  /// **'The microphone stays paused after each reply so your screen reader can finish. Choose Resume listening when you are ready.'**
  String get liveVoiceScreenReaderHint;

  /// No description provided for @liveVoiceMicrophonePermission.
  ///
  /// In en, this message translates to:
  /// **'Allow microphone access in your device settings, then resume. You can also type your request.'**
  String get liveVoiceMicrophonePermission;

  /// No description provided for @liveVoiceNoSpeech.
  ///
  /// In en, this message translates to:
  /// **'No speech was heard. Resume to try again, or type your request.'**
  String get liveVoiceNoSpeech;

  /// No description provided for @liveVoiceConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Voice could not finish. Check your connection, then resume or type your request.'**
  String get liveVoiceConnectionError;

  /// No description provided for @liveVoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Saarthi'**
  String get liveVoiceTitle;

  /// No description provided for @liveVoiceLatest.
  ///
  /// In en, this message translates to:
  /// **'Latest reply'**
  String get liveVoiceLatest;

  /// No description provided for @liveVoiceScreenReaderShort.
  ///
  /// In en, this message translates to:
  /// **'Screen reader mode: resume after each reply.'**
  String get liveVoiceScreenReaderShort;

  /// No description provided for @liveVoiceFinalTimeout.
  ///
  /// In en, this message translates to:
  /// **'The transcript did not finish. Correct the words we heard, or resume to try again.'**
  String get liveVoiceFinalTimeout;

  /// No description provided for @liveVoiceSpeechUnavailable.
  ///
  /// In en, this message translates to:
  /// **'I couldn’t play the audio. Your reply is below. Tap Hear reply again to retry, and check your media volume.'**
  String get liveVoiceSpeechUnavailable;

  /// No description provided for @notifDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notifDetailTitle;

  /// No description provided for @notifDeleteThis.
  ///
  /// In en, this message translates to:
  /// **'Delete this notification'**
  String get notifDeleteThis;

  /// No description provided for @notifDeletedToast.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get notifDeletedToast;

  /// No description provided for @notifReceivedOn.
  ///
  /// In en, this message translates to:
  /// **'Received {date}'**
  String notifReceivedOn(String date);

  /// No description provided for @notifToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notifToday;

  /// No description provided for @notifYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get notifYesterday;

  /// No description provided for @notifEarlier.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get notifEarlier;

  /// No description provided for @settingsHapticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get settingsHapticsTitle;

  /// No description provided for @settingsHapticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vibrate lightly on taps and when a notification arrives'**
  String get settingsHapticsSubtitle;

  /// No description provided for @homeFeaturedBestForYou.
  ///
  /// In en, this message translates to:
  /// **'Best for you'**
  String get homeFeaturedBestForYou;

  /// No description provided for @homeFeaturedNewlyAdded.
  ///
  /// In en, this message translates to:
  /// **'Newly added'**
  String get homeFeaturedNewlyAdded;

  /// No description provided for @homeFeaturedAddedOn.
  ///
  /// In en, this message translates to:
  /// **'Added {date}'**
  String homeFeaturedAddedOn(String date);

  /// No description provided for @homeTip2.
  ///
  /// In en, this message translates to:
  /// **'Udyam registration is free. Most MSME schemes ask for your Udyam number.'**
  String get homeTip2;

  /// No description provided for @homeTip3.
  ///
  /// In en, this message translates to:
  /// **'Keep your Aadhaar, PAN and bank details ready before you start an application.'**
  String get homeTip3;

  /// No description provided for @homeTip4.
  ///
  /// In en, this message translates to:
  /// **'Under CGTMSE, micro and small enterprises can get loans without collateral.'**
  String get homeTip4;

  /// No description provided for @homeTip5.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile to get better scheme matches in MSS.'**
  String get homeTip5;

  /// No description provided for @homeTip6.
  ///
  /// In en, this message translates to:
  /// **'Check a scheme\'s last date before applying. Some schemes stay open only for a few weeks.'**
  String get homeTip6;

  /// No description provided for @homeTip7.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark on a scheme to keep it in Saved for later.'**
  String get homeTip7;

  /// No description provided for @homeTip8.
  ///
  /// In en, this message translates to:
  /// **'Buyers paying late? MSME Samadhaan lets micro and small enterprises file a delayed-payment case online.'**
  String get homeTip8;

  /// No description provided for @homeTip9.
  ///
  /// In en, this message translates to:
  /// **'DPIIT-recognised startups can apply to the Startup India Seed Fund Scheme.'**
  String get homeTip9;

  /// No description provided for @homeTip10.
  ///
  /// In en, this message translates to:
  /// **'Apply only through the official scheme link. Never pay an agent for a free government service.'**
  String get homeTip10;

  /// No description provided for @homeTourFindTitle.
  ///
  /// In en, this message translates to:
  /// **'Find a Scheme'**
  String get homeTourFindTitle;

  /// No description provided for @homeTourFindBody.
  ///
  /// In en, this message translates to:
  /// **'Search by scheme name, keyword, or benefit to find relevant government schemes and support.'**
  String get homeTourFindBody;

  /// No description provided for @homeTourAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask Saarthi'**
  String get homeTourAskTitle;

  /// No description provided for @homeTourAskBody.
  ///
  /// In en, this message translates to:
  /// **'Get quick answers to your questions about government schemes, eligibility, required documents, and application procedures.'**
  String get homeTourAskBody;

  /// No description provided for @homeTourDiscoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get homeTourDiscoverTitle;

  /// No description provided for @homeTourDiscoverBody.
  ///
  /// In en, this message translates to:
  /// **'Explore schemes and support categories to find opportunities for financial assistance, business growth, registration, training, and more.'**
  String get homeTourDiscoverBody;

  /// No description provided for @homeTourProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Your Profile'**
  String get homeTourProfileTitle;

  /// No description provided for @homeTourProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Update your personal and business details to help us provide more relevant scheme recommendations.'**
  String get homeTourProfileBody;

  /// No description provided for @homeTourProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} of {total}'**
  String homeTourProgress(int current, int total);

  /// No description provided for @homeTourSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get homeTourSkip;

  /// No description provided for @homeTourNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get homeTourNext;

  /// No description provided for @homeTourFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get homeTourFinish;

  /// No description provided for @verificationStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verificationStatusVerified;

  /// No description provided for @verificationStatusNotIndependentlyVerified.
  ///
  /// In en, this message translates to:
  /// **'Not independently verified'**
  String get verificationStatusNotIndependentlyVerified;

  /// No description provided for @deleteAccountScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Deleting your account'**
  String get deleteAccountScreenTitle;

  /// No description provided for @deleteAccountStepRemoving.
  ///
  /// In en, this message translates to:
  /// **'Removing your account'**
  String get deleteAccountStepRemoving;

  /// No description provided for @deleteAccountStepVerifying.
  ///
  /// In en, this message translates to:
  /// **'Checking that it is gone'**
  String get deleteAccountStepVerifying;

  /// No description provided for @deleteAccountStepClearing.
  ///
  /// In en, this message translates to:
  /// **'Clearing this phone'**
  String get deleteAccountStepClearing;

  /// No description provided for @deleteAccountDone.
  ///
  /// In en, this message translates to:
  /// **'Your account was deleted'**
  String get deleteAccountDone;

  /// No description provided for @deleteAccountFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your account was not deleted'**
  String get deleteAccountFailedTitle;

  /// No description provided for @deleteAccountRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get deleteAccountRetry;

  /// No description provided for @deleteAccountBack.
  ///
  /// In en, this message translates to:
  /// **'Back to settings'**
  String get deleteAccountBack;

  /// No description provided for @deleteAccountSignOutAgain.
  ///
  /// In en, this message translates to:
  /// **'Sign out and sign in again'**
  String get deleteAccountSignOutAgain;

  /// No description provided for @deleteAccountKeepOpen.
  ///
  /// In en, this message translates to:
  /// **'Please keep the app open.'**
  String get deleteAccountKeepOpen;

  /// No description provided for @deleteAccountErrReauth.
  ///
  /// In en, this message translates to:
  /// **'For your security, sign in again and then delete your account within 5 minutes. Nothing was changed.'**
  String get deleteAccountErrReauth;

  /// No description provided for @deleteAccountErrRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a minute and try again. Nothing was changed.'**
  String get deleteAccountErrRateLimited;

  /// No description provided for @deleteAccountErrUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Account deletion is temporarily unavailable. Try again later. Nothing was changed.'**
  String get deleteAccountErrUnavailable;

  /// No description provided for @deleteAccountErrOffline.
  ///
  /// In en, this message translates to:
  /// **'Account deletion needs an internet connection. Nothing was changed.'**
  String get deleteAccountErrOffline;

  /// No description provided for @deleteAccountErrNotVerified.
  ///
  /// In en, this message translates to:
  /// **'The server still shows your account. Try again; if it keeps happening, contact support.'**
  String get deleteAccountErrNotVerified;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
