plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.plantify_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        
        // --- PERUBAHAN 1: AKTIFKAN FITUR DESUGARING DI SINI ---
        // Baris ini memberitahu Gradle untuk mengaktifkan "translator" Java.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.plantify_app"
        minSdk = flutter.minSdkVersion 
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Konfigurasi Multidex (tetap biarkan)
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Dependensi untuk Multidex (tetap biarkan)
    implementation("androidx.multidex:multidex:2.0.1")

    // --- PERUBAHAN 2: TAMBAHKAN LIBRARY "TRANSLATOR"-NYA ---
    // Baris ini memberitahu Gradle library mana yang harus digunakan untuk proses desugaring.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}
