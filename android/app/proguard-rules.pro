# Flutter specific ProGuard rules

# Keep Flutter engine and embedding
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep Dart runtime
-keep class android.** { *; }
-keep class androidx.** { *; }

# Keep all classes with native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep serializable classes (JSON)
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep annotations
-keepattributes *Annotation*

# Keep localization resources
-keep class **.R$* { *; }

# WebView
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String);
}

# Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Background Service
-keep class id.flutter.flutter_background_service.** { *; }

# HTTP Library (required for Telegram reporting)
-keep class org.apache.http.** { *; }
-keep class java.net.** { *; }
-keep class javax.net.ssl.** { *; }

# Ensure ErrorReporting models are preserved for JSON serialization
-keep class * implements java.io.Serializable { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
