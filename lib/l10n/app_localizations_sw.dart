// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get appName => 'Moyo App';

  @override
  String get continueButton => 'ENDELEA';

  @override
  String get welcomeTitle => 'Karibu\nKatika Moyo App';

  @override
  String get welcomeWhatFor => 'Hii ni App kwa ajili gani';

  @override
  String get welcomeIntro =>
      'Moyo App ni chanzo chako cha habari,\nmafunzo na msukumo wa kila siku.\nTunakuletea maudhui ya moyo wazi.';

  @override
  String get welcomeBenefitTitle => 'Humu utafaidika nini?';

  @override
  String get welcomeBenefitBody =>
      'Pata maudhui mapya kila siku, jifunze,\nna ushirikiane na jamii yenye upendo\nna mioyo iliyojaa furaha na imani.';

  @override
  String get authTagline => 'Jifunze · Kukua · Kupenda';

  @override
  String get authWelcome => 'Karibu Moyo App';

  @override
  String get authContinueWithGoogleHint => 'Endelea kwa akaunti yako ya Google';

  @override
  String get authGoogleButton => 'ENDELEA NA GOOGLE';

  @override
  String get authTermsPrefix => 'Kwa kuendelea unakubaliana na ';

  @override
  String get authTermsLink => 'Vigezo na masharti';

  @override
  String get authGoogleFailed => 'Imeshindwa kuingia na Google';

  @override
  String get authSignInError => 'Hitilafu imetokea wakati wa kuingia';

  @override
  String get profileFillAll => 'Tafadhali jaza nafasi zote';

  @override
  String saveFailed(String error) {
    return 'Imeshindwa kuhifadhi: $error';
  }

  @override
  String get searchHint => 'Tafuta…';

  @override
  String get profileSetupTitle => 'Kamilisha Taarifa Zako';

  @override
  String get profileSetupSubtitle =>
      'Tunahitaji taarifa chache kabla ya kuendelea';

  @override
  String signedInAs(String email) {
    return 'Umeingia kama $email';
  }

  @override
  String get useAnotherGoogleAccount => 'Tumia akaunti nyingine ya Google';

  @override
  String get fullName => 'Jina Kamili';

  @override
  String get country => 'Nchi';

  @override
  String get chooseYourCountry => 'Chagua nchi yako';

  @override
  String get chooseCountry => 'Chagua Nchi';

  @override
  String get region => 'Mkoa';

  @override
  String get chooseYourRegion => 'Chagua mkoa wako';

  @override
  String get chooseRegion => 'Chagua Mkoa';

  @override
  String get regionOrState => 'Mkoa / Jimbo';

  @override
  String get chooseCountryFirst => 'Chagua nchi kwanza';

  @override
  String get yourRegionOrState => 'Mkoa au jimbo lako';

  @override
  String get saveAndContinue => 'HIFADHI NA ENDELEA';

  @override
  String get phoneNumber => 'Namba ya Simu';

  @override
  String get paymentLoadPackagesFailed =>
      'Imeshindwa kupakua vifurushi. Jaribu tena.';

  @override
  String get errorOccurred => 'Hitilafu imetokea.';

  @override
  String get errorCheckNetwork =>
      'Hitilafu imetokea. Angalia mtandao na ujaribu tena.';

  @override
  String get paymentFailedMessage => 'Malipo hayakufanikiwa.';

  @override
  String get paymentNotConfirmedYet =>
      'Malipo bado hayajathibitishwa. Subiri kidogo.';

  @override
  String get paymentSupportPrompt =>
      'Unahitaji msaada wa malipo? Wasiliana nasi';

  @override
  String get paymentConfirmPhone => 'Thibitisha namba ya simu utakayolipia';

  @override
  String get paymentPinPrompt =>
      'Utapokea ujumbe wa kuweka PIN kwenye namba hii';

  @override
  String get payNow => 'LIPIA SASA';

  @override
  String get goBack => 'Rudi nyuma';

  @override
  String get paymentPreparing => 'Inaandaa malipo…';

  @override
  String get paymentCheckPhone => 'Angalia simu yako';

  @override
  String get paymentWaitingBody =>
      'Tumetuma ombi la malipo kwenye simu yako. Weka PIN yako kukamilisha malipo. Programu itafunguka moja kwa moja baada ya malipo kukubaliwa.';

  @override
  String get paymentDone => 'Nimemaliza malipo';

  @override
  String get paymentFailedTitle => 'Malipo hayakufanikiwa';

  @override
  String get tryAgain => 'Jaribu tena.';

  @override
  String get tryAgainButton => 'JARIBU TENA';

  @override
  String get paymentNoPackages =>
      'Hakuna vifurushi vya usajili kwa sasa.\nTafadhali wasiliana na msimamizi.';

  @override
  String get paymentChoosePackage => 'Chagua kifurushi cha usajili';

  @override
  String get showFewer => 'Onyesha vichache';

  @override
  String paymentShowMorePackages(int count) {
    return 'Ona vifurushi vingine ($count)';
  }

  @override
  String daysCount(int count) {
    return '$count siku';
  }

  @override
  String get homeTodayLesson => 'Somo la Leo!';

  @override
  String get homeHotTopics => 'Mada za Moto!';

  @override
  String homeGreeting(String name) {
    return 'Habari, $name 👋';
  }

  @override
  String get userFallbackName => 'Mtumiaji';

  @override
  String get homeSubtitle => 'Karibu tujifunze kitu kipya leo';

  @override
  String get searchCategoriesHint => 'Tafuta categories...';

  @override
  String get search => 'Tafuta';

  @override
  String get seeMore => 'Ona zaidi →';

  @override
  String errorWithDetails(String error) {
    return 'Hitilafu: $error';
  }

  @override
  String get noCategoriesNow => 'Hakuna categories kwa sasa.';

  @override
  String get noTopicsNow => 'Hakuna mada kwa sasa.';

  @override
  String get navExplore => 'Gundua';

  @override
  String get navSaved => 'Hifadhi';

  @override
  String get navChat => 'Gumzo';

  @override
  String get navAccount => 'Akaunti';

  @override
  String get logoutConfirmTitle => 'Toka?';

  @override
  String get logoutConfirmBody =>
      'Je, una uhakika unataka kutoka kwenye akaunti?';

  @override
  String get no => 'Hapana';

  @override
  String get yesLogout => 'Ndiyo, Toka';

  @override
  String get location => 'Mahali';

  @override
  String get accountActive => 'Akaunti Hai';

  @override
  String get accountInactive => 'Akaunti Imezimwa';

  @override
  String get yourSubscription => 'Usajili Wako';

  @override
  String get statusActive => 'Hai';

  @override
  String get statusNone => 'Haina';

  @override
  String get subscriptionPackage => 'Kifurushi cha Usajili';

  @override
  String expiresOn(String date) {
    return 'Unaisha: $date';
  }

  @override
  String get timeRemaining => 'Muda uliobaki';

  @override
  String get renewSubscription => 'Fanya Upya Usajili';

  @override
  String get noActiveSubscription => 'Huna usajili\nunaofanya kazi';

  @override
  String get subscribePrompt =>
      'Jiandikishe ili uendelee\nkufurahia maudhui yetu.';

  @override
  String get subscribeNow => 'Jiandikishe Sasa';

  @override
  String get logout => 'Toka Kwenye Akaunti';

  @override
  String get savedToast => 'Imehifadhiwa!';

  @override
  String get removedToast => 'Imeondolewa!';

  @override
  String get audioTrack => 'Wimbo';

  @override
  String get comments => 'Maoni';

  @override
  String commentsWithCount(int count) {
    return 'Maoni ($count)';
  }

  @override
  String get noCommentsYet => 'Hakuna maoni bado.';

  @override
  String get writeCommentHint => 'Andika maoni...';

  @override
  String get savedTitle => 'Alamisho';

  @override
  String get savedSubtitle => 'Mada ulizohifadhi kwa ajili ya baadaye';

  @override
  String get savedEmpty => 'Hujachagua mada bado.';

  @override
  String get postNoLongerAvailable => 'Chapisho hili halipatikani tena.';

  @override
  String get notificationsTitle => 'Taarifa';

  @override
  String get noNotificationsYet => 'Hakuna taarifa bado.';

  @override
  String searchFailed(String error) {
    return 'Imeshindwa kutafuta: $error';
  }

  @override
  String openConversationFailed(String error) {
    return 'Imeshindwa kufungua mazungumzo: $error';
  }

  @override
  String get newMessage => 'Ujumbe Mpya';

  @override
  String get searchUserHint => 'Tafuta jina la mtumiaji...';

  @override
  String get newMessagePrompt => 'Andika jina la mtu unayetaka kumtumia ujumbe';

  @override
  String get noUserFound => 'Hakuna mtumiaji aliyepatikana.';

  @override
  String get searchCategoryPrompt => 'Andika jina la category kutafuta';

  @override
  String get categoryNotFound => 'Category haijapatikana';

  @override
  String get passwordProtected => 'Imefungwa kwa password';

  @override
  String get searchTopicsHint => 'Tafuta mada...';

  @override
  String get searchTopicPrompt => 'Andika jina la mada kutafuta';

  @override
  String get topicNotFound => 'Mada haijapatikana';

  @override
  String get categoryPasswordPrompt =>
      'Kipengele hiki kimefungwa. Weka password ili kuendelea.';

  @override
  String get password => 'Password';

  @override
  String get incorrectPassword => 'Password si sahihi';

  @override
  String get cancel => 'Ghairi';

  @override
  String get unlock => 'Fungua';

  @override
  String get openAppFailed => 'Imeshindwa kufungua programu husika';

  @override
  String get callNumber => 'Piga simu';

  @override
  String get messageOnWhatsApp => 'Tuma ujumbe WhatsApp';

  @override
  String get copyNumber => 'Nakili namba';

  @override
  String get numberCopied => 'Namba imenakiliwa';

  @override
  String sendFailed(String error) {
    return 'Imeshindwa kutuma: $error';
  }

  @override
  String deleteFailed(String error) {
    return 'Imeshindwa kufuta: $error';
  }

  @override
  String pollResponsesCount(int count) {
    return '$count wamejibu';
  }

  @override
  String get pollAnswerHint => 'Andika jibu lako...';

  @override
  String get send => 'Tuma';

  @override
  String get pollRetract => 'Futa jibu';

  @override
  String get save => 'Hifadhi';

  @override
  String get pollYourAnswer => 'Jibu lako:';

  @override
  String get edit => 'Badilisha';

  @override
  String get delete => 'Futa';

  @override
  String get pollQuestionHint => 'Andika swali lako...';

  @override
  String get pollMultipleChoice => 'Chaguo Nyingi';

  @override
  String get pollOpenText => 'Jibu la Maandishi';

  @override
  String pollOptionN(int n) {
    return 'Chaguo $n';
  }

  @override
  String get pollAddOption => 'Ongeza chaguo';

  @override
  String get pollIncomplete => 'Jaza swali la kura kikamilifu';

  @override
  String get timeJustNow => 'Sasa hivi';

  @override
  String timeMinutes(int n) {
    return '$n dak';
  }

  @override
  String timeHours(int n) {
    return '$n saa';
  }

  @override
  String timeDays(int n) {
    return '$n siku';
  }

  @override
  String timeWeeks(int n) {
    return '$n wiki';
  }

  @override
  String shareAppText(String url) {
    return 'Jiunge nami kwenye Moyo App — jifunze, kua na upende! Pakua hapa: $url';
  }

  @override
  String get shareAppSubject => 'Pakua Moyo App';

  @override
  String shareReferralText(String code, String url) {
    return 'Jiunge nami kwenye Moyo App — jifunze, kua na upende! Tumia namba yangu ya mwaliko $code unapojisajili. Pakua hapa: $url';
  }

  @override
  String get messagesTitle => 'Ujumbe';

  @override
  String get noConversationsYet => 'Hakuna mazungumzo bado.';

  @override
  String get startConversation => 'Anza mazungumzo';

  @override
  String deleteChatTitle(String name) {
    return 'Futa mazungumzo na $name?';
  }

  @override
  String get deleteChatBody =>
      'Mazungumzo haya yatafutwa kwako tu. Mwenzako bado ataona ujumbe wote. Akikutumia ujumbe mpya, mazungumzo yatarudi yakiwa na ujumbe mpya tu.';

  @override
  String get chatDeleted => 'Mazungumzo yamefutwa';

  @override
  String get noMessagesYet => 'Hakuna ujumbe bado. Kuwa wa kwanza kuandika!';

  @override
  String get noMessagesStartConversation =>
      'Hakuna ujumbe bado. Anza mazungumzo!';

  @override
  String get writeMessageHint => 'Andika ujumbe...';

  @override
  String get deleteMessageTitle => 'Futa ujumbe huu?';

  @override
  String get cannotBeUndone => 'Hatua hii haiwezi kutenduliwa.';

  @override
  String uploadingPercent(int percent) {
    return 'Inapakia $percent%';
  }

  @override
  String get attach => 'Ambatisha';

  @override
  String get poll => 'Kura';

  @override
  String get attachmentTypeNotAllowed => 'Aina hii ya faili hairuhusiwi hapa';

  @override
  String attachmentsMax(int count) {
    return 'Huwezi kuongeza viambatisho zaidi ya $count';
  }

  @override
  String imagesMax(int count) {
    return 'Unaweza kuweka picha $count tu kwa pamoja';
  }

  @override
  String get oneVideoOnly => 'Unaweza kuweka video moja tu';

  @override
  String videoMaxMinutes(int minutes) {
    return 'Video isizidi dakika $minutes';
  }

  @override
  String fileTooLarge(int mb) {
    return 'Faili lisizidi MB $mb';
  }

  @override
  String get videoReadFailed => 'Imeshindwa kusoma video hii';

  @override
  String attachImages(int count) {
    return 'Picha (hadi $count)';
  }

  @override
  String get attachVideo => 'Video';

  @override
  String attachVideoMax(int minutes) {
    return 'Video (isizidi dakika $minutes)';
  }

  @override
  String get attachAudio => 'Sauti';

  @override
  String attachAudioMax(int mb) {
    return 'Sauti (isizidi MB $mb)';
  }

  @override
  String get attachPdf => 'PDF';

  @override
  String attachPdfMax(int mb) {
    return 'PDF (isizidi MB $mb)';
  }

  @override
  String get pdfDocument => 'Hati ya PDF';

  @override
  String get videoPlaybackFailed => 'Imeshindwa kucheza video';

  @override
  String get audioPlaybackFailed => 'Imeshindwa kucheza sauti';

  @override
  String get audioClip => 'Sauti';

  @override
  String get openLinkFailed => 'Imeshindwa kufungua kiungo';

  @override
  String get communityWall => 'Ukuta wa Jumuiya';

  @override
  String get whatsOnYourMind => 'Unafikiria nini?';

  @override
  String get noPostsYet => 'Hakuna chapisho bado. Kuwa wa kwanza kuchapisha!';

  @override
  String get deletePostTitle => 'Futa chapisho?';

  @override
  String get writePost => 'Andika Chapisho';

  @override
  String get publish => 'Chapisha';

  @override
  String get discussion => 'Mazungumzo';

  @override
  String get sendMessage => 'Tuma ujumbe';

  @override
  String get noRepliesYet => 'Hakuna majibu bado. Kuwa wa kwanza!';

  @override
  String get writeReplyHint => 'Andika jibu...';

  @override
  String get addLink => 'Ongeza kiungo';

  @override
  String get linkHint => 'https://mfano.com';

  @override
  String get add => 'Ongeza';

  @override
  String get invalidLink => 'Kiungo si sahihi';

  @override
  String linksMax(int count) {
    return 'Unaweza kuweka viungo $count tu';
  }

  @override
  String get exploreTitle => 'Chagua Mada\nyako pendwa';

  @override
  String get exploreSubtitle => 'Jifunze kwa Video, Sauti, Soma na Muziki';

  @override
  String get categoryGroupsTitle => 'Makundi';

  @override
  String get otherCategoriesTitle => 'Mada Nyingine';

  @override
  String get chooseSubcategory => 'Chagua kipengele unachotaka';

  @override
  String get chooseCategory => 'Chagua mada unayotaka';

  @override
  String categoriesCount(int count) {
    return 'Mada $count';
  }

  @override
  String topicsFound(int count) {
    return 'Mada $count zilizopatikana';
  }

  @override
  String get noTopicsYet => 'Hakuna mada bado';

  @override
  String get noTopicsYetBody => 'Tunarudi hivi punde na mada mpya.';

  @override
  String get tabTopics => 'Mada';

  @override
  String get tabCommunity => 'Jamii';

  @override
  String get tabChat => 'Gumzo';

  @override
  String get tabGroups => 'Vikundi';

  @override
  String get tabPosts => 'Machapisho';

  @override
  String get tabMembers => 'Wanachama';

  @override
  String get createGroup => 'Unda Kikundi';

  @override
  String get editGroup => 'Hariri Kikundi';

  @override
  String get deleteGroup => 'Futa Kikundi';

  @override
  String get noGroupsYet => 'Hakuna vikundi bado. Unda cha kwanza!';

  @override
  String membersCount(int count) {
    return 'Wanachama $count';
  }

  @override
  String get groupNameRequired => 'Weka jina la kikundi';

  @override
  String get groupPhotoHint => 'Gusa kuweka picha ya kikundi';

  @override
  String get groupName => 'Jina la kikundi';

  @override
  String get groupDescription => 'Maelezo ya kikundi';

  @override
  String get groupNotFound => 'Kikundi hiki hakipo tena.';

  @override
  String get joinGroup => 'Jiunge';

  @override
  String get leaveGroup => 'Toka';

  @override
  String get leaveGroupTitle => 'Toka kwenye kikundi?';

  @override
  String get leaveGroupBody =>
      'Hutaona tena machapisho na gumzo la kikundi hiki hadi ujiunge tena.';

  @override
  String get deleteGroupTitle => 'Futa kikundi?';

  @override
  String get deleteGroupBody =>
      'Machapisho yote, gumzo na wanachama wa kikundi hiki watafutwa. Hatua hii haiwezi kutenduliwa.';

  @override
  String get joinGroupFailed => 'Imeshindwa kujiunga na kikundi hiki.';

  @override
  String get joinToSeePosts =>
      'Jiunge na kikundi ili kuona na kuandika machapisho na kushiriki gumzo.';

  @override
  String get groupOwner => 'Mmiliki';

  @override
  String groupCreatedBy(String name) {
    return 'Kimeundwa na $name';
  }

  @override
  String joinedAgo(String time) {
    return 'Alijiunga $time';
  }

  @override
  String get removeMember => 'Ondoa';

  @override
  String removeMemberTitle(String name) {
    return 'Ondoa $name?';
  }

  @override
  String get removeMemberBody =>
      'Ataondolewa kwenye kikundi na hataweza kujiunga tena.';

  @override
  String get language => 'Lugha';

  @override
  String get chooseLanguage => 'Chagua lugha';

  @override
  String get copy => 'Nakili';

  @override
  String get share => 'Shiriki';

  @override
  String get referralCodeTitle => 'Namba Yako ya Mwaliko';

  @override
  String referralCodeExplainer(int percent) {
    return 'Waalike marafiki kwa namba hii. Kila wanapolipia usajili, unapata $percent% ya malipo yao kwenye pochi yako.';
  }

  @override
  String get referralGenerate => 'Tengeneza namba yangu';

  @override
  String referralGenerateFailed(String error) {
    return 'Imeshindwa kutengeneza namba: $error';
  }

  @override
  String get referralCodeCopied => 'Namba ya mwaliko imenakiliwa';

  @override
  String get referralCodeOptional => 'Namba ya mwaliko (si lazima)';

  @override
  String get referralCodeHint => 'Mf. AB2C';

  @override
  String get referralErrorFormat =>
      'Namba ya mwaliko ina herufi au tarakimu 4.';

  @override
  String get referralErrorNotFound => 'Namba hii ya mwaliko haipo.';

  @override
  String get referralErrorOwnCode => 'Huwezi kutumia namba yako mwenyewe.';

  @override
  String get referralErrorAlreadyUsed => 'Tayari umeshatumia namba ya mwaliko.';

  @override
  String get referralErrorNotNew =>
      'Namba ya mwaliko ni kwa watumiaji wapya tu.';

  @override
  String get referralErrorNoProfile => 'Kamilisha taarifa zako kwanza.';

  @override
  String get referralErrorGeneric =>
      'Imeshindwa kutumia namba ya mwaliko. Jaribu tena.';

  @override
  String get walletTitle => 'Pochi Yangu';

  @override
  String get walletBalance => 'Salio';

  @override
  String get walletPending => 'Inasubiri kutolewa';

  @override
  String get walletTotalEarned => 'Jumla ya mapato';

  @override
  String get walletReferrals => 'Uliowaalika';

  @override
  String get walletHistory => 'Historia';

  @override
  String get noWalletTransactionsYet => 'Bado hakuna miamala.';

  @override
  String get withdrawalRequests => 'Maombi ya kutoa pesa';

  @override
  String get noWithdrawalsYet => 'Hujaomba kutoa pesa bado.';

  @override
  String get withdrawalStatusPending => 'Inasubiri';

  @override
  String get withdrawalStatusPaid => 'Imelipwa';

  @override
  String get withdrawalStatusRejected => 'Imekataliwa';

  @override
  String txReferralCredit(String name) {
    return 'Kamisheni ya mwaliko — $name';
  }

  @override
  String get txWithdrawalRequested => 'Ombi la kutoa pesa';

  @override
  String get txWithdrawalRefunded => 'Ombi limekataliwa — pesa imerudishwa';

  @override
  String get txWithdrawalPaid => 'Pesa imelipwa';

  @override
  String get withdraw => 'Toa Pesa';

  @override
  String withdrawMinimum(String amount) {
    return 'Kiwango cha chini cha kutoa ni $amount';
  }

  @override
  String get withdrawPhoneLabel => 'Namba ya simu / ya malipo';

  @override
  String get withdrawAmountLabel => 'Kiasi';

  @override
  String get withdrawNotesLabel => 'Maelezo (si lazima)';

  @override
  String get withdrawIdTypeLabel => 'Aina ya kitambulisho';

  @override
  String get idTypeNational => 'Kitambulisho cha Taifa (NIDA)';

  @override
  String get idTypeDriversLicense => 'Leseni ya udereva';

  @override
  String get idTypePassport => 'Pasipoti';

  @override
  String get withdrawIdPhotoLabel => 'Picha ya kitambulisho';

  @override
  String get takePhoto => 'Piga picha';

  @override
  String get chooseFromGallery => 'Chagua picha';

  @override
  String get withdrawSubmit => 'TUMA OMBI';

  @override
  String get withdrawSubmitted =>
      'Ombi lako limetumwa. Utajulishwa likishashughulikiwa.';

  @override
  String get withdrawErrorBalance => 'Salio lako halitoshi.';

  @override
  String get withdrawErrorAmount => 'Weka kiasi sahihi.';

  @override
  String get withdrawErrorPhone => 'Weka namba sahihi ya simu.';

  @override
  String get withdrawErrorName => 'Weka jina lako kamili.';

  @override
  String get withdrawErrorIdPhoto => 'Weka picha ya kitambulisho chako.';

  @override
  String get paymentUnderpaid =>
      'Kiasi kilicholipwa ni kidogo kuliko bei ya kifurushi, kwa hiyo usajili haujawashwa. Wasiliana nasi kwa msaada.';
}
