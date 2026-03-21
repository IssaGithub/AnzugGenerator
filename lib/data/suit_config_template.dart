import '../models/config_field.dart';

// TODO: Optionen 1:1 aus dem angehaengten PDF uebernehmen, sobald es vorliegt.
const List<ConfigSection> suitConfigurationSections = [
  ConfigSection(
    title: 'Sakko',
    fields: [
      ConfigField(
        key: 'jacket_fit',
        label: 'Passform',
        options: ['Slim Fit', 'Modern Fit', 'Classic Fit'],
      ),
      ConfigField(
        key: 'jacket_size',
        label: 'Groesse',
        options: ['44', '46', '48', '50', '52', '54', '56'],
      ),
      ConfigField(
        key: 'jacket_fabric',
        label: 'Stoffqualitaet',
        options: [
          'Super 110',
          'Super 120',
          'Super 130',
          'Leinenmischung',
        ],
      ),
      ConfigField(
        key: 'jacket_color',
        label: 'Farbe',
        options: ['Navy', 'Anthrazit', 'Schwarz', 'Hellgrau', 'Braun'],
      ),
      ConfigField(
        key: 'lapel_style',
        label: 'Revers',
        options: ['Spitzfasson', 'Fallendes Revers', 'Schalkragen'],
      ),
      ConfigField(
        key: 'button_count',
        label: 'Knopfanzahl',
        options: ['1-Knopf', '2-Knopf', '3-Knopf'],
      ),
      ConfigField(
        key: 'lining',
        label: 'Futter',
        options: ['Vollfutter', 'Halbfutter', 'Ungefuettert'],
      ),
    ],
  ),
  ConfigSection(
    title: 'Hose',
    fields: [
      ConfigField(
        key: 'trousers_fit',
        label: 'Passform',
        options: ['Schmal', 'Gerade', 'Komfort'],
      ),
      ConfigField(
        key: 'trousers_size',
        label: 'Bundweite',
        options: ['44', '46', '48', '50', '52', '54', '56'],
      ),
      ConfigField(
        key: 'trousers_pleats',
        label: 'Bundfalten',
        options: ['Keine', 'Eine Bundfalte', 'Zwei Bundfalten'],
      ),
      ConfigField(
        key: 'hem',
        label: 'Saum',
        options: ['Offen', 'Umschlag 3.5 cm', 'Umschlag 4.5 cm'],
      ),
    ],
  ),
  ConfigSection(
    title: 'Weste und Extras',
    fields: [
      ConfigField(
        key: 'waistcoat',
        label: 'Weste',
        options: ['Keine', 'Einreihig', 'Zweireihig'],
      ),
      ConfigField(
        key: 'button_material',
        label: 'Knopfmaterial',
        options: ['Hornoptik', 'Perlmuttoptik', 'Matt Schwarz'],
      ),
      ConfigField(
        key: 'monogram',
        label: 'Monogramm',
        options: ['Kein Monogramm', 'Initialen innen', 'Initialen sichtbar'],
      ),
    ],
  ),
];

final List<ConfigField> allConfigFields = [
  for (final section in suitConfigurationSections) ...section.fields,
];

final Map<String, String> configFieldLabels = {
  for (final field in allConfigFields) field.key: field.label,
};
