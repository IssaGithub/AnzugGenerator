class ConfigSection {
  const ConfigSection({
    required this.title,
    required this.fields,
  });

  final String title;
  final List<ConfigField> fields;
}

class ConfigField {
  const ConfigField({
    required this.key,
    required this.label,
    required this.options,
    this.helperText,
  });

  final String key;
  final String label;
  final List<String> options;
  final String? helperText;
}
