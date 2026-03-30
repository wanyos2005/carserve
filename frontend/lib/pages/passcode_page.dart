import 'package:flutter/material.dart';
import 'package:driveon_car_platform/services/auth_service.dart';
import 'package:driveon_car_platform/services/user_context_service.dart';
import 'package:driveon_car_platform/services/mpesa_sms_service.dart';
import 'main_service_nav.dart';
import 'ProviderPages/provider_homepage.dart';
import 'AdminPages/admin_dashboard.dart';

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
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final success = await AuthService.verifyCode(_codeController.text.trim());
    setState(() => _loading = false);

    if (success) {
      // Initialize user context after successful verification
      final userContext = await UserContextService.refreshContext();
      if (!mounted) return;

      if (userContext != null && userContext.userType != UserType.unknown) {
        if (userContext.isAdmin) {
          // 🔧 Admin user
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        } else if (userContext.isProvider && userContext.providerId != null) {
          // ✅ Provider employee or owner — trigger SMS permission prompt, don't block navigation
          MpesaSmsService.initialize();
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProviderHomePage(providerId: userContext.providerId!),
            ),
          );
        } else {
          // 🚗 Regular car owner
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainServiceNav()),
          );
        }
      } else {
        setState(() => _error = "Failed to load user information");
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
                Text(
                  "Verification Code",
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 28),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "A 4-digit code was sent to your email. Please enter it below to be signed in.",
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
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
