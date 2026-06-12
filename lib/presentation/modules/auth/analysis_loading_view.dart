import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio_lib;
import '../../../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'auth_controller.dart';

class AnalysisLoadingView extends StatefulWidget {
  final String username;
  final String token;

  const AnalysisLoadingView({
    super.key,
    required this.username,
    required this.token,
  });

  @override
  State<AnalysisLoadingView> createState() => _AnalysisLoadingViewState();
}

class _AnalysisLoadingViewState extends State<AnalysisLoadingView> {
  final List<String> _steps = [
    'Connecting to GitHub...',
    'Fetching repositories...',
    'Analyzing code metrics...',
    'Consulting AI for insights...',
    'Finalizing your portfolio...',
  ];

  int _currentStep = 0;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startAnalysis();
    _simulateSteps();
  }

  void _simulateSteps() async {
    for (int i = 0; i < _steps.length - 1; i++) {
      if (_hasError) break;
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && !_hasError) {
        setState(() {
          _currentStep = i + 1;
        });
      }
    }
  }

  Future<void> _startAnalysis() async {
    try {
      final dio = dio_lib.Dio();
      
      // Use 10.0.2.2 for Android emulator to reach localhost, or localhost for iOS/Web
      // In production, this would be a real URL.
      final baseUrl = GetPlatform.isAndroid ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
      
      final response = await dio.post(
        '$baseUrl/analyze',
        data: {
          'username': widget.username,
          'token': widget.token,
        },
      );

      if (response.statusCode == 200) {
        final analysis = response.data;
        final controller = Get.find<AuthController>();
        
        // Complete the profile update with AI data
        await controller.completeDeveloperProfile(analysis);
      } else {
        throw Exception('Server responded with status: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIcon(),
                    const SizedBox(height: 48),
                    _buildProgressCard(),
                    if (_hasError) ...[
                      const SizedBox(height: 24),
                      _buildErrorState(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2), width: 2),
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        color: AppTheme.primary,
        size: 64,
      ),
    );
  }

  Widget _buildProgressCard() {
    return GlassCard(
      child: Column(
        children: [
          Text(
            'Analyzing Portfolio',
            style: AppTheme.headlineMedium.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            'Crafting your professional digital identity',
            style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          LinearProgressIndicator(
            backgroundColor: Colors.white10,
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
          const SizedBox(height: 32),
          Column(
            children: List.generate(_steps.length, (index) {
              final isCurrent = index == _currentStep;
              final isDone = index < _currentStep;
              
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      isDone ? Icons.check_circle_rounded : (isCurrent ? Icons.sync_rounded : Icons.circle_outlined),
                      color: isDone ? Colors.green : (isCurrent ? AppTheme.primary : Colors.white24),
                      size: 20,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _steps[index],
                      style: AppTheme.bodyMedium.copyWith(
                        color: isCurrent || isDone ? AppTheme.textPrimary : AppTheme.textSecondary,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isCurrent) ...[
                      const SizedBox(width: 12),
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ]
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        Text(
          _errorMessage ?? 'Something went wrong during analysis',
          style: AppTheme.bodyMedium.copyWith(color: AppTheme.error),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => Get.back(),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
          child: const Text('Go Back'),
        ),
      ],
    );
  }
}
