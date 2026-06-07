import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/leaderboard_page.dart';
import 'package:flutter_pomodoro/providers/avatar_utils.dart';
import 'package:flutter_pomodoro/services/quiz_storage_service.dart';
import 'package:flutter_pomodoro/widgets/layout.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String title = 'LEADERBOARD';
  late final String _weekLabel;
  late final Stream<QuerySnapshot> _leaderStream;

  // Compute the current week label based on PHT timezone (UTC+8)
  @override
  void initState() {
    super.initState();
    _weekLabel = QuizStorageService().currentWeekLabel; // computed once on init
    _leaderStream = FirebaseFirestore.instance
        .collection('leaderboard')
        .doc('weekly')
        .collection(_weekLabel)
        .orderBy('score', descending: true)
        .limit(50)
        .snapshots();
  }

// Position avatars based on rank and user ID to create a dynamic but consistent layout
  @override
  Widget build(BuildContext context) {
    final storage = QuizStorageService();
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? ''; 

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

          if (docs.isNotEmpty) {
            storage.cacheLeaderboard(
              docs
                  .map((d) => Map<String, dynamic>.from(d.data() as Map))
                  .toList(),
            );
          }

          final entries = docs.isNotEmpty
              ? docs.map((d) => LeaderboardEntry.fromFirestore(d.data() as Map<String, dynamic>, docs.indexOf(d) + 1, currentUid)).toList()
              : storage.getCachedLeaderboard()
                    .asMap().entries
                    .map((e) => LeaderboardEntry.fromFirestore(e.value, e.key + 1, currentUid))
                    .toList();

          if (entries.isEmpty && snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allUsers = docs.asMap().entries.map((entry) {
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

          final users = allUsers.where((u) => u.uid == currentUid).toList();

          if (users.isEmpty && currentUid.isNotEmpty) {
            final currentUser = FirebaseAuth.instance.currentUser;
            users.add(RankedAvatarData(
              uid: currentUid,
              rank: 51, // unranked — maps to base of triangle
              displayName: currentUser?.displayName ?? 'You',
              avatarPath: currentUser?.photoURL,
              score: 0,
            ));
          }

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

  // Normalize Y position based on rank (1 at top, 50 at bottom, 51+ just below)
  double get normalizedY {
    if (user.rank > 50) return 0.88;
    return ((user.rank - 1) / 49).clamp(0.02, 0.88);
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
              user.rank > 50 ? 'unranked' : '#${user.rank}',
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

