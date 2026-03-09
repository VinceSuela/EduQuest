import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/providers/counter.dart';
import 'package:flutter_pomodoro/widgets/layout.dart';
import 'package:flutter_pomodoro/widgets/my_button.dart';
import 'package:flutter_pomodoro/widgets/my_card.dart';
import 'package:flutter_pomodoro/widgets/my_dialog.dart';
import 'package:provider/provider.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  final String title = 'LEADERBOARD';

  String getCount(BuildContext context) {
    return Provider.of<MyCounter>(context).count.toString();
  }

  void increase(BuildContext context) {
    return Provider.of<MyCounter>(context, listen: false).increment();
  }

  @override
  Widget build(BuildContext context) {
    return MyLayout(
      title: title,
      hideBottomNav: false,
      child: MyCard(
        child: ListView(
          children: [
            Center(
              child: Text(
                getCount(context),
                key: const Key('counterState'),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            MyButton(
              label: 'Sample answer here.',
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              isActive: false,
            ),

            MyButton(
              label: 'Sample answer here.',
              onPressed: () {
                increase(context);
              },
              isActive: true,
            ),
            MyButton(
              label: 'Sample answer here.',
              onPressed: () => showMyDialog(context),
              isActive: false,
            ),
            MyButton(
              label: 'Sample answer here.',
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushNamed(context, '/login');
              },
              isActive: false,
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> showMyDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => MyDialog(
        title: 'About EduQuest',
        child: Consumer<MyCounter>(
          builder: (context, myCounter, child) {
            return Text(
              myCounter.count.toString(),
              key: const Key('counterState'),
              style: Theme.of(context).textTheme.headlineMedium,
            );
          },
        ),
      ),
    );
  }
}
