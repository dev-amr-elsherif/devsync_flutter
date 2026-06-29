import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

// ─── API Constants ─────────────────────────────────────────────────────────
class ApiConstants {
  ApiConstants._();

  // ── GitHub OAuth ──────────────────────────────────────────────
  static const String githubClientId = 'Ov23liGJL09c0Oqc2Tbk';
  static const String githubCallbackUrl =
      'https://dev--sync.firebaseapp.com/__/auth/handler';
  static const String githubCallbackScheme = 'devsync';
  static const String githubAuthorizeUrl =
      'https://github.com/login/oauth/authorize';
  static const String githubTokenUrl =
      'https://github.com/login/oauth/access_token';
  static const String githubApiBase = 'https://api.github.com';

  // ── Firebase Cloud Function names ─────────────────────────────
  static const String cfExchangeGitHubToken = 'exchangeGitHubToken';

  // ── FCM / Notifications ────────────────────────────────────────
  static const String vapidKey =
      'BP-7kNYGUvd0IYXZHlplBZevMv4ro5HVFrW75KOPgpw2V2QMwjLLaSX8NfnwIx7GCigMkh8V4JnaeFNibpwfOEg';

  // ── Remote Config key names ────────────────────────────────────
  static const String rcGithubClientSecret = 'github_client_secret';
  static const String rcGeminiApiKey = 'gemini_api_key';
  static const String rcGroqApiKey = 'groq_api_key'; // ✅ NEW

  // ── Groq (Active AI) ──────────────────────────────────────────
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String groqModel = 'llama-3.3-70b-versatile';

  // ── Python Backend ────────────────────────────────────────────
  static String get pythonBackendUrl {
    if (kIsWeb) return 'http://localhost:8000';
    if (GetPlatform.isAndroid) return 'http://192.168.1.15:8000';
    return 'http://localhost:8000';
  }

  // ── Hive box names (Legacy/Unused) ────────────────────────────
  static const String hiveMatchesBox = 'matches_box';
  static const String hiveProjectsBox = 'projects_box';
  static const String hiveUserBox = 'user_box';
  static const String hiveCacheBox = 'cache_box';

  static const Duration aiCacheTtl = Duration(hours: 24);
  static const int pageSize = 10;
}
