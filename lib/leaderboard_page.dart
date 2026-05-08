import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/widgets/layout.dart';

class LeaderboardEntry {
  final int rank;
  final String displayName;
  final String username;
  final double score;
  final String? avatarUrl;

  const LeaderboardEntry({
    required this.rank,
    required this.displayName,
    required this.username,
    required this.score,
    this.avatarUrl,
  });
}

// Test leaderboard data
final List<LeaderboardEntry> _mockEntries = [
  LeaderboardEntry(rank: 1, displayName: 'Eiden',     username: '@eiden',    score: 2430),
  LeaderboardEntry(rank: 2, displayName: 'Jackson',   username: '@jackson',  score: 1847),
  LeaderboardEntry(rank: 3, displayName: 'Emma Aria', username: '@emmaaria', score: 1674),
  LeaderboardEntry(rank: 4, displayName: 'Sebastian', username: '@seb',      score: 1124),
  LeaderboardEntry(rank: 5, displayName: 'Jason',     username: '@jason',    score: 875),
  LeaderboardEntry(rank: 6, displayName: 'Natalie',   username: '@natalie',  score: 774),
  LeaderboardEntry(rank: 7, displayName: 'Serenity',  username: '@serenity', score: 723),
  LeaderboardEntry(rank: 8, displayName: 'Hannah',    username: '@hannah',   score: 559),
  LeaderboardEntry(rank: 9, displayName: 'Marcus',    username: '@marcus',   score: 487),
  LeaderboardEntry(rank: 10, displayName: 'Yuki',     username: '@yuki',     score: 412),
];

const Color _gold   = Color(0xFFFFC107);
const Color _silver = Color(0xFFB0BEC5);
const Color _bronze = Color(0xFFBF8970);

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final top3 = _mockEntries.take(3).toList();
    final rest = _mockEntries.skip(3).toList();

    final podiumOrder = [top3[1], top3[0], top3[2]];

    return MyLayout(
      title: 'LEADERBOARD',
      hideBottomNav: true,
      hideSideNav: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: podiumOrder.map((entry) {
                return Expanded(
                  child: _PodiumCard(entry: entry),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Divider
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.all(
                  Radius.circular(20)
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
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: rest.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 72,
                    endIndent: 16,
                    color: Colors.grey.withOpacity(0.2),
                  ),
                  itemBuilder: (context, index) {
                    return _RankRow(entry: rest[index]);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  final LeaderboardEntry entry;

  const _PodiumCard({required this.entry});

  Color get _medalColor {
    if (entry.rank == 1) return _gold;
    if (entry.rank == 2) return _silver;
    return _bronze;
  }

  double get _podiumHeight {
    if (entry.rank == 1) return 0; 
    if (entry.rank == 2) return 28;
    return 40;
  }

  double get _avatarSize {
    if (entry.rank == 1) return 72;
    return 58;
  }

  // Top 3 podium card with avatar, name, score, and rank badge
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: _podiumHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (entry.rank == 1)
            const Text('👑', style: TextStyle(fontSize: 22)),

          // Circular avatar with colored border and shadow
          Container(
            width: _avatarSize + 6,
            height: _avatarSize + 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _medalColor, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _medalColor.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ClipOval(
              child: entry.avatarUrl != null
                  ? Image.network(
                      entry.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _InitialAvatar(entry: entry, color: _medalColor),
                    )
                  : _InitialAvatar(entry: entry, color: _medalColor),
            ),
          ),

          Transform.translate(
            offset: const Offset(0, -10),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _medalColor,
                shape: BoxShape.circle,
                boxShadow: [
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

          // Display name
          Text(
            entry.displayName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),

          // Score
          Text(
            entry.score.toStringAsFixed(0),
            style: TextStyle(
              fontSize: entry.rank == 1 ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: _medalColor,
            ),
          ),

          // Username
          Text(
            entry.username,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  final LeaderboardEntry entry;

  const _RankRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Rank number
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

          // Circular avatar
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: ClipOval(
              child: entry.avatarUrl != null
                  ? Image.network(
                      entry.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _InitialAvatar(entry: entry),
                    )
                  : _InitialAvatar(entry: entry),
            ),
          ),

          const SizedBox(width: 12),

          // Username takes remaining space
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry.username,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Score right aligned
          Text(
            entry.score.toStringAsFixed(0),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Initials  avatar
class _InitialAvatar extends StatelessWidget {
  final LeaderboardEntry entry;
  final Color? color;

  const _InitialAvatar({required this.entry, this.color});

  String get _initials {
    final parts = entry.displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return entry.displayName.isNotEmpty ? entry.displayName[0].toUpperCase() : '?';
  }

  Color get _bg => color ?? Colors.blueGrey;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg.withOpacity(0.2),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _bg,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}