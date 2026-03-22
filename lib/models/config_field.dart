enum ConfigFieldType {
  dropdown,
  text,
}

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
    this.options = const [],
    this.type = ConfigFieldType.dropdown,
    this.helperText,
    this.placeholder,
  });

  final String key;
  final String label;
  final List<String> options;
  final ConfigFieldType type;
  final String? helperText;
  final String? placeholder;
}
