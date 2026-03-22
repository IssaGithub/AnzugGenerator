import '../models/suit_order.dart';

String buildOrderSummary(
  SuitOrder order, {
  required Map<String, String> fieldLabels,
}) {
  final buffer = StringBuffer()
    ..writeln('Anzug-Konfiguration')
    ..writeln('Erstellt am: ${_formatDate(order.createdAt)}')
    ..writeln()
    ..writeln('Kundendaten')
    ..writeln('Name: ${order.customerName}')
    ..writeln('E-Mail: ${order.customerEmail}')
    ..writeln('Telefon: ${order.customerPhone}')
    ..writeln()
    ..writeln('Konfiguration');

  for (final entry in order.selections.entries) {
    if (entry.value.trim().isEmpty) {
      continue;
    }
    final label = fieldLabels[entry.key] ?? entry.key;
    buffer.writeln('- $label: ${entry.value}');
  }

  if (order.additionalNotes.trim().isNotEmpty) {
    buffer
      ..writeln()
      ..writeln('Weitere Hinweise')
      ..writeln(order.additionalNotes.trim());
  }

  return buffer.toString();
}

String _formatDate(DateTime value) {
  final date = '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
  final time = '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
