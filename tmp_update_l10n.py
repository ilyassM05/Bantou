import re

# Read the file
with open('c:\\Users\\ilyas\\Desktop\\project PFE\\circleback\\lib\\l10n\\app_localizations.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Strings to add to each language map
new_strings = {
    'en': """      'cdActionRequired': 'Action Required',
      'cdActionMsg': 'Please complete your profile to unlock full administrative features (e.g., creating circles).',
      'cdCompleteProfile': 'Complete Profile',
      'cdWelcome': 'Welcome back,',
      'cdMeetingsThisWeek': 'You have 3 meetings scheduled this week.',
      'cdTotalCircles': 'Total Circles',
      'cdActiveMembers': 'Active Members',
      'cdMeetings': 'Meetings',
      'cdAssocCircles': 'Your Association Circles',
      'cdViewMap': 'View Map',
      'cdSearch': 'Search circles or locations...',
      'cdNoCircles': 'No circles created yet.\\nTap New Circle to get started!',
      'cdNewCircle': 'New Circle',
      'cdActive': 'Active',
      'cdNoDate': 'No date set',
      'cdMeetingLabel': 'Meeting',
      'cdResponsibleSmall': 'Responsible',
      'cdViceResponsibleSmall': 'Vice-Responsible',
      'cdNoAssoc': 'No Association Attached',
""",
    'fr': """      'cdActionRequired': 'Action requise',
      'cdActionMsg': 'Veuillez compléter votre profil pour débloquer toutes les fonctionnalités (ex: créer des cercles).',
      'cdCompleteProfile': 'Compléter le profil',
      'cdWelcome': 'Bon retour,',
      'cdMeetingsThisWeek': 'Vous avez 3 réunions prévues cette semaine.',
      'cdTotalCircles': 'Total des Cercles',
      'cdActiveMembers': 'Membres Actifs',
      'cdMeetings': 'Réunions',
      'cdAssocCircles': 'Cercles de votre association',
      'cdViewMap': 'Voir la carte',
      'cdSearch': 'Rechercher des cercles ou des lieux...',
      'cdNoCircles': 'Aucun cercle créé.\\nAppuyez sur Nouveau Cercle pour commencer !',
      'cdNewCircle': 'Nouveau Cercle',
      'cdActive': 'Actif',
      'cdNoDate': 'Aucune date définie',
      'cdMeetingLabel': 'Réunion',
      'cdResponsibleSmall': 'Responsable',
      'cdViceResponsibleSmall': 'Vice-Responsable',
      'cdNoAssoc': 'Aucune association liée',
""",
    'es': """      'cdActionRequired': 'Acción requerida',
      'cdActionMsg': 'Por favor, completa tu perfil para desbloquear todas las funciones (ej. crear círculos).',
      'cdCompleteProfile': 'Completar perfil',
      'cdWelcome': 'Bienvenido de nuevo,',
      'cdMeetingsThisWeek': 'Tienes 3 reuniones programadas esta semana.',
      'cdTotalCircles': 'Total de Círculos',
      'cdActiveMembers': 'Miembros Activos',
      'cdMeetings': 'Reuniones',
      'cdAssocCircles': 'Círculos de tu asociación',
      'cdViewMap': 'Ver mapa',
      'cdSearch': 'Buscar círculos o lugares...',
      'cdNoCircles': 'No hay círculos creados.\\n¡Toca Nuevo Círculo para empezar!',
      'cdNewCircle': 'Nuevo Círculo',
      'cdActive': 'Activo',
      'cdNoDate': 'Sin fecha',
      'cdMeetingLabel': 'Reunión',
      'cdResponsibleSmall': 'Responsable',
      'cdViceResponsibleSmall': 'Vice-Responsable',
      'cdNoAssoc': 'Ninguna asociación adjunta',
""",
    'ar': """      'cdActionRequired': 'إجراء مطلوب',
      'cdActionMsg': 'يرجى إكمال ملفك الشخصي لفتح جميع الميزات (مثل إنشاء دوائر).',
      'cdCompleteProfile': 'إكمال الملف الشخصي',
      'cdWelcome': 'مرحباً بـعودتك،',
      'cdMeetingsThisWeek': 'لديك 3 اجتماعات مقررة هذا الأسبوع.',
      'cdTotalCircles': 'إجمالي الدوائر',
      'cdActiveMembers': 'الأعضاء النشطين',
      'cdMeetings': 'الاجتماعات',
      'cdAssocCircles': 'دوائر جمعيتك',
      'cdViewMap': 'عرض الخريطة',
      'cdSearch': 'ابحث عن الدوائر أو الأماكن...',
      'cdNoCircles': 'لا توجد دوائر بعد.\\nاضغط على دائرة جديدة للبدء!',
      'cdNewCircle': 'دائرة جديدة',
      'cdActive': 'نشط',
      'cdNoDate': 'لم يتم تحديد تاريخ',
      'cdMeetingLabel': 'اجتماع',
      'cdResponsibleSmall': 'المسؤول',
      'cdViceResponsibleSmall': 'نائب المسؤول',
      'cdNoAssoc': 'لا توجد جمعية مرتبطة',
"""
}

# Add getters
getters = """
  String get cdActionRequired => _t('cdActionRequired');
  String get cdActionMsg => _t('cdActionMsg');
  String get cdCompleteProfile => _t('cdCompleteProfile');
  String get cdWelcome => _t('cdWelcome');
  String get cdMeetingsThisWeek => _t('cdMeetingsThisWeek');
  String get cdTotalCircles => _t('cdTotalCircles');
  String get cdActiveMembers => _t('cdActiveMembers');
  String get cdMeetings => _t('cdMeetings');
  String get cdAssocCircles => _t('cdAssocCircles');
  String get cdViewMap => _t('cdViewMap');
  String get cdSearch => _t('cdSearch');
  String get cdNoCircles => _t('cdNoCircles');
  String get cdNewCircle => _t('cdNewCircle');
  String get cdActive => _t('cdActive');
  String get cdNoDate => _t('cdNoDate');
  String get cdMeetingLabel => _t('cdMeetingLabel');
  String get cdResponsibleSmall => _t('cdResponsibleSmall');
  String get cdViceResponsibleSmall => _t('cdViceResponsibleSmall');
  String get cdNoAssoc => _t('cdNoAssoc');
"""

# Insert strings
import re
for lang in ['en', 'fr', 'es', 'ar']:
    # Find the end of the language block.
    # We look for: 'cdSaveBtn': '...',
    # and insert right after it.
    pattern = r"('cdSaveBtn': '[^']+',)"
    
    # We need to only replace in the specific language block. This is tricky.
    # Let's find the 'lang': { block and replace inside it.
    
    # Alternatively, just find all 'cdSaveBtn' lines and replace them
    # Because they occur once per language block.
    pass

# A simpler way: just append to the end of each language translation block
# For en:
content = content.replace("'cdSaveBtn': 'Save Changes',", "'cdSaveBtn': 'Save Changes',\n" + new_strings['en'])
content = content.replace("'cdSaveBtn': 'Enregistrer',", "'cdSaveBtn': 'Enregistrer',\n" + new_strings['fr'])
content = content.replace("'cdSaveBtn': 'Guardar Cambios',", "'cdSaveBtn': 'Guardar Cambios',\n" + new_strings['es'])
content = content.replace("'cdSaveBtn': 'حفظ التغييرات',", "'cdSaveBtn': 'حفظ التغييرات',\n" + new_strings['ar'])

# Add getters before the last closing brace
content = content.replace("String get caEmailRequired => _t('caEmailRequired');", "String get caEmailRequired => _t('caEmailRequired');" + getters)
# Wait, let's just append getters to the very end of the getters section
content = content.replace("String get cdSaveBtn => _t('cdSaveBtn');", "String get cdSaveBtn => _t('cdSaveBtn');\n" + getters)


with open('c:\\Users\\ilyas\\Desktop\\project PFE\\circleback\\lib\\l10n\\app_localizations.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("success")
