// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Moyo App';

  @override
  String get continueButton => 'CONTINUER';

  @override
  String get welcomeTitle => 'Bienvenue\nsur Moyo App';

  @override
  String get welcomeWhatFor => 'À quoi sert cette application ?';

  @override
  String get welcomeIntro =>
      'Moyo App est votre source d\'actualités,\nd\'apprentissage et d\'inspiration au quotidien.\nNous vous offrons un contenu sincère.';

  @override
  String get welcomeBenefitTitle => 'Qu\'allez-vous y gagner ?';

  @override
  String get welcomeBenefitBody =>
      'Recevez du contenu chaque jour, apprenez\net partagez avec une communauté bienveillante\npleine de joie et de foi.';

  @override
  String get authTagline => 'Apprendre · Grandir · Aimer';

  @override
  String get authWelcome => 'Bienvenue sur Moyo App';

  @override
  String get authContinueWithGoogleHint => 'Continuez avec votre compte Google';

  @override
  String get authGoogleButton => 'CONTINUER AVEC GOOGLE';

  @override
  String get authTermsPrefix => 'En continuant, vous acceptez les ';

  @override
  String get authTermsLink => 'Conditions générales';

  @override
  String get authGoogleFailed => 'Échec de la connexion avec Google';

  @override
  String get authSignInError => 'Une erreur est survenue lors de la connexion';

  @override
  String get profileFillAll => 'Veuillez remplir tous les champs';

  @override
  String saveFailed(String error) {
    return 'Échec de l\'enregistrement : $error';
  }

  @override
  String get searchHint => 'Rechercher…';

  @override
  String get profileSetupTitle => 'Complétez vos informations';

  @override
  String get profileSetupSubtitle =>
      'Nous avons besoin de quelques informations avant de continuer';

  @override
  String signedInAs(String email) {
    return 'Connecté en tant que $email';
  }

  @override
  String get useAnotherGoogleAccount => 'Utiliser un autre compte Google';

  @override
  String get fullName => 'Nom complet';

  @override
  String get country => 'Pays';

  @override
  String get chooseYourCountry => 'Choisissez votre pays';

  @override
  String get chooseCountry => 'Choisir le pays';

  @override
  String get region => 'Région';

  @override
  String get chooseYourRegion => 'Choisissez votre région';

  @override
  String get chooseRegion => 'Choisir la région';

  @override
  String get regionOrState => 'Région / État';

  @override
  String get chooseCountryFirst => 'Choisissez d\'abord un pays';

  @override
  String get yourRegionOrState => 'Votre région ou État';

  @override
  String get saveAndContinue => 'ENREGISTRER ET CONTINUER';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get paymentLoadPackagesFailed =>
      'Impossible de charger les forfaits. Réessayez.';

  @override
  String get errorOccurred => 'Une erreur est survenue.';

  @override
  String get errorCheckNetwork =>
      'Une erreur est survenue. Vérifiez votre connexion et réessayez.';

  @override
  String get paymentFailedMessage => 'Le paiement n\'a pas abouti.';

  @override
  String get paymentNotConfirmedYet =>
      'Paiement pas encore confirmé. Patientez un instant.';

  @override
  String get paymentSupportPrompt =>
      'Besoin d\'aide pour le paiement ? Contactez-nous';

  @override
  String get paymentConfirmPhone =>
      'Confirmez le numéro de téléphone pour le paiement';

  @override
  String get paymentPinPrompt =>
      'Vous recevrez une demande de code PIN sur ce numéro';

  @override
  String get payNow => 'PAYER MAINTENANT';

  @override
  String get goBack => 'Retour';

  @override
  String get paymentPreparing => 'Préparation du paiement…';

  @override
  String get paymentCheckPhone => 'Vérifiez votre téléphone';

  @override
  String get paymentWaitingBody =>
      'Nous avons envoyé une demande de paiement sur votre téléphone. Saisissez votre code PIN pour finaliser le paiement. L\'application s\'ouvrira automatiquement une fois le paiement accepté.';

  @override
  String get paymentDone => 'J\'ai effectué le paiement';

  @override
  String get paymentFailedTitle => 'Paiement échoué';

  @override
  String get tryAgain => 'Veuillez réessayer.';

  @override
  String get tryAgainButton => 'RÉESSAYER';

  @override
  String get paymentNoPackages =>
      'Aucun forfait d\'abonnement disponible pour le moment.\nVeuillez contacter l\'administrateur.';

  @override
  String get paymentChoosePackage => 'Choisissez un forfait d\'abonnement';

  @override
  String get showFewer => 'Afficher moins';

  @override
  String paymentShowMorePackages(int count) {
    return 'Voir les autres forfaits ($count)';
  }

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get homeTodayLesson => 'Leçon du jour !';

  @override
  String get homeHotTopics => 'Sujets populaires !';

  @override
  String homeGreeting(String name) {
    return 'Bonjour, $name 👋';
  }

  @override
  String get userFallbackName => 'Utilisateur';

  @override
  String get homeSubtitle => 'Apprenons quelque chose de nouveau aujourd’hui';

  @override
  String get searchCategoriesHint => 'Rechercher des catégories...';

  @override
  String get search => 'Rechercher';

  @override
  String get seeMore => 'Voir plus →';

  @override
  String errorWithDetails(String error) {
    return 'Erreur : $error';
  }

  @override
  String get noCategoriesNow => 'Aucune catégorie pour le moment.';

  @override
  String get noTopicsNow => 'Aucun sujet pour le moment.';

  @override
  String get navExplore => 'Explorer';

  @override
  String get navSaved => 'Favoris';

  @override
  String get navChat => 'Discussion';

  @override
  String get navAccount => 'Compte';

  @override
  String get logoutConfirmTitle => 'Se déconnecter ?';

  @override
  String get logoutConfirmBody =>
      'Voulez-vous vraiment vous déconnecter de votre compte ?';

  @override
  String get no => 'Non';

  @override
  String get yesLogout => 'Oui, se déconnecter';

  @override
  String get location => 'Lieu';

  @override
  String get accountActive => 'Compte actif';

  @override
  String get accountInactive => 'Compte désactivé';

  @override
  String get yourSubscription => 'Votre abonnement';

  @override
  String get statusActive => 'Actif';

  @override
  String get statusNone => 'Aucun';

  @override
  String get subscriptionPackage => 'Forfait d\'abonnement';

  @override
  String expiresOn(String date) {
    return 'Expire le : $date';
  }

  @override
  String get timeRemaining => 'Temps restant';

  @override
  String get renewSubscription => 'Renouveler l\'abonnement';

  @override
  String get noActiveSubscription => 'Vous n\'avez pas\nd\'abonnement actif';

  @override
  String get subscribePrompt =>
      'Abonnez-vous pour continuer\nà profiter de nos contenus.';

  @override
  String get subscribeNow => 'S\'abonner maintenant';

  @override
  String get logout => 'Se déconnecter';

  @override
  String get savedToast => 'Enregistré !';

  @override
  String get removedToast => 'Retiré !';

  @override
  String get audioTrack => 'Piste';

  @override
  String get comments => 'Commentaires';

  @override
  String commentsWithCount(int count) {
    return 'Commentaires ($count)';
  }

  @override
  String get noCommentsYet => 'Aucun commentaire pour le moment.';

  @override
  String get writeCommentHint => 'Écrire un commentaire...';

  @override
  String get savedTitle => 'Favoris';

  @override
  String get savedSubtitle => 'Sujets enregistrés pour plus tard';

  @override
  String get savedEmpty => 'Vous n\'avez encore enregistré aucun sujet.';

  @override
  String get postNoLongerAvailable =>
      'Cette publication n\'est plus disponible.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get noNotificationsYet => 'Aucune notification pour le moment.';

  @override
  String searchFailed(String error) {
    return 'Échec de la recherche : $error';
  }

  @override
  String openConversationFailed(String error) {
    return 'Impossible d\'ouvrir la conversation : $error';
  }

  @override
  String get newMessage => 'Nouveau message';

  @override
  String get searchUserHint => 'Rechercher un utilisateur par nom...';

  @override
  String get newMessagePrompt => 'Saisissez le nom de la personne à qui écrire';

  @override
  String get noUserFound => 'Aucun utilisateur trouvé.';

  @override
  String get searchCategoryPrompt => 'Saisissez un nom de catégorie';

  @override
  String get categoryNotFound => 'Catégorie introuvable';

  @override
  String get passwordProtected => 'Protégé par mot de passe';

  @override
  String get searchTopicsHint => 'Rechercher des sujets...';

  @override
  String get searchTopicPrompt => 'Saisissez un nom de sujet';

  @override
  String get topicNotFound => 'Sujet introuvable';

  @override
  String get categoryPasswordPrompt =>
      'Cette catégorie est protégée. Saisissez le mot de passe pour continuer.';

  @override
  String get password => 'Mot de passe';

  @override
  String get incorrectPassword => 'Mot de passe incorrect';

  @override
  String get cancel => 'Annuler';

  @override
  String get unlock => 'Déverrouiller';

  @override
  String get openAppFailed => 'Impossible d\'ouvrir l\'application';

  @override
  String get callNumber => 'Appeler';

  @override
  String get messageOnWhatsApp => 'Écrire sur WhatsApp';

  @override
  String get copyNumber => 'Copier le numéro';

  @override
  String get numberCopied => 'Numéro copié';

  @override
  String sendFailed(String error) {
    return 'Échec de l\'envoi : $error';
  }

  @override
  String deleteFailed(String error) {
    return 'Échec de la suppression : $error';
  }

  @override
  String pollResponsesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count réponses',
      one: '1 réponse',
      zero: '0 réponse',
    );
    return '$_temp0';
  }

  @override
  String get pollAnswerHint => 'Écrivez votre réponse...';

  @override
  String get send => 'Envoyer';

  @override
  String get pollRetract => 'Retirer ma réponse';

  @override
  String get save => 'Enregistrer';

  @override
  String get pollYourAnswer => 'Votre réponse :';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get pollQuestionHint => 'Écrivez votre question...';

  @override
  String get pollMultipleChoice => 'Choix multiple';

  @override
  String get pollOpenText => 'Réponse libre';

  @override
  String pollOptionN(int n) {
    return 'Option $n';
  }

  @override
  String get pollAddOption => 'Ajouter une option';

  @override
  String get pollIncomplete => 'Complétez la question du sondage';

  @override
  String get timeJustNow => 'À l\'instant';

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
    return '$n j';
  }

  @override
  String timeWeeks(int n) {
    return '$n sem';
  }

  @override
  String shareAppText(String url) {
    return 'Rejoins-moi sur Moyo App — apprends, grandis et aime ! Télécharge-la ici : $url';
  }

  @override
  String get shareAppSubject => 'Télécharger Moyo App';

  @override
  String shareReferralText(String code, String url) {
    return 'Rejoins-moi sur Moyo App — apprends, grandis et aime ! Utilise mon code de parrainage $code lors de l\'inscription. Télécharge-la ici : $url';
  }

  @override
  String get messagesTitle => 'Messages';

  @override
  String get noConversationsYet => 'Aucune conversation pour le moment.';

  @override
  String get startConversation => 'Démarrer une conversation';

  @override
  String deleteChatTitle(String name) {
    return 'Supprimer la discussion avec $name ?';
  }

  @override
  String get deleteChatBody =>
      'Cette discussion sera supprimée uniquement pour vous. L\'autre personne verra toujours tous les messages. S\'il vous écrit à nouveau, la discussion réapparaîtra avec seulement les nouveaux messages.';

  @override
  String get chatDeleted => 'Discussion supprimée';

  @override
  String get deleteChat => 'Supprimer la discussion';

  @override
  String get noMessagesYet =>
      'Aucun message pour le moment. Soyez le premier à écrire !';

  @override
  String get noMessagesStartConversation =>
      'Aucun message pour le moment. Lancez la conversation !';

  @override
  String get writeMessageHint => 'Écrire un message...';

  @override
  String get deleteMessageTitle => 'Supprimer ce message ?';

  @override
  String get cannotBeUndone => 'Cette action est irréversible.';

  @override
  String uploadingPercent(int percent) {
    return 'Envoi $percent %';
  }

  @override
  String get attach => 'Joindre';

  @override
  String get poll => 'Sondage';

  @override
  String get attachmentTypeNotAllowed =>
      'Ce type de fichier n\'est pas autorisé ici';

  @override
  String attachmentsMax(int count) {
    return 'Vous ne pouvez pas ajouter plus de $count pièces jointes';
  }

  @override
  String imagesMax(int count) {
    return 'Vous ne pouvez ajouter que $count images à la fois';
  }

  @override
  String get oneVideoOnly => 'Vous ne pouvez ajouter qu\'une seule vidéo';

  @override
  String videoMaxMinutes(int minutes) {
    return 'La vidéo ne doit pas dépasser $minutes minutes';
  }

  @override
  String fileTooLarge(int mb) {
    return 'Le fichier ne doit pas dépasser $mb Mo';
  }

  @override
  String get videoReadFailed => 'Impossible de lire cette vidéo';

  @override
  String attachImages(int count) {
    return 'Photos (jusqu\'à $count)';
  }

  @override
  String get attachVideo => 'Vidéo';

  @override
  String attachVideoMax(int minutes) {
    return 'Vidéo ($minutes min max)';
  }

  @override
  String get attachAudio => 'Audio';

  @override
  String attachAudioMax(int mb) {
    return 'Audio ($mb Mo max)';
  }

  @override
  String get attachPdf => 'PDF';

  @override
  String attachPdfMax(int mb) {
    return 'PDF ($mb Mo max)';
  }

  @override
  String get pdfDocument => 'Document PDF';

  @override
  String get videoPlaybackFailed => 'Impossible de lire la vidéo';

  @override
  String get audioPlaybackFailed => 'Impossible de lire l\'audio';

  @override
  String get audioClip => 'Extrait audio';

  @override
  String get openLinkFailed => 'Impossible d\'ouvrir le lien';

  @override
  String get communityWall => 'Mur communautaire';

  @override
  String get whatsOnYourMind => 'À quoi pensez-vous ?';

  @override
  String get noPostsYet =>
      'Aucune publication pour le moment. Soyez le premier à publier !';

  @override
  String get deletePostTitle => 'Supprimer la publication ?';

  @override
  String get writePost => 'Écrire une publication';

  @override
  String get publish => 'Publier';

  @override
  String get discussion => 'Discussion';

  @override
  String get sendMessage => 'Envoyer un message';

  @override
  String get noRepliesYet =>
      'Aucune réponse pour le moment. Soyez le premier !';

  @override
  String get writeReplyHint => 'Écrire une réponse...';

  @override
  String get addLink => 'Ajouter un lien';

  @override
  String get linkHint => 'https://exemple.com';

  @override
  String get add => 'Ajouter';

  @override
  String get invalidLink => 'Lien invalide';

  @override
  String linksMax(int count) {
    return 'Vous ne pouvez ajouter que $count liens';
  }

  @override
  String get exploreTitle => 'Choisissez votre\nsujet préféré';

  @override
  String get exploreSubtitle =>
      'Apprenez par la vidéo, l’audio, la lecture et la musique';

  @override
  String get categoryGroupsTitle => 'Groupes';

  @override
  String get otherCategoriesTitle => 'Autres catégories';

  @override
  String get chooseSubcategory => 'Choisissez la rubrique souhaitée';

  @override
  String get chooseCategory => 'Choisissez la catégorie souhaitée';

  @override
  String categoriesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count catégories',
      one: '1 catégorie',
      zero: '0 catégorie',
    );
    return '$_temp0';
  }

  @override
  String topicsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sujets trouvés',
      one: '1 sujet trouvé',
      zero: '0 sujet trouvé',
    );
    return '$_temp0';
  }

  @override
  String get noTopicsYet => 'Aucun sujet pour le moment';

  @override
  String get noTopicsYetBody =>
      'Nous revenons bientôt avec de nouveaux sujets.';

  @override
  String get tabTopics => 'Sujets';

  @override
  String get tabCommunity => 'Communauté';

  @override
  String get tabChat => 'Discussion';

  @override
  String get tabGroups => 'Groupes';

  @override
  String get tabPosts => 'Publications';

  @override
  String get tabMembers => 'Membres';

  @override
  String get createGroup => 'Créer un groupe';

  @override
  String get editGroup => 'Modifier le groupe';

  @override
  String get deleteGroup => 'Supprimer le groupe';

  @override
  String get noGroupsYet => 'Aucun groupe pour le moment. Créez le premier !';

  @override
  String membersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
      zero: '0 membre',
    );
    return '$_temp0';
  }

  @override
  String get groupNameRequired => 'Saisissez un nom de groupe';

  @override
  String get groupPhotoHint => 'Touchez pour ajouter une photo de groupe';

  @override
  String get groupName => 'Nom du groupe';

  @override
  String get groupDescription => 'Description du groupe';

  @override
  String get groupNotFound => 'Ce groupe n\'existe plus.';

  @override
  String get joinGroup => 'Rejoindre';

  @override
  String get leaveGroup => 'Quitter';

  @override
  String get leaveGroupTitle => 'Quitter ce groupe ?';

  @override
  String get leaveGroupBody =>
      'Vous ne verrez plus les publications et la discussion de ce groupe tant que vous ne le rejoindrez pas à nouveau.';

  @override
  String get deleteGroupTitle => 'Supprimer le groupe ?';

  @override
  String get deleteGroupBody =>
      'Toutes les publications, la discussion et les membres de ce groupe seront supprimés. Action irréversible.';

  @override
  String get joinGroupFailed => 'Impossible de rejoindre ce groupe.';

  @override
  String get joinToSeePosts =>
      'Rejoignez le groupe pour voir et écrire des publications et participer à la discussion.';

  @override
  String get groupOwner => 'Propriétaire';

  @override
  String groupCreatedBy(String name) {
    return 'Créé par $name';
  }

  @override
  String joinedAgo(String time) {
    return 'Membre depuis $time';
  }

  @override
  String get removeMember => 'Retirer';

  @override
  String removeMemberTitle(String name) {
    return 'Retirer $name ?';
  }

  @override
  String get removeMemberBody =>
      'Cette personne sera retirée du groupe et ne pourra plus le rejoindre.';

  @override
  String get language => 'Langue';

  @override
  String get chooseLanguage => 'Choisir la langue';

  @override
  String get copy => 'Copier';

  @override
  String get share => 'Partager';

  @override
  String get referralCodeTitle => 'Votre code de parrainage';

  @override
  String referralCodeExplainer(int percent) {
    return 'Invitez vos amis avec ce code. À chaque paiement d\'abonnement, vous recevez $percent % du montant dans votre portefeuille.';
  }

  @override
  String get referralGenerate => 'Générer mon code';

  @override
  String referralGenerateFailed(String error) {
    return 'Impossible de générer le code : $error';
  }

  @override
  String get referralCodeCopied => 'Code de parrainage copié';

  @override
  String get referralCodeOptional => 'Code de parrainage (facultatif)';

  @override
  String get referralCodeHint => 'ex. AB2C';

  @override
  String get referralErrorFormat =>
      'Un code de parrainage comporte 4 lettres ou chiffres.';

  @override
  String get referralErrorNotFound => 'Ce code de parrainage n\'existe pas.';

  @override
  String get referralErrorOwnCode =>
      'Vous ne pouvez pas utiliser votre propre code.';

  @override
  String get referralErrorAlreadyUsed =>
      'Vous avez déjà utilisé un code de parrainage.';

  @override
  String get referralErrorNotNew =>
      'Les codes de parrainage sont réservés aux nouveaux utilisateurs.';

  @override
  String get referralErrorNoProfile => 'Complétez d\'abord votre profil.';

  @override
  String get referralErrorGeneric =>
      'Impossible d\'appliquer le code. Réessayez.';

  @override
  String get walletTitle => 'Mon portefeuille';

  @override
  String get walletBalance => 'Solde';

  @override
  String get walletPending => 'Retrait en attente';

  @override
  String get walletTotalEarned => 'Total gagné';

  @override
  String get walletReferrals => 'Filleuls';

  @override
  String get walletHistory => 'Historique';

  @override
  String get noWalletTransactionsYet => 'Aucune transaction pour le moment.';

  @override
  String get withdrawalRequests => 'Demandes de retrait';

  @override
  String get noWithdrawalsYet => 'Vous n\'avez encore demandé aucun retrait.';

  @override
  String get withdrawalStatusPending => 'En attente';

  @override
  String get withdrawalStatusPaid => 'Payé';

  @override
  String get withdrawalStatusRejected => 'Refusé';

  @override
  String txReferralCredit(String name) {
    return 'Commission de parrainage — $name';
  }

  @override
  String get txWithdrawalRequested => 'Retrait demandé';

  @override
  String get txWithdrawalRefunded => 'Retrait refusé — remboursé';

  @override
  String get txWithdrawalPaid => 'Retrait payé';

  @override
  String get withdraw => 'Retirer';

  @override
  String withdrawMinimum(String amount) {
    return 'Retrait minimum : $amount';
  }

  @override
  String get withdrawPhoneLabel => 'Téléphone / numéro de paiement';

  @override
  String get withdrawAmountLabel => 'Montant';

  @override
  String get withdrawNotesLabel => 'Notes (facultatif)';

  @override
  String get withdrawIdTypeLabel => 'Type de pièce d\'identité';

  @override
  String get idTypeNational => 'Carte d\'identité nationale';

  @override
  String get idTypeDriversLicense => 'Permis de conduire';

  @override
  String get idTypePassport => 'Passeport';

  @override
  String get withdrawIdPhotoLabel => 'Photo de votre pièce d\'identité';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get chooseFromGallery => 'Choisir une photo';

  @override
  String get withdrawSubmit => 'ENVOYER LA DEMANDE';

  @override
  String get withdrawSubmitted =>
      'Votre demande a été envoyée. Elle sera bientôt traitée.';

  @override
  String get withdrawErrorBalance => 'Votre solde est insuffisant.';

  @override
  String get withdrawErrorAmount => 'Saisissez un montant valide.';

  @override
  String get withdrawErrorPhone => 'Saisissez un numéro de téléphone valide.';

  @override
  String get withdrawErrorName => 'Saisissez votre nom complet.';

  @override
  String get withdrawErrorIdPhoto =>
      'Ajoutez une photo de votre pièce d\'identité.';

  @override
  String get paymentUnderpaid =>
      'Le montant payé est inférieur au prix du forfait ; l\'abonnement n\'a donc pas été activé. Contactez-nous pour obtenir de l\'aide.';
}
