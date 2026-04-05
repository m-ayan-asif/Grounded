const List<String> kBlockedApps = [
  'Instagram',
  'TikTok',
  'YouTube',
  'WhatsApp',
  'Reddit',
];

const Map<String, String> kAppEmojis = {
  'Instagram': '📸',
  'TikTok': '🎵',
  'YouTube': '📺',
  'WhatsApp': '💬',
  'Reddit': '🤖',
};

class SubTask {
  final String id;
  final String title;
  final String estimatedTime;
  final bool isCompleted;

  const SubTask({
    required this.id,
    required this.title,
    required this.estimatedTime,
    this.isCompleted = false,
  });

  SubTask copyWith({bool? isCompleted}) => SubTask(
        id: id,
        title: title,
        estimatedTime: estimatedTime,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'estimatedTime': estimatedTime,
        'isCompleted': isCompleted,
      };

  factory SubTask.fromJson(Map<String, dynamic> j) => SubTask(
        id: j['id'] as String,
        title: j['title'] as String,
        estimatedTime: j['estimatedTime'] as String,
        isCompleted: (j['isCompleted'] as bool?) ?? false,
      );
}

class Task {
  final String id;
  final String title;
  final String? description;
  final List<String> blockedApps;
  final bool isCompleted;
  final int createdAt;
  final List<SubTask> subTasks;

  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.blockedApps,
    this.isCompleted = false,
    required this.createdAt,
    this.subTasks = const [],
  });

  Task copyWith({
    String? title,
    String? description,
    List<String>? blockedApps,
    bool? isCompleted,
    List<SubTask>? subTasks,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        blockedApps: blockedApps ?? this.blockedApps,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt,
        subTasks: subTasks ?? this.subTasks,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'blockedApps': blockedApps,
        'isCompleted': isCompleted,
        'createdAt': createdAt,
        'subTasks': subTasks.map((s) => s.toJson()).toList(),
      };

  factory Task.fromJson(Map<String, dynamic> j) => Task(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        blockedApps: List<String>.from(j['blockedApps'] as List? ?? []),
        isCompleted: (j['isCompleted'] as bool?) ?? false,
        createdAt: (j['createdAt'] as int?) ?? 0,
        subTasks: ((j['subTasks'] as List?) ?? [])
            .map((s) => SubTask.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

class AppSettings {
  final bool isBreaksEnabled;
  final int breakDuration;
  final bool hasCompletedOnboarding;
  final bool isDarkMode;
  /// Full base URL of the Node backend, e.g. http://192.168.1.5:3000
  final String backendUrl;

  const AppSettings({
    this.isBreaksEnabled = true,
    this.breakDuration = 15,
    this.hasCompletedOnboarding = false,
    this.isDarkMode = false,
    this.backendUrl = 'http://192.168.18.82:3000',
  });

  AppSettings copyWith({
    bool? isBreaksEnabled,
    int? breakDuration,
    bool? hasCompletedOnboarding,
    bool? isDarkMode,
    String? backendUrl,
  }) =>
      AppSettings(
        isBreaksEnabled: isBreaksEnabled ?? this.isBreaksEnabled,
        breakDuration: breakDuration ?? this.breakDuration,
        hasCompletedOnboarding:
            hasCompletedOnboarding ?? this.hasCompletedOnboarding,
        isDarkMode: isDarkMode ?? this.isDarkMode,
        backendUrl: backendUrl ?? this.backendUrl,
      );

  Map<String, dynamic> toJson() => {
        'isBreaksEnabled': isBreaksEnabled,
        'breakDuration': breakDuration,
        'hasCompletedOnboarding': hasCompletedOnboarding,
        'isDarkMode': isDarkMode,
        'backendUrl': backendUrl,
      };

  factory AppSettings.fromJson(Map<String, dynamic> j) => AppSettings(
        isBreaksEnabled: (j['isBreaksEnabled'] as bool?) ?? true,
        breakDuration: (j['breakDuration'] as int?) ?? 15,
        hasCompletedOnboarding:
            (j['hasCompletedOnboarding'] as bool?) ?? false,
        isDarkMode: (j['isDarkMode'] as bool?) ?? false,
        backendUrl:
            (j['backendUrl'] as String?) ?? 'http://192.168.1.100:3000',
      );
}
