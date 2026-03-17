import re

file_path = r"c:\Users\ilyas\Desktop\project PFE\circleback\lib\screens\circles\circle_dashboard_screen.dart"

with open(file_path, "r", encoding="utf-8") as f:
    c = f.read()

# 1. Imports
c = c.replace(
    "import 'create_circle_screen.dart';",
    "import 'create_circle_screen.dart';\nimport '../../widgets/language_picker.dart';\nimport '../../l10n/app_localizations.dart';"
)

# 2. Add LanguagePicker
c = c.replace(
"""          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            onPressed: () async {""",
"""          const LanguagePicker(),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            onPressed: () async {"""
)

# 3. Replacements
reps = [
    ("'No circles created yet.\\nTap New Circle to get started!'", "AppLocalizations.of(context).cdNoCircles"),
    ("'New Circle'", "AppLocalizations.of(context).cdNewCircle"),
    ("'Action Required'", "AppLocalizations.of(context).cdActionRequired"),
    ("'Please complete your profile to unlock full administrative features (e.g., creating circles).'", "AppLocalizations.of(context).cdActionMsg"),
    ("'Complete Profile'", "AppLocalizations.of(context).cdCompleteProfile"),
    ("'Bantou'", "AppLocalizations.of(context).appName"),
    ("'Je suis parce que nous sommes'", "AppLocalizations.of(context).appSubtitle"),
    ("'Welcome back, $firstName'", "'${AppLocalizations.of(context).cdWelcome} $firstName'"),
    ("'You have 3 meetings scheduled this week.'", "AppLocalizations.of(context).cdMeetingsThisWeek"),
    ("'Total Circles'", "AppLocalizations.of(context).cdTotalCircles"),
    ("'Active Members'", "AppLocalizations.of(context).cdActiveMembers"),
    ("'Meetings'", "AppLocalizations.of(context).cdMeetings"),
    ("'Your Association Circles'", "AppLocalizations.of(context).cdAssocCircles"),
    ("'View Map'", "AppLocalizations.of(context).cdViewMap"),
    ("'Search circles or locations...'", "AppLocalizations.of(context).cdSearch"),
    ("?? 'Active'", "?? AppLocalizations.of(context).cdActive"),
    ("'No date set'", "AppLocalizations.of(context).cdNoDate"),
    ("Text(\n                  'Meeting',", "Text(\n                  AppLocalizations.of(context).cdMeetingLabel,"),
    ("'Responsible'", "AppLocalizations.of(context).cdResponsibleSmall"),
    ("'Vice-Responsible'", "AppLocalizations.of(context).cdViceResponsibleSmall"),
    ('displayAssociationName = _associationName ?? "No Association Attached";', "displayAssociationName = _associationName ?? AppLocalizations.of(context).cdNoAssoc;")
]

for src, tgt in reps:
    c = c.replace(src, tgt)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(c)

print("done")
