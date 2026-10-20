// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Moyo App';

  @override
  String get continueButton => 'CONTINUE';

  @override
  String get welcomeTitle => 'Welcome\nto Moyo App';

  @override
  String get welcomeWhatFor => 'What is this app for?';

  @override
  String get welcomeIntro =>
      'Moyo App is your source of news,\nlearning and daily inspiration.\nWe bring you heartfelt content.';

  @override
  String get welcomeBenefitTitle => 'What will you gain here?';

  @override
  String get welcomeBenefitBody =>
      'Get fresh content every day, learn,\nand connect with a loving community\nfull of joy and faith.';

  @override
  String get authTagline => 'Learn · Grow · Love';

  @override
  String get authWelcome => 'Welcome to Moyo App';

  @override
  String get authContinueWithGoogleHint => 'Continue with your Google account';

  @override
  String get authGoogleButton => 'CONTINUE WITH GOOGLE';

  @override
  String get authTermsPrefix => 'By continuing you agree to the ';

  @override
  String get authTermsLink => 'Terms and conditions';

  @override
  String get authGoogleFailed => 'Google sign-in failed';

  @override
  String get authSignInError => 'An error occurred while signing in';

  @override
  String get profileFillAll => 'Please fill in all fields';

  @override
  String saveFailed(String error) {
    return 'Could not save: $error';
  }

  @override
  String get searchHint => 'Search…';

  @override
  String get profileSetupTitle => 'Complete Your Details';

  @override
  String get profileSetupSubtitle =>
      'We need a few details before you continue';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get useAnotherGoogleAccount => 'Use another Google account';

  @override
  String get fullName => 'Full Name';

  @override
  String get country => 'Country';

  @override
  String get chooseYourCountry => 'Choose your country';

  @override
  String get chooseCountry => 'Choose Country';

  @override
  String get region => 'Region';

  @override
  String get chooseYourRegion => 'Choose your region';

  @override
  String get chooseRegion => 'Choose Region';

  @override
  String get regionOrState => 'Region / State';

  @override
  String get chooseCountryFirst => 'Choose a country first';

  @override
  String get yourRegionOrState => 'Your region or state';

  @override
  String get saveAndContinue => 'SAVE AND CONTINUE';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get paymentLoadPackagesFailed =>
      'Could not load packages. Please try again.';

  @override
  String get errorOccurred => 'An error occurred.';

  @override
  String get errorCheckNetwork =>
      'An error occurred. Check your connection and try again.';

  @override
  String get paymentFailedMessage => 'The payment was not successful.';

  @override
  String get paymentNotConfirmedYet =>
      'Payment not confirmed yet. Please wait a moment.';

  @override
  String get paymentSupportPrompt => 'Need help with payment? Contact us';

  @override
  String get paymentConfirmPhone =>
      'Confirm the phone number you will pay with';

  @override
  String get paymentPinPrompt =>
      'You will receive a prompt to enter your PIN on this number';

  @override
  String get payNow => 'PAY NOW';

  @override
  String get goBack => 'Go back';

  @override
  String get paymentPreparing => 'Preparing payment…';

  @override
  String get paymentCheckPhone => 'Check your phone';

  @override
  String get paymentWaitingBody =>
      'We have sent a payment request to your phone. Enter your PIN to complete the payment. The app will open automatically once the payment is accepted.';

  @override
  String get paymentDone => 'I have completed the payment';

  @override
  String get paymentFailedTitle => 'Payment unsuccessful';

  @override
  String get tryAgain => 'Please try again.';

  @override
  String get tryAgainButton => 'TRY AGAIN';

  @override
  String get paymentNoPackages =>
      'No subscription packages available right now.\nPlease contact the administrator.';

  @override
  String get paymentChoosePackage => 'Choose a subscription package';

  @override
  String get showFewer => 'Show fewer';

  @override
  String paymentShowMorePackages(int count) {
    return 'See other packages ($count)';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get homeTodayLesson => 'Today\'s Lesson!';

  @override
  String get homeHotTopics => 'Hot Topics!';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name 👋';
  }

  @override
  String get userFallbackName => 'User';

  @override
  String get homeSubtitle => 'Let\'s learn something new today';

  @override
  String get searchCategoriesHint => 'Search categories...';

  @override
  String get search => 'Search';

  @override
  String get seeMore => 'See more →';

  @override
  String errorWithDetails(String error) {
    return 'Error: $error';
  }

  @override
  String get noCategoriesNow => 'No categories right now.';

  @override
  String get noTopicsNow => 'No topics right now.';

  @override
  String get navExplore => 'Explore';

  @override
  String get navSaved => 'Saved';

  @override
  String get navChat => 'Chat';

  @override
  String get navAccount => 'Account';

  @override
  String get logoutConfirmTitle => 'Sign out?';

  @override
  String get logoutConfirmBody =>
      'Are you sure you want to sign out of your account?';

  @override
  String get no => 'No';

  @override
  String get yesLogout => 'Yes, sign out';

  @override
  String get location => 'Location';

  @override
  String get accountActive => 'Account Active';

  @override
  String get accountInactive => 'Account Inactive';

  @override
  String get yourSubscription => 'Your Subscription';

  @override
  String get statusActive => 'Active';

  @override
  String get statusNone => 'None';

  @override
  String get subscriptionPackage => 'Subscription Package';

  @override
  String expiresOn(String date) {
    return 'Expires: $date';
  }

  @override
  String get timeRemaining => 'Time remaining';

  @override
  String get renewSubscription => 'Renew Subscription';

  @override
  String get noActiveSubscription => 'You don\'t have an\nactive subscription';

  @override
  String get subscribePrompt => 'Subscribe to keep\nenjoying our content.';

  @override
  String get subscribeNow => 'Subscribe Now';

  @override
  String get logout => 'Sign Out';

  @override
  String get savedToast => 'Saved!';

  @override
  String get removedToast => 'Removed!';

  @override
  String get audioTrack => 'Track';

  @override
  String get comments => 'Comments';

  @override
  String commentsWithCount(int count) {
    return 'Comments ($count)';
  }

  @override
  String get noCommentsYet => 'No comments yet.';

  @override
  String get writeCommentHint => 'Write a comment...';

  @override
  String get savedTitle => 'Bookmarks';

  @override
  String get savedSubtitle => 'Topics you saved for later';

  @override
  String get savedEmpty => 'You haven\'t saved any topics yet.';

  @override
  String get postNoLongerAvailable => 'This post is no longer available.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get noNotificationsYet => 'No notifications yet.';

  @override
  String searchFailed(String error) {
    return 'Search failed: $error';
  }

  @override
  String openConversationFailed(String error) {
    return 'Could not open the conversation: $error';
  }

  @override
  String get newMessage => 'New Message';

  @override
  String get searchUserHint => 'Search for a user by name...';

  @override
  String get newMessagePrompt =>
      'Type the name of the person you want to message';

  @override
  String get noUserFound => 'No user found.';

  @override
  String get searchCategoryPrompt => 'Type a category name to search';

  @override
  String get categoryNotFound => 'Category not found';

  @override
  String get passwordProtected => 'Password protected';

  @override
  String get searchTopicsHint => 'Search topics...';

  @override
  String get searchTopicPrompt => 'Type a topic name to search';

  @override
  String get topicNotFound => 'Topic not found';

  @override
  String get categoryPasswordPrompt =>
      'This category is protected. Enter the password to continue.';

  @override
  String get password => 'Password';

  @override
  String get incorrectPassword => 'Incorrect password';

  @override
  String get cancel => 'Cancel';

  @override
  String get unlock => 'Unlock';

  @override
  String get openAppFailed => 'Could not open the app';

  @override
  String get callNumber => 'Call';

  @override
  String get messageOnWhatsApp => 'Message on WhatsApp';

  @override
  String get copyNumber => 'Copy number';

  @override
  String get numberCopied => 'Number copied';

  @override
  String sendFailed(String error) {
    return 'Could not send: $error';
  }

  @override
  String deleteFailed(String error) {
    return 'Could not delete: $error';
  }

  @override
  String pollResponsesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count responses',
      one: '1 response',
    );
    return '$_temp0';
  }

  @override
  String get pollAnswerHint => 'Write your answer...';

  @override
  String get send => 'Send';

  @override
  String get pollRetract => 'Remove answer';

  @override
  String get save => 'Save';

  @override
  String get pollYourAnswer => 'Your answer:';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get pollQuestionHint => 'Write your question...';

  @override
  String get pollMultipleChoice => 'Multiple Choice';

  @override
  String get pollOpenText => 'Text Answer';

  @override
  String pollOptionN(int n) {
    return 'Option $n';
  }

  @override
  String get pollAddOption => 'Add option';

  @override
  String get pollIncomplete => 'Complete the poll question';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutes(int n) {
    return '$n min';
  }

  @override
  String timeHours(int n) {
    return '$n h';
  }

  @override
  String timeDays(int n) {
    return '$n d';
  }

  @override
  String timeWeeks(int n) {
    return '$n w';
  }

  @override
  String shareAppText(String url) {
    return 'Join me on Moyo App — learn, grow and love! Download it here: $url';
  }

  @override
  String get shareAppSubject => 'Download Moyo App';

  @override
  String shareReferralText(String code, String url) {
    return 'Join me on Moyo App — learn, grow and love! Use my referral code $code when you sign up. Download it here: $url';
  }

  @override
  String get messagesTitle => 'Messages';

  @override
  String get noConversationsYet => 'No conversations yet.';

  @override
  String get startConversation => 'Start a conversation';

  @override
  String deleteChatTitle(String name) {
    return 'Delete chat with $name?';
  }

  @override
  String get deleteChatBody =>
      'This chat will be deleted for you only. The other person will still see all messages. If they send you a new message, the chat comes back with only the new messages.';

  @override
  String get chatDeleted => 'Chat deleted';

  @override
  String get noMessagesYet => 'No messages yet. Be the first to write!';

  @override
  String get noMessagesStartConversation =>
      'No messages yet. Start the conversation!';

  @override
  String get writeMessageHint => 'Write a message...';

  @override
  String get deleteMessageTitle => 'Delete this message?';

  @override
  String get cannotBeUndone => 'This action cannot be undone.';

  @override
  String uploadingPercent(int percent) {
    return 'Uploading $percent%';
  }

  @override
  String get attach => 'Attach';

  @override
  String get poll => 'Poll';

  @override
  String get attachmentTypeNotAllowed => 'This file type is not allowed here';

  @override
  String attachmentsMax(int count) {
    return 'You cannot add more than $count attachments';
  }

  @override
  String imagesMax(int count) {
    return 'You can add only $count images at once';
  }

  @override
  String get oneVideoOnly => 'You can add only one video';

  @override
  String videoMaxMinutes(int minutes) {
    return 'Video must not exceed $minutes minutes';
  }

  @override
  String fileTooLarge(int mb) {
    return 'File must not exceed $mb MB';
  }

  @override
  String get videoReadFailed => 'Could not read this video';

  @override
  String attachImages(int count) {
    return 'Photos (up to $count)';
  }

  @override
  String get attachVideo => 'Video';

  @override
  String attachVideoMax(int minutes) {
    return 'Video (max $minutes min)';
  }

  @override
  String get attachAudio => 'Audio';

  @override
  String attachAudioMax(int mb) {
    return 'Audio (max $mb MB)';
  }

  @override
  String get attachPdf => 'PDF';

  @override
  String attachPdfMax(int mb) {
    return 'PDF (max $mb MB)';
  }

  @override
  String get pdfDocument => 'PDF document';

  @override
  String get videoPlaybackFailed => 'Could not play the video';

  @override
  String get audioPlaybackFailed => 'Could not play the audio';

  @override
  String get audioClip => 'Audio clip';

  @override
  String get openLinkFailed => 'Could not open the link';

  @override
  String get communityWall => 'Community Wall';

  @override
  String get whatsOnYourMind => 'What\'s on your mind?';

  @override
  String get noPostsYet => 'No posts yet. Be the first to post!';

  @override
  String get deletePostTitle => 'Delete post?';

  @override
  String get writePost => 'Write a Post';

  @override
  String get publish => 'Post';

  @override
  String get discussion => 'Discussion';

  @override
  String get sendMessage => 'Send message';

  @override
  String get noRepliesYet => 'No replies yet. Be the first!';

  @override
  String get writeReplyHint => 'Write a reply...';

  @override
  String get addLink => 'Add link';

  @override
  String get linkHint => 'https://example.com';

  @override
  String get add => 'Add';

  @override
  String get invalidLink => 'Invalid link';

  @override
  String linksMax(int count) {
    return 'You can add only $count links';
  }

  @override
  String get exploreTitle => 'Choose your\nfavourite topic';

  @override
  String get exploreSubtitle => 'Learn through Video, Audio, Reading and Music';

  @override
  String get categoryGroupsTitle => 'Groups';

  @override
  String get otherCategoriesTitle => 'Other Categories';

  @override
  String get chooseSubcategory => 'Choose the section you want';

  @override
  String get chooseCategory => 'Choose the category you want';

  @override
  String categoriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count categories',
      one: '1 category',
    );
    return '$_temp0';
  }

  @override
  String topicsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count topics found',
      one: '1 topic found',
    );
    return '$_temp0';
  }

  @override
  String get noTopicsYet => 'No topics yet';

  @override
  String get noTopicsYetBody => 'We\'ll be back soon with new topics.';

  @override
  String get tabTopics => 'Topics';

  @override
  String get tabCommunity => 'Community';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabGroups => 'Groups';

  @override
  String get tabPosts => 'Posts';

  @override
  String get tabMembers => 'Members';

  @override
  String get createGroup => 'Create Group';

  @override
  String get editGroup => 'Edit Group';

  @override
  String get deleteGroup => 'Delete Group';

  @override
  String get noGroupsYet => 'No groups yet. Create the first one!';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get groupNameRequired => 'Enter a group name';

  @override
  String get groupPhotoHint => 'Tap to set a group picture';

  @override
  String get groupName => 'Group name';

  @override
  String get groupDescription => 'Group description';

  @override
  String get groupNotFound => 'This group no longer exists.';

  @override
  String get joinGroup => 'Join';

  @override
  String get leaveGroup => 'Leave';

  @override
  String get leaveGroupTitle => 'Leave this group?';

  @override
  String get leaveGroupBody =>
      'You won\'t see this group\'s posts and chat until you join again.';

  @override
  String get deleteGroupTitle => 'Delete group?';

  @override
  String get deleteGroupBody =>
      'All of this group\'s posts, chat and members will be deleted. This cannot be undone.';

  @override
  String get joinGroupFailed => 'Could not join this group.';

  @override
  String get joinToSeePosts =>
      'Join the group to see and write posts and take part in the chat.';

  @override
  String get groupOwner => 'Owner';

  @override
  String groupCreatedBy(String name) {
    return 'Created by $name';
  }

  @override
  String joinedAgo(String time) {
    return 'Joined $time';
  }

  @override
  String get removeMember => 'Remove';

  @override
  String removeMemberTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get removeMemberBody =>
      'They will be removed from the group and cannot join again.';

  @override
  String get language => 'Language';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get copy => 'Copy';

  @override
  String get share => 'Share';

  @override
  String get referralCodeTitle => 'Your Referral Code';

  @override
  String referralCodeExplainer(int percent) {
    return 'Invite friends with this code. Every time they pay for a subscription, you get $percent% of their payment in your wallet.';
  }

  @override
  String get referralGenerate => 'Generate my code';

  @override
  String referralGenerateFailed(String error) {
    return 'Could not generate the code: $error';
  }

  @override
  String get referralCodeCopied => 'Referral code copied';

  @override
  String get referralCodeOptional => 'Referral code (optional)';

  @override
  String get referralCodeHint => 'e.g. AB2C';

  @override
  String get referralErrorFormat => 'A referral code has 4 letters or digits.';

  @override
  String get referralErrorNotFound => 'This referral code does not exist.';

  @override
  String get referralErrorOwnCode => 'You can\'t use your own code.';

  @override
  String get referralErrorAlreadyUsed =>
      'You have already used a referral code.';

  @override
  String get referralErrorNotNew => 'Referral codes are for new users only.';

  @override
  String get referralErrorNoProfile => 'Complete your profile first.';

  @override
  String get referralErrorGeneric =>
      'Could not apply the referral code. Try again.';

  @override
  String get walletTitle => 'My Wallet';

  @override
  String get walletBalance => 'Balance';

  @override
  String get walletPending => 'Pending withdrawal';

  @override
  String get walletTotalEarned => 'Total earned';

  @override
  String get walletReferrals => 'Referrals';

  @override
  String get walletHistory => 'History';

  @override
  String get noWalletTransactionsYet => 'No transactions yet.';

  @override
  String get withdrawalRequests => 'Withdrawal requests';

  @override
  String get noWithdrawalsYet => 'You haven\'t requested a withdrawal yet.';

  @override
  String get withdrawalStatusPending => 'Pending';

  @override
  String get withdrawalStatusPaid => 'Paid';

  @override
  String get withdrawalStatusRejected => 'Rejected';

  @override
  String txReferralCredit(String name) {
    return 'Referral commission — $name';
  }

  @override
  String get txWithdrawalRequested => 'Withdrawal requested';

  @override
  String get txWithdrawalRefunded => 'Withdrawal rejected — refunded';

  @override
  String get txWithdrawalPaid => 'Withdrawal paid';

  @override
  String get withdraw => 'Withdraw';

  @override
  String withdrawMinimum(String amount) {
    return 'Minimum withdrawal is $amount';
  }

  @override
  String get withdrawPhoneLabel => 'Phone / payment number';

  @override
  String get withdrawAmountLabel => 'Amount';

  @override
  String get withdrawNotesLabel => 'Notes (optional)';

  @override
  String get withdrawIdTypeLabel => 'ID type';

  @override
  String get idTypeNational => 'National ID';

  @override
  String get idTypeDriversLicense => 'Driver\'s licence';

  @override
  String get idTypePassport => 'Passport';

  @override
  String get withdrawIdPhotoLabel => 'Photo of your ID';

  @override
  String get takePhoto => 'Take photo';

  @override
  String get chooseFromGallery => 'Choose photo';

  @override
  String get withdrawSubmit => 'SUBMIT REQUEST';

  @override
  String get withdrawSubmitted =>
      'Your request has been sent. We\'ll process it soon.';

  @override
  String get withdrawErrorBalance => 'Your balance is not enough.';

  @override
  String get withdrawErrorAmount => 'Enter a valid amount.';

  @override
  String get withdrawErrorPhone => 'Enter a valid phone number.';

  @override
  String get withdrawErrorName => 'Enter your full name.';

  @override
  String get withdrawErrorIdPhoto => 'Add a photo of your ID.';

  @override
  String get paymentUnderpaid =>
      'The amount paid is less than the package price, so the subscription was not activated. Contact us for help.';
}
