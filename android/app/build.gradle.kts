// app/build.gradle.kts

plugins {
    id("com.android.application")
    id("kotlin-android")
    // Plugin الخاص بـ Flutter
    id("dev.flutter.flutter-gradle-plugin")
    // Plugin الخاص بـ Firebase
    id("com.google.gms.google-services")
}

android {
    namespace = "nti.edu.eg.chat_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "nti.edu.eg.chat_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    buildTypes {
        release {
            // Signing debug keys مؤقتًا لتشغيل release
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM لتوحيد نسخ المكتبات
    implementation(platform("com.google.firebase:firebase-bom:34.11.0"))

    // Firebase Analytics (اختياري)
    implementation("com.google.firebase:firebase-analytics")

    // Firebase Authentication
    implementation("com.google.firebase:firebase-auth")

    // Firebase Firestore
    implementation("com.google.firebase:firebase-firestore")

    // Firebase Storage (لرفع الصور)
    implementation("com.google.firebase:firebase-storage")

    // أي dependencies أخرى موجودة عندك
}