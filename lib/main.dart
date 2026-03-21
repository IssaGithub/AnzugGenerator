import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import 'data/suit_config_template.dart';
import 'models/config_field.dart';
import 'models/suit_order.dart';
import 'services/email_service.dart';
import 'services/order_summary_builder.dart';

const _smtpHost = String.fromEnvironment(
  'SMTP_HOST',
  defaultValue: 'smtp.example.com',
);
const _smtpPort = int.fromEnvironment('SMTP_PORT', defaultValue: 587);
const _smtpUser = String.fromEnvironment('SMTP_USER', defaultValue: '');
const _smtpPassword = String.fromEnvironment('SMTP_PASSWORD', defaultValue: '');
const _sellerEmail = String.fromEnvironment('SELLER_EMAIL', defaultValue: '');
const _senderName = String.fromEnvironment(
  'SENDER_NAME',
  defaultValue: 'Anzug Verkauf',
);
const _smtpUseSsl = bool.fromEnvironment('SMTP_USE_SSL', defaultValue: false);
const _smtpAllowInsecure = bool.fromEnvironment(
  'SMTP_ALLOW_INSECURE',
  defaultValue: false,
);

void main() {
  runApp(const SuitConfiguratorApp());
}

class SuitConfiguratorApp extends StatelessWidget {
  const SuitConfiguratorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anzug Konfigurator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const SuitConfiguratorPage(),
    );
  }
}

class SuitConfiguratorPage extends StatefulWidget {
  const SuitConfiguratorPage({super.key});

  @override
  State<SuitConfiguratorPage> createState() => _SuitConfiguratorPageState();
}

class _SuitConfiguratorPageState extends State<SuitConfiguratorPage> {
  static const _lastStepIndex = 2;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  late final SignatureController _signatureController;
  late final EmailService _emailService;
  late Map<String, String> _selectedValues;

  int _currentStep = 0;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 2.0,
      penColor: Colors.black,
    );
    _emailService = EmailService(
      smtpHost: _smtpHost,
      smtpPort: _smtpPort,
      smtpUsername: _smtpUser,
      smtpPassword: _smtpPassword,
      sellerEmail: _sellerEmail,
      senderName: _senderName,
      useSsl: _smtpUseSsl,
      allowInsecure: _smtpAllowInsecure,
    );
    _selectedValues = {
      for (final field in allConfigFields) field.key: field.options.first,
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anzug Konfigurator')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepTapped: _isSending
                ? null
                : (step) => setState(() {
                    _currentStep = step;
                  }),
            onStepContinue: _isSending
                ? null
                : () {
                    if (_currentStep == _lastStepIndex) {
                      _sendOrder();
                    } else {
                      setState(() {
                        _currentStep += 1;
                      });
                    }
                  },
            onStepCancel: _isSending || _currentStep == 0
                ? null
                : () {
                    setState(() {
                      _currentStep -= 1;
                    });
                  },
            controlsBuilder: (context, details) {
              final isLastStep = _currentStep == _lastStepIndex;
              return Row(
                children: [
                  ElevatedButton(
                    onPressed: _isSending ? null : details.onStepContinue,
                    child: Text(
                      isLastStep
                          ? (_isSending
                                ? 'Senden...'
                                : 'Bestaetigen und E-Mail senden')
                          : 'Weiter',
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: _isSending ? null : details.onStepCancel,
                      child: const Text('Zurueck'),
                    ),
                ],
              );
            },
            steps: [
              Step(
                title: const Text('Kundendaten'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: _buildCustomerStep(),
              ),
              Step(
                title: const Text('Konfiguration'),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                content: _buildConfigurationStep(),
              ),
              Step(
                title: const Text('Zusammenfassung und Signatur'),
                isActive: _currentStep >= 2,
                content: _buildSummaryStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerStep() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Bitte Name eingeben.';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'E-Mail',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Bitte E-Mail eingeben.';
            }
            final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
            if (!emailRegex.hasMatch(value.trim())) {
              return 'Bitte gueltige E-Mail eingeben.';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Telefon',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Bitte Telefonnummer eingeben.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildConfigurationStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in suitConfigurationSections) ...[
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final field in section.fields) ...[
                    _buildConfigField(field),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Weitere Hinweise',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildConfigField(ConfigField field) {
    return DropdownButtonFormField<String>(
      value: _selectedValues[field.key],
      decoration: InputDecoration(
        labelText: field.label,
        helperText: field.helperText,
        border: const OutlineInputBorder(),
      ),
      items: field.options
          .map(
            (option) => DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value == null) {
          return;
        }
        setState(() {
          _selectedValues[field.key] = value;
        });
      },
    );
  }

  Widget _buildSummaryStep() {
    final order = _buildCurrentOrder();
    final summary = buildOrderSummary(order, fieldLabels: configFieldLabels);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bitte pruefen Sie alle Angaben vor dem Versand.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SelectableText(summary),
        ),
        const SizedBox(height: 16),
        Text(
          'Unterschrift',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade500),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Signature(
            controller: _signatureController,
            backgroundColor: Colors.white,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isSending
                ? null
                : () {
                    _signatureController.clear();
                    setState(() {});
                  },
            child: const Text('Unterschrift loeschen'),
          ),
        ),
        if (!_emailService.isConfigured)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade700),
            ),
            child: const Text(
              'Hinweis: SMTP ist noch nicht konfiguriert. '
              'Setzen Sie --dart-define fuer SMTP_HOST, SMTP_PORT, SMTP_USER, '
              'SMTP_PASSWORD, SELLER_EMAIL und optional SENDER_NAME.',
            ),
          ),
      ],
    );
  }

  SuitOrder _buildCurrentOrder() {
    return SuitOrder(
      customerName: _nameController.text.trim(),
      customerEmail: _emailController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      selections: Map<String, String>.from(_selectedValues),
      additionalNotes: _notesController.text.trim(),
      createdAt: DateTime.now(),
    );
  }

  Future<void> _sendOrder() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _currentStep = 0;
      });
      _showMessage('Bitte Kundendaten vollstaendig und korrekt ausfuellen.');
      return;
    }

    if (_signatureController.isEmpty) {
      _showMessage('Bitte unterschreiben Sie vor dem Versand.');
      return;
    }

    final signatureBytes = await _signatureController.toPngBytes();
    if (signatureBytes == null || signatureBytes.isEmpty) {
      _showMessage('Unterschrift konnte nicht verarbeitet werden.');
      return;
    }

    final order = _buildCurrentOrder();
    final summary = buildOrderSummary(order, fieldLabels: configFieldLabels);

    setState(() {
      _isSending = true;
    });

    try {
      await _emailService.sendOrderConfirmation(
        order: order,
        signatureBytes: Uint8List.fromList(signatureBytes),
        summaryText: summary,
      );
      if (!mounted) {
        return;
      }
      _showMessage('E-Mail erfolgreich versendet.');
      _resetForm();
    } on MailConfigurationException catch (error) {
      _showMessage(error.message);
    } on MailDeliveryException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Unerwarteter Fehler beim Versand: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _resetForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _notesController.clear();
    _signatureController.clear();
    setState(() {
      _selectedValues = {
        for (final field in allConfigFields) field.key: field.options.first,
      };
      _currentStep = 0;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
