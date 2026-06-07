// lib/widgets/settings_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pomodoro/services/api_key_service.dart';
import 'package:flutter_pomodoro/services/quiz_storage_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_pomodoro/providers/user.dart';

class SettingsDialog {
  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const _SettingsDialogContent(),
    );
  }
}

class _SettingsDialogContent extends StatefulWidget {
  const _SettingsDialogContent();

  @override
  State<_SettingsDialogContent> createState() => _SettingsDialogContentState();
}

class _SettingsDialogContentState extends State<_SettingsDialogContent> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final settings = QuizStorageService();
  String _selectedDifficulty = 'medium';
  String _selectedTimer = '25:5';

  final Map<String, String> _difficultyDescriptions = {
    'easy': 'Focuses on facts and definitions',
    'medium': 'Balanced understanding and application',
    'hard': 'Deep analysis and critical thinking',
    'mixed': '3 Easy • 4 Medium • 3 Hard',
  };

  final List<String> _timerPresets = [
    '25:5',
    '30:7',
    '45:10',
  ];

  bool _obscure = true;
  bool _loading = true;
  bool _saving = false;
  bool _saved = false;
  bool _hasExistingKey = false;

  static const _aiStudioUrl = 'https://aistudio.google.com/api-keys';
  

  @override
  void initState() {
    super.initState();
    _loadExistingKey();
  }

  Future<void> _loadExistingKey() async {
    final existing = await ApiKeyService.getApiKey();
    final savedDifficulty = settings.loadDifficulty();
    final savedTimer = settings.loadPomodoroPreset();

    setState(() {
      _hasExistingKey = existing != null && existing.isNotEmpty;
      if (_hasExistingKey) {
        _controller.text = existing!;
      }

      _selectedDifficulty = savedDifficulty;
      _selectedTimer = savedTimer;
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final user = FirebaseAuth.instance.currentUser!;

    await MyUser.pushApiKeyToFirestore(user.uid, _controller.text.trim());

    setState(() {
      _saving = false;
      _saved = true;
      _hasExistingKey = true;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteKey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove API key?'),
        content: const Text(
          'You will need to re-enter your key to generate quizzes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiKeyService.deleteApiKey();
      setState(() {
        _hasExistingKey = false;
        _controller.clear();
      });
    }
  }

  Future<void> _openAiStudio() async {
    final uri = Uri.parse(_aiStudioUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open browser')));
      }
    }
  }

  void _copyLink() {
    Clipboard.setData(const ClipboardData(text: _aiStudioUrl));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Link copied to clipboard')));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : Form(
                key: _formKey,
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    scrollbars: false,
                    overscroll: false,
                  ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with title and close button
                      Row(
                        children: [
                          const Icon(Icons.settings_rounded, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Settings',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),

                      Text(
                        'Quiz Difficulty',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 10),

                      ...['easy', 'medium', 'hard', 'mixed'].map(
                        (difficulty) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              setState(() {
                                _selectedDifficulty = difficulty;
                              });
                              settings.saveDifficulty(_selectedDifficulty);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _selectedDifficulty == difficulty
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                color: _selectedDifficulty == difficulty
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.08)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _selectedDifficulty == difficulty
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),

                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          difficulty[0].toUpperCase() +
                                              difficulty.substring(1),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        const SizedBox(height: 2),

                                        Text(
                                          _difficultyDescriptions[difficulty]!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 20),

                      Text(
                        'Pomodoro Timer',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),

                      const SizedBox(height: 10),

                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _timerPresets.map((preset) {
                          final selected = _selectedTimer == preset;

                          return ChoiceChip(
                            label: Text(preset),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                _selectedTimer = preset;
                              });
                              settings.savePomodoroPreset(_selectedTimer);
                            },
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 20),

                      Text(
                        'Gemini API Key',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Status
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: _hasExistingKey
                                  ? Colors.green[50]
                                  : Colors.orange[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _hasExistingKey
                                      ? Icons.check_circle_outline
                                      : Icons.warning_amber_rounded,
                                  size: 13,
                                  color: _hasExistingKey
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _hasExistingKey ? 'Key saved' : 'No key set',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _hasExistingKey
                                        ? Colors.green[700]
                                        : Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_hasExistingKey) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _deleteKey,
                              child: Text(
                                'Remove',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red[400],
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Input field for API key
                      TextFormField(
                        controller: _controller,
                        obscureText: _obscure,
                        style: const TextStyle(
                          fontSize: 13,
                          letterSpacing: 0.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'AIza...',
                          hintStyle: const TextStyle(letterSpacing: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 18,
                                ),
                                onPressed: () {
                                  setState(() => _obscure = !_obscure);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.paste),
                                onPressed: () async {
                                  final data = await Clipboard.getData(
                                    'text/plain',
                                  );
                                  if (data?.text != null) {
                                    _controller.text = data!.text!;
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your API key';
                          }
                          if (!RegExp(
                            r'^AIza[0-9A-Za-z\-_]{30,}$',
                          ).hasMatch(v.trim())) {
                            return 'Invalid Gemini API key format';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // API key Guide
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 15,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'How to get your free API key',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _Step(number: '1', text: 'Go to Google AI Studio'),
                            _Step(
                              number: '2',
                              text: 'Sign in with your Google account',
                            ),
                            _Step(number: '3', text: 'Click "Create API Key"'),
                            _Step(
                              number: '4',
                              text: 'Copy and paste the key here',
                            ),
                            const SizedBox(height: 10),

                            // Open AI Studio and Copy link
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _openAiStudio,
                                    icon: const Icon(
                                      Icons.open_in_new,
                                      size: 14,
                                    ),
                                    label: const Text(
                                      'Open AI Studio',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: _copyLink,
                                  icon: const Icon(Icons.copy, size: 14),
                                  label: const Text(
                                    'Copy link',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Save API key button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _saving ? null : _saveSettings,
                          style: FilledButton.styleFrom(
                            backgroundColor: _saved
                                ? Colors.green
                                : Theme.of(context).colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _saved
                                      ? '✓ Saved!'
                                      : _hasExistingKey
                                      ? 'Update Key'
                                      : 'Save Key',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Center(
                        child: Text(
                          '🔒 Stored securely with your account',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }
}

// Helper widget for the numbered steps in the API key guide section
class _Step extends StatelessWidget {
  final String number;
  final String text;

  const _Step({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.only(top: 1, right: 6),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: Colors.blue[900]),
            ),
          ),
        ],
      ),
    );
  }
}
