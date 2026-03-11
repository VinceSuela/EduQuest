import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/widgets/my_button.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // backgroundColor: Colors.white,
      // isDrawerOpen: true, //Provider.of<MyPage>(context).isDrawerOpen,
      // alignment: .start,
      child: Column(
        children: [
          MyButton(
            label: 'Leaderboard',
            onPressed: () {
              Navigator.pushNamed(context, '/home');
            },
            isActive: true,
          ),
          MyButton(
            label: 'Friends',
            onPressed: () {
              Navigator.pushNamed(context, '/friends');
            },
            isActive: true,
          ),
          MyButton(
            label: 'About',
            onPressed: () {
              Navigator.pushNamed(context, '/about');
            },
            isActive: true,
          ),
          MyButton(
            label: 'Flappy Bird',
            onPressed: () {
              Navigator.pushNamed(context, '/flappy');
            },
            isActive: false,
          ),
          MyButton(
            label: 'Flappy Bird',
            onPressed: () {
              Navigator.pushNamed(context, '/flappy');
            },
            isActive: false,
          ),
          MyButton(
            label: 'Snake',
            onPressed: () {
              Navigator.pushNamed(context, '/snake');
            },
            isActive: false,
          ),
          MyButton(
            label: 'Trex',
            onPressed: () {
              Navigator.pushNamed(context, '/trex');
            },
            isActive: false,
          ),
          MyButton(
            label: 'Logout',
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
            isActive: false,
          ),
        ],
      ),
    );
  }
}
