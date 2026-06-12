import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  // ─── Auth Events ──────────────────────────────────────────────────
  Future<void> logGitHubLogin() => _analytics.logLogin(loginMethod: 'github');
  Future<void> logGoogleLogin() => _analytics.logLogin(loginMethod: 'google');
  Future<void> logSignOut() => _event('sign_out');

  // ─── Role Events ──────────────────────────────────────────────────
  Future<void> logRoleSelected(String role) =>
      _event('role_selected', params: {'role': role});

  // ─── Developer Events ─────────────────────────────────────────────
  Future<void> logAIMatchRequested() => _event('ai_match_requested');
  Future<void> logMatchViewed(String projectId) =>
      _event('match_viewed', params: {'project_id': projectId});
  Future<void> logProfileRefreshed() => _event('profile_refreshed');

  // ─── Owner Events ─────────────────────────────────────────────────
  Future<void> logProjectCreated(String projectTitle) =>
      _event('project_created', params: {'title': projectTitle});
  Future<void> logDeveloperSuggested() => _event('developer_suggested');
  Future<void> logProjectDescriptionGenerated() => _event('project_ai_refined');
  Future<void> logProjectTemplateApplied(String type) => 
      _event('project_template_applied', params: {'type': type});

  // ─── Generic ──────────────────────────────────────────────────────
  Future<void> setUserId(String uid) => _analytics.setUserId(id: uid);
  Future<void> setUserRole(String role) =>
      _analytics.setUserProperty(name: 'role', value: role);

  Future<void> _event(String name, {Map<String, Object>? params}) =>
      _analytics.logEvent(name: name, parameters: params);
}
