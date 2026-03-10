import 'package:flutter/material.dart';
import 'package:flutter_pomodoro/widgets/my_button.dart';

class SignInForm extends StatefulWidget {
  final void Function(String email, String password)? onSignIn;
  final Widget? child;
  final String? submitLabel;
  final bool isLoading;
  final bool hidePassword;

  const SignInForm({
    super.key,
    this.onSignIn,
    this.child,
    this.submitLabel,
    this.isLoading = false,
    this.hidePassword = false,
  });

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.onSignIn?.call(
        _emailController.text.trim(),
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            style: TextStyle(fontSize: 15),
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              const String emailRegexPattern =
                  r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';

              final emailRegex = RegExp(emailRegexPattern);
              if (!emailRegex.hasMatch(value)) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          Visibility(
            visible: !widget.hidePassword,
            child: const SizedBox(height: 16),
          ),
          Visibility(
            visible: !widget.hidePassword,
            child: TextFormField(
              controller: _passwordController,
              style: TextStyle(fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 24),
          MyButton(
            label: widget.submitLabel ?? 'Login',
            onPressed: _submit,
            isActive: true,
          ),
          Container(child: widget.child),
        ],
      ),
    );
  }
}
