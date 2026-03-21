# AnzugGenerator

Flutter-App fuer die Konfiguration von Anzuegen mit:
- mehrstufigem Konfigurator (Kundendaten, Anzugdetails, Zusammenfassung),
- digitaler Unterschrift,
- E-Mail-Bestaetigung an den Kunden (mit Signatur als Anhang).

## Projektstruktur

- `lib/main.dart`: App-Flow und UI (Stepper + Formvalidierung)
- `lib/data/suit_config_template.dart`: zentrale Konfigurationsoptionen
- `lib/services/email_service.dart`: SMTP-Versand inkl. Signatur-Anhang
- `lib/services/order_summary_builder.dart`: Bestelltext fuer Anzeige und E-Mail
- `lib/models/*`: Datenmodelle

## Wichtig zum PDF

Das vom Auftrag genannte PDF war in diesem Workspace nicht verfuegbar.
Die Konfigurationspunkte sind daher als saubere Platzhalter in
`lib/data/suit_config_template.dart` hinterlegt und koennen dort direkt
1:1 mit den PDF-Feldern ersetzt werden.

## Voraussetzungen

- Flutter SDK (laut `pubspec.yaml`)
- Plattform-Setup (Android/iOS/Web/Desktop je nach Ziel)

## Starten

```bash
flutter pub get
flutter run
```

## SMTP fuer echten E-Mail-Versand konfigurieren

Der Versand nutzt `--dart-define` Konfiguration:

```bash
flutter run \
  --dart-define=SMTP_HOST=smtp.dein-provider.de \
  --dart-define=SMTP_PORT=587 \
  --dart-define=SMTP_USER=servicekonto@firma.de \
  --dart-define=SMTP_PASSWORD=dein-passwort \
  --dart-define=SELLER_EMAIL=verkauf@firma.de \
  --dart-define=SENDER_NAME=Anzug\ Verkauf
```

Optional:
- `--dart-define=SMTP_USE_SSL=true`
- `--dart-define=SMTP_ALLOW_INSECURE=true`
