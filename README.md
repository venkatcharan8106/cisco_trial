# Ember Ledger

Ember Ledger is a calendar-first, offline expense tracker built with Flutter for Android, iOS, and Web. Financial data remains local: Android and iOS use SQLite on the device, while Web uses browser-local SQLite/WASM persistence through `sqflite_common_ffi_web`.

There is currently no cloud or server database, backend API, authentication, login, or signup flow.

## Included

- Fully selectable past, present, and future dates with an original dark orange-red calendar UI.
- Per-date transactions, per-month income/spending/remaining totals, transaction dots, and smooth month swiping.
- Add, edit, delete (with confirmation), and full-history search.
- Local persistent SQLite storage (`transactions.db`) with dates stored as timezone-safe `yyyy-MM-dd` local calendar days.
- Responsive layouts, semantic labels, keyboard-safe sheets, validation, and INR currency formatting.

## Run

```bash
flutter pub get
flutter run                 # Android device or emulator
flutter run -d chrome       # Web browser testing
```

iOS development and builds require macOS with Xcode:

```bash
flutter run -d ios
flutter build ios
```

The generated Android and iOS folders contain the platform runners and do not replace the application source under `lib/`.

## Web build

```bash
flutter build web
python -m http.server 8000 --directory build/web
```

Open `http://localhost:8000` in a browser. Web data is stored in that browser's local storage through the SQLite/WASM adapter; it is not sent to a server.

## Verification

```bash
flutter analyze
flutter test
flutter build apk
```

## Architecture

`lib/models` defines immutable records and aggregate values. `lib/data` owns SQLite schema and queries. `lib/state` is the single UI controller and reload boundary. `lib/ui` contains screens and reusable widgets. This keeps storage replaceable if cloud backup is added later.
