// login_page.dart
import 'package:flutter/material.dart';
import 'package:car_platform/services/auth_service.dart';
import 'home_page.dart';


class PasscodePage extends StatefulWidget {
  const PasscodePage({super.key});

  @override
  State<PasscodePage> createState() => _PasscodePageState();
}

class _PasscodePageState extends State<PasscodePage> {
  final _passcodeController = TextEditingController();
  // final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final success = await AuthService.login(
      _passcodeController.text.trim(),
      // _passwordController.text.trim(),
    );

    setState(() => _loading = false);

    if (success) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      setState(() => _error = "Invalid code");
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Color(0xFFFF6F61), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Text(
                "Enter the Code",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Email
              TextField(
                controller: _passcodeController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Passcode"),
              ),
              const SizedBox(height: 16),

              // // Password
              // TextField(
              //   controller: _passwordController,
              //   obscureText: true,
              //   style: const TextStyle(color: Colors.white),
              //   decoration: _inputDecoration("Password"),
              // ),

              // const SizedBox(height: 24),

              if (_error != null)
                Text(_error!,
                    style: const TextStyle(color: Colors.redAccent)),

              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF6F61),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Proceed",
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, "/register"),
                child: const Text(
                  "Don’t have an account? Register",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
