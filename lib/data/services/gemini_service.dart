import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import 'package:flutter/foundation.dart';

class GeminiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.groqBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    headers: {
      'Authorization': 'Bearer ${ApiConstants.groqApiKey}',
      'Content-Type': 'application/json',
    },
  ));

  // استخراج مقترح مشروع كامل بناءً على المحادثة باستخدام Groq
  Future<Map<String, dynamic>?> extractProjectProposal(dynamic history) async {
    try {
      final messages = _formatHistory(history);
      messages.add({
        "role": "system",
        "content": "Return ONLY a valid JSON object with these keys: "
            "\"title\": (string), \"description\": (string), \"techStack\": (list of strings), \"ownerRequirements\": (string). "
            "Ensure the JSON is strictly formatted."
      });

      final response = await _dio.post('/chat/completions', data: {
        "model": ApiConstants.groqModel,
        "messages": messages,
        "temperature": 0.3,
        "response_format": {"type": "json_object"}
      });

      final content = response.data['choices'][0]['message']['content'];
      return _extractJson(content);
    } catch (e) {
      debugPrint('DEBUG: Groq extraction error: $e');
      return null;
    }
  }

  // حساب نسبة التطابق باستخدام Groq
  Future<double> calculateMatch(
    String skills, 
    String projectDescription, {
    Map<String, dynamic>? githubActivity,
  }) async {
    try {
      String githubContext = '';
      if (githubActivity != null && githubActivity['error'] == null) {
        githubContext = '''
User GitHub Activity:
- Top Languages: ${githubActivity['top_languages']?.join(', ') ?? 'N/A'}
- Recent Repos: ${githubActivity['recent_repos']?.join(', ') ?? 'N/A'}
''';
      }

      final prompt = '''
$githubContext
Rate the match between these developer skills: "$skills" and this project description: "$projectDescription".
Return only a number between 0 and 100.
''';

      final response = await _dio.post('/chat/completions', data: {
        "model": ApiConstants.groqModel,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.1,
      });

      final result = response.data['choices'][0]['message']['content'];
      
      // Use regex to find the first number in the response (handles things like "Score: 85")
      final match = RegExp(r"(\d+(\.\d+)?)").firstMatch(result);
      if (match != null) {
        return double.tryParse(match.group(0)!) ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // توسيع فكرة مشروع بسيطة باستخدام Groq
  Future<Map<String, dynamic>?> expandProjectIdea(String miniConcept) async {
    try {
      final prompt = '''
Analyze: "$miniConcept".
Expand into professional JSON with:
"title": Refined Name,
"description": 3-4 sentences scope,
"techStack": 5-8 technologies.
ONLY JSON.
''';

      final response = await _dio.post('/chat/completions', data: {
        "model": ApiConstants.groqModel,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.7,
        "response_format": {"type": "json_object"}
      });

      final content = response.data['choices'][0]['message']['content'];
      return _extractJson(content);
    } catch (e) {
      debugPrint('DEBUG: Groq expansion error: $e');
      return null;
    }
  }

  // ─── NEW: Robust JSON Extraction ───
  Map<String, dynamic>? _extractJson(String content) {
    try {
      // Find the first '{' and last '}' to strip Markdown backticks or extra text
      final int start = content.indexOf('{');
      final int end = content.lastIndexOf('}');
      if (start == -1 || end == -1) return null;

      final String cleanJson = content.substring(start, end + 1);
      return jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('DEBUG: JSON clean/parse error: $e');
      return null;
    }
  }

  // إرسال رسالة في الشات والحصول على رد من Groq
  Future<String?> sendMessage(dynamic history) async {
    try {
      final messages = _formatHistory(history);
      
      final response = await _dio.post('/chat/completions', data: {
        "model": ApiConstants.groqModel,
        "messages": messages,
        "temperature": 0.7,
      });

      return response.data['choices'][0]['message']['content'];
    } catch (e) {
      debugPrint('DEBUG: Groq Chat Error: $e');
      return 'Error connecting to AI Architect.';
    }
  }

  // تحويل الهستوري من تنسيق Google Generative AI المعتمد سابقاً إلى تنسيق OpenAI/Groq
  List<Map<String, String>> _formatHistory(dynamic history) {
    List<Map<String, String>> formatted = [];
    
    // ─── RIGOROUS SYSTEM PROMPT ─────────────────────────────────────
    formatted.add({
      "role": "system",
      "content": "You are the 'DevSync Project Architect'. Your mission is to interview project managers "
          "to create highly detailed project assignments for developers. "
          "BE DISCIPLINED: Do not allow shallow ideas. Ask about: 1. Platform (Web/Mobile), 2. Core Problem, "
          "3. Main Features, 4. Tech Preferences. "
          "IMPORTANT: Only when you have a professional-grade definition (Title, Type, and Scope), "
          "append the hidden token [READY_TO_FINALIZE] at the very end of your response. "
          "Speak in a professional, senior technical tone."
    });

    if (history is! List) return formatted;
    
    for (var h in history) {
      final role = h.role == 'model' ? 'assistant' : 'user';
      final parts = h.parts;
      String text = '';
      if (parts is List) {
        text = parts.map((p) => p.text).join('\n');
      }
      formatted.add({"role": role, "content": text});
    }
    return formatted;
  }

  // بدء جلسة شات (للتوافق مع الكود القديم فقط)
  dynamic startChat({dynamic history}) {
    // Groq لا يحتاج ChatSession مفتوح، سنقوم بإرسال الهستوري كاملاً مع كل رسالة
    return null; 
  }
}
