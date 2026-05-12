import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/providers/avatar_utils.dart';
import 'package:flutter_pomodoro/services/quiz_storage_service.dart';
import 'package:flutter_pomodoro/widgets/layout.dart';

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  final String title = 'LEADERBOARD';

// Position avatars based on rank and user ID to create a dynamic but consistent layout
  @override
  Widget build(BuildContext context) {
    final storage = QuizStorageService();

    return MyLayout(
      title: title,
      hideBottomNav: false,
      hideSideNav: false,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('leaderboard')
            .doc('weekly')
            .collection(storage.currentWeekLabel)
            .orderBy('score', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          final users = docs.asMap().entries.map((entry) {
            final index = entry.key;
            final data = entry.value.data() as Map<String, dynamic>;

            return RankedAvatarData(
              uid: data['uid'] ?? '',
              rank: index + 1,
              displayName: data['displayName'] ?? 'Student',
              avatarPath: data['photoURL'],
              score: (data['score'] as num?)?.toDouble() ?? 0,
            );
          }).toList();

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 265 * 1.1,
                height: 663 * 0.75,
                child: Stack(
                  children: [
                    /// Triangle
                    Positioned.fill(
                      child: CustomPaint(
                        painter: TrianglePainter(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.15),
                        ),
                      ),
                    ),

                    /// Avatars
                    ...users.map(
                      (user) => _RankedAvatar(
                        user: user,
                        triangleWidth: 265 * 1.1,
                        triangleHeight: 663 * 0.75,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class RankedAvatarData {
  final String uid;
  final int rank;
  final String displayName;
  final String? avatarPath;
  final double score;

  RankedAvatarData({
    required this.uid,
    required this.rank,
    required this.displayName,
    required this.avatarPath,
    required this.score,
  });
}

/// Helper to determine border color based on rank
class _RankedAvatar extends StatelessWidget {
  final RankedAvatarData user;
  final double triangleWidth;
  final double triangleHeight;

  const _RankedAvatar({
    required this.user,
    required this.triangleWidth,
    required this.triangleHeight,
  });

  double get normalizedY {
    return ((user.rank - 1) / 49).clamp(0.02, 0.95);
  }

  @override
  Widget build(BuildContext context) {
    final random = Random(user.uid.hashCode);

    final y = normalizedY;

    // Triangle narrows upward
    final availableWidth = triangleWidth * y;

    final startX = (triangleWidth - availableWidth) / 2;

    final x = startX + (random.nextDouble() * availableWidth);

    final top = y * triangleHeight;

    final avatarSize = user.rank == 1
        ? 62.0
        : user.rank <= 3
            ? 54.0
            : 42.0;

    return Positioned(
      left: x,
      top: top,
      child: Column(
        children: [
          if (user.rank == 1)
            const Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Text(
                '👑',
                style: TextStyle(fontSize: 18),
              ),
            ),

          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AvatarWidget(
              displayName: user.displayName,
              avatarAssetPath: user.avatarPath,
              size: avatarSize,
              borderColor: _rankColor(user.rank),
              borderWidth: user.rank <= 3 ? 3 : 2,
            ),
          ),

          const SizedBox(height: 4),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '#${user.rank}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper to determine border color based on rank
Color _rankColor(int rank) {
  if (rank == 1) {
    return const Color(0xFFFFC107);
  }

  if (rank == 2) {
    return const Color(0xFFB0BEC5);
  }

  if (rank == 3) {
    return const Color(0xFFBF8970);
  }

  return Colors.white;
}

/// Custom painter for the leaderboard triangle background
class TrianglePainter extends CustomPainter {
  final Color color;

  TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    const LinearGradient gradient = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [Color(0xFFFEE533), Color(0xFF47B9FF), Color(0xFF2A37FF)],
      stops: [0.0, 0.90, 1.0],
    );

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..shader = gradient.createShader(rect);

    final linePaint = Paint()..color = Colors.white;

    final path = Path();
    path.moveTo((size.width / 2) - 5, 10);
    path.quadraticBezierTo(size.width / 2, 0, (size.width / 2) + 5, 10);
    path.lineTo(size.width, size.height - 10);
    path.quadraticBezierTo(
      size.width,
      size.height,
      size.width - 10,
      size.height,
    );
    path.lineTo(10, size.height);
    path.quadraticBezierTo(0, size.height, 0, size.height - 10);
    path.close();

    canvas.drawPath(path, paint);
    canvas.clipPath(path);
    canvas.drawShadow(path, const Color.fromARGB(100, 0, 0, 0), 2, true);

    // Add horizontal lines for visual interest
    canvas.drawLine(Offset((size.width / 2), 40), Offset(0, 40), linePaint);
    canvas.drawLine(Offset((size.width / 2), 40 * 2), Offset(0, 40 * 2), linePaint);
    canvas.drawLine(Offset((size.width / 2), 40 * 3), Offset(0, 40 * 3), linePaint);
    canvas.drawLine(Offset((size.width / 2), 40 * 4.3), Offset(0, 40 * 4.3), linePaint);
    canvas.drawLine(Offset((size.width / 2), 40 * 5.8), Offset(0, 40 * 5.8), linePaint);
    canvas.drawLine(Offset((size.width / 2), 40 * 7.7), Offset(0, 40 * 7.7), linePaint);
    canvas.drawLine(Offset((size.width / 2), 40 * 10), Offset(0, 40 * 10), linePaint);
  }

  @override
  bool shouldRepaint(covariant TrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_pomodoro/providers/counter.dart';
// import 'package:flutter_pomodoro/widgets/layout.dart';
// import 'package:flutter_pomodoro/widgets/my_button.dart';
// import 'package:flutter_pomodoro/widgets/my_card.dart';
// import 'package:flutter_pomodoro/widgets/my_dialog.dart';
// import 'package:flutter_pomodoro/widgets/paint.dart';
// import 'package:provider/provider.dart';

// class MyHomePage extends StatelessWidget {
//   const MyHomePage({super.key});

//   final String title = 'LEADERBOARD';

//   // String getCount(BuildContext context) {
//   //   return Provider.of<MyCounter>(context).count.toString();
//   // }

//   // void increase(BuildContext context) {
//   //   return Provider.of<MyCounter>(context, listen: false).increment();
//   // }

  // @override
  // Widget build(BuildContext context) {
  //   return MyLayout(
  //     title: title,
  //     hideBottomNav: false,
  //     child: Container(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Column(
  //         children: [
  //           CustomPaint(
  //             painter: TrianglePainter(color: Colors.blue),
  //             child: SizedBox(height: 663 * 0.7, width: 265 * 0.7),
  //           )
  //         ],
  //       ),
  //     ),
  //   );
  // }


//   // MyCard newMethod(BuildContext context) {
//   //   return MyCard(
//   //     child: ListView(
//   //       children: [
//   //         Center(
//   //           child: Text(
//   //             getCount(context),
//   //             key: const Key('counterState'),
//   //             style: Theme.of(context).textTheme.headlineMedium,
//   //           ),
//   //         ),
//   //         MyButton(
//   //           label: 'Sample answer here.',
//   //           onPressed: () {
//   //             Navigator.pushNamed(context, '/profile');
//   //           },
//   //           isActive: false,
//   //         ),

//   //         MyButton(
//   //           label: '++',
//   //           onPressed: () {
//   //             increase(context);
//   //           },
//   //           isActive: true,
//   //         ),
//   //         MyButton(
//   //           label: 'alert',
//   //           onPressed: () => showMyDialog(context),
//   //           isActive: false,
//   //         ),
//   //         MyButton(
//   //           label: 'Logout',
//   //           onPressed: () {
//   //             FirebaseAuth.instance.signOut();
//   //             Navigator.pushNamed(context, '/login');
//   //           },
//   //           isActive: false,
//   //         ),
//   //         MyButton(
//   //           label: 'Flappy Bird',
//   //           onPressed: () {
//   //             Navigator.pushNamed(context, '/flappy');
//   //           },
//   //           isActive: false,
//   //         ),
//   //         MyButton(
//   //           label: 'Snake',
//   //           onPressed: () {
//   //             Navigator.pushNamed(context, '/snake');
//   //           },
//   //           isActive: false,
//   //         ),
//   //         MyButton(
//   //           label: 'Trex',
//   //           onPressed: () {
//   //             Navigator.pushNamed(context, '/trex');
//   //           },
//   //           isActive: false,
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }

//   // Future<String?> showMyDialog(BuildContext context) {
//   //   return showDialog<String>(
//   //     context: context,
//   //     builder: (BuildContext context) => MyDialog(
//   //       title: 'About EduQuest',
//   //       child: Consumer<MyCounter>(
//   //         builder: (context, myCounter, child) {
//   //           return Text(
//   //             myCounter.count.toString(),
//   //             key: const Key('counterState'),
//   //             style: Theme.of(context).textTheme.headlineMedium,
//   //           );
//   //         },
//   //       ),
//   //     ),
//   //   );
//   // }
// }

