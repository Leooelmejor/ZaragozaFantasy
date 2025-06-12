plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Flutter plugin
}

android {
    namespace = "com.example.zaragoza_fantasy_app"
    compileSdk = 34
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.zaragoza_fantasy_app"
        minSdk = 21
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // ❗ Usa "release" en producción
            isMinifyEnabled = false // ✅ No se requiere shrinkResources
            // Si algún día activas minifyEnabled = true, puedes habilitar esto también:
             isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    lint {
        disable.add("Instantiatable") // ⚠️ Solo si sabes que tu MainActivity está bien
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.android.material:material:1.6.0")
}
