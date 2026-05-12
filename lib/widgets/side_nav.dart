import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/widgets/my_dialog.dart';
import 'package:flutter_pomodoro/widgets/settings_dialog.dart';

class SideNav extends StatelessWidget {
  final bool hideSideNav;
  const SideNav({super.key, required this.hideSideNav});

  @override
  Widget build(BuildContext context) {
    return !hideSideNav
        ? Container(
            padding: .symmetric(horizontal: 2),
            height: 250,
            child: Column(
              mainAxisAlignment: .spaceEvenly,
              children: [
                IconButton(
                  onPressed: () => {SettingsDialog.show(context)},
                  icon: Icon(Icons.settings, size: 36),
                ),
                IconButton(
                  onPressed: () => {showAbout(context)},
                  icon: Icon(Icons.question_mark, size: 36),
                ),
                // IconButton(
                //   onPressed: () => {Navigator.pushNamed(context, '/friends')},
                //   icon: Icon(Icons.people, size: 36),
                // ),
                IconButton(
                  onPressed: () => {Navigator.pushNamed(context, '/profile')},
                  icon: Icon(Icons.person, size: 36),
                ),
                IconButton(
                  onPressed: () => {
                    Navigator.pushNamed(context, '/leaderboard'),
                  },
                  icon: Icon(Icons.leaderboard, size: 36),
                ),
              ],
            ),
          )
        : SizedBox();
  }

  Future<String?> showAbout(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 42,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'About EduQuest',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),

                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EduQuest is designed to make studying feel less like a task and more like a guided learning journey. Built with students in mind, the app combines smart technology with practical study strategies to help users learn more efficiently, stay consistent, and feel more in control of their academic progress.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'By transforming learning materials into interactive quiz questions, EduQuest encourages active recall rather than passive rereading. This helps strengthen understanding, improve memory retention, and identify topics that need more attention.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),

                        Text(
                          'To support focus and productivity, EduQuest also includes structured study sessions inspired by the Pomodoro technique, along with light gamified breaks that help students recharge without losing momentum.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 22),

                        Text(
                          'Core Features',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),

                        const _FeatureItem(
                          'AI-powered quiz generation from study materials',
                        ),
                        const _FeatureItem(
                          'Timed study sessions for better focus',
                        ),
                        const _FeatureItem(
                          'Gamified breaks for balanced learning',
                        ),
                        const _FeatureItem(
                          'Progress tracking to monitor improvement',
                        ),

                        const SizedBox(height: 22),

                        Text(
                          'Our Objective',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          'EduQuest aims to help students build effective study habits by combining technology, structure, and engagement in one platform. Rather than replacing traditional learning, it enhances it—helping students study smarter, stay motivated, and make better use of their time.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> showSettings(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => MyDialog(
        title: 'Settings',
        child: Center(
          child: Text(
            'Content here',
            key: const Key('counterState'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;

  const _FeatureItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
