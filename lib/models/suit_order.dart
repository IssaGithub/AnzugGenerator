class SuitOrder {
  SuitOrder({
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.selections,
    required this.additionalNotes,
    required this.createdAt,
  });

  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final Map<String, String> selections;
  final String additionalNotes;
  final DateTime createdAt;
}
