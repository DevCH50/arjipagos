import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android plugin.
    // Incluye soporte Kotlin built-in desde Flutter 3.27+, no requiere kotlin-android explícito.
    id("dev.flutter.flutter-gradle-plugin")
    // Plugin de Google Services para Firebase Cloud Messaging (FCM)
    id("com.google.gms.google-services")
}

// Cargar propiedades del keystore para firma de release
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "mx.moriah.arjipagos"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Requerido por flutter_local_notifications para APIs de Java 8+ en Android antiguo
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "mx.moriah.arjipagos"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        getByName("release") {
            // Indica que el build de release use la firma que configuramos arriba
            signingConfig = signingConfigs.getByName("release")
            // R8: Ofuscación y optimización de código
            isMinifyEnabled = true
            // Eliminar recursos no utilizados
            isShrinkResources = true
            // Reglas de ProGuard para Flutter
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// Objetivo de la JVM para Kotlin. Reemplaza al bloque `kotlinOptions` dentro de
// `android { }`, eliminado en AGP 9.0. Es la forma que usa la plantilla oficial
// de Flutter 3.44.8. NO volver a `kotlinOptions`: rompe la compilacion del script.
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Requerido por flutter_local_notifications para core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
