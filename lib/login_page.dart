// import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/providers/user.dart';
import 'package:flutter_pomodoro/widgets/layout.dart';
import 'package:flutter_pomodoro/widgets/my_button.dart';
import 'package:flutter_pomodoro/widgets/my_card.dart';
import 'package:flutter_pomodoro/widgets/sign_in_form.dart';
import 'package:provider/provider.dart';

enum FormViews { login, signup, forgot }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final String title = '';
  FormViews formView = .login;

  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser?.email != null) {
      // Navigator.pushNamed(context, '/');
    }
    super.initState();
  }

  Future<void> signIn(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      UserCredential credentials = await Provider.of<MyUser>(
        context,
        listen: false,
      ).logIn(email, password);
      if (credentials.user?.email != null) {
        if (context.mounted) {
          Navigator.pushNamed(context, '/');
        }
      }

      print(credentials);
    } catch (e) {
      print(e);
    }
  }

  Future<void> signUp(
    BuildContext context,
    String email,
    String password,
  ) async {
    try {
      UserCredential credentials = await Provider.of<MyUser>(
        context,
        listen: false,
      ).signUp(email, password);
      if (credentials.user?.email != null) {
        if (context.mounted) {
          Navigator.pushNamed(context, '/');
        }
      }

      print(credentials);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MyLayout(
      title: title,
      hideBottomNav: true,
      hideSideNav: true,
      hideBackButton: true,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Expanded(
            child: MyCard(
              child: ListView(
                children: [
                  Container(
                    alignment: .center,
                    padding: .symmetric(vertical: 20),
                    child: FittedBox(
                      child: Text(
                        'Welcome to EduQuest',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Visibility(
                    visible: formView == FormViews.login,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: renderLoginForm(context),
                    ),
                  ),
                  Visibility(
                    visible: formView == FormViews.signup,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: renderSignupForm(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  SignInForm renderLoginForm(BuildContext context) {
    return SignInForm(
      onSignIn: (email, password) {
        signIn(context, email, password);
      },
      child: Column(
        children: [
          TextButton(
            onPressed: () => {print('forgot password')},
            style: ButtonStyle(overlayColor: WidgetStateColor.transparent),
            child: Text('Forgot Password?'),
          ),

          Divider(indent: 50, endIndent: 50, height: 50),
          Text('or'),
          Divider(indent: 50, endIndent: 50, height: 50),
          MyButton(
            label: 'Sign Up',
            onPressed: () {
              setState(() {
                formView = .signup;
              });
            },
            isActive: false,
          ),
        ],
      ),
    );
  }

  SignInForm renderSignupForm(BuildContext context) {
    return SignInForm(
      submitLabel: 'Sign Up',
      onSignIn: (email, password) {
        signUp(context, email, password);
      },
      child: Column(
        children: [
          TextButton(
            onPressed: () => {
              setState(() {
                formView = .login;
              }),
            },
            style: ButtonStyle(overlayColor: WidgetStateColor.transparent),
            child: Text('Already have an account'),
          ),
        ],
      ),
    );
  }
}
