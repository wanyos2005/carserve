import 'package:flutter/material.dart';

// Pages
import 'package:car_platform/pages/login_page.dart';
import 'package:car_platform/pages/home_page.dart';

// Services
import 'package:car_platform/services/auth_service.dart';

void main() {
  runApp(const CarPlatformApp());
}

class CarPlatformApp extends StatelessWidget {
  const CarPlatformApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Car Platform",
      theme: _buildLightTheme(),      // ✅ Light theme
      darkTheme: _buildDarkTheme(),  // ✅ Dark theme
      themeMode: ThemeMode.system,   // ✅ Adapts to system setting
      initialRoute: "/login",
      routes: {
        "/login": (context) => const LoginPage(),
        "/home": (context) => const HomePage(),
      },
      home: FutureBuilder(
        future: AuthService.getMe(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const HomePage();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }

  // 🌞 Light theme
  ThemeData _buildLightTheme() {
    const primaryAccent = Color(0xFFD32F2F); // Netflix red

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryAccent,
      scaffoldBackgroundColor: Colors.grey[80], // or 300
      fontFamily: 'Poppins',

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black87, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.black54, fontSize: 14),
        titleLarge: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),

      inputDecorationTheme: const InputDecorationTheme(
        filled: false, // ❌ no background fill
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red), // red underline when enabled
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2), // thicker underline on focus
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.red),
        ),
        labelStyle: TextStyle(color: Colors.black54),
        hintStyle: TextStyle(color: Colors.black38),
      ),
    );
  }

  // 🌑 Dark theme (your existing one)
  ThemeData _buildDarkTheme() {
    const primaryAccent = Color(0xFFD32F2F); // Netflix red
    const abyssBlack = Color(0xFF0D0D0F);    // near-black
    const abyssBlue = Color(0xFF0A0E1A);     // dark abyss blue

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryAccent,
      scaffoldBackgroundColor: abyssBlack,
      fontFamily: 'Poppins',

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
        bodyMedium: TextStyle(color: Colors.white70, fontSize: 14),
        titleLarge: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      cardTheme: CardThemeData(
        color: abyssBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),

      inputDecorationTheme: const InputDecorationTheme(
        filled: false, // ❌ no background fill
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 2),
        ),
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent),
        ),
        labelStyle: TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white38),
      ),
    );
  }
}
