## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

## Preserve annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

## Keep native methods
-keepclassmembers class * {
    native <methods>;
}
