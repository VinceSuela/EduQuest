// import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/firebase_options.dart';
import 'package:flutter_pomodoro/friends_page.dart';
import 'package:flutter_pomodoro/login_page.dart';
import 'package:flutter_pomodoro/my_home_page.dart';
import 'package:flutter_pomodoro/pdf_viewer.dart';
import 'package:flutter_pomodoro/page_flappy_bird.dart';
import 'package:flutter_pomodoro/page_snake.dart';
import 'package:flutter_pomodoro/page_trex.dart';
import 'package:flutter_pomodoro/profile_page.dart';
import 'package:flutter_pomodoro/providers/counter.dart';
import 'package:flutter_pomodoro/providers/my_file.dart';
import 'package:flutter_pomodoro/providers/page.dart';
import 'package:flutter_pomodoro/providers/quiz_generator.dart';
import 'package:flutter_pomodoro/providers/user.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
import 'package:flutter_pomodoro/splash_page.dart';
import 'package:flutter_pomodoro/quiz_page.dart';
import 'package:provider/provider.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:flutter_pomodoro/models/quiz_question.dart';
import 'package:flutter_pomodoro/models/quiz_session.dart';
import 'package:flutter_pomodoro/leaderboard_page.dart';
// import 'package:file_picker/file_picker.dart';

bool shouldUseFirebaseEmulator = false;
late final FirebaseApp app;
late final FirebaseAuth auth;

Future<void> _precacheAvatars(BuildContext context) async {
  final avatars = [
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
  for (final path in avatars) {
    await precacheImage(AssetImage(path), context);
  }
}

Future<void> _compactHiveIfNeeded() async {
  await Hive.box<QuizSession>('quiz_sessions').compact();
  await Hive.box('user_stats').compact();
  await Hive.box('quiz_cache').compact();
  await Hive.box('pdf_cache').compact();
  await Hive.box('leaderboard_cache').compact();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(QuizQuestionHiveAdapter());
  Hive.registerAdapter(QuizSessionAdapter());

  await Future.wait([
    Hive.openBox<QuizSession>('quiz_sessions'),
    Hive.openBox('user_stats'),
    Hive.openBox('quiz_cache'),
    Hive.openBox('pdf_cache'),
    Hive.openBox('leaderboard_cache'),
  ]);

  await _compactHiveIfNeeded();

  app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  auth = FirebaseAuth.instanceFor(app: app);

  if (shouldUseFirebaseEmulator) {
    await auth.useAuthEmulator('localhost', 9099);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MyPage()),
        ChangeNotifierProvider(create: (_) => MyCounter()),
        ChangeNotifierProvider(create: (_) => MyUser()),
        ChangeNotifierProvider(create: (_) => MyFile()),
        ChangeNotifierProvider(create: (_) => GeminiQuizService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    // Provider.of<MyUser>(context).googleSignIn.silentSignIn();
    // _googleSignIn.silentSignIn();
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheAvatars(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      title: 'EduQuest',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.lightBlueAccent),
        fontFamily: 'Baloo2',
        textTheme: TextTheme(
          bodySmall: TextStyle(color: Color(0xFF5E5E5E), fontSize: 10),
          bodyMedium: TextStyle(color: Color(0xFF5E5E5E)),
          bodyLarge: TextStyle(color: Color(0xFF5E5E5E), fontSize: 25),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => SplashPage(),
        '/home': (context) => const MyHomePage(),
        '/profile': (context) => ProfilePage(),
        '/login': (context) => LoginPage(),
        '/friends': (context) => FriendsPage(),
        '/pdfViewer': (context) => PinchPage(),
        '/flappy': (context) => FlappyBirdPage(),
        '/snake': (context) => SnakeGamePage(),
        '/trex': (context) => TrexGamePage(),
        '/quiz': (context) => MyQuiz(),
        '/leaderboard': (context) => LeaderboardPage(),
      },
    );
  }
}
