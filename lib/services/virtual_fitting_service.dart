import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class VirtualFittingService {
  VirtualFittingService({
    required this.apiKey,
    required this.modelEndpointId,
    this.queueBaseUrl = 'https://queue.fal.run',
  });

  final String apiKey;
  final String modelEndpointId;
  final String queueBaseUrl;

  bool get isConfigured {
    if (apiKey.trim().isEmpty) {
      return false;
    }
    if (modelEndpointId.trim().isEmpty) {
      return false;
    }
    final uri = Uri.tryParse(queueBaseUrl);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  Future<VirtualFittingResult> generateFittingImage({
    required Uint8List customerPhotoBytes,
    required String prompt,
  }) async {
    if (!isConfigured) {
      throw const VirtualFittingConfigurationException(
        'Virtual Fitting ist nicht konfiguriert. '
        'Bitte VIRTUAL_FIT_API_KEY und optional VIRTUAL_FIT_MODEL setzen.',
      );
    }

    final queueEndpoint = _buildQueueEndpointUri();
    final submitResponse = await http.post(
      queueEndpoint,
      headers: _buildJsonHeaders(),
      body: jsonEncode({
        'prompt': prompt,
        'image_url': _buildDataUri(customerPhotoBytes),
        'output_format': 'png',
        'resolution_mode': 'match_input',
        'enable_safety_checker': true,
      }),
    );

    if (submitResponse.statusCode < 200 || submitResponse.statusCode >= 300) {
      throw VirtualFittingRequestException(
        'fal.ai Anfrage fehlgeschlagen (${submitResponse.statusCode}): '
        '${submitResponse.body}',
      );
    }

    final submitJson = _decodeObject(submitResponse.body);
    final requestId = _readString(submitJson, const ['request_id']);
    if (requestId == null || requestId.isEmpty) {
      throw const VirtualFittingRequestException(
        'fal.ai Antwort ohne request_id erhalten.',
      );
    }

    final status = _readString(submitJson, const ['status']) ?? 'IN_QUEUE';
    if (status != 'COMPLETED') {
      await _pollUntilCompleted(
        requestId: requestId,
        statusUrl: _readString(submitJson, const ['status_url']),
      );
    }

    final resultMap = await _fetchResult(
      requestId: requestId,
      responseUrl: _readString(submitJson, const ['response_url']),
    );
    final imageUrl = _extractImageUrl(resultMap);

    if (imageUrl == null || imageUrl.isEmpty) {
      throw VirtualFittingRequestException(
        'Kein Bild in der fal.ai Antwort gefunden. '
        'Antwort: ${jsonEncode(resultMap)}',
      );
    }

    final imageResponse = await http.get(Uri.parse(imageUrl));
    if (imageResponse.statusCode < 200 || imageResponse.statusCode >= 300) {
      throw VirtualFittingRequestException(
        'Generiertes Bild konnte nicht geladen werden '
        '(${imageResponse.statusCode}).',
      );
    }

    return VirtualFittingResult(
      imageBytes: imageResponse.bodyBytes,
      sourceUrl: imageUrl,
    );
  }

  Uri _buildQueueEndpointUri() {
    final normalizedBase = queueBaseUrl.endsWith('/')
        ? queueBaseUrl.substring(0, queueBaseUrl.length - 1)
        : queueBaseUrl;
    final normalizedModel = modelEndpointId.startsWith('/')
        ? modelEndpointId.substring(1)
        : modelEndpointId;
    return Uri.parse('$normalizedBase/$normalizedModel');
  }

  Map<String, String> _buildJsonHeaders() {
    return {
      'Authorization': 'Key ${apiKey.trim()}',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<void> _pollUntilCompleted({
    required String requestId,
    required String? statusUrl,
  }) async {
    final statusUri = statusUrl != null && statusUrl.isNotEmpty
        ? Uri.parse(statusUrl)
        : Uri.parse('${_buildQueueEndpointUri()}/requests/$requestId/status');
    const maxAttempts = 50;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 2));

      final response = await http.get(statusUri, headers: _buildJsonHeaders());
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw VirtualFittingRequestException(
          'fal.ai Statusabfrage fehlgeschlagen (${response.statusCode}): '
          '${response.body}',
        );
      }

      final statusMap = _decodeObject(response.body);
      final status = _readString(statusMap, const ['status']) ?? 'UNKNOWN';
      if (status == 'COMPLETED') {
        return;
      }
      if (status == 'FAILED') {
        throw VirtualFittingRequestException(
          'fal.ai Generierung fehlgeschlagen: ${response.body}',
        );
      }
      if (status == 'CANCELLED') {
        throw const VirtualFittingRequestException(
          'fal.ai Generierung wurde abgebrochen.',
        );
      }
    }

    throw const VirtualFittingRequestException(
      'fal.ai Generierung hat das Zeitlimit ueberschritten.',
    );
  }

  Future<Map<String, dynamic>> _fetchResult({
    required String requestId,
    required String? responseUrl,
  }) async {
    final resultUri = responseUrl != null && responseUrl.isNotEmpty
        ? Uri.parse(responseUrl)
        : Uri.parse('${_buildQueueEndpointUri()}/requests/$requestId');

    final response = await http.get(resultUri, headers: _buildJsonHeaders());
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw VirtualFittingRequestException(
        'fal.ai Ergebnis konnte nicht geladen werden (${response.statusCode}): '
        '${response.body}',
      );
    }

    return _decodeObject(response.body);
  }
}

class VirtualFittingResult {
  const VirtualFittingResult({
    required this.imageBytes,
    required this.sourceUrl,
  });

  final Uint8List imageBytes;
  final String? sourceUrl;
}

class VirtualFittingConfigurationException implements Exception {
  const VirtualFittingConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VirtualFittingRequestException implements Exception {
  const VirtualFittingRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}

Map<String, dynamic> _decodeObject(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, dynamic>) {
    throw const VirtualFittingRequestException(
      'Unerwartete API-Antwort: JSON-Objekt erwartet.',
    );
  }
  return decoded;
}

String? _readString(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
  }
  return null;
}

String? _extractImageUrl(Map<String, dynamic> data) {
  final images = data['images'];
  if (images is List && images.isNotEmpty) {
    final first = images.first;
    if (first is Map<String, dynamic>) {
      final imageUrl = first['url'];
      if (imageUrl is String && imageUrl.isNotEmpty) {
        return imageUrl;
      }
    }
  }

  final image = data['image'];
  if (image is Map<String, dynamic>) {
    final imageUrl = image['url'];
    if (imageUrl is String && imageUrl.isNotEmpty) {
      return imageUrl;
    }
  }

  final direct = data['imageUrl'] ?? data['image_url'] ?? data['url'];
  if (direct is String && direct.isNotEmpty) {
    return direct;
  }

  final output = data['output'];
  if (output is String && output.isNotEmpty) {
    return output;
  }
  if (output is List && output.isNotEmpty) {
    final first = output.first;
    if (first is String && first.isNotEmpty) {
      return first;
    }
  }

  final dataList = data['data'];
  if (dataList is List && dataList.isNotEmpty) {
    final first = dataList.first;
    if (first is Map<String, dynamic>) {
      final url = first['url'];
      if (url is String && url.isNotEmpty) {
        return url;
      }
    }
  }

  return null;
}

String _buildDataUri(Uint8List bytes) {
  final base64 = base64Encode(bytes);
  return 'data:image/jpeg;base64,$base64';
}
