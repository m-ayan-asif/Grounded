import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../services/ai_service.dart';
import '../theme.dart';

class CreateTaskScreen extends StatefulWidget {
  final Task? editingTask;
  const CreateTaskScreen({super.key, this.editingTask});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late List<String> _selectedApps;
  late List<SubTask> _subTasks;
  bool _isBreakingDown = false;

  @override
  void initState() {
    super.initState();
    final t = widget.editingTask;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _selectedApps = List<String>.from(t?.blockedApps ?? []);
    _subTasks = List<SubTask>.from(t?.subTasks ?? []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _breakDownWithAI() async {
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Please enter a title first.');
      return;
    }
    setState(() => _isBreakingDown = true);
    try {
      final backendUrl = context.read<AppState>().settings.backendUrl;
      final result = await AIService.breakdownTask(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        backendUrl: backendUrl,
      );
      setState(() => _subTasks = result);
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''),
          error: true);
    } finally {
      if (mounted) setState(() => _isBreakingDown = false);
    }
  }

  void _save() {
    if (_titleCtrl.text.trim().isEmpty) {
      _snack('Title cannot be empty.');
      return;
    }
    final state = context.read<AppState>();
    if (widget.editingTask != null) {
      state.updateTask(widget.editingTask!.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        blockedApps: _selectedApps,
        subTasks: _subTasks,
      ));
    } else {
      state.addTask(Task(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        blockedApps: _selectedApps,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        subTasks: _subTasks,
      ));
    }
    Navigator.pop(context);
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade400 : null,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.editingTask != null;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(children: [
                _CircleBtn(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                    isDark: isDark),
                const SizedBox(width: 14),
                Text(isEditing ? 'Edit Task' : 'New Task',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 32),

              // Title
              _Label('Title'),
              const SizedBox(height: 8),
              _Field(
                controller: _titleCtrl,
                hint: 'What needs to be done?',
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600),
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // Description
              _Label('Description (Optional)'),
              const SizedBox(height: 8),
              _Field(
                controller: _descCtrl,
                hint: 'Add more details...',
                maxLines: 4,
                isDark: isDark,
              ),
              const SizedBox(height: 24),

              // Block Apps
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Label('Block Apps'),
                  const Text('Tap to toggle',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.slate400)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: kBlockedApps.map((app) {
                  final selected = _selectedApps.contains(app);
                  return GestureDetector(
                    onTap: () => setState(() {
                      selected
                          ? _selectedApps.remove(app)
                          : _selectedApps.add(app);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.lavender.withOpacity(0.12)
                            : (isDark
                                ? AppColors.charcoalLight
                                : Colors.white),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? AppColors.lavender
                              : (isDark
                                  ? Colors.grey.withOpacity(0.2)
                                  : Colors.grey.withOpacity(0.15)),
                          width: selected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(children: [
                        Text(kAppEmojis[app] ?? '📱',
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(app,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: selected
                                    ? AppColors.lavender
                                    : AppColors.slate400,
                                letterSpacing: 0.3)),
                      ]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // AI Breakdown button
              GestureDetector(
                onTap: _isBreakingDown ? null : _breakDownWithAI,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: AppColors.lavender.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.lavender.withOpacity(0.35),
                        width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isBreakingDown
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.lavender))
                          : const Icon(Icons.auto_awesome_rounded,
                              color: AppColors.lavender, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        _isBreakingDown
                            ? 'Breaking down…'
                            : _subTasks.isEmpty
                                ? 'Break Down with AI'
                                : 'Regenerate AI Breakdown',
                        style: const TextStyle(
                            color: AppColors.lavender,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),

              // Subtasks preview
              if (_subTasks.isNotEmpty) ...[
                const SizedBox(height: 16),
                ..._subTasks.map((sub) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.charcoalLight
                              : AppColors.slate100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: isDark
                                  ? Colors.grey.withOpacity(0.15)
                                  : Colors.grey.withOpacity(0.1)),
                        ),
                        child: Row(children: [
                          Expanded(
                              child: Text(sub.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14))),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.lavender.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(sub.estimatedTime,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.lavender)),
                          ),
                        ]),
                      ),
                    )),
              ],

              const SizedBox(height: 36),

              // Save / Cancel
              Row(children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(
                            color: AppColors.slate400,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lavender,
                      padding:
                          const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: Text(
                      isEditing ? 'Save Changes' : 'Create Task',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared small widgets ────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: AppColors.slate500));
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextStyle? style;
  final bool isDark;
  const _Field(
      {required this.controller,
      required this.hint,
      required this.isDark,
      this.maxLines = 1,
      this.style});

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        maxLines: maxLines,
        style: style,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: AppColors.slate400, fontSize: 14),
          filled: true,
          fillColor: isDark
              ? AppColors.charcoal.withOpacity(0.6)
              : AppColors.slate100,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: isDark
                      ? Colors.grey.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.15))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                  color: isDark
                      ? Colors.grey.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.15))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                  color: AppColors.lavender, width: 2)),
        ),
      );
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _CircleBtn(
      {required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) => Material(
        color: isDark ? AppColors.charcoalLight : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, size: 20)),
        ),
      );
}
