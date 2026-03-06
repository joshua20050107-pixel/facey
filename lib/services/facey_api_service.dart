import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FaceyChatTurn {
  const FaceyChatTurn({required this.role, required this.text});

  final String role;
  final String text;

  Map<String, String> toJson() => <String, String>{'role': role, 'text': text};
}

class FaceyApiService {
  static const String _baseUrl = String.fromEnvironment(
    'FACEY_API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );
  static Future<void>? _startupWarmupFuture;
  static String get baseUrl => _baseUrl;

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');
  static void _log(String message) {
    if (kDebugMode) debugPrint('[FaceyApi] $message');
  }

  static Future<void> warmupForStartup() {
    return _startupWarmupFuture ??= _runStartupWarmup();
  }

  static Future<void> _runStartupWarmup() async {
    await waitUntilReady();
    await Future.wait<void>(<Future<void>>[warmupHome(), warmupCondition()]);
  }

  static Future<bool> isReady() async {
    _log('health check: ${_uri('/api/health')}');
    final http.Response response = await http
        .get(_uri('/api/health'))
        .timeout(const Duration(seconds: 5));
    if (response.statusCode != 200) return false;
    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    return json['ready'] == true;
  }

  static Future<void> waitUntilReady({
    Duration timeout = const Duration(seconds: 30),
    Duration interval = const Duration(milliseconds: 800),
  }) async {
    final DateTime deadline = DateTime.now().add(timeout);
    Object? lastError;
    while (DateTime.now().isBefore(deadline)) {
      try {
        if (await isReady()) return;
      } catch (error) {
        lastError = error;
        _log('health check failed: $error');
        // Retry until timeout.
      }
      await Future<void>.delayed(interval);
    }
    final String detail = lastError == null ? '' : ' / lastError: $lastError';
    throw StateError('API is not ready yet: $_baseUrl$detail');
  }

  static Future<void> warmupHome() async {
    await _postWithoutResult('/api/home');
  }

  static Future<void> warmupCondition() async {
    await _postWithoutResult('/api/condition');
  }

  static Future<void> _postWithoutResult(String path) async {
    _log('warmup request: ${_uri(path)}');
    final http.Response response = await http
        .post(
          _uri(path),
          headers: const <String, String>{'Content-Type': 'application/json'},
          body: '{}',
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw StateError('API request failed: ${response.statusCode}');
    }
  }

  static Future<Map<String, dynamic>> analyzeHome({
    required List<int> frontImageBytes,
    List<int>? sideImageBytes,
    required String gender,
  }) async {
    _log('home request: ${_uri('/api/home')}');
    final Map<String, dynamic> payload = <String, dynamic>{
      'frontImageBase64': base64Encode(frontImageBytes),
      'gender': gender,
    };
    if (sideImageBytes != null && sideImageBytes.isNotEmpty) {
      payload['sideImageBase64'] = base64Encode(sideImageBytes);
    }

    final http.Response response = await http
        .post(
          _uri('/api/home'),
          headers: const <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 60));

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || json['ok'] != true) {
      throw StateError((json['error'] ?? 'home analysis failed').toString());
    }
    final Object? raw = json['analysis'];
    if (raw is! Map<String, dynamic>) {
      throw StateError('invalid analysis response');
    }
    return raw;
  }

  static Future<String> sendChat({
    required String message,
    required List<FaceyChatTurn> history,
    List<List<int>> imageBytesList = const <List<int>>[],
  }) async {
    _log('chat request: ${_uri('/api/chat')}');
    final Map<String, dynamic> payload = <String, dynamic>{
      'message': message,
      'history': history.map((FaceyChatTurn e) => e.toJson()).toList(),
    };
    if (imageBytesList.isNotEmpty) {
      payload['imagesBase64'] = imageBytesList
          .where((List<int> bytes) => bytes.isNotEmpty)
          .map(base64Encode)
          .toList();
    }

    final http.Response response = await http
        .post(
          _uri('/api/chat'),
          headers: const <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 30));

    final Map<String, dynamic> json =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || json['ok'] != true) {
      throw StateError((json['error'] ?? 'chat request failed').toString());
    }

    final String reply = (json['reply'] ?? '').toString().trim();
    if (reply.isEmpty) {
      throw StateError('empty reply from API');
    }
    return reply;
  }
}
