import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'IQS'**
  String get appName;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loadingLabel;

  /// No description provided for @errorTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorTitle;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred'**
  String get errorUnexpected;

  /// No description provided for @noConnectionTitle.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get noConnectionTitle;

  /// No description provided for @noConnectionBody.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again'**
  String get noConnectionBody;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @endOfList.
  ///
  /// In en, this message translates to:
  /// **'End of list'**
  String get endOfList;

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendIn(int seconds);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

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

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

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

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @invalidNumber.
  ///
  /// In en, this message translates to:
  /// **'Invalid number'**
  String get invalidNumber;

  /// No description provided for @savedChanges.
  ///
  /// In en, this message translates to:
  /// **'Changes saved'**
  String get savedChanges;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @governorate.
  ///
  /// In en, this message translates to:
  /// **'Governorate'**
  String get governorate;

  /// No description provided for @selectGovernorate.
  ///
  /// In en, this message translates to:
  /// **'Select governorate'**
  String get selectGovernorate;

  /// No description provided for @selectHint.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get selectHint;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get searchHint;

  /// No description provided for @searchShort.
  ///
  /// In en, this message translates to:
  /// **'Search…'**
  String get searchShort;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @typeToSearch.
  ///
  /// In en, this message translates to:
  /// **'Type to search'**
  String get typeToSearch;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMatches.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get navMatches;

  /// No description provided for @navNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get navNews;

  /// No description provided for @navVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get navVideo;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @adminNameAr.
  ///
  /// In en, this message translates to:
  /// **'Name (Arabic)'**
  String get adminNameAr;

  /// No description provided for @adminNameEn.
  ///
  /// In en, this message translates to:
  /// **'Name (English)'**
  String get adminNameEn;

  /// No description provided for @adminDescriptionAr.
  ///
  /// In en, this message translates to:
  /// **'Description (Arabic)'**
  String get adminDescriptionAr;

  /// No description provided for @adminDescriptionEn.
  ///
  /// In en, this message translates to:
  /// **'Description (English)'**
  String get adminDescriptionEn;

  /// No description provided for @adminCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get adminCity;

  /// No description provided for @adminAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get adminAddress;

  /// No description provided for @adminFoundedYear.
  ///
  /// In en, this message translates to:
  /// **'Founded year'**
  String get adminFoundedYear;

  /// No description provided for @adminPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get adminPhone;

  /// No description provided for @adminEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get adminEmail;

  /// No description provided for @adminWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get adminWebsite;

  /// No description provided for @adminFacebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get adminFacebook;

  /// No description provided for @adminInstagram.
  ///
  /// In en, this message translates to:
  /// **'Instagram'**
  String get adminInstagram;

  /// No description provided for @adminTwitter.
  ///
  /// In en, this message translates to:
  /// **'Twitter'**
  String get adminTwitter;

  /// No description provided for @adminTitleAr.
  ///
  /// In en, this message translates to:
  /// **'Title (Arabic)'**
  String get adminTitleAr;

  /// No description provided for @adminTitleEn.
  ///
  /// In en, this message translates to:
  /// **'Title (English)'**
  String get adminTitleEn;

  /// No description provided for @adminExcerptAr.
  ///
  /// In en, this message translates to:
  /// **'Excerpt (Arabic)'**
  String get adminExcerptAr;

  /// No description provided for @adminExcerptEn.
  ///
  /// In en, this message translates to:
  /// **'Excerpt (English)'**
  String get adminExcerptEn;

  /// No description provided for @adminContentAr.
  ///
  /// In en, this message translates to:
  /// **'Content (Arabic)'**
  String get adminContentAr;

  /// No description provided for @adminContentEn.
  ///
  /// In en, this message translates to:
  /// **'Content (English)'**
  String get adminContentEn;

  /// No description provided for @adminAuthorName.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get adminAuthorName;

  /// No description provided for @adminPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get adminPublished;

  /// No description provided for @adminPositionAr.
  ///
  /// In en, this message translates to:
  /// **'Position (Arabic)'**
  String get adminPositionAr;

  /// No description provided for @adminPositionEn.
  ///
  /// In en, this message translates to:
  /// **'Position (English)'**
  String get adminPositionEn;

  /// No description provided for @adminParentIdOptional.
  ///
  /// In en, this message translates to:
  /// **'Parent ID (optional)'**
  String get adminParentIdOptional;

  /// No description provided for @adminDisplayOrder.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get adminDisplayOrder;

  /// No description provided for @adminRoleAr.
  ///
  /// In en, this message translates to:
  /// **'Role (Arabic)'**
  String get adminRoleAr;

  /// No description provided for @adminRoleEn.
  ///
  /// In en, this message translates to:
  /// **'Role (English)'**
  String get adminRoleEn;

  /// No description provided for @adminType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get adminType;

  /// No description provided for @adminBio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get adminBio;

  /// No description provided for @adminHonorTitleAr.
  ///
  /// In en, this message translates to:
  /// **'Title (Arabic)'**
  String get adminHonorTitleAr;

  /// No description provided for @adminHonorTitleEn.
  ///
  /// In en, this message translates to:
  /// **'Title (English)'**
  String get adminHonorTitleEn;

  /// No description provided for @adminCompetitionAr.
  ///
  /// In en, this message translates to:
  /// **'Competition (Arabic)'**
  String get adminCompetitionAr;

  /// No description provided for @adminCompetitionEn.
  ///
  /// In en, this message translates to:
  /// **'Competition (English)'**
  String get adminCompetitionEn;

  /// No description provided for @adminSeason.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get adminSeason;

  /// No description provided for @adminYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get adminYear;

  /// No description provided for @adminCount.
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get adminCount;

  /// No description provided for @adminPeriodFrom.
  ///
  /// In en, this message translates to:
  /// **'From year'**
  String get adminPeriodFrom;

  /// No description provided for @adminPeriodTo.
  ///
  /// In en, this message translates to:
  /// **'To year'**
  String get adminPeriodTo;

  /// No description provided for @adminDescriptionShort.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get adminDescriptionShort;

  /// No description provided for @adminStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get adminStatus;

  /// No description provided for @adminLeagueIdOptional.
  ///
  /// In en, this message translates to:
  /// **'League ID (optional)'**
  String get adminLeagueIdOptional;

  /// No description provided for @adminStaffCoaching.
  ///
  /// In en, this message translates to:
  /// **'Coaching'**
  String get adminStaffCoaching;

  /// No description provided for @adminStaffTechnical.
  ///
  /// In en, this message translates to:
  /// **'Technical'**
  String get adminStaffTechnical;

  /// No description provided for @adminStaffMedical.
  ///
  /// In en, this message translates to:
  /// **'Medical'**
  String get adminStaffMedical;

  /// No description provided for @adminStaffAdmin.
  ///
  /// In en, this message translates to:
  /// **'Administrative'**
  String get adminStaffAdmin;

  /// No description provided for @adminCompActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminCompActive;

  /// No description provided for @adminCompPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get adminCompPast;

  /// No description provided for @adminChildBoard.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get adminChildBoard;

  /// No description provided for @adminChildStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get adminChildStaff;

  /// No description provided for @adminChildTitles.
  ///
  /// In en, this message translates to:
  /// **'Titles'**
  String get adminChildTitles;

  /// No description provided for @adminChildCaptains.
  ///
  /// In en, this message translates to:
  /// **'Captains'**
  String get adminChildCaptains;

  /// No description provided for @adminChildCompetitions.
  ///
  /// In en, this message translates to:
  /// **'Competitions'**
  String get adminChildCompetitions;

  /// No description provided for @authWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to IQS'**
  String get authWelcomeTitle;

  /// No description provided for @authWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your first destination for everything Iraqi sports'**
  String get authWelcomeSubtitle;

  /// No description provided for @authLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLoginButton;

  /// No description provided for @authRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'Create a new account'**
  String get authRegisterButton;

  /// No description provided for @authSocialLoginLabel.
  ///
  /// In en, this message translates to:
  /// **'Log in with'**
  String get authSocialLoginLabel;

  /// No description provided for @authInvalidIraqiPhone.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid Iraqi phone number'**
  String get authInvalidIraqiPhone;

  /// No description provided for @authEnterPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get authEnterPhoneTitle;

  /// No description provided for @authEnterPhoneSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a verification code via SMS'**
  String get authEnterPhoneSubtitle;

  /// No description provided for @authContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get authContinue;

  /// No description provided for @authNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get authNameRequired;

  /// No description provided for @authCompleteProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get authCompleteProfileTitle;

  /// No description provided for @authTellUsMore.
  ///
  /// In en, this message translates to:
  /// **'Tell us more about you'**
  String get authTellUsMore;

  /// No description provided for @authNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get authNameLabel;

  /// No description provided for @authNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your full name'**
  String get authNameHint;

  /// No description provided for @authEmailOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get authEmailOptionalLabel;

  /// No description provided for @authSaveAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get authSaveAndContinue;

  /// No description provided for @authGenderOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender (optional)'**
  String get authGenderOptionalLabel;

  /// No description provided for @authGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get authGenderMale;

  /// No description provided for @authGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get authGenderFemale;

  /// No description provided for @authDobOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth (optional)'**
  String get authDobOptionalLabel;

  /// No description provided for @authSelectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get authSelectDate;

  /// No description provided for @authUpdateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get authUpdateRequiredTitle;

  /// No description provided for @authUpdateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get authUpdateAvailableTitle;

  /// No description provided for @authUpdateBody.
  ///
  /// In en, this message translates to:
  /// **'A new version of the app is available. Please update to get the latest features.'**
  String get authUpdateBody;

  /// No description provided for @authUpdateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get authUpdateNow;

  /// No description provided for @authLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get authLater;

  /// No description provided for @authOtpSixDigits.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code'**
  String get authOtpSixDigits;

  /// No description provided for @authOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get authOtpTitle;

  /// No description provided for @authOtpSentTo.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to'**
  String get authOtpSentTo;

  /// No description provided for @authDebugOtpFill.
  ///
  /// In en, this message translates to:
  /// **'Test code (Dev): {otp} — tap to fill'**
  String authDebugOtpFill(Object otp);

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get homeGreeting;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow the latest Iraqi sports news'**
  String get homeSubtitle;

  /// No description provided for @homeSectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'App Sections'**
  String get homeSectionsTitle;

  /// No description provided for @homeSectionTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get homeSectionTeams;

  /// No description provided for @homeLatestNewsTitle.
  ///
  /// In en, this message translates to:
  /// **'Latest News'**
  String get homeLatestNewsTitle;

  /// No description provided for @homeNoNews.
  ///
  /// In en, this message translates to:
  /// **'No news'**
  String get homeNoNews;

  /// No description provided for @homeMainNewsBadge.
  ///
  /// In en, this message translates to:
  /// **'Top Story'**
  String get homeMainNewsBadge;

  /// No description provided for @discoveryTypeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get discoveryTypeAll;

  /// No description provided for @discoveryTypeTeams.
  ///
  /// In en, this message translates to:
  /// **'Teams'**
  String get discoveryTypeTeams;

  /// No description provided for @discoveryTypePlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get discoveryTypePlayers;

  /// No description provided for @discoveryTypeClubs.
  ///
  /// In en, this message translates to:
  /// **'Clubs'**
  String get discoveryTypeClubs;

  /// No description provided for @discoveryTypeFanGroups.
  ///
  /// In en, this message translates to:
  /// **'Fan Groups'**
  String get discoveryTypeFanGroups;

  /// No description provided for @discoveryTypeMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get discoveryTypeMarket;

  /// No description provided for @discoverySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a team, player, club…'**
  String get discoverySearchHint;

  /// No description provided for @discoverySearchInIqs.
  ///
  /// In en, this message translates to:
  /// **'Search IQS'**
  String get discoverySearchInIqs;

  /// No description provided for @discoverySearchMinChars.
  ///
  /// In en, this message translates to:
  /// **'Type at least two characters to search'**
  String get discoverySearchMinChars;

  /// No description provided for @discoveryPageFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get discoveryPageFallbackTitle;

  /// No description provided for @discoveryErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Sorry'**
  String get discoveryErrorTitle;

  /// No description provided for @discoveryPageNotAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Page not available'**
  String get discoveryPageNotAvailableTitle;

  /// No description provided for @discoveryPageNotAvailableBody.
  ///
  /// In en, this message translates to:
  /// **'This page is not available right now'**
  String get discoveryPageNotAvailableBody;

  /// No description provided for @discoveryBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get discoveryBackToHome;

  /// No description provided for @matchesNavFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get matchesNavFilterAll;

  /// No description provided for @matchesNavFilterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get matchesNavFilterToday;

  /// No description provided for @matchesNavFilterTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get matchesNavFilterTomorrow;

  /// No description provided for @matchesNavFilterEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get matchesNavFilterEnded;

  /// No description provided for @matchesNavAllMatches.
  ///
  /// In en, this message translates to:
  /// **'All matches'**
  String get matchesNavAllMatches;

  /// No description provided for @matchesNavAllLeagues.
  ///
  /// In en, this message translates to:
  /// **'All leagues'**
  String get matchesNavAllLeagues;

  /// No description provided for @matchesNavSeason.
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get matchesNavSeason;

  /// No description provided for @matchesNavSelectSeason.
  ///
  /// In en, this message translates to:
  /// **'Select season'**
  String get matchesNavSelectSeason;

  /// No description provided for @matchesNavCurrentSeason.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get matchesNavCurrentSeason;

  /// No description provided for @matchesNavNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get matchesNavNoMatches;

  /// No description provided for @matchesNavStatusLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get matchesNavStatusLive;

  /// No description provided for @matchesNavStatusEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get matchesNavStatusEnded;

  /// No description provided for @matchesNavStatusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get matchesNavStatusNotStarted;

  /// No description provided for @matchesNavLeagues.
  ///
  /// In en, this message translates to:
  /// **'Leagues'**
  String get matchesNavLeagues;

  /// No description provided for @matchesNavNoLeagues.
  ///
  /// In en, this message translates to:
  /// **'No leagues'**
  String get matchesNavNoLeagues;

  /// No description provided for @matchesNavSeasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Season {season}'**
  String matchesNavSeasonLabel(Object season);

  /// No description provided for @matchesNavTabStandings.
  ///
  /// In en, this message translates to:
  /// **'Standings'**
  String get matchesNavTabStandings;

  /// No description provided for @matchesNavTabScorers.
  ///
  /// In en, this message translates to:
  /// **'Top scorers'**
  String get matchesNavTabScorers;

  /// No description provided for @matchesNavLeagueTitle.
  ///
  /// In en, this message translates to:
  /// **'League'**
  String get matchesNavLeagueTitle;

  /// No description provided for @matchesNavNoStandings.
  ///
  /// In en, this message translates to:
  /// **'No standings available'**
  String get matchesNavNoStandings;

  /// No description provided for @matchesNavNoScorers.
  ///
  /// In en, this message translates to:
  /// **'No top scorers'**
  String get matchesNavNoScorers;

  /// No description provided for @matchesNavGoals.
  ///
  /// In en, this message translates to:
  /// **'goals'**
  String get matchesNavGoals;

  /// No description provided for @matchesNavTabSquad.
  ///
  /// In en, this message translates to:
  /// **'Squad'**
  String get matchesNavTabSquad;

  /// No description provided for @matchesNavPosGoalkeeper.
  ///
  /// In en, this message translates to:
  /// **'Goalkeepers'**
  String get matchesNavPosGoalkeeper;

  /// No description provided for @matchesNavPosDefender.
  ///
  /// In en, this message translates to:
  /// **'Defenders'**
  String get matchesNavPosDefender;

  /// No description provided for @matchesNavPosMidfielder.
  ///
  /// In en, this message translates to:
  /// **'Midfielders'**
  String get matchesNavPosMidfielder;

  /// No description provided for @matchesNavPosAttacker.
  ///
  /// In en, this message translates to:
  /// **'Forwards'**
  String get matchesNavPosAttacker;

  /// No description provided for @matchesNavPosOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get matchesNavPosOther;

  /// No description provided for @matchesNavTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get matchesNavTeamTitle;

  /// No description provided for @matchesNavFoundedYear.
  ///
  /// In en, this message translates to:
  /// **'Founded {year}'**
  String matchesNavFoundedYear(Object year);

  /// No description provided for @matchesNavNoSquad.
  ///
  /// In en, this message translates to:
  /// **'No squad available'**
  String get matchesNavNoSquad;

  /// No description provided for @matchesNavPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Player'**
  String get matchesNavPlayerTitle;

  /// No description provided for @matchesNavNationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get matchesNavNationality;

  /// No description provided for @matchesNavDateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get matchesNavDateOfBirth;

  /// No description provided for @matchesNavHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get matchesNavHeight;

  /// No description provided for @matchesNavWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get matchesNavWeight;

  /// No description provided for @matchesNavBirthPlace.
  ///
  /// In en, this message translates to:
  /// **'Place of birth'**
  String get matchesNavBirthPlace;

  /// No description provided for @matchesNavStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get matchesNavStatus;

  /// No description provided for @matchesNavInjured.
  ///
  /// In en, this message translates to:
  /// **'Injured'**
  String get matchesNavInjured;

  /// No description provided for @matchesNavNoExtraInfo.
  ///
  /// In en, this message translates to:
  /// **'No additional information'**
  String get matchesNavNoExtraInfo;

  /// No description provided for @matchesNavColTeam.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get matchesNavColTeam;

  /// No description provided for @matchesNavColPlayed.
  ///
  /// In en, this message translates to:
  /// **'P'**
  String get matchesNavColPlayed;

  /// No description provided for @matchesNavColGoalDiff.
  ///
  /// In en, this message translates to:
  /// **'GD'**
  String get matchesNavColGoalDiff;

  /// No description provided for @matchesNavColPoints.
  ///
  /// In en, this message translates to:
  /// **'Pts'**
  String get matchesNavColPoints;

  /// No description provided for @matchDetailTabEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get matchDetailTabEvents;

  /// No description provided for @matchDetailTabDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get matchDetailTabDetails;

  /// No description provided for @matchDetailTabLineups.
  ///
  /// In en, this message translates to:
  /// **'Lineups'**
  String get matchDetailTabLineups;

  /// No description provided for @matchDetailTabStatistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get matchDetailTabStatistics;

  /// No description provided for @matchDetailTabStandings.
  ///
  /// In en, this message translates to:
  /// **'Standings'**
  String get matchDetailTabStandings;

  /// No description provided for @matchDetailTabScores.
  ///
  /// In en, this message translates to:
  /// **'Scores'**
  String get matchDetailTabScores;

  /// No description provided for @matchDetailTabNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get matchDetailTabNews;

  /// No description provided for @matchDetailTabFanZone.
  ///
  /// In en, this message translates to:
  /// **'Fan Zone'**
  String get matchDetailTabFanZone;

  /// No description provided for @matchDetailTabPredictions.
  ///
  /// In en, this message translates to:
  /// **'Predictions'**
  String get matchDetailTabPredictions;

  /// No description provided for @matchDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Match Details'**
  String get matchDetailTitle;

  /// No description provided for @matchDetailLikeUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update the like'**
  String get matchDetailLikeUpdateFailed;

  /// No description provided for @matchDetailStatusLive.
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get matchDetailStatusLive;

  /// No description provided for @matchDetailStatusFinished.
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get matchDetailStatusFinished;

  /// No description provided for @matchDetailStatusNotStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get matchDetailStatusNotStarted;

  /// No description provided for @matchDetailPeriodFirstHalf.
  ///
  /// In en, this message translates to:
  /// **'First half'**
  String get matchDetailPeriodFirstHalf;

  /// No description provided for @matchDetailPeriodFullTime.
  ///
  /// In en, this message translates to:
  /// **'Full time'**
  String get matchDetailPeriodFullTime;

  /// No description provided for @matchDetailPeriodExtraTime.
  ///
  /// In en, this message translates to:
  /// **'Extra time'**
  String get matchDetailPeriodExtraTime;

  /// No description provided for @matchDetailPeriodPenalties.
  ///
  /// In en, this message translates to:
  /// **'Penalties'**
  String get matchDetailPeriodPenalties;

  /// No description provided for @matchDetailScoresEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Period scores will appear once the match kicks off.'**
  String get matchDetailScoresEmptySubtitle;

  /// No description provided for @matchDetailInfoTournament.
  ///
  /// In en, this message translates to:
  /// **'Tournament'**
  String get matchDetailInfoTournament;

  /// No description provided for @matchDetailInfoRound.
  ///
  /// In en, this message translates to:
  /// **'Round'**
  String get matchDetailInfoRound;

  /// No description provided for @matchDetailInfoStadium.
  ///
  /// In en, this message translates to:
  /// **'Stadium'**
  String get matchDetailInfoStadium;

  /// No description provided for @matchDetailInfoStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get matchDetailInfoStatus;

  /// No description provided for @matchDetailEventsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No events'**
  String get matchDetailEventsEmptyTitle;

  /// No description provided for @matchDetailEventsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Match goals and cards will appear here'**
  String get matchDetailEventsEmptySubtitle;

  /// No description provided for @matchDetailEventSubOut.
  ///
  /// In en, this message translates to:
  /// **'Off: {name}'**
  String matchDetailEventSubOut(Object name);

  /// No description provided for @matchDetailEventAssist.
  ///
  /// In en, this message translates to:
  /// **'Assist: {name}'**
  String matchDetailEventAssist(Object name);

  /// No description provided for @matchDetailLineupsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Lineup unavailable'**
  String get matchDetailLineupsEmptyTitle;

  /// No description provided for @matchDetailLineupsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Both teams\' lineups will appear here'**
  String get matchDetailLineupsEmptySubtitle;

  /// No description provided for @matchDetailLineupCoach.
  ///
  /// In en, this message translates to:
  /// **'Coach: {name}'**
  String matchDetailLineupCoach(Object name);

  /// No description provided for @matchDetailLineupStarters.
  ///
  /// In en, this message translates to:
  /// **'Starters'**
  String get matchDetailLineupStarters;

  /// No description provided for @matchDetailLineupSubstitutes.
  ///
  /// In en, this message translates to:
  /// **'Substitutes'**
  String get matchDetailLineupSubstitutes;

  /// No description provided for @matchDetailStatsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No statistics'**
  String get matchDetailStatsEmptyTitle;

  /// No description provided for @matchDetailStatsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Match statistics will appear here'**
  String get matchDetailStatsEmptySubtitle;

  /// No description provided for @matchDetailStatBallPossession.
  ///
  /// In en, this message translates to:
  /// **'Ball possession'**
  String get matchDetailStatBallPossession;

  /// No description provided for @matchDetailStatTotalShots.
  ///
  /// In en, this message translates to:
  /// **'Total shots'**
  String get matchDetailStatTotalShots;

  /// No description provided for @matchDetailStatShotsOnGoal.
  ///
  /// In en, this message translates to:
  /// **'Shots on goal'**
  String get matchDetailStatShotsOnGoal;

  /// No description provided for @matchDetailStatShotsOffGoal.
  ///
  /// In en, this message translates to:
  /// **'Shots off goal'**
  String get matchDetailStatShotsOffGoal;

  /// No description provided for @matchDetailStatCornerKicks.
  ///
  /// In en, this message translates to:
  /// **'Corner kicks'**
  String get matchDetailStatCornerKicks;

  /// No description provided for @matchDetailStatOffsides.
  ///
  /// In en, this message translates to:
  /// **'Offsides'**
  String get matchDetailStatOffsides;

  /// No description provided for @matchDetailStatFouls.
  ///
  /// In en, this message translates to:
  /// **'Fouls'**
  String get matchDetailStatFouls;

  /// No description provided for @matchDetailStatYellowCards.
  ///
  /// In en, this message translates to:
  /// **'Yellow cards'**
  String get matchDetailStatYellowCards;

  /// No description provided for @matchDetailStatRedCards.
  ///
  /// In en, this message translates to:
  /// **'Red cards'**
  String get matchDetailStatRedCards;

  /// No description provided for @matchDetailStatGoalkeeperSaves.
  ///
  /// In en, this message translates to:
  /// **'Goalkeeper saves'**
  String get matchDetailStatGoalkeeperSaves;

  /// No description provided for @matchDetailStatPasses.
  ///
  /// In en, this message translates to:
  /// **'Passes'**
  String get matchDetailStatPasses;

  /// No description provided for @matchDetailStatPassesAccurate.
  ///
  /// In en, this message translates to:
  /// **'Accurate passes'**
  String get matchDetailStatPassesAccurate;

  /// No description provided for @matchDetailStandingsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No standings available'**
  String get matchDetailStandingsEmptyTitle;

  /// No description provided for @matchDetailNewsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No news'**
  String get matchDetailNewsEmptyTitle;

  /// No description provided for @matchDetailNewsEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Match news will appear here'**
  String get matchDetailNewsEmptySubtitle;

  /// No description provided for @matchSocialPredictionSaved.
  ///
  /// In en, this message translates to:
  /// **'Your prediction has been saved'**
  String get matchSocialPredictionSaved;

  /// No description provided for @matchSocialCrowdPredictions.
  ///
  /// In en, this message translates to:
  /// **'Crowd predictions'**
  String get matchSocialCrowdPredictions;

  /// No description provided for @matchSocialPredictionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} predictions'**
  String matchSocialPredictionsCount(Object count);

  /// No description provided for @matchSocialNoPredictions.
  ///
  /// In en, this message translates to:
  /// **'No predictions'**
  String get matchSocialNoPredictions;

  /// No description provided for @matchSocialTeamWins.
  ///
  /// In en, this message translates to:
  /// **'{team} wins'**
  String matchSocialTeamWins(Object team);

  /// No description provided for @matchSocialDraw.
  ///
  /// In en, this message translates to:
  /// **'Draw'**
  String get matchSocialDraw;

  /// No description provided for @matchSocialCorrectPredictionsLink.
  ///
  /// In en, this message translates to:
  /// **'Correct predictions ›'**
  String get matchSocialCorrectPredictionsLink;

  /// No description provided for @matchSocialEditPrediction.
  ///
  /// In en, this message translates to:
  /// **'Edit prediction'**
  String get matchSocialEditPrediction;

  /// No description provided for @matchSocialSavePrediction.
  ///
  /// In en, this message translates to:
  /// **'Save your prediction'**
  String get matchSocialSavePrediction;

  /// No description provided for @matchSocialPredictionsClosed.
  ///
  /// In en, this message translates to:
  /// **'Predictions are closed'**
  String get matchSocialPredictionsClosed;

  /// No description provided for @matchSocialYourPrediction.
  ///
  /// In en, this message translates to:
  /// **'Your prediction: {score}'**
  String matchSocialYourPrediction(Object score);

  /// No description provided for @matchSocialCorrectPredictionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Correct predictions'**
  String get matchSocialCorrectPredictionsTitle;

  /// No description provided for @matchSocialNoCorrectPredictions.
  ///
  /// In en, this message translates to:
  /// **'No correct predictions yet'**
  String get matchSocialNoCorrectPredictions;

  /// No description provided for @matchSocialUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get matchSocialUser;

  /// No description provided for @matchSocialExactScore.
  ///
  /// In en, this message translates to:
  /// **'Exact score'**
  String get matchSocialExactScore;

  /// No description provided for @matchSocialEditComment.
  ///
  /// In en, this message translates to:
  /// **'Edit comment'**
  String get matchSocialEditComment;

  /// No description provided for @matchSocialDeleteComment.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get matchSocialDeleteComment;

  /// No description provided for @matchSocialDeleteCommentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this comment?'**
  String get matchSocialDeleteCommentConfirm;

  /// No description provided for @matchSocialRepliesCount.
  ///
  /// In en, this message translates to:
  /// **'Replies ({count})'**
  String matchSocialRepliesCount(Object count);

  /// No description provided for @matchSocialReply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get matchSocialReply;

  /// No description provided for @matchSocialSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get matchSocialSortNewest;

  /// No description provided for @matchSocialSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get matchSocialSortOldest;

  /// No description provided for @matchSocialSortMostLiked.
  ///
  /// In en, this message translates to:
  /// **'Most liked'**
  String get matchSocialSortMostLiked;

  /// No description provided for @matchSocialSortMostActive.
  ///
  /// In en, this message translates to:
  /// **'Most active'**
  String get matchSocialSortMostActive;

  /// No description provided for @matchSocialNoComments.
  ///
  /// In en, this message translates to:
  /// **'No comments'**
  String get matchSocialNoComments;

  /// No description provided for @matchSocialBeFirstToComment.
  ///
  /// In en, this message translates to:
  /// **'Be the first to comment'**
  String get matchSocialBeFirstToComment;

  /// No description provided for @matchSocialAddCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment…'**
  String get matchSocialAddCommentHint;

  /// No description provided for @matchSocialContextMatch.
  ///
  /// In en, this message translates to:
  /// **'Match'**
  String get matchSocialContextMatch;

  /// No description provided for @matchSocialContextPredictions.
  ///
  /// In en, this message translates to:
  /// **'Predictions'**
  String get matchSocialContextPredictions;

  /// No description provided for @matchSocialCommentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get matchSocialCommentsTitle;

  /// No description provided for @matchSocialRepliesTitle.
  ///
  /// In en, this message translates to:
  /// **'Replies'**
  String get matchSocialRepliesTitle;

  /// No description provided for @matchSocialNoReplies.
  ///
  /// In en, this message translates to:
  /// **'No replies'**
  String get matchSocialNoReplies;

  /// No description provided for @matchSocialBeFirstToReply.
  ///
  /// In en, this message translates to:
  /// **'Be the first to reply'**
  String get matchSocialBeFirstToReply;

  /// No description provided for @matchSocialAddReplyHint.
  ///
  /// In en, this message translates to:
  /// **'Add a reply…'**
  String get matchSocialAddReplyHint;

  /// No description provided for @matchSocialNewsTitle.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get matchSocialNewsTitle;

  /// No description provided for @matchSocialNewsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to display the news'**
  String get matchSocialNewsUnavailable;

  /// No description provided for @marketNoListings.
  ///
  /// In en, this message translates to:
  /// **'No listings'**
  String get marketNoListings;

  /// No description provided for @marketSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search the marketplace…'**
  String get marketSearchHint;

  /// No description provided for @marketFeaturedChip.
  ///
  /// In en, this message translates to:
  /// **'⭐ Featured'**
  String get marketFeaturedChip;

  /// No description provided for @marketAllChip.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get marketAllChip;

  /// No description provided for @marketListingDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing details'**
  String get marketListingDetailsTitle;

  /// No description provided for @marketInfoName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get marketInfoName;

  /// No description provided for @marketInfoAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get marketInfoAge;

  /// No description provided for @marketInfoNationality.
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get marketInfoNationality;

  /// No description provided for @marketInfoCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get marketInfoCity;

  /// No description provided for @marketContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get marketContact;

  /// No description provided for @marketViewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} views'**
  String marketViewsCount(Object count);

  /// No description provided for @marketContactsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} contacts'**
  String marketContactsCount(Object count);

  /// No description provided for @marketCvLabel.
  ///
  /// In en, this message translates to:
  /// **'Résumé (CV)'**
  String get marketCvLabel;

  /// No description provided for @marketContactChannels.
  ///
  /// In en, this message translates to:
  /// **'Contact channels'**
  String get marketContactChannels;

  /// No description provided for @marketContactFetchError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load contact channels'**
  String get marketContactFetchError;

  /// No description provided for @marketNoDirectContact.
  ///
  /// In en, this message translates to:
  /// **'Please continue through the platform — no direct contact channels are available right now.'**
  String get marketNoDirectContact;

  /// No description provided for @marketChannelCall.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get marketChannelCall;

  /// No description provided for @marketChannelWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get marketChannelWhatsapp;

  /// No description provided for @marketChannelEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get marketChannelEmail;

  /// No description provided for @sellerStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get sellerStatusDraft;

  /// No description provided for @sellerStatusPendingPayment.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment'**
  String get sellerStatusPendingPayment;

  /// No description provided for @sellerStatusPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get sellerStatusPendingReview;

  /// No description provided for @sellerStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get sellerStatusPublished;

  /// No description provided for @sellerStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get sellerStatusRejected;

  /// No description provided for @sellerStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get sellerStatusExpired;

  /// No description provided for @sellerStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get sellerStatusSuspended;

  /// No description provided for @sellerMyStoreTitle.
  ///
  /// In en, this message translates to:
  /// **'My Store'**
  String get sellerMyStoreTitle;

  /// No description provided for @sellerCreateStoreHeadline.
  ///
  /// In en, this message translates to:
  /// **'Create your store'**
  String get sellerCreateStoreHeadline;

  /// No description provided for @sellerCreateStoreBody.
  ///
  /// In en, this message translates to:
  /// **'Create your store to list your ads in the marketplace. You\'ll automatically become a seller.'**
  String get sellerCreateStoreBody;

  /// No description provided for @sellerCreateStoreButton.
  ///
  /// In en, this message translates to:
  /// **'Create store'**
  String get sellerCreateStoreButton;

  /// No description provided for @sellerListingsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} listings'**
  String sellerListingsCount(Object count);

  /// No description provided for @sellerMyListings.
  ///
  /// In en, this message translates to:
  /// **'My Listings'**
  String get sellerMyListings;

  /// No description provided for @sellerAddListing.
  ///
  /// In en, this message translates to:
  /// **'Add listing'**
  String get sellerAddListing;

  /// No description provided for @sellerEditStore.
  ///
  /// In en, this message translates to:
  /// **'Edit store'**
  String get sellerEditStore;

  /// No description provided for @sellerStoreNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Store name is required'**
  String get sellerStoreNameRequired;

  /// No description provided for @sellerStoreCreated.
  ///
  /// In en, this message translates to:
  /// **'Store created'**
  String get sellerStoreCreated;

  /// No description provided for @sellerStoreNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Store name'**
  String get sellerStoreNameLabel;

  /// No description provided for @sellerStoreNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your store name'**
  String get sellerStoreNameHint;

  /// No description provided for @sellerStoreBioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio (optional)'**
  String get sellerStoreBioLabel;

  /// No description provided for @sellerStoreBioHint.
  ///
  /// In en, this message translates to:
  /// **'A short description of the store'**
  String get sellerStoreBioHint;

  /// No description provided for @sellerCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City (optional)'**
  String get sellerCityLabel;

  /// No description provided for @sellerCityHint.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get sellerCityHint;

  /// No description provided for @sellerPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get sellerPhoneLabel;

  /// No description provided for @sellerWhatsappLabel.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp (optional)'**
  String get sellerWhatsappLabel;

  /// No description provided for @sellerEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get sellerEmailLabel;

  /// No description provided for @sellerCreateStoreSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create store'**
  String get sellerCreateStoreSubmit;

  /// No description provided for @sellerDeleteListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete listing'**
  String get sellerDeleteListingTitle;

  /// No description provided for @sellerDeleteListingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String sellerDeleteListingConfirm(Object title);

  /// No description provided for @sellerNoListings.
  ///
  /// In en, this message translates to:
  /// **'No listings'**
  String get sellerNoListings;

  /// No description provided for @sellerNoListingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add the first listing to your store'**
  String get sellerNoListingsSubtitle;

  /// No description provided for @sellerPay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get sellerPay;

  /// No description provided for @sellerMedia.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get sellerMedia;

  /// No description provided for @sellerPayNow.
  ///
  /// In en, this message translates to:
  /// **'Pay now'**
  String get sellerPayNow;

  /// No description provided for @sellerTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get sellerTitleRequired;

  /// No description provided for @sellerSelectCategoryFirst.
  ///
  /// In en, this message translates to:
  /// **'Select a category first'**
  String get sellerSelectCategoryFirst;

  /// No description provided for @sellerFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get sellerFieldRequired;

  /// No description provided for @sellerCreatedCompletePayment.
  ///
  /// In en, this message translates to:
  /// **'Created — complete the payment'**
  String get sellerCreatedCompletePayment;

  /// No description provided for @sellerSavedAwaitingPayment.
  ///
  /// In en, this message translates to:
  /// **'Saved — awaiting payment'**
  String get sellerSavedAwaitingPayment;

  /// No description provided for @sellerSavedUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Saved — under review'**
  String get sellerSavedUnderReview;

  /// No description provided for @sellerEditListingTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit listing'**
  String get sellerEditListingTitle;

  /// No description provided for @sellerNewListingTitle.
  ///
  /// In en, this message translates to:
  /// **'New listing'**
  String get sellerNewListingTitle;

  /// No description provided for @sellerCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get sellerCategory;

  /// No description provided for @sellerTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sellerTitleLabel;

  /// No description provided for @sellerTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Listing title'**
  String get sellerTitleHint;

  /// No description provided for @sellerFullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get sellerFullNameLabel;

  /// No description provided for @sellerNationalityLabel.
  ///
  /// In en, this message translates to:
  /// **'Nationality (optional)'**
  String get sellerNationalityLabel;

  /// No description provided for @sellerAdditionalDetails.
  ///
  /// In en, this message translates to:
  /// **'Additional details'**
  String get sellerAdditionalDetails;

  /// No description provided for @sellerContactSection.
  ///
  /// In en, this message translates to:
  /// **'Contact info (optional)'**
  String get sellerContactSection;

  /// No description provided for @sellerContactPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get sellerContactPhone;

  /// No description provided for @sellerContactWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get sellerContactWhatsapp;

  /// No description provided for @sellerContactEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get sellerContactEmail;

  /// No description provided for @sellerSaveEdits.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get sellerSaveEdits;

  /// No description provided for @sellerPublishListing.
  ///
  /// In en, this message translates to:
  /// **'Publish listing'**
  String get sellerPublishListing;

  /// No description provided for @sellerPaidCategoryNote.
  ///
  /// In en, this message translates to:
  /// **'Paid category ({basePrice} {currency}) — payment is required before publishing.'**
  String sellerPaidCategoryNote(Object basePrice, Object currency);

  /// No description provided for @sellerDobLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth (optional)'**
  String get sellerDobLabel;

  /// No description provided for @sellerPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get sellerPickDate;

  /// No description provided for @sellerShowContactToBuyers.
  ///
  /// In en, this message translates to:
  /// **'Show contact info to buyers'**
  String get sellerShowContactToBuyers;

  /// No description provided for @sellerImageLimitReached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the image limit'**
  String get sellerImageLimitReached;

  /// No description provided for @sellerImageUploaded.
  ///
  /// In en, this message translates to:
  /// **'Image uploaded'**
  String get sellerImageUploaded;

  /// No description provided for @sellerListingMediaTitle.
  ///
  /// In en, this message translates to:
  /// **'Listing media'**
  String get sellerListingMediaTitle;

  /// No description provided for @sellerPhotosCountLimited.
  ///
  /// In en, this message translates to:
  /// **'Photos ({count} / {limit})'**
  String sellerPhotosCountLimited(Object count, Object limit);

  /// No description provided for @sellerPhotosCount.
  ///
  /// In en, this message translates to:
  /// **'Photos ({count})'**
  String sellerPhotosCount(Object count);

  /// No description provided for @sellerNoPhotosYet.
  ///
  /// In en, this message translates to:
  /// **'No photos yet'**
  String get sellerNoPhotosYet;

  /// No description provided for @sellerAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get sellerAddPhoto;

  /// No description provided for @sellerMediaAdminNote.
  ///
  /// In en, this message translates to:
  /// **'Videos and documents are currently managed from the admin dashboard.'**
  String get sellerMediaAdminNote;

  /// No description provided for @clubsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clubs'**
  String get clubsTitle;

  /// No description provided for @clubsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No clubs'**
  String get clubsEmpty;

  /// No description provided for @clubsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a club…'**
  String get clubsSearchHint;

  /// No description provided for @clubsTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get clubsTabOverview;

  /// No description provided for @clubsTabPlayers.
  ///
  /// In en, this message translates to:
  /// **'Players'**
  String get clubsTabPlayers;

  /// No description provided for @clubsVerifyBadge.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get clubsVerifyBadge;

  /// No description provided for @clubsInfoStadium.
  ///
  /// In en, this message translates to:
  /// **'Stadium'**
  String get clubsInfoStadium;

  /// No description provided for @clubsInfoCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get clubsInfoCity;

  /// No description provided for @clubsInfoFounded.
  ///
  /// In en, this message translates to:
  /// **'Founded'**
  String get clubsInfoFounded;

  /// No description provided for @clubsSectionTitles.
  ///
  /// In en, this message translates to:
  /// **'Titles'**
  String get clubsSectionTitles;

  /// No description provided for @clubsSectionBoard.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get clubsSectionBoard;

  /// No description provided for @clubsSectionStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get clubsSectionStaff;

  /// No description provided for @clubsSectionCaptains.
  ///
  /// In en, this message translates to:
  /// **'Captains'**
  String get clubsSectionCaptains;

  /// No description provided for @clubsSectionCompetitions.
  ///
  /// In en, this message translates to:
  /// **'Competitions'**
  String get clubsSectionCompetitions;

  /// No description provided for @clubsNoInfo.
  ///
  /// In en, this message translates to:
  /// **'No information available'**
  String get clubsNoInfo;

  /// No description provided for @clubsNoNews.
  ///
  /// In en, this message translates to:
  /// **'No news'**
  String get clubsNoNews;

  /// No description provided for @clubsNoMatches.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get clubsNoMatches;

  /// No description provided for @clubsNoSquad.
  ///
  /// In en, this message translates to:
  /// **'No squad available'**
  String get clubsNoSquad;

  /// No description provided for @clubsNewsTitle.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get clubsNewsTitle;

  /// No description provided for @clubsViewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} views'**
  String clubsViewsCount(Object count);

  /// No description provided for @clubsVerifyMethodMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get clubsVerifyMethodMessage;

  /// No description provided for @clubsVerifyMethodVoice.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get clubsVerifyMethodVoice;

  /// No description provided for @clubsVerifyMethodVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get clubsVerifyMethodVideo;

  /// No description provided for @clubsVerifySubmitted.
  ///
  /// In en, this message translates to:
  /// **'Verification request sent'**
  String get clubsVerifySubmitted;

  /// No description provided for @clubsVerifySheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Club verification request'**
  String get clubsVerifySheetTitle;

  /// No description provided for @clubsVerifySheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a verification method and add a note if you wish'**
  String get clubsVerifySheetSubtitle;

  /// No description provided for @clubsVerifyMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification method'**
  String get clubsVerifyMethodLabel;

  /// No description provided for @clubsVerifyNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get clubsVerifyNoteLabel;

  /// No description provided for @clubsVerifyNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Additional details'**
  String get clubsVerifyNoteHint;

  /// No description provided for @clubsVerifySubmit.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get clubsVerifySubmit;

  /// No description provided for @clubAdminDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Club Management'**
  String get clubAdminDashboardTitle;

  /// No description provided for @clubAdminNotAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'You don\'t manage any club'**
  String get clubAdminNotAdminTitle;

  /// No description provided for @clubAdminNotAdminBody.
  ///
  /// In en, this message translates to:
  /// **'Club management is granted by an administrator.'**
  String get clubAdminNotAdminBody;

  /// No description provided for @clubAdminEditClubData.
  ///
  /// In en, this message translates to:
  /// **'Edit club details'**
  String get clubAdminEditClubData;

  /// No description provided for @clubAdminManageNews.
  ///
  /// In en, this message translates to:
  /// **'Manage news'**
  String get clubAdminManageNews;

  /// No description provided for @clubAdminEditClubTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit club'**
  String get clubAdminEditClubTitle;

  /// No description provided for @clubAdminInvalidValue.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get clubAdminInvalidValue;

  /// No description provided for @clubAdminNoItems.
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get clubAdminNoItems;

  /// No description provided for @clubAdminAddFirstItem.
  ///
  /// In en, this message translates to:
  /// **'Add the first item'**
  String get clubAdminAddFirstItem;

  /// No description provided for @clubAdminDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"?'**
  String clubAdminDeleteConfirm(Object title);

  /// No description provided for @clubAdminNoNews.
  ///
  /// In en, this message translates to:
  /// **'No news'**
  String get clubAdminNoNews;

  /// No description provided for @clubAdminAddFirstNews.
  ///
  /// In en, this message translates to:
  /// **'Add the first article'**
  String get clubAdminAddFirstNews;

  /// No description provided for @clubAdminNewNews.
  ///
  /// In en, this message translates to:
  /// **'New article'**
  String get clubAdminNewNews;

  /// No description provided for @clubAdminEditNews.
  ///
  /// In en, this message translates to:
  /// **'Edit article'**
  String get clubAdminEditNews;

  /// No description provided for @clubAdminDeleteNews.
  ///
  /// In en, this message translates to:
  /// **'Delete article'**
  String get clubAdminDeleteNews;

  /// No description provided for @fanGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Fan Groups'**
  String get fanGroupsTitle;

  /// No description provided for @fanGroupsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No fan groups'**
  String get fanGroupsEmpty;

  /// No description provided for @fanGroupsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a fan group…'**
  String get fanGroupsSearchHint;

  /// No description provided for @fanGroupsOfficialBadge.
  ///
  /// In en, this message translates to:
  /// **'Official'**
  String get fanGroupsOfficialBadge;

  /// No description provided for @fanGroupsTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get fanGroupsTabOverview;

  /// No description provided for @fanGroupsTabPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get fanGroupsTabPhotos;

  /// No description provided for @fanGroupsTabVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get fanGroupsTabVideos;

  /// No description provided for @fanGroupsTabChants.
  ///
  /// In en, this message translates to:
  /// **'Chants'**
  String get fanGroupsTabChants;

  /// No description provided for @fanGroupsVerifyAction.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get fanGroupsVerifyAction;

  /// No description provided for @fanGroupsDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get fanGroupsDocuments;

  /// No description provided for @fanGroupsNoInfo.
  ///
  /// In en, this message translates to:
  /// **'No information available'**
  String get fanGroupsNoInfo;

  /// No description provided for @fanGroupsContact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get fanGroupsContact;

  /// No description provided for @fanGroupsNoVideos.
  ///
  /// In en, this message translates to:
  /// **'No videos'**
  String get fanGroupsNoVideos;

  /// No description provided for @fanGroupsNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos'**
  String get fanGroupsNoPhotos;

  /// No description provided for @fanGroupsVideoDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get fanGroupsVideoDefaultTitle;

  /// No description provided for @fanGroupsNoChants.
  ///
  /// In en, this message translates to:
  /// **'No chants'**
  String get fanGroupsNoChants;

  /// No description provided for @fanGroupsMethodMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get fanGroupsMethodMessage;

  /// No description provided for @fanGroupsMethodVoice.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get fanGroupsMethodVoice;

  /// No description provided for @fanGroupsMethodVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get fanGroupsMethodVideo;

  /// No description provided for @fanGroupsVerifySent.
  ///
  /// In en, this message translates to:
  /// **'Verification request sent'**
  String get fanGroupsVerifySent;

  /// No description provided for @fanGroupsVerifyTitle.
  ///
  /// In en, this message translates to:
  /// **'Fan Group Verification Request'**
  String get fanGroupsVerifyTitle;

  /// No description provided for @fanGroupsVerifyMethodLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification method'**
  String get fanGroupsVerifyMethodLabel;

  /// No description provided for @fanGroupsVerifyNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get fanGroupsVerifyNoteLabel;

  /// No description provided for @fanGroupsVerifyNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Additional details'**
  String get fanGroupsVerifyNoteHint;

  /// No description provided for @fanGroupsVerifySubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get fanGroupsVerifySubmit;

  /// No description provided for @fanAdminManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Fan Group'**
  String get fanAdminManageTitle;

  /// No description provided for @fanAdminNotAdminTitle.
  ///
  /// In en, this message translates to:
  /// **'You don\'t manage any fan group'**
  String get fanAdminNotAdminTitle;

  /// No description provided for @fanAdminNotAdminBody.
  ///
  /// In en, this message translates to:
  /// **'Fan group management is granted by an administrator.'**
  String get fanAdminNotAdminBody;

  /// No description provided for @fanAdminEditGroupData.
  ///
  /// In en, this message translates to:
  /// **'Edit fan group details'**
  String get fanAdminEditGroupData;

  /// No description provided for @fanAdminManageMedia.
  ///
  /// In en, this message translates to:
  /// **'Manage Media'**
  String get fanAdminManageMedia;

  /// No description provided for @fanAdminManageChants.
  ///
  /// In en, this message translates to:
  /// **'Manage Chants'**
  String get fanAdminManageChants;

  /// No description provided for @fanAdminManageDocuments.
  ///
  /// In en, this message translates to:
  /// **'Manage Documents'**
  String get fanAdminManageDocuments;

  /// No description provided for @fanAdminEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Fan Group'**
  String get fanAdminEditTitle;

  /// No description provided for @fanAdminInvalidValue.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get fanAdminInvalidValue;

  /// No description provided for @fanAdminPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get fanAdminPhotos;

  /// No description provided for @fanAdminVideos.
  ///
  /// In en, this message translates to:
  /// **'Videos'**
  String get fanAdminVideos;

  /// No description provided for @fanAdminMediaAddNote.
  ///
  /// In en, this message translates to:
  /// **'New media is added from the web dashboard. Here you can view and delete.'**
  String get fanAdminMediaAddNote;

  /// No description provided for @fanAdminNoMedia.
  ///
  /// In en, this message translates to:
  /// **'No media'**
  String get fanAdminNoMedia;

  /// No description provided for @fanAdminItem.
  ///
  /// In en, this message translates to:
  /// **'the item'**
  String get fanAdminItem;

  /// No description provided for @fanAdminVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get fanAdminVideo;

  /// No description provided for @fanAdminPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get fanAdminPhoto;

  /// No description provided for @fanAdminChantsAddNote.
  ///
  /// In en, this message translates to:
  /// **'Chants are added from the web dashboard. Here you can view and delete.'**
  String get fanAdminChantsAddNote;

  /// No description provided for @fanAdminNoChants.
  ///
  /// In en, this message translates to:
  /// **'No chants'**
  String get fanAdminNoChants;

  /// No description provided for @fanAdminDocumentsAddNote.
  ///
  /// In en, this message translates to:
  /// **'Documents are added from the web dashboard. Here you can view and delete.'**
  String get fanAdminDocumentsAddNote;

  /// No description provided for @fanAdminNoDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents'**
  String get fanAdminNoDocuments;

  /// No description provided for @fanAdminConfirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm deletion'**
  String get fanAdminConfirmDeleteTitle;

  /// No description provided for @fanAdminConfirmDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String fanAdminConfirmDeleteBody(Object name);

  /// No description provided for @paymentStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment'**
  String get paymentStatusPending;

  /// No description provided for @paymentStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get paymentStatusProcessing;

  /// No description provided for @paymentStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paymentStatusPaid;

  /// No description provided for @paymentStatusFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get paymentStatusFailed;

  /// No description provided for @paymentStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get paymentStatusCancelled;

  /// No description provided for @paymentStatusRefunded.
  ///
  /// In en, this message translates to:
  /// **'Refunded'**
  String get paymentStatusRefunded;

  /// No description provided for @paymentGatewayZaincash.
  ///
  /// In en, this message translates to:
  /// **'ZainCash'**
  String get paymentGatewayZaincash;

  /// No description provided for @paymentGatewayManual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get paymentGatewayManual;

  /// No description provided for @paymentHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get paymentHistoryTitle;

  /// No description provided for @paymentHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payments'**
  String get paymentHistoryEmpty;

  /// No description provided for @paymentMethodTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentMethodTitle;

  /// No description provided for @paymentMethodChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a payment method'**
  String get paymentMethodChoose;

  /// No description provided for @paymentMethodZaincashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pay with your ZainCash wallet'**
  String get paymentMethodZaincashSubtitle;

  /// No description provided for @paymentMethodFibSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan a QR code with the FIB app'**
  String get paymentMethodFibSubtitle;

  /// No description provided for @paymentMethodContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get paymentMethodContinue;

  /// No description provided for @paymentStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentStatusTitle;

  /// No description provided for @paymentNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment not found'**
  String get paymentNotFoundTitle;

  /// No description provided for @paymentNotFoundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'It may have expired or is unavailable.'**
  String get paymentNotFoundSubtitle;

  /// No description provided for @paymentBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get paymentBack;

  /// No description provided for @paymentSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment successful'**
  String get paymentSuccessTitle;

  /// No description provided for @paymentSuccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your payment was received. Your listing is now under review.'**
  String get paymentSuccessSubtitle;

  /// No description provided for @paymentCancelledTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment cancelled'**
  String get paymentCancelledTitle;

  /// No description provided for @paymentFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment failed'**
  String get paymentFailedTitle;

  /// No description provided for @paymentFailedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The payment did not complete. You can try again.'**
  String get paymentFailedSubtitle;

  /// No description provided for @paymentRefundedTitle.
  ///
  /// In en, this message translates to:
  /// **'Amount refunded'**
  String get paymentRefundedTitle;

  /// No description provided for @paymentRefundedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The amount has been returned to your account.'**
  String get paymentRefundedSubtitle;

  /// No description provided for @paymentExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment timed out'**
  String get paymentExpiredTitle;

  /// No description provided for @paymentExpiredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The time allowed to complete the payment has elapsed.'**
  String get paymentExpiredSubtitle;

  /// No description provided for @paymentPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Payment pending'**
  String get paymentPendingTitle;

  /// No description provided for @paymentPendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To complete the payment, start a new attempt.'**
  String get paymentPendingSubtitle;

  /// No description provided for @paymentAmountDue.
  ///
  /// In en, this message translates to:
  /// **'Amount due'**
  String get paymentAmountDue;

  /// No description provided for @paymentScanQr.
  ///
  /// In en, this message translates to:
  /// **'Scan the code with the FIB app'**
  String get paymentScanQr;

  /// No description provided for @paymentOpenFibApp.
  ///
  /// In en, this message translates to:
  /// **'Open FIB app'**
  String get paymentOpenFibApp;

  /// No description provided for @paymentOpenGateway.
  ///
  /// In en, this message translates to:
  /// **'Open payment gateway'**
  String get paymentOpenGateway;

  /// No description provided for @paymentExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in {time}'**
  String paymentExpiresIn(Object time);

  /// No description provided for @paymentCheckNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get paymentCheckNow;

  /// No description provided for @paymentWaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting payment confirmation…'**
  String get paymentWaitingConfirmation;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// No description provided for @notifEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notifEmpty;

  /// No description provided for @notifNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get notifNameRequired;

  /// No description provided for @notifEditProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get notifEditProfileTitle;

  /// No description provided for @notifNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get notifNameLabel;

  /// No description provided for @notifNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your full name'**
  String get notifNameHint;

  /// No description provided for @notifEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get notifEmailLabel;

  /// No description provided for @notifFavoriteClubLabel.
  ///
  /// In en, this message translates to:
  /// **'Favorite club (optional)'**
  String get notifFavoriteClubLabel;

  /// No description provided for @notifPickClub.
  ///
  /// In en, this message translates to:
  /// **'Select club'**
  String get notifPickClub;

  /// No description provided for @notifSearchClubHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a club…'**
  String get notifSearchClubHint;

  /// No description provided for @notifFavoriteTeamLabel.
  ///
  /// In en, this message translates to:
  /// **'Favorite team (optional)'**
  String get notifFavoriteTeamLabel;

  /// No description provided for @notifPickTeam.
  ///
  /// In en, this message translates to:
  /// **'Select team'**
  String get notifPickTeam;

  /// No description provided for @notifSearchTeamHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a team…'**
  String get notifSearchTeamHint;

  /// No description provided for @notifGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender (optional)'**
  String get notifGenderLabel;

  /// No description provided for @notifGenderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get notifGenderMale;

  /// No description provided for @notifGenderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get notifGenderFemale;

  /// No description provided for @notifDobLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth (optional)'**
  String get notifDobLabel;

  /// No description provided for @notifPickDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get notifPickDate;

  /// No description provided for @notifDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get notifDeleteAccount;

  /// No description provided for @notifDeleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'Your account will be permanently deleted. This action cannot be undone.'**
  String get notifDeleteAccountBody;

  /// No description provided for @notifDeleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get notifDeleteAccountConfirm;

  /// No description provided for @notifGroupAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get notifGroupAccount;

  /// No description provided for @notifRowProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get notifRowProfile;

  /// No description provided for @notifRowFavoriteClubs.
  ///
  /// In en, this message translates to:
  /// **'Favorite clubs'**
  String get notifRowFavoriteClubs;

  /// No description provided for @notifRowNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifRowNotifications;

  /// No description provided for @notifGroupServices.
  ///
  /// In en, this message translates to:
  /// **'My Services'**
  String get notifGroupServices;

  /// No description provided for @notifRowMyStore.
  ///
  /// In en, this message translates to:
  /// **'My Store'**
  String get notifRowMyStore;

  /// No description provided for @notifRowMyClub.
  ///
  /// In en, this message translates to:
  /// **'My Club'**
  String get notifRowMyClub;

  /// No description provided for @notifRowMyFanGroup.
  ///
  /// In en, this message translates to:
  /// **'My Fan Group'**
  String get notifRowMyFanGroup;

  /// No description provided for @notifRowPayments.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get notifRowPayments;

  /// No description provided for @notifGroupApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get notifGroupApp;

  /// No description provided for @notifRowLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get notifRowLanguage;

  /// No description provided for @notifLangArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get notifLangArabic;

  /// No description provided for @notifRowAbout.
  ///
  /// In en, this message translates to:
  /// **'About the app'**
  String get notifRowAbout;

  /// No description provided for @notifGroupSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get notifGroupSupport;

  /// No description provided for @notifRowHelpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help center'**
  String get notifRowHelpCenter;

  /// No description provided for @notifRowPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get notifRowPrivacy;

  /// No description provided for @notifDefaultUserName.
  ///
  /// In en, this message translates to:
  /// **'IQS user'**
  String get notifDefaultUserName;

  /// No description provided for @notifLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get notifLogout;

  /// No description provided for @notifVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0 · IQS'**
  String get notifVersion;

  /// No description provided for @notifDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notifDefaultTitle;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
