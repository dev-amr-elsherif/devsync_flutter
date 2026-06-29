// lib/presentation/modules/auth/auth_controller.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:get/get.dart';
import 'analysis_loading_view.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/providers/firebase_provider.dart';
import '../../../../data/services/analytics_service.dart';

class AuthController extends GetxController {
  final FirebaseProvider _firebaseProvider = Get.find<FirebaseProvider>();
  final AnalyticsService _analytics = Get.find<AnalyticsService>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _auth.authStateChanges().listen((User? firebaseUser) async {
      if (firebaseUser != null) {
        if (!isLoading.value) {
          await _syncUserProfile(firebaseUser);
          _analytics.setUserId(firebaseUser.uid);
        }
      } else {
        currentUser.value = null;
        if (Get.currentRoute != '/onboarding') {
          Get.offAllNamed('/onboarding');
        }
      }
    });
  }

  Future<void> _syncUserProfile(User firebaseUser) async {
    try {
      final userModel = await _firebaseProvider.getUser(firebaseUser.uid);
      if (userModel != null) {
        await _firebaseProvider.saveUser(userModel);
        currentUser.value = userModel;
        _navigateBasedOnRole(userModel);
      }
    } catch (e) {
      debugPrint('Error syncing profile: $e');
    }
  }

  // ✅ إصلاح: استخراج الكود المكرر في method واحدة
  Future<String?> _getGithubAccessToken(UserCredential credential) async {
    try {
      return (credential.credential as dynamic).accessToken;
    } catch (e) {
      debugPrint('DEBUG: Could not extract access token: $e');
      return null;
    }
  }

  // ✅ إصلاح: استخراج GitHub flow المكرر في method واحدة
  Future<void> _handleGithubAnalysisFlow(UserCredential credential) async {
    final profile = credential.additionalUserInfo?.profile;
    if (profile == null) return;

    final token = await _getGithubAccessToken(credential);
    if (token != null) {
      Get.to(
        () => AnalysisLoadingView(
          username: profile['login']?.toString() ?? 'developer',
          token: token,
        ),
      );
    } else {
      debugPrint('DEBUG: Failed to get GitHub Access Token.');
      await _createOrUpdateProfile(credential.user!, 'developer');
    }
  }

  Future<void> loginAsDeveloper() async {
    try {
      isLoading.value = true;
      final GithubAuthProvider githubProvider = GithubAuthProvider();
      final UserCredential credential = await _auth.signInWithProvider(
        githubProvider,
      );

      if (credential.user != null) {
        final UserModel? existingUser = await _firebaseProvider.getUser(
          credential.user!.uid,
        );
        final needsAnalysis =
            existingUser == null || existingUser.githubUrl == null;

        if (needsAnalysis) {
          // ✅ استخدام الـ method المشتركة بدل التكرار
          await _handleGithubAnalysisFlow(credential);
          return;
        }
        await _createOrUpdateProfile(credential.user!, 'developer');
      }
    } catch (e) {
      debugPrint('DEBUG: GitHub Login Error: $e');
      Get.snackbar(
        'Authentication Failed',
        'Could not sign in with GitHub: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshDeveloperPortfolio() async {
    try {
      isLoading.value = true;
      final GithubAuthProvider githubProvider = GithubAuthProvider();
      final UserCredential credential = await _auth.signInWithProvider(
        githubProvider,
      );

      if (credential.user != null) {
        // ✅ نفس الـ method — مش كود مكرر
        await _handleGithubAnalysisFlow(credential);
        return;
      }
    } catch (e) {
      debugPrint('DEBUG: GitHub Refresh Error: $e');
      Get.snackbar('Refresh Failed', 'Could not refresh from GitHub: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loginAsOwner() async {
    try {
      isLoading.value = true;
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        isLoading.value = false;
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCred = await _auth.signInWithCredential(
        credential,
      );
      if (userCred.user != null) {
        await _analytics.logGoogleLogin();
        await _createOrUpdateProfile(userCred.user!, 'owner');
      }
    } catch (e) {
      debugPrint('Google Login Error: $e');
      Get.snackbar(
        'Authentication Failed',
        'Could not sign in with Google: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _createOrUpdateProfile(
    User firebaseUser,
    String role, {
    Map<String, dynamic>? aiAnalysis,
  }) async {
    try {
      UserModel? existingUser;
      try {
        existingUser = await _firebaseProvider.getUser(firebaseUser.uid);
      } catch (e) {
        debugPrint('Non-fatal error fetching existing user: $e');
      }

      // ✅ استخدام copyWith بدل إعادة كتابة كل الحقول
      final baseUser =
          existingUser ??
          UserModel(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ?? '',
            photoUrl: firebaseUser.photoURL,
            role: role,
          );

      final UserModel userModel = baseUser.copyWith(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? baseUser.email,
        name: firebaseUser.displayName ?? baseUser.name,
        photoUrl: firebaseUser.photoURL ?? baseUser.photoUrl,
        role: role,
        githubUrl: aiAnalysis?['githubUrl'] ?? baseUser.githubUrl,
        aiBio: aiAnalysis?['aiBio'] ?? baseUser.aiBio,
        githubSeniority:
            aiAnalysis?['githubSeniority'] ?? baseUser.githubSeniority,
        topAiSkills: aiAnalysis != null
            ? List<String>.from(aiAnalysis['topAiSkills'] ?? [])
            : baseUser.topAiSkills,
        publicRepos: aiAnalysis?['publicRepos'] ?? baseUser.publicRepos,
        followers: aiAnalysis?['followers'] ?? baseUser.followers,
        accountAgeYears:
            aiAnalysis?['accountAgeYears'] ?? baseUser.accountAgeYears,
        location: aiAnalysis?['location'] ?? baseUser.location,
        topRepositories: aiAnalysis?['topRepositories'] != null
            ? List<dynamic>.from(aiAnalysis!['topRepositories'])
            : baseUser.topRepositories,
      );

      await _firebaseProvider.saveUser(userModel);
      currentUser.value = userModel;
      await _analytics.logRoleSelected(role);
      _navigateBasedOnRole(userModel);
    } catch (e) {
      debugPrint('CRITICAL ERROR in _createOrUpdateProfile: $e');
      if (e.toString().contains('permission-denied')) {
        Get.snackbar(
          'Database Error',
          'Permission denied. Please check Firestore rules.',
          backgroundColor: Colors.red.withValues(alpha: 0.1),
          colorText: Colors.red,
        );
      } else {
        Get.snackbar('Error', 'Failed to configure your profile: $e');
      }
    }
  }

  Future<void> completeDeveloperProfile(Map<String, dynamic> aiAnalysis) async {
    final user = _auth.currentUser;
    if (user != null) {
      await _createOrUpdateProfile(user, 'developer', aiAnalysis: aiAnalysis);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    currentUser.value = null;
    Get.offAllNamed('/onboarding');
  }

  void _navigateBasedOnRole(UserModel user) {
    if (user.isDeveloper || user.isOwner) {
      Get.offAllNamed('/main-shell');
    } else {
      Get.offAllNamed('/onboarding');
    }
  }

  bool get isLoggedIn => currentUser.value != null;
}
