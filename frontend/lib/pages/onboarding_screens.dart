import 'package:flutter/material.dart';
import 'package:driveon_car_platform/pages/login_page.dart';
// SUPPRESSED: Provider onboarding imports — re-enable when provider features go live
// import 'package:driveon_car_platform/pages/ProviderPages/dynamic_onboarding_flow.dart';
// import 'package:driveon_car_platform/models/onboarding_config.dart';

//we first declare the class OnboardingScreens which extends StatefulWidget
class OnboardingScreens extends StatefulWidget {
  const OnboardingScreens({super.key});

  @override
  State<OnboardingScreens> createState() => _OnboardingScreensState();
}

//we then declare the class _OnboardingScreensState which extends State<OnboardingScreens>
class _OnboardingScreensState extends State<OnboardingScreens> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  //we then declare the list _onboardingData which contains the data for the onboarding screens
  // ALERTS-FOCUSED SLIDES — strategy phase: gain users through the Alerts feature first
  final List<OnboardingData> _onboardingData = [
    OnboardingData(
      title: "Real-Time Road Alerts",
      description: "Get instant notifications about hazards, accidents, and road conditions near you — before you encounter them.",
      image: Icons.warning_amber_rounded,
      color: const Color(0xFFD32F2F),
      features: [
        "Live Hazard Warnings",
        "Location-Based Alerts",
        "Instant Notifications",
        "Accurate & Up-to-Date",
      ],
    ),
    OnboardingData(
      title: "Report Incidents Instantly",
      description: "Spot a pothole, accident, or road closure? Report it in seconds and help fellow drivers stay safe.",
      image: Icons.report_problem,
      color: const Color(0xFF1E3A8A),
      features: [
        "One-Tap Reporting",
        "Photo Attachments",
        "Verified by Community",
        "Reach Nearby Drivers",
      ],
    ),
    OnboardingData(
      title: "Stay Informed, Drive Safe",
      description: "Receive safety briefings tailored to your regular routes. Know what's ahead before you hit the road.",
      image: Icons.shield_outlined,
      color: const Color(0xFF059669),
      features: [
        "Route-Specific Alerts",
        "Weather Warnings",
        "Traffic Incidents",
        "Emergency Broadcasts",
      ],
    ),
    OnboardingData(
      title: "Community-Powered Safety",
      description: "Every driver on DriveOn contributes to a safer road network. Together we see more, share faster, and protect each other.",
      image: Icons.people_alt_outlined,
      color: const Color(0xFF7C3AED),
      features: [
        "Crowd-Sourced Reports",
        "Verified Alert Network",
        "Growing Community",
        "Always Free to Use",
      ],
    ),
  ];

  // SUPPRESSED: Provider-focused slides — re-enable when service provider features go live
  // OnboardingData(
  //   title: "Find Trusted Service Providers",
  //   description: "Connect with verified garages, mechanics, and automotive specialists in your area. All providers are vetted and rated by real customers.",
  //   image: Icons.build_circle,
  //   color: const Color(0xFF1E3A8A),
  //   features: ["Verified & Rated Providers", "Real Customer Reviews", "Location-Based Search", "24/7 Availability"],
  // ),
  // OnboardingData(
  //   title: "Book Services Instantly",
  //   description: "Schedule oil changes, repairs, inspections, and more with just a few taps.",
  //   image: Icons.calendar_today,
  //   color: const Color(0xFF059669),
  //   features: ["Instant Booking", "Flexible Scheduling", "Real-Time Availability", "Service Tracking"],
  // ),
  // OnboardingData(
  //   title: "Complete Automotive Care",
  //   description: "From routine maintenance to repairs, fuel stations to car washes - we've got all your automotive needs covered.",
  //   image: Icons.car_repair,
  //   color: const Color(0xFFDC2626),
  //   features: ["Routine Maintenance", "Emergency Repairs", "Fuel & Car Wash", "Insurance & Documentation"],
  // ),
  // OnboardingData(
  //   title: "Transparent Pricing",
  //   description: "No hidden fees or surprises. See upfront pricing for all services, compare quotes, and pay securely through the app.",
  //   image: Icons.account_balance_wallet,
  //   color: const Color(0xFF7C3AED),
  //   features: ["Upfront Pricing", "Quote Comparison", "Secure Payments", "No Hidden Fees"],
  // ),
  //dispose in laymans language means to remove the object from the memory, in this case we are removing the page controller from the memory, so that it is not used again
  //since the user the user has already seen the onboarding screens, we can remove the page controller from the memory
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  //build in laymans language means to build the widget tree, in this case we are building the widget tree for the onboarding screens. Overide in laymans language means that we are overriding the build method of the State class, that is what will show up on the screen. 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Light theme background
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip Button
                  TextButton(
                    onPressed: _goToLogin,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  
                  // Sign In Button
                  TextButton(
                    onPressed: _goToLogin,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Colors.grey, width: 1),
                      ),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingPage(_onboardingData[index]);
                },
              ),
            ),
            
             // Bottom Section
             Padding(
               padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
               child: Column(
                 children: [
                   // Page Indicators
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: List.generate(
                       _onboardingData.length,
                       (index) => _buildPageIndicator(index),
                     ),
                   ),
                   
                   const SizedBox(height: 20),
                  
                   // Buttons arranged horizontally
                   Row(
                     children: [
                       // Get Started Button (Left)
                       Expanded(
                         child: SizedBox(
                           height: 50,
                           child: ElevatedButton(
                             onPressed: _goToLogin,
                             style: ElevatedButton.styleFrom(
                               backgroundColor: const Color(0xFFD32F2F), // Primary red from main.dart
                               foregroundColor: Colors.white,
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(12),
                               ),
                               elevation: 2,
                             ),
                             child: const Text(
                               'Get Started',
                               style: TextStyle(
                                 fontSize: 16,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                           ),
                         ),
                       ),
                       
                       // SUPPRESSED: "Register as Provider" button — re-enable when provider features go live
                       // const SizedBox(width: 12),
                       // Expanded(
                       //   child: SizedBox(
                       //     height: 50,
                       //     child: OutlinedButton(
                       //       onPressed: _goToProviderOnboarding,
                       //       style: OutlinedButton.styleFrom(
                       //         side: const BorderSide(color: Color(0xFFD32F2F), width: 2),
                       //         shape: RoundedRectangleBorder(
                       //           borderRadius: BorderRadius.circular(12),
                       //         ),
                       //       ),
                       //       child: const Text(
                       //         'Register as Provider',
                       //         style: TextStyle(
                       //           fontSize: 16,
                       //           fontWeight: FontWeight.w600,
                       //           color: Color(0xFFD32F2F),
                       //         ),
                       //       ),
                       //     ),
                       //   ),
                       // ),
                     ],
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingPage(OnboardingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: data.color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              data.image,
              size: 50,
              color: data.color,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Title
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            data.description,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 30),
          
          // Features
          Column(
            children: data.features.map((feature) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: data.color,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? const Color(0xFFD32F2F) : Colors.grey[400],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  void _goToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  // SUPPRESSED: Provider registration bottom sheet — re-enable when provider features go live
  // void _goToProviderOnboarding() {
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  //     ),
  //     builder: (context) {
  //       return SafeArea(
  //         child: Padding(
  //           padding: const EdgeInsets.all(16),
  //           child: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Register As',
  //                 style: Theme.of(context).textTheme.titleLarge?.copyWith(
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //               ),
  //               const SizedBox(height: 12),
  //               Card(
  //                 child: ListTile(
  //                   leading: const Icon(Icons.build_circle, color: Colors.blue),
  //                   title: const Text('Service Provider'),
  //                   subtitle: const Text('Garage, fuel station, car wash, roadside, etc.'),
  //                   onTap: () {
  //                     Navigator.pop(context);
  //                     Navigator.pushReplacement(
  //                       context,
  //                       MaterialPageRoute(
  //                         builder: (context) => const DynamicOnboardingFlow(
  //                           type: OnboardingType.serviceProvider,
  //                         ),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //               ),
  //               const SizedBox(height: 8),
  //               Card(
  //                 child: ListTile(
  //                   leading: const Icon(Icons.security, color: Colors.red),
  //                   title: const Text('Insurance Partner'),
  //                   subtitle: const Text('Insurance company offering quotes and policies'),
  //                   onTap: () {
  //                     Navigator.pop(context);
  //                     Navigator.pushReplacement(
  //                       context,
  //                       MaterialPageRoute(
  //                         builder: (context) => const DynamicOnboardingFlow(
  //                           type: OnboardingType.insurancePartner,
  //                         ),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       );
  //     },
  //   );
  // }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData image;
  final Color color;
  final List<String> features;

  OnboardingData({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
    required this.features,
  });
}
