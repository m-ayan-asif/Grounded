import 'dart:async';
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'services/storage_service.dart';
import 'services/blocker_service.dart';

class AppState extends ChangeNotifier {
  List<Task> _tasks = [];
  AppSettings _settings = const AppSettings();
  bool _isBreaking = false;
  int _breakTimer = 0;
  Timer? _timer;
  bool _initialized = false;

  /// Set by the Android accessibility service when a blocked app is opened.
  String? pendingBlockedApp;

  final _storage = StorageService();

  List<Task> get tasks => _tasks;
  AppSettings get settings => _settings;
  bool get isBreaking => _isBreaking;
  int get breakTimer => _breakTimer;
  bool get initialized => _initialized;

  String get breakTimerLabel {
    final m = _breakTimer ~/ 60;
    final s = _breakTimer % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// All apps actively blocked across incomplete tasks.
  List<String> get activeBlockedApps {
    final apps = <String>{};
    for (final t in _tasks) {
      if (!t.isCompleted) apps.addAll(t.blockedApps);
    }
    return apps.toList();
  }

  Future<void> initialize() async {
    _tasks = await _storage.loadTasks();
    _settings = await _storage.loadSettings();
    _initialized = true;

    // Wire Android → Flutter callback
    BlockerService.initialize();
    BlockerService.onAppBlocked = (appName) {
      pendingBlockedApp = appName;
      notifyListeners();
    };

    // Resume blocking if tasks exist (e.g. after app restart)
    _syncBlocker();
    notifyListeners();
  }

  // ── Tasks ──────────────────────────────────────────────────────────────────

  void addTask(Task task) {
    _tasks = [task, ..._tasks];
    _storage.saveTasks(_tasks);
    _syncBlocker();
    notifyListeners();
  }

  void updateTask(Task task) {
    _tasks = _tasks.map((t) => t.id == task.id ? task : t).toList();
    _storage.saveTasks(_tasks);
    _syncBlocker();
    notifyListeners();
  }

  void deleteTask(String id) {
    _tasks = _tasks.where((t) => t.id != id).toList();
    _storage.saveTasks(_tasks);
    _syncBlocker();
    notifyListeners();
  }

  void toggleTask(String id) {
    _tasks = _tasks
        .map((t) => t.id == id ? t.copyWith(isCompleted: !t.isCompleted) : t)
        .toList();
    _storage.saveTasks(_tasks);
    _syncBlocker();
    notifyListeners();
  }

  void toggleSubTask(String taskId, String subTaskId) {
    _tasks = _tasks.map((t) {
      if (t.id != taskId) return t;
      return t.copyWith(
        subTasks: t.subTasks
            .map((s) => s.id == subTaskId
                ? s.copyWith(isCompleted: !s.isCompleted)
                : s)
            .toList(),
      );
    }).toList();
    _storage.saveTasks(_tasks);
    notifyListeners();
  }

  // ── Settings ───────────────────────────────────────────────────────────────

  void updateSettings(AppSettings s) {
    _settings = s;
    _storage.saveSettings(s);
    notifyListeners();
  }

  // ── Break Timer ────────────────────────────────────────────────────────────

  void startBreak() {
    _isBreaking = true;
    _breakTimer = _settings.breakDuration * 60;
    _timer?.cancel();
    BlockerService.stopBlocking(); // unlock apps during break
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_breakTimer > 0) {
        _breakTimer--;
        notifyListeners();
      } else {
        _isBreaking = false;
        _timer?.cancel();
        _syncBlocker(); // re-engage blocking after break ends
        notifyListeners();
      }
    });
    notifyListeners();
  }

  void endBreak() {
    _isBreaking = false;
    _breakTimer = 0;
    _timer?.cancel();
    _syncBlocker();
    notifyListeners();
  }

  // ── Blocking helpers ───────────────────────────────────────────────────────

  List<Task> blockingTasksFor(String app) =>
      _tasks.where((t) => !t.isCompleted && t.blockedApps.contains(app)).toList();

  bool isAppBlocked(String app) =>
      !_isBreaking && blockingTasksFor(app).isNotEmpty;

  void clearPendingBlockedApp() {
    pendingBlockedApp = null;
    notifyListeners();
  }

  void _syncBlocker() {
    if (kIsWeb) return; // no-op on web
    final apps = activeBlockedApps;
    if (apps.isEmpty || _isBreaking) {
      BlockerService.stopBlocking();
    } else {
      BlockerService.startBlocking(apps);
    }
  }

  // ── Reset ──────────────────────────────────────────────────────────────────

  Future<void> resetAll() async {
    _timer?.cancel();
    BlockerService.stopBlocking();
    _tasks = [];
    _settings = const AppSettings();
    _isBreaking = false;
    _breakTimer = 0;
    pendingBlockedApp = null;
    await _storage.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
