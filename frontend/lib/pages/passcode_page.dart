import 'package:flutter/material.dart';
import 'package:car_platform/services/auth_service.dart';
import 'home_page.dart';

class PasscodePage extends StatefulWidget {
  const PasscodePage({super.key});

  @override
  State<PasscodePage> createState() => _PasscodePageState();
}

class _PasscodePageState extends State<PasscodePage> {
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _verifyCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final success = await AuthService.verifyCode(
      _codeController.text.trim(),
    );

    setState(() => _loading = false);

    if (success) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      setState(() => _error = "Invalid or expired code");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // ✅ get active theme (light/dark)

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              Text(
                "Enter the Code",
                style: theme.textTheme.titleLarge, // ✅ uses themed text
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _codeController,
                style: theme.textTheme.bodyLarge, // ✅ themed input text
                decoration: const InputDecoration(
                  labelText: "Passcode",
                  // underline, focus color, etc. come from InputDecorationTheme
                ),
              ),
              const SizedBox(height: 16),

              if (_error != null)
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),

              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _verifyCode,
                      child: const Text("Proceed"),
                    ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
