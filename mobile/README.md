# Lessons Mobile (Flutter)

Native Android/iOS build of the **جدول دروسي** lesson scheduler, sharing the same Supabase backend as the web app. Accounts created on the website can log in on the APK (and vice-versa) — lessons, exceptions, and all data stay in sync.

## Features

- Arabic RTL UI, Tajawal font, light + dark themes.
- Username + password auth (matches the web app's `username@lessons.app` fake-email scheme).
- Weekly view with today highlighted, indicator dots for days that have lessons.
- List view grouped by day for the upcoming 60 days.
- Add / edit / delete lessons.
- Single-occurrence edits and deletions via the `lesson_exceptions` table.
- Supabase realtime-ready client (uses RLS policies in `supabase/migrations`).

## Project structure

```
mobile/
├── lib/
│   ├── main.dart                 # entrypoint, Supabase.initialize
│   ├── app.dart                  # MaterialApp, theme mode, RTL
│   ├── theme.dart                # teal + gold palette, gradients
│   ├── models/lesson.dart        # Lesson / LessonException / LessonOccurrence
│   ├── services/
│   │   ├── supabase_config.dart  # project URL + anon key
│   │   ├── auth_service.dart
│   │   └── lessons_service.dart
│   ├── utils/occurrences.dart    # recurrence expansion + exception merge
│   ├── screens/
│   │   ├── root_gate.dart        # auth state listener
│   │   ├── auth_page.dart
│   │   └── home_page.dart        # week/list tabs, FAB, header
│   └── widgets/
│       ├── lesson_card.dart
│       ├── empty_state.dart
│       ├── week_view.dart
│       ├── list_view.dart
│       ├── add_lesson_sheet.dart
│       └── lesson_details_sheet.dart
└── android/                      # label = "جدول دروسي", com.lessons.lessons_mobile
```

## Running

```bash
cd mobile
flutter pub get
flutter run            # debug on a connected device / emulator
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk
```

Requires Flutter ≥ 3.27 and the Android SDK (platforms;android-36, build-tools;36.0.0).

## Supabase configuration

`lib/services/supabase_config.dart` is hard-coded to the same project as the web app. The anon key is public (anon role, RLS-protected) and identical to the `VITE_SUPABASE_*` values in the repo's `.env`. If you rotate the project, update both files.
