import 'package:flutter/material.dart';
import 'package:car_platform/services/auth_service.dart';
import 'home_page.dart';
import 'ProviderPages/provider_homepage.dart';

class PasscodePage extends StatefulWidget {
  const PasscodePage({super.key});

  @override
  State<PasscodePage> createState() => _PasscodePageState();
}

class _PasscodePageState extends State<PasscodePage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final success = await AuthService.verifyCode(_codeController.text.trim());
    setState(() => _loading = false);

    if (success) {
      final user = await AuthService.getCurrentUser();
      if (!mounted) return;

      final providerId = user?['provider_id']?.toString();

      if (providerId != null && providerId.isNotEmpty) {
        // ✅ Provider employee or owner — pass providerId to homepage
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProviderHomePage(providerId: providerId),
          ),
        );
      } else {
        // 🚗 Regular car owner
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      }
    } else {
      setState(() => _error = "Invalid or expired code");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Spacer(),
                const Text("A 4 digit code was sent to your email, Enter the Code", style: TextStyle(fontSize: 18)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Passcode"),
                  validator: (v) => (v == null || v.length != 4)
                      ? "Enter a valid 4-digit code"
                      : null,
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                _loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _verifyCode,
                        child: const Text("Proceed"),
                      ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
