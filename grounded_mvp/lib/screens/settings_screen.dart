import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';
import '../services/ai_service.dart';
import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlCtrl;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(
        text: context.read<AppState>().settings.backendUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final state = context.read<AppState>();
    state.updateSettings(
        state.settings.copyWith(backendUrl: _urlCtrl.text.trim()));
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Settings saved.'),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ));
  }

  Future<void> _testConnection() async {
    _save(); // persist first so the test uses the entered value
    setState(() {
      _isTesting = true;
      _testResult = null;
    });
    try {
      final msg = await AIService.testConnection(_urlCtrl.text.trim());
      setState(() {
        _testSuccess = true;
        _testResult = msg;
      });
    } catch (e) {
      setState(() {
        _testSuccess = false;
        _testResult = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isTesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.settings;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ──────────────────────────────────────────────────
              Row(children: [
                Material(
                  color: isDark ? AppColors.charcoalLight : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.chevron_left_rounded, size: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Text('Settings',
                    style: TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 32),

              // ── Appearance ───────────────────────────────────────────────
              _Card(isDark: isDark, children: [
                _Toggle(
                  title: 'Dark Mode',
                  subtitle: 'Switch between light and dark',
                  value: s.isDarkMode,
                  onChanged: (v) =>
                      state.updateSettings(s.copyWith(isDarkMode: v)),
                ),
              ]),
              const SizedBox(height: 16),

              // ── Breaks ───────────────────────────────────────────────────
              _Card(isDark: isDark, children: [
                _Toggle(
                  title: 'Enable Breaks',
                  subtitle: 'Allow temporary app unlocks',
                  value: s.isBreaksEnabled,
                  onChanged: (v) =>
                      state.updateSettings(s.copyWith(isBreaksEnabled: v)),
                ),
                if (s.isBreaksEnabled) ...[
                  _Divider(isDark),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Break Duration',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      _Pill('${s.breakDuration}m'),
                    ],
                  ),
                  Slider(
                    value: s.breakDuration.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    activeColor: AppColors.lavender,
                    onChanged: (v) => state.updateSettings(
                        s.copyWith(breakDuration: v.round())),
                  ),
                ],
              ]),
              const SizedBox(height: 16),

              // ── Backend Server ───────────────────────────────────────────
              _Card(isDark: isDark, children: [
                const Text('AI Backend Server',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                const Text(
                  'Your Node.js + Ollama server URL.\n'
                  'Use your PC\'s LAN IP — not localhost.',
                  style: TextStyle(
                      color: AppColors.slate500, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlCtrl,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'http://192.168.18.82:3000',
                    hintStyle: const TextStyle(
                        color: AppColors.slate400, fontSize: 14),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.charcoal.withOpacity(0.6)
                        : AppColors.slate100,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                            color: AppColors.lavender, width: 1.5)),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          size: 18, color: AppColors.slate400),
                      onPressed: () => _urlCtrl.clear(),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Quick-help hint
                const Text(
                  'Find your IP: run  ipconfig  (Windows) or  ifconfig  (Mac/Linux)',
                  style: TextStyle(
                      color: AppColors.slate400,
                      fontSize: 11,
                      fontStyle: FontStyle.italic),
                ),
              ]),
              const SizedBox(height: 12),

              // ── Save + Test buttons ──────────────────────────────────────
              Row(children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lavender,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Save',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isTesting ? null : _testConnection,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.lavender,
                      side: const BorderSide(color: AppColors.lavender),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isTesting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.lavender))
                        : const Text('Test Connection',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ]),

              // ── Test result box ──────────────────────────────────────────
              if (_testResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _testSuccess
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: _testSuccess
                            ? Colors.green.shade200
                            : Colors.red.shade200),
                  ),
                  child: Text(
                    _testResult!,
                    style: TextStyle(
                      color: _testSuccess
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // ── Firewall help ────────────────────────────────────────────
              _Card(isDark: isDark, children: [
                const Text('Setup Guide',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                _Step('1',
                    'Start your server:\n node server.js'),
                _Step('2',
                    'Find your PC\'s IP:\n ipconfig → IPv4 Address'),
                _Step('3',
                    'Enter it above:\n http://192.168.x.x:3000'),
                _Step('4',
                    'Phone and PC must be on the same WiFi'),
                _Step('5',
                    'If Test still fails, allow port 3000 through Windows Firewall:\n'
                    ' netsh advfirewall firewall add rule name="Node 3000" dir=in action=allow protocol=TCP localport=3000'),
              ]),
              const SizedBox(height: 16),

              // ── About ─────────────────────────────────────────────────────
              _Card(isDark: isDark, children: [
                const Text('About Grounded',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                const Text(
                  'Deep work, powered by your own AI. App blocking keeps you focused; Ollama keeps your data private.',
                  style: TextStyle(
                      color: AppColors.slate500, fontSize: 13, height: 1.6),
                ),
                _Divider(isDark),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('VERSION 1.0.0',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate400,
                            letterSpacing: 0.8)),
                    Text('PRIVACY FIRST',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.slate400,
                            letterSpacing: 0.8)),
                  ],
                ),
              ]),
              const SizedBox(height: 24),

              // ── Reset ─────────────────────────────────────────────────────
              Center(
                child: TextButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Reset All Data?'),
                        content: const Text(
                            'Deletes all tasks and settings permanently.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Reset',
                                  style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await context.read<AppState>().resetAll();
                      if (context.mounted) Navigator.pop(context);
                    }
                  },
                  child: const Text('Reset All Data',
                      style: TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Small reusable widgets ──────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  const _Card({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.charcoalLight : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isDark
                  ? Colors.grey.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.1)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children),
      );
}

class _Toggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _Toggle(
      {required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.slate500, fontSize: 12)),
              ]),
        ),
        Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.lavender),
      ]);
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider(this.isDark);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Divider(
            height: 1,
            color: isDark
                ? Colors.grey.withOpacity(0.15)
                : Colors.grey.withOpacity(0.1)),
      );
}

class _Pill extends StatelessWidget {
  final String text;
  const _Pill(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.lavender.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: const TextStyle(
                color: AppColors.lavender,
                fontWeight: FontWeight.bold)));
}

class _Step extends StatelessWidget {
  final String number;
  final String text;
  const _Step(this.number, this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.lavender.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(number,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.lavender)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.slate500,
                      height: 1.5)),
            ),
          ],
        ),
      );
}
