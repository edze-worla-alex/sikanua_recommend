import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Update this to your backend URL
  static const String baseUrl = 'http://localhost:8000';

  /// Check if backend is reachable
  static Future<bool> healthCheck() async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/'))
          .timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Stream a chat completion response token-by-token.
  ///
  /// [messages] — full conversation history as API message maps
  /// [onToken]  — called with each streamed text token
  /// [onDone]   — called when the stream ends
  /// [onError]  — called on any failure
  static Future<void> streamChatCompletion({
    required List<Map<String, String>> messages,
    required void Function(String token) onToken,
    required void Function() onDone,
    required void Function(String error) onError,
  }) async {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('$baseUrl/v1/chat/completions'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({
        'model': 'sikanua-v1',
        'messages': messages,
        'stream': true,
      });

      final streamedResponse = await request.send().timeout(
            const Duration(seconds: 120),
          );

      if (streamedResponse.statusCode != 200) {
        final body = await streamedResponse.stream.bytesToString();
        onError('API error ${streamedResponse.statusCode}: $body');
        return;
      }

      final buffer = StringBuffer();

      await for (final chunk
          in streamedResponse.stream.transform(utf8.decoder)) {
        buffer.write(chunk);
        final raw = buffer.toString();

        // Process complete SSE lines
        final lines = raw.split('\n');

        // Keep the last (potentially incomplete) line in buffer
        buffer.clear();
        buffer.write(lines.last);

        for (final line in lines.sublist(0, lines.length - 1)) {
          if (!line.startsWith('data: ')) continue;
          final data = line.substring(6).trim();
          if (data == '[DONE]') {
            onDone();
            return;
          }
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            final choices = json['choices'] as List?;
            if (choices == null || choices.isEmpty) continue;
            final delta = choices[0]['delta'] as Map<String, dynamic>?;
            final content = delta?['content'] as String?;
            if (content != null && content.isNotEmpty) {
              onToken(content);
            }
          } catch (_) {
            // skip malformed chunk
          }
        }
      }
      onDone();
    } on TimeoutException {
      onError('Request timed out. Is the backend running at $baseUrl?');
    } catch (e) {
      onError('Connection error: $e');
    }
  }
}
