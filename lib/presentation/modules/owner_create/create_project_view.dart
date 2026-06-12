import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/skill_chip.dart';
import '../owner_dashboard/owner_controller.dart';
import '../ai_chat/ai_chat_view.dart';

class CreateProjectView extends GetView<OwnerController> {
  const CreateProjectView({super.key});

  @override
  Widget build(BuildContext context) {
    final techController = TextEditingController();
    final titleFieldController = TextEditingController();
    final descFieldController = TextEditingController();

    // Sync controllers with Rx state
    ever(controller.projectTitle, (val) {
      if (titleFieldController.text != val) titleFieldController.text = val;
    });
    ever(controller.projectDescription, (val) {
      if (descFieldController.text != val) descFieldController.text = val;
    });

    return Scaffold(
      floatingActionButton: _buildAIArchitectFAB(),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient)),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildHeader(),
                   const SizedBox(height: 24),
                   _buildTemplateShortcuts(),
                   const SizedBox(height: 24),
                   _buildManualForm(techController, titleFieldController, descFieldController),
                   const SizedBox(height: 24),
                   _buildSubmitButton(),
                   const SizedBox(height: 80), // Extra space for FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIArchitectFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          Get.bottomSheet(
            const AIChatView(),
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
          );
        },
        backgroundColor: AppTheme.secondary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.auto_awesome_rounded, size: 20),
        label: const Text('Design with AI Architect', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
      ),
    ).animate().scale(delay: const Duration(seconds: 1)).shimmer(duration: const Duration(seconds: 2));
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Launch Project', style: AppTheme.headlineLarge.copyWith(fontSize: 28)),
        const SizedBox(height: 4),
        Text('Describe your technical vision or use a shortcut.', style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary)),
      ],
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildTemplateShortcuts() {
    final templates = ['Mobile App', 'Web Platform', 'AI Engine', 'E-Commerce'];
    final icons = [Icons.smartphone_rounded, Icons.web_rounded, Icons.psychology_rounded, Icons.shopping_bag_rounded];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('QUICK TEMPLATES'),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, i) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => controller.applyTemplate(templates[i]),
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    borderColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icons[i], color: AppTheme.primary, size: 28),
                        const SizedBox(height: 8),
                        Text(templates[i], style: AppTheme.bodySmall.copyWith(fontWeight: FontWeight.bold, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: const Duration(milliseconds: 200)).slideY(begin: 0.1);
  }

  Widget _buildManualForm(TextEditingController techController, TextEditingController titleController, TextEditingController descController) {
    return Column(
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('CORE INFORMATION'),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: _buildEntryField(
                      label: 'PROJECT TITLE',
                      hint: 'e.g. Real-time Delivery Hub',
                      controller: titleController,
                      onChanged: (v) => controller.projectTitle.value = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Obx(() => IconButton.filled(
                    onPressed: controller.isRefining.value ? null : controller.refineProjectWithAI,
                    icon: controller.isRefining.value 
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.secondary.withValues(alpha: 0.2),
                      foregroundColor: AppTheme.secondary,
                    ),
                  )),
                ],
              ),
              const Divider(color: Colors.white10, height: 32),
              _buildEntryField(
                label: 'DESCRIPTION',
                hint: 'Specify goals and user stories...',
                maxLines: 4,
                controller: descController,
                onChanged: (v) => controller.projectDescription.value = v,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('TECHNICAL STACK'),
              const SizedBox(height: 16),
              _buildSmartTechSuggestions(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: techController,
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty) {
                          controller.addTech(v.trim());
                          techController.clear();
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Add custom skill...',
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () {
                      if (techController.text.trim().isNotEmpty) {
                        controller.addTech(techController.text.trim());
                        techController.clear();
                      }
                    },
                    icon: const Icon(Icons.add_rounded),
                    style: IconButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Obx(() => Wrap(
                spacing: 8,
                runSpacing: 8,
                children: controller.techStack.map((tech) => SkillChip(
                  label: tech,
                  isSelected: true,
                  onDelete: () => controller.removeTech(tech),
                )).toList(),
              )),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: const Duration(milliseconds: 400));
  }

  Widget _buildSmartTechSuggestions() {
    final suggestions = ['Flutter', 'Firebase', 'React', 'Python', 'Node.js', 'PostgreSQL', 'AI', 'UI/UX'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SUGGESTIONS', style: AppTheme.bodySmall.copyWith(fontSize: 9, color: AppTheme.textMuted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((s) => Obx(() {
            final isAdded = controller.techStack.contains(s);
            return GestureDetector(
              onTap: () => isAdded ? controller.removeTech(s) : controller.addTech(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isAdded ? AppTheme.primary.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isAdded ? AppTheme.primary : Colors.white12),
                ),
                child: Text(s, style: TextStyle(color: isAdded ? AppTheme.primary : AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            );
          })).toList(),
        ),
      ],
    );
  }

  Widget _buildEntryField({required String label, required String hint, int maxLines = 1, required TextEditingController controller, required Function(String) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white10),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Text(label, style: AppTheme.bodySmall.copyWith(color: AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.0));
  }

  Widget _buildSubmitButton() {
    return Obx(() => DevSyncButton(
      id: 'btn_manual_create',
      onPressed: controller.isCreatingProject.value ? null : controller.createProject,
      isLoading: controller.isCreatingProject.value,
      gradient: AppTheme.primaryGradient,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Text('Launch & Match', style: AppTheme.headlineMedium.copyWith(fontSize: 16)),
        ],
      ),
    )).animate().fadeIn(delay: const Duration(milliseconds: 600)).slideY(begin: 0.1);
  }
}
