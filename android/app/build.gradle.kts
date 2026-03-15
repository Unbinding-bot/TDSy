plugins {
    id "com.android.application"
    id "kotlin-android"
    // Flutter Gradle plugin must be applied after Android and Kotlin
    id "dev.flutter.flutter-gradle-plugin"
}

android {
    namespace "com.example.tds_monitor"
    compileSdk flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId "com.example.tds_monitor"
        minSdk 21
        targetSdk flutter.targetSdkVersion
        versionCode flutter.versionCode
        versionName flutter.versionName
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug
            minifyEnabled false
            shrinkResources false
        }
    }
}

flutter {
    source "../.."
}