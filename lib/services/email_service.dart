import 'dart:io';
import 'dart:typed_data';

import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:path_provider/path_provider.dart';

import '../models/suit_order.dart';

class EmailService {
  EmailService({
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpUsername,
    required this.smtpPassword,
    required this.sellerEmail,
    required this.senderName,
    this.useSsl = true,
    this.allowInsecure = false,
  });

  final String smtpHost;
  final int smtpPort;
  final String smtpUsername;
  final String smtpPassword;
  final String sellerEmail;
  final String senderName;
  final bool useSsl;
  final bool allowInsecure;

  bool get isConfigured {
    return smtpHost.isNotEmpty &&
        !smtpHost.contains('example.com') &&
        smtpUsername.isNotEmpty &&
        smtpPassword.isNotEmpty &&
        sellerEmail.contains('@');
  }

  Future<void> sendOrderConfirmation({
    required SuitOrder order,
    required Uint8List signatureBytes,
    required String summaryText,
  }) async {
    if (!isConfigured) {
      throw const MailConfigurationException(
        'SMTP ist nicht konfiguriert. Bitte --dart-define Werte setzen.',
      );
    }

    final tempDirectory = await getTemporaryDirectory();
    final signatureFile = File(
      '${tempDirectory.path}/signature_${order.createdAt.millisecondsSinceEpoch}.png',
    );

    await signatureFile.writeAsBytes(signatureBytes, flush: true);

    final smtpServer = SmtpServer(
      smtpHost,
      port: smtpPort,
      username: smtpUsername,
      password: smtpPassword,
      ssl: useSsl,
      allowInsecure: allowInsecure,
    );

    final message = Message()
      ..from = Address(smtpUsername, senderName)
      ..recipients.add(order.customerEmail)
      ..ccRecipients.add(sellerEmail)
      ..subject = 'Ihre Anzug-Konfiguration (${order.customerName})'
      ..text = '$summaryText\n\nSignaturdatei ist als Anhang enthalten.'
      ..attachments.add(FileAttachment(signatureFile));

    try {
      await send(message, smtpServer);
    } on MailerException catch (error) {
      throw MailDeliveryException('E-Mail konnte nicht gesendet werden: $error');
    } finally {
      if (await signatureFile.exists()) {
        await signatureFile.delete();
      }
    }
  }
}

class MailConfigurationException implements Exception {
  const MailConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class MailDeliveryException implements Exception {
  const MailDeliveryException(this.message);

  final String message;

  @override
  String toString() => message;
}
