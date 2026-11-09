import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localProperties.load(FileInputStream(localPropertiesFile))
}

android {
    namespace = "com.example.rideapp"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true

    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // Release signing reads android/key.properties (see key.properties.example).
    // Without it, release builds are signed with the debug key.
    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.rideapp"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // resConfigs is deprecated, using androidResources below
        manifestPlaceholders["MAPS_API_KEY"] = localProperties["MAPS_API_KEY"] as String? ?: ""
    }

    androidResources {
        localeFilters += listOf("en", "es")
    }

 buildTypes {
    release {
        signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")

        isMinifyEnabled = true
        isShrinkResources = true

        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}

    flavorDimensions += "default"
    productFlavors {
        create("dev") {
            dimension = "default"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Ride App Dev")
        }
        create("staging") {
            dimension = "default"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "Ride App Staging")
        }
        create("production") {
            dimension = "default"
            resValue("string", "app_name", "Ride App")
        }
    }

}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.9.0")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}