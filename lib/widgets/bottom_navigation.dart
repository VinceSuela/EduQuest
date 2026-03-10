import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final bool hideBottomNav;
  final bool hideBackButton;

  const BottomNavigation({
    super.key,
    required this.hideBottomNav,
    this.hideBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: !hideBottomNav ? 150 : 60,
      clipBehavior: .none,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/bottom-bar.png'),
          fit: .cover,
          alignment: .topCenter,
        ),
      ),
      child: !hideBottomNav ? renderButtons() : renderBackButton(context),
      //SizedBox(width: .infinity),
    );
  }

  Transform renderButtons() {
    return Transform.translate(
      offset: Offset(0, 0),
      child: Row(
        mainAxisAlignment: .spaceEvenly,
        crossAxisAlignment: .end,
        children: [
          Flexible(
            flex: 3,
            child: GestureDetector(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(
                  'assets/images/generate-button.png',
                  fit: .contain,
                ),
              ),
            ),
          ),
          Flexible(
            flex: 5,
            child: GestureDetector(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset('assets/images/start-button.png'),
              ),
            ),
          ),
          Flexible(
            flex: 3,
            child: GestureDetector(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset('assets/images/review-button.png'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget renderBackButton(BuildContext context) {
    return SizedBox(
      width: .infinity,
      child: Visibility(
        visible: !hideBackButton,
        child: TextButton(
          style: ButtonStyle(overlayColor: WidgetStateColor.transparent),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
          child: Text('Back', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
