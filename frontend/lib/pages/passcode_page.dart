import 'package:flutter/material.dart';
import 'package:car_platform/services/auth_service.dart';
import 'home_page.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                Text(
                  "Enter the Code",
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.start,
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _codeController,
                  style: theme.textTheme.bodyLarge,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Passcode"),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return "Passcode required";
                    }
                    if (val.length != 6) {
                      return "Enter a valid 6-digit code";
                    }
                    return null;
                  },
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
      ),
    );
  }
}
