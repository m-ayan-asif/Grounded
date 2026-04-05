import 'dart:convert';
import 'dart:developer' as dev;
import 'package:http/http.dart' as http;
import '../models.dart';

class AIService {
  static Future<List<SubTask>> breakdownTask({
    required String title,
    required String? description,
    required String backendUrl,
  }) async {
    final base = backendUrl.trim().trimRight();

    if (base.isEmpty) {
      throw Exception(
        'Backend URL is not set.\n'
        'Go to Settings and enter your server URL, e.g. http://192.168.1.5:3000',
      );
    }

    if (base.contains('localhost') || base.contains('127.0.0.1')) {
      throw Exception(
        'Android cannot reach localhost.\n'
        'Use your PC\'s LAN IP instead — run "ipconfig" on Windows and look '
        'for IPv4 Address, e.g. http://192.168.1.5:3000',
      );
    }

    final uri = Uri.parse('$base/api/breakdown');
    dev.log('POST → $uri', name: 'AIService');

    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'task': title,
              'description': description ?? '',
            }),
          )
          .timeout(const Duration(seconds: 120));
    } catch (e) {
      // Connection-level failure — give an actionable message
      throw Exception(
        'Could not reach server at $base\n\n'
        'Checklist:\n'
        '1. Is "node server.js" running on your PC?\n'
        '2. Is the IP correct? Run "ipconfig" → IPv4 Address\n'
        '3. Are your phone and PC on the same WiFi?\n'
        '4. Does Windows Firewall allow port 3000?\n'
        '   → Run in PowerShell as Admin:\n'
        '   netsh advfirewall firewall add rule name="Node 3000" '
        'dir=in action=allow protocol=TCP localport=3000\n\n'
        'Error: $e',
      );
    }

    dev.log('Status: ${response.statusCode}', name: 'AIService');
    dev.log('Body: ${response.body}', name: 'AIService');

    if (response.statusCode != 200) {
      throw Exception('Server error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final subtasks = data['subtasks'] as List;

    final now = DateTime.now().millisecondsSinceEpoch;
    return subtasks.asMap().entries.map((e) {
      final item = e.value as Map<String, dynamic>;
      return SubTask(
        id: 'sub-$now-${e.key}',
        title: (item['title'] as String?) ?? 'Step ${e.key + 1}',
        estimatedTime: (item['estimatedTime'] as String?) ?? '?',
      );
    }).toList();
  }

  /// Quick reachability test — hits GET /api/test
  static Future<String> testConnection(String backendUrl) async {
    final base = backendUrl.trim().trimRight();

    if (base.isEmpty) throw Exception('URL is empty.');
    if (base.contains('localhost') || base.contains('127.0.0.1')) {
      throw Exception('Use your PC\'s LAN IP, not localhost.');
    }

    final uri = Uri.parse('$base/api/test');
    dev.log('GET → $uri', name: 'AIService');

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 10));
      dev.log('Test status: ${response.statusCode}  body: ${response.body}',
          name: 'AIService');
      if (response.statusCode == 200) {
        return '✓ Server reachable! ${response.body}';
      }
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    } catch (e) {
      throw Exception('$e');
    }
  }
}
