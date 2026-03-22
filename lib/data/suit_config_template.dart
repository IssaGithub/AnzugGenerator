import '../models/config_field.dart';

const List<String> monogramFonts = [
  'Druckschrift',
  'Calligraphy',
];

const List<String> threadColourCardOptions = [
  'white',
  'sand',
  'light blue',
  'pink',
  'off-white',
  'light-brown',
  'sky blue',
  'red',
  'mid-grey',
  'dark brown',
  'slate blue',
  'orange',
  'silver',
  'mid-brown',
  'royal blue',
  'dark red',
  'anthracite',
  'light green',
  'midnight blue',
  'oxide red',
  'light grey',
  'chocolate brown',
  'navy blue',
  'wine red',
  'black',
  'forest green',
  'purple',
  'gold',
  'dark green',
  'violet',
];

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
  ConfigSection(
    title: 'Accessoires - Krawatte (PDF)',
    fields: [
      ConfigField(
        key: 'tie_processing',
        label: 'Verarbeitung',
        options: [
          'Tipped',
          'Untipped',
          'Bobtail',
          '7-fach gefaltet tipped',
          '7-fach gefaltet untipped',
        ],
      ),
      ConfigField(
        key: 'tie_width',
        label: 'Weite',
        options: ['5,5 cm (nur Bobtail)', '6 cm', '7 cm', '8 cm', '9 cm'],
      ),
      ConfigField(
        key: 'tie_length',
        label: 'Laenge',
        options: ['Standard (148 cm)', 'Lang (165 cm)', 'Extra lang (175 cm)'],
      ),
      ConfigField(
        key: 'tie_monogram_position',
        label: 'Monogramm Positionierung',
        options: [
          'Vorderseite 3 cm von unten',
          'Vorderseite 38 cm von unten',
          'In Fuetterung (Rueckseite der Krawatte)',
          'Auf der Spitze',
        ],
        helperText:
            'Hinweis laut PDF: Monogramm nicht fuer Untipped und Bobtail.',
      ),
      ConfigField(
        key: 'tie_monogram_font',
        label: 'Monogrammschrift',
        options: monogramFonts,
      ),
      ConfigField(
        key: 'tie_monogram_text',
        label: 'Monogramm Text',
        type: ConfigFieldType.text,
        placeholder: 'z. B. MT',
      ),
      ConfigField(
        key: 'tie_thread_colour',
        label: 'Thread colour card',
        options: threadColourCardOptions,
      ),
    ],
  ),
  ConfigSection(
    title: 'Accessoires - Fliege (PDF)',
    fields: [
      ConfigField(
        key: 'bow_tie_processing',
        label: 'Verarbeitung',
        options: ['Vorgebunden', 'Vorgefaltet', 'Selbstbinder'],
      ),
      ConfigField(
        key: 'bow_tie_width',
        label: 'Weite',
        options: ['6 cm', '7 cm', '8 cm'],
      ),
      ConfigField(
        key: 'bow_tie_monogram_position',
        label: 'Monogramm Positionierung',
        options: ['Aeusseres Band selbstbinder', 'Aeusseres Band vorgebunden'],
      ),
      ConfigField(
        key: 'bow_tie_monogram_font',
        label: 'Monogrammschrift',
        options: monogramFonts,
      ),
      ConfigField(
        key: 'bow_tie_monogram_text',
        label: 'Monogramm Text',
        type: ConfigFieldType.text,
        placeholder: 'z. B. ABCD',
      ),
      ConfigField(
        key: 'bow_tie_thread_colour',
        label: 'Thread colour card',
        options: threadColourCardOptions,
      ),
    ],
  ),
  ConfigSection(
    title: 'Accessoires - Einstecktuch (PDF)',
    fields: [
      ConfigField(
        key: 'pocket_square_processing',
        label: 'Verarbeitung',
        options: ['Von Hand rolliert', 'Von Hand bestickt'],
      ),
      ConfigField(
        key: 'pocket_square_monogram_position',
        label: 'Monogramm Positionierung',
        options: ['Ecke diagonal', 'Ecke gerade', 'Mittig', 'Rand'],
      ),
      ConfigField(
        key: 'pocket_square_monogram_font',
        label: 'Monogrammschrift',
        options: monogramFonts,
      ),
      ConfigField(
        key: 'pocket_square_monogram_text',
        label: 'Monogramm Text',
        type: ConfigFieldType.text,
        placeholder: 'z. B. MT',
      ),
      ConfigField(
        key: 'pocket_square_thread_colour',
        label: 'Thread colour card',
        options: threadColourCardOptions,
      ),
    ],
  ),
  ConfigSection(
    title: 'Accessoires - Cummerbund (PDF)',
    fields: [
      ConfigField(
        key: 'cummerbund_model',
        label: 'Model',
        options: ['Vorderseite', 'Rueckseite'],
      ),
      ConfigField(
        key: 'cummerbund_monogram_position',
        label: 'Monogramm Positionierung',
        options: ['Aussen rechts'],
      ),
      ConfigField(
        key: 'cummerbund_monogram_font',
        label: 'Monogrammschrift',
        options: monogramFonts,
      ),
      ConfigField(
        key: 'cummerbund_monogram_text',
        label: 'Monogramm Text',
        type: ConfigFieldType.text,
        placeholder: 'z. B. AbC',
      ),
      ConfigField(
        key: 'cummerbund_thread_colour',
        label: 'Thread colour card',
        options: threadColourCardOptions,
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
