import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/providers/avatar_utils.dart';
import 'dart:developer' as dev;
import 'package:flutter_pomodoro/services/quiz_storage_service.dart';
import 'package:flutter_pomodoro/widgets/layout.dart';

// Data model
class LeaderboardEntry {
  final int rank;
  final String uid;
  final String displayName;
  final String username;
  final double score;
  final String? avatarAssetPath;
  final double accuracyPercent;
  final int currentStreak;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.uid,
    required this.displayName,
    required this.username,
    required this.score,
    required this.accuracyPercent,
    required this.currentStreak,
    this.avatarAssetPath,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromFirestore(
    Map<String, dynamic> data,
    int rank,
    String currentUid,
  ) {
    final email = data['userEmail'] as String? ?? '';
    final username = email.contains('@')
        ? '@${email.split('@')[0]}'
        : '@unknown';

    return LeaderboardEntry(
      rank: rank,
      uid: data['uid'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'Student',
      username: username,
      score: (data['score'] as num?)?.toDouble() ?? 0.0,
      accuracyPercent: (data['accuracyPercent'] as num?)?.toDouble() ?? 0.0,
      currentStreak: (data['currentStreak'] as num?)?.toInt() ?? 0,
      avatarAssetPath: data['photoURL'] as String?,
      isCurrentUser: data['uid'] == currentUid,
    );
  }
}

const Color _gold = Color(0xFFFFC107);
const Color _silver = Color(0xFFB0BEC5);
const Color _bronze = Color(0xFFBF8970);

Color _medalColor(int rank) {
  if (rank == 1) return _gold;
  if (rank == 2) return _silver;
  if (rank == 3) return _bronze;
  return Colors.blueGrey;
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final _storageService = QuizStorageService();

  Stream<QuerySnapshot> get _weeklyStream {
    final weekLabel = _storageService.currentWeekLabel;
    dev.log('LeaderboardPage: querying week "$weekLabel"', name: 'Leaderboard');
    return FirebaseFirestore.instance
        .collection('leaderboard')
        .doc('weekly')
        .collection(weekLabel)
        .orderBy('score', descending: true)
        .limit(50)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return MyLayout(
      title: 'LEADERBOARD',
      hideBottomNav: true,
      hideSideNav: true,
      child: StreamBuilder<QuerySnapshot>(
        stream: _weeklyStream,
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error — log the REAL error, show helpful message
          if (snapshot.hasError) {
            final err = snapshot.error;
            dev.log(
              'Leaderboard Firestore error: $err',
              name: 'Leaderboard',
              error: err,
            );

            // Check for common Firestore index error
            final errStr = err.toString();
            final needsIndex =
                errStr.contains('index') ||
                errStr.contains('FAILED_PRECONDITION');

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[300], size: 48),
                    const SizedBox(height: 12),
                    Text(
                      needsIndex
                          ? 'Firestore index required'
                          : 'Could not load leaderboard',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      needsIndex
                          ? 'Check your debug console for a Firestore link to create the required index. '
                                'It only takes one click.'
                          : 'Check your connection and try again.\n\nError: $err',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _EmptyLeaderboard(storageService: _storageService);
          }

          final entries = docs.asMap().entries.map((e) {
            final data = e.value.data() as Map<String, dynamic>;
            return LeaderboardEntry.fromFirestore(data, e.key + 1, currentUid);
          }).toList();

          final top3 = entries.take(3).toList();
          final rest = entries.skip(3).toList();

          final podiumOrder = top3.length == 3
              ? [top3[1], top3[0], top3[2]]
              : top3;

          final myEntry = entries.firstWhere(
            (e) => e.isCurrentUser,
            orElse: () => LeaderboardEntry(
              rank: 0,
              uid: currentUid,
              displayName:
                  FirebaseAuth.instance.currentUser?.displayName ?? 'You',
              username: '@me',
              score: _storageService.computeLeaderboardScore(),
              accuracyPercent: 0,
              currentStreak: 0,
              isCurrentUser: true,
            ),
          );

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: podiumOrder
                      .map((e) => Expanded(child: _PodiumCard(entry: e)))
                      .toList(),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: rest.isEmpty
                        ? const Center(child: Text('Top 3 only this week!'))
                        : ListView.separated(
                            padding: const EdgeInsets.only(top: 8, bottom: 80),
                            itemCount: rest.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              indent: 72,
                              endIndent: 16,
                              color: Colors.grey.withOpacity(0.2),
                            ),
                            itemBuilder: (_, i) => _RankRow(entry: rest[i]),
                          ),
                  ),
                ),
              ),
              _MyRankFooter(entry: myEntry, storageService: _storageService),
            ],
          );
        },
      ),
    );
  }
}

