import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/widgets/layout.dart';
import 'package:flutter_pomodoro/widgets/my_card.dart';

class FriendsPage extends StatelessWidget {
  FriendsPage({super.key});

  final textController = TextEditingController();

  final String title = 'FIND FRIENDS';

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
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
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
                  return ListTile(
                    title: Card(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(index.toString()),
                        ),
                      ),
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
