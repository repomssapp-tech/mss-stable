import java.io.File
import java.util.Properties

val releaseKeystorePropertiesFile = rootProject.file("key.properties")
val releaseKeystoreProperties = Properties().apply {
    if (releaseKeystorePropertiesFile.isFile) {
        releaseKeystorePropertiesFile.inputStream().use(::load)
    }
}
val requiredReleaseSigningFields =
    listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val hasReleaseSigning = requiredReleaseSigningFields.all { field ->
    !releaseKeystoreProperties.getProperty(field).isNullOrBlank()
}

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.inschemes.app"
    // permission_handler_android 14 needs compileSdk 37 (its CHANGELOG).
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications uses java.time on older Android.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.inschemes.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // The on-device llama.cpp bridge requires API 26. This still covers
        // Android 8+ devices while allowing the app to run a CPU/NEON fallback
        // on older chipsets without relying on vendor-specific acceleration.
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Keep native Android resources for the four supported app languages.
    androidResources.localeFilters += listOf("en", "ta", "hi", "mr")

    signingConfigs.getByName("debug") {
        // Use repo-specific debug.keystore if available, otherwise fall back to standard Android debug keystore.
        // This certificate is registered with the Android Google OAuth client if present.
        // The keystore itself is ignored by Git (android/.gitignore).
        val customKeystore = file("debug.keystore")
        if (customKeystore.exists()) {
            storeFile = customKeystore
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
    }

    if (hasReleaseSigning) {
        signingConfigs.create("release") {
            storeFile = rootProject.file(
                releaseKeystoreProperties.getProperty("storeFile"),
            )
            storePassword = releaseKeystoreProperties.getProperty("storePassword")
            keyAlias = releaseKeystoreProperties.getProperty("keyAlias")
            keyPassword = releaseKeystoreProperties.getProperty("keyPassword")
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                null
            }

            // AGP 9 uses R8 full mode and optimized resource shrinking.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    packaging {
        jniLibs.pickFirsts += "**/libomp.so"
    }

    lint {
        // Flutter regenerates the ignored local.properties file using Windows
        // path escaping that Android lint misidentifies as a source error.
        disable += "PropertyEscape"
    }
}

// Keep debug builds and IDE sync usable without production credentials, while
// preventing an unsigned release artifact from being created accidentally.
val appReleaseRequested = gradle.startParameter.taskNames.any { taskName ->
    taskName.contains("Release", ignoreCase = true)
}
if (appReleaseRequested && !hasReleaseSigning) {
    throw GradleException(
        "Release signing is not configured. Copy android/key.properties.example " +
            "to android/key.properties and provide the release keystore values.",
    )
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
