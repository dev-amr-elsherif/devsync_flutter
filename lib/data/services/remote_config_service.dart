import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../../core/constants/api_constants.dart';

/// Wraps Firebase Remote Config.
///
/// Secrets (Gemini key, GitHub client secret) are NEVER hardcoded in the app
/// binary — they live exclusively in Firebase Remote Config and are fetched
/// at startup. Fallback defaults are intentionally empty strings so the app
/// can detect a misconfiguration gracefully.
class RemoteConfigService {
  final FirebaseRemoteConfig _rc = FirebaseRemoteConfig.instance;

  Future<void> init() async {
    try {
      await _rc.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 15),
        minimumFetchInterval: const Duration(hours: 1),
      ));
    } catch (_) {
      // Desktop platforms (Windows/Linux/macOS) may not fully support
      // RemoteConfigSettings — continue with defaults.
    }

    try {
      await _rc.setDefaults({
        ApiConstants.rcGeminiApiKey:       '',
        ApiConstants.rcGithubClientSecret: '',
      });
    } catch (_) { /* ignore */ }

    try {
      await _rc.fetchAndActivate();
    } catch (_) {
      // Use cached/default values if fetch fails (offline or desktop).
    }
  }

  // ── Typed named getters ──────────────────────────────────────────────────

  /// Gemini 1.5 Flash API key — set in Firebase Console → Remote Config.
  String get geminiApiKey       => _rc.getString(ApiConstants.rcGeminiApiKey);

  /// GitHub OAuth Client Secret — set in Firebase Console → Remote Config.
  String get githubClientSecret => _rc.getString(ApiConstants.rcGithubClientSecret);

  /// Pro feature flag — toggle Pro-only features without a release.
  /// Default: false (safe — free tier behaviour if Remote Config unreachable).
  bool get isProFeaturesEnabled => _rc.getBool('pro_features_enabled');

  // ── Generic accessors for future keys ────────────────────────────────────
  String getString(String key) => _rc.getString(key);
  bool   getBool(String key)   => _rc.getBool(key);
  int    getInt(String key)    => _rc.getInt(key);
  double getDouble(String key) => _rc.getDouble(key);
}
