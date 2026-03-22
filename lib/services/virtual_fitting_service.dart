import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class VirtualFittingService {
  VirtualFittingService({
    required this.endpointUrl,
    required this.apiKey,
    required this.model,
  });

  final String endpointUrl;
  final String apiKey;
  final String model;

  bool get isConfigured {
    if (endpointUrl.trim().isEmpty) {
      return false;
    }
    final uri = Uri.tryParse(endpointUrl);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  Future<VirtualFittingResult> generateFittingImage({
    required Uint8List customerPhotoBytes,
    required String prompt,
  }) async {
    if (!isConfigured) {
      throw const VirtualFittingConfigurationException(
        'Virtual Fitting API ist nicht konfiguriert. '
        'Bitte VIRTUAL_FIT_API_URL setzen.',
      );
    }

    final uri = Uri.parse(endpointUrl);
    final request = http.MultipartRequest('POST', uri)
      ..fields['prompt'] = prompt
      ..fields['model'] = model
      ..files.add(
        http.MultipartFile.fromBytes(
          'customer_image',
          customerPhotoBytes,
          filename: 'customer_photo.jpg',
        ),
      );

    if (apiKey.trim().isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $apiKey';
      request.headers['x-api-key'] = apiKey;
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw VirtualFittingRequestException(
        'Virtual Fitting API Fehler (${response.statusCode}): '
        '${response.body}',
      );
    }

    final contentType = response.headers['content-type'] ?? '';
    if (contentType.startsWith('image/')) {
      return VirtualFittingResult(
        imageBytes: response.bodyBytes,
        sourceUrl: null,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const VirtualFittingRequestException(
        'Unerwartete API-Antwort: JSON-Objekt erwartet.',
      );
    }

    final directBase64 = _extractBase64(decoded);
    if (directBase64 != null && directBase64.isNotEmpty) {
      return VirtualFittingResult(
        imageBytes: base64Decode(directBase64),
        sourceUrl: null,
      );
    }

    final imageUrl = _extractImageUrl(decoded);
    if (imageUrl == null || imageUrl.isEmpty) {
      throw const VirtualFittingRequestException(
        'Kein Bild in API-Antwort gefunden (erwartet: imageUrl oder imageBase64).',
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

String? _extractImageUrl(Map<String, dynamic> data) {
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

String? _extractBase64(Map<String, dynamic> data) {
  final candidates = [
    data['imageBase64'],
    data['image_base64'],
    data['b64_json'],
  ];

  for (final value in candidates) {
    if (value is String && value.trim().isNotEmpty) {
      return _normalizeBase64(value.trim());
    }
  }

  return null;
}

String _normalizeBase64(String value) {
  const prefix = 'base64,';
  final index = value.indexOf(prefix);
  if (index == -1) {
    return value;
  }
  return value.substring(index + prefix.length);
}
