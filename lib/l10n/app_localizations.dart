import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_sw.dart';

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
    Locale('en'),
    Locale('fr'),
    Locale('sw'),
  ];

  /// No description provided for @appName.
  ///
  /// In sw, this message translates to:
  /// **'Moyo App'**
  String get appName;

  /// No description provided for @continueButton.
  ///
  /// In sw, this message translates to:
  /// **'ENDELEA'**
  String get continueButton;

  /// No description provided for @welcomeTitle.
  ///
  /// In sw, this message translates to:
  /// **'Karibu\nKatika Moyo App'**
  String get welcomeTitle;

  /// No description provided for @welcomeWhatFor.
  ///
  /// In sw, this message translates to:
  /// **'Hii ni App kwa ajili gani'**
  String get welcomeWhatFor;

  /// No description provided for @welcomeIntro.
  ///
  /// In sw, this message translates to:
  /// **'Moyo App ni chanzo chako cha habari,\nmafunzo na msukumo wa kila siku.\nTunakuletea maudhui ya moyo wazi.'**
  String get welcomeIntro;

  /// No description provided for @welcomeBenefitTitle.
  ///
  /// In sw, this message translates to:
  /// **'Humu utafaidika nini?'**
  String get welcomeBenefitTitle;

  /// No description provided for @welcomeBenefitBody.
  ///
  /// In sw, this message translates to:
  /// **'Pata maudhui mapya kila siku, jifunze,\nna ushirikiane na jamii yenye upendo\nna mioyo iliyojaa furaha na imani.'**
  String get welcomeBenefitBody;

  /// No description provided for @authTagline.
  ///
  /// In sw, this message translates to:
  /// **'Jifunze · Kukua · Kupenda'**
  String get authTagline;

  /// No description provided for @authWelcome.
  ///
  /// In sw, this message translates to:
  /// **'Karibu Moyo App'**
  String get authWelcome;

  /// No description provided for @authContinueWithGoogleHint.
  ///
  /// In sw, this message translates to:
  /// **'Endelea kwa akaunti yako ya Google'**
  String get authContinueWithGoogleHint;

  /// No description provided for @authGoogleButton.
  ///
  /// In sw, this message translates to:
  /// **'ENDELEA NA GOOGLE'**
  String get authGoogleButton;

  /// No description provided for @authTermsPrefix.
  ///
  /// In sw, this message translates to:
  /// **'Kwa kuendelea unakubaliana na '**
  String get authTermsPrefix;

  /// No description provided for @authTermsLink.
  ///
  /// In sw, this message translates to:
  /// **'Vigezo na masharti'**
  String get authTermsLink;

  /// No description provided for @authGoogleFailed.
  ///
  /// In sw, this message translates to:
  /// **'Imeshindwa kuingia na Google'**
  String get authGoogleFailed;

  /// No description provided for @authSignInError.
  ///
  /// In sw, this message translates to:
  /// **'Hitilafu imetokea wakati wa kuingia'**
  String get authSignInError;

  /// No description provided for @profileFillAll.
  ///
  /// In sw, this message translates to:
  /// **'Tafadhali jaza nafasi zote'**
  String get profileFillAll;

  /// No description provided for @saveFailed.
  ///
  /// In sw, this message translates to:
  /// **'Imeshindwa kuhifadhi: {error}'**
  String saveFailed(String error);

  /// No description provided for @searchHint.
  ///
  /// In sw, this message translates to:
  /// **'Tafuta…'**
  String get searchHint;

  /// No description provided for @profileSetupTitle.
  ///
  /// In sw, this message translates to:
  /// **'Kamilisha Taarifa Zako'**
  String get profileSetupTitle;

  /// No description provided for @profileSetupSubtitle.
  ///
  /// In sw, this message translates to:
  /// **'Tunahitaji taarifa chache kabla ya kuendelea'**
  String get profileSetupSubtitle;

  /// No description provided for @signedInAs.
  ///
  /// In sw, this message translates to:
  /// **'Umeingia kama {email}'**
  String signedInAs(String email);

  /// No description provided for @useAnotherGoogleAccount.
  ///
  /// In sw, this message translates to:
  /// **'Tumia akaunti nyingine ya Google'**
  String get useAnotherGoogleAccount;

  /// No description provided for @fullName.
  ///
  /// In sw, this message translates to:
  /// **'Jina Kamili'**
  String get fullName;

  /// No description provided for @country.
  ///
  /// In sw, this message translates to:
  /// **'Nchi'**
  String get country;

  /// No description provided for @chooseYourCountry.
  ///
  /// In sw, this message translates to:
  /// **'Chagua nchi yako'**
  String get chooseYourCountry;

  /// No description provided for @chooseCountry.
  ///
  /// In sw, this message translates to:
  /// **'Chagua Nchi'**
  String get chooseCountry;

  /// No description provided for @region.
  ///
  /// In sw, this message translates to:
  /// **'Mkoa'**
  String get region;

  /// No description provided for @chooseYourRegion.
  ///
  /// In sw, this message translates to:
  /// **'Chagua mkoa wako'**
  String get chooseYourRegion;

  /// No description provided for @chooseRegion.
  ///
  /// In sw, this message translates to:
  /// **'Chagua Mkoa'**
  String get chooseRegion;

  /// No description provided for @regionOrState.
  ///
  /// In sw, this message translates to:
  /// **'Mkoa / Jimbo'**
  String get regionOrState;

  /// No description provided for @chooseCountryFirst.
  ///
  /// In sw, this message translates to:
  /// **'Chagua nchi kwanza'**
  String get chooseCountryFirst;

  /// No description provided for @yourRegionOrState.
  ///
  /// In sw, this message translates to:
  /// **'Mkoa au jimbo lako'**
  String get yourRegionOrState;

  /// No description provided for @saveAndContinue.
  ///
  /// In sw, this message translates to:
  /// **'HIFADHI NA ENDELEA'**
  String get saveAndContinue;

  /// No description provided for @phoneNumber.
  ///
  /// In sw, this message translates to:
  /// **'Namba ya Simu'**
  String get phoneNumber;

  /// No description provided for @paymentLoadPackagesFailed.
  ///
  /// In sw, this message translates to:
  /// **'Imeshindwa kupakua vifurushi. Jaribu tena.'**
  String get paymentLoadPackagesFailed;

  /// No description provided for @errorOccurred.
  ///
  /// In sw, this message translates to:
  /// **'Hitilafu imetokea.'**
  String get errorOccurred;

  /// No description provided for @errorCheckNetwork.
  ///
  /// In sw, this message translates to:
  /// **'Hitilafu imetokea. Angalia mtandao na ujaribu tena.'**
  String get errorCheckNetwork;

  /// No description provided for @paymentFailedMessage.
  ///
  /// In sw, this message translates to:
  /// **'Malipo hayakufanikiwa.'**
  String get paymentFailedMessage;

  /// No description provided for @paymentNotConfirmedYet.
  ///
  /// In sw, this message translates to:
  /// **'Malipo bado hayajathibitishwa. Subiri kidogo.'**
  String get paymentNotConfirmedYet;

  /// No description provided for @paymentSupportPrompt.
  ///
  /// In sw, this message translates to:
  /// **'Unahitaji msaada wa malipo? Wasiliana nasi'**
  String get paymentSupportPrompt;

  /// No description provided for @paymentConfirmPhone.
  ///
  /// In sw, this message translates to:
  /// **'Thibitisha namba ya simu utakayolipia'**
  String get paymentConfirmPhone;

  /// No description provided for @paymentPinPrompt.
  ///
  /// In sw, this message translates to:
  /// **'Utapokea ujumbe wa kuweka PIN kwenye namba hii'**
  String get paymentPinPrompt;

  /// No description provided for @payNow.
  ///
  /// In sw, this message translates to:
  /// **'LIPIA SASA'**
  String get payNow;

  /// No description provided for @goBack.
  ///
  /// In sw, this message translates to:
  /// **'Rudi nyuma'**
  String get goBack;

  /// No description provided for @paymentPreparing.
  ///
  /// In sw, this message translates to:
  /// **'Inaandaa malipo…'**
  String get paymentPreparing;

  /// No description provided for @paymentCheckPhone.
  ///
  /// In sw, this message translates to:
  /// **'Angalia simu yako'**
  String get paymentCheckPhone;

  /// No description provided for @paymentWaitingBody.
  ///
  /// In sw, this message translates to:
  /// **'Tumetuma ombi la malipo kwenye simu yako. Weka PIN yako kukamilisha malipo. Programu itafunguka moja kwa moja baada ya malipo kukubaliwa.'**
  String get paymentWaitingBody;

  /// No description provided for @paymentDone.
  ///
  /// In sw, this message translates to:
  /// **'Nimemaliza malipo'**
  String get paymentDone;

  /// No description provided for @paymentFailedTitle.
  ///
  /// In sw, this message translates to:
  /// **'Malipo hayakufanikiwa'**
  String get paymentFailedTitle;

  /// No description provided for @tryAgain.
  ///
  /// In sw, this message translates to:
  /// **'Jaribu tena.'**
  String get tryAgain;

  /// No description provided for @tryAgainButton.
  ///
  /// In sw, this message translates to:
  /// **'JARIBU TENA'**
  String get tryAgainButton;

  /// No description provided for @paymentNoPackages.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna vifurushi vya usajili kwa sasa.\nTafadhali wasiliana na msimamizi.'**
  String get paymentNoPackages;

  /// No description provided for @paymentChoosePackage.
  ///
  /// In sw, this message translates to:
  /// **'Chagua kifurushi cha usajili'**
  String get paymentChoosePackage;

  /// No description provided for @showFewer.
  ///
  /// In sw, this message translates to:
  /// **'Onyesha vichache'**
  String get showFewer;

  /// No description provided for @paymentShowMorePackages.
  ///
  /// In sw, this message translates to:
  /// **'Ona vifurushi vingine ({count})'**
  String paymentShowMorePackages(int count);

  /// No description provided for @daysCount.
  ///
  /// In sw, this message translates to:
  /// **'{count} siku'**
  String daysCount(int count);

  /// No description provided for @homeTodayLesson.
  ///
  /// In sw, this message translates to:
  /// **'Somo la Leo!'**
  String get homeTodayLesson;

  /// No description provided for @homeHotTopics.
  ///
  /// In sw, this message translates to:
  /// **'Mada za Moto!'**
  String get homeHotTopics;

  /// No description provided for @homeGreeting.
  ///
  /// In sw, this message translates to:
  /// **'Habari, {name} 👋'**
  String homeGreeting(String name);

  /// No description provided for @userFallbackName.
  ///
  /// In sw, this message translates to:
  /// **'Mtumiaji'**
  String get userFallbackName;

  /// No description provided for @homeSubtitle.
  ///
  /// In sw, this message translates to:
  /// **'Karibu tujifunze kitu kipya leo'**
  String get homeSubtitle;

  /// No description provided for @searchCategoriesHint.
  ///
  /// In sw, this message translates to:
  /// **'Tafuta categories...'**
  String get searchCategoriesHint;

  /// No description provided for @search.
  ///
  /// In sw, this message translates to:
  /// **'Tafuta'**
  String get search;

  /// No description provided for @seeMore.
  ///
  /// In sw, this message translates to:
  /// **'Ona zaidi →'**
  String get seeMore;

  /// No description provided for @errorWithDetails.
  ///
  /// In sw, this message translates to:
  /// **'Hitilafu: {error}'**
  String errorWithDetails(String error);

  /// No description provided for @noCategoriesNow.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna categories kwa sasa.'**
  String get noCategoriesNow;

  /// No description provided for @noTopicsNow.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna mada kwa sasa.'**
  String get noTopicsNow;

  /// No description provided for @navExplore.
  ///
  /// In sw, this message translates to:
  /// **'Gundua'**
  String get navExplore;

  /// No description provided for @navSaved.
  ///
  /// In sw, this message translates to:
  /// **'Hifadhi'**
  String get navSaved;

  /// No description provided for @navChat.
  ///
  /// In sw, this message translates to:
  /// **'Gumzo'**
  String get navChat;

  /// No description provided for @navAccount.
  ///
  /// In sw, this message translates to:
  /// **'Akaunti'**
  String get navAccount;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In sw, this message translates to:
  /// **'Toka?'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmBody.
  ///
  /// In sw, this message translates to:
  /// **'Je, una uhakika unataka kutoka kwenye akaunti?'**
  String get logoutConfirmBody;

  /// No description provided for @no.
  ///
  /// In sw, this message translates to:
  /// **'Hapana'**
  String get no;

  /// No description provided for @yesLogout.
  ///
  /// In sw, this message translates to:
  /// **'Ndiyo, Toka'**
  String get yesLogout;

  /// No description provided for @location.
  ///
  /// In sw, this message translates to:
  /// **'Mahali'**
  String get location;

  /// No description provided for @accountActive.
  ///
  /// In sw, this message translates to:
  /// **'Akaunti Hai'**
  String get accountActive;

  /// No description provided for @accountInactive.
  ///
  /// In sw, this message translates to:
  /// **'Akaunti Imezimwa'**
  String get accountInactive;

  /// No description provided for @yourSubscription.
  ///
  /// In sw, this message translates to:
  /// **'Usajili Wako'**
  String get yourSubscription;

  /// No description provided for @statusActive.
  ///
  /// In sw, this message translates to:
  /// **'Hai'**
  String get statusActive;

  /// No description provided for @statusNone.
  ///
  /// In sw, this message translates to:
  /// **'Haina'**
  String get statusNone;

  /// No description provided for @subscriptionPackage.
  ///
  /// In sw, this message translates to:
  /// **'Kifurushi cha Usajili'**
  String get subscriptionPackage;

  /// No description provided for @expiresOn.
  ///
  /// In sw, this message translates to:
  /// **'Unaisha: {date}'**
  String expiresOn(String date);

  /// No description provided for @timeRemaining.
  ///
  /// In sw, this message translates to:
  /// **'Muda uliobaki'**
  String get timeRemaining;

  /// No description provided for @renewSubscription.
  ///
  /// In sw, this message translates to:
  /// **'Fanya Upya Usajili'**
  String get renewSubscription;

  /// No description provided for @noActiveSubscription.
  ///
  /// In sw, this message translates to:
  /// **'Huna usajili\nunaofanya kazi'**
  String get noActiveSubscription;

  /// No description provided for @subscribePrompt.
  ///
  /// In sw, this message translates to:
  /// **'Jiandikishe ili uendelee\nkufurahia maudhui yetu.'**
  String get subscribePrompt;

  /// No description provided for @subscribeNow.
  ///
  /// In sw, this message translates to:
  /// **'Jiandikishe Sasa'**
  String get subscribeNow;

  /// No description provided for @logout.
  ///
  /// In sw, this message translates to:
  /// **'Toka Kwenye Akaunti'**
  String get logout;

  /// No description provided for @savedToast.
  ///
  /// In sw, this message translates to:
  /// **'Imehifadhiwa!'**
  String get savedToast;

  /// No description provided for @removedToast.
  ///
  /// In sw, this message translates to:
  /// **'Imeondolewa!'**
  String get removedToast;

  /// No description provided for @audioTrack.
  ///
  /// In sw, this message translates to:
  /// **'Wimbo'**
  String get audioTrack;

  /// No description provided for @comments.
  ///
  /// In sw, this message translates to:
  /// **'Maoni'**
  String get comments;

  /// No description provided for @commentsWithCount.
  ///
  /// In sw, this message translates to:
  /// **'Maoni ({count})'**
  String commentsWithCount(int count);

  /// No description provided for @noCommentsYet.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna maoni bado.'**
  String get noCommentsYet;

  /// No description provided for @writeCommentHint.
  ///
  /// In sw, this message translates to:
  /// **'Andika maoni...'**
  String get writeCommentHint;

  /// No description provided for @savedTitle.
  ///
  /// In sw, this message translates to:
  /// **'Alamisho'**
  String get savedTitle;

  /// No description provided for @savedSubtitle.
  ///
  /// In sw, this message translates to:
  /// **'Mada ulizohifadhi kwa ajili ya baadaye'**
  String get savedSubtitle;

  /// No description provided for @savedEmpty.
  ///
  /// In sw, this message translates to:
  /// **'Hujachagua mada bado.'**
  String get savedEmpty;

  /// No description provided for @postNoLongerAvailable.
  ///
  /// In sw, this message translates to:
  /// **'Chapisho hili halipatikani tena.'**
  String get postNoLongerAvailable;

  /// No description provided for @notificationsTitle.
  ///
  /// In sw, this message translates to:
  /// **'Taarifa'**
  String get notificationsTitle;

  /// No description provided for @noNotificationsYet.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna taarifa bado.'**
  String get noNotificationsYet;

  /// No description provided for @searchFailed.
  ///
  /// In sw, this message translates to:
  /// **'Imeshindwa kutafuta: {error}'**
  String searchFailed(String error);

  /// No description provided for @openConversationFailed.
  ///
  /// In sw, this message translates to:
  /// **'Imeshindwa kufungua mazungumzo: {error}'**
  String openConversationFailed(String error);

  /// No description provided for @newMessage.
  ///
  /// In sw, this message translates to:
  /// **'Ujumbe Mpya'**
  String get newMessage;

  /// No description provided for @searchUserHint.
  ///
  /// In sw, this message translates to:
  /// **'Tafuta jina la mtumiaji...'**
  String get searchUserHint;

  /// No description provided for @newMessagePrompt.
  ///
  /// In sw, this message translates to:
  /// **'Andika jina la mtu unayetaka kumtumia ujumbe'**
  String get newMessagePrompt;

  /// No description provided for @noUserFound.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna mtumiaji aliyepatikana.'**
  String get noUserFound;

  /// No description provided for @searchCategoryPrompt.
  ///
  /// In sw, this message translates to:
  /// **'Andika jina la category kutafuta'**
  String get searchCategoryPrompt;

  /// No description provided for @categoryNotFound.
  ///
  /// In sw, this message translates to:
  /// **'Category haijapatikana'**
  String get categoryNotFound;

  /// No description provided for @passwordProtected.
  ///
  /// In sw, this message translates to:
  /// **'Imefungwa kwa password'**
  String get passwordProtected;

  /// No description provided for @searchTopicsHint.
  ///
  /// In sw, this message translates to:
  /// **'Tafuta mada...'**
  String get searchTopicsHint;

  /// No description provided for @searchTopicPrompt.
  ///
  /// In sw, this message translates to:
  /// **'Andika jina la mada kutafuta'**
  String get searchTopicPrompt;

  /// No description provided for @topicNotFound.
  ///
  /// In sw, this message translates to:
  /// **'Mada haijapatikana'**
  String get topicNotFound;

  /// No description provided for @categoryPasswordPrompt.
  ///
  /// In sw, this message translates to:
  /// **'Kipengele hiki kimefungwa. Weka password ili kuendelea.'**
  String get categoryPasswordPrompt;

  /// No description provided for @password.
  ///
  /// In sw, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @incorrectPassword.
  ///
  /// In sw, this message translates to:
  /// **'Password si sahihi'**
  String get incorrectPassword;

  /// No description provided for @cancel.
  ///
  /// In sw, this message translates to:
  /// **'Ghairi'**
  String get cancel;

  /// No description provided for @unlock.
  ///
  /// In sw, this message translates to:
  /// **'Fungua'**
  String get unlock;

  /// No description provided for @openAppFailed.
  ///
  /// In sw, this message translates to:
  /// **'Imeshindwa kufungua programu husika'**
  String get openAppFailed;

  /// No description provided for @callNumber.
  ///
  /// In sw, this message translates to:
  /// **'Piga simu'**
  String get callNumber;

  /// No description provided for @messageOnWhatsApp.
  ///
  /// In sw, this message translates to:
  /// **'Tuma ujumbe WhatsApp'**
  String get messageOnWhatsApp;

  /// No description provided for @copyNumber.
  ///
  /// In sw, this message translates to:
  /// **'Nakili namba'**
  String get copyNumber;

  /// No description provided for @numberCopied.
  ///
  /// In sw, this message translates to:
  /// **'Namba imenakiliwa'**
  String get numberCopied;

  /// No description provided for @sendFailed.
  ///
  /// In sw, this message translates to:
  /// **'Imeshindwa kutuma: {error}'**
  String sendFailed(String error);

  /// No description provided for @deleteFailed.
  ///
  /// In sw, this message translates to:
  /// **'Imeshindwa kufuta: {error}'**
  String deleteFailed(String error);

  /// No description provided for @pollResponsesCount.
  ///
  /// In sw, this message translates to:
  /// **'{count} wamejibu'**
  String pollResponsesCount(int count);

  /// No description provided for @pollAnswerHint.
  ///
  /// In sw, this message translates to:
  /// **'Andika jibu lako...'**
  String get pollAnswerHint;

  /// No description provided for @send.
  ///
  /// In sw, this message translates to:
  /// **'Tuma'**
  String get send;

  /// No description provided for @pollRetract.
  ///
  /// In sw, this message translates to:
  /// **'Futa jibu'**
  String get pollRetract;

  /// No description provided for @save.
  ///
  /// In sw, this message translates to:
  /// **'Hifadhi'**
  String get save;

  /// No description provided for @pollYourAnswer.
  ///
  /// In sw, this message translates to:
  /// **'Jibu lako:'**
  String get pollYourAnswer;

  /// No description provided for @edit.
  ///
  /// In sw, this message translates to:
  /// **'Badilisha'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In sw, this message translates to:
  /// **'Futa'**
  String get delete;

  /// No description provided for @pollQuestionHint.
  ///
  /// In sw, this message translates to:
  /// **'Andika swali lako...'**
  String get pollQuestionHint;

  /// No description provided for @pollMultipleChoice.
  ///
  /// In sw, this message translates to:
  /// **'Chaguo Nyingi'**
  String get pollMultipleChoice;

  /// No description provided for @pollOpenText.
  ///
  /// In sw, this message translates to:
  /// **'Jibu la Maandishi'**
  String get pollOpenText;

  /// No description provided for @pollOptionN.
  ///
  /// In sw, this message translates to:
  /// **'Chaguo {n}'**
  String pollOptionN(int n);

  /// No description provided for @pollAddOption.
  ///
  /// In sw, this message translates to:
  /// **'Ongeza chaguo'**
  String get pollAddOption;

  /// No description provided for @pollIncomplete.
  ///
  /// In sw, this message translates to:
  /// **'Jaza swali la kura kikamilifu'**
  String get pollIncomplete;

  /// No description provided for @timeJustNow.
  ///
  /// In sw, this message translates to:
  /// **'Sasa hivi'**
  String get timeJustNow;

  /// No description provided for @timeMinutes.
  ///
  /// In sw, this message translates to:
  /// **'{n} dak'**
  String timeMinutes(int n);

  /// No description provided for @timeHours.
  ///
  /// In sw, this message translates to:
  /// **'{n} saa'**
  String timeHours(int n);

  /// No description provided for @timeDays.
  ///
  /// In sw, this message translates to:
  /// **'{n} siku'**
  String timeDays(int n);

  /// No description provided for @timeWeeks.
  ///
  /// In sw, this message translates to:
  /// **'{n} wiki'**
  String timeWeeks(int n);

  /// No description provided for @shareAppText.
  ///
  /// In sw, this message translates to:
  /// **'Jiunge nami kwenye Moyo App — jifunze, kua na upende! Pakua hapa: {url}'**
  String shareAppText(String url);

  /// No description provided for @shareAppSubject.
  ///
  /// In sw, this message translates to:
  /// **'Pakua Moyo App'**
  String get shareAppSubject;

  /// No description provided for @shareReferralText.
  ///
  /// In sw, this message translates to:
  /// **'Jiunge nami kwenye Moyo App — jifunze, kua na upende! Tumia namba yangu ya mwaliko {code} unapojisajili. Pakua hapa: {url}'**
  String shareReferralText(String code, String url);

  /// No description provided for @messagesTitle.
  ///
  /// In sw, this message translates to:
  /// **'Ujumbe'**
  String get messagesTitle;

  /// No description provided for @noConversationsYet.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna mazungumzo bado.'**
  String get noConversationsYet;

  /// No description provided for @startConversation.
  ///
  /// In sw, this message translates to:
  /// **'Anza mazungumzo'**
  String get startConversation;

  /// No description provided for @deleteChatTitle.
  ///
  /// In sw, this message translates to:
  /// **'Futa mazungumzo na {name}?'**
  String deleteChatTitle(String name);

  /// No description provided for @deleteChatBody.
  ///
  /// In sw, this message translates to:
  /// **'Mazungumzo haya yatafutwa kwako tu. Mwenzako bado ataona ujumbe wote. Akikutumia ujumbe mpya, mazungumzo yatarudi yakiwa na ujumbe mpya tu.'**
  String get deleteChatBody;

  /// No description provided for @chatDeleted.
  ///
  /// In sw, this message translates to:
  /// **'Mazungumzo yamefutwa'**
  String get chatDeleted;

  /// No description provided for @noMessagesYet.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna ujumbe bado. Kuwa wa kwanza kuandika!'**
  String get noMessagesYet;

  /// No description provided for @noMessagesStartConversation.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna ujumbe bado. Anza mazungumzo!'**
  String get noMessagesStartConversation;

  /// No description provided for @writeMessageHint.
  ///
  /// In sw, this message translates to:
  /// **'Andika ujumbe...'**
  String get writeMessageHint;

  /// No description provided for @deleteMessageTitle.
  ///
  /// In sw, this message translates to:
  /// **'Futa ujumbe huu?'**
  String get deleteMessageTitle;

  /// No description provided for @cannotBeUndone.
  ///
  /// In sw, this message translates to:
  /// **'Hatua hii haiwezi kutenduliwa.'**
  String get cannotBeUndone;

  /// No description provided for @uploadingPercent.
  ///
  /// In sw, this message translates to:
  /// **'Inapakia {percent}%'**
  String uploadingPercent(int percent);

  /// No description provided for @attach.
  ///
  /// In sw, this message translates to:
  /// **'Ambatisha'**
  String get attach;

  /// No description provided for @poll.
  ///
  /// In sw, this message translates to:
  /// **'Kura'**
  String get poll;

  /// No description provided for @attachmentTypeNotAllowed.
  ///
  /// In sw, this message translates to:
  /// **'Aina hii ya faili hairuhusiwi hapa'**
  String get attachmentTypeNotAllowed;

  /// No description provided for @attachmentsMax.
  ///
  /// In sw, this message translates to:
  /// **'Huwezi kuongeza viambatisho zaidi ya {count}'**
  String attachmentsMax(int count);

  /// No description provided for @imagesMax.
  ///
  /// In sw, this message translates to:
  /// **'Unaweza kuweka picha {count} tu kwa pamoja'**
  String imagesMax(int count);

  /// No description provided for @oneVideoOnly.
  ///
  /// In sw, this message translates to:
  /// **'Unaweza kuweka video moja tu'**
  String get oneVideoOnly;

  /// No description provided for @videoMaxMinutes.
  ///
  /// In sw, this message translates to:
  /// **'Video isizidi dakika {minutes}'**
  String videoMaxMinutes(int minutes);

  /// No description provided for @fileTooLarge.
  ///
  /// In sw, this message translates to:
  /// **'Faili lisizidi MB {mb}'**
  String fileTooLarge(int mb);

  /// No description provided for @videoReadFailed.
  ///
  /// In sw, this message translates to:
  /// **'Imeshindwa kusoma video hii'**
  String get videoReadFailed;

  /// No description provided for @attachImages.
  ///
  /// In sw, this message translates to:
  /// **'Picha (hadi {count})'**
  String attachImages(int count);

  /// No description provided for @attachVideo.
  ///
  /// In sw, this message translates to:
  /// **'Video'**
  String get attachVideo;

  /// No description provided for @attachVideoMax.
  ///
  /// In sw, this message translates to:
  /// **'Video (isizidi dakika {minutes})'**
  String attachVideoMax(int minutes);

  /// No description provided for @attachAudio.
  ///
  /// In sw, this message translates to:
  /// **'Sauti'**
  String get attachAudio;

  /// No description provided for @attachAudioMax.
  ///
  /// In sw, this message translates to:
  /// **'Sauti (isizidi MB {mb})'**
  String attachAudioMax(int mb);

  /// No description provided for @attachPdf.
  ///
  /// In sw, this message translates to:
  /// **'PDF'**
  String get attachPdf;

  /// No description provided for @attachPdfMax.
  ///
  /// In sw, this message translates to:
  /// **'PDF (isizidi MB {mb})'**
  String attachPdfMax(int mb);

  /// No description provided for @pdfDocument.
  ///
  /// In sw, this message translates to:
  /// **'Hati ya PDF'**
  String get pdfDocument;

  /// No description provided for @videoPlaybackFailed.
  ///
  /// In sw, this message translates to:
  /// **'Imeshindwa kucheza video'**
  String get videoPlaybackFailed;

  /// No description provided for @audioPlaybackFailed.
  ///
  /// In sw, this message translates to:
  /// **'Imeshindwa kucheza sauti'**
  String get audioPlaybackFailed;

  /// No description provided for @audioClip.
  ///
  /// In sw, this message translates to:
  /// **'Sauti'**
  String get audioClip;

  /// No description provided for @openLinkFailed.
  ///
  /// In sw, this message translates to:
  /// **'Imeshindwa kufungua kiungo'**
  String get openLinkFailed;

  /// No description provided for @communityWall.
  ///
  /// In sw, this message translates to:
  /// **'Ukuta wa Jumuiya'**
  String get communityWall;

  /// No description provided for @whatsOnYourMind.
  ///
  /// In sw, this message translates to:
  /// **'Unafikiria nini?'**
  String get whatsOnYourMind;

  /// No description provided for @noPostsYet.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna chapisho bado. Kuwa wa kwanza kuchapisha!'**
  String get noPostsYet;

  /// No description provided for @deletePostTitle.
  ///
  /// In sw, this message translates to:
  /// **'Futa chapisho?'**
  String get deletePostTitle;

  /// No description provided for @writePost.
  ///
  /// In sw, this message translates to:
  /// **'Andika Chapisho'**
  String get writePost;

  /// No description provided for @publish.
  ///
  /// In sw, this message translates to:
  /// **'Chapisha'**
  String get publish;

  /// No description provided for @discussion.
  ///
  /// In sw, this message translates to:
  /// **'Mazungumzo'**
  String get discussion;

  /// No description provided for @sendMessage.
  ///
  /// In sw, this message translates to:
  /// **'Tuma ujumbe'**
  String get sendMessage;

  /// No description provided for @noRepliesYet.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna majibu bado. Kuwa wa kwanza!'**
  String get noRepliesYet;

  /// No description provided for @writeReplyHint.
  ///
  /// In sw, this message translates to:
  /// **'Andika jibu...'**
  String get writeReplyHint;

  /// No description provided for @addLink.
  ///
  /// In sw, this message translates to:
  /// **'Ongeza kiungo'**
  String get addLink;

  /// No description provided for @linkHint.
  ///
  /// In sw, this message translates to:
  /// **'https://mfano.com'**
  String get linkHint;

  /// No description provided for @add.
  ///
  /// In sw, this message translates to:
  /// **'Ongeza'**
  String get add;

  /// No description provided for @invalidLink.
  ///
  /// In sw, this message translates to:
  /// **'Kiungo si sahihi'**
  String get invalidLink;

  /// No description provided for @linksMax.
  ///
  /// In sw, this message translates to:
  /// **'Unaweza kuweka viungo {count} tu'**
  String linksMax(int count);

  /// No description provided for @exploreTitle.
  ///
  /// In sw, this message translates to:
  /// **'Chagua Mada\nyako pendwa'**
  String get exploreTitle;

  /// No description provided for @exploreSubtitle.
  ///
  /// In sw, this message translates to:
  /// **'Jifunze kwa Video, Sauti, Soma na Muziki'**
  String get exploreSubtitle;

  /// No description provided for @categoryGroupsTitle.
  ///
  /// In sw, this message translates to:
  /// **'Makundi'**
  String get categoryGroupsTitle;

  /// No description provided for @otherCategoriesTitle.
  ///
  /// In sw, this message translates to:
  /// **'Mada Nyingine'**
  String get otherCategoriesTitle;

  /// No description provided for @chooseSubcategory.
  ///
  /// In sw, this message translates to:
  /// **'Chagua kipengele unachotaka'**
  String get chooseSubcategory;

  /// No description provided for @chooseCategory.
  ///
  /// In sw, this message translates to:
  /// **'Chagua mada unayotaka'**
  String get chooseCategory;

  /// No description provided for @categoriesCount.
  ///
  /// In sw, this message translates to:
  /// **'Mada {count}'**
  String categoriesCount(int count);

  /// No description provided for @topicsFound.
  ///
  /// In sw, this message translates to:
  /// **'Mada {count} zilizopatikana'**
  String topicsFound(int count);

  /// No description provided for @noTopicsYet.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna mada bado'**
  String get noTopicsYet;

  /// No description provided for @noTopicsYetBody.
  ///
  /// In sw, this message translates to:
  /// **'Tunarudi hivi punde na mada mpya.'**
  String get noTopicsYetBody;

  /// No description provided for @tabTopics.
  ///
  /// In sw, this message translates to:
  /// **'Mada'**
  String get tabTopics;

  /// No description provided for @tabCommunity.
  ///
  /// In sw, this message translates to:
  /// **'Jamii'**
  String get tabCommunity;

  /// No description provided for @tabChat.
  ///
  /// In sw, this message translates to:
  /// **'Gumzo'**
  String get tabChat;

  /// No description provided for @tabGroups.
  ///
  /// In sw, this message translates to:
  /// **'Vikundi'**
  String get tabGroups;

  /// No description provided for @tabPosts.
  ///
  /// In sw, this message translates to:
  /// **'Machapisho'**
  String get tabPosts;

  /// No description provided for @tabMembers.
  ///
  /// In sw, this message translates to:
  /// **'Wanachama'**
  String get tabMembers;

  /// No description provided for @createGroup.
  ///
  /// In sw, this message translates to:
  /// **'Unda Kikundi'**
  String get createGroup;

  /// No description provided for @editGroup.
  ///
  /// In sw, this message translates to:
  /// **'Hariri Kikundi'**
  String get editGroup;

  /// No description provided for @deleteGroup.
  ///
  /// In sw, this message translates to:
  /// **'Futa Kikundi'**
  String get deleteGroup;

  /// No description provided for @noGroupsYet.
  ///
  /// In sw, this message translates to:
  /// **'Hakuna vikundi bado. Unda cha kwanza!'**
  String get noGroupsYet;

  /// No description provided for @membersCount.
  ///
  /// In sw, this message translates to:
  /// **'Wanachama {count}'**
  String membersCount(int count);

  /// No description provided for @groupNameRequired.
  ///
  /// In sw, this message translates to:
  /// **'Weka jina la kikundi'**
  String get groupNameRequired;

  /// No description provided for @groupPhotoHint.
  ///
  /// In sw, this message translates to:
  /// **'Gusa kuweka picha ya kikundi'**
  String get groupPhotoHint;

  /// No description provided for @groupName.
  ///
  /// In sw, this message translates to:
  /// **'Jina la kikundi'**
  String get groupName;

  /// No description provided for @groupDescription.
  ///
  /// In sw, this message translates to:
  /// **'Maelezo ya kikundi'**
  String get groupDescription;

  /// No description provided for @groupNotFound.
  ///
  /// In sw, this message translates to:
  /// **'Kikundi hiki hakipo tena.'**
  String get groupNotFound;

  /// No description provided for @joinGroup.
  ///
  /// In sw, this message translates to:
  /// **'Jiunge'**
  String get joinGroup;

  /// No description provided for @leaveGroup.
  ///
  /// In sw, this message translates to:
  /// **'Toka'**
  String get leaveGroup;

  /// No description provided for @leaveGroupTitle.
  ///
  /// In sw, this message translates to:
  /// **'Toka kwenye kikundi?'**
  String get leaveGroupTitle;

  /// No description provided for @leaveGroupBody.
  ///
  /// In sw, this message translates to:
  /// **'Hutaona tena machapisho na gumzo la kikundi hiki hadi ujiunge tena.'**
  String get leaveGroupBody;

  /// No description provided for @deleteGroupTitle.
  ///
  /// In sw, this message translates to:
  /// **'Futa kikundi?'**
  String get deleteGroupTitle;

  /// No description provided for @deleteGroupBody.
  ///
  /// In sw, this message translates to:
  /// **'Machapisho yote, gumzo na wanachama wa kikundi hiki watafutwa. Hatua hii haiwezi kutenduliwa.'**
  String get deleteGroupBody;

  /// No description provided for @joinGroupFailed.
  ///
  /// In sw, this message translates to:
  /// **'Imeshindwa kujiunga na kikundi hiki.'**
  String get joinGroupFailed;

  /// No description provided for @joinToSeePosts.
  ///
  /// In sw, this message translates to:
  /// **'Jiunge na kikundi ili kuona na kuandika machapisho na kushiriki gumzo.'**
  String get joinToSeePosts;

  /// No description provided for @groupOwner.
  ///
  /// In sw, this message translates to:
  /// **'Mmiliki'**
  String get groupOwner;

  /// No description provided for @groupCreatedBy.
  ///
  /// In sw, this message translates to:
  /// **'Kimeundwa na {name}'**
  String groupCreatedBy(String name);

  /// No description provided for @joinedAgo.
  ///
  /// In sw, this message translates to:
  /// **'Alijiunga {time}'**
  String joinedAgo(String time);

  /// No description provided for @removeMember.
  ///
  /// In sw, this message translates to:
  /// **'Ondoa'**
  String get removeMember;

  /// No description provided for @removeMemberTitle.
  ///
  /// In sw, this message translates to:
  /// **'Ondoa {name}?'**
  String removeMemberTitle(String name);

  /// No description provided for @removeMemberBody.
  ///
  /// In sw, this message translates to:
  /// **'Ataondolewa kwenye kikundi na hataweza kujiunga tena.'**
  String get removeMemberBody;

  /// No description provided for @language.
  ///
  /// In sw, this message translates to:
  /// **'Lugha'**
  String get language;

  /// No description provided for @chooseLanguage.
  ///
  /// In sw, this message translates to:
  /// **'Chagua lugha'**
  String get chooseLanguage;

  /// No description provided for @copy.
  ///
  /// In sw, this message translates to:
  /// **'Nakili'**
  String get copy;

  /// No description provided for @share.
  ///
  /// In sw, this message translates to:
  /// **'Shiriki'**
  String get share;

  /// No description provided for @referralCodeTitle.
  ///
  /// In sw, this message translates to:
  /// **'Namba Yako ya Mwaliko'**
  String get referralCodeTitle;

  /// No description provided for @referralCodeExplainer.
  ///
  /// In sw, this message translates to:
  /// **'Waalike marafiki kwa namba hii. Kila wanapolipia usajili, unapata {percent}% ya malipo yao kwenye pochi yako.'**
  String referralCodeExplainer(int percent);

  /// No description provided for @referralGenerate.
  ///
  /// In sw, this message translates to:
  /// **'Tengeneza namba yangu'**
  String get referralGenerate;

  /// No description provided for @referralGenerateFailed.
  ///
  /// In sw, this message translates to:
  /// **'Imeshindwa kutengeneza namba: {error}'**
  String referralGenerateFailed(String error);

  /// No description provided for @referralCodeCopied.
  ///
  /// In sw, this message translates to:
  /// **'Namba ya mwaliko imenakiliwa'**
  String get referralCodeCopied;

  /// No description provided for @referralCodeOptional.
  ///
  /// In sw, this message translates to:
  /// **'Namba ya mwaliko (si lazima)'**
  String get referralCodeOptional;

  /// No description provided for @referralCodeHint.
  ///
  /// In sw, this message translates to:
  /// **'Mf. AB2C'**
  String get referralCodeHint;

  /// No description provided for @referralErrorFormat.
  ///
  /// In sw, this message translates to:
  /// **'Namba ya mwaliko ina herufi au tarakimu 4.'**
  String get referralErrorFormat;

  /// No description provided for @referralErrorNotFound.
  ///
  /// In sw, this message translates to:
  /// **'Namba hii ya mwaliko haipo.'**
  String get referralErrorNotFound;

  /// No description provided for @referralErrorOwnCode.
  ///
  /// In sw, this message translates to:
  /// **'Huwezi kutumia namba yako mwenyewe.'**
  String get referralErrorOwnCode;

  /// No description provided for @referralErrorAlreadyUsed.
  ///
  /// In sw, this message translates to:
  /// **'Tayari umeshatumia namba ya mwaliko.'**
  String get referralErrorAlreadyUsed;

  /// No description provided for @referralErrorNotNew.
  ///
  /// In sw, this message translates to:
  /// **'Namba ya mwaliko ni kwa watumiaji wapya tu.'**
  String get referralErrorNotNew;

  /// No description provided for @referralErrorNoProfile.
  ///
  /// In sw, this message translates to:
  /// **'Kamilisha taarifa zako kwanza.'**
  String get referralErrorNoProfile;

  /// No description provided for @referralErrorGeneric.
  ///
  /// In sw, this message translates to:
  /// **'Imeshindwa kutumia namba ya mwaliko. Jaribu tena.'**
  String get referralErrorGeneric;

  /// No description provided for @walletTitle.
  ///
  /// In sw, this message translates to:
  /// **'Pochi Yangu'**
  String get walletTitle;

  /// No description provided for @walletBalance.
  ///
  /// In sw, this message translates to:
  /// **'Salio'**
  String get walletBalance;

  /// No description provided for @walletPending.
  ///
  /// In sw, this message translates to:
  /// **'Inasubiri kutolewa'**
  String get walletPending;

  /// No description provided for @walletTotalEarned.
  ///
  /// In sw, this message translates to:
  /// **'Jumla ya mapato'**
  String get walletTotalEarned;

  /// No description provided for @walletReferrals.
  ///
  /// In sw, this message translates to:
  /// **'Uliowaalika'**
  String get walletReferrals;

  /// No description provided for @walletHistory.
  ///
  /// In sw, this message translates to:
  /// **'Historia'**
  String get walletHistory;

  /// No description provided for @noWalletTransactionsYet.
  ///
  /// In sw, this message translates to:
  /// **'Bado hakuna miamala.'**
  String get noWalletTransactionsYet;

  /// No description provided for @withdrawalRequests.
  ///
  /// In sw, this message translates to:
  /// **'Maombi ya kutoa pesa'**
  String get withdrawalRequests;

  /// No description provided for @noWithdrawalsYet.
  ///
  /// In sw, this message translates to:
  /// **'Hujaomba kutoa pesa bado.'**
  String get noWithdrawalsYet;

  /// No description provided for @withdrawalStatusPending.
  ///
  /// In sw, this message translates to:
  /// **'Inasubiri'**
  String get withdrawalStatusPending;

  /// No description provided for @withdrawalStatusPaid.
  ///
  /// In sw, this message translates to:
  /// **'Imelipwa'**
  String get withdrawalStatusPaid;

  /// No description provided for @withdrawalStatusRejected.
  ///
  /// In sw, this message translates to:
  /// **'Imekataliwa'**
  String get withdrawalStatusRejected;

  /// No description provided for @txReferralCredit.
  ///
  /// In sw, this message translates to:
  /// **'Kamisheni ya mwaliko — {name}'**
  String txReferralCredit(String name);

  /// No description provided for @txWithdrawalRequested.
  ///
  /// In sw, this message translates to:
  /// **'Ombi la kutoa pesa'**
  String get txWithdrawalRequested;

  /// No description provided for @txWithdrawalRefunded.
  ///
  /// In sw, this message translates to:
  /// **'Ombi limekataliwa — pesa imerudishwa'**
  String get txWithdrawalRefunded;

  /// No description provided for @txWithdrawalPaid.
  ///
  /// In sw, this message translates to:
  /// **'Pesa imelipwa'**
  String get txWithdrawalPaid;

  /// No description provided for @withdraw.
  ///
  /// In sw, this message translates to:
  /// **'Toa Pesa'**
  String get withdraw;

  /// No description provided for @withdrawMinimum.
  ///
  /// In sw, this message translates to:
  /// **'Kiwango cha chini cha kutoa ni {amount}'**
  String withdrawMinimum(String amount);

  /// No description provided for @withdrawPhoneLabel.
  ///
  /// In sw, this message translates to:
  /// **'Namba ya simu / ya malipo'**
  String get withdrawPhoneLabel;

  /// No description provided for @withdrawAmountLabel.
  ///
  /// In sw, this message translates to:
  /// **'Kiasi'**
  String get withdrawAmountLabel;

  /// No description provided for @withdrawNotesLabel.
  ///
  /// In sw, this message translates to:
  /// **'Maelezo (si lazima)'**
  String get withdrawNotesLabel;

  /// No description provided for @withdrawIdTypeLabel.
  ///
  /// In sw, this message translates to:
  /// **'Aina ya kitambulisho'**
  String get withdrawIdTypeLabel;

  /// No description provided for @idTypeNational.
  ///
  /// In sw, this message translates to:
  /// **'Kitambulisho cha Taifa (NIDA)'**
  String get idTypeNational;

  /// No description provided for @idTypeDriversLicense.
  ///
  /// In sw, this message translates to:
  /// **'Leseni ya udereva'**
  String get idTypeDriversLicense;

  /// No description provided for @idTypePassport.
  ///
  /// In sw, this message translates to:
  /// **'Pasipoti'**
  String get idTypePassport;

  /// No description provided for @withdrawIdPhotoLabel.
  ///
  /// In sw, this message translates to:
  /// **'Picha ya kitambulisho'**
  String get withdrawIdPhotoLabel;

  /// No description provided for @takePhoto.
  ///
  /// In sw, this message translates to:
  /// **'Piga picha'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In sw, this message translates to:
  /// **'Chagua picha'**
  String get chooseFromGallery;

  /// No description provided for @withdrawSubmit.
  ///
  /// In sw, this message translates to:
  /// **'TUMA OMBI'**
  String get withdrawSubmit;

  /// No description provided for @withdrawSubmitted.
  ///
  /// In sw, this message translates to:
  /// **'Ombi lako limetumwa. Utajulishwa likishashughulikiwa.'**
  String get withdrawSubmitted;

  /// No description provided for @withdrawErrorBalance.
  ///
  /// In sw, this message translates to:
  /// **'Salio lako halitoshi.'**
  String get withdrawErrorBalance;

  /// No description provided for @withdrawErrorAmount.
  ///
  /// In sw, this message translates to:
  /// **'Weka kiasi sahihi.'**
  String get withdrawErrorAmount;

  /// No description provided for @withdrawErrorPhone.
  ///
  /// In sw, this message translates to:
  /// **'Weka namba sahihi ya simu.'**
  String get withdrawErrorPhone;

  /// No description provided for @withdrawErrorName.
  ///
  /// In sw, this message translates to:
  /// **'Weka jina lako kamili.'**
  String get withdrawErrorName;

  /// No description provided for @withdrawErrorIdPhoto.
  ///
  /// In sw, this message translates to:
  /// **'Weka picha ya kitambulisho chako.'**
  String get withdrawErrorIdPhoto;

  /// No description provided for @paymentUnderpaid.
  ///
  /// In sw, this message translates to:
  /// **'Kiasi kilicholipwa ni kidogo kuliko bei ya kifurushi, kwa hiyo usajili haujawashwa. Wasiliana nasi kwa msaada.'**
  String get paymentUnderpaid;
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
      <String>['en', 'fr', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
