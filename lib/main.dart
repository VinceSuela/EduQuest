// import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:flutter_pomodoro/providers/user.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
import 'package:flutter_pomodoro/splash_page.dart';
import 'package:flutter_pomodoro/quiz_page.dart';
import 'package:provider/provider.dart';
// import 'package:file_picker/file_picker.dart';

bool shouldUseFirebaseEmulator = false;
late final FirebaseApp app;
late final FirebaseAuth auth;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  app = await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      title: 'Flutter Demo',
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
      },
    );
  }
}
