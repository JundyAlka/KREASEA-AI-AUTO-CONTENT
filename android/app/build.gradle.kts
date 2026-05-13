plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin (harus setelah android & kotlin)
    id("dev.flutter.flutter-gradle-plugin")
    // Google Services — untuk memproses google-services.json
    id("com.google.gms.google-services")
}

android {
    namespace = "kreasea01.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // WAJIB cocok dengan package_name di google-services.json
        applicationId = "kreasea01.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Signing dengan debug key (ganti dengan keystore production jika sudah siap)
            signingConfig = signingConfigs.getByName("debug")
            // Aktifkan minifikasi + ProGuard rules
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
        }
    }
}

flutter {
    source = "../.."
}
