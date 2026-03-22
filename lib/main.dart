import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';

import 'data/suit_config_template.dart';
import 'models/config_field.dart';
import 'models/suit_order.dart';
import 'services/email_service.dart';
import 'services/order_summary_builder.dart';
import 'services/virtual_fitting_service.dart';

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
const _virtualFitApiUrl = String.fromEnvironment(
  'VIRTUAL_FIT_API_URL',
  defaultValue: '',
);
const _virtualFitApiKey = String.fromEnvironment(
  'VIRTUAL_FIT_API_KEY',
  defaultValue: '',
);
const _virtualFitModel = String.fromEnvironment(
  'VIRTUAL_FIT_MODEL',
  defaultValue: 'virtual-fitting-v1',
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
  static const _lastStepIndex = 3;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();

  late final SignatureController _signatureController;
  late final EmailService _emailService;
  late final VirtualFittingService _virtualFittingService;
  final _imagePicker = ImagePicker();
  late Map<String, String> _selectedValues;

  int _currentStep = 0;
  bool _isSending = false;
  bool _isGeneratingFitting = false;
  int _formVersion = 0;
  Uint8List? _customerImageBytes;
  Uint8List? _generatedFittingImageBytes;
  String? _customerImageName;
  String? _fittingSourceUrl;

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
    _virtualFittingService = VirtualFittingService(
      endpointUrl: _virtualFitApiUrl,
      apiKey: _virtualFitApiKey,
      model: _virtualFitModel,
    );
    _selectedValues = {
      for (final field in allConfigFields)
        field.key: field.type == ConfigFieldType.dropdown &&
                field.options.isNotEmpty
            ? field.options.first
            : '',
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
            onStepTapped: _isSending || _isGeneratingFitting
                ? null
                : (step) => setState(() {
                    _currentStep = step;
                  }),
            onStepContinue: _isSending || _isGeneratingFitting
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
            onStepCancel: _isSending || _isGeneratingFitting || _currentStep == 0
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
                    onPressed: _isSending || _isGeneratingFitting
                        ? null
                        : details.onStepContinue,
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
                      onPressed: _isSending || _isGeneratingFitting
                          ? null
                          : details.onStepCancel,
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
                title: const Text('Virtual Fitting'),
                isActive: _currentStep >= 2,
                state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                content: _buildVirtualFittingStep(),
              ),
              Step(
                title: const Text('Zusammenfassung und Signatur'),
                isActive: _currentStep >= 3,
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
    if (field.type == ConfigFieldType.text) {
      return TextFormField(
        key: ValueKey('${field.key}_$_formVersion'),
        initialValue: _selectedValues[field.key] ?? '',
        decoration: InputDecoration(
          labelText: field.label,
          helperText: field.helperText,
          hintText: field.placeholder,
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) {
          _selectedValues[field.key] = value;
        },
      );
    }

    final availableOptions = field.options;
    final currentValue = _selectedValues[field.key];
    final selectedValue = availableOptions.contains(currentValue)
        ? currentValue
        : (availableOptions.isNotEmpty ? availableOptions.first : null);

    return DropdownButtonFormField<String>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: field.label,
        helperText: field.helperText,
        border: const OutlineInputBorder(),
      ),
      items: availableOptions
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

  Widget _buildVirtualFittingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Laden Sie ein Kundenfoto hoch. Die App erzeugt daraus eine '
          'KI-Vorschau mit passender Anzug-Konfiguration.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _isGeneratingFitting
                  ? null
                  : () => _pickCustomerImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Foto waehlen'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _isGeneratingFitting
                  ? null
                  : () => _pickCustomerImage(ImageSource.camera),
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Kamera'),
            ),
          ],
        ),
        if (_customerImageName != null) ...[
          const SizedBox(height: 8),
          Text('Ausgewaehlte Datei: $_customerImageName'),
        ],
        const SizedBox(height: 12),
        if (_customerImageBytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _customerImageBytes!,
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
            ),
          )
        else
          _buildPlaceholderBox(
            icon: Icons.person_outline,
            text: 'Noch kein Kundenfoto ausgewaehlt',
          ),
        const SizedBox(height: 12),
        if (!_virtualFittingService.isConfigured)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.lightBlue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.lightBlue.shade300),
            ),
            child: const Text(
              'Virtual Fitting API ist nicht konfiguriert. '
              'Es wird automatisch der Demo-Modus verwendet. '
              'Fuer echte KI-Generierung setzen Sie --dart-define '
              'fuer VIRTUAL_FIT_API_URL, VIRTUAL_FIT_API_KEY und optional '
              'VIRTUAL_FIT_MODEL.',
            ),
          ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _customerImageBytes == null || _isGeneratingFitting
              ? null
              : _generateFittingImage,
          icon: _isGeneratingFitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome),
          label: Text(
            _isGeneratingFitting
                ? 'Generiere...'
                : (_virtualFittingService.isConfigured
                      ? 'KI-Bild generieren'
                      : 'Demo-Vorschau generieren'),
          ),
        ),
        const SizedBox(height: 12),
        if (_generatedFittingImageBytes != null) ...[
          Text(
            'Generierte Vorschau',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _generatedFittingImageBytes!,
              width: double.infinity,
              height: 280,
              fit: BoxFit.cover,
            ),
          ),
          if (_fittingSourceUrl != null) ...[
            const SizedBox(height: 6),
            Text(
              'Quelle: $_fittingSourceUrl',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ] else
          _buildPlaceholderBox(
            icon: Icons.style_outlined,
            text: 'Noch keine KI-Vorschau erzeugt',
          ),
      ],
    );
  }

  Widget _buildPlaceholderBox({
    required IconData icon,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: Colors.grey.shade600),
          const SizedBox(height: 8),
          Text(
            text,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
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
          'Virtual Fitting Vorschau',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (_generatedFittingImageBytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _generatedFittingImageBytes!,
              width: double.infinity,
              height: 240,
              fit: BoxFit.cover,
            ),
          )
        else
          _buildPlaceholderBox(
            icon: Icons.image_not_supported_outlined,
            text: 'Keine Virtual-Fitting Vorschau vorhanden',
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

  Future<void> _pickCustomerImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 90,
      );

      if (image == null) {
        return;
      }

      final bytes = await image.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _customerImageBytes = bytes;
        _customerImageName = image.name;
        _generatedFittingImageBytes = null;
        _fittingSourceUrl = null;
      });
    } catch (error) {
      _showMessage('Foto konnte nicht geladen werden: $error');
    }
  }

  Future<void> _generateFittingImage() async {
    final customerImageBytes = _customerImageBytes;
    if (customerImageBytes == null || customerImageBytes.isEmpty) {
      _showMessage('Bitte zuerst ein Kundenfoto auswaehlen.');
      return;
    }

    setState(() {
      _isGeneratingFitting = true;
    });

    try {
      if (!_virtualFittingService.isConfigured) {
        // Demo-Fallback: Originalfoto als Vorschau verwenden, damit die
        // Funktion ohne Backend sofort erlebbar ist.
        await Future<void>.delayed(const Duration(milliseconds: 350));
        if (!mounted) {
          return;
        }
        setState(() {
          _generatedFittingImageBytes = customerImageBytes;
          _fittingSourceUrl = 'demo://local-preview';
        });
        _showMessage(
          'Demo-Vorschau erstellt. Fuer echte KI-Bilder bitte API konfigurieren.',
        );
        return;
      }

      final result = await _virtualFittingService.generateFittingImage(
        customerPhotoBytes: customerImageBytes,
        prompt: _buildVirtualFittingPrompt(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _generatedFittingImageBytes = result.imageBytes;
        _fittingSourceUrl = result.sourceUrl;
      });
      _showMessage('Virtual Fitting Bild erstellt.');
    } on VirtualFittingConfigurationException catch (error) {
      _showMessage(error.message);
    } on VirtualFittingRequestException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Virtual Fitting fehlgeschlagen: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingFitting = false;
        });
      }
    }
  }

  String _buildVirtualFittingPrompt() {
    final jacketFit = _selectedValues['jacket_fit'] ?? 'Modern Fit';
    final jacketColor = _selectedValues['jacket_color'] ?? 'Navy';
    final lapelStyle = _selectedValues['lapel_style'] ?? 'Fallendes Revers';
    final tieProcessing = _selectedValues['tie_processing'] ?? 'Tipped';
    final tieWidth = _selectedValues['tie_width'] ?? '8 cm';
    final bowTie = _selectedValues['bow_tie_processing'] ?? 'Vorgebunden';

    return '''
Erstelle ein realistisches Virtual-Fitting Bild auf Basis des Kundenfotos.
Kleidung: Herrenanzug.
Sakko-Passform: $jacketFit.
Sakko-Farbe: $jacketColor.
Revers: $lapelStyle.
Accessoires: Krawatte ($tieProcessing, $tieWidth) und Fliege-Option ($bowTie).
Wichtig: Identitaet, Gesichtszuege und Pose des Kunden beibehalten.
Foto-realistisch, studio light, hochwertige Texturen.
''';
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
        virtualFittingBytes: _generatedFittingImageBytes,
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
        for (final field in allConfigFields)
          field.key: field.type == ConfigFieldType.dropdown &&
                  field.options.isNotEmpty
              ? field.options.first
              : '',
      };
      _customerImageBytes = null;
      _generatedFittingImageBytes = null;
      _customerImageName = null;
      _fittingSourceUrl = null;
      _isGeneratingFitting = false;
      _currentStep = 0;
      _formVersion += 1;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
