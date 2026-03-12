import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
import 'package:flutter_pomodoro/widgets/bottom_navigation.dart';
import 'package:flutter_pomodoro/widgets/header_logo.dart';
import 'package:flutter_pomodoro/widgets/my_drawer.dart';
import 'package:flutter_pomodoro/widgets/side_nav.dart';
import 'package:flutter_pomodoro/widgets/title.dart';

class MyLayout extends StatefulWidget {
  final String title;
  final Widget child;
  final bool hideBottomNav;
  final bool hideSideNav;
  final bool hideBackButton;
  final bool noAuth;
  final bool hideHeader;

  const MyLayout({
    super.key,
    required this.title,
    required this.child,
    this.hideHeader = false,
    this.hideBottomNav = true,
    this.hideSideNav = false,
    this.hideBackButton = false,
    this.noAuth = false,
  });

  @override
  State<MyLayout> createState() => _MyLayoutState();
}

class _MyLayoutState extends State<MyLayout> {
  @override
  void initState() {
    bool isLoggedIn = FirebaseAuth.instance.currentUser?.email != null;
    if (widget.noAuth && !isLoggedIn) {
      Navigator.of(
        NavigationService.navigatorKey.currentContext!,
      ).pushReplacementNamed('/login');
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MyDrawer(),
      body: Container(
        decoration: BoxDecoration(color: Color(0xFF47B9FF)),
        child: Column(
          children: [
            Visibility(visible: !widget.hideHeader, child: HeaderLogo()),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 0),
                child: Container(
                  width: .infinity,
                  decoration: BoxDecoration(
                    borderRadius: !widget.hideHeader
                        ? BorderRadius.only(
                            topLeft: Radius.elliptical(500, 75),
                            topRight: Radius.elliptical(500, 75),
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(64, 0, 0, 0),
                        blurRadius: 5,
                        spreadRadius: 10,
                      ),
                    ],
                    // color: Colors.white,
                    image: DecorationImage(
                      image: AssetImage('assets/images/bigBG.png'),
                      fit: .cover,
                      alignment: .topCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      Visibility(
                        visible: !widget.hideHeader,
                        child: MyTitle(title: widget.title),
                      ),
                      // Expanded(child: widget.child),
                      Expanded(
                        child: Stack(
                          children: [
                            SizedBox(
                              width: .infinity,
                              height: .infinity,
                              child: widget.child,
                            ),
                            SideNav(hideSideNav: widget.hideSideNav),
                          ],
                        ),
                      ),
                      BottomNavigation(
                        hideBottomNav: widget.hideBottomNav,
                        hideBackButton: widget.hideBackButton,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
