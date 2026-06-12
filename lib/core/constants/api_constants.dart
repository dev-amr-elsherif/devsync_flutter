// ─── API Constants ───────────────────────────────────────────────────────────
class ApiConstants {
  ApiConstants._();

  // ── GitHub OAuth ───────────────────────────────────────────────
  static const String githubClientId     = 'Ov23liGJL09c0Oqc2Tbk';
  static const String githubCallbackUrl  = 'https://dev--sync.firebaseapp.com/__/auth/handler';
  static const String githubCallbackScheme = 'devsync';
  static const String githubAuthorizeUrl = 'https://github.com/login/oauth/authorize';
  static const String githubTokenUrl     = 'https://github.com/login/oauth/access_token';
  static const String githubApiBase      = 'https://api.github.com';

  // ── Firebase Cloud Function names ─────────────────────────────
  static const String cfExchangeGitHubToken = 'exchangeGitHubToken';

  // ── FCM / Notifications ────────────────────────────────────────
  static const String vapidKey =
      'BP-7kNYGUvd0IYXZHlplBZevMv4ro5HVFrW75KOPgpw2V2QMwjLLaSX8NfnwIx7GCigMkh8V4JnaeFNibpwfOEg';

  // ── Remote Config key names (values fetched at runtime) ────────
  static const String rcGithubClientSecret = 'github_client_secret';
  static const String rcGeminiApiKey       = 'gemini_api_key';
  
  // ── Gemini Key (Deprecated) ───────────────────────────────────
  static const String geminiApiKey         = 'YOUR_GEMINI_API_KEY';

  // ── Groq Key (Active) ──────────────────────────────────────────
  static const String groqApiKey           = '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';
  static const String groqBaseUrl          = 'https://api.groq.com/openai/v1';
  static const String groqModel            = 'llama-3.3-70b-versatile';

  // ── Hive box names (Legacy/Unused) ─────────────────────────────
  static const String hiveMatchesBox  = 'matches_box';
  static const String hiveProjectsBox = 'projects_box';
  static const String hiveUserBox     = 'user_box';
  static const String hiveCacheBox    = 'cache_box';

  static const Duration aiCacheTtl = Duration(hours: 24);
  static const int pageSize = 10;
}
