# =============================================================================
# Reglas de ProGuard/R8 para Arjipagos
# =============================================================================

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Edge-to-edge de androidx: NO ofuscar sus nombres.
# `enableEdgeToEdge()` (MainActivity) llama por dentro a
# `Window.setStatusBarColor`/`setNavigationBarColor` en sus ramas para Android
# < 15 (`EdgeToEdgeApi23/26/29`). Ofuscadas como `d.s`, `d.t`, `d.v`, Play
# Console no las reconoce como de la librería y avisa «Tu aplicación usa APIs o
# parámetros obsoletos para la vista de extremo a extremo» (1.0.34+43). Las
# mismas llamadas del motor de Flutter, que conserva su nombre, no las señala.
# Quitar `enableEdgeToEdge()` no es salida: vuelve el otro aviso de Play.
# Solo conserva nombres: R8 puede seguir quitando lo que no se use.
# Test guardián: test/unit/edge_to_edge_android_test.dart
-keepnames class androidx.activity.EdgeToEdge* { *; }

# Mantener anotaciones
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keepattributes Signature
-keepattributes Exceptions

# Gson / JSON serialization (si se usa)
-keepattributes EnclosingMethod
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# WebView
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
    public void *(android.webkit.WebView, java.lang.String);
}

# Evitar warnings de bibliotecas comunes
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn javax.naming.**

# Google Play Core (deferred components - no usados)
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Mantener nombres de clases para stack traces legibles
-renamesourcefileattribute SourceFile
