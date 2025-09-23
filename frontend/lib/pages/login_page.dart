import 'package:flutter/material.dart';
import 'package:car_platform/services/auth_service.dart';
import 'passcode_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _sendCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final success = await AuthService.sendCode(_emailController.text.trim());

    setState(() => _loading = false);

    if (success) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PasscodePage()),
      );
    } else {
      setState(() => _error = "Failed to send code. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // no need for backgroundColor — theme handles it
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // ✅ uses theme
              Text(
                "Welcome Back 👋",
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 24),

              // ✅ inherits inputDecorationTheme
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 16),

              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),

              const SizedBox(height: 16),

              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _sendCode,
                      child: const Text("Send Code"),
                    ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
