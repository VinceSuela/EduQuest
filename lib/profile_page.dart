import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/providers/avatar_utils.dart';
import 'package:flutter_pomodoro/providers/user.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
import 'package:flutter_pomodoro/services/quiz_storage_service.dart';
import 'package:flutter_pomodoro/widgets/layout.dart';
import 'package:flutter_pomodoro/widgets/my_button.dart';
import 'package:flutter_pomodoro/widgets/my_card.dart';
import 'package:provider/provider.dart';

const List<String> _avatarAssets = [
  'assets/images/avatars/boy.png',
  'assets/images/avatars/boy1.png',
  'assets/images/avatars/boy2.png',
  'assets/images/avatars/boy3.png',
  'assets/images/avatars/boy4.png',
  'assets/images/avatars/boy5.png',
  'assets/images/avatars/boy6.png',
  'assets/images/avatars/boy7.png',
  'assets/images/avatars/boy8.png',
  'assets/images/avatars/boy9.png',
  'assets/images/avatars/girl.png',
  'assets/images/avatars/girl1.png',
  'assets/images/avatars/girl2.png',
  'assets/images/avatars/girl3.png',
  'assets/images/avatars/girl4.png',
  'assets/images/avatars/girl5.png',
  'assets/images/avatars/girl6.png',
  'assets/images/avatars/girl7.png',
  'assets/images/avatars/girl8.png',
  'assets/images/avatars/girl9.png',
  'assets/images/avatars/girl10.png',
  'assets/images/avatars/girl11.png',
  'assets/images/avatars/girl12.png',
  'assets/images/avatars/girl13.png',
  'assets/images/avatars/avatar.png',
  'assets/images/avatars/man.png',
  'assets/images/avatars/bear.png',
  'assets/images/avatars/bee.png',
  'assets/images/avatars/dog.png',
  'assets/images/avatars/turtle.png',
  'assets/images/avatars/happy.png',
  'assets/images/avatars/frog.png',
  'assets/images/avatars/virgo.png',
  'assets/images/avatars/young-boy.png',
  'assets/images/avatars/student.png',
  'assets/images/avatars/student1.png',
  'assets/images/avatars/koala.png',
  'assets/images/avatars/lion.png',
];

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Edit display name
  Future<void> _editDisplayName(BuildContext context, MyUser myUser) async {
    final controller = TextEditingController(text: myUser.username);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Your name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Update Firebase Auth profile AND Firestore so both stay in sync
      await user.updateDisplayName(result);
      await _firestoreUpdateField(user.uid, 'displayName', result);
      await myUser.setUser(); // refresh provider from Firestore  
      await QuizStorageService().pushWeeklyStatsToFirestore();
      setState(() {});
    }
  }

  // Avatar picker
  Future<void> _pickAvatar(BuildContext context, MyUser myUser) async {
    final currentPhoto = FirebaseAuth.instance.currentUser?.photoURL;
    String? selectedAvatar = currentPhoto;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person_rounded,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 14),
                    Text('Choose Avatar',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),

                // Grid
                SizedBox(
                  height: 380,
                  child: GridView.builder(
                    itemCount: _avatarAssets.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemBuilder: (context, index) {
                      final path = _avatarAssets[index];
                      final isSelected = selectedAvatar == path;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedAvatar = path),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary.withOpacity(0.25)
                                    : Colors.black.withOpacity(0.08),
                                blurRadius: isSelected ? 14 : 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(path, fit: BoxFit.cover),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: isSelected ? 1 : 0,
                                  child: Container(
                                    color: Colors.black.withOpacity(0.28),
                                    child: const Center(
                                      child: Icon(Icons.check_circle_rounded,
                                          color: Colors.white, size: 30),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 28),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: selectedAvatar == null
                            ? null
                            : () async {
                                final user = FirebaseAuth.instance.currentUser;
                                if (user == null) return;
                                await user.updatePhotoURL(selectedAvatar);
                                await _firestoreUpdateField(
                                    user.uid, 'photoURL', selectedAvatar!);
                                await myUser.setUser();
                                await QuizStorageService().pushWeeklyStatsToFirestore();
                                if (context.mounted) {
                                  setState(() {});
                                  Navigator.pop(dialogContext);
                                }
                              },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _firestoreUpdateField(
      String uid, String field, String value) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({field: value});
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MyUser>(
      builder: (context, myUser, _) {
        final user        = FirebaseAuth.instance.currentUser;
        // Display name fallback logic: Firestore displayName → Firebase Auth displayName → "Student"
        final displayName = myUser.username.isNotEmpty
            ? myUser.username
            : (user?.email ?? 'Student');
        final email      = myUser.email.isNotEmpty ? myUser.email : (user?.email ?? '');
        final photoURL   = user?.photoURL;

        return MyLayout(
          title: 'PROFILE',
          hideBottomNav: true,
          hideSideNav: true,
          child: MyCard(
            child: ListView(
              children: [
                const SizedBox(height: 16),

                // Avatar
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _pickAvatar(context, myUser),
                        child: AvatarWidget(
                          displayName: displayName,
                          avatarAssetPath: photoURL,
                          size: 100,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _pickAvatar(context, myUser),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.primary,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.edit, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Display name + edit icon 
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _editDisplayName(context, myUser),
                      child: Icon(Icons.edit, size: 16,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Email
                Center(
                  child: Text(
                    email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 14),
                  ),
                ),

                const SizedBox(height: 12),

                // Points
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF47B9FF).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFF47B9FF), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'POINTS: ${QuizStorageService().computeLeaderboardScore().toStringAsFixed(1)}',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Achievements 
                Card(
                  color: const Color(0xFFD2EEFF),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text('ACHIEVEMENTS',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        Text(
                          'Complete quizzes to unlock achievements!',
                          style: Theme.of(context).textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Logout
                MyButton(
                  label: 'Log out',
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.of(
                      NavigationService.navigatorKey.currentContext!,
                    ).pushReplacementNamed('/login');
                  },
                  isActive: false,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}