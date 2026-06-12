import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import 'ai_chat_controller.dart';
import '../auth/auth_controller.dart';

class AIChatView extends GetView<AIChatController> {
  const AIChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController textController = TextEditingController();
    final authController = Get.find<AuthController>();
    final isOwner = authController.currentUser.value?.role == 'owner';

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: AppTheme.background.withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 40, spreadRadius: 5)],
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildHealthProgressBar(),
          Expanded(
            child: Obx(() => ListView.builder(
              controller: controller.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              reverse: false, // Normal order
              itemCount: controller.history.length,
              itemBuilder: (context, index) {
                final message = controller.history[index];
                return _buildMessageBubble(message).animate().fadeIn(delay: Duration(milliseconds: 100 * (index % 5))).slideY(begin: 0.1);
              },
            )),
          ),
          
          Obx(() => controller.isLoading.value ? _buildTypingIndicator() : const SizedBox.shrink()),

          // ─── NEW: Quick Replies ─────────────────────────────────────
          Obx(() => _buildQuickReplies()),

          // منطقة عرض المقترح في حال تم توليده
          Obx(() {
            final proposal = controller.proposedProject;
            if (proposal.isEmpty) return const SizedBox.shrink();
            return _buildProposalCard(proposal).animate().scale(curve: Curves.elasticOut);
          }),

          // زر إنهاء النقاش وتوليد المشروع (فقط إذا كان جاهزاً)
          if (isOwner) 
            Obx(() => (controller.isReadyToFinalize.value && controller.proposedProject.isEmpty) 
              ? _buildFinalizeButton() 
              : const SizedBox.shrink()),

          _buildInputArea(textController),
        ],
      ),
    );
  }

  Widget _buildHealthProgressBar() {
    return Obx(() => Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('PROJECT DEFINITION', style: AppTheme.bodySmall.copyWith(fontSize: 9, letterSpacing: 1.2, color: AppTheme.textMuted)),
              Text('${(controller.projectHealth.value * 100).toInt()}%', style: AppTheme.bodySmall.copyWith(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
            ],
          ),
        ),
        LinearProgressIndicator(
          value: controller.projectHealth.value,
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondary),
          minHeight: 2,
        ),
      ],
    ));
  }

  Widget _buildQuickReplies() {
    if (controller.quickReplies.isEmpty) return const SizedBox.shrink();
    return Container(
      height: 45,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.quickReplies.length,
        itemBuilder: (context, i) {
          final reply = controller.quickReplies[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              onPressed: () => controller.sendMessage(reply),
              label: Text(reply),
              backgroundColor: AppTheme.secondary.withValues(alpha: 0.1),
              side: BorderSide(color: AppTheme.secondary.withValues(alpha: 0.2)),
              labelStyle: TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.w600),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: List.generate(3, (i) => Container(
                width: 6, height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
              ).animate(onPlay: (c) => c.repeat()).scale(delay: Duration(milliseconds: i * 200), duration: const Duration(milliseconds: 600))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 12, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Project Architect', style: AppTheme.headlineMedium.copyWith(fontSize: 16)),
              Text('Llama 3.3 Enhanced', style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryLight, fontSize: 9)),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Content content) {
    final bool isModel = content.role == 'model';
    final String text = content.parts.whereType<TextPart>().map((e) => e.text).join();

    return Align(
      alignment: isModel ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        constraints: BoxConstraints(maxWidth: Get.width * 0.8),
        decoration: BoxDecoration(
          gradient: isModel 
              ? LinearGradient(colors: [Colors.white.withValues(alpha: 0.08), Colors.white.withValues(alpha: 0.03)]) 
              : AppTheme.primaryGradient,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isModel ? Radius.zero : const Radius.circular(20),
            bottomRight: isModel ? const Radius.circular(20) : Radius.zero,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontSize: 14,
            height: 1.4,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildProposalCard(Map<String, dynamic> proposal) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.rocket_launch_rounded, color: AppTheme.primary, size: 20),
                SizedBox(width: 8),
                Text('Proposed Project', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(proposal['title'] ?? '', style: AppTheme.headlineMedium.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              proposal['description'] ?? '',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => controller.confirmAndCreateProject(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Confirm & Create Project'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalizeButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextButton.icon(
        onPressed: () => controller.finalizeProject(),
        icon: const Icon(Icons.task_alt_rounded),
        label: const Text('Finalize Concept & Generate Project'),
        style: TextButton.styleFrom(foregroundColor: AppTheme.primaryLight),
      ),
    );
  }

  Widget _buildInputArea(TextEditingController textController) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: textController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Discuss project dimensions...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
                onSubmitted: (val) {
                  controller.sendMessage(val);
                  textController.clear();
                },
              ),
            ),
            Obx(() => controller.isLoading.value
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : IconButton(
                    onPressed: () {
                      controller.sendMessage(textController.text);
                      textController.clear();
                    },
                    icon: const Icon(Icons.send_rounded, color: AppTheme.primary),
                  )),
          ],
        ),
      ),
    );
  }
}
