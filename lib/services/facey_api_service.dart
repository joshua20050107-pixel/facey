import 'dart:async';
import 'dart:convert';

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

  static Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static Future<bool> isReady() async {
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
    while (DateTime.now().isBefore(deadline)) {
      try {
        if (await isReady()) return;
      } catch (_) {
        // Retry until timeout.
      }
      await Future<void>.delayed(interval);
    }
    throw StateError('API is not ready yet');
  }

  static Future<void> warmupHome() async {
    await _postWithoutResult('/api/home');
  }

  static Future<void> warmupCondition() async {
    await _postWithoutResult('/api/condition');
  }

  static Future<void> _postWithoutResult(String path) async {
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

  static Future<String> sendChat({
    required String message,
    required List<FaceyChatTurn> history,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'message': message,
      'history': history.map((FaceyChatTurn e) => e.toJson()).toList(),
    };

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
