import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/widgets/bottom_navigation.dart';
import 'package:flutter_pomodoro/widgets/header_logo.dart';
import 'package:flutter_pomodoro/widgets/side_nav.dart';
import 'package:flutter_pomodoro/widgets/title.dart';

class MyLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final bool? hideBottomNav;
  final bool? hideSideNav;
  final bool hideBackButton;

  const MyLayout({
    super.key,
    required this.title,
    required this.child,
    this.hideBottomNav = true,
    this.hideSideNav = false,
    this.hideBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Color(0xFF47B9FF)),
        child: Column(
          children: [
            HeaderLogo(),
            Expanded(
              child: Container(
                width: .infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('asset/images/bg.png'),
                    fit: .cover,
                    alignment: .topCenter,
                  ),
                ),
                child: Column(
                  children: [
                    MyTitle(title: title),
                    Expanded(
                      child: Stack(
                        children: [
                          SizedBox(
                            width: .infinity,
                            height: .infinity,
                            child: child,
                          ),
                          SideNav(hideSideNav: hideSideNav ?? false),
                        ],
                      ),
                    ),
                    BottomNavigation(
                      hideBottomNav: hideBottomNav ?? false,
                      hideBackButton: hideBackButton,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
