import 'package:flutter/material.dart';

/// Manual multi-language strings for EN, FR, ES, AR.
/// No code-generation required — just add keys here and in each locale map.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en')); // fallback: English
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // ── Translation maps ─────────────────────────────────────────────────────

  static const Map<String, Map<String, dynamic>> _translations = {
    // ── English ──────────────────────────────────────────────────────────
    'en': {
      'appName': 'Bantou',
      'appSubtitle': 'Je suis parce que nous sommes',
      'loginTab': 'Login',
      'signUpTab': 'Sign Up',
      // Fields
      'fullNameLabel': 'Full Name',
      'fullNameHint': 'Name',
      'phoneLabel': 'Phone Number',
      'phoneHint': 'Phone',
      'emailLabel': 'Email Address',
      'emailHint': 'name@example.com',
      'passwordLabel': 'Password',
      'passwordHint': '••••••••',
      'confirmPasswordLabel': 'Confirm Password',
      // Validation
      'enterName': 'Enter your name',
      'enterPhone': 'Enter your phone number',
      'invalidPhone': 'Enter a valid phone number',
      'enterEmail': 'Enter your email',
      'enterPassword': 'Enter your password',
      'passwordTooShort': 'Password must be at least 6 characters',
      'passwordsDoNotMatch': 'Passwords do not match',
      // Buttons & links
      'forgotPassword': 'Forgot Password?',
      'signIn': 'Sign In',
      'createAccount': 'Create Account',
      'orDivider': 'OR',
      'newToBantou': 'New to Bantou? ',
      'createAnAccount': 'Create an account',
      'alreadyHaveAccount': 'Already have an account? ',
      'signInLink': 'Sign In',
      // Social
      'continueWithFacebook': 'Continue with Facebook',
      // Home
      'welcomeBack': '👋 Welcome back!',
      'communityWaiting': 'Your community is waiting for you.',
      'circles': 'Circles',
      'circlesSubtitle': 'View and manage your circles',
      'events': 'Events',
      'eventsSubtitle': 'Upcoming events in your circles',
      'helpPosts': 'Help Posts',
      'helpPostsSubtitle': 'Browse and publish help requests',
      'profile': 'Profile',
      'profileSubtitle': 'Manage your account and settings',
      'signOut': 'Sign out',
      // Language picker
      'changeLanguage': 'Change Language',
      // Copyright
      'copyright': '\u00a9 2026 Bantou. All rights reserved.',
      // Forgot password screen
      'fpTitle': 'Forgot Password',
      'fpSubtitleStep1': 'Enter your registered email address.',
      'fpSubtitleStep2': 'Set a new password for your account.',
      'fpEmailLabel': 'Email',
      'fpEmailHint': 'Enter your email',
      'fpEmailRequired': 'Please enter your email',
      'fpVerifyButton': 'Send Code',
      'fpOtpSubtitle': 'Enter the 6-digit code sent to your email.',
      'fpOtpLabel': 'Verification Code',
      'fpOtpHint': '••••••',
      'fpOtpButton': 'Verify Code',
      'fpOtpResend': 'Resend Code',
      'fpOtpResendIn': 'Resend in',
      'fpOtpInvalid': 'The code must be 6 digits',
      'fpSubtitleStep3': 'Set a new password for your account.',
      'fpNewPasswordLabel': 'New Password',
      'fpNewPasswordHint': 'Enter new password',
      'fpMinChars': 'Minimum 6 characters',
      'fpConfirmLabel': 'Confirm Password',
      'fpConfirmHint': 'Re-enter new password',
      'fpPasswordsMismatch': 'Passwords do not match',
      'fpResetButton': 'Reset Password',
      'fpSuccessTitle': 'Password Changed!',
      'fpSuccessSubtitle':
          'Your password has been updated successfully.\nYou can now sign in with your new password.',
      'fpGoToLogin': 'Go to Login',
      // Profile Setup screen
      'psStepTitle': 'Step 2 of 2',
      'psHeaderTitle': 'Profile Setup',
      'psHeroTitle': 'Complete Your Profile',
      'psHeroSubtitle':
          'Help your community know who you are.\nYou can always update this later.',
      'psAvatarTitle': 'Choose Your Avatar',
      'psAvatarSelected': 'Selected',
      'psProfInfoTitle': 'Professional Info',
      'psCompanyLabel': 'Company / Organization',
      'psCompanyHint': 'e.g. Bantou Industries',
      'psJobLabel': 'Job Title',
      'psJobHint': 'e.g. Community Manager',
      'psRoleHint': 'Your Role in the Community',
      'psAboutTitle': 'About Your Company',
      'psCityLabel': 'City / Location',
      'psCityHint': 'e.g. Casablanca, Morocco',
      'psBioHint': 'A short bio about yourself or your community…',
      'psOnlineTitle': 'Online Presence',
      'psWebLabel': 'Website / LinkedIn (optional)',
      'psWebHint': 'https://...',
      'psSaveBtn': 'Save & Continue',
      'psSkipBtn': 'Skip for now',
      'psAvatarTooltips': [
        'Corporate / Business',
        'Finance / Institution',
        'Education / Academic',
        'Engineering / Technical',
        'Software / Tech',
        'Design / Creative',
        'Marketing / Comms',
        'Legal / Justice',
        'Health / Medical',
        'Food / Hospitality',
        'Customer Support',
        'Science / Research',
        'Architecture / Planning',
        'Media / Photography',
        'Audio / Entertainment',
        'International / NGO',
      ],
      // Create Association screen
      'caTitle': 'Create Association',
      'caSubtitle': 'Set up your association profile to get started.',
      'caLogoLabel': 'Association Logo',
      'caLogoBtn': 'Upload Logo',
      'caNameLabel': 'Association Name',
      'caNameHint': 'e.g. Bantou Youth Network',
      'caNameRequired': 'Please enter the association name',
      'caAddressLabel': 'Address',
      'caAddressHint': 'Street, City, Country',
      'caEmailsSectionTitle': 'Contact Emails',
      'caEmailHint': 'email@example.com',
      'caAddEmailBtn': '+ Add Email',
      'caPhonesSectionTitle': 'Contact Phones',
      'caPhoneHint': 'e.g. +1 234 567 890',
      'caAddPhoneBtn': '+ Add Phone',
      'caRemoveBtn': 'Remove',
      'caAdminEmailsTitle': 'Admin Emails',
      'caAdminEmailHint': 'admin@example.com',
      'caAddAdminEmailBtn': '+ Add Admin Email',
      'caSocialTitle': 'Social Media',
      'caFbHint': 'Facebook URL',
      'caLinkedInHint': 'LinkedIn URL',
      'caXHint': 'X (Twitter) URL',
      'caSubmitBtn': 'Save & Continue',
      'caEmailRequired': 'Please enter at least one email',
      'caPhoneRequired': 'Please enter at least one phone number',

      // Circle Dashboard
      'cdTitle': 'Circle Dashboard',
      'cdCircleNameLabel': 'Circle Name',
      'cdCircleNameHint': 'e.g. Design Team',
      'cdCountryLabel': 'Country',
      'cdCountryHint': 'e.g. Morocco',
      'cdCityLabel': 'City',
      'cdCityHint': 'e.g. Casablanca',
      'cdResponsibleLabel': 'Circle Responsible',
      'cdResponsibleHint': 'Name of the responsible',
      'cdViceResponsibleLabel': 'Vice Responsible',
      'cdViceResponsibleHint': 'Name of the vice responsible',
      'cdMeetingPlanningLabel': 'Meeting Planning',
      'cdMeetingPlanningHint': 'e.g. Every Monday at 10 AM',
      'cdSaveBtn': 'Save Changes',
      'cdActionRequired': 'Action Required',
      'cdActionMsg': 'Please complete your profile to unlock full administrative features (e.g., creating circles).',
      'cdCompleteProfile': 'Complete Profile',
      'cdWelcome': 'Welcome back,',
      'cdMeetingsThisWeek': 'You have {count} meetings scheduled this week.',
      'cdTotalCircles': 'Total Circles',
      'cdActiveMembers': 'Active Members',
      'cdMeetings': 'Meetings',
      'cdAssocCircles': 'Your Association Circles',
      'cdViewMap': 'View Map',
      'cdSearch': 'Search circles or locations...',
      'cdNoCircles': 'No circles created yet.\nTap New Circle to get started!',
      'cdNoSearchResults': 'No circles found matching your search.',
      'cdNewCircle': 'New Circle',
      'cdActive': 'Active',
      'cdNoDate': 'No date set',
      'cdMeetingLabel': 'Meeting',
      'cdResponsibleSmall': 'Responsible',
      'cdViceResponsibleSmall': 'Vice-Responsible',
      'cdNoAssoc': 'No Association Attached',

      // Create Circle & Circle Details
      'cdCreateCircleTitle': 'Create Circle',
      'cdCircleDetailsTitle': 'Circle Details',
      'cdDescriptionOptional': 'Description (Optional)',
      'cdDescriptionHintText': 'Describe the purpose or focus of this circle...',
      'cdVisibilityAccess': 'Visibility & Access',
      'cdPublic': 'Public',
      'cdPrivate': 'Private',
      'cdInviteMembers': 'Invite Members',
      'cdSearchAddMembers': 'Search and add members',
      'cdLeadership': 'Leadership',
      'cdSchedule': 'Schedule',
      'cdCircleSavedSuccess': 'Circle saved successfully!',
      'cdAddMember': 'Add Member',
      'cdSearchNameEmail': 'Search by name or email',
      'cdCancel': 'Cancel',
      'cdNoMembersFound': 'No members found.',
      'cdUnknownCircle': 'Unknown Circle',
      'cdNoDescriptionProvided': 'No description provided.',
      'cdCircleLeadership': 'Circle Leadership',
      'cdUpcomingMeetings': 'Upcoming Meetings',
      'cdViewCalendar': 'View Calendar',
      'cdNextSync': 'Next Sync',
      'cdMeetingGallery': 'Meeting Gallery',
      'cdAddPhoto': 'Add Photo',
      'cdNoPhotosYet': 'No photos yet',
      'cdTakeFirstSnapshot': 'Take the first snapshot of your meeting!',
      'cdPhotoUploadedSuccess': 'Photo uploaded directly to gallery!',
      'cdCircleParticipants': 'Circle Participants',
      'cdViewAll': 'View All',
      'cdManageParticipation': 'Manage Participation',
      'cdSeeWhoJoined': 'See who has joined this circle',
      'cdEditCircle': 'Edit Circle',
      'cdCircleUpdatedSuccess': 'Circle updated successfully!',
      'cdJoined': 'Joined',
      'cdNotJoined': 'Not Joined',
      'prTitle': 'Pending Requests',
      'prNoRequests': 'No pending requests.',
      'prAdmin': 'Admin',
      'prReject': 'Reject',
      'prApprove': 'Approve',
      'prRequestAction': 'Request {status}',
      'cdRequestsBtn': 'Requests',
      'cdInviteToCircle': 'Invite to {name}',
      'cdEmailAddress': 'Email address',
      'cdSend': 'Send',
      'cdInviteAppMember': 'Invite App Member',
      'cdSendInvite': 'Send Invite',
      'cdInviteToCircleBtn': 'Invite to Circle',
      'cdInviteBtn': 'Invite',
      'cdParticipateBtn': 'Participate',
      'cdLeaveBtn': 'Leave',
      'cdJoinBtn': 'Join',
      'cdPendingApproval': 'Pending Approval',
      'cdRequestAccess': 'Request Access',
      'cdMemberOfCircle': 'You are a member of this circle',
      // Posts
      'posts_feed': 'Posts feed',
      'share_an_update': 'Share an update with your circle...',
      'photo': 'Photo',
      'delete_post': 'Delete Post',
      'delete_post_confirmation': 'Are you sure you want to delete this post?',
      'cancel': 'Cancel',
      'like': 'Like',
      'comment': 'Comment',
      'share': 'Share',
      'create_post': 'Create Post',
      'error_fetching_posts': 'Error fetching posts',
    },

    // ── French ───────────────────────────────────────────────────────────
    'fr': {
      'appName': 'Bantou',
      'appSubtitle': 'Je suis parce que nous sommes',
      'loginTab': 'Connexion',
      'signUpTab': 'Inscription',
      'fullNameLabel': 'Nom complet',
      'fullNameHint': 'Nom',
      'phoneLabel': 'Numéro de téléphone',
      'phoneHint': 'Téléphone',
      'emailLabel': 'Adresse e-mail',
      'emailHint': 'nom@exemple.com',
      'passwordLabel': 'Mot de passe',
      'passwordHint': '••••••••',
      'confirmPasswordLabel': 'Confirmer le mot de passe',
      'enterName': 'Entrez votre nom',
      'enterPhone': 'Entrez votre numéro de téléphone',
      'invalidPhone': 'Entrez un numéro de téléphone valide',
      'enterEmail': 'Entrez votre e-mail',
      'enterPassword': 'Entrez votre mot de passe',
      'passwordTooShort':
          'Le mot de passe doit comporter au moins 6 caractères',
      'passwordsDoNotMatch': 'Les mots de passe ne correspondent pas',
      'forgotPassword': 'Mot de passe oublié ?',
      'signIn': 'Se connecter',
      'createAccount': 'Créer un compte',
      'orDivider': 'OU',
      'newToBantou': 'Nouveau sur Bantou ? ',
      'createAnAccount': 'Créer un compte',
      'alreadyHaveAccount': 'Vous avez déjà un compte ? ',
      'signInLink': 'Se connecter',
      'continueWithFacebook': 'Continuer avec Facebook',
      'welcomeBack': '👋 Bon retour !',
      'communityWaiting': 'Votre communauté vous attend.',
      'circles': 'Cercles',
      'circlesSubtitle': 'Voir et gérer vos cercles',
      'events': 'Événements',
      'eventsSubtitle': 'Événements à venir dans vos cercles',
      'helpPosts': "Publications d'aide",
      'helpPostsSubtitle': "Parcourir et publier des demandes d'aide",
      'profile': 'Profil',
      'profileSubtitle': 'Gérer votre compte et vos paramètres',
      'signOut': 'Déconnexion',
      'changeLanguage': 'Changer de langue',
      'copyright': '\u00a9 2026 Bantou. Tous droits réservés.',
      // Forgot password screen
      'fpTitle': 'Mot de passe oublié',
      'fpSubtitleStep1': 'Entrez votre adresse e-mail enregistrée.',
      'fpSubtitleStep2': 'Définissez un nouveau mot de passe.',
      'fpEmailLabel': 'E-mail',
      'fpEmailHint': 'Entrez votre e-mail',
      'fpEmailRequired': 'Veuillez entrer votre e-mail',
      'fpVerifyButton': 'Envoyer le code',
      'fpOtpSubtitle': 'Entrez le code à 6 chiffres envoyé à votre e-mail.',
      'fpOtpLabel': 'Code de vérification',
      'fpOtpHint': '••••••',
      'fpOtpButton': 'Vérifier le code',
      'fpOtpResend': 'Renvoyer le code',
      'fpOtpResendIn': 'Renvoyer dans',
      'fpOtpInvalid': 'Le code doit comporter 6 chiffres',
      'fpSubtitleStep3': 'Définissez un nouveau mot de passe.',
      'fpNewPasswordLabel': 'Nouveau mot de passe',
      'fpNewPasswordHint': 'Entrez le nouveau mot de passe',
      'fpMinChars': 'Minimum 6 caractères',
      'fpConfirmLabel': 'Confirmer le mot de passe',
      'fpConfirmHint': 'Re-entrez le nouveau mot de passe',
      'fpPasswordsMismatch': 'Les mots de passe ne correspondent pas',
      'fpResetButton': 'Réinitialiser le mot de passe',
      'fpSuccessTitle': 'Mot de passe modifié !',
      'fpSuccessSubtitle':
          'Votre mot de passe a été mis à jour avec succès.\nVous pouvez maintenant vous connecter avec votre nouveau mot de passe.',
      'fpGoToLogin': 'Aller à la connexion',
      // Profile Setup screen
      'psStepTitle': 'Étape 2 sur 2',
      'psHeaderTitle': 'Configuration du profil',
      'psHeroTitle': 'Complétez votre profil',
      'psHeroSubtitle':
          'Aidez votre communauté à vous connaître.\nVous pourrez toujours modifier ceci plus tard.',
      'psAvatarTitle': 'Choisissez votre avatar',
      'psAvatarSelected': 'Sélectionné',
      'psProfInfoTitle': 'Informations professionnelles',
      'psCompanyLabel': 'Entreprise / Organisation',
      'psCompanyHint': 'ex: Bantou Industries',
      'psJobLabel': 'Titre du poste',
      'psJobHint': 'ex: Community Manager',
      'psRoleHint': 'Votre rôle dans la communauté',
      'psAboutTitle': 'À propos de votre entreprise',
      'psCityLabel': 'Ville / Emplacement',
      'psCityHint': 'ex: Casablanca, Maroc',
      'psBioHint': 'Une courte biographie sur vous ou votre communauté…',
      'psOnlineTitle': 'Présence en ligne',
      'psWebLabel': 'Site Web / LinkedIn (facultatif)',
      'psWebHint': 'https://...',
      'psSaveBtn': 'Enregistrer & Continuer',
      'psSkipBtn': 'Ignorer pour le moment',
      'psAvatarTooltips': [
        'Entreprise / Affaires',
        'Finance / Institution',
        'Éducation / Académique',
        'Ingénierie / Technique',
        'Logiciel / Tech',
        'Design / Créatif',
        'Marketing / Comms',
        'Juridique / Justice',
        'Santé / Médical',
        'Restauration / Hôtellerie',
        'Support client',
        'Science / Recherche',
        'Architecture / Urbanisme',
        'Média / Photographie',
        'Audio / Divertissement',
        'International / ONG',
      ],
      // Create Association screen
      'caTitle': 'Créer une association',
      'caSubtitle': 'Configurez le profil de votre association pour commencer.',
      'caLogoLabel': "Logo de l'association",
      'caLogoBtn': 'Télécharger le logo',
      'caNameLabel': "Nom de l'association",
      'caNameHint': 'ex: Réseau Jeunesse Bantou',
      'caNameRequired': "Veuillez entrer le nom de l'association",
      'caAddressLabel': 'Adresse',
      'caAddressHint': 'Rue, Ville, Pays',
      'caEmailsSectionTitle': 'Emails de contact',
      'caEmailHint': 'email@exemple.com',
      'caAddEmailBtn': '+ Ajouter un e-mail',
      'caPhonesSectionTitle': 'Téléphones de contact',
      'caPhoneHint': 'ex: +33 1 23 45 67 89',
      'caAddPhoneBtn': '+ Ajouter un téléphone',
      'caRemoveBtn': 'Supprimer',
      'caAdminEmailsTitle': 'Emails administratifs',
      'caAdminEmailHint': 'admin@exemple.com',
      'caAddAdminEmailBtn': '+ Ajouter un email admin',
      'caSocialTitle': 'Réseaux sociaux',
      'caFbHint': 'URL Facebook',
      'caLinkedInHint': 'URL LinkedIn',
      'caXHint': 'URL X (Twitter)',
      'caSubmitBtn': 'Enregistrer & Continuer',
      'caEmailRequired': 'Veuillez entrer au moins un email',
      'caPhoneRequired': 'Veuillez entrer au moins un numéro de téléphone',

      // Circle Dashboard
      'cdTitle': 'Tableau de bord du Cercle',
      'cdCircleNameLabel': 'Nom du Cercle',
      'cdCircleNameHint': 'ex: Équipe de Design',
      'cdCountryLabel': 'Pays',
      'cdCountryHint': 'ex: Maroc',
      'cdCityLabel': 'Ville',
      'cdCityHint': 'ex: Casablanca',
      'cdResponsibleLabel': 'Responsable du Cercle',
      'cdResponsibleHint': 'Nom du responsable',
      'cdViceResponsibleLabel': 'Vice Responsable',
      'cdViceResponsibleHint': 'Nom du vice responsable',
      'cdMeetingPlanningLabel': 'Planification des réunions',
      'cdMeetingPlanningHint': 'ex: Tous les lundis à 10h',
      'cdSaveBtn': 'Enregistrer',
      'cdActionRequired': 'Action requise',
      'cdActionMsg': 'Veuillez compléter votre profil pour débloquer toutes les fonctionnalités (ex: créer des cercles).',
      'cdCompleteProfile': 'Compléter le profil',
      'cdWelcome': 'Bon retour,',
      'cdMeetingsThisWeek': 'Vous avez {count} réunions prévues cette semaine.',
      'cdTotalCircles': 'Total des Cercles',
      'cdActiveMembers': 'Membres Actifs',
      'cdMeetings': 'Réunions',
      'cdAssocCircles': 'Cercles de votre association',
      'cdViewMap': 'Voir la carte',
      'cdSearch': 'Rechercher des cercles ou des lieux...',
      'cdNoCircles': 'Aucun cercle créé.\nAppuyez sur Nouveau Cercle pour commencer !',
      'cdNoSearchResults': 'Aucun cercle trouvé correspondant à votre recherche.',
      'cdNewCircle': 'Nouveau Cercle',
      'cdActive': 'Actif',
      'cdNoDate': 'Aucune date définie',
      'cdMeetingLabel': 'Réunion',
      'cdResponsibleSmall': 'Responsable',
      'cdViceResponsibleSmall': 'Vice-Responsable',
      'cdNoAssoc': 'Aucune association liée',

      // Create Circle & Circle Details
      'cdCreateCircleTitle': 'Créer un Cercle',
      'cdCircleDetailsTitle': 'Détails du Cercle',
      'cdDescriptionOptional': 'Description (Optionnelle)',
      'cdDescriptionHintText': 'Décrivez le but ou l\'objectif de ce cercle...',
      'cdVisibilityAccess': 'Visibilité et Accès',
      'cdPublic': 'Public',
      'cdPrivate': 'Privé',
      'cdInviteMembers': 'Inviter des Membres',
      'cdSearchAddMembers': 'Rechercher et ajouter des membres',
      'cdLeadership': 'Leadership',
      'cdSchedule': 'Calendrier',
      'cdCircleSavedSuccess': 'Cercle enregistré avec succès !',
      'cdAddMember': 'Ajouter un membre',
      'cdSearchNameEmail': 'Rechercher par nom ou email',
      'cdCancel': 'Annuler',
      'cdNoMembersFound': 'Aucun membre trouvé.',
      'cdUnknownCircle': 'Cercle inconnu',
      'cdNoDescriptionProvided': 'Aucune description fournie.',
      'cdCircleLeadership': 'Leadership du Cercle',
      'cdUpcomingMeetings': 'Prochaines réunions',
      'cdViewCalendar': 'Voir le calendrier',
      'cdNextSync': 'Prochaine synchro',
      'cdMeetingGallery': 'Galerie de réunions',
      'cdAddPhoto': 'Ajouter une photo',
      'cdNoPhotosYet': 'Pas encore de photos',
      'cdTakeFirstSnapshot': 'Prenez la première photo de votre réunion !',
      'cdPhotoUploadedSuccess': 'Photo téléchargée dans la galerie !',
      'cdCircleParticipants': 'Participants du Cercle',
      'cdViewAll': 'Voir tout',
      'cdManageParticipation': 'Gérer la participation',
      'cdSeeWhoJoined': 'Voir qui a rejoint ce cercle',
      'cdEditCircle': 'Modifier le Cercle',
      'cdCircleUpdatedSuccess': 'Cercle mis à jour avec succès !',
      'cdJoined': 'Rejoint',
      'cdNotJoined': 'Non rejoint',
      'prTitle': 'Demandes en attente',
      'prNoRequests': 'Aucune demande en attente.',
      'prAdmin': 'Admin',
      'prReject': 'Rejeter',
      'prApprove': 'Approuver',
      'prRequestAction': 'Demande {status}',
      'cdRequestsBtn': 'Demandes',
      'cdInviteToCircle': 'Inviter à {name}',
      'cdEmailAddress': 'Adresse e-mail',
      'cdSend': 'Envoyer',
      'cdInviteAppMember': 'Inviter un membre de l\'application',
      'cdSendInvite': 'Envoyer l\'invitation',
      'cdInviteToCircleBtn': 'Inviter au cercle',
      'cdInviteBtn': 'Inviter',
      'cdParticipateBtn': 'Participer',
      'cdLeaveBtn': 'Quitter',
      'cdJoinBtn': 'Rejoindre',
      'cdPendingApproval': 'En attente d\'approbation',
      'cdRequestAccess': 'Demander l\'accès',
      'cdMemberOfCircle': 'Vous êtes membre de ce cercle',
      // Posts
      'posts_feed': 'Fil d\'actualité',
      'share_an_update': 'Partagez une mise à jour avec votre cercle...',
      'photo': 'Photo',
      'delete_post': 'Supprimer le post',
      'delete_post_confirmation': 'Êtes-vous sûr de vouloir supprimer ce post ?',
      'cancel': 'Annuler',
      'like': 'J\'aime',
      'comment': 'Commenter',
      'share': 'Partager',
      'create_post': 'Créer un post',
      'error_fetching_posts': 'Erreur lors de la récupération des posts',
    },

    // ── Spanish ──────────────────────────────────────────────────────────
    'es': {
      'appName': 'Bantou',
      'appSubtitle': 'Je suis parce que nous sommes',
      'loginTab': 'Iniciar sesión',
      'signUpTab': 'Registrarse',
      'fullNameLabel': 'Nombre completo',
      'fullNameHint': 'Nombre',
      'phoneLabel': 'Número de teléfono',
      'phoneHint': 'Teléfono',
      'emailLabel': 'Correo electrónico',
      'emailHint': 'nombre@ejemplo.com',
      'passwordLabel': 'Contraseña',
      'passwordHint': '••••••••',
      'confirmPasswordLabel': 'Confirmar contraseña',
      'enterName': 'Ingresa tu nombre',
      'enterPhone': 'Ingresa tu número de teléfono',
      'invalidPhone': 'Ingresa un número de teléfono válido',
      'enterEmail': 'Ingresa tu correo electrónico',
      'enterPassword': 'Ingresa tu contraseña',
      'passwordTooShort': 'La contraseña debe tener al menos 6 caracteres',
      'passwordsDoNotMatch': 'Las contraseñas no coinciden',
      'forgotPassword': '¿Olvidaste tu contraseña?',
      'signIn': 'Iniciar sesión',
      'createAccount': 'Crear cuenta',
      'orDivider': 'O',
      'newToBantou': '¿Nuevo en Bantou? ',
      'createAnAccount': 'Crear una cuenta',
      'alreadyHaveAccount': '¿Ya tienes una cuenta? ',
      'signInLink': 'Iniciar sesión',
      'continueWithFacebook': 'Continuar con Facebook',
      'welcomeBack': '👋 ¡Bienvenido de vuelta!',
      'communityWaiting': 'Tu comunidad te está esperando.',
      'circles': 'Círculos',
      'circlesSubtitle': 'Ver y gestionar tus círculos',
      'events': 'Eventos',
      'eventsSubtitle': 'Próximos eventos en tus círculos',
      'helpPosts': 'Publicaciones de ayuda',
      'helpPostsSubtitle': 'Explorar y publicar solicitudes de ayuda',
      'profile': 'Perfil',
      'profileSubtitle': 'Gestionar tu cuenta y configuración',
      'signOut': 'Cerrar sesión',
      'changeLanguage': 'Cambiar idioma',
      'copyright': '\u00a9 2026 Bantou. Todos los derechos reservados.',
      // Forgot password screen
      'fpTitle': 'Olvidé mi contraseña',
      'fpSubtitleStep1': 'Ingresa tu dirección de correo registrada.',
      'fpSubtitleStep2': 'Establece una nueva contraseña.',
      'fpEmailLabel': 'Correo',
      'fpEmailHint': 'Ingresa tu correo',
      'fpEmailRequired': 'Por favor ingresa tu correo',
      'fpVerifyButton': 'Enviar código',
      'fpOtpSubtitle': 'Ingresa el código de 6 dígitos enviado a tu correo.',
      'fpOtpLabel': 'Código de verificación',
      'fpOtpHint': '••••••',
      'fpOtpButton': 'Verificar código',
      'fpOtpResend': 'Reenviar código',
      'fpOtpResendIn': 'Reenviar en',
      'fpOtpInvalid': 'El código debe tener 6 dígitos',
      'fpSubtitleStep3': 'Establece una nueva contraseña.',
      'fpNewPasswordLabel': 'Nueva contraseña',
      'fpNewPasswordHint': 'Ingresa la nueva contraseña',
      'fpMinChars': 'Mínimo 6 caracteres',
      'fpConfirmLabel': 'Confirmar contraseña',
      'fpConfirmHint': 'Vuelve a ingresar la nueva contraseña',
      'fpPasswordsMismatch': 'Las contraseñas no coinciden',
      'fpResetButton': 'Restablecer contraseña',
      'fpSuccessTitle': '¡Contraseña cambiada!',
      'fpSuccessSubtitle':
          'Tu contraseña ha sido actualizada correctamente.\nAhora puedes iniciar sesión con tu nueva contraseña.',
      'fpGoToLogin': 'Ir al inicio de sesión',
      // Profile Setup screen
      'psStepTitle': 'Paso 2 de 2',
      'psHeaderTitle': 'Configuración de perfil',
      'psHeroTitle': 'Completa tu perfil',
      'psHeroSubtitle':
          'Ayuda a tu comunidad a conocerte.\nSiempre puedes actualizar esto más tarde.',
      'psAvatarTitle': 'Elige tu avatar',
      'psAvatarSelected': 'Seleccionado',
      'psProfInfoTitle': 'Información profesional',
      'psCompanyLabel': 'Empresa / Organización',
      'psCompanyHint': 'ej. Bantou Industries',
      'psJobLabel': 'Título del puesto',
      'psJobHint': 'ej. Community Manager',
      'psRoleHint': 'Tu rol en la comunidad',
      'psAboutTitle': 'Acerca de tu empresa',
      'psCityLabel': 'Ciudad / Ubicación',
      'psCityHint': 'ej. Casablanca, Marruecos',
      'psBioHint': 'Una breve biografía sobre ti o tu comunidad…',
      'psOnlineTitle': 'Presencia en línea',
      'psWebLabel': 'Sitio web / LinkedIn (opcional)',
      'psWebHint': 'https://...',
      'psSaveBtn': 'Guardar y Continuar',
      'psSkipBtn': 'Omitir por ahora',
      'psAvatarTooltips': [
        'Corporativo / Negocios',
        'Finanzas / Institución',
        'Educación / Académico',
        'Ingeniería / Técnico',
        'Software / Tecnología',
        'Diseño / Creativo',
        'Marketing / Comunicación',
        'Legal / Justicia',
        'Salud / Médico',
        'Comida / Hospitalidad',
        'Atención al cliente',
        'Ciencia / Investigación',
        'Arquitectura / Urbanismo',
        'Medios / Fotografía',
        'Audio / Entretenimiento',
        'Internacional / ONG',
      ],
      // Create Association screen
      'caTitle': 'Crear asociación',
      'caSubtitle': 'Configura el perfil de tu asociación para comenzar.',
      'caLogoLabel': 'Logo de la asociación',
      'caLogoBtn': 'Subir logo',
      'caNameLabel': 'Nombre de la asociación',
      'caNameHint': 'ej: Red Juvenil Bantou',
      'caNameRequired': 'Por favor ingresa el nombre de la asociación',
      'caAddressLabel': 'Dirección',
      'caAddressHint': 'Calle, Ciudad, País',
      'caEmailsSectionTitle': 'Correos de contacto',
      'caEmailHint': 'correo@ejemplo.com',
      'caAddEmailBtn': '+ Agregar correo',
      'caPhonesSectionTitle': 'Teléfonos de contacto',
      'caPhoneHint': 'ej: +34 600 000 000',
      'caAddPhoneBtn': '+ Agregar teléfono',
      'caRemoveBtn': 'Eliminar',
      'caAdminEmailsTitle': 'Correos de administradores',
      'caAdminEmailHint': 'admin@ejemplo.com',
      'caAddAdminEmailBtn': '+ Añadir correo admin',
      'caSocialTitle': 'Redes sociales',
      'caFbHint': 'URL de Facebook',
      'caLinkedInHint': 'URL de LinkedIn',
      'caXHint': 'URL de X (Twitter)',
      'caSubmitBtn': 'Guardar y Continuar',
      'caEmailRequired': 'Por favor ingresa al menos un correo',
      'caPhoneRequired': 'Por favor ingresa al menos un número de teléfono',

      // Circle Dashboard
      'cdTitle': 'Panel del Círculo',
      'cdCircleNameLabel': 'Nombre del Círculo',
      'cdCircleNameHint': 'ej. Equipo de Diseño',
      'cdCountryLabel': 'País',
      'cdCountryHint': 'ej. Marruecos',
      'cdCityLabel': 'Ciudad',
      'cdCityHint': 'ej. Casablanca',
      'cdResponsibleLabel': 'Responsable del Círculo',
      'cdResponsibleHint': 'Nombre del responsable',
      'cdViceResponsibleLabel': 'Vice Responsable',
      'cdViceResponsibleHint': 'Nombre del vice responsable',
      'cdMeetingPlanningLabel': 'Planificación de reuniones',
      'cdMeetingPlanningHint': 'ej. Todos los lunes a las 10 AM',
      'cdSaveBtn': 'Guardar Cambios',
      'cdActionRequired': 'Acción requerida',
      'cdActionMsg': 'Por favor, completa tu perfil para desbloquear todas las funciones (ej. crear círculos).',
      'cdCompleteProfile': 'Completar perfil',
      'cdWelcome': 'Bienvenido de nuevo,',
      'cdMeetingsThisWeek': 'Tienes {count} reuniones programadas esta semana.',
      'cdTotalCircles': 'Total de Círculos',
      'cdActiveMembers': 'Miembros Activos',
      'cdMeetings': 'Reuniones',
      'cdAssocCircles': 'Círculos de tu asociación',
      'cdViewMap': 'Ver mapa',
      'cdSearch': 'Buscar círculos o lugares...',
      'cdNoCircles': 'No hay círculos creados.\n¡Toca Nuevo Círculo para empezar!',
      'cdNoSearchResults': 'No se encontraron círculos que coincidan con su búsqueda.',
      'cdNewCircle': 'Nuevo Círculo',
      'cdActive': 'Activo',
      'cdNoDate': 'Sin fecha',
      'cdMeetingLabel': 'Reunión',
      'cdResponsibleSmall': 'Responsable',
      'cdViceResponsibleSmall': 'Vice-Responsable',
      'cdNoAssoc': 'Ninguna asociación adjunta',

      // Create Circle & Circle Details
      'cdCreateCircleTitle': 'Crear Círculo',
      'cdCircleDetailsTitle': 'Detalles del Círculo',
      'cdDescriptionOptional': 'Descripción (Opcional)',
      'cdDescriptionHintText': 'Describe el propósito o enfoque de este círculo...',
      'cdVisibilityAccess': 'Visibilidad y Acceso',
      'cdPublic': 'Público',
      'cdPrivate': 'Privado',
      'cdInviteMembers': 'Invitar Miembros',
      'cdSearchAddMembers': 'Buscar y agregar miembros',
      'cdLeadership': 'Liderazgo',
      'cdSchedule': 'Horario',
      'cdCircleSavedSuccess': '¡Círculo guardado con éxito!',
      'cdAddMember': 'Agregar miembro',
      'cdSearchNameEmail': 'Buscar por nombre o correo',
      'cdCancel': 'Cancelar',
      'cdNoMembersFound': 'No se encontraron miembros.',
      'cdUnknownCircle': 'Círculo desconocido',
      'cdNoDescriptionProvided': 'No se proporcionó descripción.',
      'cdCircleLeadership': 'Liderazgo del Círculo',
      'cdUpcomingMeetings': 'Próximas reuniones',
      'cdViewCalendar': 'Ver calendario',
      'cdNextSync': 'Próxima síncrono',
      'cdMeetingGallery': 'Galería de reuniones',
      'cdAddPhoto': 'Agregar foto',
      'cdNoPhotosYet': 'Aún no hay fotos',
      'cdTakeFirstSnapshot': '¡Toma la primera foto de tu reunión!',
      'cdPhotoUploadedSuccess': '¡Foto subida a la galería!',
      'cdCircleParticipants': 'Participantes del Círculo',
      'cdViewAll': 'Ver todo',
      'cdManageParticipation': 'Gestionar participación',
      'cdSeeWhoJoined': 'Mira quién se ha unido a este círculo',
      'cdEditCircle': 'Editar Círculo',
      'cdCircleUpdatedSuccess': '¡Círculo actualizado con éxito!',
      'cdJoined': 'Unido',
      'cdNotJoined': 'No se unió',
      'prTitle': 'Solicitudes pendientes',
      'prNoRequests': 'No hay solicitudes pendientes.',
      'prAdmin': 'Admin',
      'prReject': 'Rechazar',
      'prApprove': 'Aprobar',
      'prRequestAction': 'Solicitud {status}',
      'cdRequestsBtn': 'Solicitudes',
      'cdInviteToCircle': 'Invitar a {name}',
      'cdEmailAddress': 'Dirección de correo',
      'cdSend': 'Enviar',
      'cdInviteAppMember': 'Invitar miembro de la app',
      'cdSendInvite': 'Enviar Invitación',
      'cdInviteToCircleBtn': 'Invitar al círculo',
      'cdInviteBtn': 'Invitar',
      'cdParticipateBtn': 'Participar',
      'cdLeaveBtn': 'Salir',
      'cdJoinBtn': 'Unirse',
      'cdPendingApproval': 'Aprobación pendiente',
      'cdRequestAccess': 'Solicitar acceso',
      'cdMemberOfCircle': 'Eres miembro de este círculo',
      // Posts
      'posts_feed': 'Feed de publicaciones',
      'share_an_update': 'Comparte una actualización con tu círculo...',
      'photo': 'Foto',
      'delete_post': 'Eliminar publicación',
      'delete_post_confirmation': '¿Estás seguro de que deseas eliminar esta publicación?',
      'cancel': 'Cancelar',
      'like': 'Me gusta',
      'comment': 'Comentar',
      'share': 'Compartir',
      'create_post': 'Crear publicación',
      'error_fetching_posts': 'Error al obtener publicaciones',
    },

    // ── Arabic ───────────────────────────────────────────────────────────
    'ar': {
      'appName': 'Bantou',
      'appSubtitle': 'Je suis parce que nous sommes',
      'loginTab': 'تسجيل الدخول',
      'signUpTab': 'إنشاء حساب',
      'fullNameLabel': 'الاسم الكامل',
      'fullNameHint': 'الاسم',
      'phoneLabel': 'رقم الهاتف',
      'phoneHint': 'الهاتف',
      'emailLabel': 'البريد الإلكتروني',
      'emailHint': 'name@example.com',
      'passwordLabel': 'كلمة المرور',
      'passwordHint': '••••••••',
      'confirmPasswordLabel': 'تأكيد كلمة المرور',
      'enterName': 'أدخل اسمك',
      'enterPhone': 'أدخل رقم هاتفك',
      'invalidPhone': 'أدخل رقم هاتف صحيح',
      'enterEmail': 'أدخل بريدك الإلكتروني',
      'enterPassword': 'أدخل كلمة المرور',
      'passwordTooShort': 'يجب أن تكون كلمة المرور 6 أحرف على الأقل',
      'passwordsDoNotMatch': 'كلمات المرور غير متطابقة',
      'forgotPassword': 'نسيت كلمة المرور؟',
      'signIn': 'تسجيل الدخول',
      'createAccount': 'إنشاء حساب',
      'orDivider': 'أو',
      'newToBantou': 'جديد على Bantou؟ ',
      'createAnAccount': 'إنشاء حساب',
      'alreadyHaveAccount': 'لديك حساب بالفعل؟ ',
      'signInLink': 'تسجيل الدخول',
      'continueWithFacebook': 'المتابعة مع Facebook',
      'welcomeBack': '👋 مرحباً بعودتك!',
      'communityWaiting': 'مجتمعك ينتظرك.',
      'circles': 'الدوائر',
      'circlesSubtitle': 'عرض وإدارة دوائرك',
      'events': 'الفعاليات',
      'eventsSubtitle': 'الفعاليات القادمة في دوائرك',
      'helpPosts': 'طلبات المساعدة',
      'helpPostsSubtitle': 'تصفح ونشر طلبات المساعدة',
      'profile': 'الملف الشخصي',
      'profileSubtitle': 'إدارة حسابك وإعداداتك',
      'signOut': 'تسجيل الخروج',
      'changeLanguage': 'تغيير اللغة',
      'copyright': '\u00a9 2026 Bantou. جميع الحقوق محفوظة.',
      // Forgot password screen
      'fpTitle': 'نسيت كلمة المرور',
      'fpSubtitleStep1': 'أدخل عنوان بريدك الإلكتروني المسجل.',
      'fpSubtitleStep2': 'قم بتعيين كلمة مرور جديدة لحسابك.',
      'fpEmailLabel': 'البريد الإلكتروني',
      'fpEmailHint': 'أدخل بريدك الإلكتروني',
      'fpEmailRequired': 'الرجاء إدخال بريدك الإلكتروني',
      'fpVerifyButton': 'إرسال الرمز',
      'fpOtpSubtitle': 'أدخل الرمز المكون من 6 أرقام المرسل إلى بريدك.',
      'fpOtpLabel': 'رمز التحقق',
      'fpOtpHint': '••••••',
      'fpOtpButton': 'تحقق من الرمز',
      'fpOtpResend': 'إعادة إرسال الرمز',
      'fpOtpResendIn': 'إعادة الإرسال خلال',
      'fpOtpInvalid': 'يجب أن يتكون الرمز من 6 أرقام',
      'fpSubtitleStep3': 'قم بتعيين كلمة مرور جديدة لحسابك.',
      'fpNewPasswordLabel': 'كلمة مرور جديدة',
      'fpNewPasswordHint': 'أدخل كلمة المرور الجديدة',
      'fpMinChars': 'الحد الأدنى 6 أحرف',
      'fpConfirmLabel': 'تأكيد كلمة المرور',
      'fpConfirmHint': 'أعد إدخال كلمة المرور الجديدة',
      'fpPasswordsMismatch': 'كلمات المرور غير متطابقة',
      'fpResetButton': 'إعادة تعيين كلمة المرور',
      'fpSuccessTitle': 'تم تغيير كلمة المرور!',
      'fpSuccessSubtitle':
          'تم تحديث كلمة مرورك بنجاح.\nيمكنك الآن تسجيل الدخول بكلمة مرورك الجديدة.',
      'fpGoToLogin': 'الذهاب إلى تسجيل الدخول',
      // Profile Setup screen
      'psStepTitle': 'الخطوة 2 من 2',
      'psHeaderTitle': 'إعداد الملف الشخصي',
      'psHeroTitle': 'أكمل ملفك الشخصي',
      'psHeroSubtitle':
          'ساعد مجتمعك في التعرف عليك.\nيمكنك دائماً تحديث هذا لاحقاً.',
      'psAvatarTitle': 'اختر صورتك الرمزية',
      'psAvatarSelected': 'مُحدد',
      'psProfInfoTitle': 'معلومات مهنية',
      'psCompanyLabel': 'الشركة / المنظمة',
      'psCompanyHint': 'مثال: صناعات بانتو',
      'psJobLabel': 'المسمى الوظيفي',
      'psJobHint': 'مثال: مدير مجتمع',
      'psRoleHint': 'دورك في المجتمع',
      'psAboutTitle': 'عن شركتك',
      'psCityLabel': 'المدينة / الموقع',
      'psCityHint': 'مثال: الدار البيضاء، المغرب',
      'psBioHint': 'نبذة قصيرة عنك أو عن مجتمعك…',
      'psOnlineTitle': 'التواجد على الإنترنت',
      'psWebLabel': 'الموقع الإلكتروني / لينكد إن (اختياري)',
      'psWebHint': 'https://...',
      'psSaveBtn': 'حفظ ومتابعة',
      'psSkipBtn': 'تخطي الآن',
      'psAvatarTooltips': [
        'شركات / أعمال',
        'مالية / مؤسسة',
        'تعليم / أكاديمي',
        'هندسة / تقني',
        'برمجيات / تكنولوجيا',
        'تصميم / إبداعي',
        'تسويق / اتصالات',
        'قانون / عدالة',
        'صحة / طبي',
        'طعام / ضيافة',
        'دعم العملاء',
        'علوم / بحث',
        'هندسة معمارية / تخطيط',
        'إعلام / تصوير',
        'صوت / ترفيه',
        'دولي / منظمة غير حكومية',
      ],
      // Create Association screen
      'caTitle': 'إنشاء جمعية',
      'caSubtitle': 'أعدّ ملف جمعيتك للبدء.',
      'caLogoLabel': 'شعار الجمعية',
      'caLogoBtn': 'رفع الشعار',
      'caNameLabel': 'اسم الجمعية',
      'caNameHint': 'مثال: شبكة شباب بانتو',
      'caNameRequired': 'الرجاء إدخال اسم الجمعية',
      'caAddressLabel': 'العنوان',
      'caAddressHint': 'الشارع، المدينة، البلد',
      'caEmailsSectionTitle': 'بريد التواصل',
      'caEmailHint': 'email@example.com',
      'caAddEmailBtn': '+ إضافة بريد إلكتروني',
      'caPhonesSectionTitle': 'هواتف التواصل',
      'caPhoneHint': 'مثال: +212 600 000 000',
      'caAddPhoneBtn': '+ إضافة هاتف',
      'caRemoveBtn': 'إزالة',
      'caAdminEmailsTitle': 'رسائل البريد الإلكتروني للمسؤولين',
      'caAdminEmailHint': 'admin@example.com',
      'caAddAdminEmailBtn': '+ إضافة بريد إلكتروني لمسؤول',
      'caSocialTitle': 'وسائل التواصل الاجتماعي',
      'caFbHint': 'رابط فيسبوك',
      'caLinkedInHint': 'رابط لينكد إن',
      'caXHint': 'رابط إكس (تويتر)',
      'caSubmitBtn': 'حفظ ومتابعة',
      'caEmailRequired': 'الرجاء إدخال بريد إلكتروني واحد على الأقل',
      'caPhoneRequired': 'الرجاء إدخال رقم هاتف واحد على الأقل',

      // Circle Dashboard
      'cdTitle': 'لوحة تحكم الدائرة',
      'cdCircleNameLabel': 'اسم الدائرة',
      'cdCircleNameHint': 'مثال: فريق التصميم',
      'cdCountryLabel': 'البلد',
      'cdCountryHint': 'مثال: المغرب',
      'cdCityLabel': 'المدينة',
      'cdCityHint': 'مثال: الدار البيضاء',
      'cdResponsibleLabel': 'المسؤول عن الدائرة',
      'cdResponsibleHint': 'اسم المسؤول',
      'cdViceResponsibleLabel': 'نائب المسؤول',
      'cdViceResponsibleHint': 'اسم نائب المسؤول',
      'cdMeetingPlanningLabel': 'تخطيط الاجتماعات',
      'cdMeetingPlanningHint': 'مثال: كل يوم اثنين الساعة 10 صباحًا',
      'cdSaveBtn': 'حفظ التغييرات',
      'cdActionRequired': 'إجراء مطلوب',
      'cdActionMsg': 'يرجى إكمال ملفك الشخصي لفتح جميع الميزات (مثل إنشاء دوائر).',
      'cdCompleteProfile': 'إكمال الملف الشخصي',
      'cdWelcome': 'مرحباً بـعودتك،',
      'cdMeetingsThisWeek': 'لديك {count} اجتماعات مقررة هذا الأسبوع.',
      'cdTotalCircles': 'إجمالي الدوائر',
      'cdActiveMembers': 'الأعضاء النشطين',
      'cdMeetings': 'الاجتماعات',
      'cdAssocCircles': 'دوائر جمعيتك',
      'cdViewMap': 'عرض الخريطة',
      'cdSearch': 'ابحث عن الدوائر أو الأماكن...',
      'cdNoCircles': 'لا توجد دوائر بعد.\nاضغط على دائرة جديدة للبدء!',
      'cdNoSearchResults': 'لم يتم العثور على دوائر تطابق بحثك.',
      'cdNewCircle': 'دائرة جديدة',
      'cdActive': 'نشط',
      'cdNoDate': 'لم يتم تحديد تاريخ',
      'cdMeetingLabel': 'اجتماع',
      'cdResponsibleSmall': 'المسؤول',
      'cdViceResponsibleSmall': 'نائب المسؤول',
      'cdNoAssoc': 'لا توجد جمعية مرتبطة',

      // Create Circle & Circle Details
      'cdCreateCircleTitle': 'إنشاء دائرة',
      'cdCircleDetailsTitle': 'تفاصيل الدائرة',
      'cdDescriptionOptional': 'الوصف (اختياري)',
      'cdDescriptionHintText': 'صف الغرض من هذه الدائرة...',
      'cdVisibilityAccess': 'الرؤية والوصول',
      'cdPublic': 'عام',
      'cdPrivate': 'خاص',
      'cdInviteMembers': 'دعوة الأعضاء',
      'cdSearchAddMembers': 'البحث وإضافة أعضاء',
      'cdLeadership': 'القيادة',
      'cdSchedule': 'الجدول الزمني',
      'cdCircleSavedSuccess': 'تم حفظ الدائرة بنجاح!',
      'cdAddMember': 'إضافة عضو',
      'cdSearchNameEmail': 'البحث بالاسم أو البريد الإلكتروني',
      'cdCancel': 'إلغاء',
      'cdNoMembersFound': 'لم يتم العثور على أعضاء.',
      'cdUnknownCircle': 'دائرة غير معروفة',
      'cdNoDescriptionProvided': 'لم يتم تقديم وصف.',
      'cdCircleLeadership': 'قيادة الدائرة',
      'cdUpcomingMeetings': 'الاجتماعات القادمة',
      'cdViewCalendar': 'عرض التقويم',
      'cdNextSync': 'المزامنة التالية',
      'cdMeetingGallery': 'معرض الاجتماعات',
      'cdAddPhoto': 'إضافة صورة',
      'cdNoPhotosYet': 'لا توجد صور بعد',
      'cdTakeFirstSnapshot': 'التقط أول صورة لاجتماعك!',
      'cdPhotoUploadedSuccess': 'تم رفع الصورة إلى المعرض بنجاح!',
      'cdCircleParticipants': 'المشاركون في الدائرة',
      'cdViewAll': 'عرض الكل',
      'cdManageParticipation': 'إدارة المشاركة',
      'cdSeeWhoJoined': 'شاهد من انضم إلى هذه الدائرة',
      'cdEditCircle': 'تعديل الدائرة',
      'cdCircleUpdatedSuccess': 'تم تحديث الدائرة بنجاح!',
      'cdJoined': 'انضم',
      'cdNotJoined': 'لم ينضم',
      'prTitle': 'الطلبات المعلقة',
      'prNoRequests': 'لا توجد طلبات معلقة.',
      'prAdmin': 'المسؤول',
      'prReject': 'رفض',
      'prApprove': 'موافقة',
      'prRequestAction': 'تم {status} الطلب',
      'cdRequestsBtn': 'الطلبات',
      'cdInviteToCircle': 'دعوة إلى {name}',
      'cdEmailAddress': 'البريد الإلكتروني',
      'cdSend': 'إرسال',
      'cdInviteAppMember': 'دعوة عضو جديد',
      'cdSendInvite': 'إرسال الدعوة',
      'cdInviteToCircleBtn': 'دعوة إلى الدائرة',
      'cdInviteBtn': 'دعوة',
      'cdParticipateBtn': 'مشاركة',
      'cdLeaveBtn': 'مغادرة',
      'cdJoinBtn': 'انضمام',
      'cdPendingApproval': 'في انتظار الموافقة',
      'cdRequestAccess': 'طلب انضمام',
      'cdMemberOfCircle': 'أنت عضو في هذه الدائرة',
      // Posts
      'posts_feed': 'آخر المنشورات',
      'share_an_update': 'شارك تحديثاً مع دائرتك...',
      'photo': 'صورة',
      'delete_post': 'حذف المنشور',
      'delete_post_confirmation': 'هل أنت متأكد أنك تريد حذف هذا المنشور؟',
      'cancel': 'إلغاء',
      'like': 'إعجاب',
      'comment': 'تعليق',
      'share': 'مشاركة',
      'create_post': 'إنشاء منشور',
      'error_fetching_posts': 'خطأ في جلب المنشورات',
    },
  };

  // ── String accessor ───────────────────────────────────────────────────────

  String _t(String key) =>
      (_translations[locale.languageCode]?[key] ??
              _translations['en']![key] ??
              key)
          as String;

  // ── Getters ───────────────────────────────────────────────────────────────

  String get appName => _t('appName');
  String get appSubtitle => _t('appSubtitle');
  String get loginTab => _t('loginTab');
  String get signUpTab => _t('signUpTab');

  // Fields
  String get fullNameLabel => _t('fullNameLabel');
  String get fullNameHint => _t('fullNameHint');
  String get phoneLabel => _t('phoneLabel');
  String get phoneHint => _t('phoneHint');
  String get emailLabel => _t('emailLabel');
  String get emailHint => _t('emailHint');
  String get passwordLabel => _t('passwordLabel');
  String get passwordHint => _t('passwordHint');
  String get confirmPasswordLabel => _t('confirmPasswordLabel');

  // Validation
  String get enterName => _t('enterName');
  String get enterPhone => _t('enterPhone');
  String get invalidPhone => _t('invalidPhone');
  String get enterEmail => _t('enterEmail');
  String get enterPassword => _t('enterPassword');
  String get passwordTooShort => _t('passwordTooShort');
  String get passwordsDoNotMatch => _t('passwordsDoNotMatch');

  // Buttons & links
  String get forgotPassword => _t('forgotPassword');
  String get signIn => _t('signIn');
  String get createAccount => _t('createAccount');
  String get orDivider => _t('orDivider');
  String get newToBantou => _t('newToBantou');
  String get createAnAccount => _t('createAnAccount');
  String get alreadyHaveAccount => _t('alreadyHaveAccount');
  String get signInLink => _t('signInLink');

  // Social
  String get continueWithFacebook => _t('continueWithFacebook');

  // Home
  String get welcomeBack => _t('welcomeBack');
  String get communityWaiting => _t('communityWaiting');
  String get circles => _t('circles');
  String get circlesSubtitle => _t('circlesSubtitle');
  String get events => _t('events');
  String get eventsSubtitle => _t('eventsSubtitle');
  String get helpPosts => _t('helpPosts');
  String get helpPostsSubtitle => _t('helpPostsSubtitle');
  String get profile => _t('profile');
  String get profileSubtitle => _t('profileSubtitle');
  String get signOut => _t('signOut');

  // Language picker
  String get changeLanguage => _t('changeLanguage');

  // Copyright
  String get copyright => _t('copyright');

  // Forgot password screen
  String get fpTitle => _t('fpTitle');
  String get fpSubtitleStep1 => _t('fpSubtitleStep1');
  String get fpSubtitleStep2 => _t('fpSubtitleStep2');
  String get fpEmailLabel => _t('fpEmailLabel');
  String get fpEmailHint => _t('fpEmailHint');
  String get fpEmailRequired => _t('fpEmailRequired');
  String get fpVerifyButton => _t('fpVerifyButton');
  String get fpOtpSubtitle => _t('fpOtpSubtitle');
  String get fpOtpLabel => _t('fpOtpLabel');
  String get fpOtpHint => _t('fpOtpHint');
  String get fpOtpButton => _t('fpOtpButton');
  String get fpOtpResend => _t('fpOtpResend');
  String get fpOtpResendIn => _t('fpOtpResendIn');
  String get fpOtpInvalid => _t('fpOtpInvalid');
  String get fpSubtitleStep3 => _t('fpSubtitleStep3');
  String get fpNewPasswordLabel => _t('fpNewPasswordLabel');
  String get fpNewPasswordHint => _t('fpNewPasswordHint');
  String get fpMinChars => _t('fpMinChars');
  String get fpConfirmLabel => _t('fpConfirmLabel');
  String get fpConfirmHint => _t('fpConfirmHint');
  String get fpPasswordsMismatch => _t('fpPasswordsMismatch');
  String get fpResetButton => _t('fpResetButton');
  String get fpSuccessTitle => _t('fpSuccessTitle');
  String get fpSuccessSubtitle => _t('fpSuccessSubtitle');
  String get fpGoToLogin => _t('fpGoToLogin');

  // Profile Setup screen
  String get psStepTitle => _t('psStepTitle');
  String get psHeaderTitle => _t('psHeaderTitle');
  String get psHeroTitle => _t('psHeroTitle');
  String get psHeroSubtitle => _t('psHeroSubtitle');
  String get psAvatarTitle => _t('psAvatarTitle');
  String get psAvatarSelected => _t('psAvatarSelected');
  String get psProfInfoTitle => _t('psProfInfoTitle');
  String get psCompanyLabel => _t('psCompanyLabel');
  String get psCompanyHint => _t('psCompanyHint');
  String get psJobLabel => _t('psJobLabel');
  String get psJobHint => _t('psJobHint');
  String get psRoleHint => _t('psRoleHint');
  String get psAboutTitle => _t('psAboutTitle');
  String get psCityLabel => _t('psCityLabel');
  String get psCityHint => _t('psCityHint');
  String get psBioHint => _t('psBioHint');
  String get psOnlineTitle => _t('psOnlineTitle');
  String get psWebLabel => _t('psWebLabel');
  String get psWebHint => _t('psWebHint');
  String get psSaveBtn => _t('psSaveBtn');
  String get psSkipBtn => _t('psSkipBtn');

  // Create Association screen
  String get caTitle => _t('caTitle');
  String get caSubtitle => _t('caSubtitle');
  String get caLogoLabel => _t('caLogoLabel');
  String get caLogoBtn => _t('caLogoBtn');
  String get caNameLabel => _t('caNameLabel');
  String get caNameHint => _t('caNameHint');
  String get caNameRequired => _t('caNameRequired');
  String get caAddressLabel => _t('caAddressLabel');
  String get caAddressHint => _t('caAddressHint');
  String get caEmailsSectionTitle => _t('caEmailsSectionTitle');
  String get caEmailHint => _t('caEmailHint');
  String get caAddEmailBtn => _t('caAddEmailBtn');
  String get caPhonesSectionTitle => _t('caPhonesSectionTitle');
  String get caPhoneHint => _t('caPhoneHint');
  String get caAddPhoneBtn => _t('caAddPhoneBtn');
  String get caRemoveBtn => _t('caRemoveBtn');
  String get caAdminEmailsTitle => _t('caAdminEmailsTitle');
  String get caAdminEmailHint => _t('caAdminEmailHint');
  String get caAddAdminEmailBtn => _t('caAddAdminEmailBtn');
  String get caSocialTitle => _t('caSocialTitle');
  String get caFbHint => _t('caFbHint');
  String get caLinkedInHint => _t('caLinkedInHint');
  String get caXHint => _t('caXHint');
  String get caSubmitBtn => _t('caSubmitBtn');
  String get caEmailRequired => _t('caEmailRequired');
  String get caPhoneRequired => _t('caPhoneRequired');

  // Circle Dashboard (Form)
  String get cdTitle => _t('cdTitle');
  String get cdCircleNameLabel => _t('cdCircleNameLabel');
  String get cdCircleNameHint => _t('cdCircleNameHint');
  String get cdCountryLabel => _t('cdCountryLabel');
  String get cdCountryHint => _t('cdCountryHint');
  String get cdCityLabel => _t('cdCityLabel');
  String get cdCityHint => _t('cdCityHint');
  String get cdResponsibleLabel => _t('cdResponsibleLabel');
  String get cdResponsibleHint => _t('cdResponsibleHint');
  String get cdViceResponsibleLabel => _t('cdViceResponsibleLabel');
  String get cdViceResponsibleHint => _t('cdViceResponsibleHint');
  String get cdMeetingPlanningLabel => _t('cdMeetingPlanningLabel');
  String get cdMeetingPlanningHint => _t('cdMeetingPlanningHint');
  String get cdSaveBtn => _t('cdSaveBtn');
  String get cdActionRequired => _t('cdActionRequired');
  String get cdActionMsg => _t('cdActionMsg');
  String get cdCompleteProfile => _t('cdCompleteProfile');
  String get cdWelcome => _t('cdWelcome');
  String cdMeetingsThisWeek(int count) => _t('cdMeetingsThisWeek').toString().replaceAll('{count}', count.toString());
  String get cdTotalCircles => _t('cdTotalCircles');
  String get cdActiveMembers => _t('cdActiveMembers');
  String get cdMeetings => _t('cdMeetings');
  String get cdAssocCircles => _t('cdAssocCircles');
  String get cdViewMap => _t('cdViewMap');
  String get cdSearch => _t('cdSearch');
  String get cdNoCircles => _t('cdNoCircles');
  String get cdNoSearchResults => _t('cdNoSearchResults');
  String get cdNewCircle => _t('cdNewCircle');
  String get cdActive => _t('cdActive');
  String get cdNoDate => _t('cdNoDate');
  String get cdMeetingLabel => _t('cdMeetingLabel');
  String get cdResponsibleSmall => _t('cdResponsibleSmall');
  String get cdViceResponsibleSmall => _t('cdViceResponsibleSmall');
  String get cdNoAssoc => _t('cdNoAssoc');

  // We cast to List<String> since this specific key is a list
  List<String> get psAvatarTooltips {
    final val =
        _translations[locale.languageCode]?['psAvatarTooltips'] ??
        _translations['en']!['psAvatarTooltips'];
    return (val as List<dynamic>?)?.cast<String>() ?? [];
  }

  // Create Circle & Circle Details
  String get cdCreateCircleTitle => _t('cdCreateCircleTitle');
  String get cdCircleDetailsTitle => _t('cdCircleDetailsTitle');
  String get cdDescriptionOptional => _t('cdDescriptionOptional');
  String get cdDescriptionHintText => _t('cdDescriptionHintText');
  String get cdVisibilityAccess => _t('cdVisibilityAccess');
  String get cdPublic => _t('cdPublic');
  String get cdPrivate => _t('cdPrivate');
  String get cdInviteMembers => _t('cdInviteMembers');
  String get cdSearchAddMembers => _t('cdSearchAddMembers');
  String get cdLeadership => _t('cdLeadership');
  String get cdSchedule => _t('cdSchedule');
  String get cdCircleSavedSuccess => _t('cdCircleSavedSuccess');
  String get cdAddMember => _t('cdAddMember');
  String get cdSearchNameEmail => _t('cdSearchNameEmail');
  String get cdCancel => _t('cdCancel');
  String get cdNoMembersFound => _t('cdNoMembersFound');
  String get cdUnknownCircle => _t('cdUnknownCircle');
  String get cdNoDescriptionProvided => _t('cdNoDescriptionProvided');
  String get cdCircleLeadership => _t('cdCircleLeadership');
  String get cdUpcomingMeetings => _t('cdUpcomingMeetings');
  String get cdViewCalendar => _t('cdViewCalendar');
  String get cdNextSync => _t('cdNextSync');
  String get cdMeetingGallery => _t('cdMeetingGallery');
  String get cdAddPhoto => _t('cdAddPhoto');
  String get cdNoPhotosYet => _t('cdNoPhotosYet');
  String get cdTakeFirstSnapshot => _t('cdTakeFirstSnapshot');
  String get cdPhotoUploadedSuccess => _t('cdPhotoUploadedSuccess');
  String get cdCircleParticipants => _t('cdCircleParticipants');
  String get cdViewAll => _t('cdViewAll');
  String get cdManageParticipation => _t('cdManageParticipation');
  String get cdSeeWhoJoined => _t('cdSeeWhoJoined');
  String get cdEditCircle => _t('cdEditCircle');
  String get cdCircleUpdatedSuccess => _t('cdCircleUpdatedSuccess');
  String get cdJoined => _t('cdJoined');
  String get cdNotJoined => _t('cdNotJoined');

  // Pending Requests
  String get prTitle => _t('prTitle');
  String get prNoRequests => _t('prNoRequests');
  String get prAdmin => _t('prAdmin');
  String get prReject => _t('prReject');
  String get prApprove => _t('prApprove');
  String prRequestAction(String status) {
    if (locale.languageCode == 'ar') {
      final st = status == 'Approved' ? 'الموافقة على' : 'رفض';
      return _t('prRequestAction').replaceAll('{status}', st);
    } else if (locale.languageCode == 'fr') {
      final st = status == 'Approved' ? 'approuvée' : 'rejetée';
      return _t('prRequestAction').replaceAll('{status}', st);
    } else if (locale.languageCode == 'es') {
      final st = status == 'Approved' ? 'aprobada' : 'rechazada';
      return _t('prRequestAction').replaceAll('{status}', st);
    }
    return _t('prRequestAction').replaceAll('{status}', status);
  }

  // Dashboard missing
  String get cdRequestsBtn => _t('cdRequestsBtn');
  String cdInviteToCircle(String name) => _t('cdInviteToCircle').replaceAll('{name}', name);
  String get cdEmailAddress => _t('cdEmailAddress');
  String get cdSend => _t('cdSend');
  String get cdInviteAppMember => _t('cdInviteAppMember');
  String get cdSendInvite => _t('cdSendInvite');
  String get cdInviteToCircleBtn => _t('cdInviteToCircleBtn');
  String get cdInviteBtn => _t('cdInviteBtn');
  String get cdParticipateBtn => _t('cdParticipateBtn');
  String get cdLeaveBtn => _t('cdLeaveBtn');
  String get cdJoinBtn => _t('cdJoinBtn');
  String get cdPendingApproval => _t('cdPendingApproval');
  String get cdRequestAccess => _t('cdRequestAccess');
  String get cdMemberOfCircle => _t('cdMemberOfCircle');

  // Posts
  String get postsFeed => _t('posts_feed');
  String get shareAnUpdate => _t('share_an_update');
  String get photo => _t('photo');
  String get deletePost => _t('delete_post');
  String get deletePostConfirmation => _t('delete_post_confirmation');
  String get cancel => _t('cancel');
  String get like => _t('like');
  String get comment => _t('comment');
  String get share => _t('share');
  String get createPost => _t('create_post');
  String get errorFetchingPosts => _t('error_fetching_posts');

  // Dynamic enum translation
  String translateStatus(String status) {
    if (status == 'Active') return cdActive;
    if (status == 'Public') return cdPublic;
    if (status == 'Private') return cdPrivate;
    return status;
  }
}

// ── Delegate ──────────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  static const _supported = ['en', 'fr', 'es', 'ar'];

  @override
  bool isSupported(Locale locale) => _supported.contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
