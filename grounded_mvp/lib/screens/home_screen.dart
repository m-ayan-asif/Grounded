import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../models.dart';
import '../services/blocker_service.dart';
import '../theme.dart';
import 'create_task_screen.dart';
import 'settings_screen.dart';
import 'blocked_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _hasPermission = false;
  bool _permissionChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-check when user comes back from Accessibility Settings
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await BlockerService.hasAccessibilityPermission();
    if (mounted) {
      setState(() {
        _hasPermission = granted;
        _permissionChecked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    // Show blocked screen when Android reports a blocked app was opened
    if (state.pendingBlockedApp != null) {
      final appName = state.pendingBlockedApp!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        state.clearPendingBlockedApp();
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => BlockedScreen(appName: appName)),
        );
      });
    }

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header()),
            if (_permissionChecked && !_hasPermission)
              SliverToBoxAdapter(
                child: _PermissionBanner(
                  onTap: () async {
                    await BlockerService.requestAccessibilityPermission();
                    // didChangeAppLifecycleState will re-check on return
                  },
                ),
              ),
            SliverToBoxAdapter(child: _BreakBanner()),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: _TaskList(),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
        ),
        backgroundColor: AppColors.lavender,
        foregroundColor: Colors.white,
        elevation: 6,
        child: const Icon(Icons.add_rounded, size: 32),
      ),
    );
  }
}

// ── Permission Banner ───────────────────────────────────────────────────────

class _PermissionBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PermissionBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.accessibility_new_rounded,
                  color: Colors.orange.shade600, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enable App Blocking',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                          fontSize: 14),
                    ),
                    Text(
                      'Tap → turn on "Grounded App Blocker" in Accessibility Settings.',
                      style: TextStyle(
                          color: Colors.orange.shade700, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.orange.shade600),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Grounded',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.chalk : AppColors.charcoal,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stay focused, stay productive.',
                  style: TextStyle(
                      color: isDark
                          ? AppColors.slate400
                          : AppColors.slate500,
                      fontSize: 14),
                ),
              ],
            ),
          ),
          Material(
            color: isDark ? AppColors.charcoalLight : Colors.white,
            borderRadius: BorderRadius.circular(16),
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => const SettingsScreen())),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(Icons.settings_outlined,
                    color: isDark
                        ? AppColors.slate400
                        : AppColors.slate500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Break Banner ────────────────────────────────────────────────────────────

class _BreakBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (!state.isBreaking) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.lavender.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.lavender.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.coffee_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('On a Break',
                      style: TextStyle(
                          color: AppColors.lavender,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  Text('${state.breakTimerLabel} remaining',
                      style: const TextStyle(
                          color: AppColors.lavender, fontSize: 13)),
                ],
              ),
            ),
            TextButton(
              onPressed: state.endBreak,
              child: const Text('End',
                  style: TextStyle(
                      color: AppColors.lavender,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Task List ───────────────────────────────────────────────────────────────

class _TaskList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<AppState>().tasks;

    if (tasks.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 80),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.charcoalLight
                        : AppColors.slate100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      size: 36, color: AppColors.slate400),
                ),
                const SizedBox(height: 20),
                const Text('No tasks yet.',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.slate400)),
                const SizedBox(height: 8),
                const Text(
                  'Tap + to create a task and start blocking distractions.',
                  style:
                      TextStyle(color: AppColors.slate400, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _TaskCard(task: tasks[i]),
        ),
        childCount: tasks.length,
      ),
    );
  }
}

// ── Task Card ───────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final Task task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.charcoalLight : Colors.white;
    final border =
        isDark ? Colors.grey.withOpacity(0.15) : Colors.grey.withOpacity(0.1);

    return Opacity(
      opacity: task.isCompleted ? 0.6 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: border),
          boxShadow: task.isCompleted
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => state.toggleTask(task.id),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        task.isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: task.isCompleted
                            ? AppColors.lavender
                            : AppColors.slate400,
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: task.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                            color: isDark
                                ? AppColors.chalk
                                : AppColors.charcoal,
                          ),
                        ),
                        if (task.description?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(task.description!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.slate500,
                                  height: 1.4)),
                        ],
                      ],
                    ),
                  ),
                  Row(children: [
                    _Btn(
                      icon: Icons.chevron_right_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                CreateTaskScreen(editingTask: task)),
                      ),
                    ),
                    _Btn(
                      icon: Icons.delete_outline_rounded,
                      color: Colors.red.shade300,
                      onTap: () => state.deleteTask(task.id),
                    ),
                  ]),
                ],
              ),

              // Blocked apps row
              if (!task.isCompleted && task.blockedApps.isNotEmpty) ...[
                const SizedBox(height: 14),
                Divider(height: 1, color: border),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.shield_outlined,
                          size: 12, color: AppColors.slate400),
                      SizedBox(width: 4),
                      Text('BLOCKING',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate400,
                              letterSpacing: 0.8)),
                    ]),
                    ...task.blockedApps
                        .map((app) => _AppChip(app: app, isDark: isDark)),
                  ],
                ),
              ],

              // Subtasks
              if (task.subTasks.isNotEmpty) ...[
                const SizedBox(height: 14),
                ...task.subTasks.map((sub) => _SubTaskRow(
                      sub: sub,
                      onToggle: () =>
                          state.toggleSubTask(task.id, sub.id),
                      isDark: isDark,
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SubTaskRow extends StatelessWidget {
  final SubTask sub;
  final VoidCallback onToggle;
  final bool isDark;
  const _SubTaskRow(
      {required this.sub,
      required this.onToggle,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sub.isCompleted
                    ? AppColors.lavender
                    : (isDark
                        ? Colors.grey.shade700
                        : AppColors.slate200),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(sub.title,
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.slate400
                          : AppColors.slate500,
                      decoration: sub.isCompleted
                          ? TextDecoration.lineThrough
                          : null)),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.lavender.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(sub.estimatedTime,
                  style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.lavender)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppChip extends StatelessWidget {
  final String app;
  final bool isDark;
  const _AppChip({required this.app, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.charcoal : AppColors.slate100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(kAppEmojis[app] ?? '📱',
              style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(app,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _Btn({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon,
              size: 20, color: color ?? AppColors.slate400),
        ),
      );
}
