import 'package:flutter/material.dart';
import 'package:driveon_car_platform/pages/onboarding_screens.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _showOnboarding = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _startWelcomeSequence();
  }

  void _startWelcomeSequence() async {
    // Start logo animation
    await _logoController.forward();
    
    // Wait a bit
    await Future.delayed(const Duration(milliseconds: 1500));
    
    // Start fade animation
    await _fadeController.forward();
    
    // Wait a bit more
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Show onboarding screens
    setState(() {
      _isLoading = false;
      _showOnboarding = true;
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return const OnboardingScreens();
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[200], // Light theme background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated DriveON Logo
            AnimatedBuilder(
              animation: _logoAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoAnimation.value,
                  child: Column(
                    children: [
                      // Logo Icon
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFD32F2F), // Primary Red
                              Color(0xFFE53935), // Light Red
                              Color(0xFFEF5350), // Lighter Red
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD32F2F).withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // DriveOn Text
                      const Text(
                        'DriveOn',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Tagline
                      // SUPPRESSED: "Your Complete Automotive Solution" — too broad while we focus on Alerts
                      // child: const Text('Your Complete Automotive Solution', ...)
                      AnimatedBuilder(
                        animation: _fadeAnimation,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _fadeAnimation.value,
                            child: const Text(
                              'Drive Safe. Stay Informed.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                                letterSpacing: 1,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            
            const SizedBox(height: 60),
            
            // Loading Spinner
            if (_isLoading)
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD32F2F)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
