// lib/data/services/groq_service.dart
// ✅ اتنقل من gemini_service.dart + إصلاح expandProjectIdea

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../core/constants/api_constants.dart';
import '../services/remote_config_service.dart';

class GroqService {
  Dio? _dio;

  Dio get _client {
    if (_dio != null) return _dio!;
    // ✅ بيجيب الـ API Key من Remote Config بدل الكود
    final apiKey = Get.find<RemoteConfigService>().getString(ApiConstants.rcGroqApiKey);
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.groqBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
    ));
    return _dio!;
  }

  // ── حساب نسبة التطابق ─────────────────────────────────────────
  Future<double> calculateMatch(
    String skills,
    String projectDescription, {
    Map<String, dynamic>? githubActivity,
  }) async {
    try {
      String githubContext = '';
      if (githubActivity != null && githubActivity['error'] == null) {
        githubContext = '''
GitHub Activity:
- Top Languages: ${githubActivity['top_languages']?.join(', ') ?? 'N/A'}
- Recent Repos: ${githubActivity['recent_repos']?.join(', ') ?? 'N/A'}
''';
      }

      final prompt = '''
$githubContext
Rate the match between these developer skills: "$skills" and this project: "$projectDescription".
Return only a number between 0 and 100.
''';

      final response = await _client.post('/chat/completions', data: {
        "model": ApiConstants.groqModel,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.1,
      });

      final result = response.data['choices'][0]['message']['content'];
      final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(result);
      if (match != null) return double.tryParse(match.group(0)!) ?? 0.0;
      return 0.0;
    } catch (e) {
      debugPrint('GroqService.calculateMatch error: $e');
      return 0.0;
    }
  }

  // ── استخراج مقترح مشروع من المحادثة ──────────────────────────
  Future<Map<String, dynamic>?> extractProjectProposal(dynamic history) async {
    try {
      final messages = _formatHistory(history);
      messages.add({
        "role": "system",
        "content":
            'You are a Senior Software Architect. The conversation history is with a NON-TECHNICAL founder. '
            'Your job is to translate their business needs into a HIGHLY TECHNICAL project proposal for developers. '
            'Return ONLY a valid JSON object with these keys: '
            '"title": (string, professional project title), '
            '"description": (string, technical description of the system), '
            '"techStack": (list of strings, suggest modern technologies like Flutter, Firebase, React, Node.js based on their needs), '
            '"ownerRequirements": (string). '
            'Ensure the JSON is strictly formatted.',
      });

      final response = await _client.post('/chat/completions', data: {
        "model": ApiConstants.groqModel,
        "messages": messages,
        "temperature": 0.3,
        "response_format": {"type": "json_object"},
      });

      final content = response.data['choices'][0]['message']['content'];
      return _extractJson(content);
    } catch (e) {
      debugPrint('GroqService.extractProjectProposal error: $e');
      return null;
    }
  }

  // ── ✅ إصلاح expandProjectIdea — كانت فارغة ──────────────────
  Future<Map<String, dynamic>?> expandProjectIdea(String miniConcept) async {
    try {
      final prompt = '''
You are a senior software architect. A project manager gave you this app idea: "$miniConcept".

Your job is to expand it into a professional project brief.
Return ONLY a valid JSON object with these exact keys:
{
  "title": "Professional project title",
  "description": "2-3 sentence professional project description",
  "techStack": ["Tech1", "Tech2", "Tech3", "Tech4"]
}
Keep it concise and practical.
''';

      final response = await _client.post('/chat/completions', data: {
        "model": ApiConstants.groqModel,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.7,
        "response_format": {"type": "json_object"},
      });

      final content = response.data['choices'][0]['message']['content'];
      return _extractJson(content);
    } catch (e) {
      debugPrint('GroqService.expandProjectIdea error: $e');
      return null;
    }
  }

  // ── إرسال رسالة Chat ──────────────────────────────────────────
  Future<String?> sendMessage(dynamic history) async {
    try {
      final messages = _formatHistory(history);
      final response = await _client.post('/chat/completions', data: {
        "model": ApiConstants.groqModel,
        "messages": messages,
        "temperature": 0.7,
      });
      return response.data['choices'][0]['message']['content'];
    } catch (e) {
      debugPrint('GroqService.sendMessage error: $e');
      return 'Error connecting to AI Architect.';
    }
  }

  // ── Helpers ───────────────────────────────────────────────────
  Map<String, dynamic>? _extractJson(String content) {
    try {
      final int start = content.indexOf('{');
      final int end = content.lastIndexOf('}');
      if (start == -1 || end == -1) return null;
      return jsonDecode(content.substring(start, end + 1)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('GroqService._extractJson error: $e');
      return null;
    }
  }

  List<Map<String, String>> _formatHistory(dynamic history) {
    final List<Map<String, String>> formatted = [];
    formatted.add({
      "role": "system",
      "content":
          "You are the 'DevSync Project Architect'. Your mission is to interview business owners/founders who are NON-TECHNICAL. "
          "CRITICAL RULES: "
          "1. NEVER use technical jargon (e.g., do not say 'Flutter', 'React', 'Database', 'API'). Speak in plain business/product language. "
          "2. Keep responses EXTREMELY short, concise, and direct (max 2-3 sentences). "
          "3. Ask ONE simple question at a time (e.g., 'Do you want a Mobile App, a Website, or both?'). "
          "4. Provide 2-4 short, bulleted options to make it easy to reply. "
          "5. Gather basic product needs: Platform type, Main Idea, Target Audience, and Core Features. "
          "IMPORTANT: Once you understand the product idea, "
          "append the hidden token [READY_TO_FINALIZE] at the very end of your response.",
    });

    if (history is! List) return formatted;
    for (var h in history) {
      if (h is Map) {
        final role = h['role'] == 'model' ? 'assistant' : 'user';
        final text = h['text']?.toString() ?? '';
        formatted.add({"role": role, "content": text});
      }
    }
    return formatted;
  }

  // للتوافق مع الكود القديم
  dynamic startChat({dynamic history}) => null;
}