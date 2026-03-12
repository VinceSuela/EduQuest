import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/providers/user.dart';
import 'package:flutter_pomodoro/widgets/layout.dart';
import 'package:flutter_pomodoro/widgets/my_button.dart';
import 'package:flutter_pomodoro/widgets/my_card.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final String title = 'PROFILE';

  final List<IconData> achievement = [
    Icons.leaderboard,
    Icons.star,
    Icons.score,
  ];

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    return MyLayout(
      title: title,
      hideBottomNav: true,
      hideSideNav: true,
      child: MyCard(
        child: ListView(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Card(
                  color: Color(0xFF47B9FF),
                  child: FittedBox(
                    fit: .scaleDown,
                    child: SizedBox(
                      width: 100,
                      height: 100,
                      child: Center(child: Icon(Icons.person, size: 90)),
                    ),
                  ),
                ),
              ),
            ),
            FittedBox(
              fit: .scaleDown,
              child: Center(
                child: Consumer<MyUser>(
                  builder: (context, myUser, child) {
                    return Text(
                      myUser.username,
                      style: Theme.of(context).textTheme.bodyLarge,
                    );
                  },
                ),
              ),
            ),
            Center(child: Text('POINTS')),
            FittedBox(
              fit: .scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'This player has not updated their status yet.',
                  textAlign: .center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            Expanded(
              child: Card(
                color: Color(0xFFD2EEFF),
                child: SizedBox(
                  height: 300,
                  child: Column(
                    children: [
                      Center(
                        child: Text(
                          'ACHIEVEMENTS',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: screenWidth ~/ 80,
                              ),
                          itemCount: achievement.length,
                          itemBuilder: (context, index) {
                            return Card(
                              child: Center(
                                child: FittedBox(
                                  child: Icon(achievement[index], size: 40),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Card(child: Center(child: Icon(Icons.leaderboard))),
            // Card(child: Center(child: Icon(Icons.star))),
            // MyButton(
            //   label: 'Leader Board',
            //   onPressed: () {
            //     if (Navigator.canPop(context)) {
            //       Navigator.pop(context);
            //     }
            //   },
            //   isActive: false,
            // ),
          ],
        ),
      ),
    );
  }
}