// Podium
class _PodiumCard extends StatelessWidget {
  final LeaderboardEntry entry;
  const _PodiumCard({required this.entry});

  double get _bottomPad {
    if (entry.rank == 1) return 0;
    if (entry.rank == 2) return 28;
    return 44;
  }

  double get _avatarSize => entry.rank == 1 ? 72 : 56;

  @override
  Widget build(BuildContext context) {
    final medal = _medalColor(entry.rank);
    return Padding(
      padding: EdgeInsets.only(bottom: _bottomPad),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.rank == 1) const Text('👑', style: TextStyle(fontSize: 22)),
          AvatarWidget(
            displayName: entry.displayName,
            avatarAssetPath: entry.avatarAssetPath,
            size: _avatarSize,
            borderColor: medal,
            borderWidth: 3,
          ),
          Transform.translate(
            offset: const Offset(0, -10),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: medal,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: Center(
                child: Text(
                  '${entry.rank}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Text(
            entry.displayName,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            entry.score.toStringAsFixed(1),
            style: TextStyle(
              fontSize: entry.rank == 1 ? 20 : 15,
              fontWeight: FontWeight.bold,
              color: medal,
            ),
          ),
          Text(
            entry.username,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Rank row
class _RankRow extends StatelessWidget {
  final LeaderboardEntry entry;
  const _RankRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isMe = entry.isCurrentUser;
    return Container(
      color: isMe
          ? Theme.of(context).colorScheme.primary.withOpacity(0.07)
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${entry.rank}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          AvatarWidget(
            displayName: entry.displayName,
            avatarAssetPath: entry.avatarAssetPath,
            size: 42,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  entry.username,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            entry.score.toStringAsFixed(1),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isMe ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

// Sticky footer
class _MyRankFooter extends StatelessWidget {
  final LeaderboardEntry entry;
  final QuizStorageService storageService;
  const _MyRankFooter({required this.entry, required this.storageService});

  @override
  Widget build(BuildContext context) {
    final stats = storageService.loadLifetimeStats();
    final totalAnswered = stats[QuizStorageService.keyTotalAnswered] as int;
    final meetsThreshold = totalAnswered >= 70;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              entry.rank > 0 ? '#${entry.rank}' : '—',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          AvatarWidget(
            displayName: entry.displayName,
            avatarAssetPath: entry.avatarAssetPath,
            size: 42,
            borderColor: Theme.of(context).colorScheme.primary,
            borderWidth: 2,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                if (!meetsThreshold)
                  Text(
                    '${70 - totalAnswered} more questions to rank',
                    style: TextStyle(fontSize: 11, color: Colors.orange[700]),
                  ),
              ],
            ),
          ),
          meetsThreshold
              ? Text(
                  entry.score.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              : Tooltip(
                  message: 'Answer 70+ questions to appear on the leaderboard',
                  child: Icon(
                    Icons.lock_outline,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                ),
        ],
      ),
    );
  }
}

// Empty state
class _EmptyLeaderboard extends StatelessWidget {
  final QuizStorageService storageService;
  const _EmptyLeaderboard({required this.storageService});

  @override
  Widget build(BuildContext context) {
    final stats = storageService.loadLifetimeStats();
    final totalAnswered = stats[QuizStorageService.keyTotalAnswered] as int;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'No rankings yet this week',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              totalAnswered < 70
                  ? 'Answer ${70 - totalAnswered} more questions to be first on the board!'
                  : 'Complete a quiz session to push your score!',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
