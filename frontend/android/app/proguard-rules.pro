# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep your app's specific classes
-keep class com.driveon.carplatform.** { *; }

# Google Play Core rules
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Firebase rules
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
