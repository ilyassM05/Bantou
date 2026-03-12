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

  // Circle Dashboard
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

  // We cast to List<String> since this specific key is a list
  List<String> get psAvatarTooltips {
    final val =
        _translations[locale.languageCode]?['psAvatarTooltips'] ??
        _translations['en']!['psAvatarTooltips'];
    return (val as List<dynamic>?)?.cast<String>() ?? [];
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
