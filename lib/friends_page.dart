import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/widgets/layout.dart';
import 'package:flutter_pomodoro/widgets/my_card.dart';
import 'package:unique_names_generator/unique_names_generator.dart';

class FriendsPage extends StatelessWidget {
  FriendsPage({super.key});

  final textController = TextEditingController();

  final String title = 'FIND FRIENDS';
  final generator = UniqueNamesGenerator(
    config: Config(
      length: 2,
      separator: ' ',
      dictionaries: [adjectives, animals],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MyLayout(
      title: title,
      hideBottomNav: true,
      hideSideNav: true,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          MyCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                style: TextStyle(fontSize: 20),
                controller: textController,
                decoration: InputDecoration(
                  border: .none,
                  hintText: 'ENTER USER NAME..',
                  suffixIcon: GestureDetector(
                    onTap: () {},
                    child: Icon(Icons.search),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: MyCard(
              child: ListView.builder(
                itemCount: 20,
                itemBuilder: (context, index) {
                  return Card(
                    child: Row(
                      children: [
                        Card(
                          color: Color(0xFF47B9FF),
                          child: FittedBox(
                            fit: .scaleDown,
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: Center(
                                child: Icon(Icons.person, size: 50),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            crossAxisAlignment: .start,
                            children: [
                              FittedBox(
                                fit: .scaleDown,
                                child: Text(
                                  generator.generate(),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              Text('Points'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
