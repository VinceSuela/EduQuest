import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/widgets/my_dialog.dart';

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
                  onPressed: () => {showAbout(context)},
                  icon: Icon(Icons.settings, size: 36),
                ),
                IconButton(
                  onPressed: () => {showAbout(context)},
                  icon: Icon(Icons.question_mark, size: 36),
                ),
                IconButton(
                  onPressed: () => {Navigator.pushNamed(context, '/friends')},
                  icon: Icon(Icons.people, size: 36),
                ),
                IconButton(
                  onPressed: () => {Navigator.pushNamed(context, '/profile')},
                  icon: Icon(Icons.person, size: 36),
                ),
              ],
            ),
          )
        : SizedBox();
  }

  Future<String?> showAbout(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => MyDialog(
        title: 'About EduQuest',
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
