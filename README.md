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
- `docs/Accessories_DesignOptions.pdf`: PDF-Grundlage fuer Accessoires

## PDF-Stand

Das Dokument `Accessories_DesignOptions.pdf` liegt im Workspace unter:
`docs/Accessories_DesignOptions.pdf`.

Die Accessoire-Konfigurationen in `lib/data/suit_config_template.dart`
wurden auf Basis des PDFs erweitert:
- Krawatte (Verarbeitung, Weite, Laenge, Monogramm, Thread colour card)
- Fliege (Verarbeitung, Weite, Monogramm, Thread colour card)
- Einstecktuch (Verarbeitung, Monogramm, Thread colour card)
- Cummerbund (Model, Monogramm, Thread colour card)

## Voraussetzungen

- Flutter SDK (laut `pubspec.yaml`)
- Plattform-Setup (Android/iOS/Web/Desktop je nach Ziel)

## Starten

```bash
flutter pub get
flutter run
```

## GitHub Pages (Web-Preview)

Es gibt einen Workflow fuer Deployment nach GitHub Pages:
- Datei: `.github/workflows/deploy-pages.yml`
- Trigger: Push auf `main` oder `cursor/suit-configuration-app-a05a`, sowie manuell per `workflow_dispatch`
- Verhalten:
  - Auf Feature-Branch: Web-Build + Deployment-Versuch
  - Wenn der Branch durch Environment-Policy nicht freigegeben ist, wird ein Fallback-Deploy ohne Environment-Gate versucht
  - Wenn GitHub Pages deaktiviert ist, wird Deploy sauber geskippt (kein Pipeline-Fehler)
  - Auf `main`: Build + echtes Deployment auf GitHub Pages
  - Web-Build nutzt `--pwa-strategy=none`, damit neue Releases ohne Service-Worker-Stale-Cache sichtbar werden

Nach einem erfolgreichen Run ist die App unter folgender URL erreichbar:
`https://issagithub.github.io/AnzugGenerator/`

Wenn GitHub Pages im Repository noch nicht aktiv ist, in den Repo-Settings unter
**Pages** als Quelle **GitHub Actions** auswaehlen.

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

## Virtual Fitting (KI-Bildgenerierung)

Die App hat einen eigenen Schritt **Virtual Fitting**:
- Kundenfoto aus Galerie/Kamera waehlen
- KI-Vorschaubild mit Anzug/Accessoire-Kontext erzeugen
- Ergebnis in der Zusammenfassung anzeigen
- Ergebnisbild wird (falls vorhanden) mit der E-Mail mitgesendet

Konfiguration per `--dart-define`:

```bash
flutter run \
  --dart-define=VIRTUAL_FIT_API_URL=https://dein-endpoint.example/api/virtual-fitting \
  --dart-define=VIRTUAL_FIT_API_KEY=dein-api-key \
  --dart-define=VIRTUAL_FIT_MODEL=virtual-fitting-v1
```

### Erwartetes API-Format

`POST` Multipart mit:
- `customer_image` (Datei)
- `prompt` (String)
- `model` (String)

Erwartete Antwortvarianten:
- Bild direkt als `image/*`
- JSON mit `imageUrl` / `image_url` / `url`
- JSON mit `imageBase64` / `image_base64` / `b64_json`
