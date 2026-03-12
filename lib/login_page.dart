// import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/providers/user.dart';
import 'package:flutter_pomodoro/services/navigation_service.dart';
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
  bool isLoading = false;

  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser?.email != null) {
      Navigator.of(
        NavigationService.navigatorKey.currentContext!,
      ).pushNamed('/home');
    }
    super.initState();
  }

  void showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> signIn(
    BuildContext context,
    String email,
    String password,
  ) async {
    if (isLoading) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    showLoading(context);
    try {
      UserCredential credentials = await Provider.of<MyUser>(
        context,
        listen: false,
      ).logIn(email, password);
      if (credentials.user?.email != null) {
        if (context.mounted) Navigator.pop(context);
        Navigator.of(
          NavigationService.navigatorKey.currentContext!,
        ).pushNamed('/home');
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) Navigator.pop(context);
      showMyDialog(e.message ?? 'An error occurred');
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      showMyDialog('An unexpected error occurred: $e');
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> signUp(
    BuildContext context,
    String email,
    String password,
  ) async {
    if (isLoading) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    showLoading(context);
    try {
      UserCredential credentials = await Provider.of<MyUser>(
        context,
        listen: false,
      ).signUp(email, password);
      if (credentials.user?.email != null) {
        if (context.mounted) Navigator.pop(context);
        Navigator.of(
          NavigationService.navigatorKey.currentContext!,
        ).pushNamed('/home');
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) Navigator.pop(context);
      showMyDialog(e.message ?? 'An error occurred');
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      showMyDialog('An unexpected error occurred: $e');
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> forgotPassword(BuildContext context, String email) async {
    if (isLoading) {
      return;
    }
    setState(() {
      isLoading = true;
    });
    showLoading(context);
    try {
      // FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Provider.of<MyUser>(context, listen: false).resetPassword(email);
      showMyDialog('Password reset email sent to $email');
      setState(() {
        formView = .login;
      });
    } on FirebaseAuthException catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (e.code == 'user-not-found') {
        showMyDialog('No user found for that email.');
      } else if (e.code == 'invalid-email') {
        showMyDialog('The email address is invalid.');
      } else {
        showMyDialog(e.message ?? 'An error occurred');
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      showMyDialog('An unexpected error occurred: $e');
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<String?> showMyDialog(String text) {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) => Dialog(
        child: Padding(padding: .all(20), child: Text(text)),
      ),
    );
  }

  Widget renderLoginForm(BuildContext context) {
    return SignInForm(
      isLoading: isLoading,
      onSignIn: (email, password) {
        signIn(context, email, password);
      },
      child: Column(
        children: [
          TextButton(
            onPressed: () => {
              setState(() {
                formView = .forgot;
              }),
            },
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
            isLoading: isLoading,
          ),
        ],
      ),
    );
  }

  Widget renderSignupForm(BuildContext context) {
    return SignInForm(
      submitLabel: 'Sign Up',
      isLoading: isLoading,
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

  Widget renderResetForm(BuildContext context) {
    return SignInForm(
      submitLabel: 'Reset Password',
      isLoading: isLoading,
      hidePassword: true,
      onSignIn: (email, password) {
        forgotPassword(context, email);
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
            child: Text('Login instead'),
          ),
        ],
      ),
    );
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
                  Visibility(
                    visible: formView == FormViews.forgot,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: renderResetForm(context),
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
}
