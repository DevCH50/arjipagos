pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // AGP 9.3.1 y KGP 2.4.20 (con Gradle 9.5.0 en el wrapper): la combinacion de
    // las plantillas de Flutter 3.50.0, que es contra la que Flutter la prueba.
    // Flutter 3.50 exige AGP >= 9.1.1: con la 9.0.1 anterior el build no arranca.
    id("com.android.application") version "9.3.1" apply false
    id("org.jetbrains.kotlin.android") version "2.4.20" apply false
    // Plugin de Google Services para Firebase Cloud Messaging
    id("com.google.gms.google-services") version "4.4.2" apply false
}

include(":app")
